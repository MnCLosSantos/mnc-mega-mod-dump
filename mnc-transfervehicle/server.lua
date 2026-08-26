local QBCore = exports['qb-core']:GetCoreObject()
local pendingTransfers = {}

local function DebugPrint(message)
    if Config.Debug then
        print('[VEHICLE-TRANSFER] ' .. message)
    end
end

local function GenerateDocumentID()
    return 'VTDOC_' .. math.random(100000, 999999) .. '_' .. os.time()
end

local function comma_value(amount)
    local formatted = tostring(amount)
    while true do  
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if k == 0 then break end
    end
    return '$' .. formatted
end

-- Make the transfer document item usable
QBCore.Functions.CreateUseableItem('vehicletransdocument', function(source, item)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    
    local info = item.info or {}
    
    if not info.documentData then
        exports['ox_lib']:notify(source, {
            title = 'Invalid Document',
            description = 'This document is corrupted',
            type = 'error'
        })
        return
    end
    
    TriggerClientEvent('mnc-transfervehicle:client:viewDocument', source, info.documentData)
end)

-- Initial transfer command - opens UI for seller
QBCore.Commands.Add('transfervehicle', 'Transfer vehicle ownership', {
    { name = 'ID', help = 'Player ID (optional)' },
    { name = 'amount', help = 'Sale amount (optional)' }
}, false, function(source, args)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    local ped = GetPlayerPed(src)
    local vehicle = GetVehiclePedIsIn(ped, false)
    
    if vehicle == 0 then
        exports['ox_lib']:notify(src, {
            title = 'Vehicle Transfer',
            description = 'You must be in a vehicle',
            type = 'error'
        })
        return
    end
    
    local plate = QBCore.Shared.Trim(GetVehicleNumberPlateText(vehicle))
    if not plate then
        exports['ox_lib']:notify(src, {
            title = 'Vehicle Transfer',
            description = 'Could not get vehicle information',
            type = 'error'
        })
        return
    end
    
    local row = MySQL.single.await('SELECT * FROM player_vehicles WHERE plate = ?', { plate })
    
    if not row then
        exports['ox_lib']:notify(src, {
            title = 'Vehicle Transfer',
            description = 'Vehicle not found in database',
            type = 'error'
        })
        return
    end
    
    if Config.PreventFinanceSelling and row.balance and row.balance > 0 then
        exports['ox_lib']:notify(src, {
            title = 'Vehicle Transfer',
            description = 'Cannot sell a financed vehicle',
            type = 'error'
        })
        return
    end
    
    if row.citizenid ~= Player.PlayerData.citizenid then
        exports['ox_lib']:notify(src, {
            title = 'Vehicle Transfer',
            description = 'You do not own this vehicle',
            type = 'error'
        })
        return
    end
    
    local vehicleData = QBCore.Shared.Vehicles[row.vehicle]
    local vehicleName = vehicleData and vehicleData.name or row.vehicle
    local vehicleBrand = vehicleData and vehicleData.brand or 'Unknown'
    
    local sellerData = {
        source = src,
        citizenid = Player.PlayerData.citizenid,
        firstname = Player.PlayerData.charinfo.firstname,
        lastname = Player.PlayerData.charinfo.lastname,
        phone = Player.PlayerData.charinfo.phone,
        plate = plate,
        vehicle = row.vehicle,
        vehicleName = vehicleName,
        vehicleBrand = vehicleBrand,
        mileage = row.mileage or 0
    }
    
    local buyerId = tonumber(args[1])
    local sellAmount = tonumber(args[2])
    
    TriggerClientEvent('mnc-transfervehicle:client:openSellerUI', src, sellerData, buyerId, sellAmount)
end)

-- Get buyer info from ID
RegisterNetEvent('mnc-transfervehicle:server:getBuyerInfo', function(buyerId, sellerData, amount)
    local src = source
    local Seller = QBCore.Functions.GetPlayer(src)
    local Buyer = QBCore.Functions.GetPlayer(buyerId)
    
    if not Seller or not Buyer then
        exports['ox_lib']:notify(src, {
            title = 'Vehicle Transfer',
            description = 'Buyer not found or offline',
            type = 'error'
        })
        return
    end
    
    if buyerId == src then
        exports['ox_lib']:notify(src, {
            title = 'Vehicle Transfer',
            description = 'You cannot sell to yourself',
            type = 'error'
        })
        return
    end
    
    local sellerPed = GetPlayerPed(src)
    local buyerPed = GetPlayerPed(buyerId)
    local sellerCoords = GetEntityCoords(sellerPed)
    local buyerCoords = GetEntityCoords(buyerPed)
    
    if #(sellerCoords - buyerCoords) > Config.TransferDistance then
        exports['ox_lib']:notify(src, {
            title = 'Vehicle Transfer',
            description = 'Buyer is too far away',
            type = 'error'
        })
        return
    end
    
    local buyerInfo = {
        source = buyerId,
        citizenid = Buyer.PlayerData.citizenid,
        firstname = Buyer.PlayerData.charinfo.firstname,
        lastname = Buyer.PlayerData.charinfo.lastname,
        phone = Buyer.PlayerData.charinfo.phone,
        cash = Buyer.Functions.GetMoney('cash'),
        bank = Buyer.Functions.GetMoney('bank')
    }
    
    TriggerClientEvent('mnc-transfervehicle:client:updateBuyerInfo', src, buyerInfo, amount)
end)

-- Seller confirms and sends to buyer
RegisterNetEvent('mnc-transfervehicle:server:sendToBuyer', function(transferData)
    local src = source
    local Seller = QBCore.Functions.GetPlayer(src)
    local Buyer = QBCore.Functions.GetPlayer(transferData.buyer.source)
    
    if not Seller or not Buyer then
        exports['ox_lib']:notify(src, {
            title = 'Vehicle Transfer',
            description = 'Transaction failed: Player not found',
            type = 'error'
        })
        return
    end
    
    local documentID = GenerateDocumentID()
    transferData.documentID = documentID
    transferData.timestamp = os.date('%Y-%m-%d %H:%M:%S')
    
    pendingTransfers[documentID] = {
        data = transferData,
        seller = src,
        buyer = transferData.buyer.source,
        expiry = os.time() + (Config.DocumentExpiration / 1000)
    }
    
    TriggerClientEvent('mnc-transfervehicle:client:openBuyerUI', transferData.buyer.source, transferData)
    
    exports['ox_lib']:notify(src, {
        title = 'Vehicle Transfer',
        description = 'Transfer document sent to buyer',
        type = 'success'
    })
    
    exports['ox_lib']:notify(transferData.buyer.source, {
        title = 'Vehicle Transfer',
        description = 'You have received a vehicle transfer document',
        type = 'inform'
    })
    
    SetTimeout(Config.DocumentExpiration, function()
        if pendingTransfers[documentID] then
            pendingTransfers[documentID] = nil
            
            exports['ox_lib']:notify(src, {
                title = 'Vehicle Transfer',
                description = 'Transfer expired',
                type = 'error'
            })
            
            exports['ox_lib']:notify(transferData.buyer.source, {
                title = 'Vehicle Transfer',
                description = 'Transfer expired',
                type = 'error'
            })
        end
    end)
end)

-- Buyer accepts transfer
RegisterNetEvent('mnc-transfervehicle:server:acceptTransfer', function(documentID, signature)
    local src = source
    local transfer = pendingTransfers[documentID]
    
    if not transfer then
        exports['ox_lib']:notify(src, {
            title = 'Vehicle Transfer',
            description = 'Transfer not found or expired',
            type = 'error'
        })
        return
    end
    
    if transfer.buyer ~= src then
        exports['ox_lib']:notify(src, {
            title = 'Vehicle Transfer',
            description = 'Unauthorized',
            type = 'error'
        })
        return
    end
    
    local Seller = QBCore.Functions.GetPlayer(transfer.seller)
    local Buyer = QBCore.Functions.GetPlayer(transfer.buyer)
    
    if not Seller or not Buyer then
        exports['ox_lib']:notify(src, {
            title = 'Vehicle Transfer',
            description = 'Transaction failed: Player disconnected',
            type = 'error'
        })
        pendingTransfers[documentID] = nil
        return
    end
    
    local data = transfer.data
    local amount = tonumber(data.amount) or 0
    
    local buyerCash = Buyer.Functions.GetMoney('cash')
    local buyerBank = Buyer.Functions.GetMoney('bank')
    local paymentMethod = 'cash'
    
    if amount > 0 then
        if buyerCash >= amount then
            paymentMethod = 'cash'
        elseif buyerBank >= amount then
            paymentMethod = 'bank'
        else
            exports['ox_lib']:notify(src, {
                title = 'Vehicle Transfer',
                description = 'Insufficient funds',
                type = 'error'
            })
            
            exports['ox_lib']:notify(transfer.seller, {
                title = 'Vehicle Transfer',
                description = 'Buyer has insufficient funds',
                type = 'error'
            })
            
            pendingTransfers[documentID] = nil
            return
        end
    end
    
    local targetcid = Buyer.PlayerData.citizenid
    local targetlicense = QBCore.Functions.GetIdentifier(Buyer.PlayerData.source, 'license')
    
    MySQL.update('UPDATE player_vehicles SET citizenid = ?, license = ? WHERE plate = ?', {
        targetcid,
        targetlicense,
        data.seller.plate
    })
    
    if amount > 0 then
        Seller.Functions.AddMoney(paymentMethod, amount, 'vehicle-sale')
        Buyer.Functions.RemoveMoney(paymentMethod, amount, 'vehicle-purchase')
    end
    
    TriggerClientEvent('vehiclekeys:client:SetOwner', transfer.buyer, data.seller.plate)
    
    data.buyerSignature = signature
    data.completedDate = os.date('%Y-%m-%d %H:%M:%S')
    data.paymentMethod = paymentMethod
    data.status = 'completed'
    
    local documentInfo = {
        documentID = documentID,
        documentData = data
    }
    
    Seller.Functions.AddItem('vehicletransdocument', 1, false, documentInfo)
    TriggerClientEvent('inventory:client:ItemBox', transfer.seller, QBCore.Shared.Items['vehicletransdocument'], 'add')
    
    Buyer.Functions.AddItem('vehicletransdocument', 1, false, documentInfo)
    TriggerClientEvent('inventory:client:ItemBox', transfer.buyer, QBCore.Shared.Items['vehicletransdocument'], 'add')
    
    if amount > 0 then
        exports['ox_lib']:notify(transfer.seller, {
            title = 'Vehicle Sold',
            description = 'Vehicle sold for ' .. comma_value(amount),
            type = 'success'
        })
        
        exports['ox_lib']:notify(transfer.buyer, {
            title = 'Vehicle Purchased',
            description = 'Vehicle purchased for ' .. comma_value(amount),
            type = 'success'
        })
    else
        exports['ox_lib']:notify(transfer.seller, {
            title = 'Vehicle Gifted',
            description = 'Vehicle gifted successfully',
            type = 'success'
        })
        
        exports['ox_lib']:notify(transfer.buyer, {
            title = 'Vehicle Received',
            description = 'Vehicle received as gift',
            type = 'success'
        })
    end
    
    pendingTransfers[documentID] = nil
    
    DebugPrint('Transfer completed: ' .. documentID)
end)

-- Buyer denies transfer
RegisterNetEvent('mnc-transfervehicle:server:denyTransfer', function(documentID)
    local src = source
    local transfer = pendingTransfers[documentID]
    
    if not transfer then
        exports['ox_lib']:notify(src, {
            title = 'Vehicle Transfer',
            description = 'Transfer not found or expired',
            type = 'error'
        })
        return
    end
    
    if transfer.buyer ~= src then
        exports['ox_lib']:notify(src, {
            title = 'Vehicle Transfer',
            description = 'Unauthorized',
            type = 'error'
        })
        return
    end
    
    exports['ox_lib']:notify(transfer.seller, {
        title = 'Vehicle Transfer',
        description = 'Buyer declined the transfer',
        type = 'error'
    })
    
    exports['ox_lib']:notify(transfer.buyer, {
        title = 'Vehicle Transfer',
        description = 'Transfer declined',
        type = 'inform'
    })
    
    pendingTransfers[documentID] = nil
    
    DebugPrint('Transfer denied: ' .. documentID)
end)

print("^2[mnc-transfervehicle]^7 Server loaded successfully!")
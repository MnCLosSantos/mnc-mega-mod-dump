-- config.lua
Config = {}

-- DEBUG
Config.Debug = false

-- =====================================================================
-- INSTALL SETTINGS
-- =====================================================================
Config.Installation = {
    requireMinigame = false,
    minigameMode = 'easy', -- Options: 'easy', 'medium'
    progressDuration = 25000,
    progressType = 'bar', -- circle or bar
    useAnimation = true,
    animDict = 'mini@repair',
    animClip = 'fixing_a_ped',
}

-- =====================================================================
-- SHOP LOCATIONS AND SETTINGS
-- =====================================================================
Config.EngineShops = {
     {
         title = "LSC Salvage",              -- Title in shop ui (fallback is "Engine shop" if not defined)
         location = vector3(-340.53, -141.85, 38.93),    -- Shop location 
         theme = "purple",                               -- Shop accent
         delivery = vector3(-358.95, -128.34, 38.71),    -- Delivery point for engine
         install = vector3(-329.75, -143.7, 39.06),      -- Install location
         jobs = {'mechanic', 'mechanic2', 'mechanic3'},  -- Job restriction 
         blip = {sprite = 446, color = 27, scale = 0.8, name = "LSC Salvage"} -- Blip settings (set to "= false," to disable)
     },
    -- {
        -- title = "Bennys Salvage",
        -- location = vector3(-195.71, -1317.36, 31.38),
        -- theme = "red",
        -- delivery = vector3(-218.88, -1320.64, 30.89),
        -- install = vector3(-214.9, -1317.3, 30.89),
        -- jobs = {'bennys'}, 
        -- blip = {sprite = 446, color = 1, scale = 0.8, name = "Bennys Salvage"}
    -- },
}


-- =====================================================================
-- ORDER SETTINGS
-- =====================================================================
Config.EnginePrice = 2500
Config.EngineDeliveryTime = 5000 -- 5 seconds for testing

-- =====================================================================
-- TOOL SETTINGS
-- =====================================================================
Config.RequiredItem = 'toolbox' -- set to "= false," for no item requirement

-- =====================================================================
-- ENGINE SOUNDS WITH CATEGORIES
-- =====================================================================
Config.EngineSounds = {
    {
        category = "Supercars",
        engines = {
            { name = "Adder", sound = "ADDER", price = 00, image = "https://img.gurugamer.com/resize/740x-/2021/09/14/truffade-adder-c54b.jpg", description = "Supercar V8" },
            { name = "Banshee", sound = "BANSHEE", price = 00, image = "https://th.bing.com/th/id/R.693d35ea519e33c16b2cf7556aab0f92?rik=CrFWD9%2bc6Xn5lg&riu=http%3a%2f%2fwww.gta5rides.com%2fvehicleimages%2fcropped%2fBanshee-GTAV-front.png.jpg&ehk=2I6JY0ReS5oscDQ0qL%2fzTZxpO6NJ8lLOItGtFs39k10%3d&risl=&pid=ImgRaw&r=0", description = "V10 sports car" },
            { name = "Bullet", sound = "BULLET", price = 00, image = "https://tse2.mm.bing.net/th/id/OIP.yhVCexDBeGl5XN0qyfeWIwHaEK?pid=ImgDet&w=474&h=266&rs=1&o=7&rm=3", description = "Classic supercar V8" },
            { name = "Cheetah", sound = "CHEETAH", price = 00, image = "https://th.bing.com/th/id/R.62e6a743a9e56599e72ec9ac899868e6?rik=kyPU7IecTuAQEA&riu=http%3a%2f%2fwww.gta5rides.com%2fvehicleimages%2fcropped%2fcheetah1.jpg.jpg&ehk=BbV0Qhci2SY85y2fRm7EnHrlii87xsx2fcCakHS8ATQ%3d&risl=&pid=ImgRaw&r=0", description = "Italian supercar V12" },
            { name = "Entity XF", sound = "ENTITYXF", price = 00, image = "https://www.breakflip.com/uploads/60c1d581e5375-vignette-gta-5-entity-xf-podium.jpg", description = "Exotic supercar V10" },
            { name = "Infernus", sound = "INFERNUS", price = 00, image = "https://th.bing.com/th/id/R.f2a513c8c6b02eb39824c26656a6ea33?rik=F9gmA%2bUyAEiHbg&pid=ImgRaw&r=0", description = "V12 supercar" },
            { name = "Osiris", sound = "OSIRIS", price = 00, image = "https://vignette.wikia.nocookie.net/de.gta/images/e/e9/Osiris_a1.jpg/revision/latest?cb=20150610203105", description = "Hypercar V8 engine" },
            { name = "T20", sound = "T20", price = 00, image = "https://tse2.mm.bing.net/th/id/OIP.xhZ7dtSfMRqEPrnLaJBaFQHaEK?rs=1&pid=ImgDetMain&o=7&rm=3", description = "Modern hypercar V10" },
            { name = "Turismo R", sound = "TURISMOR", price = 00, image = "https://tse3.mm.bing.net/th/id/OIP.xAFc4jozPGYCJdp-yAD18AHaEK?rs=1&pid=ImgDetMain&o=7&rm=3", description = "Ferrari-style V12" },
            { name = "Vacca", sound = "VACCA", price = 000, image = "https://oyster.ignimgs.com/mediawiki/apis.ign.com/grand-theft-auto-5/1/17/PegassiVacca-Front-GTAV.png", description = "Lamborghini-style V10" },
            { name = "Zentorno", sound = "ZENTORNO", price = 00, image = "https://tse4.mm.bing.net/th/id/OIP.9fIXknSfBwrvbYG5ew-quAHaEK?rs=1&pid=ImgDetMain&o=7&rm=3", description = "Aggressive V10" },
            { name = "Tyrus", sound = "TYRUS", price = 000, image = "https://gtacars.net/images/f1b11590e373f4dc4f0f2c9c1083c116", description = "Track-focused hypercar V8" },
            { name = "Reaper", sound = "REAPER", price = 00, image = "https://tse1.mm.bing.net/th/id/OIP.Rp_hS44h71OC2gbHCVePqQHaEK?rs=1&pid=ImgDetMain&o=7&rm=3", description = "Exotic supercar V12" },
            { name = "FMJ", sound = "FMJ", price = 000, image = "https://th.bing.com/th/id/R.c0d9d10bf7a6816c1f9802d0e60a1841?rik=kqli%2bgyiG9R5jQ&riu=http%3a%2f%2fcs1.gtaall.com%2fattachments%2f2016-06%2foriginal%2fe6f3f59a4506a05f736e8e20566024399ec83468%2f7369-GTA5-2016-06-14-15-32-15-42.jpg&ehk=t%2fjUQRCqI52UiWLniD4RjoxPYnc7qhGqybudNLkWeXM%3d&risl=&pid=ImgRaw&r=0", description = "Futuristic supercar V10" },
            { name = "Pfister 811", sound = "PFISTER811", price = 0000, image = "https://th.bing.com/th/id/R.23db30744328df7be1450b8fed69d1db?rik=HpPYatWSzYKUHw&riu=http%3a%2f%2fcs3.gtaall.net%2fattachments%2f2016-06%2foriginal%2f1d04d237f7cb13d60278efe52ed6a5f203a75b43%2f7412-GTA5-2016-06-30-09-29-15-30.jpg&ehk=EM2iCWZxxkX2nxWnps39U3cJ7u9HwEyHkC%2b2Ezxem4s%3d&risl=&pid=ImgRaw&r=0", description = "Supercar V8" },
			{ name = "SVJ", sound = "lamavgineng", price = 0000, image = "https://img.gta5-mods.com/q95/images/lamborghini-aventador-svj-roadster-oiv-template-21d457d6-3eaa-4fea-9aa0-94097bc9c457/09607a-sdfsgh.jpg", description = "Supercar V12" },
        }
    },
    {
        category = "Sports Cars",
        engines = {
            { name = "F620", sound = "F620", price = 000, image = "https://tse4.mm.bing.net/th/id/OIP.ihT5VMkHUiuDExzgJZFMcAHaEK?rs=1&pid=ImgDetMain&o=7&rm=3", description = "Luxury coupe V8" },
            { name = "Jester", sound = "JESTER", price = 000, image = "https://tse3.mm.bing.net/th/id/OIP.h0tfkHW7EtcZ747SlJA3LgHaEK?rs=1&pid=ImgDetMain&o=7&rm=3", description = "Tuner sports car inline-6" },
            { name = "Kuruma", sound = "KURUMA", price = 000, image = "https://tse3.mm.bing.net/th/id/OIP.Kjf9tCXyWSLtpDm3hJYiFQHaEK?rs=1&pid=ImgDetMain&o=7&rm=3", description = "Sports sedan inline-4" },
            { name = "Massacro", sound = "MASSACRO", price = 0000, image = "https://www.gamerzgateway.com/wp-content/uploads/2023/05/image.webp", description = "Sports car V8" },
            { name = "Sultan", sound = "SULTAN", price = 000, image = "https://tse2.mm.bing.net/th/id/OIP.J3JsbDNX5wMJhLJ7bfLUCgAAAA?rs=1&pid=ImgDetMain&o=7&rm=3", description = "Tuner sedan inline-4" },
            { name = "Sultan RS", sound = "SULTANRS", price = 000, image = "https://cs4.gtaall.com/screenshots/4dc09/2023-06/original/ff70a72f5655b7588c48e386fc64783cf39a6f61/1257308-GTA5-2023-06-03-16-45-14-787.jpg", description = "Tuner Sports Car inline-4" },
			{ name = "VR6", sound = "lgcy00vr6", price = 000, image = "https://ih1.redbubble.net/image.4400633868.3287/st,small,507x507-pad,600x600,f8f8f8.jpg", description = "Tuner Sports Car VR-6" },
			{ name = "R7.5", sound = "ea888", price = 000, image = "https://seeklogo.com/images/G/golf-r-logo-3F0DE5438A-seeklogo.com.png", description = "Tuner Sports Car Turbo Inline-4" },
			{ name = "2JZ", sound = "a80ffeng", price = 000, image = "https://ih0.redbubble.net/image.389066793.5605/raf,360x360,075,t,fafafa:ca443f4786.jpg", description = "Tuner Sports Car Turbo Inline-6" },
			{ name = "RB30", sound = "bnr34ffeng", price = 000, image = "https://www.rodshop.com.au/assets/full/rbconvlhuc.jpg?20210507131306", description = "Tuner Sports Car Turbo Inline-6" },
			{ name = "Rotary", sound = "str02213bt", price = 000, image = "https://www.wankelshop.com/images/product_images/original_images/angry_rotary_v_02_weiss.jpg", description = "Tuner Sports Rotary" },
			{ name = "4G63", sound = "st29b18cfnf", price = 000, image = "https://ih1.redbubble.net/image.268732840.1202/st,small,507x507-pad,600x600,f8f8f8.u4.jpg", description = "Tuner Sports Inline-4" },
			{ name = "EJ20", sound = "aq90subej207", price = 000, image = "https://res.cloudinary.com/teepublic/image/private/s--zmUjWDSm--/t_Preview/b_rgb:ffffff,c_lpad,f_jpg,h_630,q_90,w_1200/v1700973480/production/designs/53684495_0.jpg", description = "Tuner Sports Boxer-4" },
			{ name = "RS3 I5", sound = "aq66audea855", price = 000, image = "https://th.bing.com/th/id/R.9b27dbc956f3c18091a6bafc1d0e9093?rik=pJv0jSnPvpne9w&riu=http%3a%2f%2fdoorled.com%2fcdn%2fshop%2fproducts%2fIMG_3478_5ddb5f04-8caa-4923-a95c-7af60be1b420.jpg%3fv%3d1676381670&ehk=wSwHqXUHNbKTKbgqb%2fnV%2folbQI0x7GcTbeiYNcr3px4%3d&risl=&pid=ImgRaw&r=0", description = "Tuner Sports Inline-5" },
			{ name = "K20A", sound = "aq58honk20a", price = 000, image = "https://ih1.redbubble.net/image.1285250105.9953/st,small,507x507-pad,600x600,f8f8f8.jpg", description = "Tuner Sports Inline-4" },
			{ name = "I30N", sound = "aq36hyutheta2n", price = 000, image = "https://tse4.mm.bing.net/th/id/OIP.nvNa9Zi5R1XBLDxl3I8AxQHaHa?rs=1&pid=ImgDetMain&o=7&rm=3", description = "Tuner Sports Inline-4" },
        }
    },
    {
        category = "Muscle Cars",
        engines = {
            { name = "Gauntlet", sound = "GAUNTLET4", price = 000, image = "https://th.bing.com/th/id/R.f32966c3197463f04be8fee2c392e5b9?rik=3Vr1%2bTicdIskcQ&riu=http%3a%2f%2fwww.gta5rides.com%2fvehicleimages%2fcropped%2fGauntlet-GTAV-front.png.jpg&ehk=JppEEF5MlSh7vy%2bzQ3LewocMdXRIy2ltnv1uYBRhor4%3d&risl=&pid=ImgRaw&r=0", description = "Muscle car V8" },
            { name = "Dominator", sound = "DOMINATOR", price = 000, image = "https://tse4.mm.bing.net/th/id/OIP.Ts-22Q1vHYcgyEkkCdIq3gHaEK?rs=1&pid=ImgDetMain&o=7&rm=3", description = "Muscle car V8" },
            { name = "Ruiner", sound = "RUINER", price = 000, image = "https://th.bing.com/th/id/R.b654f0d7e328613fa18cd0dd62601403?rik=potRyTj%2fhIjbig&riu=http%3a%2f%2fvignette1.wikia.nocookie.net%2fde.gta%2fimages%2f9%2f9a%2fMehrBremsspuren!.jpg%2frevision%2flatest%3fcb%3d20150722090136&ehk=6MclsozkseOWn57jUEzOX%2fz3skrmBgCqqt024IPozhc%3d&risl=&pid=ImgRaw&r=0", description = "Muscle car V8" },
            { name = "Sabre Turbo", sound = "SABRETURBO", price = 000, image = "https://tse4.mm.bing.net/th/id/OIP.e-8nTQWMpafXEMimh2gEqAHaEI?rs=1&pid=ImgDetMain&o=7&rm=3", description = "Muscle car V8" },
            { name = "Vigero", sound = "VIGERO", price = 000, image = "https://i.redd.it/4pdretc94x331.jpg", description = "Classic muscle V8" },
            { name = "Phoenix", sound = "PHOENIX", price = 000, image = "https://vignette1.wikia.nocookie.net/es.gta/images/8/86/PhoenixFrontalGTAV.png/revision/latest?cb=20150610110435", description = "Muscle car V8" },
            { name = "Tampa", sound = "TAMPA", price = 000, image = "https://tse2.mm.bing.net/th/id/OIP.u9Ae2MJJBHeNbhdQDegeEgHaEK?rs=1&pid=ImgDetMain&o=7&rm=3", description = "Classic muscle V8" },
            { name = "Dukes", sound = "DUKES", price = 000, image = "https://th.bing.com/th/id/R.e4e2cbea2bb1fc5323ec352158120815?rik=zCXdLMAm50DU7w&pid=ImgRaw&r=0", description = "Classic muscle V8" },
            { name = "Blade", sound = "BLADE", price = 000, image = "https://oyster.ignimgs.com/mediawiki/apis.ign.com/grand-theft-auto-5/2/2d/GTA_V.720P.HD_Screencaps.3203.jpg", description = "Muscle car V8" },
            { name = "Faction", sound = "FACTION", price = 000, image = "https://th.bing.com/th/id/OIP.h3FuPVD2tH-Iejl0Pjm3SQHaEK?o=7rm=3&rs=1&pid=ImgDetMain&o=7&rm=3", description = "Custom muscle V8" },
            { name = "Nightshade", sound = "NIGHTSHADE", price = 000, image = "https://i.redd.it/n4ahed7ikae51.jpg", description = "Muscle car V8" },
            { name = "Slamvan", sound = "SLAMVAN", price = 000, image = "https://vignette.wikia.nocookie.net/de.gta/images/a/a2/SlamvanGTAVNextGen.png/revision/latest?cb=20141220203520", description = "Custom muscle V8" },
            { name = "Voodoo", sound = "VOODOO", price = 000, image = "https://th.bing.com/th/id/OIP.Gltdq3UOPATQ1vsYFzUPmAHaEK?o=7rm=3&rs=1&pid=ImgDetMain&o=7&rm=3", description = "Classic muscle V8" },
			{ name = "RedEye", sound = "lg81hcredeye", price = 000, image = "https://wallpapers.com/images/hd/dodge-hellcat-redeye-logo-ti7ug0fl0kkfkdq7.jpg", description = "Modern muscle V8" },
        }
    },
    {
        category = "Lowriders",
        engines = {
            { name = "Chino", sound = "CHINO", price = 000, image = "https://th.bing.com/th/id/R.43ec120cab4675ddc6fe1982f912a8ac?rik=3ooTca4vADj8zQ&riu=http%3a%2f%2fcs1.gtaall.com%2fattachments%2f2016-04%2foriginal%2fb605b4ce753eb2c510aef38b9509d509000dcfa9%2f7059-chino-custom-1.jpg&ehk=lbOP8oAHeWqq8BaLhtp08SB4HJ4SfmiDF6MPqhqsAfQ%3d&risl=&pid=ImgRaw&r=0", description = "Classic lowrider V8" },
            { name = "Buccaneer", sound = "BUCCANEER", price = 000, image = "https://cs3.gtaall.com/attachments/2015-06/original/c774ff9f7779b6b9e16c0af640d68ba6825f42af/4605-gta5-albany-buccaneer-front.jpg", description = "Classic lowrider V8" },
            { name = "Manana", sound = "MANANA", price = 000, image = "https://tse4.mm.bing.net/th/id/OIP.v_kcHD2Nn4quUpfAn7Nb-gHaEO?rs=1&pid=ImgDetMain&o=7&rm=3", description = "Classic lowrider V8" },
            { name = "Peyote", sound = "PEYOTE", price = 000, image = "https://i0.wp.com/img.gta5-mods.com/q95/images/improved-vapid-peyote/ed3809-grand_theft_auto_v_s_NoTNs.jpg", description = "Classic lowrider V8" },
            { name = "Virgo", sound = "VIRGO", price = 000, image = "https://tse1.mm.bing.net/th/id/OIP.duXs19VLHExPmxsQ6w0iJwHaEK?rs=1&pid=ImgDetMain&o=7&rm=3", description = "Classic lowrider V8" }
        }
    },
	{
        category = "Sports Classics",
        engines = {
            { name = "Stinger", sound = "STINGER", price = 000, image = "https://cs4.gtavicecity.ru/attachments/2015-06/original/27286cbf0d1ce03bd1689ce7e72b0850ed1d3b84/4632-gta5-stinger-front.jpg", description = "High-revving classic sports engine" },
            { name = "Stinger GT", sound = "STINGERGT", price = 00, image = "https://files.gtavillage.com/store/5bedcb499aa68fcab7b6c69c465d9fdf.jpeg", description = "Race-tuned GT classic V12" },
            { name = "Coquette Classic", sound = "COQUETTE2", price = 000, image = "https://tse2.mm.bing.net/th/id/OIP.fChGhGlZA626iMDClGEHZQHaEK?rs=1&pid=ImgDetMain&o=7&rm=3", description = "Retro American sports V8" },
            { name = "JB 700", sound = "JB700", price = 0000, image = "https://th.bing.com/th/id/R.a8fa82ea3b86cc70163c1fb8c9310fcf?rik=BLaBZJB5572Znw&riu=http%3a%2f%2fcs4.gtaall.com%2fattachments%2f2015-06%2foriginal%2ffae47e275a3f84b59e41320c03829580d26b9ac8%2f4608-gta5-jb700-front.jpg&ehk=hOcqN1jKaFpb7xlT2vaWp7qC2qBOv9zBGKRi9L44p70%3d&risl=&pid=ImgRaw&r=0", description = "Classic grand-tourer inline-6" },
            { name = "Pigalle", sound = "PIGALLE", price = 00, image = "https://vignette.wikia.nocookie.net/gtawiki/images/e/e9/Pigalle-GTAV-FrontQuarter.png/revision/latest?cb=20181129103748", description = "Vintage French performance V6" },
            { name = "Monroe", sound = "MONROE", price = 0000, image = "https://tse1.mm.bing.net/th/id/OIP.NFW6E4JZ16hZ84ZxDPDsjQHaEK?rs=1&pid=ImgDetMain&o=7&rm=3", description = "Classic supercar V12" },
            { name = "Casco", sound = "CASCO", price = 000, image = "https://vignette.wikia.nocookie.net/gtawiki/images/2/21/Casco-GTAO-FrontQuarter.png/revision/latest?cb=20161015131003", description = "Stylish classic Italian V12" },
            { name = "Retinue", sound = "RETINUE", price = 000, image = "https://gtacars.net/images/8800ac2dc3b1c9ebabce74aff3cfa1df", description = "Lightweight rally-style sports engine" },
            { name = "Turismo Classic", sound = "TURISMOC2", price = 00000, image = "https://tse1.mm.bing.net/th/id/OIP.CgSbAJArxAtwg5YfWl2J-AHaEO?rs=1&pid=ImgDetMain&o=7&rm=3", description = "Iconic classic supercar V12" },
            { name = "Z-Type", sound = "ZTYPE", price = 0000, image = "https://vignette2.wikia.nocookie.net/gtawiki/images/9/9d/Z-Type-GTAV-front.png/revision/latest?cb=20160917231447", description = "Legendary vintage performance V16" }
        }
    },

    {
        category = "Motorcycles",
        engines = {
            { name = "Bati", sound = "BATI", price = 000, image = "https://tse4.mm.bing.net/th/id/OIP.Ml-ZN40qBNIQLPVRKpHCngHaDx?rs=1&pid=ImgDetMain&o=7&rm=3", description = "Sport bike inline-4" },
            { name = "Akuma", sound = "AKUMA", price = 00, image = "https://tse2.mm.bing.net/th/id/OIP.a6keqBU9eOg6h4jDpNoEtAHaDx?rs=1&pid=ImgDetMain&o=7&rm=3", description = "Sport bike inline-4" },
            { name = "Hakuchou", sound = "HAKUCHOU", price = 00, image = "https://vignette1.wikia.nocookie.net/de.gta/images/3/3a/Hakuchou_a1.jpg/revision/latest?cb=20150617193558", description = "Sport bike inline-4" },
            { name = "Double T", sound = "DOUBLE", price = 000, image = "https://th.bing.com/th/id/R.a0a865c8cc3fa09f25541e7d60adf8a5?rik=bjG5VjxFjpAQJA&riu=http%3a%2f%2fwww.gta5rides.com%2fvehicleimages%2fcropped%2fdouble+t.jpg.jpg&ehk=BmVFQRK8%2bJ5vyLnxYxZM3OGvqco4chjMUSLULgiDqWw%3d&risl=&pid=ImgRaw&r=0", description = "Sport bike inline-4" },
            { name = "Vindicator", sound = "VINDICATOR", price = 00, image = "https://gta5car.com/wp-content/uploads/2015/07/Dinka-Vindicator-GTA-5-Side-View.jpg", description = "Sport bike inline-4" },
            { name = "Bagger", sound = "BAGGER", price = 000, image = "https://th.bing.com/th/id/OIP.yuwb9RAkN0ASVA0Iy9THiwHaEK?o=7rm=3&rs=1&pid=ImgDetMain&o=7&rm=3", description = "Cruiser V-twin" },
            { name = "Carbon RS", sound = "CARBONRS", price = 00, image = "https://tse1.mm.bing.net/th/id/OIP.Qo7wnvn6t15Io9wHVof4uAHaEK?rs=1&pid=ImgDetMain&o=7&rm=3", description = "Sport bike inline-4" },
            { name = "Sanchez", sound = "SANCHEZ", price = 00, image = "https://th.bing.com/th/id/R.f30a3cb93c5abf24a071b427f78225e1?rik=RXtdfc3TB3508w&riu=http%3a%2f%2fvignette4.wikia.nocookie.net%2fgtawiki%2fimages%2f4%2f46%2fSanchez-GTAV-front-Sprunk.png%2frevision%2flatest%3fcb%3d20160222221309&ehk=DOOgiVrz4TQeZlEyqU1yHFVhPrFBdudUJQNXPL30Du4%3d&risl=1&pid=ImgRaw&r=0", description = "Dirt bike 4-stroke" },
            { name = "Enduro", sound = "ENDURO", price = 00, image = "https://th.bing.com/th/id/R.7778a2bf6cdb02a635b50ac07f55a080?rik=hl%2f%2fLUReTH%2fXZg&riu=http%3a%2f%2fassets.vg247.com%2fcurrent%2f2015%2f03%2fgta_heists_vehicles-4.jpg&ehk=7busyNqJg6o6S2HOSOaUEV3j2YoxLZxfrtFUWLPxWm8%3d&risl=&pid=ImgRaw&r=0", description = "Dual-sport 2-stroke" },
            { name = "Faggio", sound = "FAGGIO", price = 000, image = "https://th.bing.com/th/id/R.9a37998e1a1ce8b9cfd2c72cd2d45c9c?rik=Tc6wrLpZQSglGw&riu=http%3a%2f%2fvignette1.wikia.nocookie.net%2fde.gta%2fimages%2fb%2fbe%2fFaggio_a1.jpg%2frevision%2flatest%3fcb%3d20150609003733&ehk=JJ3TsWyv2BIL30ZGoudeWb1NONxm%2bNNPi9WL0Z5VlvE%3d&risl=&pid=ImgRaw&r=0", description = "Scooter 2-stroke" },
            { name = "PCJ 600", sound = "PCJ600", price = 00, image = "https://tse2.mm.bing.net/th/id/OIP.F5GXVs6wdgT4bl25BFvvGQHaEK?rs=1&pid=ImgDetMain&o=7&rm=3", description = "Sport bike inline-4" },
            { name = "Ruffian", sound = "RUFFIAN", price = 00, image = "https://tse1.mm.bing.net/th/id/OIP.7WE6MPNOOLT0aBz8qFx1IQHaEK?rs=1&pid=ImgDetMain&o=7&rm=3", description = "Sport bike inline-4" },
            { name = "Nemesis", sound = "NEMESIS", price = 000, image = "https://vignette.wikia.nocookie.net/gtawiki/images/a/a7/Nemesis-GTAV-FrontQuarter.png/revision/latest?cb=20180328195005", description = "Sport bike inline-4" },
            { name = "Daemon", sound = "DAEMON", price = 00, image = "https://i.ytimg.com/vi/QpUwX_ar9B4/maxresdefault.jpg", description = "Chopper V-twin" },
            { name = "Hexer", sound = "HEXER", price = 00, image = "https://vignette.wikia.nocookie.net/gtawiki/images/6/64/Hexer-GTAV-front.png/revision/latest?cb=20160211212015", description = "Chopper V-twin" },
            { name = "Innovation", sound = "INNOVATION", price = 000, image = "https://i.ytimg.com/vi/d4CB4LDbRFY/maxresdefault.jpg", description = "Chopper V-twin" },
            { name = "Sovereign", sound = "SOVEREIGN", price = 00, image = "https://th.bing.com/th/id/OIP.RWvLggUx02SM8fVTzRrx4QHaEK?o=7rm=3&rs=1&pid=ImgDetMain&o=7&rm=3", description = "Cruiser V-twin" },
            { name = "Gargoyle", sound = "GARGOYLE", price = 000, image = "https://tse3.mm.bing.net/th/id/OIP.Ss11guW3VtuAftixwONtYwHaEK?rs=1&pid=ImgDetMain&o=7&rm=3", description = "Retro chopper V-twin" },
            { name = "Thrust", sound = "THRUST", price = 000, image = "https://tse3.mm.bing.net/th/id/OIP.DMXdvtCTc7xSxSj6COzE9QHaEK?rs=1&pid=ImgDetMain&o=7&rm=3", description = "Modern cruiser V-twin" },
            { name = "Wolfsbane", sound = "WOLFSBANE", price = 00, image = "https://th.bing.com/th/id/R.100124009e261b24730289698cc70a14?rik=lEBLK8IkoLbDPg&pid=ImgRaw&r=0", description = "Classic chopper V-twin" },
			{ name = "S1000RR", sound = "kc74s1000rrakevoline", price = 00, image = "https://img.gta5-mods.com/q95/images/2020-bmw-s1000rr-addon-livery-tuning/fc25b5-106297615_2877568325687824_6174613639836544278_o.jpg", description = "Sports bike engine" },
			{ name = "ZX10R", sound = "kc144kawazx10rsc", price = 00, image = "https://img.gta5-mods.com/q95/images/zx-10r-se-edition/febdc7-EVE-20191201102435.010.jpg", description = "Sports bike engine" },
			{ name = "GXR1000R", sound = "suzukigsxr1k", price = 00, image = "https://img.gta5-mods.com/q95/images/suzuki-gsx-r-1000-engine-sound-oiv-addon-fivem/ed22d4-titleimg.jpg", description = "Sports bike engine" },
        }
    },
    {
        category = "Sedans",
        engines = {
            { name = "Buffalo", sound = "BUFFALO", price = 000, image = "https://tse4.mm.bing.net/th/id/OIP.l1-2zNMcxHtj7WcVMrZa4QHaEK?rs=1&pid=ImgDetMain&o=7&rm=3", description = "Sports sedan V8" },
            { name = "Schafter", sound = "SCHAFTER4", price = 00, image = "https://lh4.googleusercontent.com/6ePLD9XuaMTRPppWuIJ-RQrI-1bAXO7xmlFcNtiWdIVKx4Qj0cchsfQMfqyyVU31Pid1wflUtpS1PM6HWV5-hi4UTxJCzFDDeLi5zhDYBb6Hx8ZRY6N0VNJPc-wnsEig99ezfk71NccUrz-u5leltNs", description = "Luxury sedan V6" },
            { name = "Tailgater", sound = "TAILGATER", price = 00, image = "https://tse4.mm.bing.net/th/id/OIP.hsG-MnLmy-HCRTUnXRzIaAHaEK?rs=1&pid=ImgDetMain&o=7&rm=3", description = "Executive sedan V6" },
            { name = "Warrener", sound = "WARRENER", price = 00, image = "https://th.bing.com/th/id/R.d3181938e5f82fd339ec3d8b0e7b6800?rik=KHkzwNQJ78ptmA&riu=http%3a%2f%2fwww.gta5rides.com%2fvehicleimages%2fcropped%2fWarrener-GTAV-front.png.jpg&ehk=%2fW2G0qdzDu5TgcWPXF%2f3VlMNmboHaVCoqqyIu4EnIiQ%3d&risl=&pid=ImgRaw&r=0", description = "Retro sedan inline-4" },
            { name = "Stratum", sound = "STRATUM", price = 00, image = "https://tse4.mm.bing.net/th/id/OIP.CwSc-vOb0rVAzS3_2SBQLQAAAA?rs=1&pid=ImgDetMain&o=7&rm=3", description = "Classic wagon inline-6" },
            { name = "Ingot", sound = "INGOT", price = 000, image = "https://th.bing.com/th/id/R.4b6cad4c414a7f870747e527a2fb316c?rik=oGTu2sXRRiUmBg&riu=http%3a%2f%2fwww.gta5rides.com%2fvehicleimages%2fcropped%2fIngot-GTAV-front.png.jpg&ehk=89PHsAwKWjNa0xH0%2bDZIahZgX7PIKymTgmoIgNOmRsU%3d&risl=&pid=ImgRaw&r=0", description = "Family wagon inline-4" },
            { name = "Premier", sound = "PREMIER", price = 00, image = "https://tse3.mm.bing.net/th/id/OIP.Nw03tnZvXj4uIp2E-vfi_wHaEK?rs=1&pid=ImgDetMain&o=7&rm=3", description = "Compact sedan inline-4" },
            { name = "Asterope", sound = "ASTEROPE", price = 00, image = "https://cs4.gtaall.com/attachments/2015-04/original/0eedcf75181e3ef56be2485c6d9f2fded162a09c/3349-karin-asterope.jpg", description = "Mid-size sedan V6" },
            { name = "Fugitive", sound = "FUGITIVE", price = 00, image = "https://i.redd.it/t6nv2jr1sfcc1.jpeg", description = "Sport sedan V6" },
            { name = "Glendale", sound = "GLENDALE", price = 00, image = "https://vignette2.wikia.nocookie.net/gtawiki/images/4/47/Glendale-GTAV-front.png/revision/latest?cb=20150530113232", description = "Classic sedan V6" },
            { name = "Regina", sound = "REGINA", price = 00, image = "https://tse2.mm.bing.net/th/id/OIP.5EyNtwUPnIBG88Wa9hjnswHaEK?rs=1&pid=ImgDetMain&o=7&rm=3", description = "Vintage wagon V6" },
            { name = "Washington", sound = "WASHINGTON", price = 00, image = "https://tse4.mm.bing.net/th/id/OIP.GFUL-yiOQQ7FrLjJFJRAcQHaEK?rs=1&pid=ImgDetMain&o=7&rm=3", description = "Luxury sedan V8" },
            { name = "Primo", sound = "PRIMO", price = 00, image = "https://th.bing.com/th/id/R.a85576561dc03690ffc08087da078f4d?rik=1Inglv9sao4V7A&pid=ImgRaw&r=0", description = "Mid-size sedan V6" },
            { name = "Stanier", sound = "STANIER", price = 00, image = "https://img.gta5-mods.com/q95/images/dlc-add-on-2005-lssd-vapid-stanier/e7b4f7-Screenshotxcfvdxs.png", description = "EX-police V6" },
            { name = "Asea", sound = "ASEA", price = 000, image = "https://img.gta5-mods.com/q95/images/declasse-asea-custom-add-on-tuning/11cafe-gtau_asea(3).jpg", description = "Compact sedan inline-4" },
            { name = "Surge", sound = "SURGE", price = 00, image = "https://cs3.gtaall.com/attachments/2015-04/original/00048a56e5cde76430d20d131692a30a455d2c4b/3359-cheval-surge.jpg", description = "Electric sedan" },
            { name = "Cognoscenti", sound = "COGNOSCENTI", price = 000, image = "https://tse4.mm.bing.net/th/id/OIP.Bw6kDhQBPvqBEnC3miCKnAHaEy?rs=1&pid=ImgDetMain&o=7&rm=3", description = "Luxury sedan V8" },
            { name = "Oracle", sound = "ORACLE", price = 00, image = "https://tse4.mm.bing.net/th/id/OIP.REUcwGZ5F8S7-nU76HkkrgHaEK?rs=1&pid=ImgDetMain&o=7&rm=3", description = "Executive sedan V6" },
            { name = "Intruder", sound = "INTRUDER", price = 00, image = "https://tse3.mm.bing.net/th/id/OIP.2WrpAfdKs2fiGRw8FyzgVQHaEf?rs=1&pid=ImgDetMain&o=7&rm=3", description = "Sport sedan inline-6" },
            { name = "Felon", sound = "FELON", price = 00, image = "https://vignette.wikia.nocookie.net/gtawiki/images/4/4f/Felon-GTAV-FrontQuarter.png/revision/latest?cb=20180331162722", description = "Luxury sport sedan V6" },
            { name = "Jackal", sound = "JACKAL", price = 00, image = "https://tse3.mm.bing.net/th/id/OIP.XUziX6Y1a4oGtba4btvFHwHaEK?rs=1&pid=ImgDetMain&o=7&rm=3", description = "Sport sedan V6" },
			{ name = "S85", sound = "aq77bmws85", price = 000, image = "https://media.licdn.com/dms/image/v2/C4D0BAQFcjYGPKnmBUA/company-logo_200_200/company-logo_200_200/0/1649237293563/sport85srl_logo?e=2147483647&v=beta&t=LuEc1amVd4vDx4va50DTyB_9PRKGAC4IeJnZ4ECoGEs", description = "Tuner Sports V-10" },
			{ name = "C63", sound = "mbnzc63eng", price = 000, image = "https://img.gta5-mods.com/q95/images/mercedes-benz-c63-amg-vadims/f78781-GTA5%202016-08-15%2001-53-16-835.jpg", description = "Tuner Sports V-8" },
        }
    },
    {
        category = "Offroad",
        engines = {
            { name = "Brawler", sound = "BRAWLER", price = 000, image = "https://th.bing.com/th/id/R.0d207e28d6d76e066c271b5a073b14e8?rik=8PpfeKSHHp46MQ&pid=ImgRaw&r=0", description = "Offroad V8" },
            { name = "Sandking", sound = "SANDKING", price = 000, image = "https://vignette.wikia.nocookie.net/de.gta/images/a/a6/Sandking_xl_a1.jpg/revision/latest?cb=20150516225008", description = "Heavy-duty offroad V8" },
            { name = "Rebel", sound = "REBEL", price = 000, image = "https://tse2.mm.bing.net/th/id/OIP.q5J1TJBaKzFQWvglI326IwHaEK?rs=1&pid=ImgDetMain&o=7&rm=3", description = "Rugged offroad V6" },
            { name = "Rancher XL", sound = "RANCHERXL", price = 000, image = "https://gtwfilesie-thumb.grandtheftwiki.com/RancherXL-GTAV-front.jpg/600px-RancherXL-GTAV-front.jpg", description = "Classic offroad V6" },
            { name = "Bifta", sound = "BIFTA", price = 000, image = "https://cs3.gtaall.com.br/attachments/2015-06/original/6c5054bc33e5c8d7c72d0d95d6d5a4b812eff9a1/4778-gta5-bifta-front.jpg", description = "Light offroad inline-4" },
            { name = "Bodhi", sound = "BODHI", price = 000, image = "https://th.bing.com/th/id/R.b5faf240297d4f37f82ccec8f0b4d2fe?rik=gc1Tiql0aIzqjA&riu=http%3a%2f%2fwww.gta5rides.com%2fvehicleimages%2fcropped%2fBodhi-GTAV-front.png.jpg&ehk=vB38nM5SpQ1rLXAc2tdNFuMS%2bjl1mC5gCuLaCapiC%2fo%3d&risl=&pid=ImgRaw&r=0", description = "Vintage offroad V8" },
            { name = "Kalahari", sound = "KALAHARI", price = 000, image = "https://tse1.mm.bing.net/th/id/OIP.yDM8UgW3jlJTuahS3dvpdAHaEK?rs=1&pid=ImgDetMain&o=7&rm=3", description = "Compact offroad inline-4" },
            { name = "Trophy Truck", sound = "TROPHYTRUCK", price = 000, image = "https://tse3.mm.bing.net/th/id/OIP.tOwsVZs9T1UWQAPHUvpkbQHaEK?rs=1&pid=ImgDetMain&o=7&rm=3", description = "Race-ready offroad V8" },
            { name = "Desert Raid", sound = "MONSTER", price = 000, image = "https://tse1.mm.bing.net/th/id/OIP.kBv69Mfu31KxXgRqSgOnnQHaEK?rs=1&pid=ImgDetMain&o=7&rm=3", description = "Desert race truck V8" },
			{ name = "Winky", sound = "WINKY", price = 000, image = "https://tse4.mm.bing.net/th/id/OIP.WPHKN0g6XlmSNIkhAsWqLwHaEK?rs=1&pid=ImgDetMain&o=7&rm=3", description = "Old School Jeep" },
			{ name = "12V B series", sound = "tacumminsb", price = 000, image = "https://logos-world.net/wp-content/uploads/2021/08/Cummins-Symbol.png", description = "12 Valve" },
			{ name = "M57", sound = "aq96bmwb57", price = 000, image = "https://www.stickersplt.com.ua/wp-content/uploads/2024/01/1-45-324x324.png", description = "Deisel Turbo Inline-6" },
        }
    },
    {
        category = "Commercial",
        engines = {
            { name = "Mule", sound = "MULE", price = 000, image = "https://th.bing.com/th/id/R.f253086e234420bba2606e172e63ce6c?rik=6tL%2baibue9wshA&pid=ImgRaw&r=0", description = "Commercial van V6" },
            { name = "Boxville", sound = "BOXVILLE", price = 000, image = "https://tse2.mm.bing.net/th/id/OIP.pBHhzVRp04gNmTOKDteTbQHaEK?rs=1&pid=ImgDetMain&o=7&rm=3", description = "Delivery van V6" },
            { name = "Stockade", sound = "STOCKADE", price = 000, image = "https://tse4.mm.bing.net/th/id/OIP.UXXYvuZstUAqlhbQvblchwHaEK?rs=1&pid=ImgDetMain&o=7&rm=3", description = "Armored van V8" },
            { name = "Pounder", sound = "POUNDER", price = 000, image = "https://tse1.mm.bing.net/th/id/OIP.gBX3HBGR2p0GBj3tm4VZowAAAA?rs=1&pid=ImgDetMain&o=7&rm=3", description = "Heavy commercial truck V8" },
            { name = "Scania DC Series", sound = "kc98gmls6", price = 000, image = "https://i.pinimg.com/originals/12/88/7e/12887e1469052c0f9873ac8fe8008150.jpg", description = "Heavy commercial Deisel V8" },
        }
    },
    {
        category = "Formula",
        engines = {
            { name = "BR8", sound = "openwheel1", price = 0000, image = "https://tse1.mm.bing.net/th/id/OIP.g0qK46Ogq1ovJGnyFtrHnQHaEK?rs=1&pid=ImgDetMain&o=7&rm=3", description = "Formula-style V6" },
            { name = "DR1", sound = "openwheel2", price = 0000, image = "https://tse2.mm.bing.net/th/id/OIP.vvita5gOCBRzFymk83Qg7QHaEK?rs=1&pid=ImgDetMain&o=7&rm=3", description = "Openwheel race V6" },
            { name = "PR4", sound = "formula", price = 0000, image = "https://tse4.mm.bing.net/th/id/OIP.TnYcAg8gwA1SUrpbYzYpCgHaEK?rs=1&pid=ImgDetMain&o=7&rm=3", description = "Formula-inspired V6" },
            { name = "R88", sound = "formula2", price = 0000, image = "https://i.ytimg.com/vi/-KAK2GF_5-A/maxresdefault.jpg", description = "Modern openwheel V6" }
        }
    }
}
# 🚗 Vehicle Catalogue (QB-Core / QB-OX Compatible)

An advanced **UI-based vehicle catalogue** for FiveM servers, supporting **addon vehicles** and featuring **5 customizable UI styles**.  
Works with **qb-core** and **qb-ox** frameworks, including support for dealership zones (like PDM, Luxury Autos, etc.).

---

## ✨ Features

- 🔑 **Admin Command**: Open full catalogue with all vehicles.  
- 🎨 **5 Advanced UI Styles**: Dark Modern, Light Clean, Neon Night, Retro, and Oceanic glass themes.  
- 🏪 **Dealership Zones**: Set up multiple dealerships (PDM, Luxury Autos, etc.) with unique UI styling and titles.  
- ➕ **Addon Vehicle Support**: Automatically detects custom/addon vehicles.  
- 🔎 **Search & Filter**: Built-in search bar with category filtering.  
- ⚙️ **Target / Keypress Support**: Choose between `qb-target` interaction or `E` keypress.  
- 👥 **Admin Groups**: Restrict admin catalogue command to specific groups.  

---

## ⚙️ Configuration

All configuration is managed inside `config.lua`.

### 🔹 Command & Admin Groups
```lua
Command = 'vehiclecatalog', -- Command to open UI with all vehicles
AdminGroups = {'group.admin'}, -- Groups allowed to use the command
```

### 🔹 Interaction
```lua
UseTarget = true, -- true = qb-target, false = E keypress
```

### 🔹 Dealership Zones
```lua
Zones = {
    {
        name = 'pdm', -- Dealership name from qb-vehicleshop
        coords = vector3(-55.57, -1097.99, 26.42),
        radius = 3.0,
        uiStyle = 'style1', -- Choose from style1 - style5
        title = 'PDM Deluxe Catalogue',
        useAnywhere = false,
    },
    {
        name = 'luxury',
        coords = vector3(937.44, -970.88, 39.49),
        radius = 5.0,
        uiStyle = 'style2',
        title = 'Luxury Autos',
        useAnywhere = false,
    },
}
```

### 🔹 UI Styles
There are **5 built-in UI themes**:
- `style1` 
- `style2` 
- `style3`
- `style4` 
- `style5` 

Each style has customizable **backgrounds, accent colors, text colors, borders, and blur effects**.

---

## 📦 Installation

1. Download or clone this resource into your `resources` folder.
2. Add the following line to your `server.cfg`:
   ```
   ensure mnc-vehiclecatalog
   ```
3. Configure zones, UI styles, and command in `config.lua`.

---

## 🖥️ Usage

- **Admins**:  
  Run the command `/vehiclecatalog` (restricted by groups in `Config.AdminGroups`).  

- **Players**:  
  Interact with a dealership zone (via `qb-target` or `E` keypress depending on config).  

- **UI**:  
  - Search vehicles using the search bar.  
  - Browse categories in the sidebar. 

---

## 🛠️ Dependencies

- [qb-core](https://github.com/qbcore-framework/qb-core) or [ox_core](https://overextended.dev/)  
- [qb-target](https://github.com/qbcore-framework/qb-target) *(optional if `UseTarget = true`)*  

---

## 📌 Notes

- Supports **any addon vehicles** added to your server.  
- Works alongside **qb-vehicleshop** and other dealership scripts.  
- Each dealership can use a **different UI style** for variety.  

---

## 📷 Preview
---

- Style 1
<img width="1920" height="1080" alt="FiveM® by Cfx re - Midnight Club Los Santo's 21_08_2025 03_52_26" src="https://github.com/user-attachments/assets/3ff2df74-8102-4614-b8b8-c23634641ee9" />

---

- Style 2
<img width="1920" height="1080" alt="FiveM® by Cfx re - Midnight Club Los Santo's 21_08_2025 03_52_51" src="https://github.com/user-attachments/assets/afef53d9-309f-4146-851e-d8cd97665ceb" />

---

- Style 3
<img width="1920" height="1080" alt="FiveM® by Cfx re - Midnight Club Los Santo's 21_08_2025 03_53_12" src="https://github.com/user-attachments/assets/edd59fe4-9a45-4763-aaa8-5609553ae05c" />

---

- Style 4
<img width="1920" height="1080" alt="FiveM® by Cfx re - Midnight Club Los Santo's 21_08_2025 03_53_36" src="https://github.com/user-attachments/assets/666ff901-28eb-46e4-95a2-a57d6fe31e98" />

---

- Style 5
<img width="1920" height="1080" alt="FiveM® by Cfx re - Midnight Club Los Santo's 21_08_2025 03_54_02" src="https://github.com/user-attachments/assets/19eb9541-09c6-4caa-bbbe-2eb2b4407ac0" />

---

- Admin command
<img width="1920" height="1080" alt="FiveM® by Cfx re - Midnight Club Los Santo's 21_08_2025 03_54_57" src="https://github.com/user-attachments/assets/564a9700-872f-41a7-aa04-b72761905401" />

---

- Addon Support ("500x500" image size is best)
<img width="1920" height="1080" alt="FiveM® by Cfx re - Midnight Club Los Santo's 21_08_2025 03_55_13" src="https://github.com/user-attachments/assets/aced40ed-2a73-4e51-839f-579d74f5795f" />

---

- Qb-target
<img width="1920" height="1080" alt="FiveM® by Cfx re - Midnight Club Los Santo's 21_08_2025 03_55_52" src="https://github.com/user-attachments/assets/e6004485-1d85-48bb-8d65-adfa06dec0c9" />

---

## 👨‍💻 Credits

- Developed by:  **Stan Leigh**
- Support:       **https://discord.gg/cNVKQjNmtE**
- Built for:     **QB-Core / QB-OX FiveM Servers**  

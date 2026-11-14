local PLAYER_CLASS = hg.player_class
local CLASS_SELECTOR = hg.class_selector
local DERMA = hg.derma

local sizeX, sizeY = ScrW() * 0.75, ScrH() * 0.75
local gap = 8

local colors = {}
colors.mainBG = Color(25,25,30,220)
colors.secondary = Color(25,25,35,195)
colors.mainText = Color(120,35,35)
colors.secondaryText = Color(145, 145, 145, 125)
colors.highlightText = Color(145, 145, 145, 225)
colors.selectionBG = Color(155,0,0,240)
colors.presetBG = Color(35,35,45,220)
colors.border = Color(155,0,0,240)
colors.presetHover = Color(50,50,65,150)
colors.scrollbarBG = Color(20,20,30,200)
colors.scrollbarGrip = Color(70,70,90,255)
colors.scrollbarGripHover = Color(100,100,130,255)
colors.scrollbarBorder = Color(100,100,120,200)
colors.previewBorder = Color(255,200,50,255)

local elements = {  }

local function DrawClassCBox(parent)
    local colors = { 
        bg = colors.mainBG, 
        highlightBg = colors.selectionBG, 
        textColor = colors.mainText, 
        highlightText = colors.highlightText,
        border = colors.border }
    
    local classCBox 
        = DERMA.CreateStyledCBox(
            parent, 
            "Select Class", 
            "HomigradFontMedium", 
            colors)
    
    local classes = PLAYER_CLASS:GetAll()
    for classID, class in pairs(classes) do 
        if classID == "default" then continue end

        local enabled = CLASS_SELECTOR:IsClassEnabled(classID)
        if not enabled then continue end

        classCBox:AddChoice(class.className, classID)
    end

    local subClassCBox 
        = DERMA.CreateStyledCBox(
            parent, 
            "Select Sub Class", 
            "HomigradFontMedium", 
            colors)
    subClassCBox:SetEnabled(false)

    classCBox.OnSelect = function(self, index, value, data)
        local classID = data
        local subClasses 
            = PLAYER_CLASS:GetClass(classID).subClasses

        subClassCBox:Clear()
        subClassCBox:SetValue("Select Sub-Class")

        subClassCBox:SetEnabled(true)
        for subClass, _ in pairs(subClasses) do 
            local enabled = CLASS_SELECTOR:GetEnabledFor(classID, subClass)
            if not enabled then continue end

            subClassCBox:AddChoice(
                string.NiceName(subClass), subClass)
        end
    end

    elements.class = classCBox
    elements.subClass = subClassCBox

    DERMA.ChildrenFitWidth(parent, gap / 2)
end

local function DrawViewer(parent) 
    local viewer = vgui.Create("DModelPanel", parent)
    viewer:Dock(FILL)
    
    viewer.LayoutEntity = function(self, entity) return end

    elements.viewer = viewer

    return viewer
end

local function DrawTaglineCBox(parent)
    local colors = { 
        bg = colors.mainBG, 
        highlightBg = colors.selectionBG, 
        textColor = colors.mainText, 
        highlightText = colors.highlightText,
        border = colors.border }

    local classCBox = elements.class
    local subClassCBox = elements.subClass
    DERMA.HookPanelMethod(subClassCBox, "OnSelect", function(self, index, value, data)
        local className, classID = classCBox:GetSelected()
        local class = PLAYER_CLASS:GetClass(classID)
        local subClass = data

        elements.tagline = nil
        elements.squad = nil
        parent:Clear()
        
        ---@type CLASS_TAGLINES
        local tagLines = class:GetModule("class_taglines")
        local tags
        if tagLines then 
            local tagLineCBox = DERMA.CreateStyledCBox(
                parent, 
                "Select your Tagline", 
                "HomigradFontMedium", 
                colors)

            
            tags = class:GetSubConfig("tags", subClass)
            for _, tag in ipairs(tags.tags) do 
                tagLineCBox:AddChoice(string.NiceName(tag), tag)
            end

            elements.tagline = tagLineCBox
        end

        ---@type CLASS_SQUADS
        local squads = class:GetModule("class_squads")
        if squads then 
            local squadCBox = DERMA.CreateStyledCBox(
                parent, 
                "Select your Squad", 
                "HomigradFontMedium", 
                colors)
            
            squadCBox.OnSelect = function(self, index, value, data)
                if not elements.tagline then return end
                local tagLineCBox = elements.tagline

                tagLineCBox:Clear()
                tagLineCBox:SetValue("Select Your Tagline")
                if data == "new" then 
                    local tags = tags.leaderTags or tags.tags
                    for _, tag in ipairs(tags) do 
                        tagLineCBox:AddChoice(string.NiceName(tag), tag)
                    end
                else 
                    for _, tag in ipairs(tags.tags) do 
                        tagLineCBox:AddChoice(string.NiceName(tag), tag)
                    end
                end
            end

            local callSigns = squads:GetAllCallSigns()
            DERMA.PopulateComboBox(squadCBox, callSigns)
            squadCBox:AddChoice("Make New Squad", "new", table.Count(callSigns) <= 0)

            elements.squad = squadCBox
        end

        DERMA.ChildrenFitWidth(parent, gap / 2)
    end)
end

---@param parent Panel
local function CreateLeftContainer(parent) 

    local leftContainer = vgui.Create("DPanel", parent)
    leftContainer:Dock(LEFT)
    leftContainer:DockMargin(0, 0, gap, 0)
    leftContainer:SetWide(parent:GetWide() * 0.4)
    function leftContainer:Paint(w, h) return end

    ---Top left container contains the buttons which switch the class.
    local topLeftContainer = vgui.Create("DPanel", leftContainer)
    topLeftContainer:Dock(TOP)
    topLeftContainer:DockMargin(0, gap / 4 - 1, 0, gap / 2)
    topLeftContainer:SetSize(1, parent:GetTall() * 0.075)
    function topLeftContainer:Paint(w, h) return end

    DrawClassCBox(topLeftContainer)

    DrawViewer(leftContainer)

    local bottomLeftContainer = vgui.Create("DPanel", leftContainer)
    bottomLeftContainer:Dock(BOTTOM)
    bottomLeftContainer:DockMargin(0, gap / 2, 0, gap / 4 - 1)
    bottomLeftContainer:SetTall(parent:GetTall() * 0.075)
    function bottomLeftContainer:Paint(w, h) return end

    DrawTaglineCBox(bottomLeftContainer)
end

local function DrawPointsLabel(parent, prefix, initialTotal, initialLimit)
    local colors = { bg = colors.mainBG, textColor = colors.mainText, border = colors.border }

    local label 
        = DERMA.CreateStyledLabel(
            parent,
            prefix,
            "HomigradFontBig",
            colors)
    label:SetContentAlignment(5)

    local classCBox = elements.class
    local subClassCBox = elements.subClass
    DERMA.HookPanelMethod(subClassCBox, "OnSelect", function(self, index, value, data)
        local className, classID = classCBox:GetSelected()
        local subClass = data

        label:SetLimit(CLASS_SELECTOR:GetPointsFor(classID, subClass))
    end)

    label.prefix = prefix or "Points"
    label.total = initialTotal or 0
    label.limit = initialLimit or 0

    local function UpdateText(self)
        self:SetText(string.format("%s: %d/%d", self.prefix, self.total, self.limit))
    end

    label.IsOverLimit = function(self) 
        return self.total > self.limit
    end

    label.SetTotal = function(self, val)
        self.total = val
        UpdateText(self)
    end

    label.SetLimit = function(self, val)
        self.limit = val
        UpdateText(self)
    end

    ---@type table<string, function>
    label.updateFuncs = {}
    label.RecalculatePoints = function(self)
        local total = 0
        for _, func in pairs(self.updateFuncs) do
            total = total + (func() or 0)
        end

        self:SetTotal(total)
    end

    UpdateText(label)

    elements.limit = label
end

---@param parent? Panel
local function DrawAppearancePanel(parent) 
    local colors = { bg = colors.mainBG, highlightBg = colors.selectionBG, textColor = colors.mainText, border = colors.border }

    local appearancePanel 
        = DERMA.CreateStyledPanel(
            parent, 
            "HomigradFontMedium", 
            colors, 
            gap)

    elements.armor = {}
    elements.armorRender = nil

    local classCBox = elements.class
    local subClassCBox = elements.subClass
    local viewer = elements.viewer
    local limit = elements.limit
    limit.updateFuncs.armor = nil
    DERMA.HookPanelMethod(subClassCBox, "OnSelect", function(self, index, value, data)
        local className, classID = classCBox:GetSelected()
        local class = PLAYER_CLASS:GetClass(classID)
        local subClass = data
        
        appearancePanel:Clear()
        local appearances = class:GetModule("class_appearance")
        local squad = elements.squad
        if appearances then
            appearances = appearances:GetClassAppearances(class, subClass)
            viewer:SetModel("")
            viewer.playerColor = appearances.color

            appearancePanel.AddOption.Label("Models")
            local modelPanel = appearancePanel.AddOption.Panel()

            local modelCombo = modelPanel.AddOption.ComboBox("Model")
            modelCombo:SetValue("Select your Model")

            local models = appearances.models
            for modelPath, modelData in pairs(models) do 
                modelCombo:AddChoice(modelData.name, modelPath)
            end

            if squad then
                DERMA.HookPanelMethod(squad, "OnSelect", function(self, index, value, data)
                    modelCombo:Clear()

                    modelCombo:SetValue("Select your Model")
                    models = data == "new" and appearances.leaderModels or appearances.models
                    for modelPath, modelData in pairs(models) do 
                        modelCombo:AddChoice(modelData.name, modelPath)
                    end
                end)
                squad:OnSelect(nil, squad:GetSelected())
            end

            modelCombo.OnSelect = function(self, index, value, data)
                local modelPath = data

                DERMA.ClearExceptIndex({[1] = true}, modelPanel)

                viewer:SetModel(modelPath)
                local model = viewer:GetEntity()
                model:SetAngles(Angle(0, 45, 0))

                local modelData = models[modelPath]
                local skinSlider 
                    = modelPanel.AddOption.Slider("Skin", 0, model:SkinCount() - 1)
                skinSlider.OnValueChanged = function(self, value)
                    model:SetSkin(value)
                end
                if modelData.skin then 
                    skinSlider:SetValue(modelData.skin)
                    skinSlider:SetEnabled(false)
                end

                for i = 1, model:GetNumBodyGroups() - 1 do
                    local bodygroupName = model:GetBodygroupName(i)
                    local bodygroupCount = model:GetBodygroupCount(i) - 1
                    
                    local slider 
                        = modelPanel.AddOption.Slider(bodygroupName, 0, bodygroupCount)
                    slider.OnValueChanged = function(self, value)
                        model:SetBodygroup(i, value)
                    end
                    if modelData.bodygroups[i] then
                        local value = modelData.bodygroups[i]
                        slider:SetValue(value)
                        slider:SetEnabled(false)
                    end
                end

                viewer.mats = nil
                if modelData.mats then 
                    for subMaterial, material in pairs(modelData.mats) do 
                        local subMatID = model:GetSubMaterialIdByName(subMaterial)
                        model:SetSubMaterial(subMatID, material)
                    end
                    viewer.mats = modelData.mats
                end
                

                modelPanel:InvalidateLayout(true)
                modelPanel:SizeToChildren(false, true)
                appearancePanel:InvalidateLayout(true)
            end
        end

        local loadout = class:GetModule("class_loadouts")
        local config = loadout and class:GetSubConfig("loadouts", subClass)
        if loadout and config.armor then 
            local armor = config.armor
            local options = config.armorOptions

            appearancePanel.AddOption.Label("Armor")
            local armorPanel = appearancePanel.AddOption.Panel()
            
            for placement, armors in pairs(armor) do 
                local armorCBox 
                    = armorPanel.AddOption.ComboBox(
                        string.NiceName(placement))

                armorCBox:SetValue("Select your Armor")
                for class, data in pairs(armors) do 
                    armorCBox:AddChoice(data.name, class, !options.selectable)
                end
                armorCBox:SetEnabled(false)

                if options.selectable then 
                    armorCBox:AddChoice("None")
                    armorCBox:SetEnabled(true)
                end

                armorCBox.OnSelect = function(self, index, value, data) limit:RecalculatePoints() end

                elements.armor[placement] = armorCBox
            end

            limit.updateFuncs.armor = function()
                local totalCost = 0

                for placement, armorCBox in pairs(elements.armor) do 
                    local name, class = armorCBox:GetSelected()
                    local selArmor = armor[placement][class]
                    if not selArmor then continue end
                    totalCost = totalCost + selArmor.points or 0
                end

                return totalCost
            end

            limit:RecalculatePoints()

            local renderCheck = armorPanel.AddOption.CheckBox("Render Armor")
            renderCheck:SetValue(true)
            if not options.render then
                renderCheck:SetValue(false)
                renderCheck:SetEnabled(false)
            end
            
            elements.armorRender = renderCheck

            armorPanel:InvalidateLayout(true)
            armorPanel:SizeToChildren(false, true)
            appearancePanel:InvalidateLayout(true)
        end
    end)

    return appearancePanel
end

---@alias item { name: string, points: number }

---@param panel DPanel
---@param cBox DComboBox
---@param config { weapon: { name: string, points: number, ammoTypes: table<string, item>, attachments?: table<string, table<string, item>> } }
---@param title string
---@return DComboBox cBox
local function DrawWeaponComboBox(panel, cBox, config, title)
    local limit = elements.limit 

    cBox:SetSortItems(false)

    for class, data in pairs(config) do 
        cBox:AddChoice(data.name, class)
    end
    cBox:AddChoice("None")

    cBox.OnSelect = function(self, index, value, data)
        DERMA.ClearExceptIndex({ [1] = true }, panel)
        if value == "None" or data == "None" then 
            elements[title].ammoType = nil
            elements[title].ammo = nil
            elements[title].attachments = nil

            limit:RecalculatePoints()
            panel:InvalidateLayout(true)
            panel:SizeToChildren(false, true)
            panel:GetParent():InvalidateLayout(true)
            return 
        end

        local ammoTypes = config[data].ammoTypes
        local ammoTypesCBox = panel.AddOption.ComboBox("Ammo Type")
        for id, data in pairs(ammoTypes) do 
            ammoTypesCBox:AddChoice(data.name, id)
        end
        ammoTypesCBox.OnSelect = function(self, index, value, data) limit:RecalculatePoints() end

        local ammoNum = panel.AddOption.Number("Total Clips", 0, 10)
        ammoNum.OnValueChanged = function(self, value) limit:RecalculatePoints() end

        if table.Count(ammoTypes) <= 1 then
            ammoTypesCBox:ChooseOptionID(1)
            ammoTypesCBox:SetEnabled(false)
        end

        local attachments = config[data].attachments
        if attachments then 
            elements[title].attachments = {}
            for placement, atts in pairs(attachments) do
                local attachmentCBox 
                    = panel.AddOption.ComboBox(string.NiceName(placement))
                attachmentCBox:SetValue("Select a " .. placement) 
                for class, data in pairs(atts) do 
                    attachmentCBox:AddChoice(data.name, class)
                end
                attachmentCBox:AddChoice("None")
                attachmentCBox.OnSelect = function(self, index, value, data) limit:RecalculatePoints() end

                elements[title].attachments[placement] = attachmentCBox
            end
        end

        elements[title].weapon = cBox
        elements[title].ammoType = ammoTypesCBox
        elements[title].ammo = ammoNum

        limit.updateFuncs[title] = function()
            local totalCost = 0
            local data

            local name, class = cBox:GetSelected()
            if class then 
                data = config[class]
                totalCost = totalCost + data.points or 0
            else return totalCost end

            local ammoTypesCBox = elements[title].ammoType
            if ammoTypesCBox then 
                local name, id = ammoTypesCBox:GetSelected()
                local ammoNum =  elements[title].ammo
                local ammo = ammoNum and ammoNum:GetValue()
                if wep and id then 
                    local ammoData = data.ammoTypes[id]
                    totalCost = totalCost + ammo * ammoData.points
                end
            end

            local attachments = elements[title].attachments
            if attachments then 
                for placement, attachmentCBox in pairs(attachments) do 
                    local name, class = attachmentCBox:GetSelected()
                    if not class then continue end
                    local attachmentData = data.attachments[placement][class]
                    totalCost = totalCost + attachmentData.points or 0
                end
            end

            return totalCost
        end
        

        limit:RecalculatePoints()

        panel:InvalidateLayout(true)
        panel:SizeToChildren(false, true)
        panel:GetParent():InvalidateLayout(true)
    end
end

local function DrawWeaponsPanel(parent) 
    local colors = { bg = colors.mainBG, highlightBg = colors.selectionBG, textColor = colors.mainText, border = colors.border }

    local weaponsPanel 
        = DERMA.CreateStyledPanel(
            parent, 
            "HomigradFontMedium", 
            colors, 
            gap)

    elements.base = {}
    elements.primary = {}
    elements.secondary = {}
    elements.utility = {}

    local classCBox = elements.class
    local subClassCBox = elements.subClass
    local _viewer = elements.viewer
    local limit = elements.limit
    DERMA.HookPanelMethod(subClassCBox, "OnSelect", function(self, index, value, data)
        local className, classID = classCBox:GetSelected()
        local class = PLAYER_CLASS:GetClass(classID)
        local subClass = data

        weaponsPanel:Clear()

        local loadout = class:GetModule("class_loadouts")
        local config = loadout and class:GetSubConfig("loadouts", subClass).loadout
        if config and config.base then 
            elements.base = config.base
        end
        local primary = config and config.primary or nil
        weaponsPanel.AddOption.Label("Weapons")
        if loadout and primary then
            local primaryPanel = weaponsPanel.AddOption.Panel()
            local primaryCBox = primaryPanel.AddOption.ComboBox("Primary")
            
            DrawWeaponComboBox(primaryPanel, primaryCBox, primary, "primary")

            primaryPanel:InvalidateLayout(true)
            primaryPanel:SizeToChildren(false, true)
            weaponsPanel:InvalidateLayout(true)
        end
        
        local secondary = config and config.secondary or nil
        if loadout and secondary then
            local secondaryPanel = weaponsPanel.AddOption.Panel()
            local secondaryCBox = secondaryPanel.AddOption.ComboBox("Secondary")
            
            DrawWeaponComboBox(secondaryPanel, secondaryCBox, secondary, "secondary")

            secondaryPanel:InvalidateLayout(true)
            secondaryPanel:SizeToChildren(false, true)
            weaponsPanel:InvalidateLayout(true)
        end
        
        weaponsPanel.AddOption.Label("Utility")
        local utility = config and config.utility or nil
        if loadout and utility then 
            local utilityPanel = weaponsPanel.AddOption.Panel()
            for itemClass, data in pairs(utility) do
                local utilNum = utilityPanel.AddOption.Number(data.name, 0, data.max)
                utilNum.itemClass = itemClass
                utilNum.OnValueChanged = function(self, value) limit:RecalculatePoints() end

                table.insert(elements.utility, utilNum)
            end

            limit.updateFuncs.utility = function()
                local totalCost = 0

                for _, utilityNum in ipairs(elements.utility) do 
                    local itemClass = utilityNum.itemClass
                    if not itemClass or not utility[itemClass] then continue end
                    local count = utilityNum:GetValue()
                    local data = utility[itemClass]
                    totalCost = totalCost + data.points * count
                end

                return totalCost
            end

            utilityPanel:InvalidateLayout(true)
            utilityPanel:SizeToChildren(false, true)
            weaponsPanel:InvalidateLayout(true)
        end

    end)

    return weaponsPanel
end

local function DrawItemsPanel(parent) 
    local colors = { 
        bg = colors.mainBG, 
        highlightBg = colors.selectionBG, 
        textColor = colors.mainText,
        border = colors.border }

    local itemsPanel 
        = DERMA.CreateStyledPanel(
            parent, 
            "HomigradFontMedium", 
            colors, 
            gap)

    elements.items = {}

    local classCBox = elements.class
    local subClassCBox = elements.subClass
    local _viewer = elements.viewer
    local limit = elements.limit
    DERMA.HookPanelMethod(subClassCBox, "OnSelect", function(self, index, value, data)
        local className, classID = classCBox:GetSelected()
        local class = PLAYER_CLASS:GetClass(classID)
        local subClass = data

        itemsPanel:Clear()

        local loadout = class:GetModule("class_loadouts")
        local config = loadout and class:GetSubConfig("loadouts", subClass).loadout
        local items = config and config.items or nil

        itemsPanel.AddOption.Label("Items")
        if loadout and items then 
            for itemClass, data in pairs(items) do 
                local itemCheck 
                    = itemsPanel.AddOption.CheckBox(data.name)
                itemCheck.itemClass = itemClass
                itemCheck.OnChange = function(self, bVal) limit:RecalculatePoints() end

                table.insert(elements.items, itemCheck)
            end

            limit.updateFuncs.items = function()
                local totalCost = 0

                for _, itemCheck in ipairs(elements.items) do 
                    local itemClass = itemCheck.itemClass
                    if not itemClass or not items[itemClass] then continue end
                    local bVal = itemCheck:GetChecked()
                    if not bVal then continue end
                    local data = items[itemClass]
                    totalCost = totalCost + (bVal and data.points) or 0
                end

                return totalCost
            end

            limit:RecalculatePoints()
        end
        --[[
        itemPanel:InvalidateLayout(true)
        itemPanel:SizeToChildren(false, true)
        weaponSheet:InvalidateLayout(true)]]
    end)

    return itemsPanel
end

local function DrawPresetMenu(parent) 
    local colors = { 
        bg = colors.mainBG, 
        highlightBg = colors.selectionBG, 
        textColor = colors.mainText,
        highlightText = colors.highlightText,
        border = colors.border }

    local classCBox = elements.class
    local subClassCBox = elements.subClass

    local loadButton 
        = DERMA.CreateStyledButton(
            parent, 
            "Select Preset", 
            "HomigradFontMedium", 
            colors)

    loadButton.DoClick = function(self) 
        local frame = vgui.Create("ZFrame")
        frame:SetSize(sizeX / 2, sizeY / 3)
        frame:Center()
        frame:SetTitle("Preset List")
        frame:SetVisible(true)
        frame:SetDraggable(true)
        frame:ShowCloseButton(true)
        frame:MakePopup()

        local panel = vgui.Create("DPanel", frame)
        panel:Dock(FILL)
        panel.Paint = function(self, w, h) end

        local label = 
            DERMA.CreateStyledLabel(
                panel, 
                "Preset List", 
                "HomigradFontLarge", 
                colors)
        label:SetContentAlignment(5)

        local className, classID = classCBox:GetSelected()
        local subClassName, subClass = subClassCBox:GetSelected()
        local presets = CLASS_SELECTOR.GetPresetList(classID, subClass)
        local presetCBox 
            = DERMA.CreateStyledCBox(
                panel, 
                "Select a Preset", 
                "HomigradFontLarge", 
                colors)
        DERMA.PopulateComboBox(presetCBox, presets)


        local loadPanel = vgui.Create("DPanel", panel)
        loadPanel.Paint = function(self, w, h) end
        local loadButton 
            = DERMA.CreateStyledButton(
                loadPanel, 
                "Load Preset", 
                "HomigradFontLarge", 
                colors)
        local deleteButton 
            = DERMA.CreateStyledButton(
                loadPanel, 
                "Delete Preset", 
                "HomigradFontLarge", 
                colors)
        
        DERMA.ChildrenFitWidth(loadPanel, gap)
        DERMA.ChildrenFitHeight(panel, gap / 2)
    end

    loadButton:SetEnabled(false)
    
    return loadButton
end

---@param parent Panel
local function CreateRightContainer(parent)
    local colors = { bg = colors.mainBG, 
                      highlightBg = colors.selectionBG, 
                      textColor = colors.mainText, 
                      highlightText = colors.presetBG,
                      border = colors.border }
    
    local rightContainer = vgui.Create("DPanel", parent)
    rightContainer:Dock(FILL)
    function rightContainer:Paint(w, h) end

    DrawPointsLabel(rightContainer, "Acquisition Points", 0, 0)
    local pointsLabel = elements.limit
    pointsLabel:Dock(TOP)
    pointsLabel:DockMargin(0, 0, 0, gap / 2)
    pointsLabel:SetSize(1, parent:GetTall() * 0.075)

    local pSheet 
        = DERMA.CreateStyledPSheet(rightContainer, "HomigradFontSmall", colors, gap)
    pSheet:Dock(FILL)


    local appearancePanel = DrawAppearancePanel(nil)
    pSheet:AddSheet("Appearance", appearancePanel)
    local weaponsPanel = DrawWeaponsPanel(nil)
    pSheet:AddSheet("Weapons and Utility", weaponsPanel)
    local itemsPanel = DrawItemsPanel(nil)
    pSheet:AddSheet("Items", itemsPanel)

    local bottomRightContainer = vgui.Create("DPanel", rightContainer)
    bottomRightContainer:Dock(BOTTOM)
    bottomRightContainer:DockMargin(0, gap, 0, 0)
    bottomRightContainer:SetTall(parent:GetTall() * 0.075)
    function bottomRightContainer:Paint(w, h) return end

    local changeButton 
        = DERMA.CreateStyledButton(
            bottomRightContainer, 
            "Change Class", 
            "HomigradFontMedium", 
            colors)
    elements.change = changeButton

    local saveContainer = vgui.Create("DPanel", bottomRightContainer)
    function saveContainer:Paint(w, h) return end

        local saveButton
            = DERMA.CreateStyledButton(
                bottomRightContainer, 
                "Save Preset", 
                "HomigradFontMedium", 
                colors)
        elements.save = saveButton
        saveButton:Dock(LEFT)
        saveButton:SizeToContentsX(gap)
        
        local presetEntry = vgui.Create("DTextEntry",saveContainer)
        presetEntry:SetSize(ScreenScale(164),ScreenScale(15))
        presetEntry:SetFont("HomigradFont")
        presetEntry:Dock(FILL)
        presetEntry:DockMargin(4, 0, 0, 0)
        presetEntry:SetContentAlignment(5)
        presetEntry.Paint = function(self, w, h)
            draw.RoundedBox(0, 0, 0, w, h, colors.bg)

            self.DrawBorder = true
            if self.DrawBorder then
                surface.SetDrawColor(colors.border)
                surface.DrawOutlinedRect(0, 0, w, h, 1.5)
        end
    end

    local loadButton = DrawPresetMenu(bottomRightContainer)

    DERMA.ChildrenFitWidth(bottomRightContainer, gap / 2)
end

---@return table data
local function ParseInput() 
    local data = {}

    if elements.tagline then 
        local taglineCBox = elements.tagline
        local name, tag = taglineCBox:GetSelected()
        data.tagLine = tag or nil
    end

    if elements.squad then 
        local squadCBox = elements.squad
        local name, callSign = squadCBox:GetSelected()
        data.squad = callSign or nil
    end

    local appearance = {}
    local viewer = elements.viewer
    local ent = viewer:GetEntity()
    appearance.model = ent:GetModel()
    appearance.skin = ent:GetSkin()
    appearance.bodygroups = {}
    for i = 1, ent:GetNumBodyGroups() - 1 do 
        table.insert(
            appearance.bodygroups, 
            i, 
            ent:GetBodygroup(i))
    end
    appearance.mats = viewer.mats
    ---@type { r: number, g: number, b: number }
    local color = viewer.playerColor
    color = Vector(color.r, color.g, color.b)
    appearance.color = color
    data.appearance = appearance

    local armor = {}
    for placement, armorCBox in pairs(elements.armor) do 
        local name, class = armorCBox:GetSelected()
        if not class then continue end
        armor[placement] = class
    end
    data.armor = armor
    
    local loadout = {}
    local base = {}
    if elements.base 
        and not table.IsEmpty(elements.base) then 
        base = elements.base
    end
    loadout.base = base

    local primary = {}
    ---@type DComboBox
    local weapon = elements.primary.weapon
    if weapon then 
        local name, class = weapon:GetSelected()
        if class then 
            primary.weapon = class
            ---@type DComboBox
            local ammoType = elements.primary.ammoType
            ---@type DNumberWang
            local ammoNum = elements.primary.ammo

            local name, id = ammoType:GetSelected()
            local ammo = ammoNum:GetValue()
            primary.ammoType = id
            primary.ammo = ammo

            local attachments = {}
            if elements.primary.attachments then 
                for placement, attachmentCBox in pairs(elements.primary.attachments) do 
                    local name, class = attachmentCBox:GetSelected()
                    if not class then continue end
                    attachments[placement] = class
                end
            end
            primary.attachments = attachments
        end
    end
    loadout.primary = primary

    local secondary = {}
    ---@type DComboBox
    local weapon = elements.secondary.weapon
    if weapon then 
        local name, class = weapon:GetSelected()
        if class then 
            secondary.weapon = class
            ---@type DComboBox
            local ammoType = elements.secondary.ammoType
            ---@type DNumberWang
            local ammoNum = elements.secondary.ammo

            local name, id = ammoType:GetSelected()
            local ammo = ammoNum:GetValue()
            secondary.ammoType = id
            secondary.ammo = ammo

            local attachments = {}
            if elements.secondary.attachments then 
                for placement, attachmentCBox in pairs(elements.secondary.attachments) do 
                    local name, class = attachmentCBox:GetSelected()
                    if not class then continue end
                    attachments[placement] = class
                end
            end
            secondary.attachments = attachments
        end
    end
    loadout.secondary = secondary

    local utility = {}
    for _, utilityNum in ipairs(elements.utility) do 
        local class = utilityNum.itemClass
        local count = utilityNum:GetValue()
        utility[class] = count
    end
    loadout.utility = utility

    local items = {}
    for _, itemCheck in ipairs(elements.items) do 
        local class = itemCheck.itemClass
        if not class then continue end
        local bVal = itemCheck:GetChecked()
        items[class] = bVal
    end
    loadout.items = items

    data.loadout = loadout

    return data
end

local function DrawMenu()
    local frame = vgui.Create("ZFrame")
    frame:SetSize(sizeX, sizeY)
    frame:Center()
    frame:SetTitle("Class Selector")
    frame:SetVisible(true)
    frame:SetDraggable(true)
    frame:ShowCloseButton(true)
    frame:MakePopup()

    CreateLeftContainer(frame)
    CreateRightContainer(frame)

    local changeButton = elements.change
    changeButton.DoClick = function(self)
        local classCBox = elements.class
        local subClassCBox = elements.subClass
        local viewer = elements.viewer
        local limit = elements.limit
            
        local className, classID = classCBox:GetSelected()
        local class = PLAYER_CLASS:GetClass(classID)
        if not class then return end
        local subClassName, subClassID = subClassCBox:GetSelected()
        if not class.subClasses[subClassID] then return end

        if limit:IsOverLimit() then return end
        if not viewer:GetEntity():GetModel() then return end
        
        local data = ParseInput()

        netstream.Start(
            "SetPlayerClass_ClassSelector",
            classID,
            subClassID,
            data)
    end

end

CLASS_SELECTOR.DrawSelector = DrawMenu

concommand.Add("hg_equipment_menu",function()
    DrawMenu()
end)
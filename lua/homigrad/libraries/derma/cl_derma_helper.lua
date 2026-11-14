hg.derma = hg.derma or {}

local DERMA = hg.derma

---Wraps an existing panel method so both the original and a new
---callback run, without needing to know or touch what the original does.
---@param panel Panel
---@param methodName string
---@param callback function
function DERMA.HookPanelMethod(panel, methodName, callback)
    local original = panel[methodName]

    panel[methodName] = function(self, ...) 
        if original then 
            original(self, ...)
        end
        callback(self, ...)
    end
end

---Clears all children of a panel, except for the children with the given indexes.
---@param indexes table<number, true>
---@param panel Panel
function DERMA.ClearExceptIndex(indexes, panel)
    for i, child in ipairs(panel:GetChildren()) do
        if indexes[i] then continue end
        child:Clear()
        child:Remove()
    end
end

---Makes all children of a panel fit its total width.
---@warnign If a child has a variable `child.skip` set to true, this function will skip it.
---@param panel Panel
---@param gap number?
function DERMA.ChildrenFitWidth(panel, gap)
    local oldPerformLayout = panel.PerformLayout
    panel.PerformLayout = function(self, w, h)
        if oldPerformLayout then oldPerformLayout(self, w, h) end

        local children = self:GetChildren()
        local count = #children
        if count == 0 then return end

        local eachWidth = w / count
        if gap then eachWidth = eachWidth - gap / 2 end
        for i, child in ipairs(children) do
            child:Dock(LEFT)
            if child.skip then 
                child:DockMargin(eachWidth / 2 - gap, 0, 0, 0)
                continue
            end
            child:SetWide(eachWidth)

            if i < count and gap then
                child:DockMargin(0, 0, gap, 0)
            else 
                child:DockMargin(0, 0, 0, 0)
            end
        end
    end
end

---Makes all children of a panel fit its total height.
---@warnign If a child has a variable `child.skip` set to true, this function will skip it.
---@param panel Panel
---@param gap number?
function DERMA.ChildrenFitHeight(panel, gap)
    local oldPerformLayout = panel.PerformLayout
    panel.PerformLayout = function(self, w, h)
        if oldPerformLayout then oldPerformLayout(self, w, h) end
        local children = self:GetChildren()
        local count = #children
        if count == 0 then return end

        local eachHeight = h / count
        for i, child in ipairs(children) do 
            child:Dock(TOP)
            if child.skip then 
                child:DockMargin(0, eachHeight / 2 - gap, 0, 0)
                continue
            end
            child:SetHeight(eachHeight)

            if i < count then
                child:DockMargin(0, 0, 0, gap)
            else 
                child:DockMargin(0, 0, 0, 0)
            end
        end
    end
end

---Boiler-plate local function to style a DPanel object.
---@param colors {bg: Color, border: Color}
---@return fun(self: DPanel, w: number, h: number) func
local function Paint(colors)
    return function(self, w, h)
        draw.RoundedBox(0, 0, 0, w, h, colors.bg)

        self.DrawBorder = true
        if self.DrawBorder then
            surface.SetDrawColor(colors.border)
            surface.DrawOutlinedRect(0, 0, w, h, 1.5)
        end
    end
end

---@param parent? Panel
---@param text? string
---@param font? string
---@param colors { textColor: Color, bg: Color, border: Color}
---@return DLabel label
function DERMA.CreateStyledLabel(parent, text, font, colors)
    local label = vgui.Create("DLabel", parent)
    label:SetText(text)
    label:SetFont(font)
    label:SetTextColor(colors.textColor)

    label.Paint = Paint({ bg = colors.bg, border = colors.border })

    return label
end

---Boiler-plate local function to style a DPanel object.
---@param colors { textColor: Color, highlightText: Color, bg: Color, highlightBg: Color, border: Color }
---@return fun(self: DPanel, w: number, h: number) func
local function PaintCombo(colors)
    return function(self, w, h)
        local col = self:IsMenuOpen() and colors.highlightBg or colors.bg
        local colText = self:IsMenuOpen() and colors.highlightText or colors.textColor

        draw.RoundedBox(0, 0, 0, w, h, col)
        self:SetTextColor(colText)

        self.DrawBorder = true
        if self.DrawBorder then
            surface.SetDrawColor(colors.border)
            surface.DrawOutlinedRect(0, 0, w, h, 1.5)
        end
    end
end

---@param parent? Panel
---@param value? string
---@param font? string
---@param colors { textColor: Color, highlightText: Color, bg: Color, highlightBg: Color, border: Color }
---@return DComboBox combos
function DERMA.CreateStyledCBox(parent, value, font, colors)
    local combo = vgui.Create("DComboBox", parent)
    combo:SetValue(value)
    combo:SetFont(font)
    combo:SetContentAlignment(5)

    combo.DrawBorder = true

    combo.Paint = PaintCombo(colors)

    combo.OnMenuOpened = function(self, menu)
        menu.Paint = Paint({ bg = colors.highlightBg, border = colors.border })

        for _, option in ipairs(menu:GetCanvas():GetChildren()) do
            option.Paint = function(optSelf, w, h)
                local col = optSelf.Hovered and colors.highlightBg or colors.bg
                local colText = self:IsMenuOpen() and colors.highlightText or colors.textColor

                draw.RoundedBox(0, 0, 0, w, h, col)
                self:SetTextColor(colText)
            end
        end
    end
    
    return combo
end

---Populates a combo box with the data from a table.
---
---If provided with an index number, it will select that item.
---@param combo DComboBox
---@param tbl table
---@param selectIndex? number
---@return DComboBox
function DERMA.PopulateComboBox(combo, tbl, selectIndex)
    if not tbl then return end

    if table.IsSequential(tbl) then 
        for i, value in ipairs(tbl) do 
            combo:AddChoice(value, nil, i == selectIndex)
        end
    else 
        local count = 1
        for key, value in pairs(tbl) do 
            combo:AddChoice(
                string.NicePrint(key), 
                value, 
                count == selectIndex)
            count = count + 1
        end
    end

    return combo
end

---Boiler-plate local function to style a DPanel object.
---@param colors { textColor: Color, highlightText: Color, bg: Color, highlightBg: Color, border: Color }
---@return fun(self: DPanel, w: number, h: number) func
local function PaintButton(colors)
    return function(self, w, h)
        local col = self:IsHovered() and colors.highlightBg or colors.bg
        local colText = self:IsHovered() and colors.highlightText or colors.textColor

        draw.RoundedBox(0, 0, 0, w, h, col)
        self:SetTextColor(colText)

        self.DrawBorder = true
        if self.DrawBorder then
            surface.SetDrawColor(colors.border)
            surface.DrawOutlinedRect(0, 0, w, h, 1.5)
        end
    end
end

---@param parent? Panel
---@param text string
---@param font string
---@param colors { textColor: Color, highlightText: Color, bg: Color, highlightBg: Color, border: Color}
---@return DButton button
function DERMA.CreateStyledButton(parent, text, font, colors)
    local button = vgui.Create("DButton", parent)
    button:SetText(text)
    button:SetFont(font)
    button:SetContentAlignment(5)

    button.Paint = PaintButton(colors)

    return button
end

---@param parent? Panel
---@param font string
---@param colors { textColor: Color, bg: Color, highlightBg: Color, border: Color}
function DERMA.CreateStyledPanel(parent, font, colors, gap)
    local panel = vgui.Create("DPanel", parent)
    panel.Paint = function(self, w, h) return end

    panel.AddOption = {
        ["Panel"] = function()
            local childPanel = DERMA.CreateStyledPanel(panel, font, colors, gap)
            childPanel:Dock(TOP)
            childPanel:DockMargin(0, gap / 2, 0, gap / 2)
            childPanel.Paint = function(self, w, h) return end

            return childPanel
        end,
        ["Label"] = function(title)
            local childPanel = panel.AddOption.Panel(false)
                
            local label = DERMA.CreateStyledLabel(childPanel, 
                                            title, 
                                            font, 
                                            colors)
            label:SetContentAlignment(8)

            DERMA.ChildrenFitWidth(childPanel, gap)

            return label
        end,
        ["ComboBox"] = function(title)
            local childPanel = panel.AddOption.Panel(false)
                
            local label 
                = DERMA.CreateStyledLabel(
                    childPanel, 
                    title .. ":", 
                    font, 
                    colors)
            label:SetContentAlignment(8)

            local comboBox 
                = DERMA.CreateStyledCBox(
                    childPanel, 
                    "Select " .. title, 
                    font, 
                    colors)
            comboBox:SetContentAlignment(8)
            
            DERMA.ChildrenFitWidth(childPanel, gap)

            return comboBox
        end,
        ["Slider"] = function(title, min, max)
            local childPanel = panel.AddOption.Panel(false)
                
            local label 
                = DERMA.CreateStyledLabel(
                    childPanel, 
                    title .. ":", 
                    font, 
                    colors)
            label:SetContentAlignment(8)

            local slider = vgui.Create("DNumSlider", childPanel)
            slider.Label:SetVisible(false)
            slider:SetMin(min)
            slider:SetMax(max)
            slider:SetDecimals(0)

            DERMA.ChildrenFitWidth(childPanel, gap)

            return slider
        end,
        ["CheckBox"] = function(title)
            local childPanel = panel.AddOption.Panel(false)
                
            local label 
                = DERMA.CreateStyledLabel(
                    childPanel, 
                    title .. ":", 
                    font, 
                    colors)
            label:SetContentAlignment(8)

            local checkBox = vgui.Create("DCheckBox", childPanel)
            checkBox.skip = true

            DERMA.ChildrenFitWidth(childPanel, gap)

            return checkBox
        end,
        ["Number"] = function(title, min, max)
            local childPanel = panel.AddOption.Panel(false)
                
            local label 
                = DERMA.CreateStyledLabel(
                    childPanel, 
                    title .. ":", 
                    font, 
                    colors)
            label:SetContentAlignment(8)

            local number = vgui.Create("DNumberWang", childPanel)
            number.skip = true
            number:SetMinMax(min, max)

            DERMA.ChildrenFitWidth(childPanel, gap)

            return number
        end
    }

    return panel
end

---Boiler-plate local function to style a DPanel object.
---@param colors { textColor: Color, highlightText: Color, bg: Color, highlightBg: Color, border: Color}
---@return fun(self: DPanel, w: number, h: number) func
local function PaintTab(colors)
    return function(self, w, h)
        local col = self:IsActive() and colors.highlightBg or colors.bg
        local colText = self:IsActive() and colors.highlightText or colors.textColor

        self:SetTextColor(colText)
        draw.RoundedBox(0,0,0,w,h, col)

        if self.DrawBorder then
            surface.SetDrawColor(colors.border)
            surface.DrawOutlinedRect(0,0,w,h,1.5)
        end
    end
end

---@param parent? Panel
---@param font string
---@param colors { textColor: Color, highlightText: Color, bg: Color, highlightBg: Color, border: Color}
---@param gap number
---@return DPropertySheet pSheet
function DERMA.CreateStyledPSheet(parent, font, colors, gap)
    local pSheet = vgui.Create("DPropertySheet", parent)

    pSheet.Paint = Paint(colors)

    local oldAddSheet = pSheet.AddSheet
    pSheet.AddSheet = function(self, pnl, icon, noStretchX, noStretchY, tooltip)
        local sheet = oldAddSheet(self, pnl, icon, noStretchX, noStretchY, tooltip)
        local tab = sheet.Tab

        tab.Paint = PaintTab(colors)
        sheet.Paint = Paint(colors)

        return sheet
    end

    local oldPerformLayout = pSheet.PerformLayout
    pSheet.PerformLayout = function (self, w, h) 
        if oldPerformLayout then oldPerformLayout(self, w, h) end

        local scroller = self.tabScroller
        local items = self:GetItems()
        local count = items and #items or 0
        if not scroller and count == 0 then return end

        scroller:SetWide(w)
        local tabWidth = scroller:GetWide() / count
        for _, item in ipairs(items) do
            ---@type DTab
            local tab = item.Tab
            tab:SizeToContentsY(gap / 2)
            tab:SetWide(tabWidth)
            tab:SetFont(font)
            tab:SetContentAlignment(8)
            tab.ApplySchemeSettings = function(self)
                DLabel.ApplySchemeSettings(self)
                self:SetWide(tabWidth)
            end
        end
    end

    return pSheet
end

---This function sets the width of the property sheet tab to
---fill the entire space.
---@param sheet DPropertySheet
local function EquallySizeTabs(sheet)
    
end
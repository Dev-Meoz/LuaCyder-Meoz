local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer

local Library = {
    Version = "1.0.0",
    Name = "Selenium",
    Theme = "Abyss blue",
    Windows = {},
    Window = nil,
    Unloaded = false,
    _themeObjects = {},
    _connections = {},
    _blurEffect = nil,
}

Library.__index = Library

local Window = {}
Window.__index = Window

local Tab = {}
Tab.__index = Tab

local Element = {}
Element.__index = Element

local function clampNumber(value, minValue, maxValue)
    return math.clamp(value, minValue, maxValue)
end

local function roundNumber(value, decimals)
    decimals = decimals or 0
    local multiplier = 10 ^ decimals
    return math.floor(value * multiplier + 0.5) / multiplier
end

local function safeCallback(callback, ...)
    if type(callback) ~= "function" then
        return true
    end

    local success, result = pcall(callback, ...)
    if not success then
        warn("[Selenium] Callback error: " .. tostring(result))
    end

    return success, result
end

local function disconnect(connection)
    if connection then
        pcall(function()
            connection:Disconnect()
        end)
    end
end

local function addConnection(owner, connection)
    if not owner._connections then
        owner._connections = {}
    end
    table.insert(owner._connections, connection)
    return connection
end

local function cleanupConnections(owner)
    if not owner._connections then
        return
    end

    for i = #owner._connections, 1, -1 do
        disconnect(owner._connections[i])
        owner._connections[i] = nil
    end
end

local function createInstance(className, properties, children)
    local object = Instance.new(className)

    for property, value in pairs(properties or {}) do
        object[property] = value
    end

    for _, child in ipairs(children or {}) do
        child.Parent = object
    end

    return object
end

local Themes = {
    ["Abyss blue"] = {
        Background = Color3.fromRGB(8, 10, 15),
        Background2 = Color3.fromRGB(12, 16, 24),
        Surface = Color3.fromRGB(15, 19, 28),
        Surface2 = Color3.fromRGB(21, 26, 38),
        Sidebar = Color3.fromRGB(10, 13, 20),
        Border = Color3.fromRGB(36, 46, 66),
        BorderStrong = Color3.fromRGB(53, 68, 96),
        Text = Color3.fromRGB(245, 248, 255),
        SubText = Color3.fromRGB(154, 166, 188),
        Muted = Color3.fromRGB(104, 116, 139),
        Accent = Color3.fromRGB(87, 170, 255),
        Accent2 = Color3.fromRGB(49, 118, 220),
        Danger = Color3.fromRGB(240, 91, 91),
        Success = Color3.fromRGB(80, 205, 133),
        Input = Color3.fromRGB(12, 16, 24),
        Overlay = Color3.fromRGB(0, 0, 0),
        Island = Color3.fromRGB(3, 5, 9),
        Blur = false,
    },

    ["Glass blur"] = {
        Background = Color3.fromRGB(16, 18, 23),
        Background2 = Color3.fromRGB(22, 25, 31),
        Surface = Color3.fromRGB(30, 33, 40),
        Surface2 = Color3.fromRGB(42, 46, 54),
        Sidebar = Color3.fromRGB(19, 22, 27),
        Border = Color3.fromRGB(90, 95, 108),
        BorderStrong = Color3.fromRGB(130, 136, 152),
        Text = Color3.fromRGB(248, 248, 250),
        SubText = Color3.fromRGB(177, 181, 192),
        Muted = Color3.fromRGB(126, 131, 142),
        Accent = Color3.fromRGB(202, 210, 225),
        Accent2 = Color3.fromRGB(150, 160, 176),
        Danger = Color3.fromRGB(240, 102, 102),
        Success = Color3.fromRGB(91, 207, 142),
        Input = Color3.fromRGB(24, 27, 33),
        Overlay = Color3.fromRGB(0, 0, 0),
        Island = Color3.fromRGB(6, 7, 9),
        Blur = true,
    },

    ["Dark"] = {
        Background = Color3.fromRGB(13, 13, 14),
        Background2 = Color3.fromRGB(18, 18, 19),
        Surface = Color3.fromRGB(21, 21, 23),
        Surface2 = Color3.fromRGB(28, 28, 30),
        Sidebar = Color3.fromRGB(16, 16, 18),
        Border = Color3.fromRGB(42, 42, 46),
        BorderStrong = Color3.fromRGB(60, 60, 64),
        Text = Color3.fromRGB(245, 245, 246),
        SubText = Color3.fromRGB(165, 165, 170),
        Muted = Color3.fromRGB(105, 105, 110),
        Accent = Color3.fromRGB(235, 235, 240),
        Accent2 = Color3.fromRGB(170, 170, 178),
        Danger = Color3.fromRGB(238, 89, 89),
        Success = Color3.fromRGB(84, 198, 130),
        Input = Color3.fromRGB(17, 17, 19),
        Overlay = Color3.fromRGB(0, 0, 0),
        Island = Color3.fromRGB(3, 3, 4),
        Blur = false,
    },

    ["Premium"] = {
        Background = Color3.fromRGB(12, 10, 8),
        Background2 = Color3.fromRGB(19, 16, 13),
        Surface = Color3.fromRGB(23, 19, 16),
        Surface2 = Color3.fromRGB(34, 28, 23),
        Sidebar = Color3.fromRGB(15, 12, 10),
        Border = Color3.fromRGB(67, 53, 39),
        BorderStrong = Color3.fromRGB(101, 80, 55),
        Text = Color3.fromRGB(249, 243, 232),
        SubText = Color3.fromRGB(180, 166, 145),
        Muted = Color3.fromRGB(120, 110, 96),
        Accent = Color3.fromRGB(231, 194, 118),
        Accent2 = Color3.fromRGB(181, 140, 69),
        Danger = Color3.fromRGB(230, 91, 82),
        Success = Color3.fromRGB(101, 196, 133),
        Input = Color3.fromRGB(17, 14, 12),
        Overlay = Color3.fromRGB(0, 0, 0),
        Island = Color3.fromRGB(4, 3, 3),
        Blur = false,
    },

    ["Firetooth"] = {
        Background = Color3.fromRGB(15, 8, 7),
        Background2 = Color3.fromRGB(24, 12, 10),
        Surface = Color3.fromRGB(30, 15, 12),
        Surface2 = Color3.fromRGB(45, 22, 17),
        Sidebar = Color3.fromRGB(20, 10, 8),
        Border = Color3.fromRGB(85, 36, 27),
        BorderStrong = Color3.fromRGB(125, 50, 35),
        Text = Color3.fromRGB(255, 245, 239),
        SubText = Color3.fromRGB(190, 155, 145),
        Muted = Color3.fromRGB(124, 95, 88),
        Accent = Color3.fromRGB(255, 110, 62),
        Accent2 = Color3.fromRGB(207, 57, 35),
        Danger = Color3.fromRGB(255, 83, 73),
        Success = Color3.fromRGB(91, 203, 135),
        Input = Color3.fromRGB(23, 11, 9),
        Overlay = Color3.fromRGB(0, 0, 0),
        Island = Color3.fromRGB(5, 3, 3),
        Blur = false,
    },
}

Library.Themes = Themes
Library.ThemeNames = {
    "Abyss blue",
    "Glass blur",
    "Dark",
    "Premium",
    "Firetooth",
}

local function themeFor(library)
    return Themes[library.Theme] or Themes["Abyss blue"]
end

function Library:_registerTheme(object, tag)
    if not object or not tag then
        return object
    end

    self._themeObjects[object] = tag
    self:_applyThemeObject(object, tag)
    return object
end

function Library:_applyThemeObject(object, tag)
    if not object or not object.Parent then
        return
    end

    local theme = themeFor(self)

    for property, key in pairs(tag) do
        local value = theme[key]
        if value ~= nil then
            pcall(function()
                object[property] = value
            end)
        end
    end
end

function Library:_refreshTheme()
    for object, tag in pairs(self._themeObjects) do
        if object and object.Parent then
            self:_applyThemeObject(object, tag)
        else
            self._themeObjects[object] = nil
        end
    end
end

function Library:_createRootGui()
    local existing = nil

    pcall(function()
        if gethui then
            existing = gethui():FindFirstChild("SeleniumUI")
        end
    end)

    if not existing then
        pcall(function()
            existing = game:GetService("CoreGui"):FindFirstChild("SeleniumUI")
        end)
    end

    if existing then
        existing:Destroy()
    end

    local parent

    pcall(function()
        if gethui then
            parent = gethui()
        end
    end)

    if not parent then
        pcall(function()
            if protectgui then
                parent = game:GetService("CoreGui")
            end
        end)
    end

    if not parent then
        parent = LocalPlayer:WaitForChild("PlayerGui")
    end

    local gui = createInstance("ScreenGui", {
        Name = "SeleniumUI",
        IgnoreGuiInset = true,
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 999,
    })

    gui.Parent = parent

    pcall(function()
        if protectgui then
            protectgui(gui)
        end
    end)

    return gui
end

Library.GUI = Library:_createRootGui()

function Library:_new(className, properties, children, themeTag)
    local object = createInstance(className, properties, children)
    if themeTag then
        self:_registerTheme(object, themeTag)
    end
    return object
end

function Library:_tween(object, info, properties)
    local tween = TweenService:Create(object, info, properties)
    tween:Play()
    return tween
end

function Library:_getRootParent()
    return self.GUI
end

function Library:GetVersion()
    return self.Version
end

function Library:GetTheme()
    return self.Theme
end

function Library:GetThemeNames()
    local names = {}
    for _, name in ipairs(self.ThemeNames) do
        table.insert(names, name)
    end
    return names
end

function Library:GetThemeObject()
    return themeFor(self)
end

function Library:SetTheme(name)
    if not Themes[name] then
        return false
    end

    self.Theme = name
    self:_refreshTheme()

    for _, window in ipairs(self.Windows) do
        if window and not window.Destroyed then
            window:_refreshTheme()
        end
    end

    return true
end

function Library:GetWindow()
    return self.Window
end

function Library:GetWindows()
    local result = {}
    for i, window in ipairs(self.Windows) do
        result[i] = window
    end
    return result
end

function Library:SafeCallback(callback, ...)
    return safeCallback(callback, ...)
end

function Library:CreateWindow(config)
    config = config or {}

    local window = Window.new(self, config)
    table.insert(self.Windows, window)
    self.Window = window

    return window
end

function Library:Window(config)
    return self:CreateWindow(config)
end

function Library:Notify(config)
    if not self.Window then
        return nil
    end

    return self.Window:Notify(config)
end

function Library:Destroy()
    if self.Unloaded then
        return
    end

    self.Unloaded = true

    for i = #self.Windows, 1, -1 do
        local window = self.Windows[i]
        if window then
            pcall(function()
                window:Destroy()
            end)
        end
        self.Windows[i] = nil
    end

    cleanupConnections(self)

    if self._blurEffect then
        self._blurEffect:Destroy()
        self._blurEffect = nil
    end

    if self.GUI then
        self.GUI:Destroy()
        self.GUI = nil
    end
end

-- ============================================================
-- Element base
-- ============================================================

function Element:_initBase(tab, config, frame)
    self.Tab = tab
    self.Window = tab.Window
    self.Library = tab.Library
    self.Config = config or {}
    self.Frame = frame
    self.Destroyed = false
    self._connections = {}
    self.Changed = nil
    self.Callback = self.Config.Callback

    self.TitleLabel = self.Config.TitleLabel
    self.DescLabel = self.Config.DescLabel

    return self
end

function Element:SetTitle(title)
    if self.TitleLabel then
        self.TitleLabel.Text = tostring(title or "")
    end
    self.Config.Title = title
    return self
end

function Element:SetDescription(description)
    if self.DescLabel then
        description = tostring(description or "")
        self.DescLabel.Text = description
        self.DescLabel.Visible = description ~= ""
    end
    self.Config.Description = description
    return self
end

function Element:SetDesc(description)
    return self:SetDescription(description)
end

function Element:OnChanged(callback)
    self.Changed = callback
    return self
end

function Element:SetCallback(callback)
    self.Callback = callback
    self.Config.Callback = callback
    return self
end

function Element:GetValue()
    return self.Value
end

function Element:SetVisible(visible)
    if self.Frame then
        self.Frame.Visible = visible and true or false
    end
    return self
end

function Element:SetDisabled(disabled)
    self.Disabled = disabled and true or false
    return self
end

function Element:IsDestroyed()
    return self.Destroyed
end

function Element:Destroy()
    if self.Destroyed then
        return
    end

    self.Destroyed = true
    cleanupConnections(self)

    if self.Frame then
        self.Frame:Destroy()
    end
end

function Element:_fire(value)
    safeCallback(self.Callback, value)
    safeCallback(self.Changed, value)
end

-- ============================================================
-- Tab
-- ============================================================

function Tab.new(window, config)
    config = config or {}

    local self = setmetatable({}, Tab)

    self.Library = window.Library
    self.Window = window
    self.Name = tostring(config.Name or config.Title or ("Tab " .. tostring(#window.Tabs + 1)))
    self.Title = self.Name
    self.Description = tostring(config.Description or "")
    self.Icon = tostring(config.Icon or "")
    self.Elements = {}
    self.Destroyed = false
    self._connections = {}

    local library = self.Library
    local theme = themeFor(library)

    local button = library:_new("TextButton", {
        Name = "TabButton",
        Size = UDim2.new(1, 0, 0, 38),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "",
        LayoutOrder = #window.Tabs + 1,
        ZIndex = 5,
    }, nil)

    local buttonCorner = library:_new("UICorner", {
        CornerRadius = UDim.new(0, 10),
    })
    buttonCorner.Parent = button

    local iconLabel = library:_new("TextLabel", {
        Size = UDim2.fromOffset(24, 24),
        Position = UDim2.fromOffset(7, 7),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        Text = self.Icon,
        TextXAlignment = Enum.TextXAlignment.Center,
        TextYAlignment = Enum.TextYAlignment.Center,
        ZIndex = 6,
    }, nil, {
        TextColor3 = "SubText",
    })
    iconLabel.Parent = button
    self.IconLabel = iconLabel

    local nameLabel = library:_new("TextLabel", {
        Size = UDim2.new(1, -42, 1, 0),
        Position = UDim2.fromOffset(38, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium,
        TextSize = 13,
        Text = self.Name,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        ZIndex = 6,
    }, nil, {
        TextColor3 = "SubText",
    })
    nameLabel.Parent = button
    self.NameLabel = nameLabel

    local indicator = library:_new("Frame", {
        Name = "Indicator",
        Size = UDim2.fromOffset(3, 22),
        Position = UDim2.fromOffset(0, 8),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 7,
    }, nil, {
        BackgroundColor3 = "Accent",
    })
    local indicatorCorner = library:_new("UICorner", {
        CornerRadius = UDim.new(1, 0),
    })
    indicatorCorner.Parent = indicator
    indicator.Parent = button

    button.Parent = window.TabList
    self.Button = button
    self.Indicator = indicator

    local page = library:_new("ScrollingFrame", {
        Name = self.Name .. "Page",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageTransparency = 0.75,
        AutomaticCanvasSize = Enum.AutomaticSize.None,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollingDirection = Enum.ScrollingDirection.Y,
        Visible = false,
        ClipsDescendants = true,
        ZIndex = 4,
    }, nil, {
        ScrollBarImageColor3 = "Accent",
    })
    page.Parent = window.ContentHolder

    local padding = library:_new("UIPadding", {
        PaddingTop = UDim.new(0, 4),
        PaddingBottom = UDim.new(0, 18),
        PaddingLeft = UDim.new(0, 2),
        PaddingRight = UDim.new(0, 4),
    })
    padding.Parent = page

    local layout = library:_new("UIListLayout", {
        Padding = UDim.new(0, 8),
        FillDirection = Enum.FillDirection.Vertical,
        SortOrder = Enum.SortOrder.LayoutOrder,
    })
    layout.Parent = page

    self.Page = page
    self.Layout = layout
    self.ScrollFrame = page
    self.Container = page

    addConnection(self, layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        page.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 22)
    end))

    addConnection(self, button.Activated:Connect(function()
        window:SelectTab(self)
    end))

    addConnection(self, button.MouseEnter:Connect(function()
        if window.ActiveTab ~= self then
            library:_tween(button, TweenInfo.new(0.14, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                BackgroundTransparency = 0.91,
            })
        end
    end))

    addConnection(self, button.MouseLeave:Connect(function()
        if window.ActiveTab ~= self then
            library:_tween(button, TweenInfo.new(0.14, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                BackgroundTransparency = 1,
            })
        end
    end))

    return self
end

function Tab:_newContainer(height, themeKey)
    local library = self.Library

    local frame = library:_new("Frame", {
        Size = UDim2.new(1, -2, 0, height or 44),
        BackgroundTransparency = 0.02,
        BorderSizePixel = 0,
        LayoutOrder = #self.Elements + 1,
    }, nil, {
        BackgroundColor3 = themeKey or "Surface",
    })

    local corner = library:_new("UICorner", {
        CornerRadius = UDim.new(0, 10),
    })
    corner.Parent = frame

    local stroke = library:_new("UIStroke", {
        Thickness = 1,
        Transparency = 0.28,
    }, nil, {
        Color = "Border",
    })
    stroke.Parent = frame

    frame.Parent = self.Page
    return frame
end

function Tab:Section(title)
    local library = self.Library
    local frame = library:_new("Frame", {
        Size = UDim2.new(1, -4, 0, 34),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        LayoutOrder = #self.Elements + 1,
    })

    local titleLabel = library:_new("TextLabel", {
        Size = UDim2.new(1, -12, 1, 0),
        Position = UDim2.fromOffset(4, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        Text = tostring(title or "SECTION"),
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
    }, nil, {
        TextColor3 = "Text",
    })
    titleLabel.Parent = frame

    local line = library:_new("Frame", {
        Size = UDim2.new(1, -4, 0, 1),
        Position = UDim2.new(0, 4, 1, -1),
        BackgroundTransparency = 0.1,
        BorderSizePixel = 0,
    }, nil, {
        BackgroundColor3 = "Border",
    })
    line.Parent = frame

    table.insert(self.Elements, frame)
    return frame
end

function Tab:AddSection(title)
    return self:Section(title)
end

function Tab:CreateSection(title)
    return self:Section(title)
end

function Tab:Divider()
    local library = self.Library
    local frame = library:_new("Frame", {
        Size = UDim2.new(1, -4, 0, 8),
        BackgroundTransparency = 1,
        LayoutOrder = #self.Elements + 1,
    })

    local line = library:_new("Frame", {
        Size = UDim2.new(1, 0, 0, 1),
        Position = UDim2.fromScale(0, 0.5),
        BorderSizePixel = 0,
    }, nil, {
        BackgroundColor3 = "Border",
    })
    line.Parent = frame

    frame.Parent = self.Page
    table.insert(self.Elements, frame)
    return frame
end

function Tab:AddDivider()
    return self:Divider()
end

function Tab:CreateDivider()
    return self:Divider()
end

function Tab:AddSpace(height)
    return self:Space(height)
end

function Tab:CreateSpace(height)
    return self:Space(height)
end

function Tab:Space(height)
    local library = self.Library
    local frame = library:_new("Frame", {
        Size = UDim2.new(1, 0, 0, height or 8),
        BackgroundTransparency = 1,
        LayoutOrder = #self.Elements + 1,
    })
    frame.Parent = self.Page
    table.insert(self.Elements, frame)
    return frame
end

function Tab:Label(config)
    if type(config) == "string" then
        config = { Text = config }
    end
    config = config or {}

    local library = self.Library
    local frame = library:_new("Frame", {
        Size = UDim2.new(1, -2, 0, config.Height or 32),
        BackgroundTransparency = 1,
        LayoutOrder = #self.Elements + 1,
    })

    local label = library:_new("TextLabel", {
        Size = UDim2.new(1, -8, 1, 0),
        Position = UDim2.fromOffset(4, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        TextSize = config.TextSize or 13,
        Text = tostring(config.Text or config.Title or ""),
        TextWrapped = config.TextWrapped ~= false,
        TextXAlignment = config.TextXAlignment or Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
    }, nil, {
        TextColor3 = config.Color and nil or "SubText",
    })

    if config.Color then
        label.TextColor3 = config.Color
    end

    label.Parent = frame
    frame.Parent = self.Page
    table.insert(self.Elements, frame)

    local object = setmetatable({}, Element)
    object:_initBase(self, config, frame)
    object.TitleLabel = label
    object.Label = label
    object.SetText = function(obj, text)
        label.Text = tostring(text or "")
        obj.Config.Text = text
        return obj
    end

    return object
end

function Tab:AddLabel(config)
    return self:Label(config)
end

function Tab:Text(config)
    return self:Label(config)
end

function Tab:AddText(config)
    return self:Label(config)
end

function Tab:CreateLabel(config)
    return self:Label(config)
end

function Tab:Paragraph(config)
    config = config or {}

    local library = self.Library
    local frame = library:_new("Frame", {
        Size = UDim2.new(1, -2, 0, config.Height or 82),
        BackgroundTransparency = 0.04,
        BorderSizePixel = 0,
        LayoutOrder = #self.Elements + 1,
    }, nil, {
        BackgroundColor3 = config.BackgroundColor and nil or "Surface",
    })

    if config.BackgroundColor then
        frame.BackgroundColor3 = config.BackgroundColor
    end

    local corner = library:_new("UICorner", {
        CornerRadius = UDim.new(0, 10),
    })
    corner.Parent = frame

    local stroke = library:_new("UIStroke", {
        Thickness = 1,
        Transparency = 0.34,
    }, nil, {
        Color = "Border",
    })
    stroke.Parent = frame

    local padding = library:_new("UIPadding", {
        PaddingLeft = UDim.new(0, 13),
        PaddingRight = UDim.new(0, 13),
        PaddingTop = UDim.new(0, 10),
        PaddingBottom = UDim.new(0, 10),
    })
    padding.Parent = frame

    local layout = library:_new("UIListLayout", {
        Padding = UDim.new(0, 3),
        SortOrder = Enum.SortOrder.LayoutOrder,
    })
    layout.Parent = frame

    local title = library:_new("TextLabel", {
        Size = UDim2.new(1, 0, 0, 18),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        Text = tostring(config.Title or "Paragraph"),
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        LayoutOrder = 1,
    }, nil, {
        TextColor3 = "Text",
    })
    title.Parent = frame

    local description = library:_new("TextLabel", {
        Size = UDim2.new(1, 0, 0, 40),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        TextSize = config.TextSize or 12,
        Text = tostring(config.Content or config.Description or ""),
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        LayoutOrder = 2,
    }, nil, {
        TextColor3 = "SubText",
    })
    description.Parent = frame

    frame.Parent = self.Page
    table.insert(self.Elements, frame)

    local object = setmetatable({}, Element)
    object:_initBase(self, config, frame)
    object.TitleLabel = title
    object.DescLabel = description
    object.SetContent = function(obj, content)
        description.Text = tostring(content or "")
        obj.Config.Content = content
        return obj
    end
    object.SetText = object.SetContent

    return object
end

function Tab:AddParagraph(config)
    return self:Paragraph(config)
end

function Tab:Button(config)
    config = config or {}

    local library = self.Library
    local frame = self:_newContainer(config.Height or 48)

    local button = library:_new("TextButton", {
        Name = "Button",
        Size = UDim2.new(1, -16, 1, -10),
        Position = UDim2.fromOffset(8, 5),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Font = Enum.Font.GothamSemibold,
        TextSize = 13,
        Text = tostring(config.Title or config.Name or "Button"),
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
    }, nil, {
        TextColor3 = "Text",
    })
    button.Parent = frame

    local arrow = library:_new("TextLabel", {
        Size = UDim2.fromOffset(28, 28),
        Position = UDim2.new(1, -28, 0.5, -14),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 16,
        Text = ">",
        TextXAlignment = Enum.TextXAlignment.Center,
        TextYAlignment = Enum.TextYAlignment.Center,
    }, nil, {
        TextColor3 = "Muted",
    })
    arrow.Parent = frame

    local object = setmetatable({}, Element)
    object:_initBase(self, config, frame)
    object.Button = button
    object.Arrow = arrow
    object.TitleLabel = button

    addConnection(object, button.MouseEnter:Connect(function()
        if object.Disabled then
            return
        end
        library:_tween(frame, TweenInfo.new(0.13, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            BackgroundTransparency = 0,
        })
    end))

    addConnection(object, button.MouseLeave:Connect(function()
        library:_tween(frame, TweenInfo.new(0.13, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            BackgroundTransparency = 0.02,
        })
    end))

    addConnection(object, button.Activated:Connect(function()
        if object.Disabled then
            return
        end
        safeCallback(object.Callback)
    end))

    table.insert(self.Elements, object)
    return object
end

function Tab:AddButton(config)
    return self:Button(config)
end

function Tab:CreateButton(config)
    return self:Button(config)
end

function Tab:Toggle(config)
    config = config or {}

    local library = self.Library
    local frame = self:_newContainer(config.Height or 52)
    local title = library:_new("TextLabel", {
        Size = UDim2.new(1, -70, 0, 19),
        Position = UDim2.fromOffset(13, 8),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamSemibold,
        TextSize = 13,
        Text = tostring(config.Title or config.Name or "Toggle"),
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
    }, nil, {
        TextColor3 = "Text",
    })
    title.Parent = frame

    local desc = library:_new("TextLabel", {
        Size = UDim2.new(1, -76, 0, 16),
        Position = UDim2.fromOffset(13, 28),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        TextSize = 11,
        Text = tostring(config.Description or ""),
        TextTruncate = Enum.TextTruncate.AtEnd,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        Visible = (config.Description or "") ~= "",
    }, nil, {
        TextColor3 = "SubText",
    })
    desc.Parent = frame

    local track = library:_new("TextButton", {
        Size = UDim2.fromOffset(42, 22),
        Position = UDim2.new(1, -55, 0.5, -11),
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "",
    }, nil, {
        BackgroundColor3 = "Surface2",
    })
    track.Parent = frame

    local trackCorner = library:_new("UICorner", {
        CornerRadius = UDim.new(1, 0),
    })
    trackCorner.Parent = track

    local knob = library:_new("Frame", {
        Size = UDim2.fromOffset(16, 16),
        Position = UDim2.fromOffset(3, 3),
        BorderSizePixel = 0,
    }, nil, {
        BackgroundColor3 = "SubText",
    })
    knob.Parent = track

    local knobCorner = library:_new("UICorner", {
        CornerRadius = UDim.new(1, 0),
    })
    knobCorner.Parent = knob

    local object = setmetatable({}, Element)
    object:_initBase(self, config, frame)
    object.TitleLabel = title
    object.DescLabel = desc
    object.Track = track
    object.Knob = knob
    object.Value = config.Default == true

    function object:SetValue(value, fireCallback)
        value = value and true or false
        object.Value = value

        local theme = themeFor(library)
        library:_tween(knob, TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Position = UDim2.fromOffset(value and 23 or 3, 3),
            BackgroundColor3 = value and theme.Text or theme.SubText,
        })
        library:_tween(track, TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            BackgroundColor3 = value and theme.Accent or theme.Surface2,
        })

        if fireCallback ~= false then
            object:_fire(value)
        end

        return object
    end

    function object:GetValue()
        return object.Value
    end

    addConnection(object, track.Activated:Connect(function()
        if object.Disabled then
            return
        end
        object:SetValue(not object.Value)
    end))

    table.insert(self.Elements, object)
    object:SetValue(object.Value, false)
    return object
end

function Tab:AddToggle(config)
    return self:Toggle(config)
end

function Tab:CreateToggle(config)
    return self:Toggle(config)
end

function Tab:Slider(config)
    config = config or {}

    local library = self.Library
    local minValue = tonumber(config.Min or 0) or 0
    local maxValue = tonumber(config.Max or 100) or 100
    local rounding = tonumber(config.Rounding or 0) or 0

    if maxValue < minValue then
        minValue, maxValue = maxValue, minValue
    end

    local default = tonumber(config.Default)
    if default == nil then
        default = minValue
    end

    local frame = self:_newContainer(config.Height or 70)

    local title = library:_new("TextLabel", {
        Size = UDim2.new(1, -95, 0, 18),
        Position = UDim2.fromOffset(13, 8),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamSemibold,
        TextSize = 13,
        Text = tostring(config.Title or config.Name or "Slider"),
        TextXAlignment = Enum.TextXAlignment.Left,
    }, nil, {
        TextColor3 = "Text",
    })
    title.Parent = frame

    local valueLabel = library:_new("TextLabel", {
        Size = UDim2.fromOffset(80, 18),
        Position = UDim2.new(1, -92, 0, 8),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium,
        TextSize = 12,
        Text = "0",
        TextXAlignment = Enum.TextXAlignment.Right,
    }, nil, {
        TextColor3 = "SubText",
    })
    valueLabel.Parent = frame

    local rail = library:_new("Frame", {
        Size = UDim2.new(1, -26, 0, 6),
        Position = UDim2.fromOffset(13, 43),
        BorderSizePixel = 0,
    }, nil, {
        BackgroundColor3 = "Surface2",
    })
    rail.Parent = frame

    local railCorner = library:_new("UICorner", {
        CornerRadius = UDim.new(1, 0),
    })
    railCorner.Parent = rail

    local fill = library:_new("Frame", {
        Size = UDim2.fromScale(0, 1),
        BorderSizePixel = 0,
    }, nil, {
        BackgroundColor3 = "Accent",
    })
    fill.Parent = rail

    local fillCorner = library:_new("UICorner", {
        CornerRadius = UDim.new(1, 0),
    })
    fillCorner.Parent = fill

    local knob = library:_new("TextButton", {
        Size = UDim2.fromOffset(16, 16),
        Position = UDim2.new(0, -8, 0.5, -8),
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "",
    }, nil, {
        BackgroundColor3 = "Text",
    })
    knob.Parent = rail

    local knobCorner = library:_new("UICorner", {
        CornerRadius = UDim.new(1, 0),
    })
    knobCorner.Parent = knob

    local object = setmetatable({}, Element)
    object:_initBase(self, config, frame)
    object.TitleLabel = title
    object.ValueLabel = valueLabel
    object.Value = default
    object.Min = minValue
    object.Max = maxValue
    object.Rounding = rounding
    object.Rail = rail
    object.Fill = fill
    object.Knob = knob
    object._dragging = false

    function object:SetValue(value, fireCallback)
        value = tonumber(value) or object.Min
        local alpha = (value - object.Min) / (object.Max - object.Min)
        if object.Max == object.Min then
            alpha = 0
        end
        alpha = clampNumber(alpha, 0, 1)
        value = object.Min + ((object.Max - object.Min) * alpha)
        value = roundNumber(value, object.Rounding)
        value = clampNumber(value, object.Min, object.Max)

        object.Value = value
        valueLabel.Text = tostring(value)
        fill.Size = UDim2.new(alpha, 0, 1, 0)
        knob.Position = UDim2.new(alpha, -8, 0.5, -8)

        if fireCallback ~= false then
            object:_fire(value)
        end

        return object
    end

    function object:GetValue()
        return object.Value
    end

    local function setFromInput(input)
        local x = input.Position.X
        local absoluteX = rail.AbsolutePosition.X
        local width = rail.AbsoluteSize.X
        local alpha = 0
        if width > 0 then
            alpha = clampNumber((x - absoluteX) / width, 0, 1)
        end
        object:SetValue(object.Min + ((object.Max - object.Min) * alpha))
    end

    addConnection(object, knob.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            object._dragging = true
            setFromInput(input)
        end
    end))

    addConnection(object, rail.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            object._dragging = true
            setFromInput(input)
        end
    end))

    addConnection(object, UserInputService.InputChanged:Connect(function(input)
        if object._dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            setFromInput(input)
        end
    end))

    addConnection(object, UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            object._dragging = false
        end
    end))

    table.insert(self.Elements, object)
    object:SetValue(default, false)
    return object
end

function Tab:AddSlider(config)
    return self:Slider(config)
end

function Tab:CreateSlider(config)
    return self:Slider(config)
end

function Tab:Input(config)
    config = config or {}

    local library = self.Library
    local frame = self:_newContainer(config.Height or 54)

    local title = library:_new("TextLabel", {
        Size = UDim2.new(1, -185, 0, 18),
        Position = UDim2.fromOffset(13, 8),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamSemibold,
        TextSize = 13,
        Text = tostring(config.Title or config.Name or "Input"),
        TextXAlignment = Enum.TextXAlignment.Left,
    }, nil, {
        TextColor3 = "Text",
    })
    title.Parent = frame

    local desc = library:_new("TextLabel", {
        Size = UDim2.new(1, -185, 0, 15),
        Position = UDim2.fromOffset(13, 29),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        TextSize = 11,
        Text = tostring(config.Description or ""),
        TextTruncate = Enum.TextTruncate.AtEnd,
        TextXAlignment = Enum.TextXAlignment.Left,
        Visible = (config.Description or "") ~= "",
    }, nil, {
        TextColor3 = "SubText",
    })
    desc.Parent = frame

    local box = library:_new("TextBox", {
        Size = UDim2.fromOffset(config.Width or 155, 32),
        Position = UDim2.new(1, -10, 0.5, -16),
        AnchorPoint = Vector2.new(1, 0),
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        ClearTextOnFocus = false,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        Text = tostring(config.Default or ""),
        PlaceholderText = tostring(config.Placeholder or "Enter value..."),
        TextXAlignment = Enum.TextXAlignment.Left,
    }, nil, {
        TextColor3 = "Text",
        PlaceholderColor3 = "Muted",
        BackgroundColor3 = "Input",
    })
    box.Parent = frame

    local boxCorner = library:_new("UICorner", {
        CornerRadius = UDim.new(0, 8),
    })
    boxCorner.Parent = box

    local boxPadding = library:_new("UIPadding", {
        PaddingLeft = UDim.new(0, 9),
        PaddingRight = UDim.new(0, 9),
    })
    boxPadding.Parent = box

    local stroke = library:_new("UIStroke", {
        Thickness = 1,
        Transparency = 0.35,
    }, nil, {
        Color = "Border",
    })
    stroke.Parent = box

    local object = setmetatable({}, Element)
    object:_initBase(self, config, frame)
    object.TitleLabel = title
    object.DescLabel = desc
    object.Input = box
    object.Value = box.Text
    object.Numeric = config.Numeric == true
    object.Finished = config.Finished == true
    object.MaxLength = tonumber(config.MaxLength)

    function object:SetValue(value, fireCallback)
        value = tostring(value or "")

        if object.MaxLength and #value > object.MaxLength then
            value = value:sub(1, object.MaxLength)
        end

        if object.Numeric and value ~= "" and tonumber(value) == nil then
            return object
        end

        object.Value = value
        box.Text = value

        if fireCallback ~= false then
            object:_fire(value)
        end

        return object
    end

    function object:GetValue()
        return object.Value
    end

    local function updateFromText()
        object:SetValue(box.Text)
    end

    if object.Finished then
        addConnection(object, box.FocusLost:Connect(function()
            updateFromText()
        end))
    else
        addConnection(object, box:GetPropertyChangedSignal("Text"):Connect(function()
            if box.Text ~= object.Value then
                object:SetValue(box.Text)
            end
        end))
    end

    addConnection(object, box.Focused:Connect(function()
        library:_tween(stroke, TweenInfo.new(0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Transparency = 0.05,
        })
    end))

    addConnection(object, box.FocusLost:Connect(function()
        library:_tween(stroke, TweenInfo.new(0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Transparency = 0.35,
        })
    end))

    table.insert(self.Elements, object)
    return object
end

function Tab:AddInput(config)
    return self:Input(config)
end

function Tab:CreateInput(config)
    return self:Input(config)
end

function Tab:Textbox(config)
    return self:Input(config)
end

function Tab:AddTextbox(config)
    return self:Input(config)
end

function Tab:CreateTextbox(config)
    return self:Input(config)
end

function Tab:Dropdown(config)
    config = config or {}

    local library = self.Library
    local frame = self:_newContainer(config.Height or 54)
    local values = config.Values or config.Options or {}
    local multi = config.Multi == true
    local currentValue

    if multi then
        currentValue = {}
        local default = config.Default or {}
        if type(default) == "table" then
            for _, value in ipairs(default) do
                currentValue[value] = true
            end
        end
    else
        currentValue = config.Default
    end

    local title = library:_new("TextLabel", {
        Size = UDim2.new(1, -205, 0, 18),
        Position = UDim2.fromOffset(13, 8),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamSemibold,
        TextSize = 13,
        Text = tostring(config.Title or config.Name or "Dropdown"),
        TextXAlignment = Enum.TextXAlignment.Left,
    }, nil, {
        TextColor3 = "Text",
    })
    title.Parent = frame

    local desc = library:_new("TextLabel", {
        Size = UDim2.new(1, -205, 0, 15),
        Position = UDim2.fromOffset(13, 29),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        TextSize = 11,
        Text = tostring(config.Description or ""),
        TextTruncate = Enum.TextTruncate.AtEnd,
        TextXAlignment = Enum.TextXAlignment.Left,
        Visible = (config.Description or "") ~= "",
    }, nil, {
        TextColor3 = "SubText",
    })
    desc.Parent = frame

    local chooser = library:_new("TextButton", {
        Size = UDim2.fromOffset(config.Width or 175, 32),
        Position = UDim2.new(1, -10, 0.5, -16),
        AnchorPoint = Vector2.new(1, 0),
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        Text = "--",
        TextXAlignment = Enum.TextXAlignment.Left,
    }, nil, {
        BackgroundColor3 = "Input",
        TextColor3 = "Text",
    })
    chooser.Parent = frame

    local chooserCorner = library:_new("UICorner", {
        CornerRadius = UDim.new(0, 8),
    })
    chooserCorner.Parent = chooser

    local chooserPadding = library:_new("UIPadding", {
        PaddingLeft = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 28),
    })
    chooserPadding.Parent = chooser

    local arrow = library:_new("TextLabel", {
        Size = UDim2.fromOffset(22, 22),
        Position = UDim2.new(1, -5, 0.5, -11),
        AnchorPoint = Vector2.new(1, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        Text = "⌄",
        TextXAlignment = Enum.TextXAlignment.Center,
        TextYAlignment = Enum.TextYAlignment.Center,
    }, nil, {
        TextColor3 = "Muted",
    })
    arrow.Parent = chooser

    local object = setmetatable({}, Element)
    object:_initBase(self, config, frame)
    object.TitleLabel = title
    object.DescLabel = desc
    object.Button = chooser
    object.Values = values
    object.Value = currentValue
    object.Multi = multi
    object.Opened = false
    object._popup = nil
    object._overlay = nil

    local function formatValue()
        if multi then
            local selected = {}
            for _, value in ipairs(values) do
                if object.Value[value] then
                    table.insert(selected, tostring(value))
                end
            end
            if #selected == 0 then
                return "--"
            end
            local text = table.concat(selected, ", ")
            if #text > 32 then
                text = text:sub(1, 29) .. "..."
            end
            return text
        end

        if object.Value == nil or object.Value == "" then
            return "--"
        end

        return tostring(object.Value)
    end

    function object:SetValue(value, fireCallback)
        if object.Multi then
            local newValue = {}
            if type(value) == "table" then
                for _, option in ipairs(values) do
                    if value[option] == true then
                        newValue[option] = true
                    end
                end
                for key, enabled in pairs(value) do
                    if enabled and newValue[key] == nil then
                        newValue[key] = true
                    end
                end
            end
            object.Value = newValue
        else
            if value == nil or table.find(values, value) then
                object.Value = value
            end
        end

        chooser.Text = formatValue()
        if fireCallback ~= false then
            object:_fire(object.Value)
        end

        return object
    end

    function object:GetValue()
        if object.Multi then
            local copy = {}
            for key, value in pairs(object.Value) do
                copy[key] = value
            end
            return copy
        end
        return object.Value
    end

    function object:SetValues(newValues)
        object.Values = newValues or {}
        if object.Multi then
            object:SetValue(object.Value, false)
        elseif object.Value and not table.find(object.Values, object.Value) then
            object:SetValue(nil, false)
        end
        if object.Opened then
            object:Close()
            object:Open()
        end
        return object
    end

    local function closePopup()
        if not object._popup then
            return
        end

        object.Opened = false

        local popup = object._popup
        local overlay = object._overlay
        object._popup = nil
        object._overlay = nil

        if overlay then
            overlay.Visible = false
        end

        local targetSize = popup.Size
        library:_tween(popup, TweenInfo.new(0.13, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
            Size = UDim2.new(targetSize.X.Scale, targetSize.X.Offset, 0, 0),
        })

        task.delay(0.14, function()
            if popup and popup.Parent then
                popup:Destroy()
            end
        end)
    end

    function object:Close()
        closePopup()
        return object
    end

    function object:Open()
        if object.Opened or object.Destroyed then
            return object
        end

        object.Opened = true

        local viewport = library.GUI.AbsoluteSize
        local popupWidth = math.max(180, config.PopupWidth or chooser.AbsoluteSize.X)
        local itemHeight = 30
        local maxHeight = math.min(math.max(#values * itemHeight + 12, 52), config.MaxHeight or 240)

        local overlay = library:_new("TextButton", {
            Name = "DropdownOverlay",
            Size = UDim2.fromScale(1, 1),
            Position = UDim2.fromScale(0, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            Text = "",
            ZIndex = 90,
            Visible = true,
        })
        overlay.Parent = library.GUI
        object._overlay = overlay

        local popup = library:_new("Frame", {
            Name = "DropdownPopup",
            Size = UDim2.fromOffset(popupWidth, 0),
            Position = UDim2.fromOffset(0, 0),
            BorderSizePixel = 0,
            ZIndex = 100,
            ClipsDescendants = true,
        }, nil, {
            BackgroundColor3 = "Background2",
        })
        popup.Parent = library.GUI
        object._popup = popup

        local corner = library:_new("UICorner", {
            CornerRadius = UDim.new(0, 10),
        })
        corner.Parent = popup

        local stroke = library:_new("UIStroke", {
            Thickness = 1,
            Transparency = 0.18,
        }, nil, {
            Color = "BorderStrong",
        })
        stroke.Parent = popup

        local scrolling = library:_new("ScrollingFrame", {
            Size = UDim2.new(1, -8, 1, -8),
            Position = UDim2.fromOffset(4, 4),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 2,
            ScrollBarImageTransparency = 0.65,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            ZIndex = 101,
        }, nil, {
            ScrollBarImageColor3 = "Accent",
        })
        scrolling.Parent = popup

        local list = library:_new("UIListLayout", {
            Padding = UDim.new(0, 4),
            SortOrder = Enum.SortOrder.LayoutOrder,
        })
        list.Parent = scrolling

        local padding = library:_new("UIPadding", {
            PaddingLeft = UDim.new(0, 2),
            PaddingRight = UDim.new(0, 2),
            PaddingTop = UDim.new(0, 2),
            PaddingBottom = UDim.new(0, 2),
        })
        padding.Parent = scrolling

        for index, option in ipairs(values) do
            local selected = false
            if multi then
                selected = object.Value[option] == true
            else
                selected = object.Value == option
            end

            local optionButton = library:_new("TextButton", {
                Size = UDim2.new(1, -2, 0, 30),
                BackgroundTransparency = selected and 0.08 or 1,
                BorderSizePixel = 0,
                AutoButtonColor = false,
                Font = Enum.Font.GothamMedium,
                TextSize = 12,
                Text = tostring(option),
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Center,
                LayoutOrder = index,
                ZIndex = 102,
            }, nil, {
                BackgroundColor3 = "Accent",
                TextColor3 = "Text",
            })
            optionButton.Parent = scrolling

            local optionPadding = library:_new("UIPadding", {
                PaddingLeft = UDim.new(0, 9),
                PaddingRight = UDim.new(0, 9),
            })
            optionPadding.Parent = optionButton

            local capturedOption = option
            addConnection(object, optionButton.MouseEnter:Connect(function()
                if not selected then
                    optionButton.BackgroundTransparency = 0.92
                end
            end))

            addConnection(object, optionButton.MouseLeave:Connect(function()
                if not selected then
                    optionButton.BackgroundTransparency = 1
                end
            end))

            addConnection(object, optionButton.Activated:Connect(function()
                if multi then
                    object.Value[capturedOption] = not object.Value[capturedOption] or nil
                    if object.Value[capturedOption] ~= true then
                        object.Value[capturedOption] = nil
                    end
                    object:SetValue(object.Value)
                    selected = object.Value[capturedOption] == true
                    optionButton.BackgroundTransparency = selected and 0.08 or 1
                    if not config.CloseOnSelect then
                        return
                    end
                else
                    object:SetValue(capturedOption)
                end

                closePopup()
            end))
        end

        addConnection(object, list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            scrolling.CanvasSize = UDim2.new(0, 0, 0, list.AbsoluteContentSize.Y + 4)
        end))

        addConnection(object, overlay.Activated:Connect(function()
            closePopup()
        end))

        local x = chooser.AbsolutePosition.X
        local y = chooser.AbsolutePosition.Y + chooser.AbsoluteSize.Y + 6

        if y + maxHeight > viewport.Y - 8 then
            y = chooser.AbsolutePosition.Y - maxHeight - 6
        end

        x = clampNumber(x + chooser.AbsoluteSize.X - popupWidth, 8, math.max(8, viewport.X - popupWidth - 8))
        y = clampNumber(y, 8, math.max(8, viewport.Y - maxHeight - 8))

        popup.Position = UDim2.fromOffset(x, y)
        library:_tween(popup, TweenInfo.new(0.16, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Size = UDim2.fromOffset(popupWidth, maxHeight),
        })

        return object
    end

    addConnection(object, chooser.Activated:Connect(function()
        if object.Opened then
            object:Close()
        else
            object:Open()
        end
    end))

    table.insert(self.Elements, object)
    chooser.Text = formatValue()
    return object
end

function Tab:AddDropdown(config)
    return self:Dropdown(config)
end

function Tab:CreateDropdown(config)
    return self:Dropdown(config)
end

function Tab:MultiDropdown(config)
    config = config or {}
    config.Multi = true
    return self:Dropdown(config)
end

function Tab:AddMultiDropdown(config)
    return self:MultiDropdown(config)
end

function Tab:Keybind(config)
    config = config or {}

    local library = self.Library
    local frame = self:_newContainer(config.Height or 52)

    local title = library:_new("TextLabel", {
        Size = UDim2.new(1, -150, 1, 0),
        Position = UDim2.fromOffset(13, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamSemibold,
        TextSize = 13,
        Text = tostring(config.Title or config.Name or "Keybind"),
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
    }, nil, {
        TextColor3 = "Text",
    })
    title.Parent = frame

    local bindButton = library:_new("TextButton", {
        Size = UDim2.fromOffset(config.Width or 104, 30),
        Position = UDim2.new(1, -10, 0.5, -15),
        AnchorPoint = Vector2.new(1, 0),
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Font = Enum.Font.GothamMedium,
        TextSize = 12,
        Text = tostring(config.Default or "None"),
    }, nil, {
        BackgroundColor3 = "Input",
        TextColor3 = "SubText",
    })
    bindButton.Parent = frame

    local corner = library:_new("UICorner", {
        CornerRadius = UDim.new(0, 8),
    })
    corner.Parent = bindButton

    local stroke = library:_new("UIStroke", {
        Thickness = 1,
        Transparency = 0.32,
    }, nil, {
        Color = "Border",
    })
    stroke.Parent = bindButton

    local object = setmetatable({}, Element)
    object:_initBase(self, config, frame)
    object.TitleLabel = title
    object.Button = bindButton
    object.Value = tostring(config.Default or "None")
    object.Mode = tostring(config.Mode or "Toggle")
    object.Toggled = false
    object.Listening = false
    object._captureConnection = nil

    local function keyMatches(input)
        if object.Value == "None" then
            return false
        end

        if object.Value == "MouseLeft" then
            return input.UserInputType == Enum.UserInputType.MouseButton1
        end

        if object.Value == "MouseRight" then
            return input.UserInputType == Enum.UserInputType.MouseButton2
        end

        return input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode.Name == object.Value
    end

    local function trigger(value)
        safeCallback(object.Callback, value)
        safeCallback(object.Changed, value)
    end

    function object:SetValue(value, mode, fireCallback)
        object.Value = tostring(value or "None")
        if mode then
            object.Mode = tostring(mode)
        end
        bindButton.Text = object.Value
        if fireCallback ~= false then
            safeCallback(object.Config.ChangedCallback, object.Value, object.Mode)
        end
        return object
    end

    function object:GetValue()
        return object.Value
    end

    function object:GetState()
        if object.Mode == "Always" then
            return true
        elseif object.Mode == "Hold" then
            if object.Value == "None" then
                return false
            end
            if object.Value == "MouseLeft" then
                return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
            elseif object.Value == "MouseRight" then
                return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
            end
            pcall(function() return UserInputService:IsKeyDown(Enum.KeyCode[object.Value]) end)
            return UserInputService:IsKeyDown(Enum.KeyCode[object.Value])
        end
        return object.Toggled
    end

    local function stopCapture()
        object.Listening = false
        if object._captureConnection then
            disconnect(object._captureConnection)
            object._captureConnection = nil
        end
        bindButton.Text = object.Value
    end

    addConnection(object, bindButton.Activated:Connect(function()
        if object.Listening then
            return
        end

        object.Listening = true
        bindButton.Text = "..."
        object._captureConnection = UserInputService.InputBegan:Connect(function(input, processed)
            if processed then
                return
            end

            local value
            if input.UserInputType == Enum.UserInputType.Keyboard then
                value = input.KeyCode.Name
            elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
                value = "MouseLeft"
            elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
                value = "MouseRight"
            end

            if value then
                object:SetValue(value, object.Mode, false)
                stopCapture()
                safeCallback(object.Config.ChangedCallback, value, object.Mode)
            end
        end)
    end))

    addConnection(object, UserInputService.InputBegan:Connect(function(input, processed)
        if processed or object.Listening or object.Disabled then
            return
        end

        if UserInputService:GetFocusedTextBox() then
            return
        end

        if not keyMatches(input) then
            return
        end

        if object.Mode == "Toggle" then
            object.Toggled = not object.Toggled
            trigger(object.Toggled)
        elseif object.Mode == "Hold" then
            trigger(true)
        end
    end))

    addConnection(object, UserInputService.InputEnded:Connect(function(input)
        if object.Listening or object.Disabled then
            return
        end

        if object.Mode == "Hold" and keyMatches(input) then
            trigger(false)
        end
    end))

    table.insert(self.Elements, object)
    return object
end

function Tab:AddKeybind(config)
    return self:Keybind(config)
end

function Tab:CreateKeybind(config)
    return self:Keybind(config)
end

function Tab:Colorpicker(config)
    config = config or {}

    local library = self.Library
    local frame = self:_newContainer(config.Height or 50)

    local title = library:_new("TextLabel", {
        Size = UDim2.new(1, -70, 1, 0),
        Position = UDim2.fromOffset(13, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamSemibold,
        TextSize = 13,
        Text = tostring(config.Title or config.Name or "Colorpicker"),
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
    }, nil, {
        TextColor3 = "Text",
    })
    title.Parent = frame

    local preview = library:_new("TextButton", {
        Size = UDim2.fromOffset(48, 26),
        Position = UDim2.new(1, -10, 0.5, -13),
        AnchorPoint = Vector2.new(1, 0),
        AutoButtonColor = false,
        Text = "",
        BorderSizePixel = 0,
    }, nil, {
        BackgroundColor3 = config.Default or Color3.fromRGB(255, 255, 255),
    })
    preview.Parent = frame

    local previewCorner = library:_new("UICorner", {
        CornerRadius = UDim.new(0, 8),
    })
    previewCorner.Parent = preview

    local previewStroke = library:_new("UIStroke", {
        Thickness = 1,
        Transparency = 0.25,
    }, nil, {
        Color = "Border",
    })
    previewStroke.Parent = preview

    local object = setmetatable({}, Element)
    object:_initBase(self, config, frame)
    object.TitleLabel = title
    object.Preview = preview
    object.Value = typeof(config.Default) == "Color3" and config.Default or Color3.fromRGB(255, 255, 255)
    object.Transparency = tonumber(config.Transparency or 0) or 0
    object._dialog = nil

    function object:SetValue(color, transparency, fireCallback)
        if typeof(color) == "Color3" then
            object.Value = color
        end
        if transparency ~= nil then
            object.Transparency = clampNumber(tonumber(transparency) or 0, 0, 1)
        end
        preview.BackgroundColor3 = object.Value
        preview.BackgroundTransparency = object.Transparency
        if fireCallback ~= false then
            safeCallback(object.Config.Callback, object.Value, object.Transparency)
            safeCallback(object.Changed, object.Value, object.Transparency)
        end
        return object
    end

    function object:GetValue()
        return object.Value, object.Transparency
    end

    local function openPicker()
        if object._dialog then
            return
        end

        local dialog = library:_createDialog(object.Window, {
            Title = tostring(config.Title or "Colorpicker"),
            Content = "Enter a HEX color and apply it.",
            Width = 360,
            Height = 190,
            Buttons = {},
        })
        object._dialog = dialog

        local body = dialog.Body

        local label = library:_new("TextLabel", {
            Size = UDim2.new(1, -24, 0, 18),
            Position = UDim2.fromOffset(12, 54),
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamMedium,
            TextSize = 12,
            Text = "HEX",
            TextXAlignment = Enum.TextXAlignment.Left,
        }, nil, {
            TextColor3 = "SubText",
        })
        label.Parent = body

        local input = library:_new("TextBox", {
            Size = UDim2.new(1, -24, 0, 34),
            Position = UDim2.fromOffset(12, 78),
            BackgroundTransparency = 0,
            BorderSizePixel = 0,
            ClearTextOnFocus = false,
            Font = Enum.Font.Gotham,
            TextSize = 13,
            Text = "#" .. object.Value:ToHex(),
            PlaceholderText = "#FFFFFF",
            TextXAlignment = Enum.TextXAlignment.Left,
        }, nil, {
            BackgroundColor3 = "Input",
            TextColor3 = "Text",
            PlaceholderColor3 = "Muted",
        })
        input.Parent = body

        local corner = library:_new("UICorner", {
            CornerRadius = UDim.new(0, 8),
        })
        corner.Parent = input

        local padding = library:_new("UIPadding", {
            PaddingLeft = UDim.new(0, 10),
            PaddingRight = UDim.new(0, 10),
        })
        padding.Parent = input

        local cancel = dialog:AddButton("Cancel", function()
            dialog:Close()
            object._dialog = nil
        end)
        local apply = dialog:AddButton("Apply", function()
            local success, color = pcall(function()
                return Color3.fromHex(input.Text)
            end)
            if success and typeof(color) == "Color3" then
                object:SetValue(color)
            end
            dialog:Close()
            object._dialog = nil
        end)

        return dialog
    end

    addConnection(object, preview.Activated:Connect(function()
        openPicker()
    end))

    table.insert(self.Elements, object)
    object:SetValue(object.Value, object.Transparency, false)
    return object
end

function Tab:AddColorpicker(config)
    return self:Colorpicker(config)
end

function Tab:CreateColorpicker(config)
    return self:Colorpicker(config)
end

function Tab:ColorPicker(config)
    return self:Colorpicker(config)
end

function Tab:AddColorPicker(config)
    return self:Colorpicker(config)
end

function Tab:CreateColorPicker(config)
    return self:Colorpicker(config)
end

function Tab:Custom(config)
    config = config or {}
    local parent = self.Page
    local result

    if type(config.Builder) == "function" then
        result = config.Builder(parent, self, self.Library)
    elseif type(config.Create) == "function" then
        result = config.Create(parent, self, self.Library)
    end

    return result
end

function Tab:AddCustom(config)
    return self:Custom(config)
end

function Tab:GetElements()
    local result = {}
    for i, element in ipairs(self.Elements) do
        result[i] = element
    end
    return result
end

function Tab:SetName(name)
    self.Name = tostring(name or self.Name)
    self.Title = self.Name
    if self.NameLabel then
        self.NameLabel.Text = self.Name
    end
    return self
end

function Tab:Select()
    self.Window:SelectTab(self)
    return self
end

function Tab:Destroy()
    if self.Destroyed then
        return
    end

    self.Destroyed = true
    cleanupConnections(self)

    for i = #self.Elements, 1, -1 do
        local element = self.Elements[i]
        if typeof(element) == "table" and element.Destroy then
            pcall(function()
                element:Destroy()
            end)
        elseif typeof(element) == "Instance" then
            pcall(function()
                element:Destroy()
            end)
        end
        self.Elements[i] = nil
    end

    if self.Page then
        self.Page:Destroy()
    end

    if self.Button then
        self.Button:Destroy()
    end
end

-- ============================================================
-- Window
-- ============================================================

function Window.new(library, config)
    local self = setmetatable({}, Window)

    config = config or {}

    self.Library = library
    self.Config = config
    self.Name = tostring(config.Name or config.Title or "Selenium")
    self.Title = tostring(config.Title or "Selenium")
    self.Subtitle = tostring(config.Subtitle or config.SubTitle or "Premium UI Library")
    self.Width = math.max(460, tonumber(config.Width or (config.Size and config.Size.X.Offset) or 860) or 860)
    self.Height = math.max(320, tonumber(config.Height or (config.Size and config.Size.Y.Offset) or 540) or 540)
    self.MinWidth = tonumber(config.MinWidth or 460) or 460
    self.MinHeight = tonumber(config.MinHeight or 320) or 320
    self.MaxWidth = tonumber(config.MaxWidth or 1200) or 1200
    self.MaxHeight = tonumber(config.MaxHeight or 800) or 800
    self.SidebarWidth = tonumber(config.SidebarWidth or config.TabWidth or 178) or 178
    self.DisplayOrder = tonumber(config.DisplayOrder or 1000) or 1000
    self.Draggable = config.Draggable ~= false
    self.Resizable = config.Resizable ~= false
    self.ShowIsland = config.ShowDynamicIsland ~= false
    self.IslandText = tostring(config.IslandText or self.Title)
    self.ToggleKey = config.ToggleKey or config.MinimizeKey or Enum.KeyCode.RightShift
    self.Tabs = {}
    self.ActiveTab = nil
    self.Minimized = false
    self.Maximized = false
    self.Visible = true
    self.Destroyed = false
    self._connections = {}
    self._dragging = false
    self._resizing = false
    self._restoreSize = nil
    self._restorePosition = nil

    local libraryObject = library
    local theme = themeFor(library)

    local viewport = library.GUI.AbsoluteSize
    if viewport.X <= 0 or viewport.Y <= 0 then
        viewport = Vector2.new(1920, 1080)
    end

    self.Width = math.min(self.Width, math.max(self.MinWidth, viewport.X - 30))
    self.Height = math.min(self.Height, math.max(self.MinHeight, viewport.Y - 90))

    local centerPosition = UDim2.fromOffset(
        math.floor((viewport.X - self.Width) / 2),
        math.floor((viewport.Y - self.Height) / 2) + 10
    )

    self.Position = centerPosition

    local root = libraryObject:_new("Frame", {
        Name = self.Name,
        Size = UDim2.fromOffset(self.Width, self.Height),
        Position = centerPosition,
        BackgroundTransparency = 0.01,
        BorderSizePixel = 0,
        ZIndex = 10,
        Visible = true,
    }, nil, {
        BackgroundColor3 = "Background",
    })
    root.Parent = library.GUI
    self.Root = root

    local rootCorner = libraryObject:_new("UICorner", {
        CornerRadius = UDim.new(0, 16),
    })
    rootCorner.Parent = root

    local rootStroke = libraryObject:_new("UIStroke", {
        Thickness = 1,
        Transparency = 0.16,
    }, nil, {
        Color = "BorderStrong",
    })
    rootStroke.Parent = root
    self.RootStroke = rootStroke

    local shadow = libraryObject:_new("Frame", {
        Name = "Shadow",
        Size = UDim2.new(1, 20, 1, 20),
        Position = UDim2.fromOffset(-10, 10),
        BackgroundTransparency = 0.96,
        BorderSizePixel = 0,
        ZIndex = 9,
    }, nil, {
        BackgroundColor3 = "Overlay",
    })
    shadow.Parent = root

    local titleBar = libraryObject:_new("Frame", {
        Name = "TitleBar",
        Size = UDim2.new(1, 0, 0, 62),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 11,
    })
    titleBar.Parent = root
    self.TitleBar = titleBar

    local title = libraryObject:_new("TextLabel", {
        Size = UDim2.new(1, -165, 0, 22),
        Position = UDim2.fromOffset(20, 13),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 16,
        Text = self.Title,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 12,
    }, nil, {
        TextColor3 = "Text",
    })
    title.Parent = titleBar
    self.TitleLabel = title

    local subtitle = libraryObject:_new("TextLabel", {
        Size = UDim2.new(1, -165, 0, 17),
        Position = UDim2.fromOffset(20, 35),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        TextSize = 11,
        Text = self.Subtitle,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 12,
    }, nil, {
        TextColor3 = "SubText",
    })
    subtitle.Parent = titleBar
    self.SubtitleLabel = subtitle

    local separator = libraryObject:_new("Frame", {
        Size = UDim2.new(1, -40, 0, 1),
        Position = UDim2.fromOffset(20, 61),
        BackgroundTransparency = 0.1,
        BorderSizePixel = 0,
        ZIndex = 12,
    }, nil, {
        BackgroundColor3 = "Border",
    })
    separator.Parent = titleBar

    local function topButton(symbol, xOffset, callback)
        local button = libraryObject:_new("TextButton", {
            Size = UDim2.fromOffset(28, 28),
            Position = UDim2.new(1, xOffset, 0, 13),
            AnchorPoint = Vector2.new(1, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            Font = Enum.Font.GothamBold,
            TextSize = 14,
            Text = symbol,
            ZIndex = 13,
        }, nil, {
            TextColor3 = "SubText",
        })
        button.Parent = titleBar
        addConnection(self, button.MouseEnter:Connect(function()
            button.TextColor3 = themeFor(libraryObject).Text
        end))
        addConnection(self, button.MouseLeave:Connect(function()
            libraryObject:_applyThemeObject(button, { TextColor3 = "SubText" })
        end))
        addConnection(self, button.Activated:Connect(callback))
        return button
    end

    self.CloseButton = topButton("×", -13, function()
        self:Destroy()
    end)

    self.MaxButton = topButton("□", -46, function()
        self:Maximize(not self.Maximized)
    end)

    self.MinButton = topButton("—", -79, function()
        self:Minimize()
    end)

    local sidebar = libraryObject:_new("Frame", {
        Name = "Sidebar",
        Size = UDim2.new(0, self.SidebarWidth, 1, -78),
        Position = UDim2.fromOffset(14, 70),
        BackgroundTransparency = 0.02,
        BorderSizePixel = 0,
        ZIndex = 11,
    }, nil, {
        BackgroundColor3 = "Sidebar",
    })
    sidebar.Parent = root
    self.Sidebar = sidebar

    local sidebarCorner = libraryObject:_new("UICorner", {
        CornerRadius = UDim.new(0, 12),
    })
    sidebarCorner.Parent = sidebar

    local sidebarStroke = libraryObject:_new("UIStroke", {
        Thickness = 1,
        Transparency = 0.32,
    }, nil, {
        Color = "Border",
    })
    sidebarStroke.Parent = sidebar

    local sidebarTitle = libraryObject:_new("TextLabel", {
        Size = UDim2.new(1, -22, 0, 16),
        Position = UDim2.fromOffset(11, 13),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 10,
        Text = tostring(config.SidebarTitle or "NAVIGATION"),
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 12,
    }, nil, {
        TextColor3 = "Muted",
    })
    sidebarTitle.Parent = sidebar
    self.SidebarTitleLabel = sidebarTitle

    local tabList = libraryObject:_new("ScrollingFrame", {
        Name = "TabList",
        Size = UDim2.new(1, -12, 1, -42),
        Position = UDim2.fromOffset(6, 34),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 2,
        ScrollBarImageTransparency = 0.75,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ZIndex = 12,
    }, nil, {
        ScrollBarImageColor3 = "Accent",
    })
    tabList.Parent = sidebar
    self.TabList = tabList

    local tabLayout = libraryObject:_new("UIListLayout", {
        Padding = UDim.new(0, 5),
        SortOrder = Enum.SortOrder.LayoutOrder,
    })
    tabLayout.Parent = tabList

    local content = libraryObject:_new("Frame", {
        Name = "Content",
        Size = UDim2.new(1, -self.SidebarWidth - 42, 1, -78),
        Position = UDim2.fromOffset(self.SidebarWidth + 28, 70),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 11,
    })
    content.Parent = root
    self.Content = content

    local contentHeader = libraryObject:_new("TextLabel", {
        Name = "CurrentTab",
        Size = UDim2.new(1, -20, 0, 28),
        Position = UDim2.fromOffset(2, -1),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 20,
        Text = "",
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 12,
    }, nil, {
        TextColor3 = "Text",
    })
    contentHeader.Parent = content
    self.CurrentTabLabel = contentHeader

    local contentSubtitle = libraryObject:_new("TextLabel", {
        Name = "ContentHint",
        Size = UDim2.new(1, -20, 0, 18),
        Position = UDim2.fromOffset(2, 28),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        TextSize = 11,
        Text = tostring(config.ContentSubtitle or "Configure your interface below."),
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 12,
    }, nil, {
        TextColor3 = "SubText",
    })
    contentSubtitle.Parent = content
    self.ContentSubtitleLabel = contentSubtitle

    local holder = libraryObject:_new("Frame", {
        Name = "ContentHolder",
        Size = UDim2.new(1, 0, 1, -58),
        Position = UDim2.fromOffset(0, 58),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 11,
        ClipsDescendants = true,
    })
    holder.Parent = content
    self.ContentHolder = holder

    local statusFrame = libraryObject:_new("Frame", {
        Name = "Status",
        Size = UDim2.fromOffset(120, 22),
        Position = UDim2.new(1, -10, 1, -8),
        AnchorPoint = Vector2.new(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 15,
    })
    statusFrame.Parent = root
    self.StatusFrame = statusFrame

    local statusDot = libraryObject:_new("Frame", {
        Size = UDim2.fromOffset(6, 6),
        Position = UDim2.new(1, -90, 0.5, -3),
        BorderSizePixel = 0,
        ZIndex = 16,
    }, nil, {
        BackgroundColor3 = "Success",
    })
    statusDot.Parent = statusFrame

    local statusCorner = libraryObject:_new("UICorner", {
        CornerRadius = UDim.new(1, 0),
    })
    statusCorner.Parent = statusDot

    local statusLabel = libraryObject:_new("TextLabel", {
        Size = UDim2.fromOffset(78, 18),
        Position = UDim2.new(1, -79, 0.5, -9),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium,
        TextSize = 10,
        Text = tostring(config.Status or "Ready"),
        TextXAlignment = Enum.TextXAlignment.Right,
        ZIndex = 16,
    }, nil, {
        TextColor3 = "Muted",
    })
    statusLabel.Parent = statusFrame
    self.StatusDot = statusDot
    self.StatusLabel = statusLabel

    local resizeHandle = libraryObject:_new("TextButton", {
        Name = "ResizeHandle",
        Size = UDim2.fromOffset(24, 24),
        Position = UDim2.new(1, -5, 1, -5),
        AnchorPoint = Vector2.new(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "",
        ZIndex = 20,
        Visible = self.Resizable,
    })
    resizeHandle.Parent = root
    self.ResizeHandle = resizeHandle

    self:_applyLayout()
    self:_setupDrag()
    self:_setupResize()
    self:_setupToggleKey()
    self:_setupIsland()

    if config.Tab then
        if type(config.Tab) == "table" then
            self:CreateTab(config.Tab)
        end
    end

    return self
end

function Window:_applyLayout()
    if not self.Root then
        return
    end

    self.Root.Size = UDim2.fromOffset(self.Width, self.Height)
    self.Sidebar.Size = UDim2.new(0, self.SidebarWidth, 1, -78)
    self.Content.Size = UDim2.new(1, -self.SidebarWidth - 42, 1, -78)
    self.Content.Position = UDim2.fromOffset(self.SidebarWidth + 28, 70)
end

function Window:_setupDrag()
    if not self.Draggable then
        return
    end

    local dragInput
    local dragStart
    local startPosition

    addConnection(self, self.TitleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if self.Maximized then
                return
            end

            self._dragging = true
            dragStart = input.Position
            startPosition = self.Root.Position
            self:_bringToFront()

            addConnection(self, input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    self._dragging = false
                end
            end))
        end
    end))

    addConnection(self, self.TitleBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end))

    addConnection(self, UserInputService.InputChanged:Connect(function(input)
        if input ~= dragInput or not self._dragging then
            return
        end

        local delta = input.Position - dragStart
        local newX = startPosition.X.Offset + delta.X
        local newY = startPosition.Y.Offset + delta.Y

        local viewport = self.Library.GUI.AbsoluteSize
        local minX = 8
        local minY = 8
        local maxX = math.max(minX, viewport.X - self.Root.AbsoluteSize.X - 8)
        local maxY = math.max(minY, viewport.Y - self.Root.AbsoluteSize.Y - 8)

        self.Root.Position = UDim2.fromOffset(
            clampNumber(newX, minX, maxX),
            clampNumber(newY, minY, maxY)
        )
        self.Position = self.Root.Position
    end))
end

function Window:_setupResize()
    if not self.Resizable then
        return
    end

    local resizeInput
    local dragStart
    local startSize

    addConnection(self, self.ResizeHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            self._resizing = true
            resizeInput = input
            dragStart = input.Position
            startSize = Vector2.new(self.Root.AbsoluteSize.X, self.Root.AbsoluteSize.Y)
            self:_bringToFront()
        end
    end))

    addConnection(self, UserInputService.InputChanged:Connect(function(input)
        if not self._resizing then
            return
        end

        if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end

        local delta = input.Position - dragStart
        local viewport = self.Library.GUI.AbsoluteSize
        local width = clampNumber(startSize.X + delta.X, self.MinWidth, math.min(self.MaxWidth, viewport.X - 20))
        local height = clampNumber(startSize.Y + delta.Y, self.MinHeight, math.min(self.MaxHeight, viewport.Y - 70))

        self.Width = width
        self.Height = height
        self.Root.Size = UDim2.fromOffset(width, height)
    end))

    addConnection(self, UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            self._resizing = false
        end
    end))
end

function Window:_setupToggleKey()
    addConnection(self, UserInputService.InputBegan:Connect(function(input, processed)
        if processed or self.Destroyed then
            return
        end

        if UserInputService:GetFocusedTextBox() then
            return
        end

        if input.KeyCode == self.ToggleKey then
            self:Toggle()
        end
    end))
end

function Window:_setupIsland()
    local library = self.Library

    if not self.ShowIsland then
        return
    end

    local island = library:_new("Frame", {
        Name = "DynamicIsland",
        Size = UDim2.fromOffset(128, 38),
        Position = UDim2.fromScale(0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0),
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        ZIndex = 60,
    }, nil, {
        BackgroundColor3 = "Island",
    })
    island.Parent = library.GUI

    local corner = library:_new("UICorner", {
        CornerRadius = UDim.new(1, 0),
    })
    corner.Parent = island

    local stroke = library:_new("UIStroke", {
        Thickness = 1,
        Transparency = 0.1,
    }, nil, {
        Color = "Border",
    })
    stroke.Parent = island

    local dot = library:_new("Frame", {
        Size = UDim2.fromOffset(7, 7),
        Position = UDim2.fromOffset(14, 15),
        BorderSizePixel = 0,
        ZIndex = 62,
    }, nil, {
        BackgroundColor3 = "Accent",
    })
    dot.Parent = island

    local dotCorner = library:_new("UICorner", {
        CornerRadius = UDim.new(1, 0),
    })
    dotCorner.Parent = dot

    local button = library:_new("TextButton", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = self.IslandText,
        Font = Enum.Font.GothamSemibold,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Center,
        ZIndex = 61,
    }, nil, {
        TextColor3 = "Text",
    })
    button.Parent = island

    local panel = library:_new("Frame", {
        Name = "IslandPanel",
        Size = UDim2.fromOffset(280, 0),
        Position = UDim2.fromOffset(0, 42),
        AnchorPoint = Vector2.new(0.5, 0),
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        Visible = false,
        ZIndex = 59,
        ClipsDescendants = true,
    }, nil, {
        BackgroundColor3 = "Island",
    })
    panel.Parent = island

    local panelCorner = library:_new("UICorner", {
        CornerRadius = UDim.new(0, 14),
    })
    panelCorner.Parent = panel

    local panelStroke = library:_new("UIStroke", {
        Thickness = 1,
        Transparency = 0.1,
    }, nil, {
        Color = "Border",
    })
    panelStroke.Parent = panel

    local panelContent = library:_new("TextLabel", {
        Size = UDim2.new(1, -28, 1, -24),
        Position = UDim2.fromOffset(14, 12),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextWrapped = true,
        Text = "",
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        ZIndex = 61,
    }, nil, {
        TextColor3 = "SubText",
    })
    panelContent.Parent = panel

    self.Island = island
    self.IslandButton = button
    self.IslandDot = dot
    self.IslandPanel = panel
    self.IslandPanelContent = panelContent
    self.IslandExpanded = false

    addConnection(self, button.Activated:Connect(function()
        self:ToggleIsland()
    end))

    addConnection(self, button.MouseEnter:Connect(function()
        library:_tween(island, TweenInfo.new(0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Size = UDim2.fromOffset(140, 40),
        })
    end))

    addConnection(self, button.MouseLeave:Connect(function()
        if not self.IslandExpanded then
            library:_tween(island, TweenInfo.new(0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                Size = UDim2.fromOffset(128, 38),
            })
        end
    end))
end

function Window:_refreshIslandPosition()
    if self.Island and self.Island.Parent then
        self.Island.Position = UDim2.fromScale(0.5, 0)
    end
end

function Window:_bringToFront()
    if not self.Root then
        return
    end

    local highest = 10
    for _, window in ipairs(self.Library.Windows) do
        if window ~= self and window.Root and window.Root.Parent then
            highest = math.max(highest, window.Root.ZIndex)
        end
    end

    self.Root.ZIndex = highest + 1
end

function Window:_refreshTheme()
    self.Library:_refreshTheme()
end

function Window:CreateTab(config)
    if type(config) == "string" then
        config = { Name = config }
    end

    local tab = Tab.new(self, config or {})
    table.insert(self.Tabs, tab)

    if not self.ActiveTab then
        self:SelectTab(tab)
    end

    return tab
end

function Window:AddTab(config)
    return self:CreateTab(config)
end

function Window:NewTab(config)
    return self:CreateTab(config)
end

function Window:CreatePage(config)
    return self:CreateTab(config)
end

function Window:GetTabs()
    local result = {}
    for i, tab in ipairs(self.Tabs) do
        result[i] = tab
    end
    return result
end

function Window:SelectTab(tabOrIndex)
    if self.Destroyed then
        return self
    end

    local tab = tabOrIndex
    if type(tabOrIndex) == "number" then
        tab = self.Tabs[tabOrIndex]
    end

    if not tab then
        return self
    end

    for _, current in ipairs(self.Tabs) do
        local selected = current == tab
        current.Page.Visible = selected
        current.Button.BackgroundTransparency = selected and 0.88 or 1
        current.NameLabel.TextColor3 = selected and themeFor(self.Library).Text or themeFor(self.Library).SubText
        current.IconLabel.TextColor3 = selected and themeFor(self.Library).Text or themeFor(self.Library).SubText
        current.Indicator.BackgroundTransparency = selected and 0 or 1
    end

    self.ActiveTab = tab
    self.CurrentTabLabel.Text = tab.Name
    self.ContentSubtitleLabel.Text = tostring(tab.Description or self.Config.ContentSubtitle or "Configure your interface below.")
    self:_bringToFront()

    return self
end

function Window:SetTitle(title)
    self.Title = tostring(title or self.Title)
    self.Config.Title = self.Title
    if self.TitleLabel then
        self.TitleLabel.Text = self.Title
    end
    if self.IslandButton then
        self.IslandButton.Text = self.IslandText ~= "" and self.IslandText or self.Title
    end
    return self
end

function Window:SetSubtitle(subtitle)
    self.Subtitle = tostring(subtitle or "")
    self.Config.Subtitle = self.Subtitle
    if self.SubtitleLabel then
        self.SubtitleLabel.Text = self.Subtitle
    end
    return self
end

function Window:SetSidebarTitle(title)
    if self.SidebarTitleLabel then
        self.SidebarTitleLabel.Text = tostring(title or "")
    end
    return self
end

function Window:SetStatus(text, statusType)
    if self.StatusLabel then
        self.StatusLabel.Text = tostring(text or "")
    end

    if self.StatusDot then
        local theme = themeFor(self.Library)
        local color = theme.Success
        if statusType == "error" or statusType == "danger" then
            color = theme.Danger
        elseif statusType == "warning" then
            color = theme.Accent
        elseif statusType and typeof(statusType) == "Color3" then
            color = statusType
        end
        self.StatusDot.BackgroundColor3 = color
    end

    self:SetIsland(tostring(text or self.IslandText), 2.2)
    return self
end

function Window:SetSize(width, height)
    width = tonumber(width) or self.Width
    height = tonumber(height) or self.Height

    local viewport = self.Library.GUI.AbsoluteSize
    self.Width = clampNumber(width, self.MinWidth, math.min(self.MaxWidth, math.max(self.MinWidth, viewport.X - 20)))
    self.Height = clampNumber(height, self.MinHeight, math.min(self.MaxHeight, math.max(self.MinHeight, viewport.Y - 70)))

    self.Root.Size = UDim2.fromOffset(self.Width, self.Height)
    return self
end

function Window:GetSize()
    return self.Width, self.Height
end

function Window:SetPosition(x, y)
    self.Root.Position = UDim2.fromOffset(tonumber(x) or 0, tonumber(y) or 0)
    self.Position = self.Root.Position
    return self
end

function Window:GetPosition()
    return self.Root.Position
end

function Window:Center()
    local viewport = self.Library.GUI.AbsoluteSize
    local x = math.floor((viewport.X - self.Root.AbsoluteSize.X) / 2)
    local y = math.floor((viewport.Y - self.Root.AbsoluteSize.Y) / 2) + 10
    self:SetPosition(x, y)
    return self
end

function Window:SetTheme(themeName)
    self.Library:SetTheme(themeName)
    return self
end

function Window:GetTheme()
    return self.Library:GetTheme()
end

function Window:SetToggleKey(keyCode)
    if keyCode then
        self.ToggleKey = keyCode
    end
    return self
end

function Window:GetToggleKey()
    return self.ToggleKey
end

function Window:SetDraggable(enabled)
    self.Draggable = enabled and true or false
    return self
end

function Window:SetResizable(enabled)
    self.Resizable = enabled and true or false
    if self.ResizeHandle then
        self.ResizeHandle.Visible = self.Resizable
    end
    return self
end

function Window:SetVisible(visible)
    visible = visible and true or false
    self.Visible = visible
    self.Minimized = not visible
    self.Root.Visible = visible
    return self
end

function Window:Show()
    self.Visible = true
    self.Minimized = false
    self.Root.Visible = true
    self:_bringToFront()
    return self
end

function Window:Hide()
    self.Visible = false
    self.Minimized = true
    self.Root.Visible = false
    return self
end

function Window:Toggle()
    if self.Root.Visible then
        self:Hide()
    else
        self:Show()
    end
    return self
end

function Window:Focus()
    self:Show()
    self:_bringToFront()
    return self
end

function Window:Minimize()
    self.Minimized = not self.Minimized
    if self.Minimized then
        self.Root.Visible = false
        self.Visible = false
        self:SetIsland("Selenium minimized", 2.0)
    else
        self.Root.Visible = true
        self.Visible = true
        self:SetIsland(self.IslandText, 1.2)
        self:_bringToFront()
    end
    return self
end

function Window:Maximize(force)
    if force == nil then
        force = not self.Maximized
    end

    local viewport = self.Library.GUI.AbsoluteSize

    if force and not self.Maximized then
        self._restoreSize = Vector2.new(self.Root.AbsoluteSize.X, self.Root.AbsoluteSize.Y)
        self._restorePosition = self.Root.Position
        self.Maximized = true

        self.Root.Position = UDim2.fromOffset(8, 8)
        self.Width = math.max(self.MinWidth, viewport.X - 16)
        self.Height = math.max(self.MinHeight, viewport.Y - 16)
        self.Root.Size = UDim2.fromOffset(self.Width, self.Height)
        self.MaxButton.Text = "❐"
    elseif not force and self.Maximized then
        self.Maximized = false

        if self._restoreSize then
            self.Width = self._restoreSize.X
            self.Height = self._restoreSize.Y
        end
        if self._restorePosition then
            self.Root.Position = self._restorePosition
        end

        self.Root.Size = UDim2.fromOffset(self.Width, self.Height)
        self.MaxButton.Text = "□"
    end

    return self
end

function Window:SetIsland(text, duration)
    self.IslandText = tostring(text or self.IslandText)

    if not self.Island or not self.IslandButton then
        return self
    end

    self.IslandButton.Text = self.IslandText

    if duration then
        local token = tostring(os.clock())
        self._islandToken = token
        task.delay(duration, function()
            if self.Destroyed then
                return
            end
            if self._islandToken == token then
                self.IslandButton.Text = tostring(self.Config.IslandText or self.Title)
            end
        end)
    end

    return self
end

function Window:ToggleIsland(force)
    if not self.Island or not self.IslandPanel then
        return self
    end

    if force == nil then
        force = not self.IslandExpanded
    end

    self.IslandExpanded = force

    if force then
        self.IslandPanel.Visible = true
        self.IslandPanelContent.Text = tostring(self.IslandText) .. "\n\n" .. tostring(self.Title) .. "\n" .. tostring(self.Subtitle)
        self.Library:_tween(self.IslandPanel, TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Size = UDim2.fromOffset(280, 120),
        })
        self.Library:_tween(self.Island, TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Size = UDim2.fromOffset(280, 162),
        })
    else
        self.Library:_tween(self.IslandPanel, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Size = UDim2.fromOffset(280, 0),
        })
        self.Library:_tween(self.Island, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Size = UDim2.fromOffset(128, 38),
        })
        task.delay(0.16, function()
            if self.IslandPanel and self.IslandPanel.Parent and not self.IslandExpanded then
                self.IslandPanel.Visible = false
            end
        end)
    end

    return self
end

function Window:SetIslandVisible(visible)
    if self.Island then
        self.Island.Visible = visible and true or false
    end
    return self
end

function Window:Notify(config)
    config = config or {}

    local library = self.Library
    if not self.NotificationHolder then
        local holder = library:_new("Frame", {
            Name = "Notifications",
            Size = UDim2.fromOffset(330, 360),
            Position = UDim2.new(1, -18, 1, -18),
            AnchorPoint = Vector2.new(1, 1),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ZIndex = 200,
        })
        holder.Parent = library.GUI

        local layout = library:_new("UIListLayout", {
            FillDirection = Enum.FillDirection.Vertical,
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            VerticalAlignment = Enum.VerticalAlignment.Bottom,
            Padding = UDim.new(0, 8),
            SortOrder = Enum.SortOrder.LayoutOrder,
        })
        layout.Parent = holder
        self.NotificationHolder = holder
    end

    local duration = tonumber(config.Duration)
    if duration == nil then
        duration = 4
    end

    local toast = library:_new("Frame", {
        Size = UDim2.fromOffset(315, 76),
        Position = UDim2.fromOffset(35, 0),
        BackgroundTransparency = 0.03,
        BorderSizePixel = 0,
        ZIndex = 201,
        LayoutOrder = -os.clock(),
    }, nil, {
        BackgroundColor3 = "Background2",
    })
    toast.Parent = self.NotificationHolder

    local corner = library:_new("UICorner", {
        CornerRadius = UDim.new(0, 11),
    })
    corner.Parent = toast

    local stroke = library:_new("UIStroke", {
        Thickness = 1,
        Transparency = 0.18,
    }, nil, {
        Color = "BorderStrong",
    })
    stroke.Parent = toast

    local title = library:_new("TextLabel", {
        Size = UDim2.new(1, -38, 0, 18),
        Position = UDim2.fromOffset(13, 10),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        Text = tostring(config.Title or "Selenium"),
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 203,
    }, nil, {
        TextColor3 = "Text",
    })
    title.Parent = toast

    local content = library:_new("TextLabel", {
        Size = UDim2.new(1, -26, 0, 38),
        Position = UDim2.fromOffset(13, 32),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextWrapped = true,
        Text = tostring(config.Content or config.SubContent or ""),
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        ZIndex = 203,
    }, nil, {
        TextColor3 = "SubText",
    })
    content.Parent = toast

    local typeBar = library:_new("Frame", {
        Size = UDim2.fromOffset(3, 46),
        Position = UDim2.fromOffset(0, 15),
        BorderSizePixel = 0,
        ZIndex = 204,
    }, nil, {
        BackgroundColor3 = "Accent",
    })
    typeBar.Parent = toast

    local statusType = tostring(config.Type or "info"):lower()
    if statusType == "success" then
        typeBar.BackgroundColor3 = themeFor(library).Success
    elseif statusType == "error" or statusType == "danger" then
        typeBar.BackgroundColor3 = themeFor(library).Danger
    elseif statusType == "warning" then
        typeBar.BackgroundColor3 = themeFor(library).Accent
    end

    local closed = false
    local notification = {}

    function notification:Close()
        if closed then
            return
        end
        closed = true
        library:_tween(toast, TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
            Position = UDim2.fromOffset(35, 0),
            BackgroundTransparency = 1,
        })
        task.delay(0.19, function()
            if toast and toast.Parent then
                toast:Destroy()
            end
        end)
    end

    notification.Frame = toast
    notification.Title = title
    notification.Content = content

    library:_tween(toast, TweenInfo.new(0.24, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
        Position = UDim2.fromOffset(0, 0),
    })

    if duration > 0 then
        task.delay(duration, function()
            notification:Close()
        end)
    end

    return notification
end

function Window:_createDialogBase(config)
    local library = self.Library
    local theme = themeFor(library)

    local overlay = library:_new("TextButton", {
        Name = "DialogOverlay",
        Size = UDim2.fromScale(1, 1),
        Position = UDim2.fromScale(0, 0),
        BackgroundTransparency = 0.28,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "",
        ZIndex = 500,
    }, nil, {
        BackgroundColor3 = "Overlay",
    })
    overlay.Parent = library.GUI

    local root = library:_new("Frame", {
        Name = "Dialog",
        Size = UDim2.fromOffset(config.Width or 380, config.Height or 220),
        Position = UDim2.fromScale(0.5, 0.5),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 0.02,
        BorderSizePixel = 0,
        ZIndex = 501,
    }, nil, {
        BackgroundColor3 = "Background2",
    })
    root.Parent = library.GUI

    local scale = library:_new("UIScale", {
        Scale = 0.92,
    })
    scale.Parent = root

    local corner = library:_new("UICorner", {
        CornerRadius = UDim.new(0, 14),
    })
    corner.Parent = root

    local stroke = library:_new("UIStroke", {
        Thickness = 1,
        Transparency = 0.12,
    }, nil, {
        Color = "BorderStrong",
    })
    stroke.Parent = root

    local title = library:_new("TextLabel", {
        Size = UDim2.new(1, -30, 0, 24),
        Position = UDim2.fromOffset(15, 16),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 15,
        Text = tostring(config.Title or "Dialog"),
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 503,
    }, nil, {
        TextColor3 = "Text",
    })
    title.Parent = root

    local body = library:_new("Frame", {
        Size = UDim2.new(1, -30, 1, -100),
        Position = UDim2.fromOffset(15, 46),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 502,
    })
    body.Parent = root

    local content = library:_new("TextLabel", {
        Size = UDim2.new(1, 0, 0, 52),
        Position = UDim2.fromOffset(0, 6),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextWrapped = true,
        Text = tostring(config.Content or ""),
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        ZIndex = 503,
    }, nil, {
        TextColor3 = "SubText",
    })
    content.Parent = body

    local buttonBar = library:_new("Frame", {
        Size = UDim2.new(1, -30, 0, 44),
        Position = UDim2.new(0, 15, 1, -56),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 503,
    })
    buttonBar.Parent = root

    local buttonLayout = library:_new("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
    })
    buttonLayout.Parent = buttonBar

    local dialog = {
        Window = self,
        Library = library,
        Root = root,
        Overlay = overlay,
        Body = body,
        Title = title,
        Content = content,
        ButtonBar = buttonBar,
        Scale = scale,
        Buttons = {},
        Closed = false,
        _connections = {},
    }

    function dialog:AddButton(name, callback)
        local button = library:_new("TextButton", {
            Size = UDim2.fromOffset(92, 32),
            BackgroundTransparency = 0.02,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            Font = Enum.Font.GothamSemibold,
            TextSize = 12,
            Text = tostring(name or "Button"),
            LayoutOrder = #dialog.Buttons + 1,
            ZIndex = 504,
        }, nil, {
            BackgroundColor3 = "Surface",
            TextColor3 = "Text",
        })
        button.Parent = buttonBar

        local cornerButton = library:_new("UICorner", {
            CornerRadius = UDim.new(0, 8),
        })
        cornerButton.Parent = button

        local strokeButton = library:_new("UIStroke", {
            Thickness = 1,
            Transparency = 0.28,
        }, nil, {
            Color = "Border",
        })
        strokeButton.Parent = button

        addConnection(dialog, button.Activated:Connect(function()
            safeCallback(callback)
        end))

        table.insert(dialog.Buttons, button)
        return button
    end

    function dialog:Open()
        if dialog.Closed then
            return dialog
        end
        root.Visible = true
        overlay.Visible = true
        library:_tween(scale, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Scale = 1,
        })
        library:_tween(root, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            BackgroundTransparency = 0.02,
        })
        return dialog
    end

    function dialog:Close()
        if dialog.Closed then
            return
        end
        dialog.Closed = true
        cleanupConnections(dialog)
        library:_tween(scale, TweenInfo.new(0.14, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
            Scale = 0.92,
        })
        task.delay(0.15, function()
            if root and root.Parent then
                root:Destroy()
            end
            if overlay and overlay.Parent then
                overlay:Destroy()
            end
        end)
    end

    addConnection(dialog, overlay.Activated:Connect(function()
        if config.CloseOnOverlay ~= false then
            dialog:Close()
        end
    end))

    return dialog
end

function Window:Dialog(config)
    config = config or {}
    local dialog = self:_createDialogBase(config)

    if config.Buttons then
        for _, buttonConfig in ipairs(config.Buttons) do
            if type(buttonConfig) == "table" then
                dialog:AddButton(buttonConfig.Title or buttonConfig.Name or "Button", function()
                    safeCallback(buttonConfig.Callback)
                    if buttonConfig.Close ~= false then
                        dialog:Close()
                    end
                end)
            end
        end
    elseif config.Button then
        dialog:AddButton(config.Button, function()
            safeCallback(config.Callback)
            dialog:Close()
        end)
    end

    dialog:Open()
    return dialog
end

function Window:Confirm(title, content, yesCallback, noCallback)
    return self:Dialog({
        Title = title or "Confirm",
        Content = content or "Are you sure?",
        Buttons = {
            {
                Title = "Cancel",
                Callback = noCallback,
            },
            {
                Title = "Confirm",
                Callback = yesCallback,
            },
        },
    })
end

Window.CreateDialog = Window.Dialog

function Library:_createDialog(window, config)
    return window:_createDialogBase(config)
end

function Window:GetCurrentTab()
    return self.ActiveTab
end

function Window:Tab(config)
    return self:CreateTab(config)
end

function Window:SetContentSubtitle(text)
    self.Config.ContentSubtitle = tostring(text or "")
    if self.ContentSubtitleLabel then
        self.ContentSubtitleLabel.Text = self.Config.ContentSubtitle
    end
    return self
end

function Window:SetSidebarWidth(width)
    width = math.max(130, tonumber(width) or self.SidebarWidth)
    self.SidebarWidth = width
    self:_applyLayout()
    return self
end

function Window:Close()
    return self:Destroy()
end

function Window:Unload()
    return self:Destroy()
end

function Window:ToggleUI()
    return self:Toggle()
end

function Window:Destroy()
    if self.Destroyed then
        return
    end

    self.Destroyed = true
    cleanupConnections(self)

    for i = #self.Tabs, 1, -1 do
        local tab = self.Tabs[i]
        if tab then
            pcall(function()
                tab:Destroy()
            end)
        end
        self.Tabs[i] = nil
    end

    if self.NotificationHolder then
        self.NotificationHolder:Destroy()
    end

    if self.Island then
        self.Island:Destroy()
    end

    if self.Root then
        self.Root:Destroy()
    end

    for i = #self.Library.Windows, 1, -1 do
        if self.Library.Windows[i] == self then
            table.remove(self.Library.Windows, i)
            break
        end
    end

    if self.Library.Window == self then
        self.Library.Window = self.Library.Windows[#self.Library.Windows]
    end
end

-- ============================================================
-- Library convenience / aliases
-- ============================================================

function Library:Unload()
    return self:Destroy()
end

function Library:DestroyAll()
    return self:Destroy()
end

function Library:Toggle()
    if self.Window then
        return self.Window:Toggle()
    end
    return self
end

function Library:Show()
    if self.Window then
        self.Window:Show()
    end
    return self
end

function Library:Hide()
    if self.Window then
        self.Window:Hide()
    end
    return self
end

function Library:Create(config)
    return self:CreateWindow(config)
end

function Library:New(config)
    return self:CreateWindow(config)
end

function Library:IsLoaded()
    return not self.Unloaded
end

Library.CreateGUI = Library.CreateWindow
Library.Load = Library.CreateWindow

-- Expose common aliases used by UI libraries.
Library.AddTab = function(self, config)
    local window = self.Window or self:CreateWindow({})
    return window:CreateTab(config)
end

-- One-time optional blur, intentionally lightweight and only used by the Glass blur theme.
function Library:SetBlur(enabled)
    enabled = enabled and true or false

    if not enabled then
        if self._blurEffect then
            self._blurEffect.Enabled = false
        end
        return self
    end

    if not self._blurEffect then
        local blur = Instance.new("BlurEffect")
        blur.Name = "SeleniumBlur"
        blur.Size = 10
        blur.Enabled = false
        blur.Parent = Lighting
        self._blurEffect = blur
    end

    self._blurEffect.Enabled = true
    return self
end

function Window:SetBlur(enabled)
    self.Library:SetBlur(enabled)
    return self
end

-- Enable blur automatically only when explicitly requested by the window.
if Library.Theme == "Glass blur" then
    Library:SetBlur(false)
end

return Library

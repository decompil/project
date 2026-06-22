-- Variables
    local ServiceCache = {}
    getgenv().Services = setmetatable({}, {__index = function(self, idx)
        if not ServiceCache[idx] then
            local ok, svc = pcall(function() return cloneref(game:GetService(idx)) end)
            if not ok then svc = game:GetService(idx) end
            ServiceCache[idx] = svc
        end
        return ServiceCache[idx]
    end})

    local UserInputService = Services.UserInputService
    local TweenService     = Services.TweenService
    local RunService       = Services.RunService
    local HttpService      = Services.HttpService
    local Players          = Services.Players
    local CoreGui          = Services.CoreGui
    local GuiService       = Services.GuiService

    local vec2, dim2, dim = Vector2.new, UDim2.new, UDim.new
    local rgb, hex = Color3.fromRGB, Color3.fromHex
    local insert, find, remove = table.insert, table.find, table.remove

    local Camera      = workspace.CurrentCamera
    local LocalPlayer = Players.LocalPlayer
    local Mouse       = LocalPlayer:GetMouse()
    local GuiOffset   = GuiService:GetGuiInset().Y

    local Keys = {
        [Enum.KeyCode.LeftShift] = "shift", [Enum.KeyCode.RightShift] = "rshift",
        [Enum.KeyCode.LeftControl] = "ctrl", [Enum.KeyCode.RightControl] = "rctrl",
        [Enum.KeyCode.Insert] = "ins", [Enum.KeyCode.Backspace] = "back",
        [Enum.KeyCode.Return] = "ent", [Enum.KeyCode.LeftAlt] = "alt",
        [Enum.KeyCode.RightAlt] = "ralt", [Enum.KeyCode.CapsLock] = "caps",
        [Enum.KeyCode.One] = "1", [Enum.KeyCode.Two] = "2", [Enum.KeyCode.Three] = "3",
        [Enum.KeyCode.Four] = "4", [Enum.KeyCode.Five] = "5", [Enum.KeyCode.Six] = "6",
        [Enum.KeyCode.Seven] = "7", [Enum.KeyCode.Eight] = "8", [Enum.KeyCode.Nine] = "9",
        [Enum.KeyCode.Zero] = "0",
        [Enum.KeyCode.Minus] = "-", [Enum.KeyCode.Equals] = "=", [Enum.KeyCode.Tilde] = "~",
        [Enum.KeyCode.LeftBracket] = "[", [Enum.KeyCode.RightBracket] = "]",
        [Enum.KeyCode.Semicolon] = ";", [Enum.KeyCode.Quote] = "'",
        [Enum.KeyCode.BackSlash] = "\\", [Enum.KeyCode.Comma] = ",",
        [Enum.KeyCode.Period] = ".", [Enum.KeyCode.Slash] = "/",
        [Enum.UserInputType.MouseButton1] = "mouse1",
        [Enum.UserInputType.MouseButton2] = "mouse2",
        [Enum.UserInputType.MouseButton3] = "mouse3",
        [Enum.KeyCode.Escape] = "esc", [Enum.KeyCode.Space] = "space",
    }
--

if getgenv().Library and getgenv().Library.Unload then
    pcall(function() getgenv().Library:Unload() end)
end

-- Library init
getgenv().Library = {
    Directory      = "randomniceui",
    Flags          = {},
    ConfigFlags    = {},
    Connections    = {},
    OpenElement    = nil,
    EasingStyle    = Enum.EasingStyle.Quad,
    TweeningSpeed  = 0.12,
}; do
    Library.__index = Library
    local Flags = Library.Flags
    local ConfigFlags = Library.ConfigFlags

    local Theme = {
        Background    = rgb(36, 36, 38),
        BackgroundAlt = rgb(40, 40, 42),
        TopBar        = rgb(28, 28, 30),
        SubTabBar     = rgb(32, 32, 34),
        ContentBg     = rgb(36, 36, 38),
        Border        = rgb(20, 20, 22),
        BorderLight   = rgb(60, 60, 64),
        ElementBg     = rgb(28, 28, 30),
        Track         = rgb(50, 50, 54),
        Accent        = rgb(218, 201, 98),
        AccentDark    = rgb(170, 156, 70),
        Text          = rgb(238, 238, 240),
        TextDim       = rgb(178, 180, 184),
        TextMuted     = rgb(130, 132, 138),
        TextDisabled  = rgb(95, 98, 105),
        SectionHeader = rgb(218, 201, 98),
        TabActive     = rgb(255, 255, 255),
        TabInactive   = rgb(135, 135, 135),
    }
    Library.Theme = Theme

    local TextFont = Font.new("rbxasset://fonts/families/Verdana.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    local BoldFont = Font.new("rbxasset://fonts/families/Verdana.json", Enum.FontWeight.Bold,    Enum.FontStyle.Normal)
    Library.Font = TextFont
    Library.BoldFont = BoldFont
--

-- Utility
    function Library:Tween(obj, props, time, style)
        local info = TweenInfo.new(time or Library.TweeningSpeed, style or Library.EasingStyle, Enum.EasingDirection.Out)
        local t = TweenService:Create(obj, info, props)
        t:Play()
        return t
    end

    function Library:Connection(signal, fn)
        local c = signal:Connect(fn)
        insert(Library.Connections, c)
        return c
    end

    function Library:Create(class, props)
        local inst = Instance.new(class)
        for k, v in next, props or {} do
            if k ~= "Parent" then inst[k] = v end
        end
        inst.Name = "\0"
        if props and props.Parent then inst.Parent = props.Parent end
        return inst
    end

    function Library:Stroke(parent, color, thickness, transparency)
        return self:Create("UIStroke", {
            Color = color or Theme.Border,
            Thickness = thickness or 1,
            Transparency = transparency or 0,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            Parent = parent,
        })
    end

    function Library:Padding(parent, t, r, b, l)
        return self:Create("UIPadding", {
            PaddingTop    = dim(0, t or 0),
            PaddingRight  = dim(0, r or t or 0),
            PaddingBottom = dim(0, b or t or 0),
            PaddingLeft   = dim(0, l or r or t or 0),
            Parent = parent,
        })
    end

    function Library:Draggify(frame, dragger)
        dragger = dragger or frame
        local dragging, startPos, startMouse
        Library:Connection(dragger.InputBegan, function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                startMouse = input.Position
                startPos = frame.Position
            end
        end)
        Library:Connection(dragger.InputEnded, function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
        end)
        Library:Connection(UserInputService.InputChanged, function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                local delta = input.Position - startMouse
                frame.Position = dim2(
                    startPos.X.Scale, startPos.X.Offset + delta.X,
                    startPos.Y.Scale, startPos.Y.Offset + delta.Y
                )
            end
        end)
    end

    function Library:CloseOpen()
        if Library.OpenElement and Library.OpenElement.Close then
            Library.OpenElement.Close()
            Library.OpenElement = nil
        end
    end

    function Library:Unload()
        for _, c in next, Library.Connections do
            pcall(function() c:Disconnect() end)
        end
        Library.Connections = {}
        if Library.Holder then Library.Holder:Destroy() end
        if Library.HUD then Library.HUD:Destroy() end
    end
--

-- Holder
    local Holder = Library:Create("ScreenGui", {
        IgnoreGuiInset = true,
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 9999,
    })
    pcall(function()
        if gethui then Holder.Parent = gethui()
        elseif syn and syn.protect_gui then syn.protect_gui(Holder); Holder.Parent = CoreGui
        else Holder.Parent = CoreGui end
    end)
    if not Holder.Parent then Holder.Parent = LocalPlayer:WaitForChild("PlayerGui") end
    Library.Holder = Holder

    Library.Visible = true
    Library.FadeTime = 0.18
    local FadeProps = {
        Frame          = {"BackgroundTransparency"},
        ScrollingFrame = {"BackgroundTransparency", "ScrollBarImageTransparency"},
        TextLabel      = {"BackgroundTransparency", "TextTransparency"},
        TextButton     = {"BackgroundTransparency", "TextTransparency"},
        TextBox        = {"BackgroundTransparency", "TextTransparency"},
        ImageLabel     = {"BackgroundTransparency", "ImageTransparency"},
        ImageButton    = {"BackgroundTransparency", "ImageTransparency"},
        UIStroke       = {"Transparency"},
    }
    local activeFadeTweens = {}
    function Library:SetVisible(v, instant)
        if Library.Visible == v then return end
        Library.Visible = v
        for _, t in next, activeFadeTweens do pcall(function() t:Cancel() end) end
        activeFadeTweens = {}
        Library:CloseOpen()
        local target = Library.CurrentWindow and Library.CurrentWindow.Frame
        if not target then
            Holder.Enabled = v
            return
        end
        if v then Holder.Enabled = true end
        local pool = target:GetDescendants()
        insert(pool, target)
        for _, d in next, pool do
            local props = FadeProps[d.ClassName]
            if props then
                for _, p in next, props do
                    local orig = d:GetAttribute("FadeOrig_" .. p)
                    if orig == nil then
                        orig = d[p]
                        d:SetAttribute("FadeOrig_" .. p, orig)
                    end
                    local goal = v and orig or 1
                    if instant then
                        d[p] = goal
                    else
                        local tw = Library:Tween(d, {[p] = goal}, Library.FadeTime)
                        insert(activeFadeTweens, tw)
                    end
                end
            end
        end
        if not v then
            local visAtCall = Library.Visible
            task.delay(instant and 0 or (Library.FadeTime + 0.02), function()
                if Library.Visible == visAtCall and not Library.Visible then
                    Holder.Enabled = false
                end
            end)
        end
    end

    local HUD = Library:Create("ScreenGui", {
        IgnoreGuiInset = true,
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 9998,
    })
    pcall(function()
        if gethui then HUD.Parent = gethui()
        elseif syn and syn.protect_gui then syn.protect_gui(HUD); HUD.Parent = CoreGui
        else HUD.Parent = CoreGui end
    end)
    if not HUD.Parent then HUD.Parent = LocalPlayer:WaitForChild("PlayerGui") end
    Library.HUD = HUD
--

-- Watermark
    function Library:Watermark(opts)
        opts = opts or {}
        local W = {Text = opts.Text or "random nice", Visible = opts.Visible ~= false}

        local Frame = Library:Create("Frame", {
            BackgroundColor3 = Theme.Background,
            BorderSizePixel = 0,
            Position = opts.Position or dim2(0, 14, 0, 14),
            Size = dim2(0, 0, 0, 22),
            AutomaticSize = Enum.AutomaticSize.X,
            Visible = W.Visible,
            Active = true,
            Parent = HUD,
        })
        Library:Stroke(Frame, Theme.Border, 1)
        Library:Draggify(Frame)

        local AccentBar = Library:Create("Frame", {
            BackgroundColor3 = Theme.Accent,
            BorderSizePixel = 0,
            Size = dim2(1, 0, 0, 1),
            Position = dim2(0, 0, 0, 0),
            Parent = Frame,
        })
        AccentBar:SetAttribute("AccentBg", true)

        local Lbl = Library:Create("TextLabel", {
            BackgroundTransparency = 1,
            AutomaticSize = Enum.AutomaticSize.X,
            Size = dim2(0, 0, 1, -1),
            Position = dim2(0, 0, 0, 1),
            FontFace = Library.Font,
            TextSize = 14,
            TextColor3 = Theme.Text,
            Text = W.Text,
            Parent = Frame,
        })
        Library:Padding(Lbl, 0, 10, 0, 10)

        local lastUpd = 0
        Library:Connection(RunService.RenderStepped, function(dt)
            if not Frame.Visible then return end
            lastUpd = lastUpd + dt
            if lastUpd < 0.5 then return end
            lastUpd = 0
            local fps = math.floor(1 / dt + 0.5)
            Lbl.Text = string.format("%s | %dfps", W.Text, fps)
        end)

        Library.Watermark_ = W
        W.Frame = Frame
        function W:SetVisible(v) W.Visible = v; Frame.Visible = v end
        function W:SetText(t) W.Text = t; Lbl.Text = t end
        return W
    end
--

-- Keybinds list
    function Library:KeybindList(opts)
        opts = opts or {}
        local K = {Visible = opts.Visible ~= false, Items = {}}

        local Frame = Library:Create("Frame", {
            BackgroundColor3 = Theme.Background,
            BorderSizePixel = 0,
            AnchorPoint = Vector2.new(0, 0.5),
            Position = opts.Position or dim2(0, 14, 0.5, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Size = dim2(0, 170, 0, 0),
            Visible = K.Visible,
            Active = true,
            Parent = HUD,
        })
        Library:Stroke(Frame, Theme.Border, 1)
        Library:Draggify(Frame)

        local AccentBar = Library:Create("Frame", {
            BackgroundColor3 = Theme.Accent,
            BorderSizePixel = 0,
            Size = dim2(1, 0, 0, 1),
            Position = dim2(0, 0, 0, 0),
            Parent = Frame,
        })
        AccentBar:SetAttribute("AccentBg", true)

        local Inner = Library:Create("Frame", {
            BackgroundTransparency = 1,
            Position = dim2(0, 0, 0, 1),
            Size = dim2(1, 0, 1, -1),
            AutomaticSize = Enum.AutomaticSize.Y,
            Parent = Frame,
        })
        Library:Padding(Inner, 6, 8, 8, 8)

        local Title = Library:Create("TextLabel", {
            BackgroundTransparency = 1,
            Size = dim2(1, 0, 0, 14),
            FontFace = Library.BoldFont,
            TextSize = 14,
            TextColor3 = Theme.Text,
            Text = opts.Title or "keybinds",
            TextXAlignment = Enum.TextXAlignment.Left,
            LayoutOrder = 0,
            Parent = Inner,
        })

        local List = Library:Create("Frame", {
            BackgroundTransparency = 1,
            AutomaticSize = Enum.AutomaticSize.Y,
            Size = dim2(1, 0, 0, 0),
            LayoutOrder = 1,
            Parent = Inner,
        })
        Library:Create("UIListLayout", {Padding = dim(0, 2), Parent = List})
        Library:Create("UIListLayout", {Padding = dim(0, 4), Parent = Inner})

        local function relayout() Frame.Visible = K.Visible end

        function K:Add(name, key)
            local item = {Name = name, Key = key, Active = true}
            local row = Library:Create("Frame", {
                BackgroundTransparency = 1,
                Size = dim2(1, 0, 0, 14),
                Visible = key ~= nil,
                Parent = List,
            })
            local nm = Library:Create("TextLabel", {
                BackgroundTransparency = 1,
                Size = dim2(1, -50, 1, 0),
                FontFace = Library.Font,
                TextSize = 14,
                TextColor3 = Theme.Text,
                Text = name,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = row,
            })
            local kk = Library:Create("TextLabel", {
                BackgroundTransparency = 1,
                Position = dim2(1, -50, 0, 0),
                Size = dim2(0, 50, 1, 0),
                FontFace = Library.Font,
                TextSize = 14,
                TextColor3 = Theme.TextDim,
                Text = key and ("[" .. tostring(key) .. "]") or "",
                TextXAlignment = Enum.TextXAlignment.Right,
                Parent = row,
            })
            item.Frame = row
            function item:SetKey(k)
                self.Key = k
                kk.Text = k and ("[" .. tostring(k) .. "]") or ""
                row.Visible = (k ~= nil) and self.Active
            end
            function item:SetName(n) self.Name = n; nm.Text = n end
            function item:SetActive(b)
                self.Active = b
                row.Visible = b and self.Key ~= nil
            end
            function item:Remove()
                row:Destroy()
                for i, v in next, K.Items do
                    if v == self then remove(K.Items, i); break end
                end
            end
            insert(K.Items, item)
            return item
        end
        function K:SetVisible(v) K.Visible = v; relayout() end
        function K:Clear()
            for _, c in next, List:GetChildren() do
                if c:IsA("Frame") then c:Destroy() end
            end
            K.Items = {}
        end
        K.Frame = Frame
        Library.Keybinds_ = K
        relayout()
        return K
    end
--

-- Window
    function Library:Window(cfg)
        cfg = cfg or {}
        local Window = {
            Tabs = {},
            Title = cfg.Title or "random nice",
            Size  = cfg.Size or vec2(620, 540),
            CurrentTab = nil,
            CurrentSubTab = nil,
        }

        local Outer = Library:Create("Frame", {
            BackgroundColor3 = Theme.Background,
            BorderSizePixel = 0,
            Position = dim2(0.5, -Window.Size.X/2, 0.5, -Window.Size.Y/2),
            Size = dim2(0, Window.Size.X, 0, Window.Size.Y),
            Parent = Holder,
        })
        Library:Stroke(Outer, Theme.Border, 1)
        Window.Frame = Outer

        local Shadow = Library:Create("ImageLabel", {
            BackgroundTransparency = 1,
            Image = "rbxassetid://6014261993",
            ImageColor3 = Color3.new(0, 0, 0),
            ImageTransparency = 0.5,
            ScaleType = Enum.ScaleType.Slice,
            SliceCenter = Rect.new(Vector2.new(49, 49), Vector2.new(450, 450)),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = dim2(0.5, 0, 0.5, 0),
            Size = dim2(1, 50, 1, 50),
            ZIndex = 0,
            Parent = Outer,
        })

        local PopupLayer = Library:Create("Frame", {
            BackgroundTransparency = 1,
            Size = dim2(1, 0, 1, 0),
            ZIndex = 100,
            Parent = Outer,
        })
        Window.PopupLayer = PopupLayer
        Library.CurrentWindow = Window

        local TopBar = Library:Create("Frame", {
            BackgroundColor3 = Theme.TopBar,
            BorderSizePixel = 0,
            Size = dim2(1, 0, 0, 32),
            Parent = Outer,
        })
        Library:Create("Frame", {
            BackgroundColor3 = Theme.Border,
            BorderSizePixel = 0,
            Position = dim2(0, 0, 1, 0),
            Size = dim2(1, 0, 0, 1),
            Parent = TopBar,
        })

        local TabRow = Library:Create("Frame", {
            BackgroundTransparency = 1,
            Size = dim2(1, 0, 1, 0),
            Parent = TopBar,
        })
        Library:Create("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = dim(0, 0),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = TabRow,
        })
        Library:Padding(TabRow, 0, 8, 0, 8)

        local SubTabBar = Library:Create("Frame", {
            BackgroundColor3 = Theme.SubTabBar,
            BorderSizePixel = 0,
            Position = dim2(0, 0, 0, 32),
            Size = dim2(1, 0, 0, 26),
            Parent = Outer,
        })
        Library:Create("Frame", {
            BackgroundColor3 = Theme.Border,
            BorderSizePixel = 0,
            Position = dim2(0, 0, 1, 0),
            Size = dim2(1, 0, 0, 1),
            Parent = SubTabBar,
        })

        local Body = Library:Create("Frame", {
            BackgroundColor3 = Theme.ContentBg,
            BorderSizePixel = 0,
            Position = dim2(0, 0, 0, 58),
            Size = dim2(1, 0, 1, -58),
            Parent = Outer,
        })
        Library:Padding(Body, 10, 14, 14, 14)

        Library:Draggify(Outer, TopBar)

        function Window:Tab(opts)
            local name
            if type(opts) == "table" then name = opts.Name or opts[1] else name = opts end
            local Tab = {Name = name, SubTabs = {}, CurrentSubTab = nil}

            local Btn = Library:Create("TextButton", {
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                AutoButtonColor = false,
                Size = dim2(0, 0, 1, 0),
                AutomaticSize = Enum.AutomaticSize.X,
                FontFace = Library.BoldFont,
                TextSize = 14,
                TextColor3 = Theme.TabInactive,
                Text = "  " .. name .. "  ",
                Parent = TabRow,
            })

            local Marker = Library:Create("Frame", {
                BackgroundColor3 = Theme.Accent,
                BorderSizePixel = 0,
                AnchorPoint = Vector2.new(0.5, 1),
                Position = dim2(0.5, 0, 1, 0),
                Size = dim2(1, -16, 0, 2),
                Visible = false,
                Parent = Btn,
            })
            Marker:SetAttribute("AccentBg", true)

            local SubTabRow = Library:Create("Frame", {
                BackgroundTransparency = 1,
                Size = dim2(1, 0, 1, 0),
                Visible = false,
                Parent = SubTabBar,
            })
            Library:Create("UIListLayout", {
                FillDirection = Enum.FillDirection.Horizontal,
                VerticalAlignment = Enum.VerticalAlignment.Center,
                Padding = dim(0, 0),
                SortOrder = Enum.SortOrder.LayoutOrder,
                Parent = SubTabRow,
            })
            Library:Padding(SubTabRow, 0, 16, 0, 16)

            Tab.Button = Btn
            Tab.Marker = Marker
            Tab.SubTabRow = SubTabRow

            Btn.MouseButton1Click:Connect(function() Window:SelectTab(Tab) end)
            Btn.MouseEnter:Connect(function()
                if Window.CurrentTab ~= Tab then
                    Library:Tween(Btn, {TextColor3 = Theme.Text}, 0.1)
                end
            end)
            Btn.MouseLeave:Connect(function()
                if Window.CurrentTab ~= Tab then
                    Library:Tween(Btn, {TextColor3 = Theme.TabInactive}, 0.1)
                end
            end)
            insert(Window.Tabs, Tab)

            function Tab:SubTab(name2)
                local Sub = {Name = name2, Sections = {Left = {}, Right = {}}}

                local SBtn = Library:Create("TextButton", {
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    AutoButtonColor = false,
                    Size = dim2(0, 0, 1, 0),
                    AutomaticSize = Enum.AutomaticSize.X,
                    FontFace = Library.Font,
                    TextSize = 14,
                    TextColor3 = Theme.TabInactive,
                    Text = "  " .. name2 .. "  ",
                    Parent = SubTabRow,
                })
                local SMarker = Library:Create("Frame", {
                    BackgroundColor3 = Theme.Accent,
                    BorderSizePixel = 0,
                    AnchorPoint = Vector2.new(0.5, 1),
                    Position = dim2(0.5, 0, 1, 0),
                    Size = dim2(1, -12, 0, 1),
                    Visible = false,
                    Parent = SBtn,
                })
                SMarker:SetAttribute("AccentBg", true)

                local Page = Library:Create("Frame", {
                    BackgroundTransparency = 1,
                    Size = dim2(1, 0, 1, 0),
                    Visible = false,
                    Parent = Body,
                })

                local Left = Library:Create("ScrollingFrame", {
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Size = dim2(0.5, -8, 1, 0),
                    CanvasSize = dim2(0, 0, 0, 0),
                    AutomaticCanvasSize = Enum.AutomaticSize.Y,
                    ScrollBarThickness = 0,
                    ScrollingDirection = Enum.ScrollingDirection.Y,
                    Parent = Page,
                })
                local Right = Library:Create("ScrollingFrame", {
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Position = dim2(0.5, 8, 0, 0),
                    Size = dim2(0.5, -8, 1, 0),
                    CanvasSize = dim2(0, 0, 0, 0),
                    AutomaticCanvasSize = Enum.AutomaticSize.Y,
                    ScrollBarThickness = 0,
                    ScrollingDirection = Enum.ScrollingDirection.Y,
                    Parent = Page,
                })
                for _, side in next, {Left, Right} do
                    Library:Create("UIListLayout", {Padding = dim(0, 12), SortOrder = Enum.SortOrder.LayoutOrder, Parent = side})
                    Library:Padding(side, 2, 2, 4, 2)
                end

                Sub.Page = Page
                Sub.LeftHolder = Left
                Sub.RightHolder = Right
                Sub.Button = SBtn
                Sub.Marker = SMarker

                SBtn.MouseButton1Click:Connect(function() Tab:SelectSubTab(Sub) end)
                SBtn.MouseEnter:Connect(function()
                    if Tab.CurrentSubTab ~= Sub then
                        Library:Tween(SBtn, {TextColor3 = Theme.Text}, 0.1)
                    end
                end)
                SBtn.MouseLeave:Connect(function()
                    if Tab.CurrentSubTab ~= Sub then
                        Library:Tween(SBtn, {TextColor3 = Theme.TabInactive}, 0.1)
                    end
                end)

                insert(Tab.SubTabs, Sub)

                function Sub:Section(opts)
                    opts = opts or {}
                    local sideName = opts.Side or "Left"
                    local parent = sideName == "Right" and Right or Left

                    local Section = {Name = opts.Name or "section"}

                    local Container = Library:Create("Frame", {
                        BackgroundColor3 = Theme.BackgroundAlt,
                        BorderSizePixel = 0,
                        Size = dim2(1, 0, 0, 22),
                        AutomaticSize = Enum.AutomaticSize.Y,
                        Parent = parent,
                    })
                    Library:Stroke(Container, Theme.BorderLight, 1)

                    local titleLabel = Library:Create("TextLabel", {
                        BackgroundTransparency = 1,
                        BorderSizePixel = 0,
                        Position = dim2(0, 12, 0, 6),
                        Size = dim2(1, -24, 0, 14),
                        FontFace = Library.BoldFont,
                        TextSize = 14,
                        TextColor3 = Theme.Accent,
                        Text = Section.Name,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        Parent = Container,
                    })
                    titleLabel:SetAttribute("AccentText", true)

                    Library:Create("Frame", {
                        BackgroundColor3 = Theme.BorderLight,
                        BorderSizePixel = 0,
                        Position = dim2(0, 0, 0, 26),
                        Size = dim2(1, 0, 0, 1),
                        Parent = Container,
                    })

                    local Inner = Library:Create("Frame", {
                        BackgroundTransparency = 1,
                        Position = dim2(0, 12, 0, 32),
                        Size = dim2(1, -24, 0, 0),
                        AutomaticSize = Enum.AutomaticSize.Y,
                        Parent = Container,
                    })
                    Library:Create("UIListLayout", {Padding = dim(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = Inner})
                    Library:Padding(Inner, 0, 0, 14, 0)

                    Section.Container = Container
                    Section.Inner = Inner

                    local function newRow(h)
                        return Library:Create("Frame", {
                            BackgroundTransparency = 1,
                            Size = dim2(1, 0, 0, h or 18),
                            Parent = Inner,
                        })
                    end

                    function Section:Toggle(o)
                        o = o or {}
                        local flag = o.Flag or o.Name
                        Flags[flag] = o.Default or false

                        local row = newRow(18)
                        local box = Library:Create("Frame", {
                            BackgroundColor3 = Theme.ElementBg,
                            BorderSizePixel = 0,
                            Position = dim2(0, 0, 0.5, -5),
                            Size = dim2(0, 10, 0, 10),
                            Parent = row,
                        })
                        Library:Stroke(box, Theme.BorderLight, 1)

                        local check = Library:Create("Frame", {
                            BackgroundColor3 = Theme.Accent,
                            BorderSizePixel = 0,
                            AnchorPoint = Vector2.new(0.5, 0.5),
                            Position = dim2(0.5, 0, 0.5, 0),
                            Size = dim2(0, 6, 0, 6),
                            BackgroundTransparency = 1,
                            Parent = box,
                        })
                        check:SetAttribute("AccentBg", true)

                        local lbl = Library:Create("TextLabel", {
                            BackgroundTransparency = 1,
                            Position = dim2(0, 18, 0, 0),
                            Size = dim2(1, -18, 1, 0),
                            FontFace = TextFont,
                            TextSize = 14,
                            TextColor3 = Theme.TextDim,
                            Text = o.Name or "toggle",
                            TextXAlignment = Enum.TextXAlignment.Left,
                            Parent = row,
                        })

                        local btn = Library:Create("TextButton", {
                            BackgroundTransparency = 1,
                            Text = "",
                            Size = dim2(1, 0, 1, 0),
                            Parent = row,
                        })

                        local function set(v)
                            Flags[flag] = v
                            check.BackgroundTransparency = v and 0 or 1
                            lbl.TextColor3 = v and Theme.Text or Theme.TextDim
                            if o.Callback then pcall(o.Callback, v) end
                        end
                        btn.MouseButton1Click:Connect(function() set(not Flags[flag]) end)
                        set(Flags[flag])
                        ConfigFlags[flag] = set
                        return {Set = set, Get = function() return Flags[flag] end}
                    end

                    function Section:Button(o)
                        o = o or {}
                        local row = newRow(24)
                        local btn = Library:Create("TextButton", {
                            BackgroundColor3 = Theme.ElementBg,
                            BorderSizePixel = 0,
                            AutoButtonColor = false,
                            Size = dim2(1, 0, 1, 0),
                            FontFace = TextFont,
                            TextSize = 14,
                            TextColor3 = Theme.Text,
                            Text = o.Name or "button",
                            Parent = row,
                        })
                        Library:Stroke(btn, Theme.BorderLight, 1)
                        btn.MouseEnter:Connect(function()
                            Library:Tween(btn, {BackgroundColor3 = Theme.Track}, 0.1)
                        end)
                        btn.MouseLeave:Connect(function()
                            Library:Tween(btn, {BackgroundColor3 = Theme.ElementBg}, 0.1)
                        end)
                        btn.MouseButton1Click:Connect(function()
                            if o.Callback then pcall(o.Callback) end
                        end)
                        return {}
                    end

                    function Section:Label(o)
                        o = o or {}
                        local row = newRow(18)
                        local lbl = Library:Create("TextLabel", {
                            BackgroundTransparency = 1,
                            Size = dim2(1, 0, 1, 0),
                            FontFace = TextFont,
                            TextSize = 14,
                            TextColor3 = Theme.TextDim,
                            Text = o.Name or "label",
                            TextXAlignment = Enum.TextXAlignment.Left,
                            Parent = row,
                        })
                        return {Set = function(t) lbl.Text = t end}
                    end

                    local function buildSlider(o, isRange)
                        o = o or {}
                        local flag = o.Flag or o.Name
                        local minV, maxV = o.Min or 0, o.Max or 100
                        local suffix = o.Suffix or ""
                        if isRange then
                            Flags[flag] = {o.Default or minV, o.Default2 or maxV}
                        else
                            Flags[flag] = o.Default or minV
                        end

                        local row = newRow(36)
                        Library:Create("TextLabel", {
                            BackgroundTransparency = 1,
                            Size = dim2(1, -56, 0, 14),
                            FontFace = TextFont,
                            TextSize = 14,
                            TextColor3 = Theme.TextDim,
                            Text = o.Name or "slider",
                            TextXAlignment = Enum.TextXAlignment.Left,
                            Parent = row,
                        })
                        local valLabel = Library:Create("TextLabel", {
                            BackgroundTransparency = 1,
                            Position = dim2(1, -56, 0, 0),
                            Size = dim2(0, 56, 0, 14),
                            FontFace = TextFont,
                            TextSize = 14,
                            TextColor3 = Theme.Text,
                            Text = "",
                            TextXAlignment = Enum.TextXAlignment.Right,
                            Parent = row,
                        })

                        local trackBg = Library:Create("Frame", {
                            BackgroundColor3 = Theme.ElementBg,
                            BorderSizePixel = 0,
                            Position = dim2(0, 0, 0, 18),
                            Size = dim2(1, 0, 0, 4),
                            Parent = row,
                        })
                        Library:Stroke(trackBg, Theme.Border, 1)

                        local fill = Library:Create("Frame", {
                            BackgroundColor3 = Theme.Accent,
                            BorderSizePixel = 0,
                            Size = dim2(0, 0, 1, 0),
                            Parent = trackBg,
                        })
                        fill:SetAttribute("AccentBg", true)

                        local function fmt(n) return string.format("%s%s", tostring(n), suffix) end
                        local function update()
                            if isRange then
                                local lo, hi = Flags[flag][1], Flags[flag][2]
                                local a = (lo - minV) / (maxV - minV)
                                local b = (hi - minV) / (maxV - minV)
                                fill.Position = dim2(a, 0, 0, 0)
                                fill.Size = dim2(b - a, 0, 1, 0)
                                valLabel.Text = fmt(lo) .. ".." .. fmt(hi)
                            else
                                local v = Flags[flag]
                                local p = (v - minV) / (maxV - minV)
                                fill.Size = dim2(p, 0, 1, 0)
                                valLabel.Text = fmt(v)
                            end
                            if o.Callback then pcall(o.Callback, Flags[flag]) end
                        end

                        local function valueAtMouse()
                            local rel = (Mouse.X - trackBg.AbsolutePosition.X) / trackBg.AbsoluteSize.X
                            rel = math.clamp(rel, 0, 1)
                            local raw = minV + (maxV - minV) * rel
                            if o.Step then raw = math.floor(raw / o.Step + 0.5) * o.Step end
                            return math.floor(raw * 100 + 0.5) / 100
                        end

                        local btn = Library:Create("TextButton", {
                            BackgroundTransparency = 1,
                            Text = "",
                            Position = dim2(0, 0, 0, 14),
                            Size = dim2(1, 0, 0, 14),
                            Parent = row,
                        })
                        local dragging
                        btn.MouseButton1Down:Connect(function()
                            local v = valueAtMouse()
                            if isRange then
                                local lo, hi = Flags[flag][1], Flags[flag][2]
                                if math.abs(v - lo) <= math.abs(v - hi) then
                                    Flags[flag] = {math.min(v, hi), hi}
                                    dragging = "lo"
                                else
                                    Flags[flag] = {lo, math.max(v, lo)}
                                    dragging = "hi"
                                end
                            else
                                Flags[flag] = v
                                dragging = true
                            end
                            update()
                        end)
                        Library:Connection(UserInputService.InputEnded, function(input)
                            if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = nil end
                        end)
                        Library:Connection(UserInputService.InputChanged, function(input)
                            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                                local v = valueAtMouse()
                                if isRange then
                                    local lo, hi = Flags[flag][1], Flags[flag][2]
                                    if dragging == "lo" then
                                        Flags[flag] = {math.min(v, hi), hi}
                                    else
                                        Flags[flag] = {lo, math.max(v, lo)}
                                    end
                                else
                                    Flags[flag] = v
                                end
                                update()
                            end
                        end)

                        update()
                        local setter = function(v) Flags[flag] = v; update() end
                        ConfigFlags[flag] = setter
                        return {Set = setter, Get = function() return Flags[flag] end}
                    end

                    function Section:Slider(o) return buildSlider(o, false) end
                    function Section:RangeSlider(o) return buildSlider(o, true) end

                    function Section:Dropdown(o)
                        o = o or {}
                        local flag = o.Flag or o.Name
                        local options = o.Options or {}
                        local multi = o.Multi == true
                        if multi then
                            Flags[flag] = o.Default or {}
                            if type(Flags[flag]) ~= "table" then Flags[flag] = {} end
                        else
                            Flags[flag] = o.Default or options[1] or ""
                        end

                        local function isSelected(opt)
                            if multi then
                                for _, v in next, Flags[flag] do
                                    if v == opt then return true end
                                end
                                return false
                            end
                            return opt == Flags[flag]
                        end

                        local function displayText()
                            if multi then
                                local sel = Flags[flag]
                                if #sel == 0 then return "  " .. (o.Placeholder or "none") end
                                if #sel == 1 then return "  " .. tostring(sel[1]) end
                                return "  " .. #sel .. " selected"
                            end
                            return "  " .. tostring(Flags[flag])
                        end

                        local row = newRow(36)
                        Library:Create("TextLabel", {
                            BackgroundTransparency = 1,
                            Size = dim2(1, 0, 0, 12),
                            FontFace = TextFont,
                            TextSize = 14,
                            TextColor3 = Theme.TextDim,
                            Text = o.Name or "dropdown",
                            TextXAlignment = Enum.TextXAlignment.Left,
                            Parent = row,
                        })
                        local box = Library:Create("TextButton", {
                            BackgroundColor3 = Theme.ElementBg,
                            BorderSizePixel = 0,
                            AutoButtonColor = false,
                            Position = dim2(0, 0, 0, 14),
                            Size = dim2(1, 0, 0, 18),
                            FontFace = TextFont,
                            TextSize = 14,
                            TextColor3 = Theme.Text,
                            Text = displayText(),
                            TextXAlignment = Enum.TextXAlignment.Left,
                            Parent = row,
                        })
                        Library:Stroke(box, Theme.BorderLight, 1)
                        Library:Create("TextLabel", {
                            BackgroundTransparency = 1,
                            Position = dim2(1, -16, 0, 0),
                            Size = dim2(0, 12, 1, 0),
                            FontFace = TextFont,
                            TextSize = 14,
                            TextColor3 = Theme.TextDim,
                            Text = "▼",
                            Parent = box,
                        })

                        local popupParent = (Library.CurrentWindow and Library.CurrentWindow.PopupLayer) or Holder
                        local list = Library:Create("Frame", {
                            BackgroundColor3 = Theme.ElementBg,
                            BorderSizePixel = 0,
                            Size = dim2(0, 0, 0, 0),
                            Visible = false,
                            ZIndex = 200,
                            Parent = popupParent,
                        })
                        Library:Stroke(list, Theme.BorderLight, 1)
                        local layout = Library:Create("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Parent = list})

                        local handle = {Open = false, Frames = {list, box}}
                        local function toggleOpt(opt)
                            if multi then
                                local sel = Flags[flag]
                                local found
                                for i, v in next, sel do if v == opt then found = i; break end end
                                if found then remove(sel, found) else insert(sel, opt) end
                            else
                                Flags[flag] = opt
                            end
                        end
                        local function rebuild()
                            for _, c in next, list:GetChildren() do
                                if c:IsA("TextButton") then c:Destroy() end
                            end
                            for _, opt in next, options do
                                local b = Library:Create("TextButton", {
                                    BackgroundTransparency = 1,
                                    AutoButtonColor = false,
                                    Size = dim2(1, 0, 0, 18),
                                    FontFace = TextFont,
                                    TextSize = 14,
                                    TextColor3 = isSelected(opt) and Theme.Accent or Theme.TextDim,
                                    Text = "  " .. tostring(opt),
                                    TextXAlignment = Enum.TextXAlignment.Left,
                                    ZIndex = 201,
                                    Parent = list,
                                })
                                b.MouseButton1Click:Connect(function()
                                    toggleOpt(opt)
                                    box.Text = displayText()
                                    if o.Callback then pcall(o.Callback, Flags[flag]) end
                                    if multi then
                                        for _, child in next, list:GetChildren() do
                                            if child:IsA("TextButton") then
                                                local txt = tostring(child.Text):sub(3)
                                                child.TextColor3 = isSelected(txt) and Theme.Accent or Theme.TextDim
                                            end
                                        end
                                    else
                                        handle.Close()
                                        rebuild()
                                    end
                                end)
                            end
                            local rel = box.AbsolutePosition - popupParent.AbsolutePosition
                            local sz  = box.AbsoluteSize
                            list.Position = dim2(0, rel.X, 0, rel.Y + sz.Y + 1)
                            list.Size = dim2(0, sz.X, 0, layout.AbsoluteContentSize.Y)
                        end
                        handle.Close = function() list.Visible = false; handle.Open = false end
                        box.MouseButton1Click:Connect(function()
                            if handle.Open then
                                handle.Close()
                                Library.OpenElement = nil
                            else
                                Library:CloseOpen()
                                rebuild()
                                list.Visible = true
                                handle.Open = true
                                Library.OpenElement = handle
                            end
                        end)
                        box.AncestryChanged:Connect(function(_, parent)
                            if not parent then list:Destroy() end
                        end)
                        local setter = function(v) Flags[flag] = v; box.Text = displayText() end
                        ConfigFlags[flag] = setter
                        return {
                            Set = setter,
                            Get = function() return Flags[flag] end,
                            Refresh = function(opts) options = opts; rebuild() end,
                        }
                    end

                    function Section:Keybind(o)
                        o = o or {}
                        local flag = o.Flag or o.Name
                        Flags[flag] = o.Default
                        local mode = o.Mode or "Toggle"
                        Flags[flag .. "_mode"] = mode
                        local activated = false

                        local function keyName(k)
                            if not k then return nil end
                            return Keys[k] or (typeof(k) == "EnumItem" and tostring(k.Name)) or tostring(k)
                        end

                        local row = newRow(18)
                        local lbl = Library:Create("TextLabel", {
                            BackgroundTransparency = 1,
                            Size = dim2(1, -64, 1, 0),
                            FontFace = TextFont,
                            TextSize = 14,
                            TextColor3 = Theme.TextDim,
                            Text = o.Name or "keybind",
                            TextXAlignment = Enum.TextXAlignment.Left,
                            Parent = row,
                        })
                        local box = Library:Create("TextButton", {
                            BackgroundColor3 = Theme.ElementBg,
                            BorderSizePixel = 0,
                            AutoButtonColor = false,
                            Position = dim2(1, -62, 0.5, -7),
                            Size = dim2(0, 62, 0, 14),
                            FontFace = TextFont,
                            TextSize = 14,
                            TextColor3 = Theme.Text,
                            Text = "[" .. (keyName(Flags[flag]) or "...") .. "]",
                            Parent = row,
                        })
                        Library:Stroke(box, Theme.BorderLight, 1)

                        local listItem
                        if o.ShowInList ~= false and Library.Keybinds_ then
                            listItem = Library.Keybinds_:Add(o.Name or "keybind", keyName(Flags[flag]))
                            if mode ~= "Always" then listItem:SetActive(false) end
                        end
                        local function setActivated(v)
                            activated = v
                            if listItem and mode ~= "Always" then listItem:SetActive(v) end
                        end
                        local function setMode(m)
                            mode = m
                            Flags[flag .. "_mode"] = m
                            if m == "Always" then
                                setActivated(true)
                                if listItem then listItem:SetActive(true) end
                            else
                                setActivated(false)
                                if listItem then listItem:SetActive(false) end
                            end
                            if o.ModeCallback then pcall(o.ModeCallback, m) end
                        end

                        local popupParent = (Library.CurrentWindow and Library.CurrentWindow.PopupLayer) or Holder
                        local modeMenu = Library:Create("Frame", {
                            BackgroundColor3 = Theme.ElementBg,
                            BorderSizePixel = 0,
                            Size = dim2(0, 80, 0, 0),
                            AutomaticSize = Enum.AutomaticSize.Y,
                            Visible = false,
                            ZIndex = 200,
                            Parent = popupParent,
                        })
                        Library:Stroke(modeMenu, Theme.BorderLight, 1)
                        Library:Create("UIListLayout", {Parent = modeMenu})
                        Library:Padding(modeMenu, 2, 2, 2, 2)
                        local modeHandle = {Open = false, Frames = {modeMenu, box}}
                        modeHandle.Close = function() modeMenu.Visible = false; modeHandle.Open = false end
                        local modeButtons = {}
                        for _, m in next, {"Hold", "Toggle", "Always"} do
                            local b = Library:Create("TextButton", {
                                BackgroundTransparency = 1,
                                AutoButtonColor = false,
                                Size = dim2(1, 0, 0, 16),
                                FontFace = TextFont,
                                TextSize = 14,
                                TextColor3 = (m == mode) and Theme.Accent or Theme.TextDim,
                                Text = m,
                                ZIndex = 201,
                                Parent = modeMenu,
                            })
                            b.MouseButton1Click:Connect(function()
                                setMode(m)
                                for mm, btn in next, modeButtons do
                                    btn.TextColor3 = (mm == m) and Theme.Accent or Theme.TextDim
                                end
                                modeHandle.Close()
                                Library.OpenElement = nil
                            end)
                            modeButtons[m] = b
                        end
                        box.MouseButton2Click:Connect(function()
                            if modeHandle.Open then
                                modeHandle.Close()
                                Library.OpenElement = nil
                            else
                                Library:CloseOpen()
                                local rel = box.AbsolutePosition - popupParent.AbsolutePosition
                                local sz  = box.AbsoluteSize
                                modeMenu.Position = dim2(0, rel.X + sz.X - 80, 0, rel.Y + sz.Y + 1)
                                modeMenu.Visible = true
                                modeHandle.Open = true
                                Library.OpenElement = modeHandle
                            end
                        end)
                        box.AncestryChanged:Connect(function(_, parent)
                            if not parent then modeMenu:Destroy() end
                        end)

                        local listening = false
                        box.MouseButton1Click:Connect(function()
                            listening = true
                            box.Text = "[...]"
                        end)
                        Library:Connection(UserInputService.InputBegan, function(input, gp)
                            if listening then
                                if input.UserInputType == Enum.UserInputType.Keyboard or input.UserInputType.Name:find("MouseButton") then
                                    local k = input.KeyCode ~= Enum.KeyCode.Unknown and input.KeyCode or input.UserInputType
                                    if k == Enum.KeyCode.Escape or k == Enum.KeyCode.Backspace then
                                        Flags[flag] = nil
                                        box.Text = "[...]"
                                    else
                                        Flags[flag] = k
                                        box.Text = "[" .. (keyName(k) or "...") .. "]"
                                    end
                                    if listItem then listItem:SetKey(keyName(Flags[flag])) end
                                    setActivated(false)
                                    listening = false
                                    if o.Callback then pcall(o.Callback, Flags[flag]) end
                                end
                            elseif Flags[flag] and not gp then
                                local k = Flags[flag]
                                if input.KeyCode == k or input.UserInputType == k then
                                    if mode == "Toggle" then
                                        setActivated(not activated)
                                    else
                                        setActivated(true)
                                    end
                                    if o.Pressed then pcall(o.Pressed) end
                                end
                            end
                        end)
                        Library:Connection(UserInputService.InputEnded, function(input)
                            if mode ~= "Hold" then return end
                            if not Flags[flag] then return end
                            local k = Flags[flag]
                            if input.KeyCode == k or input.UserInputType == k then
                                setActivated(false)
                                if o.Released then pcall(o.Released) end
                            end
                        end)
                        local setter = function(v)
                            Flags[flag] = v
                            box.Text = "[" .. (keyName(v) or "...") .. "]"
                            if listItem then listItem:SetKey(keyName(v)) end
                        end
                        ConfigFlags[flag] = setter
                        ConfigFlags[flag .. "_mode"] = function(m)
                            if type(m) == "string" then setMode(m) end
                            if modeButtons then
                                for mm, btn in next, modeButtons do
                                    btn.TextColor3 = (mm == m) and Theme.Accent or Theme.TextDim
                                end
                            end
                        end
                        return {
                            Set = setter,
                            Get = function() return Flags[flag] end,
                            SetMode = setMode,
                            GetMode = function() return mode end,
                            SetActivated = setActivated,
                            IsActivated = function() return activated end,
                        }
                    end

                    function Section:ColorPicker(o)
                        o = o or {}
                        local flag = o.Flag or o.Name
                        Flags[flag]                = o.Default or rgb(255, 255, 255)
                        Flags[flag .. "_alpha"]    = o.Alpha or 1
                        Flags[flag .. "_mode"]     = o.Mode  or "None"
                        Flags[flag .. "_speed"]    = o.Speed or 0.5
                        Flags[flag .. "_animated"] = Flags[flag]

                        local row = newRow(18)
                        Library:Create("TextLabel", {
                            BackgroundTransparency = 1,
                            Size = dim2(1, -22, 1, 0),
                            FontFace = TextFont,
                            TextSize = 14,
                            TextColor3 = Theme.TextDim,
                            Text = o.Name or "color",
                            TextXAlignment = Enum.TextXAlignment.Left,
                            Parent = row,
                        })
                        local swatch = Library:Create("TextButton", {
                            BackgroundColor3 = Flags[flag],
                            BorderSizePixel = 0,
                            AutoButtonColor = false,
                            Position = dim2(1, -18, 0.5, -7),
                            Size = dim2(0, 18, 0, 14),
                            Text = "",
                            Parent = row,
                        })
                        Library:Stroke(swatch, Theme.Border, 1)

                        local popupParent = (Library.CurrentWindow and Library.CurrentWindow.PopupLayer) or Holder
                        local picker = Library:Create("Frame", {
                            BackgroundColor3 = Theme.Background,
                            BorderSizePixel = 0,
                            Size = dim2(0, 200, 0, 220),
                            Visible = false,
                            ZIndex = 200,
                            Parent = popupParent,
                        })
                        Library:Stroke(picker, Theme.Border, 1)
                        swatch.AncestryChanged:Connect(function(_, parent)
                            if not parent then picker:Destroy() end
                        end)
                        local function reposition()
                            local rel = swatch.AbsolutePosition - popupParent.AbsolutePosition
                            local sz  = swatch.AbsoluteSize
                            picker.Position = dim2(0, rel.X + sz.X - 200, 0, rel.Y + sz.Y + 4)
                        end

                        local sat = Library:Create("ImageLabel", {
                            Image = "rbxassetid://4155801252",
                            BackgroundColor3 = rgb(255, 0, 0),
                            BorderSizePixel = 0,
                            Position = dim2(0, 6, 0, 6),
                            Size = dim2(0, 168, 0, 130),
                            ZIndex = 201,
                            Parent = picker,
                        })
                        local satCursor = Library:Create("Frame", {
                            BackgroundColor3 = rgb(255, 255, 255),
                            BorderSizePixel = 0,
                            AnchorPoint = Vector2.new(0.5, 0.5),
                            Size = dim2(0, 6, 0, 6),
                            ZIndex = 203,
                            Parent = sat,
                        })
                        Library:Stroke(satCursor, rgb(0, 0, 0), 1)

                        local hueBar = Library:Create("Frame", {
                            BorderSizePixel = 0,
                            Position = dim2(0, 180, 0, 6),
                            Size = dim2(0, 14, 0, 130),
                            ZIndex = 201,
                            Parent = picker,
                        })
                        Library:Create("UIGradient", {
                            Color = ColorSequence.new({
                                ColorSequenceKeypoint.new(0,    Color3.fromHSV(0,    1, 1)),
                                ColorSequenceKeypoint.new(0.16, Color3.fromHSV(0.16, 1, 1)),
                                ColorSequenceKeypoint.new(0.33, Color3.fromHSV(0.33, 1, 1)),
                                ColorSequenceKeypoint.new(0.50, Color3.fromHSV(0.50, 1, 1)),
                                ColorSequenceKeypoint.new(0.66, Color3.fromHSV(0.66, 1, 1)),
                                ColorSequenceKeypoint.new(0.83, Color3.fromHSV(0.83, 1, 1)),
                                ColorSequenceKeypoint.new(1,    Color3.fromHSV(1,    1, 1)),
                            }),
                            Rotation = 90,
                            Parent = hueBar,
                        })
                        local hueCursor = Library:Create("Frame", {
                            BackgroundColor3 = rgb(255, 255, 255),
                            BorderSizePixel = 0,
                            AnchorPoint = Vector2.new(0.5, 0.5),
                            Position = dim2(0.5, 0, 0, 0),
                            Size = dim2(1, 4, 0, 2),
                            ZIndex = 203,
                            Parent = hueBar,
                        })

                        local alphaBar = Library:Create("Frame", {
                            BackgroundColor3 = rgb(255, 255, 255),
                            BorderSizePixel = 0,
                            Position = dim2(0, 6, 0, 142),
                            Size = dim2(1, -12, 0, 8),
                            ZIndex = 201,
                            Parent = picker,
                        })
                        local alphaGrad = Library:Create("UIGradient", {
                            Color = ColorSequence.new(rgb(255, 255, 255), Flags[flag]),
                            Parent = alphaBar,
                        })
                        local alphaCursor = Library:Create("Frame", {
                            BackgroundColor3 = rgb(255, 255, 255),
                            BorderSizePixel = 0,
                            AnchorPoint = Vector2.new(0.5, 0.5),
                            Position = dim2(1, 0, 0.5, 0),
                            Size = dim2(0, 2, 1, 4),
                            ZIndex = 203,
                            Parent = alphaBar,
                        })
                        Library:Stroke(alphaCursor, rgb(0, 0, 0), 1)

                        local modeBox = Library:Create("TextButton", {
                            BackgroundColor3 = Theme.ElementBg,
                            BorderSizePixel = 0,
                            AutoButtonColor = false,
                            Position = dim2(0, 6, 0, 156),
                            Size = dim2(1, -12, 0, 18),
                            FontFace = TextFont,
                            TextSize = 14,
                            TextColor3 = Theme.Text,
                            Text = "  " .. Flags[flag .. "_mode"],
                            TextXAlignment = Enum.TextXAlignment.Left,
                            ZIndex = 201,
                            Parent = picker,
                        })
                        Library:Stroke(modeBox, Theme.BorderLight, 1)

                        local modeList = Library:Create("Frame", {
                            BackgroundColor3 = Theme.ElementBg,
                            BorderSizePixel = 0,
                            Size = dim2(0, 0, 0, 0),
                            AutomaticSize = Enum.AutomaticSize.Y,
                            Visible = false,
                            ZIndex = 300,
                            Parent = popupParent,
                        })
                        Library:Stroke(modeList, Theme.BorderLight, 1)
                        Library:Create("UIListLayout", {Parent = modeList})
                        modeBox.AncestryChanged:Connect(function(_, parent)
                            if not parent then modeList:Destroy() end
                        end)

                        local MODES = {"None", "Rainbow", "Fade White", "Fade Black", "Fade Alpha"}
                        local modeButtons = {}
                        for _, m in next, MODES do
                            local mb = Library:Create("TextButton", {
                                BackgroundTransparency = 1,
                                AutoButtonColor = false,
                                Size = dim2(1, 0, 0, 18),
                                FontFace = TextFont,
                                TextSize = 14,
                                TextColor3 = (m == Flags[flag .. "_mode"]) and Theme.Accent or Theme.TextDim,
                                Text = "  " .. m,
                                TextXAlignment = Enum.TextXAlignment.Left,
                                ZIndex = 301,
                                Parent = modeList,
                            })
                            mb.MouseButton1Click:Connect(function()
                                Flags[flag .. "_mode"] = m
                                modeBox.Text = "  " .. m
                                for mm, btn in next, modeButtons do
                                    btn.TextColor3 = (mm == m) and Theme.Accent or Theme.TextDim
                                end
                                modeList.Visible = false
                            end)
                            modeButtons[m] = mb
                        end
                        modeBox.MouseButton1Click:Connect(function()
                            if modeList.Visible then
                                modeList.Visible = false
                            else
                                local rel = modeBox.AbsolutePosition - popupParent.AbsolutePosition
                                local sz  = modeBox.AbsoluteSize
                                modeList.Position = dim2(0, rel.X, 0, rel.Y + sz.Y + 1)
                                modeList.Size     = dim2(0, sz.X, 0, 0)
                                modeList.Visible  = true
                            end
                        end)

                        Library:Create("TextLabel", {
                            BackgroundTransparency = 1,
                            Position = dim2(0, 6, 0, 180),
                            Size = dim2(0, 50, 0, 12),
                            FontFace = TextFont,
                            TextSize = 14,
                            TextColor3 = Theme.TextDim,
                            Text = "speed",
                            TextXAlignment = Enum.TextXAlignment.Left,
                            ZIndex = 201,
                            Parent = picker,
                        })
                        local speedTrack = Library:Create("Frame", {
                            BackgroundColor3 = Theme.Track,
                            BorderSizePixel = 0,
                            Position = dim2(0, 6, 0, 198),
                            Size = dim2(1, -12, 0, 4),
                            ZIndex = 201,
                            Parent = picker,
                        })
                        local speedFill = Library:Create("Frame", {
                            BackgroundColor3 = Theme.Accent,
                            BorderSizePixel = 0,
                            Size = dim2(Flags[flag .. "_speed"], 0, 1, 0),
                            ZIndex = 202,
                            Parent = speedTrack,
                        })
                        speedFill:SetAttribute("AccentBg", true)
                        local speedValue = Library:Create("TextLabel", {
                            BackgroundTransparency = 1,
                            Position = dim2(1, -40, 0, 180),
                            Size = dim2(0, 34, 0, 12),
                            FontFace = TextFont,
                            TextSize = 14,
                            TextColor3 = Theme.Text,
                            Text = string.format("%.2f", Flags[flag .. "_speed"]),
                            TextXAlignment = Enum.TextXAlignment.Right,
                            ZIndex = 201,
                            Parent = picker,
                        })

                        local h, s, v = 0, 0, 1
                        local function setColor()
                            local c = Color3.fromHSV(h, s, v)
                            Flags[flag] = c
                            swatch.BackgroundColor3 = c
                            sat.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
                            satCursor.Position = dim2(s, 0, 1 - v, 0)
                            hueCursor.Position = dim2(0.5, 0, h, 0)
                            alphaGrad.Color = ColorSequence.new(rgb(255, 255, 255), c)
                            if o.Callback then pcall(o.Callback, c, Flags[flag .. "_alpha"], Flags[flag .. "_mode"]) end
                        end
                        local function setAlpha(a)
                            Flags[flag .. "_alpha"] = a
                            alphaCursor.Position = dim2(a, 0, 0.5, 0)
                            if o.Callback then pcall(o.Callback, Flags[flag], a, Flags[flag .. "_mode"]) end
                        end

                        local handle = {Open = false, Frames = {picker, swatch, modeList}}
                        handle.Close = function() picker.Visible = false; modeList.Visible = false; handle.Open = false end
                        swatch.MouseButton1Click:Connect(function()
                            if handle.Open then
                                handle.Close(); Library.OpenElement = nil
                            else
                                Library:CloseOpen()
                                reposition()
                                picker.Visible = true
                                handle.Open = true
                                Library.OpenElement = handle
                            end
                        end)

                        local satDrag, hueDrag, alphaDrag, speedDrag
                        sat.InputBegan:Connect(function(i)
                            if i.UserInputType == Enum.UserInputType.MouseButton1 then satDrag = true end
                        end)
                        hueBar.InputBegan:Connect(function(i)
                            if i.UserInputType == Enum.UserInputType.MouseButton1 then hueDrag = true end
                        end)
                        alphaBar.InputBegan:Connect(function(i)
                            if i.UserInputType == Enum.UserInputType.MouseButton1 then alphaDrag = true end
                        end)
                        speedTrack.InputBegan:Connect(function(i)
                            if i.UserInputType == Enum.UserInputType.MouseButton1 then speedDrag = true end
                        end)
                        Library:Connection(UserInputService.InputEnded, function(i)
                            if i.UserInputType == Enum.UserInputType.MouseButton1 then satDrag, hueDrag, alphaDrag, speedDrag = nil, nil, nil, nil end
                        end)
                        Library:Connection(RunService.RenderStepped, function()
                            if satDrag then
                                local rx = math.clamp((Mouse.X - sat.AbsolutePosition.X) / sat.AbsoluteSize.X, 0, 1)
                                local ry = math.clamp((Mouse.Y - sat.AbsolutePosition.Y) / sat.AbsoluteSize.Y, 0, 1)
                                s, v = rx, 1 - ry
                                setColor()
                            end
                            if hueDrag then
                                local ry = math.clamp((Mouse.Y - hueBar.AbsolutePosition.Y) / hueBar.AbsoluteSize.Y, 0, 1)
                                h = ry
                                setColor()
                            end
                            if alphaDrag then
                                local rx = math.clamp((Mouse.X - alphaBar.AbsolutePosition.X) / alphaBar.AbsoluteSize.X, 0, 1)
                                setAlpha(rx)
                            end
                            if speedDrag then
                                local rx = math.clamp((Mouse.X - speedTrack.AbsolutePosition.X) / speedTrack.AbsoluteSize.X, 0, 1)
                                Flags[flag .. "_speed"] = rx
                                speedFill.Size = dim2(rx, 0, 1, 0)
                                speedValue.Text = string.format("%.2f", rx)
                            end
                        end)
                        do
                            local hh, ss, vv = Flags[flag]:ToHSV()
                            h, s, v = hh, ss, vv
                            setColor()
                            setAlpha(Flags[flag .. "_alpha"])
                        end

                        local t = 0
                        Library:Connection(RunService.Heartbeat, function(dt)
                            local m = Flags[flag .. "_mode"]
                            local base = Flags[flag]
                            local alpha = Flags[flag .. "_alpha"]
                            local outColor, outAlpha = base, alpha
                            if m == "None" then
                                outColor, outAlpha = base, alpha
                            elseif m == "Rainbow" then
                                t = t + dt * Flags[flag .. "_speed"]
                                outColor = Color3.fromHSV(t % 1, 1, 1)
                                swatch.BackgroundColor3 = outColor
                            elseif m == "Fade White" then
                                t = t + dt * Flags[flag .. "_speed"] * 2
                                local k = (math.sin(t) + 1) * 0.5
                                outColor = base:Lerp(rgb(255, 255, 255), k)
                                swatch.BackgroundColor3 = outColor
                            elseif m == "Fade Black" then
                                t = t + dt * Flags[flag .. "_speed"] * 2
                                local k = (math.sin(t) + 1) * 0.5
                                outColor = base:Lerp(rgb(0, 0, 0), k)
                                swatch.BackgroundColor3 = outColor
                            elseif m == "Fade Alpha" then
                                t = t + dt * Flags[flag .. "_speed"] * 2
                                outAlpha = (math.sin(t) + 1) * 0.5 * alpha
                                swatch.BackgroundTransparency = 1 - outAlpha
                            end
                            if m ~= "Fade Alpha" then swatch.BackgroundTransparency = 0 end
                            Flags[flag .. "_animated"]       = outColor
                            Flags[flag .. "_animated_alpha"] = outAlpha
                            if o.Animate then pcall(o.Animate, outColor, outAlpha) end
                        end)
                        local setter = function(c) h, s, v = c:ToHSV(); setColor() end
                        ConfigFlags[flag]              = setter
                        ConfigFlags[flag .. "_alpha"]  = function(a) setAlpha(a) end
                        ConfigFlags[flag .. "_speed"]  = function(sp)
                            Flags[flag .. "_speed"] = sp
                            speedFill.Size = dim2(sp, 0, 1, 0)
                            speedValue.Text = string.format("%.2f", sp)
                        end
                        ConfigFlags[flag .. "_mode"]   = function(m)
                            Flags[flag .. "_mode"] = m
                            modeBox.Text = "  " .. m
                            for mm, btn in next, modeButtons do
                                btn.TextColor3 = (mm == m) and Theme.Accent or Theme.TextDim
                            end
                        end
                        return {
                            Set         = setter,
                            Get         = function() return Flags[flag] end,
                            GetAnimated = function() return Flags[flag .. "_animated"], Flags[flag .. "_animated_alpha"] end,
                            SetMode     = function(m) ConfigFlags[flag .. "_mode"](m) end,
                            SetSpeed    = function(s) ConfigFlags[flag .. "_speed"](s) end,
                        }
                    end

                    function Section:Search(o)
                        o = o or {}
                        local row = newRow(24)
                        local box = Library:Create("Frame", {
                            BackgroundColor3 = Theme.ElementBg,
                            BorderSizePixel = 0,
                            Size = dim2(1, 0, 1, 0),
                            Parent = row,
                        })
                        Library:Stroke(box, Theme.BorderLight, 1)
                        local tb = Library:Create("TextBox", {
                            BackgroundTransparency = 1,
                            Size = dim2(1, -12, 1, 0),
                            Position = dim2(0, 8, 0, 0),
                            FontFace = TextFont,
                            TextSize = 14,
                            TextColor3 = Theme.Text,
                            PlaceholderText = o.Placeholder or "search..",
                            PlaceholderColor3 = Theme.TextMuted,
                            Text = "",
                            TextXAlignment = Enum.TextXAlignment.Left,
                            ClearTextOnFocus = false,
                            Parent = box,
                        })
                        tb:GetPropertyChangedSignal("Text"):Connect(function()
                            if o.Callback then pcall(o.Callback, tb.Text) end
                        end)
                        return {Set = function(t) tb.Text = t end, Get = function() return tb.Text end}
                    end

                    function Section:PlayerList(o)
                        o = o or {}
                        local h = o.Height or 220
                        local row = newRow(h)
                        Library.PlayerList = Library.PlayerList or {Players = {}, Order = {}, Statuses = {"Default", "Friend", "Rage"}}
                        local PL = Library.PlayerList
                        local Entries = {}
                        local statusColors = {
                            Default = Theme.Text,
                            Friend  = rgb(120, 220, 130),
                            Rage    = rgb(230, 80, 90),
                        }
                        local list = Library:Create("ScrollingFrame", {
                            BackgroundTransparency = 1,
                            BorderSizePixel = 0,
                            Size = dim2(1, 0, 1, -22),
                            CanvasSize = dim2(0, 0, 0, 0),
                            AutomaticCanvasSize = Enum.AutomaticSize.Y,
                            ScrollBarThickness = 2,
                            ScrollBarImageColor3 = Theme.AccentDark,
                            Parent = row,
                        })
                        Library:Create("UIListLayout", {Padding = dim(0, 2), Parent = list})

                        local function setStatus(name, status)
                            if not PL.Players[name] then return end
                            PL.Players[name] = status
                            local entry = Entries[name]
                            if entry then
                                entry.statusLabel.Text = status
                                entry.statusLabel.TextColor3 = statusColors[status] or Theme.Text
                            end
                            if o.Callback then pcall(o.Callback, name, status) end
                        end
                        local function cycleStatus(name)
                            local cur = PL.Players[name] or "Default"
                            local idx = 1
                            for i, s in ipairs(PL.Statuses) do
                                if s == cur then idx = i; break end
                            end
                            setStatus(name, PL.Statuses[(idx % #PL.Statuses) + 1])
                        end
                        local function avatarFor(name)
                            local plr = Players:FindFirstChild(name)
                            if plr then
                                local ok, img = pcall(function()
                                    return Players:GetUserThumbnailAsync(plr.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
                                end)
                                if ok and img then return img end
                            end
                            return o.AvatarImage or "rbxassetid://7072706796"
                        end
                        local function addEntry(name, status)
                            status = status or "Default"
                            if not PL.Players[name] then
                                PL.Players[name] = status
                                insert(PL.Order, name)
                            end
                            local e = Library:Create("Frame", {
                                BackgroundTransparency = 1,
                                Size = dim2(1, -4, 0, 18),
                                Parent = list,
                            })
                            local av = Library:Create("ImageLabel", {
                                BackgroundColor3 = Theme.ElementBg,
                                BorderSizePixel = 0,
                                Size = dim2(0, 16, 0, 16),
                                Position = dim2(0, 0, 0.5, -8),
                                Image = avatarFor(name),
                                Parent = e,
                            })
                            local nameLabel = Library:Create("TextLabel", {
                                BackgroundTransparency = 1,
                                Position = dim2(0, 22, 0, 0),
                                Size = dim2(1, -82, 1, 0),
                                FontFace = TextFont,
                                TextSize = 14,
                                TextColor3 = Theme.Text,
                                Text = name,
                                TextXAlignment = Enum.TextXAlignment.Left,
                                TextTruncate = Enum.TextTruncate.AtEnd,
                                Parent = e,
                            })
                            local statusBtn = Library:Create("TextButton", {
                                BackgroundTransparency = 1,
                                AutoButtonColor = false,
                                Position = dim2(1, -60, 0, 0),
                                Size = dim2(0, 60, 1, 0),
                                FontFace = TextFont,
                                TextSize = 14,
                                TextColor3 = statusColors[PL.Players[name]] or Theme.Text,
                                Text = PL.Players[name],
                                TextXAlignment = Enum.TextXAlignment.Right,
                                Parent = e,
                            })
                            statusBtn.MouseButton1Click:Connect(function() cycleStatus(name) end)
                            Entries[name] = {frame = e, statusLabel = statusBtn, nameLabel = nameLabel}
                        end
                        local function clear()
                            for _, c in next, list:GetChildren() do
                                if c:IsA("Frame") then c:Destroy() end
                            end
                            Entries = {}
                        end
                        local function rebuild()
                            clear()
                            for _, name in ipairs(PL.Order) do
                                addEntry(name, PL.Players[name])
                            end
                        end
                        if o.Players then
                            for _, p in next, o.Players do
                                local n = p.Name or p[1] or "Player"
                                local s = p.Status or p[2] or "Default"
                                if not PL.Players[n] then
                                    PL.Players[n] = s
                                    insert(PL.Order, n)
                                end
                            end
                        end
                        if o.UseRealPlayers ~= false then
                            for _, plr in next, Players:GetPlayers() do
                                if plr ~= LocalPlayer and not PL.Players[plr.Name] then
                                    PL.Players[plr.Name] = "Default"
                                    insert(PL.Order, plr.Name)
                                end
                            end
                            Library:Connection(Players.PlayerAdded, function(plr)
                                if plr == LocalPlayer then return end
                                if not PL.Players[plr.Name] then
                                    PL.Players[plr.Name] = "Default"
                                    insert(PL.Order, plr.Name)
                                    addEntry(plr.Name, "Default")
                                end
                            end)
                            Library:Connection(Players.PlayerRemoving, function(plr)
                                if Entries[plr.Name] then
                                    Entries[plr.Name].frame:Destroy()
                                    Entries[plr.Name] = nil
                                end
                                PL.Players[plr.Name] = nil
                                for i, v in ipairs(PL.Order) do
                                    if v == plr.Name then remove(PL.Order, i); break end
                                end
                            end)
                        end
                        rebuild()

                        local api = {
                            Add = function(n, s) addEntry(n, s) end,
                            Set = setStatus,
                            Get = function(n) return PL.Players[n] end,
                            Cycle = cycleStatus,
                            Remove = function(n)
                                if Entries[n] then Entries[n].frame:Destroy(); Entries[n] = nil end
                                PL.Players[n] = nil
                                for i, v in ipairs(PL.Order) do
                                    if v == n then remove(PL.Order, i); break end
                                end
                            end,
                            Clear = function() clear(); PL.Players = {}; PL.Order = {} end,
                            GetAll = function() return PL.Players end,
                            Refresh = rebuild,
                        }
                        Library.PlayerList.API = api
                        return api
                    end

                    return Section
                end

                return Sub
            end

            function Tab:SelectSubTab(sub)
                Library:CloseOpen()
                for _, s in next, Tab.SubTabs do
                    local active = s == sub
                    s.Page.Visible = active
                    s.Marker.Visible = active
                    Library:Tween(s.Button, {TextColor3 = active and Theme.Accent or Theme.TabInactive}, 0.1)
                end
                Tab.CurrentSubTab = sub
            end

            return Tab
        end

        function Window:SelectTab(tab)
            Library:CloseOpen()
            for _, t in next, Window.Tabs do
                local active = t == tab
                t.SubTabRow.Visible = active
                t.Marker.Visible = active
                Library:Tween(t.Button, {TextColor3 = active and Theme.TabActive or Theme.TabInactive}, 0.1)
                if not active then
                    for _, s in next, t.SubTabs do s.Page.Visible = false end
                else
                    if t.CurrentSubTab then
                        t:SelectSubTab(t.CurrentSubTab)
                    elseif t.SubTabs[1] then
                        t:SelectSubTab(t.SubTabs[1])
                    end
                end
            end
            Window.CurrentTab = tab
        end

        return Window
    end
--

-- Config system
    function Library:GetConfig()
        local cfg = {}
        for k, v in next, Flags do
            if typeof(v) == "Color3" then
                cfg[k] = {type = "Color3", value = v:ToHex()}
            elseif typeof(v) == "EnumItem" then
                cfg[k] = {type = "Enum", value = tostring(v)}
            elseif type(v) == "table" then
                cfg[k] = {type = "table", value = v}
            else
                cfg[k] = {type = type(v), value = v}
            end
        end
        return HttpService:JSONEncode(cfg)
    end

    function Library:LoadConfig(json)
        local ok, cfg = pcall(function() return HttpService:JSONDecode(json) end)
        if not ok or type(cfg) ~= "table" then warn("[random nice] LoadConfig: invalid json") return end
        for k, v in next, cfg do
            local value
            if type(v) == "table" and v.type == "Color3" then
                value = Color3.fromHex(v.value)
            elseif type(v) == "table" and v.type == "Enum" then
                local enumType, enumName = v.value:match("^Enum%.([^.]+)%.(.+)$")
                if enumType and enumName then
                    local ok2, item = pcall(function() return Enum[enumType][enumName] end)
                    value = ok2 and item or Flags[k]
                else value = Flags[k] end
            else value = v.value end
            Flags[k] = value
            if ConfigFlags[k] then pcall(ConfigFlags[k], value) end
        end
    end

    function Library:RefreshAccent(c)
        Theme.Accent = c
        local function apply(parent)
            for _, d in next, parent:GetDescendants() do
                if d:GetAttribute("AccentBg")     then d.BackgroundColor3 = c end
                if d:GetAttribute("AccentText")   then d.TextColor3       = c end
                if d:GetAttribute("AccentImage")  then d.ImageColor3      = c end
                if d:GetAttribute("AccentStroke") then d.Color            = c end
            end
        end
        apply(Holder)
        if Library.HUD then apply(Library.HUD) end
    end
--

-- Settings tab
    function Library:Settings(window)
        local Tab = window:Tab("config")
        local Sub = Tab:SubTab("general")

        local Configs = Sub:Section({Name = "configs", Side = "Left"})
        local cfgName = ""
        local function ensureFolders()
            if not makefolder then return false end
            if not isfolder(Library.Directory) then makefolder(Library.Directory) end
            if not isfolder(Library.Directory .. "/configs") then makefolder(Library.Directory .. "/configs") end
            return true
        end
        local function listConfigs()
            local out = {}
            if isfolder and isfolder(Library.Directory .. "/configs") and listfiles then
                for _, f in next, listfiles(Library.Directory .. "/configs") do
                    local n = tostring(f):match("([^/\\]+)%.cfg$")
                    if n then insert(out, n) end
                end
            end
            return out
        end
        ensureFolders()
        local cfgDropdown
        local function refreshList()
            if cfgDropdown then cfgDropdown.Refresh(listConfigs()) end
        end
        cfgDropdown = Configs:Dropdown({Name = "config", Options = listConfigs(), Flag = "_cfgList", Callback = function(v) cfgName = v end})
        Configs:Search({Placeholder = "config name..", Callback = function(t) cfgName = t end})
        Configs:Button({Name = "save", Callback = function()
            if cfgName == nil or cfgName == "" then warn("[random nice] no config name") return end
            if not (writefile and ensureFolders()) then warn("[random nice] no file API") return end
            local data = Library:GetConfig()
            local ok, err = pcall(writefile, Library.Directory .. "/configs/" .. cfgName .. ".cfg", data)
            if not ok then warn("[random nice] save failed: " .. tostring(err)) end
            refreshList()
        end})
        Configs:Button({Name = "load", Callback = function()
            if cfgName == nil or cfgName == "" then warn("[random nice] no config selected") return end
            local path = Library.Directory .. "/configs/" .. cfgName .. ".cfg"
            if not (isfile and isfile(path)) then warn("[random nice] config not found") return end
            local ok, data = pcall(readfile, path)
            if not ok then warn("[random nice] read failed") return end
            Library:LoadConfig(data)
        end})
        Configs:Button({Name = "delete", Callback = function()
            if cfgName == nil or cfgName == "" then return end
            local path = Library.Directory .. "/configs/" .. cfgName .. ".cfg"
            if isfile and isfile(path) and delfile then pcall(delfile, path) end
            refreshList()
        end})
        Configs:Button({Name = "refresh", Callback = refreshList})

        local Settings = Sub:Section({Name = "menu", Side = "Right"})
        Settings:Keybind({Name = "menu key", Flag = "_menuBind", Default = Enum.KeyCode.RightShift, ShowInList = false, Pressed = function()
            Library:SetVisible(not Library.Visible)
        end})
        Settings:ColorPicker({Name = "menu color", Flag = "_accent", Default = Theme.Accent, Callback = function(c)
            Library:RefreshAccent(c)
        end})
        Settings:Toggle({Name = "show watermark", Flag = "_watermark", Default = true, Callback = function(v)
            if Library.Watermark_ then Library.Watermark_:SetVisible(v) end
        end})
        Settings:Toggle({Name = "show keybinds", Flag = "_keybinds", Default = true, Callback = function(v)
            if Library.Keybinds_ then Library.Keybinds_:SetVisible(v) end
        end})

        local Info = Sub:Section({Name = "info", Side = "Right"})
        Info:Label({Name = "random nice.lua v1.0"})
        Info:Label({Name = "press menu key to toggle"})
        return Tab
    end
--

    Library:Connection(UserInputService.InputBegan, function(input, gp)
        if gp then return end
        if Flags["_menuBind"] then return end
        if input.KeyCode == Enum.KeyCode.RightShift then
            Library:SetVisible(not Library.Visible)
        end
    end)
    Library:Connection(Holder:GetPropertyChangedSignal("Enabled"), function()
        if not Holder.Enabled then Library:CloseOpen() end
    end)
    Library:Connection(UserInputService.InputBegan, function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.MouseButton2 then return end
        local open = Library.OpenElement
        if not open then return end
        local function inFrame(frame)
            if not frame or not frame.Visible then return false end
            local mouse = UserInputService:GetMouseLocation() - vec2(0, GuiOffset)
            local p, s = frame.AbsolutePosition, frame.AbsoluteSize
            return mouse.X >= p.X and mouse.X <= p.X + s.X and mouse.Y >= p.Y and mouse.Y <= p.Y + s.Y
        end
        local frames = open.Frames or {open.Frame}
        for _, f in next, frames do
            if inFrame(f) then return end
        end
        Library:CloseOpen()
    end)
end

-- Demo
do
    local Window = Library:Window({Title = "random nice", Size = vec2(620, 540)})

    local Rage = Window:Tab("rage")
    local AntiAim = Window:Tab("anti-aim")
    local Visuals = Window:Tab("visuals")
    local Misc = Window:Tab("misc")
    local Players_ = Window:Tab("players")

    local RageGen   = Rage:SubTab("general")
    local RageWeap  = Rage:SubTab("weapons")
    local RageAcc   = Rage:SubTab("accuracy")

    local Aimbot = RageGen:Section({Name = "aimbot", Side = "Left"})
    Aimbot:Toggle({Name = "enabled", Flag = "rage_enabled", Default = true})
    Aimbot:Toggle({Name = "auto fire", Flag = "rage_autofire", Default = true})
    Aimbot:Toggle({Name = "auto scope", Flag = "rage_autoscope", Default = true})
    Aimbot:Toggle({Name = "silent aim", Flag = "rage_silent", Default = true})
    Aimbot:Slider({Name = "minimum damage", Flag = "rage_mindmg", Min = 1, Max = 100, Default = 24})
    Aimbot:Slider({Name = "hitchance", Flag = "rage_hc", Min = 0, Max = 100, Default = 60, Suffix = "%"})
    Aimbot:Dropdown({Name = "hitboxes", Flag = "rage_hb", Multi = true, Options = {"head", "chest", "stomach", "arms", "legs"}, Default = {"head", "chest"}})

    local Override = RageGen:Section({Name = "key override", Side = "Left"})
    Override:Keybind({Name = "force baim", Flag = "rage_baim", Default = Enum.KeyCode.X, Mode = "Hold"})
    Override:Keybind({Name = "force safe point", Flag = "rage_sp", Default = Enum.KeyCode.C, Mode = "Hold"})
    Override:Keybind({Name = "double tap", Flag = "rage_dt", Default = Enum.KeyCode.V, Mode = "Toggle"})

    local Excl = RageGen:Section({Name = "exploits", Side = "Right"})
    Excl:Toggle({Name = "double tap", Flag = "ex_dt"})
    Excl:Toggle({Name = "hide shots", Flag = "ex_hs", Default = true})
    Excl:Slider({Name = "max charge", Flag = "ex_charge", Min = 0, Max = 16, Default = 14})

    local AntiAimGen = AntiAim:SubTab("general")
    local AAA = AntiAimGen:Section({Name = "anti-aimbot angles", Side = "Left"})
    AAA:Toggle({Name = "enabled", Flag = "aa_enabled", Default = true})
    AAA:Dropdown({Name = "pitch", Flag = "aa_pitch", Options = {"off", "down", "up", "minimal", "random"}, Default = "down"})
    AAA:Dropdown({Name = "yaw base", Flag = "aa_yaw", Options = {"forward", "backward", "left", "right"}, Default = "backward"})
    AAA:Slider({Name = "yaw modifier", Flag = "aa_yawmod", Min = -180, Max = 180, Default = 0, Suffix = "°"})

    local Fakelag = AntiAimGen:Section({Name = "fakelag", Side = "Right"})
    Fakelag:Toggle({Name = "enabled", Flag = "fl_enabled", Default = true})
    Fakelag:Slider({Name = "limit", Flag = "fl_limit", Min = 1, Max = 16, Default = 14})
    Fakelag:Dropdown({Name = "trigger", Flag = "fl_trig", Options = {"never", "in air", "moving", "always"}, Default = "always"})

    local VisGen = Visuals:SubTab("general")
    local ESP = VisGen:Section({Name = "player esp", Side = "Left"})
    ESP:Toggle({Name = "enabled", Flag = "esp_enabled", Default = true})
    ESP:Toggle({Name = "boxes", Flag = "esp_box", Default = true})
    ESP:Toggle({Name = "name", Flag = "esp_name", Default = true})
    ESP:Toggle({Name = "health bar", Flag = "esp_hp", Default = true})
    ESP:Toggle({Name = "weapon", Flag = "esp_weapon"})
    ESP:ColorPicker({Name = "box color", Flag = "esp_color", Default = rgb(255, 255, 255)})

    local World = VisGen:Section({Name = "world", Side = "Right"})
    World:Toggle({Name = "remove smoke", Flag = "vis_smoke"})
    World:Toggle({Name = "remove flashbang", Flag = "vis_flash"})
    World:Slider({Name = "world brightness", Flag = "vis_bright", Min = 0, Max = 100, Default = 50})

    local MiscGen = Misc:SubTab("general")
    local MiscMain = MiscGen:Section({Name = "movement", Side = "Left"})
    MiscMain:Toggle({Name = "bunny hop", Flag = "misc_bhop", Default = true})
    MiscMain:Toggle({Name = "auto strafe", Flag = "misc_strafe", Default = true})
    MiscMain:Toggle({Name = "edge jump", Flag = "misc_edge"})
    MiscMain:Keybind({Name = "edge jump key", Flag = "misc_edgekey", Default = Enum.KeyCode.Space, Mode = "Hold"})

    local MiscOther = MiscGen:Section({Name = "miscellaneous", Side = "Right"})
    MiscOther:Toggle({Name = "remove scope overlay", Flag = "misc_scope"})
    MiscOther:Toggle({Name = "thirdperson", Flag = "misc_tp"})
    MiscOther:Search({Placeholder = "search..", Flag = "misc_search"})

    local PlayersGen = Players_:SubTab("list")
    local PList = PlayersGen:Section({Name = "players", Side = "Left"})
    PList:PlayerList({AddPlaceholder = "add player.."})

    Library:Watermark({Text = "random nice"})
    Library:KeybindList({Title = "keybinds"})
    Library:Settings(Window)

    Window:SelectTab(Rage)
end

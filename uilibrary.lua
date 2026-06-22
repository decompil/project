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
    Directory      = "Scythelua",
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
                --print(frame.Position)
            end
        end)
    end

    Library.NotifyStack = Library.NotifyStack or {}

    function Library:Notify(opts)
        opts = opts or {}
        local text = opts.Text or "notification"
        local duration = opts.Duration or 3
        local gap = 6

        local frame = Library:Create("Frame", {
            BackgroundColor3 = Theme.Background,
            BorderSizePixel = 0,
            Position = dim2(0, 14, 0, -40),
            Size = dim2(0, 180, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            AnchorPoint = Vector2.new(0, 0),
            BackgroundTransparency = 1,
            Parent = Library.HUD,
        })
        Library:Stroke(frame, Theme.Border, 1)

        local accentBar = Library:Create("Frame", {
            BackgroundColor3 = Theme.Accent,
            BorderSizePixel = 0,
            Size = dim2(1, 0, 0, 1),
            Position = dim2(0, 0, 0, 0),
            Parent = frame,
        })
        accentBar:SetAttribute("AccentBg", true)

        local lbl = Library:Create("TextLabel", {
            BackgroundTransparency = 1,
            AutomaticSize = Enum.AutomaticSize.Y,
            Size = dim2(1, 0, 0, 0),
            Position = dim2(0, 0, 0, 1),
            FontFace = Library.Font,
            TextSize = 13,
            TextColor3 = Theme.Text,
            Text = text,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextWrapped = true,
            Parent = frame,
        })
        Library:Padding(lbl, 4, 8, 14, 8)

        local timerBg = Library:Create("Frame", {
            BackgroundColor3 = Theme.ElementBg,
            BorderSizePixel = 0,
            AnchorPoint = Vector2.new(0, 1),
            Position = dim2(0, 0, 1, 0),
            Size = dim2(1, 0, 0, 2),
            Parent = frame,
        })

        local timerBar = Library:Create("Frame", {
            BackgroundColor3 = Theme.Accent,
            BorderSizePixel = 0,
            Size = dim2(1, 0, 1, 0),
            Parent = timerBg,
        })
        timerBar:SetAttribute("AccentBg", true)

        local stack = Library.NotifyStack
        insert(stack, frame)

        local function getStackOffset(f)
            local offset = 10
            for _, v in next, stack do
                if v == f then break end
                if v and v.Parent then
                    offset = offset + v.AbsoluteSize.Y + gap
                end
            end
            return offset
        end

        local function repositionAll()
            local offset = 10
            for _, v in next, stack do
                if v and v.Parent then
                    Library:Tween(v, {Position = dim2(0, 14, 0, offset)}, 0.15)
                    offset = offset + v.AbsoluteSize.Y + gap
                end
            end
        end

        frame.Position = dim2(0, 14, 0, getStackOffset(frame))
        Library:Tween(frame, {BackgroundTransparency = 0}, 0.2)
        Library:Tween(lbl, {TextTransparency = 0}, 0.2)

        local elapsed = 0
        local conn
        conn = RunService.Heartbeat:Connect(function(dt)
            elapsed = elapsed + dt
            local remaining = math.clamp(1 - (elapsed / duration), 0, 1)
            timerBar.Size = dim2(remaining, 0, 1, 0)

            if elapsed >= duration then
                conn:Disconnect()
                Library:Tween(frame, {BackgroundTransparency = 1}, 0.15)
                Library:Tween(lbl, {TextTransparency = 1}, 0.15)
                Library:Tween(timerBar, {BackgroundTransparency = 1}, 0.15)
                task.delay(0.2, function()
                    frame:Destroy()
                    for i, v in next, stack do
                        if v == frame then remove(stack, i); break end
                    end
                    repositionAll()
                end)
            end
        end)

        task.delay(0.05, repositionAll)
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
        local W = {Text = opts.Text or "Scythe.vip", Visible = opts.Visible ~= false}

        local Frame = Library:Create("Frame", {
            BackgroundColor3 = Theme.Background,
            BorderSizePixel = 0,
            Position = opts.Position or dim2(0, 905, 0, 203),
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
        local frameCount = 0
        Library:Connection(RunService.RenderStepped, function(dt)
            if not Frame.Visible then return end
        
            frameCount = frameCount + 1
            lastUpd = lastUpd + dt
        
            if lastUpd < 0.5 then return end
        
            local fps = math.floor(frameCount / lastUpd + 0.5)
            frameCount = 0
            lastUpd = 0
        
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
            Title = cfg.Title or "Scythe",
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
        local encoded = "iVBORw0KGgoAAAANSUhEUgAAA6IAAAQACAYAAAD7i+TsAAAQAElEQVR4Aez9CZRsbV3eDf+vqu7zzPPD8/CAgCA4vRFBRXACBRFlEiccY4zGMV9mv2XelfUlb7LyRVeWyVrGvInrzeCEkUEBRXEAFRQQFJlECDL7DOf0OX1OT2c+3bXf+3fvc3dXV1dVV3dVdddw7XP+fc/Tb+9ddV9176ER3kzABEzABEzABEzABEzABEzABEzgCAlYiB4h7J2m7DMBEzABEzABEzABEzABEzCB+SVgITq/+37+Ru4Rm4AJmIAJmIAJmIAJmIAJTAQBC9GJ2A3uhAnMLgGPzARMwARMwARMwARMwAQ6CViIdhJx2ARMwASmn4BHYAImYAImYAImYAITTcBCdKJ3jztnAiZgAiYwPQTcUxMwARMwARMwgUEJWIgOSsr5TMAETMAETMAEJo+Ae2QCJmACJjCVBCxEp3K3udMmYAImYAImYAImcHwE3LIJmIAJDEvAQnRYgi5vAiZgAiZgAiZgAiZgAuMn4BZMYKYIWIjO1O70YEzABEzABEzABEzABEzABEZHwDWNi4CF6LjIul4TMAETMAETMAETMAETMAETMIGuBPoK0a4lHGkCJmACJmACJmACJmACJmACJmACQxCwEB0C3piKuloTMAETMAETMAETMAETMAETmGkCFqIzvXs9uMEJOKcJmIAJmIAJmIAJmIAJmMBREbAQPSrSbscETGAvAceYgAmYgAmYgAmYgAnMJQEL0bnc7R60CZjAPBPw2E3ABEzABEzABEzguAlYiB73HnD7JmACJmAC80DAYzQBEzABEzABE2gjYCHaBsNeEzABEzABEzCBWSLgsZiACZiACUwqAQvRSd0z7pcJmIAJmIAJmIAJTCMB99kETMAEBiBgIToAJGcxARMwARMwARMwARMwgUkm4L6ZwLQRsBCdtj3m/pqACZiACZiACZiACZiACUwCAfdhCAIWokPAc1ETMAETMAETMAETMAETMAETMIGDEzi8ED14Wy5hAiZgAiZgAiZgAiZgAiZgAiZgAmEhOmUHgbtrAiZgAiZgAiZgAiZgAiZgAtNOwEJ02veg+38UBNyGCZiACZiACZiACZiACZjACAlYiI4QpqsyARMYJQHXZQImYAImYAImYAImMKsELERndc96XCZgAiZwGAIuYwImYAIm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EExiEaNMaLvVLNUTXEndkh03QgLsg2Fsv66UuvfL1ytdUhY7vdL3iy/tH6W7X58mIV3ay7UbI/ravuJ533336nGPe6xuueWW/CMSZTiXuVSXvFNqc99tC9G5PwQMwARMwARMwARmn0D7SiiT2NkfsUdoAtNBQFLXjnJJ7pkzZ3eteN599526/fbbg1czSQqvinZFNzWRxyNEpwaPO2oCJmACJmACJjALBHh6ruRLcmdhX07DGCTlFVXpcO40jHGcfZSUq7906VJ22//cfvuteuCBB3TTTTflqxy65WnPb//kErAQndx9M/KeuUITMAETMAETmFcCt91ya37oCeP3iigUbCYwOQSkWniWHkk74dOnl3etipY89913X14dJXzu3LmueUizTS4BC9HJ3Tfu2WwQ8ChMwARMwAQmhAAPQJmQrrgbJmACHQQkhaQcy49FXJrLJfX97gO95557dNtttwX3i+aC/jNVBCxEp2p3ubMmYAKDEXAuEzABE9hLgPvK9sYeT4ykPOmWDuceT69H16p0uHFLdbnR9cQ1TRoBSfmSW4QoJilWVtZ6rngmIap7771XkzYO92d/Ahai+zNyDhMwARMwgUEIOI8JTDiB22+9zZPVCd9H7p4JFAJSfbqyOtpvVbTktzt9BCxEp2+fuccmYAImYAImsE3AnoMRkOrJ7cFKObcJmMBRE0CAcsnt5uZmYGfP+p2hR70Pxt2ehei4Cbt+EzABEzABEzCBiSHQVCPU8yK/1E21IrDou0VUqZJBrJXydbO26plwH9Taik+l96Dj3ZM/jTqRjVbaB8UIF5OUL31O2Sby/57xpHG0x3XrtFSPSVKkwe2xMnbcGPOWehD9bN/zI9J51scWFhqxtXUtjaIVJ04shNJJe+3aldjY2DiK4aV2/f8oCDSOohG3YQImYAImYAImYAImYALDEehdWkIW9U6f9hRptsfXuX8Q5d3itra2OqMdnmICFqJTvPPcdRMwARMwARMwgeMhICmt0hzejqfXbnVSCEj9j51J6WfuxyH+SMONr12ISso9II5LdHPAf2aCgIXoTOxGD8IETMAETMAETMAE5pOAVAuVWR29NNvj67bfEJ3ESztjL/eLnj17di4uz2X8s24WorO+hz0+EzABEzABEzABE5hBApLyqvQMDi0PSZrt8eVB9vhThGhnMmL02jXuHe1McXga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aI3A+fkl46Sl8TlRLBVENrLqIs2UFQEREAEREIHuE5CFIlADAQWiNUCUChEQgfER4HdDx+e1PBYBERABERABEWiLgB+XJ7cB+M3epgpEe7vrZLgIiEBbBD5+PAnu7u4Sh+fkQPGVzFP8dl/SPtrcF7ayUwREQATGToBzTFT6xiNqe1J+E/74J/VvYqymxuhJINqU+9IrAiIgAusROD09D25ubtz3QbJ6+okpq00X6/pqdxdZyiYREAEREAERaIIA52pAV0SbYCudXSEgO0RABFYI8JZcPixgCGci485xYouXaVsEREAERKC7BAC4E6PActpdi2VZXQT29/dRl6629OiKaFvkNa4IpBBQcXcJnJycBT4IZdBGKWttlb5lx6y7H32oInXbs66+PNvz9MX757VXvQiIgAiIgAjUQYDzTx162tahQLTtPaDxRUAEukCgkA23t7eu3XQ6NX4S8KmrKPinTJ+Cqks366JNpZ1RRxEQAREQAREQgc4TUCDa+V0kA0VABLpA4NOn0+Dq6soFoLwtF8DD7VDr2geEfdft12R7ILQJWKR54wGLtsD6eWPyRmi2Hsi2OW90YLl/XnvVi4AIiEDdBHgSMUnqHmds+oDl4zsQbrfJIbqft7e32zSltrEViNaGUopEQASGTIAPKGIAyquhvD2XMmR/5duACcg1ERABERCB3hEA8GAzsMg/FPYwo0C0hztNJouACGyWwPHxJ/dzLVtbW+4q6Gw2c1dGN2tF90YLrElVxHbv9Tvue6+dkfGNE9AAItAEAQBuXgKW0ybGks72CQBwRgBh6jZ6/EeBaI93nkwXARFongB/ruXbt29uoucVUQahvBrKfPOjawQREAEREIEKBNRVBAZHAIDh3VlmAC8FogPYiXJBBESgOQL8uRZqZ+DJAJQCwHDb6CUCIiACIiACIhAjoM2mCQxlDaJAtOlPivSLgAj0lgAfUMTAk2ceARheDQXgzkSy3OglAiIgAiIgAh0kAMDdyQMkpx00WSZFCACIbK1mEwPR1WadL1Eg2vldJANFQATaIHB2duaekgvAXf3k0+p44PdBqdFLBERABERABERABBoiAKQHowcHB+mVDdnThNohBKJNcJFOERCBkRPgb4byCigDUApx+CCUV0MZlLJMIgIiIAIiIAIiIAJNEAAGEW+molEgmopGFdkEVCsCwyVwcnoeXN/cmenWlok+GfVuFhjKPIBLGaBS+kpiHgQmS6K+J+X76re3O8mndcq8HqUiIAIi0BqBwC7ly0hrBnd4YMyNuRfO7RQTewFwtzzHimvf9GP7FMDD0/p3dnZqH68thfbT29bQGlcERGBtAuqwEQI3Nzfue6BFBgNQpJnaiIAIiIAIiIAI9IyADwR7ZnZvzFUg2ptdJUNFQAQ2QeCX9+8C3noLwJ31BGCyZBM2NTVGll+sa2pc6RUBERABEWiXgI7xxfknBaPklyfFRxhvSwWi49338lwERCBG4OTsNOB3Qzm5zGazWK02N0xAw4mACIiACDRIgHMdpcEhRq2abCmjhpDjvALRHECqFgERGA+Bz58/m62tLcMroklnQI2ZWxhRsZspb04+eZLSVcUi0CIBDS0CIjA2Apyrxubzuv4mrwmKaamTL3VRio3c/VYKRLu/j2ShCIjABgi8P/4Q8Em4/gDv03WHZj/Kuv3UXgREYMQE5LoIdIwA57Eq0jF3ajGHwSilDmV5bJPGYJ+k8j6XKRDt896T7SIgArUQuLj8Elx9uzHbW7smmMP9bugQD/hGLxEQAREQgQcCyiwIaM5bsMjLlQlGxTeZqgLRZC4qFQERGBGBy8tLw8eh393dPQShZSaNMn1GhFmuioAIiIAIdJjAhuawDhNo1rSyfNmP0qx17WhXINoOd40qAiLQEQLv3h/zpyMfAlB+P5QPKuIZz6jQXE4EvH13MjXGyWSy9GRdtpEsEyCzNFluqS0REAEREIFNEeDdP0li7n+TNKlunTKYqckUwAALMT17RdcH6+SLuul1TqeWo+XEtQmF5bu7u0XVRNp1MzvpplmySgREQAQ2Q4AHdo7kUyCcGBlwspwCgIkTTgIuY/9E83ZT7wQCYpQARUUiIAIiIAIiUIIAsFiPlOjeuS6DD0Q7R1wGiYAIdIbA8ccTGycFxv5xT8oFsHKGFoAxmC8J2xu9ChMQr8Ko1FAEREAENkIAwNJ8B9S7vREnWhwEqMYrz3QAK00AuH22/+QpVip7WqBAtKc7ruNmyzwR6DyBk5OT4Pr62h3UAbhglEYzaPICpB/r2Ybt48LyohLvO+RtMhmyf/JNBERABESg3wQ4T3npiidRewC4NUtXbKvDDgWidVCUDhHoBAEZsQ4BBqE8wE8mW/bAPrVdw8Mhy3ibLgUID/pAmLIuKrbTw9uXPxQoIwIiIAIiIAIiIAIlCABI7BX92lBig54Vhiuvnhktc0VABESgCoFffvnl/gFFDELDgz0QpgwoqZspEJZxOy6sdxKEt/bG67W9SoC8VktVIgIiIAIiIAIikEcAgD1xjrxmvapXINqr3SVjRUAEqhI4PT0N+FRcAMafWYxe/TT25Z9SZ7OJB30FVCRTTupiV2509RIBERABEegEgfun83bClhaM4FyYJcAi4GQ7byKwKPdlfU4ViPZ578l2ERCBtQicnZ0F3759c78ZOp8bG4ga991QHuQBuKATgC2fODH3LwD3ubD9w0ZGhjrzJKP7oKvIZdAODtc5eSYCIiACIrAhAsBi7cEhAbh1CvNDEQWiQ9mT8kMERCCTwMXll+DL1yszswEoxR7N3ZNyg2BmtrZ4KJy7bQAu5VVSBkxO5rARqA1OsWWmk+0HAWDVlJdMgwdeSa4Dd1HuiUBNBKRGBESgawQ4h8VlXRsBuJPh/u4snwJw6xBgkVI3x9vZ2WF2MMLV12CckSMiIAIikEbg5ubGVfG2W5fJ+MODfUZ1blXV/rkDqIEIiIAIiECzBKRdBNYgAGCN1mrqCSgQ9SSUioAIDJYAr4be3t4+XL1koOjPPMadZl28zG+zjuK3k9K8+qQ+KhMBERABERABETCmDwyA+oPO+NoBWB2D65b9J09XK/oALcVGBaIpYFQsAiIwHAJfv35dus2FniVdGY1PBGyXJGxHidcllcXbaFsEREAEREAERKB/BAC4E9pxywHEi2rZjq8pgGbGMcbUYm8ZJQpEy1BTHxEQgd4Q+HRyFtzd3Tl7+b1PZgC472UwnyWcBChZbVQnAiIgAiIgAiIwbALAahAIIDEwXZdE0XUGr4iuq7vr7ccdiHZ978g+ERCBSgTOLz67IBQIA08GogAMD+b8CRcTeWVNBKyjRJqvZPPqVzqoQAREQAREQAREoJcEANRud3wdEd/m2qX2QVtWqEC05R0wxuHlswhsgsD5+WUQvSUXgAtAjX0xILXJwzt+sH+oiGXYjhIrLnR1Nd5H2yIgAiIgAiIwegI9+D1RoP6gk/s9aT3B8iRhW6AZO5LG21SZAtFNkdY4ItAugdGNzqfk8gFFDDp5AOeZRH4vlNu8VZfbhMI6putItE80v44OtRUBERABERABEeg2AaCZ4K/M2gFoxpY294AC0Tbpa2wREIFGCLx/fxwwEGXgyQGAxa25DEBZ7m/NBeC+4wEsp2wHLJcBi23qpQCLMmA5bwxbSERABERABERgMwQY4FA2M9rARvFXZyNpMLfrh3sxkfKqnk+wZagPZmo4hk9Zxu35zFbbcbemOzYzMWx/+Ow5zMBeCkQHtkPljgiMncDx8XFABkC147UmclLsqchsERABERABEcggwDk+LhnNDVBtTZGkG4DTC6ymvr23EYAvGlSqQHRQu1POiMC4CZyengZXV1eGVzt5RXPcNOS9CGyWgEYTAREQgSEQAJoP+gCkBqEAVjAOdU2jQHRlV6tABESgrwT4cCIerBmIFvHBn2lkWqS92oiACIhAxwjIHBEYJYG8eZv1WZIEDYALDuN1AOJFlbcBuLGAME1SCMDQB9ZxbcN0aKJAdGh7VP6IwEgJvH//PgDCAzq/A+oP3kVxsD0l2p7bVSSqS3kREAEREIGhEJAfXSDg5+c6bAGwogaACxZXKmouoB9xlQBcka9TIOpw6I8IiIAIdI/AycmJPVYHxgegAEpPHlaROwPJtHueyiIREAEREAERGCmBFLebmK8BpIxWTzFt9kKNPu9TlgELG7i+YdnQRFdEh7ZH5Y8IjIzAxcWF+71QAIY/zQLABZIjwyB3RUAEREAEREAEShAAFgFfie6luviAk+sWit/2KRDaxG0OAITbzG9amhxPgWiTdKVbBESgcQKfP392Vz/526A8YEclb3C2zWujehEQAREQAREQgW4TKDufA+0EeLSX4qkyHxVf7lOgHTv9+E2lCkRTyapCBESg6wR+8/O7IDD2MIapMVYWeZi5rQHgglST8uJ3LoCwDbCapnR7KIbNtSl2+FbfbfrOsVt1XoOLgAiIQAcI8FgYlYmdyygdMK1RE+hjXMjB2LmfEq+LbwPIXB/kGc/f+qTwdz/LyNQuXSgT2JWLFea9sMwEM2NXMk5YfrD/BHnv+mytAAAQAElEQVQ29bHeYuij2bJ5sATkmAgUJPDhw8egYFM1EwEREAEREAERGDgBXlHcpItA/bFhkg9A/eNsklPWWApEs+ioTgRGQqBvbp6fXwbfvn3LNBsY7oE703FVioAIiIAIiMDICCQFcE0iADazxgBgJpPhhmvD9czoJQIiMFQCl5eXJu0JcgAMgD64PmobN71oGDVsOS8CIiACItA5AvF5MGkbQOp6xwzgpUB0ADtRLojAmAj85je/uN8LTQpEAQWgXf8scKKltGenRhYBERABERgSga7NKUD+WqSIzWwDQFdEjV4iIAIi0AECv/zyPuDTcbe2tnTVswP7Y10TOKmu20ftB0JAboiACIhAzQQ4p1BqVltaHYDSa5MkP1gGQFdEjV4iIAIi0DKBT59Og5ubG7Ozs2P8wTlqEoDoZifytDNLOmFkh43IYse6Dpsu00SgEwRkhAgMlcBYnlYIwOzv73dvgVPTB0u35tYEUmpEQASaI3B2duEeTsQgFMDKGUcAzQ0uzbUQUOBYC0YpEQER6D4BWThCAkD96xDOm0D9eru0exSIdmlvyBYREIFEAnxCLg/I8/ncRIVPkqMAywdqtqUkKosUsk2S+DF8XaTLWlkALmgGktM8ZVXHz9O/yXpgwaDouMCiD7CaL6pH7URABERgbASGNH+k7TsgOi8s59P6FC0HlvUBy9txPZ63T+P18W3fzqfxem5zfcN0yKJAdMh7V76JwAAInJ6e2+N04L6sz4MypWm3ADQ9xGj12505Wt/luAiIgAiIgAgUIQCE65BNrHmK2JPapmKFAtGKANVdBESgOQIfP54E19fXbgAejCluw/4BwoO0zTbyBprV34jRHVc6tCCUn5CodBy/zBMBERABEegZAT6csWcmr2WuAtG1cD00VkYERKBhAmdnZ8Ht7a2ZzWZuJADuIUUMZiiuUH9EQAREQAREQAREYIAEAJiDgwOe7xygd6FLCkRDDvrbCwIyciwELi8vg6urqyV3GXxS+P1NpkuVJTeAQR/fS1Jppltd+6wZ66RVBERABERABLpDgHNm9C6w7lhWryUKROvlKW0iMDwCLXj09etX91AiAO5hP0km8CCdVL5uGZA+xrq61H6VAPcTZbVGJSIgAiIgAiIgAkkEOG9Op9OkqkGVKRAd1O6UMyLQfwIfPnwI7u7u3MOJeCD2AsCV8QwhAFPk5fumpUV0NNkmzS6WU5ocuw7dtDFP6hhHOkRABERABERgHQJ9n5tovwLRdfa42oqACIhARQInJ8sPJ+JtuBSqBWB4UKYwGDU1v4BiwW3Nw0pdtwjIGhEQAREQARHoBIEm1jqdcCxihK6IRmAoKwIi0B6Bk5Oz4Pr61gab2/bK55aZzcKfbOET43gwZkDqH17EM4W0lKGjl4kNJB9kMrE6Ju62XgCpKfVEhTqj4vXBFlL8tk9tcbW3tc0aZ/IkMMYkiS2u9KZPSWICO5qVpLpoWd7gAKxr6ZLXvyv1sIYkiS3WuxYCUiICIlAXAXv0dvMFAHf8rUtvF/V4X5NS67zJEj/3m4yXb5OUZnRbrsLcmESZ2vJQAjOx+2xZAJjnz5/DDPw1Gbh/ck8ERKAHBC4vv7jbcWkqADt3gNnOCSejzhklg0RABESgDAH1EYGREwCy1xpAdn2T+HgCvkn9XdGtQLQre0J2iMCICXz79s3we6FE4A++QHsTAO2QiIAIiIAIiEDdBKSvGwSAYmsMoFi7ur3i15Dq1tlFfQpEu7hXZJMIjIgAb8llEMqrjUA7B/x1cNNOyjp91FYEREAEREAERKA1ApUGBtZbm9SxRtje3q5kc186KxDty56SnSIwQAKfPp0GNzc3zjOe/QNgeAD3AsDdpgskp65jS39oY0tDa1gREAEREAEREIGGCAAopZnrAkqpzrFOh4eH5YyI6Wl3M390BaL5jNRCBESgAQJnZ3w40XXu74U2MLRUioAIiIAIiIAIiMASAQDu5PdS4f0GgPtcclJXAJqsfbilCkQb2LdSKQIikE3g8vIy4BNweeAGwoM7n4rrt4GwLFtL9VqOlydZo1Tpm6V3KHV5fPLq2+bQdfva5qPxRUAERGBMBIDNrE3GxFSB6Jj29rB9lXc9IsDbcRl48sFEQHg7Lre58AfgfnrFdORFmzpiiszoOAEuUTYpbeHg/wSl8PiYm8DMapHkn0GYm7zyxPGDYOmrAPRpHbGdTZYE87kJ5c62m61IUJFJ1Oequor2j45pLL91Jfr/kdc32jYpb1p+Jdm0Tlme/3n1fqyWMQxmeIBE890BVtvxuJHfUy2SCCgQTaKiMhEQgYIE1m/27t27wF4RtXPsYhEI4CH4nM1mD7frmpwXD/5Zktbd9wHgbsMBstM0PUB2Pz9OWv+ulgOhX3n2AWE7oJk0b/ym64Fsv5oev6v6gZBLG/b5/6kiaa59NkBeCqzW3I7akDQWEHICkFRduSxv/KoDAFg5PkZ1Aqv1QHbZOv2jbYeYB7JZAdn1Q2TifYLNTKz/dqFgmKfM7u4MT+wwP79fJ/B/AIBbPzDP9QOFJ7bNmi/2Lypx1QAMEEq8Lm2bdvJkvK/3z8kAYPb3933x4FMFooPfxXJQBLpD4OTkxM4jc7O7u2t4wKdlPmV+UwJgU0M1M460ioAIdIYAoONJZ3aGDBkEAa4LGKgBcEGmsS8ftLGOwm2KrXo4ec1tCoM6lndZgPBuMNoIwNBf2k7fDvafjOagokCUnwCJCIhA4wTsVdCAvxfKgywnCaDd4yzQ7viNA9cAtROQwm4RAPBwFQJYzW/CWgCbGEZjiMCoCADh/xUQBmtcNzBIozBPGHt7e+6kti8D8BC0AmF/0+GXt5smMs9AlHmg+7bTzrpEgWhdJKVHBEQgk8CXL19cPbA48+cK7B8/sdise8e3XWEDfzhOnjQwrFT2gAA/Fz0wcwwmdtZHYNgLRv4PZEmTO4bjNqlfussT4L7Jk/Law547Oztma2vLbTBA43gM1oDwf46/sXl0+AwUnthmPRsz5W25FG53WYDQFyBMaSt9pe/Mj0UUiI5lT8tPEWiRAL8Xend3ZzhhAHC30XDCyDIpr559AWReEQHAZpWEdlAqKVHn3hDgvqb0xmAZKgKNEGhHKf/3KO2MrlG7QoCBZDTwBMJ1AwM1Bqhv375+mNy5rqDd/NwAcGsCbvdJaDv9oH8vXxyiT7ZXtVWBaFWC6i8CIpBJ4Pj4OLi+vn64ZYaNOcHwgMu8Fx6Ifb7OFEAtE1NT9tXpq3RVI6B9XI3fur2B8H8TKJeuO94m2wPY5HCJYwFwxz4gOU3s1GKh/v+MMS3y79rQDEYBGF795JqB27QxfsWQdQAenjvBgI7Ctl0W/3kHQtvpB6XLNjdhmwLRJqhKpwiIgCNwfn7ufi+UB1cgPNjy4AuECyPXSH9aI8B9kSV5hmX1ZV1e/6HXk0GWtO1/lm2sa9u+vo4PoK+my+4aCfB/qIrUaEovVZEdDffrBwDuO6GHh8+W/sFYT2Ggyj5AuNZg36LSRDvakiUck/UA3Akj5hl0s3xMMhmTs/JVBERgswQuLy/dlVDeSsODrB+dV0M5cfjtTaQAKg8T9aGyMinoFAHt207tjt4aA1Q/zvTW+QqG6/+vArwBdvWfB6Y+wORVzpcvj1b+wfafPgbXE2xH8X36hAWA+8pS/Gpvn3woYavrokDUYdAfERCBugn8/O6XwExg7uYzMwvmJrDTh/1rWIbpxJXZ04AmSwJjTJbMrdIkCWx5ktjBrUYe9rzYzay3nRzi9mXZE6/zfePlfjtr6I3UJfjnbWbq7UxL2SZL0vrVVV6VEawCLxPLIi6+zjZLfOf5kcWGdXn98+oTjSpRCMCasyolVCV3Cez/W8sCMzVejLfFVHsFsEe0mMzNzHhZ1NvjGFYFgAHSpZp1drwgcLcrcmGeJJX1WwVZn9G5HT9Lon0tCBOXaH1S3nT8BaTvWwCJc1uUQZLPRco2hsV+9jEJTFQmU2Moddgw4WEjsP9P8zvD/N7eTqrax492zfbWxC4vAjOf3RrY/8LA/i9S0n4r2P9PpCotWQHAABGJHHsQyQfWr60pzN3ttRPafPj8AGZkL7ubR+Zx2+5qfBEYAYEPH4+DqJvA6I6tUfeVFwEREAEREIFMAoDmSQ9oYiNPAC6gY8AIwDx7tnxLrm/LdH9/H/bFrOvjMh3/Q3u9b0zHeFsud5ECUVKQDJ6AHNwcgU+fPrmHE/Egu7lRy41EG7OknFb1EgEREAERyDq2sk6ERCCNwHw+X6p69eoVlgoSNqbT6UMpA7uHjY5n+L9Ae3d3dztuaTPmKRBthqu0isAoCfDhRDc3N+5nWowxKwx4wF0pVIEIiIAIiIAIjJiA5sblnT+b8ZbcuWFa9HuTDET7xJG2MgBlSsm64rtMZ1hbCkSHtT/ljQi0SuDr16/uC/e8rcYbwgOszyvdBAGNIQIiIAIi0AcCnB8pfbB10zYyCOWYL168yL0aynYMRJn2hSeDUNpL4QMdmY5RFIiOca/LZxFogMD79+8DP3Hc3d25h2RkTQhZdQ2YJ5Ui0CwBaR8dAR7DqsjogMnhJQL87CwVaGOJANcTjx8/XirL2mAg2iem0UB0rLflcn8qECUFiQiIQCUCJydnwd3d3EwmWwaYmoenUvqnU8ZSmPs2Ri8REAERKE9APUVABIZHgEEoH97z/PnzQldDSYAPLGLal2CUgai39eho9Wdp6MsYRIHoGPayfBSBBgmcnp4HV1dXhmcjeUsuhbeZ+AOsHzq+7cuVioAIiIAI9IqAjBWBTAL8SRc24LzPn8WaTiZmb3fXMKrc3rInrG0l02A+N5TZ3Z2hsJ6prTZ7e3tMSgmDvFIdW+jUJ1ubwKNAtAmq0ikCIyFwfPwp+Pbtm+GBlE+541lM5uk+tzkJeWGZF7ah+G2fsmwd8f3S0nV0JbVN06vyYRBI2ufRsmF4me9F1Od18vmaFy38cSCaLmo3m/M2VB11HVZJbYuO7+1dSc3ULuzTJffOFMAAoSTZAoR1QHKa1EdlTRLolm4ADwb5zzfnfS+s9OVM+SBDAIbrBACGX+EBQh2s5xVQ9mWet6quczWUY1H4YCPq54lxAO7zzfIkAbLrk/pEy2hnlkTbRvO+DxAyePToUbR6dHkFoqPb5XJYBOojwEkjqg0ID+z+QButU14EREAEREAERGB8BLgmiHvt757iOoJ3UTEwZTsGk69eFXtAUVwnEK5B4uWVthvqTF8BmDIBd0MmtaJWgWgr2DWoCPSfwMePHwNOIMDiwM+JhZ6xnGnbAoS2AeXStu3X+M0SALI/F82O3r52INt/ILu+fQ+6awGQzQ5Ad42XZYUIBLZVFbHdR/Vm4JXkMK9eshwI/yfWeUAR+0WFuoBQT7S8iTwAd8UVSE6LjMkAvEi7IbdJC0SH7LN8EwERqEjg7Ows4G02DDiBxUE4GogCqDiKuouACIhAvwgAcIvTflktEqUlCgAAEABJREFUa0WgfgIMPClRzdFt3kJL4bqB5QwieTX04OApon3WyR8cHMC+1unSWlv6XOV7sK0ZXvPACkRrBlpNnXqLQPcJXF5euu+F8mDPAyktZp4ptynMb0I4bpZswgaNIQIiIAIkwGMRU4kIiMCCANcEFF/CPIUnsn3KOuZfv35ZOgilDgoDW6ZdFwbez549q+xv1/3Ms0+BaB4h1Q+fgDxciwAfTsTvcvBgH194+YmF5ZS1FKuxCIiACIhAbQR4DM6S2gaSIhFIIMDAMloc3+YagvUs55VRPqyI21WFn3nqrKqn6f51+du0nU3rVyDaNGHpF4EBEfj06VPAIJRn8ugWJxJ/wOfB3weiLOc226SJykVABERgKAR0vBvKnpQfdRLg+oDidTJP4Tb/ZyhcL/C7ki9f1vNbmtRH/V0X3ZYb7iEFoiEH/RUBEShA4Pr62v1UCycNBp2cRPykwu4s4zbLuS3pHAEZJAIiUDMBHe9qBip13SeAeSUbuU7gVVCe1Gb+6dOnlfT1sfP+/v7ob8vlflMgSgoSERCBTAIXny+Dv//5N8EsmJvJ1tTMTWAwnZh5EBgDuJT5re1tM93aMv4FwFani29XNg2CmQ2M08VYS7Ol7MjF+gHpvgOrdcW09qcVsOojsChr2xP76bWfZFNa8uwHvK/l0jz9qq9GAGZq6hAT2KVUA+JtS9Vvsl9c4GdJVC8SWETrE/NGryoEgPWOC1XGivb1nwnDYHINCYyda624flZhqMeW2XnYuLnWFkbemASGYmwa2HECWxeVra2Jmc1uze7utqnygCKrdun94sULTCYTAyzzXWpUw0boPz1KVsZ6Z4dlE8zvjF0pOZlOjHm0t5PcaYSlFscIvZbLIiACaxHglVB24JXQiT3A8wDLs5ksiwrLo9vKi4AIiEBrBDSwCIhAgwSqXRWlYQDMtj2BzXydAmBJXRtrE2DVBtoBwEynU6NXSECBaMhBf0VABFIInJydup9qYQBK4YHUS0oXFYuACIiACLRMAIAB0qUp86RXBPIIAHBNGJDxJ1fcRo1/gFB/jSpLqeJaiR0BGOYp9FlPyyWVUBSIhhz0VwREIIHA+eVFwKuhANwZvPl8bvyVUAalJuHFAy0loUpFIiACIiACIiAC9RNoXCNQPbgD4E6O0FgAZmenmVtU/fqEaxEKx9u0AFgZEoDhnWUrFSMumIzYd7kuAiKQQ4A/1cLg0x/UGYTyoA6sHmDjqtguT+J9hrYt/4OHs8BJLIa2v+P+JPm8Tllcn7ZFQASGQyDvWNC2p0D+PL+OjcCyviavDHLNQr7r2FeubXYv2gDgIfimz8+fP0d2r3HVKhAd1/6WtyJQmMC7d+8CBp5AeEsJ8+zMAzxTHmCZSkRABERABERABIZHAFiOmYDFNgAXYAHJaR6NJr4b6sf06xS/3UYaXyMBuhqatB9KBaJJilQmAiIwHAKnp6cuCKVHAAyvilJ4cAfgrnKxLn6gZZlEBERABESgeQI8/mZJ8xZoBBEoRgDASsMmvycJrI4XNYD/N9HtJvJcM3m9HA9AIw9m8mP0NVUg2p89J0tFYCMELi4ugi9fvjx8jwFYHNCBMAjlQZVBKQ1inqlEBERABERABERg2ASAxZqgiKfAeu2L6MxrA6SPuak1ix8HWNjSxIOZ8lh0vV6BaNf3kOxrmcD4hj8/P3dXPP3ZPN6SC8Aw8IweWJkH4G7NMQN9AaF/QHKa5zaQ3A8Iy8kwKnn6ul4PhH4BYdp1e6vaB4R+AuXSquOrf7cJANmfi6rWA83qr2pfXn9g3PYD2f5H5wbm4zyB5f7x+rRtIOyXVu/LuQagcOy4+DZZqe8DwDXjNvVxLfH9d2/CQldT/5/9/X3Y18PDFTk2hWOznPkkqdMS3nrMsegzx3r8+HGd6gejS4HoYHalHBGB6gSOj48Df/Csrq2CBnUVAREQAREQAREoRICBTqGGG27kAzE/LLebelKuH8OnHMvni6TrtqfOrD7cJ174kKImb0WmLX0VBaJ93XOyWwRqJnB2dhbc3t66q6E8aNasXup6QEAmioAIiIAIiEAdBBiEUQ+vCDKl8KdLjg6fNXo1lONQePWTqbeD+TolKwjlOBzXy6aCb47bN1Eg2rc9JntFoCEC/F4oD9y8FZdD5B1k2UYiAiJQmYAUiIAIiEApAj7QKdW54U5cQ9C+aLrJgIzrGY4dd5M2xcuS2sXbrLvtA3DacXR0tJHge10bu9BegWgX9oJsEIGWCfz8888BTeABmgdNBqNMWSYpT4A8s6S8ZvUUARGoRkC9RaDfBDi3dNkDriFoow/yeKfV4fODjQVkHI9j0wZyiua5TWEZhfk6xetkyqvAdeoemi4FokPbo/JHBNYk8OHDh4Bn7njA5AGbKYX5NVWpuQiIgAiIgAikE1BNbwhwHZAleY6wL9swpfD5E9zelDAQ5VjxtYzfpk2sr1Ook0KdTGnD7u4uNyUpBBSIpoBRsQiMgQB/quX6+to9EZf+8sDJgzQPngxOWSYRAREQAREQARHoDwHO41Fr28hzPcG1BG1huqnvhnpfD56GT87125tO6T+vCusnW7LJKxDN5qNaERg0gcvLS8OzlAw6ecDkhOEdjuZ9mVIREAEREAEREIHuEig8dwf3IYBPG3CJAahfXzSgvpDKwjwKaUtvxMAzVvtwkj9eru0FgftP4aJAOREQgXEQ+M0vPwdzE5jb2Z0JYMzdfGa4TbmbBWZuC2GmhmI4USWJGfaLE1iWVPXeYrd8TWkxHXvFWXXMvNrNifu77nbtBo1EoefctLtcWGZJ3vjezrQ0r39efd+PH2lcfHme/1Xrq47j+yel3rakuqJlXkdamrb/J4ChmCAwmWLsi/O6saEA05ggPv+bxYs+GPZbkkU9c7PbO3N3c2u2JlPz6sVLsGzTMrGz6/Z0y9gFjbUUZn43M7BYpphUNmViFc1nt4YytepmdzfGBLMH2dmemhdHz1vxu7JzG1Rg0dU8mtSJgAh0nsCn0xM7jwQGwIPQaGCxDYBFEhEQAREQAREYJAGg/nkOWOgE8DDHAsv59oEyBKDQEp8yny128ZDd4L52Op3aODhwd13dF208AdDYmADcvp1MJubu7s74hxJxm4Nub28zkeQQKP7Jy1Gk6nYJaHQRKErg4vNlwO+FAuFBFAhTHjyBMA+EaVGdaicCIiACIiACfSIAoHZzgYVOAC5QAZLT2gfvmEKuKSgvX7ZzNZQ4fDDMfNEAmm2LCABD/QBcwA3A+BfLnz3bzO+l+jH7mioQ7euek91dINBLGxiE8oDMCQLAw0RJZ4DFNgAWSURABESgkwR4HOukYTJqlASA5TkTwMP8Cizn+wIo/j8W307zg+343dC2rwoyIIzaCIT7IVqWlqcPaXW+nPrZjldD6S/Lub23t8espAABBaIFIKmJCAyFAG/Jvbm5ce7wYOky938A3Oe6nsg+ERABEQgJ8DhGCbf0VwTqIQCMYT6cW1hRsZuR98P/FWwbSqQuLcs+FNbPZjPT9k+XMECkLRRvF/NAsf3LPhT2SRLWAXBXRo19MRjlSX49KdfCKPhWIFoQlJqJQN8JXH75HFxdXbnvMvDgyUmCqfeLeYrfVioCSwS0IQIdJqBjV4d3To9MA+CuYq5rMoCVLvxMpslK4x4U0JcsM+P1vFrYdkC2v7+/umOynEipi/vGZizjOoqBpw9AWd528E0b+iQKRPu0t2SrCFQg8O3bNxM9WFIVD6RZwjZtSpZtrGvTtk2MTR+zZBM2aIx2CWh0ERCBZAJZx0bWJfeqvxRIjnVoQ5ZUtSRLN+uq6je8CkopqahrARmZAIt9xe0sKeK278+AlHn6rO+GFiG3aKNAdMFCOREYLIGPJ58C3pLLM3c8Swng4VYSHjy9GPvyeaZ2U28REAER6AWBGo9ZvfBXRtZLAFgEKUU1A9l9+JlMk6Jj9KEdfYzbeXh4mA0n3qHj20k+Ali6y6zNBzN1HF+qeQpEU9GoQgSGQeD88sI9JZdXQ3kgZUrhGTwA7jYkIEzpMRDmAXCzVQGwZB+wvN2qcRsYHFj2F1je3oAJGkIEVgjwOEJZqdhQARD+HyQNR7u8JNWvU+b1pKXr6FLbIgTWawOEnwMgOV1Pm3FPPo3u6yL9o+3jefYHkm0DwOraBUDmnAks6lMH51VQK1F/2BZY9AXCJ8WyDdcSTNmGJ7v5vcydnR1udkJoE4V2MgXg7MIkMFGZTI2JSrSOeV4hDszMeAFCBlRG/3k1lHnJegQUiK7HS61FoHcEbm9v3QQLwNkOwPBgTDGxFxC2iRVrUwREQAQeCAA6TjzAUEYE+k6gpP1AeBxgEBZdT9zd3ZkuPTWWtnkbmVJKurzUjWsrAA/rKV0NNaVeCkRLYVMnEegHAd6Sy4OlP/AC4cQBwB08jV4i0CIBfhqrSIumj35ogHuuGgZqqCLVRldvERCBJQL2Kiiv+i2VLW3M7VZU7KZ9RwM9f9Vx/8lT/mvb2vbfvELLu8C8nXVZxHWVl6dPn66tVh1CAgpEQw76KwKDJMDfDOXEAMDdruOd9AdPv80UABNJhwhwP3XIHJkiAiIgAiIgAksEptPpw4MQud549OjRUn3bG/63TBmIMiCtyx4GuPSX+tt+OnBdPrWhZ8OBaBsuakwRGCeBd+/eBf6gC8AFogxsvPAASjJAWMe8pHsE/P7qnmWyaOgEAAzdRfknAuMl4K+A+jSVhL8KutqAwR0At77geoPB2fODZ1ht2V4Jf8IFWHyfk5ZwXmVaVej/69evO+VvVZ823V+B6KaJtzGexhwdgdPT04Df06DjANwkEc/zQAyAxZIeEOD+6oGZMnFgBAA8HD8G5prcEQERqECAcxIAw5PavCrK9PHjxxU0NteV9jFQ5gjAclDKsjJCf22QW6ar+kQIKBCNwFBWBOok0Jaui4uL4Nu3b4nfAQXgynkWD4Cp+uJElCVV9bfdP8s31lW1jzqypKr+tvtn+ca6tu3T+O0S4GcgS9q1TqO3TSDrs8G6tu0b+/jAIqBjkMd1xeGz59UXFg2A5ZVa2giE5tXx+eGTgXVLbvWdpUC0OkNpEIFOEfj8+fPDGUpvGA+6FG7zzCAnDCA8ILNsQDJoV/w+HLSTcq6TBAAdLzq5Y2SUCLREgOsIXhUEwquiDPZaMiV3WNrKQJQNgXqOZa9evapHEY0asSgQHfHOl+vDI/D++ENwO7sz0+0tMwvm7uqn9xIIz17yKbp+8jCBPQQkyX0nHmWzZGJ1ZklWX9YxsKLcD7d2wr5ZsrbCWAcA7rZEIDk1QWCyBFZfpqToBeDGtdoNxW4YL9z2Ylp+wY4fijHR1DPJ+mywzuS8/L7NadZaddTnNvJNO+75+zQ+XprPfv+n1fvy1OPP/TEpmNtjVoYAMEC6xO2textWYZvijwNlU2t+pXfTvvMYkSWVjG+wc9r/S3zIyvwSPvvxMerZnth/afu/GCzL7GqVG+wAABAASURBVPbOBLO5gf0ATjExr192NzA7OjoCr2CSB9c/DEppuxczD5wvTL3Qp4mxe8nW0Ufm6TPTH7773lZQm6QqgUlVBeovAiLQDQLnlxfu4UR8ghsnwm5YJStEQAQaIyDFIiACItASAa4zeKWRaZevhkbx0FYKkB9HMmCl0EcKg9fpdGq6+j3YqJ99yisQ7dPekq0ikEGAt+TyAMsDJpB/kM1Q1ZsqAAZIl944IkNFQAR6Q0CGioAIhAS43mBub2+PSadld3fXMJjkOomG+pT5JPH1AK8EB26twZ+mefasW08FTrK9T2UKRPu0t2SrCKQQODkLn5LLAyfP4AFIaaliEegHAX6W+2GprBSBVQL6/K4yiZesySjeXdstEwDgAjteDe1DcMbbcxmIAjA+gDb3L/9Z9CmLARheAWUfCm/tpQ6jV60EFIjWilPKRKAdAl+/fnUHTB5EecBkGj/QtmOZRhWB9Qjws0tZr5dai0A3CPCzS+mGNd23gqwo3bd0rBam+801BvddH66Gei/8V5eA8GQ97fd18ZR1Xhhsv3z5MuwUb6jtSgQUiFbCp84i0D4BPqCIwSfP3PGgyZS/IQrA3UoCpKftWy8LRGBBgJ/fxZZyItAvAvr8lt9fYleeXVM9gfS1AwA3LNcbffoJk6dPn65cDXWOJPzxn0kGobwlN6FJc0Uj0qxAdEQ7W64OjwBvyeVTcDkZ8KDJM5T0kimDU+arCHVWkSpjD6FvHruu+1jV/qr9+84nz/+8+q77L/uyCTS9f5vWn+1dfm3X7cv3oFqLqv5X7V/N+vze/BoQv3eZ37I7LRg086pokfUR11W8Hff169fY398PI+/uuDIYS7oUiA4GqhwRgU0R+PLlizu7B4Tf1WAAysmLB1pOEpuyQ+OIQFUC/NxW1aH+ItAWAX1+q5MXw+oMN6mBwVwfvzPJ9RFt96zinzu/zSD0xYsXCkA9qIZSBaINge2PWlnaVwLHx8eBDzx54ATCYJT++FtzWR4X1hcVALm39wLpbfLGAcK+ee26Wg+E9gPl0jy/gFBvXrum6oFwfCA5TRsXCNun1SeVA2EfYDVNat+FMmDVVqC+si74mGSDP6Yk1bEMCBkwnyVA2A5ITn1fILvet2szBZJtBNLLq9oLpOsGUFV95f4A1p4/Kg/aAQVAMb/zTAWy9eT1z6vP+z/2J7PZjrp8yltVucbo68+YHB4e4tmzZ3RpRQA8nNxXEGo28lIguhHMGkQEYgQqbl5eXgacCCqqUXcREAEREAEREIGREgCQ6jkA44NP34jbDFB5EpwBqS/vW+pv0eXtt8DCT27zSmhfg+y+7Qfaq0CUFCQi0DMCV1dX7rHpPTO7dXNlgAiIgAiIgAgMgUBgnagiQHoQalW7q9lMKQxAfcqT4AzYnj9/nq2AHTosb968AR9e9OTJE8PAk8Lvg/J2YwaqHTZ9UKYpEB3U7pQzYyBwenoaXF9fL00SY/BbPvaWgAwXAREYIQEGL1kyQiS9chkIrxQCYUrj+d1KCr9nye2+Cx9CxICawSfTvvvTR/sViPZxr8nmURPg1VBO7qOGIOdFQARyCKhaBERABMoRAOBOdgNwCoBFMMrbcnn7qqvQHxGoSECBaEWA6i4CmyTABxT572coGN0keY0lAiIgAgUIqIkI9JgAABeA0gW/xgAWZSxnEHrwVD9nQhaS6gQUiFZnKA0isBECvCWXvxkKhJOCnyQ2MnhLg9DHLGnJLA17TyBr37DuvllvE/qQJVUdy9LNuqr6m+5PG7Ok6fGb1p/lW5G6PPvydOT1b7u+qv1V+0f972K+af82oR+AQ8uroBwPgNnb23Nl+iMCdRBQIFoHRekQgQ0QuLm5caMA4S0ynBhcgf6IgAiIgAiIgAiIQAUCQBh0RlUAcFdIAbhiAObZ/kG4YYwr0x8RqEJAgWgVeuorAhsi8P74Q3Bzd2sCe/ifm8AwnWxNC48OYGky8R1hM1liqzPfPEOaJZmd16gE8GA/sMivoSKxKWxpFcnynXVWfeY774mHmZ1rqKziu+sb2RcAEvcRkF6e539efVUEsAqyZGJtzxLbvdLb+2fBmSTx9WmpaekFwJqbL3nmBbBHswwxE+u5lbR2efqr1gP5PgLpbXgMyBRroPXQlBXbvdU3kO47kF9X1m/fr1Xn7eDIkaxjB+u8H2VTAJn/h9a8zHcwm5spJk4Q2KZzu7awZSyfGKvbljE1tnx+NzNss7u9Yxvq3S6BYY0+GZY78kYEhkfg7OI84FPq+Lh0eseFTTRlXiICIiACIiACIiAC6xLwa4p4PwCGa49oeZ9/OzTqh/LdIdCbQLQ7yGSJCGyWAH+qxT+giCP7ScOnLGtLAHvWNEPasmtT4wLj9n9TnDWOCPSRAJB9fACy6/vo8zo2A+P2fx1WTbQFsKQWWN5mJQNRrjWY8mT44eHhaiM2lIhASQIKREuCG0k3udkygZOz04BBqJ8IABh+NxTQXGD0EgEREAEREAERKE2AawsvVAKEawtfBoTbDESH8tuh9FPSHQIKRLuzL2SJCNwTCJPLy8vg6urKbQAwDEi5wUCUKScKphIREAEREAEREAERWIcAEAaZ0T7AooxrDK43mAIwu7u70abKi0AtBCa1aJESERCB2gkwCL27u3vQy8mAG0A4UQAwQLawvaQgATUTAREQAREQgZERiK8t6H60DIDZ2dkx+/v67VCjV+0EJrVrlEIREIHKBM7OzgL/m6GcEAC4W3KZpwAw7hXYf+Eq4pToT1kCge1YRWz3zDf3dZZkdu5JpcwUAREQARHYPAEgXEf4OYYWAGGZz/OWXAC6GkogkkYITBrRKqUiIAKVCPABRZwA+HAAppwomGdKAeCuhlYaRJ1FQATGSkB+i4AIiEAqAb/O4PoDgHn27BlSG6tCBCoQUCBaAZ66ikATBD59+hTc3Nw41ZwM+B0NIHyMOhDOBZwcKKzPEqfE/klrY6se3mltqpQ/KC+ZAdBowF3Ft7S+JV1N7AaE/gPJaWKnNQrTfPDleap8u7Q0r3/X69P8qqscCPdrWxzq8qOsnrb8LjpuWb/S+wVmnbqidjbVbh1bm2jblF95er0vRdv59vE0r3/b9d5erjEoXFNQALg7sFhm7Gtvb8/+1VsEmiGgQLQZrtIqAqUJ8KFEnAAAlNZRpiOw2fHK2Nj1PoAYdn0fyT4REIGREZC7axEAwnmMgSrvxNLV0LXwqfGaBBSIrglMzUWgSQIfPnwI+IAiHvyBcDLIGg+Au2IIlEuzdLMOKKcXCPtRR5cFCO0EyqVd9q2IbUC237k6bH/7ATRpkvf9WdPxF5DNB6hW37b7QDX7gWr92/Y/b3ygmn9Atf559jVdD1SzH6jWv2n/quoHsv2rqr+N/gAehmUgyocUPRSsmVFzEShCQIFoEUpqIwIbIHB6eupuyeXBfwPDJQ4BLCahxAYqTCUAiF0qHFWIgAiIgAh0mgCwPIcBMEdHR8uFnfZAxhljegdBgWjvdpkMHioB/lwLfeNtuW0Ho4DmHu6LIgLAXhBEkaZqIwIiIAIiIAK9ILC9vd0LO2VkvwkMIxDt9z6Q9SJg+IAi3pILwAU1bQaifncA8FmlKQQAMUpBo2IREAEREIGeEABW57IXL16sFvbEH5nZHwIKRPuzrzpnqQyqh8Dl5WVwe3vrnlIHwD1VsR7N0iICIiACIiACIiAC6QQAxZvpdFTTNAEFok0Tln4RyCHAn2rhI9P5gCI2ZZ4pkDg5sEoiAiIgAiIgAiIgApUIAFpnVAKozpUJKBCtjFAKRKA8gd/8/C64ur41gZmY2dy41GDq0nlgJ4jA/ovGBGZqvJiUF2/tpaRUPxTnPdW06foHQ1rKFPeP+2ZVWjK7tmHnQWCyJI9PbYa0pCjPv6brW3K7tmGr8qnNkJKKeIzMkjy1ffc/1z97fMji07b/AAyQLnn+pdUDoc60el/etv/ejqJpfF/651H4k9/86Tjm2e7t27coqlftRKAKAbvKrdJdfUVABDZJANDcsEneGqtlAhpeBERABESgEQIAHgJ5DuDvynr06BE3JSKwEQIKRDeCWYOIwCoBPqBotVQlIrA5AsBiIQKs5jdniUbqEoGx2AKsfuaBRdlYOKT5CSxYAKv5tH4q7w8BINyvvAoKwD2r4vnz5zB6icCGCCgQ3RBoDSMCcQLX19fxosxtQHNDJiBVioAIiEB/CchyEdgoAd6KywCUg/KWXG7v7u5yUyICGyOgQHRjqDWQCCwIHB8f8+sli4KMHAB3+0xGE1WJgAiIgAiIgAisTWC8HfiTcQxASYABKeXw8BDclojApggoEN0UaY0jAhECfFJuZDM1C2hOSIWjChEQAREQAREQgVIEGHgyEKXwwUU7Ozul9JTqpE4icE9Ageg9CCUisCkCHz58KHw1dFM2aRwREAEREAEREIHxEPAPJ2Igur29bV69eqUz3wPf/V10T4FoF/eKbBosgYuLi4AHfZ6JHKyTckwEREAEREAERKDTBKKB6NbWVqdtlXHDJTCCQHS4O0+e9Y/A58+f3fc9geUTjwAeyoFFvqyHQKijbP+i/YBwHKBcWnScrrYDyvkNhP266ldZu4DQL6CetKwdm+oHZPu5KTv6Og4wbH7AsP2r+rkDsvkA2fU8oZslVe3L0s26qvrz+gPZ/uf1Zz2/B3p7e2t4AhyAod18KJEXAIa35Oq7oaQlaYPApI1BNeYICMjFFQJnZ2cBzzpyQvBnIlcaqUAEREAEREAEREAEKhJg0AnA/SQLEAa1/C4o1x9MjX2xzd7ens3pLQLtEFAg2g53jTpCAt++fXMTAg/8QDgp1I1B+kRABERABERABKoTAMJ5GkhOq4/QrAauNRhw+sATgFuDADB8ATCs0++GGr1aJKBAtEX4Gno8BD59+mTnhMDwNhlODPTcp8xLek1AxouACIiACIhA5whwnUGxCxB3ey5TCm/NpbGPHj1iIhGB1ggoEG0NvQYeE4Hr62t3JpK35dJvTgRM+y70I0v67p/s7zIB2SYCIiACwyWQNbeyLs9zAO7ZE2zH9gw+eTKcwryuhpKMpG0CCkTb3gMaf/AETk9P7RwQ/mILED4sgE7bQiYSERABEegPAVkqAiLQCwJAuN7gCXCuN5hSaDyDUF0NJQlJ2wQUiLa9BzT+4AnwiXW8NYYTAFMgnBx4RnLwzstBERABERCBygSkQATKEOC6g0Eo+wJg4r4Xuru7aw4ODsICo5cItEdAgWh77DXyCAjwSbmcBIDweM88g9Ho5DACDHJRBERABERABPpGoPf2cs3B9QYdAeC+IsSn9/MnW4xeItABAgpEO7ATZMJwCXy7vjJzE5jAxqGYTlw6C+ZmsjU10+0t9/0NwFbGEHDyoMSKO7cJ4MEHYDVPH7Kkcw6taVCWb0Xq1hyuc82B5X0eN7AIg6w2cX1d286ynXVds7dr9pBRllS11+uuqqdsfz9+WlpW71g5s46GAAAQAElEQVT6pXHz5X3nAKCSC4GZGYP5kmASGC9bUxjYFcgEgaEwb5chZntrYo4On8F09iXDxkRgMiZn5asIbJLA+fl5UHY8QHNEWXbqJwIiIAIiIAJ9IACUn+uB7L78+s9kMnFXQXlVFIBhEP/ixYvsjn0AJxvrJ9CSRgWiLYHXsMMnwCflVvES0FxRhZ/6ioAIiIAIiEDXCQDNzPUMPhmI0n8gDEIfP37MTYkIdIbA2APRzuwIGTIsAh8/fgz4iPRheSVvREAEREAEREAE6iYAVA9GgWUdDEJ5BRQIy/nd0MPDw3CjbgekTwRKElAgWhKculUhMPy+Nzc3hmcjOQlkCaA5YfifBnk4VAIADJAuQ/VbfomACHSfwHQ6dbfiekvfvn0Ln1cqAl0hoEC0K3tCdgyGgP/dUKDYMR+AW8w2DkADiIAIiIAIiIAIdJIAgNJ2Aat9eRKcwShPiuuW3NJo1bFhAgpEGwYs9eMjwKuhvCUGWJ0YxkdDHouACIiACDRBgIFGljQxZp90ZrFhXRd9AepbNzAABWC2t7eNbsnt4t6WTSSgQJQUJCJQEwFeDeXBn2chgfUmFGC99jWZLDUiMEQC8kkEREAEekkAqL4WAEIdt7e35tWrV+FGL2nI6KETUCA69D0s/zZKgAd9PjKdwSivisYHB+BuwwXClO0oPDtLibdvaptjUarqp44sqapf/ZslAISfQyA5zRs9a9+zLq9/3+vpY5b03b/17e9WDyD8XHfLqvqsAUL/gOS0vpGa0ZT1v8O6ukYFNsuHtkeljB8ACnfjQ4h48tuvPZinUMH+/j4TiQh0loAC0c7uGhnWNwKXl5cBJwJOQD64jPvAunhZG9tA8UmuDfs0pgiIgAiIQEECatYpAsBifgUW+biRXCdEheuDqMTbx7fZFgh/loV6GHxSWM6n9vOWXBuIphsQV6htEWiBgALRFqBryGES4O+GcjKgd5wImHZZAM1PXd4/sk0EREAERKC7BLIsA+Dufspqw3VCVLh+iG5n9WUd2zL1/XgXFoXllN3dXVZLRKDTBBSIdnr3yLg+EeBtuTz4cyIAkGo621BSG6hCBERABERABERg0AQAuGAVWKTrOMy1BttzPUFh3gelOzs7ZqBXQ41ewyKgQHRY+1PetETg7OzMzgOBm1Q4OQDhxJJlju2QVV1LHYBa9EjJOAkAcJ9pIDkdJ5WF10AyFyAsX7RUro8EgHA/AuXSPvosm4sTAFC8cawlgJVjK9cOUYl1WdlkWxZyLUFhEMqvB/H23JdHL8A6iQjUQ6A5LQpEm2MrzSMiwO9jcCIAwmM/EKZdQADATXhdsEU2iIAIiIAIiMBQCADrza/Aoj0Q5oEwrcIECL8ryuBUt+RWIam+myagQDSDuKpEoAgBXg29ubl5aMqA1J+ZZP6hokSG/bOkhMpOdcnyjXWdMrYBY+hjljQwpFSKgAiIgAh0gEDWsZ91eSayDQWAawrAMAh9tn8QFrhS/RGBbhOYdNs8WTdCAr1zmVdDeTsMDeekwCDUp76MqZPg/l+OKcUVbuYPoLlpM6Q1igiIgAiIwJgIAPnzK7DchmuFqHDdEJU8fuzLNkCoF4A5en4YbrBCIgI9IHC/Ku6BpTJRBDpK4Orm2swDmOnWjjGYunxg7L+WzRsGm1aCOYwT286Vsd4Yd8sskD9vAHhoCyzyJucVndSYjzcHvK7kNN5+ZRtzYyrIxI6fJSYIDAXGmCQxPX9l+c66JJ+jZVXd52eiilQdP+pLNM99TomWJeWrjl+1fx67PP1JPq1Tlqe/6/Xr+JrU1vNvyk+vv2yaZ1eST+uU5emvWg/AAOlSVX/V/rAKMuXedtus9BtAKoN1lcY/R9PJxEwnC+ExnwKr2Au3p5OwDfM8Ls5nMzO7uzNTTEwwm5u7m1uXf7z3yPbUWwT6RcCulvtlsKwVgS4ROL+8sHOLDZasUTw7SbFZN3ExXQj/1Sb35ZP7Yp/ebyoZHwF5LAIiIAIi0FkCdoJv1TaO78UbAjBMDbe45gBgtra2zMGBbskNqehvnwhoJdynvSVbO0eA3w3lJEHDOCEwz4cFAIuJgnWDFXu1113hLZsOFowc6zIB2SYCIiACRQlwXi/ats52ftx4yjEA2IujgTu5zSD0xQs9JZdcJP0joEC0f/tMFneIgP/tUJrkA1EAbnJgWVQARDeVFwEREIExEZCvItBbAj4Y3LQDHDcqHB+AW2Pw2RQMQh890i255CLpJwEFov3cb7K6AwQuLy8DTgQAHqwBFnlfCMBNGn5bqQiIgAiIgAhshoBGGQIBnuiO+sE7r7jtnpL77BmYl4hAHwkoEO3jXpPNnSDAp+XSEACGkwIQpsa+eAYTgAJQy0JvERABERABEeg7Ac7rhX2oqSHHjArVAuHaYmdnxxweHoJlEhHoKwEFon3dc7K7dQK8GsoANC40jBMHMPz5gR5WEbKSiIAIiEASAR5HsySpj8rGQyDrs8G6Jkg0pTfJVj9WPGVbAOb169ecfrkpuSegpH8EFIj2b5/J4o4Q4K0yANxVTwAPV0WNfXHiAGBzeouACIiACIiACAyFAOf3TfnCsbz4MQGtLTwLpZ0gUMkIBaKV8KnzWAn474dG/edkweCUZQAMr5gyX0UAuEC3io6svrQ5S7L6bqIOaNb/TfjQxhh+n7Yxdh1jAtrv5Nj3/UgfqggQfg6A7LTKGOqbTsB//tLS9J5hTVo/Xx62Cv/6srw0bB3+Bdr7XCTZGVq1/t8kXSwD8KCMawt+HYjlfEDRmzevFpUPrZQRgf4RUCBadp+p36gJcDIgAEBzATlIREAEREAEREAE6iPA4BPAw8loAIZlL18eob5RpEkE2iWgQLRd/hp9TQJdbA4s5gQgOd9Fu2uxKbCHkCpSixHtKeHeriLtWV7PyFV8Z996rJCWtghwH1aRtuzWuCLQJwI88Q3A/W7oTz/9wH+5PpkvW0Ugk4BdRWbWq1IERKAAASB5buAEkicF1LfdROOLwAoBfq5XClUgAiIgAiJQCwE+CJFXQKmMx9vnz58zKxGBQRFQIDqo3SlnNkmAE0PSeEByUJrUlmXUQ2FeIgILAt3M8bNK6aZ1skoEREAEhkGAQSiDUR5v9/f3zfPnB+stLoaBQV4MnIAC0YHvYLnXDAFODNQMLOYFIDnPdkXE6yzSVm1EoA0Co/iMtgFWY4qACIhACoHHjx+bo6PniwVGSjsVi0AfCSgQ7eNek82dIgAs5gcgOd8pg9cwhoFHk7KGKZ1smscmz+iq/fP0t10/dP/y+I7d/zw+0foh5qvu/6r9h8i0Tz5V3X8A3M/C6eFERq8BE1AgOuCdK9f6R4ATV/+slsVjIKDP5hj2snwcGQG522EC/Am47757szi73WFbZZoIlCWgQLQsOfUbNYFnz57h9vbWTLFlgpkx85n9EwTGzRg2DeZzY2zK7VDmti6UCQLjBYABlmWTYGEHSxLaTkmqWyqbWJ8rSGDHryK2e6PvJV/tSCvbsX0HYGl/MnjLEtvYZEkeG5PyAkI7UqofimFzRWVidcbFds98A7DupUtm5x5UwtqYJXFe8W3bPfMNwPHLbNThSv/ZTzMxt952zPofsNWtvmFHz5L4/o5ve//TUgBu/wPJaVo/X27Na/QNq70uibNJ246Ol/XZYJ01r9F31JakfJoPE8CuAWCm06n7ORbuLyB8Ki4QlrPst37rR6o1VV5/+7d/G/yn//Sfgp9//nkTSKqYqr4jJaBAdKQ7Xm5XJ7C9vW0YjFLT1taWu4WGeT5cgAKsziHAahn7SERABERABERABMZDgFc8gcWagIHp3d2dC04PDg5qAfG7v/u7+I//8T/i+++/XwxUi+YeKpHJnSSgQLSTu0VG9YHA3t6emzAAuLPWfMIdhbZzQmEwynyfBQh9A5LTPvu2CduBZG5AWL4JGzSGCIhANwkA4XEASE7zrAaS+wFheV5/1bdLwK8XADhDeBUUgNnd3TUHB0/DQqOXCPSbQJ71k7wGqhcBEUgmcHR0BPtywSjPbHIS8S2Zp/htpmzLVCICIiACIiACIjBuAlwTcJ3gUwamfELuixeHCkLH/dEYlfcKRBvZ3VI6FgI7OzvOVQaizPBKKFNu8xYb5jnJUJiXiIAIiIAIiIAIiMB0CgMEJuCDJszcXgnd1s+06GMxOgIKREe3ywfscAuuvXr1ArxFl4Emz2ZSeIaTpvDWXJYzLxEBERABERCBMRHg/JclY2KR5CvZ8OQ11wx85sTLly+R1E5lIjBkAgpEh7x35dtGCPCHphmM8oFFnFgoYwpCNwK5pUG4QMiSlszSsBsikLXvWbchMzSMCIjAAAnwxDXd4p1Vr169UhBKGJLREVAgOrpdLoebIMDvdPC7HXzIAANSLlJvbm6aGEo6RYAEJCIgAiIgAj0mwECUwhPZPXZDpotAJQIKRCvhU2cRWBDgU+4OD5/h5csjPH362Ni82dqaONnd3TaTCX9adGbm8zszm926cgascTEdePGqLiVuW5HtDphf2QTvJxlkiW+XluYZktbPl+f1b7ve25mWtm1f1fFX9z1MtCzN76LlVe1ru3+en96+tHaepW83tDTN76LlQ+MR9yePQ7x937b9z7vRbvrKO6V4K250+8mTJ2Z/fx8sk4jAGAnYpfEY3ZbPItAsAU4sBwcH4O02FD5h982bN3j06JHZ3t52gyddMeXCzFX29E/f7e8pdpktAsMmIO9EoIcEONfzwYU0nXdK8eontxmQsox3UXGdwLxEBMZKQIHoWPe8/G6FwOHhIV6/fu0ecMQzpK0YscagDCyzZA1Vg2yaxYZ1eU6zTZbk9W+7Pst21rVtX9Pj08cq0rR9Teuv4jv7Nm1f2/rpYxVp2/6mx89j0/T4m9DPK6D008/3DEaZ5+24CkI3sQc0RtcJKBDt+h6SfYMkwKfj8Wxp1DlOVtHtvuX7bn/feMteERABERCB7hJgwMlAlBbySii3OU9y7udDDlmeICoSgVERUCA6qt0tZ7tEgA82oj2cmCjM91FoO6WPtstmERABERABEWiCAINQ/p44A1DqZ8qv5/DhhtyWdImAbGmLgALRtshr3NETYPBG6TOIvtvfZ/ayXQREQAREoNsEOEfyaiitZBB6ePhMDyYiDIkIkIAVBaIWgt4i0AaBpIcVxe3gGdQsibfXtgiIgAiIgAiIQPsEGIDywUS8Mso7oHQ7bvv7RBZ0j4AC0c3vE40oAo7A9fW1S/VHBERABERABERgWAR4Epm35jII1e24w9q38qY+AgpE62MpTZ0m0C3jPnw8Dswk/w4d3taTJVW94kRZReZBYLIksAZmia1u9Z3muzcqyzfWpfX35V5PV9OsfcM6+tikcIwqUpUr/wOzxNjPd5bUxaYsg6r+V+3vP+dl0yR+URZV7cvrn7XvWZe171kXtTUpn+RftCypT7Qs2jYpn+df1fqy+7VoP+9T1Od18nn+1Tl3UiaFMAAAEABJREFUJvnE8TmGr/N5XgllHZ+Qy98J1ZVQ0pCIQDIBBaLJXFQqAo0RuPh8GfAsKSetxgbpimLZIQIiIAIFCeiYWBCUmlUiwMCxkoL7zgw0GXTyc8u8v8uJT8W9vb01+/v75vnzA3dO476LEhEQgRgBBaIxINoUgaYJfP361XDS4uTV9Fh5+mlDk5I3ftv1TfpO3W35V9e49KFJqcvOpvQ06Tt1N2X3pvTShyqyKTvLjpPnW57etvvn2ZdXn2d/Xn2e/jbq6wpCve1kQJ1M+V1QBqac33klVEGop6RUBNIJKBBNZ6MaEaidwMeTT7oaWjtVKRSBThCQERUIcCFfobu6ikAuAQaMuY3WaMAHEfnPLfNbW1uGwejOzo7Rd0LXAKmmoyagQHTUu1/Ob5oAn5TLCYuTF2XT42s8ERABEegSAR4HKeVtUk8RaI8Ag1t+fpn6K6EKQtvbHxq5fwQUiPZvn8ninhLgA4p4tpSBKCctTl49dUVmi4AIiEBlAjoGVkbYnoICI3P/ZkkBFbU14Zxbm7J7RV4nA1Dm9/b2zLNn+/pO6D0fJSJQhIAC0SKU1EYEKhLgA4r8gww4YVE4eVVUq+4tE1jnCY9JbVs2X8OLgAiIQGkCSce0dcpKD7xmR863a3Yp3JwnlnmC+dGjR2YTT8c1eonAwAgoEB3YDpU73STw5csXwzPDfJIeLWSeDzVgXiICIiACIiACIlA/gSaDUM7jtPjx48cKQgliuCLPGiSgQLRBuFItAiTABxQxAOWEyLOn/kooH/HOiSxL2F8yXAJZ+551w/VcnpEA9zGF+SaEuqPSxBjSmU6Ax3xKeotu19D2IlLWC//ZjPf3Y/r6sin1UDfTJGFdlvBn1ljPeZspdfiUJ5Ln8zuzu7ttDg6e6nZcgpGIQAkCk9Q+qhABEaiFACcvTmS8fYcphROrD0hrGURKREAERCCDAI9DGdWqaogAj/UNqR6s2rqZUV+S5AFkH/7fUDhvU3wf5vk7oYeHhwpCPRSlIlCCgALREtCa7CLdwyJw/OljwIDTB6Gc2DiBMeXkNixv5Y0IiMCYCATW2Spiuw/6zeN8nx2k/VnSpG8ct6p+zrUU6kqSPP38ORbO05zD2Z/teSWUOnk77sHBgYJQQpGIQAUCCkQrwFPXwRBoxJHLy8sgeksuJzQKB+OkRmFeIgIiIAJNEeAxh9KUfukVga4T4FybJEXsZtDJvgxAKQxOGYQeHT5TEFoEoNqIQA4BBaI5gFQtAmUJfPv2zfgFIFOeVeVExjwnNkpZ3cPoJy9EQASaJMBjTZP6pbs8gSLHf7bJkvKjd6MnfWvSEuqnlB2D3xFlIErh/xKDUN6O+1w/0VIWqfqJwAoBBaIrSFQgAtUJnJ+fB5zE/CTISSwq1UeQBhEoSUDdREAEWiPAOYHSmgEdG5gsKE2Y5efcqG5fxjRanpbnyWPW8edZvnv7GvtPH+tKKIFIRKAmAgpEawIpNSLgCfCWXP+boZxgOeFRmKewHa+OUpiXiIAINEOA/3dZ0syoyVq7VkouXbNJ9ohAnQT4Gc+SvLF4JZRz9vb2tnlx9FwBaB4w1YtACQIKREtAUxcRyCJwc3Nj+N1QTmAU35Z5TmzcZhBKYV4iAiIgApskwMX5JsdrcaxODc05oFMGdciYJtjwcx6XdVzm1dDd3V0FoetAU1sRWJOAAtE1gam5CGQRODk9D75+uzYGUxOYiZndBWY+MyaYwwnzFBNMzARbpu1XlSdesi8AA6RL2/41PT6Q7juA3OHji6T4dq6ClhsA6MX+B5Lt5Ge4ilTFDyTbBSSXVx3P9wdC/X67rRQI7QCS0zy7gOV+ee3j9VX2PfvG9dW5DWBtdQCW/h/XVnDfwR+H7jdLJGEX6glzyX8DM7Pz5ELirdh/Wew8GizEBHYvRARWQZZMLJ9lCczUroIpMHNDYZ7C/G/99AN0JdRC1VsEGiRg/wUb1C7VIjAyAnd3d2YyCf+tABggW0aGR+6KgAiIQCMEGLA0orgFpQBKjdoGAyDdViC9rpSDOZ3y/E+q551JLOdPrAFwdzNxmCdPnjDpl8haEeghgXDF3EPDZbIIdI3Ah+NPSw8oon0AMoNRtpGIgAiIgAiIAAkAYNILAfpjaxJQf+KYQShvw+U2n4zLn2fRb4QmEVNZEgGVVSOgQLQaP/UWAUfg7Pwy4HdDeWbVFdz/AaBA9J6FEhEQARGomwCPuZS69bahD0DlYcmCUllRQwoAPMyJTQxB3ylpullH8fXMMwCl8KFEb9++xf7+Pny9UhEQgWYJlAxEmzVK2kWgTwQuP38Nvn79ajihAYv5i9t98kO2ikDdBAA8LDqB1Xzd43VNH7DqM7Ao65q9ddsDLHwFVvNVx2v7GAus+gQsyqr6V6V/F9hE7QdCLtGylTzmxlBM2svWm6iktTNuPk6vDet59ZMPFmQQyqugb968QVYf1YmACNRPQIFo/Uyb0yjNnSTAIJSTGb8bCizmMS4E8qSTDskoERABERCBjRIAFnPHRgeueTAA7uQT1QJhHgA3Oye8HZfB6MHBgXnx4kU3jewcNRkkAvUSUCBaL09pGyCBLJf890L5HRO2Y+DJFIA7I8vtLGFbiQg0RSDrs8e6psaVXhFom0CfPt9AuRioTz6u9XngVVFKTqc8//PqeSvud999h2fPnpXbATn2qVoERCCfgALRfEZqIQKpBL58+eLqeFaVGT6BD4A7I8xJME/YR5JIQIUiIAIiUIoAj7ulOrbQCUClUbvkK1DcF6B42yxAef5n1b9+/boeI7IMVJ0IiEAmAQWimXhUKQLpBH7++edgZ2fHNeAtPswAMAxGKf5WXQAuMAVWU/aJCifNqETrkvK+bVLdJsr8+GnpJmxoc4w0v315m7aVG3u9Xt7Psul6o63fGgj/59bvWU+PslzS+tVj1ea0pPlRtLyspcBm9nuWH0m2x9uzTbwsus36LAGy/fS6snQk1QHZepP6rFvmbctKMQnC3xkNgoc51LfneJxjmXK+ZTkQ2s0852TWM896IJybWf7o0SPz3Xf6PijZSUSgbQIKRNveAxq/lwTevXsX5BkOIK+J6kVABETAGDEYFAFgfMd+YH2fATwEmMBqPu9Dwa/EMNgE4Joy6GQGgGE5A1Cmxr74QCK239/fN8+fH4QdbLneIiAC7RJQINouf43eQwIfPnwI+HAiP+nFXQDgJtd4ubZFYNMEgPCzCCSnm7ZH44lAlwg0YQuAJtQOWGeBp+Dy+6KUGIUgmNmSaP8wP7ErW8p0CjOb3TrZ3p6at29f49kz/TSLhaa3CHSGgP137YwtMkQEOk/g9PQ04JlVnmWlRA0GoAA0CkR5ERABERgRAQAj8jZ0FcC68959RwaNYbbsX87FvOqZ1B+AKwZg9vb2jH6axeHQHxHoHAEFop3bJTKoywSurq6ceXw4EQA3AQNh6ir0Z1AEgHDfAslpnrNAcj8gLM/rr3oREIH2CADh/ymQnLZnWTdGBpBpCO8aypLVzgxOKas1roRXRSPCIJT6Abi5mG24zXIvT58+NXooEclIRKCbBBSIdnO/yKoOEnj//r37XignOi9ZZgLIqladCIiACIjAQAgA/Tve+3ksLW161wBwASSQnOaNz7uSKEDY37cH4L4j+uTJE6OfZjF6tUlAY+cSUCCai0gNRMCYk5MTO1cH7om4fOABbwlK4wIsT4pp7VQuAlUJ2A9l5u/VVtWv/iIgAvkEAOQ3GlkLoHkmPgglWh4LmXJ+3t3dNY8fPzYHB3ooEZlIRKDLBCYNGCeVIjAoAgxCr6+v3YKfkxxv+eGtuX7iizoLND/5RsdTXgREQAREoD0CgI75cfpAASZB9eUn52AK52SmAMz29rY5PDzE/r4eShTfL9oWgS4SqH4k6KJXo7RJTjdB4Jf374Jv11dmHtiJFVMTmInL380Cg8nWym1F69rAyTMq6/YH4GxYt19X2sMaUkVs906/o/s2KV/VeABu/wPJ6br6gWU96/ZXexEYEoGk/1lf5v302/HU16elbJ9Wl1bOPlFJa+fLgfD/2W/HUyCsB5LTePv4dtSWaJ6BISXeHlgeJ+wDe5I3LoEts3PsfXvqYVsAhieDJ3wkrglffpydnR3z9u1bMAgNa/RXBESgDwQUiPZhL8nGVgicX14ESQMD4WTq6vRHBERABERgVAQAZPoLZNezM5Dfhu28MBDz+bGk/AqMDzR98MltCnnMZjMXmD569Mi8fPlyPaBjgSg/RaDjBBSIdnwHybz2CHz58sUNDsBddXIb+tMJAjJCBERABNogACBzWCC7PrOzKpcIMNBkAEphUMptXhEFYG5ubgyvgjII1VXQJWzaEIFeEVAg2qvdJWM3ReDDx2N7wjW8IApgKRAFlrc3ZZPGEYGWCWh4ERg1AQCZ/gPL9QDc3AEgs19WpZ2I3G2qWW2GWsfve/LqJ4XBKP3k8xq4zYcR8WdZ9FRcUpGIQH8JKBDt776T5Q0ROP70MeBk5yc+AAYTG5Ty98vsmIDdtsIFgt3s9RsIfQGS0147J+MrEwCSPxdAWF55gJ4rAEIOQLm0mPvttQLK+QUU69eeZ5sfGQiZrDPyEOaYLH+BkAmQnLIvENYxzwAUgNnb2zNvXr0GyyQiIAL9JqBAtN/7T9bXTODT6Ulwe3vrvneSphqAO8udVq9yERABERCBnhOImQ8gVrK8CWTX+9YA3PwBwBcpTSHAwJMnhAEY5nkr7k8//IiXRy8EL4WZikWgbwQUiPZtj8nexgicnJ26K6EAlgJRAG7hYPiyV0Ufro7aPIskzRHgFYEsaW7kbmjO8p113bCyvBWwXbPEBIHJFNtf7+ES4Gc8SzblOcBPafpoQHZ9es/yNVlcfF157ZvpCfvvHZfo9vZ0ywSzuWHZ08dPdBXU6CUCwyOgQHR4+1QelSBw8fky+Pr1qws4+TAEnn3lmdg0VcDmFx5ptqhcBERABESgGQJA9rEeSK8H0uuqWMtAs0r/vvTlA4r4m91Pnjwxz58/bwZmX2A0a6e0i0BrBBSItoZeA3eFwNnFeXB5eWkvvNjTs9YoBqFAeCuQ3XS3BLGMeQrzFACuDxcFacL2ZcTrK9N3nT5+nLQ0T1daP1+e179oPQB3kgBYTov2L9vO+5GWltVbtB+w7C+wvF1UT9F2aX6mlRfVW7YdsOwvsLxdVm9d/dK4FC2vy46m9BT1o2y7NLu9PmB5fwPL22n96yoHsKTK2+VTVvp8Usp5Iqncl7F/lvh28TSrT7SO/aLbzAN4OJZyOyrAog5AtGqtPMelAOEcyafdUsjDK2I9y5gC4Visp7CM7X744QfwgUT7+/thAxZKRGAwBOQICSgQJQXJaAmcX16474Ty6ievhBKEnwRZxm2JCIiACIiACIjAegQAuKCXcykFgFPAOZayu7vrTuYyIGU9K/mzLADM27dvw8YslIiACAyWwMYD0cGSlGO9JPDl8zdzezf+xTUAABAASURBVDMzMFMznWwbIDyDy0nST4xm6TW3W15sduRvAI4ZkJyOHI/cFwEREIHREuA86p0HVucIf+st51oGoGxvr34qCPXQlIrACAhMRuCjXDRGDBIIvHv3LuBEyLOxnADZhKm/NYh5lqULA9L0WtWIgAiIgAg0QyD/+NzMuJvSOgT/OLdG51P6RIkyZABK4W+G8lbcFy/0RNwoH+VFYOgEFIgOfQ/Lv0QC79+/d0Eob8cFYDhhUuYz2zyYuNuFOIHarfs3g07K/eZ9Aqye5QV8Ge5bKREBERABEaiDAAMZSh26uqiDvlG6aFsVm+gT51TOsxRuM+XVUD6M6M2bN5owqwBWXxHoKQEFoj3dcTK7PIFffvnF/UwLJ0AfiFIbJ0mmXjhR+rzSHhGQqSIgAoMkMPRj8tD84/xK4VzLDyTnWArzANzXOr7//nvoKiiJSERgnAQUiI5zv4/Wa14Jvb29NZwcgfD7oIQBwHCyBGD8C1jkfZlSEaiTABeeWVLnWE3rKqM/y3fWldGpPiIgAt0kAMDw51h2dnbM3t6eYRDaTUtllQiIwKYITDY1kMYRgbYJ8DuhDEI5ETLopD28NYgLXgBLgSgAd7bWZL7075OJR5UiIAJNExiNfh6nh+zsEP3j1U+K940ngPldUAahR4fPMOT9Kd9EQASKEdBKuhgnteoxgcvLL8Evv/A7oXMbbG5ZTyZmPjdOtvik3GBi7uxVUgpnxp3tbTPFlpnfBWZibMk8MMHM2PzUbE2mtnxmZrd3Znu6ZfZ2d813b1/j0e7jhzYTwzZhH1jdSWLmsAZYCQJjrNgcR3qQCWAopuOvuN3xbfqWKTn+WTomS3K6N1bNhRUl7u+629zHWZKnrzEHN6QYgAHSZUNmlB4GKf/fhcvtyKgg/AxSrIpW3lVsz+rr/yeibXxZNG3aaQZRFDKmLMarJ5fnX9RX5qPt0/JsF5V4u6XjccwN+hiVWPXDpm8znbgZ0s1h1MuxOPZ0MnHzV2An2vlsZpju2qug33/3Bq9eHuFg/wmbPuhTRgREYLwEJuN1XZ6PhQCfyOevfPoJlL4DcA8pYj56hZRXTfk0XS5AmGcftuE2y6fTqXn8+LF5+fIlDu/P6lK/sS+2pdisW2AzlYiACIiACIjAUAgAYRzp5z0Abr7j3Md5kikQzq+cL/kwolevXqCy/1IgAiIwOAIKRAe3S+VQlMDx8Sf3YCI/OXKCpPg2gbFna60AeJhIWe+F7Rh8sj8Aw9uKGIQeHb0E67wwYPV59mXep8xLREAEREAERGAoBIBwCuTc6Oc6ntClcJtBKgPQ/f1940/YDsX3sfkhf0WgSQIKRJukK92tEvj48cQFoZwQAbhA0xvEiZIChA8s8pMpJ1GewQXCcrYHwgCUk+rLl69xcPAcLPfy4f1JwGAVWBRTD/X7NkpFQAREQAREoAoBYDHHVNFTV1/OcZzrKNTJuZZzqT9h+/LlEfZ1Gy7RSERgXQKjaa9AdDS7elyOfvp0Gnz79s1wogRgOFFSTOTFCZP1voh5lnEyZZ7lDEp5BZS/cWbP7K6sAnjFlVdDqZvCfgAenspr9BIBERABERCBEgSAlSmnhJbyXYDs8Tk/UjvnTArnQD6IiLfh6iooyUhEQATyCHQrEM2zVvUiUIDA8fFx8PXrVxeEsjmAh6uhwCLPoJEChGXM88omhXk+XZdBaNpvnJ2dnQXzmXFBJ9tyrPl8zsQFvn6SdgX6IwIiIAIiIAJrEgCw1ANY3l6qbGADwMP8GVcPwPg5b5cP7vvuDY6Olu8YivfRtgiIgAhECSgQjdIYaX5Ibp+enrrbcTk58uwsA0oKtynMA+HEyjzF+w/ABZX8jbPHj/fMkyePzLNnyY+Yv7i4eLjiauyLerx+5ikAbE2/3/QjS/rtnayvSoCf8CyxZ4NMplQ1oOX+Wf8brGvZvMaHp49Z0rgBLQ+Q9dlnXeZnP+DzwJt1IGvfsK7q6NTBAPSHH74Dr4JW1af+IiAC4yOgQHR8+3ywHp+fnwdXV1fOP16N5CTJ4DAqLAPcEsG1A2DXCoETBq6cVPldUF4FPTg4WDR0rcM/l5eXwZcvX2wfuKfu8pYk3p7LlC04BvNMuZ0iKhYBERABERCBtQkAiVPT2nrW6QCsjvno0SPD74Guo0dtRUAERCBKQIFolIbyvSXgg0N/W60PPhlc+jwQTqQMGhkk8oEKAM9Kzw3Tvb0d8/r1Szx7th82TKHx5cs3G4AGhrfjArB94W7F5VgUY18ck8GozSa+gbCfr6Q9XnxZF1IgtBNITr3NaWmeD2n9fDkQjpunp3h9PS2B0C5vZ1paz2jd1ZLmty/vruX1WAaEnwMgOa1nlHQtQDhueotma4BwfGA59aP6z0FTqR+nqRQI/SqrHwj7A8lpEpfoWL7elwELPZxrgMU2ANfM92EKwM1PwCJ1je7/sM191rVjnmWcv5gHwMSedA3cLbis40lenqzlb4LmzZWus/6IgAiIQAYBBaIZcFTVDwI+CPWTJCfKqDBg5KTNydUHh2zLPH9jlPVPnz41vAqa5/G7dx8C6uHtu9SR1171IiACxhhBEAERyCUAhIFfbsOaGnAO43wGwAWiANwJVs6f/oStb8OUdwy94cnag6eoyQSpEQERGDkBBaIj/wAMwX0+mIgBJYCHK5OcSIHwtlvmKQDcZOvzvHrKW4v4QKLnz/MfsOB/DsbYFydlINQHpKe2aaffsNZVkgzfATjeQPnUmtfoG1Z7Jcnxzaof9BtApX08aDgdcK5tE4Bqnw8gu3/b/vVpfM5ZlKjNEwSGMru7MfPZrZnaFaHPP360a0wwMzBzs7e7bX784Tu8fHGIaH/lRUAERKAqAXvYqapC/UWgPQLv3r0LZrOZO4sLhHMkEKacdCeTieGZXbbZ3t527RiAstwGn+a7775D2gOJol4xCOX3QqmD5dRHYV4iAiIgAiIgAvcESiVAOG+V6nzfCVjWwTnQy32TxIR3BQEwPKHLE7Wc5/jzZ0w5R758+XJZcaIWFYqACIjA+gQUiK7PTD06QuDk5MQ9IZdBJSdSmsVJl7caRYNETqys8wEpf+fs++/foujvnF1cfHZPyKUeIJyPARgGtNQrEQEREAEREIEyBAAYAGW6lu7nBwPgdHC+5LzJOc7PkzxR268A1HulVAREoE8EFIj2aW/J1gcC/gm5DEABGD+RsgGDUQoDVADudl0Ahi/eivvmzatwgwUF5PPnz04HJ2nqBcLxgLXUFBhJTURABERABMZCAKg+hwDLOoDl7ThLzmFeGHxy7uQ2U8r+/r67UyjtqfFxfdoeOQG5LwIVCSgQrQhQ3TdPgL/hyZ9p4eTJ4JCTKQWAO7tLiwAwcQEkJ1cGrEdHR2bd3zp7//44oCIGtRwPQDhGMDHTyTarJCIgAiIgAiLQaQKcvyhRI7nNuZMpn4T7448/FvqqSlSH8iIgApsnMKQRFYgOaW+OxBd+d4W3DzE45CTKQJMBKYNNIgBgfB3b8lbc7757g/39JzBrvH755ZeAAS91c6L2QhV8eiDHZl4iAiIgAiIgAl0hABSf6viwvp9++glFnhrfFf9khwiIwHAI9CgQHQ50eVKewM8//+x+PoUPUWCACMA9gIgaGZACMKyb2E92EMzM7/zOb+Hly6PiszIVWfn553fB7e3McAwGvcHcqrBXQY2V+cy4ByABtgxzYxIkMDNDSapbLqOOZeElWC+mppcdwSTJOup9IL6UWgXe1qR0HgQmS5L6RMus+kbf0bES89b+JX9r3vZsEse2nueV2yaNvL3PxvqbKRVHz/Mvr77i8Lndk/5nomX8H68ibe//qC9J+cx9bz8b/nMSTz3YeHl82/uflra9/70f8TTuR1Pbxtj5JUWAwJ5wNYYphW19Op/fGQq3o+LbTKew8+bE8Aqovgdq9BIBEWiRgF2utzi6hu4+gQ5ZyFtyaQ4nfQadfMIft3llkmW8IuoDR14R5Vle1q8rnz6dWnWBC0LZF+ASjblxCyAO4/4EyHsREAESANo9FgLh+JwHaQ/nO859duKy5w4CG5zCzV/c5vzIdkzZhncIvX37Fm/evAmVGL1EQAREoD0CCkTbY6+R1yTAn0/hZMrJlRPvzs6OPSM8cRMut/kUW169fPr0qXn1ar0HEnlTTk/P3e243KZOIH2uBtLr2L+KDKUvALcoApLTrvsJJNsN1FPed/+7br/sq0YAqOdzDpTTU836ZnsD+T7VaQGARHWcE32gyTmLwSaFeSDsw7wPQI+O1r9DKHFgFYqACIhADQQUiNYAUSo2Q4ABKG+75SRL4QTMCZZXQmkBU/7m2f7+fjj7snANOT+/DL5+/erOKFMvx4t2BxZqgUU+2mboeWDQfg9998k/ERCBHhIAFsddYDUPwJ3w47xF4dzF4JTzJL8D+v3330O34PZwx8tkERgBAQWiI9jJQ3GREyyvel5fXxsGoQDcFVHmeZtR2augxr4uL78E/JkWTt4cxxYtvQE8bAOL/EPhiDIA3KJnRC7L1UYJSLkIdJMAgE4ZBizbw0CTJ2A5ZzH45PzI+ZAnbPkU3NevX+Pw8HC5U6c8kjEiIAJjJ6BAdOyfgB75zwnWT7w+z+0qAah3n7f9RoNQTupAOH8DYcq2wCLP7TELIBZj3v/y3bgTMgBKp6bNl8YuRAAI92+hxjU3ApLHBsJyzoOct5gCMPy6Ck/K8gm4z549Q83mSJ0IiIAI1E5gUrtGKRSBhggAMJx0AbgJl7caPX/+vPJke3x8HFAvg1oA7tZcIFQLhGmSS0B6XVJ7lYmACIiACIybQFnvgdX5hidMeTWUPyfmA9Cy+tVPBERABNogMGljUI0pAmUIMFCk8PsuPONbRke8D4NQPn2XenmLEyd2tuHkzrPMzCcJsLooSGqnMhEQAREQgf4TALpxzAcWdvDpt7r9ttBnS41EQAQ6SkCBaEd3jMxaJcAJlxPvak25kg8fPgT8Tg2DTgagDDyZBxZXXuOa2Y5lTCnMJwkAd7teUl2XyuhDFemSL320Bejm5wQI7ary2SjSt+v7rIgPVdoAIeeucyhrXx6bsno31S9uf9FxfT/OJ+zjt5kH4J5tAMD9HjXvxmG9SXmxjnMT2wFwv5PNuZCS0kXFItARAjJDBPIJKBDNZ6QWAyRwcnIScHJf1zUA63ZRexEQAREQgRESYPBItxmQUphnYMmU27wTB1jMKQDcCUy24fzEnyNjyrt1Hj16ZBh86uFDpCcRARFIJdCziknP7JW5IlCZwMXFReCfvBtXBoQLgXh52nZgK6qI7d7qGwj9BcqlrRqvwRsnAGR/Luyq2VQS0+0XkO0/UK2+295Xtw7I5lN9hLY1zK0B2RIEM0MxJmzH/O3ttbm+/mb/dWD7G1sfOOEGg1AKg1j+9qcCUFKRiIAIDJXAUALRoe4f+VUzgbOzs4BPyKVaIFwEMB8XAA+LBF8HwGeVioAIiIAIiEBAjcqbAAAQAElEQVQmAV71pLARA0sKr3ACMLzKyTzrKPyaCE+Qsg0D0KOjI8MnwttUEw8BSURABAZJQIHoIHfrppzq3zhXV1eGkz8XBxQAKwFn3Csgv028j7ZFQAREQAREgPMNhfMNf9+TP7HCW3J51dOnDD4ZmB4cHJiffvoBL18eYX//CYxeIiACIjBwAgpEB76D5d6CAB9OBIRnorkIABbzPIDEgBTAQkFXcrJDBERABESg8wQ4z9BIIPxZMAakDDqZ+vLHjx+b3/7tn/DDD9/h6Oi5JhyCkYiACIyGgALR0ezqcTvKIJQ/00IKPDPN1C8GmPcCIDEg9fVKx0tAnouACIjAOgQAGF71pHC+id56+8MPP+C7797gxYtDGL1EQAREYKQEFIiOdMePyW0+IZffv2EAyrPRFACGaRoHQGuDNDYqF4ENEtBQItBrApx7+PRb3pZ7eHhofvrpJxt8vtAE0+u9KuNFQATqIqBAtC6S0tNJAu/efQiurm7sWelte6Vz6mQy2TLzuTFbWzsmMJN7MTZdFtvYUNxTcTE3QZIE4dMOeQtWkpicV1KfaFlO98LVzgfbuu7Uqqz0BmARp0sl5TV0rptXXF8NJpZS4T9jeZ3j9q5s33/+8/Sk1QPp+x5AWreNla/4a0eOls2t/1kSbZuUt+pafSfZFJYtHwubKmvK+bzP96J+Yk2Iit2MvHnykpu8mskTl7P5rZkHdyYwM2PsfMArnb6NuX8F/EzYCYYBKADz6NEjF3y+ffsWz58/b/9DfW+nEhEQARHoAgEegbtgh2wQgdoJfPr0ya4JuISyiyq7OOAAQPhdHaD4egBIbwugUiAFVOtPnyQiIAIiIAILAgAWGxVyDCYZhFIFgIdjPYNPCm+1ZRvW28nG/QQLg9OnT5+a3/qt3wKDzxcv1rj6SUUSERABERgRAQWiI9rZY3L1/PzcXgm9cgsDAMYvJsiAeQCujttFBECRZmojAiIwIgIAHoITYDU/IhSdcxVAZZsYXFIJALefGXwC4dzBeYR17krpbGb4NNzvv/8eb9680ZVPgumRyFQREIH2CCgQbY+9Rm6QwOnpqeGZaQ4BhAsH5il+ceFTlhURAEWaqY0IiIAIiMAACDDwpBucKwAYblOMfTEQ5W23/N7njz/+iJcvX2qCsFz0FoGCBNRMBBwBBaIOg/4MicDf//3fB9vbu/YqaHhLLhcR3j/mKfFtliWJb6dUBERABESgWwSAqrHf3DoUFbsZezPwxCQw/H4oHzrEeYI/ufLj9z+44HN/f7+qEbERtSkCIiACTRHonl4Fot3bJ7KoAoHf/OY3Ac9Ub21tPdx6y4UDVfoUgA1Sufhg6XoCLK85ALhbtoDkNE87kNwPCMvz+qteBERABMZMAGjuWMkglPMJhU+9PTg4MN+9eYvnB88wZubyXQREQATqIjCpS1GX9ci2cRB4//59MJsFZmdnz/ABElxE0HMGoABcYBrMYWCmhqkJyn38ARi9REAERKDvBHhszJK++5dnP4/kWTKf3ZpHezvmpx9+xNvXb/Bs/4DN89SqXgREQAREoCCBcivxgsrVbNQENur8x48f3ZXQ3d1dM5vN3NhcYAFhAAqE64domWtU8g8Q6ivZXd1EQAREQARqJADUf0z+4Ycf9JufNe4jqRIBERCBOAEFonEi2u4dgdNTPiH3xsznxor9Yz1gwGkTAyB8aJG9+jnBlnvYBOv81VIABkgXtgPCYJa3Z1HY39gX62xS6U1dWbK+8s32ANLZAcg1Jst31uUqUINSBAC4z32pzjV24j7OkhqHkqoEAkD4OQCS04QunSqKf3bixvErGnxoHY/VAFw1+zDjU+YpbMPbb/nTK9999wYUlvdFTk9Pg5OTk4AnZftis+wUAREQAQWi+gz0msDFxefg5ubG+EUFABd4+sWHqfjyeiuqUfehExixf0C4wB8xArneUQI8ceiFx3IA7mSkuX+xjFkGrHt7e+blyyPs7z/p5Qf68PAQR0dH7gFK9EkiAiIgAn0gMOmDkbJRBNIIfPnyxX0fFIC7wgPALTR4dpuLDH4XlGIqvKiH3YFwDOYpvpx5iQiMkQCAVt3W4CKQRSAahEbbAXDzBINPXgF99eoFnj3T02+NXiIgAiKwYQIKRDcMXMPVR+DDhw8Bvw8KwF0FNfbFbQoXIExtkXszaKS4jRJ/ALhAt0RXdREBERCBIRHojS+cB3hSknfI8PjPn1/hvLCzs2O+/+6NvYL4vLdXQHuzE2SoCIiACGQQUCCaAUdV3SVwfHzsbskF4M5sA3DfD+Uig4sPdxU0WP14czFCMQVf8bZAGJCynFJQjZqJwOgIABidz3K4WwR4yy3nAwagTBmA8groyxeHPfxwdoutrBEBERCBOgisrtTr0CodItAgAf5My9XVlQtAOQwDQi4ymHIbgLt6yTPh3E4StqUk1UXLfBsg1AkgWq28CIhAjAAA9/8XK9amCGycgJ8XOBc8efLEvH3zCs91C+7G90OvB5TxIiACjRJQINooXimvmwCfCsjfCAXgAlEA7kFFDBiBRRkAwxfLKcwvS1i/XJa9BcAtsAG4hsl6XZX+iIAIiIAIdIDAo0ePzA/fv8XR4bPwwN0Bm2SCCIhANgHVjoeAAtHx7Ovee8rH0vNKKL/vw8fs82w3z3QDcAEi86wD4G7TZb13ejVoDHyVUhEQgZoIAKhJk9SIQHUC/B7oi6Pn+lBWRykNIiACwyfQiocKRFvBrkHXJXB+fhnc3s7s1U+Y2SwwNzd3Lp0HgXEhJRfAVrhNMZPATLbs+sOmzFMCzM2KsH+K0EbA6rAZBrIMbCnMA3BXZM3IX2SRJSPHM3j3AbiTQECYxh0GwnIgOY2317YIRAnw2OK3fR6AnQcC97R0E8xMVGDmZntrYvafPjYMQn1fpSIgAiIgAt0koEC0m/tFVkUIXFx8fngwEYu5IPFXP7ndhABoQq10ioAIiIAIFCTAO1x4vOcJQCA8JvOBdAAMf3oFWJSxnHfKvHr1Cvv7+imWgojVTAREQARaJaBAtFX84x28qOdnZxfB169fDZ96yAUJBYD7uRYgXISYjBeApSs2wPJ2UlcAScUqEwEREAER2CABHu950pHCPIV5AIaBJ4VlDEp/+uknvHz5UgfvDe4fDSUCIiACVQkoEK1KUP0bI8Arod++fXPf9+QgPCvOlAsRCvN1CzDodUzduKRPBERABBojwGM+AHfikVdHKTz2s/z6+trs7u6ag4MDw6ugRi8REAEREIHeEVAg2rtdNh6DLy8vXRDqFx/0nIsQAK6ceZZJRKDbBGSdCIhAGQLA4son+/PqJ6+C8tjPn2NhAKrbcElGIgIiIAL9JKBAtJ/7bfBW//LLe/cMIgahdJYLEC4+uM2z4RTmWVeXALoaWhdL6RGB1gnIgN4T4HHeO8Gf7aLwuP/06VPz6uWRDtgejlIREAER6CkBBaI93XFDNvv9+/cBvxO6tbXl3GQQ6jL2D8+Gc3EChGsQ1mWJ7VLoDYT6CjVWIxEQAREQgUQCdRcC4bEZgLsV9+2bV9h/+jgsrHsw6RMBERABEdgogclGR9NgIpBDwAeh/O4PA0wGnRQgvB2XASoA950hBqWmhhegNU0NGKVCBERABGolwKufPP5zLnj06JF5/eqFDtbJhFUqAiIgAr0kMOml1TJ6kASOj4/dlVAg/F6QDzoBuN+N4625Ozs77vc7GYRygQIg86m4XMDEYQGLPqxjmzRhfVmhzrJ9u9IPWLACVvNdsVN2dJMA/weypJtWy6pNEfDHcX5GOCYQHmO4zeM7hScl+UCio8NnYBuJCHSHgCwRARGoSkCBaFWC6l8LgU+fPrnfCqUyIFxvMPDkdpvCBVFcitjDPkXaqY0IiIAIjJUAr3jyOE8BwuO+Z8EglFdB+V1Q3YrrqSgVAREwQjAoAgpEB7U7++nM2dlZ4H+mBQivftITLk6YtikMKLMkyTa2TypXmQiIgAiIwILA9tbETO0qBGZuKCaYmWB+ZyYIzKO9HaOroAtWyomACIhAmwSaGttOAU2pll4RyCfAK6EMQtnSnx1nIDefz1nUutAWStQQbnuJljPPcqYSERABERCBbAI8XgLhlVAe8ymcBx4/fmxevXoVVhi9REAEREAEhkpAgWjmnlVlkwTOz8+DL1++GD6SH4AB4IYDwpSLElfQ4h8AD3a1aIaGFgEREIHBEeCx3x/nGZRub2+bN2/e4NkzfR90cDtbDomACIhAAgEFoglQVNQ8AR+EciQAhosQPriC6XQ6NTwrzrquCBAGpMByGrWPtke3lRcBERABEcgm4INRXgV9/fo1slurVgREQAREYEgEJkNyRr70g8DFxYX7TigDT54Bn0zCj6EP5AB05iokbaMAoU3AcuqJe9v9dtGU/bKkqJ462kmHCHSNQNb/RpG6rvkje5YJ8NjKk458Mu7h4SGWa7UlAiIgAiIwdAJhBDB0L+Vfpwh8/frV8KdZtra23E+xAHCBJxclAB5sBRb5h8KWMgCcjcBySnO4IGYqEYESBNRFBEZLgLfl8kroixcvMFoIclwEREAERkxAgeiId/6mXefTcX/55ZeAV0J9EDqbGxOYicFkyxhMzTyAuZsFZjaf23Jjt4MVCYxxdUxtNvMNrK5vGDh6iXcGsBRw+nZcMCUJ6+M61tkGlscDlrfX0dVEW/qXJVXHhFWQJSawe9lKWhvbvRfvNPvzyrvuf9Zng3V5OyfN/zy/H/rF/l8ALP3/po9fTw19pJTVBtuxCbFqN/Se2HGiYjcj7wn3h91mOp0snpDLp+PCzM3333+v74NaPnqLgAiIwFgJcAYZq+/ye8MEeBWUizaASy8bTNoAI2oCEJZHy+J5IL9NvM8627RvnfZqKwIiIAIikExgYoNPHlN5Eo8tZrOZ4XdCeSLyu+++a/ZgzgElIiACIiACnSagQLTTu2c4xh0fHwc+EB2OV/JEBESgSQIAlq5wAsvbTY4t3dUJMABlMArAfR1jZgPRnZ0do4cSVWe7jga1FQEREIGuElAg2tU9MyC7+FuhPggFYPwZcqZxNwHEix62gfS6h0Y1ZGgXpQZVUiECIiACoyXAQBRYHLf5UCL+PMtogcjxMRGQryIgAgUIKBAtAElNyhPgldCbmxunwJ8Z5wYDPQrzcQHgroL4cmB525c3nabZ1/S40i8CIiAC/SAwt2ZGxW5G3gDcrbhAYJ4+fawroRE2yoqACDRBQDr7RkCBaN/2WI/s9UEoAzoGoRQAzgMAS8GmK4z9AfLbxLpoUwREQAREoCMEeOznz7Ps7e2Z58+fw+glAiIgAiIwPAIVPFIgWgGeuqYT+PTpNLi745nyiQ04p06CgLflwkwmW2Y63XZlpuUXF0otmzDo4ck3SwbtvJxrnEDWZ4t1jRugAXIIzM3e3o6C0BxKqhYBERCBsRKYjNXxGvyWihQCHz58DK6urmzAOXkQNuX3hZjyDDmvD+gQ8gAAEABJREFUjjLfBdGCtQt7QTaIgAgMjQCP9boSOrS9Kn9EQAREoD4CCkTrYylNlsC7dx8eglAf4DEApQDhnVl8ciLF19tua7yzmwKwV1oXkt3aPLQ1KS/amCUp3dwDmbL6+bq0/r68aDvfvqspsNgnwCKfZy8Qts1r14d6vy/XSb1f0T6+rMuptzfPRt8unub18/VA+PkAklPfrqkUCMel/rgP3OZxL3rSbXt72/CnSyis53GQfdmO22zL4A3g3SMBq1oVIPQPCNO4MbQ5bi99mQd3ZroFowcTxYlpWwREQAREIEpAgWiUhvKVCPB2XC5C/CILQCV9ZToHQfuLtzJ2d76PDKxMAKj+/wBU11HZESlYIZB23GFgyWCT9QAM7xRhZ5ZRWM9jJuuZZ8rf2WQdnzTOtl0R2ha3BfAPI4KZTqf3DyaCefr0qXnz6rU+rEYvERABERCBLAIKRLPoqK4wgY8fT4Jv3765xQgXVFxcFe7c4YYAHq6aAqv5PNOB1T7Aoiyvv+qHTQBYfBaA1fywvTeZ/1sATB9eSQGat5t1ANxxkUEogzUGmBR/dXRnZ8fwxeCTKY+fTPlTJ0y7LEC4j+gnj/mTqTF7j3bM84NnYUWXjZdtIiACIiACrRNQINr6Lui/AcfHn4KvX7+6RaVfkAAwXJi04R1toLQxtsYUgSwCQPn1OVC+b5ZNqlshULgg7zjDoJIBJq9y8smxVAzABaYMRI19/ff//t/NxcWFYUDKtjxusg7oxv6mjxRr6sqb5bwDhjZTHj9+bF4cHnXD8BVrVSACIiACItA1AgpEu7ZHembP2dlFwLP7XIxw0cU8FyTT6dR9T7JNd7hIanN8jS0CSQQAuJM2SXVJZcB67ZN0qKwdAjwGMajk6AwyKSzjsZK/r/yrX/3K/PrXvza8+sljJo+jbMs2AJhtVWhHlgGz+a25m90Yg7m7Enr0/LCC0UYvERABERCBkRFQIDqyHV6nu/Ysvrsdl4sqAC7wZJ4LKi5gKHWOJ10iMCQCQP6aHchvMyQmQ/KFxz+elLu+vnZXQLlNYWDKIPR//I//Yf7oj/7I/It/8S/48yaGZazzx08eS7vOg/7w5COv5r48eqEPa9d3WJJ9KhMBERCBFgkoEG0Rfp+HZhD65csXd2UHCINQLkp4Rp8LKOaZNu0jx6kyBvtnSRXd6isCItBvAlnHBtaleefrGKTxOOi/H8orn/wu/Z/92Z+ZP/3TPzWvX782v//7v2946y7bsT2DVwajDGDT9HehnD7SzkePHplXL14qCO3CTpENvSEgQ0VABEICCkRDDvq7BgEfhHLxxMUIu3JBwoWUL+M2sJm1ibeBdkhEQAREoE0C0eMRrxTSFl7pZMqTd3/yJ39i/uqv/srwO6O8GsqUx0sGoBTmAbirqKajL+8jTzzq6bgd3UkySwREIE5A2x0koEC0gzulyyZ9+PAxOD09t2fw52Z395G7HZffe6JwcQLAPaSI21xUsSxLqvoKwF2VLatnYvsnCaxCinXQlBH2peT2teNkvQFU8i9Ld5E62EZZkuef75vWbh4EpojwR3mSxJpX6e3tS0vT7M4qj+ry7dL+B/J8T/I5WlbJ+QKdvd3ej6KpZ5DU3tcx9fqjadSsaHlSPto2KQ/A/f8Aq2lS+3XL7m6vzQSBCeZ3xh75zNTOqMybYOby89mtq2Obr18uzZ//2Z+YX/9/f+nKvnv72vyTf/JP3JCz2czQP24w9dvAqt3Aoiz6WYjmqQcAk0rifaFv9IHCvBcFoZXwqrMIiIAIjIBAtouT7GrVisCCwOnpacAFEs+CU5hf1ConAiIAVF/8D5kikM0HyK6viw2DvTp08VZbfxfIfD63J+juDK9oTibh1MoytuH3P/lQor/+6782PHY+efLEfTcUgAtAo/YwTwHKswDK941zoS/0gwLA+Uj7vv/++/oGiQ+qbREQAREQgVEQCGfLUbi6WSeHNpq9ChpcXd24RVN0oZXnJwADpEte/7brgXTbAbRtXuvjA8jcv0C1+rYdBLLtr2of0Kz+pu0Dum1/kv8MopLKk8oAJBU/lPkglMElCxmsUXiSjimPlZ8/fzZ/8zd/YxiEMqhjn3/6T/+psYEcu7hjKm0C4P6XmKe4yhJ/AJTold7F28KUfgFwtxWn91CNCIiACIiACBQjoEC0GKdRtzo7O7NB6JXhwgoIFznMdxCKTBKB1ggA4f9GawZ0fGAgmw+QXV+Hewym1tUDwAWISf2oj8GlPx4y8GQ7Bmws45XQ//t//6/hw4mAUM+PP/5ofvd3f9ddOQXSr4hSz7oCYN0ume0BrBz33W+FvtATcjPBqVIEREAERKAQAQWihTCNt9H5+XnAxRQXVZ4CF18Uv6107ATG7T+A1EBl3GRC74FsPkB2fail/b8AVoxg4BkNRP1xkQ8n4hNw/8//+T/mz//8z13QyXa8JZffCz04OHi4xZV9KCvKO1AA4OGKLe3nE3KPjo5WQXTAVpkgAiIgAiLQPwIKRPu3zzZm8cnJifudUC6SuODiwD4gBeDOlLNszALABSFAuXTM7IbgO4BMNwBkfj4yO+dV9qAeQKaVQH49gFSGmcpjlTyOxYpq2QRC+6ifx0c+KZe33/JK6F/8xV8Y/nQLAMNAjldCf/rpJxfcsQ37mPsX85T7TdfG54ukAIo0W6sNAGe3sS/69UJXQi0JvUVABERABOoioEC0LpID08Pbcfl7d7NZYANOs7Qo4mKJMjCX5Y4IiMBACdR1vAJgoogYXDL45K24FJ6w+/r1q/nbv/1b9xMtvJuEt7Iyffv2rfmH//AfusCO/Si0izop1ENhnsK66FhZebbPqq9ax+/AKgitSlH9RUAEREAE4gQUiMaJaNvwd0J5Fp+LIi6suCBinosdCrcpXEgJlwiIgAh0mQCPVXXax2Og18fjIvM8FjJY41XOv/u7vzO8Enp5eWl4K+719bXhrbj//J//c8OglP0ZtLIfbeM2hXmWeYlv+/J4yr7xsrq2qZs+8sm/deksqUfdREAEREAEBkhAgegAd2oVlz59+hRwATWfG/Po0RN3JZSLES60mFKYn2DLXiadGG5nCRdTWVLF1ib7ep/yxsjyrUhdnv6u1xfxkW3K+lF0P5TV36V+5LSueD5padP+5dlbdvy43ip6on3jnDhOtD6eZ3DJMh7zGGSyPYV5ljGgpE7m2Y5B6B//8R+bL1++2OPnI8O7SljP74W+evXKXQ1lf7ZlHwq3KTzpx23WUZhneZZQN9uWFfanj0wpHIu+MaUwCP3xxx/x/Pnz+u/7LWu0+m2QgIYSAREQgWYJTJpVL+19IsDfCeUDNrggoTDfJ/tlazcJ8LPUTcu6ZZU4Nb8/GFxFR8ljzkCMASGvavIBRL4vgzfWMXhkMMpyfif0V7/6leHPtfAKIm/H5Xj/+B//Y/PDDz8YtmeQR2GefdmvbaE9tIEs6Cvtot0sox9MJSIgAhskoKFEYEQEFIiOaGdnuXp2dhHwd0Lv7uylUBN+LLhYeugT2LKoPFRkZ7i4yZLs3t2vzfKtSF33Pcy2cAw+ZhNotjaPb7OjSzuDTAaUe3t7hnkGaDwucr+QDrd5u+3//t//2/y3//bfDE/ecZuBK9szAGUgaq8oPjwll30p7EsdbQp98YEo7aBdDESZZ6on5JKERAREYAwE5GM7BGx00c7AGrU7BBYPJpo5o7g4ofDsuCsY6J8uLAQHilZulSTAQKBkV3UrSID/95S05twHXhhY8mmxDEbZh8dEf2WU2ww6/9f/+l/mj/7oj9zXGHillHrZn98P/Wf/7J+574cyKGUZ+/uUx1i2bVI4VpbQB44fTZmnH7oaSjISERABERCBBgncX/pqcgTp7jSBT59O3ZVQLoqSFiydNr6kcVxoUUp2V7eaCPDzVpOqQakhF8qgnOqgM/FjAJlToqYyGGM7Xh1kHa8eMihlYPn06VP3ZNz//J//s/udUB+gMnhlez6c6Pvvv3cBKo+vDO6om3kKg1JuVxHaliVFdHu7qId2UXgF+PD5gb4XWgSg2oiACIiACJQmoCuipdFV6NiRrnw6Lh+mwYUHF1neLC6QKFyY+LKhpEP0qW/7hp81St/s3rS9YtQ8cTL2kjQa61jOYySDSx4XmfJK6F/+5V+a//pf/6vhFVOWsR2FbfgzLb/3e7/HTffdUJb5Yw/zDGSp0zVo+Y+33dvHwPT5s30FoS3vFw0vAiIgAmMgoEB0DHs5wcfz8/OAD9XgooiLLQqbMaUw7xYm/nuhLOi5jNF87sMsGSMT+VycQNZnh3XFNbXTsqqNDBYZNFIP8wzS+FMsf/M3f2P+y3/5L+7JuCxjMOfb8Huh//Jf/kvDcl5BZT8K63ls9cdclrVDZTEqbfF2MaXNDLIXLZQTAREQAREQgeYIKBBtjm1nNfM7oQxCeQsZz+ZzccRFERclFC5IuN1ZB0oaRr9KdlW38gSWevKztlSgDRFomEDZ/3v/WWXK224ZbDJQ+5//83+6K6HRgI3BKh9QxCD13/ybf+MCVAahdI11PJ7y2MqU5cxTL+ubFI6RJ+TDNkzp4/7Tx7oa2uROkW4REAEREIEHAgpEH1CMI3N6eh58+fLNOjsxjx8/dU955AKECyNb6L7PxJQLE4rB3GTJPAgMJTDGlBHbbSNvrqwmgImLqfgq43O0T8Xhc7sDyPyt1wIKjFVQWvjZiMpsPjdR4WcvS4Bl+82aryzdrs7qi+6PeB6TickS273Rt7PR/o+lDeLrV9Pg4X85rW9WudcHhPzTPgOT6dRMpukS51l2O/oZiurI8oF1wL393EiQYH5nKCaYGZi5kwkCszWF2dmeunRvd9uwbMdu/39/9Rfmj3/1/5rHj3btAW9mAhizvbtjMJ2Y3Ud75g/+nz80Ry9fmOvbG6stMNPtLVc+2ZqaWTA3VpFrOzd2/8C4Yyd9o09MvXCbEt9mWVQSXFoqmtv/t6j4/epT7/Pd7bXZ3dkyL18cWquWVGhDBERABERABBojMGlMsxR3jsDFxeeA3wmlYRO7wOaZeuYlIiACyQT8gj0tTe5VbynQ3dggjYsvL0sCSPYZSC4vOw7tBOAeNrS1teVup2UZr1oygANsqGaDuZ2dHfPnf/7n5k//9E/d1U624QN9eByd2kD86urK/Nt/+2/N7/3e7xkeY1kO1GuraehFP+k7/WloCKkVAREQAREQgUQCCkQTsQyvkL8TygUSPQNguJDiYovbEhFII8DPSZZwEZslAAxQXtLsqqMcQK6aLN9Zl6ugYgMg38aKQ1TqTgZZUkU50LzvDMAAuN/45FcV+FkGYBhIGvtikMk2DED5cCKevGPd7u6uO4YCMOfn54bfCf393/99F4SyznY129vbTDov3H+0eX+/uQcU8esgTYKQbhEQAREQgX4SUCDaz/22ltX8iZbLy0t3Gy4XVlxIcfFBWUuRGo+OAD8jWdJHIABccEzb6RvTNGvlD1wAABAASURBVGF9lqT1G0N5FhdfVycHAHWqc7oYWFIAuOCTgaixL3+c5JVOBqEU+uSDSx5DbTPz5csX84/+0T8yf/iHf2h8X5azP7cBuM8akJyybZtCnxhoHx4eokk7Tk5OmlQv3e0Q0KgiIAIiUJmAAtHKCLut4Pj4U8Az/X7hxEUXLeY2hXmJCJQlwIVslpTV21Q/YHW97e1vasym9AKrvjQ1VlRvnbyAfB8AuGAuakNdefoCwN2Sy+Mhg0emFAahf/Znf+Zux2WwxrY+EOXdJAxCf+d3fsf8+3//7505rAfgAlr2B2D68NrELbm8tbkPLGSjCHSfgCwUgWERUCA6rP255M3JyZn7TigXVzxDz8URF0sUAI0t7paM0EavCQDh5wQol/bJef5f9MFeINwXbdjaBCMg3R8AjbrJYyKPjTxGMrjkLap8Gu7FxYX5q7/6K/N3f/d3LrBkAPrkyRN3VwkAdwvu0dGRC0IZyJEL+zOl0GifMt9VoV/Pnj1rFrJ1/scff2x8DDuM3iIgAiLQDAFpbYyAAtHG0LarmEEoz+j7M/lcaPlFFy3jNlOJCGQRAOBOWADl0izdm64DsPaQADL9jz7BtEx+bYM61gHI5tO2uQwG84THQgqDMgalHz9+NL/+9a9dIMptBqY8djLQ5PH05ubGPH361PyH//AfjA3i3HdFOQbbsJ55tqXOtv3PG5+Bd14b1YuACIiACIhAUwSyAtGmxpTehgkcHx8HvG2MCyIupChcJMWHZX28TNsisA4BoNuBiPcFgM9mpvH/CQCZgWimsgYqATSgtZjKOBv2AlAbHwBUuVHhsdEHjAwiz87O3K24f/3Xf+3sYB0DT36lgcdQfs2BV0D/3b/7d+bt27fue6H8/VAGsQDcNjnt7e25232dkg7/afIBRR12W6aJgAiIgAh0hIAC0Y7siIUZ1XInJycP3wnlwokLKS6MosIRALhbzkzFFwC3EK2oRt07SoCfnyyJfq6S8mluxdtWbZfWH8j+fAJhPbBIo7ry7PT10T5Zed/ep1ltk+p8P5+yjc8D4KYLhgCYpO/lAXD/r0CYug4Jf4DVeiAsAxapHzsvTRjCFcX7ucL7P6y7z5ZOALgrlgwkGXRSp88DMD7Pup9//tn8yZ/8ibsdl0GpDyYZZPJYyjtM2O4P/uAPzG//9m8bbt/dzs3WdMfMZ8bATJ1MJ9uG5SaYuG2WMx+XYL7gaCIvAA9bAAyAh+11M/SXQvvZl3n//8xbjVkmEQEREAEREIG2CEzaGljj1k+AV0K5OOJiiYsnLjrqH2WgGuXWRgkAi8U1sMhv1IgSgyX9TwHt2c8Agzb54MK7xACLV+r8tk/Z1uc3lQLl+ADl+kX94rGQbHgLKm+XZR2PjbyyyXIGnCzj7bj+O6EM4MmV5eTlr4iy/7/6V//K/IN/8A/cd0R9G7ZLEmBhP7DI+7ZAsTLfvkxKG+kDPw9AGJRzm34f7D9ZNaDMIOojAiIgAiIgAiUJKBAtCa5r3T6efApu7m7N3ARmFszNbD43mEzslmlUusZhXXvKfK8v2mfd8frWHoC7IgMkp1X8AWAoVXS03Xdd+9meUpfdDCqoi0EVhdteP/OsiwvLKfHyJra9LU3oLqKTASeDLvrLlIwoDDYZkDJQff/+vfnVr35l3r17Z3gVlGXRttxmUP+v//W/dldCGdSxP3V6oS3MM02TtljQLvpMu5inMDDntkQEREAEREAE2iSgQLRN+jWNffzpY8AroVzocNHEhRLP3nO7piGkpqcEuOjsqemdNZtMKVUM5P8mJU8Hx8kSBhjUw6CKwROvgOXpNMa4JtTrMi3++f/Ze6/myI47zfv/FLqbbHYDjUY30N5QJEU1RSOKohUp0ci70Uja3YnYjdirvdmLjb3Z/RL7BTZi9mIidubdifEzkkaWEodWFL3onejZbO/oCaDe/GV1AgU0UCgAVSiDpwJ/ZJ50J/N3XD4n85xD3YstpRq0YSGjfM6JGOdHGOFHTPJW3Pvuuy+OHDkSMCQMptSFdPg5t15++eVx8cUXB/lZH8KUMvAXIw/G+nCxen9Znh1GODZfOHFLNepGubi0BZf9ZHjToJZapvOZgAmYgAmYQKsIWIi2imSHykGE0iGq72yUqhBe/HZXLwE6n1gnCLBfLnW9y8m71HUuJt9CTKl/scWUu5i0iArEEXkQGhjrREThUsdipOkmo3719WEZqw9brh8OlFEYlfJZfvzxx/NI6JkzZwIBys07RlDJQzqWP/jgg7j00kvjs5/9bH75EHEwxji/FrbFZV0Y+bHZfpYx4rDZfpZbadSLOmP4KXvdunU4NhMwARMwARPoOAEL0Y5vgqVX4NChQ/nFRHQwSkeDzhEdHDpauEsv3Tn7jQD7SSfaxH6INbtu0mLNpu+2dNQdq68Xy1h9WCv8HO8YwojyEVRML8XlnFC/DrY/Vh/WCT/1xOZbN3HF5ktTwmlPI6Mc+ODChbT4H3300Xj44YfzC4f4PAtpiCsufkZCL7zwwrjiiiti/fr1AU/EaUlDOaTD6utT/LNd0mP14bOX6+Na4S/7Beuhnty42DIy7NHQVsBddBnOYAImYAImMJuAhehsIj2wnO7gV48cOVKlQ1RfXTobdJZKWL2/hNk1gdVEgM53I1uIBXkXSrOYeI5RbDF5GqVFGHGcI6Z27tim0a0jGtm8SYQxujdXXtqEzRXXbWHUs5EtVF/4wJtzJaOblHX//ffnT7QgNJmOi1ijHHgVbu+++25cdNFFcf311wdvl2UqLmm4wUdZuOSjPMKLi78Y6y1WwnAJw10JY13UDRfjBsVKrNfrMIGuIeCKmIAJdDUBC9Gu3jznVu706dPVJESDjhGdKDoZpKKTgdGR4q43fjpMxNlMoBAo+0tZXkmXfXKh9TWTZqEyWh2/GGbN1r/ZdAu1ZePGjbFj+1gWn1H3o3ysLugc72LadU7mJQbMrtPs5SUWO282ykeMlnPlvffeG0899VROzwgpcaTBOHfCBIG6e/fuuOqqq2JwcDCn5ZxKHAuURT7CWC7h+ItRXvHjLrRMmnYY6y31w1/q3I51uUwTMAETKATsmkCzBCxEmyXVBekQoe+9917+Lh535OkM8W06vmE3MV6N6qSy4edufRdUOegENbKVqmP9m27r/Su1/k6th87nbOtUXVjv7LrMXiZNK212+bOXF1pXSb9QuhI/e18nvIRxTBY/4QifgXQGXjOgwPBXlPbO6kRMTnwSE+Mfh2IyCMPwY6TdcMH5sWvn9nMEKOVi4598lMvE38jq69Mo3VLjCr/izi6nnkmpS3GJK/nmcylvfHw8T5slTaWSgKbAiYmJYISzGhNxwYbz4933TscvfvmzeObZp6IyELFmbSUG1ihCA/HxJxPZrUYl3nv/w9ixc3dc/fkvxJatY/HhR5/E+EQqZTJisqps1ZROlTUxMZmySVFJ65RSWVH7UX/qjuEvVoud/i8p5yU/JimkmRbz/OYr85zk1WoMVCqRap7ciE1DG3VOGgeYgAmYgAn0A4GebEOlJ2u9Cit98uTJKiJ0InWwSvPpvBR/t7qSQprfurXerpcJtIoAxykjUUyLZDQNv6SpmzQc05g08zgZGBjIaRBaxJN3586d2rZtm4aH+/85P0kLbgJJ+fwCI0nBaCZ+MsKbz5QcO3YsfvKTn8Rbb7019XkW0pAWQYdghC/LjITecsstMTIyEnw/lHIWMspYKM188ay7GOXMtvnyLTacctnvFpvP6U3ABEzABEygnQR6X4i2k06XlH3ixIksQumw0KmlWvjpPOG3mYAJdCcBjlGM4xUxMLuWCCLCMYQPaaWauGJED/EwNDQUSSBpdHRUsYgfZS4ieU8mpY2S8ltvYVzEe/HzbdB/+qd/yp9nQZhy/sTgLik/4gDn999/P3bs2BE33nhjbNq0Kd8AYFs0C4V6NJu2Ph35Gll92qX4pdouwzpo/1LKcB4TMAETMAETaBeBSrsKdrmtIXD48OEqnSRKo1OKSQo6WhjhnTCvs/ME6FwuZJ2v5equAaJH0pSwQQBhiByOX45nXJYhhZ94RMO+ffvy6GcSRjU1QYI+M0l5RFPSklsmKThHSgqEKPzg+vbbb8ePf/zj4CVFjCaXYwXGPB/KMtsHIZpGmePmm2+eGgkljrJiET/yLCJ5Tippqv1SzZ8jWvxPUqQbGmpxsS7OBEzABEzABJZFwEJ0Wfjam/no0aPVjz76KHdipVofgk6UpNzhWmxHKfzrdQK5/nR4sbzgfz1BoH57ScrPBnL8IkARTQgl3AsuuCCPfm7durV2wEd3/ySdI6Sk6bDF1F6q5VtMHoQkBj9YIkI3bNgQL7/8chahnC/hLNVuBkgK0iE+iWMUGhF6xx13ZBFazrekWUw9lpqWuheTau0vy7hLLbfkk2rtZt8qYXZNwARMwARMoFsIWIh2y5aYVY8yEkoHVqp1UOg4kYwOCp0r4ljuZpNqdZfmdru57t1Yt17Y5t3IbXl1Wnru+bYX4RzPCARJwbOM27dv18jIiJa+tv7IKWlK3DbTIsQnwpK0CNLnn38++EQLYhK+hMObZc6dsGYZQ4TeeuutjBZmgUoayiMPftzFGGUuJn19Wmm63VLNXx+/FL+kPHuGEfal5HceEzABEzABE2gngUo7C3fZSyNw8ODBPBJKJ0rSnIXQ4cHmjHSgCZwlwD7SyM4ms9MmAhzD3DSSlGc2lG0hKYut9evXRxJD2rx5s9pUhd4ttomaIxol5WdESf7000/HPffcMyW+EPuIUwQoYowRUIxwngn92te+lkWopPyiI9IxbReX7UaZizW2cbN5SNvImi2nUTrauhpebtWIgeNMwARMwAS6k0ClO6u1Omt15syZ6jvvvFOl40DniU4sHSKp1kelw8JdejpfpFlqR2l10u39VrP9e78Vq6sF5XjFZftxzCI++fYnttqf25Nq57al7hWIS86V8H3iiSfi4Ycfzo8tUB7nT3hzruQ8Cn/SM3q6b9++4O24fIeVOMIQoJRFeoz0lLMUazYv6WYb6y62lHXPzkP5s8MaLTvOBEzABEzABFaKgIXoSpFeYD28GffUqVOByJSU7+jTuZKUc5bOhKQ8kkIgnRWptizN7ZJuOSbNXa5UC1+obOrdyBbKv9rj69m1g0Upvx1lU2Ypf6kuZXTSOMaoe6mDVNvvJeUgVaoRmoxq8C3KyWAZY3li8pMczvK689bEho3rY9vYVm0eHlK0+SfVziGS8vlCmttdqBr1bS9ppemyiJ/PSD87jrDZJtXKmx3OMvkRh0VQssw24TyJn9FNnut89NFHAyHKORMBikk1BuQlLeXxCaxPfepTwTOhaZQwT8clTqo9O1rKRZySnnURj1+aridhxEm1MOlclzyNjDJmx0vKzw+zfkyaWW6c/Um18LOL5ziUXQyBfU4CB3QbAdfHBEzABFYlgcqqbHWXNToJ0CrfsKNaUq2DQSdjta7eAAAQAElEQVSEjgRhNhMwgc4QQMRIytNqER4IHQw/xyfGsYrwwSUcMUOaEocQGNs6quGhTVrJVkgruroZTZMWt25YzSjg7ALhsIRrMVifd955WWAT9vvf/z6effbZvI0QrVJte5GXbUEajDfrXnbZZXkklOKJw13IJOV1UR4m1ZYXytconnLmip8vfK60jcIkTUVL0/6pQHtMwAQiwhBMwAQ6TcBCtMNb4PTp0/nzLEwNq6+KpNz5qQ+z3wTOIZBG4xiRW7KdU6AD6glIteNQUn1w9kuKAaVT6GQa//xkPMY//iQmxydy2Przzo+hjYOxY9t2jQxvVqzwD1G8wqucWp3UfHMRXthU5uSRlM99ktJSZIGJBwGK0OTmAOIUYfnAAw/ESy+9FJw/EacITvyUiZ+0jJgiOq+55pq44YYbghsD8JFq5VN2MyYp16uZtPOloV7YfPGtDJdqglxSK4t1WSZgAiawPALObQJ1BFIvqm7J3hUlcPz48SrfuKNTVd8xoqOCEbaiFfLKTMAE5iQgKT97yDGJuMGVah19RA7GMYsYGhwcjNHRNAI6PNwxBSApiybq1MiixT9JyypRms4vKeBM/Qvz4j9z5kw8/vjj8cc//jELVbiXNJF+iFbOq2wX4q699tq4/vrr80uNmH1CWspKSRv+lfWTVtIMpsQ1zFwXSX6sLmheL+mweRMsIoJyFlPPRRTtpCZgAiZgAj1EoFuraiHaoS2DCKVDREeJThMdI6pCpwGjA4ER1s0m1Tpn0txuN9e9mbpJc7dLqoU3U4bT9C4BRtXqay/VxCfhRehwvDLKNjQ0FGNjY0pCVPV5OuGnTp1Y72LXyTkOq88nKQs+wmgH50ZGOVnmZUOHDh3Kz4MiQonj26uEl3LIw/bh3MoIKgL0c5/7XH4elDC2FS55KbORSbXtTdmUi+HHJDXKmuNIh+WFRf5rJp/UuA6UQZ0XuWonNwETMAETMIEVIdDnQnRFGC56JUePHs3PhErKoyylQ0SnQdLUKAAd3fDPBEygowQ4LjHEDYYfo1KImg0bNmQBumnTyj4DGg1+kqbEXINkLY2StOjyCsfilgIk5fpzboQ5o5qwPnz4cDz22GPx6quvBiKTcPJyrkSskp5lZppwY+Cmm26KSy65JItQyiYP6XDJQ9hCJtXqUtJJM5dL+GJc6ogtJs98aaXG9bEQnY+cw03ABEzABDpNwEJ0hbfAsWPH8jdC6YTQQZCUO0llGbd0kPCvcPVaszqXYgJ9RIDjEDGEKymYwcAnWPj0x9atW9VNArRglxqLk5KuVa6kJRcF15JZUhagLEvCyca58p133omHHnooDh48GIh/wqTaiCV+xCUjnbxJN41Mx4033hiXX3553l6cUyXlsiUFaXLBC/yjbpSNsQ9g+DHiFsh+TjR5sBJR7y9hrXQpf2hoo1pZpssyARMwARMwgVYRsBBtFckmyjly5Eh+JpSkdGZx6SjQeZKUR0LpMHHHnnDu7od/JtAkASdrPQGp1ofneKR0jklG5raMDGt402Atkogus5WcHiy1HoNUK5NzYxL68dZbb8W9994b6UZefs6TcyTIEZ+cS9kukvJnr3bu3BnXXXdd7N+/P9/k45zKyCniseTDj1FGI6sXnvgx8mH4G+VtNq7sW82mny+dpPmiHG4CJmACJmACXUnAQnSFNsuhI4erH378UVRTX0EDlZiMas1SQGVgbVpKYWf9a9aeF6qsyWHVqDR02119OknLsXbXr93lL9T25a6/GhNp+85vC74Nd7kVOPvW3fp65HWeLbe0/+xizzmVSiWLEQQNwkFKB2BqBe1KTkxOfBLVyfEpS1ImKkpHXbKBdHYknuX156+LTUMb83dAkyvynrWudSTF+MTHMVkdj7xN07auVquBScqPBcTZH2HFzgZlp5L4SZoaSZSUw+v/lXxzufXp5vIPrEnlpXqV+k2mumITk2m7pGMD7i++8Fzcc/ddceb0yRhI24TttWZAwbZKjUluKjm168MPPohdSYR+8aabYs+ePSEpb/tKakM1xU9OTuYwllOOYHkiraPe6o8D/KpUg7pNpnrhX7d2IMY/+Sio029/8+u4+567Ys3aStAO0pAWq6b1YTHrJ6V6z2Gzks27KM3MX01tqjd41JukectyhAmYgAmYgAl0mkC6rHe6Cv29/uMnT1QPHz1SnZiYyCOe3L0vHaG5Oir9TcOtM4GVJzAwMBAcd7iz106YpBy/du3afIxKSn35ap6+yUtweBkOU3BXcpRxdj2XslzOM4vJK2kxyZedlvMi3CVlYUiB1JsRTLjzaZa777473n333WBbEY+AjIgsMssNBl78xggon2dJ2yqXxTYn/VJNUhaurJc6MR2bsnhG9ZFHHokjR47kT8c8//zzef8hXTmnk77UkzydtDNn3ktqupM18LpNwARMwARMYG4CFqJzc2lJ6MlTZ6rvvftBfPzReFQnU6cmBiKqlexnGVvOiiQtJ7vzmkDfE0AYIAqw0lj8iAZcxApCiHSIItIgIIhjSiifYUluTx5otAGTpqsvKYsr2kmbcVfSZq8T/kyXJRzRT30xts/TTz8dfCeUFw/xTCjbhXTkQYCShrSnTp2Kffv25W+Epu01dTOB74dKWnTzJE0xIjPPk2LsH2+++Wa89tprWegilKnLCy+8kJelWj7qSVpc6tvIKH85JtXWKc3tUjZ1wW2JuRATMAETMAETaCEBC9EWwqwv6viJU9V30118abqDQIeETgGGX1J9lqb9kmZ0lJrO6IQmsEoJIAo47nAlZbESZ3+EcTwSjyhCYGzbtk1DQ0M6m6QnHUSSpHnPFbS5vmGS6hdb4p+9jtmFEo+YhDv88XNjAHGHCGXb8FIohCdxWMlD3HvvvRcXXXRRXH311ZFuGORRbEl59JS0kX6S5mWQoqf+pHPTScrx1Anh+/bbb+eRWPYRxCmjpISdOHEiv8WXxNSPupGH5U6apCySO1kHr3v5BFyCCZiACfQrAQvRNmzZI0ePZxFK0XQG6cDQKZIUdFIw4gjDXYxJtY7RYvI4rQmsZgIcb8Wk2vGD6EH8YIgG+CAqdu/e3ZVvwaV+i7UkzMQ5Rqq1mfySpkQZTGaHsdxqK+sp5c5eLiKT7cCU3BdffDHuv//+LPgIK/nw0x7yk4cRz7179+a34zISijAknm1LGs69JS+uJJwZNpDCilVmxNQWKCf7Jqvx4fsfxMmTJ3O9psJTJPsQ03OpH3VIQVn8sYy/kUnK20Oa222Ut9k4eDSb1ulMwASmCNhjAiawAgTmuvauwGr7dxWHjxyrvv/++3nEhTvipTMiKYcVUUqHSVL4ZwIm0F4CiAZJ+fiTlEUCnXOsHIeMum3ZsqXvDkjaF2d/Uq15Us0tXM5Gd8QpdeC8ODg4GK+88krwTCiCjvOnpOD5T0l5+yFAJWUxiPjkEy3kY1tSBudbhCHL+GMZP6m2r0gK3pRMUZRJHagffsK4gcEIbjnvs26MehDfSZNqrDpZB6/bBEzABJon4JSrjYCFaAu3+PETp6Y+z0KniE5WvbEqSfkOOP7SkcHfjElqJpnTmMCqIcAR0ciiWo0SX0nHz+TERPCW0bVr1sTgxo3BCNz27duVxAzJ+o6bpJBqRuMk4QTnpexZoX+z11e/jGhD6CFCf/3rX+cbBZLyNFtGNTmXIv6KqOaZ0ZGRkbjjjjuCGwjEcS6lHFzySLV2zm6eNHd4fTpJmRlhqkact3Yd036F4KQu1AMXoy64TBE+dOhQkCbnS2VQD9rZyEjbboNJu9fh8k3ABEzABHqYQAerXunguvtq1WU6Lp0SOiB0jugY0WmhoXQGitExwY9LXDMmqZlkTmMCJlBHgGOMYw3jeMTwI0C3bNmszZs3r9oDCzZ1qFbcy/oxXkTEc5aMhCLo2EYY505cSfmZT0YhmY6bRq7j1ltvjaGhoWDUkXNu2abl3EsYeWOOnzT/JpdmxlFeEr05kKnOjNJSNnWhaJZxseeeew4nf+d03bp1U2I2B3bon6QVv+nQoaZ6tSZgAiZgAj1IYDUL0ZZtLkQoHSQ6KJJy54iOEct0tLCyMkm5gyKpBDV0JeX0DRP1YSTMsD5sWm4SbcOk2vaV5nZz4jb+k85db/3qpFp8fVg3+Sv5DDaZOtsTqVqT6VhJQ1gxOeUXQ1ppeXJyPEi7ceMFsXv3Tg0P9/aLiFIDm/rbNjom9jPORxiZWMZF6Em17SvN7TaTRprOS7mzDTFHWDkfUiZGPagTz10++OCDcezYsfwZFOJISxxiEpdlzrHbtm2L22+/PYaHh4NlwkvZiFLKZH3koxyWZxvppVqd8RPPOnAxwgZUibUDayKtT1H3qxe/rI8bjuRFeCKmGRVlmbiSrdSFZcqnfhj1I6yRkb5RvKS0z89v5Kc+J06c4MBoVJTjTMAETMAETGDFCeRu3IqvtY9WiAilo0GHqBh3yfET3kdNbVFTXIwJtI5AOcak2rNwLNPBl6aXWRtTJnfu3KkyukXYajHOR4gRaXp0DIEiaUEEpCuJ8M+2EodLHG69SdPrZNtIylNvqQ/1Is8f/vCHQMQhzjDSYcRJte3ISGnadnH99ddHGsUOpsRSRv26ZvvJPztMmtnmkob1Uh/2HcqVFFu3bp2ZOBXGaCzndgQoeTHySsrCmGdFKSclze0knaR0o6SaRTZpKZ94ysFdyFjHQmnmiycv66Ee86VxuAmYgAmYgAl0ioCF6DLIpzv4Ve7KV6tKd6UHUmeDDodiYGBt6nSsi0plTUSAuJGlJP4zgXYT6NPy6dRjNI9OPkICEUOYpCBscHBwTlFBntVgPH9Z2okwKSapBM/rlrTzufNmPBvB9mBbsIgrcY6spnNlNRBHr776aiDeEEtsK8Lw45KefGxPngW9+eabGaHMIhSxR52Ix+r9cy0TNpcxYo5FGjXHrUQ1jYRW4rzz1s6VPPbv2xPrz18XE+Mfx8TEJzkN9aSOLPzxj3+Mw4cP50+5UCdJ6TpQSWkncntJixFX8kQTP9I3keycJJKi8Az/TMAETMAETKDLCKCQuqxKvVGdo0ePVnmb4+Rk5E4VtaazUDoZknIHJPwzgS4mwD7bxdVbsGoIHRLRDqwcf3S+GQXlRURDQ52bhkvdOm2DGzaKqaOFDfWBD7zwNzLSFCNd8Re3Pgz/bCNd/XpZlpTF0ZEjR+KZZ57JwpL6sS0lZdEm1W4i8CwmQvrLX/5ypBHt4M20lIdQJU8s4idp3tSUyXRauPDM6tDQ8JyJt2wdY1Q915E8k+MTU49iIKQZqX3qqafyaCgrI00RnPipNwyIw4/brJV8zaYv6STl+pw5c8bTcwsUuyZgAiZgAl1BwEJ0CZvh0KFDeSSUjgedJzoIGH6p1pGik0HYEop3FhNYUQLsp9iKrrRFK5OUb/jQyUdISIoLLriAkbNV/SKimPVDlBMkCScLwVZs84XKYLuQRtLUduI8iThjNPTgwYP5s0fMdwAAEABJREFU0yjc1GN2SYnj3IqoQxgiQrdt25YFK+GS8ogj2zvSj/KTM/VXrVan/HgkhSS85xhCMiarwaPEPBPKS6w2bBicO/HZ3BdddFFuC23AWD/1Jhr39ddfj7feeiunIY5rAe1Yu3ZtrgdpSEtbcNtpkvKNUkn5MzjtXJfLNgETMAETMIHFErAQXQQx7ii/8847VToWdCYw7spLNfFJp4SOF0YHRGrYn1nEmp3UBNpPgH22/Wtp7RqoM8ebpEBspVEzC9A5EG8aHFIRQpKyIJoj2TlBUi2tpBwnKeeVam4ObPCP7SMpp5BqLmGnTp2KN954I4ezLNXOoWxLAsvI5w033BB79+7N01o57xLPeZdzLfkw0s9nUm2d88UTTnmMuo6ObtPGjQuPnn/605/Oz6lSHwSmVBN7pSwE9ZNPPplHbxldRXBST+pOetbHMi55FmPkW0x6qVY31lWE+2LyLy6tU5uACZiACZjA4ghYiC6CF52j0vmgQ0FnSKpd6OlkYHQUJE111hZRvJOaQN8R4HhoZMttMMchHX06/KOjo1puef2cH6EuKZ+bOFfBbqH2SrX00txuo/xsd0l5ZDDSj2UEEedQXk7E23K5kYdAYhsiBlOyLDpJe/nll8cVV1wR7777bh7BJQ3nXPKTbq76k4+4Zo0RUEbQN2/eombzDA4Ni7pRX0m5bpF+tC05ub207/nnn89ilHoTXuotTV8zCF+sLbaNbGtJgbvYdTl9DxBwFU3ABEyghwlYiDa58Y4cOVIl6bp15+eO3Pj4ZLqwR+o0fZzcSaJyB4ROR+kglY5HjvQ/E+gBAovt5Ha6SYzybdu2TcPDcz/T1+n6ddP6GRWVlM9fiJIinBrVUdJUtKScV5p2pyJnecp+JCmfF1ku60R4Hj16NJ07x/PzldxEKPGcM/Hv3r07rrnmmjh9+nSehku4VCurnGMlxXJ/jILO9zxoo7IRoiMjW+OTifFcv8KytFFSPP300/HKK6/kdrKfkkZSniqLH2u0jkZxMGoUP19cEv/5OjZfvMNNwASaI+BUJmACrSFgIboAx8OHj1YPHTpSnZioJsEZMTFecytak++E0yEYGFCsWQPKyZRmPHU0JlKpk9mtVifOcSMmc3zNTd66P0khNW91WbNXmpk3B7bxn1LZjSw1Phpayt/RP6VtMZc1WalGbW8UV0nbCVO1Eo2sEgMxl5U8TVZzRjJJ0/tYKl+zLFKdoslfqceSXdZTTcfUxERMJmNfUQrD8GNwwvBXJycD/wXr18fOHdt4cUxOmrL4rwkC27eNqjo5no5JeH8SA2sU1ZiIiclPYrI6nv2RjgdVqrFmbSUhrzYslW1Rb2wMjLDipkJizcBA3r6Enzh+PN7h2dDzzovz150X4x9/EkqrwSqhmPhkPK6+6nPBM5sDKR8VwJUoMYJRUcTsZNoXIp1L89tuK5EEb6RzsoLl4LxLOyeryTuZjfLPW7sudm7foWKUvRRjVPRLX/pSWt9A8EIlxDHlIC6p63nnr42PPv4gnnv+mThx8ljmW02cI7GFOXzxK2UqBpuBSiXv39XUtonx8aiPI77eiINBNR0/qZiQlA0/YSUOXly/1qxZFx999AnRNhMwARPoRQKucx8SSJfvPmxVO5pE5xyj7NkuYckkpf+N/6SF0zQuoXEsHZDGKRxrAt1DgE4y+yyddzrzdOSl2jEiKYmLypTwIN26deuCEbTh4YWf5Qv/5iTAFF04wxODe/2InaQsaNg2cxYwTyBllajiL4KxiCJEG1NteY6yPi31YZn0+/btm3oGczyJMYz8xEvK+0RJH+nHuojHxSRFaRP7C+0dGhqKHTt2aMuW5qfgpqIb/l166aXixUW8aIn1M82X/bjUgU/O8CzsY489lkd2mcpLHG2sr1/JA2/KkZRHWSlPqm2LhhWpi6R8FouLv7AijPIJs5mACZiACZhAcwTam6rS3uJ7u/SjR4+n+/Qz28DFvITU+0uY3ZkEpFpHSprbnZnaS6uNAJ1kSWnQLI1cpZGdckxJtf2FzjlhdNx5lm90dIsGBzdotXFqZXuZxozwlJRFXZz9sS0QRbgIFtifjZrTYbvMFVEfjr++LEQYQhRBSl7ipdr2Z5n4/fv35xdPEUd9MKmWhjCMtNQTP8Y6MMJpG+JzbGxMW7duzaPmg4ON34RLvqXY7bffPrXvljZRL4z6ICaPHDkSfNKFeMQo+zJsicel/qQnvLS1xC2mTpRD+tkuZROGsb7Tp98957pGPpsJmIAJmIAJrDQBC9F5iJ84capKp4iLd72RvCzjn23S/H1kaf642eUsZ7lR/ZZTrvOawGIIsB8ulF6aPibq0+PH6JgjKnbs2KbNmzdNJ16oYMc3JMDIIKOFjDbCGbEiTYu9RplJj5U0+DGWi4sfY/vhIoCk2ubjvMpyfVrqQTqM0UvSlLyS8gitNF0/SVlElzJIS3vYV0ZGRtLNivYIz5j1G92yVd/73vfixIkTuY5wpG1Src5FXL755pvx3HPPZdFKWKk36aVa2llF57TSuXHkLUaeej/L9UacpKkg6lbPeirCHhMwARMwARPoAAEL0Tmg81wob8idIyp3DuYKrw+TlDslJUyauVzCm3HpSDSyRmWQr1F8F8a5Sn1AgP0Oa6YpjPxIyqJCqgkNwiL96KRv3z6mLVs2Ky36r8UEEGxFlEg19ggVjFVJ52KfvV3rl2f765cprxjbFyvLjVxGN4mnTuRhn5CUp2szJRZRx6gjo+WI6yRiz600BbTRrrn687r2mi/Eu6fPBM+hrluzNmKyGmsqA/l5V551rU5MxvPPPhcvPPd8fl6VNJWoMS9VkxSS8rFAOzFJwU+qufgx2BZjuRhh+Ge7Ui0/4RhpbCZgAiZgAibQaQKVTleg29Z/5Mix/J1Q6kXHBxfj4o3hx/Bj+OczSbljMV+8w02gOwi0rhYLHROz10RnG5NqnXIEB2kQF9u2jQq/rX0EBgcH8801ntlk2yHspNq2kJrHT95Sy3o/25PlgbMvHcIvnVsu6y35y5tyyct0VsJLfkZKCUegJtEZTL9FUKd2nFsoGVfIeHFREsL5UzO0kdXiln0bF8Z/+MMf4tVXX81iM6UX1xiMtBj5MElT1w5JBGUjDcZCcfFjZbnexY9JyuVRj8KSPDYTMAETMAET6CQBC9Gz9M+cea968OChKp0FSfltiFzAi0Xdj7C6xY56l1sXpdovx1L2jv7R/kbW0cqthpVrnrcONxlOx5jtR2dcUiBAeRnRyMgwu2V/E+yC1g0PbdL5687LI3iM4g2okkfyGNljmY1QLCnWKP7iRvqx/ZKT/2b72b6S8vlUqrlMny1iSJopehGYCLUPPvggJNYS+RMvCFDyID737NkjBOimTd0zVXt0dDRP0ZWUP9dS2s1+DROENm1jFJeXFzFVN9JvbGyr4EFcySMp8JNHqjGQam6c/VHmWW/aLLXnq8vybBfhTpikXO6wX/QV/pmACZiACXQHgUp3VKPzteAuPJ0dafqCT0eg8zVbuAb1nZKFUzuFCbSHwFL2QzrJTA+lw84zfnTMN21amef72kOh90rl5UVpRDELGoSSVHtra/32rPfXt3ChcAQWAhJhJSnYxtxowC15JQXbn3JJ/9prr+VnLsv5lxf87N69W636XizraYddeOGF+pM/+ZM4c+ZMvqFC/Wl7aSvLiM6TJ0/G7373u3jllVfyS4OGhjaKGy9bt47kaej4yVfPh/pK09cmlrGSBv9cRjwm1fKyHeZK5zATMAETMAET6ASBSidW2m3rPHToUJ6OSyeIzgIXbjrICFM6SCxTZ0n5Lr0kFnPHjbjlWC6o7t/ssuqislfSVB2kaX+ObOG/2fWYb7mFq5xRlFRr24zAORakWjppbneOLCsaNB+35YaXRmjWN0AXWq5oTdSniQV+C9WzdGw5XjhWKE6qbQvysozhx6TpONJPTo7H+vXnxa5dO3InnLS2lSeQRhrF503Wr18/YwSSbYZJyqNpbG9JUX6zv5MckUbIk/EtT4ztOzHxSTpXTgTLfG85Ca7YsGF9Gjn8OIVX8/q4GUHZGOt7+OGHY+fOnUKAMtpY1tft7pVXXplHRnl5EdOKaQ9tk6aZIcQRoz/72c/itdfeyGJ0dru4GYOA5XpEHMcX1yPc2nEzmfiNJ6a1cmFWwvFj5OOahstMH8L4pAzLHTCv0gRMwARMwATOIbDqheixY8eqdBgk5Y6WVHPpQHBXOvwzgQ4SkJQ7m9LcbgerlldN51dS/m4jnWapNrpF55u4nCj941giPnnzH8uSAqHBs3I50P86ToDnLRGkiCC2H8KnGNsUK8u4iJuFjHOpVNt/KROxm9aRhRRlMB27rE9SujGxPl566aX4zW9+M6dI6zikBSpw4MCBuOGGG/LIKGxoPyISdgjC0mZY/MM//EO8/vqbc7aTzxRt3rxJfLKIt0YjYBkd5jiiTKl2rFHOfMb6SM+IN2Uw+rpA9R3dVwTcGBMwARPobgKrWogiQrlQs4m4WEu1CzsdBS7sdCKkWgdKWppL2bbVS0Ba2n4j1fK1m5zSCpZjHCOpiKmbOCxjknIYx9HsTjPHF0KUUdDwrysJcHMAwch2wiT2kumqSmp4g0SaGc8+wXbnph9i6sILLwxc9g9EGnFlP2G9aRQ0GDF85pln5hRp0zXpPl8Sfbrjjjv0hS98YUqM0k4Y0Eb8MGV5YEDx13/9/yUx+vqC7USUptFk8SZpjp29e3dreHgoiqVR1ChWwnARoEz37T5SrpEJ9CkBN8sETKBpAqtWiCJCeSEGHQKmL9FB4I41RgdBUu5Ih38msEoJcBw003Q61ggJjDwcS9zY4bjC5ZhCgOASt3v3zjzK00zZTtM5Ajw7iujBmNLJ9qQ2bOdibPtGVrY54jKVF7xoaPv27Yg0XXnllXlUVKrdACznYm4Oki+J4fh//+//xeHDhxcUadSr2+yLX/xiXHHFFcE0XEZ9JeUqcgxwXEi10V+4/sVf/MXUM6M5UZP/EL3FmF4927rphU5NNsnJTMAETGBJBJypNwmsSiF69OjR6rvvvjtji5WOlaSgY4AxXWxGIi+YwCoggJjEmmmqpPycH8cPeehkIyikWjgihXJwGQFjdIZlW28RYJooU0R37tyuPXt2ZUsiJwtLxGUjKy8ZQjDVt/qSSy4JxCb7BsIMl30IP98FRbwhXhFp9fl6xZ/qri/f8qW44rOXx0cffBh8V7QS6foysCbGP/4kf0+Um6G0c/PmzUE7n3vuuZ4U3b2yTVxPEzABEzCBlhJYdmGVZZfQYwUcP368+v7770/Vmo5PMUn5MwN0piP9CE+O/0ygYwQkhTS/tbpiS9nnJeXZAxw3mKT8FlRGtRCl3NQZGRkJhEz41zcElvu84aWXXqprrrkm38goUBCh+LmxgZ+RVPaj//2//3dPCrSh4U368pe/HBdffHGU6w7ik+OsmKR8/GzdujX+8gTlmfgAABAASURBVC//Mh599NGebGv4ZwImYAImYAKLJLCqhOiZM2eqfJ6AznL9aKc0s6NPJ4jnlugAzcnTgSZgApkAb03lTam8ERXDTxj+Sjq7nHfe2ti2bVSMqOUM/mcCdQSYusqzlJxzEZ5EIdA4P3Oe5jw8PDycn7X8u7/7u54UaJs2D+vGG28MRoC5/tBO2rh27dosQGkjo8G0lxFiXmD04IMP9mRb2X42EzABEzABE2iWQOoqNpu0t9MhQt9777184acDQGu48NMhwFjGpUOAAKVjRJitewi4Ju0lwP6/2DVwvJR8uBw3hDESiphIIkKLLdPpVw8Bnmm86qqrYv/+/Xnkn/2GqaqS8vOjiDb2KUZGX3nllfj5z3/ekwJtdNuYbr755rjooovyxuUYQYDSXgJweY4al9kDP/nJT+JXv/pVT7aV9thMwARMwARMoBkCq0aIfvDRhzEZ1dBAJSaqkzE+ORHV1EUmDEu9oFAawpmspjTJrQwMxMRkjgniopISz2XR+CcpZZ/f6LxjjUuZjiVtvU3HzO0raSO1a06bO9tUqDR/3SVNpVuqp9RvPnep5TabT9VKzGmpAFq3kM1X7xKeimn4V02xjYz9sZFVI+3HDSw0GfU2Iz37RKRfYhDJFAMx29atW5enq0f6Scp+buTQYY70w49YSN48HZfwHTt2aHR0VGl0B3xE2UxgXgI7d+4Unzvh8yRMW62k8y/Hj1QTo/gxbmw8+eSTcdddd3HIzFtet0aMbN2iG266MS686FNRrkGIUUmBCKXeCFTanwR63HPPPZFGR6snT57syfbSHpsJmIAJmIAJNCJQaRTZL3HHThyvcsGnM8OFXlIeGcUfTfzI10QyJzGB3iKASE0CtFGleYMpI1J0jqXpZz85JhCdHEPl2OIFM7yYplF5jmuWwOpKd+GFF4q3zPJCqzIjpexjkJAUkqKI0V6dusrxwVTkz372s7k9HFdM1+U4kqYFKcccwvyxxx5DeAdveYeDzQRMwARMwAT6iUClnxozV1uOnzyRnwvlQk88Lh0cSSw2NGk6DXmwhhkcuWgCknKHTJrbXXSBqyyDNDc3qRa+ZByI1GTleKnf9/HTUUaAEs+IKJ3mzZs3a8nrc8ZVT+Cyyy7L01cRZ+xf7FeS8k1DbnpICqbtEve73/0ukkhr/UhhtP/H52suv/zyuPTSS4MbPRxPHEcIcGYY4JdqN32YkvzEE0/Eb37zm+Bt7+2vnddgAiZgAiZgAitHoLJyq1r5NZ1+90yVqV5c6EtHhos8HRnC6PDMVStJWRzNFUc+bK64bgvrlXp2GzfXZ5oAx4ik6YDkY78qxggWHetNmzbNTJTS+a83CZw6dapjAu/qq6/Wddddl6eAc56GIPsaNz04h3P+Lu79998fTz/9dMfqSt2WakxHZmSUt+mWY4z20lYEKeUiSpllgPh+/vnnsxg9ePBgT7aX9jQyx5mACZiACaxOAn0tRHldPhd27qxzsWcT40q1u83SuX1n6dww8s02ysVmh3fDMvXCuqEurkNvE5CUR6Q4btin6CxH+q1btyY2bryA70A2d8CkPP7rfgKnT5+uMgKH26na3njjjfrc5z4XiE+enUR4YohQ9j9JWajy8rn77rsvevXbm2NjY7rlllvy23S5YUobaS/HGf5IP8LXrFmTv22NGL333nvjrbfeshhNbPy3bAIuwARMwAQ6TqDS8Rq0qQLHzj4XSgdaqglPOjJc4LmwS7WwhVZPpwBbKF23xPdSXbuFmesxPwGOH2IRAOxbZZSGTrSn4kKmv0xSvPvuu/HHP/6xow279dZbdeDAgeD5SQQp+x77IudvKsYyo/FHjx4NxNmLL77Yk+KMF3rxNt3LLrssf2e0HGeMiuLnWoU4lRS095lnnskvMXr11Vd7sr1sO5sJrG4Cbr0JmEA9gb4UoohQnr2RlKfYIkDpuGBc3AFAh4Zl/MUkFe85Lmmx2RGENbLZ6b3cWwQabVvieqs1DWqrmW/XLSlpI8cP3wVlFJRvgm7e7Gm4hU+/uYODg9qzZ0+89tprHW8aLy/ipT5pdDaPynPuRpRKCvZLBBrPUL7xxhvx4IMPRi+L0S996UvBVF2Ed7k2IUI59piay8ag/fhfeOGFeOihh8JiFCo2EzABE2iCgJN0LYG+E6KnzpzOz4VyR5kLOhdvrGwBwrm4c3cdK+HS/CK0pOl2l85Zt9fR9esyAgjQBlWis080HeCtW7f2/kFCY2wNCYyOjuaX6HR6yivPHZfRQsSopPzWXCrPuY436HJu51MniLMHHnigZ6etcmzxCZs77rgjzpw5E0WEMgOBa5akLMY5DhHfzz77bNx1113xyiuveGQ0/DMBEzABE+hGAs3UqdJMol5Kwx1lBCYXcjopkvKoKG0o4XRiuLgThknCmWGScj5ppjsjUVqQZsZLM5dTkoZ/Ui19SUTd6q2EN+NKtbKk5t35ypVqZZS6zJeu38OlGgdpae5K8GEbSbVRIqnmlvVyPDCKxM0XwkjLcVGM5WpMEJWtHCOSgjTnn78uNmxYHyMjIwr/VgUBXj7FqCjPJHa6wex3P/zhD7Vv374s0NiXy2wX9l32a1wE20svvRS8wOjw4cM9Kc5o66233qqvfe1rwfOvHH+0T1L+Ri/HJm2VlJ+RPXjwYNx5550Wo+GfCZiACZhArxLoKyF65NjRKhdvLtgYF+1mNkyz6ZopK8KpTKDzBKSabmTUiE46N2aYIYDh5/jApFo6jgFJecojN2kkBW/s5LuHjEx1vkWuwUoSQPixvjTy1hWi7hvf+EZQJ55flZRvEnKuZ39GrDFSuHHjxuBFS0xbPXHiRFfUG4aLtTQKnMVouYnE8UgbKYcZCpKCUVGWEaO//e1vmUrds+2lHTYTMAETMIHVSaBvhOiJUyenvhcqKd9BlrQ6t+pqbLXbPCcBSVlc0pGl447gJCEiFCNcUu7Y0+FlxIlwngUdGRkWaW2rjwCfF9m1a1fwcpzTp093XOTwYixGCtNobX6BEfsx+y77NG7ZQgg0nhd97LHHGEHteL1LvRbr3nTTTfr2t7+d28pxyc0j2skLizhGEaTcZEKIv/322/HTn/40XnjhhZ5t72L5OL0JmIAJmEB/EOgLIVqeC2WTcGGe3TkhfCGjY1OfZvZyfVw7/ZL7/u3kO7vsTm3n2fVo1zIdWIQl7aQjS6e2HB8sS7UpuHRuqUNtFHS06Z2QPLb+JHDxxRfnZxXTqGhXNJDnKBFng4ODeeqqVLvJwmgo+ziVxGWZKbpPP/00QT1r1157rX70ox/lz9gwHZnjlSm7kvKNI5YRoxs2bIhTp07FL37xi3j++ectRnt2i7viJmACJrD6CPSFEOVba3Sw6XRLtc4JHW9sOZt0ufmbWbekZpI5TRsJsJ2xNq6irUVL8+9DdFZZOR30YpJyR1aqiVDaTod29+6d2rJls0hv62oCK1K54eFhXXXVVflTLt0icJgq/oMf/CAQX0WUce7nRkq5wcLNSAD98pe/ZES3p4XZFVdcof/0n/5Tfl6b9jHNXqodoizTTmzTpk1ZsP7rv/6rxShAbCZgAiZgAj1BoOeFKJ9qoSMi1S7OdKohT6cb/0JG2mKkLf6VdKVa3cs6pZnLJdxuewl0avsvp1XSzH1FmrlMZ5V2cTxgkvK0dY4Z4ui082zd9u1jMzMup1LO2zcE9u/fr2Tx+OOPR7e8BIhpw0zT5cYjz1HW79+AJ5yRffZ3pqy+/vrrLRKjlL7ydumll+qHP/xhFqOMjNIujlvaiUuNOJ6Ztisp/vEf/zHSKHZPt5k22UzABEzABPqfQE8L0VOnTlW5MEvKr7Zn9AeL9JOU3ywY/jUkQCeukTXM3AWRjepOXLuryDoaWbvXv1D5pdOKS1o6rBh1lhQ7d27XZn8XFDS2eQjceOONYjosYnSeJCsefNlll+lP//RPszhjf2b/RpQxss8MGa4LjB4yavrP//zPcfLkyZ4WZpdffnkeGUV80jaA016OY9rJMhx4RpZthRh95JFHerrNtCmb/5mACZiACfQtgZ4WolyQGdWhEyIpv5SFLcXFGeOizXIvmuQBqk5sN/abTqy3Xevk+CjGTRpJwTN0fHtx985d3snaBb7Pyr3yyivj0KFDvJW2a8TNgQMH9K1vfSsQnhy3TM9lH0eMgp8wpvBS77/9278lqKftU5/6lP7sz/4sGPlEdEqaugHLNZDrHe2n3cPDw/Ev//Iv8eSTT3bN9gr/eoqAK2sCJmACK0GgshIracc6Dh0+Wv3gw4+nLsRcfKVav1qqueViLSmn42I92xQDkS2lkWr5Ys7fZAqdy1LwMv6oN7aMIprKSm9kLgva3ITNlbcVYU1VvkEiSakJ81uDrLWolD8VEPW2mHbV55vLv1BZERyCjSxm/CSl1dRZWkEllEpRDKgS1YnJ7BK2pjIQ561dF7gxWQ2M5Z3bd2jzpmGFfybQJIHdu3frhhtuiLvvvjtefPHFtDM1mbHNyS67/LPxtW98PT78+KOYqE7GZKSqVRTnX7A+LxM2PLI5nnvh+fjHf/6nFNnmCrW5+AsvvDC/wGjLli1ZgEvTN2AHBgaC65ukkJjtsDP+7//9v3Hvvff2fLvbjNXFm0C3EHA9TGDVEaj0coslNV39lRB7TVemyYRS8+1rskgn63ECs/djSbnzGelHHKOf3IDBLylPXSwjRUzbGxsb806VWPlv8QQuueQSffnLX0bYxFtvvdUV4mZww0ZdfvnlcdNNN+UZMYwIYnxvdN26dVON3LZtW9x1113x+4cf6op6T1VsCZ59+/aJ76ru3bs3+IwLRXDc1xvnAI57nu/92c9+Fg8++GDPt5t22kzABEyg9QRcYicJ9KQQPXzkWFVSvuurODuiOY8b1dTEs1adVNQvZ3/4ZwLdSKCMvp9bN0QmRgxu6YDiZ1SEKXrEEU4Yy0xR5FuMhNtMYKkErrzySl166aVZjJ44caIrxA2j+1dffXUcOHAgXxMQojw3yf6PKynfkGEU8e///u/j1ddf64p6L3UbkG/Pnj264447YufOnblttBXxiUubGRnFlRSIcF7a9G//9m89327abjMBEzABE+gDAmebkFTaWV+POCdOnq5ysaWzISVhucx601FfZhHLyi4pd54kLascZ159BNh3MVpOxxMRikm16XocIzxPljqi2rRpk3cwQNmWTSCNPopnEO+55x6+X9kV4mbL5hHdcsstwQgggozjgf2/GM9Fn70Zk98qu2wIXVDA9u3bddttt0USpfnFfLSZ8wHXR6l2DqCa3IgaHR0Nvq169913d8X2ol42EzABEzABE+g5Ifr+++/nqYjlYrvYTciFenYewrDZ4W1YblikpCxKGyZy5KoiwH5ZbEbDlUZMk9H5ZOQDkxR0wjE6n3zCYmRkRDPyecEEWkDg61//ujgHJ2HTgtJaU8S20THdeOONeZSQF9lxTHAsUDrHCcYbZZk5ZD4JAAAQAElEQVTO+nf/8Pd9IcjSiKi+8pWvTAlw2sqUXAR4fds5H/CZpt/97nfxm9/8pi/aTlttJmACJmACvU2gp4TokaPHU5+8Glxk6VQsFX0qJD9PNDs/4bPDOrEsKQtSSZ1YfR+usz+axP6J1beG44Djgc4nJil4FjSNgDBq5R2oHpb9LSXAaByCL4nRrhE2F+7bry9+8YvBNFyOB44PGo0fYYoI5QbN66+/Hnffe0/X1Js6LtWYcs9o8Kc//empZ0Y5T2DMkMDFKJ9lPsPDNN3Tp0/3Rftpl80ETMAETKA3CfSUEKXTQ8eCO/G4y0VeLs7LLcf5+5cA+0gja13L0whn1NusktPoZ5y1akxM3UjhWKCTzehHGfXomlHQWU3wYn8RGB4e1u233x5vv/02LwLqGlFz2WcO6NprvhCbNw3nN0YPqJLdyfGJ/HbptQNrIiar8fijj8Xzzz/fNfWOZfw45hkN/vznPx/l2sh5i/MDJimHI8I5Tzz88MPB6OiZM2f6ov3hnwmYgAmYQE8S6BkhevTYiSp3c7moFrdccFtJnot3K8tbqCzJg1YLMXL83ATYVxGgxPIMHM+CDg4OeocCyCq2lWw6Aog3uB4+fDh+/etfd42oufbaa3XNNddkFJLyDBMWeJMuMwgYHeVawnOuqe5dU2/quFRjZDS1O3hxE+cFro+0lfMEZUq150a5frL86KOPxkMPPRTHjx/vi/bTJpsJmIAJmEBvEegZIcqzoVxUpVqngourpAVpS8qdEKl5d8FCUwLWjyVvwz9JOZ5OgaT8hsP6dtAZIgGdAww/8Vij8onDSN9Ok9SQXzvX3Q1lS+1tf7U6EZOT48km8ygn+wn7gaTc/Goa/VSlmkczpFpYjkj/2EfoUPPsF1NxU5D/TGDFCTAyeuutt8bp06fjl7/8ZdeImuuuu06f+9znpo4rzpeS8rEGJEYG+czLAw88wOJyrSvycyPqS1/6Un5xEzOIaDPnFM4VuCxzzUGQc55BiD722GNd89KproDoSpiACZiACawYgZ4QosdPnKpyEYUKLhdV/L1g3Jnm4k+dcen8YNSdZdoj1TpHpCFcUhZ/+OczSfNFObyHCNAZxNgPMKrOfoGxPxCHn84jLlbCeQsoo6B+Iy7UbJ0kwPdpeWkONwx/9rOfVZMo7QpBescdd+iSSy4Jpq9zfHE+hhPHFcuS4o033ohues6V+i3XeF70q1/9am43z8VSHgw4d9Bu/EzTRZAiRh955BFuJHTFNqOuzZtTmoAJmIAJ9DKBnhCidG64eNIJx+ViKinf6Y6gCcux9m4+SXkF1Jn60wGSlO/KS8ojXZF+xJU0Ui1PCm74JzWXrmEhjuwoAUlTNx1m7AOMgg7UqiYp7+t0oknDNFxeSDQyvFm1FP5vAp0nMDQ0pO9///tiH/3FL34Rx44d6wphc8MNN8To6Gh+kY80fchwHDGjgJs8zz//fN88L8qewLbgm6/f/OY3sxhl5JdrJ+cQrjP4i0CFAWKUacrd8m1Y2mDrYgKumgmYgAm0iAAKrkVFtacYRkO5cNK5wVjLbJewTlmpy3zrl5SFBhd+jI4AHQBJwTceCSNvaSN+TBKOrc8J0Amut7IfSMrfBmQZYz9jX2GfGds6qk2DQ95Bwr9uJMBLc3hr7Z133hnvvPNOx8VoEqHiOVZGADn3cixxTHHc4UeIffDBB8Ezk4cOHep4fVu5TT/zmc/oT/7kT/K5BDHKbBzajtF21sU1ifA//OEP+VujhNlMwAS6j4BrZAL9SKDrhSijoVwkuXCyAbh4SrU+OH7COm3UA2tUD0ZCieeiL9VEKHfkCWtkUq2tjdJ0c5ykLMSlud1urvtK1I39gX1bqvFhnexLdJIx/MSz/+RnQbdsFWlsJtCtBHhpzu233649e/bEz372s3j99dc7Lu6YOvytb30reG4SbuW44uYO01S5xiQRGrxNlvh+sksvvVQ/+MEP8uwbrqdMx6XdGOcWSfkcjSB/6qmn4ic/+UnXTK3up+3gtpiACfQkAVe6zQS6WoieOnWqSkedTjgcpNrLfqTaVEXCusno3Myuj1SrK6KCiz6dgE2bNuVvPXJ3njDy0CmQhDdbfVmSckchR/hf3xGQlEcs6Ayzr7Pt2V/oIEu1mxaDg4N8jkLhnwn0CIE0Mio+J3LXXXfFCy+80HExum/fPn3ta1/jLbFTBCUF52QCOP5eeumluO+++zpeV+rTSvvUpz41JUZPnz49VbRUaz/XIUn5OvPMM88E03SnEtljAiZgAiZgAm0iUJmz3C4JZLoUAo1OOS5GJx2jipJwutok5Ys7dee5vu3bRjW48QIhMmgfHQAaICnfsZZqwjX65Me2amR90swlNwPhibF/SIrQZPCWXMIYoWCfYSru0EZ/liX86zkCV111lfikyN133x1PPvlkxwVeEsb5sy5MU+W6Um504iJEOVchxF5++eWO17XVG/uiiy7iGd7gvMLIMOcYrj/1fuJg8MQTT8RPf/pTj4y2eiO4PBMwARMwgRkEulqIItboHNBJ4KIp1UQaF0qMzvuM1nTBAvWqr0apO88njWzelJRGxOkz71XpCNEJwMhDWzDysozhrzcpZ68Psr/HCbB/l+1evy8wSoMI9QuJenwDu/px4MAB3XTTTXna6/33399xgfed73xHaXQ0uBHIdaVcZzjn8rjEe++9l58XPXjwYMfr2urd55JLLsnPjCI4z5w5k2+Scg6i7bBAnJdzT3mBUavr4PJMwARMwARMoBDoWiH6zqEj1fGJan67LB31iYmJ7OdiyTJW67hPBN9ijJhMbTrXpGq62M5vKVPDP2la/EmaMWqJyBTrraY6TI7HQKK5bu1AVFhnCsfdNDQU28a2amhww1RBH7z/flQnJ1P6SvCjHXSGKI8OgaRUZxEVLNdbDkz/psOU0tRbNS1PW0o68y+NuDHq1qzxHct6m52P7TFzBa1ZKu1bqLSSbj53ofwR0VyS+bg1kXu+uhE+Mf5xjH/yUbYq+5Aqsf6882N0y1Zt3jRc2wmaWIeTmEA3E7jssst02223xauvvhr33ntvtdN1/fa3v51HBrmuSLXDTOI8Wg3OaWlENJ5++ulOV7Mt67/44ov1ox/9KLg5ymhopVLJ11auP6yQ89Jkuj7xeShe4PTjH/+449uLetlMwARMwAT6j0Clm5sk1ToIC9VRai7dQuXMFc8FGePijJFGUnDxpsNCHLZ27dosHj/88MPggi4puLs+NLRxRuWOHDlWRXRSFhYNftKMrDNSSvPHzUjY4oXZdabtLV5FLk7qTPvyylv4j/2E4uCE4ZeUO7tlJEKqtZW0vBV3eHg1CNDwb5UR2L9/v26//fZ47bXX4uc//3lHp31u2rRJf/qnfxqMCiJG2RTF5RyHSHvsscfi2Wef7UsRtnfvXv3whz/MYpQXGHH94noFB85DXNtwE6c8ks0LjIizmYAJmIAJmEArCVRaWVgry6IzINU66I3KlRZO0yj/QnGIB+qClbSSshDlQs0FHPGAuKQjw7Kk/DIi3h4ZdT9EKHegCUKEkB8/Js1shzRzmTSzTVIWv9L87uw8rViGBUZZknDaYtLCZUtqyKAtFVtEoew/dOrqt7ekXAL7C/sAaegEbt++XanjV4vMKfzPBFpMoMPFsY9/73vfCx5N4I26J0+e7JjQ27dvn77yla/EqVOnpmaRcBORY1KqjY4+8MAD8fbbb3esju3cXHv27BEjw1u3bg2mI3MNo+2crzi/47KcrmPx+9//njcg9yWHdjJ22SZgAiZgAo0JdKUQPX78eLoOVrPYa1z99sdyIcakmj5IFcvTmHAl5Try9luEBmGk3bVr1zmC4ujR41VEqKQ8JYx0pI8O/lj/QtaoeuRtFO+4yPtH4cQ2Zz+RFIhQOr3E7d69W6kzKPMygdVAYHBwkKmhnCPjb//2bzv6rdFrr71WBw4cyCOjPBvJ8ck24LiUlEdvEWHHjh1blgijzG40nhn9+te/HukGQSBEEZ+0nbrCA1dSjI2N5Tfp/upXv+pLDrTTZgImYAImsPIEulKIckHkYigtr28u1e5qU9Z8JqnhiBrioRibh9ErrJTHnX1JeTou07nSBVukq7eTJ0/n6biUUzo6iBCMdNLMLNL0sjTtJ+25NpmC6i0tzvVXnnFMcaXuybvgX0mLO1fi+cLnSrsaw+CD0Xaptp9w44J9YWhoKHbu3LnQBiarzQT6jsA3vvENXXzxxfE3f/M3Hf3W6A9/+ENt27Yt0ujsjBtEkqI8J8mzrX23Ac42iCnTjIwiRnm0hPMV1ympdv0s/h07dgRvP+4hMXq2hXZMwARMwAS6lUBXClFGiwAmLa2PLimLS8pYrkm1siTlorhIF5OUv0HHMqNamzdvriXKKWv/GAnl7Yyk4W4zAgQ/sfilc7IQNcMktaw9Zd1lBSw3spIOt6TDXwxRXvx2zyUAH7YzMdxg4eYDIw07to9peJM/yQIX2+olcNttt+mGG26If/7nf47nnnuuY6Nt3/jGN/Jz29wk4vrDuY7jtpyz77333o6O3LZ7D0lCPE9TRowyc4fzFCxggLF+HjsZHR3lO6uMjnZsW1EXWzcTcN1MwARMoHkCleaTrkzKEydOpD5A7RqXPCuz0gZroQ7F6pNxccb4xAZTcevjiv/MmTNVRCgXdcpAlGCS8pRN8sesn6RZIctcrBsJXWZJU9lpS1TTrpNManF9p9bSHx5JeSo3nVu29+DgYPAt2f5onVthAssncN111+nmm2+OX//61/HUU0/VTv7LL3ZRJaTRvlwHRgQRn9w04phFlHHMHj58OD8nyfVpUQX3UGKeGf3qV78a6XqWZ/hIys/OwoBmcN7nJtrIyEj88pe/jAcffLAj24q62EzABGYR8KIJ9CiBpCa6q+aINmrERQ93sSZpsVkapkc4UpdiJJaUhSQdlnRRnnOFp06dqjJtF/FBukg/2oaVsvCn4Kb/pDlX1XR+1tt04g4klJbXvg5UecFVso0xOnC7dm7XyOZN/dfIBSk4gQk0JnD11Vfrm9/8Zvzbv/0b0z87InAuu+yyuPzyy/PzoohQzv1MS8VN5/ngu5pvv/1244b0eOzOnTt16623xv79+/M0Za5djITSLMQ5LmGMnN5zzz0du3FAPWwmYAIm0GkCXv/yCXSdEKUDIClPRZU01cLZIoplbCrBPB5JU2VJM/2IxFKGNB1HUXQ+qAtpMDokXIAxRMW2sa3aumWzSDvbigilDKmWRFIWr5F+lFviWH+9EV5v9XH4U/YZf4QVmxGRRkKrMTG1Tsos6YpbwshHZ4NnXM8///zMizjCcbGShzCp1ib8rTTW0cryWlEWdZptkjJX9gtVUp/5LOtIbmUgAsM/WR2PgTWKDRvXx9joFoV/JmAC8xK46KKL9P3vfz9/a5TPhZw8ubJv1E0jn3maMCOCjIxKtRFBjnMqzTXgV7/6VRw5ciQd9IT0mSOpNgAAEABJREFUp6X265Zbbom9e/dmUY4Ape1cG6rVasCDMK6DvPn4ySef7Gse/bmV3SoTMAET6A4ClcVXo39ycFGVap2NIrZoHRfagYGB/MyQpPw2wXLh5dm+0a0jDUUFnRjKwCivmNQwW0m2KJd6sh6p1o76zJLyXW1JQUeCtFItXWk7nw3ZuHFjbBsd08jwZm0d2SJe0EGZjOTVl7ca/ZKyMIcH/HBhBxv2CfYbaZovjAjDJT0vJNqyufH+QlqbCZhAMC1U3/3ud/MnVX7605/G0aNHV1Tk8KzkNddck19SxDEu1c7/+HkM4/jx43H//ff3/aZKI555qvIll1ySz39Mz+V8R8M5vyFCJQXilFHs559/fkW3E/WwmYAJmIAJ9D6BSi83QdI51UcknBPYIGAgEcAUkzGXVSfHY82AYv3562KkiWmVBw8ezJ9poR7SufVrUJXGUQ1iWVcZZWUUlNE4khNeqaQGpoXJycksSqvViSRKK7F+/XmxceMFMbZ1VMND504XlZSFeMz6USY2K7hvFyXlEQBJ+Xkp2o7F2d+aykCoGjE5PhETn4xnl7ALzl8fO7Zt1+CGjTqb1I4JmEATBHjp23/8j/9RyY00MhpvvvlmOsKayNiiJFdddZWuvPLKfLxzXh1INyXLeRQx+uijj8Zjjz22onVqUdMWVQyi/KabbuLN3vnaAQMEKYVwPWGZcyFhd911V7zwwgt9z4S220zABEzABFpHoKZSWlde20qSZvbnpdoyF8JGKyW+2HzpJGXRJWnqxTJcaMnHSCIvshgZWXhUCxFaf9eY/FKtnnH2J81cPhu8ZId1YBQgKYsmOgiSQqoZbaFDJSnKCOjWEQTo3FOLuftPO8gXc/zK+uaI6rsgSVMdUhgWJnROmc4MC8JhRhxhY2NjGh4eVt/BcINMYAUJfOtb39KBAwfixz/+cbz88ssrKnI+//nPB89Jch7kWOf4xs/xzfmVUcB+n6LLpkaMMk0XFrx4Dxac7zjvEY8xo+bkyZP5+d5XX311RbcT67eZgAmYgAn0LoFK71Z9uub1F0VCZy8ThhGO4S+GeKj3s0waBCjTjkZHR5sSFHRKeN29pCwGKYOyIv0kZVGYvPlPmrmcA5f6T5PBc4o8i4hJyiWxfowOlKQ8Ajo0tDFGt4ylUbqhWqKc8tx/1BsjRlKuO2XVG3GrwSRNNbO0nwBJmQvbnHCmqtEha3Z/oQzbvAQcYQKZwPXXX5+niN55552xks8ichyndceWLVvivffeyzcquSZwPh0cHAzeovvggw/mOvb7vzJNd9euXcHoJxyk2g062g4T3i9w+vTpYGT0lVdesRgFjM0ETMAETGBBAj0hRCXNaIg0c3lGZBMLCId64w4vRpik/G1QOiKbN29uakWpU1LluVDulnPHWNKUGI26nzSzOElZzEjzu3XZ5/RS5xKBeKRTwJ172sMydWI6GSOggxsaC9BSDmVw15+2lLB6t36d9eH96C9tlZS3KVykWicMvnTKuGHByIFHQcO/nibQnZW/4oor8ptceWttEn8rJnIuvvhiMTLKMc/5lGNdUp6mynP0qS6xWp6N5Hp4xx13xL59+/ILjOr3FM6RXGeYbZNuyOaR0ddee23FtlN9Xew3ARMwARPoLQKVbq+upKaqyMWwPuHs5fq42f6Slo4Gd3a3bt3a3EpTQcePH8/PhCZvvmuOeJOUBSYdGMLbaaXuuAgjjPXRMUCA8hKizZuGRVgzduzE8SqdLupeyqrPx3qw+rB+9sOA9hajrZKyKGVb87mDxewv4Z8JmMCiCXz6058W37h86623VvTzLkwN/uxnP5u/q8kNOs6NVJ5zKy5TdHGXZT2SmfPcrbfemsUo03S5RnAOxGAjKbiGHjp0KPi0yxtvvGEx2iPb1tU0ARMwgU4R6DohSocfGMXFv1SjDGyh/JKysOCO7mJGtY4dO1Y9depUzssFmHVJtbLwc6GOWT+paU04K+fci3QC6o16MEK3fWxbfgPu3LnmD2WqKbGUI7W2rpTba8Z2pPNZDGEq1TpcTMfttfa4vibQqwT27Nmj6667Lk6cOBF33nln9cyZM20XOlwPGBUdGxvLYlRSfo8A50neiP3666/Hvffe2/Z6dMs2Y2T0y1/+coyMjEyNjHJOxGDCDVDqmkRoME2X2UIsd6O5TiZgAiZgAp0n0HVCFPGGpct9YBVVoxjLWHVyPGo2GVFNfYBJRXUiYnK8GtXJyWxB+Bymurfj5kxpG3B3m6mVmzad+/bYFD3nHyL0/fffj/PXbwhV1kQ1KjFZVYxPVLNLGMupdikusk2m+mAzwlJ9J5MheOqtrLRSqYRUE4T18fhJw9taxz/+JLV9Is5buy52bt+h0S3Nj+hSRrFTp9+tTiSGioE8/SzST1Jef6kHLsI3RbX8jzYt1haqhFSrv1RzZ6fn+dpilYEIjOVQ2o9iItasrcTadQOBMB8YGAg6Woya80mWud42HP6ZgAm0jcDu3bv1hS98IcbHx7PQObkC3xrdu3dvnqLLDT7O1ZwHOA/SSJ4XfeCBByKNAlZZXg22Y8cOffvb3+ZTO/kzO7SZ87akfN3gHIkhRn/729/2/XdXab+taQJOaAImYAIzCFRmLHXBAhe0haoh6WySyRiorA06BhhioRgdBamkiykxFWd/xK9bty64qHLX+2xwU066I5+n45KfDNL0eliez6S500lzh1MOPOj8YPgJwyTlNhFOm3lRzpYtW0TcUo1nSyXlcqWau9SyujFfPb9SP/Yb/BMTE7lzi8sy4XSmWIYLnNevXx+MNA9tHBRpbCZgAitPYNeuXbr66qvzzaH77rsvVkKMXnvttSrf1ORcwHkBl+sII4GI0ZUn0bk18gIjnhlNNwbi+PHj6b5vNW8PbhBI6XZvurnK+fPFF18M2Kz092A7R8ZrNoFuJOA6mUD3Eug6IVpQScqCqCzjSsKZYYgLOgXF6BzMSJAWSFNvkoK72zzzkqIX9Xfq1KksQqWZdZFmLi+q0FmJpemyEEFE0+GRFLgIT0lZOCGOGM0dGmruRUQxz4/RUDpUkjJ31jM7qVSLmx3ezmWptk5pbne562Z/oa0IT/YRlkuZ+OlYEcfLSRgFLXF2TcAEOkdgbGwsj4widnhOcyWEDiOxo6OjedSPc3A5b/BIx7PPPrvin5jpHP3amrmJ+81vfjMQo2fOnMnXI6kmQuEjKd8kfuqpp+L3v//9itwwCP9MwARMoFsIuB5NEegqIYrIQwyUmkvT4qOEFVeqxVUGaiGIhiJG691SHoICUUengbu5i5mGW1tD7T+v8mddAwMDgVsLrf2XVPM0+C/NTCPNXJ6dlc5OaUO5uNMW0uUposscBaUcjJdPlPawPklZkBI32yTNDmrJsqS8TmnabUXBtAebryzajcEaxqRjX0GYc8OC6XeLeeET+W0mYALtJZBEoa655ppAjDLqlkbmqu1cIy8mY32cIzhf1LucJ3iLbjvX341lsw0Qo+lmaPCoiqTg3Mk1CpfrLfV+9NFHg7ceJ8Ha1m3EumwmYAImYAK9Q6DVQnRZLefihWDAJM1ZljQzHNHJ83yVJEiznX2mElGBDSTBSLkDA4q9e3drqdNXuYAePHgwX0QpM693zhouHCgpC665UkqaEVzaIE1f4Ol45am4I82/DXdGobMWTp4+Vf1k/KOofzZS0rx1JHs1JgKjQ8Zytxr7UqO6UX9MUr57jx8BKilgPLZ1VIMbNir8MwET6DoCnM9vueWW/MktnkfksYl2VvLzn/+89u7dm8+NXAc4F0vKYphnIpPYyteIdtah28rmxu53v/vdQIxyoxYukvLsHa69CHZJWYg+8sgj4Z8JmIAJmIAJFAJdKUSpnKR8scePScLJJk37EYSIDQQbRgKWERS4LA8PD/NihelMBC7SuNtLmVKtGKnmzi5Gmjt8djqWpYXTSsrP33BBJw+joGOjWzS48YK6zMQs3T766KO8jsKPkgo7SXk7SCL4HCMd2wA2GMskkpQ7ItHlP+pOuzEYs8xd/F07dmpkePPcje7yNrl6JrCaCAwODurrX/+6EIW//vWv2970W2+9NQvfcr6Taudopu8/8cQTq3IKapmmOzY2lkdGEaMY51WpJtTZMHzWZTWKddpuMwETMAETOJdAVwlRRECpoqQsgMoyriScGcbdVowLHiKIMhAUJCJ8x45t2rRp6S+XYST0nXfeqdLpoKMj1Tod0lk3rYha1VslxdUvN+ufKx9hE+PjsWZgIHbv2qGRzc2/2TdVbcG/o8eP5bbBCn5kgCUcyzJhUa2EYiAb/mKwJh15Sscj0o+wYmmxK/+o35pKalMaw+DtwwOqxNDGwfxCoqYq7EQmYAJdQ+C2227Lsxr+6Z/+qXr69Ol0VLenamnkL79Fl5kT5bzH+ZO1nTp1KhCj+FebMXX5G9/4Rh4ZLTduuW5iXDuxgXQd++lPfxovvfRS27bPauPu9pqACZhALxOodFPluWAhDpqpk6ScjDwYwgmXwDyilUTbtm2jtUQELtFShybnpMOBhw6HpPzCCmn+4qX54yinWePZTUZBEdTN5llMOkZDSU8HofCjrWwHjLhGBo+Svj4dedkmhOHH7SYrdcKl3bwBmbv6afS8NRuumxrbZ3Vxc0xgLgKMjP7gBz8QzybyAqO50rQq7Etf+lK6wbkpihjlhpykLIR5cdHbb7+9KoXW3r17xTOjmzZtCq4tnF+5tkjK05e5NrP8l3/5l/Hmm2+uSkbhnwmYgAmYwBSBrhGivIKfCxTCBpcLGBf3qZqe9Ui1kUhEDvGICDoeLHOR27Nnl1ohQFndW2+9VS0ii/WwDtZJ3QiXFFLNSD/bJOUXGpGeOGk6bSmPcPwY6XAx1oXt379XW7a0Z4oob5qs5D1gMtcT7qU++GljGfkknPph+IuRRlJepN5YSSPVwokkbC4jrhVWXzblScrbptSH+OInHmNZUiD0l/IGZcqwmcAqIdAzzfza174W6dwWP/7xj9sqdP7sz/4sv5iH6w/nS87XXIM+/PDDePzxx3uGV6srum/fPn3nO9+JdFMvX1e4ZiJK4SQpYMR1/s///M9X5TTmVvN2eSZgAibQywQq3VJ5hAKGOMClXlJt5JFlqSYs8GOS8t1nScEnTDZv3hxjY1sVLfoxHXeuolj37PC5wkoaLrj1Yq2ES7WqEk8nhjIwqRZOm3bv3llbKJla7NJxanGRHSlOUt4X4IhJys+8si+xDFcMPyYp2CZ0iDwKGv6ZQF8RSKNxSiOjcfDgwfj5z3/eNjHKeniLLtNxOddwPuG8Asw02hfPPfdcC9ZNab1nF1544ZQY5dwLH651zPBhmbcMcy7+i7/4i95rnGtsAiZgAibQMgJdI0Ql5REsSTMax8WLAEQTFzMu9DxrQjh+XhCBAB0c3DAzI5mWaIcOHapyF3e+7FxIMeKLi38uk2rVIh0mKYsg6o5FMBo5ntpeTeJpIm5i6QAAABAASURBVMVF7Nq1o22joHH2x6cO4Hl2MTmTef3Js8Afu0y9LZC8Q9GSElPlO/J0eDDay36EP78Rd3SLOlQ9r9YETKCNBBCJ3/ve97IYbefLcdLoq4aGhvKNMK4ZjPohSHl77IsvvtjGFnZ/0YjR22+/PbhJzLkXNghQrt0Y52CeJf0//+f/dJ9g7368rqEJmIAJ9AUBFEVXNARxgNXEWZJnkwijahYThGNUlAsaaXhhBKNZm1v88h5EKBdMLpQY65zPEJbzxZVwhA9GvQmTlNskicX8jFH2pH+MgvIq/ORt6x/ToJk+ttBKmmnfQmW0O15SEtDV/MwuHUGMekvKncNIP9izDaTa6Hmr3zqcVuE/EzCBLiPAuRQhxPc9n3zyyWq7qpfEaJw5cyafh7hOlfMPo6LPPvts29bbrva0stxLL71UN954Y378oZybKR9GPJePGD127Fj8/d///armBBNbhBmYgAmsPgJdI0RBXwQDooELFWEYfsQnd1MRn+16nu/IkSNV1i3VxA3rZN3FqMtijHy0iTySsgDFX8JLHOvZvXt3GgVdmRG6Mj2KuhSjTjX/ZHImc6cqebr+T1KuI/WHZ70RhpGATs/OHdta/tZhyraZgAl0JwGeV/z2t78dv/zlL+OFF15oi9g5cOCA9u7dm1/Og9jiGsJz5zwX+dJLL3UnmBWs1VVXXaUvfelLwfWb8zE3eKXaNVaqfa85bZv4zW9+05bts4JN9apMoBcJuM4m0FECXSVECwmEGdNvEQ/cYeaiPjo6qs2bN9dUR0nYQpepqnQiuFBKtYskI6P1qyAOqw+by08ajDhJQXswqVZuiSOMizPiOlbox4gvYo11l3q0c9WSsgCX5nZbsW7agrGv4FImbaNDyD6Up297Gi5YbCaw6ggwRRQx+i//8i/BC+jaAYBPx0i1cxzXLt6my/nojTfeiGeeeWbVC6xrrrlGt9xySx4Z5dyMca6WlK+PjIw+8sgj8eijj656VuGfCZjAKiDgJhYCXSNEefU+U1MRDdjY2JgY+dyyZYuIKxVuh3vs2LEqHQfK5gKJScrTPQmbbcRjs8PnW5ZqHRTiyccFmOeIuPjSRsJXwmgn4lqq1Ye6sN5qdQJnykr4VECXe0p9JeXpuNxxpzMI47EkQIc3DSr8MwETWLUEPvOZz+RRub/5m79py5taeVQkjfwFz4by3CPnH85L+BkVPXXq1KoXWNdee23+/ipc4MMNUXZIbhhKtbeX89mdF198cdWzgovNBEzABFYDgRUVogsB5QUTWLuFZ309eDsuI6FcFLkgIhKJx88dbfzzGRfU2XGzw1iuN9JT7sjIsIaGNq6oQCpimzpQJ9qKG1G/G+DHSNX9Rv0xth+uVPteHTc1tm5p3wh695NxDU3ABOoJXHfddbr00kvjZz/7Gc90tlzsJKEV3FzkPMT5iPM8gitdY/JLk+rrslr9N954o2644YapdyPASNLUrBmW77zzTn9jdLXuIG63CZjAqiPQO4qjDZvm6NHj1fGJanwyPhmTVUVoILtVhNlZP2GNTKq97XZi4pM0gvpJREymi2o1+D4ncViJGxhQbN8+pnZ9FzStfK6/HPbWwbern0yMx5p1a6OyZiCiohifnEh1HZhpMZCi1sRAZW02pdzZqpWoEBdKbp0p+RtYzhuRck1bVFMf8KzNjq/MKmvNwEBgA5VKLoO8ish+3OrkeEQa0V2T2K5bOxDnn7c2tiSRP7jxAqLDPxMwARMoBL71rW+JG48PPPBACWqZOzQ0pJtuuimLrHLTD2F1+vTpePXVVyO56cTXstX1bEGIUTgxOwfRzg3RiYmJ/H3R888/P/O7++6748SJE+bVs1vZFTcBEzCB5ghUmkvWf6lOnDhVbebNsQu1nE4NF1NJwQVVqumfybNv/cVlqigjdKOjo7XIWNnfkWNHq6UekgI/tnbt2umKJKEZ2NkQ2nTWu6LO7PWyDGM6KpJCUhL8E0mPVoNOXmGOy1Tc4eFhrWiF512ZI0zABLqRAM+LMl324YcfbrnQufrqq1VeXETbOcdy/n/llVfi2LFjBNkSgc985jORBGkWnbzUifM3whSD2cmTJwMxavGeYPnPBEzABPqYwKoUoidPnq6+++67WZAttG0RQth86aT5dU8Re4jQkZGR+RPOV3gLws+8926Vt+RSFBf7+rawTPh8Vp92vjSLDW+mTNJglE3HBBdDjOLyAiLqzo0ESQFfnilmRIJ42yom4KabwAIEOBd//etfj9/97nfx2muvtVyMXnfddfmmJOd/zl/cMDt+/HgeFV2gaqsmmhuGSYiK52q5FnO+hxUApNqlkhc9PfnkkwTZTMAETMAE+pTAqhOip0+/W+WFEmxPOgi4zRgXSmx2WsrAEEbEI5bogLDMCB0vseC519n5VmqZtkqa6hhRv0g/qTaymLxd+wdPOOJi+KXpehe+dGq6thGumAmsAgK91sSLLrpICMb777+/5S8vuuSSS/KzqNwAZDYHbLh5xihsO4Qv5feq3XbbbXk7nDhxIs9y4TxfrlH4n3nmmWjHyHWv8nK9TcAETKDfCKwqIYoIPX36dL7gMf1Hqt15XcxG5eKIlTz4JeUpo4QhQiXlb6at5BtxWfdsY0ou056YGiYpt5s01JF600nCJWwlbK51EVZsrjogPjFJeQSbToqkPAq6bVtnpjrPVU+HmYAJ9BaBJESVbmLFfffd1/KKM9LH846M8nF+42bloUOH4uWXX27luvqirK997Wu68sorg5FRrlU0SlJ+9IJZL4hRv0k3/DMBEzCBviSwqoQoFzq2IsIGQYN/qUbnApNqI3SIOspimijfBe3kKCj1OP3umalnYCVlESppamQUMRpnf7QDO7u4Ys7sdbKM1Veg1FNSrjudO174tMmfZAn/TMAElkfgmmuu4aU4LR9127t3rw4cOMDbeQMxSi05tzEqevDgwZZPB6b8XrY0MhrwOnr0aH4HAMIdUYrLtOYHH3ww3n777S7h1sukXXcTMAET6C4Cq0aIHjx4qIr45OJGhwB/M5uCtNh8aYnDELeIpE6PgpZ6Mi2s1KuIZKkmSKmrpCzsYoV+1KXZVZEWIz11xU+HZMeObR154zD1sJmACfQfAZ4tv/nmm+OJJ56IN954o6VC57LLLot0PQhmpUCORwkQWohRlm3TBLhxy3bYs2dP/hYrMbx5mHM/fkaTH3rooTh8+HBLtxFl23qEgKtpAibQlwRWhRB9553DVS5qiBkubJKiCNJmtyr55kqLyKPcCy64IHgJxlxpVjos3UGeai/rRnRLNRHKCCP1xSQRPWXztXEqQQs9zayLNNQdgT82tnVmZVtYFxdlAiawegns379fvMX1kUceaSmEXbt26XOf+1we4eNcJtVmz7z44otx5MgRC6pZtHmr/Pe///3Yvn17nqZbHp9hlhHXK7g9/vjj/gzOLG5eNIF2EnDZJtBuAn0vRN9++5386RIuasCkQ1DvSpp6vpPwYlItnBE5STkYUUR+LoqS8pSr3bt3q9MvJMqVO/vv5MmTeUoughOj/kV0U3dJ+VlL4lg+my07Uq2deSH9k5TZSHO7lJ2SNfwjjTSdn3XO5FiNanUixsc/zjYx8UkqbzKN1ka2Xbt2aGRkWCnQfyZgAibQFgKMXvJitwcffLDayhXs27ePG5R5VJRzIaLqzTffZJppK1fTN2UxMvrd7343hoaGEJzpmjCehTwN5Nrx2GOPxQsvvMCizQRMwAT6lcCqaldfC1FGBufbmpKyyCrxdBIQmIg2/Fz0imAqoo040jC6Sr40AorTVcbLHagvdaUNy6ncQvkXimfd1KUYPAmDr1QT8sRRDmEYfsLOP//8SHfGRXqbCZiACbSTwObNm8XU0GeffRaR2DIxmoSorrjiivy9TKl2E5B2IKa4aYjfNpPA1q1b9Z3vfCe/8I9pzVwTuDZw7cW95557eOlTy7bRzLV7yQRMwARMYCUJdI8QbXGrjx07lkcGpea0DBc7SVmccrGjOoRhXAARdkzDReidn0TSzh3bNDS4QaTrFkN4lxdj0Aas03WDGXWgLlINF37CEJy48MUlLSMGjDIPDw/XEhNhMwETMIE2E0A07t+/Pxh1a+WqeO5xbGwsj4pyriufcklCtJWr6auyuAnJyCjXX0aqcWkgLst8A/add96xGAWKzQRMwAR6mEBfCtF0ga/ysh6ppmUkZYEpac5NhSDCEEK4XOwkBYIJASopdyIi/dKd8xgb3TJ3QSm+U39nzpyZ+j6qpDyliU7PQvWpj6fd9cv4CSvG8mKNThccSxnFlZRfzw9fuFPX1AnU6Kg/yRL+mYAJdITAxRdfzPOb8fjjj7dM5Fx44YX58yRcW2gU50Rmh/hTLtCY37ge/OAHP8jXYW4Ac+2AHTeCYffUU0/Nn9kxJmACJmACPUGg74QoIvT999/PLyNCAM3eCpKmRKmkHC3VXC50dBAwOg1lmVHGDRs2xN49uzTcpZ8Noc0IOtos1dqTG9fCf/DAFltkYUndEJ7kL2Gw5nmgHTt2tKfSrKz7zDUyARPoQgLMxmAqLSLn0KFDLROjqdxIN9nyDU3Ogxs3bswjrx7Va7wTpBsD+uY3v5nFKI/EcP2RFMycufvuu1t6w6BxTRxrAiZgAibQDgJ9J0QRZIgbSfniJWlKeMY8PzoGjMjhkoSLXTHE3aZNm2J064iI60ZjGjJiGZFX6k17EHuLrS/5F8pDmmILpaXzQD1gW+rE9mGZO9s7d+5U4tu1bBdqn+N7iYDragILE9i3b1/wcjue41w4dXMpGN3jzbwIKEb1eMv6u+++6xfvNIHvs5/9rG677bb8zCjXE64jGCzvuuuuln92p4kqOYkJmIAJmECLCPSVEOUONgKJixTiB389J0lZlNaHlTRSLU5SFrCls7Bv725tGtqo6NLf6dOnq+WFDrS7VFPqjipTJ0QnnBHLbBfYDg4OxmgXTnEu/OyagAm0iECPFcPLchgVfeaZZ1r6Upy9e/dGKjuPinIuREg9+eSTwbP9PYZoxav7hS98QTfddFO+NnNzuFxH0ohy8LyoGa74JvEKTcAETKAlBPpGiB49erTKBQoqUk2ElWXC6k2qxROGQJptiCdG67p5FJS6YzwLiyvV2lREXxl1JK6R0fYlx2uyUdYcR33w0HGAK1PStm0b1WCXveiJOtpMwARMAAK8XIiptC+99BKLLTFGRZMF51zsvPPOi3TzNE6dOtWS8mcX0m/L119/va699tr82TSp9tZ1hD0vl+KZ0X5rr9tjAiZgAquBQM8L0dOn362+887h6gcffJTulq6JgYG1MT4+mQ0/ggwRVK1OP+6Dv9hAIlBRNRSTgXveujWxPQmlbn0WtH6nPH78ZHWimsRgRVFZMxDVpEWx1JDgR9slhTTTiCtWiYFQtRJKAcVSTymKrVmzJnFN8ZVqRBKe1ZiIKUtMubM/OTkekfgpccTlu6BMPNOnAAAQAElEQVTFPvnkoxx3/vnrYseObRoeHmI1Kcx/JmACJtCdBJLA0ac//engcy4vvvhiOvm1pp4IUQQu52ZuzPHuAUb0WlN6/5fy+c9/Pq677rr8ORyuTVzbuWn8i1/8oltGlvt/I7iFJmACJtBCApUWltWRonhmhItR/corlUpwkcct4dK0/pGUxRXxkoJOQaQfz+2kTsJ0whTWzX+l3u2sI2wxhLukzLWwlRRr1w7kMElJu1azRfpJyuEwZRouHbvwzwRMwAR6hMC2bdvSzbMd8dBDDwWPQLSi2nv27NGOHTvyeZLzNyLq9ddfZ2S0ZWK3FfXs1jKGhobyG4gZGeWaxLUJMU8/4N577+3WartebSfgFZiACfQqgUqvVpx6Hzt2Ij8fycUIUUkYhh+TlMWQVBNJUm2ZuEg/8mF0BlLnQL300pwjR45V6chIzetmLtxYanrDP9IUk2rll2UySgpJeLMrKbsljaRg2lnqyGnLli1KQlQ5sf+ZgAmYQI8Q4KYkI5gIxTfeeKNltb744ouDRxR4dISbenyahGdFW7aCPi+I7XL11VcHz/EyKsrjKZs3b46HH344Dh48aEHf59vfzesiAq6KCbSAQKUFZXSkiBMnTlW5AHExpwKIS6kmOFmWFIhMSVkkEU84YQgmSVmkJpHECyQUPfQ7efL01POw9dWWas2Qai5xtLUYy/NZSYNbn4ZlDNFbjGXSSDXGMMUkRkjX5lfrj4x071uGqbvNBEzABBYikEYwIwmf/KmVEydOtETkJHErykWEcv1iRA8heubMmZaUv1Cb+iGeG5yMivImYm4kw5Fr/COPPNIPzXMbTMAETGBeAv0W0ZNC9NSpM3kktF4QSZraNoQjmrg44bKM4cdIWBuxGxVTfVjuJWMaEvXlwosrTbed5cUYXLDZeQjDeAYUjvgx0uEWYxmjLnQIxsbGNDw8vPQKUdhZO3nyZPXll1+uPvvss9VXX33VnbSzXOyYgAmsDAE+L/WpT30q/vjHP8Zrr73WspVedNFFwU1Qzq2SmPrL9NyWlb8aCkKMXn/99YEYpb0Iel5c1KobBpRpMwETMAETaC+BHhGi0xAYDXzvvfeCCzh3lDHpXN2DUGKUDoGEi6DCZSoPzy326ktzeEERbadd0rntniY1vw82xepTlTDcEi4pjxzDDYv0Q8xTB1xJU9NwN2/evLQKpTLn+kPQpg6bDhw4IEYR5krjMBMwARNoJ4Fdu3Zl0cho27Fjx1pyQ+ziiy9Wumk39X4CrmPPPfdcO5vRl2Wn0Wp94QtfCLYRDeT7r7///e/x2kzABEzABHqAQKUH6jhVxTNn3svTcRFAJRBBhnAiDKFZwgnDjyspEFHr16+PsbGt6tVPhzASXEZDS9twmzVYYPXpWS5WH5796R/cMDpKaTFPdyY9y+vWrQtEvafhQsZmAibQjwS2b98e6YZYvPnmm/Hiiy+2rImXXHJJMIonKRBQzz//fHh67uLxpu2j22+/PdKN0OCa9NZbby2+EOcwARMwARPoCIFKR9a6xJV+9NFHeSQU8YkQQnxKym8grBehFC8pPxuKcENI8emQLVtaO2LHelbS3n///XwHXTq3zZJmVEWauTwjchELiE4M1oyCwhn2dKAQ9b30gqdFNLujSb1yEzCB7iHA4xuMXnLOe/rpp+PUqVMtGRVlpseWLVuC6xpC9OjRo2ERtbTtjhj91re+lW+Mcs1/5ZVXWrKNllYb5zIBEzABE2iWQM8IUd4Sy8uJaBhiCFGEIBof/zgqqRVr1qR/MZmE2idp1G48idOJ7O7bt0cIJvL1svFyJsQgoppOC22RaoIUoYgRhkgvBh9JWZBL0y7ppm0yxVczQ74DWr7/GYkly9jExCfpBsDHMTCg2LjxgkDUDw1t1HQZ9plAzxNwA0xgXgL79++PkZGRePvtt/PI6LwJFxnBtFLeV4B4YnbJCy+8sMgSnLwQ4HneH/zgB9woCE/PLVTsmoAJmEB3E0C9dXcNU+2Ykspd4yK2UlD+Q5BKSoJzMlsOTP9Ix8V9z549fSOW6KggMFPzclslJbG9tJu+0kws8MIoW6rFsQxfnq0lnBcR8cmB1BmrJSDQZgImYALLItAbmRlxY/SSG4FPPPFEyyp9ySWX5Dfocq7lHPvyyy+3rOx2FXTkyJHq4cOHq6dPn17aBahdFUvlppFr/fCHP4xnn302nnzyya6rX6qi/0zABEzABOoI9IQQZUoqgghxJCk/78loHxdv2lIEWhkx3LRpE6/c7xvBdPjw0WoRojAo7abtrTBpGhXl15dJ54i3O3KBZ4pafZz9JmACJrBaCKQRt/xpKr4r2sq3ePPmV2a5cF4/deoUb89tv4BaxkbjBUHc6D158mQWe902DZYXQd1xxx3x29/+No4ePdrVLJexGZzVBEzABPqCQNcL0YMHD1W5QPMSAsRnoY74ZBmXeFxG7Lhz3U+CiRc0IUJpI23HxfAv1qRpwVnyUpakgCUilCnPCHo6Grt37xadjn7iGf6ZgAmYwBIIpPNhfnsuovGZZ55ZQglzZ9m7d694GRI3Wxlx5VMxc6fsntB0s1fU+4orrhD1vueee6qPPPJItVVvFV5uS2+55RZt3bo1fvOb3yy3qJbmd2EmYAImYAIzCXS1EOWihgirrzKCE8HExQ/RhB/RtGPHDm3evPlcpVWfuQf9fKqGNtJuRGO9EbbUJkk1VJSB8IQzZcMyCc++GlFeKiPnMwETMIFCgGtMEmDBLJGXXnqJb3+2bLQtCaf85lzOx70gRAsT3E9/+tNK9RdTl5m2/Itf/KL64osvtowN61iKfec732F0OR544IGO12Up9XeelhFwQSZgAl1MoKuFKFNypZpgQowVQzghmhjFQzgxatfFjJdVtQ8//DAkBR0U2hzpB4fiT4sN/6Qav7kSSYrCkvJ5KySdrX4U9HO132EmYAImsBgC6dyYHw3hxt0f/vCHxWRtmJZr2DXXXBPceDx9+nTDtN0auX//fj6jos985jPB9OW/+qu/qj788MMdE4Hphqp4k+59990Xb7zxxoL1OHXqVPVf//Vfq6+99tqCabt1G7heJtA9BFwTE2iOQNcKUV6IUJqASGI6FC7CSeLtrRtj9+6dTL+ZX2mVAnrUhQGisxjNkJSFKWGtEKMwRYDu2rVLfhERhG0mYAImMDeBsbGxLER5w+2TTz45d6Ilhn7lK1/R8PBwHDx4sKe/J7pv3z7dcccdSu3JgvTP//zPq7/+9a87Iu4uuugi3XDDDXHXXXctuFXSaLcOHDiQp/O+/PLLHanvgpV0AhMwARNoRKAH4yrdWGem5DISiPjk2VBEV5mKyygoAnTLlv6bhjt7W3DXHaGI4ISBVBOhknJSwrNnEf+kWt6SZffu3UypmhlYIu2agAmYgAlMEUg367KfZzl5Wc8f//jHlgoWPj9CuWl0Lq+nl/9t27ZNqT36d//u3+WZN//rf/2v6l//9V9X33rrrZYyW4jRzTffLK6lSYwuuN4LL7xQX/3qV+MnP/lJPP300wumX2jdjjcBEzABE2hMoCuFKBcNqi0pf7+Sb1uuW7cmRkaGY9euHbNFE0n7zvhkzXvvfZDbhfhGiPJMLIJc0tTLhaoTkxGT6XqZTMkpfsKxSigw4ibHJwJbt2Zt7NqxU1j4ZwImYAIm0BQBZo7wFnFJkUbQ4tFHH20qX7OJGMH74he/2NJvlTa77nalS6O8+vrXv67/8T/+h5I4jb/6q78KRkmfeuoprljtWu2Mcpmi+/jjj0czNw64Ofuf//N/jjvvvDPuv//+FavjjAp7wQRMwARWCYFKN7YT0cVoH8JrzZo1wdtwx8bGlDoA6sb6tqNOPCfEiDCiHJNqTSeM0WK+q8o0ZVhhpQ6SQpo2OCJeYUleLrI8j1TSL911ThMwARNYfQT+/b//9/ov/+W/6L/+1/+qH/3oR2o1gf/wH/4D00lbXm6r67mU8m677Tb9z//5PzO/yy+/fMXauGPHDv33//7f9alPfaqpdSKe/9t/+2+66aabmkq/FBbOYwImYAImEGmwrAspIDyHhoayAOVzLOnOs7qwmm2tEuKSabkYK0J04iJAeUETolJSfomRNI2HfIjPeiP9nj17uBs9nTD860kCrrQJmIAJmIAJmIAJmIAJ9AGBSje2IYnQ/CmW1ShAy/ZASCJCpWntyOgwgpQRUkY5eX6W9IhPjDy45EOoIkCZSuYRUCjZTGDpBJzTBEzABEzABEzABEygtQS6Uoi2tom9V9rbBw9V1513XgysWRPnr1+fjWVVKnHBhg1x3vnnB8tM0UV0SsrTcfEjQHmjI1OZt27dqvDPBEzABHqTgGttAiZgAiZgAibQxwQsRLto477zzuEqIrTZKjFCivg8PwnTwcHB4DkYRj8ZUW62DKczARMwARMwgWkC9pmACZiACZjAyhCwEF0Zzguu5fnnX6xOVhf3gj7eIMzI58jIyKp6kdOCMJ3ABEzABEzABHqJgOtqAiZgAquQgIVol2z0waGhLqmJq2ECJmACJmACJmAC/U/ALTQBE+gsAQvRzvJf0tp37tgmbEmZnckETMAETMAETMAETMAEOkPAazWBKQIWolMo7DEBEzABEzABEzABEzABEzCBfiPQne2xEO3O7TJnrRgFxeaMdKAJmIAJmIAJmIAJmIAJmIAJ9AiBvheivbAdFnpT7nnr1oQFaC9sSdfRBEzABEzABEzABEzABEygGQIWos1QamOaRx55pOGrchGgW7ZsURur0I6iXaYJmIAJmIAJmIAJmIAJmIAJzEvAQnReNCsTcc011+iD99+N1197JY4eORQff/RBrBlQHgFFhK5MLbyW/iDgVpiACZiACZiACZiACZhAbxCwEO2C7XTRRRfphhtu0JVXXqn9+/eLb4N2QbVcBRMwgWYIOI0JmIAJmIAJmIAJmMCiCViILhqZM5iACZiACXSagNdvAiZgAiZgAibQ2wQsRHt7+7n2JmACJmACJrBSBLweEzABEzABE2gZAQvRlqF0QSZgAiZgAiZgAibQagIuzwRMwAT6k4CFaH9uV7fKBEzABEzABEzABExgqQSczwRMoO0ELETbjtgrMAETMAETMAETMAETMAETWIiA41cXAQvR1bW93VoTMAETMAETMAETMAETMAETKAQ65lqIdgy9V2wCJmACJmACJmACJmACJmACq5PA6haiq3Obu9UmYAImYAImYAImYAImYAIm0FECFqIdxb86V+5Wm4AJmIAJmIAJmIAJmIAJrG4CFqKre/u79auHgFtqAiZgAiZgAiZgAiZgAl1DwEK0azaFK2ICJtB/BNwiEzABEzABEzABEzCBuQhYiM5FxWEmYAImYAK9S8A1NwETMAETMAET6HoCFqJdv4lcQRMwARMwARPofgKuoQmYgAmYgAkshoCF6GJoOa0JmIAJmIAJmIAJdA8B18QETMAEepaAhWjPbjpX3ARM7Ty1qwAABYtJREFUwARMwARMwARMYOUJeI0mYAKtIGAh2gqKLsMETMAETMAETMAETMAETKB9BFxy3xGwEO27TeoGmYAJmIAJmIAJmIAJmIAJmMDyCbSzBAvRdtJ12SZgAiZgAiZgAiZgAiZgAiZgAucQsBA9B0kJsGsCJmACJmACJmACJmACJmACJtAOAhai7aDqMpdOwDlNwARMwARMwARMwARMwAT6noCFaN9vYjfQBBYm4BQmYAImYAImYAImYAImsJIELERXkrbXZQImYALTBOwzARMwARMwARMwgVVLwEJ01W56N9wETMAEViMBt9kETMAETMAETKAbCFiIdsNWcB1MwARMwARMoJ8JuG0mYAImYAImMIuAhegsIF40ARMwARMwARMwgX4g4DaYgAmYQDcTsBDt5q3jupmACZiACZiACZiACfQSAdfVBEygSQIWok2CcjITMAETMAETMAETMAETMIFuJOA69SIBC9Fe3GquswmYgAmYgAmYgAmYgAmYgAl0ksAy120hukyAzm4CJmACJmACJmACJmACJmACJrA4Ahaii+NVUts1ARMwARMwARMwARMwARMwARNYIgEL0SWCc7ZOEPA6TcAETMAETMAETMAETMAE+oGAhWg/bEW3wQTaScBlm4AJmIAJmIAJmIAJmECLCViIthioizMBEzCBVhBwGSZgAiZgAiZgAibQzwQsRPt567ptJmACJmACiyHgtCZgAiZgAiZgAitEwEJ0hUB7NSZgAiZgAiZgAnMRcJgJmIAJmMBqJGAhuhq3uttsAiZgAiZgAiawugm49SZgAibQYQIWoh3eAF69CZiACZiACZiACZjA6iDgVpqACUwTsBCdZmGfCZiACZiACZiACZiACZhAfxFwa7qUgIVol24YV8sETMAETMAETMAETMAETMAEepPAwrW2EF2YkVOYgAmYgAmYgAmYgAmYgAmYgAm0kICFaAthlqLsmoAJmIAJmIAJmIAJmIAJmIAJzE/AQnR+No7pLQKurQmYgAmYgAmYgAmYgAmYQI8QsBDtkQ3lappAdxJwrUzABEzABEzABEzABExg8QQsRBfPzDlMwARMoLMEvHYTMAETMAETMAET6HECFqI9vgFdfRMwARMwgZUh4LWYgAmYgAmYgAm0joCFaOtYuiQTMAETMAETMIHWEnBpJmACJmACfUrAQrRPN6ybZQImYAImYAImYAJLI+BcJmACJtB+Ahai7WfsNZiACZiACZiACZiACZhAYwKONYFVRsBCdJVtcDfXBEzABEzABEzABEzABEygRsD/O0fAQrRz7L1mEzABEzABEzABEzABEzABE1htBHJ7LUQzBv8zARMwARMwARMwARMwARMwARNYKQIWoitFuqzHrgmYgAmYgAmYgAmYgAmYgAmscgIWoqt8B1gtzXc7TcAETMAETMAETMAETMAEuoeAhWj3bAvXxAT6jYDbYwImYAImYAImYAImYAJzErAQnROLA03ABEygVwm43iZgAiZgAiZgAibQ/QQsRLt/G7mGJmACJmAC3U7A9TMBEzABEzABE1gUAQvRReFyYhMwARMwARMwgW4h4HqYgAmYgAn0LgEL0d7ddq65CZiACZiACZiACaw0Aa/PBEzABFpCwEK0JRhdiAmYgAmYgAmYgAmYgAm0i4DLNYH+I2Ah2n/b1C0yARMwARMwARMwARMwARNYLgHnbysBC9G24nXhJmACJmACJmACJmACJmACJmACswnMJ0Rnp/OyCZiACZiACZiACZiACZiACZiACbSEgIVoSzC2qhCXYwImYAImYAImYAImYAImYAL9T8BCtP+3sVu4EAHHm4AJmIAJmIAJmIAJmIAJrCgBC9EVxe2VmYAJFAJ2TcAETMAETMAETMAEVi+B/x8AAP///XKK5AAAAAZJREFUAwD8PJMBesg3ygAAAABJRU5ErkJggg=="
        
        writefile("Crow.png", base64decode(encoded))

        local asset_id = getcustomasset("Crow.png")


        local Logo = Library:Create("ImageLabel", {
            BackgroundTransparency = 1,
            Image = asset_id,
            Size = dim2(0, 22, 0, 22),
            Position = dim2(0, 6, 0.5, -11),
            ZIndex = 10,
            Parent = TopBar,
        })
        Library:Padding(TabRow, 0, 8, 0, 34)

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
                    
                        local animConn = nil
                        local t = 0
                    
                        local function startAnim()
                            if animConn then return end
                            animConn = RunService.Heartbeat:Connect(function(dt)
                                local m = Flags[flag .. "_mode"]
                                if m == "None" and not o.Animate then return end
                                local base = Flags[flag]
                                local alpha = Flags[flag .. "_alpha"]
                                local outColor, outAlpha = base, alpha
                                if m == "Rainbow" then
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
                        end
                    
                        local function stopAnim()
                            if animConn then
                                animConn:Disconnect()
                                animConn = nil
                            end
                        end
                    
                        local handle = {Open = false, Frames = {picker, swatch, modeList}}
                        handle.Close = function()
                            picker.Visible = false
                            modeList.Visible = false
                            handle.Open = false
                            stopAnim()
                        end
                    
                        swatch.MouseButton1Click:Connect(function()
                            if handle.Open then
                                handle.Close()
                                Library.OpenElement = nil
                            else
                                Library:CloseOpen()
                                reposition()
                                picker.Visible = true
                                handle.Open = true
                                Library.OpenElement = handle
                                startAnim()
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
                            if i.UserInputType == Enum.UserInputType.MouseButton1 then
                                satDrag, hueDrag, alphaDrag, speedDrag = nil, nil, nil, nil
                            end
                        end)
                        Library:Connection(UserInputService.InputChanged, function(input)
                            if input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
                            if satDrag then
                                local rx = math.clamp((input.Position.X - sat.AbsolutePosition.X) / sat.AbsoluteSize.X, 0, 1)
                                local ry = math.clamp((input.Position.Y - sat.AbsolutePosition.Y) / sat.AbsoluteSize.Y, 0, 1)
                                s, v = rx, 1 - ry
                                setColor()
                            end
                            if hueDrag then
                                local ry = math.clamp((input.Position.Y - hueBar.AbsolutePosition.Y) / hueBar.AbsoluteSize.Y, 0, 1)
                                h = ry
                                setColor()
                            end
                            if alphaDrag then
                                local rx = math.clamp((input.Position.X - alphaBar.AbsolutePosition.X) / alphaBar.AbsoluteSize.X, 0, 1)
                                setAlpha(rx)
                            end
                            if speedDrag then
                                local rx = math.clamp((input.Position.X - speedTrack.AbsolutePosition.X) / speedTrack.AbsoluteSize.X, 0, 1)
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
        if not ok or type(cfg) ~= "table" then warn("[Scythe] LoadConfig: invalid json") return end
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
            if cfgName == nil or cfgName == "" then warn("[Scythe] no config name") return end
            if not (writefile and ensureFolders()) then warn("[Scythe] no file API") return end
            local data = Library:GetConfig()
            local ok, err = pcall(writefile, Library.Directory .. "/configs/" .. cfgName .. ".cfg", data)
            if not ok then warn("[Scythe] save failed: " .. tostring(err)) end
            refreshList()
        end})
        Configs:Button({Name = "load", Callback = function()
            if cfgName == nil or cfgName == "" then warn("[Scythe] no config selected") return end
            local path = Library.Directory .. "/configs/" .. cfgName .. ".cfg"
            if not (isfile and isfile(path)) then warn("[Scythe] config not found") return end
            local ok, data = pcall(readfile, path)
            if not ok then warn("[Scythe] read failed") return end
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
        Info:Label({Name = "Scythe.vip v1.0"})
        Info:Label({Name = "press menu key to toggle (Obviously)"})
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
getgenv().Library = Library
return Library
-- Demo
--[[
do
    local Window = Library:Window({Title = "Scythe", Size = vec2(620, 540)})

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

    Library:Watermark({Text = "Scythe.vip"})
    Library:KeybindList({Title = "keybinds"})
    Library:Settings(Window)

    Window:SelectTab(Rage)
end

Library:Notify({Text = 'Finished loading', Duration = 4})

local encoded = game:HttpGet("https://gist.githubusercontent.com/stunsua/37c802f3439d05a67bc7ebef9bde9a1d/raw/f9c64f6ea2c43d122bb7c9b29f48a7645fcb8ff6/gistfile1.txt")
writefile("CrowCaw.mp3", base64decode(encoded))

local asset_id = getcustomasset("CrowCaw.mp3")

local sound = Instance.new("Sound")
sound.Parent = workspace
sound.SoundId = asset_id
sound.Volume = 0.35
sound:Play()
]]

local esp = {}
local item_esp = {}
esp.item = item_esp

local RunService = game:GetService("RunService")
local CoreGui    = game:GetService("CoreGui")
local Workspace  = game:GetService("Workspace")
local Players    = game:GetService("Players")

local defaults = {
	enabled          = false,
	boxes            = false,
	boxType          = "Corner",
	boxColor1        = Color3.fromRGB(255, 255, 255),
	boxColor2        = Color3.fromRGB(255, 255, 255),
	gradientRot      = 90,
	gradientMoving   = false,
	gradientSpeed    = 120,
	boxFill          = false,
	boxFillColor1    = Color3.fromRGB(255, 255, 255),
	boxFillColor2    = Color3.fromRGB(255, 255, 255),
	boxFillAlpha1    = 0.3,
	boxFillAlpha2    = 0.6,
	fillRot          = 90,
	fillMoving       = false,
	fillSpeed        = 120,
	name             = false,
	nameColor        = Color3.fromRGB(255, 255, 255),
	namePosition     = "Top",
	nameSize         = 11,
	distance         = false,
	distanceColor    = Color3.fromRGB(255, 255, 255),
	distancePosition = "Bottom",
	distanceSize     = 11,
	maxDistance      = 2500,
	chams            = false,
	chamsDepth       = "AlwaysOnTop",
	chamsFillColor   = Color3.fromRGB(255, 255, 255),
	chamsFillAlpha   = 0.7,
	chamsOutlineColor  = Color3.new(0, 0, 0),
	chamsOutlineAlpha  = 0,
	chamsTeamFill    = false,
	chamsTeamOutline = false,
}

local item_defaults = {
	enabled       = false,
	name          = false,
	nameColor     = Color3.fromRGB(255, 255, 255),
	nameSize      = 11,
	distance      = false,
	distanceColor = Color3.fromRGB(255, 255, 255),
	distanceSize  = 11,
	maxDistance   = 2500,
}

local options = {}
for k, v in defaults do options[k] = v end

local item_types = {}

local ScreenGui, CacheGui, ChamsGui
local entries   = {}
local loop      = nil
local item_loop = nil
local connTable = {}

local mfloor = math.floor
local mmax   = math.max
local WHITE  = Color3.new(1, 1, 1)
local camera = Workspace.CurrentCamera

local function rgbseq(...) return ColorSequence.new{...} end
local function rgbkey(t, c) return ColorSequenceKeypoint.new(t, c) end
local function nseq(...) return NumberSequence.new{...} end
local function nkey(t, v) return NumberSequenceKeypoint.new(t, v) end
local function dim2(...) return UDim2.new(...) end
local function dimoff(...) return UDim2.fromOffset(...) end
local function dim(...) return UDim.new(...) end
local function vec2(...) return Vector2.new(...) end

local function new(class, props)
	local i = Instance.new(class)
	for k, v in props do i[k] = v end
	return i
end

local InterFont = Font.new(
	"rbxasset://fonts/families/Inter.json",
	Enum.FontWeight.Regular,
	Enum.FontStyle.Normal
)

local FontNonName = InterFont
local FontName    = InterFont

local function loadFonts()
	local BASE = "https://raw.githubusercontent.com/sanyoner/fonts/main/"
	local doneA, doneB = false, false
	local function loadOne(name, onDone)
		task.spawn(function()
			local f
			pcall(function()
				local ttf = name .. ".ttf"
				if not isfile(ttf) then writefile(ttf, game:HttpGet(BASE .. ttf)) end
				local asset = getcustomasset(ttf)
				local family = ('{"name":"%s","faces":[{"name":"Regular","weight":400,"style":"normal","assetId":"%s"}]}'):format(name, asset)
				local jp = name .. "_family.json"
				writefile(jp, family)
				f = Font.new(getcustomasset(jp))
			end)
			onDone(f or InterFont)
		end)
	end
	loadOne("fs-tahoma-8px",    function(f) FontNonName = f; doneA = true end)
	loadOne("smallest_pixel-7", function(f) FontName    = f; doneB = true end)
	task.spawn(function()
		while not (doneA and doneB) do task.wait() end
	end)
end

loadFonts()

local function initGui()
	if ScreenGui and ScreenGui.Parent then return end
	ScreenGui = new("ScreenGui", {
		Name           = "ESP_Main",
		IgnoreGuiInset = true,
		ResetOnSpawn   = false,
		Parent         = CoreGui,
	})
	CacheGui = new("ScreenGui", {
		Name    = "ESP_Cache",
		Enabled = false,
		Parent  = CoreGui,
	})
	ChamsGui = new("Folder", {
		Name   = "ESP_Chams",
		Parent = CoreGui,
	})
end

local function buildEntry(character, ownerPlayer)
	local hum  = character:FindFirstChildOfClass("Humanoid")
	local root = (hum and hum.RootPart) or character:FindFirstChild("HumanoidRootPart")
	if not root then return nil end

	if not ownerPlayer then
		for _, p in Players:GetPlayers() do
			if p.Character == character then ownerPlayer = p; break end
		end
	end

	local label = ownerPlayer
		and (ownerPlayer.DisplayName ~= "" and ownerPlayer.DisplayName or ownerPlayer.Name)
		or character.Name

	local E = {}
	local D = {
		Items     = E,
		character = character,
		humanoid  = hum,
		root      = root,
		player    = ownerPlayer,
		_conns    = {},
	}

	local function conn(sig, cb)
		local c = sig:Connect(cb)
		D._conns[#D._conns + 1] = c
		return c
	end

	local function makeSide(parent, pos, size, lp)
		local f = new("Frame", {
			Parent                = parent,
			BackgroundTransparency = 1,
			BorderSizePixel       = 0,
			Size                  = size,
			Position              = pos,
			ZIndex                = 2,
		})
		local lprops = { Parent = f, Padding = dim(0, 1), SortOrder = Enum.SortOrder.LayoutOrder }
		for k, v in lp do lprops[k] = v end
		new("UIListLayout", lprops)
		return f
	end

	local function makeTextContainer(parent, lo, autoSize)
		local f = new("Frame", {
			Parent                = parent,
			BackgroundTransparency = 1,
			BorderSizePixel       = 0,
			LayoutOrder           = lo,
			AutomaticSize         = autoSize or Enum.AutomaticSize.XY,
		})
		new("UIListLayout", { Parent = f, Padding = dim(0, 1), SortOrder = Enum.SortOrder.LayoutOrder })
		return f
	end

	E.Holder = new("Frame", {
		Parent                = ScreenGui,
		Name                  = "ESP_Holder",
		BackgroundTransparency = 1,
		Position              = dimoff(0, 0),
		Size                  = dim2(0, 100, 0, 100),
		BorderSizePixel       = 0,
	})
	E.Holder.Visible = false

	E.HolderGradient = new("UIGradient", {
		Parent       = E.Holder,
		Rotation     = options.fillRot,
		Color        = rgbseq(rgbkey(0, options.boxFillColor1), rgbkey(1, options.boxFillColor2)),
		Transparency = nseq(nkey(0, 1 - options.boxFillAlpha1), nkey(1, 1 - options.boxFillAlpha2)),
	})
	E.Holder.BackgroundTransparency = options.boxFill and 0 or 1

	E.Left = makeSide(E.Holder, dim2(0,0,0,0), dim2(0,0,1,0), {
		FillDirection       = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		VerticalFlex        = Enum.UIFlexAlignment.Fill,
	})
	E.Left.Parent = CacheGui
	E.LeftTexts = makeTextContainer(E.Left, -100, Enum.AutomaticSize.X)

	E.Right = makeSide(CacheGui, dim2(1,0,0,0), dim2(0,0,1,0), {
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalFlex  = Enum.UIFlexAlignment.Fill,
	})
	E.Right.Parent = CacheGui
	E.RightTexts = makeTextContainer(E.Right, 100, Enum.AutomaticSize.X)

	E.Top = makeSide(E.Holder, dim2(0,0,0,0), dim2(1,0,0,0), {
		VerticalAlignment   = Enum.VerticalAlignment.Bottom,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		HorizontalFlex      = Enum.UIFlexAlignment.Fill,
	})
	E.Top.Parent = CacheGui
	E.TopTexts = makeTextContainer(E.Top, -100, Enum.AutomaticSize.Y)

	E.Bottom = makeSide(E.Holder, dim2(0,0,1,0), dim2(1,0,0,0), {
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		HorizontalFlex      = Enum.UIFlexAlignment.Fill,
	})
	E.Bottom.Parent = CacheGui
	E.BottomTexts = makeTextContainer(E.Bottom, 1, Enum.AutomaticSize.Y)

	for _, side in {E.Left, E.Right, E.Top, E.Bottom} do
		conn(side.ChildAdded, function()
			task.wait(0.1)
			if side.Parent then side.Parent = E.Holder end
		end)
		conn(side.ChildRemoved, function()
			task.wait(0.1)
			if side.Parent and #side:GetChildren() == 0 then
				side.Parent = CacheGui
			end
		end)
	end

	E.Corners = new("Frame", {
		Parent                = CacheGui,
		BackgroundTransparency = 1,
		BorderSizePixel       = 0,
		Size                  = dim2(1, 0, 1, 0),
	})
	D._cornerGrads = {}

	local function corner(img, sl, sz, anch, pos, zi, gr)
		local ci = new("ImageLabel", {
			Parent                = E.Corners,
			ScaleType             = Enum.ScaleType.Slice,
			Image                 = img,
			SliceCenter           = sl,
			Size                  = sz,
			AnchorPoint           = anch or vec2(0, 0),
			Position              = pos  or dim2(0, 0, 0, 0),
			BackgroundTransparency = 1,
			BorderSizePixel       = 0,
			ZIndex                = zi or 2,
		})
		local g = new("UIGradient", { Parent = ci, Rotation = gr or 0 })
		D._cornerGrads[#D._cornerGrads + 1] = g
		return ci
	end

	local R = Rect.new
	corner("rbxassetid://83548615999411",  R(vec2(1,1),vec2(99,2)),  dim2(0.4,0,0,3),  vec2(0,1), dim2(0,0,1,0),  2,   0)
	corner("rbxassetid://101715268403902", R(vec2(1,0),vec2(2,96)),  dim2(0,3,0.25,0), vec2(0,1), dim2(0,0,1,-2), 500, -90)
	corner("rbxassetid://83548615999411",  R(vec2(1,1),vec2(99,2)),  dim2(0.4,0,0,3),  vec2(1,1), dim2(1,0,1,0),  2,   0)
	corner("rbxassetid://101715268403902", R(vec2(1,0),vec2(2,96)),  dim2(0,3,0.25,0), vec2(1,1), dim2(1,0,1,-2), 500, 90)
	corner("rbxassetid://102467475629368", R(vec2(1,0),vec2(2,98)),  dim2(0,3,0.25,0), vec2(0,0), dim2(0,0,0,2),  500, 90)
	corner("rbxassetid://102467475629368", R(vec2(1,0),vec2(2,98)),  dim2(0,3,0.25,0), vec2(1,0), dim2(1,0,0,2),  500, -90)
	corner("rbxassetid://83548615999411",  R(vec2(1,1),vec2(99,2)),  dim2(0.4,0,0,3),  vec2(1,0), dim2(1,0,0,0),  2,   0)
	corner("rbxassetid://83548615999411",  R(vec2(1,1),vec2(99,2)),  dim2(0.4,0,0,3),  vec2(0,0), dim2(0,0,0,0),  2,   0)

	E.ImageBox = new("ImageLabel", {
		Parent                = CacheGui,
		BackgroundTransparency = 1,
		BorderSizePixel       = 0,
		ScaleType             = Enum.ScaleType.Slice,
		SliceCenter           = Rect.new(vec2(20, 20), vec2(80, 80)),
		Image                 = "rbxassetid://129251711080353",
		Size                  = dim2(1, 0, 1, 0),
	})
	D._cornerGrads[#D._cornerGrads + 1] = new("UIGradient", { Parent = E.ImageBox })

	E.Box = new("Frame", {
		Parent                = CacheGui,
		BackgroundTransparency = 0.85,
		BorderSizePixel       = 0,
		Position              = dim2(0, 1, 0, 1),
		Size                  = dim2(1, -2, 1, -2),
	})
	new("UIStroke", { Parent = E.Box, LineJoinMode = Enum.LineJoinMode.Miter })

	E.Inner = new("Frame", {
		Parent                = E.Box,
		BackgroundTransparency = 1,
		BorderSizePixel       = 0,
		Position              = dim2(0, 1, 0, 1),
		Size                  = dim2(1, -2, 1, -2),
	})
	E.UIStroke    = new("UIStroke", { Parent = E.Inner, Color = WHITE, LineJoinMode = Enum.LineJoinMode.Miter })
	E.BoxGradient = new("UIGradient", { Parent = E.UIStroke })

	E.Inner2 = new("Frame", {
		Parent                = E.Inner,
		BackgroundTransparency = 1,
		BorderSizePixel       = 0,
		Position              = dim2(0, 1, 0, 1),
		Size                  = dim2(1, -2, 1, -2),
	})
	new("UIStroke", { Parent = E.Inner2, LineJoinMode = Enum.LineJoinMode.Miter })

	local initSeq = rgbseq(rgbkey(0, options.boxColor2), rgbkey(1, options.boxColor1))
	E.BoxGradient.Color    = initSeq
	E.BoxGradient.Rotation = options.gradientRot
	for _, g in D._cornerGrads do g.Color = initSeq end

	E.Text = new("TextLabel", {
		Parent                = options.name and E.Holder or CacheGui,
		Name                  = "Top",
		Text                  = label,
		BackgroundTransparency = 1,
		BorderSizePixel       = 0,
		FontFace              = FontName,
		TextSize              = options.nameSize,
		TextColor3            = options.nameColor,
		Size                  = dim2(0, 200, 0, 20),
		AnchorPoint           = vec2(0.5, 1),
		Position              = dim2(0.5, 0, 0, -2),
		AutomaticSize         = Enum.AutomaticSize.None,
		TextXAlignment        = Enum.TextXAlignment.Center,
	})
	new("UIStroke", { Parent = E.Text, LineJoinMode = Enum.LineJoinMode.Miter })

	E.Distance = new("TextLabel", {
		Parent                = options.distance and E.Holder or CacheGui,
		Name                  = "Bottom",
		Text                  = "",
		BackgroundTransparency = 1,
		BorderSizePixel       = 0,
		FontFace              = FontName,
		TextSize              = options.distanceSize,
		TextColor3            = options.distanceColor,
		Size                  = dim2(0, 200, 0, 20),
		AnchorPoint           = vec2(0.5, 0),
		Position              = dim2(0.5, 0, 1, 2),
		AutomaticSize         = Enum.AutomaticSize.None,
		TextXAlignment        = Enum.TextXAlignment.Center,
	})
	new("UIStroke", { Parent = E.Distance, LineJoinMode = Enum.LineJoinMode.Miter })

	E.Highlight = new("Highlight", {
		Adornee             = character,
		FillColor           = options.chamsFillColor,
		FillTransparency    = options.chamsFillAlpha,
		OutlineColor        = options.chamsOutlineColor,
		OutlineTransparency = options.chamsOutlineAlpha,
		DepthMode           = Enum.HighlightDepthMode[options.chamsDepth],
		Parent              = options.chams and ChamsGui or CacheGui,
	})

	if options.boxes then
		local bt = options.boxType
		if bt == "Corner"    then E.Corners.Parent  = E.Holder
		elseif bt == "Box"   then E.Box.Parent      = E.Holder
		elseif bt == "Image" then E.ImageBox.Parent = E.Holder end
	end

	conn(character.AncestryChanged, function()
		if not character.Parent then esp:remove(character) end
	end)

	D.destroy = function()
		for _, c in D._conns do pcall(function() c:Disconnect() end) end
		D._conns = {}
		for _, key in {"Left","Right","Top","Bottom","Corners","ImageBox","Box","Text","Distance","Highlight","Holder"} do
			local item = E[key]
			if item and typeof(item) == "Instance" then pcall(function() item:Destroy() end) end
		end
	end

	return D
end

local function applyToAll(key, value)
	for _, D in entries do
		local E = D.Items
		if not E or not E.Holder then continue end

		if key == "enabled" and not value then E.Holder.Visible = false end

		if key == "boxType" then
			E.Corners.Parent  = value == "Corner" and E.Holder or CacheGui
			E.Box.Parent      = value == "Box"    and E.Holder or CacheGui
			E.ImageBox.Parent = value == "Image"  and E.Holder or CacheGui
		end

		if key == "boxes" then
			local bt   = options.boxType
			local dest = value and E.Holder or CacheGui
			if bt == "Corner"    then E.Corners.Parent  = dest
			elseif bt == "Box"   then E.Box.Parent      = dest
			elseif bt == "Image" then E.ImageBox.Parent = dest end
		end

		if key == "boxColor1" then
			local seq = rgbseq(E.BoxGradient.Color.Keypoints[1], rgbkey(1, value))
			E.BoxGradient.Color = seq
			for _, g in D._cornerGrads do g.Color = seq end
		end

		if key == "boxColor2" then
			local seq = rgbseq(rgbkey(0, value), E.BoxGradient.Color.Keypoints[2])
			E.BoxGradient.Color = seq
			for _, g in D._cornerGrads do g.Color = seq end
		end

		if key == "gradientRot" and not options.gradientMoving then
			E.BoxGradient.Rotation = value
			for _, g in D._cornerGrads do g.Rotation = value end
		end

		if key == "gradientMoving" and not value then
			local rot = options.gradientRot
			E.BoxGradient.Rotation = rot
			for _, g in D._cornerGrads do g.Rotation = rot end
		end

		if key == "boxFill" then
			E.Holder.BackgroundTransparency = value and 0 or 1
		end

		if key == "boxFillColor1" then
			local p = E.HolderGradient
			p.Color = rgbseq(rgbkey(0, value), p.Color.Keypoints[2])
		end

		if key == "boxFillColor2" then
			local p = E.HolderGradient
			p.Color = rgbseq(p.Color.Keypoints[1], rgbkey(1, value))
		end

		if key == "boxFillAlpha1" then
			local p = E.HolderGradient
			p.Transparency = nseq(nkey(0, 1 - value), p.Transparency.Keypoints[2])
		end

		if key == "boxFillAlpha2" then
			local p = E.HolderGradient
			p.Transparency = nseq(p.Transparency.Keypoints[1], nkey(1, 1 - value))
		end

		if key == "fillRot" and not options.fillMoving then
			E.HolderGradient.Rotation = value
		end

		if key == "fillMoving" and not value then
			E.HolderGradient.Rotation = options.fillRot
		end

		if key == "name" then
			E.Text.Parent = value and E.Holder or CacheGui
		end

		if key == "nameColor" then E.Text.TextColor3 = value end
		if key == "nameSize"  then E.Text.TextSize   = value end

		if key == "namePosition" then
			local on = E.Text.Parent ~= CacheGui
			E.Text.Name   = value
			E.Text.Parent = on and E[value .. "Texts"] or CacheGui
			local horiz = value == "Top" or value == "Bottom"
			E.Text.AutomaticSize  = horiz and Enum.AutomaticSize.Y or Enum.AutomaticSize.XY
			E.Text.TextXAlignment = horiz and Enum.TextXAlignment.Center
				or Enum.TextXAlignment[value == "Right" and "Left" or "Right"]
		end

		if key == "distance" then
			E.Distance.Parent = value and E.Holder or CacheGui
		end

		if key == "distanceColor" then E.Distance.TextColor3 = value end
		if key == "distanceSize"  then E.Distance.TextSize   = value end

		if key == "distancePosition" then
			local on = E.Distance.Parent ~= CacheGui
			E.Distance.Name   = value
			E.Distance.Parent = on and E[value .. "Texts"] or CacheGui
			local horiz = value == "Top" or value == "Bottom"
			E.Distance.AutomaticSize  = horiz and Enum.AutomaticSize.Y or Enum.AutomaticSize.XY
			E.Distance.TextXAlignment = horiz and Enum.TextXAlignment.Center
				or Enum.TextXAlignment[value == "Right" and "Left" or "Right"]
		end

		if key == "chams"             then E.Highlight.Parent             = value and ChamsGui or CacheGui end
		if key == "chamsFillColor"    then E.Highlight.FillColor          = value end
		if key == "chamsFillAlpha"    then E.Highlight.FillTransparency   = value end
		if key == "chamsOutlineColor" then E.Highlight.OutlineColor       = value end
		if key == "chamsOutlineAlpha" then E.Highlight.OutlineTransparency = value end
		if key == "chamsDepth"        then E.Highlight.DepthMode          = Enum.HighlightDepthMode[value] end
	end
end

local function getItemType(typeName)
	if not item_types[typeName] then
		local opts = {}
		for k, v in item_defaults do opts[k] = v end
		item_types[typeName] = { options = opts, entries = {} }
	end
	return item_types[typeName]
end

local function buildItemEntry(instance, labelText, opts)
	local root
	if instance:IsA("BasePart") then
		root = instance
	else
		root = instance:FindFirstChildWhichIsA("BasePart", true)
	end
	if not root then return nil end

	local label = labelText or instance.Name
	local E = {}
	local D = {
		Items    = E,
		instance = instance,
		root     = root,
		_conns   = {},
	}

	local function conn(sig, cb)
		local c = sig:Connect(cb)
		D._conns[#D._conns + 1] = c
		return c
	end

	E.Holder = new("Frame", {
		Parent                = ScreenGui,
		Name                  = "ItemESP_Holder",
		BackgroundTransparency = 1,
		Position              = dimoff(0, 0),
		Size                  = dimoff(1, 1),
		BorderSizePixel       = 0,
		Visible               = false,
	})

	E.Text = new("TextLabel", {
		Parent                = opts.name and E.Holder or CacheGui,
		Name                  = "ItemName",
		Text                  = label,
		BackgroundTransparency = 1,
		BorderSizePixel       = 0,
		FontFace              = FontName,
		TextSize              = opts.nameSize,
		TextColor3            = opts.nameColor,
		AnchorPoint           = vec2(0.5, 1),
		Position              = dim2(0.5, 0, 0, -2),
		Size                  = dim2(0, 200, 0, 20),
		AutomaticSize         = Enum.AutomaticSize.None,
		TextXAlignment        = Enum.TextXAlignment.Center,
	})
	new("UIStroke", { Parent = E.Text, LineJoinMode = Enum.LineJoinMode.Miter })

	E.Distance = new("TextLabel", {
		Parent                = opts.distance and E.Holder or CacheGui,
		Name                  = "ItemDistance",
		Text                  = "",
		BackgroundTransparency = 1,
		BorderSizePixel       = 0,
		FontFace              = FontNonName,
		TextSize              = opts.distanceSize,
		TextColor3            = opts.distanceColor,
		AnchorPoint           = vec2(0.5, 0),
		Position              = dim2(0.5, 0, 1, 2),
		Size                  = dim2(0, 200, 0, 20),
		AutomaticSize         = Enum.AutomaticSize.None,
		TextXAlignment        = Enum.TextXAlignment.Center,
	})
	new("UIStroke", { Parent = E.Distance, LineJoinMode = Enum.LineJoinMode.Miter })

	conn(instance.AncestryChanged, function()
		if not instance.Parent then
			for typeName, t in item_types do
				if t.entries[instance] then
					item_esp:remove(instance, typeName)
					break
				end
			end
		end
	end)

	D.destroy = function()
		for _, c in D._conns do pcall(function() c:Disconnect() end) end
		D._conns = {}
		for _, key in {"Text", "Distance", "Holder"} do
			local item = E[key]
			if item and typeof(item) == "Instance" then pcall(function() item:Destroy() end) end
		end
	end

	return D
end

local function applyToAllItems(key, value, entriesTable)
	for _, D in entriesTable do
		local E = D.Items
		if not E or not E.Holder then continue end
		if key == "enabled"       and not value then E.Holder.Visible = false end
		if key == "name"          then E.Text.Parent         = value and E.Holder or CacheGui end
		if key == "nameColor"     then E.Text.TextColor3     = value end
		if key == "nameSize"      then E.Text.TextSize       = value end
		if key == "distance"      then E.Distance.Parent     = value and E.Holder or CacheGui end
		if key == "distanceColor" then E.Distance.TextColor3 = value end
		if key == "distanceSize"  then E.Distance.TextSize   = value end
	end
end
local function getCharacterBoundingBox(chr)
    local parts = {}
    for _, v in ipairs(chr:GetChildren()) do
        if v:IsA("BasePart") and not v:IsDescendantOf(chr:FindFirstChild("Hurtboxes")) then
            table.insert(parts, v)
        end
    end

    if #parts == 0 then return chr:GetBoundingBox() end

    local minX, minY, minZ = math.huge, math.huge, math.huge
    local maxX, maxY, maxZ = -math.huge, -math.huge, -math.huge

    for _, part in ipairs(parts) do
        local cf = part.CFrame
        local s = part.Size * 0.5
        -- Check all 8 corners of the part
        for _, corner in ipairs({
            Vector3.new( s.X,  s.Y,  s.Z),
            Vector3.new(-s.X,  s.Y,  s.Z),
            Vector3.new( s.X, -s.Y,  s.Z),
            Vector3.new(-s.X, -s.Y,  s.Z),
            Vector3.new( s.X,  s.Y, -s.Z),
            Vector3.new(-s.X,  s.Y, -s.Z),
            Vector3.new( s.X, -s.Y, -s.Z),
            Vector3.new(-s.X, -s.Y, -s.Z),
        }) do
            local world = cf:PointToWorldSpace(corner)
            minX = math.min(minX, world.X)
            minY = math.min(minY, world.Y)
            minZ = math.min(minZ, world.Z)
            maxX = math.max(maxX, world.X)
            maxY = math.max(maxY, world.Y)
            maxZ = math.max(maxZ, world.Z)
        end
    end

    local center = Vector3.new((minX + maxX) * 0.5, (minY + maxY) * 0.5, (minZ + maxZ) * 0.5)
    local size = Vector3.new(maxX - minX, maxY - minY, maxZ - minZ)
    return CFrame.new(center), size
end

local function update()
	if not options.enabled then return end

	local camCF  = camera.CFrame
	local camPos = camCF.Position
	local W2VP   = camera.WorldToViewportPoint
	local now    = tick()

	local boxGradRot, fillRotVal
	if options.gradientMoving then boxGradRot = (now * options.gradientSpeed) % 360 end
	if options.fillMoving     then fillRotVal  = (now * options.fillSpeed)    % 360 end

	local teamFill    = options.chams and options.chamsTeamFill
	local teamOutline = options.chams and options.chamsTeamOutline

	for _, D in entries do
		local E   = D.Items
		local chr = D.character
		local hum = D.humanoid
		local rt  = D.root

		local health = hum and hum.Health or 1
		if not chr.Parent or health <= 0 or not rt.Parent then
			if E.Holder.Visible then E.Holder.Visible = false end
			continue
		end

		if teamFill or teamOutline then
			local plr = D.player
			if plr then
				local tc = plr.TeamColor.Color
				if teamFill    then E.Highlight.FillColor    = tc end
				if teamOutline then E.Highlight.OutlineColor = tc end
			end
		end

		local rootPos = rt.Position
		local dx, dy, dz = rootPos.X - camPos.X, rootPos.Y - camPos.Y, rootPos.Z - camPos.Z
		local dist = (dx*dx + dy*dy + dz*dz) ^ 0.5

		local cf, size = getCharacterBoundingBox(chr)
		local hx, hy, hz = size.X * 0.5, size.Y * 0.5, size.Z * 0.5
		local rv, uv, lv = cf.RightVector, cf.UpVector, cf.LookVector
		local cp = cf.Position
		local minX, minY, maxX, maxY
		local anyOnScreen = false

		for sx = -1, 1, 2 do for sy = -1, 1, 2 do for sz = -1, 1, 2 do
			local w = cp + rv*(hx*sx) + uv*(hy*sy) + lv*(hz*sz)
			local v, onScreen = W2VP(camera, w)
			if onScreen then
				local vx, vy = v.X, v.Y
				if not anyOnScreen then
					minX, minY, maxX, maxY = vx, vy, vx, vy
					anyOnScreen = true
				else
					if vx < minX then minX = vx elseif vx > maxX then maxX = vx end
					if vy < minY then minY = vy elseif vy > maxY then maxY = vy end
				end
			end
		end end end

		if not anyOnScreen then
			if E.Holder.Visible then E.Holder.Visible = false end
			continue
		end

		if not E.Holder.Visible then E.Holder.Visible = true end

		local bpX    = mfloor(minX)
		local bpY    = mfloor(minY)
		local bsW    = mmax(mfloor(maxX - minX), 3)
		local Height = mmax(mfloor(maxY - minY), 3)

		if D._lastX ~= bpX or D._lastY ~= bpY then
			D._lastX, D._lastY = bpX, bpY
			E.Holder.Position = dimoff(bpX, bpY)
		end

		if D._lastW ~= bsW or D._lastH ~= Height then
			D._lastW, D._lastH = bsW, Height
			E.Holder.Size = dim2(0, bsW, 0, Height)
		end

		if options.gradientMoving then
			E.BoxGradient.Rotation = boxGradRot
			local grads = D._cornerGrads
			for i = 1, #grads do grads[i].Rotation = boxGradRot end
		end

		if options.fillMoving then
			E.HolderGradient.Rotation = fillRotVal
		end

		local distTxt = mfloor(dist * 0.333) .. "m"
		if D._lastDist ~= distTxt then
			D._lastDist     = distTxt
			E.Distance.Text = distTxt
		end
	end
end

local function updateItems()
	local camPos = camera.CFrame.Position
	local W2VP   = camera.WorldToViewportPoint

	for _, t in item_types do
		if not t.options.enabled then continue end
		local maxDist = t.options.maxDistance

		for _, D in t.entries do
			local E    = D.Items
			local root = D.root

			if not root.Parent or not D.instance.Parent then
				if E.Holder.Visible then E.Holder.Visible = false end
				continue
			end

			local rootPos = root.Position
			local dx = rootPos.X - camPos.X
			local dy = rootPos.Y - camPos.Y
			local dz = rootPos.Z - camPos.Z
			local dist = (dx*dx + dy*dy + dz*dz) ^ 0.5

			if dist > maxDist then
				if E.Holder.Visible then E.Holder.Visible = false end
				continue
			end

			local screenPos, onScreen = W2VP(camera, rootPos)
			if not onScreen then
				if E.Holder.Visible then E.Holder.Visible = false end
				continue
			end

			if not E.Holder.Visible then E.Holder.Visible = true end

			local sx = mfloor(screenPos.X)
			local sy = mfloor(screenPos.Y)

			if D._lastX ~= sx or D._lastY ~= sy then
				D._lastX, D._lastY = sx, sy
				E.Holder.Position = dimoff(sx, sy)
			end

			local distTxt = mfloor(dist * 0.333) .. "m"
			if D._lastDist ~= distTxt then
				D._lastDist     = distTxt
				E.Distance.Text = distTxt
			end
		end
	end
end

function esp:add(character, player)
	if entries[character] then return end
	initGui()
	local d = buildEntry(character, player)
	if d then entries[character] = d end
end

function esp:addEntity(ent)
	local model = ent and ent.WorldModel
	if not model then return end
	esp:add(model, ent.Player)
end

function esp:hookEntityList(entitylist)
    local LocalPlayer = Players.LocalPlayer
    RunService:BindToRenderStep("ESP_EntitySync", 1, function()
        local seen = {}
        for _, ent in pairs(entitylist) do
            if not ent.Parent then continue end
            if ent == LocalPlayer.Character then continue end
            seen[ent] = true
            if not entries[ent] then esp:add(ent, nil) end
        end
        for chr in pairs(entries) do
            if not seen[chr] then esp:remove(chr) end
        end
    end)
    connTable[#connTable + 1] = { Disconnect = function() RunService:UnbindFromRenderStep("ESP_EntitySync") end }
end

function esp:remove(character)
	local d = entries[character]
	if not d then return end
	pcall(d.destroy)
	entries[character] = nil
end

function esp:set(key, value)
	if defaults[key] == nil then return end
	options[key] = value
	applyToAll(key, value)
end

function esp:get(key) return options[key] end

function esp:unload()
	for chr in pairs(entries) do esp:remove(chr) end
	entries = {}
	for _, t in item_types do
		for inst in pairs(t.entries) do
			local d = t.entries[inst]
			if d then pcall(d.destroy) end
			t.entries[inst] = nil
		end
	end
	item_types = {}
	for _, c in connTable do pcall(function() c:Disconnect() end) end
	connTable = {}
	if loop      then RunService:UnbindFromRenderStep("ESPLoop");     loop      = nil end
	if item_loop then RunService:UnbindFromRenderStep("ItemESPLoop"); item_loop = nil end
	pcall(function() if ScreenGui then ScreenGui:Destroy() end end)
	pcall(function() if CacheGui  then CacheGui:Destroy()  end end)
	pcall(function() if ChamsGui  then ChamsGui:Destroy()  end end)
end

function item_esp:add(instance, labelText, typeName)
	typeName = typeName or "default"
	local t = getItemType(typeName)
	if t.entries[instance] then return end
	initGui()
	local d = buildItemEntry(instance, labelText, t.options)
	if d then
		d._typeName = typeName
		t.entries[instance] = d
	end
end

function item_esp:remove(instance, typeName)
	if typeName then
		local t = item_types[typeName]
		if not t then return end
		local d = t.entries[instance]
		if not d then return end
		pcall(d.destroy)
		t.entries[instance] = nil
	else
		for _, t in item_types do
			local d = t.entries[instance]
			if d then
				pcall(d.destroy)
				t.entries[instance] = nil
			end
		end
	end
end

function item_esp:set(key, value, typeName)
	if item_defaults[key] == nil then return end
	if typeName then
		local t = getItemType(typeName)
		t.options[key] = value
		applyToAllItems(key, value, t.entries)
	else
		for _, t in item_types do
			t.options[key] = value
			applyToAllItems(key, value, t.entries)
		end
	end
end

function item_esp:get(key, typeName)
	if typeName then
		return getItemType(typeName).options[key]
	end
	return item_defaults[key]
end

initGui()
loop      = RunService:BindToRenderStep("ESPLoop",     0, update)
item_loop = RunService:BindToRenderStep("ItemESPLoop", 0, updateItems)

return esp

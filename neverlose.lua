-- ============================================================================
-- ВСТАВЬ СВОЙ КОД СЮДА (САМЫЙ ВЕРХ СКРИПТА)
-- ============================================================================

local function SkinChander()
	-- ВСТАВЬ СВОЙ КОД SKIN CHANGER СЮДА (он запустится при нажатии кнопки во вкладке Skins):
	print("SkinChander запущен!")
	
end

local function RapidFire(enabled)
	-- ВСТАВЬ СВОЙ КОД БЫСТРОЙ СТРЕЛЬБЫ СЮДА (переменная enabled = true когда включено, false когда выключено):
	print("RapidFire статус:", enabled)
	
end

-- ============================================================================
-- ОСНОВНОЙ КОД ХАБА (FLUX HUB)
-- ============================================================================

local Players = game:GetService("Players")
local TS = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local RS = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local VirtualUser = game:GetService("VirtualUser")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local plr = Players.LocalPlayer
local playerGui = plr:WaitForChild("PlayerGui")
local old = playerGui:FindFirstChild("FluxHub") or playerGui:FindFirstChild("TuzikHub")
if old then old:Destroy() end

-- Flux Hub Dark Palette (Unified Theme, no red/danger buttons)
local C = {
	bg = Color3.fromRGB(11, 13, 18),
	side = Color3.fromRGB(14, 16, 22),
	panel = Color3.fromRGB(17, 20, 27),
	panel2 = Color3.fromRGB(22, 26, 35),
	line = Color3.fromRGB(28, 33, 44),
	text = Color3.fromRGB(235, 238, 245),
	dim = Color3.fromRGB(122, 132, 150),
	off = Color3.fromRGB(36, 42, 54),
	acc = Color3.fromRGB(58, 122, 254),
	acc2 = Color3.fromRGB(58, 122, 254),
}

local THEMES = {
	{"Flux Blue",58,122,254},{"Default Accent",255,42,92},{"Crimson Red",220,20,60},{"Neon Pink",255,20,147},
	{"Purple Dusk",138,43,226},{"Violet Glow",147,112,219},{"Deep Royal",65,105,225},{"Cyan Ice",0,206,209},
	{"Ocean Teal",0,128,128},{"Emerald Green",46,204,113},{"Lime Spark",50,205,50},{"Toxic Mint",0,255,127},
	{"Gold Glow",255,215,0},{"Amber Gold",255,191,0},{"Orange Blaze",255,127,80},{"Deep Coral",235,87,87},
	{"Pure White",240,240,240},{"Silver Mist",192,192,192},{"Steel Gray",112,128,144},{"Sunset Red",255,69,0},
}
local FONT, FONTB, FONTBL = Enum.Font.GothamMedium, Enum.Font.GothamBold, Enum.Font.GothamBlack

local Hub = { State = { set_open = "LeftShift", cfg_slot = "Global", skyid_id = "20160702" }, Hooks = {}, Reg = {} }
local refreshers, accents, switches, allCards = {}, {}, {}, {}
local ready, waiting = false, nil
local menuOpen = false
local savedMouseBehavior = Enum.MouseBehavior.Default
local savedMouseIconEnabled = true

-- Защищённая функция создания объектов (предотвращает ошибку UDim expected, got UDim2)
local function new(cls, props)
	local o = Instance.new(cls)
	for k, v in pairs(props) do
		if (k == "Padding" or k == "CornerRadius" or k == "PaddingLeft" or k == "PaddingRight" or k == "PaddingTop" or k == "PaddingBottom") then
			if typeof(v) == "UDim2" then
				v = UDim.new(v.X.Scale, v.X.Offset ~= 0 and v.X.Offset or v.Y.Offset)
			elseif type(v) == "number" then
				v = UDim.new(0, v)
			end
		end
		o[k] = v
	end
	return o
end

local function corner(o, r) new("UICorner", { CornerRadius = UDim.new(0, r), Parent = o }) end
local function stroke(o, col) return new("UIStroke", { Color = col or C.line, Thickness = 1, Parent = o }) end
local function tween(o, t, props, style, dir)
	local tw = TS:Create(o, TweenInfo.new(t, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out), props)
	tw:Play() return tw
end
local function label(parent, text, size, color, font, pos, sz, align)
	return new("TextLabel", { Parent = parent, BackgroundTransparency = 1, Text = text, TextSize = size, TextColor3 = color,
		Font = font, Position = pos, Size = sz, TextXAlignment = align or Enum.TextXAlignment.Left })
end
local function accent(inst, prop) table.insert(accents, { inst, prop }) inst[prop] = C.acc end
local function kn(s) s = tostring(s) return (s:gsub("^Left", "L "):gsub("^Right", "R ")) end
local function hook(id, v) local h = Hub.Hooks[id] if h then task.spawn(h, v) end end

local function addBtnAnim(b, strk, isAccent)
	local sc = new("UIScale", { Parent = b, Scale = 1 })
	b.MouseEnter:Connect(function()
		tween(sc, 0.2, { Scale = 1.03 }, Enum.EasingStyle.Back)
		if strk then tween(strk, 0.2, { Color = C.acc }) end
		if not isAccent then tween(b, 0.2, { BackgroundColor3 = C.panel2 }) end
	end)
	b.MouseLeave:Connect(function()
		tween(sc, 0.2, { Scale = 1 }, Enum.EasingStyle.Quint)
		if strk then tween(strk, 0.2, { Color = C.line }) end
		if not isAccent then tween(b, 0.2, { BackgroundColor3 = C.panel }) end
	end)
	b.MouseButton1Down:Connect(function()
		tween(sc, 0.1, { Scale = 0.95 }, Enum.EasingStyle.Quint)
	end)
	b.MouseButton1Up:Connect(function()
		tween(sc, 0.2, { Scale = 1.03 }, Enum.EasingStyle.Back)
	end)
end

local gui = new("ScreenGui", { Name = "FluxHub", Parent = playerGui, IgnoreGuiInset = true, ResetOnSpawn = false,
	DisplayOrder = 999, ZIndexBehavior = Enum.ZIndexBehavior.Sibling })

local modalUnlocker = new("TextButton", {
	Name = "ModalCursorUnlocker",
	Parent = gui,
	Size = UDim2.fromOffset(0, 0),
	Position = UDim2.fromOffset(0, 0),
	BackgroundTransparency = 1,
	Text = "",
	Modal = true,
	Visible = false,
	ZIndex = 1
})

-- ============================================================================
-- BACKGROUND PARTICLES (ОГРОМНОЕ КОЛИЧЕСТВО ЧАСТИЦ НА ЗАДНЕМ ФОНЕ)
-- ============================================================================
local particleContainer = new("CanvasGroup", {
	Name = "ParticlesLayer",
	Parent = gui,
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	GroupTransparency = 1,
	Visible = false,
	ZIndex = 0
})

local particles = {}
local PARTICLE_COUNT = 160
for i = 1, PARTICLE_COUNT do
	local sz = math.random(2, 9)
	local dot = new("Frame", {
		Parent = particleContainer,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(math.random(), math.random()),
		Size = UDim2.fromOffset(sz, sz),
		BackgroundColor3 = C.acc,
		BackgroundTransparency = math.random(15, 70) / 100,
		BorderSizePixel = 0,
	})
	corner(dot, 99)
	accent(dot, "BackgroundColor3")
	table.insert(particles, {
		inst = dot,
		x = dot.Position.X.Scale,
		y = dot.Position.Y.Scale,
		vx = (math.random() - 0.5) * 0.055,
		vy = -math.random(12, 55) / 1000,
		phase = math.random() * math.pi * 2,
		baseTr = dot.BackgroundTransparency
	})
end

RS.RenderStepped:Connect(function(dt)
	if menuOpen then
		UIS.MouseBehavior = Enum.MouseBehavior.Default
		UIS.MouseIconEnabled = true
	end
	if not particleContainer.Visible then return end
	local t = os.clock()
	for _, p in ipairs(particles) do
		p.x = (p.x + p.vx * dt + math.sin(t + p.phase) * 0.0006) % 1
		p.y = (p.y + p.vy * dt) % 1
		if p.x < 0 then p.x = 1 end
		if p.y < 0 then p.y = 1 end
		p.inst.Position = UDim2.fromScale(p.x, p.y)
		p.inst.BackgroundTransparency = math.clamp(p.baseTr + math.sin(t * 2.2 + p.phase) * 0.18, 0.1, 0.88)
	end
end)

-- Splash Screen
local splash = new("CanvasGroup", { Parent = gui, AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromScale(.5, .5),
	Size = UDim2.fromOffset(320, 220), BackgroundColor3 = C.side, BorderSizePixel = 0, ZIndex = 10 })
corner(splash, 22) stroke(splash)
label(splash, "FLUX HUB", 26, C.text, FONTBL, UDim2.fromOffset(0, 56), UDim2.new(1, 0, 0, 32), Enum.TextXAlignment.Center)
label(splash, "initializing Flux Hub...", 12, C.dim, FONT, UDim2.fromOffset(0, 92), UDim2.new(1, 0, 0, 20), Enum.TextXAlignment.Center)
local pct = label(splash, "0%", 11, C.dim, FONTB, UDim2.new(1, -80, 1, -46), UDim2.fromOffset(52, 16), Enum.TextXAlignment.Right)
local barBg = new("Frame", { Parent = splash, Position = UDim2.new(0, 28, 1, -26), Size = UDim2.new(1, -56, 0, 6), BackgroundColor3 = C.panel2, BorderSizePixel = 0 })
corner(barBg, 99)
local barFill = new("Frame", { Parent = barBg, Size = UDim2.fromScale(0, 1), BorderSizePixel = 0 })
corner(barFill, 99) accent(barFill, "BackgroundColor3")

-- Main Window
local W, H = 860, 560
local main = new("CanvasGroup", { Parent = gui, AnchorPoint = Vector2.new(.5, .5), Position = UDim2.new(.5, 0, .5, 30),
	Size = UDim2.fromOffset(W, H), BackgroundColor3 = C.bg, BorderSizePixel = 0, GroupTransparency = 1, Visible = false, ZIndex = 2 })
corner(main, 22)
local mainStroke = stroke(main, C.line)
local mainScale = new("UIScale", { Parent = main, Scale = 0.92 })

-- ============================================================================
-- ВЕРХНЯЯ ПОЛОСКА ОПИСАНИЯ НАД МЕНЮ (TOOLTIP BAR ABOVE MENU)
-- ============================================================================
local tooltipBar = new("CanvasGroup", {
	Name = "TopDescriptionBar",
	Parent = gui,
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 0.5, -H / 2 - 12),
	Size = UDim2.fromOffset(W, 38),
	BackgroundColor3 = C.side,
	BorderSizePixel = 0,
	GroupTransparency = 1,
	Visible = false,
	ZIndex = 5
})
corner(tooltipBar, 16)
local tooltipStroke = stroke(tooltipBar, C.acc)
accent(tooltipStroke, "Color")
local tooltipScale = new("UIScale", { Parent = tooltipBar, Scale = 0.95 })

local tooltipAccentDot = new("Frame", {
	Parent = tooltipBar,
	AnchorPoint = Vector2.new(0, 0.5),
	Position = UDim2.new(0, 16, 0.5, 0),
	Size = UDim2.fromOffset(8, 8),
	BackgroundColor3 = C.acc,
	BorderSizePixel = 0
})
corner(tooltipAccentDot, 99)
accent(tooltipAccentDot, "BackgroundColor3")

local tooltipLabel = label(tooltipBar, "Наведите курсор на элемент, чтобы увидеть его описание", 12, C.text, FONTB, UDim2.fromOffset(34, 0), UDim2.new(1, -48, 1, 0), Enum.TextXAlignment.Left)

local function syncTooltipPos()
	local sc = mainScale.Scale
	tooltipBar.Position = UDim2.new(main.Position.X.Scale, main.Position.X.Offset, main.Position.Y.Scale, main.Position.Y.Offset - (H * sc) / 2 - 12)
	tooltipBar.Size = UDim2.fromOffset(W * sc, 38)
end
main:GetPropertyChangedSignal("Position"):Connect(syncTooltipPos)
mainScale:GetPropertyChangedSignal("Scale"):Connect(syncTooltipPos)

local activeHoverCount = 0
local function bindHoverDesc(inst, title, desc)
	if not desc or desc == "" then return end
	local fullText = title and (title .. "  —  " .. desc) or desc
	inst.MouseEnter:Connect(function()
		if not main.Visible then return end
		activeHoverCount += 1
		tooltipLabel.Text = fullText
		tooltipBar.Visible = true
		syncTooltipPos()
		tween(tooltipBar, 0.22, { GroupTransparency = 0 }, Enum.EasingStyle.Quint)
		tween(tooltipScale, 0.26, { Scale = 1 }, Enum.EasingStyle.Back)
		tween(tooltipAccentDot, 0.25, { Size = UDim2.fromOffset(10, 10) }, Enum.EasingStyle.Back)
	end)
	inst.MouseLeave:Connect(function()
		activeHoverCount = math.max(0, activeHoverCount - 1)
		local myCount = activeHoverCount
		task.delay(0.08, function()
			if activeHoverCount == 0 and myCount == 0 then
				tween(tooltipBar, 0.22, { GroupTransparency = 1 }, Enum.EasingStyle.Quint)
				tween(tooltipScale, 0.22, { Scale = 0.95 }, Enum.EasingStyle.Quint)
				tween(tooltipAccentDot, 0.2, { Size = UDim2.fromOffset(8, 8) })
			end
		end)
	end)
end

local side = new("Frame", { Parent = main, Size = UDim2.new(0, 195, 1, 0), BackgroundColor3 = C.side, BorderSizePixel = 0 })
corner(side, 22)
new("Frame", { Parent = side, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0), Size = UDim2.new(0, 1, 1, 0), BackgroundColor3 = C.line, BorderSizePixel = 0 })

local topBar = new("Frame", { Parent = main, Position = UDim2.fromOffset(195, 0), Size = UDim2.new(1, -195, 0, 54), BackgroundColor3 = C.bg, BorderSizePixel = 0 })
new("Frame", { Parent = topBar, AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, 0), Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = C.line, BorderSizePixel = 0 })

local mainPanel = new("Frame", { Parent = main, Position = UDim2.fromOffset(195, 54), Size = UDim2.new(1, -195, 1, -54), BackgroundColor3 = C.bg, BorderSizePixel = 0 })

-- Sidebar Header
label(side, "FLUX HUB", 20, C.text, FONTBL, UDim2.fromOffset(22, 16), UDim2.fromOffset(160, 26))

-- Bottom User Profile Card
local prof = new("Frame", { Parent = side, AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, 0), Size = UDim2.new(1, 0, 0, 58), BackgroundColor3 = C.side, BorderSizePixel = 0 })
corner(prof, 22)
new("Frame", { Parent = prof, Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = C.line, BorderSizePixel = 0 })
local av = new("Frame", { Parent = prof, Position = UDim2.fromOffset(16, 13), Size = UDim2.fromOffset(32, 32), BackgroundColor3 = C.panel2, BorderSizePixel = 0 })
corner(av, 99)
local avStroke = stroke(av, C.acc)
accent(avStroke, "Color")
label(av, "FH", 10, C.text, FONTBL, UDim2.new(), UDim2.fromScale(1, 1), Enum.TextXAlignment.Center)
label(prof, plr.Name, 12, C.text, FONTB, UDim2.fromOffset(56, 13), UDim2.new(1, -64, 0, 16))
local subLbl = label(prof, "Flux Hub: Lifetime", 10, C.acc, FONT, UDim2.fromOffset(56, 29), UDim2.new(1, -64, 0, 14))
accent(subLbl, "TextColor3")

-- Topbar Controls
local topSaveBtn = new("TextButton", { Parent = topBar, Position = UDim2.fromOffset(20, 13), Size = UDim2.fromOffset(86, 28),
	BackgroundColor3 = C.panel, BorderSizePixel = 0, Text = "Save Cfg", TextColor3 = C.text, TextSize = 11, Font = FONTB, AutoButtonColor = false })
corner(topSaveBtn, 11)
local topSaveStroke = stroke(topSaveBtn)
addBtnAnim(topSaveBtn, topSaveStroke, false)
bindHoverDesc(topSaveBtn, "Save Config", "Быстрое сохранение текущего конфига Flux Hub в выбранный слот")

local slotBtn = new("TextButton", { Parent = topBar, Position = UDim2.fromOffset(116, 13), Size = UDim2.fromOffset(160, 28),
	BackgroundColor3 = C.panel, BorderSizePixel = 0, Text = "  Slot: Global", TextColor3 = C.dim, TextSize = 11,
	Font = FONTB, TextXAlignment = Enum.TextXAlignment.Left, AutoButtonColor = false })
corner(slotBtn, 11)
local slotStroke = stroke(slotBtn)
addBtnAnim(slotBtn, slotStroke, false)
bindHoverDesc(slotBtn, "Config Slot", "Переключение активного слота конфигурации (Global, Rage, Legit, Custom)")

local slots = { "Global", "Rage", "Legit", "Custom" }
slotBtn.MouseButton1Click:Connect(function()
	local idx = table.find(slots, Hub.State.cfg_slot) or 1
	Hub.State.cfg_slot = slots[idx % #slots + 1]
	slotBtn.Text = "  Slot: " .. Hub.State.cfg_slot
end)

local searchBox = new("TextBox", { Parent = topBar, AnchorPoint = Vector2.new(1, .5), Position = UDim2.new(1, -20, .5, 0),
	Size = UDim2.fromOffset(185, 28), BackgroundColor3 = C.panel, BorderSizePixel = 0, PlaceholderText = "Search feature...",
	PlaceholderColor3 = C.dim, Text = "", TextColor3 = C.text, TextSize = 11, Font = FONT, ClearTextOnFocus = false })
corner(searchBox, 11)
local searchStroke = stroke(searchBox)
searchBox.Focused:Connect(function() tween(searchStroke, 0.2, { Color = C.acc }) end)
searchBox.FocusLost:Connect(function() tween(searchStroke, 0.2, { Color = C.line }) end)
bindHoverDesc(searchBox, "Поиск", "Быстрый поиск нужной функции в Flux Hub по названию или описанию")

-- Dragging
do
	local drag, ds, sp
	local function bindDrag(frame)
		frame.InputBegan:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 then
				drag, ds, sp = true, i.Position, main.Position
				i.Changed:Connect(function() if i.UserInputState == Enum.UserInputState.End then drag = false end end)
			end
		end)
	end
	bindDrag(side)
	bindDrag(topBar)
	UIS.InputChanged:Connect(function(i)
		if drag and i.UserInputType == Enum.UserInputType.MouseMovement then
			local d = i.Position - ds
			main.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y)
		end
	end)
end

-- Switch (with rounded pill & smooth animation)
local function makeSwitch(parent, pos, init, cb)
	local b = new("TextButton", { Parent = parent, AnchorPoint = Vector2.new(1, .5), Position = pos, Size = UDim2.fromOffset(36, 18),
		Text = "", AutoButtonColor = false, BackgroundColor3 = C.off, BorderSizePixel = 0 })
	corner(b, 99)
	local bStroke = stroke(b, C.line)
	local k = new("Frame", { Parent = b, AnchorPoint = Vector2.new(0, .5), Size = UDim2.fromOffset(14, 14), Position = UDim2.new(0, 2, .5, 0),
		BackgroundColor3 = C.dim, BorderSizePixel = 0 })
	corner(k, 99)
	local sw = { on = init }
	local function vis(anim)
		local trackCol = sw.on and C.acc:Lerp(C.bg, 0.35) or C.off
		local strokeCol = sw.on and C.acc or C.line
		local knobCol = sw.on and C.acc or Color3.fromRGB(130, 138, 155)
		local kp = UDim2.new(0, sw.on and 20 or 2, .5, 0)
		if anim then
			tween(b, .24, { BackgroundColor3 = trackCol })
			tween(bStroke, .24, { Color = strokeCol })
			tween(k, .28, { Position = kp, BackgroundColor3 = knobCol }, Enum.EasingStyle.Back)
		else
			b.BackgroundColor3 = trackCol
			bStroke.Color = strokeCol
			k.Position = kp
			k.BackgroundColor3 = knobCol
		end
	end
	function sw.set(v, silent) sw.on = v vis(true) if cb and not silent then cb(v) end end
	b.MouseEnter:Connect(function() tween(k, 0.15, { Size = UDim2.fromOffset(15, 15) }) end)
	b.MouseLeave:Connect(function() tween(k, 0.15, { Size = UDim2.fromOffset(14, 14) }) end)
	b.MouseButton1Click:Connect(function() sw.set(not sw.on) end)
	sw.vis = vis vis(false)
	table.insert(switches, sw)
	return sw
end

local function smallBtn(parent, text, pos, w, anchor)
	local b = new("TextButton", { Parent = parent, AnchorPoint = anchor or Vector2.new(1, .5), Position = pos, Size = UDim2.fromOffset(w or 105, 22),
		BackgroundColor3 = C.panel2, BorderSizePixel = 0, Text = text, TextColor3 = C.text, TextSize = 10, Font = FONTB, AutoButtonColor = false })
	corner(b, 9)
	local s = stroke(b)
	addBtnAnim(b, s, false)
	return b
end

local ovRefresh
local function makeCtl(parent, id, o)
	local key = id .. "_" .. o.n
	if Hub.State[key] == nil then Hub.State[key] = o.v end
	local refresh
	if o.t == "key" then
		local b = smallBtn(parent, "", UDim2.new(1, -28, .5, 0), 82)
		local x = smallBtn(parent, "X", UDim2.new(1, 0, .5, 0), 22)
		x.TextColor3 = C.dim
		refresh = function() b.Text = kn(Hub.State[key]) end
		b.MouseButton1Click:Connect(function() waiting = { key = key, refresh = refresh } b.Text = "Press..." end)
		x.MouseButton1Click:Connect(function() Hub.State[key] = "None" waiting = nil refresh() ovRefresh() end)
	elseif o.t == "num" then
		local hasStep = o.step ~= nil
		local boxPos = hasStep and UDim2.new(1, -24, .5, 0) or UDim2.new(1, 0, .5, 0)
		local boxWidth = hasStep and 54 or 72
		local b = new("TextBox", { Parent = parent, AnchorPoint = Vector2.new(1, .5), Position = boxPos, Size = UDim2.fromOffset(boxWidth, 22),
			BackgroundColor3 = C.panel2, BorderSizePixel = 0, TextColor3 = C.text, TextSize = 10, Font = FONTB, ClearTextOnFocus = false, Text = "" })
		corner(b, 9)
		local s = stroke(b)

		local function clampAndRound(val)
			if o.min then val = math.max(o.min, val) end
			if o.max then val = math.min(o.max, val) end
			return math.floor(val * 100 + 0.5) / 100
		end

		refresh = function() b.Text = tostring(Hub.State[key]) end

		b.Focused:Connect(function() tween(s, 0.2, { Color = C.acc }) end)
		b.FocusLost:Connect(function()
			tween(s, 0.2, { Color = C.line })
			local n = tonumber(b.Text)
			if n then Hub.State[key] = clampAndRound(n) end
			refresh()
		end)

		if hasStep then
			local decBtn = smallBtn(parent, "<", UDim2.new(1, -82, .5, 0), 20)
			local incBtn = smallBtn(parent, ">", UDim2.new(1, 0, .5, 0), 20)
			decBtn.MouseButton1Click:Connect(function()
				local cur = tonumber(Hub.State[key]) or o.v or 0
				Hub.State[key] = clampAndRound(cur - o.step)
				refresh()
			end)
			incBtn.MouseButton1Click:Connect(function()
				local cur = tonumber(Hub.State[key]) or o.v or 0
				Hub.State[key] = clampAndRound(cur + o.step)
				refresh()
			end)
		end
	elseif o.t == "str" then
		local b = new("TextBox", { Parent = parent, AnchorPoint = Vector2.new(1, .5), Position = UDim2.new(1, 0, .5, 0), Size = UDim2.fromOffset(115, 22),
			BackgroundColor3 = C.panel2, BorderSizePixel = 0, TextColor3 = C.text, TextSize = 10, Font = FONTB, ClearTextOnFocus = false, Text = "", PlaceholderText = "ID..." })
		corner(b, 9)
		local s = stroke(b)
		refresh = function() b.Text = tostring(Hub.State[key] or "") end
		b.Focused:Connect(function() tween(s, 0.2, { Color = C.acc }) end)
		b.FocusLost:Connect(function()
			tween(s, 0.2, { Color = C.line })
			local clean = b.Text:match("%d+") or b.Text
			if clean ~= "" then Hub.State[key] = clean end
			refresh()
			if o.cb then o.cb(Hub.State[key]) end
		end)
	elseif o.t == "cyc" then
		local b = smallBtn(parent, "", UDim2.new(1, 0, .5, 0), 110)
		refresh = function() b.Text = tostring(Hub.State[key]) end
		b.MouseButton1Click:Connect(function()
			local i = table.find(o.c, Hub.State[key]) or 0
			Hub.State[key] = o.c[i % #o.c + 1] refresh()
		end)
	elseif o.t == "act" then
		local b = smallBtn(parent, o.btn or "Action", UDim2.new(1, 0, .5, 0), 136)
		b.BackgroundColor3 = C.acc2
		b.TextColor3 = Color3.new(1, 1, 1)
		accent(b, "BackgroundColor3")
		refresh = function()
			if o.getText then b.Text = o.getText() end
		end
		b.MouseButton1Click:Connect(function()
			local nt = o.cb and o.cb(b)
			if type(nt) == "string" then b.Text = nt end
		end)
	else
		local sw = makeSwitch(parent, UDim2.new(1, -2, .5, 0), Hub.State[key] == true, function(v)
			Hub.State[key] = v
			ovRefresh()
		end)
		refresh = function() sw.set(Hub.State[key] == true, true) end
	end
	refresh() table.insert(refreshers, refresh)
end

local function optRow(inner, order, text, desc)
	local f = new("Frame", { Parent = inner, LayoutOrder = order, Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1 })
	label(f, text, 11, C.dim, FONT, UDim2.new(), UDim2.new(.55, 0, 1, 0))
	if desc then bindHoverDesc(f, text, desc) end
	return f
end

-- Sub-Card Component (Extra Rounded + Smooth Hover Animation + Top Tooltip Bar)
local function featureCard(colParent, order, id, name, desc, opts, fx)
	opts = opts or {}
	local card = new("Frame", { Parent = colParent, LayoutOrder = order, Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = C.panel, BorderSizePixel = 0 })
	corner(card, 16)
	local cStroke = stroke(card)
	local cardScale = new("UIScale", { Parent = card, Scale = 1 })

	card.MouseEnter:Connect(function()
		tween(cStroke, 0.22, { Color = C.acc:Lerp(C.line, 0.35) })
		tween(card, 0.22, { BackgroundColor3 = C.panel2:Lerp(C.panel, 0.5) })
		tween(cardScale, 0.22, { Scale = 1.012 }, Enum.EasingStyle.Back)
	end)
	card.MouseLeave:Connect(function()
		tween(cStroke, 0.22, { Color = C.line })
		tween(card, 0.22, { BackgroundColor3 = C.panel })
		tween(cardScale, 0.22, { Scale = 1 }, Enum.EasingStyle.Quint)
	end)

	bindHoverDesc(card, name, desc)

	new("UIPadding", { Parent = card, PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14), PaddingTop = UDim.new(0, 11), PaddingBottom = UDim.new(0, 11) })
	new("UIListLayout", { Parent = card, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder })

	local secHdr = label(card, string.upper(name), 10, C.dim, FONTB, UDim2.new(), UDim2.new(1, 0, 0, 14))
	secHdr.LayoutOrder = 1
	new("Frame", { Parent = card, LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = C.line, BorderSizePixel = 0 })

	local mainRow = new("Frame", { Parent = card, LayoutOrder = 3, Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1 })
	label(mainRow, "Enabled", 12, C.text, FONTB, UDim2.new(), UDim2.new(1, -80, 1, 0))

	Hub.State[id .. "_on"] = Hub.State[id .. "_on"] or false
	local function set(v) Hub.State[id .. "_on"] = v hook(id, v) if fx then fx(v) end ovRefresh() end
	local sw = makeSwitch(mainRow, UDim2.new(1, -2, .5, 0), Hub.State[id .. "_on"], set)

	if #opts > 0 then
		local optsBox = new("Frame", { Parent = card, LayoutOrder = 4, Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Visible = false })
		new("UIListLayout", { Parent = optsBox, Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder })

		local gear = new("TextButton", { Parent = mainRow, AnchorPoint = Vector2.new(1, .5), Position = UDim2.new(1, -44, .5, 0),
			Size = UDim2.fromOffset(24, 24), BackgroundColor3 = C.panel2, BorderSizePixel = 0, Text = "+", TextSize = 14, TextColor3 = C.dim, Font = FONTB, AutoButtonColor = false })
		corner(gear, 8)
		local gStroke = stroke(gear)
		addBtnAnim(gear, gStroke, false)
		bindHoverDesc(gear, "Настройки " .. name, "Открыть дополнительные параметры и бинды функции")

		gear.MouseButton1Click:Connect(function()
			optsBox.Visible = not optsBox.Visible
			gear.Text = optsBox.Visible and "-" or "+"
			tween(gear, .25, { TextColor3 = optsBox.Visible and C.acc or C.dim }, Enum.EasingStyle.Back)
		end)

		for i, o in ipairs(opts) do
			makeCtl(optRow(optsBox, i, o.l, o.d), id, o)
		end
	end

	table.insert(refreshers, function() sw.set(Hub.State[id .. "_on"], true) end)
	table.insert(Hub.Reg, { id = id, name = name, set = function(v) sw.set(v) end, fx = fx })
	table.insert(allCards, { card = card, name = string.lower(name .. " " .. (desc or "")) })
end

local function actionCard(colParent, order, name, desc, btnText, onClick)
	local card = new("Frame", { Parent = colParent, LayoutOrder = order, Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = C.panel, BorderSizePixel = 0 })
	corner(card, 16)
	local cStroke = stroke(card)
	local cardScale = new("UIScale", { Parent = card, Scale = 1 })

	card.MouseEnter:Connect(function()
		tween(cStroke, 0.22, { Color = C.acc:Lerp(C.line, 0.35) })
		tween(card, 0.22, { BackgroundColor3 = C.panel2:Lerp(C.panel, 0.5) })
		tween(cardScale, 0.22, { Scale = 1.012 }, Enum.EasingStyle.Back)
	end)
	card.MouseLeave:Connect(function()
		tween(cStroke, 0.22, { Color = C.line })
		tween(card, 0.22, { BackgroundColor3 = C.panel })
		tween(cardScale, 0.22, { Scale = 1 }, Enum.EasingStyle.Quint)
	end)

	bindHoverDesc(card, name, desc)

	new("UIPadding", { Parent = card, PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14), PaddingTop = UDim.new(0, 11), PaddingBottom = UDim.new(0, 11) })
	new("UIListLayout", { Parent = card, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder })

	label(card, string.upper(name), 10, C.dim, FONTB, UDim2.new(), UDim2.new(1, 0, 0, 14)).LayoutOrder = 1
	new("Frame", { Parent = card, LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = C.line, BorderSizePixel = 0 })

	local r = new("Frame", { Parent = card, LayoutOrder = 3, Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1 })
	label(r, desc or name, 11, C.text, FONT, UDim2.new(), UDim2.new(1, -155, 1, 0))
	local b = new("TextButton", { Parent = r, AnchorPoint = Vector2.new(1, .5), Position = UDim2.new(1, 0, .5, 0),
		Size = UDim2.fromOffset(148, 26), BackgroundColor3 = C.acc2, BorderSizePixel = 0, Text = btnText,
		TextColor3 = Color3.new(1, 1, 1), TextSize = 10, Font = FONTB, AutoButtonColor = false })
	corner(b, 10)
	accent(b, "BackgroundColor3")
	addBtnAnim(b, nil, true)
	b.MouseButton1Click:Connect(function()
		local nt = onClick and onClick()
		if type(nt) == "string" then b.Text = nt end
	end)
	table.insert(allCards, { card = card, name = string.lower(name .. " " .. (desc or "")) })
	return b
end

searchBox:GetPropertyChangedSignal("Text"):Connect(function()
	local q = string.lower(searchBox.Text:gsub("^%s+", ""):gsub("%s+$", ""))
	for _, item in ipairs(allCards) do
		item.card.Visible = (q == "") or (string.find(item.name, q, 1, true) ~= nil)
	end
end)

local function K(v, l, n) return { t = "key", l = l or "Keybind", n = n or "key", v = v or "None" } end
local function N(l, n, v, minV, maxV, stepV) return { t = "num", l = l, n = n, v = v, min = minV, max = maxV, step = stepV } end
local function S(l, n, v, cb) return { t = "str", l = l, n = n, v = v, cb = cb } end
local function Cy(l, n, c) return { t = "cyc", l = l, n = n, c = c, v = c[1] } end
local function B(l, n, v) return { t = "bool", l = l, n = n, v = v } end
local function Act(l, n, btnText, cb, getText) return { t = "act", l = l, n = n, btn = btnText, cb = cb, getText = getText } end

local espOpts = { K() }
for _, p in ipairs({ {"Hitbox Chams (Vis/Inv)","chams"},{"Boxes (2D)","boxes"},{"Tracers","tracers"},{"Skeleton","skel"},{"Look Vector","look"},{"Health Bar","hp"},
	{"Show Distance","dist"},{"Past Distance (4s)","past"},{"Show Name","name"},{"Show Held Tool","tool"},{"Offscreen Arrow","arrow"} }) do
	table.insert(espOpts, B(p[1], p[2], true))
end
table.insert(espOpts, N("Max Distance", "max", 500))

local PAGES = {
	{ "Player", "P", "Combat", {
		{ "rage", "Rage Aura", "Авто-выстрел и наводка на видимых врагов (Револьвер)", {
			K(),
			B("Auto Aim", "aim", true),
			N("Range", "range", 1000),
			N("Cooldown", "cd", 0.5),
			B("Head Only", "head", false),
			B("Ignore Bots", "bots", false)
		} },
		{ "aim", "Aimbot", "Автоматическая плавная наводка на ближайшую цель в радиусе FOV", { K(), N("Field of View", "fov", 200), N("Smoothness", "smooth", 1), B("Visible Check", "vis", true), B("Team Check", "team", true), Cy("Hitboxes", "part", { "Head", "HumanoidRootPart", "UpperTorso" }) } },
		{ "trig", "Triggerbot", "Автоматически стреляет, когда прицел попадает на противника", { K(), Cy("Hit Part", "part", { "All", "Head", "Torso" }), Cy("Trigger Mode", "mode", { "Normal", "WithAim" }) } },
		{ "rf", "Rapid Fire +", "Отключение отдачи и быстрая автоматическая стрельба (Револьвер)", { K() } },
		{ "hit", "Hitbox", "Увеличение размера хитбоксов головы и тела всех врагов (кроме вас)", { K(), B("Head", "head", true), B("Body", "body", true), B("Visual", "vis", true) } },
		{ "wall", "Wallshot", "Позволяет проходить и стрелять сквозь стены с прозрачностью", { K(), Cy("Wall Mode", "mode", { "Transparent", "No Transparency" }), N("Transparency", "tr", 0.5, 0, 1, 0.1) } },
		{ "slowbot", "Slow Mode", "При нажатии на кнопку бинда замедляет вас, что позволяет обмануть игру и убить, не выходя из-за стенки", {
			K("LeftShift", "Бинд зажатия", "hold"),
			K("None", "Бинд вкл/выкл", "key"),
			N("Locked Speed", "speed", 8, 1, 100, 1),
			N("Default Speed", "def", 16, 1, 100, 1)
		} },
		{ "waypoint", "Waypoint", "Поставьте метку и в определённый момент можете телепортироваться на эту метку по клавише бинда, чтобы испугать противника", {
			K("Z", "Поставить точку / Teleport", "set"),
			K("X", "Удалить кнопку", "clear")
		} },
		{ "tpplayer", "TP к игроку", "Мгновенная телепортация ровно за спину ближайшему живому игроку по нажатию клавиши бинда", {
			K("Q", "Бинд телепорта", "tpkey"),
			K("None", "Бинд вкл/выкл", "key")
		} },
		{ "spin", "Spinbot", "Быстрое вращение вашего персонажа от 1-го и 3-го лица (Anti-Aim)", { K(), N("Speed (0-1000)", "speed", 25, 1, 1000, 5) } },
		{ "bhop", "Bunny Hop", "Автоматический распрыг с ускорением движения", { K(), N("Speed", "speed", 120), Cy("Mode", "mode", { "NORMAL", "TP" }) } },
		{ "sfly", "State Fly / TP", "Полёт и телепорт с 5 обходами отката назад", {
			K("X"), Cy("Mode", "mode", { "TP", "FLY" }), N("Speed", "speed", 70),
			B("1 Replication Block", "b1", true), B("2 Network Owner", "b2", true),
			B("3 State Toggle", "b3", false), B("4 Micro Steps", "b4", true), B("5 Velocity Clamp", "b5", true) } },
		{ "noclip", "Noclip", "Позволяет свободно проходить сквозь стены и препятствия", { K("N") } },
		{ "free", "Invisible / Desync", "Прячет персонажа на 100 стадов под землю и включает свободную камеру", { K("H"), N("Down Distance", "down", 100), N("Normal Speed", "spd", 1.2), N("Fast Speed", "fast", 3) } },
		{ "cam", "Move Camera", "Быстрый разворот камеры на 180 градусов (Флик)", { K() } },
		{ "camfree", "Third Person", "Включение и настройка обзора от третьего лица с фиксацией ракурса камеры", {
			K("None", "Бинд вкл/выкл", "key"),
			Act("Camera Setup", "setup", "Setup Third Person", function()
				return Hub.Hooks.camfree_setup and Hub.Hooks.camfree_setup()
			end, function()
				return Hub.Hooks.camfree_text and Hub.Hooks.camfree_text() or "Setup Third Person"
			end)
		} },
		{ "cursor", "Unlock Cursor", "Разблокирует курсор мыши в режимах с заблокированной камерой", { K() } },
	} },
	{ "Visual", "V", "Common", {
		{ "esp", "Player ESP", "Отображение игроков сквозь стены, боксы, линии и подсветка хитбоксов", espOpts },
		{ "btracers", "Bullet Tracers", "Показывает неоновые линии следов за пулями и точки попаданий", {
			K(),
			Cy("Color Mode", "col", { "Accent", "Cyan", "Red", "Purple", "Green", "White", "Rainbow" }),
			N("Lifetime (s)", "life", 1.2, 0.2, 5.0, 0.2),
			N("Thickness", "thick", 0.14, 0.05, 0.6, 0.05),
			B("Impact Dot", "impact", true)
		} },
		{ "xhair", "Custom Crosshair", "Кастомный прицел по центру экрана с редактором рисования по точкам", {
			K(),
			Act("Редактор прицела", "draw", "Нарисовать свой прицел", function()
				if Hub.Hooks.xhair_open then Hub.Hooks.xhair_open() end
				return "Нарисовать свой прицел"
			end),
			N("Размер точек", "px", 3, 1, 10, 1),
			N("Прозрачность", "tr", 0, 0, 0.9, 0.1)
		} },
		{ "fov", "FOV", "Изменение угла обзора камеры (Field of View), ультра-отдаление матрицы и вытягивание рук", {
			K("RightShift"),
			N("Target FOV", "val", 110, 70, 120, 5),
			N("Extra Zoom", "zoom", 0.85, 0.1, 1.0, 0.05),
			N("Arm Offset", "arm", 1.2, 0, 5.0, 0.1)
		} },
		{ "sky", "Sky Mode", "Изменение цвета неба и освещения карты (Радужный, Красный, Синий)", { K(), Cy("Mode", "mode", { "Rainbow", "Red", "Blue" }) } },
		{ "skyid", "Change Sky", "Загрузка и установка кастомного неба (Sky) по ID модельки из маркетплейса", {
			K(),
			S("Sky Model ID", "id", "20160702", function()
				if Hub.State.skyid_on and Hub.Hooks.skyid then
					Hub.Hooks.skyid(true)
				end
			end),
			Act("Применить ID", "apply", "Установить небо", function()
				if Hub.Hooks.skyid_apply then return Hub.Hooks.skyid_apply() end
				return "Установлено"
			end)
		} },
		{ "str", "Stretch", "Растягивание экрана от 0 до 1 (стрелочками или вводом своего числа)", {
			K(),
			N("Stretch (0 - 1)", "val", 0.65, 0, 1, 0.05)
		} },
	} },
	{ "Skins", "S", "Common", {} },
}

local tabs, pageFrames = {}, {}
local pill = new("Frame", { Parent = side, Position = UDim2.fromOffset(10, 82), Size = UDim2.new(1, -20, 0, 34), BorderSizePixel = 0, BackgroundTransparency = .82 })
corner(pill, 12) accent(pill, "BackgroundColor3")
local pillBar = new("Frame", { Parent = pill, Size = UDim2.new(0, 3, 1, -10), Position = UDim2.fromOffset(0, 5), BorderSizePixel = 0 })
corner(pillBar, 4) accent(pillBar, "BackgroundColor3")
local currentTab

local function makePage(name)
	local pg = new("Frame", { Parent = mainPanel, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false })
	local sc = new("ScrollingFrame", { Parent = pg, Position = UDim2.fromOffset(18, 16), Size = UDim2.new(1, -36, 1, -32), BackgroundTransparency = 1,
		BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageColor3 = C.dim, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y })

	local leftCol = new("Frame", { Parent = sc, Size = UDim2.new(0.5, -7, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1 })
	new("UIListLayout", { Parent = leftCol, Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder })

	local rightCol = new("Frame", { Parent = sc, Position = UDim2.new(0.5, 7, 0, 0), Size = UDim2.new(0.5, -7, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1 })
	new("UIListLayout", { Parent = rightCol, Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder })

	pageFrames[name] = pg
	return pg, sc, leftCol, rightCol
end

local function selectTab(t)
	currentTab = t
	for _, x in ipairs(tabs) do
		tween(x.lbl, .22, { TextColor3 = x == t and C.text or C.dim })
		tween(x.ico, .22, { TextColor3 = x == t and C.acc or C.dim })
		pageFrames[x.name].Visible = x == t
	end
	tween(pill, .32, { Position = UDim2.fromOffset(10, t.y) }, Enum.EasingStyle.Back)
end

local function makeGroupLabel(text, y)
	label(side, text, 10, C.dim, FONTB, UDim2.fromOffset(18, y), UDim2.new(1, -24, 0, 16))
end

local function makeTab(name, icon, y)
	local b = new("TextButton", { Parent = side, Position = UDim2.fromOffset(10, y), Size = UDim2.new(1, -20, 0, 34), BackgroundTransparency = 1, Text = "", ZIndex = 2 })
	local icoBg = new("Frame", { Parent = b, Position = UDim2.fromOffset(8, 5), Size = UDim2.fromOffset(24, 24), BackgroundColor3 = C.panel2, BorderSizePixel = 0 })
	corner(icoBg, 8)
	local ico = label(icoBg, icon, 11, C.dim, FONTBL, UDim2.new(), UDim2.fromScale(1, 1), Enum.TextXAlignment.Center)
	local l = label(b, name, 13, C.dim, FONTB, UDim2.fromOffset(40, 0), UDim2.new(1, -44, 1, 0))
	local t = { name = name, lbl = l, ico = ico, y = y }
	table.insert(tabs, t)
	b.MouseEnter:Connect(function()
		if currentTab ~= t then tween(l, 0.18, { TextColor3 = C.text }) end
	end)
	b.MouseLeave:Connect(function()
		if currentTab ~= t then tween(l, 0.18, { TextColor3 = C.dim }) end
	end)
	b.MouseButton1Click:Connect(function() selectTab(t) end)
	bindHoverDesc(b, "Вкладка " .. name, "Перейти к разделу настроек " .. name)
	return t
end

-- ============================================================================
-- SKINS / MORPH SYSTEM + ЗАПУСТИТЬ СКИН ЧЕНДЖЕР
-- ============================================================================
local morphActiveConn = nil
local morphDescConn = nil
local morphStatus = nil
local currentMorphId = "138151705692565"
local morphCache = {}

local function morphLoadTemplate(assetId)
	assetId = tostring(assetId)
	if morphCache[assetId] then
		return morphCache[assetId]:Clone()
	end
	local ok, result = pcall(function() return game:GetObjects("rbxassetid://" .. assetId) end)
	if ok and result and #result > 0 then
		local obj = result[1]
		local m = nil
		if obj:IsA("Model") then
			m = obj
		elseif obj:IsA("BasePart") then
			m = Instance.new("Model")
			obj.Parent = m
			m.PrimaryPart = obj
		else
			local fm = obj:FindFirstChildOfClass("Model")
			if fm then m = fm end
		end
		if m then
			morphCache[assetId] = m:Clone()
			return m
		end
	end
	return nil
end

local function hideRealChar(ch)
	if not ch then return end
	for _, p in ipairs(ch:GetDescendants()) do
		if p:IsA("BasePart") then
			p.Transparency = 1
			p.LocalTransparencyModifier = 1
		elseif p:IsA("Decal") or p:IsA("Texture") then
			p.Transparency = 1
		end
	end
end

local function clearMorph()
	if morphActiveConn then morphActiveConn:Disconnect() morphActiveConn = nil end
	if morphDescConn then morphDescConn:Disconnect() morphDescConn = nil end
	local oldM = Workspace:FindFirstChild(plr.Name .. "_ActiveMorph")
	if oldM then oldM:Destroy() end
	local ch = plr.Character
	if ch then
		for _, p in ipairs(ch:GetDescendants()) do
			if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
				p.Transparency = 0
				p.LocalTransparencyModifier = 0
			elseif p:IsA("Decal") or p:IsA("Texture") then
				p.Transparency = 0
			end
		end
	end
end

local function morphApply(assetId)
	assetId = tostring(assetId or currentMorphId)
	currentMorphId = assetId
	local ch = plr.Character
	local hrp = ch and ch:WaitForChild("HumanoidRootPart", 5)
	if not ch or not hrp then
		if morphStatus then morphStatus.Text = "Ожидание персонажа..." end
		return
	end

	local model = morphLoadTemplate(assetId)
	if not model then
		if morphStatus then morphStatus.Text = "Ошибка загрузки ID: " .. assetId end
		return
	end

	if morphActiveConn then morphActiveConn:Disconnect() morphActiveConn = nil end
	if morphDescConn then morphDescConn:Disconnect() morphDescConn = nil end
	local oldM = Workspace:FindFirstChild(plr.Name .. "_ActiveMorph")
	if oldM then oldM:Destroy() end

	hideRealChar(ch)
	morphDescConn = ch.DescendantAdded:Connect(function(p)
		if not Hub.State.morph_on then return end
		task.defer(function()
			if p:IsA("BasePart") then p.Transparency = 1; p.LocalTransparencyModifier = 1
			elseif p:IsA("Decal") or p:IsA("Texture") then p.Transparency = 1 end
		end)
	end)

	model.Name = plr.Name .. "_ActiveMorph"
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("Script") or d:IsA("LocalScript") or d:IsA("Humanoid") then
			d:Destroy()
		elseif d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = false
			d.CanQuery = false
			d.CanTouch = false
			d.Massless = true
		end
	end

	model.Parent = Workspace
	if not model.PrimaryPart then
		local fp = model:FindFirstChildWhichIsA("BasePart", true)
		if fp then model.PrimaryPart = fp
		else
			if morphStatus then morphStatus.Text = "Ошибка: в модели нет частей" end
			model:Destroy()
			return
		end
	end

	local yOffset = 0

	morphActiveConn = RS.RenderStepped:Connect(function()
		if not Hub.State.morph_on then
			clearMorph()
			return
		end
		local curChar = plr.Character
		local curHrp = curChar and curChar:FindFirstChild("HumanoidRootPart")
		if not curChar or not curHrp then return end

		if not model or not model.Parent then
			task.spawn(function() morphApply(currentMorphId) end)
			return
		end

		hideRealChar(curChar)
		model:PivotTo(curHrp.CFrame * CFrame.new(0, yOffset, 0))
	end)
	if morphStatus then morphStatus.Text = "Активен скин ID: " .. assetId end
end

local function setupViewportPreview(vp, assetId)
	for _, c in ipairs(vp:GetChildren()) do
		if not c:IsA("UICorner") and not c:IsA("UIStroke") and not c:IsA("TextLabel") then c:Destroy() end
	end
	local wm = Instance.new("WorldModel")
	wm.Parent = vp
	local cam = Instance.new("Camera")
	cam.Parent = vp
	vp.CurrentCamera = cam

	task.spawn(function()
		local m = morphLoadTemplate(assetId)
		if not m then return end
		for _, d in ipairs(m:GetDescendants()) do
			if d:IsA("Script") or d:IsA("LocalScript") then d:Destroy()
			elseif d:IsA("BasePart") then d.Anchored = true end
		end
		m.Parent = wm
		m:PivotTo(CFrame.new(0, 0, 0))
		local cf, sz = m:GetBoundingBox()
		local maxDim = math.max(sz.X, sz.Y, sz.Z, 4)
		local dist = maxDim * 1.35
		local angle = 0
		RS.RenderStepped:Connect(function(dt)
			if not vp or not vp.Parent then return end
			if vp.Visible and main.Visible then
				angle = angle + dt * 1.1
				local center = cf.Position
				local camPos = center + Vector3.new(math.sin(angle) * dist, maxDim * 0.18, math.cos(angle) * dist)
				cam.CFrame = CFrame.lookAt(camPos, center)
			end
		end)
	end)
end

local function buildSkinsUI(leftCol, rightCol)
	local card = new("Frame", { Parent = leftCol, LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = C.panel, BorderSizePixel = 0 })
	corner(card, 16)
	local cStroke = stroke(card)
	bindHoverDesc(card, "Morph", "Визуальное превращение вашего персонажа в любую 3D модельку по Roblox Asset ID")

	new("UIPadding", { Parent = card, PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14), PaddingTop = UDim.new(0, 11), PaddingBottom = UDim.new(0, 11) })
	new("UIListLayout", { Parent = card, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder })

	label(card, "MORPH / ПРЕВРАЩЕНИЕ В МОДЕЛЬКУ", 10, C.dim, FONTB, UDim2.new(), UDim2.new(1, 0, 0, 14)).LayoutOrder = 1
	new("Frame", { Parent = card, LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = C.line, BorderSizePixel = 0 })

	local mainRow = new("Frame", { Parent = card, LayoutOrder = 3, Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1 })
	label(mainRow, "Превращение в модельку", 12, C.text, FONTB, UDim2.new(), UDim2.new(1, -80, 1, 0))

	Hub.State.morph_on = Hub.State.morph_on or false
	local sw
	local function setMorph(v)
		Hub.State.morph_on = v
		if v then
			task.spawn(function() morphApply(currentMorphId) end)
		else
			clearMorph()
			if morphStatus then morphStatus.Text = "Морф выключен" end
		end
		ovRefresh()
	end
	sw = makeSwitch(mainRow, UDim2.new(1, -2, .5, 0), Hub.State.morph_on, setMorph)
	Hub.Hooks.morph = setMorph

	local optsBox = new("Frame", { Parent = card, LayoutOrder = 4, Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Visible = false })
	new("UIListLayout", { Parent = optsBox, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder })

	local gear = new("TextButton", { Parent = mainRow, AnchorPoint = Vector2.new(1, .5), Position = UDim2.new(1, -44, .5, 0),
		Size = UDim2.fromOffset(24, 24), BackgroundColor3 = C.panel2, BorderSizePixel = 0, Text = "+", TextSize = 14, TextColor3 = C.dim, Font = FONTB, AutoButtonColor = false })
	corner(gear, 8)
	local gStroke = stroke(gear)
	addBtnAnim(gear, gStroke, false)

	local previewLoaded = false
	local vpFrame

	gear.MouseButton1Click:Connect(function()
		optsBox.Visible = not optsBox.Visible
		gear.Text = optsBox.Visible and "-" or "+"
		tween(gear, .25, { TextColor3 = optsBox.Visible and C.acc or C.dim }, Enum.EasingStyle.Back)
		if optsBox.Visible and not previewLoaded and vpFrame then
			previewLoaded = true
			setupViewportPreview(vpFrame, "138151705692565")
		end
	end)

	local box = new("TextBox", { Parent = optsBox, LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = C.bg,
		BorderSizePixel = 0, PlaceholderText = "Введите ID модели (например: 138151705692565)", PlaceholderColor3 = C.dim,
		Text = "", TextColor3 = C.text, TextSize = 11, Font = FONT, ClearTextOnFocus = false })
	corner(box, 11) stroke(box)

	local applyIdBtn = new("TextButton", { Parent = optsBox, LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 28), BackgroundColor3 = C.acc2,
		BorderSizePixel = 0, Text = "ПРИМЕНИТЬ ID МОДЕЛИ", TextColor3 = Color3.new(1, 1, 1), TextSize = 11, Font = FONTB, AutoButtonColor = false })
	corner(applyIdBtn, 11) accent(applyIdBtn, "BackgroundColor3")
	addBtnAnim(applyIdBtn, nil, true)

	label(optsBox, "БЫСТРОЕ ПРЕВРАЩЕНИЕ (3D PREVIEW)", 10, C.dim, FONTB, UDim2.new(), UDim2.new(1, 0, 0, 16)).LayoutOrder = 3

	vpFrame = new("ViewportFrame", { Parent = optsBox, LayoutOrder = 4, Size = UDim2.new(1, 0, 0, 170),
		BackgroundColor3 = C.bg, BorderSizePixel = 0, Ambient = Color3.fromRGB(210, 210, 210), LightColor = Color3.fromRGB(255, 255, 255) })
	corner(vpFrame, 14) stroke(vpFrame)
	label(vpFrame, "  ТУНГ ТУНГ САХУР (3D)", 10, C.dim, FONTB, UDim2.fromOffset(6, 6), UDim2.new(1, -12, 0, 16))

	local tungBtn = new("TextButton", { Parent = optsBox, LayoutOrder = 5, Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = C.panel2,
		BorderSizePixel = 0, Text = "БЫСТРОЕ ПРЕВРАЩЕНИЕ: ТУНГ ТУНГ САХУР", TextColor3 = C.text, TextSize = 10, Font = FONTB, AutoButtonColor = false })
	corner(tungBtn, 11)
	local tStroke = stroke(tungBtn, C.acc)
	accent(tStroke, "Color")
	addBtnAnim(tungBtn, tStroke, false)

	morphStatus = label(optsBox, "Статус: готов к превращению", 10, C.dim, FONT, UDim2.new(), UDim2.new(1, 0, 0, 16))
	morphStatus.LayoutOrder = 6

	applyIdBtn.MouseButton1Click:Connect(function()
		local id = box.Text:match("%d+")
		if not id then morphStatus.Text = "Ошибка: введите цифры ID" return end
		currentMorphId = id
		setupViewportPreview(vpFrame, id)
		sw.set(true)
	end)

	tungBtn.MouseButton1Click:Connect(function()
		currentMorphId = "138151705692565"
		box.Text = currentMorphId
		sw.set(true)
	end)

	table.insert(refreshers, function() sw.set(Hub.State.morph_on == true, true) end)
	table.insert(Hub.Reg, { id = "morph", name = "Model Morph", set = function(v) sw.set(v) end })
	table.insert(allCards, { card = card, name = "skins morph превращение в модельку тунг сахур" })

	actionCard(rightCol, 1, "Запустить скин ченджер", "Запустить встроенный скрипт изменения скинов оружия", "Запустить скин ченджер", function()
		task.spawn(SkinChander)
		return "Запущено"
	end)
end

-- Build Sidebar Groups & Pages
local sideY = 58
local lastGroup = nil
for _, p in ipairs(PAGES) do
	if p[3] ~= lastGroup then
		lastGroup = p[3]
		makeGroupLabel(p[3], sideY)
		sideY += 20
	end
	local _, _, leftCol, rightCol = makePage(p[1])
	makeTab(p[1], p[2], sideY)
	sideY += 38

	for j, f in ipairs(p[4]) do
		local targetCol = (j % 2 == 1) and leftCol or rightCol
		featureCard(targetCol, j, f[1], f[2], f[3], f[4])
	end
	if p[1] == "Skins" then buildSkinsUI(leftCol, rightCol) end
end

-- Overlays
local function overlay(x)
	local f = new("Frame", { Parent = gui, Position = UDim2.fromOffset(x, 14), Size = UDim2.fromOffset(210, 0), AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = C.panel, BorderSizePixel = 0, Visible = false })
	corner(f, 14) stroke(f)
	new("UIListLayout", { Parent = f, Padding = UDim.new(0, 3) })
	new("UIPadding", { Parent = f, PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12), PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10) })
	return f
end
local ovF, ovK = overlay(14), overlay(234)
ovRefresh = function()
	for _, f in ipairs({ ovF, ovK }) do for _, c in ipairs(f:GetChildren()) do if c:IsA("Frame") or c:IsA("TextLabel") then c:Destroy() end end end
	ovF.Visible, ovK.Visible = Hub.State.ovF_on == true, Hub.State.ovK_on == true
	local function line(f, a, b, i)
		local r = new("Frame", { Parent = f, LayoutOrder = i, Size = UDim2.new(1, 0, 0, 16), BackgroundTransparency = 1 })
		label(r, a, 10, C.dim, FONT, UDim2.new(), UDim2.new(.65, 0, 1, 0))
		if b then label(r, "[" .. kn(b) .. "]", 10, C.acc, FONTB, UDim2.new(.5, 0, 0, 0), UDim2.new(.5, 0, 1, 0), Enum.TextXAlignment.Right) end
	end
	local head = function(f, t) label(f, t, 12, C.text, FONTB, UDim2.new(), UDim2.new(1, 0, 0, 18)).LayoutOrder = 0 end
	head(ovF, "Flux Hub Features") head(ovK, "Flux Hub Binds")
	local n = 0
	for _, f in ipairs(Hub.Reg) do if Hub.State[f.id .. "_on"] then n += 1 line(ovF, "-  " .. f.name, nil, n) end end
	if n == 0 then line(ovF, "Nothing enabled", nil, 1) end
	local k = 0
	local binds = { { "Open Menu", Hub.State.set_open } }
	for _, f in ipairs(Hub.Reg) do
		table.insert(binds, { f.name, Hub.State[f.id .. "_key"] })
		if f.id == "slowbot" and Hub.State.slowbot_hold and Hub.State.slowbot_hold ~= "None" then
			table.insert(binds, { "Slow Mode Hold", Hub.State.slowbot_hold })
		elseif f.id == "waypoint" then
			if Hub.State.waypoint_set and Hub.State.waypoint_set ~= "None" then
				table.insert(binds, { "Waypoint TP", Hub.State.waypoint_set })
			end
			if Hub.State.waypoint_clear and Hub.State.waypoint_clear ~= "None" then
				table.insert(binds, { "Waypoint Clear", Hub.State.waypoint_clear })
			end
		elseif f.id == "tpplayer" and Hub.State.tpplayer_tpkey and Hub.State.tpplayer_tpkey ~= "None" then
			table.insert(binds, { "TP к игроку", Hub.State.tpplayer_tpkey })
		end
	end
	for _, b in ipairs(binds) do if b[2] and b[2] ~= "None" then k += 1 line(ovK, b[1], b[2], k) end end
end

local rcur = new("Frame", { Parent = gui, Size = UDim2.fromOffset(30, 30), AnchorPoint = Vector2.new(.5, .5), BackgroundTransparency = .4, Visible = false, ZIndex = 999 })
corner(rcur, 15) stroke(rcur, Color3.new(1, 1, 1))
RS.RenderStepped:Connect(function()
	if rcur.Visible then
		local m = UIS:GetMouseLocation()
		rcur.Position = UDim2.fromOffset(m.X, m.Y)
		rcur.BackgroundColor3 = Color3.fromHSV((os.clock() * .5) % 1, 1, 1)
	end
end)

local function applyTheme(c)
	C.acc, C.acc2 = c, c
	for _, a in ipairs(accents) do a[1][a[2]] = c end
	for _, s in ipairs(switches) do s.vis(false) end
	if currentTab then currentTab.ico.TextColor3 = c end
end

-- ============================================================================
-- SETTINGS / CONFIGS TAB (FLUX HUB)
-- ============================================================================
local FOLDER = "FluxHubSettings"
local status
local loadConfigByName

do
	makeGroupLabel("Presets", sideY + 6)
	local _, _, leftCol, rightCol = makePage("Settings")
	makeTab("Settings", "C", sideY + 26)

	local mCard = new("Frame", { Parent = leftCol, LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = C.panel, BorderSizePixel = 0 })
	corner(mCard, 16) stroke(mCard)
	bindHoverDesc(mCard, "Interface & Overlays", "Настройка клавиши открытия меню Flux Hub, автозагрузки конфига и информационных окон")
	new("UIPadding", { Parent = mCard, PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14), PaddingTop = UDim.new(0, 11), PaddingBottom = UDim.new(0, 11) })
	new("UIListLayout", { Parent = mCard, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder })
	label(mCard, "INTERFACE & OVERLAYS", 10, C.dim, FONTB, UDim2.new(), UDim2.new(1, 0, 0, 14)).LayoutOrder = 1
	new("Frame", { Parent = mCard, LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = C.line, BorderSizePixel = 0 })

	local ord = 2
	local function srow(text, id, o, desc)
		ord += 1
		makeCtl(optRow(mCard, ord, text, desc), id, o)
	end
	srow("Open Menu Key", "set", { t = "key", n = "open", v = "LeftShift" }, "Клавиша для открытия и закрытия меню Flux Hub")
	srow("Load on Startup", "set", { t = "bool", n = "load", v = false }, "Автоматически загружать конфиг Global при запуске скрипта")
	srow("Enabled Features List", "ovF", { t = "bool", n = "on", v = false }, "Показывать список активных функций в левом верхнем углу")
	srow("Keybinds Overlay", "ovK", { t = "bool", n = "on", v = false }, "Показывать список назначенных клавиш в левом верхнем углу")

	featureCard(leftCol, 2, "afling", "Anti Fling", "Защищает вашего персонажа от отбрасывания другими игроками", { K() })
	featureCard(leftCol, 3, "afk", "Anti AFK", "Предотвращает отключение от сервера за бездействие", { K() })
	featureCard(leftCol, 4, "rainbow", "Rainbow Cursor", "Добавляет плавный радужный круг вокруг курсора мыши", {}, function(v) rcur.Visible = v end)

	local cCard = new("Frame", { Parent = rightCol, LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = C.panel, BorderSizePixel = 0 })
	corner(cCard, 16) stroke(cCard)
	bindHoverDesc(cCard, "Configurations", "Сохранение и полная загрузка ваших настроек и включённых функций в Flux Hub")
	new("UIPadding", { Parent = cCard, PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14), PaddingTop = UDim.new(0, 11), PaddingBottom = UDim.new(0, 12) })
	new("UIListLayout", { Parent = cCard, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder })
	label(cCard, "CONFIGURATIONS (" .. FOLDER .. ")", 10, C.dim, FONTB, UDim2.new(), UDim2.new(1, 0, 0, 14)).LayoutOrder = 1
	new("Frame", { Parent = cCard, LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = C.line, BorderSizePixel = 0 })

	local nameBox = new("TextBox", { Parent = cCard, LayoutOrder = 3, Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = C.bg, BorderSizePixel = 0,
		Text = "", PlaceholderText = "Config name (default: Global)...", PlaceholderColor3 = C.dim, TextColor3 = C.text, TextSize = 11, Font = FONT, ClearTextOnFocus = false })
	corner(nameBox, 11) stroke(nameBox)

	local btnRow = new("Frame", { Parent = cCard, LayoutOrder = 4, Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1 })
	local save = new("TextButton", { Parent = btnRow, Size = UDim2.new(0.5, -4, 1, 0), BackgroundColor3 = C.acc2, BorderSizePixel = 0,
		Text = "SAVE CONFIG", TextColor3 = Color3.new(1, 1, 1), TextSize = 10, Font = FONTB, AutoButtonColor = false })
	corner(save, 11) accent(save, "BackgroundColor3")
	addBtnAnim(save, nil, true)

	local load = new("TextButton", { Parent = btnRow, Position = UDim2.new(0.5, 4, 0, 0), Size = UDim2.new(0.5, -4, 1, 0), BackgroundColor3 = C.panel2, BorderSizePixel = 0,
		Text = "LOAD CONFIG", TextColor3 = C.text, TextSize = 10, Font = FONTB, AutoButtonColor = false })
	corner(load, 11)
	local loadStroke = stroke(load)
	addBtnAnim(load, loadStroke, false)

	status = label(cCard, "Flux Hub Ready", 10, C.dim, FONT, UDim2.new(), UDim2.new(1, 0, 0, 16))
	status.LayoutOrder = 5

	local un = new("TextButton", { Parent = cCard, LayoutOrder = 6, Size = UDim2.new(1, 0, 0, 28), BackgroundColor3 = C.panel2, BorderSizePixel = 0,
		Text = "UNLOAD INTERFACE", TextColor3 = C.text, TextSize = 10, Font = FONTB, AutoButtonColor = false })
	corner(un, 11)
	local unStroke = stroke(un)
	addBtnAnim(un, unStroke, false)
	bindHoverDesc(un, "Unload Interface", "Полностью отключить все активные функции и закрыть Flux Hub")

	local tCard = new("Frame", { Parent = rightCol, LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = C.panel, BorderSizePixel = 0 })
	corner(tCard, 16) stroke(tCard)
	bindHoverDesc(tCard, "Accent Theme", "Выбор цветовой схемы оформления всего интерфейса Flux Hub")
	new("UIPadding", { Parent = tCard, PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14), PaddingTop = UDim.new(0, 11), PaddingBottom = UDim.new(0, 11) })
	new("UIListLayout", { Parent = tCard, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder })
	label(tCard, "ACCENT THEME", 10, C.dim, FONTB, UDim2.new(), UDim2.new(1, 0, 0, 14)).LayoutOrder = 1
	new("Frame", { Parent = tCard, LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = C.line, BorderSizePixel = 0 })

	local tHdrRow = new("Frame", { Parent = tCard, LayoutOrder = 3, Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1 })
	label(tHdrRow, "Select Menu Accent Color", 12, C.text, FONTB, UDim2.new(), UDim2.new(1, -34, 1, 0))
	local tGear = new("TextButton", { Parent = tHdrRow, AnchorPoint = Vector2.new(1, .5), Position = UDim2.new(1, -2, .5, 0),
		Size = UDim2.fromOffset(24, 24), BackgroundColor3 = C.panel2, BorderSizePixel = 0, Text = "+", TextSize = 14, TextColor3 = C.dim, Font = FONTB, AutoButtonColor = false })
	corner(tGear, 8)
	local tgStroke = stroke(tGear)
	addBtnAnim(tGear, tgStroke, false)

	local grid = new("Frame", { Parent = tCard, LayoutOrder = 4, Size = UDim2.new(1, 0, 0, 10 * 28), BackgroundTransparency = 1, Visible = false })
	new("UIGridLayout", { Parent = grid, CellSize = UDim2.new(.5, -4, 0, 24), CellPadding = UDim2.fromOffset(6, 4) })
	tGear.MouseButton1Click:Connect(function()
		grid.Visible = not grid.Visible
		tGear.Text = grid.Visible and "-" or "+"
		tween(tGear, .25, { TextColor3 = grid.Visible and C.acc or C.dim }, Enum.EasingStyle.Back)
	end)

	for _, t in ipairs(THEMES) do
		local col = Color3.fromRGB(t[2], t[3], t[4])
		local b = new("TextButton", { Parent = grid, BackgroundColor3 = C.bg, BorderSizePixel = 0, Text = "  " .. t[1], TextColor3 = C.text, TextSize = 10,
			Font = FONT, TextXAlignment = Enum.TextXAlignment.Left, AutoButtonColor = false })
		corner(b, 9)
		local bs = stroke(b)
		addBtnAnim(b, bs, false)
		local dot = new("Frame", { Parent = b, AnchorPoint = Vector2.new(1, .5), Position = UDim2.new(1, -6, .5, 0), Size = UDim2.fromOffset(10, 10), BackgroundColor3 = col, BorderSizePixel = 0 })
		corner(dot, 5)
		b.MouseButton1Click:Connect(function() applyTheme(col) Hub.State.theme = t[1] status.Text = "Applied theme: " .. t[1] end)
	end

	local function cleanName()
		local raw = nameBox.Text ~= "" and nameBox.Text or (Hub.State.cfg_slot or "Global")
		return (raw:gsub('[\\/:*?"<>|]', "_"):gsub("^%s+", ""):gsub("%s+$", ""):sub(1, 48))
	end

	local function doSaveConfig()
		local nm = cleanName()
		local ok = pcall(function()
			if makefolder and isfolder and not isfolder(FOLDER) then makefolder(FOLDER) end
			writefile(FOLDER .. "/" .. nm .. ".json", HttpService:JSONEncode(Hub.State))
		end)
		if ok then
			status.Text = "Saved config: " .. nm
		else
			status.Text = "Save error (check executor File API)"
		end
	end
	save.MouseButton1Click:Connect(doSaveConfig)
	topSaveBtn.MouseButton1Click:Connect(doSaveConfig)

	loadConfigByName = function(nm)
		local path = FOLDER .. "/" .. nm .. ".json"
		if isfile and not isfile(path) then
			status.Text = "Config not found: " .. nm
			return false
		end
		local ok, data = pcall(function()
			return HttpService:JSONDecode(readfile(path))
		end)
		if not ok or type(data) ~= "table" then
			status.Text = "Could not read config: " .. nm
			return false
		end

		for k, v in pairs(data) do
			Hub.State[k] = v
		end

		if Hub.State.cfg_slot then
			slotBtn.Text = "  Slot: " .. tostring(Hub.State.cfg_slot)
		end

		for _, t in ipairs(THEMES) do
			if t[1] == Hub.State.theme then
				applyTheme(Color3.fromRGB(t[2], t[3], t[4]))
			end
		end

		for _, r in ipairs(refreshers) do
			pcall(r)
		end

		for _, f in ipairs(Hub.Reg) do
			local isEnabled = Hub.State[f.id .. "_on"] == true
			hook(f.id, isEnabled)
			if f.fx then pcall(f.fx, isEnabled) end
		end

		ovRefresh()
		status.Text = "Loaded config & features: " .. nm
		return true
	end

	load.MouseButton1Click:Connect(function()
		loadConfigByName(cleanName())
	end)

	un.MouseButton1Click:Connect(function()
		status.Text = "Unloading Flux Hub..."
		task.wait(.3)
		menuOpen = false
		modalUnlocker.Visible = false
		UIS.MouseBehavior = savedMouseBehavior
		UIS.MouseIconEnabled = savedMouseIconEnabled
		clearMorph()
		for _, f in ipairs(Hub.Reg) do if Hub.State[f.id .. "_on"] then hook(f.id, false) end end
		gui:Destroy()
	end)
end

-- Smooth Open/Close Menu Animation + Cursor Unlock/Restore
local function toggleMenu()
	if not ready then return end
	if main.Visible and main.GroupTransparency < 0.5 then
		menuOpen = false
		modalUnlocker.Visible = false
		if not Hub.State.cursor_on then
			UIS.MouseBehavior = savedMouseBehavior
			UIS.MouseIconEnabled = savedMouseIconEnabled
		end
		tween(main, .26, { GroupTransparency = 1 }, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
		tween(mainScale, .26, { Scale = 0.92 }, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
		tween(particleContainer, .26, { GroupTransparency = 1 })
		tween(tooltipBar, .2, { GroupTransparency = 1 })
		task.delay(.26, function()
			if main.GroupTransparency >= .95 then
				main.Visible = false
				particleContainer.Visible = false
				tooltipBar.Visible = false
			end
		end)
	else
		savedMouseBehavior = UIS.MouseBehavior
		savedMouseIconEnabled = UIS.MouseIconEnabled
		menuOpen = true
		modalUnlocker.Visible = true
		UIS.MouseBehavior = Enum.MouseBehavior.Default
		UIS.MouseIconEnabled = true

		main.Visible = true
		particleContainer.Visible = true
		mainScale.Scale = 0.90
		syncTooltipPos()
		tween(main, .38, { GroupTransparency = 0, Position = UDim2.fromScale(.5, .5) }, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
		tween(mainScale, .42, { Scale = 1 }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		tween(particleContainer, .38, { GroupTransparency = 0 })
	end
end

UIS.InputBegan:Connect(function(i, gp)
	if waiting then
		if i.UserInputType == Enum.UserInputType.Keyboard then
			local w = waiting waiting = nil
			if i.KeyCode ~= Enum.KeyCode.Escape then Hub.State[w.key] = i.KeyCode.Name end
			w.refresh() ovRefresh()
		end
		return
	end
	if UIS:GetFocusedTextBox() or i.UserInputType ~= Enum.UserInputType.Keyboard then return end
	local k = i.KeyCode.Name
	if k == Hub.State.set_open then
		toggleMenu()
		return
	end
	if gp then return end
	for _, f in ipairs(Hub.Reg) do
		if Hub.State[f.id .. "_key"] == k and k ~= "None" then
			f.set(not Hub.State[f.id .. "_on"])
		end
	end
end)

selectTab(tabs[1])
ovRefresh()

Hub.applyTheme = applyTheme
getgenv = getgenv or function() return _G end
getgenv().FluxHub = Hub

-- ============================================================================
-- FEATURE LOGIC & HOOKS
-- ============================================================================
local camera = Workspace.CurrentCamera
local mouse = plr:GetMouse()

local _conn = {}
local function addConn(id, c) _conn[id] = _conn[id] or {}; table.insert(_conn[id], c); return c end
local function stopConns(id) if _conn[id] then for _, c in ipairs(_conn[id]) do pcall(function() c:Disconnect() end) end; _conn[id] = nil end end
local function num(v, d) return tonumber(v) or d end

-- ============================================================================
-- WAYPOINT (МЕТКА И ТЕЛЕПОРТАЦИЯ НА НЕЁ ВО ВКЛАДКЕ PLAYER)
-- ============================================================================
do
	local markedPosition = nil
	local markerPart = nil
	local character = plr.Character

	plr.CharacterAdded:Connect(function(newChar)
		character = newChar
	end)

	local function createVisualMarker(position)
		if markerPart then
			markerPart:Destroy()
		end

		local part = Instance.new("Part")
		part.Name = "TeleportMarker"
		part.Size = Vector3.new(0.8, 0.8, 0.8)
		part.Shape = Enum.PartType.Ball
		part.Material = Enum.Material.Neon
		part.Color = Color3.fromRGB(0, 255, 200)
		part.Anchored = true
		part.CanCollide = false
		part.Position = position
		part.Parent = Workspace

		markerPart = part
	end

	local function clearWaypointMarker()
		if markerPart then
			markerPart:Destroy()
			markerPart = nil
		end
		markedPosition = nil
	end

	UIS.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed or UIS:GetFocusedTextBox() or waiting then return end
		if not Hub.State.waypoint_on then return end
		if input.UserInputType ~= Enum.UserInputType.Keyboard then return end

		local setKeyName = Hub.State.waypoint_set or "Z"
		local clearKeyName = Hub.State.waypoint_clear or "X"
		local pressedName = input.KeyCode.Name

		-- 1. Нажатие клавиши установки/телепортации
		if setKeyName ~= "None" and pressedName == setKeyName then
			local ch = character or plr.Character
			local humanoidRootPart = ch and ch:FindFirstChild("HumanoidRootPart")
			if not humanoidRootPart then return end

			if markedPosition == nil then
				-- Первый нажим: ставим маркер под ногами игрока
				markedPosition = humanoidRootPart.Position - Vector3.new(0, 3, 0)
				createVisualMarker(markedPosition)
			else
				-- Второй нажим: телепортируемся на сохраненную точку (точка НЕ пропадает)
				humanoidRootPart.CFrame = CFrame.new(markedPosition + Vector3.new(0, 3, 0))
			end

		-- 2. Нажатие клавиши очистки маркера
		elseif clearKeyName ~= "None" and pressedName == clearKeyName then
			clearWaypointMarker()
		end
	end)

	Hub.Hooks.waypoint = function(v)
		if not v then
			clearWaypointMarker()
		end
	end
end

-- ============================================================================
-- TP К ИГРОКУ (ТЕЛЕПОРТАЦИЯ ЗА СПИНУ БЛИЖАЙШЕМУ ИГРОКУ ВО ВКЛАДКЕ PLAYER)
-- ============================================================================
do
	local function getNearestPlayer()
		local character = plr.Character
		if not character then return nil end

		local rootPart = character:FindFirstChild("HumanoidRootPart")
		if not rootPart then return nil end

		local nearestTarget = nil
		local shortestDistance = math.huge

		for _, otherPlayer in ipairs(Players:GetPlayers()) do
			if otherPlayer ~= plr and otherPlayer.Character then
				local otherRoot = otherPlayer.Character:FindFirstChild("HumanoidRootPart")
				local otherHumanoid = otherPlayer.Character:FindFirstChildOfClass("Humanoid")

				if otherRoot and otherHumanoid and otherHumanoid.Health > 0 then
					local distance = (rootPart.Position - otherRoot.Position).Magnitude
					if distance < shortestDistance then
						shortestDistance = distance
						nearestTarget = otherPlayer.Character
					end
				end
			end
		end

		return nearestTarget
	end

	local function doTeleportBehindNearest()
		local character = plr.Character
		if not character then return end

		local rootPart = character:FindFirstChild("HumanoidRootPart")
		if not rootPart then return end

		local targetChar = getNearestPlayer()
		if targetChar then
			local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
			if targetRoot then
				local behindPosition = targetRoot.CFrame * CFrame.new(0, 2, 4)
				rootPart.CFrame = CFrame.new(behindPosition.Position, targetRoot.Position)
			end
		end
	end

	UIS.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed or UIS:GetFocusedTextBox() or waiting then return end
		if not Hub.State.tpplayer_on then return end
		if input.UserInputType ~= Enum.UserInputType.Keyboard then return end

		local tpKeyName = Hub.State.tpplayer_tpkey or "Q"
		if tpKeyName ~= "None" and input.KeyCode.Name == tpKeyName then
			doTeleportBehindNearest()
		end
	end)

	Hub.Hooks.tpplayer = function(v)
		-- Функция активирует обработку клавиши TELEPORT_KEY (по умолчанию Q)
	end
end

-- ============================================================================
-- BULLET TRACERS (ЛИНИИ ЗА ПУЛЯМИ + ТОЧКИ ПОПАДАНИЯ ВО ВКЛАДКЕ VISUAL)
-- ============================================================================
local spawnBulletTracer
do
	local tracerFolder = new("Folder", { Name = "FluxBulletTracers", Parent = Workspace })

	local TRACER_COLORS = {
		Cyan = Color3.fromRGB(0, 235, 255),
		Red = Color3.fromRGB(255, 50, 65),
		Purple = Color3.fromRGB(175, 70, 255),
		Green = Color3.fromRGB(50, 255, 115),
		White = Color3.fromRGB(255, 255, 255),
	}

	local function getTracerColor()
		local mode = Hub.State.btracers_col or "Accent"
		if mode == "Accent" then
			return C.acc
		elseif mode == "Rainbow" then
			return Color3.fromHSV((os.clock() * 0.8) % 1, 1, 1)
		else
			return TRACER_COLORS[mode] or C.acc
		end
	end

	spawnBulletTracer = function(fromPos, toPos)
		if not Hub.State.btracers_on then return end
		if typeof(fromPos) ~= "Vector3" or typeof(toPos) ~= "Vector3" then return end
		local dist = (toPos - fromPos).Magnitude
		if dist < 0.5 or dist > 2500 then return end

		local col = getTracerColor()
		local life = math.clamp(num(Hub.State.btracers_life, 1.2), 0.1, 10)
		local thick = math.clamp(num(Hub.State.btracers_thick, 0.14), 0.03, 1.0)

		local beamPart = new("Part", {
			Name = "BulletTracer",
			Parent = tracerFolder,
			Anchored = true,
			CanCollide = false,
			CanQuery = false,
			CanTouch = false,
			Material = Enum.Material.Neon,
			Color = col,
			Transparency = 0.15,
			Size = Vector3.new(thick, thick, dist),
			CFrame = CFrame.lookAt(fromPos:Lerp(toPos, 0.5), toPos)
		})

		tween(beamPart, life, {
			Transparency = 1,
			Size = Vector3.new(0, 0, dist)
		}, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

		task.delay(life, function()
			if beamPart and beamPart.Parent then beamPart:Destroy() end
		end)

		if Hub.State.btracers_impact ~= false then
			local dotPart = new("Part", {
				Name = "BulletImpact",
				Parent = tracerFolder,
				Shape = Enum.PartType.Ball,
				Anchored = true,
				CanCollide = false,
				CanQuery = false,
				CanTouch = false,
				Material = Enum.Material.Neon,
				Color = col,
				Transparency = 0.1,
				Size = Vector3.new(thick * 3.2, thick * 3.2, thick * 3.2),
				Position = toPos
			})
			tween(dotPart, life * 1.15, {
				Transparency = 1,
				Size = Vector3.new(0.02, 0.02, 0.02)
			}, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			task.delay(life * 1.15, function()
				if dotPart and dotPart.Parent then dotPart:Destroy() end
			end)
		end
	end

	local function getMuzzleOrigin()
		local ch = plr.Character
		if ch then
			local tool = ch:FindFirstChildOfClass("Tool")
			if tool then
				local handle = tool:FindFirstChild("Handle") or tool:FindFirstChildWhichIsA("BasePart", true)
				if handle then return handle.Position end
			end
			local head = ch:FindFirstChild("Head")
			if head then return head.Position end
		end
		local cam = Workspace.CurrentCamera
		return cam and (cam.CFrame.Position - Vector3.new(0, 0.4, 0)) or Vector3.zero
	end

	task.spawn(function()
		pcall(function()
			local bindables = ReplicatedStorage:WaitForChild("Bindables", 4)
			local sb = bindables and bindables:WaitForChild("SpawnBullet", 4)
			if sb and sb:IsA("BindableEvent") then
				sb.Event:Connect(function(packet)
					if not Hub.State.btracers_on or type(packet) ~= "table" then return end
					local orig = packet.origin or getMuzzleOrigin()
					local dest = packet.hitPos or packet.to
					if orig and dest then
						spawnBulletTracer(orig, dest)
					end
				end)
			end
		end)
	end)

	Hub.Hooks.btracers = function(v)
		stopConns("btracers")
		if not v then
			for _, c in ipairs(tracerFolder:GetChildren()) do c:Destroy() end
			return
		end

		addConn("btracers", UIS.InputBegan:Connect(function(input, gp)
			if gp or menuOpen or not Hub.State.btracers_on then return end
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				local ch = plr.Character
				local tool = ch and ch:FindFirstChildOfClass("Tool")
				if not tool then return end
				local orig = getMuzzleOrigin()
				local cam = Workspace.CurrentCamera
				local hitPos = mouse.Hit and mouse.Hit.Position
				if cam then
					local rp = RaycastParams.new()
					rp.FilterType = Enum.RaycastFilterType.Exclude
					rp.FilterDescendantsInstances = { ch, cam, tracerFolder }
					local mLoc = UIS:GetMouseLocation()
					local unitRay = cam:ViewportPointToRay(mLoc.X, mLoc.Y)
					local res = Workspace:Raycast(unitRay.Origin, unitRay.Direction * 1000, rp)
					if res then
						hitPos = res.Position
					else
						hitPos = unitRay.Origin + unitRay.Direction * 350
					end
				end
				if orig and hitPos then
					spawnBulletTracer(orig, hitPos)
				end
			end
		end))
	end
end

-- ============================================================================
-- CUSTOM CROSSHAIR + РЕДАКТОР РИСОВАНИЯ ПРИЦЕЛА ПО ТОЧКАМ (ВО ВКЛАДКЕ VISUAL)
-- ============================================================================
do
	local GRID_SIZE = 15
	local CENTER = math.ceil(GRID_SIZE / 2)

	local PALETTE = {
		{ "Accent", nil },
		{ "White", Color3.fromRGB(255, 255, 255) },
		{ "Green", Color3.fromRGB(50, 255, 100) },
		{ "Cyan", Color3.fromRGB(0, 235, 255) },
		{ "Red", Color3.fromRGB(255, 55, 65) },
		{ "Yellow", Color3.fromRGB(255, 225, 45) },
		{ "Pink", Color3.fromRGB(255, 60, 195) },
		{ "Purple", Color3.fromRGB(165, 75, 255) },
	}
	local selectedColorIdx = 1
	local isErasing = false
	local isMouseDown = false

	local function getDefaultPattern()
		local t = {}
		for i = 1, GRID_SIZE * GRID_SIZE do t[i] = 0 end
		local function setPx(r, c, val)
			t[(r - 1) * GRID_SIZE + c] = val
		end
		setPx(CENTER, CENTER, 1)
		for d = 2, 4 do
			setPx(CENTER - d, CENTER, 1)
			setPx(CENTER + d, CENTER, 1)
			setPx(CENTER, CENTER - d, 1)
			setPx(CENTER, CENTER + d, 1)
		end
		return table.concat(t, ",")
	end

	if not Hub.State.xhair_data then
		Hub.State.xhair_data = getDefaultPattern()
	end

	local function decodeGrid()
		local grid = {}
		for i = 1, GRID_SIZE * GRID_SIZE do grid[i] = 0 end
		local raw = tostring(Hub.State.xhair_data or "")
		local idx = 1
		for numStr in raw:gmatch("(%d+)") do
			if idx <= GRID_SIZE * GRID_SIZE then
				grid[idx] = tonumber(numStr) or 0
				idx += 1
			end
		end
		return grid
	end

	local function saveGrid(grid)
		local out = {}
		for i = 1, GRID_SIZE * GRID_SIZE do
			out[i] = tostring(grid[i] or 0)
		end
		Hub.State.xhair_data = table.concat(out, ",")
	end

	local function getColorByIndex(idx)
		local entry = PALETTE[idx]
		if not entry then return C.acc end
		return entry[2] or C.acc
	end

	local liveCrosshair = new("Frame", {
		Name = "LiveCustomCrosshair",
		Parent = gui,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(GRID_SIZE * 3, GRID_SIZE * 3),
		BackgroundTransparency = 1,
		Visible = false,
		ZIndex = 50
	})

	local livePixels = {}
	for r = 1, GRID_SIZE do
		for c = 1, GRID_SIZE do
			local idx = (r - 1) * GRID_SIZE + c
			local p = new("Frame", {
				Parent = liveCrosshair,
				BorderSizePixel = 0,
				Visible = false
			})
			livePixels[idx] = p
		end
	end

	local editorWin = new("CanvasGroup", {
		Name = "CrosshairDrawEditor",
		Parent = gui,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(420, 490),
		BackgroundColor3 = C.side,
		BorderSizePixel = 0,
		GroupTransparency = 1,
		Visible = false,
		ZIndex = 30
	})
	corner(editorWin, 20)
	local edStroke = stroke(editorWin, C.acc)
	accent(edStroke, "Color")
	local edScale = new("UIScale", { Parent = editorWin, Scale = 0.92 })

	local edTop = new("Frame", { Parent = editorWin, Size = UDim2.new(1, 0, 0, 44), BackgroundColor3 = C.panel, BorderSizePixel = 0 })
	corner(edTop, 20)
	label(edTop, "FLUX HUB — РЕДАКТОР ПРИЦЕЛА (15x15)", 13, C.text, FONTBL, UDim2.fromOffset(18, 0), UDim2.new(1, -70, 1, 0))

	local closeEdBtn = new("TextButton", {
		Parent = edTop,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0.5, 0),
		Size = UDim2.fromOffset(26, 26),
		BackgroundColor3 = C.panel2,
		BorderSizePixel = 0,
		Text = "X",
		TextColor3 = C.text,
		TextSize = 11,
		Font = FONTB,
		AutoButtonColor = false
	})
	corner(closeEdBtn, 8)
	addBtnAnim(closeEdBtn, stroke(closeEdBtn), false)

	do
		local dragEd, dsEd, spEd
		edTop.InputBegan:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 then
				dragEd, dsEd, spEd = true, i.Position, editorWin.Position
				i.Changed:Connect(function()
					if i.UserInputState == Enum.UserInputState.End then dragEd = false end
				end)
			end
		end)
		UIS.InputChanged:Connect(function(i)
			if dragEd and i.UserInputType == Enum.UserInputType.MouseMovement then
				local d = i.Position - dsEd
				editorWin.Position = UDim2.new(spEd.X.Scale, spEd.X.Offset + d.X, spEd.Y.Scale, spEd.Y.Offset + d.Y)
			end
		end)
	end

	local CELL_SZ = 19
	local GRID_PX = GRID_SIZE * CELL_SZ
	local gridHolder = new("Frame", {
		Parent = editorWin,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 56),
		Size = UDim2.fromOffset(GRID_PX + 8, GRID_PX + 8),
		BackgroundColor3 = C.bg,
		BorderSizePixel = 0
	})
	corner(gridHolder, 12)
	stroke(gridHolder, C.line)

	local cellButtons = {}
	local currentGrid = decodeGrid()

	local function refreshCrosshairVisuals()
		currentGrid = decodeGrid()
		local pxSz = math.clamp(num(Hub.State.xhair_px, 3), 1, 12)
		local tr = math.clamp(num(Hub.State.xhair_tr, 0), 0, 0.95)
		liveCrosshair.Size = UDim2.fromOffset(GRID_SIZE * pxSz, GRID_SIZE * pxSz)
		liveCrosshair.Visible = Hub.State.xhair_on == true

		for r = 1, GRID_SIZE do
			for c = 1, GRID_SIZE do
				local idx = (r - 1) * GRID_SIZE + c
				local val = currentGrid[idx] or 0
				local lp = livePixels[idx]
				if lp then
					lp.Size = UDim2.fromOffset(pxSz, pxSz)
					lp.Position = UDim2.fromOffset((c - 1) * pxSz, (r - 1) * pxSz)
					if val > 0 then
						lp.Visible = true
						lp.BackgroundColor3 = getColorByIndex(val)
						lp.BackgroundTransparency = tr
					else
						lp.Visible = false
					end
				end
				local cb = cellButtons[idx]
				if cb then
					if val > 0 then
						cb.BackgroundColor3 = getColorByIndex(val)
					else
						local isCenter = (r == CENTER or c == CENTER)
						cb.BackgroundColor3 = isCenter and C.panel2 or C.panel
					end
				end
			end
		end
	end

	local function paintCell(idx)
		currentGrid[idx] = isErasing and 0 or selectedColorIdx
		saveGrid(currentGrid)
		refreshCrosshairVisuals()
	end

	for r = 1, GRID_SIZE do
		for c = 1, GRID_SIZE do
			local idx = (r - 1) * GRID_SIZE + c
			local isCenterCell = (r == CENTER and c == CENTER)
			local btn = new("TextButton", {
				Parent = gridHolder,
				Position = UDim2.fromOffset(4 + (c - 1) * CELL_SZ, 4 + (r - 1) * CELL_SZ),
				Size = UDim2.fromOffset(CELL_SZ - 1, CELL_SZ - 1),
				BackgroundColor3 = C.panel,
				BorderSizePixel = 0,
				Text = isCenterCell and "+" or "",
				TextColor3 = C.dim,
				TextSize = 9,
				Font = FONTB,
				AutoButtonColor = false
			})
			corner(btn, 4)
			cellButtons[idx] = btn

			btn.MouseButton1Down:Connect(function()
				isMouseDown = true
				paintCell(idx)
			end)
			btn.MouseEnter:Connect(function()
				if isMouseDown then
					paintCell(idx)
				end
			end)
		end
	end

	UIS.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then
			isMouseDown = false
		end
	end)

	local palRow = new("Frame", {
		Parent = editorWin,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 358),
		Size = UDim2.new(1, -36, 0, 28),
		BackgroundTransparency = 1
	})
	new("UIListLayout", { Parent = palRow, FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), HorizontalAlignment = Enum.HorizontalAlignment.Center })

	local palStrokes = {}
	local function updatePaletteSelection()
		for idx, st in ipairs(palStrokes) do
			st.Color = (not isErasing and selectedColorIdx == idx) and Color3.new(1, 1, 1) or C.line
			st.Thickness = (not isErasing and selectedColorIdx == idx) and 2 or 1
		end
	end

	for idx, p in ipairs(PALETTE) do
		local colBtn = new("TextButton", {
			Parent = palRow,
			Size = UDim2.fromOffset(26, 26),
			BackgroundColor3 = p[2] or C.acc,
			BorderSizePixel = 0,
			Text = "",
			AutoButtonColor = false
		})
		corner(colBtn, 8)
		if idx == 1 then accent(colBtn, "BackgroundColor3") end
		local st = stroke(colBtn, C.line)
		palStrokes[idx] = st
		colBtn.MouseButton1Click:Connect(function()
			isErasing = false
			selectedColorIdx = idx
			updatePaletteSelection()
		end)
	end

	local eraseBtn = new("TextButton", {
		Parent = palRow,
		Size = UDim2.fromOffset(68, 26),
		BackgroundColor3 = C.panel2,
		BorderSizePixel = 0,
		Text = "Ластик",
		TextColor3 = C.text,
		TextSize = 10,
		Font = FONTB,
		AutoButtonColor = false
	})
	corner(eraseBtn, 8)
	local eraseStroke = stroke(eraseBtn, C.line)
	eraseBtn.MouseButton1Click:Connect(function()
		isErasing = true
		updatePaletteSelection()
		eraseStroke.Color = C.acc
	end)
	updatePaletteSelection()

	local presetRow1 = new("Frame", {
		Parent = editorWin,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 396),
		Size = UDim2.new(1, -36, 0, 28),
		BackgroundTransparency = 1
	})
	new("UIListLayout", { Parent = presetRow1, FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), HorizontalAlignment = Enum.HorizontalAlignment.Center })

	local function makePresetBtn(parent, txt, fn)
		local b = new("TextButton", {
			Parent = parent,
			Size = UDim2.fromOffset(88, 26),
			BackgroundColor3 = C.panel,
			BorderSizePixel = 0,
			Text = txt,
			TextColor3 = C.text,
			TextSize = 10,
			Font = FONTB,
			AutoButtonColor = false
		})
		corner(b, 8)
		addBtnAnim(b, stroke(b), false)
		b.MouseButton1Click:Connect(function()
			fn()
			if not Hub.State.xhair_on then
				Hub.State.xhair_on = true
				for _, r in ipairs(refreshers) do pcall(r) end
				ovRefresh()
			end
			refreshCrosshairVisuals()
		end)
	end

	makePresetBtn(presetRow1, "Крестик", function()
		Hub.State.xhair_data = getDefaultPattern()
	end)

	makePresetBtn(presetRow1, "Точка", function()
		local t = {}
		for i = 1, GRID_SIZE * GRID_SIZE do t[i] = 0 end
		for r = CENTER - 1, CENTER + 1 do
			for c = CENTER - 1, CENTER + 1 do
				t[(r - 1) * GRID_SIZE + c] = selectedColorIdx
			end
		end
		saveGrid(t)
	end)

	makePresetBtn(presetRow1, "Круг", function()
		local t = {}
		for r = 1, GRID_SIZE do
			for c = 1, GRID_SIZE do
				local d = math.sqrt((r - CENTER) ^ 2 + (c - CENTER) ^ 2)
				local idx = (r - 1) * GRID_SIZE + c
				if math.abs(d - 4) < 0.75 or (r == CENTER and c == CENTER) then
					t[idx] = selectedColorIdx
				else
					t[idx] = 0
				end
			end
		end
		saveGrid(t)
	end)

	makePresetBtn(presetRow1, "Очистить", function()
		local t = {}
		for i = 1, GRID_SIZE * GRID_SIZE do t[i] = 0 end
		saveGrid(t)
	end)

	local doneEdBtn = new("TextButton", {
		Parent = editorWin,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 434),
		Size = UDim2.new(1, -36, 0, 34),
		BackgroundColor3 = C.acc2,
		BorderSizePixel = 0,
		Text = "СОХРАНИТЬ И ВКЛЮЧИТЬ ПРИЦЕЛ",
		TextColor3 = Color3.new(1, 1, 1),
		TextSize = 11,
		Font = FONTB,
		AutoButtonColor = false
	})
	corner(doneEdBtn, 11)
	accent(doneEdBtn, "BackgroundColor3")
	addBtnAnim(doneEdBtn, nil, true)

	local function closeEditor()
		tween(editorWin, 0.22, { GroupTransparency = 1 })
		tween(edScale, 0.22, { Scale = 0.92 })
		task.delay(0.22, function()
			if editorWin.GroupTransparency >= 0.95 then
				editorWin.Visible = false
			end
		end)
	end

	closeEdBtn.MouseButton1Click:Connect(closeEditor)
	doneEdBtn.MouseButton1Click:Connect(function()
		Hub.State.xhair_on = true
		for _, r in ipairs(refreshers) do pcall(r) end
		ovRefresh()
		refreshCrosshairVisuals()
		closeEditor()
	end)

	Hub.Hooks.xhair_open = function()
		if editorWin.Visible and editorWin.GroupTransparency < 0.5 then
			closeEditor()
		else
			refreshCrosshairVisuals()
			editorWin.Visible = true
			edScale.Scale = 0.92
			tween(editorWin, 0.28, { GroupTransparency = 0 }, Enum.EasingStyle.Quint)
			tween(edScale, 0.32, { Scale = 1 }, Enum.EasingStyle.Back)
		end
	end

	Hub.Hooks.xhair = function(v)
		refreshCrosshairVisuals()
		liveCrosshair.Visible = v == true
	end

	table.insert(refreshers, refreshCrosshairVisuals)
end

-- ============================================================================
-- CHANGE SKY BY ID (УСТАНОВКА МОДЕЛЬКИ НЕБА ПО ID ВО ВКЛАДКЕ VISUAL)
-- ============================================================================
do
	local savedDefaultSkies = {}
	local hasSavedOriginalSky = false

	local function backupOriginalSky()
		if hasSavedOriginalSky then return end
		hasSavedOriginalSky = true
		savedDefaultSkies = {}
		for _, child in pairs(Lighting:GetChildren()) do
			if child:IsA("Sky") then
				local ok, cl = pcall(function() return child:Clone() end)
				if ok and cl then table.insert(savedDefaultSkies, cl) end
			end
		end
	end

	local function applyCustomSkyId()
		local rawId = tostring(Hub.State.skyid_id or "20160702"):match("%d+") or "20160702"
		backupOriginalSky()

		for _, child in pairs(Lighting:GetChildren()) do
			if child:IsA("Sky") then
				child:Destroy()
			end
		end

		local success, result = pcall(function()
			return game:GetObjects("rbxassetid://" .. tostring(rawId))
		end)

		if success and result and result[1] then
			local loadedItem = result[1]
			local skyFound = false

			if loadedItem:IsA("Sky") then
				loadedItem.Parent = Lighting
				skyFound = true
			else
				for _, item in pairs(loadedItem:GetDescendants()) do
					if item:IsA("Sky") then
						item.Parent = Lighting
						skyFound = true
						break
					end
				end
			end

			if skyFound then
				print("Небо успешно установлено! ID: " .. tostring(rawId))
				return "Установлено"
			else
				warn("Загрузка прошла, но в модели с ID " .. tostring(rawId) .. " нет объекта Sky.")
				return "Нет Sky в ID"
			end
		else
			warn("Ошибка загрузки неба! Проверь ID: " .. tostring(rawId))
			return "Ошибка ID"
		end
	end

	local function restoreOriginalSky()
		if not hasSavedOriginalSky then return end
		for _, child in pairs(Lighting:GetChildren()) do
			if child:IsA("Sky") then
				child:Destroy()
			end
		end
		for _, sk in ipairs(savedDefaultSkies) do
			pcall(function() sk:Clone().Parent = Lighting end)
		end
	end

	Hub.Hooks.skyid = function(v)
		if v then
			task.spawn(applyCustomSkyId)
		else
			restoreOriginalSky()
		end
	end

	Hub.Hooks.skyid_apply = function()
		if not Hub.State.skyid_on then
			Hub.State.skyid_on = true
			for _, r in ipairs(refreshers) do pcall(r) end
			ovRefresh()
		end
		return applyCustomSkyId()
	end
end

-- ============================================================================
-- SLOW MODE (ВО ВКЛАДКЕ PLAYER)
-- ============================================================================
do
	local isHolding = false
	local character = plr.Character

	plr.CharacterAdded:Connect(function(newChar)
		character = newChar
	end)

	local function getTriggerKeyCode()
		local keyName = Hub.State.slowbot_hold or "LeftShift"
		return Enum.KeyCode[keyName] or Enum.KeyCode.LeftShift
	end

	local function resetWalkSpeed()
		local ch = character or plr.Character
		local humanoid = ch and ch:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = num(Hub.State.slowbot_def, 16)
		end
	end

	UIS.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed or not Hub.State.slowbot_on then return end
		if input.KeyCode == getTriggerKeyCode() then
			isHolding = true
		end
	end)

	UIS.InputEnded:Connect(function(input)
		if input.KeyCode == getTriggerKeyCode() then
			if isHolding then
				isHolding = false
				if Hub.State.slowbot_on then
					resetWalkSpeed()
				end
			end
		end
	end)

	RS.RenderStepped:Connect(function()
		if not Hub.State.slowbot_on or not isHolding then return end
		local ch = character or plr.Character
		local humanoid = ch and ch:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = num(Hub.State.slowbot_speed, 8)
		end
	end)

	Hub.Hooks.slowbot = function(v)
		if not v then
			isHolding = false
			resetWalkSpeed()
		end
	end
end

-- ============================================================================
-- RAGE AURA (ВСТРОЕННЫЙ СКРИПТ RAGE AURA ВО ВКЛАДКЕ PLAYER)
-- ============================================================================
do
	local EXTRA = 0.01
	local lastFire = 0
	local lastShot = 0
	local shotId = 0
	local hookInstalled = false
	local Remotes, ShootReplicate, Bindables, SpawnBullet, HitBindable

	local function initRemotes()
		if ShootReplicate then return true end
		pcall(function()
			Remotes = ReplicatedStorage:FindFirstChild("Remotes") or ReplicatedStorage:WaitForChild("Remotes", 3)
			if Remotes then ShootReplicate = Remotes:FindFirstChild("ShootReplicate") or Remotes:WaitForChild("ShootReplicate", 3) end
			Bindables = ReplicatedStorage:FindFirstChild("Bindables") or ReplicatedStorage:WaitForChild("Bindables", 3)
			if Bindables then
				SpawnBullet = Bindables:FindFirstChild("SpawnBullet") or Bindables:WaitForChild("SpawnBullet", 3)
				HitBindable = Bindables:FindFirstChild("Hit") or Bindables:WaitForChild("Hit", 3)
			end
		end)
		if ShootReplicate and not hookInstalled and hookfunction then
			hookInstalled = true
			pcall(function()
				local old
				old = hookfunction(ShootReplicate.FireServer, function(self, ...)
					if Hub.State.rage_on then
						local cd = num(Hub.State.rage_cd, 0.5)
						local now = os.clock()
						if now - lastFire < cd + EXTRA then
							return
						end
						lastFire = now
					end
					return old(self, ...)
				end)
			end)
		end
		return ShootReplicate ~= nil
	end

	local function getIgnoreList()
		local list = { plr.Character, Workspace:FindFirstChild("Bin"), Workspace:FindFirstChild("Destructibles") }
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= plr and p.Team == plr.Team and p.Character then
				table.insert(list, p.Character)
			end
		end
		local side = plr:GetAttribute("MatchSide")
		local chars = Workspace:FindFirstChild("Characters")
		if chars and typeof(side) == "string" then
			for _, m in ipairs(chars:GetChildren()) do
				if m:IsA("Model") and m:GetAttribute("MatchSide") == side then
					table.insert(list, m)
				end
			end
		end
		return list
	end

	local function isEnemy(model)
		if not model or not model:IsA("Model") then return false end
		local p = Players:GetPlayerFromCharacter(model)
		if p then
			if p == plr then return false end
			if plr.Team and p.Team == plr.Team then return false end
			return true
		end
		if Hub.State.rage_bots == true then return false end
		local side = plr:GetAttribute("MatchSide")
		local mside = model:GetAttribute("MatchSide")
		if typeof(side) == "string" and mside == side then return false end
		return true
	end

	local function visiblePart(model, eye, ignore)
		local range = num(Hub.State.rage_range, 1000)
		local headOnly = Hub.State.rage_head == true
		local best, bestDist = nil, range
		for _, part in ipairs(model:GetDescendants()) do
			if part:IsA("BasePart") then
				if headOnly and part.Name ~= "Head" then continue end
				if part.Name == "HumanoidRootPart" then continue end
				local d = (part.Position - eye).Magnitude
				if d < bestDist and d > 0.01 then
					local rp = RaycastParams.new()
					rp.FilterType = Enum.RaycastFilterType.Exclude
					rp.FilterDescendantsInstances = ignore
					rp.IgnoreWater = true
					local hit = Workspace:Raycast(eye, (part.Position - eye).Unit * d, rp)
					if not hit or hit.Instance:IsDescendantOf(model) then
						best = part
						bestDist = d
					end
				end
			end
		end
		return best, bestDist
	end

	local function findTarget()
		local Cam = Workspace.CurrentCamera
		if not Cam then return nil end
		local eye = Cam.CFrame.Position
		local ignore = getIgnoreList()
		local chars = Workspace:FindFirstChild("Characters")
		if not chars then return nil end
		local best, bestDist = nil, num(Hub.State.rage_range, 1000)
		for _, model in ipairs(chars:GetChildren()) do
			if model:IsA("Model") and isEnemy(model) then
				local hum = model:FindFirstChildOfClass("Humanoid")
				if hum and hum.Health > 0 then
					local part, dist = visiblePart(model, eye, ignore)
					if part and dist < bestDist then
						best = { model = model, part = part, pos = part.Position, dist = dist }
						bestDist = dist
					end
				end
			end
		end
		return best
	end

	local function buildPacket(target)
		local char = plr.Character
		local Cam = Workspace.CurrentCamera
		if not char or not Cam then return nil end
		local origin = Cam.CFrame.Position
		local targetPos = target.pos
		local dir = targetPos - origin
		if dir.Magnitude < 0.01 then return nil end
		local unit = dir.Unit
		local segments = {
			{
				from = nil,
				hitPos = targetPos,
				hitNormal = -unit,
				hitInstance = target.part,
				isCharacterHit = true,
			}
		}
		shotId = shotId + 1
		local packet = {
			kind = "bullet",
			mode = "single",
			id = shotId,
			reloadSoundDelay = nil,
			segments = segments,
			origin = origin,
			firedAt = Workspace:GetServerTimeNow(),
			to = targetPos,
			hitInstance = target.part,
			hitPos = targetPos,
			hitNormal = -unit,
			isCharacterHit = true,
			ownerUserId = plr.UserId,
			effects = { Ricochet = 0, Barrage = 0, Frost = 0 },
			chainHits = nil,
			isADS = false,
			bulletFx = nil,
		}
		return packet
	end

	local function fireAt(target)
		if not initRemotes() then return end
		local packet = buildPacket(target)
		if not packet then return end
		lastFire = 0
		pcall(function() ShootReplicate:FireServer(packet) end)
		if SpawnBullet then pcall(function() SpawnBullet:Fire(packet) end) end
		if spawnBulletTracer then
			pcall(spawnBulletTracer, packet.origin, packet.to)
		end
		if HitBindable then
			pcall(function()
				local dmg = 100
				if target.part.Name == "Head" then dmg = 250
				elseif target.part.Name:find("Leg") then dmg = 75 end
				HitBindable:Fire(target.model, dmg, target.part.Name == "Head", false, nil, nil, nil)
			end)
		end
	end

	task.spawn(function()
		while true do
			task.wait(0.03)
			if Hub.State.rage_on then
				initRemotes()
				local char = plr.Character
				local hum = char and char:FindFirstChildOfClass("Humanoid")
				local tool = char and char:FindFirstChildOfClass("Tool")
				if hum and hum.Health > 0 and hum.WalkSpeed > 0 and tool then
					local hasRev = tool.Name:lower():find("revolver") or char:FindFirstChild("RevolverRig")
					if hasRev and not (tool:GetAttribute("Reloading") == true) then
						local target = findTarget()
						if target then
							if Hub.State.rage_aim ~= false then
								local Cam = Workspace.CurrentCamera
								local eye = Cam.CFrame.Position
								local d = (target.pos - eye)
								if d.Magnitude > 0.01 then
									Cam.CFrame = CFrame.lookAt(eye, eye + d.Unit)
								end
							end
							local now = os.clock()
							local cd = num(Hub.State.rage_cd, 0.5)
							if now - lastShot >= cd + EXTRA then
								lastShot = now
								pcall(fireAt, target)
							end
						end
					end
				end
			end
		end
	end)

	Hub.Hooks.rage = function(v)
		if v then task.spawn(initRemotes) end
	end
end

-- ============================================================================
-- THIRD PERSON (С БИНДОМ ВКЛ/ВЫКЛ И КНОПКОЙ НАСТРОЙКИ РАКУРСА)
-- ============================================================================
do
	local state = 0
	local hasSavedOffset = false
	local freeCamPos, yaw, pitch, charYaw = Vector3.new(), 0, 0, 0
	local localOffsetPos, localYawOffset = Vector3.new(0, 2.5, 8), 0
	local origCameraMode = plr.CameraMode
	local INVERT_Y, SENSITIVITY = -1, 0.0045
	local moveKeys = { W=false,A=false,S=false,D=false,Up=false,Down=false,Shift=false }
	local touching, lastPos = false, nil
	local bound = false

	local function bindMove()
		if bound then return end
		bound = true
		UIS.InputBegan:Connect(function(i, gp)
			if gp then return end
			local k = i.KeyCode
			if k == Enum.KeyCode.W then moveKeys.W = true
			elseif k == Enum.KeyCode.S then moveKeys.S = true
			elseif k == Enum.KeyCode.A then moveKeys.A = true
			elseif k == Enum.KeyCode.D then moveKeys.D = true
			elseif k == Enum.KeyCode.E or k == Enum.KeyCode.Space then moveKeys.Up = true
			elseif k == Enum.KeyCode.Q or k == Enum.KeyCode.LeftControl then moveKeys.Down = true
			elseif k == Enum.KeyCode.LeftShift then moveKeys.Shift = true end
		end)
		UIS.InputEnded:Connect(function(i)
			local k = i.KeyCode
			if k == Enum.KeyCode.W then moveKeys.W = false
			elseif k == Enum.KeyCode.S then moveKeys.S = false
			elseif k == Enum.KeyCode.A then moveKeys.A = false
			elseif k == Enum.KeyCode.D then moveKeys.D = false
			elseif k == Enum.KeyCode.E or k == Enum.KeyCode.Space then moveKeys.Up = false
			elseif k == Enum.KeyCode.Q or k == Enum.KeyCode.LeftControl then moveKeys.Down = false
			elseif k == Enum.KeyCode.LeftShift then moveKeys.Shift = false end
		end)
		UIS.InputBegan:Connect(function(i, gp)
			if gp then return end
			if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.MouseButton2
				or i.UserInputType == Enum.UserInputType.Touch then
				touching = true lastPos = i.Position
			end
		end)
		UIS.InputEnded:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.MouseButton2
				or i.UserInputType == Enum.UserInputType.Touch then
				touching = false lastPos = nil
			end
		end)
		UIS.InputChanged:Connect(function(i)
			if state ~= 1 and state ~= 2 then return end
			local d = Vector2.new()
			if i.UserInputType == Enum.UserInputType.MouseMovement then
				if i.Delta.Magnitude > 0 then
					if state == 1 or touching or UIS.MouseBehavior ~= Enum.MouseBehavior.Default then
						d = Vector2.new(i.Delta.X, i.Delta.Y)
					end
				elseif touching and lastPos then
					d = Vector2.new(i.Position.X - lastPos.X, i.Position.Y - lastPos.Y)
					lastPos = i.Position
				end
			elseif i.UserInputType == Enum.UserInputType.Touch and touching then
				if i.Delta.Magnitude > 0 then d = Vector2.new(i.Delta.X, i.Delta.Y)
				elseif lastPos then d = Vector2.new(i.Position.X - lastPos.X, i.Position.Y - lastPos.Y) lastPos = i.Position end
			end
			if d.Magnitude > 0 then
				if state == 1 then
					yaw = yaw - d.X * SENSITIVITY
					pitch = math.clamp(pitch + d.Y * INVERT_Y * SENSITIVITY, -math.rad(89), math.rad(89))
				elseif state == 2 then
					charYaw = charYaw - d.X * SENSITIVITY
					pitch = math.clamp(pitch + d.Y * INVERT_Y * SENSITIVITY, -math.rad(89), math.rad(89))
				end
			end
		end)
	end

	local function showChar(ch)
		if not ch or Hub.State.morph_on then return end
		for _, p in ipairs(ch:GetDescendants()) do
			if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then p.LocalTransparencyModifier = 0
			elseif p:IsA("Decal") then p.Transparency = 0 end
		end
	end

	local function startFreeCamSetup()
		local ch = plr.Character
		local root = ch and ch:FindFirstChild("HumanoidRootPart")
		if not root then return "No Character" end
		bindMove()
		RS:UnbindFromRenderStep("FluxFreeCam")
		RS:UnbindFromRenderStep("FluxCamFollow")

		state = 1
		origCameraMode = plr.CameraMode
		plr.CameraMode = Enum.CameraMode.Classic
		local _, ry = root.CFrame:ToEulerAnglesYXZ()
		charYaw = ry
		root.CFrame = CFrame.new(root.Position) * CFrame.Angles(0, charYaw, 0)
		root.Anchored = true
		freeCamPos = camera.CFrame.Position
		local rx, cy = camera.CFrame:ToEulerAnglesYXZ()
		pitch, yaw = rx, cy
		camera.CameraType = Enum.CameraType.Scriptable
		RS:BindToRenderStep("FluxFreeCam", Enum.RenderPriority.Camera.Value + 1, function(dt)
			showChar(ch)
			local rot = CFrame.fromEulerAnglesYXZ(pitch, yaw, 0)
			local speed = moveKeys.Shift and 75 or 30
			local mv = Vector3.new()
			if moveKeys.W then mv += rot.LookVector end
			if moveKeys.S then mv -= rot.LookVector end
			if moveKeys.D then mv += rot.RightVector end
			if moveKeys.A then mv -= rot.RightVector end
			if moveKeys.Up then mv += Vector3.new(0,1,0) end
			if moveKeys.Down then mv -= Vector3.new(0,1,0) end
			if mv.Magnitude > 0 then freeCamPos += mv.Unit * speed * dt end
			camera.CFrame = CFrame.new(freeCamPos) * rot
		end)
		return "Save Angle"
	end

	local function startFollowCam(fromFreeCam)
		local ch = plr.Character
		local root = ch and ch:FindFirstChild("HumanoidRootPart")
		if not root then return "No Character" end
		bindMove()
		RS:UnbindFromRenderStep("FluxFreeCam")
		RS:UnbindFromRenderStep("FluxCamFollow")

		state = 2
		origCameraMode = plr.CameraMode
		plr.CameraMode = Enum.CameraMode.Classic
		local _, ry = root.CFrame:ToEulerAnglesYXZ()
		charYaw = ry
		if fromFreeCam then
			local base = CFrame.new(root.Position) * CFrame.Angles(0, charYaw, 0)
			localOffsetPos = base:PointToObjectSpace(freeCamPos)
			localYawOffset = yaw - charYaw
			hasSavedOffset = true
		end
		root.Anchored = false
		RS:BindToRenderStep("FluxCamFollow", Enum.RenderPriority.Camera.Value + 1, function()
			local c = plr.Character
			local r = c and c:FindFirstChild("HumanoidRootPart")
			local h = c and c:FindFirstChildOfClass("Humanoid")
			if not r then return end
			showChar(c)
			camera.CameraType = Enum.CameraType.Scriptable
			if not Hub.State.spin_on then
				if touching or UIS.MouseBehavior ~= Enum.MouseBehavior.Default then
					if h then h.AutoRotate = false end
					r.CFrame = CFrame.new(r.Position) * CFrame.Angles(0, charYaw, 0)
				else
					if h then h.AutoRotate = true end
					local _, cy = r.CFrame:ToEulerAnglesYXZ()
					charYaw = cy
				end
			end
			local baseCF = CFrame.new(r.Position) * CFrame.Angles(0, charYaw, 0)
			local wp = baseCF:PointToWorldSpace(localOffsetPos)
			local finalYaw = charYaw + localYawOffset
			camera.CFrame = CFrame.new(wp) * CFrame.fromEulerAnglesYXZ(pitch, finalYaw, 0)
		end)
		return "Setup Third Person"
	end

	local function stopThirdPerson()
		state = 0
		RS:UnbindFromRenderStep("FluxFreeCam")
		RS:UnbindFromRenderStep("FluxCamFollow")
		local ch2 = plr.Character
		local r = ch2 and ch2:FindFirstChild("HumanoidRootPart")
		local h = ch2 and ch2:FindFirstChildOfClass("Humanoid")
		if r then r.Anchored = false end
		if h and not Hub.State.spin_on then h.AutoRotate = true end
		plr.CameraMode = origCameraMode
		camera.CameraType = Enum.CameraType.Custom
		return "Setup Third Person"
	end

	Hub.Hooks.camfree = function(v)
		if v then
			if hasSavedOffset then
				startFollowCam(false)
			else
				startFreeCamSetup()
			end
		else
			stopThirdPerson()
		end
		for _, r in ipairs(refreshers) do pcall(r) end
	end

	Hub.Hooks.camfree_setup = function()
		if not Hub.State.camfree_on then
			Hub.State.camfree_on = true
			for _, r in ipairs(refreshers) do pcall(r) end
			ovRefresh()
			return startFreeCamSetup()
		end
		if state == 1 then
			return startFollowCam(true)
		else
			return startFreeCamSetup()
		end
	end

	Hub.Hooks.camfree_text = function()
		if state == 1 then
			return "Save Angle"
		end
		return "Setup Third Person"
	end
end

-- ============================================================================
-- SPINBOT (РАБОТАЕТ ОТ ПЕРВОГО И ОТ ТРЕТЬЕГО ЛИЦА ВЕЗДЕ)
-- ============================================================================
do
	local spinAngle = 0
	Hub.Hooks.spin = function(v)
		stopConns("spin")
		local ch = plr.Character
		local hum = ch and ch:FindFirstChildOfClass("Humanoid")
		if not v then
			if hum then hum.AutoRotate = true end
			return
		end
		addConn("spin", RS.RenderStepped:Connect(function(dt)
			local curChar = plr.Character
			local hrp = curChar and curChar:FindFirstChild("HumanoidRootPart")
			local curHum = curChar and curChar:FindFirstChildOfClass("Humanoid")
			if not hrp or not curHum or curHum.Health <= 0 then return end

			curHum.AutoRotate = false
			local speed = num(Hub.State.spin_speed, 25)
			spinAngle = (spinAngle + math.rad(speed) * (dt * 60)) % (math.pi * 2)

			local savedCamCF = camera.CFrame
			hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, spinAngle, 0)
			local head = curChar:FindFirstChild("Head")
			if head and (savedCamCF.Position - head.Position).Magnitude < 2 then
				camera.CFrame = savedCamCF
			end
		end))
	end
end

Hub.Hooks.bhop = function(v)
	stopConns("bhop")
	if not v then return end
	local canTp = true
	addConn("bhop", RS.Heartbeat:Connect(function()
		if not UIS:IsKeyDown(Enum.KeyCode.Space) then return end
		local ch = plr.Character
		local hum = ch and ch:FindFirstChildOfClass("Humanoid")
		local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
		if not hum or not hrp or hum.Health <= 0 then return end
		local moveDir = hum.MoveDirection
		if moveDir.Magnitude == 0 then
			local look = camera.CFrame.LookVector
			moveDir = Vector3.new(look.X, 0, look.Z)
		end
		moveDir = moveDir.Magnitude > 0 and moveDir.Unit or Vector3.zero
		local speed = num(Hub.State.bhop_speed, 120)
		local mode = Hub.State.bhop_mode or "NORMAL"
		if hum.FloorMaterial ~= Enum.Material.Air then
			hum.Jump = true
			if mode == "TP" and canTp and moveDir.Magnitude > 0 then
				canTp = false
				hrp.CFrame = hrp.CFrame + moveDir * (speed * 0.35)
				task.delay(0.15, function() canTp = true end)
			end
		end
		if mode == "NORMAL" and hum.FloorMaterial == Enum.Material.Air and moveDir.Magnitude > 0 then
			local vy = hrp.AssemblyLinearVelocity.Y
			hrp.AssemblyLinearVelocity = Vector3.new(moveDir.X * speed, vy, moveDir.Z * speed)
		end
	end))
end

Hub.Hooks.noclip = function(v)
	stopConns("noclip")
	if not v then return end
	addConn("noclip", RS.Stepped:Connect(function()
		local ch = plr.Character
		if not ch then return end
		for _, part in ipairs(ch:GetDescendants()) do
			if part:IsA("BasePart") then part.CanCollide = false end
		end
	end))
end

Hub.Hooks.cursor = function(v)
	stopConns("cursor")
	if not v then return end
	addConn("cursor", RS.RenderStepped:Connect(function()
		UIS.MouseBehavior = Enum.MouseBehavior.Default
	end))
end

do
	local flickActive, flickProgress, flickStart, flickTarget = false, 0, nil, nil
	local FLICK_DURATION, FLICK_STRENGTH = 0.15, 180
	local function humanizedOffset(p)
		local s = p * p * (3 - 2 * p)
		return s,
			math.sin(p * math.pi * 30) * 0.3 * (1 - p),
			math.cos(p * math.pi * 25 + 1.2) * 0.3 * (1 - p),
			math.sin(p * math.pi) * 1.5
	end
	local function startFlick()
		if flickActive then return end
		local sign = (math.random(1, 2) == 1 and 1) or -1
		local yaw = math.rad(FLICK_STRENGTH * sign * (0.85 + math.random() * 0.3))
		local pitch = math.rad(math.random(-5, 5) * 0.5)
		local rot = CFrame.Angles(pitch, 0, 0) * CFrame.Angles(0, yaw, 0)
		local pos = camera.CFrame.Position
		local newCF = CFrame.new(pos) * (camera.CFrame.Rotation * rot)
		flickTarget = CFrame.new(pos, newCF.LookVector + pos)
		flickStart = camera.CFrame
		flickProgress = 0
		flickActive = true
	end
	RS.RenderStepped:Connect(function(dt)
		if not flickActive then return end
		flickProgress = flickProgress + dt / FLICK_DURATION
		if flickProgress >= 1 then
			if flickTarget then camera.CFrame = flickTarget end
			flickActive = false
			return
		end
		local sp, sx, sy, ay = humanizedOffset(flickProgress)
		local startPos = flickStart.Position
		local curLook = flickStart.LookVector:Lerp(flickTarget.LookVector, sp).Unit
		local curUp = flickStart.UpVector:Lerp(flickTarget.UpVector, sp).Unit
		local shake = flickStart.RightVector * math.rad(sx) + flickStart.UpVector * math.rad(sy)
		local arc = flickStart.UpVector * math.rad(ay * 0.8)
		camera.CFrame = CFrame.lookAt(startPos, startPos + (curLook + shake + arc).Unit, curUp)
	end)

	local function shoot(hit)
		if not hit then return end
		local model = hit:FindFirstAncestorOfClass("Model")
		if not model or model == plr.Character then return end
		local hum = model:FindFirstChildOfClass("Humanoid")
		if not hum then return end
		local part = Hub.State.trig_part or "All"
		local ok = part == "All"
			or (part == "Head" and hit.Name == "Head")
			or (part == "Torso" and (hit.Name == "Torso" or hit.Name == "UpperTorso" or hit.Name == "LowerTorso" or hit.Name == "HumanoidRootPart"))
		if not ok then return end
		if Hub.State.trig_mode == "WithAim" then startFlick() end
		if mouse1press then pcall(mouse1press) end
		task.wait()
		if mouse1release then pcall(mouse1release) end
	end

	Hub.Hooks.trig = function(v)
		stopConns("trig")
		if not v then return end
		addConn("trig", RS.RenderStepped:Connect(function()
			if mouse.Target then shoot(mouse.Target) end
		end))
	end
end

do
	local fovCircle = new("Frame", { Parent = gui, AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromScale(.5, .5),
		Size = UDim2.fromOffset(400, 400), BackgroundTransparency = 1, Visible = false, ZIndex = 15 })
	new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = fovCircle })
	local fovStroke = stroke(fovCircle, C.acc) accent(fovStroke, "Color")
	local targetLbl = label(gui, "", 12, C.acc, FONTB, UDim2.new(.5, -120, .5, 210), UDim2.fromOffset(240, 20), Enum.TextXAlignment.Center)

	local function refreshFOV()
		local r = math.clamp(num(Hub.State.aim_fov, 200), 10, 1000)
		fovCircle.Size = UDim2.fromOffset(r * 2, r * 2)
		targetLbl.Position = UDim2.new(.5, -120, .5, r + 10)
	end

	local function closestTarget()
		local fov = math.clamp(num(Hub.State.aim_fov, 200), 10, 1000)
		local center = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
		local bestPlr, bestPart, bestDist = nil, nil, fov
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= plr and p.Character then
				if Hub.State.aim_team and p.Team and p.Team == plr.Team then continue end
				local hum = p.Character:FindFirstChildOfClass("Humanoid")
				local part = p.Character:FindFirstChild(Hub.State.aim_part or "Head") or p.Character:FindFirstChild("HumanoidRootPart")
				if hum and hum.Health > 0 and part then
					if Hub.State.aim_vis then
						local rp = RaycastParams.new()
						rp.FilterDescendantsInstances = { plr.Character, camera }
						rp.FilterType = Enum.RaycastFilterType.Exclude
						local dir = part.Position - camera.CFrame.Position
						local res = dir.Magnitude > 0 and Workspace:Raycast(camera.CFrame.Position, dir, rp) or nil
						if res and res.Instance then
							if res.Instance:FindFirstAncestorOfClass("Model") ~= p.Character then continue end
						end
					end
					local sp, onScreen = camera:WorldToViewportPoint(part.Position)
					if onScreen then
						local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
						if d < bestDist then bestDist, bestPlr, bestPart = d, p, part end
					end
				end
			end
		end
		return bestPlr, bestPart
	end

	Hub.Hooks.aim = function(v)
		stopConns("aim")
		refreshFOV()
		fovCircle.Visible = v
		if not v then targetLbl.Text = "" return end
		addConn("aim", RS.RenderStepped:Connect(function(dt)
			refreshFOV()
			local p, part = closestTarget()
			if p and part then
				targetLbl.Text = "Target: " .. p.Name
				local eye = camera.CFrame.Position
				local dir = part.Position - eye
				if dir.Magnitude > 0 then
					local newCF = CFrame.lookAt(eye, eye + dir.Unit)
					local sm = math.clamp(num(Hub.State.aim_smooth, 1), 0.05, 1)
					if sm >= 1 then camera.CFrame = newCF
					else camera.CFrame = camera.CFrame:Lerp(newCF, math.clamp(sm * dt * 60, 0, 1)) end
				end
			else
				targetLbl.Text = ""
			end
		end))
	end
end

do
	local saved, activated, gameFolder = {}, {}, Workspace:FindFirstChild("Game")
	local lastCheck = 0

	local function savePart(part)
		if not part:IsA("BasePart") or saved[part] then return end
		saved[part] = { CanCollide = part.CanCollide, CanQuery = part.CanQuery, CanTouch = part.CanTouch,
			Transparency = part.Transparency, LocalTransparencyModifier = part.LocalTransparencyModifier }
	end
	local function applyPart(part)
		if not part:IsA("BasePart") then return end
		savePart(part)
		pcall(function()
			part.CanCollide = false; part.CanQuery = false; part.CanTouch = false
			if Hub.State.wall_mode == "Transparent" then
				part.Transparency = num(Hub.State.wall_tr, 0.5)
			else
				part.Transparency = saved[part].Transparency
			end
		end)
	end
	local function applyAllVisuals()
		for part, data in pairs(saved) do
			if part and part.Parent then
				pcall(function()
					if Hub.State.wall_mode == "Transparent" then
						part.Transparency = num(Hub.State.wall_tr, 0.5)
					else
						part.Transparency = data.Transparency
						part.LocalTransparencyModifier = data.LocalTransparencyModifier
					end
				end)
			end
		end
	end
	local function processObject(obj)
		if obj:IsA("BasePart") then applyPart(obj) end
		for _, d in ipairs(obj:GetDescendants()) do if d:IsA("BasePart") then applyPart(d) end end
	end
	local function activatePart(part)
		if not part or not saved[part] or activated[part] then return end
		activated[part] = true
		pcall(function()
			part.CanCollide = true; part.CanQuery = false; part.CanTouch = false
			if Hub.State.wall_mode == "Transparent" then part.Transparency = num(Hub.State.wall_tr, 0.5) end
		end)
	end
	local function partsUnderPlayer()
		local result = {}
		local root = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
		if not root or not gameFolder then return result end
		for part in pairs(saved) do if part and part.Parent then pcall(function() part.CanQuery = true end) end end
		local op = OverlapParams.new()
		op.FilterType = Enum.RaycastFilterType.Include
		op.FilterDescendantsInstances = { gameFolder }
		for _, part in ipairs(Workspace:GetPartBoundsInBox(root.CFrame + Vector3.new(0, -2.5, 0), Vector3.new(5, 4, 5), op)) do
			if saved[part] and part.Position.Y + part.Size.Y / 2 <= root.Position.Y + 1.5 then result[part] = true end
		end
		local rp = RaycastParams.new()
		rp.FilterType = Enum.RaycastFilterType.Include
		rp.FilterDescendantsInstances = { gameFolder }
		rp.IgnoreWater = true
		local offsets = { Vector3.new(0,0,0), Vector3.new(1.5,0,0), Vector3.new(-1.5,0,0), Vector3.new(0,0,1.5),
			Vector3.new(0,0,-1.5), Vector3.new(1.2,0,1.2), Vector3.new(-1.2,0,1.2), Vector3.new(1.2,0,-1.2), Vector3.new(-1.2,0,-1.2) }
		for _, off in ipairs(offsets) do
			local ray = Workspace:Raycast(root.Position + off + Vector3.new(0, 1, 0), Vector3.new(0, -6, 0), rp)
			if ray and saved[ray.Instance] then result[ray.Instance] = true end
		end
		for part in pairs(saved) do if part and part.Parent then pcall(function() part.CanQuery = false end) end end
		return result
	end

	Hub.Hooks.wall = function(v)
		stopConns("wall")
		gameFolder = gameFolder or Workspace:FindFirstChild("Game")
		if not v then
			for part, data in pairs(saved) do
				if part and part.Parent then pcall(function()
					part.CanCollide = data.CanCollide; part.CanQuery = data.CanQuery; part.CanTouch = data.CanTouch
					part.Transparency = data.Transparency; part.LocalTransparencyModifier = data.LocalTransparencyModifier
				end) end
			end
			saved, activated = {}, {}
			return
		end
		if not gameFolder then return end
		if next(saved) == nil then for _, obj in ipairs(gameFolder:GetChildren()) do processObject(obj) end end
		applyAllVisuals()
		addConn("wall", RS.Heartbeat:Connect(function()
			local now = os.clock()
			if now - lastCheck < 0.03 then return end
			lastCheck = now
			for part in pairs(partsUnderPlayer()) do activatePart(part) end
		end))
		addConn("wall2", gameFolder.DescendantAdded:Connect(function(obj)
			if not obj:IsA("BasePart") then return end
			task.wait()
			if Hub.State.wall_on then applyPart(obj) end
		end))
	end
end

do
	local turning, progress, startCF, targetCF = false, 0, nil, nil
	local DURATION, STRENGTH = 0.15, 180
	Hub.Hooks.cam = function(v)
		if not v or turning then return end
		local sign = (math.random(1, 2) == 1 and 1) or -1
		local yaw = math.rad(STRENGTH * sign * (0.85 + math.random() * 0.3))
		local pitch = math.rad(math.random(-5, 5) * 0.5)
		local rot = CFrame.Angles(pitch, 0, 0) * CFrame.Angles(0, yaw, 0)
		local pos = camera.CFrame.Position
		local newCF = CFrame.new(pos) * (camera.CFrame.Rotation * rot)
		targetCF = CFrame.new(pos, newCF.LookVector + pos)
		startCF = camera.CFrame
		progress = 0
		turning = true
		if not _conn.camTurn then
			_conn.camTurn = { RS.RenderStepped:Connect(function(dt)
				if not turning then return end
				progress = progress + dt / DURATION
				if progress >= 1 then camera.CFrame = targetCF; turning = false; return end
				local p = progress
				local s = p * p * (3 - 2 * p)
				local sx = math.sin(p * math.pi * 30) * 0.3 * (1 - p)
				local sy = math.cos(p * math.pi * 25 + 1.2) * 0.3 * (1 - p)
				local ay = math.sin(p * math.pi) * 1.5
				local curLook = startCF.LookVector:Lerp(targetCF.LookVector, s).Unit
				local curUp = startCF.UpVector:Lerp(targetCF.UpVector, s).Unit
				local noise = startCF.RightVector * math.rad(sx) + startCF.UpVector * math.rad(sy) + startCF.UpVector * math.rad(ay * 0.8)
				camera.CFrame = CFrame.lookAt(startCF.Position, startCF.Position + (curLook + noise).Unit, curUp)
			end) }
		end
	end
end

-- ============================================================================
-- HITBOX EXPANDER (ТОЛЬКО ПРОТИВНИКИ, ИГНОРИРУЕТ ЛОКАЛЬНОГО ИГРОКА)
-- ============================================================================
do
	local savedParts = {}
	local function restorePart(part)
		local data = savedParts[part]
		if data and part and part.Parent then
			pcall(function() part.Size = data.Size end)
		end
		if part then
			local v = part:FindFirstChild("Flux_VisibleHitbox")
			if v then v:Destroy() end
		end
		savedParts[part] = nil
	end

	local function hitboxCreate(part, size, color)
		if not part or not part:IsA("BasePart") then return end
		if plr.Character and part:IsDescendantOf(plr.Character) then return end
		if not savedParts[part] then savedParts[part] = { Size = part.Size } end
		part.Size = size
		local vis = part:FindFirstChild("Flux_VisibleHitbox")
		if not vis then
			vis = Instance.new("BoxHandleAdornment")
			vis.Name = "Flux_VisibleHitbox"
			vis.Adornee = part
			vis.AlwaysOnTop = true
			vis.ZIndex = 10
			vis.Parent = part
		end
		vis.Size = size
		vis.Color3 = color
		vis.Transparency = Hub.State.hit_vis and num(Hub.State.hit_tr, 0.5) or 1
	end

	local function setupCharacter(ch)
		if not ch or ch == plr.Character or ch.Name == plr.Name then
			if ch then
				for _, p in ipairs(ch:GetDescendants()) do
					if savedParts[p] then restorePart(p) end
				end
			end
			return
		end
		local p = Players:GetPlayerFromCharacter(ch)
		if p == plr then return end

		local head = ch:FindFirstChild("Head")
		if Hub.State.hit_head and head then hitboxCreate(head, Vector3.new(6, 6, 6), Color3.fromRGB(255, 60, 60)) end
		if Hub.State.hit_body then
			local torso = ch:FindFirstChild("UpperTorso") or ch:FindFirstChild("Torso") or ch:FindFirstChild("HumanoidRootPart")
			if torso then hitboxCreate(torso, Vector3.new(6, 7, 6), Color3.fromRGB(60, 140, 255)) end
		end
	end

	local function applyAll()
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= plr and p.Character then
				setupCharacter(p.Character)
			end
		end
		local charsFolder = Workspace:FindFirstChild("Characters")
		if charsFolder then
			for _, m in ipairs(charsFolder:GetChildren()) do
				if m:IsA("Model") and m ~= plr.Character and m.Name ~= plr.Name then
					setupCharacter(m)
				end
			end
		end
		if plr.Character then
			for _, part in ipairs(plr.Character:GetDescendants()) do
				if savedParts[part] then restorePart(part) end
			end
		end
	end

	local function restoreAll()
		for part in pairs(savedParts) do
			restorePart(part)
		end
		savedParts = {}
	end
	_G.FluxHitboxSetup = setupCharacter

	Hub.Hooks.hit = function(v)
		stopConns("hit")
		if v then
			applyAll()
			addConn("hit", RS.Heartbeat:Connect(function()
				if Hub.State.hit_on then applyAll() end
			end))
		else
			restoreAll()
		end
	end
end

do
	local fcOn, savedCharCF, camCF, fcConn, inBegan, inEnded = false, nil, nil, nil, nil, nil
	local yaw, pitch = 0, 0
	local keys = { W = false, A = false, S = false, D = false, Q = false, E = false, Shift = false }
	local function keyDown(i)
		local k = i.KeyCode
		if k == Enum.KeyCode.W then keys.W = true elseif k == Enum.KeyCode.A then keys.A = true
		elseif k == Enum.KeyCode.S then keys.S = true elseif k == Enum.KeyCode.D then keys.D = true
		elseif k == Enum.KeyCode.Q then keys.Q = true elseif k == Enum.KeyCode.E then keys.E = true
		elseif k == Enum.KeyCode.LeftShift then keys.Shift = true end
	end
	local function keyUp(i)
		local k = i.KeyCode
		if k == Enum.KeyCode.W then keys.W = false elseif k == Enum.KeyCode.A then keys.A = false
		elseif k == Enum.KeyCode.S then keys.S = false elseif k == Enum.KeyCode.D then keys.D = false
		elseif k == Enum.KeyCode.Q then keys.Q = false elseif k == Enum.KeyCode.E then keys.E = false
		elseif k == Enum.KeyCode.LeftShift then keys.Shift = false end
	end
	local function enable()
		if fcOn then return end
		local ch = plr.Character or plr.CharacterAdded:Wait()
		local root = ch:WaitForChild("HumanoidRootPart")
		local hum = ch:WaitForChild("Humanoid")
		fcOn = true
		savedCharCF = root.CFrame
		camCF = camera.CFrame
		local look = camCF.LookVector
		yaw = math.atan2(-look.X, -look.Z)
		pitch = math.asin(math.clamp(look.Y, -1, 1))
		hum.AutoRotate = false
		root.CFrame = savedCharCF * CFrame.new(0, -num(Hub.State.free_down, 100), 0)
		root.Anchored = true
		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero
		camera.CameraType = Enum.CameraType.Scriptable
		camera.CFrame = camCF
		UIS.MouseBehavior = Enum.MouseBehavior.LockCenter
		fcConn = RS.RenderStepped:Connect(function(dt)
			if not fcOn then return end
			if not root or not root.Parent then return end
			local md = UIS:GetMouseDelta()
			yaw -= md.X * 0.0025
			pitch = math.clamp(pitch - md.Y * 0.0025, math.rad(-89), math.rad(89))
			local rot = CFrame.Angles(0, yaw, 0) * CFrame.Angles(pitch, 0, 0)
			local mv = Vector3.zero
			if keys.W then mv += Vector3.new(0, 0, -1) end
			if keys.S then mv += Vector3.new(0, 0, 1) end
			if keys.A then mv += Vector3.new(-1, 0, 0) end
			if keys.D then mv += Vector3.new(1, 0, 0) end
			if keys.E then mv += Vector3.new(0, 1, 0) end
			if keys.Q then mv += Vector3.new(0, -1, 0) end
			if mv.Magnitude > 0 then
				local spd = keys.Shift and num(Hub.State.free_fast, 3) or num(Hub.State.free_spd, 1.2)
				camCF += rot:VectorToWorldSpace(mv.Unit) * spd * 60 * dt
			end
			camera.CFrame = CFrame.new(camCF.Position) * rot
			root.CFrame = savedCharCF * CFrame.new(0, -num(Hub.State.free_down, 100), 0)
			root.AssemblyLinearVelocity = Vector3.zero
			root.AssemblyAngularVelocity = Vector3.zero
		end)
		inBegan = UIS.InputBegan:Connect(keyDown)
		inEnded = UIS.InputEnded:Connect(keyUp)
	end
	local function disable()
		if not fcOn then return end
		local curCF = camera.CFrame
		local curPos, curLook = curCF.Position, curCF.LookVector
		fcOn = false
		if fcConn then fcConn:Disconnect() fcConn = nil end
		if inBegan then inBegan:Disconnect() inBegan = nil end
		if inEnded then inEnded:Disconnect() inEnded = nil end
		local ch = plr.Character
		local root = ch and ch:FindFirstChild("HumanoidRootPart")
		local hum = ch and ch:FindFirstChildOfClass("Humanoid")
		if root then
			root.Anchored = false
			root.CFrame = CFrame.lookAt(curPos + Vector3.new(0, 2, 0), curPos + Vector3.new(0, 2, 0) + curLook)
			root.AssemblyLinearVelocity = Vector3.zero
			root.AssemblyAngularVelocity = Vector3.zero
		end
		if hum then hum.AutoRotate = true end
		camera.CameraType = Enum.CameraType.Custom
		if hum then camera.CameraSubject = hum end
		UIS.MouseBehavior = Enum.MouseBehavior.Default
		savedCharCF, camCF = nil, nil
		for k in pairs(keys) do keys[k] = false end
	end
	Hub.Hooks.free = function(v) if v then enable() else disable() end end
end

-- ============================================================================
-- ESP + HITBOX CHAMS
-- ============================================================================
do
	local espLayer = new("Folder", { Parent = gui, Name = "ESPLayer" })
	local chamsLayer = new("Folder", { Parent = gui, Name = "ChamsLayer" })
	local drawings = {}

	local COLOR_VIS = Color3.fromRGB(40, 235, 75)
	local COLOR_HID = Color3.fromRGB(240, 40, 45)

	local HITBOX_NAMES = {
		"Head", "UpperTorso", "LowerTorso", "Torso",
		"LeftUpperArm", "LeftLowerArm", "LeftHand", "Left Arm",
		"RightUpperArm", "RightLowerArm", "RightHand", "Right Arm",
		"LeftUpperLeg", "LeftLowerLeg", "LeftFoot", "Left Leg",
		"RightUpperLeg", "RightLowerLeg", "RightFoot", "Right Leg"
	}

	local function clearChams(d)
		if d.chams then
			for _, box in pairs(d.chams) do
				if box and box.Parent then box:Destroy() end
			end
			d.chams = {}
		end
	end

	local function removeESP(p)
		if drawings[p] then
			clearChams(drawings[p])
			for k, v in pairs(drawings[p]) do
				if k ~= "chams" and v and v.Parent then v:Destroy() end
			end
			drawings[p] = nil
		end
	end

	local function createESP(p)
		if p == plr or drawings[p] then return end
		local box = new("Frame", { Parent = espLayer, BackgroundTransparency = 1, BorderSizePixel = 0, Visible = false })
		stroke(box, C.acc)
		local tracer = new("Frame", { Parent = espLayer, BackgroundColor3 = C.acc, BorderSizePixel = 0,
			AnchorPoint = Vector2.new(.5, .5), Visible = false })
		local nameTag = new("TextLabel", { Parent = espLayer, BackgroundTransparency = 1, TextColor3 = Color3.new(1, 1, 1),
			TextSize = 11, Font = FONTB, Visible = false, TextStrokeTransparency = 0.3 })
		local toolTag = new("TextLabel", { Parent = espLayer, BackgroundTransparency = 1, TextColor3 = C.dim,
			TextSize = 9, Font = FONT, Visible = false, TextStrokeTransparency = 0.3 })
		local hpBg = new("Frame", { Parent = espLayer, BackgroundColor3 = Color3.fromRGB(20, 20, 20), BorderSizePixel = 0, Visible = false })
		local hpBar = new("Frame", { Parent = hpBg, BackgroundColor3 = Color3.fromRGB(50, 220, 50), BorderSizePixel = 0, Size = UDim2.fromScale(1, 1) })
		drawings[p] = { box = box, tracer = tracer, nameTag = nameTag, toolTag = toolTag, hpBg = hpBg, hpBar = hpBar, chams = {} }
	end

	for _, p in ipairs(Players:GetPlayers()) do createESP(p) end
	Players.PlayerAdded:Connect(createESP)
	Players.PlayerRemoving:Connect(removeESP)

	local function isCharacterVisible(targetChar)
		local camPos = camera.CFrame.Position
		local rp = RaycastParams.new()
		local ignore = { camera }
		if plr.Character then table.insert(ignore, plr.Character) end
		local activeMorph = Workspace:FindFirstChild(plr.Name .. "_ActiveMorph")
		if activeMorph then table.insert(ignore, activeMorph) end
		rp.FilterDescendantsInstances = ignore
		rp.FilterType = Enum.RaycastFilterType.Exclude
		rp.IgnoreWater = true

		local checkPoints = {}
		for _, partName in ipairs({ "Head", "HumanoidRootPart", "UpperTorso", "Torso", "LeftUpperArm", "RightUpperArm", "LeftArm", "RightArm", "LeftLowerLeg", "RightLowerLeg" }) do
			local pt = targetChar:FindFirstChild(partName)
			if pt and pt:IsA("BasePart") then
				table.insert(checkPoints, pt.Position)
			end
		end

		for _, pos in ipairs(checkPoints) do
			local dir = pos - camPos
			if dir.Magnitude > 0 then
				local res = Workspace:Raycast(camPos, dir, rp)
				if not res or res.Instance:IsDescendantOf(targetChar) then
					return true
				end
			end
		end
		return false
	end

	local function updateHitboxChams(d, ch, showChams, col)
		if not showChams then
			for _, ad in pairs(d.chams) do ad.Visible = false end
			return
		end
		local activeParts = {}
		for _, name in ipairs(HITBOX_NAMES) do
			local part = ch:FindFirstChild(name)
			if part and part:IsA("BasePart") then
				activeParts[part] = true
				local ad = d.chams[part]
				if not ad or not ad.Parent then
					ad = Instance.new("BoxHandleAdornment")
					ad.Name = "FluxChamBox"
					ad.Adornee = part
					ad.AlwaysOnTop = true
					ad.ZIndex = 5
					ad.Transparency = 0.45
					ad.Parent = chamsLayer
					d.chams[part] = ad
				end
				ad.Adornee = part
				ad.Size = part.Size + Vector3.new(0.05, 0.05, 0.05)
				ad.Color3 = col
				ad.Visible = true
			end
		end
		for part, ad in pairs(d.chams) do
			if not activeParts[part] or not part.Parent then
				ad:Destroy()
				d.chams[part] = nil
			end
		end
	end

	addConn("__esp", RS.RenderStepped:Connect(function()
		for p, d in pairs(drawings) do
			local on = Hub.State.esp_on == true
			local ch = p.Character
			local hum = ch and ch:FindFirstChildOfClass("Humanoid")
			local root = ch and ch:FindFirstChild("HumanoidRootPart")
			local show2D = false
			local inRange = false

			if on and ch and hum and root and hum.Health > 0 then
				local myRoot = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
				local dist = myRoot and (myRoot.Position - root.Position).Magnitude or (camera.CFrame.Position - root.Position).Magnitude
				if dist <= num(Hub.State.esp_max, 500) then
					inRange = true
					local vis = isCharacterVisible(ch)
					local chamCol = vis and COLOR_VIS or COLOR_HID
					updateHitboxChams(d, ch, Hub.State.esp_chams == true, chamCol)

					local rp, onScreen = camera:WorldToViewportPoint(root.Position)
					if onScreen then
						show2D = true
						local head = ch:FindFirstChild("Head")
						local hp = head and camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0)) or rp
						local sizeY = math.clamp(math.abs(hp.Y - rp.Y) * 2, 15, 500)
						local sizeX = sizeY * 0.65
						if Hub.State.esp_boxes then
							d.box.Size = UDim2.fromOffset(sizeX, sizeY)
							d.box.Position = UDim2.fromOffset(rp.X - sizeX / 2, rp.Y - sizeY / 2)
						end
						if Hub.State.esp_tracers then
							local origin = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y)
							local target = Vector2.new(rp.X, rp.Y)
							local len = (target - origin).Magnitude
							d.tracer.Size = UDim2.fromOffset(1.5, len)
							d.tracer.Position = UDim2.fromOffset((origin.X + target.X) / 2, (origin.Y + target.Y) / 2)
							d.tracer.Rotation = math.deg(math.atan2(target.Y - origin.Y, target.X - origin.X)) - 90
						end
						if Hub.State.esp_name then
							local text = p.Name
							if Hub.State.esp_dist then
								text = text .. " [" .. math.floor(dist) .. "m]"
							end
							d.nameTag.Text = text
							d.nameTag.Position = UDim2.fromOffset(rp.X - 100, rp.Y - sizeY / 2 - 18)
							d.nameTag.Size = UDim2.fromOffset(200, 15)
						end
						if Hub.State.esp_tool then
							local tool = ch:FindFirstChildOfClass("Tool")
							d.toolTag.Text = tool and tool.Name or "None"
							d.toolTag.Position = UDim2.fromOffset(rp.X - 100, rp.Y + sizeY / 2 + 2)
							d.toolTag.Size = UDim2.fromOffset(200, 15)
						end
						if Hub.State.esp_hp then
							local pctHp = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
							d.hpBg.Size = UDim2.fromOffset(3, sizeY)
							d.hpBg.Position = UDim2.fromOffset(rp.X - sizeX / 2 - 6, rp.Y - sizeY / 2)
							d.hpBar.Size = UDim2.new(1, 0, pctHp, 0)
							d.hpBar.Position = UDim2.new(0, 0, 1 - pctHp, 0)
							d.hpBar.BackgroundColor3 = Color3.fromRGB(255 - 255 * pctHp, 255 * pctHp, 0)
						end
					end
				end
			end

			if not inRange then
				updateHitboxChams(d, ch, false)
			end
			d.box.Visible = show2D and Hub.State.esp_boxes == true
			d.tracer.Visible = show2D and Hub.State.esp_tracers == true
			d.nameTag.Visible = show2D and Hub.State.esp_name == true
			d.toolTag.Visible = show2D and Hub.State.esp_tool == true
			d.hpBg.Visible = show2D and Hub.State.esp_hp == true
		end
	end))
end

-- ============================================================================
-- FOV + MATRIX EXTRA ZOOM + VIEWMODEL ARM OFFSET (ВО ВКЛАДКЕ VISUAL)
-- ============================================================================
do
	Hub.Hooks.fov = function(v)
		stopConns("fov")
		camera = Workspace.CurrentCamera
		if not v then
			if camera then camera.FieldOfView = 70 end
			return
		end
		addConn("fov", RS.RenderStepped:Connect(function()
			if not Hub.State.fov_on then return end
			camera = Workspace.CurrentCamera
			if not camera then return end

			local targetFov = math.clamp(num(Hub.State.fov_val, 110), 70, 120)
			local extraZoom = math.clamp(num(Hub.State.fov_zoom, 0.85), 0.1, 1.0)
			local armOffset = num(Hub.State.fov_arm, 1.2)

			camera.FieldOfView = targetFov

			if extraZoom < 1.0 then
				camera.CFrame = camera.CFrame * CFrame.new(
					0, 0, 0,
					extraZoom, 0, 0,
					0, extraZoom, 0,
					0, 0, 1
				)
			end

			if armOffset > 0 then
				for _, obj in ipairs(camera:GetChildren()) do
					if obj:IsA("Model") and obj ~= plr.Character then
						local primary = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
						if primary then
							primary.CFrame = primary.CFrame * CFrame.new(0, 0, -armOffset)
						end
					end
				end
			end
		end))
	end
end

do
	local skyConn, skyAtmosphere, snapshot = nil, nil, nil
	local props = { "Ambient", "OutdoorAmbient", "FogColor", "FogStart", "FogEnd", "Brightness", "ClockTime",
		"GeographicLatitude", "ExposureCompensation", "EnvironmentDiffuseScale", "EnvironmentSpecularScale",
		"ColorShift_Bottom", "ColorShift_Top", "GlobalShadows", "Technology" }
	local function applyColor(col)
		Lighting.OutdoorAmbient = col; Lighting.Ambient = col; Lighting.FogColor = col
		Lighting.FogStart = 0; Lighting.FogEnd = 2000
		if skyAtmosphere then skyAtmosphere.Color = col end
	end
	local function saveSnapshot()
		if snapshot then return end
		snapshot = { props = {}, children = {} }
		for _, n in ipairs(props) do local ok, v = pcall(function() return Lighting[n] end); if ok then snapshot.props[n] = v end end
		for _, c in ipairs(Lighting:GetChildren()) do local ok, cl = pcall(function() return c:Clone() end); if ok and cl then table.insert(snapshot.children, cl) end end
	end
	local function restoreSnapshot()
		if not snapshot then return end
		if skyConn then skyConn:Disconnect() skyConn = nil end
		for _, c in ipairs(Lighting:GetChildren()) do pcall(function() c:Destroy() end) end
		for _, c in ipairs(snapshot.children) do pcall(function() c:Clone().Parent = Lighting end) end
		for n, v in pairs(snapshot.props) do pcall(function() Lighting[n] = v end) end
		skyAtmosphere, snapshot = nil, nil
	end
	local function start()
		saveSnapshot()
		for _, v in ipairs(Lighting:GetChildren()) do if v:IsA("Sky") then v:Destroy() end end
		skyAtmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
		if not skyAtmosphere then skyAtmosphere = Instance.new("Atmosphere"); skyAtmosphere.Parent = Lighting end
		skyAtmosphere.Density = 0.6; skyAtmosphere.Haze = 10; skyAtmosphere.Glare = 10
		skyAtmosphere.Decay = Color3.fromRGB(0, 0, 0)
		local mode = Hub.State.sky_mode or "Rainbow"
		if mode == "Rainbow" then
			skyConn = RS.RenderStepped:Connect(function() applyColor(Color3.fromHSV((tick() % 2) / 2, 1, 1)) end)
		elseif mode == "Red" then applyColor(Color3.fromRGB(255, 0, 0))
		else applyColor(Color3.fromRGB(0, 150, 255)) end
	end
	Hub.Hooks.sky = function(v)
		stopConns("sky")
		if v then start() else restoreSnapshot() end
	end
end

-- ============================================================================
-- STRETCH (НАСТРОЙКА РАСТЯГА ОТ 0 ДО 1 СТРЕЛОЧКАМИ ИЛИ ВВОДОМ ЧИСЛА)
-- ============================================================================
Hub.Hooks.str = function(v)
	stopConns("str")
	if not v then
		getgenv().Resolution = nil
		getgenv().gg_scripters = nil
		return
	end
	addConn("str", RS.RenderStepped:Connect(function()
		camera = Workspace.CurrentCamera
		if not camera then return end
		local stretchVal = math.clamp(num(Hub.State.str_val, 0.65), 0.05, 1)
		getgenv().Resolution = { [".gg/scripters"] = stretchVal }
		camera.CFrame = camera.CFrame * CFrame.new(0, 0, 0, 1, 0, 0, 0, stretchVal, 0, 0, 0, 1)
	end))
	getgenv().gg_scripters = "GGCASHERS"
end

Hub.Hooks.afling = function(v)
	stopConns("afling")
	if not v then return end
	local lastPos = nil
	addConn("afling", RS.Stepped:Connect(function()
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= plr and p.Character then
				for _, part in ipairs(p.Character:GetDescendants()) do
					if part:IsA("BasePart") then
						part.CanCollide = false
						part.AssemblyLinearVelocity = Vector3.zero
						part.AssemblyAngularVelocity = Vector3.zero
						part.CustomPhysicalProperties = PhysicalProperties.new(0, 0, 0, 0, 0)
					end
				end
			end
		end
	end))
	addConn("afling2", RS.Heartbeat:Connect(function()
		pcall(function()
			local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
			if hrp then
				if hrp.AssemblyLinearVelocity.Magnitude > 200 or hrp.AssemblyAngularVelocity.Magnitude > 200 then
					hrp.AssemblyLinearVelocity = Vector3.zero
					hrp.AssemblyAngularVelocity = Vector3.zero
					if lastPos then hrp.CFrame = lastPos end
				elseif hrp.AssemblyLinearVelocity.Magnitude < 50 then
					lastPos = hrp.CFrame
				end
			end
		end)
	end))
end

Hub.Hooks.afk = function(v)
	stopConns("afk")
	if not v then return end
	addConn("afk", plr.Idled:Connect(function()
		VirtualUser:CaptureController()
		VirtualUser:ClickButton2(Vector2.new(0, 0))
	end))
end

-- Авто-восстановление морфа и функций после смерти/респавна
plr.CharacterAdded:Connect(function(character)
	task.wait(0.4)
	if Hub.State.morph_on then
		task.spawn(function() morphApply(currentMorphId) end)
	end
	if Hub.State.hit_on then Hub.Hooks.hit(true) end
	if Hub.State.noclip_on then Hub.Hooks.noclip(true) end
	if Hub.State.afling_on then Hub.Hooks.afling(true) end
	if Hub.State.free_on then Hub.Hooks.free(true) end
	if Hub.State.sfly_on then Hub.Hooks.sfly(true) end
	if Hub.State.camfree_on then Hub.Hooks.camfree(true) end
	if Hub.State.spin_on then Hub.Hooks.spin(true) end
end)

do
	local rfOn = false
	local function patchShoot()
		local ch = plr.Character
		local tool = ch and ch:FindFirstChild("Revolver")
		if not tool or not getgc then return false end
		for _, obj in pairs(getgc(true)) do
			if type(obj) == "function" then
				local info = debug.getinfo(obj)
				if info and info.source and info.source:find("Revolver") then
					local i = 1
					local equippedI, cooldownI, reloadI = nil, nil, nil
					while true do
						local name = debug.getupvalue(obj, i)
						if not name then break end
						local lname = tostring(name):lower()
						if lname == "u341" then equippedI = i
						elseif lname == "u344" then cooldownI = i
						elseif lname == "u345" then reloadI = i
						elseif lname:find("recoil") then pcall(debug.setupvalue, obj, i, 0) end
						i += 1
					end
					if equippedI and cooldownI and reloadI then
						pcall(debug.setupvalue, obj, equippedI, true)
						pcall(debug.setupvalue, obj, cooldownI, 0)
						pcall(debug.setupvalue, obj, reloadI, false)
						return true
					end
				end
			end
		end
		return false
	end

	Hub.Hooks.rf = function(v)
		rfOn = v
		stopConns("rf")
		task.spawn(RapidFire, v)
		if not v then return end
		addConn("rf", plr.CharacterAdded:Connect(function()
			task.wait(2)
			if rfOn then patchShoot() end
		end))
		task.spawn(function()
			while rfOn do
				local ch = plr.Character
				local tool = ch and ch:FindFirstChild("Revolver")
				if tool then
					patchShoot()
					pcall(function()
						local vim2 = game:GetService("VirtualInputManager")
						vim2:SendMouseButtonEvent(0, 0, 0, true, game, 1)
						task.wait(0.01)
						vim2:SendMouseButtonEvent(0, 0, 0, false, game, 1)
					end)
				else
					patchShoot()
				end
				task.wait(0.08)
			end
		end)
	end
end

do
	local sfActive = false
	local sfMode = "tp"
	local sfHum, sfHrp = nil, nil
	local sfStateConn, sfMoveConn = nil, nil
	local sfBg, sfBv = nil, nil
	local blockReplication = false
	local hrpRef = nil
	local oldIndex, oldNamecall = nil, nil
	local hookInstalled = false
	local stateToggle = false

	local function sfGetRoot()
		local ch = plr.Character
		if not ch then return nil end
		return ch:FindFirstChild("HumanoidRootPart") or ch:FindFirstChild("Torso") or ch:FindFirstChild("UpperTorso")
	end

	local function sfBypassOn(i) return Hub.State["sfly_b" .. i] == true end

	local function sfInstallHook()
		if hookInstalled or not getrawmetatable then return end
		local ok = pcall(function()
			local mt = getrawmetatable(game)
			oldIndex = mt.__index
			oldNamecall = mt.__namecall
			setreadonly(mt, false)
			mt.__index = newcclosure(function(self, key)
				if blockReplication and self == hrpRef
					and (key == "CFrame" or key == "Position" or key == "AssemblyLinearVelocity") then
					return rawget(self, key)
				end
				return oldIndex(self, key)
			end)
			mt.__namecall = newcclosure(function(self, ...)
				local method = getnamecallmethod and getnamecallmethod() or ""
				if blockReplication and self == hrpRef
					and (method == "SetNetworkOwner" or method == "SetPrimaryPartCFrame") then
					return nil
				end
				return oldNamecall(self, ...)
			end)
			setreadonly(mt, true)
		end)
		if ok then hookInstalled = true end
	end

	local function sfGrabNetwork()
		pcall(function()
			for _, part in ipairs(plr.Character:GetDescendants()) do
				if part:IsA("BasePart") then pcall(function() part:SetNetworkOwner(plr) end) end
			end
		end)
	end

	local function sfAbuseState()
		pcall(function()
			sfHum:SetStateEnabled(Enum.HumanoidStateType.Swimming, true)
			sfHum:SetStateEnabled(Enum.HumanoidStateType.Climbing, true)
			sfHum:SetStateEnabled(Enum.HumanoidStateType.Freefall, true)
			sfHum:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
			sfHum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
			sfHum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
			sfHum:ChangeState(Enum.HumanoidStateType.Swimming)
		end)
	end

	local function sfRestoreState()
		pcall(function()
			if not sfHum then return end
			sfHum:SetStateEnabled(Enum.HumanoidStateType.Swimming, true)
			sfHum:SetStateEnabled(Enum.HumanoidStateType.Climbing, true)
			sfHum:SetStateEnabled(Enum.HumanoidStateType.Freefall, true)
			sfHum:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)
			sfHum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
			sfHum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
			sfHum:ChangeState(Enum.HumanoidStateType.GettingUp)
			sfHum.PlatformStand = false
		end)
	end

	local function sfReadMove()
		local mv = Vector3.zero
		local cf = camera.CFrame
		if UIS:IsKeyDown(Enum.KeyCode.W) then mv += cf.LookVector end
		if UIS:IsKeyDown(Enum.KeyCode.S) then mv -= cf.LookVector end
		if UIS:IsKeyDown(Enum.KeyCode.A) then mv -= cf.RightVector end
		if UIS:IsKeyDown(Enum.KeyCode.D) then mv += cf.RightVector end
		if UIS:IsKeyDown(Enum.KeyCode.Space) then mv += Vector3.new(0, 1, 0) end
		if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then mv -= Vector3.new(0, 1, 0) end
		return mv, cf
	end

	local function sfStartFly()
		sfBg = Instance.new("BodyGyro")
		sfBg.P = 9e4
		sfBg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
		sfBg.CFrame = sfHrp.CFrame
		sfBg.Parent = sfHrp
		sfBv = Instance.new("BodyVelocity")
		sfBv.Velocity = Vector3.zero
		sfBv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
		sfBv.P = 1250
		sfBv.Parent = sfHrp
		sfMoveConn = RS.RenderStepped:Connect(function(dt)
			if not sfActive or sfMode ~= "fly" then return end
			local root = sfGetRoot()
			if not root then return end
			local mv, cf = sfReadMove()
			local spd = num(Hub.State.sfly_speed, 70)
			if mv.Magnitude > 0 then mv = mv.Unit * spd end
			sfBv.Velocity = sfBv.Velocity:Lerp(mv, math.clamp(dt * 8, 0, 1))
			sfBg.CFrame = cf
		end)
	end

	local function sfStopFly()
		if sfBg then sfBg:Destroy() sfBg = nil end
		if sfBv then sfBv:Destroy() sfBv = nil end
	end

	local MAX_STEP = 4
	local function sfStartTP()
		sfMoveConn = RS.Heartbeat:Connect(function(dt)
			if not sfActive or sfMode ~= "tp" then return end
			local ch = plr.Character
			if not ch then return end
			local root = sfGetRoot()
			local hum = ch:FindFirstChildOfClass("Humanoid")
			if not root or not hum then return end
			hum.PlatformStand = true

			local mv, cf = sfReadMove()
			local spd = num(Hub.State.sfly_speed, 70)
			if sfBypassOn(5) and spd > 80 then spd = 80 end

			local cur = root.Position
			local delta = mv * spd * dt
			if delta.Magnitude > MAX_STEP then delta = delta.Unit * MAX_STEP end
			local target = cur + delta
			local lag = 0.5

			if sfBypassOn(4) then
				local steps = 4
				local stepVec = (target - cur) / steps
				local pos = cur
				for i = 1, steps do
					pos = pos + stepVec * lag
					root.CFrame = CFrame.new(pos, pos + cf.LookVector)
				end
			else
				local pos = cur:Lerp(target, lag)
				root.CFrame = CFrame.new(pos, pos + cf.LookVector)
			end

			root.AssemblyLinearVelocity = Vector3.zero
			root.AssemblyAngularVelocity = Vector3.zero
		end)
	end

	local function sfStopTP()
		local ch = plr.Character
		if ch then
			local hum = ch:FindFirstChildOfClass("Humanoid")
			if hum then hum.PlatformStand = false end
			local root = sfGetRoot()
			if root then
				root.AssemblyLinearVelocity = Vector3.zero
				root.AssemblyAngularVelocity = Vector3.zero
			end
		end
	end

	local function sfStart()
		sfHrp = sfGetRoot()
		sfHum = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
		if not sfHrp or not sfHum then return end
		hrpRef = sfHrp
		sfMode = (Hub.State.sfly_mode or "TP"):lower()

		if sfBypassOn(1) then blockReplication = true sfInstallHook() end
		if sfBypassOn(2) then sfGrabNetwork() end
		sfAbuseState()

		sfStateConn = RS.Heartbeat:Connect(function()
			if not sfActive or not sfHum then return end
			pcall(function()
				if sfBypassOn(3) then
					stateToggle = not stateToggle
					sfHum:ChangeState(stateToggle and Enum.HumanoidStateType.Swimming or Enum.HumanoidStateType.Freefall)
				else
					if sfHum:GetState() ~= Enum.HumanoidStateType.Swimming then
						sfHum:ChangeState(Enum.HumanoidStateType.Swimming)
					end
				end
			end)
		end)

		if sfMode == "fly" then sfStartFly() else sfStartTP() end
	end

	local function sfStop()
		sfActive = false
		blockReplication = false
		hrpRef = nil
		if sfStateConn then sfStateConn:Disconnect() sfStateConn = nil end
		if sfMoveConn then sfMoveConn:Disconnect() sfMoveConn = nil end
		sfStopFly()
		sfStopTP()
		sfRestoreState()
	end

	Hub.Hooks.sfly = function(v)
		stopConns("sfly")
		if not v then sfStop() return end
		sfActive = true
		sfStart()
		addConn("sfly", { Disconnect = function() sfStop() end })
	end
end

-- Запуск сплэш-экрана и автозагрузка конфига после инициализации всех хуков
task.spawn(function()
	local p = 0
	while p < 100 do
		p = math.min(100, p + math.random() * 4.5 + 1.2)
		barFill.Size = UDim2.fromScale(p / 100, 1)
		pct.Text = math.floor(p) .. "%"
		task.wait(.03 + math.random() * .04)
	end
	task.wait(.25)
	tween(splash, .45, { GroupTransparency = 1, Size = UDim2.fromOffset(360, 250) }, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
	task.wait(.45)
	splash:Destroy()
	ready = true

	-- Автопроверка "Load on Startup" из Global конфига
	pcall(function()
		local globalPath = FOLDER .. "/Global.json"
		if isfile and isfile(globalPath) then
			local raw = HttpService:JSONDecode(readfile(globalPath))
			if type(raw) == "table" and raw.set_load == true then
				loadConfigByName("Global")
			end
		end
	end)

	toggleMenu()
end)

print("FLUX HUB V2 LOADED")
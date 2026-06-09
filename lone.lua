local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

local LP = Players.LocalPlayer
local Cam = workspace.CurrentCamera

local allowedUsers = {
	[LP.UserId] = true
}

if not allowedUsers[LP.UserId] then return end

local function asset(id)
	return "rbxthumb://type=Asset&id=" .. tostring(id) .. "&w=150&h=150"
end

local logoId = asset(95706946929530)
local bestIconId = asset(123307836187460)
local stealthIconId = asset(127295787879229)
local macroIconId = asset(101215635447507)
local notifyIconId = asset(131285912734006)

local visualEnabled = false
local focusEnabled = true
local macroEnabled = false
local macroRunning = false
local notificationsEnabled = true
local fovVisible = false
local shiftLockWasActive = false
local waitingForBind = nil

local fov = 90
local focusStrength = 0.7
local maxFocusDistance = 50
local visualColor = Color3.fromRGB(0, 0, 0)

local visualBind = {mod = "Command", key = Enum.KeyCode.C}
local disableBind = {mod = "Alt", key = Enum.KeyCode.Z}
local focusBind = {mod = "Alt", key = Enum.KeyCode.F}
local macroQBind = {mod = "None", key = Enum.KeyCode.Q}
local macroEBind = {mod = "None", key = Enum.KeyCode.E}

local highlights = {}
local held = {Command = false, Alt = false, Shift = false, Ctrl = false}

local theme = {
	bg = Color3.fromRGB(5, 5, 10),
	panel = Color3.fromRGB(14, 14, 22),
	card = Color3.fromRGB(20, 20, 30),
	button = Color3.fromRGB(75, 75, 96),
	button2 = Color3.fromRGB(92, 92, 118),
	buttonHover = Color3.fromRGB(118, 118, 150),
	accent = Color3.fromRGB(255, 255, 255),
	accent2 = Color3.fromRGB(205, 210, 230),
	text = Color3.fromRGB(255, 255, 255),
	stroke = Color3.fromRGB(255, 255, 255)
}

local gui = Instance.new("ScreenGui")
gui.Name = "Lone"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = LP:WaitForChild("PlayerGui")

local blur = Instance.new("BlurEffect")
blur.Name = "LoneBlur"
blur.Size = 0
blur.Parent = Lighting

local function tween(obj, time, props)
	local t = TweenService:Create(obj, TweenInfo.new(time, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), props)
	t:Play()
	return t
end

local function corner(obj, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r)
	c.Parent = obj
	return c
end

local function stroke(obj, trans, color, thick)
	local s = Instance.new("UIStroke")
	s.Color = color or theme.stroke
	s.Transparency = trans
	s.Thickness = thick or 1
	s.Parent = obj
	return s
end

local function forceWhite(obj)
	obj.TextColor3 = Color3.fromRGB(255, 255, 255)
	obj.TextTransparency = 0
	obj.TextStrokeTransparency = 1
	return obj
end

local function round(num, places)
	local mult = 10 ^ places
	return math.floor(num * mult + 0.5) / mult
end

local function glassFrame(obj, light)
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(0.16, Color3.fromRGB(230, 235, 255)),
		ColorSequenceKeypoint.new(0.38, Color3.fromRGB(130, 138, 170)),
		ColorSequenceKeypoint.new(0.68, Color3.fromRGB(34, 36, 52)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(8, 8, 14))
	})
	g.Transparency = light and NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.28),
		NumberSequenceKeypoint.new(0.28, 0.48),
		NumberSequenceKeypoint.new(0.68, 0.72),
		NumberSequenceKeypoint.new(1, 0.88)
	}) or NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.48),
		NumberSequenceKeypoint.new(0.3, 0.64),
		NumberSequenceKeypoint.new(0.75, 0.8),
		NumberSequenceKeypoint.new(1, 0.9)
	})
	g.Rotation = 28
	g.Parent = obj
	return g
end

local function glassButton(obj)
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(190, 195, 220)),
		ColorSequenceKeypoint.new(0.36, Color3.fromRGB(118, 122, 155)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(55, 58, 82))
	})
	g.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.5, 0.04),
		NumberSequenceKeypoint.new(1, 0.1)
	})
	g.Rotation = 25
	g.Parent = obj
	return g
end

local function rainbow(obj)
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(90, 220, 255)),
		ColorSequenceKeypoint.new(0.15, Color3.fromRGB(130, 120, 255)),
		ColorSequenceKeypoint.new(0.3, Color3.fromRGB(255, 110, 240)),
		ColorSequenceKeypoint.new(0.48, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(0.64, Color3.fromRGB(105, 255, 200)),
		ColorSequenceKeypoint.new(0.8, Color3.fromRGB(110, 165, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 95, 210))
	})
	g.Offset = Vector2.new(-1, 0)
	g.Parent = obj
	TweenService:Create(g, TweenInfo.new(0.95, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Offset = Vector2.new(1, 0)}):Play()
	return g
end

local function shine(parent, z, h)
	local f = Instance.new("Frame")
	f.Size = UDim2.new(1, -18, 0, h or 38)
	f.Position = UDim2.new(0, 9, 0, 8)
	f.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	f.BackgroundTransparency = 0.86
	f.BorderSizePixel = 0
	f.ZIndex = z or 2
	f.Parent = parent
	corner(f, 15)
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 255, 255))
	g.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.04),
		NumberSequenceKeypoint.new(0.45, 0.72),
		NumberSequenceKeypoint.new(1, 1)
	})
	g.Rotation = 18
	g.Parent = f
	return f
end

local notifyHolder = Instance.new("Frame")
notifyHolder.Size = UDim2.new(0, 342, 0, 260)
notifyHolder.Position = UDim2.new(1, -362, 1, -280)
notifyHolder.BackgroundTransparency = 1
notifyHolder.Parent = gui

local notifyList = Instance.new("UIListLayout")
notifyList.Padding = UDim.new(0, 8)
notifyList.SortOrder = Enum.SortOrder.LayoutOrder
notifyList.VerticalAlignment = Enum.VerticalAlignment.Bottom
notifyList.Parent = notifyHolder

local fovCircle = Instance.new("Frame")
fovCircle.AnchorPoint = Vector2.new(0.5, 0.5)
fovCircle.Position = UDim2.new(0.5, 0, 0.5, 0)
fovCircle.Size = UDim2.new(0, fov * 2, 0, fov * 2)
fovCircle.BackgroundTransparency = 1
fovCircle.Visible = false
fovCircle.ZIndex = 100
fovCircle.Parent = gui

local fovRound = Instance.new("UICorner")
fovRound.CornerRadius = UDim.new(1, 0)
fovRound.Parent = fovCircle

local fovStroke = Instance.new("UIStroke")
fovStroke.Color = theme.accent
fovStroke.Transparency = 0.08
fovStroke.Thickness = 1.9
fovStroke.Parent = fovCircle

local function notify(text)
	if not notificationsEnabled then return end
	local card = Instance.new("Frame")
	card.Size = UDim2.new(0, 342, 0, 64)
	card.Position = UDim2.new(0, 48, 0, 0)
	card.BackgroundColor3 = theme.panel
	card.BackgroundTransparency = 1
	card.BorderSizePixel = 0
	card.ClipsDescendants = true
	card.Parent = notifyHolder
	local scale = Instance.new("UIScale")
	scale.Scale = 0.94
	scale.Parent = card
	corner(card, 18)
	glassFrame(card, true)
	shine(card, 2, 28)
	local st = stroke(card, 1, theme.stroke, 1.15)
	local sg = Instance.new("UIGradient")
	sg.Color = ColorSequence.new(theme.accent, theme.accent2)
	sg.Parent = st
	local glow = Instance.new("ImageLabel")
	glow.Size = UDim2.new(0, 82, 0, 82)
	glow.Position = UDim2.new(0, -13, 0.5, -41)
	glow.BackgroundTransparency = 1
	glow.Image = notifyIconId
	glow.ImageTransparency = 1
	glow.ZIndex = 5
	glow.Parent = card
	local iconBox = Instance.new("Frame")
	iconBox.Size = UDim2.new(0, 38, 0, 38)
	iconBox.Position = UDim2.new(0, 14, 0.5, -19)
	iconBox.BackgroundColor3 = Color3.fromRGB(85, 85, 110)
	iconBox.BackgroundTransparency = 1
	iconBox.BorderSizePixel = 0
	iconBox.ZIndex = 6
	iconBox.Parent = card
	corner(iconBox, 13)
	stroke(iconBox, 1, theme.stroke, 1)
	glassButton(iconBox)
	local icon = Instance.new("ImageLabel")
	icon.Size = UDim2.new(0, 28, 0, 28)
	icon.Position = UDim2.new(0.5, -14, 0.5, -14)
	icon.BackgroundTransparency = 1
	icon.Image = notifyIconId
	icon.ImageTransparency = 1
	icon.ScaleType = Enum.ScaleType.Fit
	icon.ZIndex = 7
	icon.Parent = iconBox
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -78, 0, 20)
	title.Position = UDim2.new(0, 64, 0, 11)
	title.BackgroundTransparency = 1
	title.Text = "Notify"
	title.Font = Enum.Font.GothamBold
	title.TextSize = 13
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextTransparency = 1
	title.ZIndex = 8
	title.Parent = card
	forceWhite(title)
	local body = Instance.new("TextLabel")
	body.Size = UDim2.new(1, -78, 0, 18)
	body.Position = UDim2.new(0, 64, 0, 34)
	body.BackgroundTransparency = 1
	body.Text = text
	body.Font = Enum.Font.GothamMedium
	body.TextSize = 11
	body.TextXAlignment = Enum.TextXAlignment.Left
	body.TextTransparency = 1
	body.ZIndex = 8
	body.Parent = card
	forceWhite(body)
	local barBack = Instance.new("Frame")
	barBack.Size = UDim2.new(1, -28, 0, 2)
	barBack.Position = UDim2.new(0, 14, 1, -7)
	barBack.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	barBack.BackgroundTransparency = 0.78
	barBack.BorderSizePixel = 0
	barBack.ZIndex = 9
	barBack.Parent = card
	corner(barBack, 8)
	local bar = Instance.new("Frame")
	bar.Size = UDim2.new(1, 0, 1, 0)
	bar.BackgroundColor3 = theme.accent
	bar.BackgroundTransparency = 1
	bar.BorderSizePixel = 0
	bar.ZIndex = 10
	bar.Parent = barBack
	corner(bar, 8)
	local bg = Instance.new("UIGradient")
	bg.Color = ColorSequence.new(theme.accent, theme.accent2)
	bg.Parent = bar
	tween(card, 0.22, {Position = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 0.08})
	tween(scale, 0.22, {Scale = 1})
	tween(st, 0.2, {Transparency = 0.12})
	tween(title, 0.16, {TextTransparency = 0})
	tween(body, 0.16, {TextTransparency = 0})
	tween(iconBox, 0.16, {BackgroundTransparency = 0})
	tween(icon, 0.16, {ImageTransparency = 0})
	tween(glow, 0.16, {ImageTransparency = 0.72})
	tween(bar, 0.16, {BackgroundTransparency = 0})
	TweenService:Create(bar, TweenInfo.new(1.25, Enum.EasingStyle.Linear), {Size = UDim2.new(0, 0, 1, 0)}):Play()
	task.delay(1.25, function()
		if not card or not card.Parent then return end
		tween(card, 0.18, {Position = UDim2.new(0, 42, 0, 0), BackgroundTransparency = 1})
		tween(scale, 0.18, {Scale = 0.94})
		tween(st, 0.12, {Transparency = 1})
		tween(title, 0.12, {TextTransparency = 1})
		tween(body, 0.12, {TextTransparency = 1})
		tween(iconBox, 0.12, {BackgroundTransparency = 1})
		tween(icon, 0.12, {ImageTransparency = 1})
		tween(glow, 0.12, {ImageTransparency = 1})
		tween(bar, 0.12, {BackgroundTransparency = 1})
		tween(barBack, 0.12, {BackgroundTransparency = 1})
		task.delay(0.2, function()
			if card then card:Destroy() end
		end)
	end)
end

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 860, 0, 500)
main.Position = UDim2.new(0.5, -430, 0.5, -250)
main.BackgroundColor3 = theme.bg
main.BackgroundTransparency = 0.2
main.BorderSizePixel = 0
main.ClipsDescendants = true
main.Visible = false
main.Parent = gui

corner(main, 24)
stroke(main, 0.08, theme.stroke, 1.4)
glassFrame(main, true)

local shadow = Instance.new("ImageLabel")
shadow.AnchorPoint = Vector2.new(0.5, 0.5)
shadow.Position = UDim2.new(0.5, 0, 0.5, 28)
shadow.Size = UDim2.new(1, 160, 1, 160)
shadow.BackgroundTransparency = 1
shadow.Image = "rbxassetid://1316045217"
shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
shadow.ImageTransparency = 0.44
shadow.ScaleType = Enum.ScaleType.Slice
shadow.SliceCenter = Rect.new(10, 10, 118, 118)
shadow.ZIndex = 0
shadow.Parent = main

local topShine = Instance.new("Frame")
topShine.Size = UDim2.new(1, -32, 0, 132)
topShine.Position = UDim2.new(0, 16, 0, 13)
topShine.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
topShine.BackgroundTransparency = 0.88
topShine.BorderSizePixel = 0
topShine.ZIndex = 1
topShine.Parent = main
corner(topShine, 20)

local topShineGradient = Instance.new("UIGradient")
topShineGradient.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 255, 255))
topShineGradient.Transparency = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0.04),
	NumberSequenceKeypoint.new(0.45, 0.78),
	NumberSequenceKeypoint.new(1, 1)
})
topShineGradient.Rotation = 18
topShineGradient.Parent = topShine

local dragBar = Instance.new("Frame")
dragBar.Size = UDim2.new(1, 0, 0, 50)
dragBar.BackgroundTransparency = 1
dragBar.ZIndex = 30
dragBar.Parent = main

local function makeTopButton(x)
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(0, 35, 0, 35)
	b.Position = UDim2.new(1, x, 0, 8)
	b.BackgroundColor3 = theme.button
	b.BackgroundTransparency = 0.02
	b.BorderSizePixel = 0
	b.Text = ""
	b.AutoButtonColor = false
	b.ZIndex = 31
	b.Parent = dragBar
	corner(b, 11)
	stroke(b, 0.2, theme.stroke, 1)
	glassButton(b)
	return b
end

local minimize = makeTopButton(-86)
local close = makeTopButton(-46)

local function makeMinIcon(parent)
	local holder = Instance.new("Frame")
	holder.Size = UDim2.new(0, 20, 0, 20)
	holder.Position = UDim2.new(0.5, -10, 0.5, -10)
	holder.BackgroundTransparency = 1
	holder.ZIndex = parent.ZIndex + 1
	holder.Parent = parent
	local pieces = {
		{0, 0, 7, 2}, {0, 0, 2, 7}, {13, 0, 7, 2}, {18, 0, 2, 7},
		{0, 13, 2, 7}, {0, 18, 7, 2}, {13, 18, 7, 2}, {18, 13, 2, 7}
	}
	for _, d in ipairs(pieces) do
		local p = Instance.new("Frame")
		p.Size = UDim2.new(0, d[3], 0, d[4])
		p.Position = UDim2.new(0, d[1], 0, d[2])
		p.BackgroundColor3 = theme.text
		p.BackgroundTransparency = 0
		p.BorderSizePixel = 0
		p.ZIndex = parent.ZIndex + 2
		p.Parent = holder
		corner(p, 2)
	end
end

makeMinIcon(minimize)

local closeText = Instance.new("TextLabel")
closeText.Size = UDim2.new(1, 0, 1, -1)
closeText.BackgroundTransparency = 1
closeText.Text = "×"
closeText.Font = Enum.Font.GothamBold
closeText.TextSize = 23
closeText.ZIndex = 32
closeText.Parent = close
forceWhite(closeText)

local logoBubble = Instance.new("ImageButton")
logoBubble.Size = UDim2.new(0, 72, 0, 72)
logoBubble.Position = UDim2.new(0, 30, 0.5, -36)
logoBubble.BackgroundColor3 = theme.panel
logoBubble.BackgroundTransparency = 0.08
logoBubble.BorderSizePixel = 0
logoBubble.Image = ""
logoBubble.Visible = false
logoBubble.ZIndex = 50
logoBubble.AutoButtonColor = false
logoBubble.Parent = gui

corner(logoBubble, 22)

local bubbleStroke = stroke(logoBubble, 0.12, theme.stroke, 1.4)
glassFrame(logoBubble, true)
shine(logoBubble, 51, 26)

local bubbleLogo = Instance.new("ImageLabel")
bubbleLogo.Size = UDim2.new(0, 42, 0, 42)
bubbleLogo.Position = UDim2.new(0.5, -21, 0.5, -21)
bubbleLogo.BackgroundTransparency = 1
bubbleLogo.Image = logoId
bubbleLogo.ScaleType = Enum.ScaleType.Fit
bubbleLogo.ZIndex = 52
bubbleLogo.Parent = logoBubble

local sidebar = Instance.new("Frame")
sidebar.Size = UDim2.new(0, 208, 1, 0)
sidebar.BackgroundColor3 = theme.panel
sidebar.BackgroundTransparency = 0.08
sidebar.BorderSizePixel = 0
sidebar.ZIndex = 2
sidebar.Parent = main
glassFrame(sidebar, true)

local sideLine = Instance.new("Frame")
sideLine.Size = UDim2.new(0, 1, 1, 0)
sideLine.Position = UDim2.new(1, 0, 0, 0)
sideLine.BackgroundColor3 = theme.stroke
sideLine.BackgroundTransparency = 0.32
sideLine.BorderSizePixel = 0
sideLine.ZIndex = 4
sideLine.Parent = sidebar

local logoBox = Instance.new("Frame")
logoBox.Size = UDim2.new(0, 47, 0, 47)
logoBox.Position = UDim2.new(0, 17, 0, 19)
logoBox.BackgroundColor3 = theme.button
logoBox.BackgroundTransparency = 0.02
logoBox.BorderSizePixel = 0
logoBox.ZIndex = 5
logoBox.Parent = sidebar
corner(logoBox, 14)
stroke(logoBox, 0.16, theme.stroke, 1)
glassButton(logoBox)

local logo = Instance.new("ImageLabel")
logo.Size = UDim2.new(0, 33, 0, 33)
logo.Position = UDim2.new(0.5, -16.5, 0.5, -16.5)
logo.BackgroundTransparency = 1
logo.Image = logoId
logo.ScaleType = Enum.ScaleType.Fit
logo.ZIndex = 6
logo.Parent = logoBox

local name = Instance.new("TextLabel")
name.Size = UDim2.new(1, -78, 0, 25)
name.Position = UDim2.new(0, 76, 0, 20)
name.BackgroundTransparency = 1
name.Text = "Lone"
name.Font = Enum.Font.GothamBold
name.TextSize = 22
name.TextXAlignment = Enum.TextXAlignment.Left
name.ZIndex = 5
name.Parent = sidebar
forceWhite(name)

local nameSub = Instance.new("TextLabel")
nameSub.Size = UDim2.new(1, -78, 0, 18)
nameSub.Position = UDim2.new(0, 76, 0, 45)
nameSub.BackgroundTransparency = 1
nameSub.Text = "destroyers"
nameSub.Font = Enum.Font.GothamMedium
nameSub.TextSize = 11
nameSub.TextXAlignment = Enum.TextXAlignment.Left
nameSub.ZIndex = 5
nameSub.Parent = sidebar
forceWhite(nameSub)

local content = Instance.new("Frame")
content.Size = UDim2.new(1, -240, 1, -70)
content.Position = UDim2.new(0, 226, 0, 56)
content.BackgroundTransparency = 1
content.ZIndex = 2
content.Parent = main

local pages = {}
local tabButtons = {}

local function makeTab(tabName, iconId, order)
	local btn = Instance.new("TextButton")
	btn.Name = tabName
	btn.Size = UDim2.new(1, -24, 0, 54)
	btn.Position = UDim2.new(0, 12, 0, 102 + ((order - 1) * 62))
	btn.BackgroundColor3 = theme.button
	btn.BackgroundTransparency = order == 1 and 0.01 or 0.08
	btn.BorderSizePixel = 0
	btn.Text = ""
	btn.AutoButtonColor = false
	btn.ZIndex = 5
	btn.Parent = sidebar
	corner(btn, 15)
	glassButton(btn)
	local st = stroke(btn, order == 1 and 0.1 or 0.38, theme.stroke, 1)
	local bar = Instance.new("Frame")
	bar.Size = UDim2.new(0, 3, 0, 31)
	bar.Position = UDim2.new(0, 0, 0.5, -15)
	bar.BackgroundColor3 = theme.accent
	bar.BackgroundTransparency = order == 1 and 0 or 1
	bar.BorderSizePixel = 0
	bar.ZIndex = 7
	bar.Parent = btn
	corner(bar, 8)
	local iconBox = Instance.new("Frame")
	iconBox.Size = UDim2.new(0, 36, 0, 36)
	iconBox.Position = UDim2.new(0, 14, 0.5, -18)
	iconBox.BackgroundColor3 = Color3.fromRGB(65, 65, 88)
	iconBox.BackgroundTransparency = 0
	iconBox.BorderSizePixel = 0
	iconBox.ZIndex = 6
	iconBox.Parent = btn
	corner(iconBox, 12)
	stroke(iconBox, order == 1 and 0.12 or 0.34, theme.stroke, 1)
	glassButton(iconBox)
	local icon = Instance.new("ImageLabel")
	icon.Size = UDim2.new(0, 26, 0, 26)
	icon.Position = UDim2.new(0.5, -13, 0.5, -13)
	icon.BackgroundTransparency = 1
	icon.Image = iconId
	icon.ImageTransparency = 0
	icon.ScaleType = Enum.ScaleType.Fit
	icon.ZIndex = 8
	icon.Parent = iconBox
	local txt = Instance.new("TextLabel")
	txt.Size = UDim2.new(1, -66, 1, 0)
	txt.Position = UDim2.new(0, 62, 0, 0)
	txt.BackgroundTransparency = 1
	txt.Text = tabName
	txt.Font = Enum.Font.GothamBold
	txt.TextSize = 15
	txt.TextXAlignment = Enum.TextXAlignment.Left
	txt.ZIndex = 6
	txt.Parent = btn
	forceWhite(txt)
	local page = Instance.new("Frame")
	page.Size = UDim2.new(1, 0, 1, 0)
	page.BackgroundTransparency = 1
	page.Visible = order == 1
	page.Parent = content
	tabButtons[tabName] = {Button = btn, Bar = bar, Text = txt, IconBox = iconBox, Stroke = st}
	pages[tabName] = page
	return btn, page
end

local bestTab, bestPage = makeTab("Best Stuff", bestIconId, 1)
local stealthTab, stealthPage = makeTab("Stealth", stealthIconId, 2)
local macroTab, macroPage = makeTab("Macro", macroIconId, 3)

local function switchPage(pageName)
	for n, p in pairs(pages) do
		p.Visible = n == pageName
	end
	for n, d in pairs(tabButtons) do
		local selected = n == pageName
		tween(d.Button, 0.16, {BackgroundTransparency = selected and 0.01 or 0.08})
		tween(d.Bar, 0.16, {BackgroundTransparency = selected and 0 or 1})
		tween(d.Text, 0.16, {TextTransparency = 0})
		tween(d.IconBox, 0.16, {BackgroundTransparency = 0})
		tween(d.Stroke, 0.16, {Transparency = selected and 0.1 or 0.38})
	end
end

bestTab.MouseButton1Click:Connect(function() switchPage("Best Stuff") end)
stealthTab.MouseButton1Click:Connect(function() switchPage("Stealth") end)
macroTab.MouseButton1Click:Connect(function() switchPage("Macro") end)

local function makeCard(parent, x, y, w, h)
	local card = Instance.new("Frame")
	card.Size = UDim2.new(0, w, 0, h)
	card.Position = UDim2.new(0, x, 0, y)
	card.BackgroundColor3 = theme.card
	card.BackgroundTransparency = 0.08
	card.BorderSizePixel = 0
	card.ZIndex = 3
	card.Parent = parent
	corner(card, 18)
	glassFrame(card, true)
	stroke(card, 0.14, theme.stroke, 1)
	shine(card, 4, 42)
	return card
end

local function makeLabel(parent, text, x, y, size, bold)
	local l = Instance.new("TextLabel")
	l.Size = UDim2.new(1, -x - 20, 0, 24)
	l.Position = UDim2.new(0, x, 0, y)
	l.BackgroundTransparency = 1
	l.Text = text
	l.Font = bold and Enum.Font.GothamBold or Enum.Font.GothamMedium
	l.TextSize = size
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.ZIndex = 6
	l.Parent = parent
	forceWhite(l)
	return l
end

local function makeButton(parent, text, x, y, w, h)
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(0, w, 0, h)
	b.Position = UDim2.new(0, x, 0, y)
	b.BackgroundColor3 = theme.button2
	b.BackgroundTransparency = 0
	b.BorderSizePixel = 0
	b.Text = text
	b.Font = Enum.Font.GothamBold
	b.TextSize = 13
	b.AutoButtonColor = false
	b.ZIndex = 9
	b.Parent = parent
	forceWhite(b)
	corner(b, 13)
	stroke(b, 0.08, theme.stroke, 1.15)
	glassButton(b)
	b.MouseEnter:Connect(function()
		tween(b, 0.14, {BackgroundColor3 = theme.buttonHover})
	end)
	b.MouseLeave:Connect(function()
		tween(b, 0.14, {BackgroundColor3 = theme.button2})
	end)
	return b
end

local function makeSmallButton(parent, text, x, y, w, h)
	local b = makeButton(parent, text, x, y, w, h)
	b.TextSize = 12
	return b
end

local function makeSlider(parent, title, x, y, w, min, max, default, decimals, callback)
	local draggingSlider = false
	local alpha = math.clamp((default - min) / (max - min), 0, 1)
	local label = makeLabel(parent, title, x, y, 12, true)
	label.Size = UDim2.new(0, w - 76, 0, 20)
	local valuePill = Instance.new("TextLabel")
	valuePill.Size = UDim2.new(0, 66, 0, 25)
	valuePill.Position = UDim2.new(0, x + w - 66, 0, y - 3)
	valuePill.BackgroundColor3 = theme.button2
	valuePill.BackgroundTransparency = 0
	valuePill.BorderSizePixel = 0
	valuePill.Text = tostring(decimals == 0 and math.floor(default) or round(default, decimals))
	valuePill.Font = Enum.Font.GothamBold
	valuePill.TextSize = 11
	valuePill.ZIndex = 8
	valuePill.Parent = parent
	forceWhite(valuePill)
	corner(valuePill, 11)
	stroke(valuePill, 0.1, theme.stroke, 1)
	glassButton(valuePill)
	local track = Instance.new("Frame")
	track.Size = UDim2.new(0, w, 0, 13)
	track.Position = UDim2.new(0, x, 0, y + 35)
	track.BackgroundColor3 = Color3.fromRGB(72, 72, 96)
	track.BackgroundTransparency = 0
	track.BorderSizePixel = 0
	track.ZIndex = 8
	track.Parent = parent
	corner(track, 13)
	stroke(track, 0.24, theme.stroke, 1)
	local fill = Instance.new("Frame")
	fill.Size = UDim2.new(alpha, 0, 1, 0)
	fill.BackgroundColor3 = theme.accent
	fill.BackgroundTransparency = 0
	fill.BorderSizePixel = 0
	fill.ZIndex = 9
	fill.Parent = track
	corner(fill, 13)
	local fg = Instance.new("UIGradient")
	fg.Color = ColorSequence.new(theme.accent, theme.accent2)
	fg.Parent = fill
	local knob = Instance.new("Frame")
	knob.Size = UDim2.new(0, 25, 0, 25)
	knob.Position = UDim2.new(alpha, -12.5, 0.5, -12.5)
	knob.BackgroundColor3 = theme.text
	knob.BackgroundTransparency = 0
	knob.BorderSizePixel = 0
	knob.ZIndex = 11
	knob.Parent = track
	corner(knob, 25)
	stroke(knob, 0.1, theme.stroke, 1.2)
	local inner = Instance.new("Frame")
	inner.Size = UDim2.new(0, 9, 0, 9)
	inner.Position = UDim2.new(0.5, -4.5, 0.5, -4.5)
	inner.BackgroundColor3 = theme.accent2
	inner.BackgroundTransparency = 0
	inner.BorderSizePixel = 0
	inner.ZIndex = 12
	inner.Parent = knob
	corner(inner, 9)
	local hit = Instance.new("TextButton")
	hit.Size = UDim2.new(1, 42, 0, 44)
	hit.Position = UDim2.new(0, -21, 0.5, -22)
	hit.BackgroundTransparency = 1
	hit.Text = ""
	hit.ZIndex = 13
	hit.Parent = track
	local function apply(mouseX)
		local left = track.AbsolutePosition.X
		local width = track.AbsoluteSize.X
		local a = math.clamp((mouseX - left) / width, 0, 1)
		local value = min + ((max - min) * a)
		if decimals == 0 then
			value = math.floor(value + 0.5)
		else
			value = round(value, decimals)
		end
		local newAlpha = math.clamp((value - min) / (max - min), 0, 1)
		valuePill.Text = tostring(value)
		tween(fill, 0.06, {Size = UDim2.new(newAlpha, 0, 1, 0)})
		tween(knob, 0.06, {Position = UDim2.new(newAlpha, -12.5, 0.5, -12.5)})
		callback(value)
	end
	hit.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			draggingSlider = true
			tween(knob, 0.12, {Size = UDim2.new(0, 30, 0, 30), Position = UDim2.new(knob.Position.X.Scale, -15, 0.5, -15)})
			apply(input.Position.X)
		end
	end)
	hit.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			draggingSlider = false
			local a = knob.Position.X.Scale
			tween(knob, 0.12, {Size = UDim2.new(0, 25, 0, 25), Position = UDim2.new(a, -12.5, 0.5, -12.5)})
		end
	end)
	UIS.InputChanged:Connect(function(input)
		if draggingSlider and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			apply(input.Position.X)
		end
	end)
end

local function formatBind(bind)
	local mod = bind.mod
	local key = bind.key.Name
	if mod == "Command" then mod = "⌘" end
	if mod == "None" then mod = "" end
	if mod == "" then return key end
	return mod .. " + " .. key
end

local function updateHeld(input, state)
	if input.KeyCode == Enum.KeyCode.LeftMeta or input.KeyCode == Enum.KeyCode.RightMeta then held.Command = state end
	if input.KeyCode == Enum.KeyCode.LeftAlt or input.KeyCode == Enum.KeyCode.RightAlt then held.Alt = state end
	if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then held.Shift = state end
	if input.KeyCode == Enum.KeyCode.LeftControl or input.KeyCode == Enum.KeyCode.RightControl then held.Ctrl = state end
end

local function isModifierKey(key)
	return key == Enum.KeyCode.LeftMeta
		or key == Enum.KeyCode.RightMeta
		or key == Enum.KeyCode.LeftAlt
		or key == Enum.KeyCode.RightAlt
		or key == Enum.KeyCode.LeftShift
		or key == Enum.KeyCode.RightShift
		or key == Enum.KeyCode.LeftControl
		or key == Enum.KeyCode.RightControl
end

local function getHeldMod()
	if held.Command then return "Command" end
	if held.Alt then return "Alt" end
	if held.Shift then return "Shift" end
	if held.Ctrl then return "Ctrl" end
	return "None"
end

local function bindMatches(bind, key)
	if key ~= bind.key then return false end
	if bind.mod == "Command" then return held.Command end
	if bind.mod == "Alt" then return held.Alt end
	if bind.mod == "Shift" then return held.Shift end
	if bind.mod == "Ctrl" then return held.Ctrl end
	if bind.mod == "None" then return not held.Command and not held.Alt and not held.Shift and not held.Ctrl end
	return false
end

local function isShiftLockActive()
	return UIS.MouseBehavior == Enum.MouseBehavior.LockCenter
end

local function equipSlot(slot)
	local char = LP.Character
	local backpack = LP:FindFirstChildOfClass("Backpack")
	if not char or not backpack then return nil end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum then return nil end
	local tools = {}
	for _, item in ipairs(backpack:GetChildren()) do
		if item:IsA("Tool") then
			table.insert(tools, item)
		end
	end
	for _, item in ipairs(char:GetChildren()) do
		if item:IsA("Tool") then
			table.insert(tools, item)
		end
	end
	table.sort(tools, function(a, b)
		return a.Name:lower() < b.Name:lower()
	end)
	local tool = tools[slot]
	if tool then
		hum:EquipTool(tool)
		return tool
	end
	return nil
end

local function activateEquipped()
	local char = LP.Character
	if not char then return end
	local tool = char:FindFirstChildOfClass("Tool")
	if tool then
		pcall(function()
			tool:Activate()
		end)
	end
end

local function runMacroQ()
	if macroRunning then return end
	macroRunning = true
	task.spawn(function()
		equipSlot(2)
		task.wait(0.025)
		activateEquipped()
		task.wait(0.025)
		equipSlot(2)
		task.wait(0.05)
		macroRunning = false
	end)
end

local function runMacroE()
	if macroRunning then return end
	macroRunning = true
	task.spawn(function()
		equipSlot(1)
		task.wait(0.025)
		local vim = game:GetService("VirtualInputManager")
		vim:SendKeyEvent(true, Enum.KeyCode.E, false, game)
		task.wait(0.015)
		vim:SendKeyEvent(false, Enum.KeyCode.E, false, game)
		task.wait(0.025)
		equipSlot(1)
		task.wait(0.05)
		macroRunning = false
	end)
end

local focusCard = makeCard(bestPage, 0, 0, 285, 190)
makeLabel(focusCard, "lock systm", 22, 22, 18, true)
makeLabel(focusCard, "lock control", 22, 55, 13, false)

local fovVisibleButton = makeButton(focusCard, "FOV Hidden", 22, 88, 241, 38)
local focusButton = makeButton(focusCard, "Enabled", 22, 136, 116, 40)
local focusBindButton = makeButton(focusCard, formatBind(focusBind), 148, 136, 115, 40)

local controlCard = makeCard(bestPage, 305, 0, 315, 292)
makeLabel(controlCard, "Control", 22, 22, 18, true)

makeSlider(controlCard, "Strength", 22, 66, 270, 0.05, 1, focusStrength, 2, function(v)
	focusStrength = v
end)

makeSlider(controlCard, "FOV", 22, 150, 270, 40, 600, fov, 0, function(v)
	fov = math.floor(v)
	fovCircle.Size = UDim2.new(0, fov * 2, 0, fov * 2)
end)

makeSlider(controlCard, "Range", 22, 234, 270, 10, 1000, maxFocusDistance, 0, function(v)
	maxFocusDistance = math.floor(v)
end)

local stealthCard = makeCard(stealthPage, 0, 0, 285, 198)
makeLabel(stealthCard, "Visual esp", 22, 22, 18, true)
makeLabel(stealthCard, "Outline color", 22, 55, 13, false)

local visualButton = makeButton(stealthCard, "Off", 22, 120, 116, 42)
local colorButton = makeButton(stealthCard, "Black", 148, 120, 115, 42)

local commandCard = makeCard(stealthPage, 305, 0, 315, 242)
makeLabel(commandCard, "Command Control", 22, 22, 18, true)
makeLabel(commandCard, "Click a bind then press keys", 22, 55, 13, false)

local visualBindButton = makeButton(commandCard, formatBind(visualBind), 22, 104, 142, 42)
local disableBindButton = makeButton(commandCard, formatBind(disableBind), 176, 104, 116, 42)

local notifyCard = makeCard(stealthPage, 0, 220, 285, 130)
makeLabel(notifyCard, "Notifications", 22, 22, 18, true)
local notifyButton = makeButton(notifyCard, "Enabled", 22, 76, 116, 42)

local macroCard = makeCard(macroPage, 0, 0, 315, 230)
makeLabel(macroCard, "Macro", 22, 22, 18, true)
makeLabel(macroCard, "custom binds", 22, 55, 13, false)
local macroButton = makeButton(macroCard, "Enable macro", 22, 92, 271, 40)
local macroQButton = makeSmallButton(macroCard, "Q bind: " .. formatBind(macroQBind), 22, 145, 130, 38)
local macroEButton = makeSmallButton(macroCard, "E bind: " .. formatBind(macroEBind), 163, 145, 130, 38)
makeLabel(macroCard, "Q: 2 + click + 2", 22, 190, 12, false)
makeLabel(macroCard, "E: 1 + E + 1", 163, 190, 12, false)

local function getChar(player)
	return player.Character
end

local function getRoot(player)
	local char = getChar(player)
	return char and char:FindFirstChild("HumanoidRootPart")
end

local function getHead(player)
	local char = getChar(player)
	return char and char:FindFirstChild("Head")
end

local function getHumanoid(player)
	local char = getChar(player)
	return char and char:FindFirstChildOfClass("Humanoid")
end

local function isAlive(player)
	local hum = getHumanoid(player)
	return hum and hum.Health > 0
end

local function addVisual(player)
	if player == LP then return end
	if highlights[player] then highlights[player]:Destroy() end
	local char = getChar(player)
	if not char then return end
	local h = Instance.new("Highlight")
	h.Name = "LoneVisual"
	h.FillColor = visualColor
	h.OutlineColor = visualColor
	h.FillTransparency = 0.25
	h.OutlineTransparency = 0
	h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	h.Adornee = char
	h.Parent = char
	highlights[player] = h
end

local function removeVisual(player)
	if highlights[player] then
		highlights[player]:Destroy()
		highlights[player] = nil
	end
end

local function refreshVisualColor()
	for _, h in pairs(highlights) do
		h.FillColor = visualColor
		h.OutlineColor = visualColor
	end
end

local function enableVisual()
	visualEnabled = true
	visualButton.Text = "On"
	for _, player in ipairs(Players:GetPlayers()) do
		addVisual(player)
	end
	notify("Visual esp enabled")
end

local function disableVisual()
	visualEnabled = false
	visualButton.Text = "Off"
	for player in pairs(highlights) do
		removeVisual(player)
	end
	notify("Visual esp disabled")
end

local function toggleVisual()
	if visualEnabled then disableVisual() else enableVisual() end
end

local function disableAll()
	disableVisual()
	focusEnabled = false
	focusButton.Text = "Disabled"
	fovVisible = false
	fovVisibleButton.Text = "FOV Hidden"
	fovCircle.Visible = false
	notify("Disabled")
end

local colors = {
	{"Black", Color3.fromRGB(0, 0, 0)},
	{"White", Color3.fromRGB(255, 255, 255)},
	{"Purple", Color3.fromRGB(170, 90, 255)},
	{"Blue", Color3.fromRGB(85, 145, 255)},
	{"Red", Color3.fromRGB(255, 85, 85)},
	{"Green", Color3.fromRGB(85, 255, 145)}
}

local colorIndex = 1

colorButton.MouseButton1Click:Connect(function()
	colorIndex += 1
	if colorIndex > #colors then colorIndex = 1 end
	colorButton.Text = colors[colorIndex][1]
	visualColor = colors[colorIndex][2]
	refreshVisualColor()
	notify("Color " .. colors[colorIndex][1])
end)

fovVisibleButton.MouseButton1Click:Connect(function()
	fovVisible = not fovVisible
	fovVisibleButton.Text = fovVisible and "FOV Visible" or "FOV Hidden"
	fovCircle.Visible = fovVisible and isShiftLockActive()
	notify(fovVisible and "FOV visible" or "FOV hidden")
end)

visualButton.MouseButton1Click:Connect(toggleVisual)

focusButton.MouseButton1Click:Connect(function()
	focusEnabled = not focusEnabled
	focusButton.Text = focusEnabled and "Enabled" or "Disabled"
	notify(focusEnabled and "shift enabled" or "shift disabled")
end)

macroButton.MouseButton1Click:Connect(function()
	macroEnabled = not macroEnabled
	macroButton.Text = macroEnabled and "Macro enabled" or "Enable macro"
	notify(macroEnabled and "Macro enabled" or "Macro disabled")
end)

macroQButton.MouseButton1Click:Connect(function()
	waitingForBind = "macroQ"
	macroQButton.Text = "Press keys"
	notify("Press macro Q bind")
end)

macroEButton.MouseButton1Click:Connect(function()
	waitingForBind = "macroE"
	macroEButton.Text = "Press keys"
	notify("Press macro E bind")
end)

focusBindButton.MouseButton1Click:Connect(function()
	waitingForBind = "focus"
	focusBindButton.Text = "Press keys"
	notify("Press command")
end)

visualBindButton.MouseButton1Click:Connect(function()
	waitingForBind = "visual"
	visualBindButton.Text = "Press keys"
	notify("Press command")
end)

disableBindButton.MouseButton1Click:Connect(function()
	waitingForBind = "disable"
	disableBindButton.Text = "Press keys"
	notify("Press command")
end)

notifyButton.MouseButton1Click:Connect(function()
	notificationsEnabled = not notificationsEnabled
	notifyButton.Text = notificationsEnabled and "Enabled" or "Disabled"
	if notificationsEnabled then notify("Notifications enabled") end
end)

local function getClosestTargetInFOV()
	local center = Vector2.new(Cam.ViewportSize.X / 2, Cam.ViewportSize.Y / 2)
	local closestPlayer = nil
	local closestDistance = fov
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LP and isAlive(player) then
			local root = getRoot(player)
			local head = getHead(player)
			if root and head then
				local distanceFromCamera = (root.Position - Cam.CFrame.Position).Magnitude
				if distanceFromCamera <= maxFocusDistance then
					local screenPos, visible = Cam:WorldToViewportPoint(head.Position)
					if visible and screenPos.Z > 0 then
						local screenDistance = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
						if screenDistance < closestDistance then
							closestDistance = screenDistance
							closestPlayer = player
						end
					end
				end
			end
		end
	end
	return closestPlayer
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function()
		task.wait(0.4)
		if visualEnabled then addVisual(player) end
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	removeVisual(player)
end)

for _, player in ipairs(Players:GetPlayers()) do
	player.CharacterAdded:Connect(function()
		task.wait(0.4)
		if visualEnabled then addVisual(player) end
	end)
end

local dragging = false
local dragStart
local startPos

dragBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = main.Position
	end
end)

dragBar.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = false
	end
end)

UIS.InputChanged:Connect(function(input)
	if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local delta = input.Position - dragStart
		main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
end)

local logoDragging = false
local logoDragStart
local logoStartPos
local logoMoved = false

logoBubble.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		logoDragging = true
		logoMoved = false
		logoDragStart = input.Position
		logoStartPos = logoBubble.Position
	end
end)

logoBubble.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		logoDragging = false
	end
end)

UIS.InputChanged:Connect(function(input)
	if logoDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local delta = input.Position - logoDragStart
		if math.abs(delta.X) > 3 or math.abs(delta.Y) > 3 then logoMoved = true end
		logoBubble.Position = UDim2.new(logoStartPos.X.Scale, logoStartPos.X.Offset + delta.X, logoStartPos.Y.Scale, logoStartPos.Y.Offset + delta.Y)
	end
end)

local opened = false
local busy = false
local openSize = main.Size
local savedPos = UDim2.new(0.5, -430, 0.5, -250)
local closedSize = UDim2.new(0, 860, 0, 0)

local function fade(amount, time)
	for _, v in ipairs(main:GetDescendants()) do
		if v:IsA("TextLabel") or v:IsA("TextButton") then
			tween(v, time, {TextTransparency = amount == 1 and 1 or 0})
		elseif v:IsA("ImageLabel") or v:IsA("ImageButton") then
			if v:GetAttribute("ImgT") == nil then v:SetAttribute("ImgT", v.ImageTransparency) end
			tween(v, time, {ImageTransparency = amount == 1 and 1 or v:GetAttribute("ImgT")})
		elseif v:IsA("Frame") and v ~= main then
			if v:GetAttribute("BgT") == nil then v:SetAttribute("BgT", v.BackgroundTransparency) end
			tween(v, time, {BackgroundTransparency = amount == 1 and 1 or v:GetAttribute("BgT")})
		elseif v:IsA("UIStroke") then
			if v:GetAttribute("StrokeT") == nil then v:SetAttribute("StrokeT", v.Transparency) end
			tween(v, time, {Transparency = amount == 1 and 1 or v:GetAttribute("StrokeT")})
		end
	end
end

local function showBubble()
	logoBubble.Visible = true
	logoBubble.BackgroundTransparency = 1
	bubbleLogo.ImageTransparency = 1
	tween(logoBubble, 0.22, {BackgroundTransparency = 0.08})
	tween(bubbleLogo, 0.22, {ImageTransparency = 0})
	TweenService:Create(bubbleStroke, TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Transparency = 0.12}):Play()
end

local function closeGui(showMinimizedBubble)
	if busy or not opened then return end
	busy = true
	opened = false
	savedPos = main.Position
	fade(1, 0.16)
	tween(blur, 0.25, {Size = 0})
	tween(main, 0.32, {
		Size = closedSize,
		Position = UDim2.new(savedPos.X.Scale, savedPos.X.Offset, savedPos.Y.Scale, savedPos.Y.Offset + 250),
		BackgroundTransparency = 1
	})
	task.delay(0.33, function()
		main.Visible = false
		if showMinimizedBubble then
			showBubble()
		else
			logoBubble.Visible = false
		end
		busy = false
	end)
end

local function openGui()
	if busy or opened then return end
	busy = true
	opened = true
	logoBubble.Visible = false
	main.Visible = true
	main.Size = closedSize
	main.Position = UDim2.new(savedPos.X.Scale, savedPos.X.Offset, savedPos.Y.Scale, savedPos.Y.Offset + 250)
	main.BackgroundTransparency = 1
	fade(1, 0)
	tween(blur, 0.3, {Size = 8})
	tween(main, 0.38, {
		Size = openSize,
		Position = savedPos,
		BackgroundTransparency = 0.2
	})
	task.delay(0.07, function() fade(0, 0.21) end)
	task.delay(0.39, function() busy = false end)
end

local function toggleGuiFromKey()
	if opened then closeGui(false) else openGui() end
end

close.MouseButton1Click:Connect(function() closeGui(false) end)
minimize.MouseButton1Click:Connect(function() closeGui(true) end)

logoBubble.MouseButton1Click:Connect(function()
	task.delay(0.03, function()
		if not logoMoved then openGui() end
	end)
end)

for _, b in ipairs({minimize, close}) do
	b.MouseEnter:Connect(function() tween(b, 0.14, {BackgroundTransparency = 0}) end)
	b.MouseLeave:Connect(function() tween(b, 0.14, {BackgroundTransparency = 0.02}) end)
end

logoBubble.MouseEnter:Connect(function() tween(logoBubble, 0.14, {BackgroundTransparency = 0.04}) end)
logoBubble.MouseLeave:Connect(function() tween(logoBubble, 0.14, {BackgroundTransparency = 0.08}) end)

UIS.InputBegan:Connect(function(input, processed)
	if processed then return end
	updateHeld(input, true)
	if waitingForBind and not isModifierKey(input.KeyCode) then
		local newBind = {mod = getHeldMod(), key = input.KeyCode}
		if waitingForBind == "visual" then
			visualBind = newBind
			visualBindButton.Text = formatBind(visualBind)
			notify("Bind saved " .. formatBind(visualBind))
		elseif waitingForBind == "disable" then
			disableBind = newBind
			disableBindButton.Text = formatBind(disableBind)
			notify("Bind saved " .. formatBind(disableBind))
		elseif waitingForBind == "focus" then
			focusBind = newBind
			focusBindButton.Text = formatBind(focusBind)
			notify("Bind saved " .. formatBind(focusBind))
		elseif waitingForBind == "macroQ" then
			macroQBind = newBind
			macroQButton.Text = "Q bind: " .. formatBind(macroQBind)
			notify("Macro Q bind saved")
		elseif waitingForBind == "macroE" then
			macroEBind = newBind
			macroEButton.Text = "E bind: " .. formatBind(macroEBind)
			notify("Macro E bind saved")
		end
		waitingForBind = nil
		return
	end

	if not macroRunning and macroEnabled and bindMatches(macroQBind, input.KeyCode) then
		runMacroQ()
		return
	end

	if not macroRunning and macroEnabled and bindMatches(macroEBind, input.KeyCode) then
		runMacroE()
		return
	end

	if input.KeyCode == Enum.KeyCode.L then
		toggleGuiFromKey()
		return
	end
	if bindMatches(visualBind, input.KeyCode) then
		toggleVisual()
		return
	end
	if bindMatches(disableBind, input.KeyCode) then
		disableAll()
		return
	end
	if bindMatches(focusBind, input.KeyCode) then
		focusEnabled = not focusEnabled
		focusButton.Text = focusEnabled and "Enabled" or "Disabled"
		notify(focusEnabled and "shift enabled" or "shift disabled")
		return
	end
end)

UIS.InputEnded:Connect(function(input)
	updateHeld(input, false)
end)

RunService.RenderStepped:Connect(function()
	local shiftActive = isShiftLockActive()
	fovCircle.Visible = fovVisible and shiftActive
	if fovCircle.Visible then
		fovCircle.Position = UDim2.new(0.5, 0, 0.5, 0)
	end
	if shiftActive and not shiftLockWasActive then
		notify("lock active")
	end
	shiftLockWasActive = shiftActive
	if not focusEnabled then return end
	if not shiftActive then return end
	local target = getClosestTargetInFOV()
	if not target then return end
	local head = getHead(target)
	if not head then return end
	local camPos = Cam.CFrame.Position
	local targetPos = head.Position + Vector3.new(0, 0.05, 0)
	local wanted = CFrame.new(camPos, targetPos)
	Cam.CFrame = Cam.CFrame:Lerp(wanted, focusStrength)
end)

main.Size = UDim2.new(0, 860, 0, 0)
main.Position = UDim2.new(0.5, -430, 0.5, 0)
main.BackgroundTransparency = 1
fade(1, 0)

local function startupLoad(seconds)
	local holder = Instance.new("Frame")
	holder.AnchorPoint = Vector2.new(0.5, 0.5)
	holder.Size = UDim2.new(0, 650, 0, 120)
	holder.Position = UDim2.new(0.5, 0, 0.5, 0)
	holder.BackgroundTransparency = 1
	holder.BorderSizePixel = 0
	holder.ZIndex = 250
	holder.Parent = gui
	local scale = Instance.new("UIScale")
	scale.Scale = 0.82
	scale.Parent = holder
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 48)
	title.Position = UDim2.new(0, 0, 0, 10)
	title.BackgroundTransparency = 1
	title.Text = "loading lone v2 in " .. tostring(seconds)
	title.Font = Enum.Font.FredokaOne
	title.TextSize = 28
	title.TextXAlignment = Enum.TextXAlignment.Center
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextTransparency = 1
	title.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	title.TextStrokeTransparency = 0.38
	title.ZIndex = 252
	title.Parent = holder
	rainbow(title)
	local sub = Instance.new("TextLabel")
	sub.Size = UDim2.new(1, 0, 0, 34)
	sub.Position = UDim2.new(0, 0, 0, 61)
	sub.BackgroundTransparency = 1
	sub.Text = "(bypassed anticheat..) press L to reopen gui or close "
	sub.Font = Enum.Font.FredokaOne
	sub.TextSize = 21
	sub.TextXAlignment = Enum.TextXAlignment.Center
	sub.TextColor3 = Color3.fromRGB(255, 255, 255)
	sub.TextTransparency = 1
	sub.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	sub.TextStrokeTransparency = 0.5
	sub.ZIndex = 252
	sub.Parent = holder
	rainbow(sub)
	local glow1 = Instance.new("TextLabel")
	glow1.Size = title.Size
	glow1.Position = title.Position + UDim2.new(0, 0, 0, 2)
	glow1.BackgroundTransparency = 1
	glow1.Text = title.Text
	glow1.Font = title.Font
	glow1.TextSize = title.TextSize + 3
	glow1.TextXAlignment = title.TextXAlignment
	glow1.TextColor3 = Color3.fromRGB(255, 255, 255)
	glow1.TextTransparency = 1
	glow1.TextStrokeTransparency = 1
	glow1.ZIndex = 251
	glow1.Parent = holder
	rainbow(glow1)
	local glow2 = Instance.new("TextLabel")
	glow2.Size = sub.Size
	glow2.Position = sub.Position + UDim2.new(0, 0, 0, 2)
	glow2.BackgroundTransparency = 1
	glow2.Text = sub.Text
	glow2.Font = sub.Font
	glow2.TextSize = sub.TextSize + 3
	glow2.TextXAlignment = sub.TextXAlignment
	glow2.TextColor3 = Color3.fromRGB(255, 255, 255)
	glow2.TextTransparency = 1
	glow2.TextStrokeTransparency = 1
	glow2.ZIndex = 251
	glow2.Parent = holder
	rainbow(glow2)
	tween(scale, 0.38, {Scale = 1})
	tween(title, 0.32, {TextTransparency = 0})
	tween(sub, 0.42, {TextTransparency = 0})
	tween(glow1, 0.32, {TextTransparency = 0.78})
	tween(glow2, 0.42, {TextTransparency = 0.82})
	tween(blur, 0.3, {Size = 8})
	local floatTween = TweenService:Create(holder, TweenInfo.new(0.85, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Position = UDim2.new(0.5, 0, 0.5, -10)})
	floatTween:Play()
	for i = seconds, 1, -1 do
		title.Text = "loading lone v2  in " .. tostring(i)
		glow1.Text = title.Text
		task.wait(1)
	end
	floatTween:Cancel()
	tween(holder, 0.28, {Position = UDim2.new(0.5, 0, 0.5, -30)})
	tween(scale, 0.28, {Scale = 0.82})
	tween(title, 0.22, {TextTransparency = 1})
	tween(sub, 0.22, {TextTransparency = 1})
	tween(glow1, 0.22, {TextTransparency = 1})
	tween(glow2, 0.22, {TextTransparency = 1})
	task.wait(0.32)
	holder:Destroy()
end

task.spawn(function()
	task.wait(0.15)
	startupLoad(5)
	openGui()
	task.delay(0.6, function()
		notify("Hi @" .. LP.Name .. " welcome back")
	end)
end)

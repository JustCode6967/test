-- =============================================
-- ███████╗██╗   ██╗██╗  ██╗██╗      █████╗ ██████╗
-- ╚════██║╚██╗ ██╔╝╚██╗██╔╝██║     ██╔══██╗██╔══██╗
--     ██╔╝ ╚████╔╝  ╚███╔╝ ██║     ███████║██████╔╝
--    ██╔╝   ╚██╔╝   ██╔██╗ ██║     ██╔══██║██╔══██╗
--    ██║     ██║   ██╔╝ ██╗███████╗██║  ██║██████╔╝
--    ╚═╝     ╚═╝   ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝
-- ZyxLab v4 — XovaModedLib UI Edition
-- Made by ZyxFTF
-- =============================================

-- =============================================
-- 📦 SERVICES
-- =============================================
local Players              = game:GetService("Players")
local TweenService         = game:GetService("TweenService")
local UIS                  = game:GetService("UserInputService")
local RunService           = game:GetService("RunService")
local Lighting             = game:GetService("Lighting")
local ReplicatedStorage    = game:GetService("ReplicatedStorage")
local HttpService          = game:GetService("HttpService")
local PathfindingService   = game:GetService("PathfindingService")

local player = Players.LocalPlayer or game:GetService("Players").PlayerAdded:Wait()
local camera = workspace.CurrentCamera

-- =============================================
-- 🛑 IN-GAME ERROR DISPLAY
-- =============================================
-- State vars kept inside a closure so they don't consume chunk-scope local slots.
local showErrorOnScreen; do
    local _errorLines = {}
    local _errorGui = nil
    local _errorFrame = nil
    local _errorList = nil
    showErrorOnScreen = function(msg)
        table.insert(_errorLines, tostring(msg))
        pcall(function()
            local pg = player:FindFirstChildOfClass("PlayerGui") or player:WaitForChild("PlayerGui", 10)
            if not pg then return end
            if not _errorGui or not _errorGui.Parent then
                _errorGui = Instance.new("ScreenGui")
                _errorGui.Name = "ZyxLab_ErrorDisplay"
                _errorGui.ResetOnSpawn = false
                _errorGui.DisplayOrder = 2147483647
                _errorGui.IgnoreGuiInset = true
                _errorGui.Parent = pg

                _errorFrame = Instance.new("Frame", _errorGui)
                _errorFrame.Size = UDim2.new(0, 420, 0, 300)
                _errorFrame.Position = UDim2.new(0.5, -210, 0.5, -150)
                _errorFrame.BackgroundColor3 = Color3.fromRGB(18, 5, 5)
                _errorFrame.BorderSizePixel = 0
                _errorFrame.Active = true
                Instance.new("UICorner", _errorFrame).CornerRadius = UDim.new(0, 10)
                local s = Instance.new("UIStroke", _errorFrame)
                s.Color = Color3.fromRGB(220, 50, 50); s.Thickness = 2

                local hdr = Instance.new("TextLabel", _errorFrame)
                hdr.Size = UDim2.new(1, -16, 0, 28)
                hdr.Position = UDim2.new(0, 8, 0, 6)
                hdr.BackgroundTransparency = 1
                hdr.Text = "⚠️ ZyxLab Error Log"
                hdr.Font = Enum.Font.GothamBold
                hdr.TextSize = 14
                hdr.TextColor3 = Color3.fromRGB(255, 100, 100)
                hdr.TextXAlignment = Enum.TextXAlignment.Left

                local sub = Instance.new("TextLabel", _errorFrame)
                sub.Size = UDim2.new(1, -16, 0, 16)
                sub.Position = UDim2.new(0, 8, 0, 34)
                sub.BackgroundTransparency = 1
                sub.Text = "Screenshot this and share it for help"
                sub.Font = Enum.Font.Gotham
                sub.TextSize = 11
                sub.TextColor3 = Color3.fromRGB(200, 180, 180)
                sub.TextXAlignment = Enum.TextXAlignment.Left

                _errorList = Instance.new("ScrollingFrame", _errorFrame)
                _errorList.Size = UDim2.new(1, -16, 1, -60)
                _errorList.Position = UDim2.new(0, 8, 0, 54)
                _errorList.BackgroundTransparency = 1
                _errorList.BorderSizePixel = 0
                _errorList.ScrollBarThickness = 4
                _errorList.CanvasSize = UDim2.new(0, 0, 0, 0)
                _errorList.AutomaticCanvasSize = Enum.AutomaticSize.Y
                Instance.new("UIListLayout", _errorList).Padding = UDim.new(0, 3)
            end

            if _errorList then
                local lbl = Instance.new("TextLabel", _errorList)
                lbl.Size = UDim2.new(1, 0, 0, 0)
                lbl.AutomaticSize = Enum.AutomaticSize.Y
                lbl.BackgroundColor3 = Color3.fromRGB(30, 10, 10)
                lbl.BorderSizePixel = 0
                lbl.Text = "• " .. tostring(msg)
                lbl.Font = Enum.Font.Gotham
                lbl.TextSize = 11
                lbl.TextColor3 = Color3.fromRGB(255, 200, 200)
                lbl.TextXAlignment = Enum.TextXAlignment.Left
                lbl.TextWrapped = true
                Instance.new("UICorner", lbl).CornerRadius = UDim.new(0, 4)
                local pad = Instance.new("UIPadding", lbl)
                pad.PaddingLeft = UDim.new(0, 5)
                pad.PaddingRight = UDim.new(0, 5)
                pad.PaddingTop = UDim.new(0, 3)
                pad.PaddingBottom = UDim.new(0, 3)
            end
        end)
    end
end

-- =============================================
-- ✨ LOADING SCREEN (SCOPED / NON-BLOCKING)
-- =============================================
do
    local ok, err = xpcall(function()
        local DEBUG = false
        local function log(...)
            if DEBUG then print("[ZyxLab Loader]", ...) end
        end

        local env = _G
        pcall(function()
            if getgenv then env = getgenv() end
        end)

        local guiParent = nil
        local okHui, hui = pcall(function()
            return gethui and gethui()
        end)
        if okHui and hui then
            guiParent = hui
            log("Using gethui parent")
        else
            local okGui, pg = pcall(function()
                return player:WaitForChild("PlayerGui", 15)
            end)
            if okGui and pg then
                guiParent = pg
                log("Using PlayerGui parent")
            end
        end

        if not guiParent then
            warn("[ZyxLab Loader] Could not find a GUI parent")
            return
        end

        pcall(function()
            local old = guiParent:FindFirstChild("ZyxLab_LoadingScreen")
            if old then old:Destroy() end
        end)

        local accent = Color3.fromRGB(90, 60, 220)
        local softText = Color3.fromRGB(208, 203, 228)
        local alive = true
        local finished = false
        local startTime = tick()
        local minTime = 5.8
        local targetProgress = 0.08
        local currentProgress = 0
        env.__ZyxLoadingDone = false

        local gui = Instance.new("ScreenGui")
        gui.Name = "ZyxLab_LoadingScreen"
        gui.ResetOnSpawn = false
        gui.IgnoreGuiInset = true
        gui.DisplayOrder = 2147483000
        gui.Enabled = true
        gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        gui.Parent = guiParent

        local overlay = Instance.new("Frame")
        overlay.Name = "Overlay"
        overlay.Size = UDim2.new(1, 0, 1, 0)
        overlay.BackgroundTransparency = 1
        overlay.BorderSizePixel = 0
        overlay.Visible = true
        overlay.ZIndex = 1
        overlay.Parent = gui

        local shadow = Instance.new("Frame")
        shadow.Name = "Shadow"
        shadow.AnchorPoint = Vector2.new(0.5, 0.5)
        shadow.Position = UDim2.new(0.5, 0, 0.5, 8)
        shadow.Size = UDim2.new(0, 394, 0, 150)
        shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        shadow.BackgroundTransparency = 0.62
        shadow.BorderSizePixel = 0
        shadow.ZIndex = 1
        shadow.Parent = overlay
        Instance.new("UICorner", shadow).CornerRadius = UDim.new(0, 22)

        local card = Instance.new("Frame")
        card.Name = "Card"
        card.AnchorPoint = Vector2.new(0.5, 0.5)
        card.Position = UDim2.new(0.5, 0, 0.5, 18)
        card.Size = UDim2.new(0, 380, 0, 136)
        card.BackgroundColor3 = Color3.fromRGB(14, 13, 24)
        card.BackgroundTransparency = 0.16
        card.BorderSizePixel = 0
        card.Visible = true
        card.ZIndex = 2
        card.Parent = overlay
        Instance.new("UICorner", card).CornerRadius = UDim.new(0, 20)

        local cardScale = Instance.new("UIScale")
        cardScale.Scale = 0.96
        cardScale.Parent = card

        local stroke = Instance.new("UIStroke")
        stroke.Color = accent
        stroke.Thickness = 1.4
        stroke.Transparency = 0.42
        stroke.Parent = card

        local cardGradient = Instance.new("UIGradient")
        cardGradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 18, 34)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(11, 10, 19))
        })
        cardGradient.Rotation = 90
        cardGradient.Parent = card

        local accentLine = Instance.new("Frame")
        accentLine.Name = "AccentLine"
        accentLine.Position = UDim2.new(0, 18, 0, 14)
        accentLine.Size = UDim2.new(0, 46, 0, 4)
        accentLine.BackgroundColor3 = accent
        accentLine.BorderSizePixel = 0
        accentLine.ZIndex = 3
        accentLine.Parent = card
        Instance.new("UICorner", accentLine).CornerRadius = UDim.new(1, 0)

        local spinnerWrap = Instance.new("Frame")
        spinnerWrap.Name = "SpinnerWrap"
        spinnerWrap.AnchorPoint = Vector2.new(1, 0)
        spinnerWrap.Position = UDim2.new(1, -20, 0, 18)
        spinnerWrap.Size = UDim2.new(0, 26, 0, 26)
        spinnerWrap.BackgroundTransparency = 1
        spinnerWrap.ZIndex = 3
        spinnerWrap.Parent = card

        local spinnerRing = Instance.new("Frame")
        spinnerRing.Size = UDim2.new(1, 0, 1, 0)
        spinnerRing.BackgroundColor3 = Color3.fromRGB(29, 26, 45)
        spinnerRing.BorderSizePixel = 0
        spinnerRing.ZIndex = 3
        spinnerRing.Parent = spinnerWrap
        Instance.new("UICorner", spinnerRing).CornerRadius = UDim.new(1, 0)

        local spinnerDot = Instance.new("Frame")
        spinnerDot.AnchorPoint = Vector2.new(0.5, 0.5)
        spinnerDot.Position = UDim2.new(0.5, 0, 0, 3)
        spinnerDot.Size = UDim2.new(0, 6, 0, 6)
        spinnerDot.BackgroundColor3 = accent
        spinnerDot.BorderSizePixel = 0
        spinnerDot.ZIndex = 4
        spinnerDot.Parent = spinnerWrap
        Instance.new("UICorner", spinnerDot).CornerRadius = UDim.new(1, 0)

        local title = Instance.new("TextLabel")
        title.Name = "Title"
        title.Position = UDim2.new(0, 20, 0, 30)
        title.Size = UDim2.new(1, -82, 0, 24)
        title.BackgroundTransparency = 1
        title.Text = "ZyxLab"
        title.TextColor3 = Color3.new(1, 1, 1)
        title.TextTransparency = 0.15
        title.TextSize = 22
        title.Font = Enum.Font.GothamBold
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.Visible = true
        title.ZIndex = 3
        title.Parent = card

        local subtitle = Instance.new("TextLabel")
        subtitle.Name = "Subtitle"
        subtitle.Position = UDim2.new(0, 20, 0, 54)
        subtitle.Size = UDim2.new(1, -40, 0, 16)
        subtitle.BackgroundTransparency = 1
        subtitle.Text = "Initializing interface"
        subtitle.TextColor3 = Color3.fromRGB(140, 134, 172)
        subtitle.TextSize = 11
        subtitle.Font = Enum.Font.GothamMedium
        subtitle.TextXAlignment = Enum.TextXAlignment.Left
        subtitle.Visible = true
        subtitle.ZIndex = 3
        subtitle.Parent = card

        local status = Instance.new("TextLabel")
        status.Name = "Status"
        status.Position = UDim2.new(0, 20, 0, 81)
        status.Size = UDim2.new(1, -40, 0, 20)
        status.BackgroundTransparency = 1
        status.Text = "Starting interface"
        status.TextColor3 = softText
        status.TextTransparency = 0.18
        status.TextSize = 12
        status.Font = Enum.Font.GothamMedium
        status.TextXAlignment = Enum.TextXAlignment.Left
        status.Visible = true
        status.ZIndex = 3
        status.Parent = card
        status:SetAttribute("BaseText", status.Text)

        local barBack = Instance.new("Frame")
        barBack.Name = "ProgressBack"
        barBack.Position = UDim2.new(0, 20, 1, -26)
        barBack.Size = UDim2.new(1, -40, 0, 6)
        barBack.BackgroundColor3 = Color3.fromRGB(36, 31, 54)
        barBack.BackgroundTransparency = 0
        barBack.BorderSizePixel = 0
        barBack.Visible = true
        barBack.ZIndex = 3
        barBack.Parent = card
        Instance.new("UICorner", barBack).CornerRadius = UDim.new(1, 0)

        local barFill = Instance.new("Frame")
        barFill.Name = "ProgressFill"
        barFill.Size = UDim2.new(0, 0, 1, 0)
        barFill.BackgroundColor3 = accent
        barFill.BackgroundTransparency = 0
        barFill.BorderSizePixel = 0
        barFill.Visible = true
        barFill.ZIndex = 4
        barFill.Parent = barBack
        Instance.new("UICorner", barFill).CornerRadius = UDim.new(1, 0)

        local shine = Instance.new("Frame")
        shine.Name = "Shine"
        shine.AnchorPoint = Vector2.new(0, 0.5)
        shine.Position = UDim2.new(0, -36, 0.5, 0)
        shine.Size = UDim2.new(0, 36, 1, 6)
        shine.BackgroundTransparency = 1
        shine.BorderSizePixel = 0
        shine.ZIndex = 5
        shine.Parent = barFill
        local shineGradient = Instance.new("UIGradient")
        shineGradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255,255,255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255,255,255))
        })
        shineGradient.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(0.5, 0.55),
            NumberSequenceKeypoint.new(1, 1)
        })
        shineGradient.Rotation = 0
        shineGradient.Parent = shine

        local dotsWrap = Instance.new("Frame")
        dotsWrap.Name = "DotsWrap"
        dotsWrap.AnchorPoint = Vector2.new(1, 1)
        dotsWrap.Position = UDim2.new(1, -20, 1, -34)
        dotsWrap.Size = UDim2.new(0, 42, 0, 10)
        dotsWrap.BackgroundTransparency = 1
        dotsWrap.ZIndex = 3
        dotsWrap.Parent = card

        local dots = {}
        for i = 1, 3 do
            local dot = Instance.new("Frame")
            dot.Size = UDim2.new(0, 6, 0, 6)
            dot.Position = UDim2.new(0, (i - 1) * 12, 0, 2)
            dot.BackgroundColor3 = accent
            dot.BackgroundTransparency = 0.55
            dot.BorderSizePixel = 0
            dot.ZIndex = 4
            dot.Parent = dotsWrap
            Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
            dots[i] = dot
        end

        pcall(function()
            local intro = TweenInfo.new(0.75, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
            local introSoft = TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            TweenService:Create(card, intro, {
                Position = UDim2.new(0.5, 0, 0.5, 0),
                BackgroundTransparency = 0.04
            }):Play()
            TweenService:Create(cardScale, intro, { Scale = 1 }):Play()
            TweenService:Create(shadow, intro, {
                BackgroundTransparency = 0.72,
                Position = UDim2.new(0.5, 0, 0.5, 10)
            }):Play()
            TweenService:Create(stroke, introSoft, {Transparency = 0.18}):Play()
            TweenService:Create(title, introSoft, {TextTransparency = 0}):Play()
            TweenService:Create(subtitle, introSoft, {TextTransparency = 0}):Play()
            TweenService:Create(status, introSoft, {TextTransparency = 0}):Play()
        end)

        env.__ZyxLoadingSet = function(text, progress)
            if not alive or not gui.Parent then return end
            if type(text) == "string" and text ~= "" then
                status:SetAttribute("BaseText", text)
                status.Text = text
                log(text)
            end
            if type(progress) == "number" and progress > targetProgress then
                targetProgress = math.clamp(progress, 0, 0.985)
            end
        end

        env.__ZyxLoadingFinish = function(text)
            if finished or not gui.Parent then return end
            finished = true
            alive = false
            if type(text) == "string" and text ~= "" then
                status:SetAttribute("BaseText", text)
                status.Text = text
            end
            task.spawn(function()
                targetProgress = 1
                local finishStart = tick()
                while gui.Parent and currentProgress < 0.995 and tick() - finishStart < 1.15 do
                    currentProgress = currentProgress + ((1 - currentProgress) * 0.14)
                    barFill.Size = UDim2.new(currentProgress, 0, 1, 0)
                    task.wait(0.025)
                end
                barFill.Size = UDim2.new(1, 0, 1, 0)
                local remaining = minTime - (tick() - startTime)
                if remaining > 0 then task.wait(remaining) end
                local ti = TweenInfo.new(0.62, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
                pcall(function() TweenService:Create(cardScale, ti, {Scale = 0.985}):Play() end)
                pcall(function() TweenService:Create(card, ti, {BackgroundTransparency = 1, Position = UDim2.new(0.5, 0, 0.5, 8)}):Play() end)
                pcall(function() TweenService:Create(shadow, ti, {BackgroundTransparency = 1}):Play() end)
                pcall(function() TweenService:Create(stroke, ti, {Transparency = 1}):Play() end)
                pcall(function() TweenService:Create(accentLine, ti, {BackgroundTransparency = 1}):Play() end)
                pcall(function() TweenService:Create(spinnerRing, ti, {BackgroundTransparency = 1}):Play() end)
                pcall(function() TweenService:Create(spinnerDot, ti, {BackgroundTransparency = 1}):Play() end)
                pcall(function() TweenService:Create(title, ti, {TextTransparency = 1}):Play() end)
                pcall(function() TweenService:Create(subtitle, ti, {TextTransparency = 1}):Play() end)
                pcall(function() TweenService:Create(status, ti, {TextTransparency = 1}):Play() end)
                pcall(function() TweenService:Create(barBack, ti, {BackgroundTransparency = 1}):Play() end)
                pcall(function() TweenService:Create(barFill, ti, {BackgroundTransparency = 1}):Play() end)
                for _, dot in ipairs(dots) do
                    pcall(function() TweenService:Create(dot, ti, {BackgroundTransparency = 1}):Play() end)
                end
                task.wait(0.72)
                if gui and gui.Parent then gui:Destroy() end
                env.__ZyxLoadingDone = true
            end)
        end

        env.__ZyxLoadingError = function(text)
            alive = false
            finished = true
            if gui and gui.Parent then
                status:SetAttribute("BaseText", tostring(text or "Startup failed"))
                status.Text = tostring(text or "Startup failed")
                barFill.BackgroundColor3 = Color3.fromRGB(255, 80, 90)
                accentLine.BackgroundColor3 = Color3.fromRGB(255, 80, 90)
                stroke.Color = Color3.fromRGB(255, 80, 90)
                subtitle.Text = "Loader error"
            end
            warn("[ZyxLab Loader]", text)
        end

        task.spawn(function()
            local lastDot = 0
            local dotIndex = 1
            local angle = 0
            local shineOffset = -36
            while alive and gui.Parent do
                currentProgress = currentProgress + ((targetProgress - currentProgress) * 0.10)
                barFill.Size = UDim2.new(currentProgress, 0, 1, 0)

                angle = (angle + 8) % 360
                local radians = math.rad(angle)
                spinnerDot.Position = UDim2.new(0.5, math.cos(radians) * 8, 0.5, math.sin(radians) * 8)

                if barFill.AbsoluteSize.X > 24 then
                    shine.BackgroundTransparency = 0
                    shineOffset = shineOffset + 2.5
                    if shineOffset > barFill.AbsoluteSize.X + 36 then
                        shineOffset = -36
                    end
                    shine.Position = UDim2.new(0, shineOffset, 0.5, 0)
                else
                    shine.BackgroundTransparency = 1
                end

                if tick() - lastDot >= 0.16 then
                    lastDot = tick()
                    dotIndex = (dotIndex % 3) + 1
                    for i, dot in ipairs(dots) do
                        dot.BackgroundTransparency = (i == dotIndex) and 0.05 or 0.55
                    end
                end

                task.wait(0.03)
            end
        end)

        task.delay(35, function()
            if not finished and gui and gui.Parent then
                warn("[ZyxLab Loader] Safety timeout destroying loader")
                alive = false
                gui:Destroy()
            end
        end)

        log("Loading screen parented to", gui.Parent and gui.Parent:GetFullName() or "nil")
        task.wait(0.18)
    end, function(e)
        return tostring(e)
    end)

    if not ok then
        warn("[ZyxLab Loader] Creation error:", err)
    end
end

-- =============================================
-- 📋 FORWARD DECLARATIONS (CROSS-SECTION NAMES)
-- =============================================
-- Each section below is wrapped in a `do ... end` block so its internal
-- helpers are scoped to that section and don't pile up at chunk-level
-- (Lua's hard cap is 200 simultaneously active locals in the main chunk).
--
-- The names below are forward-declared once here; sections then ASSIGN to
-- them (e.g. `function enableFullbright()` instead of `local function
-- enableFullbright()`) so the outer pre-declared local is the target.
--
-- 👉 To add new cross-section names: drop them into the right group below.

-- UTILITIES
local deepCopy, getGuiParent, color3ToHex, hexToColor3

-- THEME / CHROMA SYSTEM
local DEFAULT_THEME, theme, chromaHue
local getEffectiveAccent, getEffectiveESPFill, getEffectiveESPOutline, espFT, espOT
local espRefreshFns, registerESPRefresh

-- CONFIG SYSTEM
local DEFAULT_CFG, DEFAULT_STATE
local listConfigs, saveConfigList, readConfig, writeConfig, deleteConfig
local getLastCfgName, setLastCfgName

-- FEATURE STATE
local state, activeConfigName, applyConfigData

-- FEATURE LOGIC (fullbright, noslow, beast notifier)
local enableFullbright, disableFullbright
local isBeastSelf, enableNoSlow, disableNoSlow
local showBeastNotif, notifGui, beastNotifierReady

-- ESP MODULES
local applyPlayerHighlight, clearPlayerESP
local applyDoorESP, clearDoorESP
local applyExitESP, clearExitESP, clearComputerESP
local applyFreezeESP, clearFreezeESP

-- SOUNDPACK
local refreshSoundpack

-- PATH VISUALIZER
local VIZ_ACTIVE, VIZ_BLOCKED
local vizInit, vizClear, vizDrawPath, vizSetColor, vizMarkEscape

-- WALL SCANNER (used by walkTo, escape, sentinel)
local SCAN_DIST_MAX
local buildExclude
local castRay, fanHits, scan360, bestOpenDir

-- BEAST DETECTION / AVOIDANCE
local beast, getBeastPos, beastNear, beastNearLocal
local avoidance, doFleeFromBeast

-- EXIT DOOR ENGINE
local exitEngine, exitLocalEscaped

-- FARM
local getAllComputers, hackComputer

-- CONFIG PAGE BRIDGE (chroma loop needs this)
local protectProfileAvatarImages


-- =============================================
-- 🔧 UTILITIES
-- =============================================
do  -- 🔒 UTILITIES section (scopes internal locals)
function deepCopy(t)
    local c = {}
    for k, v in pairs(t) do
        c[k] = type(v) == "table" and deepCopy(v) or v
    end
    return c
end

-- gethui fallback (executor-safe parent for our extra GUIs)
function getGuiParent()
    local ok, hui = pcall(function() return gethui and gethui() end)
    if ok and hui then return hui end
    return player:WaitForChild("PlayerGui")
end

-- Hex helpers
function color3ToHex(c)
    return string.format("#%02X%02X%02X",
        math.floor(c.R * 255 + 0.5),
        math.floor(c.G * 255 + 0.5),
        math.floor(c.B * 255 + 0.5))
end
function hexToColor3(hex)
    if type(hex) ~= "string" then return nil end
    hex = hex:gsub("#", ""):gsub("%s", "")
    if #hex == 3 then
        hex = hex:sub(1,1):rep(2) .. hex:sub(2,2):rep(2) .. hex:sub(3,3):rep(2)
    end
    if #hex ~= 6 then return nil end
    local r = tonumber(hex:sub(1,2), 16)
    local g = tonumber(hex:sub(3,4), 16)
    local b = tonumber(hex:sub(5,6), 16)
    if not (r and g and b) then return nil end
    return Color3.fromRGB(r, g, b)
end
end  -- close UTILITIES section

-- =============================================
-- 🎨 DEFAULT THEME
-- =============================================
do  -- 🔒 DEFAULT_THEME section (scopes internal locals)
-- ESP slot layout: {fillR, fillG, fillB, outR, outG, outB, fillTrans(0-100), outTrans(0-100), fillChroma(bool), outChroma(bool)}
DEFAULT_THEME = {
    accentR        = 90,  accentG  = 60,  accentB  = 220,
    accentChroma   = false,
    espPlayer      = {0,255,0,     0,255,0,     50, 0, false, false},
    espBeast       = {255,0,0,     255,80,80,   50, 0, false, false},
    espDoor        = {0,170,255,   0,255,255,   50, 0, false, false},
    espExit        = {255,85,255,  255,170,255, 50, 0, false, false},
    espComputer    = {0,128,255,   0,128,255,   50, 0, false, false},
    espFreeze      = {200,81,31,   255,153,29,  50, 0, false, false},
    snd_Typing     = true,  snd_Error    = true,  snd_Popup    = true,
    snd_DoorOpen   = true,  snd_DoorClose = true, snd_ExitOpen = true,
    snd_Unlock     = true,  snd_HitWall  = true,  snd_HitPlayer = true,
    snd_Chase      = true,  snd_Heartbeat = true,
    streamerName   = "Sigma",
    streamerLevel  = "67",
}

theme = deepCopy(DEFAULT_THEME)
end  -- close DEFAULT_THEME section

-- =============================================
-- 🌈 CHROMA SYSTEM
-- =============================================
do  -- 🔒 CHROMA_SYSTEM section (scopes internal locals)
chromaHue = 0  -- shared hue for all chroma slots (with offsets per slot)

function getEffectiveAccent()
    if theme.accentChroma then
        return Color3.fromHSV(chromaHue, 0.88, 1)
    end
    return Color3.fromRGB(theme.accentR, theme.accentG, theme.accentB)
end

function getEffectiveESPFill(key)
    local t = theme[key]
    if t[9] then return Color3.fromHSV(chromaHue, 0.85, 1) end
    return Color3.fromRGB(t[1], t[2], t[3])
end
function getEffectiveESPOutline(key)
    local t = theme[key]
    if t[10] then return Color3.fromHSV((chromaHue + 0.08) % 1, 0.85, 1) end
    return Color3.fromRGB(t[4], t[5], t[6])
end
function espFT(key) return (theme[key][7] or 50) / 100 end
function espOT(key) return (theme[key][8] or 0)  / 100 end

-- All ESP refresh callbacks register here; the chroma loop runs them when needed
espRefreshFns = {}
function registerESPRefresh(fn) table.insert(espRefreshFns, fn) end
end  -- close CHROMA_SYSTEM section

-- =============================================
-- 💾 CONFIG SYSTEM
-- =============================================
do  -- 🔒 CONFIG_SYSTEM section (scopes internal locals)
local CFG_DIR       = "ZyxLab_Configs/"
local CFG_LIST      = "ZyxLab_Configs/index.json"
local LAST_CFG_FILE = "ZyxLab_LastConfig.txt"
DEFAULT_CFG   = "Default"

local function ensureDir()
    pcall(function()
        if not isfolder(CFG_DIR) then makefolder(CFG_DIR) end
    end)
end

DEFAULT_STATE = {
    antierror    = true,
    antiafk      = false,
    fullbright   = false,
    noslow       = true,
    beastnotify  = true,
    playerESP    = true,
    doorESP      = true,
    exitESP      = true,
    computerESP  = true,
    freezepodESP = true,
    progressbar  = true,
    soundpack    = false,
    streamermode = false,
    nohammercooldown = false,
    silenthack = false,
    autotie = false,
    forcebeastability = false,
    slowbeast = false,
    removerope = false,
    autosavecaptured = false,
}

local function buildDefaultCfgData()
    return { state = deepCopy(DEFAULT_STATE), theme = deepCopy(DEFAULT_THEME) }
end

function listConfigs()
    ensureDir()
    local names = {DEFAULT_CFG}
    pcall(function()
        if isfile(CFG_LIST) then
            local parsed = HttpService:JSONDecode(readfile(CFG_LIST))
            for _, n in ipairs(parsed) do
                if n ~= DEFAULT_CFG then table.insert(names, n) end
            end
        end
    end)
    return names
end

function saveConfigList(names)
    ensureDir()
    pcall(function()
        local filtered = {}
        for _, n in ipairs(names) do
            if n ~= DEFAULT_CFG then table.insert(filtered, n) end
        end
        writefile(CFG_LIST, HttpService:JSONEncode(filtered))
    end)
end

function readConfig(name)
    if name == DEFAULT_CFG then return buildDefaultCfgData() end
    local ok, data = pcall(function() return readfile(CFG_DIR .. name .. ".json") end)
    if ok and data and data ~= "" then
        local ok2, parsed = pcall(function() return HttpService:JSONDecode(data) end)
        if ok2 then return parsed end
    end
    return nil
end

function writeConfig(name, stateTable, themeTable)
    if name == DEFAULT_CFG then return false end
    ensureDir()
    local data = { state = {}, theme = deepCopy(themeTable) }
    for k, v in pairs(stateTable) do data.state[k] = v end
    local ok = pcall(function()
        writefile(CFG_DIR .. name .. ".json", HttpService:JSONEncode(data))
    end)
    return ok
end

function deleteConfig(name)
    if name == DEFAULT_CFG then return end
    pcall(function() delfile(CFG_DIR .. name .. ".json") end)
    local names = listConfigs()
    local new = {}
    for _, n in ipairs(names) do
        if n ~= name and n ~= DEFAULT_CFG then table.insert(new, n) end
    end
    saveConfigList(new)
end

function getLastCfgName()
    local ok, name = pcall(function() return readfile(LAST_CFG_FILE) end)
    if ok and name and name ~= "" then return name end
    return DEFAULT_CFG
end
function setLastCfgName(name)
    pcall(function() writefile(LAST_CFG_FILE, name) end)
end
end  -- close CONFIG_SYSTEM section

-- =============================================
-- 🔧 FEATURE STATE
-- =============================================
do  -- 🔒 FEATURE_STATE section (scopes internal locals)
state = {
    antierror    = false, antiafk      = false, fullbright   = false,
    noslow       = false, beastnotify  = false,
    playerESP    = false, doorESP      = false,
    exitESP      = false, computerESP  = false,
    freezepodESP = false, progressbar  = false,
    soundpack    = false,
    streamermode = false, nohammercooldown = false,
    silenthack   = false, autotie = false, hitaura = false, hitaurarange = 20,
    forcebeastability = false, slowbeast = false,
    removerope   = false,
    autosavecaptured = false,
}

activeConfigName = getLastCfgName()

function applyConfigData(cfg)
    if not cfg then return end
    if cfg.state then
        for k, v in pairs(cfg.state) do
            if state[k] ~= nil then state[k] = v end
        end
    end
    if cfg.theme then
        -- Reset theme to defaults first to avoid stale fields when loading older configs
        for k, v in pairs(DEFAULT_THEME) do
            theme[k] = type(v) == "table" and deepCopy(v) or v
        end
        for k, v in pairs(cfg.theme) do
            if type(v) == "table" then
                -- Merge into the existing slot to preserve newer fields like chroma flags
                local slot = theme[k]
                if type(slot) == "table" then
                    for i, sv in pairs(v) do slot[i] = sv end
                else
                    theme[k] = deepCopy(v)
                end
            else
                theme[k] = v
            end
        end
    end
end

-- Load initial config at startup
applyConfigData(readConfig(activeConfigName))

end  -- close FEATURE_STATE section
-- =============================================
-- 🌟 FEATURE LOGIC (preserved from v3)
-- =============================================
do  -- 🔒 FEATURE_LOGIC section (scopes internal locals)

-- ─── ANTI-ERROR ───
local oldnc
pcall(function()
oldnc = hookmetamethod(game, "__namecall", newcclosure(function(name, ...)
    local Args = {...}
    if state.antierror and not checkcaller()
    and tostring(name) == "RemoteEvent" and Args[1] == "SetPlayerMinigameResult" then
        Args[2] = true
    end
    return oldnc(name, unpack(Args))
end))
end) -- end pcall for hookmetamethod

-- ─── FULLBRIGHT ───
local fullbrightConn
local fullbrightOriginals = nil
function enableFullbright()
    if fullbrightConn then fullbrightConn:Disconnect(); fullbrightConn = nil end
    if not fullbrightOriginals then
        fullbrightOriginals = {
            Brightness       = Lighting.Brightness,
            ClockTime        = Lighting.ClockTime,
            FogEnd           = Lighting.FogEnd,
            FogStart         = Lighting.FogStart,
            GlobalShadows    = Lighting.GlobalShadows,
            OutdoorAmbient   = Lighting.OutdoorAmbient,
            Ambient          = Lighting.Ambient,
        }
    end
    fullbrightConn = RunService.RenderStepped:Connect(function()
        if not state.fullbright then
            fullbrightConn:Disconnect(); fullbrightConn = nil
            return
        end
        Lighting.Brightness     = 10
        Lighting.ClockTime      = 14
        Lighting.FogEnd         = 9e9
        Lighting.FogStart       = 9e9
        Lighting.GlobalShadows  = false
        Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
        Lighting.Ambient        = Color3.fromRGB(255, 255, 255)
    end)
end
function disableFullbright()
    if fullbrightConn then fullbrightConn:Disconnect(); fullbrightConn = nil end
    if fullbrightOriginals then
        pcall(function()
            Lighting.Brightness     = fullbrightOriginals.Brightness
            Lighting.ClockTime      = fullbrightOriginals.ClockTime
            Lighting.FogEnd         = fullbrightOriginals.FogEnd
            Lighting.FogStart       = fullbrightOriginals.FogStart
            Lighting.GlobalShadows  = fullbrightOriginals.GlobalShadows
            Lighting.OutdoorAmbient = fullbrightOriginals.OutdoorAmbient
            Lighting.Ambient        = fullbrightOriginals.Ambient
        end)
        fullbrightOriginals = nil
    end
end

-- ─── NO SLOW ───
local noslowConn
function isBeastSelf()
    local stats = player:FindFirstChild("TempPlayerStatsModule") or player:FindFirstChild("PlayerStats")
    if stats then
        local val = stats:FindFirstChild("IsBeast") or stats:FindFirstChild("IsMonster")
        if val and val.Value == true then return true end
    end
    return false
end
function enableNoSlow()
    if noslowConn then noslowConn:Disconnect() end
    noslowConn = RunService.RenderStepped:Connect(function()
        if not state.noslow or not isBeastSelf() then return end
        local char = player.Character
        if not char then return end
        local hum = char:FindFirstChild("Humanoid")
        if hum and hum.WalkSpeed < 16 then hum.WalkSpeed = 16 end
    end)
end
function disableNoSlow()
    if noslowConn then noslowConn:Disconnect(); noslowConn = nil end
end

-- ─── BEAST NOTIFIER (custom avatar GUI; separate from library notifications) ───
notifGui = Instance.new("ScreenGui")
notifGui.Name = "ZyxLab_BeastNotifs"
notifGui.ResetOnSpawn = false
notifGui.DisplayOrder = 1500
notifGui.IgnoreGuiInset = true
notifGui.Enabled = false -- keep beast popups hidden until the main UI has loaded
notifGui.Parent = getGuiParent()
beastNotifierReady = false

local notifyHolder = Instance.new("Frame", notifGui)
notifyHolder.Size = UDim2.new(0, 250, 1, 0)
notifyHolder.Position = UDim2.new(1, -260, 0, 100)
notifyHolder.BackgroundTransparency = 1

local notifyStack = {}

function showBeastNotif(text, userId)
    if not beastNotifierReady or not notifGui.Enabled then return end
    local frame = Instance.new("Frame", notifyHolder)
    frame.Size = UDim2.new(1, 0, 0, 60)
    frame.BackgroundColor3 = Color3.fromRGB(14, 12, 22)
    frame.BorderSizePixel = 0
    frame.Position = UDim2.new(0, 0, 0, -70)
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 14)
    local stroke = Instance.new("UIStroke", frame)
    stroke.Color = getEffectiveAccent(); stroke.Thickness = 1.5; stroke.Transparency = 0.2
    frame:SetAttribute("ZyxAccentStroke", true)

    local av = Instance.new("ImageLabel", frame)
    av.Size = UDim2.new(0, 42, 0, 42); av.Position = UDim2.new(0, 10, 0.5, -21)
    av.BackgroundTransparency = 1
    pcall(function()
        av.Image = Players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
    end)
    Instance.new("UICorner", av).CornerRadius = UDim.new(1, 0)

    local lbl = Instance.new("TextLabel", frame)
    lbl.Size = UDim2.new(1, -62, 1, 0); lbl.Position = UDim2.new(0, 58, 0, 0)
    lbl.BackgroundTransparency = 1; lbl.Text = text
    lbl.Font = Enum.Font.GothamBold; lbl.TextScaled = true
    lbl.TextColor3 = Color3.new(1,1,1); lbl.TextXAlignment = Enum.TextXAlignment.Left

    pcall(function()
        local snd = Instance.new("Sound", frame)
        snd.SoundId = "rbxassetid://138118203571469"
        snd:Play()
    end)

    table.insert(notifyStack, 1, frame)
    for i, v in ipairs(notifyStack) do
        TweenService:Create(v, TweenInfo.new(0.4, Enum.EasingStyle.Quint), {
            Position = UDim2.new(0, 0, 0, (i-1) * 70)
        }):Play()
    end

    task.delay(4, function()
        for i, v in ipairs(notifyStack) do
            if v == frame then table.remove(notifyStack, i); break end
        end
        TweenService:Create(frame, TweenInfo.new(0.3), {
            Position = UDim2.new(1, 10, 0, frame.Position.Y.Offset)
        }):Play()
        task.wait(0.35); frame:Destroy()
        for i, v in ipairs(notifyStack) do
            TweenService:Create(v, TweenInfo.new(0.4, Enum.EasingStyle.Quint), {
                Position = UDim2.new(0, 0, 0, (i-1) * 70)
            }):Play()
        end
    end)
end

local currentBeast    = nil
local lastPower       = nil
local lastPowerActive = false

task.spawn(function()
    local beastRechargeNotifiedPlayers = {}
    while true do
        if state.beastnotify then
            for _, plr in pairs(game:GetService("Players"):GetPlayers()) do
                local stats = plr:FindFirstChild("TempPlayerStatsModule")
                if stats and stats:FindFirstChild("IsBeast") and stats.IsBeast.Value then
                    if currentBeast ~= plr then
                        -- Snapshot whatever CurrentPower already holds (leftover from last round)
                        -- so we don't misfire "chose X" before they've actually picked anything
                        local cp = ReplicatedStorage:FindFirstChild("CurrentPower")
                        lastPower = cp and cp.Value or nil
                        lastPowerActive = false
                        currentBeast = plr
                        showBeastNotif(plr.Name .. " is Beast!", plr.UserId)
                    end
                end
            end
            if currentBeast then
                local cp = ReplicatedStorage:FindFirstChild("CurrentPower")
                local pa = ReplicatedStorage:FindFirstChild("PowerActive")
                if cp and cp.Value ~= "" and lastPower ~= cp.Value then
                    lastPower = cp.Value
                    showBeastNotif(currentBeast.Name .. " chose " .. cp.Value, currentBeast.UserId)
                end
                if pa then
                    if pa.Value and not lastPowerActive then
                        lastPowerActive = true
                        showBeastNotif(currentBeast.Name .. " used " .. (lastPower or "power"), currentBeast.UserId)
                    elseif not pa.Value then lastPowerActive = false end
                end

                -- Ability recharge stays merged into the existing Beast Notifier.
                -- No CoreGui/StarterGui notification is used here, so it works with the
                -- same avatar toast system as "is Beast", "chose power", and "used power".
                local char = currentBeast.Character
                local beastPowers = char and char:FindFirstChild("BeastPowers")
                local progress = beastPowers and beastPowers:FindFirstChild("PowerProgressPercent")
                if progress then
                    if progress.Value <= 0 then
                        beastRechargeNotifiedPlayers[currentBeast.UserId] = nil
                    elseif progress.Value >= 1 and not beastRechargeNotifiedPlayers[currentBeast.UserId] then
                        beastRechargeNotifiedPlayers[currentBeast.UserId] = true
                        showBeastNotif(currentBeast.Name .. "'s ability is ready!", currentBeast.UserId)
                    end
                end
            end
        end
        task.wait(0.2)
    end
end)

end  -- close FEATURE_LOGIC section
-- =============================================
-- 👁️ ESP MODULES
-- =============================================
do  -- 🔒 ESP_MODULES section (scopes internal locals)

-- ─── PLAYER ESP ───
local playerHighlights = {}
local function isBeastPlayer(plr)
    local s = plr:FindFirstChild("TempPlayerStatsModule")
    return s and s:FindFirstChild("IsBeast") and s.IsBeast.Value == true
end
local function createNameTag(plr)
    if not plr.Character then return end
    if plr.Character:FindFirstChild("ZyxNameTag") then return end
    local head = plr.Character:FindFirstChild("Head")
    if not head then return end
    local bill = Instance.new("BillboardGui", head)
    bill.Name = "ZyxNameTag"; bill.Size = UDim2.new(0, 100, 0, 30)
    bill.StudsOffset = Vector3.new(0, 2.5, 0); bill.AlwaysOnTop = true
    local txt = Instance.new("TextLabel", bill)
    txt.Size = UDim2.new(1, 0, 1, 0); txt.BackgroundTransparency = 1
    txt.Text = plr.Name; txt.TextColor3 = Color3.new(1, 1, 1)
    txt.TextStrokeTransparency = 0; txt.TextScaled = true; txt.Font = Enum.Font.GothamBold
end
function applyPlayerHighlight(plr)
    if plr == player or not plr.Character then return end
    if playerHighlights[plr] then return end
    local h = Instance.new("Highlight", plr.Character)
    h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    h.Adornee = plr.Character
    local key = isBeastPlayer(plr) and "espBeast" or "espPlayer"
    h.FillColor       = getEffectiveESPFill(key)
    h.OutlineColor    = getEffectiveESPOutline(key)
    h.FillTransparency    = espFT(key)
    h.OutlineTransparency = espOT(key)
    playerHighlights[plr] = h
    createNameTag(plr)
end
function clearPlayerESP()
    for _, plr in pairs(game:GetService("Players"):GetPlayers()) do
        if plr.Character and plr.Character:FindFirstChild("ZyxNameTag") then
            plr.Character.ZyxNameTag:Destroy()
        end
    end
    for _, v in pairs(playerHighlights) do if v then v:Destroy() end end
    playerHighlights = {}
end
local function refreshPlayerESPColors()
    for plr, h in pairs(playerHighlights) do
        if h and h.Parent then
            local key = isBeastPlayer(plr) and "espBeast" or "espPlayer"
            h.FillColor       = getEffectiveESPFill(key)
            h.OutlineColor    = getEffectiveESPOutline(key)
            h.FillTransparency    = espFT(key)
            h.OutlineTransparency = espOT(key)
        end
    end
end
registerESPRefresh(refreshPlayerESPColors)

local function setupPlayerESP(plr)
    if plr == player then return end
    plr.CharacterAdded:Connect(function()
        task.wait(0.2)
        if state.playerESP then applyPlayerHighlight(plr) end
    end)
    local stats = plr:FindFirstChild("TempPlayerStatsModule")
    if stats then
        local val = stats:FindFirstChild("IsBeast")
        if val then
            val.Changed:Connect(function()
                if playerHighlights[plr] then playerHighlights[plr]:Destroy(); playerHighlights[plr] = nil end
                if state.playerESP then applyPlayerHighlight(plr) end
            end)
        end
    end
end
for _, p in pairs(game:GetService("Players"):GetPlayers()) do setupPlayerESP(p) end
game:GetService("Players").PlayerAdded:Connect(setupPlayerESP)

-- ─── DOOR ESP ───
local doorHighlights = {}
function applyDoorESP()
    for _, v in pairs(workspace:GetDescendants()) do
        if (v.Name == "DoubleDoor" or v.Name == "SingleDoor") and not doorHighlights[v] then
            local ex = v:FindFirstChildOfClass("Highlight")
            local h = ex or Instance.new("Highlight", v)
            h.Enabled = true; h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            h.FillColor = getEffectiveESPFill("espDoor")
            h.FillTransparency = espFT("espDoor")
            h.OutlineColor = getEffectiveESPOutline("espDoor")
            h.OutlineTransparency = espOT("espDoor")
            doorHighlights[v] = h
        end
    end
end
function clearDoorESP()
    for _, h in pairs(doorHighlights) do if h then h:Destroy() end end
    doorHighlights = {}
end
local function refreshDoorColors()
    for _, h in pairs(doorHighlights) do
        if h and h.Parent then
            h.FillColor = getEffectiveESPFill("espDoor")
            h.FillTransparency = espFT("espDoor")
            h.OutlineColor = getEffectiveESPOutline("espDoor")
            h.OutlineTransparency = espOT("espDoor")
        end
    end
end
registerESPRefresh(refreshDoorColors)
task.spawn(function()
    while true do
        if state.doorESP then
            for d, h in pairs(doorHighlights) do
                if not d or not d.Parent then if h then h:Destroy() end; doorHighlights[d] = nil end
            end
            applyDoorESP()
        end
        task.wait(0.75)
    end
end)

-- ─── EXIT ESP ───
local exitHighlights = {}
function applyExitESP()
    for _, v in pairs(workspace:GetDescendants()) do
        if v.Name == "ExitDoor" and not exitHighlights[v] then
            local ex = v:FindFirstChildOfClass("Highlight")
            local h = ex or Instance.new("Highlight", v)
            h.Enabled = true; h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            h.FillColor = getEffectiveESPFill("espExit")
            h.FillTransparency = espFT("espExit")
            h.OutlineColor = getEffectiveESPOutline("espExit")
            h.OutlineTransparency = espOT("espExit")
            exitHighlights[v] = h
        end
    end
end
function clearExitESP()
    for _, h in pairs(exitHighlights) do if h then h:Destroy() end end
    exitHighlights = {}
end
local function refreshExitColors()
    for _, h in pairs(exitHighlights) do
        if h and h.Parent then
            h.FillColor = getEffectiveESPFill("espExit")
            h.FillTransparency = espFT("espExit")
            h.OutlineColor = getEffectiveESPOutline("espExit")
            h.OutlineTransparency = espOT("espExit")
        end
    end
end
registerESPRefresh(refreshExitColors)
task.spawn(function()
    while true do
        if state.exitESP then
            for d, h in pairs(exitHighlights) do
                if not d or not d.Parent then if h then h:Destroy() end; exitHighlights[d] = nil end
            end
            applyExitESP()
        end
        task.wait(0.75)
    end
end)

-- ─── COMPUTER ESP ───
local computerHighlights = {}
local function getScreenColor(screen)
    if not screen then return getEffectiveESPFill("espComputer") end
    local c = screen.Color
    local r = math.floor(c.R * 255 + 0.5)
    local g = math.floor(c.G * 255 + 0.5)
    local function cl(a, b) return math.abs(a - b) <= 5 end
    if cl(r, 40)  and cl(g, 127) then return Color3.fromRGB(0, 150, 50)  end
    if cl(r, 196) and cl(g, 40)  then return Color3.fromRGB(255, 50, 50) end
    return getEffectiveESPFill("espComputer")
end
local function getBeastPlayer()
    for _, plr in pairs(game:GetService("Players"):GetPlayers()) do
        if isBeastPlayer(plr) then return plr end
    end
end
local function updateComputerESP()
    local beast = getBeastPlayer()
    local bp = beast and beast.Character and beast.Character.PrimaryPart
    local bestPc, maxD = nil, -1
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj.Name == "ComputerTable" then
            local screen = obj:FindFirstChild("Screen")
            if not computerHighlights[obj] then
                local h = Instance.new("Highlight", obj)
                h.Adornee = obj; h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                computerHighlights[obj] = h
            end
            local h = computerHighlights[obj]
            if h then
                h.FillTransparency = espFT("espComputer")
                h.OutlineTransparency = espOT("espComputer")
                local fillCol = theme.espComputer[9] and getEffectiveESPFill("espComputer") or getScreenColor(screen)
                local outCol  = theme.espComputer[10] and getEffectiveESPOutline("espComputer") or fillCol
                h.FillColor = fillCol
                h.OutlineColor = outCol
                local root = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
                if root and bp then
                    local d = (root.Position - bp.Position).Magnitude
                    if d > maxD then maxD = d; bestPc = obj end
                end
            end
        end
    end
    if bestPc and computerHighlights[bestPc] then
        computerHighlights[bestPc].OutlineColor = theme.espComputer[10]
            and getEffectiveESPOutline("espComputer")
            or Color3.fromRGB(200, 0, 255)
    end
end
function clearComputerESP()
    for _, h in pairs(computerHighlights) do if h then h:Destroy() end end
    computerHighlights = {}
end
local function refreshComputerColors()
    -- Chroma refresh for existing computer highlights only. The normal
    -- computer ESP scan creates/removes highlights on a slower loop, so this
    -- avoids doing workspace:GetDescendants() during every chroma tick.
    for obj, h in pairs(computerHighlights) do
        if h and h.Parent and obj and obj.Parent then
            local screen = obj:FindFirstChild("Screen")
            local fillCol = theme.espComputer[9] and getEffectiveESPFill("espComputer") or getScreenColor(screen)
            local outCol  = theme.espComputer[10] and getEffectiveESPOutline("espComputer") or fillCol
            h.FillColor = fillCol
            h.OutlineColor = outCol
            h.FillTransparency = espFT("espComputer")
            h.OutlineTransparency = espOT("espComputer")
        end
    end
end
registerESPRefresh(refreshComputerColors)
task.spawn(function()
    while true do
        if state.computerESP then updateComputerESP() end
        task.wait(0.25)
    end
end)

-- ─── FREEZE POD ESP ───
local freezeHighlights = {}
function applyFreezeESP()
    for _, v in pairs(workspace:GetDescendants()) do
        if v.Name == "FreezePod" and not freezeHighlights[v] then
            local ex = v:FindFirstChildOfClass("Highlight")
            local h = ex or Instance.new("Highlight", v)
            h.Enabled = true; h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            h.FillColor = getEffectiveESPFill("espFreeze")
            h.FillTransparency = espFT("espFreeze")
            h.OutlineColor = getEffectiveESPOutline("espFreeze")
            h.OutlineTransparency = espOT("espFreeze")
            freezeHighlights[v] = h
        end
    end
end
function clearFreezeESP()
    for _, h in pairs(freezeHighlights) do if h then h:Destroy() end end
    freezeHighlights = {}
end
local function refreshFreezeColors()
    for _, h in pairs(freezeHighlights) do
        if h and h.Parent then
            h.FillColor = getEffectiveESPFill("espFreeze")
            h.FillTransparency = espFT("espFreeze")
            h.OutlineColor = getEffectiveESPOutline("espFreeze")
            h.OutlineTransparency = espOT("espFreeze")
        end
    end
end
registerESPRefresh(refreshFreezeColors)
task.spawn(function()
    while true do
        if state.freezepodESP then
            for pod, h in pairs(freezeHighlights) do
                if not pod or not pod.Parent then
                    if h and h.Parent then h:Destroy() end
                    freezeHighlights[pod] = nil
                end
            end
            applyFreezeESP()
        end
        task.wait(0.75)
    end
end)

end  -- close ESP_MODULES section
-- =============================================
-- 📊 PROGRESS BAR  (pc_progress_esp v3)
-- =============================================
do  -- 🔒 PROGRESS_BAR section (scopes internal locals)

    local LP_pb       = Players.LocalPlayer
    local SPlayers_pb = Players

    local function getMap_pb()
        local ok, v = pcall(function()
            return workspace:FindFirstChild(tostring(game.ReplicatedStorage.CurrentMap.Value))
        end)
        return ok and v or nil
    end

    local COL_pb = {
        YOU    = Color3.fromRGB(110, 210, 255),
        TEAM   = Color3.fromRGB(150, 220, 255),
        IDLE   = Color3.fromRGB(255, 220, 80),
        DONE   = Color3.fromRGB(130, 255, 160),
        LOCKED = Color3.fromRGB(255, 120, 120),
        EMPTY  = Color3.fromRGB(160, 160, 175),
    }

    local computerProgressBBs  = {}
    local computerProgressLoop = nil
    local prevActionProgress   = {}

    local function getScreenState_pb(model)
        local screen = model:FindFirstChild("Screen", true)
        if not screen then return "none" end
        local color
        if screen:IsA("BasePart") then
            color = screen.Color
        elseif screen:IsA("Decal") or screen:IsA("Texture") then
            color = screen.Color3
        elseif screen:IsA("Frame") or screen:IsA("ImageLabel") or screen:IsA("TextLabel") then
            color = screen.BackgroundColor3
        else
            for _, child in ipairs(screen:GetChildren()) do
                if child:IsA("BasePart") then color = child.Color; break end
            end
        end
        if not color then return "none" end
        local h, s, v = Color3.toHSV(color)
        if s < 0.25 or v < 0.15 then return "none" end
        if (h >= 0 and h <= 0.083) or (h >= 0.917 and h <= 1) then return "red" end
        if h >= 0.25 and h <= 0.46 then return "green" end
        return "none"
    end

    local DOOR_NAMES   = { "SingleDoor", "DoubleDoor", "DoorTrigger", "Door" }
    local MAX_AP_DELTA = 0.15

    local function isTampered_pb(p, currentAP)
        local stats = p:FindFirstChild("TempPlayerStatsModule")
        if stats then
            local ragdoll = stats:FindFirstChild("Ragdoll")
            if ragdoll and ragdoll:IsA("BoolValue") and ragdoll.Value then return true end
            local captured = stats:FindFirstChild("Captured")
            if captured and captured:IsA("BoolValue") and captured.Value then return true end
        end
        local prev = prevActionProgress[p] or 0
        if (currentAP - prev) > MAX_AP_DELTA then return true end
        local char = p.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if root then
            local map = getMap_pb()
            if map then
                for _, obj in ipairs(map:GetDescendants()) do
                    for _, dname in ipairs(DOOR_NAMES) do
                        if obj.Name == dname and obj:IsA("BasePart") then
                            if (obj.Position - root.Position).Magnitude < 8 then return true end
                        end
                    end
                end
            end
        end
        return false
    end

    local function updateOurProgress_pb(entry)
        local pos = entry.adornee.Position
        for _, p in pairs(SPlayers_pb:GetPlayers()) do
            local char = p.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if not root then continue end
            if (root.Position - pos).Magnitude > 12 then continue end
            local stats = p:FindFirstChild("TempPlayerStatsModule")
            local ap    = stats and stats:FindFirstChild("ActionProgress")
            local val   = ap and math.clamp(ap.Value, 0, 1) or 0
            if val <= 0 then continue end
            if isTampered_pb(p, val) then prevActionProgress[p] = val; continue end
            local delta = val - (prevActionProgress[p] or val)
            if delta >= 0 then
                entry.ourProgress = math.min(1, (entry.ourProgress or 0) + delta)
                entry.ourProgress = math.max(entry.ourProgress, val)
            end
            prevActionProgress[p] = val
            return p
        end
        return nil
    end

    local function getDisplayProgress_pb(entry)
        local ss = getScreenState_pb(entry.model)
        if ss == "green" then return 1, COL_pb.DONE, "100%" end
        local activePlayer = updateOurProgress_pb(entry)
        local progress     = entry.ourProgress or 0
        if activePlayer then
            local col = (activePlayer == LP_pb) and COL_pb.YOU or COL_pb.TEAM
            if ss == "red" then col = COL_pb.LOCKED end
            return progress, col, nil
        end
        if progress > 0.005 then
            return progress, (ss == "red") and COL_pb.LOCKED or COL_pb.IDLE, nil
        end
        return 0, (ss == "red") and COL_pb.LOCKED or COL_pb.EMPTY, nil
    end

    local function clearESP_pb()
        for _, e in pairs(computerProgressBBs) do
            if e.bb and e.bb.Parent then e.bb:Destroy() end
        end
        computerProgressBBs = {}
        prevActionProgress  = {}
    end

    local function buildESP_pb()
        clearESP_pb()
        local map = getMap_pb()
        if not map then return end
        for _, child in ipairs(map:GetChildren()) do
            if child.Name ~= "ComputerTable" then continue end
            local adornee = child.PrimaryPart or child:FindFirstChildOfClass("BasePart")
            if not adornee then continue end

            local bb = Instance.new("BillboardGui")
            bb.Name                  = "ComputerProgressESP"
            bb.AlwaysOnTop           = true
            bb.Size                  = UDim2.new(0, 80, 0, 32)
            bb.StudsOffsetWorldSpace = Vector3.new(0, 4, 0)
            bb.Adornee               = adornee
            bb.Parent                = child

            local bg = Instance.new("Frame", bb)
            bg.Size                   = UDim2.new(1, 0, 1, 0)
            bg.BackgroundColor3       = Color3.fromRGB(0, 0, 0)
            bg.BackgroundTransparency = 0.45
            bg.BorderSizePixel        = 0
            Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 5)

            local lbl = Instance.new("TextLabel", bg)
            lbl.Name                   = "ProgressLabel"
            lbl.Size                   = UDim2.new(1, 0, 0.58, 0)
            lbl.BackgroundTransparency = 1
            lbl.TextColor3             = COL_pb.EMPTY
            lbl.TextScaled             = true
            lbl.Font                   = Enum.Font.GothamBold
            lbl.Text                   = "0%"

            local track = Instance.new("Frame", bg)
            track.Name             = "Track"
            track.Size             = UDim2.new(0.86, 0, 0.20, 0)
            track.Position         = UDim2.new(0.07, 0, 0.74, 0)
            track.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
            track.BorderSizePixel  = 0
            Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

            local fill = Instance.new("Frame", track)
            fill.Name             = "Fill"
            fill.Size             = UDim2.new(0, 0, 1, 0)
            fill.BackgroundColor3 = COL_pb.EMPTY
            fill.BorderSizePixel  = 0
            Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

            table.insert(computerProgressBBs, {
                bb          = bb,
                adornee     = adornee,
                model       = child,
                ourProgress = 0,
            })
        end
    end

    local function startLoop_pb()
        if computerProgressLoop then task.cancel(computerProgressLoop); computerProgressLoop = nil end
        computerProgressLoop = task.spawn(function()
            while state.progressbar do
                task.wait(0.1)
                pcall(function()
                    for _, entry in pairs(computerProgressBBs) do
                        if not entry.bb or not entry.bb.Parent then continue end
                        local bg    = entry.bb:FindFirstChildOfClass("Frame"); if not bg then continue end
                        local lbl   = bg:FindFirstChild("ProgressLabel")
                        local track = bg:FindFirstChild("Track")
                        local fill  = track and track:FindFirstChild("Fill")
                        local progress, barColor, textOverride = getDisplayProgress_pb(entry)
                        local display = textOverride or (math.floor(progress * 100) .. "%")
                        if lbl  then lbl.Text = display; lbl.TextColor3 = barColor end
                        if fill then fill.Size = UDim2.new(progress, 0, 1, 0); fill.BackgroundColor3 = barColor end
                    end
                end)
            end
            computerProgressLoop = nil
        end)
    end

    -- hooked by the existing visualsPage "Progress Bar" toggle via state.progressbar
    -- watch for state changes in a lightweight loop
    task.spawn(function()
        local last = false
        while true do
            task.wait(0.25)
            local cur = state.progressbar == true
            if cur == last then continue end
            last = cur
            if cur then
                buildESP_pb()
                startLoop_pb()
            else
                clearESP_pb()
                if computerProgressLoop then task.cancel(computerProgressLoop); computerProgressLoop = nil end
            end
        end
    end)

end  -- close PROGRESS_BAR section
-- =============================================
-- 🔊 SOUNDPACK
-- =============================================
do  -- 🔒 SOUNDPACK section (scopes internal locals)
local SOUND_IDS = {
    SoundTyping       = "rbxassetid://9164301052",
    ErrorSound        = "rbxassetid://132281440773764",
    SoundWindowsPopUp = "rbxassetid://131390520971848",
    SoundDoorOpen     = "rbxassetid://139882610901041",
    SoundDoorClose    = "rbxassetid://130044785338025",
    SoundExitDoorOpen = "rbxassetid://108325145779552",
    SoundExitsUnlock  = "rbxassetid://70757098054364",
    SoundHitWall      = "rbxassetid://9114865628",
    SoundHitPlayer    = "rbxassetid://105716529495378",
    SoundChaseMusic   = "rbxassetid://1845350706",
    SoundHeartbeat    = "rbxassetid://128058566511485",
}
local SOUND_TO_THEME = {
    SoundTyping       = "snd_Typing",
    ErrorSound        = "snd_Error",
    SoundWindowsPopUp = "snd_Popup",
    SoundDoorOpen     = "snd_DoorOpen",
    SoundDoorClose    = "snd_DoorClose",
    SoundExitDoorOpen = "snd_ExitOpen",
    SoundExitsUnlock  = "snd_Unlock",
    SoundHitWall      = "snd_HitWall",
    SoundHitPlayer    = "snd_HitPlayer",
    SoundChaseMusic   = "snd_Chase",
    SoundHeartbeat    = "snd_Heartbeat",
}
local originals = {}

local function applySound(sound)
    if not sound:IsA("Sound") then return end
    local custom   = SOUND_IDS[sound.Name]
    local themeKey = SOUND_TO_THEME[sound.Name]
    if not custom or not themeKey then return end
    if not originals[sound] then originals[sound] = sound.SoundId end
    sound.SoundId = (state.soundpack and theme[themeKey]) and custom or originals[sound]
end

function refreshSoundpack()
    for sound, original in pairs(originals) do
        if sound and sound.Parent then
            local custom   = SOUND_IDS[sound.Name]
            local themeKey = SOUND_TO_THEME[sound.Name]
            if custom and themeKey then
                sound.SoundId = (state.soundpack and theme[themeKey]) and custom or original
                if sound.Playing then sound:Stop(); sound:Play() end
            end
        end
    end
end

for _, v in pairs(workspace:GetDescendants()) do applySound(v) end
workspace.DescendantAdded:Connect(applySound)

end  -- close SOUNDPACK section
-- =============================================
-- 🎧 AUDIO PLAYER POP-OUT (LAZY LOADED / ISOLATED)
-- =============================================
-- Kept out of the main chunk as a loadstring source so the large pop-out UI
-- does not push this already-large ZyxLab file over Lua's 200-local/register limit.
_G.__ZyxAudioPlayerPopupSource = [====[
-- ZyxLab Audio Player Popup (lazy-loaded separate chunk, no boost/custom asset)
-- duplicate service local removed
local SoundService = game:GetService("SoundService")
-- duplicate service local removed
local UIS = game:GetService("UserInputService")
-- duplicate service local removed
local player = Players.LocalPlayer or game:GetService("Players").PlayerAdded:Wait()

local function getParent()
    local ok, hui = pcall(function() return gethui and gethui() end)
    if ok and hui then return hui end
    return player:WaitForChild("PlayerGui")
end

local parent = getParent()
local old = parent:FindFirstChild("ZyxLab_AudioPlayerPopup")
if old then
    old.Enabled = true
    local root = old:FindFirstChild("Root")
    local mini = old:FindFirstChild("MiniButton")
    if root then root.Visible = true end
    if mini then mini.Visible = false end
    return
end

local ACCENT = Color3.fromRGB(90, 60, 220)
local BG = Color3.fromRGB(11, 11, 16)
local PANEL = Color3.fromRGB(16, 15, 24)
local ROW = Color3.fromRGB(21, 20, 30)
local ROW2 = Color3.fromRGB(26, 24, 38)
local TEXT = Color3.fromRGB(235, 235, 245)
local SUB = Color3.fromRGB(150, 145, 175)
local RED = Color3.fromRGB(88, 30, 35)
local GREEN = Color3.fromRGB(28, 58, 36)

local gui = Instance.new("ScreenGui")
gui.Name = "ZyxLab_AudioPlayerPopup"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 3800
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = parent

local currentAudios = {}
local visibleAudios = {}
local customVolumes = {}
local originalVolumes = {}
local spamActive = false
local muteConn = nil
local filterMode = "All"

local function tween(obj, info, props)
    pcall(function() TweenService:Create(obj, info, props):Play() end)
end

local function rememberVolume(sound)
    if sound and originalVolumes[sound] == nil then
        originalVolumes[sound] = sound.Volume
    end
end

local function getVol(id)
    local v = tonumber(customVolumes[id])
    if v == nil then return 1 end
    return math.clamp(v, 0, 10)
end

local function applyVolume(sound, id)
    if not sound or not sound.Parent then return end
    rememberVolume(sound)
    pcall(function() sound.Volume = getVol(id) end)
end

local function restoreVolumes()
    for snd, vol in pairs(originalVolumes) do
        pcall(function()
            if snd and snd.Parent then snd.Volume = vol end
        end)
    end
    table.clear(originalVolumes)
end

local function categoryFor(id)
    id = tostring(id or ""):lower()
    if id:find("rbxasset://sounds", 1, true) then
        return "Roblox"
    end
    return "Game"
end

local function shortPath(obj)
    local ok, full = pcall(function() return obj:GetFullName() end)
    full = ok and full or tostring(obj.Name or "Sound")
    if #full > 70 then
        full = "…" .. full:sub(#full - 67)
    end
    return full
end

local function scanAudios()
    local groups = {}
    local function scan(root)
        if not root then return end
        for _, obj in ipairs(root:GetDescendants()) do
            if obj:IsA("Sound") then
                local id = obj.SoundId
                if id and id ~= "" then
                    local g = groups[id]
                    if not g then
                        g = {name = obj.Name, id = id, refs = {}, parents = {}, paths = {}, category = categoryFor(id)}
                        groups[id] = g
                    end
                    table.insert(g.refs, obj)
                    local pname = obj.Parent and obj.Parent.Name or "?"
                    local exists = false
                    for _, p in ipairs(g.parents) do
                        if p == pname then exists = true break end
                    end
                    if not exists then table.insert(g.parents, pname) end
                    if #g.paths < 4 then table.insert(g.paths, shortPath(obj)) end
                end
            end
        end
    end
    pcall(function() scan(workspace) end)
    pcall(function() scan(SoundService) end)
    pcall(function() scan(player.Character) end)
    local found = {}
    for _, info in pairs(groups) do table.insert(found, info) end
    table.sort(found, function(a, b) return tostring(a.name):lower() < tostring(b.name):lower() end)
    return found
end

local root = Instance.new("Frame")
root.Name = "Root"
root.Size = UDim2.fromOffset(500, 565)
root.Position = UDim2.new(0.5, -250, 0.5, -282)
root.BackgroundColor3 = BG
root.BorderSizePixel = 0
root.Active = true
root.Draggable = true
root.Parent = gui
Instance.new("UICorner", root).CornerRadius = UDim.new(0, 15)
local rootStroke = Instance.new("UIStroke", root)
rootStroke.Color = Color3.fromRGB(45, 42, 65)
rootStroke.Thickness = 1.2
rootStroke.Transparency = 0.15

local titleBar = Instance.new("Frame", root)
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0, 46)
titleBar.BackgroundColor3 = PANEL
titleBar.BorderSizePixel = 0
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 15)
local titleFix = Instance.new("Frame", titleBar)
titleFix.Size = UDim2.new(1, 0, 0.5, 0)
titleFix.Position = UDim2.new(0, 0, 0.5, 0)
titleFix.BackgroundColor3 = PANEL
titleFix.BorderSizePixel = 0

local titleIcon = Instance.new("TextLabel", titleBar)
titleIcon.Size = UDim2.new(0, 34, 1, 0)
titleIcon.Position = UDim2.new(0, 12, 0, 0)
titleIcon.BackgroundTransparency = 1
titleIcon.Text = "🎧"
titleIcon.Font = Enum.Font.GothamBold
titleIcon.TextSize = 18
titleIcon.TextColor3 = ACCENT

local title = Instance.new("TextLabel", titleBar)
title.Size = UDim2.new(1, -155, 1, 0)
title.Position = UDim2.new(0, 47, 0, 0)
title.BackgroundTransparency = 1
title.Text = "ZyxLab Audio Player"
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.TextColor3 = TEXT
title.TextXAlignment = Enum.TextXAlignment.Left

local statusPill = Instance.new("TextLabel", titleBar)
statusPill.Size = UDim2.fromOffset(92, 22)
statusPill.Position = UDim2.new(1, -164, 0.5, -11)
statusPill.BackgroundColor3 = Color3.fromRGB(25, 24, 35)
statusPill.BorderSizePixel = 0
statusPill.Text = "RFE: —"
statusPill.Font = Enum.Font.GothamMedium
statusPill.TextSize = 11
statusPill.TextColor3 = SUB
Instance.new("UICorner", statusPill).CornerRadius = UDim.new(1, 0)

local function headerButton(text, offset)
    local btn = Instance.new("TextButton", titleBar)
    btn.Size = UDim2.fromOffset(28, 28)
    btn.Position = UDim2.new(1, offset, 0.5, -14)
    btn.BackgroundColor3 = Color3.fromRGB(30, 29, 42)
    btn.BorderSizePixel = 0
    btn.Text = text
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.TextColor3 = TEXT
    btn.AutoButtonColor = false
    Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)
    return btn
end

local minimizeBtn = headerButton("—", -68)
local closeBtn = headerButton("X", -34)

local sep = Instance.new("Frame", root)
sep.Size = UDim2.new(1, -24, 0, 1)
sep.Position = UDim2.new(0, 12, 0, 46)
sep.BackgroundColor3 = Color3.fromRGB(38, 36, 54)
sep.BorderSizePixel = 0

local body = Instance.new("Frame", root)
body.Name = "Body"
body.Size = UDim2.new(1, 0, 1, -47)
body.Position = UDim2.new(0, 0, 0, 47)
body.BackgroundTransparency = 1
local pad = Instance.new("UIPadding", body)
pad.PaddingLeft = UDim.new(0, 14)
pad.PaddingRight = UDim.new(0, 14)
pad.PaddingTop = UDim.new(0, 10)
pad.PaddingBottom = UDim.new(0, 10)
local bodyLayout = Instance.new("UIListLayout", body)
bodyLayout.FillDirection = Enum.FillDirection.Vertical
bodyLayout.SortOrder = Enum.SortOrder.LayoutOrder
bodyLayout.Padding = UDim.new(0, 8)

local function makeRow(parent, order, height)
    local row = Instance.new("Frame", parent)
    row.LayoutOrder = order
    row.Size = UDim2.new(1, 0, 0, height or 36)
    row.BackgroundTransparency = 1
    row.BorderSizePixel = 0
    local layout = Instance.new("UIListLayout", row)
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 6)
    return row
end

local function makeBtn(parent, text, order, color)
    local btn = Instance.new("TextButton", parent)
    btn.LayoutOrder = order
    btn.Size = UDim2.new(0.25, -5, 1, 0)
    btn.BackgroundColor3 = color or ROW2
    btn.BorderSizePixel = 0
    btn.Text = text
    btn.Font = Enum.Font.GothamMedium
    btn.TextSize = 11
    btn.TextColor3 = TEXT
    btn.AutoButtonColor = false
    btn.TextWrapped = true
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    local s = Instance.new("UIStroke", btn)
    s.Color = Color3.fromRGB(55, 52, 75)
    s.Transparency = 0.42
    btn.MouseEnter:Connect(function() tween(btn, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(36, 34, 52)}) end)
    btn.MouseLeave:Connect(function() tween(btn, TweenInfo.new(0.12), {BackgroundColor3 = color or ROW2}) end)
    return btn
end

local quickRow = makeRow(body, 1, 35)
local btnPlayFiltered = makeBtn(quickRow, "▶ Play Filtered", 1, Color3.fromRGB(34, 28, 58))
local btnStopAll = makeBtn(quickRow, "■ Stop All", 2, RED)
local btnSpam = makeBtn(quickRow, "⚡ Spam", 3, Color3.fromRGB(45, 31, 16))
local btnStopSpam = makeBtn(quickRow, "✋ Stop Spam", 4, RED)

local secondRow = makeRow(body, 2, 35)
local btnMute = makeBtn(secondRow, "🔇 Mute", 1, Color3.fromRGB(24, 32, 42))
local btnUnmute = makeBtn(secondRow, "🔊 Unmute", 2, GREEN)
local btnReset = makeBtn(secondRow, "🔄 Reset Vol", 3, Color3.fromRGB(27, 29, 42))
local btnRefresh = makeBtn(secondRow, "🔁 Refresh", 4, Color3.fromRGB(34, 28, 58))

local spamRow = Instance.new("Frame", body)
spamRow.LayoutOrder = 3
spamRow.Size = UDim2.new(1, 0, 0, 32)
spamRow.BackgroundColor3 = PANEL
spamRow.BorderSizePixel = 0
Instance.new("UICorner", spamRow).CornerRadius = UDim.new(0, 8)
local spamLbl = Instance.new("TextLabel", spamRow)
spamLbl.Size = UDim2.new(0.54, 0, 1, 0)
spamLbl.BackgroundTransparency = 1
spamLbl.Text = "  Spam interval (seconds)"
spamLbl.Font = Enum.Font.GothamMedium
spamLbl.TextSize = 12
spamLbl.TextColor3 = SUB
spamLbl.TextXAlignment = Enum.TextXAlignment.Left
local spamInput = Instance.new("TextBox", spamRow)
spamInput.Size = UDim2.new(0.46, -10, 0.74, 0)
spamInput.Position = UDim2.new(0.54, 0, 0.13, 0)
spamInput.BackgroundColor3 = Color3.fromRGB(25, 24, 35)
spamInput.BorderSizePixel = 0
spamInput.Text = "0.5"
spamInput.Font = Enum.Font.GothamMedium
spamInput.TextSize = 12
spamInput.TextColor3 = TEXT
spamInput.ClearTextOnFocus = false
Instance.new("UICorner", spamInput).CornerRadius = UDim.new(0, 7)

local searchRow = makeRow(body, 4, 36)
local searchBox = Instance.new("TextBox", searchRow)
searchBox.LayoutOrder = 1
searchBox.Size = UDim2.new(0.52, -4, 1, 0)
searchBox.BackgroundColor3 = PANEL
searchBox.BorderSizePixel = 0
searchBox.PlaceholderText = "🔎 Search name, ID, parent..."
searchBox.Text = ""
searchBox.Font = Enum.Font.GothamMedium
searchBox.TextSize = 12
searchBox.TextColor3 = TEXT
searchBox.PlaceholderColor3 = Color3.fromRGB(105, 105, 130)
searchBox.ClearTextOnFocus = false
Instance.new("UICorner", searchBox).CornerRadius = UDim.new(0, 8)
local filterAllBtn = makeBtn(searchRow, "🌐 All", 2, Color3.fromRGB(34, 28, 58)); filterAllBtn.Size = UDim2.new(0.16, -4, 1, 0)
local filterGameBtn = makeBtn(searchRow, "🎮 Game", 3, Color3.fromRGB(22, 30, 24)); filterGameBtn.Size = UDim2.new(0.16, -4, 1, 0)
local filterRobloxBtn = makeBtn(searchRow, "🧱 Roblox", 4, Color3.fromRGB(25, 26, 38)); filterRobloxBtn.Size = UDim2.new(0.16, -4, 1, 0)

local listHeader = Instance.new("Frame", body)
listHeader.LayoutOrder = 5
listHeader.Size = UDim2.new(1, 0, 0, 24)
listHeader.BackgroundTransparency = 1
local listTitle = Instance.new("TextLabel", listHeader)
listTitle.Size = UDim2.new(0.55, 0, 1, 0)
listTitle.BackgroundTransparency = 1
listTitle.Text = "AVAILABLE SOUNDS"
listTitle.Font = Enum.Font.GothamBold
listTitle.TextSize = 10
listTitle.TextColor3 = Color3.fromRGB(105, 100, 135)
listTitle.TextXAlignment = Enum.TextXAlignment.Left
local countLbl = Instance.new("TextLabel", listHeader)
countLbl.Size = UDim2.new(0.45, 0, 1, 0)
countLbl.Position = UDim2.new(0.55, 0, 0, 0)
countLbl.BackgroundTransparency = 1
countLbl.Text = "0 found"
countLbl.Font = Enum.Font.GothamMedium
countLbl.TextSize = 10
countLbl.TextColor3 = Color3.fromRGB(95, 90, 120)
countLbl.TextXAlignment = Enum.TextXAlignment.Right

local listScroll = Instance.new("ScrollingFrame", body)
listScroll.LayoutOrder = 6
listScroll.Size = UDim2.new(1, 0, 0, 265)
listScroll.BackgroundColor3 = Color3.fromRGB(13, 12, 19)
listScroll.BorderSizePixel = 0
listScroll.ScrollBarThickness = 4
listScroll.ScrollBarImageColor3 = ACCENT
listScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
listScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
Instance.new("UICorner", listScroll).CornerRadius = UDim.new(0, 10)
local listLayout = Instance.new("UIListLayout", listScroll)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 5)
local listPad = Instance.new("UIPadding", listScroll)
listPad.PaddingLeft = UDim.new(0, 6)
listPad.PaddingRight = UDim.new(0, 6)
listPad.PaddingTop = UDim.new(0, 6)
listPad.PaddingBottom = UDim.new(0, 6)

local nowBar = Instance.new("Frame", body)
nowBar.LayoutOrder = 7
nowBar.Size = UDim2.new(1, 0, 0, 30)
nowBar.BackgroundColor3 = PANEL
nowBar.BorderSizePixel = 0
Instance.new("UICorner", nowBar).CornerRadius = UDim.new(0, 8)
local nowLabel = Instance.new("TextLabel", nowBar)
nowLabel.Size = UDim2.new(1, -14, 1, 0)
nowLabel.Position = UDim2.new(0, 10, 0, 0)
nowLabel.BackgroundTransparency = 1
nowLabel.Text = "🎵 Nothing playing"
nowLabel.Font = Enum.Font.GothamMedium
nowLabel.TextSize = 11
nowLabel.TextColor3 = Color3.fromRGB(150, 140, 190)
nowLabel.TextXAlignment = Enum.TextXAlignment.Left
nowLabel.TextTruncate = Enum.TextTruncate.AtEnd

local mini = Instance.new("TextButton", gui)
mini.Name = "MiniButton"
mini.Size = UDim2.fromOffset(146, 38)
mini.Position = UDim2.new(1, -165, 0.62, 0)
mini.BackgroundColor3 = PANEL
mini.BorderSizePixel = 0
mini.Text = "🎧 Audio Player"
mini.Font = Enum.Font.GothamBold
mini.TextSize = 12
mini.TextColor3 = TEXT
mini.Visible = false
mini.Active = true
mini.Draggable = true
mini.AutoButtonColor = false
Instance.new("UICorner", mini).CornerRadius = UDim.new(1, 0)
local miniStroke = Instance.new("UIStroke", mini)
miniStroke.Color = ACCENT
miniStroke.Transparency = 0.1

local function setNow(text)
    nowLabel.Text = "🎵 " .. tostring(text or "Nothing playing")
end

local function updateFilterButtons()
    filterAllBtn.BackgroundColor3 = filterMode == "All" and Color3.fromRGB(72, 52, 138) or Color3.fromRGB(34, 28, 58)
    filterGameBtn.BackgroundColor3 = filterMode == "Game" and Color3.fromRGB(45, 82, 54) or Color3.fromRGB(22, 30, 24)
    filterRobloxBtn.BackgroundColor3 = filterMode == "Roblox" and Color3.fromRGB(55, 58, 85) or Color3.fromRGB(25, 26, 38)
end

local function matches(info)
    if filterMode ~= "All" and info.category ~= filterMode then return false end
    local q = tostring(searchBox.Text or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
    if q == "" then return true end
    local hay = (tostring(info.name) .. " " .. tostring(info.id) .. " " .. table.concat(info.parents, " ") .. " " .. table.concat(info.paths, " ")):lower()
    return hay:find(q, 1, true) ~= nil
end

local function stopGroup(info)
    for _, snd in ipairs(info.refs) do
        pcall(function() if snd and snd.Parent then snd:Stop() end end)
    end
end

local function playGroup(info)
    local played = 0
    for _, snd in ipairs(info.refs) do
        pcall(function()
            if snd and snd.Parent then
                applyVolume(snd, info.id)
                snd:Play()
                played = played + 1
            end
        end)
    end
    setNow(info.name .. " (" .. played .. " instances)")
end

local function applyVolumeToGroup(info)
    for _, snd in ipairs(info.refs) do
        pcall(function() applyVolume(snd, info.id) end)
    end
end

local function makeSlider(parent, info, valueLabel)
    local wrap = Instance.new("Frame", parent)
    wrap.Size = UDim2.new(1, -12, 0, 16)
    wrap.Position = UDim2.new(0, 6, 1, -20)
    wrap.BackgroundTransparency = 1
    local back = Instance.new("Frame", wrap)
    back.Size = UDim2.new(1, -58, 0, 5)
    back.Position = UDim2.new(0, 0, 0.5, -2)
    back.BackgroundColor3 = Color3.fromRGB(40, 37, 55)
    back.BorderSizePixel = 0
    Instance.new("UICorner", back).CornerRadius = UDim.new(1, 0)
    local fill = Instance.new("Frame", back)
    fill.Size = UDim2.new(math.clamp(getVol(info.id) / 10, 0, 1), 0, 1, 0)
    fill.BackgroundColor3 = ACCENT
    fill.BorderSizePixel = 0
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
    local dragging = false
    local function setFromX(x)
        local pct = math.clamp((x - back.AbsolutePosition.X) / math.max(back.AbsoluteSize.X, 1), 0, 1)
        local value = math.floor((pct * 10) * 10 + 0.5) / 10
        customVolumes[info.id] = value
        fill.Size = UDim2.new(value / 10, 0, 1, 0)
        valueLabel.Text = string.format("%.1fx", value)
        applyVolumeToGroup(info)
    end
    back.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            setFromX(input.Position.X)
        end
    end)
    UIS.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            setFromX(input.Position.X)
        end
    end)
    UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

local function buildRow(info, order)
    local row = Instance.new("Frame", listScroll)
    row.LayoutOrder = order
    row.Size = UDim2.new(1, 0, 0, 66)
    row.BackgroundColor3 = ROW
    row.BorderSizePixel = 0
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)
    local name = Instance.new("TextLabel", row)
    name.Size = UDim2.new(1, -158, 0, 20)
    name.Position = UDim2.new(0, 8, 0, 4)
    name.BackgroundTransparency = 1
    name.Text = tostring(info.name)
    name.Font = Enum.Font.GothamMedium
    name.TextSize = 12
    name.TextColor3 = TEXT
    name.TextXAlignment = Enum.TextXAlignment.Left
    name.TextTruncate = Enum.TextTruncate.AtEnd
    local sub = Instance.new("TextLabel", row)
    sub.Size = UDim2.new(1, -158, 0, 16)
    sub.Position = UDim2.new(0, 8, 0, 23)
    sub.BackgroundTransparency = 1
    local parentSummary = table.concat(info.parents, ", ")
    if #parentSummary > 48 then parentSummary = parentSummary:sub(1, 45) .. "…" end
    sub.Text = tostring(info.category) .. " • ×" .. tostring(#info.refs) .. " • " .. parentSummary
    sub.Font = Enum.Font.Gotham
    sub.TextSize = 10
    sub.TextColor3 = SUB
    sub.TextXAlignment = Enum.TextXAlignment.Left
    sub.TextTruncate = Enum.TextTruncate.AtEnd
    local value = Instance.new("TextLabel", row)
    value.Size = UDim2.fromOffset(46, 18)
    value.Position = UDim2.new(1, -150, 0, 6)
    value.BackgroundColor3 = Color3.fromRGB(31, 29, 45)
    value.BorderSizePixel = 0
    value.Text = string.format("%.1fx", getVol(info.id))
    value.Font = Enum.Font.GothamBold
    value.TextSize = 10
    value.TextColor3 = TEXT
    Instance.new("UICorner", value).CornerRadius = UDim.new(1, 0)
    local play = Instance.new("TextButton", row)
    play.Size = UDim2.fromOffset(48, 26)
    play.Position = UDim2.new(1, -96, 0, 6)
    play.BackgroundColor3 = ACCENT
    play.BorderSizePixel = 0
    play.Text = "▶"
    play.Font = Enum.Font.GothamBold
    play.TextSize = 12
    play.TextColor3 = Color3.new(1, 1, 1)
    Instance.new("UICorner", play).CornerRadius = UDim.new(0, 7)
    local stop = Instance.new("TextButton", row)
    stop.Size = UDim2.fromOffset(34, 26)
    stop.Position = UDim2.new(1, -40, 0, 6)
    stop.BackgroundColor3 = RED
    stop.BorderSizePixel = 0
    stop.Text = "■"
    stop.Font = Enum.Font.GothamBold
    stop.TextSize = 11
    stop.TextColor3 = Color3.fromRGB(255, 170, 175)
    Instance.new("UICorner", stop).CornerRadius = UDim.new(0, 7)
    makeSlider(row, info, value)
    play.MouseButton1Click:Connect(function() playGroup(info) end)
    stop.MouseButton1Click:Connect(function() stopGroup(info); setNow("Stopped " .. info.name) end)
end

local function refreshList(rescan)
    for _, child in ipairs(listScroll:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end
    if rescan then currentAudios = scanAudios() end
    visibleAudios = {}
    for _, info in ipairs(currentAudios) do
        if matches(info) then table.insert(visibleAudios, info) end
    end
    countLbl.Text = tostring(#visibleAudios) .. " shown / " .. tostring(#currentAudios) .. " total"
    if #visibleAudios == 0 then
        local empty = Instance.new("TextLabel", listScroll)
        empty.Size = UDim2.new(1, 0, 0, 44)
        empty.BackgroundTransparency = 1
        empty.Text = "No sounds match this search/filter"
        empty.Font = Enum.Font.GothamMedium
        empty.TextSize = 12
        empty.TextColor3 = SUB
    else
        for i, info in ipairs(visibleAudios) do buildRow(info, i) end
    end
    updateFilterButtons()
end

btnRefresh.MouseButton1Click:Connect(function()
    setNow("Refreshing audio list...")
    refreshList(true)
end)

btnPlayFiltered.MouseButton1Click:Connect(function()
    local total = 0
    for _, info in ipairs(visibleAudios) do
        for _, snd in ipairs(info.refs) do
            pcall(function()
                if snd and snd.Parent then applyVolume(snd, info.id); snd:Play(); total = total + 1 end
            end)
        end
    end
    setNow("Playing filtered — " .. tostring(total) .. " instances")
end)

btnStopAll.MouseButton1Click:Connect(function()
    spamActive = false
    for _, info in ipairs(currentAudios) do stopGroup(info) end
    setNow("Stopped scanned audio")
end)

btnSpam.MouseButton1Click:Connect(function()
    if spamActive then return end
    spamActive = true
    btnSpam.TextColor3 = Color3.fromRGB(255, 210, 95)
    task.spawn(function()
        while spamActive do
            local delay = tonumber(spamInput.Text) or 0.5
            delay = math.max(delay, 0.05)
            for _, info in ipairs(visibleAudios) do
                if not spamActive then break end
                for _, snd in ipairs(info.refs) do
                    pcall(function()
                        if snd and snd.Parent then applyVolume(snd, info.id); snd:Play() end
                    end)
                end
            end
            task.wait(delay)
        end
    end)
    setNow("Spamming filtered audio")
end)

btnStopSpam.MouseButton1Click:Connect(function()
    spamActive = false
    btnSpam.TextColor3 = TEXT
    setNow("Spam stopped")
end)

btnMute.MouseButton1Click:Connect(function()
    if muteConn then return end
    muteConn = RunService.Heartbeat:Connect(function()
        pcall(function()
            for _, info in ipairs(currentAudios) do
                for _, snd in ipairs(info.refs) do
                    pcall(function()
                        if snd and snd.Parent then rememberVolume(snd); snd.Volume = 0 end
                    end)
                end
            end
        end)
    end)
    setNow("Muted scanned audio")
end)

btnUnmute.MouseButton1Click:Connect(function()
    if muteConn then muteConn:Disconnect(); muteConn = nil end
    restoreVolumes()
    refreshList(false)
    setNow("Unmuted/restored volumes")
end)

btnReset.MouseButton1Click:Connect(function()
    if muteConn then muteConn:Disconnect(); muteConn = nil end
    customVolumes = {}
    restoreVolumes()
    refreshList(false)
    setNow("Volume controls reset")
end)

searchBox:GetPropertyChangedSignal("Text"):Connect(function() refreshList(false) end)
filterAllBtn.MouseButton1Click:Connect(function() filterMode = "All"; refreshList(false) end)
filterGameBtn.MouseButton1Click:Connect(function() filterMode = "Game"; refreshList(false) end)
filterRobloxBtn.MouseButton1Click:Connect(function() filterMode = "Roblox"; refreshList(false) end)

minimizeBtn.MouseButton1Click:Connect(function()
    root.Visible = false
    mini.Visible = true
end)
mini.MouseButton1Click:Connect(function()
    root.Visible = true
    mini.Visible = false
end)
closeBtn.MouseButton1Click:Connect(function()
    root.Visible = false
    mini.Visible = false
end)

task.spawn(function()
    while gui.Parent do
        task.wait(0.6)
        pcall(function()
            if SoundService.RespectFilteringEnabled then
                statusPill.Text = "RFE: ON"
                statusPill.TextColor3 = Color3.fromRGB(255, 110, 110)
                statusPill.BackgroundColor3 = Color3.fromRGB(48, 20, 24)
            else
                statusPill.Text = "RFE: OFF"
                statusPill.TextColor3 = Color3.fromRGB(110, 235, 145)
                statusPill.BackgroundColor3 = Color3.fromRGB(20, 42, 27)
            end
        end)
    end
end)

currentAudios = scanAudios()
refreshList(false)
setNow("Loaded " .. tostring(#currentAudios) .. " audio groups")

]====]

_G.__ZyxOpenAudioPlayer = function()
    local ok, err = xpcall(function()
        if type(_G.__ZyxAudioPlayerPopupSource) ~= "string" then
            error("Audio Player source is missing")
        end
        local fn, loadErr = loadstring(_G.__ZyxAudioPlayerPopupSource)
        if not fn then error(loadErr or "loadstring failed") end
        fn()
    end, function(e)
        return tostring(e)
    end)
    if not ok then
        pcall(function() showErrorOnScreen("Audio Player failed: " .. tostring(err)) end)
        warn("[ZyxLab Audio Player]", err)
    end
end


-- =============================================
-- 🏃 MOVEMENT MODULE (LAZY LOADED / LOGIC ONLY)
-- =============================================
-- Logic from mergethese.lua, with the standalone UI removed.  It is kept as a
-- lazy loadstring chunk so this large ZyxLab file does not hit Lua's 200-local limit.
_G.__ZyxMovementModuleSource = [====[
return function()
    local Players = game:GetService("Players")
    local UserInputService = game:GetService("UserInputService")
    local Workspace = game:GetService("Workspace")
    local RunService = game:GetService("RunService")

    local player = Players.LocalPlayer or Players.PlayerAdded:Wait()
    local camera = Workspace.CurrentCamera

    local walkspeeddefault = 16
    local walkspeedduringcrawldefault = 8

    local character, humanoid, root
    local defaults = {
        JumpValue = 50,
        Gravity = Workspace.Gravity,
        FlySpeed = 60,
        OrbitRadius = 10,
        OrbitHeight = 3,
        OrbitSpeed = 2,
    }

    local settings = {
        WalkSpeedEnabled = false,
        CrawlSpeedEnabled = false,
        JumpEnabled = false,
        GravityEnabled = false,
        FlyEnabled = false,
        NoclipEnabled = false,
        InfiniteJumpEnabled = false,
        WallHopEnabled = false,
        OrbitEnabled = false,

        WalkSpeed = walkspeeddefault,
        CrawlSpeed = walkspeedduringcrawldefault,
        JumpValue = 50,
        Gravity = Workspace.Gravity,
        FlySpeed = 60,
        WallHopJumpDelay = 0.30,
        WallHopFlickIntensity = 0.03,
        WallHopReady = true,

        OrbitTarget = nil,
        OrbitRadius = 10,
        OrbitHeight = 3,
        OrbitSpeed = 2,
    }

    local keys = {}
    local savedCollision = {}
    local orbitAngle = 0
    local flyVelocity, flyGyro
    local controls
    local function getControls()
        if controls then return controls end
        local ok, result = pcall(function()
            return require(player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule")):GetControls()
        end)
        if ok then controls = result end
        return controls
    end

    local function getJumpValue()
        if not humanoid then return 50 end
        if humanoid.UseJumpPower then return humanoid.JumpPower end
        return humanoid.JumpHeight
    end

    local function setJumpValue(value)
        if not humanoid then return end
        if humanoid.UseJumpPower then
            humanoid.JumpPower = value
        else
            humanoid.JumpHeight = value
        end
    end

    local function refreshCharacter()
        character = player.Character or player.CharacterAdded:Wait()
        humanoid = character:WaitForChild("Humanoid")
        root = character:WaitForChild("HumanoidRootPart")
        task.wait(0.35)
        defaults.JumpValue = getJumpValue()
        defaults.Gravity = Workspace.Gravity
        settings.JumpValue = defaults.JumpValue
        settings.Gravity = defaults.Gravity
    end

    local function getIsCrawling()
        local stats = player:FindFirstChild("TempPlayerStatsModule")
        if not stats then return false end
        local flag = stats:FindFirstChild("IsCrawling")
        if not flag then return false end
        local ok, value = pcall(function() return flag.Value end)
        return ok and typeof(value) == "boolean" and value or false
    end

    local function applyCorrectSpeed()
        if not humanoid then return end
        if getIsCrawling() then
            if settings.CrawlSpeedEnabled then humanoid.WalkSpeed = settings.CrawlSpeed end
        else
            if settings.WalkSpeedEnabled then humanoid.WalkSpeed = settings.WalkSpeed end
        end
    end

    local function findPlayerByPartialName(text)
        text = string.lower(text or "")
        if text == "" then return nil end
        for _, target in ipairs(game:GetService("Players"):GetPlayers()) do
            if target ~= player then
                local name = string.lower(target.Name)
                local display = string.lower(target.DisplayName)
                if string.find(name, text, 1, true) or string.find(display, text, 1, true) then
                    return target
                end
            end
        end
        return nil
    end

    local function stopFly()
        if humanoid then
            humanoid.PlatformStand = false
            humanoid.AutoRotate = true
        end
        if flyVelocity then flyVelocity:Destroy() end
        if flyGyro then flyGyro:Destroy() end
        flyVelocity = nil
        flyGyro = nil
    end

    local function startFly()
        stopFly()
        if not root or not humanoid then return end
        root.Anchored = false
        humanoid.PlatformStand = true
        humanoid.AutoRotate = false

        flyVelocity = Instance.new("BodyVelocity")
        flyVelocity.Name = "ZyxLabMovementFlyVelocity"
        flyVelocity.MaxForce = Vector3.new(1e9, 1e9, 1e9)
        flyVelocity.P = 12500
        flyVelocity.Velocity = Vector3.zero
        flyVelocity.Parent = root

        flyGyro = Instance.new("BodyGyro")
        flyGyro.Name = "ZyxLabMovementFlyGyro"
        flyGyro.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
        flyGyro.P = 12500
        flyGyro.D = 500
        flyGyro.CFrame = camera.CFrame
        flyGyro.Parent = root
    end

    local function enableNoclip()
        if not character then return end
        for _, obj in ipairs(character:GetDescendants()) do
            if obj:IsA("BasePart") then
                if savedCollision[obj] == nil then savedCollision[obj] = obj.CanCollide end
                obj.CanCollide = false
            end
        end
    end

    local function disableNoclip()
        for part, oldValue in pairs(savedCollision) do
            if part and part.Parent then part.CanCollide = oldValue end
        end
        savedCollision = {}
    end

    local function getWallRaycastResult()
        if not character or not root then return nil end
        wallhopRaycastParams.FilterDescendantsInstances = { character }

        local directions = {
            root.CFrame.LookVector,
            -root.CFrame.LookVector,
            root.CFrame.RightVector,
            -root.CFrame.RightVector,
        }

        for _, dir in ipairs(directions) do
            local ray = Workspace:Raycast(root.Position, dir * 2, wallhopRaycastParams)
            if ray then return ray end
        end

        return nil
    end

    local function executeWallHop(wallRayResult)
        if not settings.WallHopEnabled or not settings.WallHopReady then return end
        if not wallRayResult or not humanoid or not root then return end
        if humanoid:GetState() == Enum.HumanoidStateType.Dead then return end

        settings.WallHopReady = false

        local vel = root.AssemblyLinearVelocity
        root.AssemblyLinearVelocity = Vector3.new(0, vel.Y, 0)

        local original = root.CFrame
        local direction = (math.random(1, 2) == 1) and -90 or 90

        root.CFrame = root.CFrame * CFrame.Angles(0, math.rad(direction), 0)
        task.wait(settings.WallHopFlickIntensity)

        if root and root.Parent then
            root.CFrame = original
        end
        if humanoid and humanoid.Parent then
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end

        task.wait(settings.WallHopJumpDelay)
        settings.WallHopReady = true
    end

    refreshCharacter()

    player.CharacterAdded:Connect(function()
        task.wait(0.25)
        refreshCharacter()
        savedCollision = {}
        if settings.FlyEnabled then startFly() end
    end)

    UserInputService.InputBegan:Connect(function(input, processed)
        if processed or not input.UserInputType == Enum.UserInputType.Keyboard then return end
        keys[input.KeyCode] = true
    end)

    UserInputService.InputEnded:Connect(function(input)
        if not input.UserInputType == Enum.UserInputType.Keyboard then return end
        keys[input.KeyCode] = false
    end)

    UserInputService.JumpRequest:Connect(function()
        if settings.WallHopEnabled and humanoid and root and humanoid.FloorMaterial == Enum.Material.Air then
            local wallRayResult = getWallRaycastResult()
            if wallRayResult then
                task.spawn(executeWallHop, wallRayResult)
                return
            end
        end

        if settings.InfiniteJumpEnabled and humanoid then
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end)

    RunService.Heartbeat:Connect(function()
        pcall(function()
            if humanoid then
                applyCorrectSpeed()
                if settings.JumpEnabled then setJumpValue(settings.JumpValue) end
            end
            if settings.GravityEnabled then Workspace.Gravity = settings.Gravity end
            if settings.NoclipEnabled then enableNoclip() end
        end)
    end)

    RunService.RenderStepped:Connect(function(dt)
        pcall(function()
            camera = Workspace.CurrentCamera

            if settings.FlyEnabled then
                if not flyVelocity or not flyVelocity.Parent then startFly() end
                if root and flyVelocity and flyGyro and camera then
                    local move = Vector3.zero
                    local ctrl = getControls()
                    if ctrl then
                        local moveVector = ctrl:GetMoveVector()
                        move += camera.CFrame.RightVector * moveVector.X
                        move += camera.CFrame.LookVector * -moveVector.Z
                    end
                    if keys[Enum.KeyCode.W] then move += camera.CFrame.LookVector end
                    if keys[Enum.KeyCode.S] then move -= camera.CFrame.LookVector end
                    if keys[Enum.KeyCode.A] then move -= camera.CFrame.RightVector end
                    if keys[Enum.KeyCode.D] then move += camera.CFrame.RightVector end
                    if move.Magnitude > 0 then move = move.Unit end
                    flyVelocity.Velocity = move * settings.FlySpeed
                    flyGyro.CFrame = camera.CFrame
                end
            end

            if settings.OrbitEnabled and root and settings.OrbitTarget then
                local targetCharacter = settings.OrbitTarget.Character
                local targetRoot = targetCharacter and targetCharacter:FindFirstChild("HumanoidRootPart")
                if targetRoot then
                    orbitAngle += dt * settings.OrbitSpeed
                    local offset = Vector3.new(
                        math.cos(orbitAngle) * settings.OrbitRadius,
                        settings.OrbitHeight,
                        math.sin(orbitAngle) * settings.OrbitRadius
                    )
                    local orbitPosition = targetRoot.Position + offset
                    root.AssemblyLinearVelocity = Vector3.zero
                    root.CFrame = CFrame.lookAt(orbitPosition, targetRoot.Position)
                end
            end
        end)
    end)

    local API = {}

    function API.setWalkSpeedEnabled(value)
        settings.WalkSpeedEnabled = value == true
        applyCorrectSpeed()
    end
    function API.setWalkSpeed(value)
        settings.WalkSpeed = math.clamp(tonumber(value) or settings.WalkSpeed, 1, 500)
        applyCorrectSpeed()
    end
    function API.setCrawlSpeedEnabled(value)
        settings.CrawlSpeedEnabled = value == true
        applyCorrectSpeed()
    end
    function API.setCrawlSpeed(value)
        settings.CrawlSpeed = math.clamp(tonumber(value) or settings.CrawlSpeed, 1, 100)
        applyCorrectSpeed()
    end
    function API.setJumpEnabled(value)
        settings.JumpEnabled = value == true
        if not settings.JumpEnabled then setJumpValue(defaults.JumpValue) end
    end
    function API.setJumpValue(value)
        settings.JumpValue = math.clamp(tonumber(value) or settings.JumpValue, 1, 1000)
        if settings.JumpEnabled then setJumpValue(settings.JumpValue) end
    end
    function API.setGravityEnabled(value)
        settings.GravityEnabled = value == true
        if not settings.GravityEnabled then Workspace.Gravity = defaults.Gravity end
    end
    function API.setGravity(value)
        settings.Gravity = math.clamp(tonumber(value) or settings.Gravity, 0, 500)
        if settings.GravityEnabled then Workspace.Gravity = settings.Gravity end
    end
    function API.setFlyEnabled(value)
        settings.FlyEnabled = value == true
        if settings.FlyEnabled then startFly() else stopFly() end
    end
    function API.setFlySpeed(value)
        settings.FlySpeed = math.clamp(tonumber(value) or settings.FlySpeed, 5, 300)
    end
    function API.setNoclipEnabled(value)
        settings.NoclipEnabled = value == true
        if not settings.NoclipEnabled then disableNoclip() end
    end
    function API.setInfiniteJumpEnabled(value)
        settings.InfiniteJumpEnabled = value == true
    end
    function API.setWallHopEnabled(value)
        settings.WallHopEnabled = value == true
        if not settings.WallHopEnabled then settings.WallHopReady = true end
    end
    function API.setWallHopJumpDelay(value)
        settings.WallHopJumpDelay = math.clamp(tonumber(value) or settings.WallHopJumpDelay, 0.01, 1)
    end
    function API.setWallHopFlickIntensity(value)
        settings.WallHopFlickIntensity = math.clamp(tonumber(value) or settings.WallHopFlickIntensity, 0.001, 1)
    end
    function API.setOrbitTarget(text)
        settings.OrbitTarget = findPlayerByPartialName(text)
        return settings.OrbitTarget and settings.OrbitTarget.Name or nil
    end
    function API.setOrbitEnabled(value)
        settings.OrbitEnabled = value == true
    end
    function API.setOrbitRadius(value)
        settings.OrbitRadius = math.clamp(tonumber(value) or settings.OrbitRadius, 2, 80)
    end
    function API.setOrbitHeight(value)
        settings.OrbitHeight = math.clamp(tonumber(value) or settings.OrbitHeight, -25, 80)
    end
    function API.setOrbitSpeed(value)
        settings.OrbitSpeed = math.clamp(tonumber(value) or settings.OrbitSpeed, 0, 20)
    end
    function API.reset()
        settings.WalkSpeedEnabled = false
        settings.CrawlSpeedEnabled = false
        settings.JumpEnabled = false
        settings.GravityEnabled = false
        settings.FlyEnabled = false
        settings.NoclipEnabled = false
        settings.InfiniteJumpEnabled = false
        settings.WallHopEnabled = false
        settings.OrbitEnabled = false
        settings.WallHopReady = true
        settings.WallHopJumpDelay = 0.30
        settings.WallHopFlickIntensity = 0.03
        settings.WalkSpeed = walkspeeddefault
        settings.CrawlSpeed = walkspeedduringcrawldefault
        settings.JumpValue = defaults.JumpValue
        settings.Gravity = defaults.Gravity
        settings.FlySpeed = defaults.FlySpeed
        settings.OrbitTarget = nil
        settings.OrbitRadius = defaults.OrbitRadius
        settings.OrbitHeight = defaults.OrbitHeight
        settings.OrbitSpeed = defaults.OrbitSpeed
        if humanoid then
            humanoid.WalkSpeed = walkspeeddefault
            setJumpValue(defaults.JumpValue)
            humanoid.PlatformStand = false
            humanoid.AutoRotate = true
        end
        Workspace.Gravity = defaults.Gravity
        stopFly()
        disableNoclip()
    end

    function API.getDefaults()
        return {
            WalkSpeed = walkspeeddefault,
            CrawlSpeed = walkspeedduringcrawldefault,
            JumpValue = defaults.JumpValue,
            Gravity = defaults.Gravity,
            FlySpeed = defaults.FlySpeed,
            OrbitRadius = defaults.OrbitRadius,
            OrbitHeight = defaults.OrbitHeight,
            OrbitSpeed = defaults.OrbitSpeed,
        }
    end

    return API
end
]====]

_G.__ZyxGetMovementController = function()
    if _G.__ZyxMovementController then return _G.__ZyxMovementController end
    local ok, result = xpcall(function()
        if type(_G.__ZyxMovementModuleSource) ~= "string" then error("Movement source is missing") end
        local fn, loadErr = loadstring(_G.__ZyxMovementModuleSource)
        if not fn then error(loadErr or "loadstring failed") end
        local builder = fn()
        if type(builder) ~= "function" then error("Movement builder did not return a function") end
        local controller = builder()
        if type(controller) ~= "table" then error("Movement controller did not return a table") end
        _G.__ZyxMovementController = controller
        return controller
    end, function(e)
        return tostring(e)
    end)
    if not ok then
        pcall(function() showErrorOnScreen("Movement module failed: " .. tostring(result)) end)
        warn("[ZyxLab Movement]", result)
        return nil
    end
    return result
end

-- =============================================
-- 🧩 OLYMPIA FUNCTIONS MERGED INTO ZYXLAB UI
-- =============================================
-- Functions only.  No Olympia wall-v3 UI loader/window/folder is included.
local Olympia = (function()
    local O = {}
    local streamerConnection, streamerLevelBackup, noHammerConnection
    local silentHackThread, autoTieThread, slowBeastThread, forceAbilityThread, removeRopeThread
    local silentHackConnections = {}
    local noHammerSpeed = 100
    local streamerName = tostring(theme.streamerName or "Sigma")
    local streamerLevel = tostring(theme.streamerLevel or "67")

    pcall(function()
        if getgenv then
            getgenv().Text = streamerName
            getgenv().Text2 = streamerLevel
        end
    end)

    local function localRoot()
        local char = player.Character
        return char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso"))
    end

    local function localBeast()
        local stats = player:FindFirstChild("TempPlayerStatsModule")
        return stats and stats:FindFirstChild("IsBeast") and stats.IsBeast.Value == true
    end

    local function beastPlayer()
        for _, plr in pairs(game:GetService("Players"):GetPlayers()) do
            local char = plr.Character
            local stats = plr:FindFirstChild("TempPlayerStatsModule")
            if (stats and stats:FindFirstChild("IsBeast") and stats.IsBeast.Value)
            or (char and char:FindFirstChild("BeastPowers")) then
                return plr
            end
        end
        return nil
    end

    local function powersEvent(plr)
        local char = plr and plr.Character
        local powers = char and char:FindFirstChild("BeastPowers", true)
        return powers and powers:FindFirstChild("PowersEvent", true)
    end

    function O.setStreamerMode(enabled)
        if streamerConnection then streamerConnection:Disconnect(); streamerConnection = nil end
        local pg = player:FindFirstChildOfClass("PlayerGui") or player:WaitForChild("PlayerGui")
        local sg = pg:FindFirstChild("ScreenGui")
        local statusBars = sg and sg:FindFirstChild("StatusBars")
        local namesFrame = sg and sg:FindFirstChild("PlayerNamesFrame")
        local frame = namesFrame and namesFrame:FindFirstChild(player.Name .. "PlayerFrame")
        local nameLabel = frame and frame:FindFirstChild("NameLabel")
        local levelLabel = frame and frame:FindFirstChild("LevelLabel")

        if enabled then
            if levelLabel then streamerLevelBackup = streamerLevelBackup or levelLabel.Text end
            if nameLabel then
                nameLabel.Text = streamerName
                nameLabel.TextColor3 = Color3.new(1, 1, 1)
            end
            if levelLabel then levelLabel.Text = streamerLevel end
            local streamerAccum = 0
            streamerConnection = RunService.Heartbeat:Connect(function(dt)
                pcall(function()
                    if not state.streamermode then return end
                    streamerAccum = streamerAccum + dt
                    if streamerAccum < 0.25 then return end
                    streamerAccum = 0
                    if not statusBars or not statusBars.Parent then return end
                    for _, child in pairs(statusBars:GetChildren()) do
                        if child:IsA("TextLabel") and child.Text == player.Name then
                            child.Text = streamerName
                        end
                    end
                end)
            end)
        else
            if statusBars then
                for _, child in pairs(statusBars:GetChildren()) do
                    if child:IsA("TextLabel") and child.Text == streamerName then
                        child.Text = player.Name
                    end
                end
            end
            if nameLabel then
                nameLabel.Text = player.Name
                nameLabel.TextColor3 = Color3.new(1, 1, 1)
            end
            if levelLabel and streamerLevelBackup then levelLabel.Text = streamerLevelBackup end
        end
    end

    function O.setStreamerName(text)
        local oldName = streamerName
        streamerName = tostring((text and text ~= "") and text or "Sigma")
        theme.streamerName = streamerName
        pcall(function() if getgenv then getgenv().Text = streamerName end end)
        if state.streamermode then
            local pg = player:FindFirstChildOfClass("PlayerGui")
            local sg = pg and pg:FindFirstChild("ScreenGui")
            local statusBars = sg and sg:FindFirstChild("StatusBars")
            if statusBars then
                for _, child in pairs(statusBars:GetChildren()) do
                    if child:IsA("TextLabel") and (child.Text == oldName or child.Text == player.Name) then
                        child.Text = streamerName
                    end
                end
            end
            O.setStreamerMode(true)
        end
    end

    function O.setStreamerLevel(text)
        streamerLevel = tostring((text and text ~= "") and text or "67")
        theme.streamerLevel = streamerLevel
        pcall(function() if getgenv then getgenv().Text2 = streamerLevel end end)
        if state.streamermode then O.setStreamerMode(true) end
    end

    function O.getStreamerName()
        return streamerName
    end

    function O.getStreamerLevel()
        return streamerLevel
    end

    function O.stopNoHammerCooldown()
        if noHammerConnection then noHammerConnection:Disconnect(); noHammerConnection = nil end
    end

    function O.startNoHammerCooldown()
        O.stopNoHammerCooldown()
        local noHammerAccum = 0
        noHammerConnection = RunService.Heartbeat:Connect(function(dt)
            pcall(function()
                if not state.nohammercooldown then O.stopNoHammerCooldown(); return end
                noHammerAccum = noHammerAccum + dt
                if noHammerAccum < 0.05 then return end
                noHammerAccum = 0
                if not localBeast() then return end
                local char = player.Character
                local controller = char and (char:FindFirstChild("Humanoid") or char:FindFirstChild("AnimationController"))
                if not controller then return end
                for _, track in ipairs(controller:GetPlayingAnimationTracks()) do
                    if track.Animation and track.Animation.Name == "AnimWipe" then
                        track:AdjustSpeed(noHammerSpeed)
                    end
                end
            end)
        end)
    end

    local function setHackSoundsMuted(map, muted)
        if not map then return end
        for _, descendant in ipairs(map:GetDescendants()) do
            if descendant:IsA("Sound") and (descendant.Name == "ErrorSound" or descendant.Name == "SoundTyping") then
                if muted then
                    descendant.Playing = false
                    descendant.Volume = 0
                else
                    descendant.Volume = 5
                end
            end
        end
    end

    function O.stopSilentHack()
        if silentHackThread then task.cancel(silentHackThread); silentHackThread = nil end
        for _, conn in ipairs(silentHackConnections) do pcall(function() conn:Disconnect() end) end
        table.clear(silentHackConnections)
        local currentMap = ReplicatedStorage:FindFirstChild("CurrentMap")
        if currentMap then setHackSoundsMuted(currentMap.Value, false) end
    end

    function O.startSilentHack()
        O.stopSilentHack()
        local currentMap = ReplicatedStorage:FindFirstChild("CurrentMap")
        silentHackThread = task.spawn(function()
            while state.silenthack do
                pcall(function()
                    if currentMap then setHackSoundsMuted(currentMap.Value, true) end
                end)
                task.wait(1)
            end
            silentHackThread = nil
        end)
        if currentMap then
            table.insert(silentHackConnections, currentMap.Changed:Connect(function(newMap)
                if state.silenthack then setHackSoundsMuted(newMap, true) end
            end))
        end
    end

    local function closestTieTarget()
        local root = localRoot()
        if not root then return nil end
        local closest, distance = nil, math.huge
        for _, plr in ipairs(game:GetService("Players"):GetPlayers()) do
            if plr ~= player and plr.Character then
                local hum = plr.Character:FindFirstChildOfClass("Humanoid")
                local targetRoot = plr.Character:FindFirstChild("HumanoidRootPart")
                if hum and targetRoot then
                    local dist = (root.Position - targetRoot.Position).Magnitude
                    if dist < distance then closest, distance = plr, dist end
                end
            end
        end
        return closest
    end

    function O.stopAutoTie()
        state.autotie = false
    end

    function O.startAutoTie()
        if autoTieThread then return end
        autoTieThread = task.spawn(function()
            while state.autotie do
                task.wait(0.5)
                pcall(function()
                    if localBeast() then
                        local char = player.Character
                        local target = closestTieTarget()
                        local targetChar = target and target.Character
                        if char and targetChar then
                            local targetTorso = targetChar:FindFirstChild("Torso") or targetChar:FindFirstChild("UpperTorso")
                            local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
                            local hammer = char:FindFirstChild("Hammer")
                            local hammerEvent = hammer and hammer:FindFirstChild("HammerEvent")
                            if targetTorso and targetRoot and hammerEvent then
                                hammerEvent:FireServer("HammerTieUp", targetTorso, targetRoot.Position)
                            end
                        end
                    end
                end)
            end
            autoTieThread = nil
        end)
    end

    function O.stopSlowBeast() state.slowbeast = false end
    function O.startSlowBeast()
        if slowBeastThread then return end
        slowBeastThread = task.spawn(function()
            while state.slowbeast do
                task.wait(0.12)
                pcall(function()
                    local beast = beastPlayer()
                    if beast and beast ~= player then
                        local event = powersEvent(beast)
                        if event then event:FireServer("Jumped") end
                    end
                end)
            end
            slowBeastThread = nil
        end)
    end

    function O.stopForceBeastAbility() state.forcebeastability = false end
    function O.startForceBeastAbility()
        if forceAbilityThread then return end
        forceAbilityThread = task.spawn(function()
            while state.forcebeastability do
                task.wait(0.12)
                pcall(function()
                    local beast = beastPlayer()
                    if beast and beast ~= player then
                        local event = powersEvent(beast)
                        if event then event:FireServer("Input") end
                    end
                end)
            end
            forceAbilityThread = nil
        end)
    end

    function O.stopRemoveRope() state.removerope = false end
    function O.startRemoveRope()
        if removeRopeThread then return end
        removeRopeThread = task.spawn(function()
            while state.removerope do
                task.wait(0.12)
                pcall(function()
                    local beast = beastPlayer()
                    local beastChar = beast and beast.Character
                    local hammer = beastChar and beastChar:FindFirstChild("Hammer")
                    local hammerEvent = hammer and hammer:FindFirstChild("HammerEvent")
                    local carriedTorso = beastChar and beastChar:FindFirstChild("CarriedTorso")
                    if hammerEvent and carriedTorso and carriedTorso:IsA("ObjectValue") then
                        for _, victim in pairs(game:GetService("Players"):GetPlayers()) do
                            local victimChar = victim.Character
                            local torso = victimChar and (victimChar:FindFirstChild("Torso") or victimChar:FindFirstChild("UpperTorso"))
                            if torso and carriedTorso.Value == torso then
                                hammerEvent:FireServer("HammerClick", true)
                            end
                        end
                    end
                end)
            end
            removeRopeThread = nil
        end)
    end

    function O.apply()
        if state.streamermode then O.setStreamerMode(true) else O.setStreamerMode(false) end
        if state.nohammercooldown then O.startNoHammerCooldown() else O.stopNoHammerCooldown() end
        if state.silenthack then O.startSilentHack() else O.stopSilentHack() end
        if state.autotie then O.startAutoTie() else O.stopAutoTie() end
        if state.slowbeast then O.startSlowBeast() else O.stopSlowBeast() end
        if state.forcebeastability then O.startForceBeastAbility() else O.stopForceBeastAbility() end
        if state.removerope then O.startRemoveRope() else O.stopRemoveRope() end
    end

    return O
end)()



-- =============================================
-- 👁️ SPECTATE MODULE
-- =============================================
-- Camera-only spectate with a separate draggable + resizable control panel.
-- The Spectate tab only asks which team to watch; the popup handles controls.
local Spectate = (function()
    local S = {}
    local active = false
    local mode = "None"
    local index = 1
    local target = nil
    local conn = nil
    local lastTick = 0
    local savedSubject = nil
    local savedType = nil

    local gui, panel, header, modeLabel, targetLabel, closeBtn, reopenButton, stopBtn, backBtn, nextBtn, resizeGrip
    local dragging = false
    local resizing = false
    local dragStart, startPos, resizeStart, startSize

    local function cam()
        camera = workspace.CurrentCamera or camera
        return camera
    end

    local function isInputPress(inp)
        return inp.UserInputType == Enum.UserInputType.MouseButton1
            or inp.UserInputType == Enum.UserInputType.Touch
    end

    local function isInputMove(inp)
        return inp.UserInputType == Enum.UserInputType.MouseMovement
            or inp.UserInputType == Enum.UserInputType.Touch
    end

    local function styleButton(btn, text)
        btn.Text = text
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 12
        btn.TextColor3 = Color3.new(1, 1, 1)
        btn.BackgroundColor3 = getEffectiveAccent()
        btn.BorderSizePixel = 0
        btn.AutoButtonColor = true
        btn:SetAttribute("ZyxAccentBG", true)
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    end

    local function updatePanelLayout()
        if not panel then return end
        local w = math.max(panel.AbsoluteSize.X, 240)
        local compact = w < 310
        if modeLabel then
            modeLabel.Size = UDim2.new(1, -24, 0, 18)
            modeLabel.Position = UDim2.new(0, 12, 0, 42)
        end
        if targetLabel then
            targetLabel.Size = UDim2.new(1, -24, 0, 22)
            targetLabel.Position = UDim2.new(0, 12, 0, 62)
        end
        if compact then
            backBtn.Size = UDim2.new(0.5, -16, 0, 32)
            backBtn.Position = UDim2.new(0, 12, 1, -82)
            nextBtn.Size = UDim2.new(0.5, -16, 0, 32)
            nextBtn.Position = UDim2.new(0.5, 4, 1, -82)
            stopBtn.Size = UDim2.new(1, -24, 0, 32)
            stopBtn.Position = UDim2.new(0, 12, 1, -44)
        else
            backBtn.Size = UDim2.new(0.28, -8, 0, 34)
            backBtn.Position = UDim2.new(0, 12, 1, -48)
            nextBtn.Size = UDim2.new(0.28, -8, 0, 34)
            nextBtn.Position = UDim2.new(0.28, 8, 1, -48)
            stopBtn.Size = UDim2.new(0.44, -20, 0, 34)
            stopBtn.Position = UDim2.new(0.56, 8, 1, -48)
        end
    end

    local function updatePanelText()
        if modeLabel then
            modeLabel.Text = active and ("Mode: " .. mode) or "Mode: Not spectating"
        end
        if targetLabel then
            if active and target then
                targetLabel.Text = "Watching: @" .. target.Name
            elseif active then
                targetLabel.Text = "Watching: Waiting for target"
            else
                targetLabel.Text = "Watching: None"
            end
        end
    end

    local function ensurePanel()
        if gui and panel then return end

        gui = Instance.new("ScreenGui")
        gui.Name = "ZyxLab_SpectatePanel"
        gui.ResetOnSpawn = false
        gui.IgnoreGuiInset = true
        gui.DisplayOrder = 3500
        gui.Enabled = true
        gui.Parent = getGuiParent()

        panel = Instance.new("Frame", gui)
        panel.Name = "Panel"
        panel.Size = UDim2.new(0, 330, 0, 160)
        panel.Position = UDim2.new(0.5, -165, 0.5, -80)
        panel.BackgroundColor3 = Color3.fromRGB(13, 13, 13)
        panel.BorderSizePixel = 0
        panel.ClipsDescendants = false
        panel.Visible = false
        panel.Active = true
        panel:SetAttribute("ZyxAccentStroke", true)
        Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 12)

        local stroke = Instance.new("UIStroke", panel)
        stroke.Color = getEffectiveAccent()
        stroke.Thickness = 1.4
        stroke.Transparency = 0.2

        header = Instance.new("TextButton", panel)
        header.Name = "DragHeader"
        header.Size = UDim2.new(1, 0, 0, 34)
        header.Position = UDim2.new(0, 0, 0, 0)
        header.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
        header.BorderSizePixel = 0
        header.AutoButtonColor = false
        header.Text = ""
        Instance.new("UICorner", header).CornerRadius = UDim.new(0, 12)

        local accentBar = Instance.new("Frame", header)
        accentBar.Name = "AccentBar"
        accentBar.Size = UDim2.new(0, 4, 1, 0)
        accentBar.Position = UDim2.new(0, 0, 0, 0)
        accentBar.BackgroundColor3 = getEffectiveAccent()
        accentBar.BorderSizePixel = 0
        accentBar:SetAttribute("ZyxAccentBG", true)

        local title = Instance.new("TextLabel", header)
        title.Size = UDim2.new(1, -58, 1, 0)
        title.Position = UDim2.new(0, 14, 0, 0)
        title.BackgroundTransparency = 1
        title.Font = Enum.Font.GothamBold
        title.TextSize = 13
        title.TextColor3 = Color3.new(1, 1, 1)
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.Text = "Spectate Control Panel"

        closeBtn = Instance.new("TextButton", header)
        closeBtn.Name = "ClosePanel"
        closeBtn.AnchorPoint = Vector2.new(1, 0.5)
        closeBtn.Size = UDim2.new(0, 24, 0, 24)
        closeBtn.Position = UDim2.new(1, -8, 0.5, 0)
        closeBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
        closeBtn.BorderSizePixel = 0
        closeBtn.AutoButtonColor = true
        closeBtn.Text = "×"
        closeBtn.Font = Enum.Font.GothamBold
        closeBtn.TextSize = 16
        closeBtn.TextColor3 = Color3.fromRGB(235, 235, 235)
        Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(1, 0)
        closeBtn.MouseButton1Click:Connect(function()
            if panel then panel.Visible = false end
            if reopenButton and active then reopenButton.Visible = true end
        end)

        reopenButton = Instance.new("TextButton", gui)
        reopenButton.Name = "OpenSpectatePanel"
        reopenButton.Size = UDim2.new(0, 112, 0, 34)
        reopenButton.Position = UDim2.new(1, -126, 0.5, -17)
        reopenButton.BackgroundColor3 = getEffectiveAccent()
        reopenButton.BorderSizePixel = 0
        reopenButton.Text = "👁 Spectate"
        reopenButton.Font = Enum.Font.GothamBold
        reopenButton.TextSize = 12
        reopenButton.TextColor3 = Color3.new(1, 1, 1)
        reopenButton.AutoButtonColor = true
        reopenButton.Visible = false
        reopenButton:SetAttribute("ZyxAccentBG", true)
        Instance.new("UICorner", reopenButton).CornerRadius = UDim.new(1, 0)
        reopenButton.MouseButton1Click:Connect(function()
            if panel then panel.Visible = true end
            reopenButton.Visible = false
            updatePanelText()
        end)

        modeLabel = Instance.new("TextLabel", panel)
        modeLabel.BackgroundTransparency = 1
        modeLabel.Font = Enum.Font.GothamMedium
        modeLabel.TextSize = 12
        modeLabel.TextColor3 = Color3.fromRGB(185, 185, 185)
        modeLabel.TextXAlignment = Enum.TextXAlignment.Left

        targetLabel = Instance.new("TextLabel", panel)
        targetLabel.BackgroundTransparency = 1
        targetLabel.Font = Enum.Font.GothamBold
        targetLabel.TextSize = 15
        targetLabel.TextColor3 = getEffectiveAccent()
        targetLabel.TextXAlignment = Enum.TextXAlignment.Left
        targetLabel.TextTruncate = Enum.TextTruncate.AtEnd
        targetLabel:SetAttribute("ZyxAccentText", true)

        backBtn = Instance.new("TextButton", panel)
        styleButton(backBtn, "◀ Back")
        backBtn.MouseButton1Click:Connect(function() S.back() end)

        nextBtn = Instance.new("TextButton", panel)
        styleButton(nextBtn, "Next ▶")
        nextBtn.MouseButton1Click:Connect(function() S.next() end)

        stopBtn = Instance.new("TextButton", panel)
        styleButton(stopBtn, "Stop")
        stopBtn.BackgroundColor3 = Color3.fromRGB(190, 45, 55)
        stopBtn:SetAttribute("ZyxAccentBG", nil)
        stopBtn.MouseButton1Click:Connect(function() S.stop() end)

        resizeGrip = Instance.new("TextButton", panel)
        resizeGrip.Name = "ResizeGrip"
        resizeGrip.AnchorPoint = Vector2.new(1, 1)
        resizeGrip.Size = UDim2.new(0, 22, 0, 22)
        resizeGrip.Position = UDim2.new(1, 2, 1, 2)
        resizeGrip.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
        resizeGrip.BorderSizePixel = 0
        resizeGrip.Text = "↘"
        resizeGrip.Font = Enum.Font.GothamBold
        resizeGrip.TextSize = 12
        resizeGrip.TextColor3 = Color3.fromRGB(220, 220, 220)
        resizeGrip.AutoButtonColor = false
        Instance.new("UICorner", resizeGrip).CornerRadius = UDim.new(0, 6)

        header.InputBegan:Connect(function(inp)
            if not isInputPress(inp) then return end
            dragging = true
            dragStart = inp.Position
            startPos = panel.Position
        end)
        resizeGrip.InputBegan:Connect(function(inp)
            if not isInputPress(inp) then return end
            resizing = true
            resizeStart = inp.Position
            startSize = panel.Size
        end)
        UIS.InputChanged:Connect(function(inp)
            if dragging and isInputMove(inp) and dragStart and startPos then
                local delta = inp.Position - dragStart
                panel.Position = UDim2.new(
                    startPos.X.Scale, startPos.X.Offset + delta.X,
                    startPos.Y.Scale, startPos.Y.Offset + delta.Y
                )
            elseif resizing and isInputMove(inp) and resizeStart and startSize then
                local delta = inp.Position - resizeStart
                local newW = math.clamp(startSize.X.Offset + delta.X, 240, 560)
                local newH = math.clamp(startSize.Y.Offset + delta.Y, 140, 340)
                panel.Size = UDim2.new(0, newW, 0, newH)
                updatePanelLayout()
            end
        end)
        UIS.InputEnded:Connect(function(inp)
            if isInputPress(inp) then
                dragging = false
                resizing = false
            end
        end)
        panel:GetPropertyChangedSignal("AbsoluteSize"):Connect(updatePanelLayout)

        updatePanelLayout()
        updatePanelText()
    end

    local function showPanel()
        ensurePanel()
        panel.Visible = true
        if reopenButton then reopenButton.Visible = false end
        updatePanelText()
    end

    local function hidePanel()
        if panel then panel.Visible = false end
        if reopenButton then reopenButton.Visible = false end
    end

    local function isBeast(plr)
        local char = plr and plr.Character
        local stats = plr and plr:FindFirstChild("TempPlayerStatsModule")
        return (stats and stats:FindFirstChild("IsBeast") and stats.IsBeast.Value == true)
            or (char and (char:FindFirstChild("BeastPowers") or char:FindFirstChild("Hammer")))
    end

    local function subjectFor(plr)
        local char = plr and plr.Character
        if not char then return nil end
        return char:FindFirstChildOfClass("Humanoid")
            or char:FindFirstChild("HumanoidRootPart")
            or char:FindFirstChild("Head")
            or char.PrimaryPart
    end

    local function candidates()
        local list = {}
        for _, plr in ipairs(game:GetService("Players"):GetPlayers()) do
            if plr ~= player and subjectFor(plr) then
                local beast = isBeast(plr)
                if (mode == "Beast" and beast) or (mode == "Survivor" and not beast) then
                    table.insert(list, plr)
                end
            end
        end
        table.sort(list, function(a, b) return a.Name:lower() < b.Name:lower() end)
        return list
    end

    local function notifyUI()
        updatePanelText()
    end

    local function applyCamera(plr)
        local c = cam()
        local subject = subjectFor(plr)
        if c and subject then
            c.CameraType = Enum.CameraType.Custom
            c.CameraSubject = subject
            target = plr
        else
            target = nil
        end
        notifyUI()
    end

    local function restoreCamera()
        local c = cam()
        if not c then return end
        local localChar = player.Character
        local localSubject = localChar and (localChar:FindFirstChildOfClass("Humanoid") or localChar:FindFirstChild("HumanoidRootPart"))
        c.CameraType = savedType or Enum.CameraType.Custom
        c.CameraSubject = (savedSubject and savedSubject.Parent and savedSubject) or localSubject
    end

    function S.refresh()
        if not active then return end
        local list = candidates()
        if #list == 0 then
            target = nil
            notifyUI()
            return
        end
        if index < 1 then index = #list end
        if index > #list then index = 1 end

        if target then
            for i, plr in ipairs(list) do
                if plr == target then
                    index = i
                    break
                end
            end
        end

        applyCamera(list[index])
    end

    local function startLoop()
        if conn then return end
        conn = RunService.Heartbeat:Connect(function()
            pcall(function()
                if not active then return end
                local now = tick()
                if now - lastTick < 0.25 then return end
                lastTick = now
                if not target or not target.Parent or not subjectFor(target) then
                    target = nil
                end
                S.refresh()
            end)
        end)
    end

    function S.start(newMode)
        mode = newMode or "Survivor"
        active = true
        index = 1
        target = nil
        local c = cam()
        if c then
            savedSubject = savedSubject or c.CameraSubject
            savedType = savedType or c.CameraType
        end
        showPanel()
        startLoop()
        S.refresh()
    end

    function S.next()
        if not active then return end
        index = index + 1
        target = nil
        S.refresh()
    end

    function S.back()
        if not active then return end
        index = index - 1
        target = nil
        S.refresh()
    end

    function S.stop()
        active = false
        mode = "None"
        target = nil
        restoreCamera()
        notifyUI()
        hidePanel()
    end

    function S.modeText()
        if not active then return "Not spectating" end
        return mode
    end

    function S.targetText()
        if not active then return "None" end
        if target then return "@" .. target.Name end
        return "Waiting for target"
    end

    Players.PlayerRemoving:Connect(function(plr)
        if plr == target then
            target = nil
            task.defer(S.refresh)
        end
    end)
    player.CharacterAdded:Connect(function()
        if not active then task.wait(0.2); restoreCamera() end
    end)

    return S
end)()

-- =============================================
-- 🎨 CUSTOM COLOR PICKER OVERLAY
-- =============================================
-- A single shared floating picker. Reconfigured per-target via picker:Bind(...).
-- HSV square + hue bar + hex input + R/G/B inputs + 🌈 Chroma toggle.
--
-- Wrapped in do-end so the ~50 internal locals only occupy chunk registers
-- while this block is active. The four names used outside are pre-declared
-- above the block so they remain accessible to the rest of the script.
local crPill    -- toggle pill in the chroma row (recolored by the chroma loop)
local applyBtn  -- "Apply" button (recolored by the chroma loop)
local picker    -- public picker state table  { h, s, v, chroma, open, … }
local openPicker -- function: openPicker(opts) shows the picker
do
local PickerGui = Instance.new("ScreenGui")
PickerGui.Name = "ZyxLab_ColorPicker"
PickerGui.ResetOnSpawn = false
PickerGui.DisplayOrder = 2000
PickerGui.IgnoreGuiInset = true
PickerGui.Parent = getGuiParent()

local pickerBackdrop = Instance.new("TextButton", PickerGui)
pickerBackdrop.Size = UDim2.new(1, 0, 1, 0)
pickerBackdrop.BackgroundColor3 = Color3.new(0, 0, 0)
pickerBackdrop.BackgroundTransparency = 0.55
pickerBackdrop.BorderSizePixel = 0
pickerBackdrop.Text = ""
pickerBackdrop.AutoButtonColor = false
pickerBackdrop.Visible = false

local pickerPanel = Instance.new("Frame", PickerGui)
pickerPanel.Size = UDim2.new(0, 290, 0, 360)
pickerPanel.Position = UDim2.new(0.5, -145, 0.5, -180)
pickerPanel.BackgroundColor3 = Color3.fromRGB(13, 13, 13)
pickerPanel.BorderSizePixel = 0
pickerPanel.Active = true  -- Consume clicks so they don't fall through to the backdrop
pickerPanel.Visible = false
Instance.new("UICorner", pickerPanel).CornerRadius = UDim.new(0, 12)
local pp_stroke = Instance.new("UIStroke", pickerPanel)
pp_stroke.Color = Color3.fromRGB(40, 40, 40); pp_stroke.Thickness = 1; pp_stroke.Transparency = 0.3

-- Header
local pHdr = Instance.new("Frame", pickerPanel)
pHdr.Size = UDim2.new(1, 0, 0, 36)
pHdr.BackgroundTransparency = 1
local pTitle = Instance.new("TextLabel", pHdr)
pTitle.Size = UDim2.new(1, -50, 1, 0); pTitle.Position = UDim2.new(0, 14, 0, 0)
pTitle.BackgroundTransparency = 1
pTitle.Text = "Color Picker"
pTitle.Font = Enum.Font.GothamBold; pTitle.TextSize = 14
pTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
pTitle.TextXAlignment = Enum.TextXAlignment.Left
local pClose = Instance.new("TextButton", pHdr)
pClose.Size = UDim2.new(0, 26, 0, 26); pClose.Position = UDim2.new(1, -32, 0.5, -13)
pClose.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
pClose.Text = "❌"; pClose.Font = Enum.Font.GothamBold
pClose.TextSize = 11; pClose.TextColor3 = Color3.new(1, 1, 1)
pClose.BorderSizePixel = 0
Instance.new("UICorner", pClose).CornerRadius = UDim.new(1, 0)

-- SV (saturation-value) square
local svSquare = Instance.new("Frame", pickerPanel)
svSquare.Size = UDim2.new(0, 200, 0, 160)
svSquare.Position = UDim2.new(0, 14, 0, 44)
svSquare.BackgroundColor3 = Color3.fromHSV(0, 1, 1)
svSquare.BorderSizePixel = 0
Instance.new("UICorner", svSquare).CornerRadius = UDim.new(0, 6)
-- White-to-transparent horizontal gradient (saturation)
local svSat = Instance.new("Frame", svSquare)
svSat.Size = UDim2.new(1, 0, 1, 0); svSat.BackgroundColor3 = Color3.new(1, 1, 1)
svSat.BorderSizePixel = 0
Instance.new("UICorner", svSat).CornerRadius = UDim.new(0, 6)
local svSatGrad = Instance.new("UIGradient", svSat)
svSatGrad.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
    ColorSequenceKeypoint.new(1, Color3.new(1, 1, 1)),
}
svSatGrad.Transparency = NumberSequence.new{
    NumberSequenceKeypoint.new(0, 0),
    NumberSequenceKeypoint.new(1, 1),
}
-- Black-to-transparent vertical gradient (value)
local svVal = Instance.new("Frame", svSquare)
svVal.Size = UDim2.new(1, 0, 1, 0); svVal.BackgroundColor3 = Color3.new(0, 0, 0)
svVal.BorderSizePixel = 0
Instance.new("UICorner", svVal).CornerRadius = UDim.new(0, 6)
local svValGrad = Instance.new("UIGradient", svVal)
svValGrad.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.new(0, 0, 0)),
    ColorSequenceKeypoint.new(1, Color3.new(0, 0, 0)),
}
svValGrad.Transparency = NumberSequence.new{
    NumberSequenceKeypoint.new(0, 1),
    NumberSequenceKeypoint.new(1, 0),
}
svValGrad.Rotation = 90
-- SV cursor
local svCursor = Instance.new("Frame", svSquare)
svCursor.Size = UDim2.new(0, 12, 0, 12)
svCursor.AnchorPoint = Vector2.new(0.5, 0.5)
svCursor.Position = UDim2.new(1, 0, 0, 0)
svCursor.BackgroundTransparency = 1
svCursor.ZIndex = 5
local svCStroke = Instance.new("UIStroke", svCursor)
svCStroke.Color = Color3.new(1, 1, 1); svCStroke.Thickness = 2
Instance.new("UICorner", svCursor).CornerRadius = UDim.new(1, 0)

-- Hue bar
local hueBar = Instance.new("Frame", pickerPanel)
hueBar.Size = UDim2.new(0, 22, 0, 160)
hueBar.Position = UDim2.new(0, 222, 0, 44)
hueBar.BackgroundColor3 = Color3.new(1, 1, 1)
hueBar.BorderSizePixel = 0
Instance.new("UICorner", hueBar).CornerRadius = UDim.new(0, 6)
local hueGrad = Instance.new("UIGradient", hueBar)
hueGrad.Rotation = 90
hueGrad.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0.00, Color3.fromHSV(0.00, 1, 1)),
    ColorSequenceKeypoint.new(0.16, Color3.fromHSV(0.16, 1, 1)),
    ColorSequenceKeypoint.new(0.33, Color3.fromHSV(0.33, 1, 1)),
    ColorSequenceKeypoint.new(0.50, Color3.fromHSV(0.50, 1, 1)),
    ColorSequenceKeypoint.new(0.66, Color3.fromHSV(0.66, 1, 1)),
    ColorSequenceKeypoint.new(0.83, Color3.fromHSV(0.83, 1, 1)),
    ColorSequenceKeypoint.new(1.00, Color3.fromHSV(1.00, 1, 1)),
}
local hueCursor = Instance.new("Frame", hueBar)
hueCursor.Size = UDim2.new(1, 4, 0, 4)
hueCursor.AnchorPoint = Vector2.new(0.5, 0.5)
hueCursor.Position = UDim2.new(0.5, 0, 0, 0)
hueCursor.BackgroundColor3 = Color3.new(1, 1, 1)
hueCursor.BorderSizePixel = 0
hueCursor.ZIndex = 5
local hcStroke = Instance.new("UIStroke", hueCursor)
hcStroke.Color = Color3.new(0, 0, 0); hcStroke.Thickness = 1

-- Hex input
local function makeBox(parent, x, y, w)
    local box = Instance.new("TextBox", parent)
    box.Size = UDim2.new(0, w, 0, 24); box.Position = UDim2.new(0, x, 0, y)
    box.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    box.BorderSizePixel = 0
    box.Font = Enum.Font.Gotham; box.TextSize = 12
    box.TextColor3 = Color3.fromRGB(230, 230, 230)
    box.PlaceholderColor3 = Color3.fromRGB(110, 110, 110)
    box.ClearTextOnFocus = false
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 4)
    local s = Instance.new("UIStroke", box); s.Color = Color3.fromRGB(45, 45, 45); s.Thickness = 1
    return box
end

local hexLbl = Instance.new("TextLabel", pickerPanel)
hexLbl.Size = UDim2.new(0, 30, 0, 24); hexLbl.Position = UDim2.new(0, 14, 0, 214)
hexLbl.BackgroundTransparency = 1; hexLbl.Text = "Hex"
hexLbl.Font = Enum.Font.GothamBold; hexLbl.TextSize = 12
hexLbl.TextColor3 = Color3.fromRGB(180, 180, 180); hexLbl.TextXAlignment = Enum.TextXAlignment.Left
local hexBox = makeBox(pickerPanel, 50, 214, 110)
hexBox.PlaceholderText = "#FFFFFF"

local rLbl = Instance.new("TextLabel", pickerPanel)
rLbl.Size = UDim2.new(0, 14, 0, 24); rLbl.Position = UDim2.new(0, 14, 0, 244)
rLbl.BackgroundTransparency = 1; rLbl.Text = "R"; rLbl.Font = Enum.Font.GothamBold
rLbl.TextSize = 12; rLbl.TextColor3 = Color3.fromRGB(255, 100, 100)
local rBox = makeBox(pickerPanel, 30, 244, 50)
rBox.PlaceholderText = "0"

local gLbl = Instance.new("TextLabel", pickerPanel)
gLbl.Size = UDim2.new(0, 14, 0, 24); gLbl.Position = UDim2.new(0, 88, 0, 244)
gLbl.BackgroundTransparency = 1; gLbl.Text = "G"; gLbl.Font = Enum.Font.GothamBold
gLbl.TextSize = 12; gLbl.TextColor3 = Color3.fromRGB(100, 220, 120)
local gBox = makeBox(pickerPanel, 104, 244, 50)
gBox.PlaceholderText = "0"

local bLbl = Instance.new("TextLabel", pickerPanel)
bLbl.Size = UDim2.new(0, 14, 0, 24); bLbl.Position = UDim2.new(0, 162, 0, 244)
bLbl.BackgroundTransparency = 1; bLbl.Text = "B"; bLbl.Font = Enum.Font.GothamBold
bLbl.TextSize = 12; bLbl.TextColor3 = Color3.fromRGB(100, 160, 255)
local bBox = makeBox(pickerPanel, 178, 244, 50)
bBox.PlaceholderText = "0"

-- Chroma toggle pill
local chromaRow = Instance.new("Frame", pickerPanel)
chromaRow.Size = UDim2.new(1, -28, 0, 38); chromaRow.Position = UDim2.new(0, 14, 0, 280)
chromaRow.BackgroundColor3 = Color3.fromRGB(18, 18, 18); chromaRow.BorderSizePixel = 0
Instance.new("UICorner", chromaRow).CornerRadius = UDim.new(0, 8)
local crStroke = Instance.new("UIStroke", chromaRow)
crStroke.Color = Color3.fromRGB(40, 40, 40); crStroke.Thickness = 1
local crLbl = Instance.new("TextLabel", chromaRow)
crLbl.Size = UDim2.new(1, -70, 1, 0); crLbl.Position = UDim2.new(0, 12, 0, 0)
crLbl.BackgroundTransparency = 1; crLbl.Text = "🌈 Chroma (Rainbow)"
crLbl.Font = Enum.Font.GothamBold; crLbl.TextSize = 13
crLbl.TextColor3 = Color3.new(1, 1, 1); crLbl.TextXAlignment = Enum.TextXAlignment.Left
-- pill on right (pre-declared outside do block so the chroma loop can reach it)
crPill = Instance.new("TextButton", chromaRow)
crPill.Size = UDim2.new(0, 44, 0, 22); crPill.Position = UDim2.new(1, -54, 0.5, -11)
crPill.BackgroundColor3 = Color3.fromRGB(40, 40, 40); crPill.Text = ""
crPill.BorderSizePixel = 0
Instance.new("UICorner", crPill).CornerRadius = UDim.new(1, 0)
local crKnob = Instance.new("Frame", crPill)
crKnob.Size = UDim2.new(0, 16, 0, 16); crKnob.Position = UDim2.new(0, 3, 0.5, -8)
crKnob.BackgroundColor3 = Color3.fromRGB(140, 140, 140); crKnob.BorderSizePixel = 0
Instance.new("UICorner", crKnob).CornerRadius = UDim.new(1, 0)

-- Apply button (pre-declared outside do block so the chroma loop can reach it)
applyBtn = Instance.new("TextButton", pickerPanel)
applyBtn.Size = UDim2.new(1, -28, 0, 30); applyBtn.Position = UDim2.new(0, 14, 0, 324)
applyBtn.BackgroundColor3 = Color3.fromRGB(255, 0, 127)
applyBtn.Text = "Done"; applyBtn.Font = Enum.Font.GothamBold
applyBtn.TextSize = 13; applyBtn.TextColor3 = Color3.new(1, 1, 1)
applyBtn.BorderSizePixel = 0
Instance.new("UICorner", applyBtn).CornerRadius = UDim.new(0, 6)

-- Picker logic state (pre-declared outside do block so other code can read picker.open etc.)
picker = {
    open       = false,
    h = 0, s = 1, v = 1,
    chroma     = false,
    onChange   = nil,  -- function(Color3)
    onChroma   = nil,  -- function(bool)
    title      = "Color Picker",
}

local function refreshSVTint()
    svSquare.BackgroundColor3 = Color3.fromHSV(picker.h, 1, 1)
end
local function refreshSwatch()
    -- preview swatch removed; SV/hue cursors + hex input show current color
    return Color3.fromHSV(picker.h, picker.s, picker.v)
end
local function refreshCursors()
    svCursor.Position = UDim2.new(picker.s, 0, 1 - picker.v, 0)
    hueCursor.Position = UDim2.new(0.5, 0, picker.h, 0)
end
local function refreshInputs()
    local c = Color3.fromHSV(picker.h, picker.s, picker.v)
    hexBox.Text = color3ToHex(c)
    rBox.Text = tostring(math.floor(c.R * 255 + 0.5))
    gBox.Text = tostring(math.floor(c.G * 255 + 0.5))
    bBox.Text = tostring(math.floor(c.B * 255 + 0.5))
end
local function refreshChromaPill()
    local on = picker.chroma
    TweenService:Create(crPill, TweenInfo.new(0.18, Enum.EasingStyle.Quint), {
        BackgroundColor3 = on and Color3.fromRGB(255, 0, 127) or Color3.fromRGB(40, 40, 40)
    }):Play()
    TweenService:Create(crKnob, TweenInfo.new(0.18, Enum.EasingStyle.Quint), {
        Position = on and UDim2.new(0, 25, 0.5, -8) or UDim2.new(0, 3, 0.5, -8),
        BackgroundColor3 = on and Color3.new(1, 1, 1) or Color3.fromRGB(140, 140, 140),
    }):Play()
end
local function fireChange()
    if picker.onChange then
        picker.onChange(Color3.fromHSV(picker.h, picker.s, picker.v))
    end
end

-- SV drag
local svDrag = false
local function svApply(absX, absY)
    local rel = svSquare.AbsoluteSize
    local x = math.clamp((absX - svSquare.AbsolutePosition.X) / rel.X, 0, 1)
    local y = math.clamp((absY - svSquare.AbsolutePosition.Y) / rel.Y, 0, 1)
    picker.s = x; picker.v = 1 - y
    refreshSwatch(); refreshCursors(); refreshInputs(); fireChange()
end
svSquare.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
        svDrag = true; svApply(inp.Position.X, inp.Position.Y)
    end
end)
UIS.InputChanged:Connect(function(inp)
    if svDrag and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
        svApply(inp.Position.X, inp.Position.Y)
    end
end)
UIS.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
        svDrag = false
    end
end)

-- Hue drag
local hueDrag = false
local function hueApply(absY)
    local rel = hueBar.AbsoluteSize
    local y = math.clamp((absY - hueBar.AbsolutePosition.Y) / rel.Y, 0, 1)
    picker.h = y
    refreshSVTint(); refreshSwatch(); refreshCursors(); refreshInputs(); fireChange()
end
hueBar.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
        hueDrag = true; hueApply(inp.Position.Y)
    end
end)
UIS.InputChanged:Connect(function(inp)
    if hueDrag and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
        hueApply(inp.Position.Y)
    end
end)
UIS.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
        hueDrag = false
    end
end)

-- Hex input
hexBox.FocusLost:Connect(function()
    local c = hexToColor3(hexBox.Text)
    if c then
        local h, s, v = Color3.toHSV(c)
        picker.h, picker.s, picker.v = h, s, v
        refreshSVTint(); refreshSwatch(); refreshCursors(); refreshInputs(); fireChange()
    else
        refreshInputs()
    end
end)

-- RGB inputs
local function rgbCommit()
    local r = tonumber(rBox.Text) or 0
    local g = tonumber(gBox.Text) or 0
    local b = tonumber(bBox.Text) or 0
    r = math.clamp(math.floor(r), 0, 255)
    g = math.clamp(math.floor(g), 0, 255)
    b = math.clamp(math.floor(b), 0, 255)
    local c = Color3.fromRGB(r, g, b)
    local h, s, v = Color3.toHSV(c)
    picker.h, picker.s, picker.v = h, s, v
    refreshSVTint(); refreshSwatch(); refreshCursors(); refreshInputs(); fireChange()
end
rBox.FocusLost:Connect(rgbCommit)
gBox.FocusLost:Connect(rgbCommit)
bBox.FocusLost:Connect(rgbCommit)

-- Chroma toggle.  The full row is clickable so it works better on mobile.
local function setPickerChroma(on)
    picker.chroma = on and true or false
    refreshChromaPill()
    if picker.onChroma then picker.onChroma(picker.chroma) end
end
local lastPickerChromaToggle = 0
local function togglePickerChroma()
    local now = tick()
    if now - lastPickerChromaToggle < 0.08 then return end
    lastPickerChromaToggle = now
    setPickerChroma(not picker.chroma)
end
crPill.MouseButton1Click:Connect(togglePickerChroma)
chromaRow.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
        togglePickerChroma()
    end
end)

-- Open / close
local function closePicker()
    picker.open = false
    pickerPanel.Visible = false
    pickerBackdrop.Visible = false
    picker.onChange = nil
    picker.onChroma = nil
end
pClose.MouseButton1Click:Connect(closePicker)
applyBtn.MouseButton1Click:Connect(closePicker)
pickerBackdrop.MouseButton1Click:Connect(closePicker)

-- Public open function (pre-declared outside do block so tab pages can call it)
openPicker = function(opts)
    -- opts: { title, color, chroma, onChange, onChroma }
    pTitle.Text = opts.title or "Color Picker"
    local c = opts.color or Color3.new(1, 1, 1)
    local h, s, v = Color3.toHSV(c)
    picker.h, picker.s, picker.v = h, s, v
    picker.chroma = opts.chroma or false
    picker.onChange = opts.onChange
    picker.onChroma = opts.onChroma

    refreshSVTint(); refreshSwatch(); refreshCursors(); refreshInputs(); refreshChromaPill()

    -- Hide chroma row if not supported
    chromaRow.Visible = (opts.onChroma ~= nil)
    if not chromaRow.Visible then
        applyBtn.Position = UDim2.new(0, 14, 0, 282)
        pickerPanel.Size = UDim2.new(0, 290, 0, 320)
    else
        applyBtn.Position = UDim2.new(0, 14, 0, 324)
        pickerPanel.Size = UDim2.new(0, 290, 0, 360)
    end

    picker.open = true
    pickerBackdrop.Visible = true
    pickerPanel.Visible = true
end
end -- close color picker do block

-- =============================================
-- 🚀 LOAD XovaModedLib (VitaLib_Enhanced)
-- =============================================
pcall(function() ((getgenv and getgenv()) or _G).__ZyxLoadingSet("Loading Xova library", 0.35) end)
local Library
local libOk, libErr = pcall(function()
    Library = loadstring(game:HttpGet(
        "https://raw.githubusercontent.com/JScripter-Lua/Xova" .. "ModedLib/refs/heads/main/VitaLib_Enhanced.lua"
    ))()
end)
if not libOk or not Library then
    showErrorOnScreen("Library load FAILED: " .. tostring(libErr))
    showErrorOnScreen("Fix: Enable HTTP Requests in your executor settings, then re-run.")
    -- Unblock the loading screen so it doesn't hang forever
    pcall(function()
        local env = (getgenv and getgenv()) or _G
        if env.__ZyxLoadingError then env.__ZyxLoadingError("Library load failed") end
        task.wait(2)
        if env.__ZyxLoadingFinish then env.__ZyxLoadingFinish("Error") end
    end)
    return
end
pcall(function() ((getgenv and getgenv()) or _G).__ZyxLoadingSet("Building interface", 0.58) end)

-- Small helpers used by the startup toast, chroma recolor, and header cleanup.
local function collectGuiRoots()
    local roots = {}
    local function add(root)
        if not root then return end
        for _, r in ipairs(roots) do
            if r == root then return end
        end
        table.insert(roots, root)
    end

    local ok, hui = pcall(function() return gethui and gethui() end)
    if ok then add(hui) end
    add(player:FindFirstChildOfClass("PlayerGui") or player:WaitForChild("PlayerGui"))
    return roots
end

local function colorClose(a, b, eps)
    eps = eps or 0.045
    return math.abs(a.R - b.R) <= eps
       and math.abs(a.G - b.G) <= eps
       and math.abs(a.B - b.B) <= eps
end


local function fireStartupNotification()
    -- Keep only the native library startup notification.
    -- The custom fallback toast was the extra blue notification.
    pcall(function()
        Library:Notification({
            Title = "ZyxLab",
            Desc = "Made by ZyxFTF",
            Duration = 4,
            Type = "Success",
        })
    end)
end

local function accentHex()
    return color3ToHex(Color3.fromRGB(theme.accentR, theme.accentG, theme.accentB))
end

-- Finish the loader before the main Xova window appears.  This avoids the
-- broken v39 approach that hid the created UI; here the window simply is not
-- created until the small loader has completed its progress and fade-out.
pcall(function()
    local env = _G
    pcall(function() if getgenv then env = getgenv() end end)
    if env.__ZyxLoadingSet then env.__ZyxLoadingSet("Finalizing interface", 0.98) end
    if env.__ZyxLoadingFinish then env.__ZyxLoadingFinish("Ready") end
end)
do
    local env = _G
    pcall(function() if getgenv then env = getgenv() end end)
    local started = tick()
    while env.__ZyxLoadingDone == false and tick() - started < 9 do
        task.wait(0.05)
    end
    -- Force-unblock if still stuck (safety net)
    if env.__ZyxLoadingDone == false then
        pcall(function() if env.__ZyxLoadingFinish then env.__ZyxLoadingFinish("Ready") end end)
        task.wait(0.8)
    end
end

local Window = Library:Window({
    Title             = "ZyxLab",
    SubTitle          = "",
    ToggleKey         = Enum.KeyCode.RightControl,
    BbIcon            = "cpu",         -- pill toggle icon
    PillIcon          = "cpu",         -- pill toggle icon (some lib versions use this key)
    ShowTime          = false,            -- for library builds that support hiding the time block
    AutoScale         = true,
    Scale             = 1.45,
    ExecIdentifyShown = false,
    Theme = {
        Accent     = accentHex(),
        Background = "#0D0D0D",
        Row        = "#0F0F0F",
        RowAlt     = "#0A0A0A",
        Stroke     = "#191919",
        Text       = "#FFFFFF",
        SubText    = "#A3A3A3",
        TabBg      = "#0A0A0A",
        TabStroke  = "#1E1E1E",
        TabImage   = accentHex(),
        DropBg     = "#121212",
        DropStroke = "#1E1E1E",
        PillBg     = "#0B0B0B",
    },
})

pcall(function() Library:SetExecutorIdentity(false) end)

-- Now that the main Xova window exists, allow beast notifications to appear.
beastNotifierReady = true
notifGui.Enabled = true

-- XovaModedLib's current enhanced header always creates an "Expires" block.
-- Hide only the visual header group/text in this UI; it does not touch feature logic.
local function hideExpiryHeader()
    for _, root in ipairs(collectGuiRoots()) do
        for _, obj in ipairs(root:GetDescendants()) do
            pcall(function()
                if obj:IsA("GuiObject") and obj.Name == "Expires" then
                    obj.Visible = false
                    obj.Size = UDim2.new(0, 0, 0, 0)
                elseif (obj:IsA("TextLabel") or obj:IsA("TextButton")) then
                    local txt = tostring(obj.Text or "")
                    if txt:lower():find("expires at", 1, true) then
                        obj.Visible = false
                        obj.Text = ""
                        obj.Size = UDim2.new(0, 0, 0, 0)
                    end
                end
            end)
        end
    end
end

hideExpiryHeader()
task.spawn(function()
    for _ = 1, 20 do
        hideExpiryHeader()
        task.wait(0.25)
    end
end)
-- Fire after the window exists, before the rest of the page code can interfere.
task.delay(0.8, fireStartupNotification)

-- Helper to push current accent into only the ZyxLab UI.
-- The old version scanned every GUI under gethui()/PlayerGui and recolored
-- anything that looked like the previous accent color.  That could tint the
-- actual game UI or executor UI/logo.  This version first finds ZyxLab-owned
-- ScreenGuis, then recolors only inside those roots.
local lastPushedAccent = ""
local lastPushedAccentColor = Color3.fromRGB(theme.accentR, theme.accentG, theme.accentB)

local function collectZyxAccentRoots()
    local roots = {}

    local function add(root)
        if not root then return end
        for _, existing in ipairs(roots) do
            if existing == root then return end
        end
        table.insert(roots, root)
    end

    local function rootLooksOwned(root)
        if not root then return false end
        local name = tostring(root.Name or "")
        return name:find("ZyxLab", 1, true) ~= nil
    end

    local function scanRoot(root)
        if not root then return end

        pcall(function()
            if root:IsA("ScreenGui") and rootLooksOwned(root) then
                add(root)
            end
        end)

        local ok, desc = pcall(function()
            return root:GetDescendants()
        end)
        if not ok or not desc then return end

        for _, obj in ipairs(desc) do
            pcall(function()
                if obj:IsA("ScreenGui") and rootLooksOwned(obj) then
                    add(obj)
                    return
                end

                if obj:IsA("TextLabel") or obj:IsA("TextButton") then
                    local text = tostring(obj.Text or "")
                    if text == "ZyxLab" or text:find("ZyxLab", 1, true) then
                        local sg = obj:FindFirstAncestorOfClass("ScreenGui")
                        if sg then add(sg) end
                    end
                end
            end)
        end
    end

    for _, root in ipairs(collectGuiRoots()) do
        scanRoot(root)
    end

    return roots
end

local function pushAccentToLibrary(force)
    local c = getEffectiveAccent()
    local hex = color3ToHex(c)
    if not force and hex == lastPushedAccent then return end

    local old = lastPushedAccentColor
    local staticAccent = Color3.fromRGB(theme.accentR, theme.accentG, theme.accentB)
    local function isAccentCandidate(color)
        return colorClose(color, old, 0.07) or colorClose(color, staticAccent, 0.07)
    end
    lastPushedAccent = hex

    -- Do NOT call Library:SetTheme here.  Some library/executor combinations
    -- apply theme changes by walking broad GUI parents.  The manual update
    -- below is deliberately scoped to ZyxLab roots only.

    for _, root in ipairs(collectZyxAccentRoots()) do
        local ok, desc = pcall(function()
            return root:GetDescendants()
        end)
        if ok and desc then
            for _, obj in ipairs(desc) do
                pcall(function()
                    if obj:GetAttribute("ZyxAccentStroke") then
                        local stroke = obj:IsA("UIStroke") and obj or obj:FindFirstChildOfClass("UIStroke")
                        if stroke then stroke.Color = c end
                    elseif obj:IsA("UIStroke") and isAccentCandidate(obj.Color) then
                        obj.Color = c
                    end

                    if obj:GetAttribute("ZyxAccentText") then
                        if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
                            obj.TextColor3 = c
                        end
                    elseif (obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox"))
                    and isAccentCandidate(obj.TextColor3) then
                        obj.TextColor3 = c
                    end

                    if obj:IsA("ImageLabel") or obj:IsA("ImageButton") then
                        local img = tostring(obj.Image or "")
                        local isPlayerThumb = img:find("rbxthumb://", 1, true) and img:find(tostring(player.UserId), 1, true)
                        if not obj:GetAttribute("ZyxNoAccentImage") and not isPlayerThumb and isAccentCandidate(obj.ImageColor3) then
                            obj.ImageColor3 = c
                        end
                    end

                    if obj:GetAttribute("ZyxAccentBG") then
                        if obj:IsA("GuiObject") then obj.BackgroundColor3 = c end
                    elseif obj:IsA("GuiObject") and isAccentCandidate(obj.BackgroundColor3) then
                        obj.BackgroundColor3 = c
                    end
                end)
            end
        end
    end

    lastPushedAccentColor = c
end
pushAccentToLibrary(true)

pcall(function() ((getgenv and getgenv()) or _G).__ZyxLoadingSet("Building pages", 0.70) end)

-- Wrapped in do-end to reset the Lua local register counter.
-- The color picker section above is also wrapped in its own do-end block,
-- which freed ~46 chunk-scope register slots. By this point the outer chunk
-- has ~117 chunk-scope locals; the pages below add ~19 more (well under 200).
do
-- =============================================
-- 📑 PAGES
-- =============================================
local visualsPage = Window:NewPage({
    Title    = "Visuals",
    Desc     = "ESPs & screen tweaks",
    Icon     = "view",
    TabImage = accentHex(),
})

local miscPage = Window:NewPage({
    Title    = "Misc",
    Desc     = "Gameplay tweaks",
    Icon     = "wrench",
    TabImage = accentHex(),
})

_G.__ZyxMovementPage = Window:NewPage({
    Title    = "Movements",
    Desc     = "Speed & mobility",
    Icon     = "move",
    TabImage = accentHex(),
})

local ragePage = Window:NewPage({
    Title    = "Rage",
    Desc     = "Beast pressure tools",
    Icon     = "swords",
    TabImage = accentHex(),
})

local funPage = Window:NewPage({
    Title    = "Fun",
    Desc     = "Fun Stuff",
    Icon     = "laugh",
    TabImage = accentHex(),
})

local endGamePage = Window:NewPage({
    Title    = "End Game",
    Desc     = "Force-end the round",
    Icon     = "flag",
    TabImage = accentHex(),
})

local autofarmsPage = Window:NewPage({
    Title    = "Autofarms",
    Desc     = "Automated farming tools",
    Icon     = "bot",
    TabImage = accentHex(),
})

local spectatePage = Window:NewPage({
    Title    = "Spectate",
    Desc     = "Watch survivor or beast POV",
    Icon     = "video",
    TabImage = accentHex(),
})

local audioPage = Window:NewPage({
    Title    = "Audio",
    Desc     = "Custom soundpack",
    Icon     = "music",
    TabImage = accentHex(),
})

_G.__ZyxAudioPlayerPage = Window:NewPage({
    Title    = "Audio Player",
    Desc     = "Pop-out scanner",
    Icon     = "volume-2",
    TabImage = accentHex(),
})

local customizePage = Window:NewPage({
    Title    = "Customize",
    Desc     = "Colors & chroma",
    Icon     = "palette",
    TabImage = accentHex(),
})

local configPage = Window:NewPage({
    Title    = "Configs",
    Desc     = "Save & load profiles",
    Icon     = "database",
    TabImage = accentHex(),
})

local searchPage = Window:NewPage({
    Title    = "Search",
    Desc     = "Find features fast",
    Icon     = "file-search",
    TabImage = accentHex(),
})

local infoPage = Window:NewPage({
    Title    = "Info",
    Desc     = "Session stats & profile",
    Icon     = "user",
    TabImage = accentHex(),
})

-- Visuals/Search use the same short Lucide-name style as the working tabs.

-- Track toggle handles so we can refresh their visual state after a config load
local toggleHandles = {}

-- =============================================
-- 👁️ VISUALS PAGE
-- =============================================
visualsPage:Section("Detection")

toggleHandles.playerESP = visualsPage:Toggle({
    Title = "Player ESP",
    Desc  = "Highlight all players (red for beast)",
    Value = state.playerESP,
    Callback = function(v)
        state.playerESP = v
        if v then
            for _, p in pairs(game:GetService("Players"):GetPlayers()) do applyPlayerHighlight(p) end
        else
            clearPlayerESP()
        end
    end,
})

toggleHandles.doorESP = visualsPage:Toggle({
    Title = "Door ESP",
    Desc  = "Highlight all doors",
    Value = state.doorESP,
    Callback = function(v)
        state.doorESP = v
        if v then applyDoorESP() else clearDoorESP() end
    end,
})

toggleHandles.exitESP = visualsPage:Toggle({
    Title = "Exit ESP",
    Desc  = "Highlight exit doors",
    Value = state.exitESP,
    Callback = function(v)
        state.exitESP = v
        if v then applyExitESP() else clearExitESP() end
    end,
})

toggleHandles.computerESP = visualsPage:Toggle({
    Title = "Computer ESP",
    Desc  = "Highlight computer terminals",
    Value = state.computerESP,
    Callback = function(v)
        state.computerESP = v
        if not v then clearComputerESP() end
    end,
})

toggleHandles.freezepodESP = visualsPage:Toggle({
    Title = "FreezePod ESP",
    Desc  = "Highlight freeze pods",
    Value = state.freezepodESP,
    Callback = function(v)
        state.freezepodESP = v
        if v then applyFreezeESP() else clearFreezeESP() end
    end,
})

visualsPage:Section("Helpers")

toggleHandles.progressbar = visualsPage:Toggle({
    Title = "Progress Bar",
    Desc  = "Show hacking % above PCs",
    Value = state.progressbar,
    Callback = function(v) state.progressbar = v end,
})

toggleHandles.fullbright = visualsPage:Toggle({
    Title = "Fullbright",
    Desc  = "Disable shadows + max brightness",
    Value = state.fullbright,
    Callback = function(v)
        state.fullbright = v
        if v then enableFullbright() else disableFullbright() end
    end,
})


-- ─── WALLHOP VIEWER (core logic) ───
do
    local whl_enabled   = false
    local whl_color     = Color3.new(1, 1, 1)
    local whl_thickness = 0.02
    local whl_loop      = nil
    local whl_chroma    = false

    local function whl_isCharPart(part)
        local m = part:FindFirstAncestorOfClass("Model")
        return m and m:FindFirstChildOfClass("Humanoid") ~= nil
    end

    local function whl_apply()
        for _, p in pairs(workspace:GetDescendants()) do
            if p:IsA("BasePart") and not whl_isCharPart(p) then
                local hl = p:FindFirstChild("MEWHL")
                if not hl then
                    hl = Instance.new("SelectionBox")
                    hl.Name          = "MEWHL"
                    hl.Adornee       = p
                    hl.Parent        = p
                end
                hl.Color3        = whl_color
                hl.LineThickness = whl_thickness
            end
        end
    end

    local function whl_clear()
        for _, p in pairs(workspace:GetDescendants()) do
            if p:IsA("BasePart") then
                local hl = p:FindFirstChild("MEWHL")
                if hl then hl:Destroy() end
            end
        end
    end

    local function whl_start()
        if whl_loop then task.cancel(whl_loop) end
        whl_loop = task.spawn(function()
            whl_apply()
            while whl_enabled do
                task.wait(2)
                if whl_enabled then whl_apply() end
            end
            whl_loop = nil
        end)
    end

    -- expose so customization page can update live
    _G.__ZyxWhl = {
        setColor = function(c)
            whl_color = c
            if whl_enabled then whl_apply() end
        end,
        setThickness = function(t)
            whl_thickness = t
            if whl_enabled then whl_apply() end
        end,
        setChroma = function(b)
            whl_chroma = b == true
        end,
        getChroma = function()
            return whl_chroma
        end,
    }

    visualsPage:Section("Wallhop Viewer")

    visualsPage:Toggle({
        Title = "Wallhop Viewer",
        Desc  = "Draws SelectionBox outlines on every BasePart in workspace",
        Value = false,
        Callback = function(v)
            whl_enabled = v
            if v then
                whl_start()
            else
                if whl_loop then task.cancel(whl_loop); whl_loop = nil end
                whl_clear()
            end
        end,
    })
end

-- =============================================
-- 🛠️ MISC PAGE
-- =============================================
miscPage:Section("Gameplay")

toggleHandles.antierror = miscPage:Toggle({
    Title = "Anti-Error",
    Desc  = "Force success on minigame results",
    Value = state.antierror,
    Callback = function(v) state.antierror = v end,
})

toggleHandles.noslow = miscPage:Toggle({
    Title = "No Slow",
    Desc  = "Maintain min walkspeed when Beast",
    Value = state.noslow,
    Callback = function(v)
        state.noslow = v
        if v then enableNoSlow() else disableNoSlow() end
    end,
})

toggleHandles.beastnotify = miscPage:Toggle({
    Title = "Beast Notifier",
    Desc  = "Toast when Beast is chosen / uses power + ability recharge",
    Value = state.beastnotify,
    Callback = function(v) state.beastnotify = v end,
})

-- ─── ANTI AFK ───
-- Uses Roblox VirtualUser only while the toggle is enabled.  Stored on _G so
-- this tiny feature does not add persistent top-level locals to the large main chunk.
toggleHandles.antiafk = miscPage:Toggle({
    Title = "Anti AFK",
    Desc  = "Prevents idle kick by sending a small VirtualUser input",
    Value = state.antiafk,
    Callback = function(v)
        state.antiafk = v
        pcall(function()
            if _G.__ZyxAntiAFKConn then
                _G.__ZyxAntiAFKConn:Disconnect()
                _G.__ZyxAntiAFKConn = nil
            end
        end)

        if v then
            _G.__ZyxAntiAFKConn = player.Idled:Connect(function()
                pcall(function()
                    local VirtualUser = game:GetService("VirtualUser")
                    local currentCamera = workspace.CurrentCamera
                    local cf = currentCamera and currentCamera.CFrame or CFrame.new()
                    VirtualUser:Button2Down(Vector2.zero, cf)
                    task.wait(1)
                    currentCamera = workspace.CurrentCamera
                    cf = currentCamera and currentCamera.CFrame or CFrame.new()
                    VirtualUser:Button2Up(Vector2.zero, cf)
                    print("Player Successfully UnIdled.")
                end)
            end)
            print("Anti AFK Active")
        else
            print("Anti AFK Disabled")
        end
    end,
})

-- ─── AUTO INTERACT ───
do
    -- Persists across toggle cycles; declared here so start/stop share state.
    local Remote = ReplicatedStorage:WaitForChild("RemoteEvent")

    local interactCache    = {}
    local lastCacheUpdate  = 0
    local lastTrigger      = nil
    local lastActionTick   = 0
    local lastComputerTick = 0
    local autoInteractConn = nil

    local ACTION_CD   = 0.05  -- doors / pods
    local COMPUTER_CD = 0.1   -- computers
    local TRIGGER_CD  = 0.03  -- kept for parity with source

    local function fireTrigger(triggerPart, state)
        local ev = triggerPart and triggerPart:FindFirstChild("Event")
        if not ev then return end
        pcall(function() Remote:FireServer("Input", "Trigger", state, ev) end)
    end

    local function fireAction(state)
        pcall(function() Remote:FireServer("Input", "Action", state) end)
    end

    local function setTypingAnimation(state)
        local stats = player:FindFirstChild("TempPlayerStatsModule")
        if stats and stats:FindFirstChild("CurrentAnimation") then
            stats.CurrentAnimation.Value = state and "Typing" or ""
        end
    end

    local function updateCache()
        interactCache = {}
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("Model") then
                if obj.Name == "SingleDoor" or obj.Name == "DoubleDoor"
                or obj.Name == "ExitDoor"   or obj.Name == "FreezePod" then
                    local tName = (obj.Name == "FreezePod" and "PodTrigger")
                        or (obj.Name == "ExitDoor" and "ExitDoorTrigger")
                        or "DoorTrigger"
                    local trigger = obj:FindFirstChild(tName, true)
                    if trigger then
                        table.insert(interactCache, { Trigger = trigger, Root = trigger, IsComputer = false })
                    end
                elseif obj.Name == "ComputerTable" then
                    for _, child in ipairs(obj:GetDescendants()) do
                        if child.Name:find("ComputerTrigger") and child:FindFirstChild("Event") then
                            table.insert(interactCache, { Trigger = child, Root = child, IsComputer = true })
                        end
                    end
                end
            end
        end
    end

    local function getNearestInteract()
        local character = player.Character
        local hrp = character and character:FindFirstChild("HumanoidRootPart")
        if not hrp then return nil end
        local closest, minDist = nil, 7
        for _, data in ipairs(interactCache) do
            if data.Trigger and data.Trigger.Parent then
                local dist = (hrp.Position - data.Root.Position).Magnitude
                if dist < minDist then
                    minDist = dist
                    closest = data
                end
            end
        end
        return closest
    end

    local function startAutoInteract()
        if autoInteractConn then return end
        updateCache()
        lastCacheUpdate = tick()
        autoInteractConn = RunService.Heartbeat:Connect(function()
            local now = tick()
            if now - lastCacheUpdate > 2 then
                updateCache()
                lastCacheUpdate = now
            end
            local nearest = getNearestInteract()
            if nearest then
                if lastTrigger ~= nearest.Trigger then
                    if lastTrigger then fireTrigger(lastTrigger, false) end
                    fireTrigger(nearest.Trigger, true)
                    lastTrigger = nearest.Trigger
                end
                if nearest.IsComputer then
                    setTypingAnimation(true)
                    if now - lastComputerTick > COMPUTER_CD then
                        fireAction(true)
                        lastComputerTick = now
                    end
                else
                    setTypingAnimation(false)
                    if now - lastActionTick > ACTION_CD then
                        fireAction(true)
                        lastActionTick = now
                    end
                end
            else
                if lastTrigger then
                    fireTrigger(lastTrigger, false)
                    lastTrigger = nil
                end
                setTypingAnimation(false)
            end
        end)
    end

    local function stopAutoInteract()
        if autoInteractConn then
            autoInteractConn:Disconnect()
            autoInteractConn = nil
        end
        if lastTrigger then
            fireTrigger(lastTrigger, false)
            lastTrigger = nil
        end
        setTypingAnimation(false)
    end

    miscPage:Toggle({
        Title = "Auto Interact",
        Desc  = "Automatically interact with nearby doors, pods, and computers",
        Value = false,
        Callback = function(v)
            if v then startAutoInteract() else stopAutoInteract() end
        end,
    })
end

-- ─── PC FAST HACK ───
do
    local Remote = ReplicatedStorage:WaitForChild("RemoteEvent")

    local pcInteractCache    = {}
    local pcLastCacheUpdate  = 0
    local pcLastTrigger      = nil
    local pcLastComputerTick = 0
    local pcLastCrawlTick    = 0
    local pcIsHacking        = false
    local pcIsCrawling       = false
    local pcConn             = nil

    local crawlAnim = Instance.new("Animation")
    crawlAnim.AnimationId = "rbxassetid://961932719"
    local loadedAnim = nil

    local function pcFireTrigger(triggerPart, state)
        local ev = triggerPart and triggerPart:FindFirstChild("Event")
        if not ev then return end
        pcall(function() Remote:FireServer("Input", "Trigger", state, ev) end)
    end

    local function pcFireAction(state)
        pcall(function() Remote:FireServer("Input", "Action", state) end)
    end

    local function resetCrawl()
        if pcIsCrawling then
            pcall(function() Remote:FireServer("Input", "Crawl", false) end)
            pcIsCrawling = false
        end
        if loadedAnim then loadedAnim:Stop() end
        local hum = player.Character and player.Character:FindFirstChild("Humanoid")
        if hum then hum.HipHeight = 0 end
    end

    local function stealthPop()
        local char = player.Character
        local hum = char and char:FindFirstChild("Humanoid")
        if not hum or pcIsCrawling then return end
        pcIsCrawling = true
        if not loadedAnim then loadedAnim = hum:LoadAnimation(crawlAnim) end
        pcall(function() Remote:FireServer("Input", "Crawl", true) end)
        hum.HipHeight = -2
        loadedAnim:Play()
        task.wait(0.3)
        resetCrawl()
    end

    local function pcUpdateCache()
        pcInteractCache = {}
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("Model") and obj.Name == "ComputerTable" then
                for _, child in ipairs(obj:GetDescendants()) do
                    if child.Name:find("ComputerTrigger") and child:FindFirstChild("Event") then
                        table.insert(pcInteractCache, { Trigger = child, Root = child })
                    end
                end
            end
        end
    end

    local function pcGetNearest()
        local character = player.Character
        local hrp = character and character:FindFirstChild("HumanoidRootPart")
        if not hrp then return nil end
        local closest, minDist = nil, 7
        for _, data in ipairs(pcInteractCache) do
            if data.Trigger and data.Trigger.Parent then
                local dist = (hrp.Position - data.Root.Position).Magnitude
                if dist < minDist then minDist = dist; closest = data end
            end
        end
        return closest
    end

    local function startPCFastHack()
        if pcConn then return end
        pcUpdateCache()
        pcLastCacheUpdate = tick()
        pcConn = RunService.Heartbeat:Connect(function()
            local now = tick()
            if now - pcLastCacheUpdate > 2 then pcUpdateCache(); pcLastCacheUpdate = now end
            local nearest = pcGetNearest()
            if nearest then
                if pcLastTrigger ~= nearest.Trigger then
                    if pcLastTrigger then pcFireTrigger(pcLastTrigger, false) end
                    pcFireTrigger(nearest.Trigger, true)
                    pcLastTrigger = nearest.Trigger
                    pcIsHacking = true
                    pcLastCrawlTick = now
                end
                if now - pcLastComputerTick > 0.1 then
                    pcFireAction(true)
                    pcLastComputerTick = now
                end
                if now - pcLastCrawlTick > 3 then
                    task.spawn(stealthPop)
                    pcLastCrawlTick = now
                end
            else
                if pcLastTrigger then
                    pcFireTrigger(pcLastTrigger, false)
                    pcLastTrigger = nil
                end
                if pcIsHacking then
                    pcIsHacking = false
                    resetCrawl()
                end
            end
        end)
    end

    local function stopPCFastHack()
        if pcConn then pcConn:Disconnect(); pcConn = nil end
        resetCrawl()
        if pcLastTrigger then pcFireTrigger(pcLastTrigger, false); pcLastTrigger = nil end
    end

    miscPage:Toggle({
        Title = "PC Fast Hack",
        Desc  = "Spam-interact with nearby computers only; stealth-crawls every 3s while hacking",
        Value = false,
        Callback = function(v)
            if v then startPCFastHack() else stopPCFastHack() end
        end,
    })
end

-- =============================================
-- 🏃 MOVEMENTS PAGE
-- =============================================
do
    _G.__ZyxMoveHandles = _G.__ZyxMoveHandles or {}
    _G.__ZyxMoveOrbitText = ""

    local function moveCall(method, ...)
        local ctrl = _G.__ZyxGetMovementController and _G.__ZyxGetMovementController()
        if ctrl and ctrl[method] then
            return ctrl[method](...)
        end
    end

    _G.__ZyxMovementPage:Section("Player Movement")
    pcall(function()
        _G.__ZyxMovementPage:Paragraph({
            Title = "Movement Controller",
            Desc  = "Merged from mergethese.lua without its separate UI. Toggle a setting before its slider takes over.",
            Icon  = "move",
        })
    end)

    _G.__ZyxMoveHandles.WalkSpeed = _G.__ZyxMovementPage:Toggle({
        Title = "WalkSpeed",
        Desc  = "Only changes normal walking speed when enabled",
        Value = false,
        Callback = function(v) moveCall("setWalkSpeedEnabled", v) end,
    })
    _G.__ZyxMovementPage:Slider({
        Title = "WalkSpeed Value",
        Min = 1,
        Max = 500,
        Rounding = 0,
        Value = 16,
        Callback = function(v) moveCall("setWalkSpeed", v) end,
    })

    _G.__ZyxMoveHandles.CrawlSpeed = _G.__ZyxMovementPage:Toggle({
        Title = "CrawlSpeed",
        Desc  = "Uses TempPlayerStatsModule.IsCrawling detection",
        Value = false,
        Callback = function(v) moveCall("setCrawlSpeedEnabled", v) end,
    })
    _G.__ZyxMovementPage:Slider({
        Title = "CrawlSpeed Value",
        Min = 1,
        Max = 100,
        Rounding = 0,
        Value = 8,
        Callback = function(v) moveCall("setCrawlSpeed", v) end,
    })

    _G.__ZyxMoveHandles.Jump = _G.__ZyxMovementPage:Toggle({
        Title = "Jump",
        Desc  = "Controls JumpPower or JumpHeight depending on the humanoid",
        Value = false,
        Callback = function(v) moveCall("setJumpEnabled", v) end,
    })
    _G.__ZyxMovementPage:Slider({
        Title = "Jump Value",
        Min = 1,
        Max = 1000,
        Rounding = 0,
        Value = 50,
        Callback = function(v) moveCall("setJumpValue", v) end,
    })

    _G.__ZyxMovementPage:Section("Abilities")
    _G.__ZyxMoveHandles.Fly = _G.__ZyxMovementPage:Toggle({
        Title = "Fly",
        Desc  = "Mobile/keyboard friendly fly movement",
        Value = false,
        Callback = function(v) moveCall("setFlyEnabled", v) end,
    })
    _G.__ZyxMovementPage:Slider({
        Title = "Fly Speed",
        Min = 5,
        Max = 300,
        Rounding = 0,
        Value = 60,
        Callback = function(v) moveCall("setFlySpeed", v) end,
    })
    _G.__ZyxMoveHandles.Noclip = _G.__ZyxMovementPage:Toggle({
        Title = "Noclip",
        Desc  = "Disables collision on your character parts",
        Value = false,
        Callback = function(v) moveCall("setNoclipEnabled", v) end,
    })
    _G.__ZyxMoveHandles.InfiniteJump = _G.__ZyxMovementPage:Toggle({
        Title = "Infinite Jump",
        Desc  = "Jump again from mid-air",
        Value = false,
        Callback = function(v) moveCall("setInfiniteJumpEnabled", v) end,
    })

    _G.__ZyxMovementPage:Section("WallHop")
    _G.__ZyxMoveHandles.WallHop = _G.__ZyxMovementPage:Toggle({
        Title = "WallHop",
        Desc  = "Attempts a 90° flick jump when you press jump against a wall in mid-air",
        Value = false,
        Callback = function(v) moveCall("setWallHopEnabled", v) end,
    })
    _G.__ZyxMovementPage:Slider({
        Title = "WallHop Jump Delay",
        Min = 0.01,
        Max = 1,
        Rounding = 2,
        Value = 0.30,
        Callback = function(v) moveCall("setWallHopJumpDelay", v) end,
    })
    _G.__ZyxMovementPage:Slider({
        Title = "WallHop Flick Speed",
        Min = 0.001,
        Max = 1,
        Rounding = 3,
        Value = 0.03,
        Callback = function(v) moveCall("setWallHopFlickIntensity", v) end,
    })

    _G.__ZyxMovementPage:Section("World")
    _G.__ZyxMoveHandles.Gravity = _G.__ZyxMovementPage:Toggle({
        Title = "Gravity",
        Desc  = "Temporarily overrides Workspace.Gravity",
        Value = false,
        Callback = function(v) moveCall("setGravityEnabled", v) end,
    })
    _G.__ZyxMovementPage:Slider({
        Title = "Gravity Value",
        Min = 0,
        Max = 500,
        Rounding = 1,
        Value = 196.2,
        Callback = function(v) moveCall("setGravity", v) end,
    })

    _G.__ZyxMovementPage:Section("Orbit")
    _G.__ZyxMovementPage:Input({
        Title = "Target Player",
        Desc  = "Partial username or display name",
        Value = "",
        Callback = function(text) _G.__ZyxMoveOrbitText = text or "" end,
    })
    _G.__ZyxMovementPage:Button({
        Title = "Set Orbit Target",
        Desc  = "Finds the closest matching player name",
        Text  = "Set Target",
        Callback = function()
            local name = moveCall("setOrbitTarget", _G.__ZyxMoveOrbitText or "")
            if name then
                Library:Notification({ Title = "Orbit target set", Desc = name, Duration = 3, Type = "Success" })
            else
                Library:Notification({ Title = "Target not found", Desc = "Try a different name.", Duration = 3, Type = "Warning" })
            end
        end,
    })
    _G.__ZyxMoveHandles.Orbit = _G.__ZyxMovementPage:Toggle({
        Title = "Orbit",
        Desc  = "Moves around the selected target",
        Value = false,
        Callback = function(v)
            if v then moveCall("setOrbitTarget", _G.__ZyxMoveOrbitText or "") end
            moveCall("setOrbitEnabled", v)
        end,
    })
    _G.__ZyxMovementPage:Slider({
        Title = "Orbit Radius",
        Min = 2,
        Max = 80,
        Rounding = 0,
        Value = 10,
        Callback = function(v) moveCall("setOrbitRadius", v) end,
    })
    _G.__ZyxMovementPage:Slider({
        Title = "Orbit Height",
        Min = -25,
        Max = 80,
        Rounding = 0,
        Value = 3,
        Callback = function(v) moveCall("setOrbitHeight", v) end,
    })
    _G.__ZyxMovementPage:Slider({
        Title = "Orbit Speed",
        Min = 0,
        Max = 20,
        Rounding = 1,
        Value = 2,
        Callback = function(v) moveCall("setOrbitSpeed", v) end,
    })

    _G.__ZyxMovementPage:Section("AutoFlop")
    do
        local flopXPower = 2.305
        local flopYPower = 0
        local flopZPower = 2.504
        local autoflopEnabled = false
        local RemoteEvent = ReplicatedStorage:WaitForChild("RemoteEvent")

        _G.__ZyxMoveHandles.AutoFlop = _G.__ZyxMovementPage:Toggle({
            Title = "AutoFlop",
            Desc  = "While ragdolled and a Beast is within 15 studs, fires a camera-directional Flop every 0.4s",
            Value = false,
            Callback = function(v)
                autoflopEnabled = v
            end,
        })
        _G.__ZyxMovementPage:Slider({
            Title = "Flop X Power",
            Min = -10, Max = 10, Rounding = 3,
            Value = flopXPower,
            Callback = function(v) flopXPower = v end,
        })
        _G.__ZyxMovementPage:Slider({
            Title = "Flop Y Power",
            Min = -10, Max = 10, Rounding = 3,
            Value = flopYPower,
            Callback = function(v) flopYPower = v end,
        })
        _G.__ZyxMovementPage:Slider({
            Title = "Flop Z Power",
            Min = -10, Max = 10, Rounding = 3,
            Value = flopZPower,
            Callback = function(v) flopZPower = v end,
        })

        RunService.Heartbeat:Connect(function()
            if not autoflopEnabled then return end
            local stats = player:FindFirstChild("TempPlayerStatsModule")
            if not (stats and stats:FindFirstChild("Ragdoll") and stats.Ragdoll.Value == true) then return end

            local beastNearby = false
            local myHRP = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            if myHRP then
                for _, plr in ipairs(game:GetService("Players"):GetPlayers()) do
                    local pStats = plr:FindFirstChild("TempPlayerStatsModule")
                    if pStats and pStats:FindFirstChild("IsBeast") and pStats.IsBeast.Value == true then
                        local pHRP = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
                        if pHRP and (myHRP.Position - pHRP.Position).Magnitude < 15 then
                            beastNearby = true
                            break
                        end
                    end
                end
            end

            if beastNearby then
                local lookDir  = camera.CFrame.LookVector
                local rightDir = camera.CFrame.RightVector
                local velocity = Vector3.new(
                    (lookDir.X * flopZPower) + (rightDir.X * flopXPower),
                    flopYPower,
                    (lookDir.Z * flopZPower) + (rightDir.Z * flopXPower)
                )
                pcall(function() RemoteEvent:FireServer("Flop", velocity) end)
                task.wait(0.4)
            end
        end)
    end

    _G.__ZyxMovementPage:Section("Reset")
    _G.__ZyxMovementPage:Button({
        Title = "Reset Movement Defaults",
        Desc  = "Turns movement effects off and restores jump/gravity/collisions",
        Text  = "Reset",
        Callback = function()
            moveCall("reset")
            for _, handle in pairs(_G.__ZyxMoveHandles or {}) do
                pcall(function() handle.Value = false end)
            end
            Library:Notification({ Title = "Movement reset", Desc = "Movement effects were restored.", Duration = 3, Type = "Success" })
        end,
    })
end

miscPage:Section("Olympia")

toggleHandles.streamermode = miscPage:Toggle({
    Title = "Streamer Mode",
    Desc  = "Rename your in-game UI name/level",
    Value = state.streamermode,
    Callback = function(v)
        state.streamermode = v
        Olympia.setStreamerMode(v)
    end,
})

toggleHandles.nohammercooldown = miscPage:Toggle({
    Title = "No Hammer Cooldown",
    Desc  = "Speed up Beast hammer wipe animation",
    Value = state.nohammercooldown,
    Callback = function(v)
        state.nohammercooldown = v
        if v then Olympia.startNoHammerCooldown() else Olympia.stopNoHammerCooldown() end
    end,
})

toggleHandles.silenthack = miscPage:Toggle({
    Title = "Silent Hack",
    Desc  = "Mute typing/error hack sounds",
    Value = state.silenthack,
    Callback = function(v)
        state.silenthack = v
        if v then Olympia.startSilentHack() else Olympia.stopSilentHack() end
    end,
})

toggleHandles.autotie = miscPage:Toggle({
    Title = "Auto Tie",
    Desc  = "Automatically tie nearest player as Beast",
    Value = state.autotie,
    Callback = function(v)
        state.autotie = v
        if v then Olympia.startAutoTie() else Olympia.stopAutoTie() end
    end,
})

-- ─── HIT AURA + TIE AURA ───
do
    local LP_aura  = Players.LocalPlayer

    local hitAuraEnabled = false; local hitAuraRange   = state.hitaurarange or 10
    local autoTieEnabled = false; local tiePlayerRange = 5

    local function startHitAura()
        task.spawn(function()
            while hitAuraEnabled and task.wait(0.15) do
                pcall(function()
                    local LPC = LP_aura.Character
                    local LPR = LPC and LPC:FindFirstChild("HumanoidRootPart")
                    local LHE = LPC and LPC:FindFirstChild("HammerEvent", true)
                    if not (LPC and LPR and LHE) then return end
                    for _, p in pairs(game:GetService("Players"):GetPlayers()) do
                        if p == LP_aura then continue end
                        local S = p:FindFirstChild("TempPlayerStatsModule"); if not S then continue end
                        local R = S:FindFirstChild("Ragdoll"); local C = S:FindFirstChild("Captured")
                        if R and C and not (R.Value or C.Value) then
                            local root = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
                            if root and (root.Position - LPR.Position).Magnitude <= hitAuraRange then
                                LHE:FireServer("HammerHit", root)
                            end
                        end
                    end
                end)
            end
        end)
    end

    local function startTieAura()
        task.spawn(function()
            while autoTieEnabled and task.wait(0.15) do
                pcall(function()
                    local LPC = LP_aura.Character
                    local LPR = LPC and LPC:FindFirstChild("HumanoidRootPart")
                    local LHE = LPC and LPC:FindFirstChild("HammerEvent", true)
                    if not (LPC and LPR and LHE) then return end
                    for _, p in pairs(game:GetService("Players"):GetPlayers()) do
                        if p == LP_aura then continue end
                        local S = p:FindFirstChild("TempPlayerStatsModule"); if not S then continue end
                        local R = S:FindFirstChild("Ragdoll"); local C = S:FindFirstChild("Captured")
                        if R and C and R.Value and not C.Value then
                            local root = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
                            if root and (root.Position - LPR.Position).Magnitude <= tiePlayerRange then
                                LHE:FireServer("HammerTieUp", root, root.Position)
                            end
                        end
                    end
                end)
            end
        end)
    end

    toggleHandles.hitaura = miscPage:Toggle({
        Title = "Hit Aura",
        Desc  = "Auto-hit players in range [Beast only]",
        Value = state.hitaura,
        Callback = function(v)
            state.hitaura  = v
            hitAuraEnabled = v
            if v then startHitAura() end
        end,
    })

    miscPage:Slider({
        Title    = "Hit Aura Range",
        Min      = 5,
        Max      = 50,
        Rounding = 0,
        Value    = state.hitaurarange,
        Callback = function(v)
            state.hitaurarange = v
            hitAuraRange       = v
        end,
    })

    miscPage:Toggle({
        Title = "Tie Aura",
        Desc  = "Auto-tie ragdolled players in range [Beast only]",
        Value = false,
        Callback = function(v)
            autoTieEnabled = v
            if v then startTieAura() end
        end,
    })

    miscPage:Slider({
        Title    = "Tie Aura Range",
        Min      = 5,
        Max      = 100,
        Rounding = 0,
        Value    = tiePlayerRange,
        Callback = function(v)
            tiePlayerRange = v
        end,
    })
end
-- ─── ADMIN JOIN NOTIFY ───
miscPage:Section("Utilities")

do
    local creId    = game.CreatorId
    local creType  = game.CreatorType
    local adminNotifyConn = nil

    miscPage:Toggle({
        Title = "Admin Join Notify",
        Desc  = "Notifies you when a Mod/Admin or game owner joins",
        Value = false,
        Callback = function(v)
            if v then
                adminNotifyConn = task.spawn(function()
                    while v do
                        task.wait(2.5)
                        for _, p in pairs(game:GetService("Players"):GetPlayers()) do
                            if creType == Enum.CreatorType.Group then
                                pcall(function()
                                    local rank = p:GetRankInGroup(creId)
                                    if rank >= 2 then
                                        local role = p:GetRoleInGroup(creId)
                                        Library:Notify({
                                            Title   = p.Name .. " joined!",
                                            Desc    = "Role: " .. role .. " | Rank: " .. rank,
                                            Icon    = "user-check",
                                            Duration = 5,
                                        })
                                    end
                                end)
                            elseif creType == Enum.CreatorType.User and p.UserId == creId then
                                Library:Notify({
                                    Title   = p.Name .. " joined!",
                                    Desc    = "Role: Game Owner",
                                    Icon    = "user-check",
                                    Duration = 5,
                                })
                            end
                        end
                    end
                end)
            else
                if adminNotifyConn then
                    task.cancel(adminNotifyConn)
                    adminNotifyConn = nil
                end
                v = false
            end
        end,
    })
end

-- ─── ANTI RAGDOLL ───
do
    local antiRagdollConn = nil

    miscPage:Toggle({
        Title = "Anti Ragdoll",
        Desc  = "Prevents your character from ragdolling locally",
        Value = false,
        Callback = function(v)
            if v then
                antiRagdollConn = RunService.Heartbeat:Connect(function()
                    pcall(function()
                        local char = player.Character
                        if not char then return end
                        local hum = char:FindFirstChildOfClass("Humanoid")
                        if not hum then return end
                        hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
                        hum:SetStateEnabled(Enum.HumanoidStateType.Physics, false)
                        hum:SetStateEnabled(Enum.HumanoidStateType.PlatformStanding, false)
                        local stats = player:FindFirstChild("TempPlayerStatsModule")
                        local ragdollVal = stats and stats:FindFirstChild("Ragdoll")
                        if ragdollVal and ragdollVal.Value then
                            hum:ChangeState(6)
                            hum:ChangeState(8)
                        end
                    end)
                end)
            else
                if antiRagdollConn then
                    antiRagdollConn:Disconnect()
                    antiRagdollConn = nil
                end
            end
        end,
    })
end

-- ─── ANTI FLING ───
do
    local antiFlingConn = nil

    miscPage:Toggle({
        Title = "Anti Fling",
        Desc  = "Removes collision on other players so they can't fling you",
        Value = false,
        Callback = function(v)
            if v then
                antiFlingConn = RunService.Heartbeat:Connect(function()
                    for _, p in pairs(game:GetService("Players"):GetPlayers()) do
                        if p ~= player and p.Character then
                            for _, part in pairs(p.Character:GetDescendants()) do
                                if part:IsA("BasePart") and part.CanCollide then
                                    part.CanCollide = false
                                end
                            end
                        end
                    end
                end)
            else
                if antiFlingConn then
                    antiFlingConn:Disconnect()
                    antiFlingConn = nil
                end
            end
        end,
    })
end

-- ─── NOCLIP ───
do
    local noclipConn = nil

    miscPage:Toggle({
        Title = "Noclip",
        Desc  = "Walk through walls and objects",
        Value = false,
        Callback = function(v)
            if v then
                noclipConn = RunService.Heartbeat:Connect(function()
                    local char = player.Character
                    if not char then return end
                    for _, part in pairs(char:GetDescendants()) do
                        if part:IsA("BasePart") and part.CanCollide then
                            part.CanCollide = false
                        end
                    end
                end)
            else
                if noclipConn then
                    noclipConn:Disconnect()
                    noclipConn = nil
                end
            end
        end,
    })
end

-- ─── TOUCH FLING ───
do
    local touchFlingActive = false

    miscPage:Toggle({
        Title = "Touch Fling",
        Desc  = "Fling nearby players by touching them",
        Value = false,
        Callback = function(v)
            touchFlingActive = v
            if v then
                task.spawn(function()
                    while touchFlingActive do
                        local char = player.Character
                        local root = char and char:FindFirstChild("HumanoidRootPart")
                        if root then
                            local vel = root.Velocity
                            root.Velocity = (vel * 9e8) + Vector3.new(0, 9e8, 0)
                            RunService.RenderStepped:Wait()
                            if root then root.Velocity = vel end
                            RunService.Stepped:Wait()
                            if root then
                                root.Velocity = vel + Vector3.new(0, 0.05, 0)
                            end
                        end
                        RunService.Heartbeat:Wait()
                    end
                end)
            end
        end,
    })
end

-- =============================================
-- 🔥 RAGE PAGE
-- =============================================
ragePage:Section("Olympia")

toggleHandles.forcebeastability = ragePage:Toggle({
    Title = "Force Beast Ability",
    Desc  = "Force the Beast ability input remotely",
    Value = state.forcebeastability,
    Callback = function(v)
        state.forcebeastability = v
        if v then Olympia.startForceBeastAbility() else Olympia.stopForceBeastAbility() end
    end,
})

toggleHandles.slowbeast = ragePage:Toggle({
    Title = "Slow Beast",
    Desc  = "Repeatedly fires Beast jump power event",
    Value = state.slowbeast,
    Callback = function(v)
        state.slowbeast = v
        if v then Olympia.startSlowBeast() else Olympia.stopSlowBeast() end
    end,
})

toggleHandles.removerope = ragePage:Toggle({
    Title = "Remove Rope",
    Desc  = "Attempts to drop carried survivors",
    Value = state.removerope,
    Callback = function(v)
        state.removerope = v
        if v then Olympia.startRemoveRope() else Olympia.stopRemoveRope() end
    end,
})


-- =============================================
-- 😂 FUN PAGE  (RB BeastTool — Bang & Jerk)
-- =============================================
-- ── Raw variables ─────────────────────────
local bangEnabled    = false
local jerkEnabled    = false

local bangOffset     = 1.1
local bangAnimSpeed  = 1.0
local jerkAnimSpeed  = 1.0
local jerkOffset     = 1.1

local bangCon        = nil
local bangSavedPos   = nil

local bangTrack1     = nil
local bangTrack2     = nil
local bangAnimLoop   = nil
local currentbangAnim = 1
local jerkTrack      = nil
local jerkAnimCon    = nil
local jerkAccum      = 0

-- ── Beast finder (reuses zyxlab detection) ─
local function RB_GetTargetPlayer()
    for _, p in ipairs(game:GetService("Players"):GetPlayers()) do
        if p == player then continue end
        local function checkStats(obj)
            if not obj then return false end
            local s = obj:FindFirstChild("TempPlayerStatsModule")
            return s and s:FindFirstChild("IsBeast") and s.IsBeast.Value
        end
        if checkStats(p) or checkStats(p.Character) then return p end
    end
    return nil
end

-- ── bang animation helpers ─────────────────
local function StopBangAnim()
    if bangAnimLoop then task.cancel(bangAnimLoop) bangAnimLoop = nil end
    if bangTrack1 then bangTrack1:Stop() bangTrack1 = nil end
    if bangTrack2 then bangTrack2:Stop() bangTrack2 = nil end
end

local function StartBangAnimLoop(humanoid)
    if not humanoid then return end
    if bangAnimLoop then task.cancel(bangAnimLoop) bangAnimLoop = nil end

    if not bangTrack1 then
        local a1 = Instance.new("Animation")
        a1.AnimationId = "rbxassetid://215262147"
        bangTrack1 = humanoid:LoadAnimation(a1)
        bangTrack1.Priority = Enum.AnimationPriority.Action4
    end
    if not bangTrack2 then
        local a2 = Instance.new("Animation")
        a2.AnimationId = "rbxassetid://185299570"
        bangTrack2 = humanoid:LoadAnimation(a2)
        bangTrack2.Priority = Enum.AnimationPriority.Action4
    end

    local function cycle()
        if not bangEnabled then return end
        currentBangAnim = (currentBangAnim == 1) and 2 or 1
        if currentBangAnim == 1 then
            if bangTrack2 then bangTrack2:Stop() end
            bangTrack1:AdjustSpeed(bangAnimSpeed)
            bangTrack1:Play(0)
        else
            if bangTrack1 then bangTrack1:Stop() end
            bangTrack2:AdjustSpeed(bangAnimSpeed)
            bangTrack2:Play(0)
        end
        local interval = 0.5 / math.max(bangAnimSpeed, 0.1)
        bangAnimLoop = task.delay(interval, cycle)
    end
    cycle()
end

-- ── Bang core ──────────────────────────────
local function StopBang()
    if bangCon then bangCon:Disconnect() bangCon = nil end
    StopBangAnim()
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if root and bangSavedPos then
        root.CFrame = bangSavedPos
        pcall(function() sethiddenproperty(root, "PhysicsRepRootPart", nil) end)
    end
    bangSavedPos = nil
end

local function StartBang()
    if bangCon then bangCon:Disconnect() end
    local target = RB_GetTargetPlayer()
    local char   = player.Character
    local root   = char and char:FindFirstChild("HumanoidRootPart")
    local hum    = char and char:FindFirstChildOfClass("Humanoid")
    if not target or not root or not hum then
        Library:Notify({ Title = "Bang", Desc = "Beast not found!", Icon = "laugh", Duration = 3 })
        bangEnabled = false
        return
    end
    bangSavedPos = root.CFrame
    StartBangAnimLoop(hum)
    bangCon = RunService.Heartbeat:Connect(function()
        if not root.Parent or hum.Health <= 0 then StopBang() return end
        local tChar = target.Character
        if not tChar then return end
        local tRoot = tChar:FindFirstChild("HumanoidRootPart")
        if not tRoot then return end
        pcall(function() sethiddenproperty(root, "PhysicsRepRootPart", tRoot) end)
        root.CFrame = tRoot.CFrame * CFrame.new(0, 0, bangOffset)
        root.Velocity = Vector3.zero
        root.AssemblyLinearVelocity = Vector3.zero
    end)
end

-- ── Jerk core ──────────────────────────────
local function StopJerk()
    if jerkAnimCon then jerkAnimCon:Disconnect() jerkAnimCon = nil end
    if jerkTrack then jerkTrack:Stop() jerkTrack = nil end
    if bangCon and jerkEnabled then bangCon:Disconnect() bangCon = nil end
end

local function PlayJerkAnim(humanoid)
    if jerkTrack then jerkTrack:Stop() end
    local anim = Instance.new("Animation")
    local isR15 = humanoid.RigType == Enum.HumanoidRigType.R15
    anim.AnimationId = isR15 and "rbxassetid://698251653" or "rbxassetid://72042024"
    jerkTrack = humanoid:LoadAnimation(anim)
    jerkTrack.Priority = Enum.AnimationPriority.Action4
    jerkTrack:Play(0.1)
    jerkTrack:AdjustSpeed(jerkAnimSpeed)
    jerkTrack.TimePosition = 0.6
end

local function StartJerk(humanoid)
    if jerkAnimCon then jerkAnimCon:Disconnect() end
    PlayJerkAnim(humanoid)
    jerkAccum = 0
    local isR15 = humanoid.RigType == Enum.HumanoidRigType.R15

    local target = RB_GetTargetPlayer()
    local char   = player.Character
    local root   = char and char:FindFirstChild("HumanoidRootPart")
    if target and root then
        if bangCon then bangCon:Disconnect() end
        bangSavedPos = root.CFrame
        bangCon = RunService.Heartbeat:Connect(function()
            if not jerkEnabled then return end
            local tChar = target.Character
            if not tChar then return end
            local tRoot = tChar:FindFirstChild("HumanoidRootPart")
            if not tRoot then return end
            local torso = tChar:FindFirstChild("UpperTorso") or tChar:FindFirstChild("Torso") or tRoot
            pcall(function() sethiddenproperty(root, "PhysicsRepRootPart", tRoot) end)
            root.CFrame = torso.CFrame * CFrame.new(0, 0, -jerkOffset) * CFrame.Angles(0, math.pi, 0)
            root.Velocity = Vector3.zero
            root.AssemblyLinearVelocity = Vector3.zero
        end)
    end

    jerkAnimCon = RunService.Heartbeat:Connect(function(dt)
        if not jerkEnabled then return end
        if not jerkTrack or not jerkTrack.IsPlaying then
            PlayJerkAnim(humanoid)
            return
        end
        jerkAccum += dt
        if jerkAccum >= 0.2 then
            local maxPos = isR15 and 0.7 or 0.65
            if jerkTrack.TimePosition >= maxPos then
                jerkTrack:Stop()
                jerkAccum = 0
            end
        end
    end)
end

-- ── Respawn handler ────────────────────────
player.CharacterAdded:Connect(function()
    task.wait(1.5)
    local hum = player.Character:WaitForChild("Humanoid", 3)
    if bangEnabled then StartBang() end
    if jerkEnabled and hum then StartJerk(hum) end
end)

-- ── Remote Hack & Remote Exit Door — Logic ──────────────────────────────────

local smRemoteHackOn      = false
local smRemoteHackThread  = nil
local smTriggerSend       = false
local smBlocking          = false
local smRemoteRef         = nil
local smHookDone          = false

local smOpenExitsOn       = false
local smOpenExitsThread   = nil

local function sm_getRemote()
    local ev = ReplicatedStorage:FindFirstChild("RemoteEvent")
    if ev and ev:IsA("RemoteEvent") then return ev end
end

local function sm_scanMap()
    local cur = ReplicatedStorage:FindFirstChild("CurrentMap")
    local val = cur and cur.Value
    if typeof(val) == "Instance" then return val end
    return typeof(val) == "string" and val ~= "" and workspace:FindFirstChild(val) or nil
end

local function sm_isActive()
    local v = ReplicatedStorage:FindFirstChild("IsGameActive")
    return v and v:IsA("BoolValue") and v.Value == true
end

local function sm_localStats()
    return player:FindFirstChild("TempPlayerStatsModule")
end

local function sm_isTyping()
    local stats = sm_localStats()
    local anim  = stats and stats:FindFirstChild("CurrentAnimation")
    return anim and anim:IsA("StringValue") and anim.Value == "Typing"
end

local function sm_isBeast()
    local stats = sm_localStats()
    local ib    = stats and stats:FindFirstChild("IsBeast")
    return ib and ib:IsA("BoolValue") and ib.Value == true
end

local function sm_isEscaped()
    local stats = sm_localStats()
    local esc   = stats and stats:FindFirstChild("Escaped")
    return esc and esc:IsA("BoolValue") and esc.Value == true
end

local function sm_exitLight(door)
    return door:FindFirstChild("Light") or door:FindFirstChild("Light", true)
end

local function sm_exitOpen(door)
    local light = sm_exitLight(door)
    if not light then return false end
    local ok, color = pcall(function() return light.Color end)
    return ok and color == Color3.fromRGB(0, 255, 0)
end

local function sm_exitTriggerEvent(door)
    local trigger = door:FindFirstChild("ExitDoorTrigger") or door:FindFirstChild("ExitDoorTrigger", true)
    return trigger and (trigger:FindFirstChild("Event") or nil)
end

local function sm_fireRemoteAction(event)
    local ev = sm_getRemote()
    if not ev or not event then return false end
    ev:FireServer("Input", "Trigger", true, event)
    task.wait(0.3)
    ev:FireServer("Input", "Action", true)
    return true
end

-- Manual Remote Hack — hook (integrates with existing oldnc hook gracefully)
local function sm_hookBlock()
    if smHookDone or not hookmetamethod or not getnamecallmethod then return end
    smHookDone = true
    local prev = oldnc  -- chain into zyxlab's existing __namecall hook
    local fn = newcclosure(function(self, ...)
        if smRemoteHackOn and smBlocking and self == smRemoteRef
            and not smTriggerSend and getnamecallmethod() == "FireServer" then
            local a1, a2 = ...
            if a1 == "Input" and a2 == "Trigger" then return nil end
        end
        return prev(self, ...)
    end)
    local ok, res = pcall(hookmetamethod, game, "__namecall", fn)
    if ok then oldnc = res else smHookDone = false end
end

local function setSmRemoteHack(state)
    smRemoteHackOn = state
    if not state then
        smRemoteRef   = nil
        smTriggerSend = false
        smBlocking    = false
        return
    end
    smRemoteRef = sm_getRemote()
    sm_hookBlock()
    if smRemoteHackThread then return end
    smRemoteHackThread = task.spawn(function()
        while smRemoteHackOn do
            local active = sm_isTyping()
                and sm_isActive()
                and not sm_isBeast()
                and not sm_isEscaped()
            smBlocking = active
            if active then
                local ev = smRemoteRef
                if not ev or not ev:IsDescendantOf(game) then
                    ev = sm_getRemote(); smRemoteRef = ev
                end
                if ev then
                    local map = sm_scanMap()
                    smTriggerSend = true
                    if map then ev:FireServer("Input", "Trigger", true, map)
                    else        ev:FireServer("Input", "Trigger", true) end
                    smTriggerSend = false
                end
                task.wait(0.25)
            else
                task.wait(0.2)
            end
        end
        smRemoteRef = nil; smTriggerSend = false; smBlocking = false
        smRemoteHackThread = nil
    end)
end

local function smOpenExitsOnce()
    local map = sm_scanMap()
    if not map then return end
    for _, obj in ipairs(map:GetChildren()) do
        if obj.Name == "ExitDoor" and obj:IsDescendantOf(workspace) and not sm_exitOpen(obj) then
            sm_fireRemoteAction(sm_exitTriggerEvent(obj))
            task.wait(0.1)
        end
    end
end

local function setSmOpenExits(state)
    smOpenExitsOn = state
    if not state then
        if smOpenExitsThread then
            smOpenExitsThread = nil
        end
        return
    end
    if smOpenExitsThread then return end
    smOpenExitsThread = task.spawn(function()
        while smOpenExitsOn do
            if sm_isActive() and not sm_isBeast() then
                smOpenExitsOnce()
            end
            task.wait(2)
        end
        smOpenExitsThread = nil
    end)
end

-- ── Fun Page UI ────────────────────────────
funPage:Section("Fun")

pcall(function()
    funPage:Paragraph({
        Title = "Bang & Jerk",
        Desc  = "Attach to the Beast and Rape.",
        Icon  = "laugh",
    })
end)

funPage:Toggle({
    Title = "Bang",
    Desc  = "Glue yourself behind the Beast",
    Value = false,
    Callback = function(v)
        bangEnabled = v
        if v then
            StartBang()
        else
            StopBang()
        end
    end,
})

funPage:Slider({
    Title    = "Bang — Behind Offset",
    Min      = 0,
    Max      = 20,
    Rounding = 1,
    Value    = bangOffset,
    Callback = function(v)
        bangOffset = v
    end,
})

funPage:Slider({
    Title    = "Bang — Anim Speed",
    Min      = 0.1,
    Max      = 10,
    Rounding = 1,
    Value    = bangAnimSpeed,
    Callback = function(v)
        bangAnimSpeed = v
        if bangTrack1 then bangTrack1:AdjustSpeed(bangAnimSpeed) end
        if bangTrack2 then bangTrack2:AdjustSpeed(bangAnimSpeed) end
    end,
})

funPage:Section("Fun")

funPage:Toggle({
    Title = "Jerk",
    Desc  = "Dive in front of the Beast and Jerk",
    Value = false,
    Callback = function(v)
        jerkEnabled = v
        local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if v and hum then
            StartJerk(hum)
        else
            StopJerk()
        end
    end,
})

funPage:Slider({
    Title    = "Jerk — Front Offset",
    Min      = 0,
    Max      = 20,
    Rounding = 1,
    Value    = jerkOffset,
    Callback = function(v)
        jerkOffset = v
    end,
})

funPage:Slider({
    Title    = "Jerk — Anim Speed",
    Min      = 0.1,
    Max      = 10,
    Rounding = 1,
    Value    = jerkAnimSpeed,
    Callback = function(v)
        jerkAnimSpeed = v
        if jerkTrack then jerkTrack:AdjustSpeed(jerkAnimSpeed) end
    end,
})

funPage:Section("Remote Tools")

pcall(function()
    funPage:Paragraph({
        Title = "Remote Hack & Exit Doors",
        Desc  = "Auto-fires hack trigger while typing at a computer. Open Exit fires all closed exit doors remotely.",
        Icon  = "zap",
    })
end)

funPage:Toggle({
    Title = "Manual Remote Hack",
    Desc  = "Auto-fires hack input while you are typing at a computer",
    Value = false,
    Callback = function(v)
        setSmRemoteHack(v)
    end,
})

funPage:Toggle({
    Title = "Remote Open Exit Doors",
    Desc  = "Continuously fires all closed Exit Doors open every 2 seconds",
    Value = false,
    Callback = function(v)
        setSmOpenExits(v)
    end,
})

-- =============================================
-- 🏁 END GAME PAGE
-- =============================================
do
    endGamePage:Section("Force End Round")
    pcall(function()
        endGamePage:Paragraph({
            Title = "How it works",
            Desc  = "Glitches your character onto the Beast every frame and spams the Beast's ability to slow them down. When the Beast's health reaches 0, your character auto-resets to end the round.",
            Icon  = "info",
        })
    end)

    do
        -- Persistent connection handles so the toggle cleanly starts/stops.
        local eg_slowConn, eg_mainConn
        local eg_lastBeast = nil

        local function eg_findBeast()
            for _, plr in pairs(game:GetService("Players"):GetPlayers()) do
                local stats = plr:FindFirstChild("TempPlayerStatsModule")
                local char  = plr.Character
                if (stats and stats:FindFirstChild("IsBeast") and stats.IsBeast.Value)
                or (char  and char:FindFirstChild("BeastPowers")) then
                    return plr
                end
            end
            return nil
        end

        local function eg_resetChar()
            pcall(function()
                local char = Players.LocalPlayer.Character
                if not char then return end
                local hum = char:FindFirstChild("Humanoid")
                if hum then
                    hum:ChangeState(Enum.HumanoidStateType.Dead)
                else
                    char:BreakJoints()
                end
            end)
        end

        local function eg_stopAll()
            if eg_slowConn then pcall(function() eg_slowConn:Disconnect() end); eg_slowConn = nil end
            if eg_mainConn then pcall(function() eg_mainConn:Disconnect() end); eg_mainConn = nil end
            eg_lastBeast = nil
        end

        local function eg_start()
            eg_stopAll()  -- clear any lingering connections first
            local RS = RunService
            local lp = Players.LocalPlayer

            eg_slowConn = RS.Heartbeat:Connect(function()
                pcall(function()
                    local beast     = eg_findBeast()
                    local beastChar = beast and beast.Character
                    if not beastChar then return end
                    local powers = beastChar:FindFirstChild("BeastPowers", true)
                    if powers then
                        local pe = powers:FindFirstChild("PowersEvent", true)
                        if pe then pcall(function() pe:FireServer("Jumped") end) end
                    end
                end)
            end)

            eg_mainConn = RS.RenderStepped:Connect(function()
                pcall(function()
                    local char     = lp.Character
                    local beastPlr = eg_findBeast()
                    if beastPlr then eg_lastBeast = beastPlr end
                    local activeBeast     = beastPlr or eg_lastBeast
                    local activeBeastChar = activeBeast and activeBeast.Character

                    if not char or not activeBeastChar then
                        if eg_lastBeast then
                            eg_stopAll()
                            eg_resetChar()
                        end
                        return
                    end

                    local hrp  = char:FindFirstChild("HumanoidRootPart")
                    local hum  = char:FindFirstChild("Humanoid")
                    local bHrp = activeBeastChar:FindFirstChild("HumanoidRootPart")
                    local bHum = activeBeastChar:FindFirstChild("Humanoid")

                    if hrp and hum and bHrp and bHum and bHum.Health > 0 then
                        hum.PlatformStand = true
                        for _, v in pairs(char:GetChildren()) do
                            if v:IsA("BasePart") then v.Massless = true end
                        end
                        local jitter = Vector3.new(math.sin(tick()*100)/100, 0, math.cos(tick()*100)/100)
                        pcall(function()
                            hrp.CFrame = (bHrp.CFrame + jitter) * CFrame.Angles(0, math.rad(tick()*100000 % 360), 0)
                            local NaN    = 0/0
                            local nanVec = Vector3.new(NaN, NaN, NaN)
                            hrp.Velocity    = nanVec
                            hrp.RotVelocity = nanVec
                            hum:Move(nanVec)
                        end)
                    else
                        eg_stopAll()
                        eg_resetChar()
                    end
                end)
            end)
        end

        endGamePage:Toggle({
            Title    = "Activate End Game",
            Desc     = "Glitch to Beast position until Beast dies, then reset your character. Toggle off to stop early.",
            Value    = false,
            Callback = function(v)
                if v then
                    eg_start()
                else
                    eg_stopAll()
                    -- restore PlatformStand in case it was left on
                    pcall(function()
                        local char = Players.LocalPlayer.Character
                        local hum  = char and char:FindFirstChild("Humanoid")
                        if hum then hum.PlatformStand = false end
                    end)
                end
            end,
        })
    end
end

-- =============================================
-- 🌾 AUTOFARMS PAGE
-- =============================================
-- Persists between button runs so pods don't get double-assigned.
local occupiedPods = {}

do
    autofarmsPage:Section("Beast Farming")
    pcall(function()
        autofarmsPage:Paragraph({
            Title = "Autofarm Beast",
            Desc  = "Continuously targets free survivors: teleports behind them, hammers + ties them up, then freezes them in an empty FreezePod. Toggle off to stop. Only works when you are the Beast.",
            Icon  = "info",
        })
    end)

    -- ── sippin' milk auto-beast logic (merged) ────────────────────────────────
    do
        local ab_active      = false
        local ab_thread      = nil
        local ab_podFail     = {}
        local ab_podSkip     = {}
        local ab_beastWhitelist = {}

        local function ab_bval(obj)
            if obj and obj:IsA("BoolValue") then return obj.Value == true end
            return false
        end
        local function ab_nval(obj)
            if obj and (obj:IsA("NumberValue") or obj:IsA("IntValue")) then return obj.Value end
        end
        local function ab_sval(obj)
            if obj and obj:IsA("StringValue") then return obj.Value end
        end
        local function ab_anyBool(obj)
            if not obj then return false end
            local ok, val = pcall(function() return obj.Value end)
            if ok then return val == true or val == "true" or val == 1 end
            return false
        end

        local function ab_localPlayer() return Players.LocalPlayer end
        local function ab_rootPart()
            local char = ab_localPlayer().Character
            return char and char:FindFirstChild("HumanoidRootPart")
        end
        local function ab_localBeast()
            local stats = ab_localPlayer():FindFirstChild("TempPlayerStatsModule")
            return ab_anyBool(stats and stats:FindFirstChild("IsBeast"))
        end
        local function ab_playerRoot(plr)
            local char = plr and plr.Character
            return char and char:FindFirstChild("HumanoidRootPart")
        end
        local function ab_playerAlive(plr)
            local stats = plr and plr:FindFirstChild("TempPlayerStatsModule")
            local hp    = ab_nval(stats and stats:FindFirstChild("Health"))
            return hp == nil or hp > 0
        end
        local function ab_whitelisted(plr)
            return plr and ab_beastWhitelist[plr.Name] == true
        end

        -- scan active beast from zyxlab's existing helper
        local function ab_scanBeast()
            for _, plr in ipairs(game:GetService("Players"):GetPlayers()) do
                local stats   = plr:FindFirstChild("TempPlayerStatsModule")
                local isBeast = stats and stats:FindFirstChild("IsBeast")
                if ab_bval(isBeast) then return plr end
            end
        end
        local function ab_scanMap()
            local rs  = game:GetService("ReplicatedStorage")
            local cur = rs:FindFirstChild("CurrentMap")
            local val = cur and cur.Value
            if typeof(val) == "Instance" then return val end
            if type(val) ~= "string" or val == "" then return nil end
            return workspace:FindFirstChild(val)
        end
        local function ab_scanPods(map)
            local out = {}
            if not map then return out end
            for _, obj in ipairs(map:GetChildren()) do
                if obj.Name == "FreezePod" then out[#out+1] = obj end
            end
            return out
        end

        local function ab_triggerPart(trigger)
            if not trigger then return nil end
            if trigger:IsA("BasePart") then return trigger end
            if trigger:IsA("Model") then
                return trigger.PrimaryPart or trigger:FindFirstChildWhichIsA("BasePart", true)
            end
            return trigger:FindFirstChildWhichIsA("BasePart", true)
        end
        local function ab_podTrigger(pod)
            local t = pod and pod:FindFirstChild("PodTrigger")
            if not t then t = pod and pod:FindFirstChild("PodTrigger", true) end
            return t
        end
        local function ab_capturedPod(pod)
            local trigger = ab_podTrigger(pod)
            local cap     = trigger and trigger:FindFirstChild("CapturedTorso")
            if not cap then return false end
            local ok, val = pcall(function() return cap.Value end)
            if ok then
                if typeof(val) == "Instance" then return val ~= nil end
                if type(val)   == "string"   then return val ~= ""  end
                return val ~= nil and val ~= false
            end
            return true
        end

        local function ab_skipFor(tbl, key, time)
            if key then tbl[key] = os.clock() + (time or 8) end
        end
        local function ab_skipped(tbl, key)
            local t = key and tbl[key]
            if not t then return false end
            if os.clock() >= t then tbl[key] = nil; return false end
            return true
        end

        local function ab_freePod(pods)
            for _, pod in ipairs(pods) do
                if pod and pod:IsDescendantOf(workspace)
                   and not ab_skipped(ab_podSkip, pod)
                   and not ab_capturedPod(pod) then
                    local part = ab_triggerPart(ab_podTrigger(pod))
                    if part then return pod, part end
                end
            end
        end

        local function ab_findHammerEvent(plr)
            local char   = plr and plr.Character
            if not char then return nil end
            local hammer = char:FindFirstChild("Hammer")
            local ev     = hammer and hammer:FindFirstChild("HammerEvent")
            if ev and ev:IsA("RemoteEvent") then return ev end
            for _, obj in ipairs(char:GetDescendants()) do
                if obj.Name == "HammerEvent" and obj:IsA("RemoteEvent") then return obj end
            end
        end

        local function ab_remote()
            local rs = game:GetService("ReplicatedStorage")
            local ev = rs:FindFirstChild("RemoteEvent")
            if ev and ev:IsA("RemoteEvent") then return ev end
        end

        local function ab_v3(pos)
            if vector and vector.create then
                return vector.create(pos.X, pos.Y, pos.Z)
            end
            return pos
        end

        local function ab_playerCaptured(plr, pods)
            local char = plr and plr.Character
            if not char then return false end
            for _, pod in ipairs(pods) do
                local trigger = ab_podTrigger(pod)
                local cap     = trigger and trigger:FindFirstChild("CapturedTorso")
                if cap then
                    local ok, val = pcall(function() return cap.Value end)
                    if ok and typeof(val) == "Instance" and val:IsDescendantOf(char) then
                        return true
                    end
                    if ok and type(val) == "string" and val:find(plr.Name, 1, true) then
                        return true
                    end
                end
            end
            return false
        end

        -- reads the health bar labels from the local player's GUI to find live targets
        local function ab_activeSurvivors(pods)
            local pgui   = Players.LocalPlayer:FindFirstChild("PlayerGui")
            local screen = pgui and pgui:FindFirstChild("ScreenGui")
            local bars   = screen and screen:FindFirstChild("StatusBars")
            local out, seen = {}, {}
            if not bars then
                -- fallback: iterate all players
                for _, plr in ipairs(game:GetService("Players"):GetPlayers()) do
                    local stats   = plr:FindFirstChild("TempPlayerStatsModule")
                    local isBeast = stats and stats:FindFirstChild("IsBeast")
                    if plr ~= Players.LocalPlayer
                       and not ab_bval(isBeast)
                       and not ab_whitelisted(plr)
                       and ab_playerAlive(plr)
                       and not ab_playerCaptured(plr, pods) then
                        out[#out+1] = plr
                    end
                end
                return out
            end
            for _, id in ipairs({"HealthBarA","HealthBarB","HealthBarC","HealthBarD"}) do
                local label = bars:FindFirstChild(id)
                local name  = label and label.Text
                local plr   = name and Players:FindFirstChild(name)
                if not plr then
                    -- try display name match
                    for _, p in ipairs(game:GetService("Players"):GetPlayers()) do
                        if p.DisplayName == name then plr = p; break end
                    end
                end
                if plr and plr ~= Players.LocalPlayer and not seen[plr]
                   and not ab_whitelisted(plr)
                   and ab_playerAlive(plr)
                   and not ab_playerCaptured(plr, pods) then
                    seen[plr] = true
                    out[#out+1] = plr
                end
            end
            return out
        end

        -- hit + tie a target
        local function ab_beastHitTie(plr)
            local root   = ab_rootPart()
            local target = ab_playerRoot(plr)
            local ev     = ab_findHammerEvent(Players.LocalPlayer)
            if not root or not target or not ev or not ab_playerAlive(plr) then return false end
            root.CFrame = CFrame.new(target.Position + Vector3.new(0, 2.5, 3), target.Position)
            task.wait(0.12)
            ev:FireServer("HammerHit", target)
            task.wait(0.22)
            ev:FireServer("HammerTieUp", target, ab_v3(target.Position))
            return true
        end

        -- teleport into a free pod to freeze the player
        local function ab_beastFreeze(plr, pods)
            local ev = ab_remote()
            if not ev then return false end
            local tried = {}
            while ab_active and ab_localBeast()
                  and plr and plr.Parent
                  and ab_playerAlive(plr)
                  and not ab_playerCaptured(plr, pods) do
                local pod, part = ab_freePod(pods)
                local root      = ab_rootPart()
                if not pod or not part or not root or tried[pod] then return false end
                tried[pod]  = true
                local pos   = part.Position + part.CFrame.LookVector * 5 + Vector3.new(0, 3, 0)
                root.CFrame = CFrame.new(pos, part.Position)
                task.wait(0.25)
                ev:FireServer("Input", "Action", true)
                task.wait(1)
                if ab_playerCaptured(plr, pods) then
                    ab_podFail[pod] = nil
                    return true
                end
                ab_podFail[pod] = (ab_podFail[pod] or 0) + 1
                if ab_podFail[pod] >= 3 then
                    ab_podFail[pod] = nil
                    ab_skipFor(ab_podSkip, pod, 10)
                else
                    return false
                end
                task.wait(0.15)
            end
            return ab_playerCaptured(plr, pods)
        end

        local function ab_start()
            if ab_thread then return end
            ab_thread = task.spawn(function()
                while ab_active do
                    if ab_localBeast() then
                        local map  = ab_scanMap()
                        local pods = map and ab_scanPods(map) or {}
                        local targets = ab_activeSurvivors(pods)
                        if #targets == 0 then
                            task.wait(0.4)
                        else
                            for _, plr in ipairs(targets) do
                                if not ab_active or not ab_localBeast() then break end
                                if plr.Parent and ab_playerAlive(plr)
                                   and not ab_playerCaptured(plr, pods)
                                   and ab_playerRoot(plr)
                                   and ab_beastHitTie(plr) then
                                    task.wait(0.2)
                                    ab_beastFreeze(plr, pods)
                                end
                                task.wait(0.25)
                            end
                        end
                    else
                        task.wait(0.5)
                    end
                end
                ab_thread = nil
            end)
        end

        local function ab_stop()
            ab_active = false
            for pod in pairs(ab_podFail)  do ab_podFail[pod]  = nil end
            for pod in pairs(ab_podSkip)  do ab_podSkip[pod]  = nil end
        end

        -- initialise whitelist with local player so they are never targeted
        do
            local lp = Players.LocalPlayer
            if lp then ab_beastWhitelist[lp.Name] = true end
        end

        autofarmsPage:Toggle({
            Title    = "Autofarm Beast [Blatant]",
            Desc     = "Continuously hammers, ties, and freezes free survivors. Toggle off to stop. Only active while you are the Beast.",
            Value    = false,
            Callback = function(v)
                if v then
                    ab_active = true
                    ab_start()
                else
                    ab_stop()
                end
            end,
        })
    end
    -- ── end auto-beast block ──────────────────────────────────────────────────

    -- ── Survivor Farming ──────────────────────────────────────────────────────
    autofarmsPage:Section("Survivor Farming")
    pcall(function()
        autofarmsPage:Paragraph({
            Title = "Survivor Farming Suite",
            Desc  = "All-in-one survivor tools: Auto Hack computers, Auto Exit when doors open, and Avoid Beast proximity. Click the button below to open the control panel.",
            Icon  = "info",
        })
    end)

    toggleHandles.autosavecaptured = autofarmsPage:Toggle({
        Title = "Auto Save Captured [Remote]",
        Desc  = "Silently saves players frozen in FreezePods",
        Value = state.autosavecaptured,
        Callback = function(v)
            state.autosavecaptured = v
        end,
    })

    -- ── AIO Sub-Page Button ───────────────────────────────────────────────────
    autofarmsPage:Button({
        Title    = "Open Survivor Autofarm [Blatant] Panel",
        Desc     = "Auto Hack · Auto Exit · Avoid Beast — opens a draggable control panel",
        Text     = "⚡ Open Panel",
        Callback = function()
            if _G.__ZyxOpenSurvivorAIO then _G.__ZyxOpenSurvivorAIO() end
        end,
    })

    autofarmsPage:Button({
        Title    = "Open Pathfind Survivor Panel",
        Desc     = "Pathfinding farm · Auto Exit · Avoid Beast (hover) — beta",
        Text     = "⚡ Open Panel",
        Callback = function()
            if _G.__ZyxOpenPathFarm then _G.__ZyxOpenPathFarm() end
        end,
    })
end

-- ─────────────────────────────────────────────────────────────────────────────
-- ⚡ SURVIVOR AIO MODULE (Auto Hack + Auto Exit + Avoid Beast)
-- Logic extracted from autofarmautoexitavoidbeast.lua — no external UI/key auth.
-- Opened as a ZyxLab-style draggable overlay sub-page via the button above.
-- ─────────────────────────────────────────────────────────────────────────────
do
    -- ── Runtime state ────────────────────────────────────────────────────────
    local aioRt = {
        alive         = true,
        active        = false,
        beast         = nil,
        powersEvent   = nil,
        localBeast    = false,
        map           = nil,
        computers     = {},
        pods          = {},
        exits         = {},
        escaped       = false,
        escapeTried   = false,
        computersLeft = nil,
        mapCache      = nil,
        mapScanAt     = 0,
        powersCache   = nil,
        powersScanAt  = 0,
        hackWaitPaid  = false,
        hackWaitComp  = nil,
        hackWaitUntil = 0,
        hackShortWait = false,
    }

    local aio = {
        autoHack   = false,
        autoExit   = false,
        avoidBeast = false,
    }

    local skip = { hack = {}, exit = {} }
    local AVOID_RANGE = 18.7
    local hackTarget  = nil
    local hackMarker  = nil
    local hackFirst   = true
    local aioThread   = nil
    local nextEscapeTry = 0

    -- ── Utility ──────────────────────────────────────────────────────────────
    local util = {}
    function util.rootPart()
        local char = player.Character
        return char and char:FindFirstChild("HumanoidRootPart")
    end
    function util.beastRoot()
        local char = aioRt.beast and aioRt.beast.Character
        return char and char:FindFirstChild("HumanoidRootPart")
    end
    function util.beastNear(pos, range)
        if not aio.avoidBeast or not pos then return false end
        local root = util.beastRoot()
        return root and (root.Position - pos).Magnitude <= (range or 10)
    end
    function util.beastNearLocal()
        local root = util.rootPart()
        return root and util.beastNear(root.Position, AVOID_RANGE)
    end
    function util.skipFor(tbl, key2, time)
        if key2 then tbl[key2] = os.clock() + (time or 8) end
    end
    function util.skipped(tbl, key2)
        local t = key2 and tbl[key2]
        if not t then return false end
        if os.clock() >= t then tbl[key2] = nil; return false end
        return true
    end
    function util.instPos(inst)
        if not inst then return nil end
        if inst:IsA("BasePart") then return inst.Position end
        if inst:IsA("Model") then
            local p = inst.PrimaryPart or inst:FindFirstChildWhichIsA("BasePart", true)
            return p and p.Position
        end
        local p = inst:FindFirstChildWhichIsA("BasePart", true)
        return p and p.Position
    end
    function util.localDist(pos)
        local root = util.rootPart()
        return root and pos and (root.Position - pos).Magnitude
    end
    function util.hackWaitTime(dist)
        return 10 + ((tonumber(dist) or 0) / 20)
    end
    function util.remote()
        local ev = ReplicatedStorage:FindFirstChild("RemoteEvent")
        if ev and ev:IsA("RemoteEvent") then return ev end
    end
    function util.localStats()
        return player:FindFirstChild("TempPlayerStatsModule")
    end
    function util.localTyping()
        local stats = util.localStats()
        local anim  = stats and stats:FindFirstChild("CurrentAnimation")
        return anim and anim.Value == "Typing"
    end
    function util.localRagdoll()
        local stats = util.localStats()
        local v = stats and stats:FindFirstChild("Ragdoll")
        return v and v.Value == true
    end
    function util.localEscaped()
        local stats = util.localStats()
        local v = stats and stats:FindFirstChild("Escaped")
        return v and v.Value == true
    end
    function util.escapedNow()
        aioRt.escaped = aioRt.active and util.localEscaped() or false
        return aioRt.escaped
    end

    local scan = {}
    function scan.active()
        local v = ReplicatedStorage:FindFirstChild("IsGameActive")
        return v and v:IsA("BoolValue") and v.Value == true
    end
    function scan.beast()
        for _, plr in ipairs(game:GetService("Players"):GetPlayers()) do
            local stats = plr:FindFirstChild("TempPlayerStatsModule")
            local isBeast = stats and stats:FindFirstChild("IsBeast")
            if isBeast and isBeast.Value == true then return plr end
        end
    end
    function scan.map()
        local cur = ReplicatedStorage:FindFirstChild("CurrentMap")
        local val = cur and cur.Value
        if typeof(val) == "Instance" then return val end
        local name = val
        if type(name) ~= "string" or name == "" then return nil end
        return workspace:FindFirstChild(name)
    end
    function scan.mapObjects(map, force)
        if not map then
            aioRt.mapCache = nil; aioRt.computers = {}; aioRt.pods = {}; aioRt.exits = {}; return
        end
        local t = os.clock()
        if not force and map == aioRt.mapCache and t - aioRt.mapScanAt < 8 then return end
        local computers, pods, exits = {}, {}, {}
        for _, obj in ipairs(map:GetChildren()) do
            if     obj.Name == "ComputerTable" then computers[#computers+1] = obj
            elseif obj.Name == "FreezePod"     then pods[#pods+1] = obj
            elseif obj.Name == "ExitDoor"      then exits[#exits+1] = obj
            end
        end
        aioRt.mapCache = map; aioRt.mapScanAt = t
        aioRt.computers = computers; aioRt.pods = pods; aioRt.exits = exits
    end
    function scan.computersLeft()
        local v = ReplicatedStorage:FindFirstChild("ComputersLeft")
        if v then
            local ok, n = pcall(function() return v.Value end)
            if ok then return tonumber(n) end
        end
    end
    function scan.computersLeftNow()
        local left = scan.computersLeft()
        if left ~= nil then aioRt.computersLeft = left; return left end
        return aioRt.computersLeft
    end
    function scan.shouldHack()
        local left = scan.computersLeftNow()
        return left == nil or left > 0
    end
    function scan.findPowersEvent(plr)
        local char = plr and plr.Character
        if char then
            local powers = char:FindFirstChild("BeastPowers")
            local ev = powers and powers:FindFirstChild("PowersEvent")
            if ev and ev:IsA("RemoteEvent") then aioRt.powersCache = ev; return ev end
            for _, obj in ipairs(char:GetDescendants()) do
                if obj.Name == "PowersEvent" and obj:IsA("RemoteEvent") then
                    aioRt.powersCache = obj; return obj
                end
            end
        end
        if aioRt.powersCache and aioRt.powersCache:IsDescendantOf(workspace) then return aioRt.powersCache end
        local t = os.clock()
        if t - aioRt.powersScanAt < 5 then return nil end
        aioRt.powersScanAt = t
        local best
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj.Name == "PowersEvent" and obj:IsA("RemoteEvent") then
                if obj.Parent and obj.Parent.Name == "BeastPowers" then
                    aioRt.powersCache = obj; return obj
                end
                best = best or obj
            end
        end
        aioRt.powersCache = best; return best
    end

    function scan.rt()
        local wasActive = aioRt.active
        aioRt.active = scan.active()
        if not aioRt.active or not wasActive then
            hackFirst = true; hackTarget = nil; aioRt.escapeTried = false
            if hackMarker then hackMarker:Destroy(); hackMarker = nil end
        end
        if not aioRt.active then
            aioRt.escaped = false; aioRt.escapeTried = false; aioRt.beast = nil
            aioRt.powersEvent = nil; aioRt.localBeast = false
            aioRt.hackWaitPaid = false; aioRt.hackWaitComp = nil; aioRt.hackWaitUntil = 0
            aioRt.hackShortWait = false; aioRt.map = nil; aioRt.computersLeft = nil
            scan.mapObjects(nil, true); return
        end
        aioRt.escaped   = aioRt.active and util.localEscaped() or false
        aioRt.beast     = aioRt.active and scan.beast() or nil
        aioRt.powersEvent = aioRt.beast and scan.findPowersEvent(aioRt.beast) or nil
        aioRt.localBeast = aioRt.beast == Players.LocalPlayer
        local map = scan.map()
        local mapChanged = map ~= aioRt.map
        aioRt.map = map
        scan.mapObjects(map, mapChanged or not wasActive)
        aioRt.computersLeft = scan.computersLeft()
    end

    -- Background scanner
    task.spawn(function()
        while aioRt.alive do
            pcall(scan.rt)
            task.wait(0.4)
        end
    end)

    -- ── Hack helpers ─────────────────────────────────────────────────────────
    local hack = {}
    function hack.leave()
        local ev = util.remote()
        if not ev then return end
        if aioRt.map then ev:FireServer("Input", "Trigger", false, aioRt.map)
        else               ev:FireServer("Input", "Trigger", false) end
    end
    function hack.computerTriggerPart(trigger)
        if not trigger then return nil end
        if trigger:IsA("BasePart") then return trigger end
        if trigger:IsA("Model") then
            return trigger.PrimaryPart or trigger:FindFirstChildWhichIsA("BasePart", true)
        end
        return trigger:FindFirstChildWhichIsA("BasePart", true)
    end
    function hack.occupied(part)
        if not part then return true end
        for _, plr in ipairs(game:GetService("Players"):GetPlayers()) do
            if plr ~= player then
                local char = plr.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                if root and (root.Position - part.Position).Magnitude <= 3.5 then return true end
            end
        end
        return false
    end
    function hack.computerTrigger(comp)
        for i = 1, 3 do
            local trigger = comp and (
                comp:FindFirstChild("ComputerTrigger"..i) or
                comp:FindFirstChild("ComputerTrigger"..i, true)
            )
            local part = hack.computerTriggerPart(trigger)
            if part and not hack.occupied(part) and not util.beastNear(part.Position, AVOID_RANGE) then
                return part
            end
        end
    end
    function hack.computerDone(comp)
        local screen = comp and comp:FindFirstChild("Screen")
        if screen and screen:IsA("BasePart") then
            return screen.Color == Color3.fromRGB(0,255,0) or screen.Color == Color3.fromRGB(40,127,71)
        end
        return false
    end
    function hack.computerErrored(comp)
        local screen = comp and comp:FindFirstChild("Screen")
        return screen and screen:IsA("BasePart") and screen.Color == Color3.fromRGB(196,40,28)
    end
    function hack.nextComputerTarget()
        local root = util.rootPart()
        if not root then return nil end
        local bestComp, bestPart, bestDist
        for _, comp in ipairs(aioRt.computers) do
            local pos = util.instPos(comp)
            if comp and comp:IsDescendantOf(workspace) and not util.skipped(skip.hack, comp)
                and not hack.computerDone(comp) and not util.beastNear(pos, AVOID_RANGE) then
                local part = hack.computerTrigger(comp)
                if part then
                    local dist = (root.Position - part.Position).Magnitude
                    if not bestDist or dist < bestDist then
                        bestComp = comp; bestPart = part; bestDist = dist
                    end
                end
            end
        end
        return bestComp, bestPart, bestDist
    end
    function hack.clearMarker()
        if hackMarker then hackMarker:Destroy(); hackMarker = nil end
    end
    function hack.markerCFrame(comp, part)
        local root = util.rootPart()
        local base = util.instPos(comp) or part.Position
        local dir  = part.Position - base
        if dir.Magnitude < 1 then dir = root and root.Position - part.Position or part.CFrame.RightVector end
        if dir.Magnitude < 1 then dir = part.CFrame.RightVector end
        dir = Vector3.new(dir.X, 0, dir.Z)
        if dir.Magnitude < 1 then dir = Vector3.new(1,0,0) end
        dir = dir.Unit
        local pos = part.Position + dir * 10 + Vector3.new(0,4,0)
        return CFrame.new(pos, part.Position)
    end
    function hack.moveMarker(comp, part)
        if not hackMarker or not hackMarker.Parent then
            hackMarker = Instance.new("Part")
            hackMarker.Name        = "zyx_aio_hack_wait"
            hackMarker.Anchored    = true
            hackMarker.CanCollide  = true
            hackMarker.Transparency = 1
            hackMarker.Size        = Vector3.new(5,1,5)
            hackMarker.Parent      = workspace
        end
        hackMarker.CFrame = hack.markerCFrame(comp, part)
        return hackMarker
    end
    function hack.waitStart(comp, part, dist)
        local root   = util.rootPart()
        local marker = hack.moveMarker(comp, part)
        if not root or not marker then return false end
        local waitTime = util.hackWaitTime(dist or util.localDist(part.Position))
        root.CFrame = marker.CFrame + Vector3.new(0,3,0)
        local start = os.clock()
        while aio.autoHack and aioRt.active and not aioRt.localBeast and not aioRt.escaped and os.clock()-start < waitTime do
            if not comp or not comp:IsDescendantOf(workspace) or hack.computerDone(comp) then
                if comp then util.skipFor(skip.hack, comp, 8) end
                local left = scan.computersLeftNow()
                if left and left <= 0 then return "complete" end
                return "done"
            end
            if aio.avoidBeast and (util.beastNear(marker.Position, AVOID_RANGE) or util.beastNear(part.Position, AVOID_RANGE)) then
                util.skipFor(skip.hack, comp, 8); return "avoid"
            end
            task.wait(0.25)
        end
        local left = scan.computersLeftNow()
        if left and left <= 0 then return "complete" end
        if not comp or not comp:IsDescendantOf(workspace) or hack.computerDone(comp) then return false end
        aioRt.hackWaitComp  = comp
        aioRt.hackWaitUntil = os.clock() + 6
        return aio.autoHack and aioRt.active and not aioRt.localBeast and not aioRt.escaped
    end
    function hack.doneTarget(target)
        if not target or not target.comp then return false end
        return not target.comp:IsDescendantOf(workspace) or hack.computerDone(target.comp)
    end
    function hack.start(comp, part, dist)
        local root = util.rootPart()
        local ev   = util.remote()
        if not root or not part or not ev then return false end
        if util.localTyping() then hack.leave(); task.wait(0.1) end
        hackTarget = {
            comp = comp, part = part,
            left = scan.computersLeftNow(),
            dist = dist or util.localDist(part.Position)
        }
        local errored = hack.computerErrored(comp)
        local paid    = aioRt.hackWaitPaid or (aioRt.hackWaitComp == comp and os.clock() < (aioRt.hackWaitUntil or 0))
        if paid then
            aioRt.hackWaitPaid = false; aioRt.hackWaitComp = nil; aioRt.hackWaitUntil = 0
        elseif aioRt.hackShortWait then
            aioRt.hackShortWait = false
            local marker = hack.moveMarker(comp, part)
            if marker then root.CFrame = marker.CFrame + Vector3.new(0,3,0) end
            local start = os.clock()
            while aio.autoHack and aioRt.active and not aioRt.localBeast and not aioRt.escaped and os.clock()-start < 5 do
                task.wait(0.25)
            end
        elseif not hackFirst and not errored then
            local ready = hack.waitStart(comp, part, hackTarget.dist)
            if ready ~= true then return ready end
        end
        local freshPart = hack.computerTrigger(comp)
        if not freshPart then
            aioRt.hackWaitPaid = false; aioRt.hackWaitComp = nil; aioRt.hackWaitUntil = 0
            aioRt.hackShortWait = true
            util.skipFor(skip.hack, comp, 4); return "retry"
        end
        part = freshPart; hackTarget.part = part; hackTarget.dist = util.localDist(part.Position) or hackTarget.dist
        root = util.rootPart()
        if not root then return false end
        root.CFrame = part.CFrame + Vector3.new(0,3,0)
        if not aio.autoHack then return false end
        if errored then
            local stop = os.clock() + 5
            while aio.autoHack and aioRt.active and not aioRt.localBeast and not aioRt.escaped and not util.localTyping() and os.clock() < stop do
                root = util.rootPart()
                if not root or not part.Parent then return false end
                root.CFrame = part.CFrame + Vector3.new(0,3,0)
                ev:FireServer("Input", "Action", true)
                task.wait(1)
            end
            if not util.localTyping() then return "retry" end
        else
            task.wait(0.8)
            ev:FireServer("Input", "Action", true)
        end
        hackFirst = false
        return true
    end
    function hack.waitRetry(comp)
        local part = hackTarget and hackTarget.comp == comp and hackTarget.part
        local root = util.rootPart()
        local dist = hackTarget and hackTarget.dist
        if root and part and part.Parent then
            dist = dist or util.localDist(part.Position)
            local marker = hack.moveMarker(comp, part)
            if marker then root.CFrame = marker.CFrame + Vector3.new(0,3,0) end
        end
        local waitTime = util.hackWaitTime(dist)
        local start = os.clock()
        while aio.autoHack and aioRt.active and not aioRt.localBeast and not aioRt.escaped and os.clock()-start < waitTime do
            if not comp or not comp:IsDescendantOf(workspace) or hack.computerDone(comp) then
                if comp then util.skipFor(skip.hack, comp, 8) end
                local left = scan.computersLeftNow()
                if left and left <= 0 then return "complete" end
                return "done"
            end
            if aio.avoidBeast and (util.beastNear(util.instPos(comp), AVOID_RANGE) or util.beastNearLocal()) then
                util.skipFor(skip.hack, comp, 8); return "avoid"
            end
            task.wait(0.25)
        end
        local left = scan.computersLeftNow()
        if left and left <= 0 then return "complete" end
        aioRt.hackWaitPaid = true
        return "retry"
    end
    function hack.avoidTarget(comp)
        if comp then util.skipFor(skip.hack, comp, 8) end
        hack.leave(); hackTarget = nil
        aioRt.hackWaitPaid = false; aioRt.hackWaitComp = nil
        aioRt.hackWaitUntil = 0; aioRt.hackShortWait = false
    end

    -- ── Exit helpers ──────────────────────────────────────────────────────────
    local exit = {}
    function exit.light(door)
        return door and (door:FindFirstChild("Light") or door:FindFirstChild("Light",true))
    end
    function exit.open(door)
        local light = exit.light(door)
        if not light then return false end
        local ok, color = pcall(function() return light.Color end)
        return ok and color == Color3.fromRGB(0,255,0)
    end
    function exit.area(door)
        local area = door and (door:FindFirstChild("ExitArea") or door:FindFirstChild("ExitArea",true))
        if area and area:IsA("BasePart") then return area end
    end
    function exit.trigger(door)
        local trigger = door and (door:FindFirstChild("ExitDoorTrigger") or door:FindFirstChild("ExitDoorTrigger",true))
        if trigger and trigger:IsA("BasePart") then return trigger end
        return trigger and trigger:FindFirstChildWhichIsA("BasePart",true)
    end
    function exit.openDoor(door)
        local root    = util.rootPart()
        local trigger = exit.trigger(door)
        local ev      = ReplicatedStorage:FindFirstChild("RemoteEvent")
        if not root or not trigger or not ev or not ev:IsA("RemoteEvent") then return false end
        if aio.autoHack and util.localTyping() then hack.leave(); task.wait(0.1) end
        root.CFrame = trigger.CFrame + Vector3.new(0,3,0)
        task.wait(0.35)
        ev:FireServer("Input","Action",true)
        return true
    end
    function exit.escapeDoor(door)
        if os.clock() < nextEscapeTry or aioRt.escapeTried or util.escapedNow() then return false end
        local area = exit.area(door)
        if not area then return false end
        local root = util.rootPart()
        if not root then return false end
        if util.beastNear(area.Position, AVOID_RANGE) then util.skipFor(skip.exit, door, 6); return false end
        nextEscapeTry = os.clock() + 2
        if aio.autoHack and util.localTyping() then hack.leave(); task.wait(0.1) end
        root.CFrame = area.CFrame + Vector3.new(0,3,0)
        local touch = area:FindFirstChild("TouchInterest") or area:FindFirstChildOfClass("TouchTransmitter")
        if touch and firetouchinterest then
            firetouchinterest(root, area, 0); task.wait(); firetouchinterest(root, area, 1)
        end
        task.wait(2); aioRt.escapeTried = true; aioRt.escaped = true
        return true
    end
    function exit.findOpen()
        for _, door in ipairs(aioRt.exits) do
            local area    = exit.area(door)
            local trigger = exit.trigger(door)
            local unsafe  = util.beastNear(area and area.Position, AVOID_RANGE)
                or util.beastNear(trigger and trigger.Position, AVOID_RANGE)
                or util.beastNear(util.instPos(door), AVOID_RANGE)
            if door and door:IsDescendantOf(workspace) and not util.skipped(skip.exit, door)
                and exit.open(door) and area and not unsafe then return door end
        end
    end
    function exit.findUsable()
        for _, door in ipairs(aioRt.exits) do
            local area    = exit.area(door)
            local trigger = exit.trigger(door)
            local unsafe  = util.beastNear(area and area.Position, AVOID_RANGE)
                or util.beastNear(trigger and trigger.Position, AVOID_RANGE)
                or util.beastNear(util.instPos(door), AVOID_RANGE)
            if door and door:IsDescendantOf(workspace) and not util.skipped(skip.exit, door)
                and area and trigger and not unsafe then return door end
        end
    end

    -- ── All-in-one combined loop ───────────────────────────────────────────
    local function startAioThread()
        if aioThread then return end
        aioThread = task.spawn(function()
            while aioRt.alive and (aio.autoHack or aio.autoExit or aio.avoidBeast) do

                -- avoid beast
                if aio.avoidBeast and aioRt.active and not aioRt.localBeast then
                    if util.beastNearLocal() then
                        if hackTarget then hack.avoidTarget(hackTarget.comp) end
                    end
                end

                -- auto hack
                if aio.autoHack and aioRt.active and not aioRt.localBeast and not util.localRagdoll() and not aioRt.escaped and scan.shouldHack() then
                    if util.localTyping() then
                        if aio.avoidBeast and util.beastNearLocal() then
                            hack.avoidTarget(hackTarget and hackTarget.comp)
                        end
                        task.wait(0.25)
                    else
                        local holdHackTarget = false
                        if aio.avoidBeast and util.beastNearLocal() and hackTarget and hackTarget.comp then
                            hack.avoidTarget(hackTarget.comp)
                        end
                        local pickComp, pickPart, pickDist = hack.nextComputerTarget()
                        if pickComp and hackTarget and pickComp ~= hackTarget.comp then hackTarget = nil end
                        local comp, part, dist
                        if hackTarget and hackTarget.comp and hackTarget.comp:IsDescendantOf(workspace)
                            and not util.skipped(skip.hack, hackTarget.comp) and not hack.computerDone(hackTarget.comp) then
                            comp = hackTarget.comp
                            part = hack.computerTrigger(comp)
                            dist = hackTarget.dist
                            if not part then
                                if hack.computerErrored(comp) then
                                    holdHackTarget = true; task.wait(0.25)
                                else
                                    local res = hack.waitRetry(comp)
                                    if res == "complete" or res == "avoid" or res == "done" then
                                        hackTarget = nil; aioRt.hackWaitPaid = false
                                        aioRt.hackWaitComp = nil; aioRt.hackWaitUntil = 0; aioRt.hackShortWait = false
                                        if res == "complete" then task.wait(0.5) end
                                    elseif res == "retry" then
                                        hackTarget = nil
                                    end
                                end
                            end
                        elseif hackTarget and hackTarget.comp then
                            if hack.doneTarget(hackTarget) and not hack.computerErrored(hackTarget.comp) then
                                util.skipFor(skip.hack, hackTarget.comp, 8)
                            end
                            hackTarget = nil
                            aioRt.hackWaitPaid = false; aioRt.hackWaitComp = nil; aioRt.hackWaitUntil = 0; aioRt.hackShortWait = false
                        end
                        if not comp or not part then
                            if not holdHackTarget and scan.shouldHack() then
                                if pickComp and pickPart then
                                    comp = pickComp; part = pickPart; dist = pickDist
                                else
                                    comp, part, dist = hack.nextComputerTarget()
                                end
                            end
                        end
                        if comp and part then
                            local res = hack.start(comp, part, dist)
                            if res == true then
                                task.wait(0.7)
                            elseif res == "complete" then
                                hackTarget = nil; aioRt.hackWaitPaid = false
                                aioRt.hackWaitComp = nil; aioRt.hackWaitUntil = 0; aioRt.hackShortWait = false
                                task.wait(0.5)
                            elseif res == "retry" then
                                task.wait(0.2)
                            elseif not res then
                                hackTarget = nil; aioRt.hackWaitPaid = false
                                aioRt.hackWaitComp = nil; aioRt.hackWaitUntil = 0; aioRt.hackShortWait = false
                                task.wait(0.25)
                            else
                                task.wait(0.5)
                            end
                        else
                            task.wait(0.25)
                        end
                    end
                elseif aio.autoHack then
                    if util.localTyping() then hack.leave() end
                end

                -- auto exit
                if aio.autoExit and aioRt.active and not aioRt.localBeast and not aioRt.escapeTried and not util.escapedNow() and aioRt.computersLeft == 0 then
                    local door = exit.findOpen()
                    if door then
                        local area = exit.area(door)
                        if area and util.beastNear(area.Position, AVOID_RANGE) then
                            util.skipFor(skip.exit, door, 6)
                        else
                            if not exit.escapeDoor(door) then task.wait(1) end
                        end
                    else
                        door = exit.findUsable()
                        if door and exit.openDoor(door) then
                            local start = os.clock()
                            while aio.autoExit and aioRt.active and not aioRt.escapeTried and not util.escapedNow()
                                and door:IsDescendantOf(workspace) and not exit.open(door) and os.clock()-start < 12 do
                                local trigger = exit.trigger(door)
                                if trigger and util.beastNear(trigger.Position, AVOID_RANGE) then
                                    util.skipFor(skip.exit, door, 6); break
                                end
                                task.wait(0.25)
                            end
                            if aio.autoExit and not aioRt.escapeTried and not util.escapedNow() and exit.open(door) then
                                task.wait(3)
                                if aio.autoExit and aioRt.active and not aioRt.escapeTried and not util.escapedNow()
                                    and door:IsDescendantOf(workspace) then
                                    local area = exit.area(door)
                                    if area and not util.beastNear(area.Position, AVOID_RANGE) then
                                        exit.escapeDoor(door)
                                    else
                                        util.skipFor(skip.exit, door, 6)
                                    end
                                end
                            end
                        else
                            task.wait(0.5)
                        end
                    end
                end

                task.wait(0.15)
            end
            aioThread = nil
        end)
    end

    local function aioRefresh()
        if aio.autoHack or aio.autoExit or aio.avoidBeast then
            startAioThread()
        else
            if not aio.avoidBeast then
                for k in pairs(skip.hack) do skip.hack[k] = nil end
                for k in pairs(skip.exit) do skip.exit[k] = nil end
            end
            if not aio.autoHack then
                hackTarget = nil; hackFirst = true
                aioRt.hackWaitPaid = false; aioRt.hackWaitComp = nil
                aioRt.hackWaitUntil = 0; aioRt.hackShortWait = false
                hack.clearMarker()
                if util.localTyping() then pcall(hack.leave) end
            end
            if not aio.autoExit then
                aioRt.escapeTried = false; nextEscapeTry = 0
            end
        end
    end

    -- ── ZyxLab-style Sub-Page Overlay UI ──────────────────────────────────────
    -- Opened via the button above; uses ZyxLab accent colors & design language.
    local aioGui = nil
    local aioToggleSetters = {}  -- { autoHack = fn, autoExit = fn, avoidBeast = fn }

    local function buildAioSubPage()
        local parent = getGuiParent()
        -- Destroy any previous instance
        local old = parent:FindFirstChild("ZyxLab_SurvivorAIO")
        if old then old:Destroy() end

        local sgui = Instance.new("ScreenGui")
        sgui.Name             = "ZyxLab_SurvivorAIO"
        sgui.ResetOnSpawn     = false
        sgui.IgnoreGuiInset   = true
        sgui.DisplayOrder     = 3600
        sgui.ZIndexBehavior   = Enum.ZIndexBehavior.Sibling
        sgui.Parent           = parent
        aioGui = sgui

        -- Backdrop
        local backdrop = Instance.new("TextButton", sgui)
        backdrop.Size                = UDim2.new(1,0,1,0)
        backdrop.BackgroundColor3    = Color3.new(0,0,0)
        backdrop.BackgroundTransparency = 0.5
        backdrop.BorderSizePixel     = 0
        backdrop.Text                = ""
        backdrop.AutoButtonColor     = false
        backdrop.ZIndex              = 1

        -- Panel
        local panel = Instance.new("Frame", sgui)
        panel.Name                  = "AIOPanel"
        panel.Size                  = UDim2.fromOffset(340, 310)
        panel.Position              = UDim2.new(0.5,-170,0.5,-155)
        panel.BackgroundColor3      = Color3.fromRGB(13,13,13)
        panel.BorderSizePixel       = 0
        panel.Active                = true
        panel.Draggable             = true
        panel.ZIndex                = 2
        panel:SetAttribute("ZyxAccentStroke", true)
        Instance.new("UICorner", panel).CornerRadius = UDim.new(0,14)
        local panelStroke = Instance.new("UIStroke", panel)
        panelStroke.Thickness   = 1.5
        panelStroke.Color       = getEffectiveAccent()
        panelStroke.Transparency = 0.15

        -- Header bar
        local hdr = Instance.new("Frame", panel)
        hdr.Size             = UDim2.new(1,0,0,42)
        hdr.BackgroundColor3 = Color3.fromRGB(18,17,28)
        hdr.BorderSizePixel  = 0
        Instance.new("UICorner", hdr).CornerRadius = UDim.new(0,14)
        local hdrFix = Instance.new("Frame", hdr)
        hdrFix.Size             = UDim2.new(1,0,0.5,0)
        hdrFix.Position         = UDim2.new(0,0,0.5,0)
        hdrFix.BackgroundColor3 = Color3.fromRGB(18,17,28)
        hdrFix.BorderSizePixel  = 0

        local accentBar = Instance.new("Frame", hdr)
        accentBar.Size             = UDim2.new(0,4,1,0)
        accentBar.BackgroundColor3 = getEffectiveAccent()
        accentBar.BorderSizePixel  = 0
        accentBar:SetAttribute("ZyxAccentBG", true)

        local titleLbl = Instance.new("TextLabel", hdr)
        titleLbl.Size                = UDim2.new(1,-80,1,0)
        titleLbl.Position            = UDim2.new(0,16,0,0)
        titleLbl.BackgroundTransparency = 1
        titleLbl.Text                = "⚡ Survivor AIO"
        titleLbl.Font                = Enum.Font.GothamBold
        titleLbl.TextSize            = 14
        titleLbl.TextColor3          = Color3.new(1,1,1)
        titleLbl.TextXAlignment      = Enum.TextXAlignment.Left

        local closeBtn = Instance.new("TextButton", hdr)
        closeBtn.Size             = UDim2.fromOffset(28,28)
        closeBtn.Position         = UDim2.new(1,-34,0.5,-14)
        closeBtn.BackgroundColor3 = Color3.fromRGB(32,30,48)
        closeBtn.BorderSizePixel  = 0
        closeBtn.Text             = "×"
        closeBtn.Font             = Enum.Font.GothamBold
        closeBtn.TextSize         = 18
        closeBtn.TextColor3       = Color3.new(1,1,1)
        closeBtn.AutoButtonColor  = false
        Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(1,0)
        closeBtn.MouseButton1Click:Connect(function()
            sgui.Enabled = false
        end)

        backdrop.MouseButton1Click:Connect(function()
            sgui.Enabled = false
        end)

        -- Description pill
        local descFrame = Instance.new("Frame", panel)
        descFrame.Size             = UDim2.new(1,-28,0,44)
        descFrame.Position         = UDim2.new(0,14,0,50)
        descFrame.BackgroundColor3 = Color3.fromRGB(18,17,28)
        descFrame.BorderSizePixel  = 0
        Instance.new("UICorner", descFrame).CornerRadius = UDim.new(0,8)
        local descLbl = Instance.new("TextLabel", descFrame)
        descLbl.Size                  = UDim2.new(1,-12,1,0)
        descLbl.Position              = UDim2.new(0,10,0,0)
        descLbl.BackgroundTransparency = 1
        descLbl.Text                  = "Toggle each function independently. All three can run simultaneously."
        descLbl.Font                  = Enum.Font.GothamMedium
        descLbl.TextSize              = 11
        descLbl.TextColor3            = Color3.fromRGB(160,155,190)
        descLbl.TextXAlignment        = Enum.TextXAlignment.Left
        descLbl.TextWrapped           = true

        -- Toggle row builder (ZyxLab style)
        local function makeAioToggle(yOffset, icon, label, desc, key)
            local row = Instance.new("Frame", panel)
            row.Size             = UDim2.new(1,-28,0,58)
            row.Position         = UDim2.fromOffset(14, yOffset)
            row.BackgroundColor3 = Color3.fromRGB(18,17,28)
            row.BorderSizePixel  = 0
            Instance.new("UICorner", row).CornerRadius = UDim.new(0,10)
            local rowStroke = Instance.new("UIStroke", row)
            rowStroke.Color       = Color3.fromRGB(35,33,52)
            rowStroke.Thickness   = 1
            rowStroke.Transparency = 0.3

            local iconLbl = Instance.new("TextLabel", row)
            iconLbl.Size                  = UDim2.fromOffset(34,34)
            iconLbl.Position              = UDim2.fromOffset(12,12)
            iconLbl.BackgroundTransparency = 1
            iconLbl.Text                  = icon
            iconLbl.Font                  = Enum.Font.GothamBold
            iconLbl.TextSize              = 20

            local nameLbl = Instance.new("TextLabel", row)
            nameLbl.Size                  = UDim2.new(1,-110,0,20)
            nameLbl.Position              = UDim2.fromOffset(54,10)
            nameLbl.BackgroundTransparency = 1
            nameLbl.Text                  = label
            nameLbl.Font                  = Enum.Font.GothamBold
            nameLbl.TextSize              = 13
            nameLbl.TextColor3            = Color3.new(1,1,1)
            nameLbl.TextXAlignment        = Enum.TextXAlignment.Left

            local subLbl = Instance.new("TextLabel", row)
            subLbl.Size                  = UDim2.new(1,-110,0,16)
            subLbl.Position              = UDim2.fromOffset(54,30)
            subLbl.BackgroundTransparency = 1
            subLbl.Text                  = desc
            subLbl.Font                  = Enum.Font.Gotham
            subLbl.TextSize              = 11
            subLbl.TextColor3            = Color3.fromRGB(140,135,170)
            subLbl.TextXAlignment        = Enum.TextXAlignment.Left

            -- Pill toggle
            local pill = Instance.new("Frame", row)
            pill.Size             = UDim2.fromOffset(44,22)
            pill.Position         = UDim2.new(1,-54,0.5,-11)
            pill.BackgroundColor3 = Color3.fromRGB(38,36,56)
            pill.BorderSizePixel  = 0
            Instance.new("UICorner", pill).CornerRadius = UDim.new(1,0)

            local knob = Instance.new("Frame", pill)
            knob.Size             = UDim2.fromOffset(17,17)
            knob.Position         = UDim2.fromOffset(2,2.5)
            knob.BackgroundColor3 = Color3.fromRGB(160,155,190)
            knob.BorderSizePixel  = 0
            Instance.new("UICorner", knob).CornerRadius = UDim.new(1,0)

            local pillOn = false
            local function setPill(v)
                pillOn = v
                local accent = getEffectiveAccent()
                TweenService:Create(pill, TweenInfo.new(0.15, Enum.EasingStyle.Quint), {
                    BackgroundColor3 = v and accent or Color3.fromRGB(38,36,56)
                }):Play()
                TweenService:Create(knob, TweenInfo.new(0.15, Enum.EasingStyle.Quint), {
                    Position         = v and UDim2.fromOffset(25,2.5) or UDim2.fromOffset(2,2.5),
                    BackgroundColor3 = v and Color3.new(1,1,1) or Color3.fromRGB(160,155,190),
                }):Play()
                aio[key] = v
                aioRefresh()
            end

            -- Clickable overlay
            local hitBtn = Instance.new("TextButton", row)
            hitBtn.Size                  = UDim2.new(1,0,1,0)
            hitBtn.BackgroundTransparency = 1
            hitBtn.Text                  = ""
            hitBtn.ZIndex                = 5
            hitBtn.AutoButtonColor       = false
            hitBtn.MouseButton1Click:Connect(function()
                setPill(not pillOn)
            end)

            aioToggleSetters[key] = setPill
            return setPill
        end

        makeAioToggle(102, "💻", "Auto Hack", "Hacks computers automatically; avoids anticheat waits",       "autoHack")
        makeAioToggle(168, "🚪", "Auto Exit",  "Escapes through exit doors when computers are done",          "autoExit")
        makeAioToggle(234, "👁", "Avoid Beast","Skips computers/exits near the beast (18.7 stud range)",      "avoidBeast")

        -- Status bar
        local statusFrame = Instance.new("Frame", panel)
        statusFrame.Size             = UDim2.new(1,-28,0,28)
        statusFrame.Position         = UDim2.fromOffset(14, 300 - 38)
        statusFrame.BackgroundColor3 = Color3.fromRGB(18,17,28)
        statusFrame.BorderSizePixel  = 0
        Instance.new("UICorner", statusFrame).CornerRadius = UDim.new(0,8)
        local statusLbl = Instance.new("TextLabel", statusFrame)
        statusLbl.Size                  = UDim2.new(1,-14,1,0)
        statusLbl.Position              = UDim2.fromOffset(10,0)
        statusLbl.BackgroundTransparency = 1
        statusLbl.Text                  = "● idle"
        statusLbl.Font                  = Enum.Font.GothamMedium
        statusLbl.TextSize              = 11
        statusLbl.TextColor3            = Color3.fromRGB(120,115,150)
        statusLbl.TextXAlignment        = Enum.TextXAlignment.Left

        -- Live status ticker
        task.spawn(function()
            while sgui and sgui.Parent do
                if sgui.Enabled then
                    local parts = {}
                    if aio.autoHack   then parts[#parts+1] = "hacking" end
                    if aio.autoExit   then parts[#parts+1] = "exit"    end
                    if aio.avoidBeast then parts[#parts+1] = "avoiding beast" end
                    local left = aioRt.computersLeft
                    if left ~= nil then parts[#parts+1] = left.." PC left" end
                    if #parts > 0 then
                        statusLbl.Text      = "● " .. table.concat(parts, "  ·  ")
                        statusLbl.TextColor3 = getEffectiveAccent()
                    else
                        statusLbl.Text      = "● idle"
                        statusLbl.TextColor3 = Color3.fromRGB(120,115,150)
                    end
                end
                task.wait(0.5)
            end
        end)
    end

    -- Public opener used by the ZyxLab button
    _G.__ZyxOpenSurvivorAIO = function()
        if aioGui and aioGui.Parent then
            aioGui.Enabled = true
            return
        end
        buildAioSubPage()
    end
end

-- ─────────────────────────────────────────────────────────────────────────────
-- ⚡ PATHFIND SURVIVOR MODULE
-- Pathfinding autofarm: walks to PCs, opens doors, hovers over beast
-- ─────────────────────────────────────────────────────────────────────────────
do

-- // Services


-- // Runtime state
local pf = {
    enabled       = false,
    thread        = nil,
    currentTarget = nil,
    status        = "Idle",
    statusLabel   = nil,
    -- signal that the current walkTo should abort immediately
    abortWalk     = false,
}

-- // Helpers
local function getChar()  return player.Character end
local function getRoot()
    local c = getChar()
    return c and (c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Torso"))
end
local function getHum()
    local c = getChar()
    return c and c:FindFirstChildOfClass("Humanoid")
end
local function getRemote()
    local ev = ReplicatedStorage:FindFirstChild("RemoteEvent")
    return ev and ev:IsA("RemoteEvent") and ev or nil
end
local function getMap()
    local cur = ReplicatedStorage:FindFirstChild("CurrentMap")
    local val = cur and cur.Value
    if typeof(val) == "Instance" then return val end
    if type(val) == "string" and val ~= "" then return workspace:FindFirstChild(val) end
end
local function computersLeft()
    local v = ReplicatedStorage:FindFirstChild("ComputersLeft")
    if v then
        local ok, n = pcall(function() return v.Value end)
        if ok then return tonumber(n) end
    end
end
local function isComputerDone(comp)
    local screen = comp and comp:FindFirstChild("Screen")
    if screen and screen:IsA("BasePart") then
        return screen.Color == Color3.fromRGB(0, 255, 0)
            or screen.Color == Color3.fromRGB(40, 127, 71)
    end
    return false
end
local function getTriggerPart(trigger)
    if not trigger then return nil end
    if trigger:IsA("BasePart") then return trigger end
    return trigger:FindFirstChildWhichIsA("BasePart", true)
end
local function isOccupied(part)
    if not part then return true end
    for _, p in pairs(game:GetService("Players"):GetPlayers()) do
        if p ~= player then
            local c = p.Character
            local r = c and c:FindFirstChild("HumanoidRootPart")
            if r and (r.Position - part.Position).Magnitude <= 3.5 then return true end
        end
    end
    return false
end
-- Returns the nearest unoccupied trigger part for a computer (checks all 3 slots).
-- Third return value is true if all slots exist but all are occupied (skip this PC).
local function getComputerTrigger(comp)
    local root = getRoot()
    local bestPart, bestTrig, bestDist = nil, nil, math.huge
    local anyFound = false
    for i = 1, 3 do
        local t = comp:FindFirstChild("ComputerTrigger" .. i)
               or comp:FindFirstChild("ComputerTrigger" .. i, true)
        local part = getTriggerPart(t)
        if part then
            anyFound = true
            if not isOccupied(part) then
                local dist = root and (root.Position - part.Position).Magnitude or 0
                if dist < bestDist then
                    bestDist = dist; bestPart = part; bestTrig = t
                end
            end
        end
    end
    local allOccupied = anyFound and not bestPart
    return bestPart, bestTrig, allOccupied
end
local function setStatus(s)
    pf.status = s
    if pf.statusLabel then pf.statusLabel.Text = s end
end

-- ============================================================
-- BEAST DETECTION ENGINE
-- ============================================================
do  -- 🔒 BEAST_DETECTION section (scopes internal locals)
beast = {
    _player   = nil,
    _scanAt   = 0,
    AVOID_MIN = 30,
    AVOID_MAX = 45,
}

local function beastScan()
    local t = os.clock()
    if t - beast._scanAt < 0.3 then return beast._player end
    beast._scanAt = t
    for _, plr in ipairs(game:GetService("Players"):GetPlayers()) do
        local stats = plr:FindFirstChild("TempPlayerStatsModule")
        local isBeast = stats and stats:FindFirstChild("IsBeast")
        if isBeast and isBeast.Value == true then
            beast._player = plr; return plr
        end
        local char = plr.Character
        if char and (char:FindFirstChild("BeastPowers") or char:FindFirstChild("Hammer")) then
            beast._player = plr; return plr
        end
    end
    beast._player = nil
    return nil
end

function isBeastSelf()
    local b = beastScan()
    return b == player
end

function getBeastPos()
    local b = beastScan()
    if not b or b == player then return nil end
    local char = b.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    return hrp and hrp.Position
end

local function beastDistFrom(pos)
    if not pos then return math.huge end
    local bp = getBeastPos()
    return bp and (bp - pos).Magnitude or math.huge
end

function beastNear(pos, range)
    return beastDistFrom(pos) <= (range or beast.AVOID_MAX)
end

function beastNearLocal(range)
    local root = getRoot()
    return root and beastNear(root.Position, range or beast.AVOID_MIN)
end

end  -- close BEAST_DETECTION section
-- ============================================================
-- BEAST AVOIDANCE — Heartbeat flee engine
-- KEY FIX: when fleeing, we set pf.abortWalk = true so the
-- main walkTo loop exits immediately and re-evaluates.
-- The flee itself is handled by a separate dedicated flee task
-- that runs INSTEAD of walkTo while beast is near.
-- ============================================================
do  -- 🔒 BEAST_AVOIDANCE section (scopes internal locals)
avoidance = {
    active   = false,
    enabled  = false,
    fleeing  = false,
    _conn    = nil,
}

local FLEE_DIST     = 25
local FLEE_INTERVAL = 0.15

local function computeFleeTarget(rootPos, beastPos)
    local away = Vector3.new(rootPos.X - beastPos.X, 0, rootPos.Z - beastPos.Z)
    if away.Magnitude < 0.01 then away = Vector3.new(1, 0, 0) else away = away.Unit end
    -- add a small random offset so we don't flee straight back if beast follows
    local randAngle = math.rad(math.random(-30, 30))
    local rot = CFrame.fromAxisAngle(Vector3.new(0,1,0), randAngle)
    away = rot:VectorToWorldSpace(away)
    return rootPos + away * FLEE_DIST
end

-- Beast Hover System
-- Noclip is ONE-SHOT only at teleport moment — no persistent Stepped loop
-- Persistent loop was causing physics bobbing during normal walking

local function doHoverWait()
    local root = getRoot()
    local hum  = getHum()
    if not root or not hum then return end

    local groundPos = root.Position
    local hoverPos  = groundPos + Vector3.new(0, 80, 0)

    setStatus("⚡ Beast! Hovering...")

    -- Teleport up to hover position
    hum.PlatformStand = true
    root.CFrame = CFrame.new(hoverPos)
    root.AssemblyLinearVelocity = Vector3.zero
    task.wait(0.05)

    -- Hover: keep locking position until beast leaves
    local hoverDeadline = os.clock() + 30
    repeat
        task.wait(0.2)
        local r = getRoot()
        if r and math.abs(r.Position.Y - hoverPos.Y) > 3 then
            r.CFrame = CFrame.new(hoverPos)
            r.AssemblyLinearVelocity = Vector3.zero
        end
        local bp   = getBeastPos()
        local dist = bp and (groundPos - bp).Magnitude or math.huge
        setStatus("⚡ Hovering — beast " .. (bp and math.floor(dist) .. " studs" or "gone"))
    until not pf.enabled
        or os.clock() > hoverDeadline
        or not getBeastPos()
        or (getBeastPos() and (groundPos - getBeastPos()).Magnitude > beast.AVOID_MIN + 15)

    if not pf.enabled then
        hum.PlatformStand = false
        return
    end

    -- Land: teleport back down
    setStatus("✅ Beast left, landing...")
    local r = getRoot()
    if r then
        r.CFrame = CFrame.new(groundPos + Vector3.new(0, 3, 0))
        r.AssemblyLinearVelocity = Vector3.zero
    end
    task.wait(0.05)
    hum.PlatformStand = false
    task.wait(0.4)
end

function doFleeFromBeast(_timeoutSecs)
    doHoverWait()
end

function avoidance.start()
    if avoidance._conn then return end
    avoidance._conn = RunService.Heartbeat:Connect(function()
        if not avoidance.enabled then return end
        if isBeastSelf() then avoidance.active = false; return end
        local root = getRoot()
        local hum  = getHum()
        if not root or not hum then return end
        if hum:GetState() == Enum.HumanoidStateType.Dead then return end
        local beastPos = getBeastPos()
        if not beastPos then avoidance.active = false; return end
        local dist = (root.Position - beastPos).Magnitude
        if dist <= beast.AVOID_MIN then
            avoidance.active = true
            pf.abortWalk     = true
        else
            avoidance.active = false
        end
    end)
end

function avoidance.stop()
    if avoidance._conn then
        avoidance._conn:Disconnect()
        avoidance._conn = nil
    end
end

-- RAYCAST UTILITY

end  -- close BEAST_AVOIDANCE section
-- ============================================================
do  -- 🔒 WALL_SCANNER_HELPERS section (scopes internal locals)
function buildExclude()
    local ex = {}
    local ch = getChar()
    if ch then
        for _, p in ipairs(ch:GetDescendants()) do
            if p:IsA("BasePart") then table.insert(ex, p) end
        end
    end
    return ex
end

-- Smart raycast — filters out parts that should not count as walls:
--   • non-collidable (CanCollide=false)
--   • fully transparent (Transparency=1)
--   • tiny props (all 3 axes < 0.6 studs — decorations, handles, etc.)
--   • named door parts (SingleDoor/DoubleDoor panels) — treated as passable
--     because the door engine will open them; blocking on them causes jitter
local DOOR_NAMES = { DoorPanel=true, DoorFrame=true, SingleDoor=true, DoubleDoor=true }
function castRay(origin, dir, maxLen, params)
    local len = math.min(dir.Magnitude, maxLen)
    if len < 0.05 then return false, nil, nil end
    local res = workspace:Raycast(origin, dir.Unit * len, params)
    if not res then return false, nil, nil end
    local hit = res.Instance
    if not hit or not hit:IsA("BasePart") then return false, nil, nil end
    -- Ignore transparent parts (glass, fx, invisible colliders)
    if hit.Transparency >= 0.9 then return false, nil, nil end
    -- Ignore non-collidable parts (decorations, triggers)
    if not hit.CanCollide then return false, nil, nil end
    -- Ignore tiny decorative props (all 3 axes under 0.6)
    local s = hit.Size
    if s.X < 0.6 and s.Y < 0.6 and s.Z < 0.6 then return false, nil, nil end
    -- Ignore door panels — the door engine opens them; don't treat as permanent wall
    if DOOR_NAMES[hit.Name] then return false, nil, nil end
    local parent = hit.Parent
    if parent and (DOOR_NAMES[parent.Name]) then return false, nil, nil end
    return true, res.Position, res.Normal
end

function fanHits(origin, forward, angles, dist, params)
    local up   = Vector3.new(0, 1, 0)
    local hits = 0
    for _, ang in ipairs(angles) do
        local rad    = math.rad(ang)
        local rotDir = CFrame.fromAxisAngle(up, rad):VectorToWorldSpace(forward)
        if castRay(origin, rotDir, dist, params) then hits = hits + 1 end
    end
    return hits
end

end  -- close WALL_SCANNER_HELPERS section
-- ============================================================
-- 360° WALL SCANNER — Full surround scan
-- Returns a scored table of directions, sorted best (most open) first.
-- Each entry: { dir=Vector3, score=number, clearDist=number }
-- Uses multi-height, multi-angle sweeps to detect walls in all
-- directions and also checks for jump-through gaps (holes in walls).
-- ============================================================
do  -- 🔒 WALL_SCANNER section (scopes internal locals)
local SCAN_ANGLES_FULL = {}
do
    -- 36 directions = every 10 degrees
    for i = 0, 35 do SCAN_ANGLES_FULL[i+1] = i * 10 end
end

local SCAN_HEIGHTS  = { 0.3, 1.2, 2.0, 3.0 }   -- hip, chest, head, above-head
local SCAN_DIST_MIN = 3.0
SCAN_DIST_MAX = 9.0

-- Returns: { angle, hitFraction, hasGap, clearDist }
-- hitFraction = fraction of height samples that hit a wall (0=clear, 1=solid)
-- hasGap      = true if some heights clear but others blocked (jumpable hole)
-- clearDist   = shortest clear ray distance in this direction (how far we can go)
local function scanDirection(origin, dir, dist, params)
    local up = Vector3.new(0,1,0)
    local hits = 0
    local misses = 0
    local minClearDist = dist
    for _, hOff in ipairs(SCAN_HEIGHTS) do
        local o = origin + Vector3.new(0, hOff, 0)
        local blocked, hitPos = castRay(o, dir, dist, params)
        if blocked then
            hits = hits + 1
            if hitPos then
                local d = (hitPos - o).Magnitude
                if d < minClearDist then minClearDist = d end
            end
        else
            misses = misses + 1
        end
    end
    local total = hits + misses
    local hitFraction = hits / total
    local hasGap = hits > 0 and misses > 0  -- partial = gap (hole in wall)
    return hitFraction, hasGap, (misses > 0 and dist or minClearDist)
end

-- Full 360° environment scan. Returns directions sorted best→worst.
-- A direction is scored lower (better) if it has fewer wall hits.
-- Gaps (holes) get a bonus since the agent can jump through.
function scan360(origin, params, scanDist)
    scanDist = scanDist or SCAN_DIST_MAX
    local up = Vector3.new(0,1,0)
    -- Use a stable reference forward direction (world +Z)
    local refForward = Vector3.new(0, 0, 1)
    local results = {}
    for i, angleDeg in ipairs(SCAN_ANGLES_FULL) do
        local rad    = math.rad(angleDeg)
        local dir    = CFrame.fromAxisAngle(up, rad):VectorToWorldSpace(refForward)
        local hitFrac, hasGap, clearDist = scanDirection(origin, dir, scanDist, params)
        -- Score: lower = better. Gaps reduce score (passable with jump)
        local score = hitFrac - (hasGap and 0.25 or 0)
        table.insert(results, {
            angle     = angleDeg,
            dir       = dir,
            score     = score,
            hitFrac   = hitFrac,
            hasGap    = hasGap,
            clearDist = clearDist,
        })
    end
    -- Sort: best (most open) first
    table.sort(results, function(a, b) return a.score < b.score end)
    return results
end

-- Given a scan result table, find the best direction that is NOT
-- too close to the beast's direction and not heading back into a wall.
-- beastDir: optional Vector3 direction toward beast (to avoid fleeing toward it)
function bestOpenDir(scanResults, beastDir, minClearDist)
    minClearDist = minClearDist or SCAN_DIST_MIN
    for _, entry in ipairs(scanResults) do
        if entry.score < 0.55 and entry.clearDist >= minClearDist then
            -- Avoid moving toward beast
            if beastDir and beastDir.Magnitude > 0.1 then
                local dot = entry.dir:Dot(beastDir.Unit)
                if dot > 0.6 then continue end  -- this direction is toward beast
            end
            return entry.dir, entry
        end
    end
    -- Fallback: just take the most open direction
    return scanResults[1].dir, scanResults[1]
end

-- Validate that a path segment from 'from' to 'to' doesn't go through a wall.
-- Uses multi-height ray from origin toward destination.
-- Returns true if the path is clear.
local function pathSegmentClear(from, to, params)
    local dir = to - from
    local dist = dir.Magnitude
    if dist < 0.1 then return true end
    local hitFrac, hasGap, clearDist = scanDirection(from + Vector3.new(0, 0.5, 0), dir.Unit, dist + 1, params)
    -- Clear if hit fraction < 0.4, or it's a jumpable gap
    return hitFrac < 0.25 or (hasGap and clearDist >= dist * 0.8)
end

-- Find a detour point that goes AROUND a wall.
-- Tries arc of candidate points at different angles and distances.
local function findDetourAroundWall(from, blocked, params)
    local dir = (blocked - from)
    local dist = dir.Magnitude
    if dist < 0.1 then return nil end
    dir = dir.Unit
    local up = Vector3.new(0,1,0)

    -- Scan full 360 from current position at increasing distances
    local scanResults = scan360(from + Vector3.new(0, 1.0, 0), params, SCAN_DIST_MAX)

    -- Try candidate directions from scan, biased away from the blocked direction
    for _, entry in ipairs(scanResults) do
        if entry.score < 0.4 and entry.clearDist >= 4.0 then
            -- Don't pick directions that point back exactly where we came from
            -- (allow up to 120° from the blocked direction)
            local dot = entry.dir:Dot(dir)
            if dot > -0.3 then  -- mostly forward or sideways
                local candidate = from + entry.dir * math.min(entry.clearDist * 0.8, 7.0)
                -- Double-check the segment from candidate to destination is plausible
                if pathSegmentClear(from, candidate, params) then
                    return candidate
                end
            end
        end
    end
    return nil
end

end  -- close WALL_SCANNER section
-- ============================================================
-- PATH VISUALIZER
-- ============================================================
do  -- 🔒 PATH_VISUALIZER section (scopes internal locals)
local vizFolder  = nil
local vizEnabled = true

local VIZ_QUEUED  = Color3.fromRGB(0,   200, 255)
VIZ_ACTIVE  = Color3.fromRGB(0,   255, 80)
VIZ_BLOCKED = Color3.fromRGB(255, 60,  60)
local VIZ_ESCAPE  = Color3.fromRGB(255, 220, 0)
local VIZ_LINE    = Color3.fromRGB(60,  140, 255)
local VIZ_DETOUR  = Color3.fromRGB(255, 140, 0)

function vizInit()
    pcall(function()
        local old = workspace:FindFirstChild("_PF_VizFolder")
        if old then old:Destroy() end
    end)
    vizFolder = Instance.new("Folder")
    vizFolder.Name   = "_PF_VizFolder"
    vizFolder.Parent = workspace
end

function vizClear()
    if vizFolder then
        for _, c in ipairs(vizFolder:GetChildren()) do c:Destroy() end
    end
end

local function vizNode(pos, color, size)
    if not vizEnabled or not vizFolder then return nil end
    size = size or 0.65
    local p = Instance.new("Part")
    p.Name         = "VN"
    p.Shape        = Enum.PartType.Ball
    p.Size         = Vector3.new(size, size, size)
    p.Position     = pos
    p.Anchored     = true
    p.CanCollide   = false
    p.CastShadow   = false
    p.Material     = Enum.Material.Neon
    p.Color        = color
    p.Transparency = 0.12
    p.Parent       = vizFolder
    return p
end

local function vizLine(a, b, color)
    if not vizEnabled or not vizFolder then return end
    local len = (b - a).Magnitude
    if len < 0.1 then return end
    local p = Instance.new("Part")
    p.Name         = "VL"
    p.Size         = Vector3.new(0.14, 0.14, len)
    p.CFrame       = CFrame.lookAt((a+b)/2, b)
    p.Anchored     = true
    p.CanCollide   = false
    p.CastShadow   = false
    p.Material     = Enum.Material.Neon
    p.Color        = color or VIZ_LINE
    p.Transparency = 0.4
    p.Parent       = vizFolder
end

function vizDrawPath(waypoints)
    vizClear()
    local nodes = {}
    local prev  = nil
    for i, wp in ipairs(waypoints) do
        nodes[i] = vizNode(wp.Position, VIZ_QUEUED)
        if prev then vizLine(prev, wp.Position, VIZ_LINE) end
        prev = wp.Position
    end
    return nodes
end

function vizSetColor(node, color)
    if node and node.Parent then node.Color = color end
end

function vizMarkEscape(pos)
    -- Clear previous escape markers so only one target sphere exists at a time
    if vizFolder then
        for _, c in ipairs(vizFolder:GetChildren()) do
            if c.Name == "VE" then c:Destroy() end
        end
    end
    local p = vizNode(pos, VIZ_ESCAPE, 1.0)
    if p then p.Name = "VE" end  -- tag escape nodes so we can selectively clear them
end

local function vizMarkDetour(pos)
    vizNode(pos, VIZ_DETOUR, 0.9)
end

end  -- close PATH_VISUALIZER section
-- ============================================================
-- AUTO INTERACT ENGINE (Door + ExitDoor — from zyxlab pattern)
-- Handles: SingleDoor, DoubleDoor, ExitDoor, ComputerTable
-- ============================================================
do
    local Remote = ReplicatedStorage:WaitForChild("RemoteEvent")

    local interactCache    = {}
    local lastCacheUpdate  = 0
    local lastTrigger      = nil
    local lastActionTick   = 0
    local lastComputerTick = 0
    local autoInteractConn = nil

    local ACTION_CD   = 0.05
    local COMPUTER_CD = 0.1

    local function fireTrigger(triggerPart, state)
        local ev = triggerPart and triggerPart:FindFirstChild("Event")
        if not ev then return end
        pcall(function() Remote:FireServer("Input", "Trigger", state, ev) end)
    end

    local function fireAction(state)
        pcall(function() Remote:FireServer("Input", "Action", state) end)
    end

    local function updateInteractCache()
        interactCache = {}
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("Model") then
                -- Doors, ExitDoor, FreezePod
                if obj.Name == "SingleDoor" or obj.Name == "DoubleDoor"
                or obj.Name == "ExitDoor"   or obj.Name == "FreezePod" then
                    local tName = (obj.Name == "FreezePod"  and "PodTrigger")
                               or (obj.Name == "ExitDoor"   and "ExitDoorTrigger")
                               or "DoorTrigger"
                    local trigger = obj:FindFirstChild(tName, true)
                    if trigger then
                        local tp = getTriggerPart(trigger)
                        if tp then
                            table.insert(interactCache, {
                                Trigger    = tp,
                                Root       = tp,
                                IsComputer = false,
                                IsExit     = (obj.Name == "ExitDoor"),
                            })
                        end
                    end
                -- ComputerTable
                elseif obj.Name == "ComputerTable" then
                    for _, child in ipairs(obj:GetDescendants()) do
                        if child.Name:find("ComputerTrigger") and child:FindFirstChild("Event") then
                            table.insert(interactCache, {
                                Trigger    = child,
                                Root       = child,
                                IsComputer = true,
                                IsExit     = false,
                            })
                        end
                    end
                end
            end
        end
    end

    local function getNearestInteract(maxRange)
        local ch  = getChar()
        local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
        if not hrp then return nil end
        maxRange = maxRange or 7
        local closest, minDist = nil, maxRange
        for _, data in ipairs(interactCache) do
            if data.Trigger and data.Trigger.Parent then
                local ok, rp = pcall(function()
                    return data.Root:IsA("BasePart") and data.Root.Position
                        or data.Root:GetPivot().Position
                end)
                if ok and rp then
                    local d = (hrp.Position - rp).Magnitude
                    if d < minDist then minDist = d; closest = data end
                end
            end
        end
        return closest
    end

    function pf.startDoorEngine(includeExit)
        if autoInteractConn then return end
        updateInteractCache()
        lastCacheUpdate = tick()
        autoInteractConn = RunService.Heartbeat:Connect(function()
            local now = tick()
            if now - lastCacheUpdate > 2 then
                updateInteractCache()
                lastCacheUpdate = now
            end
            local nearest = getNearestInteract(7)
            if nearest then
                if lastTrigger ~= nearest.Trigger then
                    if lastTrigger then fireTrigger(lastTrigger, false) end
                    fireTrigger(nearest.Trigger, true)
                    lastTrigger = nearest.Trigger
                end
                if nearest.IsComputer then
                    if now - lastComputerTick > COMPUTER_CD then
                        fireAction(true)
                        lastComputerTick = now
                    end
                else
                    -- Door, ExitDoor, FreezePod
                    if now - lastActionTick > ACTION_CD then
                        fireAction(true)
                        lastActionTick = now
                    end
                end
            else
                if lastTrigger then
                    fireTrigger(lastTrigger, false)
                    lastTrigger = nil
                end
            end
        end)
    end

    function pf.stopDoorEngine()
        if autoInteractConn then
            autoInteractConn:Disconnect()
            autoInteractConn = nil
        end
        if lastTrigger then
            fireTrigger(lastTrigger, false)
            lastTrigger = nil
        end
        interactCache = {}
    end
end

-- ============================================================
-- PC FAST HACK ENGINE
-- ============================================================
do
    local Remote = ReplicatedStorage:WaitForChild("RemoteEvent")
    local pcInteractCache   = {}
    local pcLastCacheUpdate = 0
    local pcLastTrigger     = nil
    local pcLastCompTick    = 0
    local pcLastCrawlTick   = 0
    local pcIsHacking       = false
    local pcIsCrawling      = false
    local pcConn            = nil

    local crawlAnim = Instance.new("Animation")
    crawlAnim.AnimationId = "rbxassetid://961932719"
    local loadedAnim = nil

    local function pcFireTrigger(tp, state)
        local ev = tp and tp:FindFirstChild("Event")
        if not ev then return end
        pcall(function() Remote:FireServer("Input","Trigger",state,ev) end)
    end
    local function pcFireAction(state)
        pcall(function() Remote:FireServer("Input","Action",state) end)
    end
    local function resetCrawl()
        if pcIsCrawling then
            pcall(function() Remote:FireServer("Input","Crawl",false) end)
            pcIsCrawling = false
        end
        if loadedAnim then loadedAnim:Stop() end
        local hum = player.Character and player.Character:FindFirstChild("Humanoid")
        if hum then hum.HipHeight = 0 end
    end
    local function stealthPop()
        local char = player.Character
        local hum  = char and char:FindFirstChild("Humanoid")
        if not hum or pcIsCrawling then return end
        pcIsCrawling = true
        if not loadedAnim then loadedAnim = hum:LoadAnimation(crawlAnim) end
        pcall(function() Remote:FireServer("Input","Crawl",true) end)
        hum.HipHeight = -2
        loadedAnim:Play()
        task.wait(0.3)
        resetCrawl()
    end
    local function pcUpdateCache()
        pcInteractCache = {}
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("Model") and obj.Name == "ComputerTable" then
                for _, child in ipairs(obj:GetDescendants()) do
                    if child.Name:find("ComputerTrigger") and child:FindFirstChild("Event") then
                        table.insert(pcInteractCache, { Trigger = child, Root = child })
                    end
                end
            end
        end
    end
    local function pcGetNearest()
        local ch  = player.Character
        local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
        if not hrp then return nil end
        local best, bd = nil, 7
        for _, data in ipairs(pcInteractCache) do
            if data.Trigger and data.Trigger.Parent then
                local ok, rp = pcall(function()
                    return data.Root:IsA("BasePart") and data.Root.Position
                        or data.Root:GetPivot().Position
                end)
                if ok and rp then
                    local d = (hrp.Position - rp).Magnitude
                    if d < bd then bd = d; best = data end
                end
            end
        end
        return best
    end
    function pf.startFastHack()
        if pcConn then return end
        pcUpdateCache(); pcLastCacheUpdate = tick()
        pcConn = RunService.Heartbeat:Connect(function()
            local now = tick()
            if now - pcLastCacheUpdate > 2 then pcUpdateCache(); pcLastCacheUpdate = now end
            local nearest = pcGetNearest()
            if nearest then
                if pcLastTrigger ~= nearest.Trigger then
                    if pcLastTrigger then pcFireTrigger(pcLastTrigger, false) end
                    pcFireTrigger(nearest.Trigger, true)
                    pcLastTrigger   = nearest.Trigger
                    pcIsHacking     = true
                    pcLastCrawlTick = now
                end
                if now - pcLastCompTick > 0.1 then
                    pcFireAction(true); pcLastCompTick = now
                end
                if now - pcLastCrawlTick > 3 then
                    task.spawn(stealthPop); pcLastCrawlTick = now
                end
            else
                if pcLastTrigger then pcFireTrigger(pcLastTrigger, false); pcLastTrigger = nil end
                if pcIsHacking   then pcIsHacking = false; resetCrawl() end
            end
        end)
    end
    function pf.stopFastHack()
        if pcConn then pcConn:Disconnect(); pcConn = nil end
        resetCrawl()
        if pcLastTrigger then pcFireTrigger(pcLastTrigger, false); pcLastTrigger = nil end
        pcIsHacking = false
    end
end

-- ============================================================
-- WALL SENTINEL — Continuous wall detection
-- Uses 360° fan rather than just forward/look vectors.
-- Now also detects being "pinned" (velocity near zero but target far).
-- ============================================================
local wallSentinel = {
    triggered    = false,
    escapeDir    = Vector3.new(0,0,0),
    _conn        = nil,
    _rcParams    = nil,
    _hitFrames   = 0,
    _scanResult  = nil,   -- full 360 scan cache
    _scanAt      = 0,
}

-- How many forward+side rays need to hit before we declare "wall"
-- Raised from 3→5 so corners and door frames don't panic-trigger
local S_FORWARD_HIT_THRESH = 5  -- out of 7 forward fan rays
local S_MIN_SPEED          = 0.8 -- ignore sentinel when barely moving (e.g. rotating in place)
-- Re-scan 360 every N seconds (expensive, only when actually stuck)
local S_FULL_SCAN_INTERVAL = 0.6
-- Require this many consecutive hit-frames before declaring wall
-- Raised from 2→4 to ignore momentary corner clips
local S_HIT_FRAMES_THRESH  = 4

-- Forward fan angles
local S_FWD_FAN = {0, 15, -15, 30, -30, 50, -50}
local S_BASE_DIST = 4.5

function wallSentinel.start(rcParams)
    wallSentinel.triggered  = false
    wallSentinel.escapeDir  = Vector3.new(0,0,0)
    wallSentinel._rcParams  = rcParams
    wallSentinel._hitFrames = 0
    wallSentinel._scanResult = nil
    wallSentinel._scanAt     = 0
    if wallSentinel._conn then wallSentinel._conn:Disconnect() end

    wallSentinel._conn = RunService.Heartbeat:Connect(function()
        if wallSentinel.triggered then return end

        local root = getRoot()
        local hum  = getHum()
        if not root or not hum then return end
        if hum:GetState() == Enum.HumanoidStateType.Dead then return end

        local vel      = root.AssemblyLinearVelocity
        local speed    = Vector3.new(vel.X, 0, vel.Z).Magnitude
        local rayDist  = math.max(S_BASE_DIST, speed * 0.65)

        local chestOrigin = root.Position + Vector3.new(0, 1.5, 0)

        -- Check forward direction hits
        local forwardDir = nil
        local hits = 0

        if speed >= S_MIN_SPEED then
            forwardDir = Vector3.new(vel.X, 0, vel.Z).Unit
            hits = fanHits(chestOrigin, forwardDir, S_FWD_FAN, rayDist, rcParams)
        else
            -- Use look direction if barely moving
            local lookDir = root.CFrame.LookVector
            local lookFlat = Vector3.new(lookDir.X, 0, lookDir.Z)
            if lookFlat.Magnitude > 0.01 then
                forwardDir = lookFlat.Unit
                hits = fanHits(chestOrigin, forwardDir, S_FWD_FAN, rayDist * 0.7, rcParams)
            end
        end

        if hits >= S_FORWARD_HIT_THRESH then
            wallSentinel._hitFrames = wallSentinel._hitFrames + 1
            if wallSentinel._hitFrames >= S_HIT_FRAMES_THRESH then
                -- Do a full 360 scan to find the best escape direction
                local now = os.clock()
                if not wallSentinel._scanResult or now - wallSentinel._scanAt > S_FULL_SCAN_INTERVAL then
                    wallSentinel._scanResult = scan360(root.Position + Vector3.new(0, 1.0, 0), rcParams, SCAN_DIST_MAX)
                    wallSentinel._scanAt = now
                end
                -- Pick escape dir: most open direction, away from beast if possible
                local beastPos = getBeastPos()
                local beastDir = beastPos and (beastPos - root.Position) or nil
                local escDir = bestOpenDir(wallSentinel._scanResult, beastDir, 3.0)
                wallSentinel.escapeDir = escDir
                wallSentinel.triggered = true
            end
        else
            wallSentinel._hitFrames = 0
        end
    end)
end

function wallSentinel.stop()
    if wallSentinel._conn then
        wallSentinel._conn:Disconnect()
        wallSentinel._conn = nil
    end
    wallSentinel.triggered  = false
    wallSentinel._hitFrames = 0
    wallSentinel._scanResult = nil
end

function wallSentinel.reset()
    wallSentinel.triggered   = false
    wallSentinel.escapeDir   = Vector3.new(0,0,0)
    wallSentinel._hitFrames  = 0
    wallSentinel._scanResult = nil
end

-- ============================================================
-- ESCAPE MANOEUVRE — TP to a nearby non-beast survivor
-- Avoids the buggy floor-raycast approach that was landing on
-- roofs or falling out of the map. A living survivor's HRP is
-- always a valid floor position by definition.
-- ============================================================
local lastEscapePos = nil

local function getSurvivorRoot()
    -- Returns the HumanoidRootPart of the nearest player who:
    --   • is not us
    --   • does not have Players/<name>/TempPlayerStatsModule/IsBeast = true
    --   • is alive (Humanoid.Health > 0)
    local myPlayer = player
    local bestRoot = nil
    local bestDist = math.huge
    local myRoot   = getRoot()

    for _, p in ipairs(game:GetService("Players"):GetPlayers()) do
        if p == myPlayer then continue end

        -- IsBeast check
        local statsModule = p:FindFirstChild("TempPlayerStatsModule")
        if statsModule then
            local isBeastVal = statsModule:FindFirstChild("IsBeast")
            if isBeastVal and isBeastVal:IsA("BoolValue") and isBeastVal.Value == true then
                continue  -- skip beasts
            end
        end

        local char = p.Character
        if not char then continue end
        local hrp  = char:FindFirstChild("HumanoidRootPart")
        local hum  = char:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum then continue end
        if hum.Health <= 0 then continue end

        local dist = myRoot and (myRoot.Position - hrp.Position).Magnitude or math.huge
        if dist < bestDist then
            bestDist = dist
            bestRoot = hrp
        end
    end

    return bestRoot
end

local function doEscape(rcParams)
    local root = getRoot()
    if not root or not pf.enabled or pf.abortWalk then return end

    setStatus("⚠ Stuck! Finding escape...")

    -- Primary: teleport to a nearby survivor
    local survivorHRP = getSurvivorRoot()
    if survivorHRP then
        -- Offset slightly so we don't overlap them exactly
        local offset = Vector3.new(math.random(-3, 3), 0, math.random(-3, 3))
        local landPos = survivorHRP.Position + offset
        vizMarkEscape(landPos)
        lastEscapePos = landPos
        setStatus("⚠ TPing to survivor...")
        local r = getRoot()
        if r then
            r.CFrame = CFrame.new(landPos)
            r.AssemblyLinearVelocity = Vector3.zero
        end
        task.wait(0.3)
        return
    end

    -- Fallback: use last known safe escape position
    if lastEscapePos then
        local dist = (lastEscapePos - root.Position).Magnitude
        if dist > 3.0 and dist < 80 then
            setStatus("⚠ TPing to last escape pos...")
            vizMarkEscape(lastEscapePos)
            local r = getRoot()
            if r then
                r.CFrame = CFrame.new(lastEscapePos)
                r.AssemblyLinearVelocity = Vector3.zero
            end
            task.wait(0.3)
            return
        end
    end

    -- Last resort: scan for a valid floor spot close by (capped ray to avoid roof hits)
    local scanResults = scan360(root.Position + Vector3.new(0, 1.0, 0), rcParams, SCAN_DIST_MAX)
    local beastPos    = getBeastPos()
    local beastDir    = beastPos and (beastPos - root.Position) or nil
    local escDir      = bestOpenDir(scanResults, beastDir, 3.0)

    local candidates = {}
    if escDir then
        table.insert(candidates, root.Position + escDir * 5)
    end
    for _ = 1, 12 do
        local a = math.rad(math.random(0, 359))
        local d = math.random(40, 80) / 10
        table.insert(candidates, root.Position + Vector3.new(math.cos(a)*d, 0, math.sin(a)*d))
    end

    local landPos = nil
    for _, candidate in ipairs(candidates) do
        -- Cast DOWN only 8 studs (not 14) — prevents roof hits on low-ceiling maps
        local above    = candidate + Vector3.new(0, 2, 0)
        local floorHit = workspace:Raycast(above, Vector3.new(0, -8, 0), rcParams)
        if not floorHit then continue end

        -- Y-sanity: must be within 6 studs of current Y (no teleporting to a different floor)
        local hitY = floorHit.Position.Y
        if math.abs(hitY - root.Position.Y) > 6 then continue end

        local lp = floorHit.Position + Vector3.new(0, 2.5, 0)
        local horizDir = Vector3.new(candidate.X - root.Position.X, 0, candidate.Z - root.Position.Z)
        local wallHit  = workspace:Raycast(root.Position + Vector3.new(0, 1, 0), horizDir, rcParams)
        local clear    = not wallHit or (wallHit.Position - root.Position).Magnitude > horizDir.Magnitude * 0.85
        if clear then landPos = lp; break end
    end

    landPos = landPos or (root.Position + Vector3.new(math.random(-4,4), 0, math.random(-4,4)))
    vizMarkEscape(landPos)
    lastEscapePos = landPos
    setStatus("⚠ Escape TP (floor scan)...")
    local r = getRoot()
    if r then
        r.CFrame = CFrame.new(landPos)
        r.AssemblyLinearVelocity = Vector3.zero
    end
    task.wait(0.3)
end

-- ============================================================
-- WALK TO — Smart navigation with local steering
-- ============================================================
-- Recovery ladder (exhausted in order before recomputing):
--   1. Jump — try jumping over small obstacle/ledge
--   2. Sidestep — strafe left/right to slip around corner
--   3. Back-up — reverse a stud then re-approach from slightly different angle
--   4. Repath — recompute with jittered origin (different route guaranteed)
--   5. Emergency TP — only after several full repath failures
--
-- Door handling:
--   Waypoints that approach a SingleDoor/DoubleDoor are not treated
--   as walls — the door engine fires the interact event to open them.
--   We give doors extra approach time so they can animate open.
--
-- Wall detection:
--   Uses the smarter castRay (ignores tiny props, door panels, transparent)
--   and requires HIGH confidence (many rays) before declaring blocked.
--   False positives from corners / doorframes are suppressed.
--
-- Jumping:
--   Besides PathWaypointAction.Jump, we proactively jump when a forward
--   low-height raycast hits an obstacle but a higher ray clears it —
--   signature of a ledge, stair lip, or vent bump.
-- ============================================================
local function walkTo(targetPos)
    local ARRIVE_DIST      = 4.0
    local MAX_RECOMPUTES   = 10   -- calmer; less spammy
    local WP_TIMEOUT       = 7.0  -- per-waypoint timeout (longer = less twitchy)
    local STUCK_SECS       = 3.5  -- genuine stuck threshold (was 2.0 — too fast)
    local STUCK_MOVE       = 1.2  -- studs needed in STUCK_SECS to not be "stuck"
    local DOOR_EXTRA_TIME  = 2.0  -- wait for door to fully open (2 s is enough)
    local DOOR_RADIUS      = 6.0  -- detection radius for SingleDoor/DoubleDoor
    -- Wall confidence: needs THIS many total ray hits across heights to be "solid"
    -- Higher = fewer false positives from corners/doorframes
    local WALL_HIT_THRESH  = 10   -- across 4 heights × 5 angles = max 20

    vizInit()

    local rcParams = RaycastParams.new()
    rcParams.FilterType = Enum.RaycastFilterType.Exclude
    rcParams.FilterDescendantsInstances = buildExclude()

    wallSentinel.start(rcParams)
    pf.abortWalk = false

    -- Returns true if 'pos' is near a door (SingleDoor or DoubleDoor).
    -- Used to skip wall-blocking checks near doors and extend timeouts.
    local function nearDoor(pos, radius)
        radius = radius or DOOR_RADIUS
        local map = getMap()
        if not map then return false end
        for _, obj in ipairs(map:GetDescendants()) do
            if obj:IsA("Model") and (obj.Name == "SingleDoor" or obj.Name == "DoubleDoor") then
                local ok, pivot = pcall(function() return obj:GetPivot().Position end)
                if ok and (pos - pivot).Magnitude < radius then return true end
            end
        end
        return false
    end

    -- Returns true if there's a window-like obstacle ahead: solid at ankle/waist
    -- but open above (head clears). Windows are jumpable — we detect and jump them.
    local function isWindowAhead(from, to)
        local dir  = (to - from)
        local dist = math.min(dir.Magnitude, 6.0)
        if dist < 1.0 then return false end
        local fwd = dir.Unit
        -- Ankle (0.5) and waist (1.4) blocked, but head (2.8) clear = window ledge
        local ankleBlocked = castRay(from + Vector3.new(0, 0.5, 0), fwd, dist, rcParams)
        local waistBlocked = castRay(from + Vector3.new(0, 1.4, 0), fwd, dist, rcParams)
        local headBlocked  = castRay(from + Vector3.new(0, 2.8, 0), fwd, dist, rcParams)
        return ankleBlocked and waistBlocked and not headBlocked
    end

    -- Solid wall check. High threshold to avoid false positives.
    -- Skips check entirely if waypoint is near a door (door engine handles it).
    local function wallBlocking(from, to)
        local dir  = to - from
        local dist = dir.Magnitude
        if dist < 0.1 then return false end
        -- Near a door: never report blocked — the door engine will open it
        if nearDoor(to, 5) then return false end
        local fwd      = dir.Unit
        local checkDist = math.min(dist + 1.0, 7.0)
        local orig     = from + Vector3.new(0, 1.2, 0)
        local totalHits = 0
        -- 4 heights × 5 angles = max 20 rays. Need >WALL_HIT_THRESH to confirm solid.
        for _, yOff in ipairs({0.0, 0.9, 1.8, 2.7}) do
            local o = orig + Vector3.new(0, yOff, 0)
            totalHits = totalHits + fanHits(o, fwd, {0, 20, -20, 40, -40}, checkDist, rcParams)
        end
        return totalHits > WALL_HIT_THRESH
    end

    -- Proactive jump detection: a ledge/stair lip blocks at ankle height but
    -- clears at waist height — jumping will clear it.
    -- Returns true if jumping would likely help.
    local function shouldJump(from, to)
        local dir  = (to - from)
        local dist = math.min(dir.Magnitude, 5.0)
        if dist < 0.5 then return false end
        local fwd  = dir.Unit
        local orig = from + Vector3.new(0, 0.5, 0)  -- ankle height
        local ankleBlocked = castRay(orig, fwd, dist, rcParams)
        if not ankleBlocked then return false end     -- nothing at ankle → no ledge
        -- Check waist height — if clear, this is a jumpable ledge
        local waistOrig = from + Vector3.new(0, 2.5, 0)
        local waistBlocked = castRay(waistOrig, fwd, dist, rcParams)
        -- Ankle blocked + waist clear = ledge. Ankle blocked + waist blocked = real wall.
        return not waistBlocked
    end

    -- LOCAL RECOVERY — only does a jump attempt if geometry suggests it'll help.
    -- Does NOT sidestep. Returns true if jump moved us, false otherwise.
    -- Caller should repath immediately after this returns false.
    local function tryJumpRecovery(from, toward)
        local hum = getHum()
        if not hum then return false end
        if shouldJump(from, toward) or isWindowAhead(from, toward) then
            setStatus("↑ Jump recovery...")
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
            task.wait(0.35)
            hum:MoveTo(toward)
            task.wait(0.55)
            local r = getRoot()
            if r and (r.Position - from).Magnitude > 1.5 then return true end
        end
        return false
    end

    local jitter         = Vector3.new(0, 0, 0)
    local repathCount    = 0   -- how many full repaths done
    local MAX_TP_AFTER   = 6   -- only emergency-TP after this many repath failures

    for attempt = 1, MAX_RECOMPUTES do
        if not pf.enabled or pf.abortWalk then
            wallSentinel.stop(); vizClear(); return false
        end

        wallSentinel.reset()
        rcParams.FilterDescendantsInstances = buildExclude()

        local hum  = getHum()
        local root = getRoot()
        if not hum or not root then wallSentinel.stop(); vizClear(); return false end

        if (root.Position - targetPos).Magnitude <= ARRIVE_DIST then
            wallSentinel.stop(); vizClear(); return true
        end

        local computeOrigin = root.Position + jitter
        jitter = Vector3.new(0, 0, 0)

        -- Wider agent radius smooths corners (less hugging)
        -- Larger waypoint spacing = fewer micro-corrections = smoother movement
        local path = PathfindingService:CreatePath({
            AgentRadius     = 2.0,   -- was 1.5 — slightly wider avoids corner hugging
            AgentHeight     = 5,
            AgentCanJump    = true,
            AgentCanClimb   = false,
            WaypointSpacing = 4.0,   -- was 2.5 — bigger spacing = smoother, less jitter
        })

        local ok = pcall(function() path:ComputeAsync(computeOrigin, targetPos) end)

        if not ok or path.Status ~= Enum.PathStatus.Success then
            repathCount = repathCount + 1
            setStatus("⚠ No path (" .. repathCount .. ") — jitter repath...")
            if repathCount >= MAX_TP_AFTER then
                setStatus("⚠ Emergency TP after " .. repathCount .. " failures")
                doEscape(rcParams)
                repathCount = 0
            end
            jitter = Vector3.new(math.random(-4,4), 0, math.random(-4,4))
            wallSentinel.reset()
            task.wait(0.2)
            continue
        end

        local waypoints = path:GetWaypoints()
        if #waypoints == 0 then
            jitter = Vector3.new(math.random(-4,4), 0, math.random(-4,4))
            wallSentinel.reset()
            continue
        end

        local vizNodes   = vizDrawPath(waypoints)
        setStatus("Walking (" .. attempt .. "/" .. MAX_RECOMPUTES .. ")...")

        local needRepath = false
        local i = 1

        while i <= #waypoints do
            if not pf.enabled or pf.abortWalk then
                wallSentinel.stop(); vizClear(); return false
            end

            if wallSentinel.triggered then
                pcall(function() conn:Disconnect() end)
                local r = getRoot()
                -- Try a quick jump in case it's a ledge, then force a fresh repath
                if r then tryJumpRecovery(r.Position, wp.Position) end
                wallSentinel.reset()
                needRepath = true; break
            end

            local wp      = waypoints[i]
            local curRoot = getRoot()
            if not curRoot then wallSentinel.stop(); vizClear(); return false end

            -- Skip waypoints we're already past
            if (curRoot.Position - wp.Position).Magnitude < 1.8 then
                if vizNodes[i] then vizSetColor(vizNodes[i], VIZ_ACTIVE) end
                i = i + 1; continue
            end

            local isJump    = (wp.Action == Enum.PathWaypointAction.Jump)
            local isDoorArea = nearDoor(wp.Position, DOOR_RADIUS)

            -- If this waypoint is at a door, pause briefly to let the door engine
            -- open it before we try to walk through (2 s max wait).
            if isDoorArea then
                local doorWaitStart = tick()
                while tick() - doorWaitStart < DOOR_EXTRA_TIME do
                    task.wait(0.1)
                    if not pf.enabled or pf.abortWalk then break end
                    -- If we're already through (fast door) don't over-wait
                    local r2 = getRoot()
                    if r2 and (r2.Position - wp.Position).Magnitude < ARRIVE_DIST then break end
                end
            end

            -- PROACTIVE WALL CHECK — high confidence required, doors skipped
            -- Only run for non-jump waypoints that aren't near a door
            if not isJump and not isDoorArea then
                if wallBlocking(curRoot.Position, wp.Position) then
                    -- Try a jump first (might be a ledge), then repath regardless
                    tryJumpRecovery(curRoot.Position, wp.Position)
                    if vizNodes[i] then vizSetColor(vizNodes[i], VIZ_BLOCKED) end
                    needRepath = true; break
                end
            end

            -- PROACTIVE JUMP — ledge/vent/stair/window detection independent of waypoint action
            -- Fires for: classic ankle-blocked ledge OR window-height obstacle (jumpable sill)
            if not isJump and (shouldJump(curRoot.Position, wp.Position) or isWindowAhead(curRoot.Position, wp.Position)) then
                hum = getHum()
                if hum then
                    setStatus("↑ Jumping (ledge/window)...")
                    hum:ChangeState(Enum.HumanoidStateType.Jumping)
                    task.wait(0.2)
                end
            end

            if vizNodes[i] then vizSetColor(vizNodes[i], VIZ_ACTIVE) end
            hum = getHum()
            if not hum then wallSentinel.stop(); vizClear(); return false end
            if isJump then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
            hum:MoveTo(wp.Position)

            local reached = false
            local conn
            conn = hum.MoveToFinished:Connect(function(r)
                reached = r; pcall(function() conn:Disconnect() end)
            end)

            -- Doors get extra time — they need to animate open before we can pass
            local timeout    = isDoorArea and (WP_TIMEOUT + DOOR_EXTRA_TIME) or WP_TIMEOUT
            local wpDeadline = tick() + timeout
            local stuckStart = tick()
            local stuckOrigin = curRoot.Position

            while not reached and pf.enabled and not pf.abortWalk and tick() < wpDeadline do
                task.wait(0.05)

                if wallSentinel.triggered then
                    pcall(function() conn:Disconnect() end)
                    local r = getRoot()
                    if r then tryJumpRecovery(r.Position, wp.Position) end
                    wallSentinel.reset()
                    needRepath = true; break
                end

                local nowRoot = getRoot()
                if not nowRoot then break end

                local disp = (nowRoot.Position - stuckOrigin).Magnitude
                if disp >= STUCK_MOVE then
                    -- Made progress — re-check wall ahead (skip near doors)
                    if not isJump and not isDoorArea and
                       wallBlocking(nowRoot.Position, wp.Position) then
                        pcall(function() conn:Disconnect() end)
                        tryJumpRecovery(nowRoot.Position, wp.Position)
                        needRepath = true; break
                    end
                    stuckStart  = tick()
                    stuckOrigin = nowRoot.Position
                elseif tick() - stuckStart >= STUCK_SECS then
                    -- Genuinely stuck — force a fresh path calculation immediately
                    pcall(function() conn:Disconnect() end)
                    setStatus("⚠ Stuck — repathing now")
                    needRepath = true; break
                end
            end

            pcall(function() conn:Disconnect() end)
            if not pf.enabled or pf.abortWalk then
                wallSentinel.stop(); vizClear(); return false
            end
            if needRepath then break end

            i = i + 1
        end

        if needRepath then
            repathCount = repathCount + 1
            wallSentinel.reset()
            -- Only emergency-TP after many repath failures — not eagerly
            if repathCount >= MAX_TP_AFTER then
                setStatus("⚠ Emergency TP (" .. repathCount .. " repaths failed)")
                doEscape(rcParams)
                repathCount    = 0
                steeringFails  = 0
            end
            -- Jitter guarantees a different path next compute
            jitter = Vector3.new(math.random(-4,4), 0, math.random(-4,4))
            task.wait(0.15)
        else
            local finalRoot = getRoot()
            local arrived   = finalRoot and (finalRoot.Position - targetPos).Magnitude <= ARRIVE_DIST * 2
            wallSentinel.stop(); vizClear()
            return arrived
        end
    end

    wallSentinel.stop(); vizClear()
    return false
end

-- ============================================================
-- EXIT DOOR ENGINE
-- ============================================================
do  -- 🔒 EXIT_DOOR section (scopes internal locals)
exitEngine = {
    enabled    = false,
    thread     = nil,
    _skipList  = {},
    _nextTry   = 0,
    _escaped   = false,
}

function exitLocalEscaped()
    local stats = player:FindFirstChild("TempPlayerStatsModule")
    local v = stats and stats:FindFirstChild("Escaped")
    return v and v.Value == true
end

local function exitDoorOpen(door)
    local light = door and (door:FindFirstChild("Light") or door:FindFirstChild("Light", true))
    if not light then return false end
    local ok, color = pcall(function() return light.Color end)
    return ok and color == Color3.fromRGB(0, 255, 0)
end

local function exitDoorTrigger(door)
    local t = door and (
        door:FindFirstChild("ExitDoorTrigger") or
        door:FindFirstChild("ExitDoorTrigger", true)
    )
    if not t then return nil end
    if t:IsA("BasePart") then return t end
    return t:FindFirstChildWhichIsA("BasePart", true)
end

local function exitDoorArea(door)
    local area = door and (
        door:FindFirstChild("ExitArea") or
        door:FindFirstChild("ExitArea", true)
    )
    if area and area:IsA("BasePart") then return area end
end

local function exitDoorPosition(door)
    if not door then return nil end
    local trigger = exitDoorTrigger(door)
    if trigger then return trigger.Position end
    local area = exitDoorArea(door)
    if area then return area.Position end
    if door:IsA("Model") then
        local pp = door.PrimaryPart or door:FindFirstChildWhichIsA("BasePart", true)
        return pp and pp.Position
    end
    return nil
end

local function getAllExitDoors()
    local map = getMap()
    if not map then return {} end
    local doors = {}
    for _, obj in ipairs(map:GetChildren()) do
        if obj.Name == "ExitDoor" then
            table.insert(doors, obj)
        end
    end
    return doors
end

local function findBestExit(doors)
    local root = getRoot()
    if not root then return nil end

    local bestOpen, bestOpenDist = nil, math.huge
    local bestAny,  bestAnyDist  = nil, math.huge

    for _, door in ipairs(doors) do
        if not door:IsDescendantOf(workspace) then continue end
        if exitEngine._skipList[door] and os.clock() < exitEngine._skipList[door] then continue end

        local pos = exitDoorPosition(door)
        if not pos then continue end

        -- Skip if beast is within AVOID_MAX of the door or its area
        if beastNear(pos, beast.AVOID_MAX) then continue end
        local area = exitDoorArea(door)
        if area and beastNear(area.Position, beast.AVOID_MAX) then continue end
        local trigger = exitDoorTrigger(door)
        if trigger and beastNear(trigger.Position, beast.AVOID_MAX) then continue end

        local dist = (root.Position - pos).Magnitude

        if exitDoorOpen(door) then
            if dist < bestOpenDist then bestOpenDist = dist; bestOpen = door end
        else
            if dist < bestAnyDist then bestAnyDist = dist; bestAny = door end
        end
    end

    return bestOpen or bestAny
end

-- Open exit door via server Remote (zyxlab aioOpenExit pattern)
local function openExitDoor(door)
    local root    = getRoot()
    local trigger = exitDoorTrigger(door)
    local ev      = getRemote()
    if not root or not trigger or not ev then return false end
    root.CFrame = trigger.CFrame + Vector3.new(0, 3, 0)
    task.wait(0.35)
    ev:FireServer("Input", "Action", true)
    return true
end

-- Touch the ExitArea to actually escape (zyxlab aioEscapeDoor pattern)
local function touchExitArea(door)
    local root = getRoot()
    local area = exitDoorArea(door)
    if not root or not area then return false end

    if beastNear(area.Position, beast.AVOID_MAX) then
        exitEngine._skipList[door] = os.clock() + 6
        return false
    end

    root.CFrame = area.CFrame + Vector3.new(0, 3, 0)

    local touch = area:FindFirstChild("TouchInterest") or area:FindFirstChildOfClass("TouchTransmitter")
    if touch and firetouchinterest then
        firetouchinterest(root, area, 0)
        task.wait()
        firetouchinterest(root, area, 1)
    end

    task.wait(2)
    exitEngine._escaped = true
    return true
end

-- Main auto-exit loop
local function runAutoExit()
    exitEngine._escaped = false
    exitEngine._nextTry = 0

    while exitEngine.enabled and pf.enabled do
        if exitLocalEscaped() or exitEngine._escaped then
            setStatus("✅ Escaped!")
            break
        end

        local left = computersLeft()
        if left == nil or left > 0 then
            task.wait(0.5)
            continue
        end

        if isBeastSelf() then task.wait(0.5); continue end

        if os.clock() < exitEngine._nextTry then task.wait(0.2); continue end

        local doors = getAllExitDoors()
        if #doors == 0 then
            setStatus("🚪 No exits found...")
            task.wait(2)
            continue
        end

        local door = findBestExit(doors)
        if not door then
            setStatus("⚠ All exits beast-blocked, waiting...")
            task.wait(1)
            continue
        end

        local pos = exitDoorPosition(door)
        if not pos then task.wait(0.5); continue end

        local root = getRoot()
        if not root then task.wait(0.3); continue end

        local dist = (root.Position - pos).Magnitude

        -- Reset the walk abort flag before each walk attempt
        pf.abortWalk = false

        if exitDoorOpen(door) then
            setStatus("🚪 Exit open! Heading there... (" .. math.floor(dist) .. " studs)")

            pf.startDoorEngine(true)
            local arrived = walkTo(pos)
            pf.stopDoorEngine()

            if not exitEngine.enabled or not pf.enabled then break end

            if pf.abortWalk then
                -- Beast interrupted the walk — flee then retry
                doFleeFromBeast(3)
                exitEngine._skipList[door] = os.clock() + 5
                exitEngine._nextTry = os.clock() + 1
                pf.abortWalk = false
                continue
            end

            if beastNear(pos, beast.AVOID_MAX) then
                exitEngine._skipList[door] = os.clock() + 6
                setStatus("⚠ Beast near exit, rerouting...")
                exitEngine._nextTry = os.clock() + 1
                continue
            end

            if arrived or (getRoot() and (getRoot().Position - pos).Magnitude < 12) then
                setStatus("🚪 Touching exit area...")
                touchExitArea(door)
            else
                exitEngine._nextTry = os.clock() + 1
            end
        else
            local trigger = exitDoorTrigger(door)
            if not trigger then task.wait(0.5); continue end

            setStatus("🚪 Walking to exit... (" .. math.floor(dist) .. " studs)")

            pf.startDoorEngine(true)
            local arrived = walkTo(trigger.Position)
            pf.stopDoorEngine()

            if not exitEngine.enabled or not pf.enabled then break end

            if pf.abortWalk then
                doFleeFromBeast(3)
                exitEngine._skipList[door] = os.clock() + 5
                exitEngine._nextTry = os.clock() + 1
                pf.abortWalk = false
                continue
            end

            if beastNear(trigger.Position, beast.AVOID_MAX) then
                exitEngine._skipList[door] = os.clock() + 6
                setStatus("⚠ Beast at exit, rerouting...")
                exitEngine._nextTry = os.clock() + 1
                continue
            end

            if arrived or (getRoot() and (getRoot().Position - trigger.Position).Magnitude < 10) then
                setStatus("🚪 Opening exit door...")
                openExitDoor(door)

                -- Wait for door to open (up to 12s)
                local waitStart = os.clock()
                while exitEngine.enabled and pf.enabled
                    and not exitDoorOpen(door)
                    and os.clock() - waitStart < 12 do

                    if beastNear(trigger.Position, beast.AVOID_MAX) then
                        exitEngine._skipList[door] = os.clock() + 6
                        setStatus("⚠ Beast near open door, rerouting...")
                        break
                    end
                    task.wait(0.25)
                end

                if exitDoorOpen(door) and not beastNear(exitDoorPosition(door), beast.AVOID_MAX) then
                    task.wait(1.5)
                    if exitEngine.enabled and pf.enabled then
                        local area = exitDoorArea(door)
                        if area and not beastNear(area.Position, beast.AVOID_MAX) then
                            setStatus("🚪 Going through exit!")
                            touchExitArea(door)
                        else
                            exitEngine._skipList[door] = os.clock() + 6
                        end
                    end
                end
            else
                exitEngine._nextTry = os.clock() + 1
            end
        end

        task.wait(0.2)
    end

    exitEngine.thread = nil
end

function exitEngine.startThread()
    if exitEngine.thread then return end
    exitEngine.thread = task.spawn(runAutoExit)
end

function exitEngine.stopThread()
    exitEngine.enabled = false
    exitEngine._escaped = false
    if exitEngine.thread then
        pcall(task.cancel, exitEngine.thread)
        exitEngine.thread = nil
    end
end

end  -- close EXIT_DOOR section
-- ============================================================
-- COMPUTER TABLE HELPERS
-- ============================================================
do  -- 🔒 COMPUTER_TABLE section (scopes internal locals)
function getAllComputers()
    local map  = getMap()
    if not map then return {} end
    local root = getRoot()
    local list = {}
    for _, obj in pairs(map:GetChildren()) do
        if obj.Name == "ComputerTable" and not isComputerDone(obj) then
            local part, _, allOccupied = getComputerTrigger(obj)
            -- allOccupied: every slot taken → skip entirely so we don't path to it
            if allOccupied then continue end
            if part then
                if avoidance.enabled and beastNear(part.Position, beast.AVOID_MAX) then
                    continue
                end
                local dist = root and (root.Position - part.Position).Magnitude or math.huge
                table.insert(list, { comp = obj, part = part, dist = dist })
            end
        end
    end
    table.sort(list, function(a, b) return a.dist < b.dist end)
    return list
end
end  -- close COMPUTER_TABLE section

-- ============================================================
-- HACK COMPUTER
-- ============================================================
do  -- 🔒 HACK_COMPUTER section (scopes internal locals)
function hackComputer(comp, triggerPart)
    if not triggerPart then return false end
    setStatus("Hacking PC...")
    pf.startFastHack()
    local deadline = tick() + 30
    while pf.enabled and not isComputerDone(comp) and tick() < deadline do
        local left = computersLeft()
        if left and left <= 0 then break end
        if avoidance.enabled and beastNearLocal(beast.AVOID_MIN) then
            setStatus("⚡ Beast nearby! Aborting hack...")
            break
        end
        task.wait(0.1)
    end
    pf.stopFastHack()
    return isComputerDone(comp)
end

end  -- close HACK_COMPUTER section
-- ============================================================
-- MAIN FARM LOOP
-- ============================================================
local function farmLoop()
    local failCount = 0
    local MAX_FAIL  = 3

    -- avoidance and exitEngine are started by roundWatcher before calling us

    while pf.enabled do
        -- If beast aborted our walk while not mid-walk, handle flee here
        if pf.abortWalk then
            if avoidance.enabled and beastNearLocal() then
                setStatus("⚡ Fleeing beast!")
                doFleeFromBeast(4)
            end
            pf.abortWalk = false
            task.wait(0.5)
            continue
        end

        local left = computersLeft()

        if left and left <= 0 then
            if exitEngine.enabled then
                setStatus("All PCs done! Auto-exiting...")
                while pf.enabled and exitEngine.enabled and not exitLocalEscaped() do
                    -- If beast aborts, handle it
                    if pf.abortWalk then
                        doFleeFromBeast(4)
                        pf.abortWalk = false
                    end
                    task.wait(0.5)
                end
                setStatus("✅ Done!")
            else
                setStatus("All PCs done!")
            end
            task.wait(2)
            break
        end

        local computers = getAllComputers()
        if #computers == 0 then
            setStatus("No PCs found, waiting...")
            task.wait(3); failCount = failCount + 1
            if failCount >= MAX_FAIL then setStatus("No PCs — stopping."); break end
            continue
        end
        failCount = 0

        local target = computers[1]
        pf.currentTarget = target.comp
        setStatus("Walking to PC (" .. math.floor(target.dist) .. " studs)...")

        pf.abortWalk = false
        pf.startDoorEngine(false)
        local arrived = walkTo(target.part.Position)
        pf.stopDoorEngine()

        if not pf.enabled then break end

        -- Beast interrupted the walk
        if pf.abortWalk then
            if avoidance.enabled then
                setStatus("⚡ Fleeing beast!")
                doFleeFromBeast(4)
            end
            pf.abortWalk = false
            task.wait(0.5)
            continue
        end

        if not arrived then setStatus("Path failed, next..."); task.wait(1); continue end
        if isComputerDone(target.comp) then setStatus("PC done, next..."); task.wait(0.5); continue end

        if avoidance.enabled and beastNear(target.part.Position, beast.AVOID_MAX) then
            setStatus("⚡ Beast at PC! Skipping...")
            task.wait(1)
            continue
        end

        local freshPart, _, allOccupied = getComputerTrigger(target.comp)
        if allOccupied then
            setStatus("PC all slots occupied, next..."); task.wait(1); continue
        end
        if not freshPart then
            setStatus("PC occupied, next..."); task.wait(1); continue
        end

        hackComputer(target.comp, freshPart)
        pf.currentTarget = nil
        wallSentinel.reset()  -- clear any sentinel state from standing still while hacking
        task.wait(0.3)
    end

    -- farmLoop complete — roundWatcher will handle avoidance/exit cleanup and next round
    pf.abortWalk = false
    pf.currentTarget = nil
    setStatus("Round done ✅")
end

-- ============================================================
-- ROUND WATCHER — auto-restarts farmLoop each new round
-- Round-start signal: workspace/<mapname>/ComputerSpawns appears
-- while map is loading, then disappears once all PCs are placed.
-- We detect its PRESENCE as "loading" and its DISAPPEARANCE + computers
-- existing as "round live". Also falls back to computersLeft() > 0.
-- ============================================================

-- Returns the ComputerSpawns folder if it currently exists in the active map
local function getComputerSpawns()
    local map = getMap()
    if not map then return nil end
    return map:FindFirstChild("ComputerSpawns")
end

-- Pre-cache approximate computer positions from ComputerSpawns entries.
-- Each child of ComputerSpawns typically has a Position or CFrame value.
local function cacheSpawnPositions()
    local spawns = getComputerSpawns()
    if not spawns then return end
    -- Just log that we see them; the actual computer models appear shortly after
    setStatus("📡 Map loading — " .. #spawns:GetChildren() .. " PC spawns detected")
end

local function roundWatcher()
    while pf.enabled do
        setStatus("⏳ Waiting for round...")

        -- Wait for a round to start.
        -- A round is live when EITHER:
        --   (a) ComputerSpawns existed and then disappeared (PCs spawned), OR
        --   (b) computersLeft() returns a number > 0
        -- Poll every 0.75s so we don't miss the transition.
        local spawnsSeenAt = nil
        local waitStart    = tick()

        repeat
            task.wait(0.75)
            if not pf.enabled then return end

            local spawns = getComputerSpawns()
            local left   = computersLeft()

            if spawns then
                -- ComputerSpawns present = map is loading, PCs not placed yet
                if not spawnsSeenAt then
                    spawnsSeenAt = tick()
                    cacheSpawnPositions()
                end
            else
                -- No ComputerSpawns folder
                if spawnsSeenAt then
                    -- It existed and just disappeared → PCs should be placed now
                    -- Give the map 1.5s to finish spawning computers
                    task.wait(1.5)
                    if not pf.enabled then return end
                    left = computersLeft()
                    if left ~= nil then break end  -- round is live
                    spawnsSeenAt = nil             -- false alarm, keep waiting
                elseif left ~= nil and left > 0 then
                    break  -- fallback: computersLeft already counting
                end
            end

            -- Safety timeout: 5 minutes max wait
        until tick() - waitStart > 300

        if not pf.enabled then return end

        -- Small settle so computers finish spawning
        task.wait(0.5)

        setStatus("🔄 Round detected — starting farm...")
        lastEscapePos = nil

        pf.abortWalk     = false
        pf.currentTarget = nil

        if avoidance.enabled then avoidance.start() end
        if exitEngine.enabled then exitEngine.startThread() end

        -- Run farmLoop in this thread (simpler than spawning — avoids pf.enabled races)
        farmLoop()

        if not pf.enabled then return end  -- user hit Stop during farmLoop

        -- farmLoop returned naturally (round done) — cleanup for next round
        avoidance.stop()
        exitEngine.stopThread()
        wallSentinel.stop()
        vizClear()
        pf.abortWalk     = false
        pf.currentTarget = nil
        refreshBtn()

        setStatus("⏳ Waiting for next round...")

        -- Wait until the current map is gone (getMap() returns nil) OR
        -- ComputerSpawns appears again (new map loading), whichever is first.
        -- This prevents the old "stuck in waiting" loop.
        local endWaitStart = tick()
        repeat
            task.wait(1)
            if not pf.enabled then return end
            local mapGone    = getMap() == nil
            local newSpawns  = getComputerSpawns() ~= nil
            if mapGone or newSpawns then break end
        until tick() - endWaitStart > 300

        -- Brief settle before looking for next round
        task.wait(2)
    end
end

local function stopFarm()
    pf.enabled = false      -- set FIRST so refreshBtn and any loops see it immediately
    pf.abortWalk = true     -- interrupt any active walkTo
    if pf.thread then
        pcall(task.cancel, pf.thread)
        pf.thread = nil
    end
    wallSentinel.stop()
    pf.stopFastHack()
    pf.stopDoorEngine()
    avoidance.stop()
    exitEngine.stopThread()
    vizClear()
    local hum = getHum(); local root = getRoot()
    if hum and root then hum:MoveTo(root.Position) end
    pf.currentTarget = nil
    pf.abortWalk = false
    setStatus("Stopped")
end

-- ============================================================


    -- ── Panel UI ─────────────────────────────────────────────────────────────
    -- refreshBtn is set by buildPfPanel once the UI exists; roundWatcher calls it
    -- after each round completes to sync the pill visual state with pf.enabled.
    local refreshBtn = function() end  -- safe no-op until panel is built
    local pfGui = nil

    local function buildPfPanel()
        local parent = getGuiParent()
        local old = parent:FindFirstChild("ZyxLab_PathFarm")
        if old then old:Destroy() end

        local sgui = Instance.new("ScreenGui")
        sgui.Name           = "ZyxLab_PathFarm"
        sgui.ResetOnSpawn   = false
        sgui.IgnoreGuiInset = true
        sgui.DisplayOrder   = 3601
        sgui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        sgui.Parent         = parent
        pfGui = sgui

        local backdrop = Instance.new("TextButton", sgui)
        backdrop.Size                   = UDim2.new(1,0,1,0)
        backdrop.BackgroundColor3       = Color3.new(0,0,0)
        backdrop.BackgroundTransparency = 0.5
        backdrop.BorderSizePixel        = 0
        backdrop.Text                   = ""
        backdrop.AutoButtonColor        = false
        backdrop.ZIndex                 = 1

        local panel = Instance.new("Frame", sgui)
        panel.Name             = "PFPanel"
        panel.Size             = UDim2.fromOffset(340, 310)
        panel.Position         = UDim2.new(0.5,-170,0.5,-155)
        panel.BackgroundColor3 = Color3.fromRGB(13,13,13)
        panel.BorderSizePixel  = 0
        panel.Active           = true
        panel.Draggable        = true
        panel.ZIndex           = 2
        panel:SetAttribute("ZyxAccentStroke", true)
        Instance.new("UICorner", panel).CornerRadius = UDim.new(0,14)
        local panelStroke = Instance.new("UIStroke", panel)
        panelStroke.Thickness    = 1.5
        panelStroke.Color        = getEffectiveAccent()
        panelStroke.Transparency = 0.15

        local hdr = Instance.new("Frame", panel)
        hdr.Size             = UDim2.new(1,0,0,42)
        hdr.BackgroundColor3 = Color3.fromRGB(18,17,28)
        hdr.BorderSizePixel  = 0
        Instance.new("UICorner", hdr).CornerRadius = UDim.new(0,14)
        local hdrFix = Instance.new("Frame", hdr)
        hdrFix.Size             = UDim2.new(1,0,0.5,0)
        hdrFix.Position         = UDim2.new(0,0,0.5,0)
        hdrFix.BackgroundColor3 = Color3.fromRGB(18,17,28)
        hdrFix.BorderSizePixel  = 0

        local accentBar = Instance.new("Frame", hdr)
        accentBar.Size             = UDim2.new(0,4,1,0)
        accentBar.BackgroundColor3 = getEffectiveAccent()
        accentBar.BorderSizePixel  = 0
        accentBar:SetAttribute("ZyxAccentBG", true)

        local titleLbl = Instance.new("TextLabel", hdr)
        titleLbl.Size                   = UDim2.new(1,-80,1,0)
        titleLbl.Position               = UDim2.new(0,16,0,0)
        titleLbl.BackgroundTransparency = 1
        titleLbl.Text                   = "⚡ Pathfind Survivor"
        titleLbl.Font                   = Enum.Font.GothamBold
        titleLbl.TextSize               = 14
        titleLbl.TextColor3             = Color3.new(1,1,1)
        titleLbl.TextXAlignment         = Enum.TextXAlignment.Left

        local closeBtn = Instance.new("TextButton", hdr)
        closeBtn.Size             = UDim2.fromOffset(28,28)
        closeBtn.Position         = UDim2.new(1,-34,0.5,-14)
        closeBtn.BackgroundColor3 = Color3.fromRGB(32,30,48)
        closeBtn.BorderSizePixel  = 0
        closeBtn.Text             = "×"
        closeBtn.Font             = Enum.Font.GothamBold
        closeBtn.TextSize         = 18
        closeBtn.TextColor3       = Color3.new(1,1,1)
        closeBtn.AutoButtonColor  = false
        Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(1,0)
        closeBtn.MouseButton1Click:Connect(function() sgui.Enabled = false end)
        backdrop.MouseButton1Click:Connect(function() sgui.Enabled = false end)

        local descFrame = Instance.new("Frame", panel)
        descFrame.Size             = UDim2.new(1,-28,0,44)
        descFrame.Position         = UDim2.new(0,14,0,50)
        descFrame.BackgroundColor3 = Color3.fromRGB(18,17,28)
        descFrame.BorderSizePixel  = 0
        Instance.new("UICorner", descFrame).CornerRadius = UDim.new(0,8)
        local descLbl = Instance.new("TextLabel", descFrame)
        descLbl.Size                   = UDim2.new(1,-12,1,0)
        descLbl.Position               = UDim2.new(0,10,0,0)
        descLbl.BackgroundTransparency = 1
        descLbl.Text                   = "Pathfinds to PCs, opens doors, hovers on beast. Survivor only."
        descLbl.Font                   = Enum.Font.GothamMedium
        descLbl.TextSize               = 11
        descLbl.TextColor3             = Color3.fromRGB(160,155,190)
        descLbl.TextXAlignment         = Enum.TextXAlignment.Left
        descLbl.TextWrapped            = true

        local function makePfToggle(yOffset, icon, label, desc, onToggle, getState)
            local row = Instance.new("Frame", panel)
            row.Size             = UDim2.new(1,-28,0,58)
            row.Position         = UDim2.fromOffset(14, yOffset)
            row.BackgroundColor3 = Color3.fromRGB(18,17,28)
            row.BorderSizePixel  = 0
            Instance.new("UICorner", row).CornerRadius = UDim.new(0,10)
            local rowStroke = Instance.new("UIStroke", row)
            rowStroke.Color       = Color3.fromRGB(35,33,52)
            rowStroke.Thickness   = 1
            rowStroke.Transparency = 0.3

            local iconLbl = Instance.new("TextLabel", row)
            iconLbl.Size                   = UDim2.fromOffset(34,34)
            iconLbl.Position               = UDim2.fromOffset(12,12)
            iconLbl.BackgroundTransparency = 1
            iconLbl.Text                   = icon
            iconLbl.Font                   = Enum.Font.GothamBold
            iconLbl.TextSize               = 20

            local nameLbl = Instance.new("TextLabel", row)
            nameLbl.Size                   = UDim2.new(1,-110,0,20)
            nameLbl.Position               = UDim2.fromOffset(54,10)
            nameLbl.BackgroundTransparency = 1
            nameLbl.Text                   = label
            nameLbl.Font                   = Enum.Font.GothamBold
            nameLbl.TextSize               = 13
            nameLbl.TextColor3             = Color3.new(1,1,1)
            nameLbl.TextXAlignment         = Enum.TextXAlignment.Left

            local subLbl = Instance.new("TextLabel", row)
            subLbl.Size                   = UDim2.new(1,-110,0,16)
            subLbl.Position               = UDim2.fromOffset(54,30)
            subLbl.BackgroundTransparency = 1
            subLbl.Text                   = desc
            subLbl.Font                   = Enum.Font.Gotham
            subLbl.TextSize               = 11
            subLbl.TextColor3             = Color3.fromRGB(140,135,170)
            subLbl.TextXAlignment         = Enum.TextXAlignment.Left

            local pill = Instance.new("Frame", row)
            pill.Size             = UDim2.fromOffset(44,22)
            pill.Position         = UDim2.new(1,-54,0.5,-11)
            pill.BackgroundColor3 = Color3.fromRGB(38,36,56)
            pill.BorderSizePixel  = 0
            Instance.new("UICorner", pill).CornerRadius = UDim.new(1,0)

            local knob = Instance.new("Frame", pill)
            knob.Size             = UDim2.fromOffset(17,17)
            knob.Position         = UDim2.fromOffset(2,2.5)
            knob.BackgroundColor3 = Color3.fromRGB(160,155,190)
            knob.BorderSizePixel  = 0
            Instance.new("UICorner", knob).CornerRadius = UDim.new(1,0)

            local function setPill(v)
                local accent = getEffectiveAccent()
                TweenService:Create(pill, TweenInfo.new(0.15, Enum.EasingStyle.Quint), {
                    BackgroundColor3 = v and accent or Color3.fromRGB(38,36,56)
                }):Play()
                TweenService:Create(knob, TweenInfo.new(0.15, Enum.EasingStyle.Quint), {
                    Position         = v and UDim2.fromOffset(25,2.5) or UDim2.fromOffset(2,2.5),
                    BackgroundColor3 = v and Color3.new(1,1,1) or Color3.fromRGB(160,155,190),
                }):Play()
                onToggle(v)
            end

            local hitBtn = Instance.new("TextButton", row)
            hitBtn.Size                   = UDim2.new(1,0,1,0)
            hitBtn.BackgroundTransparency = 1
            hitBtn.Text                   = ""
            hitBtn.ZIndex                 = 5
            hitBtn.AutoButtonColor        = false
            hitBtn.MouseButton1Click:Connect(function()
                setPill(not getState())
            end)

            return setPill
        end

        local farmPillSetter = makePfToggle(102, "🤖", "Pathfind Farm",
            "Walks to PCs via pathfinding and hacks them",
            function(v)
                if v then
                    if not pf.enabled then
                        pf.enabled         = true
                        avoidance.enabled  = avoidance._userWants or false
                        exitEngine.enabled = exitEngine._userWants or false
                        if pf.thread then pcall(task.cancel, pf.thread); pf.thread = nil end
                        pf.thread = task.spawn(roundWatcher)
                    end
                else
                    stopFarm()
                end
            end,
            function() return pf.enabled end
        )
        -- Wire refreshBtn so roundWatcher can sync the pill after each round ends
        refreshBtn = function()
            pcall(function() farmPillSetter(pf.enabled) end)
        end

        makePfToggle(168, "🚪", "Auto Exit",
            "Escapes through exit doors when PCs are done",
            function(v)
                exitEngine._userWants = v
                exitEngine.enabled    = v
                if pf.enabled then
                    if v then exitEngine.startThread()
                    else exitEngine.stopThread(); exitEngine.enabled = false end
                end
            end,
            function() return exitEngine.enabled end
        )

        makePfToggle(234, "👁", "Avoid Beast",
            "Hovers 80 studs up when beast is nearby",
            function(v)
                avoidance._userWants = v
                avoidance.enabled    = v
                if pf.enabled then
                    if v then avoidance.start()
                    else avoidance.stop(); avoidance.enabled = false end
                end
            end,
            function() return avoidance.enabled end
        )

        local statusFrame = Instance.new("Frame", panel)
        statusFrame.Size             = UDim2.new(1,-28,0,28)
        statusFrame.Position         = UDim2.fromOffset(14, 262)
        statusFrame.BackgroundColor3 = Color3.fromRGB(18,17,28)
        statusFrame.BorderSizePixel  = 0
        Instance.new("UICorner", statusFrame).CornerRadius = UDim.new(0,8)

        local statusLbl = Instance.new("TextLabel", statusFrame)
        statusLbl.Size                   = UDim2.new(1,-14,1,0)
        statusLbl.Position               = UDim2.fromOffset(10,0)
        statusLbl.BackgroundTransparency = 1
        statusLbl.Text                   = "● idle"
        statusLbl.Font                   = Enum.Font.GothamMedium
        statusLbl.TextSize               = 11
        statusLbl.TextColor3             = Color3.fromRGB(120,115,150)
        statusLbl.TextXAlignment         = Enum.TextXAlignment.Left

        pf.statusLabel = statusLbl
        task.spawn(function()
            while sgui and sgui.Parent do
                if sgui.Enabled then
                    local txt    = pf.status or "idle"
                    local active = pf.enabled or exitEngine.enabled or avoidance.enabled
                    statusLbl.Text       = "● " .. txt
                    statusLbl.TextColor3 = active and getEffectiveAccent() or Color3.fromRGB(120,115,150)
                end
                task.wait(0.35)
            end
        end)
    end

    _G.__ZyxOpenPathFarm = function()
        if pfGui and pfGui.Parent then
            pfGui.Enabled = true
            return
        end
        buildPfPanel()
    end
end

-- ─── AUTO SAVE CAPTURED LOOP ───
-- Fires the pod release remote for any occupied FreezePod while the toggle is on.
task.spawn(function()
    while true do
        task.wait(0.2)
        if state.autosavecaptured then
            local map
            for _, v in pairs(workspace:GetChildren()) do
                if v:FindFirstChild("ComputerTable") or v:FindFirstChild("FreezePod") then
                    map = v
                    break
                end
            end
            if map then
                for _, o in pairs(map:GetChildren()) do
                    if o.Name == "FreezePod" then
                        local PodTrigger = o:FindFirstChild("PodTrigger", true)
                        if PodTrigger
                        and PodTrigger:FindFirstChild("CapturedTorso")
                        and PodTrigger.CapturedTorso.Value then
                            local Event = PodTrigger:FindFirstChild("Event")
                            if Event then
                                pcall(function()
                                    ReplicatedStorage.RemoteEvent:FireServer("Input", "Trigger", true, Event)
                                    ReplicatedStorage.RemoteEvent:FireServer("Input", "Action", true)
                                end)
                            end
                        end
                    end
                end
            end
        end
    end
end)

-- =============================================
-- 👁️ SPECTATE PAGE
-- =============================================
do
    spectatePage:Section("Choose POV")
    pcall(function()
        spectatePage:Paragraph({
            Title = "Who do you want to spectate?",
            Desc  = "Pick one. A draggable, resizable control panel will pop up on-screen.",
            Icon  = "eye",
        })
    end)

    spectatePage:Button({
        Title = "Spectate Survivor",
        Desc  = "Open the popup and watch survivor players",
        Text  = "Survivor",
        Callback = function() Spectate.start("Survivor") end,
    })

    spectatePage:Button({
        Title = "Spectate Beast",
        Desc  = "Open the popup and watch the Beast",
        Text  = "Beast",
        Callback = function() Spectate.start("Beast") end,
    })
end

-- =============================================
-- 🔊 AUDIO PAGE
-- =============================================
audioPage:Section("Master")

toggleHandles.soundpack = audioPage:Toggle({
    Title = "Custom Soundpack",
    Desc  = "Replace game sounds with custom IDs",
    Value = state.soundpack,
    Callback = function(v)
        state.soundpack = v
        refreshSoundpack()
    end,
})

audioPage:Section("Per-Sound Overrides")

local SOUND_ROWS = {
    {"snd_Typing",    "Typing"},
    {"snd_Error",     "Error"},
    {"snd_Popup",     "Popup"},
    {"snd_DoorOpen",  "Door Open"},
    {"snd_DoorClose", "Door Close"},
    {"snd_ExitOpen",  "Exit Open"},
    {"snd_Unlock",    "Unlock"},
    {"snd_HitWall",   "Hit Wall"},
    {"snd_HitPlayer", "Hit Player"},
    {"snd_Chase",     "Chase Music"},
    {"snd_Heartbeat", "Heartbeat"},
}

local soundToggleHandles = {}
for _, row in ipairs(SOUND_ROWS) do
    local key, label = row[1], row[2]
    soundToggleHandles[key] = audioPage:Toggle({
        Title = label,
        Desc  = "On = use custom sound",
        Value = theme[key],
        Callback = function(v)
            theme[key] = v
            refreshSoundpack()
        end,
    })
end

-- =============================================
-- 🎧 AUDIO PLAYER PAGE
-- =============================================
_G.__ZyxAudioPlayerPage:Section("Pop-out")
pcall(function()
    _G.__ZyxAudioPlayerPage:Paragraph({
        Title = "Audio Player Window",
        Desc  = "Opens a separate draggable scanner/player. It does not change the Custom Soundpack IDs.",
        Icon  = "volume-2",
    })
end)

_G.__ZyxAudioPlayerPage:Button({
    Title = "Open / Reopen Audio Player",
    Desc  = "Show the separate draggable audio panel",
    Text  = "Open",
    Callback = function()
        if _G.__ZyxOpenAudioPlayer then _G.__ZyxOpenAudioPlayer() end
    end,
})

_G.__ZyxAudioPlayerPage:Button({
    Title = "Hide Audio Player",
    Desc  = "Hide the pop-out window without deleting ZyxLab",
    Text  = "Hide",
    Callback = function()
        local function hideFrom(root)
            local gui = root and root:FindFirstChild("ZyxLab_AudioPlayerPopup")
            if gui then
                local panel = gui:FindFirstChild("Root")
                local mini = gui:FindFirstChild("MiniButton")
                if panel then panel.Visible = false end
                if mini then mini.Visible = false end
            end
        end
        for _, root in ipairs(collectGuiRoots()) do
            pcall(function() hideFrom(root) end)
        end
    end,
})

-- =============================================
-- 🎨 CUSTOMIZE PAGE
-- =============================================
customizePage:Section("Streamer Mode")

customizePage:Input({
    Title = "Streamer Name",
    Desc  = "Name shown when Streamer Mode is enabled",
    Value = Olympia.getStreamerName(),
    Callback = function(text)
        Olympia.setStreamerName(text)
    end,
})

customizePage:Input({
    Title = "Streamer Level",
    Desc  = "Level shown when Streamer Mode is enabled",
    Value = Olympia.getStreamerLevel(),
    Callback = function(text)
        Olympia.setStreamerLevel(text)
    end,
})

customizePage:Section("Accent")

-- The library doesn't expose a swatch on a Button, so we use Title + Desc text and
-- show the actual color via the picker overlay when opened.
customizePage:Button({
    Title = "Accent Color",
    Desc  = "Tap to open picker (hex / RGB / Chroma)",
    Text  = "🎨 Pick",
    Callback = function()
        openPicker({
            title  = "Accent Color",
            color  = Color3.fromRGB(theme.accentR, theme.accentG, theme.accentB),
            chroma = theme.accentChroma,
            onChange = function(c)
                theme.accentR = math.floor(c.R * 255 + 0.5)
                theme.accentG = math.floor(c.G * 255 + 0.5)
                theme.accentB = math.floor(c.B * 255 + 0.5)
                if not theme.accentChroma then
                    pushAccentToLibrary(true)
                end
            end,
            onChroma = function(b)
                theme.accentChroma = b
                pushAccentToLibrary(true)
            end,
        })
    end,
})

-- Helper to build an ESP color section
local ESP_LABELS = {
    { key = "espPlayer",   label = "Player ESP",    showOutline = true  },
    { key = "espBeast",    label = "Beast ESP",     showOutline = true  },
    { key = "espDoor",     label = "Door ESP",      showOutline = true  },
    { key = "espExit",     label = "Exit ESP",      showOutline = true  },
    { key = "espComputer", label = "Computer ESP",  showOutline = false },
    { key = "espFreeze",   label = "FreezePod ESP", showOutline = true  },
}

local function refreshAllESPs()
    for _, fn in ipairs(espRefreshFns) do fn() end
end

for _, info in ipairs(ESP_LABELS) do
    local key, label = info.key, info.label
    customizePage:Section(label)

    customizePage:Button({
        Title = "Fill Color",
        Desc  = "Tap to pick fill (with Chroma option)",
        Text  = "🎨 Pick",
        Callback = function()
            local t = theme[key]
            openPicker({
                title  = label .. " — Fill",
                color  = Color3.fromRGB(t[1], t[2], t[3]),
                chroma = t[9],
                onChange = function(c)
                    t[1] = math.floor(c.R * 255 + 0.5)
                    t[2] = math.floor(c.G * 255 + 0.5)
                    t[3] = math.floor(c.B * 255 + 0.5)
                    if not t[9] then refreshAllESPs() end
                end,
                onChroma = function(b)
                    t[9] = b
                    refreshAllESPs()
                end,
            })
        end,
    })

    customizePage:Slider({
        Title = "Fill Transparency",
        Min   = 0,
        Max   = 100,
        Rounding = 0,
        Value = 100 - (theme[key][7] or 50),  -- Display as opacity
        Callback = function(v)
            theme[key][7] = 100 - v  -- Store as transparency
            refreshAllESPs()
        end,
    })

    if info.showOutline then
        customizePage:Button({
            Title = "Outline Color",
            Desc  = "Tap to pick outline (with Chroma option)",
            Text  = "🎨 Pick",
            Callback = function()
                local t = theme[key]
                openPicker({
                    title  = label .. " — Outline",
                    color  = Color3.fromRGB(t[4], t[5], t[6]),
                    chroma = t[10],
                    onChange = function(c)
                        t[4] = math.floor(c.R * 255 + 0.5)
                        t[5] = math.floor(c.G * 255 + 0.5)
                        t[6] = math.floor(c.B * 255 + 0.5)
                        if not t[10] then refreshAllESPs() end
                    end,
                    onChroma = function(b)
                        t[10] = b
                        refreshAllESPs()
                    end,
                })
            end,
        })

        customizePage:Slider({
            Title = "Outline Transparency",
            Min   = 0,
            Max   = 100,
            Rounding = 0,
            Value = 100 - (theme[key][8] or 0),
            Callback = function(v)
                theme[key][8] = 100 - v
                refreshAllESPs()
            end,
        })
    end
end


customizePage:Section("Wallhop Viewer")

customizePage:Button({
    Title = "Line Color",
    Desc  = "Pick the SelectionBox outline color",
    Text  = "🎨 Pick",
    Callback = function()
        openPicker({
            title    = "Wallhop Viewer — Line Color",
            color    = Color3.new(1, 1, 1),
            chroma   = _G.__ZyxWhl and _G.__ZyxWhl.getChroma() or false,
            onChange = function(c)
                if _G.__ZyxWhl then _G.__ZyxWhl.setColor(c) end
            end,
            onChroma = function(b)
                if _G.__ZyxWhl then _G.__ZyxWhl.setChroma(b) end
            end,
        })
    end,
})

customizePage:Slider({
    Title    = "Line Thickness",
    Desc     = "SelectionBox line thickness (0.005 – 0.1)",
    Min      = 1,
    Max      = 100,
    Rounding = 0,
    Value    = 20,   -- default ~0.02 mapped to 1-100 scale
    Callback = function(v)
        -- map 1-100 → 0.005-0.1
        local t = 0.005 + (v - 1) / 99 * (0.1 - 0.005)
        if _G.__ZyxWhl then _G.__ZyxWhl.setThickness(t) end
    end,
})

-- =============================================
-- 💾 CONFIGS PAGE
-- =============================================
do  -- 🔒 CONFIGS_PAGE section (scopes internal locals)
configPage:Section("Save Slot")

local newConfigName = ""
configPage:Input({
    Title = "Config Name",
    Desc  = "Letters / numbers only — leave Default alone",
    Value = "",
    Callback = function(text) newConfigName = text or "" end,
})

local cfgDropdown
local selectedConfigName = activeConfigName

local function repopulateDropdown(selectName)
    -- Clear and re-add all configs. Library should expose :Clear() and :AddList().
    pcall(function() cfgDropdown:Clear() end)
    for _, name in ipairs(listConfigs()) do
        pcall(function() cfgDropdown:AddList(name) end)
    end
    if selectName then
        selectedConfigName = selectName
    end
end

configPage:Button({
    Title = "Save Config",
    Desc  = "Persist current toggles + theme",
    Text  = "💾 Save",
    Callback = function()
        local name = (newConfigName or ""):match("^%s*(.-)%s*$") or ""
        if name == "" then
            Library:Notification({ Title = "Need a name", Desc = "Type a name first.", Duration = 3, Type = "Warning" })
            return
        end
        if name == DEFAULT_CFG then
            Library:Notification({ Title = "Reserved", Desc = "Can't overwrite Default.", Duration = 3, Type = "Warning" })
            return
        end
        local ok = writeConfig(name, state, theme)
        if ok then
            local names = listConfigs()
            local found = false
            for _, n in ipairs(names) do if n == name then found = true; break end end
            if not found then
                table.insert(names, name)
                saveConfigList(names)
            end
            activeConfigName = name
            setLastCfgName(name)
            repopulateDropdown(name)
            Library:Notification({ Title = "Saved", Desc = "'" .. name .. "' is ready to load.", Duration = 3, Type = "Success" })
        else
            Library:Notification({ Title = "Save failed", Desc = "Executor blocked the write.", Duration = 4, Type = "Error" })
        end
    end,
})

configPage:Section("Slot Manager")

cfgDropdown = configPage:Dropdown({
    Title = "Config",
    Desc  = "Pick a slot",
    List  = listConfigs(),
    Value = activeConfigName,
    Callback = function(selected) selectedConfigName = selected end,
})

local function applyLoadedConfig(name)
    local cfg = readConfig(name)
    if not cfg then
        Library:Notification({ Title = "Load failed", Desc = "'" .. name .. "' is missing or corrupt.", Duration = 4, Type = "Error" })
        return
    end
    applyConfigData(cfg)

    -- Push accent to library
    pushAccentToLibrary(true)

    -- Update toggle visuals
    for k, h in pairs(toggleHandles) do
        if state[k] ~= nil then
            pcall(function() h.Value = state[k] end)
        end
    end
    for k, h in pairs(soundToggleHandles) do
        if theme[k] ~= nil then
            pcall(function() h.Value = theme[k] end)
        end
    end

    -- Apply side effects directly (so we don't depend on whether .Value setter fires the callback)
    if state.fullbright then enableFullbright() else disableFullbright() end
    if state.noslow     then enableNoSlow()     else disableNoSlow()     end
    if state.playerESP then
        for _, p in pairs(game:GetService("Players"):GetPlayers()) do applyPlayerHighlight(p) end
    else clearPlayerESP() end
    if state.doorESP      then applyDoorESP()   else clearDoorESP()   end
    if state.exitESP      then applyExitESP()   else clearExitESP()   end
    if state.freezepodESP then applyFreezeESP() else clearFreezeESP() end
    if not state.computerESP then clearComputerESP() end
    Olympia.setStreamerName(theme.streamerName or "Sigma")
    Olympia.setStreamerLevel(theme.streamerLevel or "67")
    Olympia.apply()
    refreshSoundpack()
    refreshAllESPs()

    activeConfigName = name
    setLastCfgName(name)
    Library:Notification({ Title = "Loaded", Desc = "'" .. name .. "' applied.", Duration = 3, Type = "Success" })
end

configPage:Button({
    Title = "Load Selected",
    Desc  = "Apply the chosen config",
    Text  = "📂 Load",
    Callback = function()
        applyLoadedConfig(selectedConfigName or DEFAULT_CFG)
    end,
})

configPage:Button({
    Title = "Overwrite Selected",
    Desc  = "Replace the chosen slot with current settings",
    Text  = "♻️ Overwrite",
    Callback = function()
        local name = selectedConfigName
        if not name or name == DEFAULT_CFG then
            Library:Notification({ Title = "Can't overwrite", Desc = "Default is protected.", Duration = 3, Type = "Warning" })
            return
        end
        local ok = writeConfig(name, state, theme)
        if ok then
            activeConfigName = name
            setLastCfgName(name)
            repopulateDropdown(name)
            Library:Notification({ Title = "Overwritten", Desc = "'" .. name .. "' now uses current settings.", Duration = 3, Type = "Success" })
        else
            Library:Notification({ Title = "Overwrite failed", Desc = "Executor blocked the write.", Duration = 4, Type = "Error" })
        end
    end,
})

configPage:Button({
    Title = "Delete Selected",
    Desc  = "Permanently remove this slot",
    Text  = "🗑️ Delete",
    Callback = function()
        local name = selectedConfigName
        if not name or name == DEFAULT_CFG then
            Library:Notification({ Title = "Can't delete", Desc = "Default is protected.", Duration = 3, Type = "Warning" })
            return
        end
        deleteConfig(name)
        if activeConfigName == name then
            activeConfigName = DEFAULT_CFG
            setLastCfgName(DEFAULT_CFG)
        end
        repopulateDropdown(DEFAULT_CFG)
        Library:Notification({ Title = "Deleted", Desc = "'" .. name .. "' is gone.", Duration = 3, Type = "Info" })
    end,
})

configPage:Section("Reset")

configPage:Button({
    Title = "Reset to Defaults",
    Desc  = "Restore default toggles + colors (no save)",
    Text  = "♻️ Reset",
    Callback = function()
        for k, v in pairs(DEFAULT_THEME) do
            theme[k] = type(v) == "table" and deepCopy(v) or v
        end
        for k, v in pairs(DEFAULT_STATE) do state[k] = v end

        pushAccentToLibrary(true)

        for k, h in pairs(toggleHandles) do
            if state[k] ~= nil then
                pcall(function() h.Value = state[k] end)
            end
        end
        for k, h in pairs(soundToggleHandles) do
            if theme[k] ~= nil then
                pcall(function() h.Value = theme[k] end)
            end
        end

        if state.fullbright then enableFullbright() else disableFullbright() end
        if state.noslow     then enableNoSlow()     else disableNoSlow()     end
        if state.playerESP then
            for _, p in pairs(game:GetService("Players"):GetPlayers()) do applyPlayerHighlight(p) end
        else clearPlayerESP() end
        if state.doorESP      then applyDoorESP()   else clearDoorESP()   end
        if state.exitESP      then applyExitESP()   else clearExitESP()   end
        if state.freezepodESP then applyFreezeESP() else clearFreezeESP() end
        if not state.computerESP then clearComputerESP() end
        Olympia.setStreamerName(theme.streamerName or "Sigma")
        Olympia.setStreamerLevel(theme.streamerLevel or "67")
        Olympia.apply()
        refreshSoundpack()
        refreshAllESPs()

        Library:Notification({ Title = "Reset", Desc = "All settings back to defaults.", Duration = 3, Type = "Success" })
    end,
})

-- =============================================
-- 🪪 INFO PAGE
-- =============================================
-- Different approach: keep everything native to the Info tab.  The library's
-- RightLabel returns a TextLabel, so the values below update live without a
-- separate overlay ScreenGui.

local sessionStart = tick()
local lastFPS = 0
RunService.RenderStepped:Connect(function(dt)
    if dt > 0 then
        lastFPS = math.floor((1 / dt) + 0.5)
    end
end)

local execName = "Unknown"
pcall(function()
    if identifyexecutor then
        local ok, n = pcall(identifyexecutor)
        if ok and n then execName = tostring(n) end
    elseif getexecutorname then
        local ok, n = pcall(getexecutorname)
        if ok and n then execName = tostring(n) end
    end
end)

local avatarImage = "user"
pcall(function()
    avatarImage = Players:GetUserThumbnailAsync(
        player.UserId,
        Enum.ThumbnailType.HeadShot,
        Enum.ThumbnailSize.Size150x150
    )
end)

infoPage:Section("Profile")
pcall(function()
    infoPage:Paragraph({
        Title = player.DisplayName,
        Desc = "@" .. player.Name .. "  •  User ID: " .. tostring(player.UserId),
        Icon = avatarImage,
    })
end)

-- XovaModedLib tints tab/page icons with the accent. The profile image is a
-- real Roblox thumbnail, so force it back to white and mark it so chroma skips it.
function protectProfileAvatarImages()
    local uid = tostring(player.UserId)
    for _, root in ipairs(collectGuiRoots()) do
        for _, obj in ipairs(root:GetDescendants()) do
            if obj:IsA("ImageLabel") or obj:IsA("ImageButton") then
                local img = tostring(obj.Image or "")
                local isThisAvatar = (img == avatarImage)
                    or (img:find("rbxthumb://", 1, true) and img:find(uid, 1, true))
                if isThisAvatar then
                    obj:SetAttribute("ZyxNoAccentImage", true)
                    obj.ImageColor3 = Color3.new(1, 1, 1)
                end
            end
        end
    end
end

task.spawn(function()
    for _ = 1, 25 do
        protectProfileAvatarImages()
        task.wait(0.12)
    end
end)

local function safeRightLabel(args)
    local ok, lbl = pcall(function() return infoPage:RightLabel(args) end)
    if ok and lbl then return lbl end

    -- Last-resort fallback for older library builds.  This is static, but it
    -- prevents the rest of the script from stopping.
    pcall(function()
        infoPage:Paragraph({ Title = args.Title, Desc = tostring(args.Right or ""), Icon = "info" })
    end)
    return nil
end

local infoDisplayVal = safeRightLabel({ Title = "Display Name", Desc = "Roblox display name", Right = player.DisplayName })
local infoUserVal    = safeRightLabel({ Title = "Username",     Desc = "Roblox username",     Right = "@" .. player.Name })
local infoPlayVal    = safeRightLabel({ Title = "Playtime",     Desc = "Current session",     Right = "0m 0s" })
local infoPingVal    = safeRightLabel({ Title = "Ping",         Desc = "Network latency",     Right = "-- ms" })
local infoFPSVal     = safeRightLabel({ Title = "FPS",          Desc = "Client framerate",    Right = "-- fps" })
local infoExecVal    = safeRightLabel({ Title = "Executor",     Desc = "Detected executor",   Right = execName })

local function setInfoText(lbl, text)
    if lbl then
        pcall(function() lbl.Text = tostring(text) end)
    end
end

local function getPingText()
    local pingText = "-- ms"
    pcall(function()
        local stats = game:GetService("Stats")
        local item = stats.Network.ServerStatsItem:FindFirstChild("Data Ping")
        if item then
            local raw = item:GetValueString()
            local num = tonumber(raw:match("[%d%.]+"))
            pingText = num and (tostring(math.floor(num + 0.5)) .. " ms") or raw
        else
            local ping = stats.Network.ServerStatsItem["Data Ping"].Value
            pingText = tostring(math.floor(ping + 0.5)) .. " ms"
        end
    end)
    return pingText
end

local function formatPlaytime()
    local elapsed = math.floor(tick() - sessionStart)
    local hh = math.floor(elapsed / 3600)
    local mm = math.floor((elapsed % 3600) / 60)
    local ss = elapsed % 60
    if hh > 0 then
        return hh .. "h " .. mm .. "m " .. ss .. "s"
    end
    return mm .. "m " .. ss .. "s"
end

task.spawn(function()
    while true do
        setInfoText(infoDisplayVal, player.DisplayName)
        setInfoText(infoUserVal, "@" .. player.Name)
        setInfoText(infoPlayVal, formatPlaytime())
        setInfoText(infoPingVal, getPingText())
        setInfoText(infoFPSVal, (lastFPS > 0) and (tostring(lastFPS) .. " fps") or "-- fps")
        setInfoText(infoExecVal, execName)
        task.wait(0.5)
    end
end)



-- =============================================
-- 🔎 FEATURE SEARCH PAGE
-- =============================================
-- Native Search tab.  It lists matching features and opens the matched page.
-- Flash/highlight behavior was removed to keep the UI stable.
local function setupFeatureSearch(pageRegistry)
    pageRegistry = pageRegistry or {}
    local searchPageRef = pageRegistry.Search
    if not searchPageRef then return end

    local items = {
        {page = "Visuals", feature = "Player ESP"},
        {page = "Visuals", feature = "Door ESP"},
        {page = "Visuals", feature = "Exit ESP"},
        {page = "Visuals", feature = "Computer ESP"},
        {page = "Visuals", feature = "FreezePod ESP"},
        {page = "Visuals", feature = "Progress Bar"},
        {page = "Visuals", feature = "Fullbright"},
        {page = "Movements", feature = "WalkSpeed"},
        {page = "Movements", feature = "CrawlSpeed"},
        {page = "Movements", feature = "Jump"},
        {page = "Movements", feature = "Fly"},
        {page = "Movements", feature = "Noclip"},
        {page = "Movements", feature = "Infinite Jump"},
        {page = "Movements", feature = "WallHop"},
        {page = "Movements", feature = "WallHop Jump Delay"},
        {page = "Movements", feature = "WallHop Flick Speed"},
        {page = "Movements", feature = "Gravity"},
        {page = "Movements", feature = "Orbit"},
        {page = "Misc", feature = "Anti-Error"},
        {page = "Misc", feature = "No Slow"},
        {page = "Misc", feature = "Beast Notifier"},
        {page = "Misc", feature = "Anti AFK"},
        {page = "Misc", feature = "Streamer Mode"},
        {page = "Misc", feature = "No Hammer Cooldown"},
        {page = "Misc", feature = "Silent Hack"},
        {page = "Misc", feature = "Auto Tie"},
        {page = "Rage", feature = "Force Beast Ability"},
        {page = "Rage", feature = "Slow Beast"},
        {page = "Rage", feature = "Remove Rope"},
        {page = "Spectate", feature = "Spectate Survivor"},
        {page = "Spectate", feature = "Spectate Beast"},
        {page = "Audio", feature = "Custom Soundpack"},
        {page = "Audio", feature = "Typing"},
        {page = "Audio", feature = "Error"},
        {page = "Audio", feature = "Popup"},
        {page = "Audio", feature = "Door Open"},
        {page = "Audio", feature = "Door Close"},
        {page = "Audio", feature = "Exit Open"},
        {page = "Audio", feature = "Unlock"},
        {page = "Audio", feature = "Hit Wall"},
        {page = "Audio", feature = "Hit Player"},
        {page = "Audio", feature = "Chase Music"},
        {page = "Audio", feature = "Heartbeat"},
        {page = "Audio Player", feature = "Open Audio Player"},
        {page = "Audio Player", feature = "Hide Audio Player"},
        {page = "Customize", feature = "Accent Color"},
        {page = "Customize", feature = "Streamer Name"},
        {page = "Customize", feature = "Streamer Level"},
        {page = "Customize", feature = "Player ESP Fill Color"},
        {page = "Customize", feature = "Player ESP Outline Color"},
        {page = "Customize", feature = "Beast ESP Fill Color"},
        {page = "Customize", feature = "Beast ESP Outline Color"},
        {page = "Customize", feature = "Door ESP Fill Color"},
        {page = "Customize", feature = "Door ESP Outline Color"},
        {page = "Customize", feature = "Exit ESP Fill Color"},
        {page = "Customize", feature = "Exit ESP Outline Color"},
        {page = "Customize", feature = "Computer ESP Fill Color"},
        {page = "Customize", feature = "FreezePod ESP Fill Color"},
        {page = "Customize", feature = "FreezePod ESP Outline Color"},
        {page = "Configs", feature = "Load Selected"},
        {page = "Configs", feature = "Save New"},
        {page = "Configs", feature = "Overwrite Selected"},
        {page = "Configs", feature = "Delete Selected"},
        {page = "Info", feature = "Session Stats"},
    }

    local markerText = "__ZyxLab_SearchMount__"
    searchPageRef:Section("Search")
    searchPageRef:Paragraph({
        Title = "Find anything",
        Desc = "Type a feature name, then click a result to jump to it.",
        Icon = "file-search",
    })
    searchPageRef:Section(markerText)

    local searchContainer = nil
    local searchBox = nil
    local clearBtn = nil
    local results = nil

    local function visibleInTree(obj)
        local n = obj
        while n do
            if n:IsA("ScreenGui") and not n.Enabled then return false end
            if n:IsA("GuiObject") and not n.Visible then return false end
            n = n.Parent
        end
        return true
    end

    local function isDescendantOf(obj, ancestor)
        local n = obj
        while n do
            if n == ancestor then return true end
            n = n.Parent
        end
        return false
    end

    local function findSearchScroller()
        for _, root in ipairs(collectGuiRoots()) do
            for _, obj in ipairs(root:GetDescendants()) do
                if (obj:IsA("TextLabel") or obj:IsA("TextButton"))
                and tostring(obj.Text or ""):find(markerText, 1, true) then
                    obj.Visible = false
                    obj.Text = ""
                    obj.Size = UDim2.new(1, 0, 0, 0)
                    local n = obj.Parent
                    while n do
                        if n:IsA("ScrollingFrame") then return n end
                        n = n.Parent
                    end
                end
            end
        end
        return nil
    end

    local function clickGuiButton(btn)
        pcall(function()
            if typeof(firesignal) == "function" then
                firesignal(btn.MouseButton1Click)
                firesignal(btn.Activated)
            end
        end)
        pcall(function() btn:Activate() end)
    end

    -- XovaModedLib tab cards are named NewTabs.  The visible title label sits
    -- inside the card, while the transparent TextButton is a sibling overlay.
    local tabClicks = {}

    local function findTabFrame(obj)
        local n = obj
        while n do
            if n:IsA("Frame") and n.Name == "NewTabs" then return n end
            n = n.Parent
        end
        return nil
    end

    local function findTabButtonInFrame(frame)
        if not frame then return nil end
        for _, child in ipairs(frame:GetChildren()) do
            if child:IsA("TextButton") then return child end
        end
        return frame:FindFirstChildWhichIsA("TextButton", true)
    end

    local function buildTabRegistry()
        tabClicks = {}
        local pageNames = {}
        for name, _ in pairs(pageRegistry) do
            if name ~= "Search" then pageNames[name] = true end
        end

        for _, root in ipairs(collectGuiRoots()) do
            for _, obj in ipairs(root:GetDescendants()) do
                if (obj:IsA("TextLabel") or obj:IsA("TextButton"))
                and obj.Text and pageNames[obj.Text]
                and obj.AbsoluteSize.X > 0
                and obj.AbsoluteSize.Y > 0 then
                    local tabFrame = findTabFrame(obj)
                    local btn = findTabButtonInFrame(tabFrame)
                    if btn and not tabClicks[obj.Text] then
                        tabClicks[obj.Text] = btn
                    end
                end
            end
        end
    end

    task.spawn(function()
        for _ = 1, 8 do
            buildTabRegistry()
            local count = 0
            for _ in pairs(tabClicks) do count = count + 1 end
            if count >= 4 then break end
            task.wait(0.4)
        end
    end)

    local function openPage(pageName)
        local btn = tabClicks[pageName]
        if btn and btn.Parent then
            clickGuiButton(btn)
            return true
        end

        buildTabRegistry()
        btn = tabClicks[pageName]
        if btn and btn.Parent then
            clickGuiButton(btn)
            return true
        end

        return false
    end

    local function getAncestorScroller(obj)
        local n = obj and obj.Parent
        while n do
            if n:IsA("ScrollingFrame") then return n end
            n = n.Parent
        end
        return nil
    end

    local function getCanvasHeight(scroller)
        local ok, absCanvas = pcall(function() return scroller.AbsoluteCanvasSize end)
        if ok and absCanvas and absCanvas.Y and absCanvas.Y > 0 then
            return absCanvas.Y
        end

        local scrSize = scroller.AbsoluteSize
        local canvas = scroller.CanvasSize
        if canvas.Y.Offset > 0 then
            return canvas.Y.Offset
        end
        return canvas.Y.Scale * scrSize.Y
    end

    local function scrollToObjIfScrollable(obj)
        local didScroll = false
        pcall(function()
            local scroller = getAncestorScroller(obj)
            if not scroller then return end
            task.wait()

            local scrSize = scroller.AbsoluteSize
            local canvasH = getCanvasHeight(scroller)
            local maxScrollY = math.max(0, canvasH - scrSize.Y)

            -- Some pages are built inside ScrollingFrames even when their content
            -- fits. Only move the canvas when there is actual scroll space.
            if maxScrollY <= 2 then return end

            local objAbs  = obj.AbsolutePosition
            local objSize = obj.AbsoluteSize
            local scrAbs  = scroller.AbsolutePosition
            local relTop  = objAbs.Y - scrAbs.Y + scroller.CanvasPosition.Y
            local targetY = math.clamp(relTop - math.max(8, (scrSize.Y - objSize.Y) * 0.35), 0, maxScrollY)

            if math.abs(targetY - scroller.CanvasPosition.Y) > 1 then
                scroller.CanvasPosition = Vector2.new(scroller.CanvasPosition.X, targetY)
                didScroll = true
            else
                -- Page is scrollable and the row is already in view.
                didScroll = true
            end
        end)
        return didScroll
    end

    local function flashFeature(featureName)
        -- Removed by request. Search results now only open/scroll to the feature.
    end

    local function clearResults()
        if not results then return end
        for _, child in ipairs(results:GetChildren()) do
            if child:IsA("TextButton") or child:IsA("TextLabel") then
                child:Destroy()
            end
        end
    end

    local function resizeSearchArea(rowCount, empty)
        if not results or not searchContainer then return end
        local resultsH = 0
        if rowCount > 0 then
            resultsH = 8 + rowCount * 32
        elseif empty then
            resultsH = 42
        end
        results.Visible = resultsH > 0
        results.Size = UDim2.new(1, 0, 0, resultsH)
        searchContainer.Size = UDim2.new(1, 0, 0, 62 + resultsH)
    end

    local function addEmptyState(text)
        local lbl = Instance.new("TextLabel", results)
        lbl.Name = "EmptyState"
        lbl.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
        lbl.BorderSizePixel = 0
        lbl.Size = UDim2.new(1, 0, 0, 34)
        lbl.Text = text
        lbl.Font = Enum.Font.Gotham
        lbl.TextSize = 12
        lbl.TextColor3 = Color3.fromRGB(150, 150, 150)
        lbl.TextXAlignment = Enum.TextXAlignment.Center
        Instance.new("UICorner", lbl).CornerRadius = UDim.new(0, 7)
    end

    local function addResult(item)
        local btn = Instance.new("TextButton", results)
        btn.Size = UDim2.new(1, 0, 0, 30)
        btn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        btn.BorderSizePixel = 0
        btn.AutoButtonColor = false
        btn.Text = ""
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 7)
        local btnStroke = Instance.new("UIStroke", btn)
        btnStroke.Color = Color3.fromRGB(40, 40, 40)
        btnStroke.Thickness = 1
        btnStroke.Transparency = 0.5

        local nameLbl = Instance.new("TextLabel", btn)
        nameLbl.BackgroundTransparency = 1
        nameLbl.Position = UDim2.new(0, 10, 0, 0)
        nameLbl.Size = UDim2.new(1, -90, 1, 0)
        nameLbl.Text = item.feature
        nameLbl.Font = Enum.Font.GothamMedium
        nameLbl.TextSize = 12
        nameLbl.TextColor3 = Color3.fromRGB(235, 235, 235)
        nameLbl.TextXAlignment = Enum.TextXAlignment.Left
        nameLbl.TextYAlignment = Enum.TextYAlignment.Center
        nameLbl.TextTruncate = Enum.TextTruncate.AtEnd

        local pageLbl = Instance.new("TextLabel", btn)
        pageLbl.BackgroundTransparency = 1
        pageLbl.AnchorPoint = Vector2.new(1, 0.5)
        pageLbl.Position = UDim2.new(1, -10, 0.5, 0)
        pageLbl.Size = UDim2.new(0, 74, 1, 0)
        pageLbl.Text = item.page
        pageLbl.Font = Enum.Font.Gotham
        pageLbl.TextSize = 11
        pageLbl.TextColor3 = Color3.fromRGB(140, 140, 140)
        pageLbl.TextXAlignment = Enum.TextXAlignment.Right
        pageLbl.TextYAlignment = Enum.TextYAlignment.Center

        btn.MouseEnter:Connect(function()
            local accent = getEffectiveAccent()
            btn.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
            btnStroke.Color = accent
            btnStroke.Transparency = 0.2
            pageLbl.TextColor3 = accent
        end)
        btn.MouseLeave:Connect(function()
            btn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
            btnStroke.Color = Color3.fromRGB(40, 40, 40)
            btnStroke.Transparency = 0.5
            pageLbl.TextColor3 = Color3.fromRGB(140, 140, 140)
        end)
        btn.MouseButton1Click:Connect(function()
            if searchBox then searchBox:ReleaseFocus() end
            if openPage(item.page) then
                task.delay(0.35, function()
                    pcall(function() scrollToFeature(item.feature) end)
                end)
            end
        end)
    end

    local function refreshResults()
        if not searchBox then return end
        clearResults()
        local q = (searchBox.Text or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
        if clearBtn then clearBtn.Visible = q ~= "" end
        if q == "" then
            resizeSearchArea(0, false)
            return
        end

        local count = 0
        for _, item in ipairs(items) do
            local hay = (item.page .. " " .. item.feature):lower()
            if hay:find(q, 1, true) then
                addResult(item)
                count = count + 1
                if count >= 8 then break end
            end
        end

        if count == 0 then
            addEmptyState("No matches for \"" .. searchBox.Text .. "\"")
            resizeSearchArea(0, true)
        else
            resizeSearchArea(count, false)
        end
    end

    local function buildSearchUI(parent)
        if searchContainer and searchContainer.Parent then return end

        searchContainer = Instance.new("Frame", parent)
        searchContainer.Name = "ZyxSearchContainer"
        searchContainer.BackgroundTransparency = 1
        searchContainer.BorderSizePixel = 0
        searchContainer.Size = UDim2.new(1, 0, 0, 62)
        searchContainer.LayoutOrder = 2

        local box = Instance.new("Frame", searchContainer)
        box.Name = "SearchBoxShell"
        box.Size = UDim2.new(1, 0, 0, 38)
        box.BackgroundColor3 = Color3.fromRGB(11, 11, 11)
        box.BorderSizePixel = 0
        box:SetAttribute("ZyxAccentStroke", true)
        Instance.new("UICorner", box).CornerRadius = UDim.new(0, 8)
        local boxStroke = Instance.new("UIStroke", box)
        boxStroke.Color = getEffectiveAccent()
        boxStroke.Thickness = 1
        boxStroke.Transparency = 0.35

        local iconImg = Instance.new("ImageLabel", box)
        iconImg.Name = "SearchIcon"
        iconImg.BackgroundTransparency = 1
        iconImg.Size = UDim2.new(0, 16, 0, 16)
        iconImg.Position = UDim2.new(0, 10, 0.5, -8)
        iconImg.ImageColor3 = Color3.fromRGB(170, 170, 170)
        do
            local okAsset, asset = pcall(function() return Library:Asset("file-search") end)
            iconImg.Image = (okAsset and type(asset) == "string" and asset ~= "" and asset ~= "file-search")
                and asset
                or "rbxassetid://10723366550"
        end

        searchBox = Instance.new("TextBox", box)
        searchBox.Name = "SearchBox"
        searchBox.Size = UDim2.new(1, -62, 1, 0)
        searchBox.Position = UDim2.new(0, 34, 0, 0)
        searchBox.BackgroundTransparency = 1
        searchBox.ClearTextOnFocus = false
        searchBox.PlaceholderText = "Search feature..."
        searchBox.PlaceholderColor3 = Color3.fromRGB(125, 125, 125)
        searchBox.Text = ""
        searchBox.Font = Enum.Font.GothamMedium
        searchBox.TextSize = 13
        searchBox.TextColor3 = Color3.fromRGB(240, 240, 240)
        searchBox.TextXAlignment = Enum.TextXAlignment.Left

        clearBtn = Instance.new("TextButton", box)
        clearBtn.Name = "ClearBtn"
        clearBtn.AnchorPoint = Vector2.new(1, 0.5)
        clearBtn.Size = UDim2.new(0, 22, 0, 22)
        clearBtn.Position = UDim2.new(1, -9, 0.5, 0)
        clearBtn.BackgroundTransparency = 1
        clearBtn.Text = "×"
        clearBtn.Font = Enum.Font.GothamBold
        clearBtn.TextSize = 18
        clearBtn.TextColor3 = Color3.fromRGB(170, 170, 170)
        clearBtn.AutoButtonColor = false
        clearBtn.Visible = false

        results = Instance.new("Frame", searchContainer)
        results.Name = "SearchResults"
        results.Position = UDim2.new(0, 0, 0, 46)
        results.Size = UDim2.new(1, 0, 0, 0)
        results.BackgroundTransparency = 1
        results.BorderSizePixel = 0
        results.Visible = false
        local resultsLayout = Instance.new("UIListLayout", results)
        resultsLayout.Padding = UDim.new(0, 4)
        resultsLayout.FillDirection = Enum.FillDirection.Vertical
        resultsLayout.SortOrder = Enum.SortOrder.LayoutOrder

        clearBtn.MouseButton1Click:Connect(function()
            searchBox.Text = ""
            clearBtn.Visible = false
            clearResults()
            resizeSearchArea(0, false)
        end)

        searchBox:GetPropertyChangedSignal("Text"):Connect(refreshResults)
        searchBox.Focused:Connect(refreshResults)
    end

    task.spawn(function()
        for _ = 1, 20 do
            local scroller = findSearchScroller()
            if scroller then
                buildSearchUI(scroller)
                return
            end
            task.wait(0.2)
        end
    end)
end

setupFeatureSearch({
    Visuals        = visualsPage,
    Misc           = miscPage,
    Movements      = _G.__ZyxMovementPage,
    Rage           = ragePage,
    ["End Game"]   = endGamePage,
    Autofarms      = autofarmsPage,
    Spectate       = spectatePage,
    Audio          = audioPage,
    ["Audio Player"] = _G.__ZyxAudioPlayerPage,
    Customize      = customizePage,
    Configs        = configPage,
    Search         = searchPage,
    Info           = infoPage,
})

end  -- close CONFIGS_PAGE section
-- =============================================
-- 🌈 CHROMA MASTER LOOP
-- =============================================
-- One Heartbeat connection updates the rainbow hue, live theme accent,
-- custom overlay accents, and ESP highlight colors.
local function anyESPChroma()
    for _, info in ipairs(ESP_LABELS) do
        local t = theme[info.key]
        if t and (t[9] or t[10]) then return true end
    end
    return false
end

local function applyAccentToTaggedUI(accent)
    for _, root in ipairs(collectGuiRoots()) do
        for _, obj in ipairs(root:GetDescendants()) do
            if obj:GetAttribute("ZyxAccentStroke") then
                local stroke = obj:IsA("UIStroke") and obj or obj:FindFirstChildOfClass("UIStroke")
                if stroke then stroke.Color = accent end
            end
            if obj:GetAttribute("ZyxAccentText")
            and (obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox")) then
                obj.TextColor3 = accent
            end
            if obj:GetAttribute("ZyxAccentBG") and obj:IsA("GuiObject") then
                obj.BackgroundColor3 = accent
            end
        end
    end
end

-- Wrapped in do-end to give the Heartbeat callback a fresh local register
-- pool, avoiding the Lua 200-local limit hit by the large script chunk above.
do
    local libraryAccentAccum = 0
    local espAccum = 0
    local avatarProtectAccum = 0
    RunService.Heartbeat:Connect(function(dt)
        chromaHue = (chromaHue + dt * 0.18) % 1

        local accent = getEffectiveAccent()
        libraryAccentAccum = libraryAccentAccum + dt
        espAccum = espAccum + dt
        avatarProtectAccum = avatarProtectAccum + dt

        -- Accent + UI refresh (~8Hz).
        if libraryAccentAccum >= 0.12 then
            libraryAccentAccum = 0
            if theme.accentChroma then
                pushAccentToLibrary(false)
            end
            applyAccentToTaggedUI(accent)

            if applyBtn then applyBtn.BackgroundColor3 = accent end
            if picker and picker.chroma and crPill then crPill.BackgroundColor3 = accent end
            if avatarProtectAccum >= 1 then
                avatarProtectAccum = 0
                if protectProfileAvatarImages then protectProfileAvatarImages() end
            end
        end

        -- ESP chroma refresh (~10Hz).
        if espAccum >= 0.10 then
            espAccum = 0
            if anyESPChroma() then
                refreshAllESPs()
            end
            -- Wallhop viewer chroma
            if _G.__ZyxWhl and _G.__ZyxWhl.getChroma() then
                _G.__ZyxWhl.setColor(Color3.fromHSV(chromaHue, 1, 1))
            end
        end
    end)
end

pcall(function() ((getgenv and getgenv()) or _G).__ZyxLoadingSet("Restoring saved settings", 0.88) end)

-- =============================================
-- 🚀 STARTUP STATE RESTORE
-- =============================================
if state.fullbright   then enableFullbright()  end
if state.noslow       then enableNoSlow()      end
if state.soundpack    then refreshSoundpack()  end
if state.playerESP    then
    for _, p in pairs(game:GetService("Players"):GetPlayers()) do applyPlayerHighlight(p) end
end
if state.doorESP      then applyDoorESP()      end
if state.exitESP      then applyExitESP()      end
if state.freezepodESP then applyFreezeESP()    end
Olympia.apply()
pcall(function() ((getgenv and getgenv()) or _G).__ZyxLoadingFinish("Ready") end)

print("[ZyxLab v4] Loaded — XovaModedLib UI · Made by ZyxFTF")

end -- close do-end local register reset block


-- Lightweight grouped caches
local ZyxLabCache = {
    ESP = {},
    Connections = {},
    Computers = {},
    Doors = {},
    Players = {}
}

local ZyxLabToggles = {}

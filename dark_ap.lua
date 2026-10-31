local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    repeat task.wait() until Players.LocalPlayer
    LocalPlayer = Players.LocalPlayer
end

local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Camera = workspace.CurrentCamera

local CONFIG_FILE = "DARK_AP_config.json"
local ALL_POSSIBLE_CMDS = { "tiny", "inverse", "rocket", "balloon", "ragdoll", "morph", "jumpscare", "jail", "nightvision", "nil" }

local updateWindowSize
local rebuild

-- ========================= PERSISTENCIA SEGURA =========================
local savedConfig = {}
pcall(function()
    if isfile and readfile and isfile(CONFIG_FILE) then
        local success, decoded = pcall(function() return HttpService:JSONDecode(readfile(CONFIG_FILE)) end)
        if success and type(decoded) == "table" then savedConfig = decoded end
    end
end)

local function getVal(key, default)
    local val = nil
    pcall(function() val = savedConfig[key] end)
    if val == nil then return default end
    return val
end

local SavedCMDS = getVal("SavedCMDS", {})
local SemiCMDS = getVal("SemiCMDS", {})
if #SavedCMDS == 0 then for _, v in ipairs(ALL_POSSIBLE_CMDS) do table.insert(SavedCMDS, v) end end
if #SemiCMDS == 0 then for _, v in ipairs(ALL_POSSIBLE_CMDS) do table.insert(SemiCMDS, v) end end

local SpamDelay = getVal("SpamDelay", 0)
local SemiDelay = getVal("SemiDelay", 0.5)
local ProximityEnabled = getVal("ProximityEnabled", false)
local ProximityRange = getVal("ProximityRange", 30)
local AutoSemiBtnVisible = getVal("AutoSemiBtnVisible", true)
local ProtectorCooldown = getVal("ProtectorCooldown", 2.5)
local ProtectorNearestFallback = getVal("ProtectorNearestFallback", true)
local ProtectorScanRange = getVal("ProtectorScanRange", 40)
local ProtectorPromptDetection = getVal("ProtectorPromptDetection", true)
local ProtectorRemoteDetection = getVal("ProtectorRemoteDetection", true)

-- Variables de Filtros
local FilterFmly = getVal("FilterFmly", false)
local FilterDark = getVal("FilterDark", false)
local FilterCustomEnabled = getVal("FilterCustomEnabled", false)
local CustomFilteredUsers = getVal("CustomFilteredUsers", {})

local BaseProtectorEnabled = getVal("BaseProtectorEnabled", true)

local StealerConfigs = getVal("StealerConfigs", { {} })
if type(StealerConfigs) ~= "table" or #StealerConfigs == 0 then StealerConfigs = { {} } end

local savedWinPos = getVal("WinPos", nil)
local SemiButtons = {}
local SemiQueue = {}
local adminTextBox = nil
local busy = false
local DebugMode = false

-- =====================================================================
-- DARK AP · BLOQUE DE ACCESO  (reemplaza TODO desde
--   "-- ===== SISTEMA DE ACCESO (DARK / PRUEBA 1H) =====" hasta la linea  runAccessFlow()
--  y borra tambien el "PANEL SECRETO (TECLA K)" y el "Monitor de acceso" del final
--  (el monitor nuevo esta al final de este archivo))
-- =====================================================================
PANEL_ACTIVE = true

-- >>> CONFIGURA ESTO <<<
local API_URL        = "https://dark-ap-server.onrender.com"   -- servidor de verificacion (ver server.js)
local DISCORD_INVITE = "https://discord.gg/MRNfySceKX"

local LANGS = {
    { code = "en", name = "English" }, { code = "es", name = "Español" },
    { code = "ru", name = "Русский" }, { code = "de", name = "Deutsch" },
    { code = "zh", name = "中文" },    { code = "ja", name = "日本語" },
}

-- ---------------------------------------------------------------------
-- TRADUCCIONES. Si falta una clave en un idioma, se usa ingles.
-- Panel: usa tr("clave") en vez del texto en espanol (lista en las notas).
-- ---------------------------------------------------------------------
local T = {
 en = {
  selectLang="Select your language",
  promo="Welcome to DARK AP!\n\nFast, automatic and constantly updated.\n\nTry it free for 1 hour before adding DARK to your name.",
  claim="Claim 1h Free",
  verifyTitle="Discord verification",
  verifyText="Joining our Discord is required.\n1) Press Join Discord\n2) In the server, run  /verify  and enter this code:",
  join="Join Discord (copies link)", copied="Link copied: paste it in your browser",
  check="I already verified", checking="Checking...", notVerified="Not verified yet. Run the command in Discord.",
  gettingCode="Getting code...", serverError="Verification server unreachable. Try again.",
  lockedTitle="Access Locked",
  lockedText="Your free hour is over. To keep using the panel add Dark to your name or display name (e.g. Dark_baby), then press Check again.",
  recheck="Check again", kick="Leave game", stillNoDark="No 'Dark' found in your name yet.",
  kickMsg="DARK AP: access locked.",
  cardSpam="Spam all & delay", delayAll="Delay All (seconds):", delaySemi="Delay Semi (seconds):", ph="e.g. 0.50",
  saveSpam="Save Spam settings", saveSemi="Save Semi settings", saved="Saved!",
  cardSemi="Semi Full · 3 random per click", showSemi="Show Semi button", on="ON", off="OFF",
  cardBase="Base protector · anti-steal", baseProt="Base Protector", hide="Hide", show="Show",
  testBase="Manual test (nearest player)", testSent="Test sent to ", noNear="No players nearby",
  addCombo="+ Add command combo", detPrompts="Prompt detection", detRemotes="Remote detection", fallback="Nearest-player fallback",
  cardFilter="PLAYER FILTERS", hideFmly="Hide 'fmly'", hideDark="Hide 'dark'", useCustom="Use custom filter",
  phUsers="Comma-separated users (e.g. Qty, Admin)", saveFilters="Save & apply filters",
  back="Back to list", emptyServer="Empty / filtered server", trial="TRIAL", adminPanel="ADMIN PANEL",
 },
 es = {
  selectLang="Selecciona tu idioma",
  promo="¡Bienvenido a DARK AP!\n\nRápido, automático y constantemente actualizado.\n\nPruébalo 1 hora gratis antes de ponerte DARK en el nombre.",
  claim="Reclamar 1h gratis",
  verifyTitle="Verificación de Discord",
  verifyText="Es obligatorio entrar a nuestro Discord.\n1) Pulsa Unirse al Discord\n2) En el servidor ejecuta  /verificar  e introduce este código:",
  join="Unirse al Discord (copia el link)", copied="Link copiado: pégalo en tu navegador",
  check="Ya verifiqué", checking="Comprobando...", notVerified="Aún no verificado. Ejecuta el comando en Discord.",
  gettingCode="Obteniendo código...", serverError="Servidor de verificación inaccesible. Reintenta.",
  lockedTitle="Acceso bloqueado",
  lockedText="Tu hora gratis terminó. Para seguir usando el panel pon Dark en tu nombre de usuario o de visualización (ej: Dark_baby) y pulsa Chequear de nuevo.",
  recheck="Chequear de nuevo", kick="Salir del juego", stillNoDark="Aún no hay 'Dark' en tu nombre.",
  kickMsg="DARK AP: acceso bloqueado.",
  cardSpam="Spam general y delay", delayAll="Delay All (Segundos):", delaySemi="Delay Semi (Segundos):", ph="Ej: 0.50",
  saveSpam="Guardar ajustes de Spam", saveSemi="Guardar ajustes Semi", saved="¡Guardado!",
  cardSemi="Semi Full · 3 aleatorios por click", showSemi="Mostrar Botón Semi", on="ON", off="OFF",
  cardBase="Protector de base · anti-robo", baseProt="Base Protector", hide="Ocultar", show="Mostrar",
  testBase="Test Manual (jugador más cercano)", testSent="¡Test enviado a ", noNear="No hay jugadores cerca",
  addCombo="+ Añadir combo de comandos", detPrompts="Detección por prompts", detRemotes="Detección por remotos", fallback="Fallback al jugador cercano",
  cardFilter="FILTROS DE JUGADORES", hideFmly="Ocultar 'fmly'", hideDark="Ocultar 'dark'", useCustom="Usar Filtro Personalizado",
  phUsers="Users separados por coma (ej: Qty, Admin)", saveFilters="Guardar y Aplicar Filtros",
  back="Volver a la lista", emptyServer="Servidor Vacío / Filtrado", trial="PRUEBA", adminPanel="ADMIN PANEL",
 },
 ru = { selectLang="Выберите язык", claim="Получить 1 час бесплатно",
  verifyTitle="Проверка Discord", join="Вступить в Discord (копирует ссылку)", check="Я уже прошёл проверку",
  lockedTitle="Доступ заблокирован", recheck="Проверить снова", kick="Выйти из игры",
  lockedText="Бесплатный час закончился. Добавьте Dark в ник или отображаемое имя (например Dark_baby) и нажмите «Проверить снова».",
  verifyText="Вступление в наш Discord обязательно.\n1) Нажмите «Вступить»\n2) На сервере выполните /verify и введите код:" },
 de = { selectLang="Wähle deine Sprache", claim="1 Stunde gratis holen",
  verifyTitle="Discord-Verifizierung", join="Discord beitreten (kopiert Link)", check="Ich habe verifiziert",
  lockedTitle="Zugang gesperrt", recheck="Erneut prüfen", kick="Spiel verlassen",
  lockedText="Deine Gratis-Stunde ist vorbei. Setze Dark in deinen Namen oder Anzeigenamen (z.B. Dark_baby) und drücke Erneut prüfen.",
  verifyText="Der Beitritt zu unserem Discord ist Pflicht.\n1) Discord beitreten\n2) Auf dem Server /verify ausführen und diesen Code eingeben:" },
 zh = { selectLang="请选择你的语言", claim="领取 1 小时免费试用",
  verifyTitle="Discord 验证", join="加入 Discord（复制链接）", check="我已验证",
  lockedTitle="访问已被锁定", recheck="重新检查", kick="退出游戏",
  lockedText="免费时间已结束。请在用户名或显示名中加入 Dark（例如 Dark_baby），然后点击重新检查。",
  verifyText="必须加入我们的 Discord。\n1) 点击加入\n2) 在服务器中执行 /verify 并输入此代码：" },
 ja = { selectLang="言語を選択してください", claim="1時間無料で試す",
  verifyTitle="Discord認証", join="Discordに参加（リンクをコピー）", check="認証しました",
  lockedTitle="アクセスがロックされました", recheck="再確認", kick="ゲームを退出",
  lockedText="無料の1時間が終了しました。ユーザー名または表示名にDarkを入れて（例: Dark_baby）再確認を押してください。",
  verifyText="当社のDiscordへの参加が必須です。\n1) 参加を押す\n2) サーバーで /verify を実行しコードを入力：" },
}
for code, tbl in pairs(T) do if code ~= "en" then setmetatable(tbl, { __index = T.en }) end end

local LANG = getVal("Lang", nil)
if type(LANG) ~= "string" or not T[LANG] then LANG = nil end
local function tr(key) return (T[LANG or "en"] or T.en)[key] or T.en[key] or key end

local DiscordId = getVal("DiscordId", nil)       -- cache local; la verdad la tiene el servidor

local function saveAccessData()
    if not writefile then return end
    savedConfig.Lang = LANG
    savedConfig.DiscordId = DiscordId
    pcall(function() writefile(CONFIG_FILE, HttpService:JSONEncode(savedConfig)) end)
end

-- ---------------------------------------------------------------------
-- NOMBRE: revisa usuario interno Y nombre de visualizacion, sin importar mayus/minus
-- ---------------------------------------------------------------------
local function hasDarkName()
    return string.find(string.lower(LocalPlayer.Name), "dark", 1, true) ~= nil
        or string.find(string.lower(LocalPlayer.DisplayName), "dark", 1, true) ~= nil
end

-- ---------------------------------------------------------------------
-- API del servidor
-- ---------------------------------------------------------------------
local timeOffset = 0
local function nowS() return os.time() + timeOffset end

local function api(path, extra)
    local req = (syn and syn.request) or request or http_request
    if not req then return nil end
    local body = {
        userId = LocalPlayer.UserId, name = LocalPlayer.Name, display = LocalPlayer.DisplayName,
        hasDark = hasDarkName(), discordId = DiscordId, lang = LANG, placeId = game.PlaceId,
    }
    for k, v in pairs(extra or {}) do body[k] = v end
    local ok, res = pcall(req, { Url = API_URL .. path, Method = "POST",
        Headers = { ["Content-Type"] = "application/json" }, Body = HttpService:JSONEncode(body) })
    if not ok or type(res) ~= "table" or res.StatusCode ~= 200 then return nil end
    local ok2, data = pcall(function() return HttpService:JSONDecode(res.Body) end)
    if ok2 and type(data) == "table" then
        if data.now then timeOffset = data.now - os.time() end
        return data
    end
    return nil
end

-- estado = { verified, trialEnd, trialUsed, discordId }
local ACCESS = { verified = false, trialEnd = 0, trialUsed = false }
local function refreshStatus()
    local d = api("/status")
    if d then
        ACCESS.verified = d.verified and true or false
        ACCESS.trialEnd = tonumber(d.trialEnd) or 0
        ACCESS.trialUsed = d.trialUsed and true or false
        if d.discordId and d.discordId ~= DiscordId then DiscordId = d.discordId; saveAccessData() end
    end
    return d ~= nil
end

local function evaluate()
    if not ACCESS.verified then return "verify" end
    if hasDarkName() then return "ok" end                 -- ilimitado
    if ACCESS.trialEnd > nowS() then return "ok" end      -- prueba activa
    if not ACCESS.trialUsed then return "promo" end
    return "locked"
end

-- ---------------------------------------------------------------------
-- GUI de acceso (bloquea hasta que se avanza)
-- ---------------------------------------------------------------------
local gateCounter = 0
local function showGate(mode)
    gateCounter += 1
    local closed = false
    local gui = Instance.new("ScreenGui")
    gui.Name = "DARK_AP_GATE"; gui.ResetOnSpawn = false; gui.DisplayOrder = 9999999; gui.IgnoreGuiInset = true
    pcall(function() if gethui then gui.Parent = gethui() end end)
    if not gui.Parent then pcall(function() gui.Parent = game:GetService("CoreGui") end) end
    if not gui.Parent then gui.Parent = PlayerGui end

    local bg = Instance.new("Frame", gui)
    bg.Size = UDim2.fromScale(1, 1); bg.BackgroundColor3 = Color3.new(0, 0, 0); bg.BackgroundTransparency = 0.35; bg.BorderSizePixel = 0
    bg.Active = true

    local heights = { lang = 330, promo = 330, verify = 400, locked = 330 }
    local card = Instance.new("Frame", gui)
    card.Size = UDim2.fromOffset(430, heights[mode]); card.AnchorPoint = Vector2.new(.5, .5); card.Position = UDim2.fromScale(.5, .5)
    card.BackgroundColor3 = Color3.fromRGB(15, 19, 29); card.BorderSizePixel = 0
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 12)
    local cs = Instance.new("UIStroke", card); cs.Color = Color3.fromRGB(99, 102, 241); cs.Transparency = .3

    local function label(text, y, h, size, color, font)
        local l = Instance.new("TextLabel", card)
        l.Size = UDim2.new(1, -24, 0, h); l.Position = UDim2.fromOffset(12, y); l.BackgroundTransparency = 1
        l.Text = text; l.TextColor3 = color or Color3.fromRGB(190, 198, 215); l.Font = font or Enum.Font.GothamMedium
        l.TextSize = size or 13; l.TextWrapped = true; l.TextYAlignment = Enum.TextYAlignment.Top
        return l
    end
    local function button(text, color, y, h)
        local b = Instance.new("TextButton", card)
        b.Size = UDim2.new(1, -24, 0, h or 38); b.Position = UDim2.fromOffset(12, y); b.BackgroundColor3 = color
        b.Text = text; b.TextColor3 = Color3.new(1, 1, 1); b.Font = Enum.Font.GothamBold; b.TextSize = 13
        b.BorderSizePixel = 0; b.AutoButtonColor = true
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
        return b
    end
    local function flash(b, text, color, orig, origColor)
        b.Text = text; if color then b.BackgroundColor3 = color end
        task.delay(2.2, function() if b and b.Parent then b.Text = orig; b.BackgroundColor3 = origColor end end)
    end
    local purple, red, green, discord = Color3.fromRGB(99,102,241), Color3.fromRGB(239,68,68), Color3.fromRGB(34,197,94), Color3.fromRGB(88,101,242)

    local titles = { lang = "🌐 " .. tr("selectLang"), promo = "⭐ DARK AP", verify = "💬 " .. tr("verifyTitle"), locked = "🔒 " .. tr("lockedTitle") }
    label(titles[mode], 12, 28, 16, Color3.fromRGB(231, 236, 245), Enum.Font.GothamBold)

    if mode == "lang" then
        for i, l in ipairs(LANGS) do
            local b = button(l.name, Color3.fromRGB(21, 26, 39), 48 + (i - 1) * 44, 38)
            b.MouseButton1Click:Connect(function() LANG = l.code; saveAccessData(); closed = true end)
        end

    elseif mode == "promo" then
        label(tr("promo"), 50, 170, 13)
        local c = button("🎁 " .. tr("claim"), purple, 260, 48)
        c.MouseButton1Click:Connect(function()
            local d = api("/claim")
            if d and d.ok then refreshStatus(); closed = true
            else flash(c, "⚠️ " .. tr("serverError"), red, "🎁 " .. tr("claim"), purple) end
        end)

    elseif mode == "verify" then
        label(tr("verifyText"), 48, 90, 12)
        local codeLbl = label(tr("gettingCode"), 136, 40, 26, Color3.fromRGB(34, 211, 238), Enum.Font.GothamBold)
        codeLbl.TextXAlignment = Enum.TextXAlignment.Center
        task.spawn(function()
            local d = api("/code")
            if codeLbl.Parent then codeLbl.Text = (d and d.code) or tr("serverError") end
        end)
        local j = button("💬 " .. tr("join"), discord, 200, 38)
        j.MouseButton1Click:Connect(function()
            pcall(function() if setclipboard then setclipboard(DISCORD_INVITE) end end)
            flash(j, "✅ " .. tr("copied"), nil, "💬 " .. tr("join"), discord)
        end)
        local chk = button(tr("check"), purple, 248, 44)
        local msg = label("", 300, 40, 11, Color3.fromRGB(139, 150, 173))
        local function doCheck()
            chk.Text = tr("checking")
            if refreshStatus() and ACCESS.verified then closed = true
            else chk.Text = tr("check"); msg.Text = tr("notVerified") end
        end
        chk.MouseButton1Click:Connect(doCheck)
        task.spawn(function()      -- comprobacion automatica cada 3 s
            while not closed and gui.Parent do
                task.wait(3)
                if not closed and refreshStatus() and ACCESS.verified then closed = true end
            end
        end)

    elseif mode == "locked" then
        label(tr("lockedText"), 50, 120, 13)
        local msg = label("", 175, 20, 11, Color3.fromRGB(245, 158, 11))
        local rc = button("🔄 " .. tr("recheck"), green, 205, 44)
        local kk = button("🚪 " .. tr("kick"), red, 257, 44)
        rc.MouseButton1Click:Connect(function()
            rc.Text = tr("checking")
            refreshStatus()
            if hasDarkName() then closed = true       -- re-lee Name y DisplayName en este momento
            else rc.Text = "🔄 " .. tr("recheck"); msg.Text = tr("stillNoDark") end
        end)
        kk.MouseButton1Click:Connect(function() LocalPlayer:Kick(tr("kickMsg")) end)
    end

    repeat task.wait(0.15) until closed or not gui.Parent
    pcall(function() gui:Destroy() end)
end

-- Se ejecuta en CADA entrada: revisa idioma -> verificacion Discord -> nombre -> prueba
local function runAccessFlow()
    if not LANG then showGate("lang") end
    while true do
        if not refreshStatus() then
            -- servidor caido: no se da acceso
            showGate("verify")
        else
            local mode = evaluate()
            if mode == "ok" then break end
            showGate(mode)
        end
    end
    api("/event", { event = hasDarkName() and "login_dark" or "login_trial" })
end

runAccessFlow()

-- ========================= FUNCIONES =========================
local function findAdminTextBox()
    if adminTextBox and adminTextBox.Parent then return adminTextBox end
    local ok, res = pcall(function()
        return PlayerGui:WaitForChild("AdminPanel", 5):WaitForChild("AdminPanel", 5):WaitForChild("CommandBox", 5):WaitForChild("TextBox", 5)
    end)
    if ok and res then adminTextBox = res; return adminTextBox end
    local found = nil
    pcall(function()
        for _, d in ipairs(PlayerGui:GetDescendants()) do
            if d:IsA("TextBox") then
                local p = d:GetFullName():lower()
                if p:find("adminpanel") and p:find("commandbox") then found = d; break end
            end
        end
    end)
    adminTextBox = found
    return adminTextBox
end

local function fireCmdOneFrame(cmd, name)
    if not PANEL_ACTIVE then return false end -- bloqueo central de acceso
    local tb = adminTextBox
    if not tb or not tb.Parent then tb = findAdminTextBox(); if not tb then return false end end
    tb.Text = ";" .. cmd .. " " .. name
    local fired = false
    if firesignal then fired = pcall(firesignal, tb.FocusLost, true)
    elseif getconnections then
        for _, c in pairs(getconnections(tb.FocusLost)) do pcall(function() c:Fire(true) end); fired = true end
    end
    if not fired then pcall(function() tb:CaptureFocus(); tb:ReleaseFocus(true) end) end
    RunService.Heartbeat:Wait()
    if tb and tb.Parent then tb.Text = "" end
    return true
end

local function sendAll(name)
    local tb = findAdminTextBox()
    if not tb then return end
    local vis = tb.Visible
    tb.Visible = false
    for i, cmd in ipairs(SavedCMDS) do
        local startTime = os.clock()
        fireCmdOneFrame(cmd, name)
        if SpamDelay > 0 and i < #SavedCMDS then
            local t = SpamDelay - (os.clock() - startTime)
            if t > 0 then task.wait(t) end
        end
    end
    if tb and tb.Parent then tb.Visible = vis end
end

local function sendSpecific(cmd, name)
    local tb = findAdminTextBox()
    if not tb then return end
    local vis = tb.Visible
    tb.Visible = false
    fireCmdOneFrame(cmd, name)
    if tb and tb.Parent then tb.Visible = vis end
end

local function sendSequence(cmds, name, delay)
    local tb = findAdminTextBox()
    if not tb then return end
    local vis = tb.Visible
    tb.Visible = false
    for i, cmd in ipairs(cmds) do
        local startTime = os.clock()
        fireCmdOneFrame(cmd, name)
        if delay and delay > 0 and i < #cmds then
            local t = delay - (os.clock() - startTime)
            if t > 0 then task.wait(t) end
        end
    end
    if tb and tb.Parent then tb.Visible = vis end
end

local function getRandomSemiCommands(count)
    if #SemiCMDS == 0 then return {} end
    if #SemiQueue < count then
        SemiQueue = {}
        local available = {}
        for _, cmd in ipairs(SemiCMDS) do table.insert(available, cmd) end
        for i = #available, 2, -1 do
            local j = math.random(i)
            available[i], available[j] = available[j], available[i]
        end
        SemiQueue = available
    end
    local result = {}
    for i = 1, math.min(count, #SemiQueue) do
        table.insert(result, table.remove(SemiQueue, 1))
    end
    return result
end

local function getClosestPlayer()
    local closest, shortest = nil, math.huge
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return nil end
    local myPos = char.HumanoidRootPart.Position
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            local d = (plr.Character.HumanoidRootPart.Position - myPos).Magnitude
            if d < shortest then
                shortest = d
                closest = plr
            end
        end
    end
    return closest
end

-- ========================= DETECCION DE JUGADORES (AP) =========================
local AP_ATTRIBUTES = { "AP", "HasAP", "Admin", "IsAdmin", "AdminPanel", "HasAdmin", "Owner" }
local AP_TOOL_KEYS = { "admin", "panel", "mod" }

local function getEquippedTool(plr)
    local char = plr and plr.Character
    if not char then return nil end
    for _, t in ipairs(char:GetChildren()) do
        if t:IsA("Tool") then return t end
    end
    return nil
end

local function attrTruthy(v)
    if v == nil or v == false or v == 0 or v == "" then return false end
    if type(v) == "number" and v > 1000000000 and workspace.GetServerTimeNow then
        return v > workspace:GetServerTimeNow()
    end
    return true
end

local function playerHasAP(plr)
    for _, obj in ipairs({ plr, plr and plr.Character }) do
        if obj then
            for _, a in ipairs(AP_ATTRIBUTES) do
                local ok, v = pcall(function() return obj:GetAttribute(a) end)
                if ok and attrTruthy(v) then return true end
            end
        end
    end
    local tool = getEquippedTool(plr)
    if tool then
        local nm = tool.Name:lower()
        for _, k in ipairs(AP_TOOL_KEYS) do
            if nm:find(k, 1, true) then return true end
        end
    end
    return false
end

-- ========================= FILTRO DE JUGADORES =========================
local function isPlayerFiltered(plrName)
    local lowerName = string.lower(plrName)
    if FilterFmly and string.find(lowerName, "fmly") then return true end
    if FilterDark and string.find(lowerName, "dark") then return true end
    if FilterCustomEnabled then
        for _, customName in ipairs(CustomFilteredUsers) do
            if customName ~= "" and string.find(lowerName, string.lower(customName)) then
                return true
            end
        end
    end
    return false
end

-- ========================= BASE PROTECTOR (ANTI-ROBO) =========================
local recentThieves = {}
local lastProtectorFire = {}
local protectorSending = {}

local function getInstanceNameSafe(inst)
    if typeof(inst) ~= "Instance" then return "" end
    local ok, name = pcall(function() return inst.Name end)
    if ok and type(name) == "string" then return name end
    return ""
end

local function playerFromValue(value)
    if typeof(value) == "Instance" then
        local node = value
        for _ = 1, 6 do
            if not node then break end
            if node:IsA("Player") then return node end
            local fromChar = Players:GetPlayerFromCharacter(node)
            if fromChar then return fromChar end
            node = node.Parent
        end
    elseif type(value) == "number" then
        return Players:GetPlayerByUserId(value)
    elseif type(value) == "string" then
        local direct = Players:FindFirstChild(value)
        if direct then return direct end
        local lower = string.lower(value)
        for _, p in ipairs(Players:GetPlayers()) do
            if string.lower(p.Name) == lower or string.lower(p.DisplayName) == lower then
                return p
            end
        end
    end
    return nil
end

local function extractThiefFromArgs(args)
    for _, arg in ipairs(args) do
        local plr = playerFromValue(arg)
        if plr and plr ~= LocalPlayer then return plr end
        if type(arg) == "table" then
            for _, key in ipairs({ "Player", "player", "Thief", "thief", "UserId", "userId", "Name", "name", "Target", "target" }) do
                local ok, value = pcall(function() return arg[key] end)
                if ok then
                    local plr2 = playerFromValue(value)
                    if plr2 and plr2 ~= LocalPlayer then return plr2 end
                end
            end
        end
    end
    return nil
end

local function nearestOtherPlayer(range)
    range = tonumber(range) or 40
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local best, bestDist = nil, range
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            local d = (plr.Character.HumanoidRootPart.Position - hrp.Position).Magnitude
            if d < bestDist then
                best = plr
                bestDist = d
            end
        end
    end
    return best
end

local function triggerBaseProtector(thief, source)
    if not PANEL_ACTIVE then return false end
    if not BaseProtectorEnabled then return false end
    if not thief or thief == LocalPlayer then return false end
    if protectorSending[thief.UserId] then return false end
    if not findAdminTextBox() then return false end

    local now = os.clock()
    if lastProtectorFire[thief.UserId] and (now - lastProtectorFire[thief.UserId]) < math.max(ProtectorCooldown, 0) then
        return false
    end
    if #StealerConfigs == 0 then StealerConfigs = { {} } end

    local idx = recentThieves[thief.Name] or 1
    if idx < 1 or idx > #StealerConfigs then idx = 1 end
    local cmds = StealerConfigs[idx]
    if type(cmds) ~= "table" or #cmds == 0 then return false end

    lastProtectorFire[thief.UserId] = now
    recentThieves[thief.Name] = idx + 1
    if recentThieves[thief.Name] > #StealerConfigs then recentThieves[thief.Name] = 1 end

    protectorSending[thief.UserId] = true
    task.spawn(function()
        pcall(function()
            sendSequence(cmds, thief.Name, 0.03)
        end)
        task.wait(0.15)
        protectorSending[thief.UserId] = nil
    end)

    if DebugMode then
        print(("[PROTECTOR] comandos enviados a %s (%s)"):format(thief.Name, tostring(source or "desconocido")))
    end
    return true
end

local stealKeywords = { "steal", "rob", "take", "grab", "snatch", "pickup", "collect", "claim", "interact" }
local promptStealKeywords = { "steal", "rob", "take", "grab", "snatch", "pickup", "collect", "claim" }

local function containsKeyword(str, list)
    str = string.lower(tostring(str or ""))
    for _, kw in ipairs(list) do
        if str:find(kw, 1, true) then
            return true
        end
    end
    return false
end

local function checkArgsForSteal(args)
    for _, arg in ipairs(args) do
        if type(arg) == "string" and containsKeyword(arg, stealKeywords) then
            return true
        elseif typeof(arg) == "Instance" then
            if containsKeyword(getInstanceNameSafe(arg), stealKeywords) then return true end
            local ok, actionText = pcall(function() return arg.ActionText end)
            if ok and containsKeyword(actionText, stealKeywords) then return true end
        end
    end
    return false
end

local function analyzeRemotePayload(remoteName, args, source)
    if not BaseProtectorEnabled or not ProtectorRemoteDetection then return end
    local suspicious = containsKeyword(remoteName, stealKeywords) or checkArgsForSteal(args)
    if not suspicious then return end

    local thief = extractThiefFromArgs(args)
    if not thief and ProtectorNearestFallback then
        thief = nearestOtherPlayer(ProtectorScanRange)
    end
    if thief then
        triggerBaseProtector(thief, source or "remote")
    end
end

local function hookRemoteEvents()
    local seen = {}
    local function watch(obj)
        if seen[obj] then return end
        if obj:IsA("RemoteEvent") or obj:IsA("UnreliableRemoteEvent") then
            seen[obj] = true
            pcall(function()
                obj.OnClientEvent:Connect(function(...)
                    analyzeRemotePayload(obj.Name, { ... }, "OnClientEvent")
                end)
            end)
        end
    end

    for _, root in ipairs({ ReplicatedStorage, workspace, PlayerGui }) do
        for _, d in ipairs(root:GetDescendants()) do
            watch(d)
        end
        root.DescendantAdded:Connect(function(d)
            task.defer(watch, d)
        end)
    end
end

local function setupStealHook()
    if not (hookmetamethod and getnamecallmethod) then return end

    local old
    pcall(function()
        old = hookmetamethod(game, "__namecall", function(self, ...)
            local method = getnamecallmethod()
            local args = { ... }
            local rName = getInstanceNameSafe(self)

            if DebugMode and (method == "FireServer" or method == "InvokeServer" or method == "FireClient" or method == "InvokeClient") then
                print("[DEBUG REMOTE]", method, rName)
                for i, v in ipairs(args) do
                    print("  [Arg " .. i .. "]", typeof(v), tostring(v))
                end
            end

            if method == "FireClient" or method == "InvokeClient" then
                analyzeRemotePayload(rName, args, "__namecall:" .. tostring(method))
            end

            return old(self, ...)
        end)
    end)
end

local function promptLooksSteal(prompt)
    if containsKeyword(prompt.Name, promptStealKeywords) then return true end
    local okAction, action = pcall(function() return prompt.ActionText end)
    if okAction and containsKeyword(action, promptStealKeywords) then return true end
    local okObject, objectText = pcall(function() return prompt.ObjectText end)
    if okObject and containsKeyword(objectText, promptStealKeywords) then return true end

    local parent = prompt.Parent
    local depth = 0
    while parent and depth < 4 do
        if containsKeyword(parent.Name, promptStealKeywords) then return true end
        parent = parent.Parent
        depth = depth + 1
    end
    return false
end

local function setupPromptProtector()
    if not ProtectorPromptDetection then return end

    local function onPrompt(prompt, player)
        if not BaseProtectorEnabled or not ProtectorPromptDetection then return end
        if not prompt or not prompt.Parent then return end
        if not promptLooksSteal(prompt) then return end
        local thief = playerFromValue(player)
        if not thief and ProtectorNearestFallback then
            thief = nearestOtherPlayer(ProtectorScanRange)
        end
        if thief and thief ~= LocalPlayer then
            triggerBaseProtector(thief, "proximity_prompt")
        end
    end

    pcall(function()
        ProximityPromptService.PromptTriggered:Connect(onPrompt)
    end)

    local seen = {}
    local function watchPrompt(inst)
        if seen[inst] or not inst:IsA("ProximityPrompt") then return end
        seen[inst] = true
        pcall(function()
            inst.Triggered:Connect(function(player)
                onPrompt(inst, player)
            end)
        end)
    end

    for _, d in ipairs(workspace:GetDescendants()) do
        watchPrompt(d)
    end
    workspace.DescendantAdded:Connect(function(d)
        task.defer(watchPrompt, d)
    end)
end

setupStealHook()
hookRemoteEvents()
setupPromptProtector()

-- ========================= DETECCION DE ROBO EN TU BASE =========================
local function findMyBase()
    local plots = workspace:FindFirstChild("Plots")
    if not plots then return nil end
    for _, base in ipairs(plots:GetChildren()) do
        local sign = base:FindFirstChild("PlotSign")
        local yourBase = sign and sign:FindFirstChild("YourBase")
        if yourBase and yourBase.Enabled then return base end
    end
    for _, base in ipairs(plots:GetChildren()) do
        if base:IsA("Model") then
            for _, d in ipairs(base:GetDescendants()) do
                if d:IsA("TextLabel") and (d.Text:find(LocalPlayer.Name, 1, true) or d.Text:find(LocalPlayer.DisplayName, 1, true)) then
                    return base
                end
            end
        end
    end
    return nil
end

local plotBoxes = setmetatable({}, { __mode = "k" })
local function insidePlot(plot, pos)
    if not plot then return false end
    local box = plotBoxes[plot]
    if not box then
        local ok, cf, size = pcall(plot.GetBoundingBox, plot)
        box = ok and { cf, size } or false
        plotBoxes[plot] = box
    end
    if not box then return false end
    local l = box[1]:PointToObjectSpace(pos)
    return math.abs(l.X) <= box[2].X / 2 and math.abs(l.Z) <= box[2].Z / 2
end

task.spawn(function()
    while true do
        task.wait(0.35)
        if not PANEL_ACTIVE then continue end
        if not BaseProtectorEnabled then continue end
        local myBase = findMyBase()
        if not myBase then continue end
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                local okS, stealing = pcall(function() return plr:GetAttribute("Stealing") end)
                if okS and attrTruthy(stealing) and insidePlot(myBase, plr.Character.HumanoidRootPart.Position) then
                    triggerBaseProtector(plr, "base_robo")
                end
            end
        end
    end
end)

-- ========================= GUI =========================
for _, guiName in ipairs({ "DARK_AP", "DARK_AP_SPAM" }) do
    local oldGui = PlayerGui:FindFirstChild(guiName)
    if oldGui then oldGui:Destroy() end
end
pcall(function()
    if gethui then
        local h = gethui()
        local og = h:FindFirstChild("DARK_AP") or h:FindFirstChild("DARK_AP_SPAM")
        if og then og:Destroy() end
    end
end)

local GUI = Instance.new("ScreenGui")
GUI.Name = "DARK_AP"
GUI.ResetOnSpawn = false
GUI.DisplayOrder = 999999

pcall(function() if gethui then GUI.Parent = gethui() end end)
if not GUI.Parent then pcall(function() GUI.Parent = game:GetService("CoreGui") end) end
if not GUI.Parent then GUI.Parent = PlayerGui end

local C = {
    bg = Color3.fromRGB(10, 13, 20),
    panel = Color3.fromRGB(15, 19, 29),
    card = Color3.fromRGB(21, 26, 39),
    input = Color3.fromRGB(12, 16, 25),
    stroke = Color3.fromRGB(42, 50, 70),
    text = Color3.fromRGB(231, 236, 245),
    mute = Color3.fromRGB(139, 150, 173),
    purple = Color3.fromRGB(99, 102, 241),
    accent = Color3.fromRGB(99, 102, 241),
    accentHover = Color3.fromRGB(79, 70, 229),
    darkBtn = Color3.fromRGB(17, 21, 34),
    blue = Color3.fromRGB(34, 211, 238),
    cyanHover = Color3.fromRGB(14, 116, 144),
    green = Color3.fromRGB(34, 197, 94),
    red = Color3.fromRGB(239, 68, 68),
    yellow = Color3.fromRGB(245, 158, 11),
}

local ROW_HEIGHT = 64

local function corner(obj, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 6)
    c.Parent = obj
    return c
end

local function stroke(obj, color, thickness, transparency)
    local s = Instance.new("UIStroke")
    s.Color = color or C.stroke
    s.Thickness = thickness or 1
    s.Transparency = transparency or 0
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = obj
    return s
end

local function gradient(obj, top, bottom, rotation)
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, top),
        ColorSequenceKeypoint.new(1, bottom),
    })
    g.Rotation = rotation or 90
    g.Parent = obj
    return g
end

local function styleTextBox(tb)
    tb.BackgroundColor3 = C.input
    tb.TextColor3 = C.text
    tb.PlaceholderColor3 = C.mute
    tb.ClearTextOnFocus = false
    tb.BorderSizePixel = 0
    corner(tb, 6)
    local st = stroke(tb, C.stroke, 1, 0.25)
    tb.Focused:Connect(function()
        st.Color = C.accent
        st.Transparency = 0
    end)
    tb.FocusLost:Connect(function()
        st.Color = C.stroke
        st.Transparency = 0.25
    end)
end

local function addHover(btn, normal, hover)
    btn.AutoButtonColor = false
    btn.MouseEnter:Connect(function()
        if btn and btn.Parent then btn.BackgroundColor3 = hover end
    end)
    btn.MouseLeave:Connect(function()
        if btn and btn.Parent then btn.BackgroundColor3 = normal end
    end)
end

local Win = Instance.new("Frame")
Win.Size = UDim2.fromOffset(500, 112)
if savedWinPos then
    Win.Position = UDim2.new(savedWinPos.X or 0.5, savedWinPos.XOff or -240, savedWinPos.Y or 0.5, savedWinPos.YOff or -54)
else
    Win.Position = UDim2.new(0.5, -250, 0.5, -56)
end
Win.BackgroundColor3 = C.bg
Win.BorderSizePixel = 0
Win.ClipsDescendants = true
Win.Active = true
Win.Parent = GUI
corner(Win, 12)
stroke(Win, C.stroke, 1, 0.1)
gradient(Win, Color3.fromRGB(13, 17, 26), Color3.fromRGB(8, 10, 15), 90)

local function saveAll()
    if not writefile then return end
    local data = {
        SavedCMDS = SavedCMDS, SemiCMDS = SemiCMDS, SpamDelay = SpamDelay, SemiDelay = SemiDelay,
        ProximityEnabled = ProximityEnabled, ProximityRange = ProximityRange,
        AutoSemiBtnVisible = AutoSemiBtnVisible, BaseProtectorEnabled = BaseProtectorEnabled,
        ProtectorCooldown = ProtectorCooldown, ProtectorNearestFallback = ProtectorNearestFallback,
        ProtectorScanRange = ProtectorScanRange, ProtectorPromptDetection = ProtectorPromptDetection,
        ProtectorRemoteDetection = ProtectorRemoteDetection,
        StealerConfigs = StealerConfigs,
        FilterFmly = FilterFmly, FilterDark = FilterDark, FilterCustomEnabled = FilterCustomEnabled, CustomFilteredUsers = CustomFilteredUsers,
        WinPos = { X = Win.Position.X.Scale, XOff = Win.Position.X.Offset, Y = Win.Position.Y.Scale, YOff = Win.Position.Y.Offset },
        Lang = LANG, DiscordId = DiscordId,
    }
    pcall(function() writefile(CONFIG_FILE, HttpService:JSONEncode(data)) end)
end

-- HEADER
local Header = Instance.new("Frame", Win)
Header.Size = UDim2.new(1, 0, 0, 44); Header.BackgroundColor3 = C.panel; Header.BorderSizePixel = 0
gradient(Header, Color3.fromRGB(18, 23, 35), Color3.fromRGB(13, 16, 25), 90)
local HeaderLine = Instance.new("Frame", Header)
HeaderLine.Size = UDim2.new(1, 0, 0, 1); HeaderLine.Position = UDim2.new(0, 0, 1, -1)
HeaderLine.BackgroundColor3 = C.stroke; HeaderLine.BackgroundTransparency = 0.25; HeaderLine.BorderSizePixel = 0

local HeaderAv = Instance.new("ImageLabel", Header)
HeaderAv.Size = UDim2.fromOffset(28, 28); HeaderAv.Position = UDim2.fromOffset(10, 8)
HeaderAv.BackgroundColor3 = C.bg; HeaderAv.BorderSizePixel = 0
Instance.new("UICorner", HeaderAv).CornerRadius = UDim.new(0, 6)
local avStroke = Instance.new("UIStroke", HeaderAv)
avStroke.Color = C.accent; avStroke.Thickness = 1; avStroke.Transparency = 0.3
task.spawn(function()
    pcall(function()
        HeaderAv.Image = Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
    end)
end)

local Title = Instance.new("TextLabel", Header)
Title.Size = UDim2.new(0, 100, 0, 18); Title.Position = UDim2.fromOffset(46, 6)
Title.BackgroundTransparency = 1; Title.Text = "DARK AP"; Title.TextColor3 = C.text
Title.Font = Enum.Font.GothamBold; Title.TextSize = 14; Title.TextXAlignment = Enum.TextXAlignment.Left
local SubTitle = Instance.new("TextLabel", Header)
SubTitle.Size = UDim2.new(0, 120, 0, 14); SubTitle.Position = UDim2.fromOffset(46, 24)
SubTitle.BackgroundTransparency = 1; SubTitle.Text = tr("adminPanel"); SubTitle.TextColor3 = C.mute
SubTitle.Font = Enum.Font.Gotham; SubTitle.TextSize = 9; SubTitle.TextXAlignment = Enum.TextXAlignment.Left

local ClickAPBtn = Instance.new("TextButton", Header)
ClickAPBtn.Size = UDim2.fromOffset(75, 24); ClickAPBtn.Position = UDim2.fromOffset(150, 10)
ClickAPBtn.BackgroundColor3 = C.card; ClickAPBtn.Text = "Click To AP"; ClickAPBtn.TextColor3 = C.mute
ClickAPBtn.Font = Enum.Font.GothamBold; ClickAPBtn.TextSize = 10; ClickAPBtn.BorderSizePixel = 0
Instance.new("UICorner", ClickAPBtn).CornerRadius = UDim.new(0, 4)

local ProxBtn = Instance.new("TextButton", Header)
ProxBtn.Size = UDim2.fromOffset(75, 24); ProxBtn.Position = UDim2.fromOffset(231, 10)
ProxBtn.BackgroundColor3 = C.card; ProxBtn.Text = "Proximity"; ProxBtn.TextColor3 = C.mute
ProxBtn.Font = Enum.Font.GothamBold; ProxBtn.TextSize = 10; ProxBtn.BorderSizePixel = 0
Instance.new("UICorner", ProxBtn).CornerRadius = UDim.new(0, 4)
if ProximityEnabled then ProxBtn.TextColor3 = C.purple end

local MsLbl = Instance.new("TextLabel", Header)
MsLbl.Size = UDim2.fromOffset(50, 16); MsLbl.Position = UDim2.new(0, 312, 0.5, -8)
MsLbl.BackgroundTransparency = 1; MsLbl.Text = "-- MS"; MsLbl.TextColor3 = C.mute
MsLbl.Font = Enum.Font.GothamBold; MsLbl.TextSize = 10; MsLbl.TextXAlignment = Enum.TextXAlignment.Left

local FpsLbl = Instance.new("TextLabel", Header)
FpsLbl.Size = UDim2.fromOffset(50, 16); FpsLbl.Position = UDim2.new(0, 360, 0.5, -8)
FpsLbl.BackgroundTransparency = 1; FpsLbl.Text = "-- FPS"; FpsLbl.TextColor3 = C.mute
FpsLbl.Font = Enum.Font.GothamBold; FpsLbl.TextSize = 10; FpsLbl.TextXAlignment = Enum.TextXAlignment.Left

do
    local frameCount, fpsLast = 0, os.clock()
    RunService.RenderStepped:Connect(function()
        frameCount += 1
        local now = os.clock()
        if now - fpsLast >= 0.5 then
            FpsLbl.Text = tostring(math.floor(frameCount / (now - fpsLast) + 0.5)) .. " FPS"
            frameCount = 0
            fpsLast = now
        end
        local okPing, ping = pcall(function() return LocalPlayer:GetNetworkPing() end)
        if okPing then MsLbl.Text = tostring(math.floor(ping * 1000 + 0.5)) .. " MS" end
    end)
end

local SetBtn = Instance.new("TextButton", Header)
SetBtn.Size = UDim2.fromOffset(32, 24); SetBtn.Position = UDim2.new(1, -94, 0.5, -12)
SetBtn.BackgroundColor3 = C.card; SetBtn.Text = "⚙"; SetBtn.TextColor3 = C.mute
SetBtn.Font = Enum.Font.GothamBold; SetBtn.TextSize = 16; SetBtn.BorderSizePixel = 0
Instance.new("UICorner", SetBtn).CornerRadius = UDim.new(0, 4)

local MinBtn = Instance.new("TextButton", Header)
MinBtn.Size = UDim2.fromOffset(24, 24); MinBtn.Position = UDim2.new(1, -59, 0.5, -12)
MinBtn.BackgroundColor3 = C.card; MinBtn.Text = "-"; MinBtn.TextColor3 = C.mute
MinBtn.Font = Enum.Font.GothamBold; MinBtn.TextSize = 14; MinBtn.BorderSizePixel = 0
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 4)

local CloseBtn = Instance.new("TextButton", Header)
CloseBtn.Size = UDim2.fromOffset(24, 24); CloseBtn.Position = UDim2.new(1, -32, 0.5, -12)
CloseBtn.BackgroundColor3 = C.card; CloseBtn.Text = "X"; CloseBtn.TextColor3 = C.mute
CloseBtn.Font = Enum.Font.GothamBold; CloseBtn.TextSize = 12; CloseBtn.BorderSizePixel = 0
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 4)

-- PROXIMITY
local ProxFrame = Instance.new("Frame", Win)
ProxFrame.Size = UDim2.new(1, -16, 0, 30); ProxFrame.Position = UDim2.fromOffset(8, 48)
ProxFrame.BackgroundColor3 = C.card; ProxFrame.BorderSizePixel = 0; ProxFrame.Visible = false
Instance.new("UICorner", ProxFrame).CornerRadius = UDim.new(0, 4)

local SliderBg = Instance.new("Frame", ProxFrame)
SliderBg.Size = UDim2.new(1, -60, 0, 6); SliderBg.Position = UDim2.new(0, 10, 0.5, -3)
SliderBg.BackgroundColor3 = C.bg; SliderBg.BorderSizePixel = 0
Instance.new("UICorner", SliderBg).CornerRadius = UDim.new(1, 0)

local SliderFill = Instance.new("Frame", SliderBg)
SliderFill.Size = UDim2.new(math.clamp((ProximityRange - 5) / 95, 0, 1), 0, 1, 0)
SliderFill.BackgroundColor3 = C.purple; SliderFill.BorderSizePixel = 0
Instance.new("UICorner", SliderFill).CornerRadius = UDim.new(1, 0)

local SliderKnob = Instance.new("Frame", SliderBg)
SliderKnob.Size = UDim2.fromOffset(12, 12); SliderKnob.Position = UDim2.new(math.clamp((ProximityRange - 5) / 95, 0, 1), -6, 0.5, -6)
SliderKnob.BackgroundColor3 = C.text; SliderKnob.BorderSizePixel = 0
Instance.new("UICorner", SliderKnob).CornerRadius = UDim.new(1, 0)

local ProxLabel = Instance.new("TextLabel", ProxFrame)
ProxLabel.Size = UDim2.fromOffset(40, 30); ProxLabel.Position = UDim2.new(1, -50, 0, 0)
ProxLabel.BackgroundTransparency = 1; ProxLabel.Text = tostring(ProximityRange); ProxLabel.TextColor3 = C.text
ProxLabel.Font = Enum.Font.GothamBold; ProxLabel.TextSize = 12; ProxLabel.TextXAlignment = Enum.TextXAlignment.Center

-- LIST
local List = Instance.new("ScrollingFrame", Win)
List.Size = UDim2.new(1, -16, 1, -56); List.Position = UDim2.fromOffset(8, 48)
List.BackgroundTransparency = 1; List.BorderSizePixel = 0; List.ScrollBarThickness = 2
List.ScrollBarImageColor3 = C.stroke; List.CanvasSize = UDim2.new(0, 0, 0, 0)
List.AutomaticCanvasSize = Enum.AutomaticSize.Y; List.ScrollingDirection = Enum.ScrollingDirection.Y
local LL = Instance.new("UIListLayout", List)
LL.Padding = UDim.new(0, 4); LL.SortOrder = Enum.SortOrder.LayoutOrder

-- SETTINGS PANEL
local SetPanel = Instance.new("ScrollingFrame", Win)
SetPanel.Size = UDim2.new(1, -16, 1, -56); SetPanel.Position = UDim2.fromOffset(8, 48)
SetPanel.BackgroundTransparency = 1; SetPanel.BorderSizePixel = 0; SetPanel.ScrollBarThickness = 3
SetPanel.ScrollBarImageColor3 = C.stroke; SetPanel.CanvasSize = UDim2.new(0, 0, 0, 0)
SetPanel.AutomaticCanvasSize = Enum.AutomaticSize.Y; SetPanel.ScrollingDirection = Enum.ScrollingDirection.Y
SetPanel.Visible = false

local SetLayout = Instance.new("UIListLayout", SetPanel)
SetLayout.Padding = UDim.new(0, 5); SetLayout.SortOrder = Enum.SortOrder.LayoutOrder

local CardCollapseAppliers = {}

local function createCard(title, order)
    local f = Instance.new("Frame", SetPanel)
    f.Size = UDim2.new(1, -6, 0, 0)
    f.AutomaticSize = Enum.AutomaticSize.Y
    f.BackgroundColor3 = C.card
    f.BorderSizePixel = 0
    f.LayoutOrder = order
    corner(f, 10)
    stroke(f, C.stroke, 1, 0.18)
    gradient(f, Color3.fromRGB(25, 31, 46), Color3.fromRGB(17, 21, 32), 90)

    local padding = Instance.new("UIPadding", f)
    padding.PaddingTop = UDim.new(0, 8); padding.PaddingBottom = UDim.new(0, 8)
    padding.PaddingLeft = UDim.new(0, 10); padding.PaddingRight = UDim.new(0, 10)

    local layout = Instance.new("UIListLayout", f)
    layout.Padding = UDim.new(0, 6); layout.SortOrder = Enum.SortOrder.LayoutOrder

    local head = Instance.new("Frame", f)
    head.Size = UDim2.new(1, 0, 0, 22)
    head.BackgroundTransparency = 1
    head.LayoutOrder = 1
    head.Active = true

    local bar = Instance.new("Frame", head)
    bar.Size = UDim2.fromOffset(4, 16); bar.Position = UDim2.fromOffset(0, 3)
    bar.BackgroundColor3 = C.accent; bar.BorderSizePixel = 0
    corner(bar, 99)

    local lbl = Instance.new("TextLabel", head)
    lbl.Size = UDim2.new(1, -40, 1, 0); lbl.Position = UDim2.fromOffset(12, 0)
    lbl.BackgroundTransparency = 1; lbl.Text = string.upper(title)
    lbl.TextColor3 = C.text; lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 12; lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Active = true

    local toggleBtn = Instance.new("TextButton", head)
    toggleBtn.Size = UDim2.fromOffset(22, 22); toggleBtn.Position = UDim2.new(1, -22, 0, 0)
    toggleBtn.BackgroundColor3 = C.input; toggleBtn.Text = "+"; toggleBtn.TextColor3 = C.mute
    toggleBtn.Font = Enum.Font.GothamBold; toggleBtn.TextSize = 14; toggleBtn.BorderSizePixel = 0
    corner(toggleBtn, 6)
    stroke(toggleBtn, C.stroke, 1, 0.35)

    local collapsed = true
    local function applyCollapse()
        for _, child in ipairs(f:GetChildren()) do
            if child:IsA("GuiObject") and child ~= head then
                child.Visible = not collapsed
            end
        end
        toggleBtn.Text = collapsed and "+" or "–"
        toggleBtn.TextColor3 = collapsed and C.mute or C.accent
    end
    local function toggleCollapse()
        collapsed = not collapsed
        applyCollapse()
    end
    toggleBtn.MouseButton1Click:Connect(toggleCollapse)
    lbl.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            toggleCollapse()
        end
    end)

    table.insert(CardCollapseAppliers, applyCollapse)
    return f
end

local function applyAllCardCollapses()
    for _, fn in ipairs(CardCollapseAppliers) do pcall(fn) end
end

local function createCmdGrid(parent, togglesTable, btnRefTable, columns, rowH, initialTable)
    columns = columns or 5; rowH = rowH or 26
    local grid = Instance.new("Frame", parent)
    local rows = math.ceil(#ALL_POSSIBLE_CMDS / columns)
    grid.Size = UDim2.new(1, 0, 0, rows * (rowH + 6) - 6)
    grid.BackgroundTransparency = 1

    local layout = Instance.new("UIGridLayout", grid)
    layout.CellSize = UDim2.new(1 / columns - 0.012, 0, 0, rowH)
    layout.CellPadding = UDim2.new(0.012, 0, 0, 6)
    layout.SortOrder = Enum.SortOrder.LayoutOrder

    local function initialSelected(cmd)
        if type(initialTable) ~= "table" then return true end
        if initialTable[cmd] ~= nil then return initialTable[cmd] and true or false end
        for _, v in ipairs(initialTable) do
            if v == cmd then return true end
        end
        return false
    end

    for i, cmd in ipairs(ALL_POSSIBLE_CMDS) do
        local btn = Instance.new("TextButton", grid)
        local state = { isSelected = initialSelected(cmd) }
        btn.Text = cmd
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 10
        btn.BorderSizePixel = 0
        btn.LayoutOrder = i
        btn.AutoButtonColor = false
        corner(btn, 6)
        local st = stroke(btn, C.stroke, 1, 0.35)

        local function apply()
            btn.BackgroundColor3 = state.isSelected and C.accent or C.input
            btn.TextColor3 = state.isSelected and C.text or C.mute
            st.Color = state.isSelected and C.accent or C.stroke
            st.Transparency = state.isSelected and 0 or 0.35
        end
        apply()

        btn.MouseButton1Click:Connect(function()
            state.isSelected = not state.isSelected
            apply()
        end)
        btn.MouseEnter:Connect(function()
            if not state.isSelected then btn.BackgroundColor3 = C.darkBtn end
        end)
        btn.MouseLeave:Connect(apply)

        togglesTable[cmd] = function() return state.isSelected end
        if btnRefTable then
            btnRefTable[cmd] = {
                Button = btn,
                SetState = function(val)
                    state.isSelected = val and true or false
                    apply()
                end
            }
        end
    end
    return grid
end

local function onOff(v) return v and tr("on") or tr("off") end

-- TARJETA 1: SPAM ALL
local CardAll = createCard(tr("cardSpam"), 1)
local allToggles = {}
local allGrid = createCmdGrid(CardAll, allToggles, nil, 5, 26, SavedCMDS)
allGrid.LayoutOrder = 2

local lblDelayAll = Instance.new("TextLabel", CardAll)
lblDelayAll.Size = UDim2.new(1, 0, 0, 16); lblDelayAll.BackgroundTransparency = 1
lblDelayAll.Text = tr("delayAll"); lblDelayAll.TextColor3 = C.text
lblDelayAll.Font = Enum.Font.GothamMedium; lblDelayAll.TextSize = 11; lblDelayAll.TextXAlignment = Enum.TextXAlignment.Left
lblDelayAll.LayoutOrder = 3

local txtDelayAll = Instance.new("TextBox", CardAll)
txtDelayAll.Size = UDim2.new(1, 0, 0, 30); txtDelayAll.BackgroundColor3 = C.bg
txtDelayAll.Text = tostring(SpamDelay); txtDelayAll.TextColor3 = C.text
txtDelayAll.Font = Enum.Font.Gotham; txtDelayAll.TextSize = 14; txtDelayAll.PlaceholderText = tr("ph")
txtDelayAll.LayoutOrder = 4
styleTextBox(txtDelayAll)

local btnSaveAll = Instance.new("TextButton", CardAll)
btnSaveAll.Size = UDim2.new(1, 0, 0, 30); btnSaveAll.BackgroundColor3 = C.purple
btnSaveAll.Text = tr("saveSpam"); btnSaveAll.TextColor3 = C.text
btnSaveAll.Font = Enum.Font.GothamBold; btnSaveAll.TextSize = 12; btnSaveAll.LayoutOrder = 5
Instance.new("UICorner", btnSaveAll).CornerRadius = UDim.new(0, 4)

btnSaveAll.MouseButton1Click:Connect(function()
    SavedCMDS = {}
    for _, cmd in ipairs(ALL_POSSIBLE_CMDS) do
        if allToggles[cmd] and allToggles[cmd]() then table.insert(SavedCMDS, cmd) end
    end
    local parsed = tonumber(txtDelayAll.Text)
    SpamDelay = (parsed and parsed >= 0) and parsed or 0
    if not parsed then txtDelayAll.Text = "0" end
    saveAll()
    btnSaveAll.Text = tr("saved")
    task.delay(1.2, function()
        if btnSaveAll and btnSaveAll.Parent then
            btnSaveAll.Text = tr("saveSpam")
        end
    end)
end)

-- TARJETA 2: SEMI
local CardSemi = createCard(tr("cardSemi"), 2)
local semiToggles = {}
local semiBtnRefs = {}
local semiGrid = createCmdGrid(CardSemi, semiToggles, semiBtnRefs, 5, 26, SemiCMDS)
semiGrid.LayoutOrder = 2

local btnAutoSemiToggle = Instance.new("TextButton", CardSemi)
btnAutoSemiToggle.Size = UDim2.new(1, 0, 0, 24)
btnAutoSemiToggle.BackgroundColor3 = AutoSemiBtnVisible and C.green or C.darkBtn
btnAutoSemiToggle.Text = tr("showSemi") .. ": " .. onOff(AutoSemiBtnVisible)
btnAutoSemiToggle.TextColor3 = C.text; btnAutoSemiToggle.Font = Enum.Font.GothamBold
btnAutoSemiToggle.TextSize = 11; btnAutoSemiToggle.BorderSizePixel = 0
btnAutoSemiToggle.LayoutOrder = 3
Instance.new("UICorner", btnAutoSemiToggle).CornerRadius = UDim.new(0, 4)

btnAutoSemiToggle.MouseButton1Click:Connect(function()
    AutoSemiBtnVisible = not AutoSemiBtnVisible
    btnAutoSemiToggle.BackgroundColor3 = AutoSemiBtnVisible and C.green or C.darkBtn
    btnAutoSemiToggle.Text = tr("showSemi") .. ": " .. onOff(AutoSemiBtnVisible)
    for _, b in pairs(SemiButtons) do
        if b and b.Parent then b.Visible = AutoSemiBtnVisible end
    end
    saveAll()
end)

local lblDelaySemi = Instance.new("TextLabel", CardSemi)
lblDelaySemi.Size = UDim2.new(1, 0, 0, 16); lblDelaySemi.BackgroundTransparency = 1
lblDelaySemi.Text = tr("delaySemi"); lblDelaySemi.TextColor3 = C.text
lblDelaySemi.Font = Enum.Font.GothamMedium; lblDelaySemi.TextSize = 11; lblDelaySemi.TextXAlignment = Enum.TextXAlignment.Left
lblDelaySemi.LayoutOrder = 4

local txtDelaySemi = Instance.new("TextBox", CardSemi)
txtDelaySemi.Size = UDim2.new(1, 0, 0, 30); txtDelaySemi.BackgroundColor3 = C.bg
txtDelaySemi.Text = tostring(SemiDelay); txtDelaySemi.TextColor3 = C.text
txtDelaySemi.Font = Enum.Font.Gotham; txtDelaySemi.TextSize = 14; txtDelaySemi.PlaceholderText = tr("ph")
txtDelaySemi.LayoutOrder = 5
styleTextBox(txtDelaySemi)

local btnSaveSemi = Instance.new("TextButton", CardSemi)
btnSaveSemi.Size = UDim2.new(1, 0, 0, 30); btnSaveSemi.BackgroundColor3 = C.purple
btnSaveSemi.Text = tr("saveSemi"); btnSaveSemi.TextColor3 = C.text
btnSaveSemi.Font = Enum.Font.GothamBold; btnSaveSemi.TextSize = 12; btnSaveSemi.LayoutOrder = 6
Instance.new("UICorner", btnSaveSemi).CornerRadius = UDim.new(0, 4)

btnSaveSemi.MouseButton1Click:Connect(function()
    SemiCMDS = {}
    for _, cmd in ipairs(ALL_POSSIBLE_CMDS) do
        if semiToggles[cmd] and semiToggles[cmd]() then table.insert(SemiCMDS, cmd) end
    end
    local parsed = tonumber(txtDelaySemi.Text)
    SemiDelay = (parsed and parsed >= 0) and parsed or 0.5
    if not parsed then txtDelaySemi.Text = "0.5" end
    SemiQueue = {}
    saveAll()
    btnSaveSemi.Text = tr("saved")
    task.delay(1.2, function()
        if btnSaveSemi and btnSaveSemi.Parent then
            btnSaveSemi.Text = tr("saveSemi")
        end
    end)
end)

-- TARJETA 3: BASE PROTECTOR
local CardBase = createCard(tr("cardBase"), 3)
local baseTopFrame = Instance.new("Frame", CardBase)
baseTopFrame.Size = UDim2.new(1, 0, 0, 26)
baseTopFrame.BackgroundTransparency = 1
baseTopFrame.LayoutOrder = 2

local btnBaseToggle = Instance.new("TextButton", baseTopFrame)
btnBaseToggle.Size = UDim2.new(0.6, -4, 1, 0)
btnBaseToggle.BackgroundColor3 = BaseProtectorEnabled and C.accent or C.input
btnBaseToggle.Text = tr("baseProt") .. ": " .. onOff(BaseProtectorEnabled)
btnBaseToggle.TextColor3 = C.text; btnBaseToggle.Font = Enum.Font.GothamBold
btnBaseToggle.TextSize = 12; btnBaseToggle.BorderSizePixel = 0
Instance.new("UICorner", btnBaseToggle).CornerRadius = UDim.new(0, 6)
local baseToggleStroke = Instance.new("UIStroke", btnBaseToggle)
baseToggleStroke.Color = BaseProtectorEnabled and C.accent or C.stroke
baseToggleStroke.Transparency = BaseProtectorEnabled and 0.35 or 0.3
baseToggleStroke.Thickness = 1
if BaseProtectorEnabled then gradient(btnBaseToggle, C.accent, C.accentHover, 90) end

local btnBaseMinimize = Instance.new("TextButton", baseTopFrame)
btnBaseMinimize.Size = UDim2.new(0.4, -4, 1, 0); btnBaseMinimize.Position = UDim2.new(0.6, 4, 0, 0)
btnBaseMinimize.BackgroundColor3 = C.card; btnBaseMinimize.Text = tr("hide")
btnBaseMinimize.TextColor3 = C.mute; btnBaseMinimize.Font = Enum.Font.GothamBold
btnBaseMinimize.TextSize = 11; btnBaseMinimize.BorderSizePixel = 0
Instance.new("UICorner", btnBaseMinimize).CornerRadius = UDim.new(0, 6)
stroke(btnBaseMinimize, C.stroke, 1, 0.35)

local baseContent = Instance.new("Frame", CardBase)
baseContent.Size = UDim2.new(1, 0, 0, 0)
baseContent.AutomaticSize = Enum.AutomaticSize.Y
baseContent.BackgroundTransparency = 1
baseContent.Visible = BaseProtectorEnabled
baseContent.LayoutOrder = 3

local baseContentLayout = Instance.new("UIListLayout", baseContent)
baseContentLayout.Padding = UDim.new(0, 8); baseContentLayout.SortOrder = Enum.SortOrder.LayoutOrder

local btnTestBase = Instance.new("TextButton", baseContent)
btnTestBase.Size = UDim2.new(1, 0, 0, 28)
btnTestBase.BackgroundColor3 = C.card
btnTestBase.Text = tr("testBase")
btnTestBase.TextColor3 = C.blue; btnTestBase.Font = Enum.Font.GothamBold
btnTestBase.TextSize = 11; btnTestBase.BorderSizePixel = 0
btnTestBase.LayoutOrder = 1
btnTestBase.AutoButtonColor = false
corner(btnTestBase, 6)
stroke(btnTestBase, C.blue, 1, 0.4)
addHover(btnTestBase, C.card, C.darkBtn)

local btnAddStealer = Instance.new("TextButton", baseContent)
btnAddStealer.Size = UDim2.new(1, 0, 0, 28)
btnAddStealer.BackgroundColor3 = C.card
btnAddStealer.Text = tr("addCombo")
btnAddStealer.TextColor3 = C.text; btnAddStealer.Font = Enum.Font.GothamBold
btnAddStealer.TextSize = 11; btnAddStealer.BorderSizePixel = 0
btnAddStealer.LayoutOrder = 999
btnAddStealer.AutoButtonColor = false
corner(btnAddStealer, 6)
stroke(btnAddStealer, C.accent, 1, 0.4)
addHover(btnAddStealer, C.card, C.darkBtn)

local function makeProtectorToggle(label, get, set, order)
    local b = Instance.new("TextButton", baseContent)
    b.Size = UDim2.new(1, 0, 0, 24)
    b.BackgroundColor3 = C.input
    b.TextColor3 = C.mute
    b.Font = Enum.Font.GothamBold
    b.TextSize = 11
    b.BorderSizePixel = 0
    b.LayoutOrder = order
    b.AutoButtonColor = false
    corner(b, 6)
    local st = stroke(b, C.stroke, 1, 0.35)

    local function apply()
        local on = get() and true or false
        b.BackgroundColor3 = on and C.accent or C.input
        b.Text = label .. ": " .. onOff(on)
        b.TextColor3 = on and C.text or C.mute
        st.Color = on and C.accent or C.stroke
        st.Transparency = 0.35
    end

    b.MouseButton1Click:Connect(function()
        set(not get())
        apply()
        saveAll()
    end)
    apply()
    return b
end

makeProtectorToggle(tr("detPrompts"), function() return ProtectorPromptDetection end, function(v) ProtectorPromptDetection = v end, 2)
makeProtectorToggle(tr("detRemotes"), function() return ProtectorRemoteDetection end, function(v) ProtectorRemoteDetection = v end, 3)
makeProtectorToggle(tr("fallback"), function() return ProtectorNearestFallback end, function(v) ProtectorNearestFallback = v end, 4)

local function refreshStealersUI()
    for _, child in ipairs(baseContent:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end

    for s, config in ipairs(StealerConfigs) do
        local sFrame = Instance.new("Frame", baseContent)
        sFrame.Size = UDim2.new(1, 0, 0, 68)
        sFrame.BackgroundColor3 = C.bg; sFrame.BorderSizePixel = 0
        sFrame.LayoutOrder = 10 + s
        Instance.new("UICorner", sFrame).CornerRadius = UDim.new(0, 4)

        local sLbl = Instance.new("TextLabel", sFrame)
        sLbl.Size = UDim2.new(1, -30, 0, 16); sLbl.Position = UDim2.fromOffset(8, 4)
        sLbl.BackgroundTransparency = 1; sLbl.Text = "STEALER " .. s .. " (combo)"
        sLbl.TextColor3 = C.accent; sLbl.Font = Enum.Font.GothamBold
        sLbl.TextSize = 10; sLbl.TextXAlignment = Enum.TextXAlignment.Left

        if #StealerConfigs > 1 then
            local delBtn = Instance.new("TextButton", sFrame)
            delBtn.Size = UDim2.fromOffset(20, 16); delBtn.Position = UDim2.new(1, -24, 0, 4)
            delBtn.BackgroundColor3 = C.red; delBtn.Text = "x"; delBtn.TextColor3 = C.text
            delBtn.Font = Enum.Font.GothamBold; delBtn.TextSize = 9; delBtn.BorderSizePixel = 0
            Instance.new("UICorner", delBtn).CornerRadius = UDim.new(0, 3)
            delBtn.MouseButton1Click:Connect(function()
                table.remove(StealerConfigs, s)
                saveAll()
                refreshStealersUI()
                if rebuild then rebuild() end
            end)
        end

        local sGrid = Instance.new("Frame", sFrame)
        sGrid.Size = UDim2.new(1, -10, 0, 44); sGrid.Position = UDim2.fromOffset(5, 22)
        sGrid.BackgroundTransparency = 1
        local sLayout = Instance.new("UIGridLayout", sGrid)
        sLayout.CellSize = UDim2.new(0.19, 0, 0, 20)
        sLayout.CellPadding = UDim2.new(0.01, 0, 0, 2)

        for i, cmd in ipairs(ALL_POSSIBLE_CMDS) do
            local inS = false
            for _, c in ipairs(StealerConfigs[s]) do if c == cmd then inS = true; break end end
            local btn = Instance.new("TextButton", sGrid)
            btn.BackgroundColor3 = inS and C.accent or C.card
            btn.Text = cmd; btn.TextColor3 = inS and C.text or C.mute
            btn.Font = Enum.Font.GothamMedium; btn.TextSize = 9; btn.BorderSizePixel = 0
            btn.LayoutOrder = i; btn.AutoButtonColor = false
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
            btn.MouseButton1Click:Connect(function()
                local found = false
                for i2, c in ipairs(StealerConfigs[s]) do
                    if c == cmd then table.remove(StealerConfigs[s], i2); found = true; break end
                end
                if not found then table.insert(StealerConfigs[s], cmd) end
                btn.BackgroundColor3 = (not found) and C.accent or C.card
                btn.TextColor3 = (not found) and C.text or C.mute
                saveAll()
            end)
        end
    end
end

btnAddStealer.MouseButton1Click:Connect(function()
    table.insert(StealerConfigs, {})
    saveAll()
    refreshStealersUI()
    if rebuild then rebuild() end
end)

btnBaseToggle.MouseButton1Click:Connect(function()
    BaseProtectorEnabled = not BaseProtectorEnabled
    btnBaseToggle.BackgroundColor3 = BaseProtectorEnabled and C.accent or C.input
    btnBaseToggle.Text = tr("baseProt") .. ": " .. onOff(BaseProtectorEnabled)
    baseToggleStroke.Color = BaseProtectorEnabled and C.accent or C.stroke
    baseToggleStroke.Transparency = BaseProtectorEnabled and 0.35 or 0.3
    local g = btnBaseToggle:FindFirstChildOfClass("UIGradient")
    if BaseProtectorEnabled and not g then
        gradient(btnBaseToggle, C.accent, C.accentHover, 90)
    elseif not BaseProtectorEnabled and g then
        g:Destroy()
    end
    baseContent.Visible = BaseProtectorEnabled
    saveAll()
end)

local baseMinimized = false
btnBaseMinimize.MouseButton1Click:Connect(function()
    baseMinimized = not baseMinimized
    baseContent.Visible = not baseMinimized and BaseProtectorEnabled
    btnBaseMinimize.Text = baseMinimized and tr("show") or tr("hide")
end)

refreshStealersUI()

-- TARJETA 4: FILTROS
local CardFilter = createCard(tr("cardFilter"), 4)

local btnFilterFmly = Instance.new("TextButton", CardFilter)
btnFilterFmly.Size = UDim2.new(1, 0, 0, 24)
btnFilterFmly.BackgroundColor3 = FilterFmly and C.red or C.darkBtn
btnFilterFmly.Text = tr("hideFmly") .. ": " .. onOff(FilterFmly)
btnFilterFmly.TextColor3 = C.text; btnFilterFmly.Font = Enum.Font.GothamBold
btnFilterFmly.TextSize = 11; btnFilterFmly.BorderSizePixel = 0
btnFilterFmly.LayoutOrder = 2
Instance.new("UICorner", btnFilterFmly).CornerRadius = UDim.new(0, 4)

local btnFilterDark = Instance.new("TextButton", CardFilter)
btnFilterDark.Size = UDim2.new(1, 0, 0, 24)
btnFilterDark.BackgroundColor3 = FilterDark and C.red or C.darkBtn
btnFilterDark.Text = tr("hideDark") .. ": " .. onOff(FilterDark)
btnFilterDark.TextColor3 = C.text; btnFilterDark.Font = Enum.Font.GothamBold
btnFilterDark.TextSize = 11; btnFilterDark.BorderSizePixel = 0
btnFilterDark.LayoutOrder = 3
Instance.new("UICorner", btnFilterDark).CornerRadius = UDim.new(0, 4)

local btnFilterCustom = Instance.new("TextButton", CardFilter)
btnFilterCustom.Size = UDim2.new(1, 0, 0, 24)
btnFilterCustom.BackgroundColor3 = FilterCustomEnabled and C.green or C.darkBtn
btnFilterCustom.Text = tr("useCustom") .. ": " .. onOff(FilterCustomEnabled)
btnFilterCustom.TextColor3 = C.text; btnFilterCustom.Font = Enum.Font.GothamBold
btnFilterCustom.TextSize = 11; btnFilterCustom.BorderSizePixel = 0
btnFilterCustom.LayoutOrder = 4
Instance.new("UICorner", btnFilterCustom).CornerRadius = UDim.new(0, 4)

local txtCustomUsers = Instance.new("TextBox", CardFilter)
txtCustomUsers.Size = UDim2.new(1, 0, 0, 30); txtCustomUsers.BackgroundColor3 = C.bg
txtCustomUsers.Text = table.concat(CustomFilteredUsers, ", "); txtCustomUsers.TextColor3 = C.text
txtCustomUsers.Font = Enum.Font.Gotham; txtCustomUsers.TextSize = 12; txtCustomUsers.PlaceholderText = tr("phUsers")
txtCustomUsers.LayoutOrder = 5
styleTextBox(txtCustomUsers)

local btnSaveFilters = Instance.new("TextButton", CardFilter)
btnSaveFilters.Size = UDim2.new(1, 0, 0, 30); btnSaveFilters.BackgroundColor3 = C.purple
btnSaveFilters.Text = tr("saveFilters"); btnSaveFilters.TextColor3 = C.text
btnSaveFilters.Font = Enum.Font.GothamBold; btnSaveFilters.TextSize = 12; btnSaveFilters.LayoutOrder = 6
Instance.new("UICorner", btnSaveFilters).CornerRadius = UDim.new(0, 4)

btnFilterFmly.MouseButton1Click:Connect(function()
    FilterFmly = not FilterFmly
    btnFilterFmly.BackgroundColor3 = FilterFmly and C.red or C.darkBtn
    btnFilterFmly.Text = tr("hideFmly") .. ": " .. onOff(FilterFmly)
    saveAll()
    rebuild()
end)

btnFilterDark.MouseButton1Click:Connect(function()
    FilterDark = not FilterDark
    btnFilterDark.BackgroundColor3 = FilterDark and C.red or C.darkBtn
    btnFilterDark.Text = tr("hideDark") .. ": " .. onOff(FilterDark)
    saveAll()
    rebuild()
end)

btnFilterCustom.MouseButton1Click:Connect(function()
    FilterCustomEnabled = not FilterCustomEnabled
    btnFilterCustom.BackgroundColor3 = FilterCustomEnabled and C.green or C.darkBtn
    btnFilterCustom.Text = tr("useCustom") .. ": " .. onOff(FilterCustomEnabled)
    saveAll()
    rebuild()
end)

btnSaveFilters.MouseButton1Click:Connect(function()
    CustomFilteredUsers = {}
    for name in string.gmatch(txtCustomUsers.Text, "([^,]+)") do
        local trimmed = string.match(name, "^%s*(.-)%s*$")
        if trimmed and trimmed ~= "" then
            table.insert(CustomFilteredUsers, trimmed)
        end
    end
    saveAll()
    rebuild()
    btnSaveFilters.Text = tr("saved")
    task.delay(1.2, function()
        if btnSaveFilters and btnSaveFilters.Parent then
            btnSaveFilters.Text = tr("saveFilters")
        end
    end)
end)

-- BOTÓN VOLVER
local btnBack = Instance.new("TextButton", SetPanel)
btnBack.Size = UDim2.new(1, -6, 0, 30); btnBack.BackgroundColor3 = C.darkBtn
btnBack.Text = tr("back"); btnBack.TextColor3 = C.text
btnBack.Font = Enum.Font.GothamBold; btnBack.TextSize = 12; btnBack.LayoutOrder = 5
local backStroke = Instance.new("UIStroke", btnBack); backStroke.Color = C.stroke
Instance.new("UICorner", btnBack).CornerRadius = UDim.new(0, 4)

btnTestBase.MouseButton1Click:Connect(function()
    local closestPlr = getClosestPlayer()
    if closestPlr then
        triggerBaseProtector(closestPlr)
        btnTestBase.Text = tr("testSent") .. closestPlr.Name .. "!"
    else
        btnTestBase.Text = tr("noNear")
    end
    task.delay(2, function()
        if btnTestBase.Parent then
            btnTestBase.Text = tr("testBase")
        end
    end)
end)

applyAllCardCollapses()

-- ========================= CLICK TO AP & PROXIMITY =========================
local ClickToAP = false
local hoveredPlayer = nil
local clickHighlight = nil
local commandIndex = 1

ClickAPBtn.MouseButton1Click:Connect(function()
    ClickToAP = not ClickToAP
    ClickAPBtn.TextColor3 = ClickToAP and C.purple or C.mute
    if not ClickToAP and clickHighlight then
        clickHighlight:Destroy()
        clickHighlight = nil
        hoveredPlayer = nil
    end
end)

RunService.RenderStepped:Connect(function()
    if not ClickToAP then return end
    local mousePos = UserInputService:GetMouseLocation()
    local closestPlayer = nil
    local shortestDist = 150
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            if not isPlayerFiltered(plr.Name) then
                local hrp = plr.Character:FindFirstChild("HumanoidRootPart") or plr.Character:FindFirstChild("Head")
                if hrp then
                    local screenPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                    if onScreen then
                        local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                        if dist < shortestDist then
                            shortestDist = dist
                            closestPlayer = plr
                        end
                    end
                end
            end
        end
    end
    if closestPlayer then
        if hoveredPlayer ~= closestPlayer then
            if clickHighlight then clickHighlight:Destroy() end
            hoveredPlayer = closestPlayer
            local char = closestPlayer.Character
            if char then
                clickHighlight = Instance.new("Highlight")
                clickHighlight.FillColor = C.blue
                clickHighlight.OutlineColor = Color3.fromRGB(0, 255, 255)
                clickHighlight.FillTransparency = 0.5
                clickHighlight.Parent = char
            end
        end
    else
        if clickHighlight then
            clickHighlight:Destroy()
            clickHighlight = nil
        end
        hoveredPlayer = nil
    end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 and ClickToAP and hoveredPlayer then
        if #SavedCMDS > 0 then
            sendSpecific(SavedCMDS[commandIndex], hoveredPlayer.Name)
            commandIndex = commandIndex + 1
            if commandIndex > #SavedCMDS then commandIndex = 1 end
        end
    end
end)

local proxCommandIndex = 1
local proxCircle = nil

local function updateProxCircle()
    if not ProximityEnabled then
        if proxCircle then
            proxCircle:Destroy()
            proxCircle = nil
        end
        return
    end
    if not proxCircle then
        proxCircle = Instance.new("Part")
        proxCircle.Name = "LocalProxCircle"
        proxCircle.Shape = Enum.PartType.Cylinder
        proxCircle.CanCollide = false; proxCircle.CanQuery = false
        proxCircle.CanTouch = false; proxCircle.CastShadow = false
        proxCircle.Anchored = true; proxCircle.Color = C.blue
        proxCircle.Material = Enum.Material.Neon; proxCircle.Transparency = 0.5
        proxCircle.Parent = Camera
    end
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        local pos = char.HumanoidRootPart.Position
        proxCircle.CFrame = CFrame.new(pos - Vector3.new(0, 2.5, 0)) * CFrame.Angles(0, 0, math.rad(90))
        proxCircle.Size = Vector3.new(0.2, ProximityRange * 2, ProximityRange * 2)
    else
        proxCircle.CFrame = CFrame.new(0, -100, 0)
    end
end

local draggingSlider = false
SliderBg.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        draggingSlider = true
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        draggingSlider = false
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if draggingSlider and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local mouseX = input.Position.X
        local percent = math.clamp((mouseX - SliderBg.AbsolutePosition.X) / SliderBg.AbsoluteSize.X, 0, 1)
        SliderFill.Size = UDim2.new(percent, 0, 1, 0)
        SliderKnob.Position = UDim2.new(percent, -6, 0.5, -6)
        ProximityRange = math.floor(5 + (percent * 95))
        ProxLabel.Text = tostring(ProximityRange)
    end
end)

ProxBtn.MouseButton1Click:Connect(function()
    ProximityEnabled = not ProximityEnabled
    ProxBtn.TextColor3 = ProximityEnabled and C.purple or C.mute
    ProxFrame.Visible = ProximityEnabled and not SetPanel.Visible
    if not ProximityEnabled then
        if proxCircle then
            proxCircle:Destroy()
            proxCircle = nil
        end
    end
    saveAll()
    if updateWindowSize then updateWindowSize() end
end)

RunService.RenderStepped:Connect(function()
    if ProximityEnabled and PANEL_ACTIVE then updateProxCircle() end
end)

task.spawn(function()
    while true do
        task.wait(math.max(SpamDelay, 0.1))
        if not PANEL_ACTIVE then continue end
        if ProximityEnabled and #SavedCMDS > 0 then
            local char = LocalPlayer.Character
            if not char or not char:FindFirstChild("HumanoidRootPart") then continue end
            local myPos = char.HumanoidRootPart.Position
            local playersInRange = {}
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                    if not isPlayerFiltered(plr.Name) then
                        if (plr.Character.HumanoidRootPart.Position - myPos).Magnitude <= ProximityRange then
                            table.insert(playersInRange, plr)
                        end
                    end
                end
            end
            if #playersInRange > 0 then
                local cmd = SavedCMDS[proxCommandIndex]
                for _, targetPlr in ipairs(playersInRange) do
                    sendSpecific(cmd, targetPlr.Name)
                end
                proxCommandIndex = proxCommandIndex + 1
                if proxCommandIndex > #SavedCMDS then proxCommandIndex = 1 end
            end
        end
    end
end)

-- ========================= LISTA DE JUGADORES =========================
local function doSpamAll(plr)
    if busy then return end
    busy = true
    task.spawn(function() sendAll(plr.Name); busy = false end)
end

local AP_BADGE_ID = "rbxassetid://99542126849967"
local RowAPBadges = setmetatable({}, { __mode = "k" })

task.spawn(function()
    while true do
        task.wait(0.5)
        for plr, badge in pairs(RowAPBadges) do
            if not plr.Parent or not (badge and badge.Parent) then
                RowAPBadges[plr] = nil
                continue
            end
            local hasAP = playerHasAP(plr)
            if badge.Visible ~= hasAP then badge.Visible = hasAP end
        end
    end
end)

local function isClick(input)
    return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
end

local function makeRow(plr)
    local row = Instance.new("Frame")
    row.Name = "P_" .. plr.UserId; row.Size = UDim2.new(1, -4, 0, ROW_HEIGHT)
    row.BackgroundColor3 = C.card; row.BorderSizePixel = 0; row.LayoutOrder = plr.UserId; row.Parent = List
    row.Active = true
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)

    local av = Instance.new("ImageLabel", row)
    av.Size = UDim2.fromOffset(36, 36); av.Position = UDim2.fromOffset(8, 8)
    av.BackgroundColor3 = C.bg; av.BorderSizePixel = 0; av.Active = true
    Instance.new("UICorner", av).CornerRadius = UDim.new(0, 6)
    task.spawn(function()
        pcall(function()
            av.Image = Players:GetUserThumbnailAsync(plr.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
        end)
    end)

    local name = Instance.new("TextLabel", row)
    name.Size = UDim2.new(0, 150, 0, 16); name.Position = UDim2.fromOffset(52, 8)
    name.BackgroundTransparency = 1; name.Text = plr.DisplayName; name.TextColor3 = C.text
    name.Font = Enum.Font.GothamBold; name.TextSize = 12; name.TextXAlignment = Enum.TextXAlignment.Left
    name.TextTruncate = Enum.TextTruncate.AtEnd; name.Active = true

    local username = Instance.new("TextLabel", row)
    username.Size = UDim2.new(0, 150, 0, 14); username.Position = UDim2.fromOffset(52, 24)
    username.BackgroundTransparency = 1; username.Text = "@" .. plr.Name; username.TextColor3 = C.mute
    username.Font = Enum.Font.Gotham; username.TextSize = 10; username.TextXAlignment = Enum.TextXAlignment.Left
    username.TextTruncate = Enum.TextTruncate.AtEnd; username.Active = true

    local apBadge = Instance.new("ImageLabel", row)
    apBadge.Name = "APBadge"; apBadge.Size = UDim2.fromOffset(20, 20)
    apBadge.Position = UDim2.fromOffset(206, 10)
    apBadge.BackgroundTransparency = 1; apBadge.Image = AP_BADGE_ID
    apBadge.ScaleType = Enum.ScaleType.Fit; apBadge.Visible = false; apBadge.Active = true
    RowAPBadges[plr] = apBadge
    apBadge.InputBegan:Connect(function(input) if isClick(input) then doSpamAll(plr) end end)

    local btnFrame = Instance.new("Frame", row)
    btnFrame.AnchorPoint = Vector2.new(1, 0.5)
    btnFrame.Position = UDim2.new(1, -8, 0.5, 0)
    btnFrame.Size = UDim2.new(0.6, 0, 1, 0)
    btnFrame.BackgroundTransparency = 1

    local btnLayout = Instance.new("UIListLayout", btnFrame)
    btnLayout.FillDirection = Enum.FillDirection.Horizontal
    btnLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    btnLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    btnLayout.Padding = UDim.new(0, 4)
    btnLayout.SortOrder = Enum.SortOrder.LayoutOrder

    local allBtn = Instance.new("TextButton", btnFrame)
    allBtn.Size = UDim2.fromOffset(36, 22); allBtn.BackgroundColor3 = C.purple
    allBtn.Text = "All"; allBtn.TextColor3 = C.text
    allBtn.Font = Enum.Font.GothamBold; allBtn.TextSize = 10; allBtn.BorderSizePixel = 0
    allBtn.LayoutOrder = 1
    Instance.new("UICorner", allBtn).CornerRadius = UDim.new(0, 4)
    allBtn.MouseButton1Click:Connect(function() doSpamAll(plr) end)
    allBtn.MouseEnter:Connect(function() allBtn.BackgroundColor3 = C.accentHover end)
    allBtn.MouseLeave:Connect(function() allBtn.BackgroundColor3 = C.purple end)

    local semiBtn = Instance.new("TextButton", btnFrame)
    semiBtn.Size = UDim2.fromOffset(52, 22)
    semiBtn.BackgroundColor3 = C.blue; semiBtn.Text = "Semi Full"
    semiBtn.TextColor3 = C.text; semiBtn.Font = Enum.Font.GothamBold; semiBtn.TextSize = 9
    semiBtn.BorderSizePixel = 0; semiBtn.Visible = AutoSemiBtnVisible
    semiBtn.LayoutOrder = 2
    Instance.new("UICorner", semiBtn).CornerRadius = UDim.new(0, 4)
    SemiButtons[plr.Name] = semiBtn

    semiBtn.MouseButton1Click:Connect(function()
        local cmds = getRandomSemiCommands(3)
        if #cmds > 0 then
            task.spawn(function()
                for i, cmd in ipairs(cmds) do
                    sendSpecific(cmd, plr.Name)
                    if i < #cmds then task.wait(SemiDelay) end
                end
            end)
        end
    end)

    semiBtn.MouseEnter:Connect(function() semiBtn.BackgroundColor3 = C.cyanHover end)
    semiBtn.MouseLeave:Connect(function() semiBtn.BackgroundColor3 = C.blue end)

    local function rowClick() doSpamAll(plr) end
    for _, o in ipairs({ row, name, username, av }) do
        o.InputBegan:Connect(function(input) if isClick(input) then rowClick() end end)
    end
end

function updateWindowSize()
    if SetPanel.Visible then
        local contentH = 0
        for _, child in ipairs(SetPanel:GetChildren()) do
            if child:IsA("GuiObject") then contentH = contentH + child.AbsoluteSize.Y + 5 end
        end
        local setH = math.clamp(44 + contentH + 16, 120, 560)
        TweenService:Create(Win, TweenInfo.new(0.15), { Size = UDim2.fromOffset(500, setH) }):Play()
        return
    end
    local playerCount = #Players:GetPlayers() - 1
    if playerCount < 0 then playerCount = 0 end
    local rows = math.max(playerCount, 1)
    local listHeight = (rows * ROW_HEIGHT) + ((rows - 1) * 4)
    local proxHeight = ProximityEnabled and 34 or 0
    local targetHeight = 44 + proxHeight + listHeight + 12

    if ProximityEnabled then
        List.Position = UDim2.fromOffset(8, 82)
        List.Size = UDim2.new(1, -16, 1, -(56 + proxHeight))
    else
        List.Position = UDim2.fromOffset(8, 48)
        List.Size = UDim2.new(1, -16, 1, -56)
    end

    TweenService:Create(Win, TweenInfo.new(0.15), { Size = UDim2.fromOffset(500, targetHeight) }):Play()
end

function rebuild()
    for _, c in ipairs(List:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end
    SemiButtons = {}
    local playerCount = 0
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and not isPlayerFiltered(plr.Name) then
            makeRow(plr)
            playerCount = playerCount + 1
        end
    end
    if playerCount == 0 then
        local emptyRow = Instance.new("Frame")
        emptyRow.Name = "EmptyRow"; emptyRow.Size = UDim2.new(1, -4, 0, ROW_HEIGHT)
        emptyRow.BackgroundColor3 = C.card; emptyRow.BackgroundTransparency = 0.5
        emptyRow.BorderSizePixel = 0; emptyRow.Parent = List
        Instance.new("UICorner", emptyRow).CornerRadius = UDim.new(0, 6)
        local emptyText = Instance.new("TextLabel", emptyRow)
        emptyText.Size = UDim2.new(1, 0, 1, 0); emptyText.BackgroundTransparency = 1
        emptyText.Text = tr("emptyServer"); emptyText.TextColor3 = C.mute
        emptyText.Font = Enum.Font.GothamMedium; emptyText.TextSize = 12
    end
    updateWindowSize()
end

Players.PlayerAdded:Connect(function(p)
    task.wait(0.3)
    if p ~= LocalPlayer then
        rebuild()
    end
end)

Players.PlayerRemoving:Connect(function(p)
    RowAPBadges[p] = nil
    task.wait(0.2)
    rebuild()
end)

-- CONTROLES DE LA VENTANA
SetBtn.MouseButton1Click:Connect(function()
    SetPanel.Visible = not SetPanel.Visible
    List.Visible = not SetPanel.Visible
    ProxFrame.Visible = false
    updateWindowSize()
end)

btnBack.MouseButton1Click:Connect(function()
    SetPanel.Visible = false
    List.Visible = true
    ProxFrame.Visible = ProximityEnabled
    updateWindowSize()
end)

local minimized = false
MinBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    MinBtn.Text = minimized and "+" or "-"
    if minimized then
        SetPanel.Visible = false
        List.Visible = false
        ProxFrame.Visible = false
        TweenService:Create(Win, TweenInfo.new(0.15), { Size = UDim2.fromOffset(500, 44) }):Play()
    else
        List.Visible = not SetPanel.Visible
        ProxFrame.Visible = ProximityEnabled and not SetPanel.Visible
        updateWindowSize()
    end
end)

CloseBtn.MouseButton1Click:Connect(function()
    GUI:Destroy()
    adminTextBox = nil
    if proxCircle then
        proxCircle:Destroy()
        proxCircle = nil
    end
end)

-- Arrastre
do
    local dragging, dragStart, startPos = false, nil, nil
    Header.InputBegan:Connect(function(input)
        if isClick(input) then
            dragging = true; dragStart = input.Position; startPos = Win.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end
        local d = input.Position - dragStart
        Win.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
    end)
    UserInputService.InputEnded:Connect(function(input)
        if isClick(input) then
            if dragging then
                saveAll()
            end
            dragging = false
        end
    end)
end

findAdminTextBox()
rebuild()

-- Reemplaza los dos bloques finales (TEMPORIZADOR + PANEL SECRETO + Monitor de acceso) por esto.
-- Requiere: GUI (ScreenGui del panel), SubTitle, tr, ACCESS, evaluate, refreshStatus, showGate, api, hasDarkName, nowS

task.spawn(function()
    while true do
        task.wait(1)
        if PANEL_ACTIVE then
            if hasDarkName() then
                if SubTitle.Text ~= tr("adminPanel") then SubTitle.Text = tr("adminPanel"); SubTitle.TextColor3 = C.mute end
            elseif ACCESS.trialEnd > nowS() then
                local r = ACCESS.trialEnd - nowS()
                SubTitle.Text = ("⏳ %s %02d:%02d"):format(tr("trial"), math.floor(r / 60), r % 60)
                SubTitle.TextColor3 = C.yellow
            end
        end
    end
end)

-- Monitor: si se acaba la hora (y no hay "dark" en el nombre) -> oculta panel y muestra bloqueo
-- con "Chequear de nuevo" y "Salir". Si el chequeo da OK, el panel vuelve sin reiniciar.
task.spawn(function()
    while true do
        task.wait(2)
        if PANEL_ACTIVE and not hasDarkName() and ACCESS.trialEnd > 0 and nowS() >= ACCESS.trialEnd then
            PANEL_ACTIVE = false
            GUI.Enabled = false
            if proxCircle then proxCircle.Transparency = 1 end
            api("/event", { event = "trial_ended" })
            repeat
                refreshStatus()
                if evaluate() == "ok" then break end
                showGate(evaluate() == "verify" and "verify" or "locked")
            until evaluate() == "ok"
            api("/event", { event = hasDarkName() and "access_restored_dark" or "access_restored" })
            GUI.Enabled = true
            if proxCircle then proxCircle.Transparency = 0.5 end
            PANEL_ACTIVE = true
        end
    end
end)

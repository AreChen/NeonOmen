local addonName, ns = ...
local defaults = {
    width = 280, rowHeight = 22, maxRows = 8, opacity = 0.85,
    style = 2, classColors = true, showPets = true, locked = false,
    test = false, padNavigation = true, x = 180, y = 0,
    red = 0.25, green = 0.72, blue = 0.85, barAlpha = 0.95,
    fontSize = 12, font = 1, fontName = "",
    spacing = 3, scale = 1, showValue = false, showTPS = true,
    useFocus = false, showTitle = true, showTarget = true,
    showCombat = true, showOutOfCombat = true, showSolo = true,
    showParty = true, showRaid = true, hideResting = false,
    warningThreshold = 80, warningSound = true, warningMessage = true,
    warningFlash = true, warningCooldown = 4, suppressTank = true,
    showMinimap = true, glow = true, glowIntensity = 0.55,
    barGlow = true, barGlowIntensity = 0.21, barGlowSpread = 1,
    showSelf = true, clickThrough = false, showMarker = true,
    height = 180, autoCollapse = true, growUp = false,
    showHeader = true, showAggroLine = true, showAggroBar = true, soundChoice = 1, hidePvp = false,
    barTexture = 4, textureName = "", windowAlpha = 1, showWithPet = true, minimapAngle = 220,
    warningAggro = true, warningShake=false, warningScreenShake=false, animateBars = true, useSelfColor=true, usePetColor=true, useTankColor=true,
    minimapOffset=0,
    selfRed = 0.25, selfGreen = 0.72, selfBlue = 0.85,
    tankRed = 0.95, tankGreen = 0.32, tankBlue = 0.25,
    petRed = 0.60, petGreen = 0.75, petBlue = 0.35,
    aggroRed = 1, aggroGreen = 0.32, aggroBlue = 0.18,
}
ns.defaults = defaults
ns.styles = {"Solid", "Gradient", "Glass"}
ns.sounds = {
    {"RAID_WARNING","soundRaid"}, {"READY_CHECK","soundReady"},
    {"ALARM_CLOCK_WARNING_1","soundAlarm1"}, {"ALARM_CLOCK_WARNING_2","soundAlarm2"},
    {"ALARM_CLOCK_WARNING_3","soundAlarm3"}, {"TELL_MESSAGE","soundWhisper"},
    {"IG_PLAYER_INVITE","soundInvite"}, {"LEVEL_UP","soundLevel"},
    {"IG_QUEST_LIST_COMPLETE","soundQuest"}, {"MAP_PING","soundPing"},
    {"AUCTION_WINDOW_OPEN","soundAuction"}, {568582,"soundFel"},
    {566982,"soundExplosion"}, {566946,"soundImpact"}, {567275,"soundDrums"},
    {546633,"soundDoom"}, {567283,"soundCheer"}, {566121,"soundDuck"},
}
ns.barTextures = {
    "Interface\\Buttons\\WHITE8X8",
    "Interface\\TargetingFrame\\UI-StatusBar",
    "Interface\\RaidFrame\\Raid-Bar-Hp-Fill",
    "Interface\\AddOns\\NeonOmenReborn\\Media\\NeonBar",
}
local locale = GetLocale()
local zh = locale == "zhCN" or locale == "zhTW"
local tw = locale == "zhTW"
local text = {
    title = zh and "仇恨監測" or "Threat meter",
    appearance = zh and "外觀" or "Appearance",
    colors = zh and "顏色與文字" or "Colors & text",
    layout = zh and "佈局" or "Layout",
    controls = zh and "操作與手柄" or "Controls & gamepad",
    subtitle = zh and "自訂仇恨條、視窗及操作方式" or "Customize your meter and controls",
    style = zh and "條形樣式" or "Bar style",
    red = zh and "紅色" or "Red", green = zh and "綠色" or "Green", blue = zh and "藍色" or "Blue",
    barAlpha = zh and "條形透明度" or "Bar opacity",
    font = zh and "文字字體" or "Font", fontSize = zh and "文字大小" or "Font size",
    width = zh and "視窗寬度" or "Window width",
    rowHeight = zh and "條目高度" or "Row height",
    maxRows = zh and "最多條目" or "Maximum rows",
    opacity = zh and "背景透明度" or "Background opacity",
    classColors = zh and "職業顏色" or "Class colors",
    showPets = zh and "顯示寵物" or "Show pets",
    locked = zh and "鎖定位置" or "Lock position",
    test = zh and "測試資料" or "Preview data",
    padNavigation = zh and "手柄導航" or "Gamepad navigation",
    padHint = zh and "方向鍵調整 · A 確認 · B 關閉 · LB/RB 子頁 · LT/RT 分類" or "D-pad adjust · A select · B close · LB/RB tabs · LT/RT categories",
    empty = zh and "目前沒有仇恨資料" or "No threat data",
    on = zh and "開" or "On", off = zh and "關" or "Off",
    solid = zh and "純色" or "Solid", gradient = zh and "漸變" or "Gradient", glass = zh and "玻璃" or "Glass",
}
local more = {
    display={"Data display","資料顯示","数据显示"},
    visibility={"Visibility","顯示規則","显示规则"},
    warnings={"Alerts","仇恨警報","仇恨警报"},
    extras={"Window behavior","視窗行為","窗口行为"},
    effects={"Effects","視覺效果","视觉效果"},
    spacing={"Row spacing","條目間距","条目间距"},
    scale={"Window scale","視窗縮放","窗口缩放"},
    showValue={"Threat amount","仇恨數值","仇恨数值"},
    showTPS={"Threat per second","每秒仇恨","每秒仇恨"},
    useFocus={"Prefer focus target","優先焦點目標","优先焦点目标"},
    showTitle={"Show title","顯示標題","显示标题"},
    showTarget={"Show target name","顯示目標名稱","显示目标名称"},
    showCombat={"Show in combat","戰鬥中顯示","战斗中显示"},
    showOutOfCombat={"Show out of combat","非戰鬥時顯示","非战斗时显示"},
    showSolo={"Show solo","單人時顯示","单人时显示"},
    showParty={"Show in party","隊伍中顯示","队伍中显示"},
    showRaid={"Show in raid","團隊中顯示","团队中显示"},
    hideResting={"Hide while resting","休息區隱藏","休息区隐藏"},
    warningThreshold={"Alert threshold","警告門檻","警告阈值"},
    warningSound={"Alert sound","聲音警告","声音警告"},
    warningMessage={"Alert message","文字警告","文字警告"},
    warningFlash={"Screen flash","螢幕閃光","屏幕闪光"},
    warningShake={"Shake meter on alert","警報時震動仇恨窗","警报时震动仇恨窗"},
    warningScreenShake={"Shake game world on alert","警報時震動畫面","警报时震动画面"},
    screenEffects={"Screen effects","畫面效果","画面效果"},
    warningCooldown={"Alert cooldown","警告間隔","警告间隔"},
    suppressTank={"Suppress tank alerts","坦克不警告","坦克不警告"},
    showMinimap={"Minimap button","小地圖按鈕","小地图按钮"},
    showSelf={"Always show yourself","始終顯示自己","始终显示自己"},
    clickThrough={"Click-through","滑鼠穿透","鼠标穿透"},
    showMarker={"Tank and status markers","坦克與狀態標記","坦克与状态标记"},
    petSuffix={" (Pet)","（寵物）","（宠物）"},
    dead={"Dead","死亡","死亡"}, offline={"Offline","離線","离线"},
    glow={"Window glow","視窗光暈","窗口光晕"},
    glowIntensity={"Glow intensity","光暈強度","光晕强度"},
    barGlowPage={"Bar glow","條形光暈","条形光晕"},
    barGlow={"Show bar glow","顯示條形光暈","显示条形光晕"},
    barGlowIntensity={"Bar glow intensity","條形光暈強度","条形光晕强度"},
    barGlowSpread={"Bar glow spread","條形光暈範圍","条形光晕范围"},
    debugTarget={"Target","目標","目标"},
    debugData={"Threat status / scaled / raw / value","仇恨狀態／比例／原始比例／數值","仇恨状态／比例／原始比例／数值"},
    debugUnavailable={"unavailable or restricted","不可用或受限","不可用或受限"},
    hideWindow={"Hide window","隱藏視窗","隐藏窗口"},
    colorPicker={"Choose bar color","選擇條形顏色","选择条形颜色"},
    geometry={"Window size","視窗尺寸","窗口尺寸"},
    alertSound={"Alert options","警報選項","警报选项"},
    testAlert={"Test alert","測試警報","测试警报"},
    lockAction={"Lock window","鎖定視窗","锁定窗口"},
    unlockAction={"Unlock window","解鎖視窗","解锁窗口"},
    previewOn={"Show preview","顯示預覽","显示预览"},
    previewOff={"Hide preview","關閉預覽","关闭预览"},
    resetPosition={"Reset position","重設位置","重置位置"},
    bindingToggle={"Toggle threat meter","顯示／隱藏仇恨窗","显示／隐藏仇恨窗"},
    bindingFocus={"Toggle focus target","切換焦點目標","切换焦点目标"},
    bindingPreview={"Toggle preview","切換預覽","切换预览"},
    bindingSettings={"Open settings","開啟設定","打开设置"},
    openSettings={"Open NeonOmen settings","開啟 NeonOmen 設定","打开 NeonOmen 设置"},
    barStyle={"Bar materials","條形材質","条形材质"},
    barTexture={"Bar texture","條形紋理","条形纹理"},
    textureNeon={"Rounded neon","圓角霓虹","圆角霓虹"},
    profilePage={"Profiles","設定檔","配置方案"},
    profileSlot={"Active profile","目前設定檔","当前配置方案"},
    minimapLeft={"Left click: settings","左鍵：設定","左键：设置"},
    minimapShift={"Shift-left click: toggle meter","Shift + 左鍵：顯示／隱藏","Shift + 左键：显示／隐藏"},
    minimapRight={"Right click: preview","右鍵：預覽","右键：预览"},
    minimapDrag={"Drag to move","拖曳以移動","拖动以移动"},
    fonts={"Fonts","字體","字体"},
    mediaStyle={"Shared media","共享材質","共享材质"},
    textureName={"Shared bar texture","共享條形紋理","共享条形纹理"},
    fontName={"Shared font","共享字體","共享字体"},
    defaultFont={"Game font","遊戲字體","游戏字体"},
    defaultTexture={"Built-in texture","內建紋理","内置纹理"},
    fontSmall={"Small","小字體","小字体"}, fontRegular={"Standard","標準","标准"}, fontTitle={"Title","標題","标题"},
    textureFlat={"Flat","平滑","平滑"}, textureClassic={"Classic","經典","经典"}, textureSoft={"Soft","柔和","柔和"},
    soundRaid={"Raid warning","團隊警報","团队警报"}, soundReady={"Ready check","準備確認","准备确认"},
    soundAlarm1={"Alarm 1","鬧鐘 1","闹钟 1"}, soundAlarm2={"Alarm 2","鬧鐘 2","闹钟 2"}, soundAlarm3={"Alarm 3","鬧鐘 3","闹钟 3"},
    soundWhisper={"Whisper","密語","密语"}, soundInvite={"Invitation","邀請","邀请"},
    soundLevel={"Level up","升級","升级"}, soundQuest={"Quest complete","任務完成","任务完成"}, soundPing={"Map ping","地圖標記","地图标记"},
    soundAuction={"Auction house","拍賣場","拍卖行"}, soundFel={"Fel nova","邪能新星","邪能新星"},
    soundExplosion={"Explosion","爆炸","爆炸"}, soundImpact={"Impact","衝擊","冲击"},
    soundDrums={"War drums","戰鼓","战鼓"}, soundDoom={"You will die","死亡警告","死亡警告"},
    soundCheer={"Cheer","歡呼","欢呼"}, soundDuck={"Rubber duck","橡皮鴨","橡皮鸭"},
    height={"Window height","視窗高度","窗口高度"},
    autoCollapse={"Fit height to rows","按條目自動收合","按条目自动收合"},
    growUp={"Grow upwards","向上增長","向上增长"},
    showHeader={"Show column headings","顯示欄位標題","显示列标题"},
    showAggroLine={"Show alert threshold line","顯示警報門檻線","显示警报阈值线"},
    showAggroBar={"Show aggro pull boundary","顯示搶仇恨界線","显示抢仇恨界线"},
    pullBoundary={"Aggro pull","搶仇恨界線","抢仇恨界线"},
    sampleTank={"Tank","坦克示例","坦克示例"},
    sampleDamage={"Damage","輸出示例","输出示例"},
    sampleYou={"You","你","你"},
    previewTitle={"Preview data","測試資料","测试数据"},
    soundChoice={"Alert sound","警告音效","警告音效"},
    hidePvp={"Hide in PvP","PvP 隱藏","PvP 隐藏"},
    windowAlpha={"Window opacity","視窗不透明度","窗口不透明度"},
    showWithPet={"Show solo with pet","單人帶寵物時顯示","单人带宠物时显示"},
    warningAggro={"Alert when gaining aggro","獲得仇恨時警告","获得仇恨时警告"},
    animateBars={"Animate bars","條形動畫","条形动画"},
    roleColors={"Role colors","角色顏色","角色颜色"},
    colorOverrides={"Color overrides","自訂顏色開關","自定义颜色开关"},
    useSelfColor={"Use your custom color","使用自身自訂顏色","使用自身自定义颜色"},
    useTankColor={"Use tank custom color","使用坦克自訂顏色","使用坦克自定义颜色"},
    usePetColor={"Use pet custom color","使用寵物自訂顏色","使用宠物自定义颜色"},
    minimapOffset={"Minimap button offset","小地圖按鈕偏移","小地图按钮偏移"},
    advanced={"More options","更多選項","更多选项"},
    selfColor={"Your color","自身顏色","自身颜色"},
    tankColor={"Tank color","坦克顏色","坦克颜色"},
    petColor={"Pet color","寵物顏色","宠物颜色"},
    aggroColor={"Alert color","警告顏色","警告颜色"},
    aggroTaken={"You gained aggro!","你獲得了仇恨！","你获得了仇恨！"},
    aggroNear={"Threat is high!","仇恨過高！","仇恨过高！"},
    classFilter1={"Classes I","職業篩選 I","职业筛选 I"},
    classFilter2={"Classes II","職業篩選 II","职业筛选 II"},
    classFilter3={"Classes III","職業篩選 III","职业筛选 III"},
    hide_WARRIOR={"Hide warrior","隱藏戰士","隐藏战士"},
    hide_PALADIN={"Hide paladin","隱藏聖騎士","隐藏圣骑士"},
    hide_HUNTER={"Hide hunter","隱藏獵人","隐藏猎人"},
    hide_ROGUE={"Hide rogue","隱藏盜賊","隐藏潜行者"},
    hide_PRIEST={"Hide priest","隱藏牧師","隐藏牧师"},
    hide_SHAMAN={"Hide shaman","隱藏薩滿","隐藏萨满"},
    hide_MAGE={"Hide mage","隱藏法師","隐藏法师"},
    hide_WARLOCK={"Hide warlock","隱藏術士","隐藏术士"},
    hide_DRUID={"Hide druid","隱藏德魯伊","隐藏德鲁伊"},
    hide_DEATHKNIGHT={"Hide death knight","隱藏死亡騎士","隐藏死亡骑士"},
    hide_MONK={"Hide monk","隱藏武僧","隐藏武僧"},
    hide_DEMONHUNTER={"Hide demon hunter","隱藏惡魔獵人","隐藏恶魔猎手"},
    hide_EVOKER={"Hide evoker","隱藏喚能師","隐藏唤魔师"},
}
for key, names in pairs(more) do text[key] = names[tw and 2 or (zh and 3 or 1)] end
if zh and not tw then
    text.title, text.appearance, text.layout = "仇恨监测", "外观", "布局"
    text.controls, text.subtitle, text.colors = "操作与手柄", "自定义仇恨条、窗口及操作方式", "颜色与文字"
    text.red, text.green, text.blue, text.barAlpha, text.font, text.fontSize = "红色", "绿色", "蓝色", "条形透明度", "文字字体", "文字大小"
    text.style, text.width, text.rowHeight, text.maxRows = "条形样式", "窗口宽度", "条目高度", "最多条目"
    text.opacity, text.classColors, text.showPets = "背景透明度", "职业颜色", "显示宠物"
    text.locked, text.test, text.padNavigation = "锁定位置", "测试数据", "手柄导航"
    text.padHint = "方向键调整 · A 确认 · B 关闭 · LB/RB 子页 · LT/RT 分类"
    text.empty, text.on, text.off, text.solid, text.gradient, text.glass = "目前没有仇恨数据", "开", "关", "纯色", "渐变", "玻璃"
end
ns.L = text
BINDING_HEADER_NEONOMENREBORN = "NeonOmen"
BINDING_NAME_NEONOMENREBORN_TOGGLE = text.bindingToggle
BINDING_NAME_NEONOMENREBORN_FOCUS = text.bindingFocus
BINDING_NAME_NEONOMENREBORN_PREVIEW = text.bindingPreview
BINDING_NAME_NEONOMENREBORN_SETTINGS = text.bindingSettings
function ns.Safe(value)
    if issecretvalue and issecretvalue(value) then return nil end
    return value
end
function ns.SharedMedia()
    if not LibStub then return nil end
    local ok,media=pcall(LibStub,"LibSharedMedia-3.0",true)
    if ok then return media end
end
function ns.MediaPath(kind,name)
    if not name or name=="" then return nil end
    local media=ns.SharedMedia()
    if not media or not media.Fetch then return nil end
    local ok,path=pcall(media.Fetch,media,kind,name,true)
    if ok and type(path)=="string" then return path end
end
function ns.InitDB()
    if type(NeonOmenRebornDB) ~= "table" then NeonOmenRebornDB = {} end
    if NeonOmenRebornDB.barGlow==nil and type(NeonOmenRebornDB.glow)=="boolean" then
        NeonOmenRebornDB.barGlow=NeonOmenRebornDB.glow
    end
    if NeonOmenRebornDB.barGlowIntensity==nil and type(NeonOmenRebornDB.glowIntensity)=="number" then
        NeonOmenRebornDB.barGlowIntensity=math.max(0,math.min(0.6,NeonOmenRebornDB.glowIntensity*0.38))
    end
    for key, value in pairs(defaults) do
        if NeonOmenRebornDB[key] == nil then NeonOmenRebornDB[key] = value end
    end
    NeonOmenRebornDB.test = false
    if type(NeonOmenRebornDB.profiles) ~= "table" then NeonOmenRebornDB.profiles={} end
    if type(NeonOmenRebornDB.profileSlot) ~= "number" or NeonOmenRebornDB.profileSlot < 1 or NeonOmenRebornDB.profileSlot > 3 then NeonOmenRebornDB.profileSlot=1 end
    ns.db = NeonOmenRebornDB
end
function ns.SwitchProfile(slot)
    if not ns.db or type(slot)~="number" or slot<1 or slot>3 or slot==ns.db.profileSlot then return end
    local db=ns.db
    local previous={}
    for key,value in pairs(db) do
        if key~="test" and (defaults[key]~=nil or (type(key)=="string" and key:match("^hide_"))) then previous[key]=value end
    end
    db.profiles[db.profileSlot]=previous
    local target=db.profiles[slot] or {}
    for key in pairs(db) do if type(key)=="string" and key:match("^hide_") then db[key]=nil end end
    for key,value in pairs(defaults) do db[key]=target[key]~=nil and target[key] or value end
    -- False is a valid setting and must survive a profile change.
    for key,value in pairs(target) do db[key]=value end
    if target.barGlow==nil and type(target.glow)=="boolean" then db.barGlow=target.glow end
    if target.barGlowIntensity==nil and type(target.glowIntensity)=="number" then
        db.barGlowIntensity=math.max(0,math.min(0.6,target.glowIntensity*0.38))
    end
    db.test=false;db.profileSlot=slot
    local meter=_G.NeonOmenRebornMeter
    if meter then meter:ClearAllPoints();meter:SetPoint("CENTER",UIParent,"CENTER",db.x,db.y) end
    if ns.RefreshMeter then ns.RefreshMeter() end
    if ns.RefreshSettings then ns.RefreshSettings() end
    if ns.UpdateMinimap then ns.UpdateMinimap() end
end
function ns.Set(key, value)
    ns.db[key] = value
    if key == "barTexture" then ns.db.textureName="" end
    if key == "font" then ns.db.fontName="" end
    if key == "locked" and not value then ns.db.clickThrough = false end
    if ns.RefreshMeter then ns.RefreshMeter() end
    if ns.RefreshSettings then ns.RefreshSettings() end
    if ns.UpdateMinimap then ns.UpdateMinimap() end
end
function NeonOmenReborn_Toggle() if ns.ToggleMeter then ns.ToggleMeter() end end
function NeonOmenReborn_ToggleFocus() if ns.db then ns.Set("useFocus",not ns.db.useFocus) end end
function NeonOmenReborn_TogglePreview() if ns.db then ns.Set("test",not ns.db.test) end end
function NeonOmenReborn_ToggleSettings() if ns.ToggleSettings then ns.ToggleSettings() end end
local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:SetScript("OnEvent", function(_, event, name)
    if event ~= "ADDON_LOADED" or name ~= addonName then return end
    ns.InitDB()
    ns.CreateMeter()
    ns.CreateSettings()
    ns.CreateMinimap()
end)
SLASH_NEONOMENREBORN1 = "/neonomenreborn"
SLASH_NEONOMENREBORN2 = "/nor"
SLASH_NEONOMENREBORN3 = "/neonomen"
SLASH_NEONOMENREBORN4 = "/orf"
SlashCmdList.NEONOMENREBORN = function(message)
    local command = (message or ""):lower():match("^%s*(.-)%s*$")
    if command == "test" then ns.Set("test",not ns.db.test)
    elseif command == "lock" then ns.Set("locked",true)
    elseif command == "unlock" then ns.Set("locked",false)
    elseif command == "toggle" and ns.ToggleMeter then ns.ToggleMeter()
    elseif command == "reset" and ns.ResetMeter then ns.ResetMeter()
    elseif command == "focus" then NeonOmenReborn_ToggleFocus()
    elseif command == "pets" then ns.Set("showPets",not ns.db.showPets)
    elseif command == "minimap" then ns.Set("showMinimap",not ns.db.showMinimap)
    elseif command == "debug" and ns.Debug then ns.Debug()
    elseif ns.ToggleSettings then ns.ToggleSettings() end
end

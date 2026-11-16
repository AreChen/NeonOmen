local _, ns = ...
local frame, nav, controls, page = nil, {}, {}, 1
local selected = 1
local tabs = {}
local active = {}
local white = "Interface\\Buttons\\WHITE8X8"
local pages = {
    {key="appearance", entries={
        {key="style", kind="choice", count=3},
        {key="opacity", kind="number", min=0, max=1, step=0.1},
        {key="classColors", kind="boolean"},
        {key="test", kind="boolean"},
    }},
    {key="layout", entries={
        {key="width", kind="number", min=160, max=600, step=20},
        {key="rowHeight", kind="number", min=14, max=40, step=2},
        {key="maxRows", kind="number", min=1, max=40, step=1},
        {key="showPets", kind="boolean"},
        {key="locked", kind="boolean"},
    }},
    {key="colors", entries={
        {key="red", kind="number", min=0, max=1, step=0.1},
        {key="green", kind="number", min=0, max=1, step=0.1},
        {key="blue", kind="number", min=0, max=1, step=0.1},
        {key="barAlpha", kind="number", min=0.1, max=1, step=0.1},
        {key="fontSize", kind="number", min=9, max=24, step=1},
    }},
    {key="controls", entries={
        {key="padNavigation", kind="boolean"},
        {key="font", kind="choice", count=3},
        {key="locked", kind="boolean"},
        {key="clickThrough", kind="boolean"},
        {key="showMinimap", kind="boolean"},
    }},
    {key="display", entries={
        {key="showValue", kind="boolean"}, {key="showTPS", kind="boolean"},
        {key="useFocus", kind="boolean"}, {key="showSelf", kind="boolean"},
        {key="showMarker", kind="boolean"},
    }},
    {key="visibility", entries={
        {key="showCombat", kind="boolean"}, {key="showOutOfCombat", kind="boolean"},
        {key="showSolo", kind="boolean"}, {key="showParty", kind="boolean"},
        {key="showRaid", kind="boolean"},
    }},
    {key="warnings", entries={
        {key="warningThreshold",kind="number",min=50,max=100,step=5},
        {key="warningSound",kind="boolean"}, {key="warningMessage",kind="boolean"},
        {key="warningFlash",kind="boolean"}, {key="suppressTank",kind="boolean"},
    }},
    {key="effects", entries={
        {key="glow",kind="boolean"},
        {key="glowIntensity",kind="number",min=0,max=1,step=0.1},
        {key="scale",kind="number",min=0.5,max=2,step=0.1},
        {key="spacing",kind="number",min=0,max=12,step=1},
        {key="warningCooldown",kind="number",min=1,max=30,step=1},
    }},
    {key="extras", entries={
        {key="showTitle",kind="boolean"}, {key="showTarget",kind="boolean"},
        {key="hideResting",kind="boolean"}, {key="colorPicker",kind="color"},
        {key="hidePvp",kind="boolean"},
    }},
    {key="geometry", entries={
        {key="height",kind="number",min=70,max=600,step=10},
        {key="autoCollapse",kind="boolean"}, {key="growUp",kind="boolean"},
        {key="showHeader",kind="boolean"}, {key="showAggroLine",kind="boolean"},
    }},
    {key="alertSound", entries={
        {key="soundChoice",kind="choice",count=#ns.sounds},
        {key="warningCooldown",kind="number",min=1,max=30,step=1},
        {key="warningAggro",kind="boolean"},
        {key="warningShake",kind="boolean"},
        {key="testAlert",kind="action"},
    }},
    {key="barStyle", entries={
        {key="barTexture",kind="choice",count=4},
        {key="style",kind="choice",count=3},
        {key="barAlpha",kind="number",min=0.1,max=1,step=0.1},
        {key="classColors",kind="boolean"},
        {key="colorPicker",kind="color"},
    }},
    {key="classFilter1", entries={
        {key="hide_WARRIOR",kind="boolean"}, {key="hide_PALADIN",kind="boolean"},
        {key="hide_HUNTER",kind="boolean"}, {key="hide_ROGUE",kind="boolean"},
        {key="hide_PRIEST",kind="boolean"},
    }},
    {key="classFilter2", entries={
        {key="hide_SHAMAN",kind="boolean"}, {key="hide_MAGE",kind="boolean"},
        {key="hide_WARLOCK",kind="boolean"}, {key="hide_DRUID",kind="boolean"},
        {key="hide_DEATHKNIGHT",kind="boolean"},
    }},
    {key="classFilter3", entries={
        {key="hide_MONK",kind="boolean"}, {key="hide_DEMONHUNTER",kind="boolean"},
        {key="hide_EVOKER",kind="boolean"},
    }},
    {key="roleColors", entries={
        {key="selfColor",kind="color",prefix="self"},
        {key="tankColor",kind="color",prefix="tank"},
        {key="petColor",kind="color",prefix="pet"},
        {key="aggroColor",kind="color",prefix="aggro"},
    }},
    {key="colorOverrides", entries={
        {key="useSelfColor",kind="boolean"}, {key="useTankColor",kind="boolean"},
        {key="usePetColor",kind="boolean"},
        {key="minimapOffset",kind="number",min=-20,max=40,step=1},
    }},
    {key="advanced", entries={
        {key="windowAlpha",kind="number",min=0.1,max=1,step=0.1},
        {key="showWithPet",kind="boolean"},
        {key="animateBars",kind="boolean"},
        {key="showAggroBar",kind="boolean"},
    }},
    {key="fonts", entries={
        {key="fontName",kind="mediafont"}, {key="font",kind="choice",count=3},
        {key="fontSize",kind="number",min=9,max=24,step=1},
    }},
    {key="mediaStyle", entries={
        {key="textureName",kind="mediatexture"},
        {key="barTexture",kind="choice",count=4},
    }},
    {key="profilePage", entries={{key="profileSlot",kind="profile"}}},
}
local groups = {
    {key="appearance", pages={1,8,12,20}},
    {key="layout", pages={2,10,9,18}},
    {key="colors", pages={3,16,17,19}},
    {key="display", pages={5,6,13,14,15}},
    {key="warnings", pages={7,11}},
    {key="controls", pages={4,21}},
}
local function groupForPage(index)
    for groupIndex,group in ipairs(groups) do
        for _,pageIndex in ipairs(group.pages) do
            if index == pageIndex then return groupIndex end
        end
    end
    return 1
end
local function box(parent, color)
    local t = parent:CreateTexture(nil,"BACKGROUND")
    t:SetTexture(white); t:SetVertexColor(unpack(color)); t:SetAllPoints()
    return t
end
local function label(parent, text, font)
    local s=parent:CreateFontString(nil,"OVERLAY",font or "GameFontHighlight")
    s:SetText(text);s:SetJustifyH("LEFT")
    return s
end
local function smallButton(parent, caption)
    local b=CreateFrame("Button",nil,parent)
    b.bg=box(b,{0.11,0.16,0.21,1})
    b.caption=label(b,caption,"GameFontHighlight")
    b.caption:SetPoint("CENTER")
    b:SetScript("OnEnter",function() b.bg:SetVertexColor(0.18,0.29,0.35,1) end)
    b:SetScript("OnLeave",function() b.bg:SetVertexColor(0.11,0.16,0.21,1) end)
    return b
end
local function readableValue(entry)
    local value=ns.db[entry.key]
    if entry.kind=="profile" then return ns.L.profilePage.." "..value end
    if entry.kind=="mediafont" or entry.kind=="mediatexture" then return value ~= "" and value or ns.L[entry.kind=="mediafont" and "defaultFont" or "defaultTexture"] end
    if entry.kind=="action" then return "▶" end
    if entry.kind=="color" then return "..." end
    if entry.kind=="boolean" then return value and ns.L.on or ns.L.off end
    if entry.kind=="choice" then
        if entry.key=="font" then return ns.L[({"fontSmall", "fontRegular", "fontTitle"})[value]] end
        if entry.key=="soundChoice" then return ns.L[(ns.sounds[value] or ns.sounds[1])[2]] end
        if entry.key=="barTexture" then return ns.L[({"textureFlat", "textureClassic", "textureSoft", "textureNeon"})[value]] end
        return ({ns.L.solid,ns.L.gradient,ns.L.glass})[value]
    end
    if entry.key=="opacity" or entry.key=="windowAlpha" or entry.key=="red" or entry.key=="green" or entry.key=="blue" or entry.key=="barAlpha" then return string.format("%d%%",math.floor(value*100+0.5)) end
    return tostring(value)
end
local function adjust(entry, direction)
    if entry.kind=="profile" then ns.SwitchProfile(((ns.db.profileSlot-1+direction)%3)+1);return end
    if entry.kind=="action" then if entry.key=="testAlert" then ns.TestAlert() end;return end
    if entry.kind=="mediafont" or entry.kind=="mediatexture" then
        local options={""}
        local media=ns.SharedMedia()
        if media and media.List then
            local ok,names=pcall(media.List,media,entry.kind=="mediafont" and "font" or "statusbar")
            if ok and type(names)=="table" then
                for _,name in ipairs(names) do options[#options+1]=name end
            end
        end
        local current=1
        for i,name in ipairs(options) do if name==ns.db[entry.key] then current=i;break end end
        ns.Set(entry.key,options[((current-1+direction)%#options)+1])
        return
    end
    if entry.kind=="color" then
        if not ColorPickerFrame then return end
        local keys=entry.prefix and {entry.prefix.."Red",entry.prefix.."Green",entry.prefix.."Blue"} or {"red","green","blue"}
        local original={ns.db[keys[1]],ns.db[keys[2]],ns.db[keys[3]]}
        local function apply()
            local r,g,b=ColorPickerFrame:GetColorRGB()
            ns.db[keys[1]],ns.db[keys[2]],ns.db[keys[3]]=r,g,b
            ns.RefreshMeter();ns.RefreshSettings()
        end
        local function cancel()
            ns.db[keys[1]],ns.db[keys[2]],ns.db[keys[3]]=unpack(original)
            ns.RefreshMeter();ns.RefreshSettings()
        end
        if ColorPickerFrame.SetupColorPickerAndShow then
            ColorPickerFrame:SetupColorPickerAndShow({r=original[1],g=original[2],b=original[3],swatchFunc=apply,cancelFunc=cancel})
        else
            ColorPickerFrame:Hide()
            ColorPickerFrame.func=apply;ColorPickerFrame.cancelFunc=cancel
            ColorPickerFrame:SetColorRGB(unpack(original));ColorPickerFrame:Show()
        end
        return
    end
    local v=ns.db[entry.key]
    if entry.kind=="boolean" then v=not v
    elseif entry.kind=="choice" then v=((v-1+direction)%entry.count)+1
    else
        v=math.max(entry.min,math.min(entry.max,v+entry.step*direction))
        v=math.floor(v*100+0.5)/100
    end
    ns.Set(entry.key,v)
end
local function paint()
    local definition=pages[page]
    local groupIndex=groupForPage(page)
    local group=groups[groupIndex]
    frame.heading:SetText(ns.L[definition.key])
    for i,button in ipairs(nav) do
        button.bg:SetVertexColor(i==groupIndex and 0.13 or 0.055,i==groupIndex and 0.21 or 0.075,i==groupIndex and 0.29 or 0.10,1)
    end
    for i,button in ipairs(tabs) do
        local pageIndex=group.pages[i]
        button:SetShown(pageIndex ~= nil)
        if pageIndex then
            button.caption:SetText(ns.L[pages[pageIndex].key])
            button.bg:SetVertexColor(pageIndex==page and 0.15 or 0.08,pageIndex==page and 0.27 or 0.11,pageIndex==page and 0.34 or 0.15,1)
        end
    end
    active=definition.entries
    for i=1,#controls do
        local row,entry=controls[i],active[i]
        if entry then
            row.name:SetText(ns.L[entry.key])
            row.value:SetText(readableValue(entry))
            row.bg:SetVertexColor(i==selected and 0.12 or 0.065,i==selected and 0.19 or 0.085,i==selected and 0.25 or 0.11,1)
            row:Show()
        else row:Hide() end
    end
    frame.preview:SetStatusBarColor(ns.db.red,ns.db.green,ns.db.blue,ns.db.barAlpha)
    frame.lockButton.caption:SetText(ns.db.locked and ns.L.unlockAction or ns.L.lockAction)
    frame.previewButton.caption:SetText(ns.db.test and ns.L.previewOff or ns.L.previewOn)
    local previewTexture=ns.MediaPath("statusbar",ns.db.textureName) or ns.barTextures[ns.db.barTexture] or ns.barTextures[1]
    if frame.preview.currentTexture~=previewTexture then
        frame.preview:SetStatusBarTexture(previewTexture)
        frame.preview.shade:SetAllPoints(frame.preview:GetStatusBarTexture())
        frame.preview.currentTexture=previewTexture
    end
    frame.preview.value:SetText(ns.L[({"solid","gradient","glass"})[ns.db.style]].."   78%")
    if ns.db.style == 2 and frame.preview.shade.SetGradient and CreateColor then
        frame.preview.shade:SetVertexColor(1,1,1,1)
        frame.preview.shade:SetGradient("VERTICAL",CreateColor(0,0,0,0.4),CreateColor(1,1,1,0.18))
    else
        frame.preview.shade:SetVertexColor(1,1,1,ns.db.style==3 and 0.16 or 0)
    end
    if frame.EnableGamePadButton then
        frame:EnableGamePadButton(ns.db.padNavigation and frame:IsShown() and not InCombatLockdown())
    end
end
function ns.RefreshSettings() if frame then paint() end end
local function choosePage(index)
    page=((index-1)%#pages)+1
    selected=1
    paint()
end
function ns.CreateSettings()
    frame=CreateFrame("Frame","NeonOmenRebornSettings",UIParent)
    frame:SetSize(840,570);frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG");frame:SetClampedToScreen(true)
    frame:SetMovable(true);frame:EnableMouse(true);frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart",frame.StartMoving);frame:SetScript("OnDragStop",frame.StopMovingOrSizing)
    local shell=box(frame,{1,1,1,1})
    shell:SetTexture("Interface\\AddOns\\NeonOmenReborn\\Media\\Panel")
    if shell.SetTextureSliceMargins and Enum and Enum.UITextureSliceMode then
        shell:SetTextureSliceMargins(24,24,24,24)
        shell:SetTextureSliceMode(Enum.UITextureSliceMode.Stretched)
    end
    local sidebar=CreateFrame("Frame",nil,frame); sidebar:SetPoint("TOPLEFT");sidebar:SetPoint("BOTTOMLEFT");sidebar:SetWidth(210)
    box(sidebar,{0.022,0.031,0.046,1})
    local brand=label(sidebar,"NEONOMEN","GameFontNormalLarge");brand:SetPoint("TOPLEFT",20,-26)
    local sub=label(sidebar,ns.L.title,"GameFontDisableSmall");sub:SetPoint("TOPLEFT",20,-53)
    frame.heading=label(frame,"","GameFontNormalLarge");frame.heading:SetPoint("TOPLEFT",240,-33)
    local desc=label(frame,ns.L.subtitle,"GameFontDisableSmall");desc:SetPoint("TOPLEFT",240,-60)
    local close=smallButton(frame,"×")
    close:SetSize(28,26);close:SetPoint("TOPRIGHT",-14,-14)
    close:SetScript("OnClick",function() frame:Hide() end)
    for i,definition in ipairs(groups) do
        local b=CreateFrame("Button",nil,sidebar)
        b:SetSize(190,36);b:SetPoint("TOPLEFT",10,-85-(i-1)*42)
        b.bg=box(b,{0.055,0.075,0.10,1})
        b.text=label(b,ns.L[definition.key]);b.text:SetPoint("LEFT",14,0)
        b:SetScript("OnClick",function() choosePage(definition.pages[1]) end)
        nav[i]=b
    end
    for i=1,5 do
        local tab=smallButton(frame,"")
        tab:SetSize(108,25);tab:SetPoint("TOPLEFT",240+(i-1)*112,-87)
        tab.caption:SetWidth(100)
        tab:SetScript("OnClick",function()
            local group=groups[groupForPage(page)]
            if group.pages[i] then choosePage(group.pages[i]) end
        end)
        tabs[i]=tab
    end
    local section=CreateFrame("Frame",nil,frame)
    section:SetPoint("TOPLEFT",230,-124);section:SetSize(580,326)
    box(section,{0.052,0.068,0.09,1})
    for i=1,5 do
        local row=CreateFrame("Button",nil,section)
        row:SetSize(556,50);row:SetPoint("TOPLEFT",12,-12-(i-1)*60)
        row.bg=box(row,{0.065,0.085,0.11,1})
        row.name=label(row,"");row.name:SetPoint("LEFT",14,0)
        row.value=label(row,"");row.value:SetPoint("RIGHT",-56,0);row.value:SetJustifyH("RIGHT")
        local previous=smallButton(row,"‹")
        previous:SetSize(24,26);previous:SetPoint("RIGHT",-27,0)
        previous:SetScript("OnClick",function() selected=i;adjust(active[i],-1) end)
        local nextButton=smallButton(row,"›")
        nextButton:SetSize(24,26);nextButton:SetPoint("RIGHT",-2,0)
        nextButton:SetScript("OnClick",function() selected=i;adjust(active[i],1) end)
        row:SetScript("OnClick",function() selected=i;adjust(active[i],1) end)
        controls[i]=row
    end
    frame.preview=CreateFrame("StatusBar",nil,frame)
    frame.preview:SetPoint("TOPLEFT",242,-468);frame.preview:SetSize(556,25)
    frame.preview:SetStatusBarTexture(white);frame.preview:SetMinMaxValues(0,100);frame.preview:SetValue(78)
    box(frame.preview,{0.10,0.13,0.16,0.8})
    frame.preview.shade=frame.preview:CreateTexture(nil,"ARTWORK")
    frame.preview.shade:SetTexture(white);frame.preview.shade:SetAllPoints(frame.preview:GetStatusBarTexture())
    frame.preview.value=label(frame.preview,"","GameFontHighlightSmall")
    frame.preview.value:SetPoint("LEFT",8,0)
    frame.lockButton=smallButton(frame,"")
    frame.lockButton:SetSize(176,25);frame.lockButton:SetPoint("TOPLEFT",242,-508)
    frame.lockButton:SetScript("OnClick",function() ns.Set("locked",not ns.db.locked) end)
    frame.previewButton=smallButton(frame,"")
    frame.previewButton:SetSize(176,25);frame.previewButton:SetPoint("LEFT",frame.lockButton,"RIGHT",12,0)
    frame.previewButton:SetScript("OnClick",function() ns.Set("test",not ns.db.test) end)
    local reset=smallButton(frame,ns.L.resetPosition)
    reset:SetSize(176,25);reset:SetPoint("LEFT",frame.previewButton,"RIGHT",12,0)
    reset:SetScript("OnClick",function() ns.ResetMeter() end)
    local hint=label(frame,ns.L.padHint,"GameFontDisableSmall")
    hint:SetPoint("BOTTOMLEFT",242,12);hint:SetWidth(556)
    frame:SetScript("OnGamePadButtonDown",function(_,button)
        if not ns.db.padNavigation or InCombatLockdown() then return end
        if button=="PADDUP" then selected=((selected-2)%#active)+1;paint()
        elseif button=="PADDDOWN" then selected=(selected%#active)+1;paint()
        elseif button=="PADDLEFT" then adjust(active[selected],-1)
        elseif button=="PADDRIGHT" or button=="PAD1" then adjust(active[selected],1)
        elseif button=="PADLSHOULDER" then choosePage(page-1)
        elseif button=="PADRSHOULDER" then choosePage(page+1)
        elseif button=="PAD2" then frame:Hide() end
    end)
    frame:RegisterEvent("PLAYER_REGEN_DISABLED");frame:RegisterEvent("PLAYER_REGEN_ENABLED")
    frame:SetScript("OnEvent",function() paint() end)
    frame:SetScript("OnShow",function() paint() end)
    frame:SetScript("OnHide",function(self) if self.EnableGamePadButton then self:EnableGamePadButton(false) end end)
    frame:Hide()
    table.insert(UISpecialFrames,"NeonOmenRebornSettings")
    ns.RegisterSettingsCategory()
    ns.RefreshSettings()
end
function ns.ToggleSettings()
    if not frame then return end
    if frame:IsShown() then frame:Hide() else frame:Show() end
end
function ns.RegisterSettingsCategory()
    if not Settings or not Settings.RegisterCanvasLayoutCategory or not Settings.RegisterAddOnCategory then return end
    local panel=CreateFrame("Frame",nil,UIParent)
    local title=label(panel,"NeonOmen Reborn","GameFontNormalLarge")
    title:SetPoint("TOPLEFT",24,-28)
    local button=smallButton(panel,ns.L.openSettings)
    button:SetSize(260,34);button:SetPoint("TOPLEFT",24,-70)
    button:SetScript("OnClick",function() if frame and not frame:IsShown() then frame:Show() end end)
    local ok,category=pcall(Settings.RegisterCanvasLayoutCategory,panel,"NeonOmen Reborn")
    if ok and category then pcall(Settings.RegisterAddOnCategory,category) end
end

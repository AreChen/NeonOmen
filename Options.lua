-- NeonCast-inspired control panel. The core supplies live settings and actions;
-- this module never captures a SavedVariables table before ADDON_LOADED.
local _, ns = ...
local T, W = ns.Theme, ns.Widgets
ns.Options = {}

function ns.Options.Create(api)
    local L = api.L
    ns.ApplyOptionsLocale(L)
    local controls, pages, themed, widgets, presets = {}, {}, {}, {}, {}
    local selected = 1
    local function accent() return api.DB().themeColor end
    local Refresh
    local function surface(parent, color, opacity, edgeAlpha)
        local bg, edge = T.Surface(parent, color, opacity)
        themed[#themed+1] = function()
            local c = accent(); edge:SetVertexColor(c.r, c.g, c.b, edgeAlpha or 0.12)
        end
        return bg, edge
    end
    local function button(parent, text)
        local b = T.Button(parent, text)
        themed[#themed+1] = function() b:Paint(accent()) end
        return b
    end

    local f = CreateFrame("Frame", "OmenReloadedForeverOptionsPanel", UIParent)
    f.name = "NeonOmen"
    f:SetSize(800, 680); f:SetPoint("CENTER")
    f:SetFrameStrata("DIALOG"); f:SetToplevel(true)
    f:SetClampedToScreen(true); f:SetMovable(true); f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:Hide()
    surface(f, T.colors.panel, 0.98, 0.22)
    local shadow = f:CreateTexture(nil, "BACKGROUND", nil, -8)
    shadow:SetTexture("Interface\\AddOns\\NeonOmen\\Media\\NeonGlow")
    shadow:SetPoint("TOPLEFT", -24, 24); shadow:SetPoint("BOTTOMRIGHT", 24, -24)
    shadow:SetVertexColor(0, 0, 0, 0.85)

    local side = CreateFrame("Frame", nil, f)
    side:SetPoint("TOPLEFT"); side:SetPoint("BOTTOMLEFT"); side:SetWidth(172)
    surface(side, {0.018, 0.025, 0.043}, 1, 0.10)
    local brand = W.Label(side, "NEON|cffffffffOMEN|r", 20, -28, 144, nil, "GameFontNormalLarge")
    W.Label(side, L.UI_SUBTITLE, 20, -55, 136, T.colors.muted)
    local divider = T.Texture(side, "BORDER", {1, 1, 1}, 0.05)
    divider:SetPoint("TOPRIGHT", 0, -16); divider:SetPoint("BOTTOMRIGHT", 0, 16); divider:SetWidth(1)
    local hint = W.Label(side, L.UI_LIVE_HINT, 20, -418, 132, T.colors.muted)
    hint:SetWordWrap(true)
    local version = W.Label(side, api.Version(), 20, -642, 132, T.colors.muted)

    local top = T.Texture(f, "ARTWORK", {1, 1, 1}, 1)
    top:SetPoint("TOPLEFT", 190, -1); top:SetPoint("TOPRIGHT", -22, -1); top:SetHeight(1)
    local wash = f:CreateTexture(nil, "BACKGROUND", nil, -1)
    wash:SetPoint("TOPLEFT", 182, -10); wash:SetPoint("BOTTOMRIGHT", f, "TOPRIGHT", -10, -72)
    local title = W.Label(f, "", 194, -25, 500, nil, "GameFontNormalLarge")
    local description = W.Label(f, "", 194, -50, 540, T.colors.muted)
    local close = button(f, "×")
    close:SetSize(28, 28); close:SetPoint("TOPRIGHT", -14, -14)
    close:SetScript("OnClick", function() f:Hide() end)
    W.Tooltip(close, L.MENU_CLOSE)
    themed[#themed+1] = function()
        local c = accent()
        brand:SetTextColor(c.r, c.g, c.b)
        top:SetColorTexture(c.r, c.g, c.b, 0.85)
        T.Gradient(wash, {c.r, c.g, c.b, 0.07}, {c.r, c.g, c.b, 0}, "HORIZONTAL")
    end

    local definitions = {
        {"UI_APPEARANCE", "UI_DESC_APPEARANCE"}, {"UI_LAYOUT", "UI_DESC_LAYOUT"},
        {"UI_DISPLAY", "UI_DESC_DISPLAY"}, {"UI_VISIBILITY", "UI_DESC_VISIBILITY"},
        {"UI_WARNINGS", "UI_DESC_WARNINGS"},
    }
    local function selectPage(index)
        selected = index
        title:SetText(L[definitions[index][1]])
        description:SetText(L[definitions[index][2]])
        for i, page in ipairs(pages) do
            page.scroll:SetShown(i == index)
            page.nav.selected = i == index
            page.nav:Paint(accent())
            page.marker:SetShown(i == index)
        end
    end
    for i, definition in ipairs(definitions) do
        local scroll = CreateFrame("ScrollFrame", "NeonOmenOptionsScroll"..i, f, "UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT", 192, -84); scroll:SetSize(568, 418)
        local content = CreateFrame("Frame", nil, scroll)
        content:SetSize(562, 418); scroll:SetScrollChild(content)
        local scrollbar=scroll.ScrollBar or _G["NeonOmenOptionsScroll"..i.."ScrollBar"]
        if scrollbar then
            scrollbar:SetWidth(8)
            if scrollbar.ScrollUpButton then scrollbar.ScrollUpButton:Hide() end
            if scrollbar.ScrollDownButton then scrollbar.ScrollDownButton:Hide() end
            local thumb=scrollbar:GetThumbTexture()
            if thumb then
                thumb:SetTexture("Interface\\Buttons\\WHITE8x8");thumb:SetSize(4,28)
                themed[#themed+1]=function() local c=accent();thumb:SetVertexColor(c.r,c.g,c.b,0.65) end
            end
        end
        local nav = button(side, "")
        nav:SetSize(156, 40); nav:SetPoint("TOPLEFT", 8, -104-(i-1)*50)
        W.Label(nav, string.format("%02d", i), 12, -14, 22, T.colors.muted)
        nav.caption:ClearAllPoints(); nav.caption:SetPoint("LEFT", 40, 0)
        nav:SetText(L[definition[1]])
        local marker = T.Texture(nav, "ARTWORK", {1, 1, 1}, 1)
        marker:SetPoint("TOPLEFT", 1, -9); marker:SetPoint("BOTTOMLEFT", 1, 9); marker:SetWidth(2)
        themed[#themed+1] = function()
            local c = accent(); marker:SetColorTexture(c.r, c.g, c.b, 1)
        end
        nav:SetScript("OnClick", function() selectPage(i) end)
        pages[i] = {scroll=scroll, content=content, nav=nav, marker=marker, cursor=0}
    end

    local function card(page, heading)
        local c = CreateFrame("Frame", nil, page.content)
        c:SetPoint("TOPLEFT", 0, page.cursor); c:SetSize(562, 100)
        surface(c, T.colors.card, 0.96, 0.10)
        W.Label(c, heading, 18, -15, 520, {0.65, 0.72, 0.82})
        local line = T.Texture(c, "BORDER", {1, 1, 1}, 0.06)
        line:SetPoint("TOPLEFT", 18, -35); line:SetPoint("TOPRIGHT", -18, -35); line:SetHeight(1)
        c.cursor = -43
        function c:Add(row)
            row:SetPoint("TOPLEFT", 0, self.cursor)
            self.cursor = self.cursor - row:GetHeight()
            widgets[#widgets+1] = row
            return row
        end
        function c:Finish()
            local height = -self.cursor+12
            self:SetHeight(height); page.cursor = page.cursor-height-12
            page.content:SetHeight(math.max(418, -page.cursor))
        end
        return c
    end
    local function changed()
        api.ApplyFrameSettings(); api.ApplyTheme(); api.RequestRefresh()
        if Refresh then Refresh() end
    end
    local function openColor(key)
        if not ColorPickerFrame then return end
        local c = api.DB()[key]
        local original = {r=c.r, g=c.g, b=c.b}
        local function apply(r, g, b) api.DB()[key]={r=r,g=g,b=b}; changed() end
        local function update() local r,g,b=ColorPickerFrame:GetColorRGB(); apply(r,g,b) end
        local function cancel() apply(original.r, original.g, original.b) end
        if ColorPickerFrame.SetupColorPickerAndShow then
            ColorPickerFrame:SetupColorPickerAndShow({r=c.r,g=c.g,b=c.b,swatchFunc=update,cancelFunc=cancel})
        else
            ColorPickerFrame:Hide(); ColorPickerFrame.hasOpacity=false
            ColorPickerFrame.opacityFunc=nil; ColorPickerFrame.func=update; ColorPickerFrame.cancelFunc=cancel
            ColorPickerFrame:SetColorRGB(c.r,c.g,c.b); ColorPickerFrame:Show()
        end
        ColorPickerFrame:SetFrameStrata("FULLSCREEN_DIALOG")
    end
    local function swatch(parent, key)
        local b = button(parent, "")
        b:SetSize(24, 24); b:SetPoint("RIGHT", parent, "RIGHT", -68, 0)
        local fill = T.Texture(b, "ARTWORK", {1,1,1}, 1)
        fill:SetPoint("TOPLEFT", 4, -4); fill:SetPoint("BOTTOMRIGHT", -4, 4)
        themed[#themed+1] = function()
            local c = api.DB()[key]; fill:SetColorTexture(c.r,c.g,c.b,1)
        end
        b:SetScript("OnClick", function() openColor(key) end)
        controls[key] = b
        W.Tooltip(b, L.UI_CUSTOM_COLOR)
        return b
    end
    local function check(c, key, label, after, colorKey)
        local row = W.Switch(c, label or L[key], function() return api.DB()[key] end,
            function(on)
                api.DB()[key]=on
                if after then after() end
                changed()
            end, accent, colorKey)
        if colorKey then swatch(row, colorKey) end
        controls[key] = c:Add(row)
        return row
    end
    local function checks(c, entries)
        for _, entry in ipairs(entries) do check(c, entry[1], L[entry[2]]) end
    end
    local function slider(c, key, label, lo, hi, step, format, after)
        local row = W.Slider(c, label, lo, hi, step, function() return api.DB()[key] end,
            function(value)
                api.DB()[key]=value
                if after then after() end
                changed()
            end, accent, format)
        controls[key] = c:Add(row)
        return row
    end
    local function percent(value) return string.format("%d%%", math.floor(value*100+0.5)) end

    local palette = card(pages[1], L.UI_THEME)
    for i, preset in ipairs(T.presets) do
        local b = button(palette, "")
        b:SetSize(32, 32); b:SetPoint("TOPLEFT", 18+(i-1)*42, -50)
        local fill=T.Texture(b,"ARTWORK",{preset.r,preset.g,preset.b},1)
        fill:SetPoint("TOPLEFT",5,-5);fill:SetPoint("BOTTOMRIGHT",-5,5)
        b:SetScript("OnClick",function()
            api.DB().themeColor={r=preset.r,g=preset.g,b=preset.b};changed()
        end)
        presets[i] = b
        W.Tooltip(b, L[preset.key])
        themed[#themed+1] = function()
            local c=accent()
            b.selected=math.abs(c.r-preset.r)+math.abs(c.g-preset.g)+math.abs(c.b-preset.b)<0.001
            b:Paint(c)
        end
    end
    local custom = button(palette, L.UI_CUSTOM_COLOR)
    custom:SetSize(160, 30); custom:SetPoint("TOPRIGHT", -18, -51)
    custom:SetScript("OnClick", function() openColor("themeColor") end)
    controls.themeColor = custom
    palette.cursor=-96; palette:Finish()

    local material = card(pages[1], L.UI_MATERIAL)
    check(material,"showGlow",L.OPT_GLOW)
    slider(material,"glowIntensity",L.OPT_GLOW_INTENSITY,0,1,0.05,percent)
    slider(material,"backgroundOpacity",L.OPT_BACKGROUND_OPACITY,0,1,0.05,percent)
    slider(material,"alpha",L.OPT_ALPHA,0.2,1,0.05,percent)
    material:Finish()
    local colors = card(pages[1], L.UI_COLORS)
    check(colors,"useClassColors",L.OPT_CLASS_COLORS)
    check(colors,"useMyBarColor",L.OPT_MY_COLOR,nil,"myBarColor")
    check(colors,"useTankBarColor",L.OPT_TANK_COLOR,nil,"tankBarColor")
    check(colors,"usePetBarColor",L.OPT_PET_COLOR,nil,"petBarColor")
    local aggro = CreateFrame("Frame",nil,colors);aggro:SetSize(562,36)
    W.Label(aggro,L.OPT_AGGRO_COLOR,18,-9,420);swatch(aggro,"aggroBarColor")
    colors:Add(aggro);colors:Finish()

    local geometry = card(pages[2], L.UI_GEOMETRY)
    slider(geometry,"width",L.UI_WIDTH,100,600,1,nil,api.ApplyWidth)
    slider(geometry,"frameHeight",L.UI_WINDOW_HEIGHT,60,900,1,nil,function() if not api.DB().autoCollapse then api.Frame:SetHeight(api.DB().frameHeight) end end)
    slider(geometry,"height",L.OPT_BAR_HEIGHT,10,40,1)
    slider(geometry,"spacing",L.UI_SPACING,0,10,1)
    slider(geometry,"numBars",L.OPT_NUM_BARS,1,40,1)
    slider(geometry,"scale",L.OPT_SCALE,0.5,2,0.05,percent)
    geometry:Finish()
    local behavior = card(pages[2], L.UI_BEHAVIOR)
    check(behavior,"locked",L.OPT_LOCKED)
    check(behavior,"clickThrough",L.OPT_CLICK_THROUGH)
    check(behavior,"autoCollapse",L.OPT_AUTO_COLLAPSE,function()
        if not api.DB().autoCollapse then api.Frame:SetHeight(api.DB().frameHeight) end
    end)
    check(behavior,"growUp",L.OPT_GROW_UP)
    behavior:Finish()

    local display = card(pages[3], L.SEC_DISPLAY)
    checks(display, {
        {"showPets","OPT_SHOW_PETS"},{"useFocus","OPT_USE_FOCUS"},
        {"alwaysShowSelf","OPT_ALWAYS_SHOW_SELF"},{"showAggroBar","OPT_AGGRO_BAR"},
        {"showValue","OPT_SHOW_VALUE"},{"showTPS","OPT_SHOW_TPS"},
        {"animateBars","OPT_ANIMATE"},{"showTitleBar","OPT_SHOW_TITLE"},
        {"showHeader","OPT_SHOW_HEADER"},{"showTargetInTitle","OPT_TARGET_TITLE"},
        {"showMarkers","OPT_SHOW_MARKERS"},
    })
    display:Finish()
    local visibility = card(pages[4], L.UI_GROUPS)
    checks(visibility, {
        {"showInCombat","OPT_COMBAT"},{"showOutOfCombat","OPT_OUT_OF_COMBAT"},
        {"showSolo","OPT_SHOW_SOLO"},{"showWithPet","OPT_SHOW_WITH_PET"},
        {"showInParty","OPT_SHOW_PARTY"},{"showInRaid","OPT_SHOW_RAID"},
        {"hideWhileResting","OPT_HIDE_RESTING"},{"hideInPVP","OPT_HIDE_PVP"},
    })
    visibility:Finish()
    local classes = card(pages[4], L.SEC_CLASSES)
    controls.hiddenClasses = {}
    for i, token in ipairs(api.Classes) do
        local name=(LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[token]) or token
        local b=button(classes,name)
        b:SetSize(166,30);b:SetPoint("TOPLEFT",18+((i-1)%3)*180,-47-math.floor((i-1)/3)*38)
        b:SetScript("OnClick",function()
            api.DB().hiddenClasses[token]=not api.DB().hiddenClasses[token] or nil;changed()
        end)
        themed[#themed+1]=function()
            b.selected=not api.DB().hiddenClasses[token];b:Paint(accent())
            local color=RAID_CLASS_COLORS and RAID_CLASS_COLORS[token]
            if color and b.selected then b.caption:SetTextColor(color.r,color.g,color.b) end
            b:SetAlpha(b.selected and 1 or 0.45)
        end
        controls.hiddenClasses[token]=b
    end
    classes.cursor=-47-math.ceil(#api.Classes/3)*38;classes:Finish()
    local minimap=card(pages[4],L.SEC_MINIMAP)
    check(minimap,"showMinimapButton",L.OPT_SHOW_MINIMAP,api.UpdateMinimap)
    slider(minimap,"minimapOffset",L.OPT_MINIMAP_OFFSET,-20,40,1,nil,api.UpdateMinimap)
    minimap:Finish()

    local alerts = card(pages[5], L.SEC_WARNINGS)
    checks(alerts, {
        {"warnSoundEnabled","OPT_WARN_SOUND"},{"warnFlash","OPT_WARN_FLASH"},
        {"warnShake","OPT_WARN_SHAKE"},{"warnMessage","OPT_WARN_MESSAGE"},
        {"warnAggroTaken","OPT_WARN_AGGRO_TAKEN"},{"disableWarnAsTank","OPT_WARN_TANK"},
    })
    slider(alerts,"yellowThreshold",L.OPT_WARN_THRESHOLD,50,100,1,function(v) return string.format("%d%%",v) end)
    local soundRow=CreateFrame("Frame",nil,alerts);soundRow:SetSize(562,38)
    W.Label(soundRow,L.UI_SOUND,18,-11,260)
    local sound=button(soundRow,"");sound:SetSize(240,26);sound:SetPoint("RIGHT",-18,0)
    sound.caption:SetWidth(220)
    function soundRow.Refresh() sound:SetText(api.SoundLabel(api.DB().warnSound)) end
    alerts:Add(soundRow);controls.warnSound=sound
    local menu=CreateFrame("Frame","NeonOmenSoundMenu",f,"UIDropDownMenuTemplate");menu:Hide()
    UIDropDownMenu_Initialize(menu,function(_,level)
        for _,choice in ipairs(api.Sounds) do
            local info=UIDropDownMenu_CreateInfo()
            info.text=choice.label;info.checked=api.DB().warnSound==choice.id
            info.func=function() api.DB().warnSound=choice.id;api.PlaySound(choice);changed() end
            UIDropDownMenu_AddButton(info,level)
        end
    end,"MENU")
    sound:SetScript("OnClick",function() ToggleDropDownMenu(1,nil,menu,sound,0,0) end)
    local warningRow=CreateFrame("Frame",nil,alerts);warningRow:SetSize(562,42)
    local warnTest=button(warningRow,L.BTN_TEST_WARN)
    warnTest:SetSize(220,28);warnTest:SetPoint("RIGHT",-18,0)
    warnTest:SetScript("OnClick",api.TestWarning);controls.testWarning=warnTest
    alerts:Add(warningRow);alerts:Finish()

    W.Label(f,L.UI_PREVIEW,194,-516,150,T.colors.muted)
    local previewHint=W.Label(f,L.UI_PREVIEW_HINT,344,-516,430,T.colors.muted)
    previewHint:SetJustifyH("RIGHT")
    local preview=CreateFrame("Frame",nil,f)
    preview:SetPoint("TOPLEFT",192,-537);preview:SetSize(586,89)
    local previewBg, previewEdge=surface(preview,T.colors.panel,1,0.28)
    local samples = {
        {unit="party1",name=L.TESTDATA_TANK,isTanking=true,status=3,scaledPct=100,displayPct=100,classToken="WARRIOR"},
        {unit="party2",name=L.TESTDATA_DPS,isTanking=false,status=0,scaledPct=88,displayPct=88,classToken="MAGE"},
        {unit="player",name=L.YOU,isTanking=false,status=0,scaledPct=68,displayPct=68,classToken="MAGE"},
    }
    local sampleTitle=W.Label(preview,L.TITLE,12,-7,560,T.colors.text)
    local previewBars={}
    for i,entry in ipairs(samples) do
        local bar=CreateFrame("StatusBar",nil,preview)
        bar:SetSize(562,16);bar:SetPoint("TOPLEFT",12,-25-(i-1)*19)
        bar:SetStatusBarTexture("Interface\\AddOns\\NeonOmen\\Media\\ThreatGradient")
        bar:SetMinMaxValues(0,100);bar:SetValue(entry.displayPct);T.SkinBar(bar)
        bar.nameText=W.Label(bar,entry.name,6,-2,360)
        bar.pctText=W.Label(bar,string.format("%d%%",entry.displayPct),440,-2,116)
        bar.pctText:SetJustifyH("RIGHT")
        for _,text in ipairs({bar.nameText,bar.pctText}) do text:SetShadowColor(0,0,0,1);text:SetShadowOffset(1,-1) end
        previewBars[i]=bar
    end
    local test=button(f,"");test:SetSize(276,28);test:SetPoint("TOPLEFT",192,-640)
    test:SetScript("OnClick",api.ToggleTestMode);controls.testMode=test
    local reset=button(f,L.BTN_RESET_POSITION);reset:SetSize(276,28);reset:SetPoint("TOPLEFT",502,-640)
    reset:SetScript("OnClick",api.ResetPosition);controls.resetPosition=reset

    Refresh=function()
        for _,paint in ipairs(themed) do paint() end
        for _,widget in ipairs(widgets) do if widget.Refresh then widget.Refresh() end end
        local db=api.DB()
        previewBg:SetVertexColor(T.colors.panel[1],T.colors.panel[2],T.colors.panel[3],db.backgroundOpacity)
        preview:SetAlpha(db.alpha)
        for i,bar in ipairs(previewBars) do
            local r,g,b=api.BarColor(samples[i]);T.PaintBar(bar,r,g,b,db.showGlow,db.glowIntensity)
        end
        test.selected=api.IsTestMode();test:SetText(test.selected and L.UI_TEST_ON or L.UI_TEST_OFF);test:Paint(accent())
        version:SetText(api.Version())
    end
    local function resize()
        f:SetScale(math.max(0.35,math.min(1,(UIParent:GetWidth()-24)/800,(UIParent:GetHeight()-24)/680)))
    end
    f:SetScript("OnShow",function() resize();Refresh() end)
    f:RegisterEvent("UI_SCALE_CHANGED");f:RegisterEvent("DISPLAY_SIZE_CHANGED")
    f:SetScript("OnEvent",function() if f:IsShown() then resize() end end)
    table.insert(UISpecialFrames,"OmenReloadedForeverOptionsPanel")

    -- Keep a system-settings entry without squeezing the full control panel
    -- into Blizzard's canvas. Slash commands and the minimap open it directly.
    if Settings and Settings.RegisterCanvasLayoutCategory then
        local launcher=CreateFrame("Frame","NeonOmenSettingsLauncher",UIParent)
        W.Label(launcher,"NEONOMEN",24,-28,450,T.colors.text,"GameFontNormalLarge")
        W.Label(launcher,L.UI_LAUNCHER_HINT,24,-64,450,T.colors.muted)
        local open=button(launcher,L.UI_OPEN_SETTINGS)
        open:SetSize(240,32);open:SetPoint("TOPLEFT",24,-110);open:SetScript("OnClick",api.Open)
        controls.openSettings=open
        launcher:SetScript("OnShow",Refresh)
        local ok,category=pcall(Settings.RegisterCanvasLayoutCategory,launcher,"NeonOmen")
        if ok and category then Settings.RegisterAddOnCategory(category) end
    end
    selectPage(1);Refresh()
    return {frame=f,controls=controls,pages=pages,presets=presets,previewBars=previewBars,
        SelectPage=selectPage,Refresh=Refresh,
        Show=function()
            if not f:IsShown() then f:ClearAllPoints();f:SetPoint("CENTER",UIParent,"CENTER",0,0);f:Show()
            else Refresh() end
            if f.Raise then f:Raise() end
        end,
    }
end

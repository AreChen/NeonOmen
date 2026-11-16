from pathlib import Path

from lupa.lua51 import LuaRuntime


ROOT = Path(__file__).resolve().parents[1]


def runtime(locale="enUS"):
    lua = LuaRuntime(unpack_returned_tuples=True)
    lua.execute("""
        unpack = unpack
        frames, SlashCmdList, UISpecialFrames = {}, {}, {}
        UIParent = {}
        function GetLocale() return 'enUS' end
        function InCombatLockdown() return combat or false end
        function issecretvalue() return false end
        function UnitExists(unit) return unit == 'player' or unit == 'target' end
        function UnitCanAttack() return true end
        function UnitName() return 'Tester' end
        function UnitGUID(unit) return unit end
        now=1
        function GetTime() return now end
        function UnitClass() return 'Mage', 'MAGE' end
        function IsInRaid() return false end
        function GetNumGroupMembers() return 0 end
        function GetNumSubgroupMembers() return 0 end
        threat=1200
        function UnitDetailedThreatSituation() return false, 1, 67, 67, threat end
        RAID_CLASS_COLORS = { MAGE={r=0.2,g=0.6,b=1} }
        function CreateColor(...) return {...} end
        local M = {}
        local function noop() end
        setmetatable(M,{__index=function() return noop end})
        function CreateFrame(kind,name,parent)
            local f=setmetatable({kind=kind,name=name,parent=parent,scripts={},shown=true}, {__index=M})
            if name then _G[name]=f end
            frames[#frames+1]=f
            return f
        end
        function M:CreateTexture() return CreateFrame('Texture',nil,self) end
        function M:CreateFontString() return CreateFrame('FontString',nil,self) end
        function M:SetScript(key,func) self.scripts[key]=func end
        function M:GetScript(key) return self.scripts[key] end
        function M:SetSize(w,h) self.width=w;self.height=h end
        function M:SetWidth(w) assert(w>=0, 'width must not be negative');self.width=w end
        function M:GetWidth() return self.width end
        function M:SetPoint(...) self.point={...} end
        function M:SetText(s) if rejectSecretText and type(s)=='table' and s.secret then error('restricted') end;self.text=s end
        function M:SetFont(path,size,flags) self.fontPath=path;self.fontSize=size end
        function M:SetFormattedText(fmt,...) if rejectSecretFormat then error('restricted') end;self.formatted={fmt,...} end
        function M:SetVertexColor(...) self.color={...} end
        function M:SetValue(v) if rejectSecretValue and type(v)=='table' and v.secret then error('restricted') end;self.statusValue=v end
        function M:SetStatusBarColor(...) self.barColor={...} end
        function M:SetStatusBarTexture(path) self.barTexture=path end
        function M:SetTexture(path) self.texturePath=path end
        function M:GetStatusBarTexture() self.status=self.status or CreateFrame('Texture');return self.status end
        function M:Show() self.shown=true;if self.scripts.OnShow then self.scripts.OnShow(self) end end
        function M:Hide() self.shown=false;if self.scripts.OnHide then self.scripts.OnHide(self) end end
        function M:SetShown(v) if v then self:Show() else self:Hide() end end
        function M:IsShown() return self.shown end
        function M:EnableGamePadButton(v) self.padEnabled=v end
        function M:GetPoint() return 'CENTER',UIParent,'CENTER',180,0 end
        ns = {}
    """)
    lua.execute(f"function GetLocale() return {locale!r} end")
    for file in ("Core.lua", "Meter.lua", "Settings.lua", "Minimap.lua"):
        lua.execute(f"assert(loadfile({str(ROOT / file)!r}))('NeonOmenReborn', ns)")
    lua.execute("frames[1].scripts.OnEvent(frames[1], 'ADDON_LOADED', 'NeonOmenReborn')")
    return lua


def test_startup_meter_and_persisted_settings():
    lua = runtime()
    lua.execute("""
        assert(NeonOmenRebornDB.width == 280)
        assert(NeonOmenRebornMeter.width == 280)
        ns.Set('width', 360)
        assert(NeonOmenRebornDB.width == 360 and NeonOmenRebornMeter.width == 360)
        ns.Set('test', true)
        assert(not NeonOmenRebornMeter.empty.shown)
        ns.Set('test', false)
        assert(not NeonOmenRebornMeter.empty.shown)
        UnitCanAttack=function() return false end
        ns.RefreshMeter()
        assert(NeonOmenRebornMeter.empty.shown)
    """)


def test_styles_and_colors_are_adjustable():
    lua = runtime()
    lua.execute("""
        ns.Set('style',1)
        SlashCmdList.NEONOMENREBORN()
        local settings=NeonOmenRebornSettings
        settings.scripts.OnGamePadButtonDown(settings, 'PADDRIGHT')
        assert(NeonOmenRebornDB.style == 2)
        settings.scripts.OnGamePadButtonDown(settings, 'PADDRIGHT')
        assert(NeonOmenRebornDB.style == 3)
        settings.scripts.OnGamePadButtonDown(settings, 'PADRSHOULDER')
        settings.scripts.OnGamePadButtonDown(settings, 'PADRSHOULDER')
        settings.scripts.OnGamePadButtonDown(settings, 'PADDRIGHT')
        assert(NeonOmenRebornDB.red == 0.35)
    """)


def test_threat_rate_visibility_and_filters():
    lua = runtime()
    lua.execute("""
        now=1;threat=1200;ns.RefreshMeter()
        now=3;threat=1600;ns.RefreshMeter()
        local found=false
        for _,f in ipairs(frames) do
            if f.kind=='FontString' and f.text=='200/s  67%' then found=true end
        end
        assert(found, 'expected measured TPS')
        ns.Set('showSolo',false)
        assert(not NeonOmenRebornMeter.shown)
        ns.Set('showSolo',true)
        NeonOmenRebornDriver.scripts.OnUpdate(NeonOmenRebornDriver,0.3)
        assert(NeonOmenRebornMeter.shown)
        ns.Set('hide_MAGE',true)
        ns.Set('showSelf',false)
        assert(NeonOmenRebornMeter.empty.shown)
        ns.Set('showSelf',true)
        assert(not NeonOmenRebornMeter.empty.shown)
        SlashCmdList.NEONOMENREBORN('lock')
        ns.Set('clickThrough',true)
        SlashCmdList.NEONOMENREBORN('unlock')
        assert(not NeonOmenRebornDB.locked and not NeonOmenRebornDB.clickThrough)
    """)


def test_opt_in_gamepad_navigation_and_combat_release():
    lua = runtime()
    lua.execute("""
        ns.Set('style',1)
        SlashCmdList.NEONOMENREBORN()
        local settings=NeonOmenRebornSettings
        assert(settings.shown and settings.padEnabled)
        ns.Set('padNavigation', false)
        assert(not settings.padEnabled)
        ns.Set('padNavigation', true)
        assert(settings.padEnabled)
        settings.scripts.OnGamePadButtonDown(settings, 'PADDRIGHT')
        assert(NeonOmenRebornDB.style == 2)
        settings.scripts.OnGamePadButtonDown(settings, 'PADRSHOULDER')
        settings.scripts.OnGamePadButtonDown(settings, 'PADDRIGHT')
        assert(NeonOmenRebornDB.width == 300)
        combat=true;settings.scripts.OnEvent(settings, 'PLAYER_REGEN_DISABLED')
        assert(not settings.padEnabled)
        settings.scripts.OnGamePadButtonDown(settings, 'PADDRIGHT')
        assert(NeonOmenRebornDB.width == 300)
        combat=false;settings.scripts.OnEvent(settings, 'PLAYER_REGEN_ENABLED')
        assert(settings.padEnabled)
        settings.scripts.OnGamePadButtonDown(settings, 'PAD2')
        assert(not settings.shown and not settings.padEnabled)
    """)


def test_raid_player_retention_and_missing_threat_amount():
    lua = runtime()
    lua.execute("""
        IsInRaid=function() return true end
        GetNumGroupMembers=function() return 2 end
        UnitExists=function(u) return u=='target' or u=='raid1' or u=='raid2' end
        UnitIsUnit=function(u,v) return u=='raid2' and v=='player' end
        UnitName=function(u) return u end
        UnitGUID=function(u) return u end
        UnitDetailedThreatSituation=function(u)
            if u=='raid1' then return true,3,100,100,1000 end
            return false,1,40,40,nil
        end
        ns.Set('hide_MAGE',true)
        ns.Set('showValue',true)
        ns.RefreshMeter()
        local found=false
        for _,f in ipairs(frames) do
            if f.kind=='FontString' and f.text=='raid2' then found=true end
        end
        assert(found, 'raid player retained even when class hidden and amount unavailable')
    """)


def test_restricted_threat_is_passed_to_secure_widgets_without_comparison():
    lua = runtime()
    lua.execute("""
        local secretPct={secret=true}
        local secretName={secret=true}
        issecretvalue=function(v) return type(v)=='table' and v.secret == true end
        UnitDetailedThreatSituation=function() return false,1,secretPct,nil,nil end
        UnitName=function(u) if u=='player' then return secretName end return 'target' end
        ns.Set('showTPS',false)
        ns.RefreshMeter()
        assert(not NeonOmenRebornMeter.empty.shown, 'restricted threat must retain the row')
        local bar,name,value=false,false,false
        for _,f in ipairs(frames) do
            if f.kind=='StatusBar' and f.statusValue==secretPct then bar=true end
            if f.kind=='FontString' and f.text==secretName then name=true end
            if f.kind=='FontString' and rawget(f,'formatted') and f.formatted[2]==secretPct then value=true end
        end
        assert(bar and name and value, 'restricted values must reach supported display widgets')
    """)


def test_warning_only_fires_again_after_threat_drops_below_threshold():
    lua = runtime()
    lua.execute("""
        local pct=90
        UnitDetailedThreatSituation=function() return false,1,pct,pct,1200 end
        local count=0
        UIErrorsFrame={AddMessage=function() count=count+1 end}
        ns.Set('warningCooldown',1)
        ns.RefreshMeter()
        assert(count==1, 'crossing the threshold warns')
        now=10; ns.RefreshMeter()
        assert(count==1, 'staying above the threshold should not repeat')
        pct=20; now=12; ns.RefreshMeter()
        pct=90; now=15; ns.RefreshMeter()
        assert(count==2, 'crossing again after dropping should warn again')
    """)


def test_damage_player_receives_aggro_warning_when_tank_suppression_enabled():
    lua=runtime()
    lua.execute("""
        local tanking=false
        UnitGroupRolesAssigned=function() return 'DAMAGER' end
        UnitIsUnit=function(a,b) return a=='targettarget' and b=='player' and tanking end
        UnitDetailedThreatSituation=function() return tanking,3,100,100,1200 end
        local alerts=0
        UIErrorsFrame={AddMessage=function() alerts=alerts+1 end}
        ns.Set('suppressTank',true);ns.Set('warningThreshold',100);ns.Set('warningCooldown',1)
        ns.RefreshMeter();alerts=0
        now=now+2;tanking=true;ns.RefreshMeter()
        assert(alerts==1,'a damage player must be warned on gaining aggro')
    """)


def test_assigned_tank_still_has_warnings_suppressed():
    lua=runtime()
    lua.execute("""
        UnitGroupRolesAssigned=function() return 'TANK' end
        UnitDetailedThreatSituation=function() return false,2,90,90,1200 end
        local alerts=0
        UIErrorsFrame={AddMessage=function() alerts=alerts+1 end}
        ns.Set('suppressTank',true);ns.RefreshMeter()
        assert(alerts==0,'assigned tanks should still be suppressed')
    """)


def test_role_color_override_can_be_disabled_to_use_class_color():
    lua=runtime()
    lua.execute("""
        ns.Set('useSelfColor',false)
        ns.Set('classColors',true)
        ns.RefreshMeter()
        local matched=false
        for _,f in ipairs(frames) do
            local c=rawget(f,'barColor')
            if f.kind=='StatusBar' and c and c[1]==0.2 and c[2]==0.6 and c[3]==1 then matched=true end
        end
        assert(matched, 'player uses class color when custom override is off')
    """)


def test_pull_boundary_row_uses_player_scaled_and_raw_threat():
    lua=runtime()
    lua.execute("""
        UnitDetailedThreatSituation=function() return false,1,50,65,650 end
        ns.Set('showAggroBar',true)
        ns.RefreshMeter()
        local found=false
        for _,f in ipairs(frames) do
            if f.kind=='FontString' and f.text=='Aggro pull · 130%' then found=true end
        end
        assert(found, 'show the pull boundary inferred from readable API values')
        ns.Set('showAggroBar',false)
        local visible=false
        for _,f in ipairs(frames) do
            if f.kind=='FontString' and f.text=='Aggro pull · 130%' and f.parent.shown then visible=true end
        end
        assert(not visible, 'the boundary is optional')
    """)


def test_settings_groups_show_related_subpages():
    lua=runtime()
    lua.execute("""
        SlashCmdList.NEONOMENREBORN()
        local button
        for _,f in ipairs(frames) do
            local label=rawget(f,'text')
            if f.kind=='Button' and type(label)=='table' and rawget(label,'text')=='Alerts' then button=f;break end
        end
        assert(button and button.shown, 'alerts must have a visible navigation group')
        button.scripts.OnClick(button)
        assert(NeonOmenRebornSettings.heading.text=='Alerts', 'group opens its main page')
        local tab
        for _,f in ipairs(frames) do
            local caption=rawget(f,'caption')
            if f.kind=='Button' and type(caption)=='table' and rawget(caption,'text')=='Alert options' and f.shown then tab=f end
        end
        assert(tab, 'related settings are accessible as a visible subpage')
        tab.scripts.OnClick(tab)
        assert(NeonOmenRebornSettings.heading.text=='Alert options')
    """)


def test_alert_sound_can_be_previewed_without_combat():
    lua=runtime()
    lua.execute("""
        local played
        SOUNDKIT={RAID_WARNING=99}
        PlaySound=function(id) played=id end
        ns.Set('warningSound',true)
        ns.TestAlert()
        assert(played==99, 'preview plays the selected warning sound')
        assert(NeonOmenRebornMeter.flash.shown, 'preview shows the configured flash')
    """)


def test_bar_glow_tracks_its_color_and_can_be_disabled():
    lua=runtime()
    lua.execute("""
        ns.Set('test',true)
        local row
        for _,f in ipairs(frames) do
            if f.kind=='StatusBar' and rawget(f,'glow') then row=f;break end
        end
        assert(row and row.glow.color[4]>0, 'threat bar has a visible glow')
        ns.Set('barGlow',false)
        assert(row.glow.color[4]==0, 'bar glow can be disabled independently')
    """)


def test_preview_shows_example_tps_instead_of_missing_data():
    lua=runtime()
    lua.execute("""
        ns.Set('test',true)
        local found=false
        for _,f in ipairs(frames) do
            if f.kind=='FontString' and type(rawget(f,'text'))=='string' and f.text:find('/s',1,true) and not f.text:find('%-%-/s') then found=true end
        end
        assert(found, 'preview should illustrate TPS formatting')
    """)


def test_narrow_window_fits_long_threat_values():
    lua=runtime()
    lua.execute("""
        UnitDetailedThreatSituation=function() return false,1,67,67,1234567 end
        ns.Set('width',160)
        ns.Set('showValue',true)
        ns.Set('showTPS',true)
        ns.RefreshMeter()
        local found=false
        for _,f in ipairs(frames) do
            if f.kind=='FontString' and type(rawget(f,'text'))=='string' and f.text:find('1.2M',1,true) then found=true end
        end
        assert(found, 'large threat values should be shortened')
    """)


def test_settings_footer_unlocks_and_toggles_preview():
    lua=runtime()
    lua.execute("""
        SlashCmdList.NEONOMENREBORN()
        local f=NeonOmenRebornSettings
        assert(rawget(f,'lockButton') and rawget(f,'previewButton'), 'window controls are available on every page')
        f.lockButton.scripts.OnClick(f.lockButton)
        assert(NeonOmenRebornDB.locked)
        f.lockButton.scripts.OnClick(f.lockButton)
        assert(not NeonOmenRebornDB.locked)
        f.previewButton.scripts.OnClick(f.previewButton)
        assert(NeonOmenRebornDB.test)
        f.previewButton.scripts.OnClick(f.previewButton)
        assert(not NeonOmenRebornDB.test)
    """)


def test_addon_appears_in_blizzard_settings_when_available():
    lua=runtime()
    lua.execute("""
        local category,registered
        Settings={
            RegisterCanvasLayoutCategory=function(panel,name) category={panel=panel,name=name};return category end,
            RegisterAddOnCategory=function(value) registered=value end,
        }
        ns.RegisterSettingsCategory()
        assert(registered==category and category.name=='NeonOmen Reborn')
    """)


def test_hidden_meter_does_not_poll_threat():
    lua=runtime()
    lua.execute("""
        ns.Set('showSolo',false)
        local calls=0
        UnitDetailedThreatSituation=function() calls=calls+1;return false,1,67,67,1200 end
        for i=1,20 do NeonOmenRebornDriver.scripts.OnUpdate(NeonOmenRebornDriver,0.25) end
        assert(calls==0, 'hidden meter should not query threat')
        ns.Set('showSolo',true)
        assert(calls>0, 'showing meter resumes threat updates')
    """)


def test_alert_can_shake_meter_without_moving_world_frame():
    lua=runtime()
    lua.execute("""
        ns.Set('warningShake',true)
        ns.TestAlert()
        assert(NeonOmenRebornMeter.shakeTime and NeonOmenRebornMeter.shakeTime>0)
        NeonOmenRebornDriver.scripts.OnUpdate(NeonOmenRebornDriver,0.2)
        NeonOmenRebornDriver.scripts.OnUpdate(NeonOmenRebornDriver,1)
        assert(NeonOmenRebornMeter.shakeTime==0, 'shake ends and restores the meter')
    """)


def test_minimap_shift_click_toggles_meter_without_opening_settings():
    lua=runtime()
    lua.execute("""
        IsShiftKeyDown=function() return true end
        local button=NeonOmenRebornMinimapButton
        local wasShown=NeonOmenRebornMeter.shown
        button.scripts.OnClick(button,'LeftButton')
        assert(NeonOmenRebornMeter.shown~=wasShown)
        assert(not NeonOmenRebornSettings.shown)
        button.scripts.OnClick(button,'LeftButton')
        assert(NeonOmenRebornMeter.shown==wasShown)
    """)


def test_warning_flash_uses_four_screen_edges():
    lua=runtime()
    lua.execute("""
        ns.Set('warningFlash',true)
        ns.TestAlert()
        local flash=NeonOmenRebornMeter.flash
        assert(flash.shown and #flash.edges==4)
        flash.scripts.OnUpdate(flash,1)
        assert(not flash.shown)
    """)


def test_threat_names_show_tank_pet_and_status_markers():
    lua=runtime()
    lua.execute("""
        UnitExists=function(unit) return unit=='target' or unit=='player' or unit=='pet' end
        UnitName=function(unit) return unit=='pet' and 'Wolf' or 'Tester' end
        UnitDetailedThreatSituation=function(unit) return unit=='pet',2,80,80,1200 end
        UnitIsDeadOrGhost=function(unit) return unit=='pet' end
        ns.Set('showMarker',true);ns.RefreshMeter()
        local found=false
        for _,f in ipairs(frames) do
            if f.kind=='FontString' and type(rawget(f,'text'))=='string'
                and f.text:find('Wolf',1,true) and f.text:find('[T]',1,true)
                and f.text:find(ns.L.petSuffix,1,true) and f.text:find(ns.L.dead,1,true) then found=true end
        end
        assert(found,'pet tank and dead state should be visible')
    """)


def test_threat_transfer_marker_tracks_new_holder():
    lua=runtime()
    lua.execute("""
        local holder='player'
        UnitExists=function(unit) return unit=='target' or unit=='player' or unit=='pet' end
        UnitName=function(unit) return unit=='pet' and 'Wolf' or 'Tester' end
        UnitDetailedThreatSituation=function(unit) return unit==holder,2,80,80,1200 end
        ns.RefreshMeter();holder='pet';now=now+1;ns.RefreshMeter()
        local found=false
        for _,f in ipairs(frames) do
            if f.kind=='FontString' and type(rawget(f,'text'))=='string'
                and f.text:find('Wolf',1,true) and f.text:find('[!]',1,true) then found=true end
        end
        assert(found, 'new threat holder should be flagged')
    """)


def test_restricted_widget_rejection_degrades_without_crashing():
    lua=runtime()
    lua.execute("""
        local secret={secret=true}
        issecretvalue=function(v) return type(v)=='table' and v.secret==true end
        UnitDetailedThreatSituation=function() return false,1,secret,nil,nil end
        UnitName=function(u) if u=='player' then return secret end return 'target' end
        rejectSecretText=true;rejectSecretFormat=true;rejectSecretValue=true
        ns.RefreshMeter()
        assert(not NeonOmenRebornMeter.empty.shown)
    """)


def test_readable_threat_status_can_warn_when_percentage_is_restricted():
    lua=runtime()
    lua.execute("""
        local secret={secret=true}
        issecretvalue=function(v) return type(v)=='table' and v.secret==true end
        local status=0
        UnitDetailedThreatSituation=function() return false,status,secret,nil,nil end
        local count=0
        UIErrorsFrame={AddMessage=function() count=count+1 end}
        ns.RefreshMeter()
        status=1;now=10;ns.RefreshMeter()
        assert(count==1, 'readable threat status should warn if percentage is unavailable')
    """)


def test_threshold_marks_each_bar_without_covering_its_text():
    lua=runtime()
    lua.execute("""
        ns.Set('test',true)
        local row
        for _,f in ipairs(frames) do
            if f.kind=='StatusBar' and rawget(f,'threshold') then row=f;break end
        end
        assert(row and row.threshold.shown, 'threshold marker appears on each bar')
        assert(row.threshold.height<=5, 'marker stays away from the text line')
        ns.Set('showAggroLine',false)
        assert(not row.threshold.shown, 'threshold marker can be disabled')
    """)


def test_chinese_locales_translate_choices_and_preview():
    for locale in ('zhCN','zhTW'):
        lua=runtime(locale)
        lua.execute("""
            assert(type(ns.L.fontSmall)=='string' and ns.L.fontSmall~='Small')
            assert(type(ns.L.textureFlat)=='string' and ns.L.textureFlat~='Flat')
            assert(type(ns.L.soundRaid)=='string' and ns.L.soundRaid~='Raid warning')
            ns.Set('test',true)
            local found=false
            for _,f in ipairs(frames) do
                if f.kind=='FontString' and type(rawget(f,'text'))=='string' and f.text:find(ns.L.sampleTank,1,true) then found=true end
            end
            assert(found, 'preview labels should be localized')
        """)


def test_preview_is_disabled_on_combat_entry():
    lua=runtime()
    lua.execute("""
        ns.Set('test',true)
        assert(NeonOmenRebornDB.test)
        UnitAffectingCombat=function() return true end
        NeonOmenRebornDriver.scripts.OnUpdate(NeonOmenRebornDriver,0.3)
        assert(not NeonOmenRebornDB.test, 'sample values cannot be mistaken for live threat during combat')
        local found=false
        for _,f in ipairs(frames) do
            if f.kind=='FontString' and f.text=='Tester' and f.parent.shown then found=true end
        end
        assert(found, 'real data replaces preview data')
    """)


def test_slash_commands_and_binding_actions_control_the_meter():
    lua=runtime()
    lua.execute("""
        SlashCmdList.NEONOMENREBORN('pets')
        assert(not NeonOmenRebornDB.showPets)
        SlashCmdList.NEONOMENREBORN('focus')
        assert(NeonOmenRebornDB.useFocus)
        SlashCmdList.NEONOMENREBORN('minimap')
        assert(not NeonOmenRebornDB.showMinimap)
        NeonOmenReborn_ToggleFocus()
        assert(not NeonOmenRebornDB.useFocus)
        NeonOmenReborn_TogglePreview()
        assert(NeonOmenRebornDB.test)
    """)


def test_minimap_button_radius_follows_minimap_size():
    lua=runtime()
    lua.execute("""
        Minimap=CreateFrame('Frame')
        Minimap:SetWidth(240)
        ns.db.minimapAngle=0;ns.db.minimapOffset=0
        ns.CreateMinimap()
        local button=NeonOmenRebornMinimapButton
        assert(button.point[4] > 120, 'button should follow the outer rim of a resized minimap')
    """)


def test_shared_media_font_is_used_when_available():
    lua=runtime()
    lua.execute("""
        local media={Fetch=function(_,kind,name) if kind=='font' and name=='Custom' then return 'Fonts/Custom.ttf' end end}
        LibStub=function() return media end
        ns.Set('fontName','Custom')
        ns.RefreshMeter()
        local found=false
        for _,f in ipairs(frames) do
            if f.kind=='FontString' and rawget(f,'fontPath')=='Fonts/Custom.ttf' then found=true end
        end
        assert(found, 'registered shared-media font should be applied')
    """)


def test_shared_media_texture_is_used_when_available():
    lua=runtime()
    lua.execute("""
        local media={Fetch=function(_,kind,name) if kind=='statusbar' and name=='Custom bar' then return 'Textures/Custom.tga' end end}
        LibStub=function() return media end
        ns.Set('textureName','Custom bar')
        ns.RefreshMeter()
        local found=false
        for _,f in ipairs(frames) do
            if f.kind=='StatusBar' and rawget(f,'barTexture')=='Textures/Custom.tga' then found=true end
        end
        assert(found, 'registered shared-media bar texture should be applied')
    """)


def test_bar_highlight_preserves_the_selected_texture_mask():
    lua=runtime()
    lua.execute("""
        ns.Set('barTexture',4);ns.Set('style',2);ns.Set('test',true)
        local found=false
        for _,f in ipairs(frames) do
            if f.kind=='Texture' and rawget(f,'texturePath')==ns.barTextures[4]
                and f.parent and f.parent.kind=='StatusBar' then found=true end
        end
        assert(found, 'the highlight must use the bar mask to keep rounded corners')
    """)


def test_bar_halo_uses_soft_texture_and_respects_glow_setting():
    lua=runtime()
    lua.execute("""
        ns.Set('test',true);ns.Set('barGlow',true);ns.Set('barGlowIntensity',0.3)
        local halo
        for _,f in ipairs(frames) do
            if f.kind=='Texture' and type(rawget(f,'texturePath'))=='string'
                and f.texturePath:find('BarGlow',1,true) then halo=f;break end
        end
        assert(halo and halo.color[4] > 0 and halo.color[4] < 0.5)
        ns.Set('barGlow',false)
        assert(halo.color[4]==0)
    """)


def test_bar_halo_range_and_brightness_are_independent_of_window_glow():
    lua=runtime()
    lua.execute("""
        ns.Set('test',true);ns.Set('barGlow',true);ns.Set('glow',false)
        ns.Set('barGlowIntensity',0.2);ns.Set('barGlowSpread',1)
        local row
        for _,f in ipairs(frames) do if f.kind=='StatusBar' and rawget(f,'glow') then row=f;break end end
        assert(row.glow.color[4]==0.2)
        local offset=row.glow.point[4]
        ns.Set('barGlowSpread',2)
        assert(row.glow.point[4]>offset, 'wider spread should enlarge the halo bounds')
        ns.Set('barGlowIntensity',0.1)
        assert(row.glow.color[4]==0.1)
    """)


def test_existing_glow_settings_are_preserved_during_upgrade():
    lua=runtime()
    lua.execute("""
        NeonOmenRebornDB={glow=false,glowIntensity=0.8}
        ns.InitDB()
        assert(not ns.db.barGlow)
        assert(math.abs(ns.db.barGlowIntensity-0.304)<0.0001)
    """)


def test_profiles_keep_settings_independent_and_preview_disabled():
    lua=runtime()
    lua.execute("""
        ns.Set('width', 360);ns.Set('hide_MAGE',true);ns.Set('test',true)
        ns.SwitchProfile(2)
        assert(ns.db.width==280 and not ns.db.hide_MAGE and not ns.db.test)
        ns.Set('width', 420)
        ns.SwitchProfile(1)
        assert(ns.db.width==360 and ns.db.hide_MAGE and not ns.db.test)
        ns.SwitchProfile(2)
        assert(ns.db.width==420 and not ns.db.hide_MAGE)
    """)

import pytest

from support import addon


@pytest.mark.parametrize("locale", ["enUS", "zhCN", "zhTW"])
def test_settings_tabs_keep_live_samples_separate_from_the_main_meter(locale):
    lua = addon(locale)
    lua.execute('''
        local ui=ns.Options.current
        SlashCmdList.OMENRELOADEDFOREVER('')
        assert(ui.frame:IsShown() and not OmenReloadedForeverFrame:IsShown())
        assert(not ui.controls.testMode.selected)
        for selected,page in ipairs(ui.pages) do
            page.nav.scripts.OnClick(page.nav)
            for i,other in ipairs(ui.pages) do
                assert(other.scroll:IsShown()==(i==selected))
                assert(other.nav.selected==(i==selected))
            end
        end
        ui.controls.showGlow.scripts.OnClick(ui.controls.showGlow)
        assert(not OmenReloadedForeverDB.showGlow)
        for _,bar in ipairs(ui.previewBars) do assert(not bar.neonGlow:IsShown()) end
        assert(not OmenReloadedForeverFrame:IsShown())
        ui.controls.testMode.scripts.OnClick(ui.controls.testMode)
        flush()
        assert(OmenReloadedForeverFrame:IsShown() and ui.controls.testMode.selected)
    ''')


@pytest.mark.parametrize("modern", [True, False])
def test_presets_and_color_picker_apply_and_cancel_to_the_current_settings(modern):
    lua = addon(modern=modern)
    lua.execute('''
        local ui=ns.Options.current
        SlashCmdList.OMENRELOADEDFOREVER('')
        ui.presets[2].scripts.OnClick(ui.presets[2])
        assert(OmenReloadedForeverDB.themeColor.r==0.64)
        assert(ui.presets[2].selected)
        ui.controls.themeColor.scripts.OnClick(ui.controls.themeColor)
        ColorPickerFrame:SetColorRGB(0.3,0.4,0.5)
        if ColorPickerFrame.info then ColorPickerFrame.info.swatchFunc()
        else ColorPickerFrame.func() end
        assert(OmenReloadedForeverDB.themeColor.r==0.3)
        if ColorPickerFrame.info then ColorPickerFrame.info.cancelFunc()
        else ColorPickerFrame.cancelFunc() end
        assert(OmenReloadedForeverDB.themeColor.r==0.64)
        assert(ColorPickerFrame.strata=='FULLSCREEN_DIALOG')
    ''')


def test_opening_settings_is_read_only_and_slider_buttons_update_real_geometry():
    lua = addon(saved="{width=312,height=39,spacing=3,scale=1.15,frameHeight=344}")
    lua.execute('''
        local ui=ns.Options.current
        SlashCmdList.OMENRELOADEDFOREVER('')
        assert(OmenReloadedForeverDB.width==312 and OmenReloadedForeverDB.height==39)
        assert(OmenReloadedForeverDB.scale==1.15 and OmenReloadedForeverDB.frameHeight==344)
        ui.controls.width.plus.scripts.OnClick()
        flush()
        assert(OmenReloadedForeverDB.width==313 and OmenReloadedForeverFrame:GetWidth()==333)
        ui.controls.height.plus.scripts.OnClick()
        assert(OmenReloadedForeverDB.height==40)
        ui.controls.height.plus.scripts.OnClick()
        assert(OmenReloadedForeverDB.height==40)
        ui.controls.hiddenClasses.MAGE.scripts.OnClick()
        assert(OmenReloadedForeverDB.hiddenClasses.MAGE)
        ui.controls.hiddenClasses.MAGE.scripts.OnClick()
        assert(not OmenReloadedForeverDB.hiddenClasses.MAGE)
        ui.controls.warnSound.scripts.OnClick()
        local choice=dropdownEntries[#dropdownEntries]
        choice.func()
        assert(OmenReloadedForeverDB.warnSound=='DUCKY' and playedSound==566121)
        ui.controls.resetPosition.scripts.OnClick()
        flush()
        assert(OmenReloadedForeverDB.width==200 and OmenReloadedForeverDB.frameHeight==200)
    ''')


def test_native_settings_launcher_uses_the_same_combat_gate_and_window():
    lua = addon(native_settings=True)
    lua.execute('''
        local ui=ns.Options.current
        assert(nativeSettingsRegistered and nativeSettingsName=='NeonOmen')
        assert(nativeSettingsPanel~=ui.frame)
        combat=true
        ui.controls.openSettings.scripts.OnClick()
        assert(not ui.frame:IsShown())
        combat=false;dispatch('PLAYER_REGEN_ENABLED');flush()
        assert(ui.frame:IsShown() and ui.frame:GetFrameStrata()=='DIALOG')
        assert(OmenReloadedForeverFrame:GetFrameStrata()=='LOW')
        UIParent:SetSize(1024,600);dispatch('DISPLAY_SIZE_CHANGED')
        assert(ui.frame:GetWidth()*ui.frame.scale<=1000)
        assert(ui.frame:GetHeight()*ui.frame.scale<=576)
        assert(UISpecialFrames[#UISpecialFrames]=='OmenReloadedForeverOptionsPanel')
    ''')


@pytest.mark.parametrize("locale", ["enUS", "zhCN", "zhTW"])
def test_navigation_uses_full_width_labels_and_pages_scroll_without_native_arrows(locale):
    lua = addon(locale)
    lua.execute('''
        local ui=ns.Options.current
        SlashCmdList.OMENRELOADEDFOREVER('')
        for i,page in ipairs(ui.pages) do
            page.nav.scripts.OnClick()
            assert(#page.nav.caption.points==2)
            assert(page.nav.caption.points[1][1]=='LEFT')
            assert(page.nav.caption.points[2][1]=='RIGHT')
            -- Each nav button has one text label, with no narrow numeric field.
            local labels=0
            for _,frame in ipairs(frames) do
                if frame.parent==page.nav and frame.kind=='FontString' then labels=labels+1 end
            end
            assert(labels==1)
            local bar=page.scrollbar
            assert(bar.ScrollUpButton==nil and bar.ScrollDownButton==nil)
            local range=math.max(0,-page.cursor-418)
            page.scroll.scripts.OnMouseWheel(page.scroll,-100)
            assert(page.scroll.verticalScroll==range)
            page.scroll.scripts.OnMouseWheel(page.scroll,100)
            assert(page.scroll.verticalScroll==0)
            if range>0 then
                bar:SetValue(range/2)
                assert(page.scroll.verticalScroll==range/2)
            end
            for otherIndex,other in ipairs(ui.pages) do
                assert(other.scrollbar:IsShown()==(otherIndex==i and -other.cursor>418))
            end
        end
    ''')

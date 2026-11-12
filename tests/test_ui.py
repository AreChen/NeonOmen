import pytest

from support import addon, preview


@pytest.mark.parametrize("locale", ["enUS", "zhCN", "zhTW"])
@pytest.mark.parametrize("modern", [True, False])
def test_toc_load_and_preview_keep_meter_below_system_windows(locale, modern):
    lua = addon(locale, modern=modern)
    preview(lua)
    g = lua.globals()
    assert g.OmenReloadedForeverFrame.GetFrameStrata(g.OmenReloadedForeverFrame) == "LOW"
    assert g.OmenReloadedForeverFrame.toplevel is False
    for i in range(1, 5):
        bar = g[f"OmenReloadedForeverBar{i}"]
        assert bar is not None and bar.shown
        assert bar.GetFrameStrata(bar) == "LOW"
    # The fallback options panel still opens above the meter.
    g.SlashCmdList.OMENRELOADEDFOREVER("")
    assert g.OmenReloadedForeverOptionsPanel.shown
    assert g.OmenReloadedForeverOptionsPanel.strata == "DIALOG"


def test_fill_decorations_hide_at_zero_and_follow_the_native_texture():
    lua = addon()
    preview(lua)
    lua.execute('''
        local bar=OmenReloadedForeverBar1
        bar:SetValue(0)
        assert(not bar.materialTop:IsShown() and not bar.neonGlow:IsShown())
        assert(not bar.neonSheen:IsShown() and not bar.neonShade:IsShown())
        bar:SetValue(45)
        assert(bar.materialTop:IsShown() and bar.neonSheen:IsShown())
        for _,texture in ipairs(bar.materialLayers) do
            if texture.allPoints then assert(texture.allPoints==bar:GetStatusBarTexture()) end
            for _,point in ipairs(texture.points) do assert(point[2]==bar:GetStatusBarTexture()) end
        end
        -- No new per-frame material animation is needed: the existing fill
        -- animation moves all of the anchored decorations.
        assert(bar.neonGlow.scripts.OnUpdate==nil)
    ''')


@pytest.mark.parametrize("modern", [True, False])
def test_secret_values_are_never_compared_or_used_for_geometry(modern):
    lua = addon(modern=modern)
    preview(lua)
    lua.execute('''
        local bar=OmenReloadedForeverBar1
        local function forbidden() error('Secret value was inspected') end
        local value=setmetatable({secret=true}, {__lt=forbidden,__le=forbidden,
            __add=forbidden,__sub=forbidden,__mul=forbidden,__div=forbidden})
        bar:SetValue(value)
        ns.Theme.PaintBar(bar,1,0.2,0.1,true,0.8)
        assert(bar.neonHasFill and bar.materialTop:IsShown())
        assert(bar:GetValue()==value)
        bar:SetValue(0)
        assert(not bar.materialTop:IsShown())
    ''')


def test_saved_glow_setting_keeps_material_and_warning_colors():
    lua = addon(saved="{showGlow=false, glowIntensity=1, useClassColors=true}")
    preview(lua)
    lua.execute('''
        local sawYellow, sawRed = false,false
        for i=1,8 do
            local bar=_G['OmenReloadedForeverBar'..i]
            if bar and bar:IsShown() then
                assert(not bar.neonGlow:IsShown())
                assert(bar.materialTop:IsShown())
                local c=bar.barColor
                if c[1]==1 and c[2]==1 and c[3]==0 then sawYellow=true end
                if c[1]==1 and c[2]==0.2 and c[3]==0.1 then sawRed=true end
            end
        end
        assert(sawYellow and sawRed)
    ''')


@pytest.mark.parametrize("height", [10, 16, 40])
@pytest.mark.parametrize("width", [100, 600])
def test_short_and_wide_rows_have_no_stretched_mask_or_vertical_cap(width, height):
    lua = addon(saved=f"{{width={width},height={height},frameHeight=900}}")
    preview(lua)
    lua.execute('''
        for i=1,3 do
            local bar=_G['OmenReloadedForeverBar'..i]
            assert(bar.neonEdge==nil and bar.roundMask==nil)
            assert(bar:GetStatusBarTexture().mask==nil)
            assert(bar:GetStatusBarTexture().texture=='Interface\\\\Buttons\\\\WHITE8x8')
            assert(bar.neonGlow.allPoints==bar:GetStatusBarTexture())
            bar:SetValue(0)
            for _,layer in ipairs(bar.materialLayers) do assert(not layer:IsShown()) end
            assert(not bar.neonGlow:IsShown())
        end
    ''')


def test_options_requested_in_combat_open_after_combat():
    lua = addon()
    lua.execute('''
        combat=true
        SlashCmdList.OMENRELOADEDFOREVER('')
        assert(not OmenReloadedForeverOptionsPanel:IsShown())
        combat=false
        dispatch('PLAYER_REGEN_ENABLED')
        flush()
        assert(OmenReloadedForeverOptionsPanel:IsShown())
        assert(OmenReloadedForeverFrame:GetFrameStrata()=='LOW')
    ''')


def test_renamed_addon_loads_copied_legacy_settings_and_retains_bindings():
    lua = addon(saved="{width=312,height=24,showGlow=false,themeColor={r=0.2,g=0.5,b=0.8}}")
    g = lua.globals()
    assert g.OmenReloadedForeverFrame.width == 332
    assert g.OmenReloadedForeverDB.height == 24
    assert g.OmenReloadedForeverDB.showGlow is False
    assert g.OmenReloadedForeverDB.themeColor.b == 0.8
    assert g.OmenReloadedForeverOptionsPanel.name == "NeonOmen"
    assert g.SLASH_OMENRELOADEDFOREVER2 == "/neonomen"
    preview(lua)
    # Binding command IDs stay unchanged so existing key assignments still work.
    g.OmenReloadedForever_ToggleTestMode()
    g.flush()

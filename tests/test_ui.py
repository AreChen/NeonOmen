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
        assert(not bar.neonEdge:IsShown() and not bar.neonGlow:IsShown())
        assert(not bar.neonSheen:IsShown() and not bar.neonShade:IsShown())
        bar:SetValue(45)
        assert(bar.neonEdge:IsShown() and bar.neonSheen:IsShown())
        for _,texture in ipairs({bar.neonEdge,bar.neonSheen,bar.neonShade,bar.neonGlow}) do
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
        assert(bar.neonHasFill and bar.neonEdge:IsShown())
        assert(bar:GetValue()==value)
        bar:SetValue(0)
        assert(not bar.neonEdge:IsShown())
    ''')


def test_saved_glow_setting_keeps_progress_edge_and_warning_colors():
    lua = addon(saved="{showGlow=false, glowIntensity=1, useClassColors=true}")
    preview(lua)
    lua.execute('''
        local sawYellow, sawRed = false,false
        for i=1,8 do
            local bar=_G['OmenReloadedForeverBar'..i]
            if bar and bar:IsShown() then
                assert(not bar.neonGlow:IsShown())
                assert(bar.neonEdge:IsShown())
                local c=bar.barColor
                if c[1]==1 and c[2]==1 and c[3]==0 then sawYellow=true end
                if c[1]==1 and c[2]==0.2 and c[3]==0.1 then sawRed=true end
            end
        end
        assert(sawYellow and sawRed)
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

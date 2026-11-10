from pathlib import Path

from lupa.lua51 import LuaRuntime

ROOT = Path(__file__).resolve().parents[1]


def addon(locale="enUS", saved="{}", modern=True):
    lua = LuaRuntime(unpack_returned_tuples=True)
    lua.execute(r'''
        frames = {}; ns = {}; messages = {}; timers = {}; combat = false
        local M = {}
        local function noop() end
        for _, key in ipairs({
            'SetJustifyH','SetWordWrap','SetShadowColor','SetShadowOffset',
            'SetBlendMode','SetClampedToScreen','SetMovable','EnableMouse',
            'SetResizable','SetResizeBounds','SetMinResize','SetMaxResize',
            'RegisterForDrag','RegisterForClicks','StartMoving','StartSizing',
            'StopMovingOrSizing','SetHighlightTexture','SetNormalTexture',
            'SetPushedTexture','SetBackdrop','SetBackdropColor',
            'SetBackdropBorderColor','SetValueStep','SetObeyStepOnDrag',
            'SetOwner','AddLine','SetTexCoord','SetTextureSliceMargins',
            'SetTextureSliceMode','SetOrientation'
        }) do M[key] = noop end
        function CreateFrame(kind, name, parent, template)
            local f = setmetatable({kind=kind,name=name,parent=parent,
                scripts={},events={},points={},shown=true,width=220,height=200}, {__index=M})
            frames[#frames+1] = f
            if name then _G[name] = f end
            if template == 'UICheckButtonTemplate' then f.Text = f:CreateFontString() end
            if template == 'OptionsSliderTemplate' then
                f.Text=f:CreateFontString(); f.Low=f:CreateFontString(); f.High=f:CreateFontString()
            end
            return f
        end
        function M:CreateTexture(_, layer, _, sublevel)
            local t=CreateFrame('Texture',nil,self);t.layer=layer;t.sublevel=sublevel;return t
        end
        function M:CreateMaskTexture() return CreateFrame('MaskTexture',nil,self) end
        function M:AddMaskTexture(mask) self.mask=mask end
        function M:CreateFontString() return CreateFrame('FontString',nil,self) end
        function M:SetSize(w,h) self.width=w;self.height=h end
        function M:SetWidth(w) self.width=w end
        function M:SetHeight(h) self.height=h end
        function M:GetWidth() return self.width end
        function M:GetHeight() return self.height end
        function M:SetPoint(...) self.points[#self.points+1]={...} end
        function M:ClearAllPoints() self.points={} end
        function M:SetAllPoints(ref) self.allPoints=ref or self.parent end
        function M:GetPoint(i) return unpack(self.points[i or 1]) end
        function M:SetFrameStrata(s) self.strata=s end
        function M:GetFrameStrata() return self.strata or (self.parent and self.parent:GetFrameStrata()) or 'MEDIUM' end
        function M:SetFixedFrameStrata(on) self.fixedStrata=on end
        function M:SetFrameLevel(n) self.level=n end
        function M:GetFrameLevel() return self.level or 1 end
        function M:SetToplevel(on) self.toplevel=on end
        function M:SetScale(s) self.scale=s end
        function M:GetEffectiveScale() return self.scale or 1 end
        function M:SetAlpha(a) self.alpha=a end
        function M:SetText(t) self.text=t end
        function M:SetFormattedText(fmt, ...) self.text=string.format(fmt,...) end
        function M:SetTextColor(...) self.textColor={...} end
        function M:GetFont() return 'Fonts/ARIALN.TTF',12 end
        function M:SetFont(...) self.font={...} end
        function M:SetTexture(t) self.texture=t end
        function M:SetVertexColor(...) self.vertex={...} end
        function M:SetColorTexture(...) self.color={...} end
        function M:SetGradient(direction, from, to)
            assert(type(from)=='table' and type(to)=='table')
            self.gradient={direction,from,to}
        end
        function M:SetGradientAlpha(...) self.legacyGradient={...} end
        function M:SetStatusBarTexture(t) self.fill=self:CreateTexture(nil,'ARTWORK');self.fill:SetTexture(t) end
        function M:GetStatusBarTexture() return self.fill end
        function M:SetStatusBarColor(...) self.barColor={...} end
        function M:SetMinMaxValues(a,b) self.min=a;self.max=b end
        function M:SetValue(v)
            self.value=v
            if self.scripts.OnValueChanged then self.scripts.OnValueChanged(self,v) end
        end
        function M:GetValue() return self.value or 0 end
        function M:SetChecked(on) self.checked=on end
        function M:GetChecked() return self.checked end
        function M:SetScrollChild(child) self.child=child end
        function M:SetScript(event, fn) self.scripts[event]=fn end
        function M:GetScript(event) return self.scripts[event] end
        function M:HookScript(event, fn)
            local old=self.scripts[event]
            self.scripts[event]=function(...) if old then old(...) end;fn(...) end
        end
        function M:Show()
            local changed=not self.shown;self.shown=true
            if changed and self.scripts.OnShow then self.scripts.OnShow(self) end
        end
        function M:Hide() self.shown=false end
        function M:SetShown(on) if on then self:Show() else self:Hide() end end
        function M:IsShown() return self.shown end
        function M:RegisterEvent(event) self.events[event]=true end
        function M:UnregisterEvent(event) self.events[event]=nil end
        function dispatch(event,...)
            for _,f in ipairs(frames) do
                if f.events[event] and f.scripts.OnEvent then f.scripts.OnEvent(f,event,...) end
            end
        end
        function flush()
            for i=1,100 do
                if #timers==0 then return end
                local batch=timers;timers={}
                for _,fn in ipairs(batch) do fn() end
            end
            error('Timer loop')
        end
        function print(...) messages[#messages+1]=table.concat({...},' ') end
        function CreateColor(...) return {...} end
        function GetLocale() return 'enUS' end
        function GetTime() return 10 end
        function InCombatLockdown() return combat end
        function UnitAffectingCombat() return combat end
        function IsInRaid() return false end
        function IsInGroup() return false end
        function IsResting() return false end
        function IsInInstance() return false,'none' end
        function UnitExists(unit) return unit=='player' end
        function UnitClass() return 'Mage','MAGE' end
        function UnitName(unit) return unit=='player' and 'Tester' or 'Pet' end
        function UnitGUID(unit) return unit end
        function UnitGroupRolesAssigned() return 'DAMAGER' end
        function GetThreatStatusColor(status)
            if status==0 then return 0.3,0.8,0.4 end
            return 1,0.2,0.1
        end
        function issecretvalue(v) return type(v)=='table' and v.secret==true end
        function UIDropDownMenu_SetWidth() end
        function UIDropDownMenu_Initialize() end
        function UIDropDownMenu_SetSelectedValue() end
        function UIDropDownMenu_SetText() end
        function UIDropDownMenu_CreateInfo() return {} end
        function UIDropDownMenu_AddButton() end
        UIParent=CreateFrame('Frame'); Minimap=CreateFrame('Frame')
        GameTooltip=CreateFrame('Frame'); UISpecialFrames={}; SlashCmdList={}
        C_Timer={After=function(_,fn) timers[#timers+1]=fn end,NewTicker=function() end}
        Enum={UITextureSliceMode={Stretched=1}}
        methods=M
    ''')
    if not modern:
        lua.execute('''
            CreateColor=nil; methods.SetGradient=nil
            methods.CreateMaskTexture=nil; methods.AddMaskTexture=nil
            methods.SetTextureSliceMargins=nil; methods.SetFixedFrameStrata=nil
        ''')
    lua.globals().GetLocale = lambda: locale
    for entry in (ROOT / "OmenReloadedForever.toc").read_text().splitlines():
        if entry.endswith(".lua"):
            lua.execute((ROOT / entry).read_text(encoding="utf-8-sig"), "OmenReloadedForever", lua.globals().ns)
    # Replacing the table matches the actual SavedVariables loading lifecycle.
    lua.execute("OmenReloadedForeverDB=" + saved)
    lua.globals().dispatch("ADDON_LOADED", "OmenReloadedForever")
    lua.globals().flush()
    return lua


def preview(lua):
    lua.globals().SlashCmdList.OMENRELOADEDFOREVER("test")
    lua.globals().flush()
    assert not any("|cffff0000" in msg for msg in lua.globals().messages.values())

local _, ns = ...
local button
local function position()
    if not button then return end
    local angle=math.rad(ns.db.minimapAngle)
    button:ClearAllPoints()
    local width=Minimap and Minimap.GetWidth and ns.Safe(Minimap:GetWidth())
    local radius=(type(width)=="number" and width>0 and width/2+8 or 80)+ns.db.minimapOffset
    button:SetPoint("CENTER",Minimap or UIParent,"CENTER",math.cos(angle)*radius,math.sin(angle)*radius)
end

function ns.UpdateMinimap()
    if button then position();button:SetShown(ns.db.showMinimap) end
end

function ns.CreateMinimap()
    button=CreateFrame("Button","NeonOmenRebornMinimapButton",Minimap or UIParent)
    button:SetSize(30,30)
    position()
    button:RegisterForClicks("LeftButtonUp","RightButtonUp")
    button:RegisterForDrag("LeftButton")
    button:SetScript("OnDragStart",function(self)
        self:SetScript("OnUpdate",function()
            local x,y=GetCursorPosition()
            local scale=Minimap:GetEffectiveScale()
            local cx,cy=Minimap:GetCenter()
            if not cx or not cy then return end
            x,y=x/scale-cx,y/scale-cy
            ns.db.minimapAngle=math.deg(math.atan2(y,x))
            position()
        end)
    end)
    button:SetScript("OnDragStop",function(self) self:SetScript("OnUpdate",nil) end)
    local icon=button:CreateTexture(nil,"ARTWORK")
    icon:SetAllPoints()
    icon:SetTexture("Interface\\Icons\\Spell_Nature_Reincarnation")
    button:SetScript("OnClick",function(_,mouseButton)
        if mouseButton=="RightButton" then ns.Set("test",not ns.db.test)
        elseif IsShiftKeyDown and IsShiftKeyDown() then ns.ToggleMeter()
        else ns.ToggleSettings() end
    end)
    button:SetScript("OnEnter",function(self)
        if not GameTooltip then return end
        GameTooltip:SetOwner(self,"ANCHOR_LEFT")
        GameTooltip:AddLine("NeonOmen Reborn")
        GameTooltip:AddLine(ns.L.minimapLeft,1,1,1)
        GameTooltip:AddLine(ns.L.minimapShift,1,1,1)
        GameTooltip:AddLine(ns.L.minimapRight,1,1,1)
        GameTooltip:AddLine(ns.L.minimapDrag,1,1,1)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
    ns.UpdateMinimap()
end

local _, ns = ...
local floor, max, min = math.floor, math.max, math.min
local meter, rows, elapsed = nil, {}, 0
local history, targetKey, lastWarning, manualHidden = {}, nil, -1000, false
local aggroTarget, hadAggro, warningTarget, wasNear = nil, nil, nil, false
local markerTarget, markerHolder, markerUntil = nil, nil, 0
local white = "Interface\\Buttons\\WHITE8X8"
local samples = {
    {name=ns.L.sampleTank, pct=100, value=10000, tps=320, class="WARRIOR", tank=true},
    {name=ns.L.sampleDamage, pct=82, value=8200, tps=290, class="MAGE"},
    {name=ns.L.sampleYou, pct=57, value=5700, tps=180, class="HUNTER", player=true},
}
local function texture(parent, layer, color)
    local t = parent:CreateTexture(nil, layer)
    t:SetTexture(white)
    t:SetVertexColor(unpack(color))
    return t
end
local function readable(v)
    v = ns.Safe(v)
    if type(v) ~= "number" then return nil end
    return v
end
local function safeCall(fn, ...)
    if not fn then return nil end
    local ok,value=pcall(fn,...)
    if ok then return ns.Safe(value) end
end
local function shortNumber(value)
    if value >= 1000000000 then return string.format("%.1fB",value/1000000000) end
    if value >= 1000000 then return string.format("%.1fM",value/1000000) end
    if value >= 10000 then return string.format("%.1fk",value/1000) end
    return string.format("%.0f",value)
end
local function sampleRate(key, value, now)
    if not key then return nil end
    local points = history[key] or {}
    history[key] = points
    local last = points[#points]
    if last and (value < last.value or now-last.time>10 or now<last.time) then
        points = {}; history[key] = points; last = nil
    end
    if not last or now - last.time >= 0.24 then
        points[#points+1] = {time=now,value=value}
    end
    while #points > 2 and now - points[2].time > 10 do table.remove(points,1) end
    local first = points[1]
    if first and now > first.time then return max(0,(value-first.value)/(now-first.time)) end
end
local function findTarget()
    local candidates = ns.db.useFocus and {"focus", "focustarget", "target", "targettarget"} or {"target", "targettarget"}
    for _,unit in ipairs(candidates) do
        if UnitExists(unit) and UnitCanAttack("player",unit)
            and (not UnitIsPlayer or not ns.Safe(UnitIsPlayer(unit)))
            and (not UnitIsDeadOrGhost or not ns.Safe(UnitIsDeadOrGhost(unit))) then
            if unit == "targettarget" or unit == "focustarget" then
                for i=1,40 do
                    local plate="nameplate"..i
                    if UnitExists(plate) and UnitIsUnit and ns.Safe(UnitIsUnit(plate,unit)) then return plate end
                end
            end
            return unit
        end
    end
end
local function gather()
    if ns.db.test then return samples end
    local target = findTarget()
    if not target then history={};targetKey=nil;return {} end
    local guid = UnitGUID and ns.Safe(UnitGUID(target)) or target
    if guid ~= targetKey then history={};targetKey=guid end
    local now = GetTime and GetTime() or 0
    local units = {}
    if IsInRaid() then
        for i=1,GetNumGroupMembers() do
            units[#units+1] = "raid"..i
            if ns.db.showPets then units[#units+1] = "raidpet"..i end
        end
    else
        units[#units+1] = "player"
        if ns.db.showPets then units[#units+1] = "pet" end
        for i=1,GetNumSubgroupMembers() do
            units[#units+1] = "party"..i
            if ns.db.showPets then units[#units+1] = "partypet"..i end
        end
    end
    local found = {}
    for _, unit in ipairs(units) do
        if UnitExists(unit) then
            local ok, tank, status, scaled, raw, value = pcall(UnitDetailedThreatSituation, unit, target)
            local isSecretPct = ok and issecretvalue and issecretvalue(scaled) or false
            local pct = ok and readable(scaled) or nil
            value = ok and readable(value) or nil
            local rawName = UnitName(unit)
            local isSecretName = issecretvalue and issecretvalue(rawName) or false
            local name = ns.Safe(rawName)
            local _, class = UnitClass(unit)
            class = ns.Safe(class)
            local isPlayer = unit == "player" or (UnitIsUnit and ns.Safe(UnitIsUnit(unit,"player")) == true)
            local hidden = class and ns.db["hide_"..class]
            if (pct or isSecretPct) and (type(name) == "string" or isSecretName) and (not hidden or isPlayer and ns.db.showSelf) then
                local id = UnitGUID and ns.Safe(UnitGUID(unit)) or unit
                local isPet=unit:lower():find("pet",1,true) ~= nil
                found[#found+1] = {name=name, secretName=isSecretName, rawName=rawName, pct=pct, secretPct=isSecretPct,
                    rawPct=scaled, rawThreatPct=readable(raw), value=value, class=class, status=readable(status), tank=ns.Safe(tank), pet=unit:lower():find("pet",1,true) ~= nil,
                    unit=unit, player=isPlayer, tps=value and sampleRate(id,value,now), order=#found+1,
                    dead=safeCall(UnitIsDeadOrGhost,unit)==true,
                    offline=not isPet and safeCall(UnitIsConnected,unit)==false}
            end
        end
    end
    table.sort(found, function(a,b)
        if a.pct and b.pct and a.pct ~= b.pct then return a.pct > b.pct end
        if (a.pct ~= nil) ~= (b.pct ~= nil) then return a.pct ~= nil end
        return a.order < b.order
    end)
    if guid~=markerTarget then markerTarget,markerHolder,markerUntil=guid,nil,0 end
    for _,entry in ipairs(found) do
        if entry.tank then
            local holder=UnitGUID and ns.Safe(UnitGUID(entry.unit)) or entry.unit
            if markerHolder and holder~=markerHolder then markerUntil=now+3 end
            markerHolder=holder
            entry.aggroChanged=now<markerUntil
            break
        end
    end
    return found, target
end
local function showForContext()
    if manualHidden then return false end
    if ns.db.test then return true end
    if ns.db.hideResting and IsResting and IsResting() then return false end
    if ns.db.hidePvp and IsInInstance then
        local _,kind = IsInInstance()
        if kind == "pvp" or kind == "arena" then return false end
    end
    local inCombat = UnitAffectingCombat and UnitAffectingCombat("player")
    if inCombat and not ns.db.showCombat then return false end
    if not inCombat and not ns.db.showOutOfCombat then return false end
    if IsInRaid() then return ns.db.showRaid end
    if GetNumSubgroupMembers() > 0 then return ns.db.showParty end
    if UnitExists("pet") then return ns.db.showWithPet end
    return ns.db.showSolo
end
local function fireAlert(message)
    if ns.db.warningSound and PlaySound then
        local choice=ns.sounds[ns.db.soundChoice] or ns.sounds[1]
        local id=SOUNDKIT and SOUNDKIT[choice[1]] or 8959
        PlaySound(id,"Master")
    end
    if ns.db.warningMessage and UIErrorsFrame then UIErrorsFrame:AddMessage(message,1,0.3,0.2) end
    if ns.db.warningFlash and meter.flash then meter.flashTime=0.7;meter.flash:Show() end
    if ns.db.warningShake and not meter.dragging and not meter.resizing then meter.shakeTime=0.45 end
end
function ns.TestAlert() if meter then fireAlert(ns.L.title..": 90%") end end
local function maybeAlert(data, target)
    if ns.db.test then return end
    local now = GetTime and GetTime() or 0
    local role = UnitGroupRolesAssigned and ns.Safe(UnitGroupRolesAssigned("player"))
    local targetID = target and UnitGUID and ns.Safe(UnitGUID(target))
    local attackingPlayer = target and UnitIsUnit and ns.Safe(UnitIsUnit(target.."target", "player")) or false
    local gained = targetID and aggroTarget == targetID and hadAggro == false and attackingPlayer
    aggroTarget, hadAggro = targetID, not not attackingPlayer
    if targetID ~= warningTarget then warningTarget=targetID;wasNear=false end
    local playerEntry
    for _,entry in ipairs(data) do
        if entry.player then playerEntry=entry;break end
    end
    local near=playerEntry and (playerEntry.pct and playerEntry.pct >= ns.db.warningThreshold
        or playerEntry.secretPct and playerEntry.status and playerEntry.status >= 1 and not playerEntry.tank) or false
    local crossed=near and not wasNear
    wasNear=near
    if now - lastWarning < ns.db.warningCooldown or (ns.db.suppressTank and role=="TANK") then return end
    if playerEntry and (crossed or (ns.db.warningAggro and gained)) then
            lastWarning = now
            local message=gained and ns.db.warningAggro and ns.L.aggroTaken
                or playerEntry.pct and (ns.L.title..": "..string.format("%.0f%%",playerEntry.pct)) or ns.L.aggroNear
            fireAlert(message)
    end
end
local function newRow(index)
    local row = CreateFrame("StatusBar", nil, meter)
    row:SetStatusBarTexture(white)
    row.currentTexture=white
    row:SetMinMaxValues(0,100)
    row.glow = texture(row, "OVERLAY", {1,1,1,0})
    row.glow:SetDrawLayer("OVERLAY",-1)
    row.glow:SetTexture("Interface\\AddOns\\NeonOmenReborn\\Media\\BarGlow")
    row.glow:SetBlendMode("ADD")
    row.glow:SetPoint("TOPLEFT",row:GetStatusBarTexture(),"TOPLEFT",-18,13)
    row.glow:SetPoint("BOTTOMRIGHT",row:GetStatusBarTexture(),"BOTTOMRIGHT",18,-13)
    row.background = texture(row, "BACKGROUND", {0.12,0.15,0.20,0.75})
    row.background:SetAllPoints()
    row.threshold = texture(row,"OVERLAY",{1,0.85,0.4,0.95})
    row.threshold:SetSize(2,4)
    row.shade = texture(row, "ARTWORK", {1,1,1,0})
    row.shade:SetAllPoints(row:GetStatusBarTexture())
    row.name = row:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    row.name:SetPoint("LEFT", 7, 0); row.name:SetJustifyH("LEFT")
    row.value = row:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    row.value:SetPoint("RIGHT",-7,0); row.value:SetJustifyH("RIGHT")
    row.name:SetWordWrap(false);row.value:SetWordWrap(false)
    row.name:SetShadowColor(0,0,0,1); row.name:SetShadowOffset(1,-1)
    row.value:SetShadowColor(0,0,0,1); row.value:SetShadowOffset(1,-1)
    row:SetScript("OnUpdate",function(self,dt)
        local target = self.targetValue
        if not target then self:SetScript("OnUpdate",nil);return end
        local current = self.displayValue or 0
        current = current + (target-current)*min(1,dt*12)
        if math.abs(target-current)<0.1 then current=target;self:SetScript("OnUpdate",nil) end
        self.displayValue=current;self:SetValue(current)
    end)
    row.animate = row:GetScript("OnUpdate")
    rows[index] = row
    return row
end
function ns.RefreshMeter()
    if not meter or not ns.db then return end
    local db = ns.db
    if db.test and UnitAffectingCombat and UnitAffectingCombat("player") then
        db.test=false
        if ns.RefreshSettings then ns.RefreshSettings() end
    end
    if not showForContext() then meter:Hide();return end
    local data, target = gather()
    if not meter:IsShown() then meter:Show() end
    maybeAlert(data,target)
    if db.showAggroBar and not db.test then
        for _,entry in ipairs(data) do
            if entry.player and entry.pct and entry.rawThreatPct and entry.pct > 0 and entry.rawThreatPct > 0 and entry.value then
                local ratio=entry.rawThreatPct/entry.pct
                if ratio >= 1.08 and ratio <= 1.32 then
                    local boundary=ratio >= 1.2 and 130 or 110
                    table.insert(data,1,{name=ns.L.pullBoundary.." · "..boundary.."%",pct=100,
                        value=entry.value*boundary/entry.rawThreatPct, reference=true})
                end
                break
            end
        end
    end
    local capacity = db.autoCollapse and db.maxRows or max(1,floor((db.height-44)/(db.rowHeight+db.spacing)))
    local count = min(#data, db.maxRows, capacity)
    if db.showSelf and #data > count and count > 0 then
        for i=count+1,#data do
            if data[i].player then data[count] = data[i];break end
        end
    end
    if not meter.resizing then
        meter:SetSize(db.width, db.autoCollapse and (44 + max(1,count)*(db.rowHeight+db.spacing)) or db.height)
    end
    meter:SetScale(db.scale)
    meter:SetAlpha(db.windowAlpha)
    meter:EnableMouse(not db.clickThrough)
    meter.grip:SetShown(not db.locked and not db.clickThrough)
    meter.bg:SetVertexColor(1,1,1,db.opacity)
    meter.glow:SetVertexColor(db.red,db.green,db.blue,db.glow and db.glowIntensity*0.25 or 0)
    meter.title:SetShown(db.showTitle)
    meter.header:SetShown(db.showHeader)
    meter.header:SetText(db.showTPS and "TPS  %" or "%")
    local targetName = target and ns.Safe(UnitName(target))
    meter.title:SetText(db.test and ns.L.previewTitle or (db.showTarget and type(targetName)=="string" and targetName or ns.L.title))
    meter.empty:SetShown(count == 0)
    local fontObject=({GameFontHighlightSmall,GameFontHighlight,GameFontNormal})[db.font] or GameFontHighlightSmall
    local fontPath,fontFlags
    fontPath=ns.MediaPath("font",db.fontName)
    local barTexture=ns.MediaPath("statusbar",db.textureName) or ns.barTextures[db.barTexture] or white
    if not fontPath and fontObject and fontObject.GetFont then
        local size
        fontPath,size,fontFlags=fontObject:GetFont()
    end
    for i=1,max(#rows,count) do
        local row = rows[i] or newRow(i)
        local entry = data[i]
        if i <= count and entry then
            row:ClearAllPoints()
            if db.growUp then row:SetPoint("BOTTOMLEFT", 6, 8+(i-1)*(db.rowHeight+db.spacing))
            else row:SetPoint("TOPLEFT", 6, -33-(i-1)*(db.rowHeight+db.spacing)) end
            row:SetSize(db.width-12,db.rowHeight)
            row.threshold:ClearAllPoints()
            row.threshold:SetPoint("TOPLEFT",row,"TOPLEFT",(db.width-12)*db.warningThreshold/100,0)
            row.threshold:SetShown(db.showAggroLine and not entry.reference)
            row.name:SetWidth(db.width-100)
            local marker = db.showMarker and entry.unit and GetRaidTargetIndex and ns.Safe(GetRaidTargetIndex(entry.unit))
            if entry.secretName then
                if not pcall(row.name.SetText,row.name,entry.rawName) then row.name:SetText(entry.unit or "?") end
            else
                local name=entry.name..(entry.pet and ns.L.petSuffix or "")
                if db.showMarker then
                    if entry.dead then name=name.." ("..ns.L.dead..")"
                    elseif entry.offline then name=name.." ("..ns.L.offline..")" end
                    if entry.tank then name="[T] "..name end
                    if entry.aggroChanged then name="[!] "..name end
                end
                row.name:SetText((type(marker)=="number" and ("|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_"..marker..":14|t ") or "")..name)
            end
            local parts = {}
            if db.showValue then parts[#parts+1]=entry.value and shortNumber(entry.value) or "--" end
            if db.showTPS then parts[#parts+1]=entry.tps and (shortNumber(entry.tps).."/s") or "--/s" end
            if entry.secretPct then
                local prefix=table.concat(parts,"  ")
                prefix=prefix ~= "" and prefix.."  " or ""
                if not pcall(row.value.SetFormattedText,row.value,prefix.."%d%%",entry.rawPct) then row.value:SetText(prefix.."--%") end
            else
                parts[#parts+1]=string.format("%.0f%%",entry.pct)
                row.value:SetText(table.concat(parts,"  "))
            end
            local valueWidth=min(db.width*0.56,db.showValue and 164 or db.showTPS and 120 or 62)
            row.value:SetWidth(valueWidth)
            row.name:SetWidth(max(24,db.width-valueWidth-28))
            local c = db.classColors and RAID_CLASS_COLORS and RAID_CLASS_COLORS[entry.class]
            local r,g,b = db.red,db.green,db.blue
            if c then r,g,b = c.r,c.g,c.b end
            if entry.player and db.useSelfColor then r,g,b=db.selfRed,db.selfGreen,db.selfBlue
            elseif entry.pet and db.usePetColor then r,g,b=db.petRed,db.petGreen,db.petBlue end
            if entry.reference or (not entry.tank and (entry.pct and entry.pct >= db.warningThreshold or entry.secretPct and entry.status and entry.status >= 1)) then r,g,b=db.aggroRed,db.aggroGreen,db.aggroBlue
            elseif entry.tank and db.useTankColor then r,g,b=db.tankRed,db.tankGreen,db.tankBlue end
            row:SetStatusBarColor(r,g,b,db.barAlpha)
            row.glow:SetVertexColor(r,g,b,db.barGlow and db.barGlowIntensity or 0)
            local fill = barTexture
            if row.currentTexture ~= fill then
                row:SetStatusBarTexture(fill)
                row.shade:SetTexture(fill)
                row.shade:SetAllPoints(row:GetStatusBarTexture())
                row.currentTexture=fill
            end
            if row.glowSpread~=db.barGlowSpread or row.glowTexture~=fill then
                local spread=db.barGlowSpread
                row.glow:ClearAllPoints()
                row.glow:SetPoint("TOPLEFT",row:GetStatusBarTexture(),"TOPLEFT",-18*spread,13*spread)
                row.glow:SetPoint("BOTTOMRIGHT",row:GetStatusBarTexture(),"BOTTOMRIGHT",18*spread,-13*spread)
                row.glowSpread=spread;row.glowTexture=fill
            end
            if fontPath and (row.fontPath~=fontPath or row.fontSize~=db.fontSize or row.fontFlags~=fontFlags) then
                row.name:SetFont(fontPath,db.fontSize,fontFlags);row.value:SetFont(fontPath,db.fontSize,fontFlags)
                row.fontPath,row.fontSize,row.fontFlags=fontPath,db.fontSize,fontFlags
            end
            if entry.secretPct then
                row.targetValue=nil;row.displayValue=nil;row:SetScript("OnUpdate",nil)
                if not pcall(row.SetValue,row,entry.rawPct) then row:SetValue(0) end
            else
                row.targetValue=min(100,max(0,entry.pct))
                if db.animateBars then row:SetScript("OnUpdate",row.animate)
                else row.displayValue=row.targetValue;row:SetValue(row.targetValue);row:SetScript("OnUpdate",nil) end
            end
            if db.style == 1 then row.shade:SetVertexColor(1,1,1,0)
            elseif db.style == 2 and row.shade.SetGradient and CreateColor then
                row.shade:SetVertexColor(1,1,1,1)
                row.shade:SetGradient("VERTICAL", CreateColor(0,0,0,0.4), CreateColor(1,1,1,0.18))
            else row.shade:SetVertexColor(1,1,1,db.style == 3 and 0.16 or 0.06) end
            row:Show()
        else row:Hide() end
    end
end
function ns.CreateMeter()
    meter = CreateFrame("Frame","NeonOmenRebornMeter",UIParent)
    meter.resizing=false;meter.dragging=false;meter.shakeTime=0
    meter:SetPoint("CENTER",UIParent,"CENTER",ns.db.x,ns.db.y)
    meter:SetClampedToScreen(true); meter:SetMovable(true); meter:EnableMouse(true)
    meter:SetResizable(true)
    if meter.SetResizeBounds then meter:SetResizeBounds(160,70,600,600) end
    meter:RegisterForDrag("LeftButton")
    meter:SetScript("OnMouseUp",function(_,button)
        if button=="RightButton" and ns.ToggleSettings then ns.ToggleSettings() end
    end)
    meter:SetScript("OnDragStart",function(self)
        if not ns.db.locked then self.shakeTime=0;self.dragging=true;self:StartMoving() end
    end)
    meter:SetScript("OnDragStop",function(self)
        self.dragging=false
        self:StopMovingOrSizing()
        local x,y = self:GetCenter()
        local cx,cy = UIParent:GetCenter()
        x,y,cx,cy=ns.Safe(x),ns.Safe(y),ns.Safe(cx),ns.Safe(cy)
        if type(x)=="number" and type(y)=="number" and type(cx)=="number" and type(cy)=="number" then
            local factor=self:GetEffectiveScale()/UIParent:GetEffectiveScale()
            ns.db.x,ns.db.y=x*factor-cx,y*factor-cy
            self:ClearAllPoints();self:SetPoint("CENTER",UIParent,"CENTER",ns.db.x,ns.db.y)
        end
    end)
    meter.glow=texture(meter,"BACKGROUND",{0.2,0.7,0.9,0.1})
    meter.glow:SetTexture("Interface\\AddOns\\NeonOmenReborn\\Media\\Glow")
    meter.glow:SetPoint("TOPLEFT",-16,16);meter.glow:SetPoint("BOTTOMRIGHT",16,-16)
    meter.bg = texture(meter,"BACKGROUND",{1,1,1,0.85})
    meter.bg:SetTexture("Interface\\AddOns\\NeonOmenReborn\\Media\\Panel")
    meter.bg:SetAllPoints()
    for _,image in ipairs({meter.bg,meter.glow}) do
        if image.SetTextureSliceMargins and Enum and Enum.UITextureSliceMode then
            image:SetTextureSliceMargins(24,24,24,24)
            image:SetTextureSliceMode(Enum.UITextureSliceMode.Stretched)
        end
    end
    local line = texture(meter,"ARTWORK",{0.30,0.75,0.95,0.9})
    line:SetPoint("TOPLEFT",0,0);line:SetPoint("TOPRIGHT",0,0);line:SetHeight(2)
    meter.title = meter:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
    meter.title:SetPoint("TOPLEFT",8,-10);meter.title:SetText(ns.L.title)
    meter.header = meter:CreateFontString(nil,"OVERLAY","GameFontDisableSmall")
    meter.header:SetPoint("TOPRIGHT",-8,-12);meter.header:SetText("TPS  %")
    local grip=CreateFrame("Button",nil,meter)
    grip:SetSize(16,16);grip:SetPoint("BOTTOMRIGHT",-2,2)
    grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    grip:SetScript("OnMouseDown",function()
        if ns.db.locked or ns.db.clickThrough then return end
        meter.resizing=true;meter:StartSizing("BOTTOMRIGHT")
    end)
    grip:SetScript("OnMouseUp",function()
        if not meter.resizing then return end
        meter:StopMovingOrSizing();meter.resizing=false
        local w,h=ns.Safe(meter:GetWidth()),ns.Safe(meter:GetHeight())
        if type(w)=="number" then ns.db.width=max(160,min(600,w)) end
        if type(h)=="number" then ns.db.height=max(70,min(600,h));ns.db.autoCollapse=false end
        ns.RefreshMeter()
        if ns.RefreshSettings then ns.RefreshSettings() end
    end)
    meter.grip=grip
    meter.empty = meter:CreateFontString(nil,"OVERLAY","GameFontDisableSmall")
    meter.empty:SetPoint("TOP",0,-38);meter.empty:SetText(ns.L.empty)
    meter.flash = CreateFrame("Frame",nil,UIParent)
    meter.flash:SetAllPoints(UIParent);meter.flash:SetFrameStrata("FULLSCREEN_DIALOG")
    meter.flash:EnableMouse(false)
    meter.flash.edges={}
    for i=1,4 do
        local edge=texture(meter.flash,"OVERLAY",{1,1,1,1})
        if i==1 then edge:SetPoint("TOPLEFT");edge:SetPoint("TOPRIGHT");edge:SetHeight(100)
        elseif i==2 then edge:SetPoint("BOTTOMLEFT");edge:SetPoint("BOTTOMRIGHT");edge:SetHeight(100)
        elseif i==3 then edge:SetPoint("TOPLEFT");edge:SetPoint("BOTTOMLEFT");edge:SetWidth(100)
        else edge:SetPoint("TOPRIGHT");edge:SetPoint("BOTTOMRIGHT");edge:SetWidth(100) end
        if edge.SetGradient and CreateColor then
            local strong,clear=CreateColor(1,0.05,0.05,0.65),CreateColor(1,0.05,0.05,0)
            local first,second=clear,strong
            if i==2 or i==3 then first,second=strong,clear end
            edge:SetGradient(i<=2 and "VERTICAL" or "HORIZONTAL",first,second)
        else edge:SetVertexColor(1,0.05,0.05,0.35) end
        meter.flash.edges[i]=edge
    end
    meter.flash:Hide()
    meter.flash:SetScript("OnUpdate",function(self,dt)
        meter.flashTime=(meter.flashTime or 0)-dt
        if meter.flashTime<=0 then self:Hide() else self:SetAlpha(meter.flashTime/0.7) end
    end)
    local driver=CreateFrame("Frame","NeonOmenRebornDriver",UIParent)
    driver:SetScript("OnUpdate",function(_,dt)
        if meter.shakeTime>0 and not meter.dragging and not meter.resizing then
            meter.shakeTime=max(0,meter.shakeTime-dt)
            local displacement=math.sin(meter.shakeTime*45)*5*(meter.shakeTime/0.45)
            meter:ClearAllPoints();meter:SetPoint("CENTER",UIParent,"CENTER",ns.db.x+displacement,ns.db.y)
        end
        elapsed=elapsed+dt
        if elapsed >= 0.25 then elapsed=0; ns.RefreshMeter() end
    end)
    ns.RefreshMeter()
end
function ns.ToggleMeter() manualHidden=not manualHidden;ns.RefreshMeter() end
function ns.ResetMeter()
    ns.db.x,ns.db.y=180,0
    meter:ClearAllPoints();meter:SetPoint("CENTER",UIParent,"CENTER",180,0)
    ns.RefreshMeter()
end

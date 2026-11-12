local _, ns = ...
local T = ns.Theme
local W = {}
ns.Widgets = W

function W.Label(parent, text, x, y, width, color, font)
    local label = parent:CreateFontString(nil, "OVERLAY", font or "GameFontHighlightSmall")
    label:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    if width then label:SetWidth(width) end
    label:SetJustifyH("LEFT")
    label:SetWordWrap(true)
    label:SetTextColor(unpack(color or T.colors.text))
    label:SetText(text)
    return label
end

function W.Tooltip(button, text)
    button:HookScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(text, nil, nil, nil, true)
        GameTooltip:Show()
    end)
    button:HookScript("OnLeave", function() GameTooltip:Hide() end)
end

function W.Switch(parent, text, get, set, accent, colorButton)
    local row = CreateFrame("Button", nil, parent)
    row:SetSize(562, 36)
    local label = W.Label(row, text, 18, -9, colorButton and 408 or 468)
    local height = math.max(36, label:GetStringHeight() + 18)
    row:SetHeight(height)
    local track = CreateFrame("Frame", nil, row)
    track:SetSize(36, 20)
    track:SetPoint("RIGHT", row, "RIGHT", -18, 0)
    local bg, edge = T.Surface(track, T.colors.inset, 1)
    local knob = T.Texture(track, "ARTWORK", {0.95, 0.97, 1}, 1)
    knob:SetSize(12, 12)
    local hover = T.Texture(row, "HIGHLIGHT", {1, 1, 1}, 0.035)
    hover:SetPoint("TOPLEFT", 8, 0); hover:SetPoint("BOTTOMRIGHT", -8, 0)
    function row.Refresh()
        local on, c = get(), accent()
        bg:SetVertexColor(on and c.r*0.28 or 0.025, on and c.g*0.28 or 0.035, on and c.b*0.28 or 0.055, 1)
        edge:SetVertexColor(c.r, c.g, c.b, on and 0.6 or 0.14)
        knob:ClearAllPoints(); knob:SetPoint("LEFT", track, "LEFT", on and 20 or 4, 0)
        knob:SetAlpha(on and 1 or 0.4)
    end
    row:SetScript("OnClick", function() set(not get()); row.Refresh() end)
    row.label = label
    return row
end

function W.Slider(parent, text, lo, hi, step, get, set, accent, format)
    local row = CreateFrame("Frame", nil, parent)
    row:SetSize(562, 38)
    W.Label(row, text, 18, -10, 220)
    local minus, plus = T.Button(row, "-"), T.Button(row, "+")
    minus:SetSize(24, 24); minus:SetPoint("RIGHT", row, "RIGHT", -282, 0)
    plus:SetSize(24, 24); plus:SetPoint("RIGHT", row, "RIGHT", -76, 0)
    local slider = CreateFrame("Slider", nil, row)
    slider:SetSize(166, 20); slider:SetPoint("LEFT", minus, "RIGHT", 8, 0)
    slider:SetOrientation("HORIZONTAL"); slider:SetMinMaxValues(lo, hi)
    slider:SetValueStep(step)
    if slider.SetObeyStepOnDrag then slider:SetObeyStepOnDrag(true) end
    local track = T.Texture(slider, "BACKGROUND", {0.11, 0.15, 0.21}, 1)
    track:SetPoint("LEFT"); track:SetPoint("RIGHT"); track:SetHeight(3)
    slider:SetThumbTexture("Interface\\Buttons\\WHITE8x8")
    slider:GetThumbTexture():SetSize(6, 14)
    local active = T.Texture(slider, "ARTWORK", {1, 1, 1}, 1)
    active:SetPoint("LEFT", track, "LEFT"); active:SetHeight(3)
    local value = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    value:SetPoint("RIGHT", row, "RIGHT", -18, 0); value:SetWidth(50); value:SetJustifyH("RIGHT")
    local busy = false
    function row.Refresh()
        local v, c = get(), accent()
        busy = true; slider:SetValue(v); busy = false
        active:SetWidth(166 * math.max(0, math.min(1, (v-lo)/(hi-lo))))
        active:SetColorTexture(c.r, c.g, c.b, 0.85)
        slider:GetThumbTexture():SetVertexColor(c.r, c.g, c.b, 1)
        minus:Paint(c); plus:Paint(c)
        value:SetText(format and format(v) or string.format("%g", v))
        value:SetTextColor(c.r, c.g, c.b)
    end
    local function apply(v)
        v = math.max(lo, math.min(hi, math.floor(v/step+0.5)*step))
        set(v); row.Refresh()
    end
    slider:SetScript("OnValueChanged", function(_, v) if not busy then apply(v) end end)
    minus:SetScript("OnClick", function() apply(get()-step) end)
    plus:SetScript("OnClick", function() apply(get()+step) end)
    row.slider, row.minus, row.plus, row.value = slider, minus, plus, value
    return row
end

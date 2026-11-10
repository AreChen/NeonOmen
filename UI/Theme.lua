-- Native surfaces and threat-bar materials, using NeonCast's visual palette.
local _, ns = ...
local Theme = {}
ns.Theme = Theme

Theme.colors = {
    panel = {0.025, 0.035, 0.062},
    card = {0.045, 0.060, 0.092},
    inset = {0.018, 0.027, 0.045},
    text = {0.90, 0.94, 1.00},
    muted = {0.46, 0.55, 0.68},
}

local MEDIA = "Interface\\AddOns\\NeonOmen\\Media\\"

function Theme.ApplyMeterLayer(frame)
    -- Settings, the game menu and dialogs must remain above the meter, even
    -- after moving it. Child bars inherit this stratum from their parent.
    frame:SetFrameStrata("LOW")
    frame:SetToplevel(false)
    if frame.SetFixedFrameStrata then frame:SetFixedFrameStrata(true) end
end

local function Surface(bar, asset, layer, sublevel, margins)
    local texture = bar:CreateTexture(nil, layer, nil, sublevel)
    texture:SetAllPoints()
    if texture.SetTextureSliceMargins then
        texture:SetTexture(MEDIA .. asset)
        margins = margins or 8
        texture:SetTextureSliceMargins(margins, margins, margins, margins)
        if texture.SetTextureSliceMode and Enum and Enum.UITextureSliceMode then
            texture:SetTextureSliceMode(Enum.UITextureSliceMode.Stretched)
        end
    else
        texture:SetTexture("Interface\\Buttons\\WHITE8x8")
    end
    return texture
end

local function Gradient(texture, from, to, direction)
    direction = direction or "VERTICAL"
    texture:SetColorTexture(1, 1, 1, 1)
    if texture.SetGradient and CreateColor then
        local ok = pcall(texture.SetGradient, texture, direction,
            CreateColor(unpack(from)), CreateColor(unpack(to)))
        if ok then return end
    end
    if texture.SetGradientAlpha then
        local ok = pcall(texture.SetGradientAlpha, texture, direction,
            from[1], from[2], from[3], from[4], to[1], to[2], to[3], to[4])
        if ok then return end
    end
    texture:SetColorTexture(from[1], from[2], from[3], (from[4] + to[4]) / 2)
end
Theme.Gradient = Gradient

Theme.presets = {
    {key="UI_GLACIER", r=0.20, g=0.82, b=1.00},
    {key="UI_AMETHYST", r=0.64, g=0.48, b=1.00},
    {key="UI_JADE", r=0.24, g=0.91, b=0.69},
    {key="UI_EMBER", r=1.00, g=0.57, b=0.26},
    {key="UI_ROSE", r=1.00, g=0.36, b=0.62},
}

function Theme.Texture(parent, layer, color, alpha, sublevel)
    local texture = parent:CreateTexture(nil, layer or "BACKGROUND", nil, sublevel)
    texture:SetColorTexture(color[1], color[2], color[3], alpha or 1)
    return texture
end

function Theme.Surface(parent, color, alpha)
    local bg = Surface(parent, "NeonBack", "BACKGROUND", -2, 16)
    bg:SetVertexColor(color[1], color[2], color[3], alpha or 1)
    local edge = Surface(parent, "NeonRing", "BORDER", 0, 16)
    edge:SetShown(edge.SetTextureSliceMargins ~= nil)
    return bg, edge
end

function Theme.Button(parent, text)
    local button = CreateFrame("Button", nil, parent)
    local bg, edge = Theme.Surface(button, {0.065, 0.085, 0.12}, 1)
    local caption = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    caption:SetPoint("CENTER")
    caption:SetWordWrap(false)
    caption:SetText(text or "")
    button:SetFontString(caption)
    button.caption = caption
    local hover = Theme.Texture(button, "HIGHLIGHT", {1, 1, 1}, 0.06)
    hover:SetAllPoints()
    function button:Paint(c)
        local active = self.selected
        bg:SetVertexColor(active and c.r*0.15 or 0.065, active and c.g*0.15 or 0.085,
            active and c.b*0.15 or 0.12, 1)
        edge:SetVertexColor(c.r, c.g, c.b, active and 0.75 or 0.18)
        caption:SetTextColor(active and c.r or 0.9, active and c.g or 0.94, active and c.b or 1)
    end
    return button
end

local function UpdateFillVisibility(bar, value)
    -- Secret values are interpreted only by the native StatusBar. Every
    -- material layer follows its texture; none reads the resulting width.
    local secret = issecretvalue and issecretvalue(value)
    local visible = secret or (type(value) == "number" and value > 0)
    bar.neonHasFill = visible
    for _, layer in ipairs(bar.materialLayers) do layer:SetShown(visible) end
    bar.neonGlow:SetShown(visible and bar.neonShowGlow or false)
end

function Theme.SkinBar(bar)
    -- A stretched rounded mask turns a long, short bar into an uneven capsule.
    -- Use a native rectangular fill and contained materials at every row size.
    bar:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
    local fill = bar:GetStatusBarTexture()
    local bg = Theme.Texture(bar, "BACKGROUND", Theme.colors.inset, 0.94, -2)
    bg:SetAllPoints()
    local trackTop = Theme.Texture(bar, "BORDER", {1, 1, 1}, 0.035)
    trackTop:SetPoint("TOPLEFT"); trackTop:SetPoint("TOPRIGHT"); trackTop:SetHeight(1)
    local trackBottom = Theme.Texture(bar, "BORDER", {0, 0, 0}, 0.28)
    trackBottom:SetPoint("BOTTOMLEFT"); trackBottom:SetPoint("BOTTOMRIGHT"); trackBottom:SetHeight(1)

    bar.materialLayers = {}
    local function layer(sublevel)
        local texture = bar:CreateTexture(nil, "ARTWORK", nil, sublevel)
        texture:SetAllPoints(fill)
        bar.materialLayers[#bar.materialLayers+1] = texture
        return texture
    end
    bar.materialDepth = layer(1)
    Gradient(bar.materialDepth, {0,0,0,0.28}, {0,0,0,0.02}, "HORIZONTAL")
    bar.neonShade = layer(1)
    Gradient(bar.neonShade, {0,0,0,0.28}, {0,0,0,0.035})
    bar.neonSheen = layer(2)
    Gradient(bar.neonSheen, {1,1,1,0}, {1,1,1,0.08})

    -- Fine horizontal brushing and a restrained top reflection give the fill
    -- depth without a bright vertical end-cap or a glow extending past it.
    for i, anchor in ipairs({"TOP", "CENTER", "BOTTOM"}) do
        local grain = layer(2)
        grain:ClearAllPoints()
        local left = anchor=="TOP" and "TOPLEFT" or anchor=="BOTTOM" and "BOTTOMLEFT" or "LEFT"
        local right = anchor=="TOP" and "TOPRIGHT" or anchor=="BOTTOM" and "BOTTOMRIGHT" or "RIGHT"
        local offset = anchor=="TOP" and -3 or anchor=="BOTTOM" and 3 or 0
        grain:SetPoint("LEFT", fill, left, 0, offset)
        grain:SetPoint("RIGHT", fill, right, 0, offset)
        grain:SetHeight(1); grain:SetColorTexture(1,1,1,0.030-i*0.004)
    end
    bar.materialTop = layer(3)
    bar.materialTop:ClearAllPoints()
    bar.materialTop:SetPoint("TOPLEFT",fill,"TOPLEFT")
    bar.materialTop:SetPoint("TOPRIGHT",fill,"TOPRIGHT")
    bar.materialTop:SetHeight(1); bar.materialTop:SetColorTexture(1,1,1,0.18)
    local bottom = layer(3)
    bottom:ClearAllPoints()
    bottom:SetPoint("BOTTOMLEFT",fill,"BOTTOMLEFT")
    bottom:SetPoint("BOTTOMRIGHT",fill,"BOTTOMRIGHT")
    bottom:SetHeight(1); bottom:SetColorTexture(0,0,0,0.18)

    bar.neonGlow = bar:CreateTexture(nil,"ARTWORK",nil,2)
    bar.neonGlow:SetAllPoints(fill)
    Gradient(bar.neonGlow, {1,1,1,0}, {1,1,1,0.14})
    bar:SetScript("OnValueChanged", UpdateFillVisibility)
    UpdateFillVisibility(bar, bar:GetValue())
end

function Theme.PaintBar(bar, r, g, b, showGlow, intensity)
    bar:SetStatusBarColor(r, g, b, 0.90)
    bar.neonGlow:SetAlpha(intensity * 0.35)
    bar.neonShowGlow = showGlow and intensity > 0
    bar.neonGlow:SetShown(bar.neonHasFill and bar.neonShowGlow or false)
end

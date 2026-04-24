local C    = require("game.constants")
local Road = require("game.road")

local Background = {}
local _time    = 0
local _pilatus = nil   -- Image object loaded in Background.load()

function Background.load()
    local ok, img = pcall(love.graphics.newImage, "assets/background/pilatus.png")
    if ok then _pilatus = img end
end

-- ── Pilatus ───────────────────────────────────────────────────────────────────

local function drawPilatus(cam_x)
    if not _pilatus then return end

    local iw = _pilatus:getWidth()
    local ih = _pilatus:getHeight()

    -- Scale to fill full game width; anchor at y=0 (horizon)
    local sx = C.W / iw
    -- Gentle horizontal parallax: the mountain barely moves with steering
    local px = cam_x * 0.03

    -- Light icy-blue tint
    love.graphics.setColor(0.45, 0.82, 1.0, 1.0)
    love.graphics.draw(_pilatus, px, 0, 0, sx, sx)
    love.graphics.setColor(1, 1, 1, 1)
end

-- ── Lake sides ────────────────────────────────────────────────────────────────

local function drawLake(cam_x)
    local lx_near, ly_near = Road.project(-0.5, 0.001, cam_x)
    local rx_near, ry_near = Road.project( 0.5, 0.001, cam_x)
    local lx_far,  ly_far  = Road.project(-0.5, 0.97,  cam_x)
    local rx_far,  ry_far  = Road.project( 0.5, 0.97,  cam_x)

    love.graphics.setColor(0.0, 0.22, 0.30, 0.92)

    love.graphics.polygon("fill",
        0,       C.H,
        lx_near, ly_near,
        lx_far,  ly_far,
        0,       ly_far)

    love.graphics.polygon("fill",
        C.W,     C.H,
        rx_near, ry_near,
        rx_far,  ry_far,
        C.W,     ry_far)

    -- Shimmer: animated cyan reflection lines
    love.graphics.setLineWidth(1)
    for i = 1, 8 do
        local t     = i / 9.0
        local sy    = ly_far  + (ly_near - ly_far)  * t
        local lx_at = lx_far  + (lx_near - lx_far)  * t
        local rx_at = rx_far  + (rx_near - rx_far)  * t
        local alpha = math.max(0.0, 0.07 + 0.10 * math.sin(_time * 1.3 + i * 1.4))
        love.graphics.setColor(0.0, 0.9, 1.0, alpha)
        if lx_at > 4 then
            love.graphics.line(0, sy, lx_at - 2, sy)
        end
        if rx_at < C.W - 4 then
            love.graphics.line(rx_at + 2, sy, C.W, sy)
        end
    end
    love.graphics.setLineWidth(1)
end

-- ── Public API ────────────────────────────────────────────────────────────────

function Background.update(dt)
    _time = _time + dt
end

function Background.draw(cam_x)
    drawLake(cam_x)
    drawPilatus(cam_x)   -- drawn after lake so mountain silhouette sits over the water
end

return Background

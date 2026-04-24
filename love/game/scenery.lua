-- Scenery: Lucerne landmarks that zoom in from the horizon on both sides of the
-- road, using the same perspective projection as road objects.
-- Images are white-on-transparent PNGs; setColor() tints them to neon hues.

local C = require("game.constants")

local Scenery = {}

-- ── Asset manifest ────────────────────────────────────────────────────────────
local IMAGE_PATHS = {
    "assets/scenery/altstadt.png",
    "assets/scenery/bahnhof.png",
    "assets/scenery/hofkirche.png",
    "assets/scenery/jesuitenkirche.png",
    "assets/scenery/kapellbruecke.png",
    "assets/scenery/ringer.png",
    "assets/scenery/suva.png",
}

local NEON_PALETTE = {
    {0.0, 1.0, 1.0},   -- cyan
    {1.0, 0.0, 0.71},  -- pink
    {0.62, 0.0, 1.0},  -- purple
    {1.0, 0.31, 0.0},  -- orange
    {0.0, 1.0, 0.31},  -- neon-green
}

-- ── Module state ──────────────────────────────────────────────────────────────
local images      = {}   -- { img, w, h }
local items       = {}   -- active scenery items
local spawn_timer = 0

local SPAWN_INTERVAL = 12.0  -- seconds between paired spawns (one per side)
local CULL_Z         = 0.42  -- remove item when it gets this close (before road fills screen)

-- lane_frac controls how far outside the road edges the building appears.
-- Values > 0.5 are outside the right road edge; < -0.5 outside the left edge.
local LANE_MIN = 0.72   -- closest to road edge
local LANE_MAX = 1.05   -- furthest from road edge

-- ── Internal helpers ──────────────────────────────────────────────────────────

local function randcol()
    return NEON_PALETTE[love.math.random(#NEON_PALETTE)]
end

local function spawnOne(speed, side)
    if #images == 0 then return end
    local lane_frac = side * (LANE_MIN + love.math.random() * (LANE_MAX - LANE_MIN))
    local idx = love.math.random(#images)
    items[#items+1] = {
        z          = C.OBJ_SPAWN_Z,
        speed      = speed * 0.020,
        lane_frac  = lane_frac,
        img_idx    = idx,
        color      = randcol(),
    }
end

-- ── Public API ────────────────────────────────────────────────────────────────

function Scenery.load()
    for _, path in ipairs(IMAGE_PATHS) do
        local ok, img = pcall(love.graphics.newImage, path)
        if ok then
            images[#images+1] = { img = img, w = img:getWidth(), h = img:getHeight() }
        end
    end
end

function Scenery.update(dt, speed)
    -- Spawn a pair (left + right) every SPAWN_INTERVAL seconds
    spawn_timer = spawn_timer + dt
    if spawn_timer >= SPAWN_INTERVAL then
        spawn_timer = 0
        spawnOne(speed, -1)   -- left side
        spawnOne(speed,  1)   -- right side
    end

    -- Advance each item toward the camera, cull when too close
    local i = 1
    while i <= #items do
        local item = items[i]
        item.z = item.z - item.speed * (1.0 - item.z + 0.08) * dt
        if item.z < CULL_Z then
            items[i] = items[#items]
            items[#items] = nil
        else
            i = i + 1
        end
    end
end

function Scenery.draw(cam_x)
    -- Sort far-to-near so closer buildings overdraw distant ones
    table.sort(items, function(a, b) return a.z > b.z end)

    for _, item in ipairs(items) do
        local idata = images[item.img_idx]
        if not idata then goto continue end

        -- Road perspective projection (mirrors Road.project logic)
        local half_w   = C.ROAD_HALF_BOT + (C.ROAD_HALF_TOP - C.ROAD_HALF_BOT) * item.z
        local screen_y = C.HORIZON_Y + (C.H - C.HORIZON_Y) * (1.0 - item.z)
        local center_x = C.W / 2 + cam_x * (1.0 - item.z)  -- same parallax law as road objects
        local screen_x = center_x + item.lane_frac * half_w * 2
        local sc       = math.max(0, 1.0 - item.z)   -- same scale law as road objects

        if sc < 0.01 then goto continue end

        local iw = idata.w
        local ih = idata.h
        local draw_w = iw * sc
        local draw_h = ih * sc

        -- Draw: base of building at screen_y, horizontally centered on screen_x
        local col = item.color
        love.graphics.setColor(col[1], col[2], col[3], 0.92)
        love.graphics.draw(idata.img,
            screen_x - draw_w / 2,
            screen_y - draw_h,
            0, sc, sc)

        ::continue::
    end

    love.graphics.setColor(1, 1, 1, 1)
end

function Scenery.reset()
    items       = {}
    spawn_timer = 0
end

return Scenery

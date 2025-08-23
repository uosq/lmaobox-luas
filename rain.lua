--- made by navet

--- settings

local rain_color = {255, 255, 255, 50} --- Red, Green, Blue, Alpha
local MAX_PARTICLES <const> = 100
local MAX_PARTICLE_SPAWN_DISTANCE <const> = 400
local MAX_LIFETIME_SECONDS <const> = 5.0

local MAX_PARTICLE_SPEED <const> = 1500
local MIN_PARTILE_SPEED <const> = 800

local THICKNESS <const> = 5

--- 

local texture = draw.CreateTextureRGBA(string.char(255, 255, 255, 255), 1, 1)

local particles = {}
local TraceLine = engine.TraceLine
local Vector3 = Vector3
local MASK = MASK_SHOT_HULL
local FrameTime = globals.FrameTime
local WorldToScreen = client.WorldToScreen
local RandomFloat = engine.RandomFloat

---@class Raindrop
---@field pos Vector3
---@field vel Vector3
---@field oldpos Vector3
---@field lifetime number
---@field groundZ number

local function shouldHit(ent, contentsMask)
    return ent ~= nil
end

---@param headPos Vector3
---@param particle Raindrop
local function ParticleInit(headPos, particle)
    local x = RandomFloat(-MAX_PARTICLE_SPAWN_DISTANCE, MAX_PARTICLE_SPAWN_DISTANCE)
    local y = RandomFloat(-MAX_PARTICLE_SPAWN_DISTANCE, MAX_PARTICLE_SPAWN_DISTANCE)

    particle.pos = headPos + Vector3(x, y, 800)
    particle.vel = Vector3(RandomFloat(-100, 100), RandomFloat(-100, 100), -RandomFloat(MIN_PARTILE_SPEED, MAX_PARTICLE_SPEED))
    particle.oldpos = particle.pos
    particle.lifetime = 0

    local trace = engine.TraceLine(particle.pos, particle.pos + Vector3(0, 0, -2048 ), MASK, shouldHit)
    particle.groundZ = trace.endpos.z
end

---@param particle Raindrop
---@param deltatime number
---@return boolean
local function ParticleMove(particle, deltatime)
    particle.lifetime = particle.lifetime + deltatime
    if particle.lifetime > MAX_LIFETIME_SECONDS then
        return false
    end

    particle.oldpos = particle.pos
    particle.pos = particle.pos + particle.vel * deltatime
    particle.vel = particle.vel + Vector3(0, 0, -800 * deltatime)

    return particle.groundZ and particle.pos.z > particle.groundZ
end

local function Draw()
    if engine.Con_IsVisible() or engine.IsGameUIVisible() or engine.IsTakingScreenshot() then
        return
    end

    local plocal = entities.GetLocalPlayer()
    if not plocal then return end

    local headPos = plocal:GetAbsOrigin() + plocal:GetPropVector("m_vecViewOffset[0]")

    local deltatime = FrameTime()
    local currentpos
    local oldpos
    local trace

    draw.Color(rain_color[1], rain_color[2], rain_color[3], rain_color[4])

    for i = 1, MAX_PARTICLES do
        local particle = particles[i]
        if not particle then
            particle = {}
            particles[i] = particle
            ParticleInit(headPos, particle)
        end

        local success = ParticleMove(particle, deltatime)
        if not success then
            ParticleInit(headPos, particle)
        else
            trace = TraceLine(headPos, particle.pos, MASK, shouldHit)
            if trace and trace.fraction == 1 then
                currentpos = WorldToScreen(particle.pos)
                oldpos = WorldToScreen(particle.oldpos)

                if currentpos and oldpos then
                    local dx = currentpos[1] - oldpos[1]
                    local dy = currentpos[2] - oldpos[2]
                    local length = dx*dx + dy*dy --- i should probably use a math.sqrt here, but fuck it

                    if length > 0 then -- do NOT do division by 0 ( computers dont like them :( )
                        local angle = math.atan(dy, dx)

                        -- get perpendicular offset
                        local perpX = -math.sin(angle) * THICKNESS/2
                        local perpY = math.cos(angle) * THICKNESS/2

                        --- make the vertices for the rain drop
                        local vertices = {
                            {oldpos[1] + perpX, oldpos[2] + perpY, 0, 0}, -- x, y, u, v
                            {oldpos[1] - perpX, oldpos[2] - perpY, 1, 0},
                            {currentpos[1] - perpX, currentpos[2] - perpY, 1, 1},
                            {currentpos[1] + perpX, currentpos[2] + perpY, 0, 1}
                        }

                        draw.TexturedPolygon(texture, vertices, true)
                    end
                end
            end
        end
    end
end

local function unload()
    draw.DeleteTexture(texture)
end

callbacks.Register("Draw", Draw)
callbacks.Register("Unload", unload)

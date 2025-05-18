TOOL.Category = "Construction"
TOOL.Name = "#tool.spawnbox.name"
TOOL.Command = nil
TOOL.ConfigName = ""

if CLIENT then
    language.Add("tool.spawnbox.name", "Spawn Box")
    language.Add("tool.spawnbox.desc", "Spawns a box where you are aiming.")
    language.Add("tool.spawnbox.0", "Left click to spawn a box.")
end

-- Left Click Function
function TOOL:LeftClick(trace)
    if CLIENT then return true end

    local ply = self:GetOwner()
    if not IsValid(ply) then return false end

    local pos = trace.HitPos
    pos.x = math.floor(pos.x/4)*4
    pos.y = math.floor(pos.y/4)*4
    pos.z = math.floor(pos.z/4)*4
    local normal = trace.HitNormal
    local rotangle=ply:EyeAngles()
    rotangle.z = 0
    rotangle.x = 0
    rotangle.y = rotangle.y+90
    print("NORMAL!!!!")
    print(normal)
    
    local angle = normal:Angle()
    local ent = ents.Create("testent")
    if not IsValid(ent) then return false end
    ent:SetSize_X(128)
    ent:SetSize_Y(128)
    ent:SetModel("models/props_c17/oildrum001.mdl") -- You can change this to a cube or other box model
    ent:SetPos(pos)
    if math.abs(normal.z) > 0.95 then
        ent:SetAngles(rotangle)
    else
        ent:SetAngles(normal:Angle())
    end
    //ent.wall_size = Vector(256,256,0)
    ent:Spawn()

    -- Make the spawned box undoable and cleanupable
    undo.Create("Spawned Box")
        undo.AddEntity(ent)
        undo.SetPlayer(ply)
    undo.Finish()

    cleanup.Add(ply, "props", ent)

    return true
end
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

    pos, angle = self:getBoxTransform(trace,ply)
    
    local ent = ents.Create("testent")
    if not IsValid(ent) then return false end
    ent:SetSize_X(128)
    ent:SetSize_Y(128)
    ent:SetThickness(1)
    ent:SetPos(pos)
    ent:SetAngles(angle)
    //ent.wall_size = Vector(256,256,0)
    ent:Spawn()

    undo.Create("Spawned Box")
        undo.AddEntity(ent)
        undo.SetPlayer(ply)
    undo.Finish()

    cleanup.Add(ply, "props", ent)

    return true
end

function TOOL:getBoxTransform(tr,ply)
    local pos = tr.HitPos
    pos.x = math.floor(pos.x/4)*4
    pos.y = math.floor(pos.y/4)*4
    pos.z = math.floor(pos.z/4)*4
    local normal = tr.HitNormal
    local rotangle=ply:EyeAngles()
    rotangle.z = 0
    rotangle.x = 0
    rotangle.y = rotangle.y+90
    if math.abs(normal.z) <= 0.95 then
        rotangle = normal:Angle()
    end
    rotangle.y = math.Round(rotangle.y/45,0)*45
    return pos, rotangle
end

function TOOL:DrawHUD()
    local ply = LocalPlayer()

		local tr = LocalPlayer():GetEyeTrace()

		local pos, ang = self:getBoxTransform(tr,ply)

		cam.Start3D()
		render.DrawWireframeBox( pos, ang, Vector(0,0,0), Vector(128,4,128) )
		cam.End3D()
end
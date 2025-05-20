
TOOL.Category = "Construction"
TOOL.Name = "spawnwall"
--TOOL.Command = nil
--TOOL.ConfigName = ""

TOOL.ClientConVar[ "size_x" ] = "128"
TOOL.ClientConVar[ "size_y" ] = "128"
TOOL.ClientConVar[ "thickness" ] = "4"
TOOL.ClientConVar[ "gridsnap" ] = "4"
TOOL.ClientConVar[ "rotsnap" ] = "45"

TOOL.Information = { { name = "left" } }

if CLIENT then
    language.Add("tool.spawnwall.name", "Spawn Box")
    language.Add("tool.spawnwall.desc", "Spawns a box where you are aiming.")
    language.Add("tool.spawnwall.0", "Left click to spawn a box.")
end

-- Left Click Function
function TOOL:LeftClick(trace)
    if CLIENT then return true end

    local ply = self:GetOwner()
    if not IsValid(ply) then return false end

    pos, angle = self:getBoxTransform(trace,ply)
    
    local ent = ents.Create("testent")
    if not IsValid(ent) then return false end
    local size_x = math.Clamp(math.floor(self:GetClientNumber( "size_x" )),0,256)
    local size_y = math.Clamp(math.floor(self:GetClientNumber( "size_y" )),0,256)
    local thickness = math.floor(self:GetClientNumber( "thickness" ))
    ent:SetSize_X(size_x)
    ent:SetSize_Y(size_y)
    ent:SetThickness(thickness)
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
    local grid_snap = math.max(math.floor(self:GetClientNumber( "gridsnap" )),0)
    if grid_snap ~= 0 then
        pos.x = math.Round(pos.x/grid_snap)*grid_snap
        pos.y = math.Round(pos.y/grid_snap)*grid_snap
        pos.z = math.Round(pos.z/grid_snap)*grid_snap
    end
    local normal = tr.HitNormal
    local rotangle=ply:EyeAngles()
    rotangle.z = 0
    rotangle.x = 0
    rotangle.y = rotangle.y+90
    if math.abs(normal.z) <= 0.95 then
        rotangle = normal:Angle()
    end
    local rot_snap = math.max(math.floor(self:GetClientNumber( "rotsnap" )),0)
    if rot_snap ~= 0 then
        rotangle.y = math.Round(rotangle.y/rot_snap,0)*rot_snap
    end
    return pos, rotangle
end

function TOOL:DrawHUD()
    local ply = LocalPlayer()

		local tr = LocalPlayer():GetEyeTrace()

		local pos, ang = self:getBoxTransform(tr,ply)
        local size_x = math.Clamp(math.floor(self:GetClientNumber( "size_x" )),0,256)
        local size_y = math.Clamp(math.floor(self:GetClientNumber( "size_y" )),0,256)
        local thickness = math.floor(self:GetClientNumber( "thickness" ))
		cam.Start3D()
		render.DrawWireframeBox( pos, ang, Vector(0,0,0), Vector(size_x,thickness,size_y) )
		cam.End3D()
end


--local ConVarsDefault = TOOL:BuildConVarList()
function TOOL.BuildCPanel( CPanel )

	CPanel:Help( "#tool.spawnbox.desc" )
	--CPanel:ToolPresets( "spawnbox", ConVarsDefault )
	CPanel:NumSlider( "#tool.spawnbox.size_x", "spawnwall_size_x", 8, 256 )
    CPanel:NumSlider( "#tool.spawnbox.size_y", "spawnwall_size_y", 8, 256 )
    CPanel:NumSlider( "#tool.spawnbox.thickness", "spawnwall_thickness", 0, 16 )
    CPanel:NumSlider( "#tool.spawnbox.gridsnap", "spawnwall_gridsnap", 0, 128 )
    CPanel:NumSlider( "#tool.spawnbox.rotsnap", "spawnwall_rotsnap", 0, 128 )
end
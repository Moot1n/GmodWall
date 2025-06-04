AddCSLuaFile()
TOOL.Category = "Construction"
TOOL.Name = "spawnwall"
--TOOL.Command = nil
--TOOL.ConfigName = ""

TOOL.ClientConVar[ "size_x" ] = "128"
TOOL.ClientConVar[ "size_y" ] = "128"
TOOL.ClientConVar[ "thickness" ] = "4"
TOOL.ClientConVar[ "gridsnap" ] = "4"
TOOL.ClientConVar[ "rotsnap" ] = "45"

TOOL.ClientConVar[ "leftcon" ] = "1"
TOOL.ClientConVar[ "rightcon" ] = "1"
TOOL.ClientConVar[ "topcon" ] = "1"
TOOL.ClientConVar[ "botcon" ] = "1"
TOOL.ClientConVar[ "rotated"] = "1"

TOOL.ClientConVar["stack_left"] = "1"
TOOL.ClientConVar["stack_up"] = "1"
TOOL.ClientConVar["stack_thick"] = "0"

TOOL.Information = { { name = "left" } }


--[[ TOOL.material_plaster1 = CreateMaterial("breakmat_plaster1", "VertexLitGeneric", {
            ["$basetexture"] = "plaster/plasterwall016a",
            ["$surfaceprop"] = "plaster",
            ["$model"] = "0",
            ["$flat"] = "1",
            ["$nocull"] = "0",
        })
TOOL.material_plaster2 = CreateMaterial("breakmat_plaster2", "VertexLitGeneric", {

            ["$basetexture"] = "plaster/plasterwall005c",
            ["$surfaceprop"] = "plaster",
            ["$model"] = "0",
            ["$flat"] = "1",
            ["$nocull"] = "0",
        })
TOOL.material_woodcrate = CreateMaterial("breakmat_woodcrate", "VertexLitGeneric", {

            ["$basetexture"] = "props/woodcrate001a",
            ["$basetexturetransform"] = "center .5 .5 scale 2 2 rotate 0 translate 0 0",
            ["$surfaceprop"] = "wood_crate",
            ["$model"] = "0",
            ["$flat"] = "1",
            ["$nocull"] = "0",
        })
TOOL.material_woodfloor1 = CreateMaterial("breakmat_woodfloor1","VertexLitGeneric", {
            ["$basetexture"] = "wood/woodfloor005a",
            ["$basetexturetransform"] = "center .5 .5 scale 2 2 rotate 0 translate 0 0",
            ["$surfaceprop"] = "Wood_Panel",
            ["$model"] = "0",
            ["$flat"] = "1",
            ["$nocull"] = "0",
        })
TOOL.material_woodfloor2 = CreateMaterial("breakmat_woodfloor2","VertexLitGeneric", {
            ["$basetexture"] = "wood/woodfloor008a",
            ["$basetexturetransform"] = "center .5 .5 scale 2 2 rotate 0 translate 0 0",
            ["$surfaceprop"] = "Wood_Panel",
            ["$model"] = "0",
            ["$flat"] = "1",
            ["$nocull"] = "0",
        })
TOOL.material_tilefloor = CreateMaterial("breakmat_tilefloor","VertexLitGeneric", {
            ["$basetexture"] = "tile/tilefloor001a",
            ["$basetexturetransform"] = "center .5 .5 scale 1 1 rotate 0 translate 0 0",
            ["$surfaceprop"] = "tile",
            ["$model"] = "0",
            ["$flat"] = "1",
            ["$nocull"] = "0",
        }) ]]
list.Add( "OverrideMaterials", "procedural/large/plaster1" )
list.Add( "OverrideMaterials", "procedural/large/plaster2" )
list.Add( "OverrideMaterials", "procedural/large/tilefloor" )
list.Add( "OverrideMaterials", "procedural/small/woodcrate" )
list.Add( "OverrideMaterials", "procedural/small/woodfloor" )
list.Add( "OverrideMaterials", "procedural/small/woodfloor2" )

-- Left Click Function
function TOOL:LeftClick(trace)
    if CLIENT then return true end

    local ply = self:GetOwner()
    if not IsValid(ply) then return false end
    
    pos, angle = self:getBoxTransform(trace,ply)
    local size_x = math.Clamp(math.floor(self:GetClientNumber( "size_x" )),0,256)
    local size_y = math.Clamp(math.floor(self:GetClientNumber( "size_y" )),0,256)
    local thickness = math.floor(self:GetClientNumber( "thickness" ))
    --self:SpawnTheWall(pos,angle,size_x,size_y,thickness,ply)
    local spawned_wall = false
    local step_i = 1
    if (self:GetClientNumber( "stack_up" )<0) then step_i = -1 end
    for i=0, math.floor(self:GetClientNumber( "stack_up" )-step_i),step_i do
        --render.DrawWireframeBox( pos, ang, Vector(0,0,i*size_y), Vector(size_x,thickness,size_y) )
        
        local upvec = Vector(0,0,i*size_y)
        upvec:Rotate(angle)
        local stackthick = self:GetClientNumber( "stack_thick" )-1
        --if i >= 1 then
        --self:SpawnTheWall(pos+upvec,angle,size_x,size_y,thickness,ply)
        --end
        local step_j = 1
        if (self:GetClientNumber( "stack_left" )<0) then step_j = -1 end
        for j=0,math.floor(self:GetClientNumber("stack_left")-step_j),step_j do
            local leftvec = Vector(j*size_x,0,0)
            leftvec:Rotate(angle)
            leftvec = leftvec+upvec
            --self:SpawnTheWall(pos+leftvec,angle,size_x,size_y,thickness,ply)

            --render.DrawWireframeBox( pos, ang, Vector(j*size_x,0,i*size_y), Vector(size_x,thickness,size_y) )
            local step_k = 1
            local subtract = 0
            if (self:GetClientNumber( "stack_thick" )<0) then 
                step_k = -1 
                subtract = -1
            end
            
            for k=0, stackthick-subtract, step_k do
                local thickvec = Vector(0,-k*thickness,0)
                thickvec:Rotate(angle)
                thickvec = leftvec+thickvec
                spawned_wall = true
                self:SpawnTheWall(pos+thickvec,angle,size_x,size_y,thickness,ply)
                --render.DrawWireframeBox( pos, ang, Vector(j*size_x,-k*thickness,i*size_y), Vector(size_x,thickness,size_y) )
            end
        end
    end
    if not spawned_wall then
        self:SpawnTheWall(pos,angle,size_x,size_y,thickness,ply)
    end

    return true
end

function TOOL:SpawnTheWall(pos,angle,size_x,size_y,thickness,ply)
    local ent = ents.Create("proceduralwall")
    if not IsValid(ent) then return false end
    if self:GetClientNumber( "leftcon" ) == 1 then ent:SetLeftCon(true) else ent:SetLeftCon(false) end
    if self:GetClientNumber( "rightcon" ) == 1 then ent:SetRightCon(true) else ent:SetRightCon(false) end
    if self:GetClientNumber( "topcon" ) == 1 then ent:SetTopCon(true) else ent:SetTopCon(false) end
    if self:GetClientNumber( "botcon" ) == 1 then ent:SetBotCon(true) else ent:SetBotCon(false) end
    ent:SetSize_X(size_x)
    ent:SetSize_Y(size_y)
    ent:SetThickness(thickness)
    ent:SetPos(pos)
    ent:SetAngles(angle)
    ent:Spawn()

    undo.Create("#undo.create.wallname")
        undo.AddEntity(ent)
        undo.SetPlayer(ply)
    undo.Finish()

    cleanup.Add(ply, "props", ent)
end

function TOOL:RightClick( trace )
	-- The SWEP doesn't reload so this does nothing :(
    if self:GetClientNumber( "rotated" ) == 0 then
        RunConsoleCommand("spawnwall_rotated", 1)
    else
        RunConsoleCommand("spawnwall_rotated", 0)
    end
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
        --rotangle.y = rotangle.y+90
    end
    if self:GetClientNumber( "rotated" ) == 1 then
        rotangle.z = rotangle.z+90
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
        local stackthick = self:GetClientNumber( "stack_thick" )-1
		cam.Start3D()
        local step_i = 1
        if (self:GetClientNumber( "stack_up" )<0) then step_i = -1 end
        for i=0, self:GetClientNumber( "stack_up" ),step_i do
            --render.DrawWireframeBox( pos, ang, Vector(0,0,i*size_y), Vector(size_x,thickness,size_y) )
            local step_j = 1
            if (self:GetClientNumber( "stack_left" )<0) then step_j = -1 end
            for j=0,self:GetClientNumber("stack_left"),step_j do
		        --render.DrawWireframeBox( pos, ang, Vector(j*size_x,0,i*size_y), Vector(size_x,thickness,size_y) )
                local step_k = 1
                
                if (stackthick<0) then step_k = -1 end
                for k=0, stackthick, step_k do
                    render.DrawWireframeBox( pos, ang, Vector(j*size_x,-k*thickness,i*size_y), Vector(size_x,thickness,size_y) )
                end
            end
        end
		cam.End3D()
end


--local ConVarsDefault = TOOL:BuildConVarList()
function TOOL.BuildCPanel( CPanel )

	CPanel:Help( "#spawnwall_helptext" )
	--CPanel:ToolPresets( "spawnbox", ConVarsDefault )
	CPanel:NumSlider( "#spawnwall_size_x", "spawnwall_size_x", 8, 256 )
    CPanel:NumSlider( "#spawnwall_size_y", "spawnwall_size_y", 8, 256 )
    CPanel:NumSlider( "#spawnwall_thickness", "spawnwall_thickness", 0, 16 )
    CPanel:NumSlider( "#spawnwall_gridsnap", "spawnwall_gridsnap", 0, 128 )
    CPanel:NumSlider( "#spawnwall_rotsnap", "spawnwall_rotsnap", 0, 128 )
    CPanel:CheckBox("#spawnwall_leftcon", "spawnwall_leftcon")
    CPanel:CheckBox("#spawnwall_rightcon", "spawnwall_rightcon")
    CPanel:CheckBox("#spawnwall_topcon", "spawnwall_topcon")
    CPanel:CheckBox("#spawnwall_botcon", "spawnwall_botcon")

    CPanel:NumSlider("#spawnwall_stack_left", "spawnwall_stack_left",-31,31)
    CPanel:NumSlider("#spawnwall_stack_up", "spawnwall_stack_up",-31,31)
    CPanel:NumSlider("#spawnwall_stack_thick", "spawnwall_stack_thick",-31,31)
end

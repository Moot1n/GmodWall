// Maybe try https://github.com/Bigfoot71/2d-polygon-boolean-lua
// Didn;t work, now try https://github.com/EgoMoose/PolyBool-Lua

local new_poly = include("poly.lua") 
local PolyBool = include("PolyBool/pbinit.lua")

-- Defines the Entity's type, base, printable name, and author for shared access (both server and client)
ENT.Type = "anim" -- Sets the Entity type to 'anim', indicating it's an animated Entity.
ENT.Base = "base_gmodentity" -- Specifies that this Entity is based on the 'base_gmodentity', inheriting its functionality.
ENT.PrintName = "Test Entity" -- The name that will appear in the spawn menu.
ENT.Author = "YourName" -- The author's name for this Entity.
ENT.Category = "Test entities" -- The category for this Entity in the spawn menu.
ENT.Contact = "STEAM_0:1:12345678" -- The contact details for the author of this Entity.
ENT.Purpose = "To test the creation of entities." -- The purpose of this Entity.
ENT.Spawnable = true -- Specifies whether this Entity can be spawned by players in the spawn menu.
ENT.Mins = Vector( 0, 0, 0 )
ENT.Maxs = Vector(  100,  16,  100 )
ENT.mdlScale = 1
ENT.Material = Material( "hunter/myplastic" )
function GetVerts()
    local subject = { regions = {{{0,0}, {100,0}, {100,100}, {0,100}}}, inverted = false }
    local clip = { regions = {{{90,90}, {100,90}, {100,110}, {90,110}}},inverted =false }
    return trianglePoly(subject, clip);
end

function GetVerts2()
    local positions = {
        Vector( -0.5, 0, 0.5 ),
        Vector(  0.5, 0, 0.5 ),
        Vector( -0.5, 0,-0.5 ),

        Vector( -0.5, 0,-0.5 ),
        Vector(  0.5, 0, 0.5 ),
        Vector(  0.5, 0, -0.5 ),
    };
    return positions;
end

-- Bridge Holes
local function connectHoles(outer, holes)
    -- First copy outer to a new polygon
    local copy = {}
    for i=1, #outer do
        local curr_x = outer[i][1]
        local curr_y = outer[i][2]
        table.insert(copy, {curr_x,curr_y})
    end
    for _, hole in ipairs(holes) do
        -- Naive bridge: connect rightmost point of hole to closest outer vertex
        
        
        
        
        
        local rightmost = hole[1]
        for _, p in ipairs(hole) do
            
            if p[1] > rightmost[1] then rightmost = p end
        end

        local bridgeIndex = 1
        local minDist = math.huge
        for i, p in ipairs(copy) do
            print("TEST")
            print(p[1])
            local dx = p[1] - rightmost[1]
            local dy = p[2] - rightmost[2]
            local dist = dx*dx + dy*dy
            if dist < minDist then
                minDist = dist
                bridgeIndex = i
            end
        end
        
        -- Insert bridge and hole into outer polygon
        local bridgePoint = copy[bridgeIndex]
        table.insert(copy, bridgeIndex, rightmost)
        
        for _, p in ipairs(hole) do
            table.insert(copy, bridgeIndex + 1, p)
        end
        table.insert(copy, bridgeIndex + #hole + 1, bridgePoint)
    end
    
    return copy
end

function trianglePoly(subject, clip)
    
    local output = PolyBool.difference(subject,clip)
    local poly = new_poly{}
    local geoOutput = PolyBool.polygonToGeoJSON(output)
    print("GEOOUTPUT")
    local sub2 = geoOutput.coordinates
    local holes = {}
    print(#sub2)
    for i = 1, #sub2 do
        print("Geo Polygon "..i)
        for j = 2, #sub2[i] do
            print("region "..j)
            if i == 1 then
                table.insert(holes,sub2[i][j])
            end
        end
    end
    local polyconnect = connectHoles(sub2[1][1], holes)
    print("POLYCONNECT")
    print(polyconnect)
    for i = 1, #polyconnect do
        print(polyconnect[i][1], polyconnect[i][2])
        poly:push_coord(polyconnect[i][1],polyconnect[i][2])
    end


    --[[ local sub = output.regions
    
    for i, result in ipairs(sub) do
        if i == #sub then
            print("result "..i..": ")
            
            for j = 1, #result do
                print(
                    "x"..(j)..": "..result[j][1],
                    "y"..(j)..": "..result[j][2]
                )
                poly:push_coord(result[j][1],result[j][2])
            end
        end
    end ]]
    
    poly:close()
    local triangles = poly:get_triangles()
    
    print("TriangleasdPol")
    local positions = {}
    for i = 1, #triangles do
        for j =1, 3 do
            local i1 = triangles[i][j]
            local x,y = poly:get_coord(i1)
            table.insert(positions, Vector(x,0,y))
        end
    end
    for i = 1, #positions do
        print(positions[i])
    end
   
    return output, positions;
end

function ENT:GetVertsPhys()
    local out_polygon, positions = GetVerts()
    for i = 1, #positions do
        positions[i] = positions[i]*self.mdlScale
    end
    self.PhysicsPoly = out_polygon
    self.RenderPoly = out_polygon
    return positions
end


function ENT:OnTakeDamage(damage)
    local damagepos = damage:GetDamagePosition()
    if not CLIENT then
        print("DAMAGE")
        print(damagepos) 
        --self:UpdateMeshHit(self:WorldToLocal(damagepos))
        --self:PhysicsFromMesh(self.physicsPoly)
    end
 end

function ENT:ImpactTrace(trace,dmgtype,customimpactname)
    local damagepos = trace.HitPos
	if CLIENT then
        print(self:WorldToLocal(damagepos))
        self:UpdateMeshHit(self:WorldToLocal(damagepos))
    end
end


function ENT:Initialize()
    --trianglePoly()
    local current_polygons = {}
    if CLIENT then
        self:CreateMesh()
        self:SetRenderBounds( self.Mins, self.Maxs )

        self:DrawShadow( false )
    end
    

	
    
    if not CLIENT then
        --self:PhysicsInitConvex(GetVerts())
        self:SetModel("models/props_c17/FurnitureCouch002a.mdl") -- Sets the model for the Entity.
        self:PhysicsDestroy()
        self:PhysicsFromMesh( self:GetVertsPhys() )
        self:SetSolid( SOLID_VPHYSICS ) -- Makes the Entity solid, allowing for collisions.
        self:SetMoveType( MOVETYPE_NONE ) -- Sets how the Entity moves, using physics.
        self:EnableCustomCollisions()
        self:GetPhysicsObject():EnableMotion(false)
        --self:PhysicsInit( SOLID_VPHYSICS ) -- Initializes physics for the Entity, making it solid and interactable.
       
        
        
        -- Enable custom collisions on the entity
        -- self:PhysicsInitConvex( self:GetVertsPhys())
    end
    if CLIENT then
        self:PhysicsFromMesh( self:GetVertsPhys() )
    end
	--self:GetPhysicsObject():EnableMotion( false )

	
    if not CLIENT then
        local phys = self:GetPhysicsObject() -- Retrieves the physics object of the Entity.
        if phys:IsValid() then -- Checks if the physics object is valid.
            --phys:SetMass(math.sqrt(phys:GetVolume()))
            
            phys:SetMaterial("glass")
            phys:Wake() -- Activates the physics object, making the Entity subject to physics (gravity, collisions, etc.).
        end
    end
end

function ENT:CreateMesh()
    local texcoord  = {
        Vector( 1, 0, 1 ),
        Vector(  1, 1, 0 ),
        Vector( 1, 0,0 ),
    }
    local out_polygon, positions = GetVerts()
    local mesh = mesh
    self.RenderMesh = Mesh(self.Material)
    self.RenderPoly = out_polygon
    print("TRIANGLE COUNT")
    
    mesh.Begin(self.RenderMesh, MATERIAL_TRIANGLES, math.floor(#positions/3))
    
    local j = 1
    for i = 1, #positions do
        --mesh.TexCoord( texcoord[j])
        mesh.Position( positions[i]*self.mdlScale)
        mesh.AdvanceVertex()
        j = j+1
        if j > 3 then
            j = 1
        end
    end
    mesh.End()
end

function ENT:UpdateMeshHit(localhitpos)
    local texcoord  = {
        Vector( 1, 0, 1 ),
        Vector(  1, 1, 0 ),
        Vector( 1, 0,0 ),
    }
    --local subject = { regions = {{{0,0}, {100,0}, {100,100}, {0,100}}}, inverted = false }
    local subject = self.RenderPoly
    --local clip = { regions = {{{-5,-5}, {5,-5}, {5,5}, {-5,5}}},inverted =false }
    local clip = { regions = {{{-5,-5}, {5,-5}, {5,5}, {-5,5}}},inverted =false }
    for i = 1, #clip.regions do
        for j = 1, #clip.regions[i] do
            clip.regions[i][j][1] = localhitpos[1] + clip.regions[i][j][1]
            clip.regions[i][j][2] = localhitpos[3] + clip.regions[i][j][2]
        end
    end
    local out_polygon, positions = trianglePoly(subject, clip);
    self.RenderPoly = out_polygon
    if not CLIENT then
    self:PhysicsFromMesh(positions)
        return
    end
    self:PhysicsFromMesh(positions)
    local mesh = mesh
    self.RenderMesh = Mesh(self.Material)
    
    print("SUBJECT")
    print(self.RenderPoly)
    mesh.Begin(self.RenderMesh, MATERIAL_TRIANGLES, math.floor(#positions/3))
    local j = 1
    for i = 1, #positions do
        --mesh.TexCoord( texcoord[j])
        mesh.Position( positions[i]*self.mdlScale)
        mesh.AdvanceVertex()
        j = j+1
        if j > 3 then
            j = 1
        end
    end
    mesh.End()
end

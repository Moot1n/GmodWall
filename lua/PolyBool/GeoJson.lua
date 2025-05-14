-- Moot1n Port of GeoJson to Lua
-- Original https://github.com/velipso/polybooljs/blob/master/lib/geojson.js

AddCSLuaFile()
local GeoJson = {
    fromPolygon = function(PolyBool, eps, poly)
        function regionInsideRegion(r1, r2)
            return eps.pointInsideRegion(
                
                {(r1[1][1]+r1[2][1])*0.5,
                (r1[1][2]+r1[2][2])*0.5},r2)
        end
        
        function newNode(reg)
            return {region = reg, children = {}}
        end

        local roots = newNode(nil)
        
        function addChild(root, region)
            -- first check if we're inside any children
            for i=1, #root.children do
                local child = root.children[i]
                -- we are, so insert inside them instead
                if regionInsideRegion(region, child.region) then
                    
                    addChild(child, region)
                    return
                
                end
            end

            -- not inside any children, so check to see if any children are inside us
            local node = newNode(region)
            local i = 1
            while i <= #root.children do
                local child = root.children[i]

                if (regionInsideRegion(child.region, region)) then
                    -- oops... move the child beneath us, and remove them from root
                    table.insert(node.children,child)
                    table.remove(root.children, i)
                    i = i - 1
                end
                i = i + 1
            end
            table.insert(root.children, node)
        end

        for i=1, #poly.regions do
            local region = poly.regions[i]
            if #region >= 3 then 
                addChild(roots, region)
            end
        end
        
        function forceWinding(region, clockwise)
            local winding = 0
            local last_x = region[#region][1]
            local last_y = region[#region][2]
            local copy = {}
            for i=1, #region do
                local curr_x = region[i][1]
                local curr_y = region[i][2]
                table.insert(copy, {curr_x,curr_y})
                winding = winding + curr_y*last_x-curr_x*last_y
                last_x = curr_x
                last_y = curr_y
            end
            local isclockwise = winding < 0
            print("ISCLOCK "..winding  )
            if isclockwise ~= clockwise then
                print("FORCED")
                --table.Reverse(copy)
                for i = 1, math.floor(#copy/2), 1 do
                    copy[i], copy[#copy-i+1] = copy[#copy-i+1], copy[i]
                end
            end
            -- Make Last Point First Point, Probably could remove this
            -- table.insert(copy,{copy[1][1],copy[1][2]})
            return copy
        end

        local geopolys = {}

        function addExterior(node)
            local poly = {forceWinding(node.region, true)}
            table.insert(geopolys,poly)

            for i=1, #node.children do
                table.insert(poly, getInterior(node.children[i]))
            end
        end

        function getInterior(node)
            for i=1, #node.children do
                addExterior(node.children[i])
            end
            return forceWinding(node.region, true)
        end

        for i=1, #roots.children do
            addExterior(roots.children[i])
        end
        if #geopolys <= 0 then
            return {type = "Polygon", coordinates = {}}
        end
        return {type = "Polygon", coordinates = geopolys}
    end
}
return GeoJson
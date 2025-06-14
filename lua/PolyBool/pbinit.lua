--[[
 * @copyright 2016 Sean Connelly (@voidqk), http://syntheti.cc
 * @license MIT
 * @preserve Project Home: https://github.com/voidqk/polybooljs

   Converted to Lua by EgoMoose
--]]
AddCSLuaFile()
local Epsilon = include("PolyBool/Epsilon.lua")
local Intersecter = include("PolyBool/Intersector.lua")
local SegmentChainer = include("PolyBool/SegmentChainer.lua")
local SegmentSelector = include("PolyBool/SegmentSelector.lua")
local GeoJson = include("PolyBool/GeoJson.lua")

local epsilon = Epsilon()
local buildLog = false

local PolyBool
PolyBool = {
	-- getter/setter for epsilon
	epsilon = function(v)
		return epsilon.epsilon(v)
	end,

	-- core API
	segments = function(poly)
		local i = Intersecter(true, epsilon, buildLog)
		for _, reg in next, poly.regions do
			i.addRegion(reg)
		end
		return {
			segments = i.calculate(poly.inverted),
			inverted = poly.inverted
		}
	end,
	combine = function(segments1, segments2)
		local i3 = Intersecter(false, epsilon, buildLog)
		return {
			combined = i3.calculate(
				segments1.segments, segments1.inverted,
				segments2.segments, segments2.inverted
			),
			inverted1 = segments1.inverted,
			inverted2 = segments2.inverted
		}
	end,
	selectUnion = function(combined)
		return {
			segments = SegmentSelector.union(combined.combined, buildLog),
			inverted = combined.inverted1 or combined.inverted2
		}
	end,
	selectIntersect = function(combined)
		return {
			segments = SegmentSelector.intersect(combined.combined, buildLog),
			inverted = combined.inverted1 and combined.inverted2
		}
	end,
	selectDifference = function(combined)
		return {
			segments = SegmentSelector.difference(combined.combined, buildLog),
			inverted = combined.inverted1 and not combined.inverted2
		}
	end,
	selectDifferenceRev = function(combined)
		return {
			segments = SegmentSelector.differenceRev(combined.combined, buildLog),
			inverted = not combined.inverted1 and combined.inverted2
		}
	end,
	selectXor = function(combined)
		return {
			segments = SegmentSelector.xor(combined.combined, buildLog),
			inverted = combined.inverted1 ~= combined.inverted2
		}
	end,
	polygon = function(segments)
		return {
			regions = SegmentChainer(segments.segments, epsilon, buildLog),
			inverted = segments.inverted
		}
	end,
	-- GeoJson Converters
	polygonToGeoJSON = function(poly)
		return GeoJson.fromPolygon(PolyBool, epsilon, poly)
	end,
	-- helper functions for common operations
	union = function(poly1, poly2)
		return operate(poly1, poly2, PolyBool.selectUnion)
	end,
	intersect = function(poly1, poly2)
		return operate(poly1, poly2, PolyBool.selectIntersect)
	end,
	difference = function(poly1, poly2)
		return operate(poly1, poly2, PolyBool.selectDifference)
	end,
	differenceRev = function(poly1, poly2)
		return operate(poly1, poly2, PolyBool.selectDifferenceRev)
	end,
	xor = function(poly1, poly2)
		return operate(poly1, poly2, PolyBool.selectXor)
	end,
	differences1 = function(poly1, poly2)
		return operate_stage1(poly1, poly2)
	end,
	differences2 = function(seg1,seg2)
		return operate_stage2(seg1,seg2,PolyBool.selectDifference)
	end
}

function operate(poly1, poly2, selector)
	local seg1 = PolyBool.segments(poly1)
	local seg2 = PolyBool.segments(poly2)
	local comb = PolyBool.combine(seg1, seg2)
	local seg3 = selector(comb)
	return PolyBool.polygon(seg3)
end

function operate_stage1(poly1, poly2)
	
	local seg1 = PolyBool.segments(poly1)
	
	local seg2 = PolyBool.segments(poly2)
	return seg1, seg2
end

function operate_stage2(seg1,seg2,selector)
	
	local comb = PolyBool.combine(seg1, seg2)
	local seg3 = selector(comb)
	return PolyBool.polygon(seg3)
end
return PolyBool
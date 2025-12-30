This is a gmod version of the Source Engine Procedural destruction. It uses LUA instead of C++, making it more laggy. However, gmod provides alot more interface with the physics engine than Source SDK, so the physics is fully functional. 
Unfortunately there is no easy interface to get lightmaps. This time I borrowed some libraries to do the polygon clipping and triangulation. 

Credits:
EgoMoose - LUA Port of Sean M Connelly's PolyboolJS https://github.com/EgoMoose/PolyBool-Lua?tab=readme-ov-file
David Gayerie - LUAPoly polygon ear clipping algorithm https://github.com/spoonless/luapoly

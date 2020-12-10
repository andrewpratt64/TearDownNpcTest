-- Andrew Pratt 2020
-- NPC Mod


local function VecToString(vec)
	return "Vec(" .. vec[1] .. ", " .. vec[2] .. ", " .. vec[3] .. ")";
end


-- Like QuatLookAt, but only affects yaw rotation
local function QuatLookAtOnYaw(eye, target)
	return QuatLookAt( eye, Vec(target[1], eye[2], target[3]) );
end


local function MakeBodyLookAtOnYaw(body, target)
	local bodyPos = GetBodyTransform(body).pos;
	SetBodyTransform( body, Transform( bodyPos, QuatLookAtOnYaw(bodyPos, target) ) );
end


function updateNpcBody(body)
	--local t = GetBodyTransform(body);
	local plyT = GetPlayerTransform();
	
	-- Make npc face the player
	MakeBodyLookAtOnYaw(body, plyT.pos);
end



function init()
	npcBody = nil;
	npcShape = FindShape("npc", true);
	
	if (npcShape ~= 0) then
		npcBody = GetShapeBody(npcShape);
		if (IsHandleValid(npcBody)) then
			SetBodyDynamic(npcBody, false);
		end
	end
end
	
	
function tick()
end


function update()
	if (IsHandleValid(npcBody)) then
		updateNpcBody(npcBody);
	end
end


function draw()
	
end
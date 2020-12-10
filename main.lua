-- Andrew Pratt 2020
-- NPC Mod


local function VecToString(vec)
	return "Vec(" .. vec[1] .. ", " .. vec[2] .. ", " .. vec[3] .. ")";
end


local function VecDiff(vecA, vecB)
	return VecLength( VecSub(vecB, vecA) );
end

-- TODO: better/less confusing name for this function
local function VecSwizzleXZ(vec)
	return Vec( vec[1], 0, vec[3] );
end


-- Like QuatLookAt, but only affects yaw rotation
local function QuatLookAtOnYaw(eye, target)
	return QuatLookAt( eye, Vec(target[1], eye[2], target[3]) );
end


local function MakeBodyLookAtOnYaw(body, target)
	local bodyPos = GetBodyTransform(body).pos;
	SetBodyTransform( body, Transform( bodyPos, QuatLookAtOnYaw(bodyPos, target) ) );
end

local function AddBodyVelocity(body, addVec)
	SetBodyVelocity( body, VecAdd( GetBodyVelocity(body), addVec ) );
end

local function OffsetBodyPos(body, offset)
	local t = GetBodyTransform(body);
	SetBodyTransform( body, Transform( VecAdd(t.pos, offset), t.rot ) );
end



function updateNpcBody(body)
	-- Get transform for npc and the player
	local t = GetBodyTransform(body);
	local plyT = GetPlayerTransform();
	
	-- Make npc face the player
	MakeBodyLookAtOnYaw(body, plyT.pos);
	
	-- Store npc's direction from itself to the player as a normalized vector
	local dir = VecNormalize(VecSub(plyT.pos, t.pos));
	
	foo = VecDiff(t.pos, plyT.pos);
	
	-- If the npc is far enough from the player that it should move...
	if (VecDiff(t.pos, plyT.pos) > 1.1) then
		-- Move npc forward
		--AddBodyVelocity(body, VecScale(dir, 0.25));
		OffsetBodyPos( body, VecScale( VecSwizzleXZ(dir), 0.1 ) );
	end
end



function init()
	foo = "nil";
	npcBody = nil;
	npcShape = FindShape("npc_torso", true);
	
	if (npcShape ~= 0) then
		npcBody = GetShapeBody(npcShape);
		if (IsHandleValid(npcBody)) then
			SetBodyDynamic(npcBody, true);
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
	DebugWatch("foo", foo);
end
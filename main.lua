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


local function MakeBodyLookAt(body, target)
	local bodyPos = GetBodyTransform(body).pos;
	SetBodyTransform( body, Transform( bodyPos, QuatLookAt(bodyPos, target) ) );
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


local function isNpcBodyValid(npc)
	return (IsHandleValid(npc.torsoBody) and IsHandleValid(npc.headBody));
end

local function OffsetNpcPos(npc, offset)
	OffsetBodyPos(npc.torsoBody, offset);
	OffsetBodyPos(npc.headBody, offset);
end

local function killNpc(npc)
	SetBodyDynamic(npc.torsoBody, true);
	SetBodyDynamic(npc.headBody, true);
	npc.bAlive = false;
end



function updateNpc(npc)
	-- Get transform for npc, player, and the camera
	local torsoT = GetBodyTransform(npc.torsoBody);
	local headT = GetBodyTransform(npc.headBody);
	local plyT = GetPlayerTransform();
	local camT = GetCameraTransform();
	
	
	-- Handle npc death
	if (IsBodyBroken(npc.headBody) == true) then
		killNpc(npc);
		
		-- Grab all bodies that *probably* came from the npc's head
		local headBoundsMin, headBoundsMax = GetBodyBounds(npc.headBody);
		QueryRequire("physical dynamic small");
		--QueryAabbBodies( VecSub( headT.pos, Vec(0.2, 0, 0.2) ), VecAdd( headT.pos, Vec(0.2, 0.3, 0.2) ) );
		local potentialHeadBodies = QueryAabbBodies(headBoundsMin, headBoundsMax);
		
		-- Give physics and a small impulse to the head debris to prevent floating pieces
		for _, headDebrisBody in pairs(potentialHeadBodies) do
			SetBodyDynamic(headDebrisBody, true);
			
			local headDebrisT = GetBodyTransform(headDebrisBody);
			ApplyBodyImpulse( headDebrisBody, VecSub( headDebrisT.pos, Vec(0, 0.01, 0) ), Vec(0, 0.01, 0) );
		end
	end	
	
	-- Make npc face the player
	MakeBodyLookAtOnYaw(npc.torsoBody, plyT.pos);
	MakeBodyLookAt(npc.headBody, camT.pos);
	
	-- Store npc's direction from itself to the player as a normalized vector
	local dir = VecNormalize(VecSub(plyT.pos, torsoT.pos));
	
	-- If the npc is far enough from the player that it should move...
	if (VecDiff(torsoT.pos, plyT.pos) > 1.1) then
		-- Move npc forward
		--AddBodyVelocity(body, VecScale(dir, 0.25));
		OffsetNpcPos( npc, VecScale( VecSwizzleXZ(dir), 0.1 ) );
	end
end


function npc_init()
	-- TODO: Implement an npc class
	npc = {
		torsoBody = nil;
		torsoShape = nil;
		
		headBody = nil;
		headShape = nil;
		
		neckJoint = nil;
		
		bAlive = true;
	};
	
	--DebugPrint("body found: " .. FindBody("npc", true));
	
	npc.torsoShape = FindShape("npc_torso", true);
	npc.headShape = FindShape("npc_head", true);
	
	if (npc.torsoShape ~= 0) then
		npc.torsoBody = GetShapeBody(npc.torsoShape);
		if (IsHandleValid(npc.torsoBody)) then
			SetBodyDynamic(npc.torsoBody, false);
		end
	end
	
	if (npc.headShape ~= 0) then
		npc.headBody = GetShapeBody(npc.headShape);
		if (IsHandleValid(npc.headBody)) then
			SetBodyDynamic(npc.headBody, false);
			
			npc.neckJoint = FindJoint("npc_joint_neck", true);
		end
	end
end

function init()
	local status, err = pcall(npc_init);
	
	if (status == false) then
		DebugPrint("LUA ERROR IN MOD npc IN FUNCTION init: " .. err);
	end
end
	
	
function tick()
	
end


function npc_update()
	if (isNpcBodyValid(npc) and npc.bAlive == true) then
		updateNpc(npc);
	end
end

function update()
	local status, err = pcall(npc_update);
	
	if (status == false) then
		--DebugPrint("LUA ERROR IN MOD npc IN FUNCTION update: " .. err);
	end
end


function draw()
end
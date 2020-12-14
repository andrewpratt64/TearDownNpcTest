-- Andrew Pratt 2020
-- Npc class

-- IMPORTANT NOTE TO SELF: Methods like GetBodyTransform return copies of the tabels, not references to the original

#include "npc_util.lua"

Npc = {};
Npc.__index = Npc;

setmetatable(Npc, {
	__call = function(cls, ...) return cls.new(...); end
});

--	=CONSTRUCTOR=
function Npc.new(name)
	local self = setmetatable({}, Npc);
	
	-- Init name
	self.name = name;
	
	-- Init npc body
	self.body = FindBody("npc_" .. self.name, true);
	if (IsHandleValid(self.body) == false) then
		DebugPrint("WARNING: Could not find npc <body> named \"" .. name .. '\"' );
	end
	
	-- Init head body
	self.headBody = FindBody("npc_head_" .. self.name, true);
	
	
	-- Init death boolean
	self.bDead = false;
	
	-- Init velocity
	-- Stored in m/s
	self.vel = Vec();
	
	-- Init move speed
	-- This is how fast the npc moves when it is walking
	self.moveSpeed = 1.56464;
	
	-- Init max step height
	self.maxStepHeight = 0.4;
	
	
	
	-- Make sure physics are disabled
	self:SetDynamic(false);
	
	return self;
end


--	=GETS/SETS=
function Npc:GetName()
	return self.name;
end

-- Npc pos
function Npc:GetPos()
	return GetBodyTransform(self.body).pos;
end
function Npc:SetPos(pos)
	self:SetTransform( Transform( pos, self:GetRot() ) );
end
function Npc:AddPos(pos)
	self:SetPos( VecAdd( self:GetPos(), pos ) );
end
-- Get/add to pos only if npc can fit
-- Returns true if npc was moved
function Npc:SetPosSafe(pos)
	if ( self:CanFitAtPos(pos) ) then
		self:SetTransform( Transform( pos, self:GetRot() ) );
		return true;
	end
	return false;
end
function Npc:AddPosSafe(pos)
	return self:SetPosSafe( VecAdd( self:GetPos(), pos ) );
end


-- Npc rot
function Npc:GetRot()
	return GetBodyTransform(self.body).rot;
end
function Npc:SetRot(rot)
	self:SetTransform( Transform( self:GetPos(), rot ) );
end
function Npc:AddRot(rot)
	self:SetRot( QuatRotateQuat( self:GetRot(), rot ) );
end


-- Npc Body
function Npc:GetBody()
	return self.body;
end


-- Npc Transform
function Npc:GetTransform()
	return GetBodyTransform(self.body);
end
function Npc:SetTransform(t)
	-- Get body transform before mutation
	local preBodyT = GetBodyTransform(self.body);
	
	-- Get head body transform local to the npc body
	local headBodyLocalT = TransformToLocalTransform( preBodyT, GetBodyTransform(self.headBody) );
	
	-- Mutate npc body
	SetBodyTransform(self.body, t);
	-- Mutate head
	SetBodyTransform( self.headBody, TransformToParentTransform( GetBodyTransform(self.body), headBodyLocalT ) );
end


-- Dynamic physics
function Npc:IsDynamic()
	-- If the npc body is dynamic, consider the npc to be dynamic
	return IsBodyDynamic(self.body);
end
function Npc:SetDynamic(val)
	SetBodyDynamic(self.body,		val);
	SetBodyDynamic(self.headBody,	val);
end


-- Velocity
function Npc:GetVel()
	return self.vel;
end
function Npc:SetVel(vel)
	self.vel = vel;
end
function Npc:AddVel(vel)
	self:SetVel( VecAdd(self:GetVel(), vel) );
end


-- Move speed
function Npc:GetMoveSpeed()
	return self.moveSpeed;
end
function Npc:SetMoveSpeed(speed)
	-- Enforce that move speed is not negative
	self.moveSpeed = math.max(0.0, speed);
end


-- Bounding Box
function Npc:GetBounds()
	-- Get bounding boxes of individual bodies of npc
	local bodyBoundMin, bodyBoundMax = GetBodyBounds(self.body);
	local headBodyBoundMin, headBodyBoundMax = GetBodyBounds(self.headBody);
	-- Return absolute min and max bounding boxes
	return NpcUtil.VecMin(bodyBoundMin, headBodyBoundMin), NpcUtil.VecMax(bodyBoundMax, headBodyBoundMax);
end
-- Size npc of bounding box
-- aka pos of max bounding box coord relative to the min coord as a Vector
function Npc:GetBoundsSize()
	-- Get npc bounding box coords
	local bboxMin, bboxMax = self:GetBounds();
	-- Return the signed distance from the min coord to the max
	return VecSub(bboxMax, bboxMin);
end



--	=PREDICATES=
-- (Some predicate methods are in the get/set area, these are the ones that don't really have a mutator method)

function Npc:IsValid()
	return IsHandleValid(self.body);
end

function Npc:IsDead()
	return self.bDead;
end

-- Returns true if npc can fit at the given position
function Npc:CanFitAtPos(pos)
	-- If the highest point we will collide with at pos is too high...
	if ( NpcUtil.GetHighestPointInAABBWithBodyRejects( pos, VecAdd( pos, self:GetBoundsSize() ), {self.body, self.headBody} )[2] - self:GetPos()[2] > self.maxStepHeight ) then
		-- We can't fit; return false;
		return false;
	end
	return true;
end



--	=METHODS=
-- Make npc face the given target position
function Npc:FacePos(target)
	-- Rotate the entire body's yaw to face target
	self:RotateYawToFacePos(target);
	-- Rotate head to face target
	self:FaceHeadTowardsPos(target);
end

-- Rotate the npc to face the given target position, but only rotate yaw
function Npc:RotateYawToFacePos(target)
	self:SetRot( NpcUtil.QuatLookAtOnYaw( GetBodyTransform(self.body).pos, target ) );
end

-- Rotate npc's head to face the given target position
function Npc:FaceHeadTowardsPos(target)
	local headPos = GetBodyTransform(self.headBody).pos;
	SetBodyTransform( self.headBody, Transform( headPos, QuatLookAt( headPos, target ) ) );
end


-- Kill the npc immediately
function Npc:Die()
	-- Set dead value to true
	self.bDead = true;
	
	-- Enable physics
	self:SetDynamic(true);
	
	-- Grab all bodies that *probably* came from the npc's head
	local headBoundsMin, headBoundsMax = GetBodyBounds(self.headBody);
	QueryRequire("physical dynamic small");
	local potentialHeadBodies = QueryAabbBodies(headBoundsMin, headBoundsMax);
	
	-- Enable dynamic physics and give a small impulse to the head debris to prevent floating pieces
	for _, headDebrisBody in pairs(potentialHeadBodies) do
		SetBodyDynamic(headDebrisBody, true);
		ApplyBodyImpulse( headDebrisBody, VecSub( GetBodyTransform(headDebrisBody).pos, Vec(0, 0.01, 0) ), Vec(0, 0.01, 0) );
	end
end


-- Set npc's velocity so that it's moving at a given speed (in m/s) towards a given target position
-- Velocity is set so that the npc will move horizontally, i.e. it's y-velocity will be zero
function Npc:MoveTowardsPosHorizontally(speed, target)
	self:SetVel(
		VecScale(
			VecNormalize(
				NpcUtil.VecSwizzleXZ(
					VecSub(
						target,
						self:GetPos()
					)
				)
			),
			speed
		)
	);
end


-- Update npc's position based on it's current velocity in m/s
function Npc:ApplyVel(dt)
	self:AddPosSafe( VecScale(self.vel, dt) );
end


-- Figure out if we just now died, and decide what to do about it
function Npc:HandlePotentialDeath()
	-- Only force the npc to die if we died since the last time we checked
	if (
		(self.bDead == false) and (
			not (
				IsHandleValid(self.headBody) and not IsBodyBroken(self.headBody)
			)
		)
	) then
		self:Die();
	end
end


-- Update physics
function Npc:updatePhys(dt)
	-- Update position based on velocity
	self:ApplyVel(dt);
end


function Npc:update(dt)
	-- Only update if we're valid
	if (not self:IsValid()) then return; end
	
	-- Handle our potential death
	self:HandlePotentialDeath();

	if (not self.bDead) then
		-- Update physics
		self:updatePhys(dt);
		
		local targetPos = GetCameraTransform().pos;
		
		-- Face the player
		self:FacePos(targetPos);
		-- Move towards the player
		self:MoveTowardsPosHorizontally(self.moveSpeed, targetPos);
	end
end
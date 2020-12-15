-- Andrew Pratt 2020
-- Npc class

-- TODO: Center of npc shouldn't pass over edge of cliff

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
	
	-- Init middair boolean
	-- True when npc has nothing below it
	self.bInAir = false;
	
	-- Init velocity
	-- Stored in m/s
	self.vel = Vec();
	
	-- Init move speed
	-- This is how fast the npc moves when it is walking
	self.moveSpeed = 1.56464;
	
	-- Init max step height in meters
	-- The npc can move up or down a slope up to this value
	self.maxStepHeight = 0.4;
	
	-- Init max dist from player in meters
	self.maxDistFromPlayer = 0.71;
	
	-- Init vertical acceleration due to gravity in m/s^2
	self.gravity = -9.8;
	
	-- Amount to scale npc's mass by.
	-- Useful for when materials that aren't human flesh make
	--  up the npc, so that it dosen't have an insane mass
	self.massScale = 1.0;
	
	-- Init min velocity threshold
	-- Any components of velocity less than this amount are considered zero
	self.minVelThreshold = 0.001;
	
	-- How many times to do a physics update during a single game update
	-- More steps means more accurate physics, 
	
	
	
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
	local canFit = self:CanFitAtPos(pos);
	
	if (canFit and NpcUtil.VecDiff(pos, GetPlayerTransform().pos) >= self.maxDistFromPlayer ) then
	
		self:SetTransform( Transform( pos, self:GetRot() ) );
	
		return true;
	end
	
	return false;
end
function Npc:AddPosSafe(pos)
	return self:SetPosSafe( VecAdd( self:GetPos(), pos ) );
end

-- Attempt to move npc to given pos
-- Npc pos may not be a bit different than pos due to stepping, collision, etc.
-- If canStep is true, npc will move up/down to be standing on top of surface (defaults to true)
-- Returns true if npc was moved
-- TODO: Is return value even needed?
function Npc:AttemptMoveTo(pos, canStep)
	canStep = canStep or true;
	local highestMovePoint = nil;
	
	-- Get our bounding box size
	local boundsSize = self:GetBoundsSize();
	-- Get our new boundary points
	local newBoundsMin, newBoundsMax = self:GetBoundsAt(pos);
	
	-- If we're in middair...
	if (self.bInAir) then
		
		-- If we're NOT rising...
		if (self.vel[2] <= self.minVelThreshold) then
			
			-- Get the highest point we can land on 
			highestMovePoint = NpcUtil.GetHighestPointInAABBWithBodyRejects(
				newBoundsMin,
				Vec(
					newBoundsMax[1],
					newBoundsMin[2] + self.maxStepHeight,
					newBoundsMax[3]
				),
				{self.body, self.headBody}
			);
			
			-- If there's nowhere to land, we can just go as low as pos since nothing is stopping us
			if (highestMovePoint == nil) then
				
				highestMovePoint = pos;
			end
			
			-- Try to move
			-- Return if we moved or not
			if (self:SetPosSafe(pos)) then
				return true;
			end
			
			-- If we couldn't move, set horizontal velocity to zero then return false
			self.vel = Vec(0, self.vel[2], 0);
			return false;
			
		else
			-- If we are rising...
			-- TODO: Only stop motion in collision direction?
			-- Try to move
			-- Return if we moved or not
			if (self:SetPosSafe(pos)) then
				return true;
			end
			-- If we couldn't move, set velocity to zero then return false
			self.vel = Vec(0, 0, 0);
			return false;
		end
	end
	
	-- Otherwise, we're on the ground
	-- Get the highest point we can step on 
	highestMovePoint = NpcUtil.GetHighestPointInAABBWithBodyRejects(
		Vec(
			newBoundsMin[1],
			newBoundsMin[2] - self.maxStepHeight,
			newBoundsMin[3]
		),
		Vec(
			newBoundsMax[1],
			newBoundsMin[2] + self.maxStepHeight,
			newBoundsMax[3]
		),
		{self.body, self.headBody}
	);

	-- Try to move
	if ( highestMovePoint == nil or self:SetPosSafe( Vec( pos[1], highestMovePoint[2] + 0.1, pos[3] ) ) == false ) then
		-- If we couldn't move, set velocity to zero then return false
		self.vel = Vec(0, 0, 0);
		return false;
	end
	
	-- Otherwise, we moved; return true
	return true;
end

-- Same as above, but adds to position instead
function Npc:AttemptMoveBy(pos, canStep)
	return self:AttemptMoveTo( VecAdd( self:GetPos(), pos ), canStep );
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
-- Get npc bounding box if it were at a specific spot
function Npc:GetBoundsAt(pos)
	local boundsSize = self:GetBoundsSize();
	
	return Vec(
		pos[1] - boundsSize[1] * 0.5,
		pos[2],
		pos[3] - boundsSize[3] * 0.5
	),
	Vec(
		pos[1] + boundsSize[1] * 0.5,
		pos[2] + boundsSize[2],
		pos[3] + boundsSize[3] * 0.5
	);
end



-- Mass and weight
function Npc:GetMass()
	return self.massScale * ( GetBodyMass(self.body) + GetBodyMass(self.headBody) );
end
function Npc:GetWeight()
	-- F = m*g
	return self:GetMass() * self.gravity;
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
	local newBoundsMin, newBoundsMax = self:GetBoundsAt(pos);
	
	return NpcUtil.IsAABBEmptyWithBodyRejects( newBoundsMin, newBoundsMax, {self.body, self.headBody} );
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


-- Updates bInAir by testing npc's velocity what's below npc
-- Returns true if npc has nothing beneath it
function Npc:UpdateInAir()
	if (self.vel[2] > self.minVelThreshold) then
		self.bInAir = true;
	else
		local minBound, maxBound = self:GetBounds();
		self.bInAir = NpcUtil.IsAABBEmptyWithBodyRejects(
			Vec( minBound[1], minBound[2] - 0.15, minBound[3] ),
			Vec( maxBound[1], minBound[2], maxBound[3] ),
			{self.body, self.headBody}
		);
	end
	return self.bInAir
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
-- Velocity is set so that the npc will move horizontally, i.e. it's y-velocity won't change
function Npc:MoveTowardsPosHorizontally(speed, target)
	self:SetVel(
		VecAdd(
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
			),
			Vec(
				0,
				self.vel[2],
				0
			)
		)
	);
end

-- Update npc's position based on it's current velocity in m/s
function Npc:ApplyVel(dt)
	self:AttemptMoveBy( VecScale(self.vel, dt) );
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
	-- Cancel velocity values below threshold
	if (math.abs(self.vel[1]) < self.minVelThreshold) then
		self.vel[1] = 0;
	end
	if (math.abs(self.vel[2]) < self.minVelThreshold) then
		self.vel[2] = 0;
	end
	if (math.abs(self.vel[3]) < self.minVelThreshold) then
		self.vel[3] = 0;
	end

	-- If we're in middair...
	if (self:UpdateInAir()) then
		-- ...accelerate downwards
		self:AddVel( Vec(0, self.gravity * dt, 0) );
	else
	-- Otherwise...
		-- If we have downwards y-velocity, set it to zero
		if (self.vel[2] < 0) then self.vel[2] = 0; end
		
		-- Make sure we're not partially in the floor
		-- (Rounds y-pos to the nearest 0.1)
		---ocal currentPos = self:GetPos();
		--self:SetPos( Vec( currentPos[1], math.floor( 10 * currentPos[2] + 0.5 ) * 0.1, currentPos[3] ) );
	end
	
	-- Update position based on velocity
	self:ApplyVel(dt);
end


function Npc:update(dt)
	-- TEMP
	if (InputDown("h")) then
		self:AddVel(Vec(0, 2, 0));
	end

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
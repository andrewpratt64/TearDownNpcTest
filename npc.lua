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




--	=PREDICATES=
-- (Some predicate methods are in the get/set area, these are the ones that don't really have a mutator method)
function Npc:IsValid()
	return IsHandleValid(self.body);
end

function Npc:IsDead()
	return self.bDead;
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


function Npc:update()
	-- Only update if we're valid
	if (not self:IsValid()) then return; end
	
	-- Handle our potential death
	self:HandlePotentialDeath();

	if (not self.bDead) then
		-- Face the player
		self:FacePos(GetCameraTransform().pos);
	end
end
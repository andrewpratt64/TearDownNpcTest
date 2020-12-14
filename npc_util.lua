-- Andrew Pratt 2020
-- Utility functions


NpcUtil = {}


function NpcUtil.VecToString(vec)
	return "Vec(" .. vec[1] .. ", " .. vec[2] .. ", " .. vec[3] .. ")";
end


function NpcUtil.VecDiff(vecA, vecB)
	return VecLength( VecSub(vecB, vecA) );
end

-- TODO: better/less confusing name for this function
-- Returns vec with it's y-value set to zero
function NpcUtil.VecSwizzleXZ(vec)
	return Vec( vec[1], 0, vec[3] );
end

-- Returns a vector with the smallest x, y, and z of the two given vectors
function NpcUtil.VecMin(vecA, vecB)
	return Vec(
		math.min(vecA[1], vecB[1]),
		math.min(vecA[2], vecB[2]),
		math.min(vecA[3], vecB[3])
	);
end

-- Returns a vector with the largest x, y, and z of the two given vectors
function NpcUtil.VecMax(vecA, vecB)
	return Vec(
		math.max(vecA[1], vecB[1]),
		math.max(vecA[2], vecB[2]),
		math.max(vecA[3], vecB[3])
	);
end


-- Like QuatLookAt, but only affects yaw rotation
function NpcUtil.QuatLookAtOnYaw(eye, target)
	return QuatLookAt( eye, Vec(target[1], eye[2], target[3]) );
end


function NpcUtil.MakeBodyLookAt(body, target)
	local bodyPos = GetBodyTransform(body).pos;
	SetBodyTransform( body, Transform( bodyPos, QuatLookAt(bodyPos, target) ) );
end

function NpcUtil.MakeBodyLookAtOnYaw(body, target)
	local bodyPos = GetBodyTransform(body).pos;
	SetBodyTransform( body, Transform( bodyPos, QuatLookAtOnYaw(bodyPos, target) ) );
end

function NpcUtil.AddBodyVelocity(body, addVec)
	SetBodyVelocity( body, VecAdd( GetBodyVelocity(body), addVec ) );
end


-- Returns true if the given position is NOT empty at pos
function NpcUtil.IsVoxelAt(pos)
	return QueryClosestPoint(pos, 0.1);
end

-- Same as above, but supports rejecting bodies
-- bodyRejects is a list of bodies to exclude from testing
function NpcUtil.IsVoxelAtWithBodyRejects(pos, bodyRejects)
	for _, body in pairs(bodyRejects) do
		QueryRejectBody(body);
	end
	
	return QueryClosestPoint(pos, 0.1);
end


-- Returns the highest position inside the given aabb that isn't empty
-- Returns nil if given aabb is empty
-- bodyRejects is a list of bodies to exclude from testing
function NpcUtil.GetHighestPointInAABB(minPos, maxPos, bodyRejects)
	local highestPos = nil;
	
	for x=minPos[1], maxPos[1], 0.1 do
		for y=minPos[2], maxPos[2], 0.1 do
			for z=minPos[3], maxPos[3], 0.1 do
				local testPos = Vec(x, y, z);

				if ( NpcUtil.IsVoxelAt(testPos) and ( highestPos == nil or testPos[2] > highestPos[2] ) ) then
					highestPos = testPos;
				end
			end
		end
	end
	
	return highestPos;
end


-- Same as above, but supports rejecting bodies
-- bodyRejects is a list of bodies to exclude from testing
function NpcUtil.GetHighestPointInAABBWithBodyRejects(minPos, maxPos, bodyRejects)
	local highestPos = nil;
	
	for x=minPos[1], maxPos[1], 0.1 do
		for y=minPos[2], maxPos[2], 0.1 do
			for z=minPos[3], maxPos[3], 0.1 do
				local testPos = Vec(x, y, z);

				if ( NpcUtil.IsVoxelAtWithBodyRejects(testPos, bodyRejects) and ( highestPos == nil or testPos[2] > highestPos[2] ) ) then
					highestPos = testPos;
				end
			end
		end
	end
	
	return highestPos;
end
package newton

foreign import "newton.lib"

NEWTON_MAJOR_VERSION :: 3
NEWTON_MINOR_VERSION :: 14

NEWTON_BROADPHASE_DEFAULT :: 0
NEWTON_BROADPHASE_PERSINTENT :: 1

NEWTON_DYNAMIC_BODY :: 0
NEWTON_KINEMATIC_BODY :: 1
NEWTON_DYNAMIC_ASYMETRIC_BODY :: 2

SERIALIZE_ID_SPHERE :: 0
SERIALIZE_ID_CAPSULE :: 1
SERIALIZE_ID_CYLINDER :: 2
SERIALIZE_ID_CHAMFERCYLINDER :: 3
SERIALIZE_ID_BOX :: 4
SERIALIZE_ID_CONE :: 5
SERIALIZE_ID_CONVEXHULL :: 6
SERIALIZE_ID_NULL :: 7
SERIALIZE_ID_COMPOUND :: 8
SERIALIZE_ID_TREE :: 9
SERIALIZE_ID_HEIGHTFIELD :: 10
SERIALIZE_ID_CLOTH_PATCH :: 11
SERIALIZE_ID_DEFORMABLE_SOLID :: 12
SERIALIZE_ID_USERMESH :: 13
SERIALIZE_ID_SCENE :: 14
SERIALIZE_ID_FRACTURED_COMPOUND :: 15

NewtonConstraintDescriptor :: NewtonImmediateModeConstraint
NewtonAllocMemory :: #type proc(sizeInBytes : i32) -> rawptr
NewtonFreeMemory :: #type proc(ptr : rawptr, sizeInBytes : i32)
NewtonWorldDestructorCallback :: #type proc(world : ^NewtonWorld)
NewtonPostUpdateCallback :: #type proc(world : ^NewtonWorld, timestep : dFloat)
NewtonCreateContactCallback :: #type proc(newtonWorld : ^NewtonWorld, contact : ^NewtonJoint)
NewtonDestroyContactCallback :: #type proc(newtonWorld : ^NewtonWorld, contact : ^NewtonJoint)
NewtonWorldListenerDebugCallback :: #type proc(world : ^NewtonWorld, listener : rawptr, debugContext : rawptr)
NewtonWorldListenerBodyDestroyCallback :: #type proc(world : ^NewtonWorld, listenerUserData : rawptr, body : ^NewtonBody)
NewtonWorldUpdateListenerCallback :: #type proc(world : ^NewtonWorld, listenerUserData : rawptr, timestep : dFloat)
NewtonWorldDestroyListenerCallback :: #type proc(world : ^NewtonWorld, listenerUserData : rawptr)
NewtonGetTimeInMicrosencondsCallback :: #type proc() -> i64
NewtonSerializeCallback :: #type proc(serializeHandle : rawptr, buffer : rawptr, size : i32)
NewtonDeserializeCallback :: #type proc(serializeHandle : rawptr, buffer : rawptr, size : i32)
NewtonOnBodySerializationCallback :: #type proc(body : ^NewtonBody, userData : rawptr, function : NewtonSerializeCallback, serializeHandle : rawptr)
NewtonOnBodyDeserializationCallback :: #type proc(body : ^NewtonBody, userData : rawptr, function : NewtonDeserializeCallback, serializeHandle : rawptr)
NewtonOnJointSerializationCallback :: #type proc(joint : ^NewtonJoint, function : NewtonSerializeCallback, serializeHandle : rawptr)
NewtonOnJointDeserializationCallback :: #type proc(body0 : ^NewtonBody, body1 : ^NewtonBody, function : NewtonDeserializeCallback, serializeHandle : rawptr)
NewtonOnUserCollisionSerializationCallback :: #type proc(userData : rawptr, function : NewtonSerializeCallback, serializeHandle : rawptr)
NewtonUserMeshCollisionDestroyCallback :: #type proc(userData : rawptr)
NewtonUserMeshCollisionRayHitCallback :: #type proc(lineDescData : ^NewtonUserMeshCollisionRayHitDesc) -> dFloat
NewtonUserMeshCollisionGetCollisionInfo :: #type proc(userData : rawptr, infoRecord : ^NewtonCollisionInfoRecord)
NewtonUserMeshCollisionAABBTest :: #type proc(userData : rawptr, boxP0 : ^dFloat, boxP1 : ^dFloat) -> i32
NewtonUserMeshCollisionGetFacesInAABB :: #type proc(userData : rawptr, p0 : ^dFloat, p1 : ^dFloat, vertexArray : ^^dFloat, vertexCount : ^i32, vertexStrideInBytes : ^i32, indexList : ^i32, maxIndexCount : i32, userDataList : ^i32) -> i32
NewtonUserMeshCollisionCollideCallback :: #type proc(collideDescData : ^NewtonUserMeshCollisionCollideDesc, continueCollisionHandle : rawptr)
NewtonTreeCollisionFaceCallback :: #type proc(_context : rawptr, polygon : ^dFloat, strideInBytes : i32, indexArray : ^i32, indexCount : i32) -> i32
NewtonCollisionTreeRayCastCallback :: #type proc(body : ^NewtonBody, treeCollision : ^NewtonCollision, intersection : dFloat, normal : ^dFloat, faceId : i32, usedData : rawptr) -> dFloat
NewtonHeightFieldRayCastCallback :: #type proc(body : ^NewtonBody, heightFieldCollision : ^NewtonCollision, intersection : dFloat, row : i32, col : i32, normal : ^dFloat, faceId : i32, usedData : rawptr) -> dFloat
NewtonCollisionCopyConstructionCallback :: #type proc(newtonWorld : ^NewtonWorld, collision : ^NewtonCollision, sourceCollision : ^NewtonCollision)
NewtonCollisionDestructorCallback :: #type proc(newtonWorld : ^NewtonWorld, collision : ^NewtonCollision)
NewtonTreeCollisionCallback :: #type proc(bodyWithTreeCollision : ^NewtonBody, body : ^NewtonBody, faceID : i32, vertexCount : i32, vertex : ^dFloat, vertexStrideInBytes : i32)
NewtonBodyDestructor :: #type proc(body : ^NewtonBody)
NewtonApplyForceAndTorque :: #type proc(body : ^NewtonBody, timestep : dFloat, threadIndex : i32)
NewtonSetTransform :: #type proc(body : ^NewtonBody, matrix4x4 : ^dFloat, threadIndex : i32)
NewtonIslandUpdate :: #type proc(newtonWorld : ^NewtonWorld, islandHandle : rawptr, bodyCount : i32) -> i32
NewtonFractureCompoundCollisionOnEmitCompoundFractured :: #type proc(fracturedBody : ^NewtonBody)
NewtonFractureCompoundCollisionOnEmitChunk :: #type proc(chunkBody : ^NewtonBody, fracturexChunkMesh : ^NewtonFracturedCompoundMeshPart, fracturedCompountCollision : ^NewtonCollision)
NewtonFractureCompoundCollisionReconstructMainMeshCallBack :: #type proc(body : ^NewtonBody, mainMesh : ^NewtonFracturedCompoundMeshPart, fracturedCompountCollision : ^NewtonCollision)
NewtonWorldRayPrefilterCallback :: #type proc(body : ^NewtonBody, collision : ^NewtonCollision, userData : rawptr) -> u32
NewtonWorldRayFilterCallback :: #type proc(body : ^NewtonBody, shapeHit : ^NewtonCollision, hitContact : ^dFloat, hitNormal : ^dFloat, collisionID : i64, userData : rawptr, intersectParam : dFloat) -> dFloat
NewtonOnAABBOverlap :: #type proc(contact : ^NewtonJoint, timestep : dFloat, threadIndex : i32) -> i32
NewtonContactsProcess :: #type proc(contact : ^NewtonJoint, timestep : dFloat, threadIndex : i32)
NewtonOnCompoundSubCollisionAABBOverlap :: #type proc(contact : ^NewtonJoint, timestep : dFloat, body0 : ^NewtonBody, collisionNode0 : rawptr, body1 : ^NewtonBody, collisionNode1 : rawptr, threadIndex : i32) -> i32
NewtonOnContactGeneration :: #type proc(material : ^NewtonMaterial, body0 : ^NewtonBody, collision0 : ^NewtonCollision, body1 : ^NewtonBody, collision1 : ^NewtonCollision, contactBuffer : ^NewtonUserContactPoint, maxCount : i32, threadIndex : i32) -> i32
NewtonBodyIterator :: #type proc(body : ^NewtonBody, userData : rawptr) -> i32
NewtonJointIterator :: #type proc(joint : ^NewtonJoint, userData : rawptr)
NewtonCollisionIterator :: #type proc(userData : rawptr, vertexCount : i32, faceArray : ^dFloat, faceId : i32)
NewtonBallCallback :: #type proc(ball : ^NewtonJoint, timestep : dFloat)
NewtonHingeCallback :: #type proc(hinge : ^NewtonJoint, desc : ^NewtonHingeSliderUpdateDesc) -> u32
NewtonSliderCallback :: #type proc(slider : ^NewtonJoint, desc : ^NewtonHingeSliderUpdateDesc) -> u32
NewtonUniversalCallback :: #type proc(universal : ^NewtonJoint, desc : ^NewtonHingeSliderUpdateDesc) -> u32
NewtonCorkscrewCallback :: #type proc(corkscrew : ^NewtonJoint, desc : ^NewtonHingeSliderUpdateDesc) -> u32
NewtonUserBilateralCallback :: #type proc(userJoint : ^NewtonJoint, timestep : dFloat, threadIndex : i32)
NewtonUserBilateralGetInfoCallback :: #type proc(userJoint : ^NewtonJoint, info : ^NewtonJointRecord)
NewtonConstraintDestructor :: #type proc(me : ^NewtonJoint)
NewtonJobTask :: #type proc(world : ^NewtonWorld, userData : rawptr, threadIndex : i32)
NewtonReportProgress :: #type proc(normalizedProgressPercent : dFloat, userData : rawptr) -> i32

NewtonMesh :: struct {}

NewtonBody :: struct {}

NewtonWorld :: struct {}

NewtonJoint :: struct {}

NewtonMaterial :: struct {}

NewtonCollision :: struct {}

NewtonDeformableMeshSegment :: struct {}

NewtonFracturedCompoundMeshPart :: struct {}

NewtonCollisionMaterial :: struct {
    m_userId : i64,
    m_userData : NewtonMaterialData,
    m_userParam : [6]NewtonMaterialData,
}

NewtonBoxParam :: struct {
    m_x : dFloat,
    m_y : dFloat,
    m_z : dFloat,
}

NewtonSphereParam :: struct {
    m_radio : dFloat,
}

NewtonCapsuleParam :: struct {
    m_radio0 : dFloat,
    m_radio1 : dFloat,
    m_height : dFloat,
}

NewtonCylinderParam :: struct {
    m_radio0 : dFloat,
    m_radio1 : dFloat,
    m_height : dFloat,
}

NewtonConeParam :: struct {
    m_radio : dFloat,
    m_height : dFloat,
}

NewtonChamferCylinderParam :: struct {
    m_radio : dFloat,
    m_height : dFloat,
}

NewtonConvexHullParam :: struct {
    m_vertexCount : i32,
    m_vertexStrideInBytes : i32,
    m_faceCount : i32,
    m_vertex : ^dFloat,
}

NewtonCompoundCollisionParam :: struct {
    m_chidrenCount : i32,
}

NewtonCollisionTreeParam :: struct {
    m_vertexCount : i32,
    m_indexCount : i32,
}

NewtonDeformableMeshParam :: struct {
    m_vertexCount : i32,
    m_triangleCount : i32,
    m_vrtexStrideInBytes : i32,
    m_indexList : ^u16,
    m_vertexList : ^dFloat,
}

NewtonHeightFieldCollisionParam :: struct {
    m_width : i32,
    m_height : i32,
    m_gridsDiagonals : i32,
    m_elevationDataType : i32,
    m_verticalScale : dFloat,
    m_horizonalScale_x : dFloat,
    m_horizonalScale_z : dFloat,
    m_vertialElevation : rawptr,
    m_atributes : cstring,
}

NewtonSceneCollisionParam :: struct {
    m_childrenProxyCount : i32,
}

NewtonCollisionInfoRecord :: struct {
    m_offsetMatrix : float4x4,
    m_collisionMaterial : NewtonCollisionMaterial,
    m_collisionType : i32,
    u : struct #raw_union {
		m_box : NewtonBoxParam,
		m_cone : NewtonConeParam,
		m_sphere : NewtonSphereParam,
		m_capsule : NewtonCapsuleParam,
		m_cylinder : NewtonCylinderParam,
		m_chamferCylinder : NewtonChamferCylinderParam,
		m_convexHull : NewtonConvexHullParam,
		m_deformableMesh : NewtonDeformableMeshParam,
		m_compoundCollision : NewtonCompoundCollisionParam,
		m_collisionTree : NewtonCollisionTreeParam,
		m_heightField : NewtonHeightFieldCollisionParam,
		m_sceneCollision : NewtonSceneCollisionParam,
		m_paramArray : [64]dFloat,
	},
}

NewtonJointRecord :: struct {
    m_attachmenMatrix_0 : float4x4,
    m_attachmenMatrix_1 : float4x4,
    m_minLinearDof : float3,
    m_maxLinearDof : float3,
    m_minAngularDof : float3,
    m_maxAngularDof : float3,
    m_attachBody_0 : ^NewtonBody,
    m_attachBody_1 : ^NewtonBody,
    m_extraParameters : [64]dFloat,
    m_bodiesCollisionOn : i32,
    m_descriptionType : [128]u8,
}

NewtonUserMeshCollisionCollideDesc :: struct {
    m_boxP0 : float4,
    m_boxP1 : float4,
    m_boxDistanceTravel : float4,
    m_threadNumber : i32,
    m_faceCount : i32,
    m_vertexStrideInBytes : i32,
    m_skinThickness : dFloat,
    m_userData : rawptr,
    m_objBody : ^NewtonBody,
    m_polySoupBody : ^NewtonBody,
    m_objCollision : ^NewtonCollision,
    m_polySoupCollision : ^NewtonCollision,
    m_vertex : ^dFloat,
    m_faceIndexCount : ^i32,
    m_faceVertexIndex : ^i32,
}

NewtonWorldConvexCastReturnInfo :: struct {
    m_point : float4,
    m_normal : float4,
    m_contactID : i64,
    m_hitBody : ^NewtonBody,
    m_penetration : dFloat,
}

NewtonUserMeshCollisionRayHitDesc :: struct {
    m_p0 : float4,
    m_p1 : float4,
    m_normalOut : float4,
    m_userIdOut : i64,
    m_userData : rawptr,
}

NewtonHingeSliderUpdateDesc :: struct {
    m_accel : dFloat,
    m_minFriction : dFloat,
    m_maxFriction : dFloat,
    m_timestep : dFloat,
}

NewtonUserContactPoint :: struct {
    m_point : float4,
    m_normal : float4,
    m_shapeId0 : i64,
    m_shapeId1 : i64,
    m_penetration : dFloat,
    m_unused : int3,
}

NewtonImmediateModeConstraint :: struct {
    m_jacobian01 : [8][6]dFloat,
    m_jacobian10 : [8][6]dFloat,
    m_minFriction : [8]dFloat,
    m_maxFriction : [8]dFloat,
    m_jointAccel : [8]dFloat,
    m_jointStiffness : [8]dFloat,
}

NewtonMeshDoubleData :: struct {
    m_data : ^f64,
    m_indexList : ^i32,
    m_strideInBytes : i32,
}

NewtonMeshFloatData :: struct {
    m_data : ^dFloat,
    m_indexList : ^i32,
    m_strideInBytes : i32,
}

NewtonMeshVertexFormat :: struct {
    m_faceCount : i32,
    m_faceIndexCount : ^i32,
    m_faceMaterial : ^i32,
    m_vertex : NewtonMeshDoubleData,
    m_normal : NewtonMeshFloatData,
    m_binormal : NewtonMeshFloatData,
    m_uv0 : NewtonMeshFloatData,
    m_uv1 : NewtonMeshFloatData,
    m_vertexColor : NewtonMeshFloatData,
}

NewtonMaterialData :: struct #raw_union {
    m_ptr : rawptr,
    m_int : i64,
    m_float : dFloat,
}

@(default_calling_convention="c")
foreign newton {

    @(link_name="NewtonWorldGetVersion")
    NewtonWorldGetVersion :: proc() -> i32 ---

    @(link_name="NewtonWorldFloatSize")
    NewtonWorldFloatSize :: proc() -> i32 ---

    @(link_name="NewtonGetMemoryUsed")
    NewtonGetMemoryUsed :: proc() -> i32 ---

    @(link_name="NewtonSetMemorySystem")
    NewtonSetMemorySystem :: proc(malloc : NewtonAllocMemory, free : NewtonFreeMemory) ---

    @(link_name="NewtonCreate")
    NewtonCreate :: proc() -> ^NewtonWorld ---

    @(link_name="NewtonDestroy")
    NewtonDestroy :: proc(newtonWorld : ^NewtonWorld) ---

    @(link_name="NewtonDestroyAllBodies")
    NewtonDestroyAllBodies :: proc(newtonWorld : ^NewtonWorld) ---

    @(link_name="NewtonGetPostUpdateCallback")
    NewtonGetPostUpdateCallback :: proc(newtonWorld : ^NewtonWorld) -> NewtonPostUpdateCallback ---

    @(link_name="NewtonSetPostUpdateCallback")
    NewtonSetPostUpdateCallback :: proc(newtonWorld : ^NewtonWorld, callback : NewtonPostUpdateCallback) ---

    @(link_name="NewtonAlloc")
    NewtonAlloc :: proc(sizeInBytes : i32) -> rawptr ---

    @(link_name="NewtonFree")
    NewtonFree :: proc(ptr : rawptr) ---

    @(link_name="NewtonLoadPlugins")
    NewtonLoadPlugins :: proc(newtonWorld : ^NewtonWorld, plugInPath : cstring) ---

    @(link_name="NewtonUnloadPlugins")
    NewtonUnloadPlugins :: proc(newtonWorld : ^NewtonWorld) ---

    @(link_name="NewtonCurrentPlugin")
    NewtonCurrentPlugin :: proc(newtonWorld : ^NewtonWorld) -> rawptr ---

    @(link_name="NewtonGetFirstPlugin")
    NewtonGetFirstPlugin :: proc(newtonWorld : ^NewtonWorld) -> rawptr ---

    @(link_name="NewtonGetPreferedPlugin")
    NewtonGetPreferedPlugin :: proc(newtonWorld : ^NewtonWorld) -> rawptr ---

    @(link_name="NewtonGetNextPlugin")
    NewtonGetNextPlugin :: proc(newtonWorld : ^NewtonWorld, plugin : rawptr) -> rawptr ---

    @(link_name="NewtonGetPluginString")
    NewtonGetPluginString :: proc(newtonWorld : ^NewtonWorld, plugin : rawptr) -> cstring ---

    @(link_name="NewtonSelectPlugin")
    NewtonSelectPlugin :: proc(newtonWorld : ^NewtonWorld, plugin : rawptr) ---

    @(link_name="NewtonGetContactMergeTolerance")
    NewtonGetContactMergeTolerance :: proc(newtonWorld : ^NewtonWorld) -> dFloat ---

    @(link_name="NewtonSetContactMergeTolerance")
    NewtonSetContactMergeTolerance :: proc(newtonWorld : ^NewtonWorld, tolerance : dFloat) ---

    @(link_name="NewtonInvalidateCache")
    NewtonInvalidateCache :: proc(newtonWorld : ^NewtonWorld) ---

    @(link_name="NewtonSetSolverIterations")
    NewtonSetSolverIterations :: proc(newtonWorld : ^NewtonWorld, model : i32) ---

    @(link_name="NewtonGetSolverIterations")
    NewtonGetSolverIterations :: proc(newtonWorld : ^NewtonWorld) -> i32 ---

    @(link_name="NewtonSetParallelSolverOnLargeIsland")
    NewtonSetParallelSolverOnLargeIsland :: proc(newtonWorld : ^NewtonWorld, mode : i32) ---

    @(link_name="NewtonGetParallelSolverOnLargeIsland")
    NewtonGetParallelSolverOnLargeIsland :: proc(newtonWorld : ^NewtonWorld) -> i32 ---

    @(link_name="NewtonGetBroadphaseAlgorithm")
    NewtonGetBroadphaseAlgorithm :: proc(newtonWorld : ^NewtonWorld) -> i32 ---

    @(link_name="NewtonSelectBroadphaseAlgorithm")
    NewtonSelectBroadphaseAlgorithm :: proc(newtonWorld : ^NewtonWorld, algorithmType : i32) ---

    @(link_name="NewtonResetBroadphase")
    NewtonResetBroadphase :: proc(newtonWorld : ^NewtonWorld) ---

    @(link_name="NewtonUpdate")
    NewtonUpdate :: proc(newtonWorld : ^NewtonWorld, timestep : dFloat) ---

    @(link_name="NewtonUpdateAsync")
    NewtonUpdateAsync :: proc(newtonWorld : ^NewtonWorld, timestep : dFloat) ---

    @(link_name="NewtonWaitForUpdateToFinish")
    NewtonWaitForUpdateToFinish :: proc(newtonWorld : ^NewtonWorld) ---

    @(link_name="NewtonGetNumberOfSubsteps")
    NewtonGetNumberOfSubsteps :: proc(newtonWorld : ^NewtonWorld) -> i32 ---

    @(link_name="NewtonSetNumberOfSubsteps")
    NewtonSetNumberOfSubsteps :: proc(newtonWorld : ^NewtonWorld, subSteps : i32) ---

    @(link_name="NewtonGetLastUpdateTime")
    NewtonGetLastUpdateTime :: proc(newtonWorld : ^NewtonWorld) -> dFloat ---

    @(link_name="NewtonSerializeToFile")
    NewtonSerializeToFile :: proc(newtonWorld : ^NewtonWorld, filename : cstring, bodyCallback : NewtonOnBodySerializationCallback, bodyUserData : rawptr) ---

    @(link_name="NewtonDeserializeFromFile")
    NewtonDeserializeFromFile :: proc(newtonWorld : ^NewtonWorld, filename : cstring, bodyCallback : NewtonOnBodyDeserializationCallback, bodyUserData : rawptr) ---

    @(link_name="NewtonSerializeScene")
    NewtonSerializeScene :: proc(newtonWorld : ^NewtonWorld, bodyCallback : NewtonOnBodySerializationCallback, bodyUserData : rawptr, serializeCallback : NewtonSerializeCallback, serializeHandle : rawptr) ---

    @(link_name="NewtonDeserializeScene")
    NewtonDeserializeScene :: proc(newtonWorld : ^NewtonWorld, bodyCallback : NewtonOnBodyDeserializationCallback, bodyUserData : rawptr, serializeCallback : NewtonDeserializeCallback, serializeHandle : rawptr) ---

    @(link_name="NewtonFindSerializedBody")
    NewtonFindSerializedBody :: proc(newtonWorld : ^NewtonWorld, bodySerializedID : i32) -> ^NewtonBody ---

    @(link_name="NewtonSetJointSerializationCallbacks")
    NewtonSetJointSerializationCallbacks :: proc(newtonWorld : ^NewtonWorld, serializeJoint : NewtonOnJointSerializationCallback, deserializeJoint : NewtonOnJointDeserializationCallback) ---

    @(link_name="NewtonGetJointSerializationCallbacks")
    NewtonGetJointSerializationCallbacks :: proc(newtonWorld : ^NewtonWorld, serializeJoint : ^NewtonOnJointSerializationCallback, deserializeJoint : ^NewtonOnJointDeserializationCallback) ---

    @(link_name="NewtonWorldCriticalSectionLock")
    NewtonWorldCriticalSectionLock :: proc(newtonWorld : ^NewtonWorld, threadIndex : i32) ---

    @(link_name="NewtonWorldCriticalSectionUnlock")
    NewtonWorldCriticalSectionUnlock :: proc(newtonWorld : ^NewtonWorld) ---

    @(link_name="NewtonSetThreadsCount")
    NewtonSetThreadsCount :: proc(newtonWorld : ^NewtonWorld, threads : i32) ---

    @(link_name="NewtonGetThreadsCount")
    NewtonGetThreadsCount :: proc(newtonWorld : ^NewtonWorld) -> i32 ---

    @(link_name="NewtonGetMaxThreadsCount")
    NewtonGetMaxThreadsCount :: proc(newtonWorld : ^NewtonWorld) -> i32 ---

    @(link_name="NewtonDispachThreadJob")
    NewtonDispachThreadJob :: proc(newtonWorld : ^NewtonWorld, task : NewtonJobTask, usedData : rawptr, functionName : cstring) ---

    @(link_name="NewtonSyncThreadJobs")
    NewtonSyncThreadJobs :: proc(newtonWorld : ^NewtonWorld) ---

    @(link_name="NewtonAtomicAdd")
    NewtonAtomicAdd :: proc(ptr : ^i32, value : i32) -> i32 ---

    @(link_name="NewtonAtomicSwap")
    NewtonAtomicSwap :: proc(ptr : ^i32, value : i32) -> i32 ---

    @(link_name="NewtonYield")
    NewtonYield :: proc() ---

    @(link_name="NewtonSetIslandUpdateEvent")
    NewtonSetIslandUpdateEvent :: proc(newtonWorld : ^NewtonWorld, islandUpdate : NewtonIslandUpdate) ---

    @(link_name="NewtonWorldForEachJointDo")
    NewtonWorldForEachJointDo :: proc(newtonWorld : ^NewtonWorld, callback : NewtonJointIterator, userData : rawptr) ---

    @(link_name="NewtonWorldForEachBodyInAABBDo")
    NewtonWorldForEachBodyInAABBDo :: proc(newtonWorld : ^NewtonWorld, p0 : ^dFloat, p1 : ^dFloat, callback : NewtonBodyIterator, userData : rawptr) ---

    @(link_name="NewtonWorldSetUserData")
    NewtonWorldSetUserData :: proc(newtonWorld : ^NewtonWorld, userData : rawptr) ---

    @(link_name="NewtonWorldGetUserData")
    NewtonWorldGetUserData :: proc(newtonWorld : ^NewtonWorld) -> rawptr ---

    @(link_name="NewtonWorldAddListener")
    NewtonWorldAddListener :: proc(newtonWorld : ^NewtonWorld, nameId : cstring, listenerUserData : rawptr) -> rawptr ---

    @(link_name="NewtonWorldGetListener")
    NewtonWorldGetListener :: proc(newtonWorld : ^NewtonWorld, nameId : cstring) -> rawptr ---

    @(link_name="NewtonWorldListenerSetDebugCallback")
    NewtonWorldListenerSetDebugCallback :: proc(newtonWorld : ^NewtonWorld, listener : rawptr, callback : NewtonWorldListenerDebugCallback) ---

    @(link_name="NewtonWorldListenerSetPostStepCallback")
    NewtonWorldListenerSetPostStepCallback :: proc(newtonWorld : ^NewtonWorld, listener : rawptr, callback : NewtonWorldUpdateListenerCallback) ---

    @(link_name="NewtonWorldListenerSetPreUpdateCallback")
    NewtonWorldListenerSetPreUpdateCallback :: proc(newtonWorld : ^NewtonWorld, listener : rawptr, callback : NewtonWorldUpdateListenerCallback) ---

    @(link_name="NewtonWorldListenerSetPostUpdateCallback")
    NewtonWorldListenerSetPostUpdateCallback :: proc(newtonWorld : ^NewtonWorld, listener : rawptr, callback : NewtonWorldUpdateListenerCallback) ---

    @(link_name="NewtonWorldListenerSetDestructorCallback")
    NewtonWorldListenerSetDestructorCallback :: proc(newtonWorld : ^NewtonWorld, listener : rawptr, callback : NewtonWorldDestroyListenerCallback) ---

    @(link_name="NewtonWorldListenerSetBodyDestroyCallback")
    NewtonWorldListenerSetBodyDestroyCallback :: proc(newtonWorld : ^NewtonWorld, listener : rawptr, callback : NewtonWorldListenerBodyDestroyCallback) ---

    @(link_name="NewtonWorldListenerDebug")
    NewtonWorldListenerDebug :: proc(newtonWorld : ^NewtonWorld, _context : rawptr) ---

    @(link_name="NewtonWorldGetListenerUserData")
    NewtonWorldGetListenerUserData :: proc(newtonWorld : ^NewtonWorld, listener : rawptr) -> rawptr ---

    @(link_name="NewtonWorldListenerGetBodyDestroyCallback")
    NewtonWorldListenerGetBodyDestroyCallback :: proc(newtonWorld : ^NewtonWorld, listener : rawptr) -> NewtonWorldListenerBodyDestroyCallback ---

    @(link_name="NewtonWorldSetDestructorCallback")
    NewtonWorldSetDestructorCallback :: proc(newtonWorld : ^NewtonWorld, destructor : NewtonWorldDestructorCallback) ---

    @(link_name="NewtonWorldGetDestructorCallback")
    NewtonWorldGetDestructorCallback :: proc(newtonWorld : ^NewtonWorld) -> NewtonWorldDestructorCallback ---

    @(link_name="NewtonWorldSetCollisionConstructorDestructorCallback")
    NewtonWorldSetCollisionConstructorDestructorCallback :: proc(newtonWorld : ^NewtonWorld, constructor : NewtonCollisionCopyConstructionCallback, destructor : NewtonCollisionDestructorCallback) ---

    @(link_name="NewtonWorldSetCreateDestroyContactCallback")
    NewtonWorldSetCreateDestroyContactCallback :: proc(newtonWorld : ^NewtonWorld, createContact : NewtonCreateContactCallback, destroyContact : NewtonDestroyContactCallback) ---

    @(link_name="NewtonWorldRayCast")
    NewtonWorldRayCast :: proc(newtonWorld : ^NewtonWorld, p0 : ^dFloat, p1 : ^dFloat, filter : NewtonWorldRayFilterCallback, userData : rawptr, prefilter : NewtonWorldRayPrefilterCallback, threadIndex : i32) ---

    @(link_name="NewtonWorldConvexCast")
    NewtonWorldConvexCast :: proc(newtonWorld : ^NewtonWorld, matrix4x4 : ^dFloat, target : ^dFloat, shape : ^NewtonCollision, param : ^dFloat, userData : rawptr, prefilter : NewtonWorldRayPrefilterCallback, info : ^NewtonWorldConvexCastReturnInfo, maxContactsCount : i32, threadIndex : i32) -> i32 ---

    @(link_name="NewtonWorldCollide")
    NewtonWorldCollide :: proc(newtonWorld : ^NewtonWorld, matrix4x4 : ^dFloat, shape : ^NewtonCollision, userData : rawptr, prefilter : NewtonWorldRayPrefilterCallback, info : ^NewtonWorldConvexCastReturnInfo, maxContactsCount : i32, threadIndex : i32) -> i32 ---

    @(link_name="NewtonWorldGetBodyCount")
    NewtonWorldGetBodyCount :: proc(newtonWorld : ^NewtonWorld) -> i32 ---

    @(link_name="NewtonWorldGetConstraintCount")
    NewtonWorldGetConstraintCount :: proc(newtonWorld : ^NewtonWorld) -> i32 ---

    @(link_name="NewtonWorldFindJoint")
    NewtonWorldFindJoint :: proc(body0 : ^NewtonBody, body1 : ^NewtonBody) -> ^NewtonJoint ---

    @(link_name="NewtonIslandGetBody")
    NewtonIslandGetBody :: proc(island : rawptr, bodyIndex : i32) -> ^NewtonBody ---

    @(link_name="NewtonIslandGetBodyAABB")
    NewtonIslandGetBodyAABB :: proc(island : rawptr, bodyIndex : i32, p0 : ^dFloat, p1 : ^dFloat) ---

    @(link_name="NewtonMaterialCreateGroupID")
    NewtonMaterialCreateGroupID :: proc(newtonWorld : ^NewtonWorld) -> i32 ---

    @(link_name="NewtonMaterialGetDefaultGroupID")
    NewtonMaterialGetDefaultGroupID :: proc(newtonWorld : ^NewtonWorld) -> i32 ---

    @(link_name="NewtonMaterialDestroyAllGroupID")
    NewtonMaterialDestroyAllGroupID :: proc(newtonWorld : ^NewtonWorld) ---

    @(link_name="NewtonMaterialGetUserData")
    NewtonMaterialGetUserData :: proc(newtonWorld : ^NewtonWorld, id0 : i32, id1 : i32) -> rawptr ---

    @(link_name="NewtonMaterialSetSurfaceThickness")
    NewtonMaterialSetSurfaceThickness :: proc(newtonWorld : ^NewtonWorld, id0 : i32, id1 : i32, thickness : dFloat) ---

    @(link_name="NewtonMaterialSetCallbackUserData")
    NewtonMaterialSetCallbackUserData :: proc(newtonWorld : ^NewtonWorld, id0 : i32, id1 : i32, userData : rawptr) ---

    @(link_name="NewtonMaterialSetContactGenerationCallback")
    NewtonMaterialSetContactGenerationCallback :: proc(newtonWorld : ^NewtonWorld, id0 : i32, id1 : i32, contactGeneration : NewtonOnContactGeneration) ---

    @(link_name="NewtonMaterialSetCompoundCollisionCallback")
    NewtonMaterialSetCompoundCollisionCallback :: proc(newtonWorld : ^NewtonWorld, id0 : i32, id1 : i32, compoundAabbOverlap : NewtonOnCompoundSubCollisionAABBOverlap) ---

    @(link_name="NewtonMaterialSetCollisionCallback")
    NewtonMaterialSetCollisionCallback :: proc(newtonWorld : ^NewtonWorld, id0 : i32, id1 : i32, aabbOverlap : NewtonOnAABBOverlap, process : NewtonContactsProcess) ---

    @(link_name="NewtonMaterialSetDefaultSoftness")
    NewtonMaterialSetDefaultSoftness :: proc(newtonWorld : ^NewtonWorld, id0 : i32, id1 : i32, value : dFloat) ---

    @(link_name="NewtonMaterialSetDefaultElasticity")
    NewtonMaterialSetDefaultElasticity :: proc(newtonWorld : ^NewtonWorld, id0 : i32, id1 : i32, elasticCoef : dFloat) ---

    @(link_name="NewtonMaterialSetDefaultCollidable")
    NewtonMaterialSetDefaultCollidable :: proc(newtonWorld : ^NewtonWorld, id0 : i32, id1 : i32, state : i32) ---

    @(link_name="NewtonMaterialSetDefaultFriction")
    NewtonMaterialSetDefaultFriction :: proc(newtonWorld : ^NewtonWorld, id0 : i32, id1 : i32, staticFriction : dFloat, kineticFriction : dFloat) ---

    @(link_name="NewtonMaterialJointResetIntraJointCollision")
    NewtonMaterialJointResetIntraJointCollision :: proc(newtonWorld : ^NewtonWorld, id0 : i32, id1 : i32) ---

    @(link_name="NewtonMaterialJointResetSelftJointCollision")
    NewtonMaterialJointResetSelftJointCollision :: proc(newtonWorld : ^NewtonWorld, id0 : i32, id1 : i32) ---

    @(link_name="NewtonWorldGetFirstMaterial")
    NewtonWorldGetFirstMaterial :: proc(newtonWorld : ^NewtonWorld) -> ^NewtonMaterial ---

    @(link_name="NewtonWorldGetNextMaterial")
    NewtonWorldGetNextMaterial :: proc(newtonWorld : ^NewtonWorld, material : ^NewtonMaterial) -> ^NewtonMaterial ---

    @(link_name="NewtonWorldGetFirstBody")
    NewtonWorldGetFirstBody :: proc(newtonWorld : ^NewtonWorld) -> ^NewtonBody ---

    @(link_name="NewtonWorldGetNextBody")
    NewtonWorldGetNextBody :: proc(newtonWorld : ^NewtonWorld, curBody : ^NewtonBody) -> ^NewtonBody ---

    @(link_name="NewtonMaterialGetMaterialPairUserData")
    NewtonMaterialGetMaterialPairUserData :: proc(material : ^NewtonMaterial) -> rawptr ---

    @(link_name="NewtonMaterialGetContactFaceAttribute")
    NewtonMaterialGetContactFaceAttribute :: proc(material : ^NewtonMaterial) -> u32 ---

    @(link_name="NewtonMaterialGetBodyCollidingShape")
    NewtonMaterialGetBodyCollidingShape :: proc(material : ^NewtonMaterial, body : ^NewtonBody) -> ^NewtonCollision ---

    @(link_name="NewtonMaterialGetContactNormalSpeed")
    NewtonMaterialGetContactNormalSpeed :: proc(material : ^NewtonMaterial) -> dFloat ---

    @(link_name="NewtonMaterialGetContactForce")
    NewtonMaterialGetContactForce :: proc(material : ^NewtonMaterial, body : ^NewtonBody, force : ^dFloat) ---

    @(link_name="NewtonMaterialGetContactPositionAndNormal")
    NewtonMaterialGetContactPositionAndNormal :: proc(material : ^NewtonMaterial, body : ^NewtonBody, posit : ^dFloat, normal : ^dFloat) ---

    @(link_name="NewtonMaterialGetContactTangentDirections")
    NewtonMaterialGetContactTangentDirections :: proc(material : ^NewtonMaterial, body : ^NewtonBody, dir0 : ^dFloat, dir1 : ^dFloat) ---

    @(link_name="NewtonMaterialGetContactTangentSpeed")
    NewtonMaterialGetContactTangentSpeed :: proc(material : ^NewtonMaterial, index : i32) -> dFloat ---

    @(link_name="NewtonMaterialGetContactMaxNormalImpact")
    NewtonMaterialGetContactMaxNormalImpact :: proc(material : ^NewtonMaterial) -> dFloat ---

    @(link_name="NewtonMaterialGetContactMaxTangentImpact")
    NewtonMaterialGetContactMaxTangentImpact :: proc(material : ^NewtonMaterial, index : i32) -> dFloat ---

    @(link_name="NewtonMaterialGetContactPenetration")
    NewtonMaterialGetContactPenetration :: proc(material : ^NewtonMaterial) -> dFloat ---

    @(link_name="NewtonMaterialSetAsSoftContact")
    NewtonMaterialSetAsSoftContact :: proc(material : ^NewtonMaterial, relaxation : dFloat) ---

    @(link_name="NewtonMaterialSetContactSoftness")
    NewtonMaterialSetContactSoftness :: proc(material : ^NewtonMaterial, softness : dFloat) ---

    @(link_name="NewtonMaterialSetContactThickness")
    NewtonMaterialSetContactThickness :: proc(material : ^NewtonMaterial, thickness : dFloat) ---

    @(link_name="NewtonMaterialSetContactElasticity")
    NewtonMaterialSetContactElasticity :: proc(material : ^NewtonMaterial, restitution : dFloat) ---

    @(link_name="NewtonMaterialSetContactFrictionState")
    NewtonMaterialSetContactFrictionState :: proc(material : ^NewtonMaterial, state : i32, index : i32) ---

    @(link_name="NewtonMaterialSetContactFrictionCoef")
    NewtonMaterialSetContactFrictionCoef :: proc(material : ^NewtonMaterial, staticFrictionCoef : dFloat, kineticFrictionCoef : dFloat, index : i32) ---

    @(link_name="NewtonMaterialSetContactNormalAcceleration")
    NewtonMaterialSetContactNormalAcceleration :: proc(material : ^NewtonMaterial, accel : dFloat) ---

    @(link_name="NewtonMaterialSetContactNormalDirection")
    NewtonMaterialSetContactNormalDirection :: proc(material : ^NewtonMaterial, directionVector : ^dFloat) ---

    @(link_name="NewtonMaterialSetContactPosition")
    NewtonMaterialSetContactPosition :: proc(material : ^NewtonMaterial, position : ^dFloat) ---

    @(link_name="NewtonMaterialSetContactTangentFriction")
    NewtonMaterialSetContactTangentFriction :: proc(material : ^NewtonMaterial, friction : dFloat, index : i32) ---

    @(link_name="NewtonMaterialSetContactTangentAcceleration")
    NewtonMaterialSetContactTangentAcceleration :: proc(material : ^NewtonMaterial, accel : dFloat, index : i32) ---

    @(link_name="NewtonMaterialContactRotateTangentDirections")
    NewtonMaterialContactRotateTangentDirections :: proc(material : ^NewtonMaterial, directionVector : ^dFloat) ---

    @(link_name="NewtonMaterialGetContactPruningTolerance")
    NewtonMaterialGetContactPruningTolerance :: proc(contactJoint : ^NewtonJoint) -> dFloat ---

    @(link_name="NewtonMaterialSetContactPruningTolerance")
    NewtonMaterialSetContactPruningTolerance :: proc(contactJoint : ^NewtonJoint, tolerance : dFloat) ---

    @(link_name="NewtonCreateNull")
    NewtonCreateNull :: proc(newtonWorld : ^NewtonWorld) -> ^NewtonCollision ---

    @(link_name="NewtonCreateSphere")
    NewtonCreateSphere :: proc(newtonWorld : ^NewtonWorld, radius : dFloat, shapeID : i32, offsetMatrix : ^dFloat) -> ^NewtonCollision ---

    @(link_name="NewtonCreateBox")
    NewtonCreateBox :: proc(newtonWorld : ^NewtonWorld, dx : dFloat, dy : dFloat, dz : dFloat, shapeID : i32, offsetMatrix : ^dFloat) -> ^NewtonCollision ---

    @(link_name="NewtonCreateCone")
    NewtonCreateCone :: proc(newtonWorld : ^NewtonWorld, radius : dFloat, height : dFloat, shapeID : i32, offsetMatrix : ^dFloat) -> ^NewtonCollision ---

    @(link_name="NewtonCreateCapsule")
    NewtonCreateCapsule :: proc(newtonWorld : ^NewtonWorld, radius0 : dFloat, radius1 : dFloat, height : dFloat, shapeID : i32, offsetMatrix : ^dFloat) -> ^NewtonCollision ---

    @(link_name="NewtonCreateCylinder")
    NewtonCreateCylinder :: proc(newtonWorld : ^NewtonWorld, radio0 : dFloat, radio1 : dFloat, height : dFloat, shapeID : i32, offsetMatrix : ^dFloat) -> ^NewtonCollision ---

    @(link_name="NewtonCreateChamferCylinder")
    NewtonCreateChamferCylinder :: proc(newtonWorld : ^NewtonWorld, radius : dFloat, height : dFloat, shapeID : i32, offsetMatrix : ^dFloat) -> ^NewtonCollision ---

    @(link_name="NewtonCreateConvexHull")
    NewtonCreateConvexHull :: proc(newtonWorld : ^NewtonWorld, count : i32, vertexCloud : ^dFloat, strideInBytes : i32, tolerance : dFloat, shapeID : i32, offsetMatrix : ^dFloat) -> ^NewtonCollision ---

    @(link_name="NewtonCreateConvexHullFromMesh")
    NewtonCreateConvexHullFromMesh :: proc(newtonWorld : ^NewtonWorld, mesh : ^NewtonMesh, tolerance : dFloat, shapeID : i32) -> ^NewtonCollision ---

    @(link_name="NewtonCollisionGetMode")
    NewtonCollisionGetMode :: proc(convexCollision : ^NewtonCollision) -> i32 ---

    @(link_name="NewtonCollisionSetMode")
    NewtonCollisionSetMode :: proc(convexCollision : ^NewtonCollision, mode : i32) ---

    @(link_name="NewtonConvexHullGetFaceIndices")
    NewtonConvexHullGetFaceIndices :: proc(convexHullCollision : ^NewtonCollision, face : i32, faceIndices : ^i32) -> i32 ---

    @(link_name="NewtonConvexHullGetVertexData")
    NewtonConvexHullGetVertexData :: proc(convexHullCollision : ^NewtonCollision, vertexData : ^^dFloat, strideInBytes : ^i32) -> i32 ---

    @(link_name="NewtonConvexCollisionCalculateVolume")
    NewtonConvexCollisionCalculateVolume :: proc(convexCollision : ^NewtonCollision) -> dFloat ---

    @(link_name="NewtonConvexCollisionCalculateInertialMatrix")
    NewtonConvexCollisionCalculateInertialMatrix :: proc(convexCollision : ^NewtonCollision, inertia : ^dFloat, origin : ^dFloat) ---

    @(link_name="NewtonConvexCollisionCalculateBuoyancyVolume")
    NewtonConvexCollisionCalculateBuoyancyVolume :: proc(convexCollision : ^NewtonCollision, matrix4x4 : ^dFloat, fluidPlane : ^dFloat, centerOfBuoyancy : ^dFloat) -> dFloat ---

    @(link_name="NewtonCollisionDataPointer")
    NewtonCollisionDataPointer :: proc(convexCollision : ^NewtonCollision) -> rawptr ---

    @(link_name="NewtonCreateCompoundCollision")
    NewtonCreateCompoundCollision :: proc(newtonWorld : ^NewtonWorld, shapeID : i32) -> ^NewtonCollision ---

    @(link_name="NewtonCreateCompoundCollisionFromMesh")
    NewtonCreateCompoundCollisionFromMesh :: proc(newtonWorld : ^NewtonWorld, mesh : ^NewtonMesh, hullTolerance : dFloat, shapeID : i32, subShapeID : i32) -> ^NewtonCollision ---

    @(link_name="NewtonCompoundCollisionBeginAddRemove")
    NewtonCompoundCollisionBeginAddRemove :: proc(compoundCollision : ^NewtonCollision) ---

    @(link_name="NewtonCompoundCollisionAddSubCollision")
    NewtonCompoundCollisionAddSubCollision :: proc(compoundCollision : ^NewtonCollision, convexCollision : ^NewtonCollision) -> rawptr ---

    @(link_name="NewtonCompoundCollisionRemoveSubCollision")
    NewtonCompoundCollisionRemoveSubCollision :: proc(compoundCollision : ^NewtonCollision, collisionNode : rawptr) ---

    @(link_name="NewtonCompoundCollisionRemoveSubCollisionByIndex")
    NewtonCompoundCollisionRemoveSubCollisionByIndex :: proc(compoundCollision : ^NewtonCollision, nodeIndex : i32) ---

    @(link_name="NewtonCompoundCollisionSetSubCollisionMatrix")
    NewtonCompoundCollisionSetSubCollisionMatrix :: proc(compoundCollision : ^NewtonCollision, collisionNode : rawptr, matrix4x4 : ^dFloat) ---

    @(link_name="NewtonCompoundCollisionEndAddRemove")
    NewtonCompoundCollisionEndAddRemove :: proc(compoundCollision : ^NewtonCollision) ---

    @(link_name="NewtonCompoundCollisionGetFirstNode")
    NewtonCompoundCollisionGetFirstNode :: proc(compoundCollision : ^NewtonCollision) -> rawptr ---

    @(link_name="NewtonCompoundCollisionGetNextNode")
    NewtonCompoundCollisionGetNextNode :: proc(compoundCollision : ^NewtonCollision, collisionNode : rawptr) -> rawptr ---

    @(link_name="NewtonCompoundCollisionGetNodeByIndex")
    NewtonCompoundCollisionGetNodeByIndex :: proc(compoundCollision : ^NewtonCollision, index : i32) -> rawptr ---

    @(link_name="NewtonCompoundCollisionGetNodeIndex")
    NewtonCompoundCollisionGetNodeIndex :: proc(compoundCollision : ^NewtonCollision, collisionNode : rawptr) -> i32 ---

    @(link_name="NewtonCompoundCollisionGetCollisionFromNode")
    NewtonCompoundCollisionGetCollisionFromNode :: proc(compoundCollision : ^NewtonCollision, collisionNode : rawptr) -> ^NewtonCollision ---

    @(link_name="NewtonCreateFracturedCompoundCollision")
    NewtonCreateFracturedCompoundCollision :: proc(newtonWorld : ^NewtonWorld, solidMesh : ^NewtonMesh, shapeID : i32, fracturePhysicsMaterialID : i32, pointcloudCount : i32, vertexCloud : ^dFloat, strideInBytes : i32, materialID : i32, textureMatrix : ^dFloat, regenerateMainMeshCallback : NewtonFractureCompoundCollisionReconstructMainMeshCallBack, emitFracturedCompound : NewtonFractureCompoundCollisionOnEmitCompoundFractured, emitFracfuredChunk : NewtonFractureCompoundCollisionOnEmitChunk) -> ^NewtonCollision ---

    @(link_name="NewtonFracturedCompoundPlaneClip")
    NewtonFracturedCompoundPlaneClip :: proc(fracturedCompound : ^NewtonCollision, plane : ^dFloat) -> ^NewtonCollision ---

    @(link_name="NewtonFracturedCompoundSetCallbacks")
    NewtonFracturedCompoundSetCallbacks :: proc(fracturedCompound : ^NewtonCollision, regenerateMainMeshCallback : NewtonFractureCompoundCollisionReconstructMainMeshCallBack, emitFracturedCompound : NewtonFractureCompoundCollisionOnEmitCompoundFractured, emitFracfuredChunk : NewtonFractureCompoundCollisionOnEmitChunk) ---

    @(link_name="NewtonFracturedCompoundIsNodeFreeToDetach")
    NewtonFracturedCompoundIsNodeFreeToDetach :: proc(fracturedCompound : ^NewtonCollision, collisionNode : rawptr) -> i32 ---

    @(link_name="NewtonFracturedCompoundNeighborNodeList")
    NewtonFracturedCompoundNeighborNodeList :: proc(fracturedCompound : ^NewtonCollision, collisionNode : rawptr, list : ^rawptr, maxCount : i32) -> i32 ---

    @(link_name="NewtonFracturedCompoundGetMainMesh")
    NewtonFracturedCompoundGetMainMesh :: proc(fracturedCompound : ^NewtonCollision) -> ^NewtonFracturedCompoundMeshPart ---

    @(link_name="NewtonFracturedCompoundGetFirstSubMesh")
    NewtonFracturedCompoundGetFirstSubMesh :: proc(fracturedCompound : ^NewtonCollision) -> ^NewtonFracturedCompoundMeshPart ---

    @(link_name="NewtonFracturedCompoundGetNextSubMesh")
    NewtonFracturedCompoundGetNextSubMesh :: proc(fracturedCompound : ^NewtonCollision, subMesh : ^NewtonFracturedCompoundMeshPart) -> ^NewtonFracturedCompoundMeshPart ---

    @(link_name="NewtonFracturedCompoundCollisionGetVertexCount")
    NewtonFracturedCompoundCollisionGetVertexCount :: proc(fracturedCompound : ^NewtonCollision, meshOwner : ^NewtonFracturedCompoundMeshPart) -> i32 ---

    @(link_name="NewtonFracturedCompoundCollisionGetVertexPositions")
    NewtonFracturedCompoundCollisionGetVertexPositions :: proc(fracturedCompound : ^NewtonCollision, meshOwner : ^NewtonFracturedCompoundMeshPart) -> ^dFloat ---

    @(link_name="NewtonFracturedCompoundCollisionGetVertexNormals")
    NewtonFracturedCompoundCollisionGetVertexNormals :: proc(fracturedCompound : ^NewtonCollision, meshOwner : ^NewtonFracturedCompoundMeshPart) -> ^dFloat ---

    @(link_name="NewtonFracturedCompoundCollisionGetVertexUVs")
    NewtonFracturedCompoundCollisionGetVertexUVs :: proc(fracturedCompound : ^NewtonCollision, meshOwner : ^NewtonFracturedCompoundMeshPart) -> ^dFloat ---

    @(link_name="NewtonFracturedCompoundMeshPartGetIndexStream")
    NewtonFracturedCompoundMeshPartGetIndexStream :: proc(fracturedCompound : ^NewtonCollision, meshOwner : ^NewtonFracturedCompoundMeshPart, segment : rawptr, index : ^i32) -> i32 ---

    @(link_name="NewtonFracturedCompoundMeshPartGetFirstSegment")
    NewtonFracturedCompoundMeshPartGetFirstSegment :: proc(fractureCompoundMeshPart : ^NewtonFracturedCompoundMeshPart) -> rawptr ---

    @(link_name="NewtonFracturedCompoundMeshPartGetNextSegment")
    NewtonFracturedCompoundMeshPartGetNextSegment :: proc(fractureCompoundMeshSegment : rawptr) -> rawptr ---

    @(link_name="NewtonFracturedCompoundMeshPartGetMaterial")
    NewtonFracturedCompoundMeshPartGetMaterial :: proc(fractureCompoundMeshSegment : rawptr) -> i32 ---

    @(link_name="NewtonFracturedCompoundMeshPartGetIndexCount")
    NewtonFracturedCompoundMeshPartGetIndexCount :: proc(fractureCompoundMeshSegment : rawptr) -> i32 ---

    @(link_name="NewtonCreateSceneCollision")
    NewtonCreateSceneCollision :: proc(newtonWorld : ^NewtonWorld, shapeID : i32) -> ^NewtonCollision ---

    @(link_name="NewtonSceneCollisionBeginAddRemove")
    NewtonSceneCollisionBeginAddRemove :: proc(sceneCollision : ^NewtonCollision) ---

    @(link_name="NewtonSceneCollisionAddSubCollision")
    NewtonSceneCollisionAddSubCollision :: proc(sceneCollision : ^NewtonCollision, collision : ^NewtonCollision) -> rawptr ---

    @(link_name="NewtonSceneCollisionRemoveSubCollision")
    NewtonSceneCollisionRemoveSubCollision :: proc(compoundCollision : ^NewtonCollision, collisionNode : rawptr) ---

    @(link_name="NewtonSceneCollisionRemoveSubCollisionByIndex")
    NewtonSceneCollisionRemoveSubCollisionByIndex :: proc(sceneCollision : ^NewtonCollision, nodeIndex : i32) ---

    @(link_name="NewtonSceneCollisionSetSubCollisionMatrix")
    NewtonSceneCollisionSetSubCollisionMatrix :: proc(sceneCollision : ^NewtonCollision, collisionNode : rawptr, matrix4x4 : ^dFloat) ---

    @(link_name="NewtonSceneCollisionEndAddRemove")
    NewtonSceneCollisionEndAddRemove :: proc(sceneCollision : ^NewtonCollision) ---

    @(link_name="NewtonSceneCollisionGetFirstNode")
    NewtonSceneCollisionGetFirstNode :: proc(sceneCollision : ^NewtonCollision) -> rawptr ---

    @(link_name="NewtonSceneCollisionGetNextNode")
    NewtonSceneCollisionGetNextNode :: proc(sceneCollision : ^NewtonCollision, collisionNode : rawptr) -> rawptr ---

    @(link_name="NewtonSceneCollisionGetNodeByIndex")
    NewtonSceneCollisionGetNodeByIndex :: proc(sceneCollision : ^NewtonCollision, index : i32) -> rawptr ---

    @(link_name="NewtonSceneCollisionGetNodeIndex")
    NewtonSceneCollisionGetNodeIndex :: proc(sceneCollision : ^NewtonCollision, collisionNode : rawptr) -> i32 ---

    @(link_name="NewtonSceneCollisionGetCollisionFromNode")
    NewtonSceneCollisionGetCollisionFromNode :: proc(sceneCollision : ^NewtonCollision, collisionNode : rawptr) -> ^NewtonCollision ---

    @(link_name="NewtonCreateUserMeshCollision")
    NewtonCreateUserMeshCollision :: proc(newtonWorld : ^NewtonWorld, minBox : ^dFloat, maxBox : ^dFloat, userData : rawptr, collideCallback : NewtonUserMeshCollisionCollideCallback, rayHitCallback : NewtonUserMeshCollisionRayHitCallback, destroyCallback : NewtonUserMeshCollisionDestroyCallback, getInfoCallback : NewtonUserMeshCollisionGetCollisionInfo, getLocalAABBCallback : NewtonUserMeshCollisionAABBTest, facesInAABBCallback : NewtonUserMeshCollisionGetFacesInAABB, serializeCallback : NewtonOnUserCollisionSerializationCallback, shapeID : i32) -> ^NewtonCollision ---

    @(link_name="NewtonUserMeshCollisionContinuousOverlapTest")
    NewtonUserMeshCollisionContinuousOverlapTest :: proc(collideDescData : ^NewtonUserMeshCollisionCollideDesc, continueCollisionHandle : rawptr, minAabb : ^dFloat, maxAabb : ^dFloat) -> i32 ---

    @(link_name="NewtonCreateCollisionFromSerialization")
    NewtonCreateCollisionFromSerialization :: proc(newtonWorld : ^NewtonWorld, deserializeFunction : NewtonDeserializeCallback, serializeHandle : rawptr) -> ^NewtonCollision ---

    @(link_name="NewtonCollisionSerialize")
    NewtonCollisionSerialize :: proc(newtonWorld : ^NewtonWorld, collision : ^NewtonCollision, serializeFunction : NewtonSerializeCallback, serializeHandle : rawptr) ---

    @(link_name="NewtonCollisionGetInfo")
    NewtonCollisionGetInfo :: proc(collision : ^NewtonCollision, collisionInfo : ^NewtonCollisionInfoRecord) ---

    @(link_name="NewtonCreateHeightFieldCollision")
    NewtonCreateHeightFieldCollision :: proc(newtonWorld : ^NewtonWorld, width : i32, height : i32, gridsDiagonals : i32, elevationdatType : i32, elevationMap : rawptr, attributeMap : cstring, verticalScale : dFloat, horizontalScale_x : dFloat, horizontalScale_z : dFloat, shapeID : i32) -> ^NewtonCollision ---

    @(link_name="NewtonHeightFieldSetUserRayCastCallback")
    NewtonHeightFieldSetUserRayCastCallback :: proc(heightfieldCollision : ^NewtonCollision, rayHitCallback : NewtonHeightFieldRayCastCallback) ---

    @(link_name="NewtonCreateTreeCollision")
    NewtonCreateTreeCollision :: proc(newtonWorld : ^NewtonWorld, shapeID : i32) -> ^NewtonCollision ---

    @(link_name="NewtonCreateTreeCollisionFromMesh")
    NewtonCreateTreeCollisionFromMesh :: proc(newtonWorld : ^NewtonWorld, mesh : ^NewtonMesh, shapeID : i32) -> ^NewtonCollision ---

    @(link_name="NewtonTreeCollisionSetUserRayCastCallback")
    NewtonTreeCollisionSetUserRayCastCallback :: proc(treeCollision : ^NewtonCollision, rayHitCallback : NewtonCollisionTreeRayCastCallback) ---

    @(link_name="NewtonTreeCollisionBeginBuild")
    NewtonTreeCollisionBeginBuild :: proc(treeCollision : ^NewtonCollision) ---

    @(link_name="NewtonTreeCollisionAddFace")
    NewtonTreeCollisionAddFace :: proc(treeCollision : ^NewtonCollision, vertexCount : i32, vertexPtr : ^dFloat, strideInBytes : i32, faceAttribute : i32) ---

    @(link_name="NewtonTreeCollisionEndBuild")
    NewtonTreeCollisionEndBuild :: proc(treeCollision : ^NewtonCollision, optimize : i32) ---

    @(link_name="NewtonTreeCollisionGetFaceAttribute")
    NewtonTreeCollisionGetFaceAttribute :: proc(treeCollision : ^NewtonCollision, faceIndexArray : ^i32, indexCount : i32) -> i32 ---

    @(link_name="NewtonTreeCollisionSetFaceAttribute")
    NewtonTreeCollisionSetFaceAttribute :: proc(treeCollision : ^NewtonCollision, faceIndexArray : ^i32, indexCount : i32, attribute : i32) ---

    @(link_name="NewtonTreeCollisionForEachFace")
    NewtonTreeCollisionForEachFace :: proc(treeCollision : ^NewtonCollision, forEachFaceCallback : NewtonTreeCollisionFaceCallback, _context : rawptr) ---

    @(link_name="NewtonTreeCollisionGetVertexListTriangleListInAABB")
    NewtonTreeCollisionGetVertexListTriangleListInAABB :: proc(treeCollision : ^NewtonCollision, p0 : ^dFloat, p1 : ^dFloat, vertexArray : ^^dFloat, vertexCount : ^i32, vertexStrideInBytes : ^i32, indexList : ^i32, maxIndexCount : i32, faceAttribute : ^i32) -> i32 ---

    @(link_name="NewtonStaticCollisionSetDebugCallback")
    NewtonStaticCollisionSetDebugCallback :: proc(staticCollision : ^NewtonCollision, userCallback : NewtonTreeCollisionCallback) ---

    @(link_name="NewtonCollisionCreateInstance")
    NewtonCollisionCreateInstance :: proc(collision : ^NewtonCollision) -> ^NewtonCollision ---

    @(link_name="NewtonCollisionGetType")
    NewtonCollisionGetType :: proc(collision : ^NewtonCollision) -> i32 ---

    @(link_name="NewtonCollisionIsConvexShape")
    NewtonCollisionIsConvexShape :: proc(collision : ^NewtonCollision) -> i32 ---

    @(link_name="NewtonCollisionIsStaticShape")
    NewtonCollisionIsStaticShape :: proc(collision : ^NewtonCollision) -> i32 ---

    @(link_name="NewtonCollisionSetUserData")
    NewtonCollisionSetUserData :: proc(collision : ^NewtonCollision, userData : rawptr) ---

    @(link_name="NewtonCollisionGetUserData")
    NewtonCollisionGetUserData :: proc(collision : ^NewtonCollision) -> rawptr ---

    @(link_name="NewtonCollisionSetUserID")
    NewtonCollisionSetUserID :: proc(collision : ^NewtonCollision, id : i64) ---

    @(link_name="NewtonCollisionGetUserID")
    NewtonCollisionGetUserID :: proc(collision : ^NewtonCollision) -> i64 ---

    @(link_name="NewtonCollisionGetMaterial")
    NewtonCollisionGetMaterial :: proc(collision : ^NewtonCollision, userData : ^NewtonCollisionMaterial) ---

    @(link_name="NewtonCollisionSetMaterial")
    NewtonCollisionSetMaterial :: proc(collision : ^NewtonCollision, userData : ^NewtonCollisionMaterial) ---

    @(link_name="NewtonCollisionGetSubCollisionHandle")
    NewtonCollisionGetSubCollisionHandle :: proc(collision : ^NewtonCollision) -> rawptr ---

    @(link_name="NewtonCollisionGetParentInstance")
    NewtonCollisionGetParentInstance :: proc(collision : ^NewtonCollision) -> ^NewtonCollision ---

    @(link_name="NewtonCollisionSetMatrix")
    NewtonCollisionSetMatrix :: proc(collision : ^NewtonCollision, matrix4x4 : ^dFloat) ---

    @(link_name="NewtonCollisionGetMatrix")
    NewtonCollisionGetMatrix :: proc(collision : ^NewtonCollision, matrix4x4 : ^dFloat) ---

    @(link_name="NewtonCollisionSetScale")
    NewtonCollisionSetScale :: proc(collision : ^NewtonCollision, scaleX : dFloat, scaleY : dFloat, scaleZ : dFloat) ---

    @(link_name="NewtonCollisionGetScale")
    NewtonCollisionGetScale :: proc(collision : ^NewtonCollision, scaleX : ^dFloat, scaleY : ^dFloat, scaleZ : ^dFloat) ---

    @(link_name="NewtonDestroyCollision")
    NewtonDestroyCollision :: proc(collision : ^NewtonCollision) ---

    @(link_name="NewtonCollisionGetSkinThickness")
    NewtonCollisionGetSkinThickness :: proc(collision : ^NewtonCollision) -> dFloat ---

    @(link_name="NewtonCollisionSetSkinThickness")
    NewtonCollisionSetSkinThickness :: proc(collision : ^NewtonCollision, thickness : dFloat) ---

    @(link_name="NewtonCollisionIntersectionTest")
    NewtonCollisionIntersectionTest :: proc(newtonWorld : ^NewtonWorld, collisionA : ^NewtonCollision, matrixA : ^dFloat, collisionB : ^NewtonCollision, matrixB : ^dFloat, threadIndex : i32) -> i32 ---

    @(link_name="NewtonCollisionPointDistance")
    NewtonCollisionPointDistance :: proc(newtonWorld : ^NewtonWorld, point : ^dFloat, collision : ^NewtonCollision, matrix4x4 : ^dFloat, contact : ^dFloat, normal : ^dFloat, threadIndex : i32) -> i32 ---

    @(link_name="NewtonCollisionClosestPoint")
    NewtonCollisionClosestPoint :: proc(newtonWorld : ^NewtonWorld, collisionA : ^NewtonCollision, matrixA : ^dFloat, collisionB : ^NewtonCollision, matrixB : ^dFloat, contactA : ^dFloat, contactB : ^dFloat, normalAB : ^dFloat, threadIndex : i32) -> i32 ---

    @(link_name="NewtonCollisionCollide")
    NewtonCollisionCollide :: proc(newtonWorld : ^NewtonWorld, maxSize : i32, collisionA : ^NewtonCollision, matrixA : ^dFloat, collisionB : ^NewtonCollision, matrixB : ^dFloat, contacts : ^dFloat, normals : ^dFloat, penetration : ^dFloat, attributeA : ^i64, attributeB : ^i64, threadIndex : i32) -> i32 ---

    @(link_name="NewtonCollisionCollideContinue")
    NewtonCollisionCollideContinue :: proc(newtonWorld : ^NewtonWorld, maxSize : i32, timestep : dFloat, collisionA : ^NewtonCollision, matrixA : ^dFloat, velocA : ^dFloat, omegaA : ^dFloat, collisionB : ^NewtonCollision, matrixB : ^dFloat, velocB : ^dFloat, omegaB : ^dFloat, timeOfImpact : ^dFloat, contacts : ^dFloat, normals : ^dFloat, penetration : ^dFloat, attributeA : ^i64, attributeB : ^i64, threadIndex : i32) -> i32 ---

    @(link_name="NewtonCollisionSupportVertex")
    NewtonCollisionSupportVertex :: proc(collision : ^NewtonCollision, dir : ^dFloat, vertex : ^dFloat) ---

    @(link_name="NewtonCollisionRayCast")
    NewtonCollisionRayCast :: proc(collision : ^NewtonCollision, p0 : ^dFloat, p1 : ^dFloat, normal : ^dFloat, attribute : ^i64) -> dFloat ---

    @(link_name="NewtonCollisionCalculateAABB")
    NewtonCollisionCalculateAABB :: proc(collision : ^NewtonCollision, matrix4x4 : ^dFloat, p0 : ^dFloat, p1 : ^dFloat) ---

    @(link_name="NewtonCollisionForEachPolygonDo")
    NewtonCollisionForEachPolygonDo :: proc(collision : ^NewtonCollision, matrix4x4 : ^dFloat, callback : NewtonCollisionIterator, userData : rawptr) ---

    @(link_name="NewtonCollisionAggregateCreate")
    NewtonCollisionAggregateCreate :: proc(world : ^NewtonWorld) -> rawptr ---

    @(link_name="NewtonCollisionAggregateDestroy")
    NewtonCollisionAggregateDestroy :: proc(aggregate : rawptr) ---

    @(link_name="NewtonCollisionAggregateAddBody")
    NewtonCollisionAggregateAddBody :: proc(aggregate : rawptr, body : ^NewtonBody) ---

    @(link_name="NewtonCollisionAggregateRemoveBody")
    NewtonCollisionAggregateRemoveBody :: proc(aggregate : rawptr, body : ^NewtonBody) ---

    @(link_name="NewtonCollisionAggregateGetSelfCollision")
    NewtonCollisionAggregateGetSelfCollision :: proc(aggregate : rawptr) -> i32 ---

    @(link_name="NewtonCollisionAggregateSetSelfCollision")
    NewtonCollisionAggregateSetSelfCollision :: proc(aggregate : rawptr, state : i32) ---

    @(link_name="NewtonSetEulerAngle")
    NewtonSetEulerAngle :: proc(eulersAngles : ^dFloat, matrix4x4 : ^dFloat) ---

    @(link_name="NewtonGetEulerAngle")
    NewtonGetEulerAngle :: proc(matrix4x4 : ^dFloat, eulersAngles0 : ^dFloat, eulersAngles1 : ^dFloat) ---

    @(link_name="NewtonCalculateSpringDamperAcceleration")
    NewtonCalculateSpringDamperAcceleration :: proc(dt : dFloat, ks : dFloat, x : dFloat, kd : dFloat, s : dFloat) -> dFloat ---

    @(link_name="NewtonCreateDynamicBody")
    NewtonCreateDynamicBody :: proc(newtonWorld : ^NewtonWorld, collision : ^NewtonCollision, matrix4x4 : ^dFloat) -> ^NewtonBody ---

    @(link_name="NewtonCreateKinematicBody")
    NewtonCreateKinematicBody :: proc(newtonWorld : ^NewtonWorld, collision : ^NewtonCollision, matrix4x4 : ^dFloat) -> ^NewtonBody ---

    @(link_name="NewtonCreateAsymetricDynamicBody")
    NewtonCreateAsymetricDynamicBody :: proc(newtonWorld : ^NewtonWorld, collision : ^NewtonCollision, matrix4x4 : ^dFloat) -> ^NewtonBody ---

    @(link_name="NewtonDestroyBody")
    NewtonDestroyBody :: proc(body : ^NewtonBody) ---

    @(link_name="NewtonBodyGetSimulationState")
    NewtonBodyGetSimulationState :: proc(body : ^NewtonBody) -> i32 ---

    @(link_name="NewtonBodySetSimulationState")
    NewtonBodySetSimulationState :: proc(bodyPtr : ^NewtonBody, state : i32) ---

    @(link_name="NewtonBodyGetType")
    NewtonBodyGetType :: proc(body : ^NewtonBody) -> i32 ---

    @(link_name="NewtonBodyGetCollidable")
    NewtonBodyGetCollidable :: proc(body : ^NewtonBody) -> i32 ---

    @(link_name="NewtonBodySetCollidable")
    NewtonBodySetCollidable :: proc(body : ^NewtonBody, collidableState : i32) ---

    @(link_name="NewtonBodyAddForce")
    NewtonBodyAddForce :: proc(body : ^NewtonBody, force : ^dFloat) ---

    @(link_name="NewtonBodyAddTorque")
    NewtonBodyAddTorque :: proc(body : ^NewtonBody, torque : ^dFloat) ---

    @(link_name="NewtonBodySetCentreOfMass")
    NewtonBodySetCentreOfMass :: proc(body : ^NewtonBody, com : ^dFloat) ---

    @(link_name="NewtonBodySetMassMatrix")
    NewtonBodySetMassMatrix :: proc(body : ^NewtonBody, mass : dFloat, Ixx : dFloat, Iyy : dFloat, Izz : dFloat) ---

    @(link_name="NewtonBodySetFullMassMatrix")
    NewtonBodySetFullMassMatrix :: proc(body : ^NewtonBody, mass : dFloat, inertiaMatrix : ^dFloat) ---

    @(link_name="NewtonBodySetMassProperties")
    NewtonBodySetMassProperties :: proc(body : ^NewtonBody, mass : dFloat, collision : ^NewtonCollision) ---

    @(link_name="NewtonBodySetMatrix")
    NewtonBodySetMatrix :: proc(body : ^NewtonBody, matrix4x4 : ^dFloat) ---

    @(link_name="NewtonBodySetMatrixNoSleep")
    NewtonBodySetMatrixNoSleep :: proc(body : ^NewtonBody, matrix4x4 : ^dFloat) ---

    @(link_name="NewtonBodySetMatrixRecursive")
    NewtonBodySetMatrixRecursive :: proc(body : ^NewtonBody, matrix4x4 : ^dFloat) ---

    @(link_name="NewtonBodySetMaterialGroupID")
    NewtonBodySetMaterialGroupID :: proc(body : ^NewtonBody, id : i32) ---

    @(link_name="NewtonBodySetContinuousCollisionMode")
    NewtonBodySetContinuousCollisionMode :: proc(body : ^NewtonBody, state : u32) ---

    @(link_name="NewtonBodySetJointRecursiveCollision")
    NewtonBodySetJointRecursiveCollision :: proc(body : ^NewtonBody, state : u32) ---

    @(link_name="NewtonBodySetOmega")
    NewtonBodySetOmega :: proc(body : ^NewtonBody, omega : ^dFloat) ---

    @(link_name="NewtonBodySetOmegaNoSleep")
    NewtonBodySetOmegaNoSleep :: proc(body : ^NewtonBody, omega : ^dFloat) ---

    @(link_name="NewtonBodySetVelocity")
    NewtonBodySetVelocity :: proc(body : ^NewtonBody, velocity : ^dFloat) ---

    @(link_name="NewtonBodySetVelocityNoSleep")
    NewtonBodySetVelocityNoSleep :: proc(body : ^NewtonBody, velocity : ^dFloat) ---

    @(link_name="NewtonBodySetForce")
    NewtonBodySetForce :: proc(body : ^NewtonBody, force : ^dFloat) ---

    @(link_name="NewtonBodySetTorque")
    NewtonBodySetTorque :: proc(body : ^NewtonBody, torque : ^dFloat) ---

    @(link_name="NewtonBodySetLinearDamping")
    NewtonBodySetLinearDamping :: proc(body : ^NewtonBody, linearDamp : dFloat) ---

    @(link_name="NewtonBodySetAngularDamping")
    NewtonBodySetAngularDamping :: proc(body : ^NewtonBody, angularDamp : ^dFloat) ---

    @(link_name="NewtonBodySetCollision")
    NewtonBodySetCollision :: proc(body : ^NewtonBody, collision : ^NewtonCollision) ---

    @(link_name="NewtonBodySetCollisionScale")
    NewtonBodySetCollisionScale :: proc(body : ^NewtonBody, scaleX : dFloat, scaleY : dFloat, scaleZ : dFloat) ---

    @(link_name="NewtonBodyGetSleepState")
    NewtonBodyGetSleepState :: proc(body : ^NewtonBody) -> i32 ---

    @(link_name="NewtonBodySetSleepState")
    NewtonBodySetSleepState :: proc(body : ^NewtonBody, state : i32) ---

    @(link_name="NewtonBodyGetAutoSleep")
    NewtonBodyGetAutoSleep :: proc(body : ^NewtonBody) -> i32 ---

    @(link_name="NewtonBodySetAutoSleep")
    NewtonBodySetAutoSleep :: proc(body : ^NewtonBody, state : i32) ---

    @(link_name="NewtonBodyGetFreezeState")
    NewtonBodyGetFreezeState :: proc(body : ^NewtonBody) -> i32 ---

    @(link_name="NewtonBodySetFreezeState")
    NewtonBodySetFreezeState :: proc(body : ^NewtonBody, state : i32) ---

    @(link_name="NewtonBodyGetGyroscopicTorque")
    NewtonBodyGetGyroscopicTorque :: proc(body : ^NewtonBody) -> i32 ---

    @(link_name="NewtonBodySetGyroscopicTorque")
    NewtonBodySetGyroscopicTorque :: proc(body : ^NewtonBody, state : i32) ---

    @(link_name="NewtonBodySetDestructorCallback")
    NewtonBodySetDestructorCallback :: proc(body : ^NewtonBody, callback : NewtonBodyDestructor) ---

    @(link_name="NewtonBodyGetDestructorCallback")
    NewtonBodyGetDestructorCallback :: proc(body : ^NewtonBody) -> NewtonBodyDestructor ---

    @(link_name="NewtonBodySetTransformCallback")
    NewtonBodySetTransformCallback :: proc(body : ^NewtonBody, callback : NewtonSetTransform) ---

    @(link_name="NewtonBodyGetTransformCallback")
    NewtonBodyGetTransformCallback :: proc(body : ^NewtonBody) -> NewtonSetTransform ---

    @(link_name="NewtonBodySetForceAndTorqueCallback")
    NewtonBodySetForceAndTorqueCallback :: proc(body : ^NewtonBody, callback : NewtonApplyForceAndTorque) ---

    @(link_name="NewtonBodyGetForceAndTorqueCallback")
    NewtonBodyGetForceAndTorqueCallback :: proc(body : ^NewtonBody) -> NewtonApplyForceAndTorque ---

    @(link_name="NewtonBodyGetID")
    NewtonBodyGetID :: proc(body : ^NewtonBody) -> i32 ---

    @(link_name="NewtonBodySetUserData")
    NewtonBodySetUserData :: proc(body : ^NewtonBody, userData : rawptr) ---

    @(link_name="NewtonBodyGetUserData")
    NewtonBodyGetUserData :: proc(body : ^NewtonBody) -> rawptr ---

    @(link_name="NewtonBodyGetWorld")
    NewtonBodyGetWorld :: proc(body : ^NewtonBody) -> ^NewtonWorld ---

    @(link_name="NewtonBodyGetCollision")
    NewtonBodyGetCollision :: proc(body : ^NewtonBody) -> ^NewtonCollision ---

    @(link_name="NewtonBodyGetMaterialGroupID")
    NewtonBodyGetMaterialGroupID :: proc(body : ^NewtonBody) -> i32 ---

    @(link_name="NewtonBodyGetSerializedID")
    NewtonBodyGetSerializedID :: proc(body : ^NewtonBody) -> i32 ---

    @(link_name="NewtonBodyGetContinuousCollisionMode")
    NewtonBodyGetContinuousCollisionMode :: proc(body : ^NewtonBody) -> i32 ---

    @(link_name="NewtonBodyGetJointRecursiveCollision")
    NewtonBodyGetJointRecursiveCollision :: proc(body : ^NewtonBody) -> i32 ---

    @(link_name="NewtonBodyGetPosition")
    NewtonBodyGetPosition :: proc(body : ^NewtonBody, pos : ^dFloat) ---

    @(link_name="NewtonBodyGetMatrix")
    NewtonBodyGetMatrix :: proc(body : ^NewtonBody, matrix4x4 : ^dFloat) ---

    @(link_name="NewtonBodyGetRotation")
    NewtonBodyGetRotation :: proc(body : ^NewtonBody, rotation : ^dFloat) ---

    @(link_name="NewtonBodyGetMass")
    NewtonBodyGetMass :: proc(body : ^NewtonBody, mass : ^dFloat, Ixx : ^dFloat, Iyy : ^dFloat, Izz : ^dFloat) ---

    @(link_name="NewtonBodyGetInvMass")
    NewtonBodyGetInvMass :: proc(body : ^NewtonBody, invMass : ^dFloat, invIxx : ^dFloat, invIyy : ^dFloat, invIzz : ^dFloat) ---

    @(link_name="NewtonBodyGetInertiaMatrix")
    NewtonBodyGetInertiaMatrix :: proc(body : ^NewtonBody, inertiaMatrix : ^dFloat) ---

    @(link_name="NewtonBodyGetInvInertiaMatrix")
    NewtonBodyGetInvInertiaMatrix :: proc(body : ^NewtonBody, invInertiaMatrix : ^dFloat) ---

    @(link_name="NewtonBodyGetOmega")
    NewtonBodyGetOmega :: proc(body : ^NewtonBody, vector : ^dFloat) ---

    @(link_name="NewtonBodyGetVelocity")
    NewtonBodyGetVelocity :: proc(body : ^NewtonBody, vector : ^dFloat) ---

    @(link_name="NewtonBodyGetAlpha")
    NewtonBodyGetAlpha :: proc(body : ^NewtonBody, vector : ^dFloat) ---

    @(link_name="NewtonBodyGetAcceleration")
    NewtonBodyGetAcceleration :: proc(body : ^NewtonBody, vector : ^dFloat) ---

    @(link_name="NewtonBodyGetForce")
    NewtonBodyGetForce :: proc(body : ^NewtonBody, vector : ^dFloat) ---

    @(link_name="NewtonBodyGetTorque")
    NewtonBodyGetTorque :: proc(body : ^NewtonBody, vector : ^dFloat) ---

    @(link_name="NewtonBodyGetCentreOfMass")
    NewtonBodyGetCentreOfMass :: proc(body : ^NewtonBody, com : ^dFloat) ---

    @(link_name="NewtonBodyGetPointVelocity")
    NewtonBodyGetPointVelocity :: proc(body : ^NewtonBody, point : ^dFloat, velocOut : ^dFloat) ---

    @(link_name="NewtonBodyApplyImpulsePair")
    NewtonBodyApplyImpulsePair :: proc(body : ^NewtonBody, linearImpulse : ^dFloat, angularImpulse : ^dFloat, timestep : dFloat) ---

    @(link_name="NewtonBodyAddImpulse")
    NewtonBodyAddImpulse :: proc(body : ^NewtonBody, pointDeltaVeloc : ^dFloat, pointPosit : ^dFloat, timestep : dFloat) ---

    @(link_name="NewtonBodyApplyImpulseArray")
    NewtonBodyApplyImpulseArray :: proc(body : ^NewtonBody, impuleCount : i32, strideInByte : i32, impulseArray : ^dFloat, pointArray : ^dFloat, timestep : dFloat) ---

    @(link_name="NewtonBodyIntegrateVelocity")
    NewtonBodyIntegrateVelocity :: proc(body : ^NewtonBody, timestep : dFloat) ---

    @(link_name="NewtonBodyGetLinearDamping")
    NewtonBodyGetLinearDamping :: proc(body : ^NewtonBody) -> dFloat ---

    @(link_name="NewtonBodyGetAngularDamping")
    NewtonBodyGetAngularDamping :: proc(body : ^NewtonBody, vector : ^dFloat) ---

    @(link_name="NewtonBodyGetAABB")
    NewtonBodyGetAABB :: proc(body : ^NewtonBody, p0 : ^dFloat, p1 : ^dFloat) ---

    @(link_name="NewtonBodyGetFirstJoint")
    NewtonBodyGetFirstJoint :: proc(body : ^NewtonBody) -> ^NewtonJoint ---

    @(link_name="NewtonBodyGetNextJoint")
    NewtonBodyGetNextJoint :: proc(body : ^NewtonBody, joint : ^NewtonJoint) -> ^NewtonJoint ---

    @(link_name="NewtonBodyGetFirstContactJoint")
    NewtonBodyGetFirstContactJoint :: proc(body : ^NewtonBody) -> ^NewtonJoint ---

    @(link_name="NewtonBodyGetNextContactJoint")
    NewtonBodyGetNextContactJoint :: proc(body : ^NewtonBody, contactJoint : ^NewtonJoint) -> ^NewtonJoint ---

    @(link_name="NewtonBodyFindContact")
    NewtonBodyFindContact :: proc(body0 : ^NewtonBody, body1 : ^NewtonBody) -> ^NewtonJoint ---

    @(link_name="NewtonContactJointGetFirstContact")
    NewtonContactJointGetFirstContact :: proc(contactJoint : ^NewtonJoint) -> rawptr ---

    @(link_name="NewtonContactJointGetNextContact")
    NewtonContactJointGetNextContact :: proc(contactJoint : ^NewtonJoint, contact : rawptr) -> rawptr ---

    @(link_name="NewtonContactJointGetContactCount")
    NewtonContactJointGetContactCount :: proc(contactJoint : ^NewtonJoint) -> i32 ---

    @(link_name="NewtonContactJointRemoveContact")
    NewtonContactJointRemoveContact :: proc(contactJoint : ^NewtonJoint, contact : rawptr) ---

    @(link_name="NewtonContactJointGetClosestDistance")
    NewtonContactJointGetClosestDistance :: proc(contactJoint : ^NewtonJoint) -> dFloat ---

    @(link_name="NewtonContactJointResetSelftJointCollision")
    NewtonContactJointResetSelftJointCollision :: proc(contactJoint : ^NewtonJoint) ---

    @(link_name="NewtonContactJointResetIntraJointCollision")
    NewtonContactJointResetIntraJointCollision :: proc(contactJoint : ^NewtonJoint) ---

    @(link_name="NewtonContactGetMaterial")
    NewtonContactGetMaterial :: proc(contact : rawptr) -> ^NewtonMaterial ---

    @(link_name="NewtonContactGetCollision0")
    NewtonContactGetCollision0 :: proc(contact : rawptr) -> ^NewtonCollision ---

    @(link_name="NewtonContactGetCollision1")
    NewtonContactGetCollision1 :: proc(contact : rawptr) -> ^NewtonCollision ---

    @(link_name="NewtonContactGetCollisionID0")
    NewtonContactGetCollisionID0 :: proc(contact : rawptr) -> rawptr ---

    @(link_name="NewtonContactGetCollisionID1")
    NewtonContactGetCollisionID1 :: proc(contact : rawptr) -> rawptr ---

    @(link_name="NewtonJointGetUserData")
    NewtonJointGetUserData :: proc(joint : ^NewtonJoint) -> rawptr ---

    @(link_name="NewtonJointSetUserData")
    NewtonJointSetUserData :: proc(joint : ^NewtonJoint, userData : rawptr) ---

    @(link_name="NewtonJointGetBody0")
    NewtonJointGetBody0 :: proc(joint : ^NewtonJoint) -> ^NewtonBody ---

    @(link_name="NewtonJointGetBody1")
    NewtonJointGetBody1 :: proc(joint : ^NewtonJoint) -> ^NewtonBody ---

    @(link_name="NewtonJointGetInfo")
    NewtonJointGetInfo :: proc(joint : ^NewtonJoint, info : ^NewtonJointRecord) ---

    @(link_name="NewtonJointGetCollisionState")
    NewtonJointGetCollisionState :: proc(joint : ^NewtonJoint) -> i32 ---

    @(link_name="NewtonJointSetCollisionState")
    NewtonJointSetCollisionState :: proc(joint : ^NewtonJoint, state : i32) ---

    @(link_name="NewtonJointGetStiffness")
    NewtonJointGetStiffness :: proc(joint : ^NewtonJoint) -> dFloat ---

    @(link_name="NewtonJointSetStiffness")
    NewtonJointSetStiffness :: proc(joint : ^NewtonJoint, state : dFloat) ---

    @(link_name="NewtonDestroyJoint")
    NewtonDestroyJoint :: proc(newtonWorld : ^NewtonWorld, joint : ^NewtonJoint) ---

    @(link_name="NewtonJointSetDestructor")
    NewtonJointSetDestructor :: proc(joint : ^NewtonJoint, destructor : NewtonConstraintDestructor) ---

    @(link_name="NewtonJointIsActive")
    NewtonJointIsActive :: proc(joint : ^NewtonJoint) -> i32 ---

    @(link_name="NewtonCreateMassSpringDamperSystem")
    NewtonCreateMassSpringDamperSystem :: proc(newtonWorld : ^NewtonWorld, shapeID : i32, points : ^dFloat, pointCount : i32, strideInBytes : i32, pointMass : ^dFloat, links : ^i32, linksCount : i32, linksSpring : ^dFloat, linksDamper : ^dFloat) -> ^NewtonCollision ---

    @(link_name="NewtonCreateDeformableSolid")
    NewtonCreateDeformableSolid :: proc(newtonWorld : ^NewtonWorld, mesh : ^NewtonMesh, shapeID : i32) -> ^NewtonCollision ---

    @(link_name="NewtonDeformableMeshGetParticleCount")
    NewtonDeformableMeshGetParticleCount :: proc(deformableMesh : ^NewtonCollision) -> i32 ---

    @(link_name="NewtonDeformableMeshGetParticleStrideInBytes")
    NewtonDeformableMeshGetParticleStrideInBytes :: proc(deformableMesh : ^NewtonCollision) -> i32 ---

    @(link_name="NewtonDeformableMeshGetParticleArray")
    NewtonDeformableMeshGetParticleArray :: proc(deformableMesh : ^NewtonCollision) -> ^dFloat ---

    @(link_name="NewtonConstraintCreateBall")
    NewtonConstraintCreateBall :: proc(newtonWorld : ^NewtonWorld, pivotPoint : ^dFloat, childBody : ^NewtonBody, parentBody : ^NewtonBody) -> ^NewtonJoint ---

    @(link_name="NewtonBallSetUserCallback")
    NewtonBallSetUserCallback :: proc(ball : ^NewtonJoint, callback : NewtonBallCallback) ---

    @(link_name="NewtonBallGetJointAngle")
    NewtonBallGetJointAngle :: proc(ball : ^NewtonJoint, angle : ^dFloat) ---

    @(link_name="NewtonBallGetJointOmega")
    NewtonBallGetJointOmega :: proc(ball : ^NewtonJoint, omega : ^dFloat) ---

    @(link_name="NewtonBallGetJointForce")
    NewtonBallGetJointForce :: proc(ball : ^NewtonJoint, force : ^dFloat) ---

    @(link_name="NewtonBallSetConeLimits")
    NewtonBallSetConeLimits :: proc(ball : ^NewtonJoint, pin : ^dFloat, maxConeAngle : dFloat, maxTwistAngle : dFloat) ---

    @(link_name="NewtonConstraintCreateHinge")
    NewtonConstraintCreateHinge :: proc(newtonWorld : ^NewtonWorld, pivotPoint : ^dFloat, pinDir : ^dFloat, childBody : ^NewtonBody, parentBody : ^NewtonBody) -> ^NewtonJoint ---

    @(link_name="NewtonHingeSetUserCallback")
    NewtonHingeSetUserCallback :: proc(hinge : ^NewtonJoint, callback : NewtonHingeCallback) ---

    @(link_name="NewtonHingeGetJointAngle")
    NewtonHingeGetJointAngle :: proc(hinge : ^NewtonJoint) -> dFloat ---

    @(link_name="NewtonHingeGetJointOmega")
    NewtonHingeGetJointOmega :: proc(hinge : ^NewtonJoint) -> dFloat ---

    @(link_name="NewtonHingeGetJointForce")
    NewtonHingeGetJointForce :: proc(hinge : ^NewtonJoint, force : ^dFloat) ---

    @(link_name="NewtonHingeCalculateStopAlpha")
    NewtonHingeCalculateStopAlpha :: proc(hinge : ^NewtonJoint, desc : ^NewtonHingeSliderUpdateDesc, angle : dFloat) -> dFloat ---

    @(link_name="NewtonConstraintCreateSlider")
    NewtonConstraintCreateSlider :: proc(newtonWorld : ^NewtonWorld, pivotPoint : ^dFloat, pinDir : ^dFloat, childBody : ^NewtonBody, parentBody : ^NewtonBody) -> ^NewtonJoint ---

    @(link_name="NewtonSliderSetUserCallback")
    NewtonSliderSetUserCallback :: proc(slider : ^NewtonJoint, callback : NewtonSliderCallback) ---

    @(link_name="NewtonSliderGetJointPosit")
    NewtonSliderGetJointPosit :: proc(slider : ^NewtonJoint) -> dFloat ---

    @(link_name="NewtonSliderGetJointVeloc")
    NewtonSliderGetJointVeloc :: proc(slider : ^NewtonJoint) -> dFloat ---

    @(link_name="NewtonSliderGetJointForce")
    NewtonSliderGetJointForce :: proc(slider : ^NewtonJoint, force : ^dFloat) ---

    @(link_name="NewtonSliderCalculateStopAccel")
    NewtonSliderCalculateStopAccel :: proc(slider : ^NewtonJoint, desc : ^NewtonHingeSliderUpdateDesc, position : dFloat) -> dFloat ---

    @(link_name="NewtonConstraintCreateCorkscrew")
    NewtonConstraintCreateCorkscrew :: proc(newtonWorld : ^NewtonWorld, pivotPoint : ^dFloat, pinDir : ^dFloat, childBody : ^NewtonBody, parentBody : ^NewtonBody) -> ^NewtonJoint ---

    @(link_name="NewtonCorkscrewSetUserCallback")
    NewtonCorkscrewSetUserCallback :: proc(corkscrew : ^NewtonJoint, callback : NewtonCorkscrewCallback) ---

    @(link_name="NewtonCorkscrewGetJointPosit")
    NewtonCorkscrewGetJointPosit :: proc(corkscrew : ^NewtonJoint) -> dFloat ---

    @(link_name="NewtonCorkscrewGetJointAngle")
    NewtonCorkscrewGetJointAngle :: proc(corkscrew : ^NewtonJoint) -> dFloat ---

    @(link_name="NewtonCorkscrewGetJointVeloc")
    NewtonCorkscrewGetJointVeloc :: proc(corkscrew : ^NewtonJoint) -> dFloat ---

    @(link_name="NewtonCorkscrewGetJointOmega")
    NewtonCorkscrewGetJointOmega :: proc(corkscrew : ^NewtonJoint) -> dFloat ---

    @(link_name="NewtonCorkscrewGetJointForce")
    NewtonCorkscrewGetJointForce :: proc(corkscrew : ^NewtonJoint, force : ^dFloat) ---

    @(link_name="NewtonCorkscrewCalculateStopAlpha")
    NewtonCorkscrewCalculateStopAlpha :: proc(corkscrew : ^NewtonJoint, desc : ^NewtonHingeSliderUpdateDesc, angle : dFloat) -> dFloat ---

    @(link_name="NewtonCorkscrewCalculateStopAccel")
    NewtonCorkscrewCalculateStopAccel :: proc(corkscrew : ^NewtonJoint, desc : ^NewtonHingeSliderUpdateDesc, position : dFloat) -> dFloat ---

    @(link_name="NewtonConstraintCreateUniversal")
    NewtonConstraintCreateUniversal :: proc(newtonWorld : ^NewtonWorld, pivotPoint : ^dFloat, pinDir0 : ^dFloat, pinDir1 : ^dFloat, childBody : ^NewtonBody, parentBody : ^NewtonBody) -> ^NewtonJoint ---

    @(link_name="NewtonUniversalSetUserCallback")
    NewtonUniversalSetUserCallback :: proc(universal : ^NewtonJoint, callback : NewtonUniversalCallback) ---

    @(link_name="NewtonUniversalGetJointAngle0")
    NewtonUniversalGetJointAngle0 :: proc(universal : ^NewtonJoint) -> dFloat ---

    @(link_name="NewtonUniversalGetJointAngle1")
    NewtonUniversalGetJointAngle1 :: proc(universal : ^NewtonJoint) -> dFloat ---

    @(link_name="NewtonUniversalGetJointOmega0")
    NewtonUniversalGetJointOmega0 :: proc(universal : ^NewtonJoint) -> dFloat ---

    @(link_name="NewtonUniversalGetJointOmega1")
    NewtonUniversalGetJointOmega1 :: proc(universal : ^NewtonJoint) -> dFloat ---

    @(link_name="NewtonUniversalGetJointForce")
    NewtonUniversalGetJointForce :: proc(universal : ^NewtonJoint, force : ^dFloat) ---

    @(link_name="NewtonUniversalCalculateStopAlpha0")
    NewtonUniversalCalculateStopAlpha0 :: proc(universal : ^NewtonJoint, desc : ^NewtonHingeSliderUpdateDesc, angle : dFloat) -> dFloat ---

    @(link_name="NewtonUniversalCalculateStopAlpha1")
    NewtonUniversalCalculateStopAlpha1 :: proc(universal : ^NewtonJoint, desc : ^NewtonHingeSliderUpdateDesc, angle : dFloat) -> dFloat ---

    @(link_name="NewtonConstraintCreateUpVector")
    NewtonConstraintCreateUpVector :: proc(newtonWorld : ^NewtonWorld, pinDir : ^dFloat, body : ^NewtonBody) -> ^NewtonJoint ---

    @(link_name="NewtonUpVectorGetPin")
    NewtonUpVectorGetPin :: proc(upVector : ^NewtonJoint, pin : ^dFloat) ---

    @(link_name="NewtonUpVectorSetPin")
    NewtonUpVectorSetPin :: proc(upVector : ^NewtonJoint, pin : ^dFloat) ---

    @(link_name="NewtonConstraintCreateUserJoint")
    NewtonConstraintCreateUserJoint :: proc(newtonWorld : ^NewtonWorld, maxDOF : i32, callback : NewtonUserBilateralCallback, childBody : ^NewtonBody, parentBody : ^NewtonBody) -> ^NewtonJoint ---

    @(link_name="NewtonUserJointGetSolverModel")
    NewtonUserJointGetSolverModel :: proc(joint : ^NewtonJoint) -> i32 ---

    @(link_name="NewtonUserJointSetSolverModel")
    NewtonUserJointSetSolverModel :: proc(joint : ^NewtonJoint, model : i32) ---

    @(link_name="NewtonUserJointMassScale")
    NewtonUserJointMassScale :: proc(joint : ^NewtonJoint, scaleBody0 : dFloat, scaleBody1 : dFloat) ---

    @(link_name="NewtonUserJointSetFeedbackCollectorCallback")
    NewtonUserJointSetFeedbackCollectorCallback :: proc(joint : ^NewtonJoint, getFeedback : NewtonUserBilateralCallback) ---

    @(link_name="NewtonUserJointAddLinearRow")
    NewtonUserJointAddLinearRow :: proc(joint : ^NewtonJoint, pivot0 : ^dFloat, pivot1 : ^dFloat, dir : ^dFloat) ---

    @(link_name="NewtonUserJointAddAngularRow")
    NewtonUserJointAddAngularRow :: proc(joint : ^NewtonJoint, relativeAngle : dFloat, dir : ^dFloat) ---

    @(link_name="NewtonUserJointAddGeneralRow")
    NewtonUserJointAddGeneralRow :: proc(joint : ^NewtonJoint, jacobian0 : ^dFloat, jacobian1 : ^dFloat) ---

    @(link_name="NewtonUserJointSetRowMinimumFriction")
    NewtonUserJointSetRowMinimumFriction :: proc(joint : ^NewtonJoint, friction : dFloat) ---

    @(link_name="NewtonUserJointSetRowMaximumFriction")
    NewtonUserJointSetRowMaximumFriction :: proc(joint : ^NewtonJoint, friction : dFloat) ---

    @(link_name="NewtonUserJointCalculateRowZeroAcceleration")
    NewtonUserJointCalculateRowZeroAcceleration :: proc(joint : ^NewtonJoint) -> dFloat ---

    @(link_name="NewtonUserJointGetRowAcceleration")
    NewtonUserJointGetRowAcceleration :: proc(joint : ^NewtonJoint) -> dFloat ---

    @(link_name="NewtonUserJointGetRowJacobian")
    NewtonUserJointGetRowJacobian :: proc(joint : ^NewtonJoint, linear0 : ^dFloat, angula0 : ^dFloat, linear1 : ^dFloat, angula1 : ^dFloat) ---

    @(link_name="NewtonUserJointSetRowAcceleration")
    NewtonUserJointSetRowAcceleration :: proc(joint : ^NewtonJoint, acceleration : dFloat) ---

    @(link_name="NewtonUserJointSetRowMassDependentSpringDamperAcceleration")
    NewtonUserJointSetRowMassDependentSpringDamperAcceleration :: proc(joint : ^NewtonJoint, spring : dFloat, damper : dFloat) ---

    @(link_name="NewtonUserJointSetRowMassIndependentSpringDamperAcceleration")
    NewtonUserJointSetRowMassIndependentSpringDamperAcceleration :: proc(joint : ^NewtonJoint, rowStiffness : dFloat, spring : dFloat, damper : dFloat) ---

    @(link_name="NewtonUserJointSetRowStiffness")
    NewtonUserJointSetRowStiffness :: proc(joint : ^NewtonJoint, stiffness : dFloat) ---

    @(link_name="NewtonUserJoinRowsCount")
    NewtonUserJoinRowsCount :: proc(joint : ^NewtonJoint) -> i32 ---

    @(link_name="NewtonUserJointGetGeneralRow")
    NewtonUserJointGetGeneralRow :: proc(joint : ^NewtonJoint, index : i32, jacobian0 : ^dFloat, jacobian1 : ^dFloat) ---

    @(link_name="NewtonUserJointGetRowForce")
    NewtonUserJointGetRowForce :: proc(joint : ^NewtonJoint, row : i32) -> dFloat ---

    @(link_name="NewtonMeshCreate")
    NewtonMeshCreate :: proc(newtonWorld : ^NewtonWorld) -> ^NewtonMesh ---

    @(link_name="NewtonMeshCreateFromMesh")
    NewtonMeshCreateFromMesh :: proc(mesh : ^NewtonMesh) -> ^NewtonMesh ---

    @(link_name="NewtonMeshCreateFromCollision")
    NewtonMeshCreateFromCollision :: proc(collision : ^NewtonCollision) -> ^NewtonMesh ---

    @(link_name="NewtonMeshCreateTetrahedraIsoSurface")
    NewtonMeshCreateTetrahedraIsoSurface :: proc(mesh : ^NewtonMesh) -> ^NewtonMesh ---

    @(link_name="NewtonMeshCreateConvexHull")
    NewtonMeshCreateConvexHull :: proc(newtonWorld : ^NewtonWorld, pointCount : i32, vertexCloud : ^dFloat, strideInBytes : i32, tolerance : dFloat) -> ^NewtonMesh ---

    @(link_name="NewtonMeshCreateVoronoiConvexDecomposition")
    NewtonMeshCreateVoronoiConvexDecomposition :: proc(newtonWorld : ^NewtonWorld, pointCount : i32, vertexCloud : ^dFloat, strideInBytes : i32, materialID : i32, textureMatrix : ^dFloat) -> ^NewtonMesh ---

    @(link_name="NewtonMeshCreateFromSerialization")
    NewtonMeshCreateFromSerialization :: proc(newtonWorld : ^NewtonWorld, deserializeFunction : NewtonDeserializeCallback, serializeHandle : rawptr) -> ^NewtonMesh ---

    @(link_name="NewtonMeshDestroy")
    NewtonMeshDestroy :: proc(mesh : ^NewtonMesh) ---

    @(link_name="NewtonMeshSerialize")
    NewtonMeshSerialize :: proc(mesh : ^NewtonMesh, serializeFunction : NewtonSerializeCallback, serializeHandle : rawptr) ---

    @(link_name="NewtonMeshSaveOFF")
    NewtonMeshSaveOFF :: proc(mesh : ^NewtonMesh, filename : cstring) ---

    @(link_name="NewtonMeshLoadOFF")
    NewtonMeshLoadOFF :: proc(newtonWorld : ^NewtonWorld, filename : cstring) -> ^NewtonMesh ---

    @(link_name="NewtonMeshLoadTetrahedraMesh")
    NewtonMeshLoadTetrahedraMesh :: proc(newtonWorld : ^NewtonWorld, filename : cstring) -> ^NewtonMesh ---

    @(link_name="NewtonMeshFlipWinding")
    NewtonMeshFlipWinding :: proc(mesh : ^NewtonMesh) ---

    @(link_name="NewtonMeshApplyTransform")
    NewtonMeshApplyTransform :: proc(mesh : ^NewtonMesh, matrix4x4 : ^dFloat) ---

    @(link_name="NewtonMeshCalculateOOBB")
    NewtonMeshCalculateOOBB :: proc(mesh : ^NewtonMesh, matrix4x4 : ^dFloat, x : ^dFloat, y : ^dFloat, z : ^dFloat) ---

    @(link_name="NewtonMeshCalculateVertexNormals")
    NewtonMeshCalculateVertexNormals :: proc(mesh : ^NewtonMesh, angleInRadians : dFloat) ---

    @(link_name="NewtonMeshApplySphericalMapping")
    NewtonMeshApplySphericalMapping :: proc(mesh : ^NewtonMesh, material : i32, aligmentMatrix : ^dFloat) ---

    @(link_name="NewtonMeshApplyCylindricalMapping")
    NewtonMeshApplyCylindricalMapping :: proc(mesh : ^NewtonMesh, cylinderMaterial : i32, capMaterial : i32, aligmentMatrix : ^dFloat) ---

    @(link_name="NewtonMeshApplyBoxMapping")
    NewtonMeshApplyBoxMapping :: proc(mesh : ^NewtonMesh, frontMaterial : i32, sideMaterial : i32, topMaterial : i32, aligmentMatrix : ^dFloat) ---

    @(link_name="NewtonMeshApplyAngleBasedMapping")
    NewtonMeshApplyAngleBasedMapping :: proc(mesh : ^NewtonMesh, material : i32, reportPrograssCallback : NewtonReportProgress, reportPrgressUserData : rawptr, aligmentMatrix : ^dFloat) ---

    @(link_name="NewtonCreateTetrahedraLinearBlendSkinWeightsChannel")
    NewtonCreateTetrahedraLinearBlendSkinWeightsChannel :: proc(tetrahedraMesh : ^NewtonMesh, skinMesh : ^NewtonMesh) ---

    @(link_name="NewtonMeshOptimize")
    NewtonMeshOptimize :: proc(mesh : ^NewtonMesh) ---

    @(link_name="NewtonMeshOptimizePoints")
    NewtonMeshOptimizePoints :: proc(mesh : ^NewtonMesh) ---

    @(link_name="NewtonMeshOptimizeVertex")
    NewtonMeshOptimizeVertex :: proc(mesh : ^NewtonMesh) ---

    @(link_name="NewtonMeshIsOpenMesh")
    NewtonMeshIsOpenMesh :: proc(mesh : ^NewtonMesh) -> i32 ---

    @(link_name="NewtonMeshFixTJoints")
    NewtonMeshFixTJoints :: proc(mesh : ^NewtonMesh) ---

    @(link_name="NewtonMeshPolygonize")
    NewtonMeshPolygonize :: proc(mesh : ^NewtonMesh) ---

    @(link_name="NewtonMeshTriangulate")
    NewtonMeshTriangulate :: proc(mesh : ^NewtonMesh) ---

    @(link_name="NewtonMeshUnion")
    NewtonMeshUnion :: proc(mesh : ^NewtonMesh, clipper : ^NewtonMesh, clipperMatrix : ^dFloat) -> ^NewtonMesh ---

    @(link_name="NewtonMeshDifference")
    NewtonMeshDifference :: proc(mesh : ^NewtonMesh, clipper : ^NewtonMesh, clipperMatrix : ^dFloat) -> ^NewtonMesh ---

    @(link_name="NewtonMeshIntersection")
    NewtonMeshIntersection :: proc(mesh : ^NewtonMesh, clipper : ^NewtonMesh, clipperMatrix : ^dFloat) -> ^NewtonMesh ---

    @(link_name="NewtonMeshClip")
    NewtonMeshClip :: proc(mesh : ^NewtonMesh, clipper : ^NewtonMesh, clipperMatrix : ^dFloat, topMesh : ^^NewtonMesh, bottomMesh : ^^NewtonMesh) ---

    @(link_name="NewtonMeshConvexMeshIntersection")
    NewtonMeshConvexMeshIntersection :: proc(mesh : ^NewtonMesh, convexMesh : ^NewtonMesh) -> ^NewtonMesh ---

    @(link_name="NewtonMeshSimplify")
    NewtonMeshSimplify :: proc(mesh : ^NewtonMesh, maxVertexCount : i32, reportPrograssCallback : NewtonReportProgress, reportPrgressUserData : rawptr) -> ^NewtonMesh ---

    @(link_name="NewtonMeshApproximateConvexDecomposition")
    NewtonMeshApproximateConvexDecomposition :: proc(mesh : ^NewtonMesh, maxConcavity : dFloat, backFaceDistanceFactor : dFloat, maxCount : i32, maxVertexPerHull : i32, reportProgressCallback : NewtonReportProgress, reportProgressUserData : rawptr) -> ^NewtonMesh ---

    @(link_name="NewtonRemoveUnusedVertices")
    NewtonRemoveUnusedVertices :: proc(mesh : ^NewtonMesh, vertexRemapTable : ^i32) ---

    @(link_name="NewtonMeshBeginBuild")
    NewtonMeshBeginBuild :: proc(mesh : ^NewtonMesh) ---

    @(link_name="NewtonMeshBeginFace")
    NewtonMeshBeginFace :: proc(mesh : ^NewtonMesh) ---

    @(link_name="NewtonMeshAddPoint")
    NewtonMeshAddPoint :: proc(mesh : ^NewtonMesh, x : f64, y : f64, z : f64) ---

    @(link_name="NewtonMeshAddLayer")
    NewtonMeshAddLayer :: proc(mesh : ^NewtonMesh, layerIndex : i32) ---

    @(link_name="NewtonMeshAddMaterial")
    NewtonMeshAddMaterial :: proc(mesh : ^NewtonMesh, materialIndex : i32) ---

    @(link_name="NewtonMeshAddNormal")
    NewtonMeshAddNormal :: proc(mesh : ^NewtonMesh, x : dFloat, y : dFloat, z : dFloat) ---

    @(link_name="NewtonMeshAddBinormal")
    NewtonMeshAddBinormal :: proc(mesh : ^NewtonMesh, x : dFloat, y : dFloat, z : dFloat) ---

    @(link_name="NewtonMeshAddUV0")
    NewtonMeshAddUV0 :: proc(mesh : ^NewtonMesh, u : dFloat, v : dFloat) ---

    @(link_name="NewtonMeshAddUV1")
    NewtonMeshAddUV1 :: proc(mesh : ^NewtonMesh, u : dFloat, v : dFloat) ---

    @(link_name="NewtonMeshAddVertexColor")
    NewtonMeshAddVertexColor :: proc(mesh : ^NewtonMesh, r : f32, g : f32, b : f32, a : f32) ---

    @(link_name="NewtonMeshEndFace")
    NewtonMeshEndFace :: proc(mesh : ^NewtonMesh) ---

    @(link_name="NewtonMeshEndBuild")
    NewtonMeshEndBuild :: proc(mesh : ^NewtonMesh) ---

    @(link_name="NewtonMeshClearVertexFormat")
    NewtonMeshClearVertexFormat :: proc(format : ^NewtonMeshVertexFormat) ---

    @(link_name="NewtonMeshBuildFromVertexListIndexList")
    NewtonMeshBuildFromVertexListIndexList :: proc(mesh : ^NewtonMesh, format : ^NewtonMeshVertexFormat) ---

    @(link_name="NewtonMeshGetPointCount")
    NewtonMeshGetPointCount :: proc(mesh : ^NewtonMesh) -> i32 ---

    @(link_name="NewtonMeshGetIndexToVertexMap")
    NewtonMeshGetIndexToVertexMap :: proc(mesh : ^NewtonMesh) -> ^i32 ---

    @(link_name="NewtonMeshGetVertexDoubleChannel")
    NewtonMeshGetVertexDoubleChannel :: proc(mesh : ^NewtonMesh, vertexStrideInByte : i32, outBuffer : ^f64) ---

    @(link_name="NewtonMeshGetVertexChannel")
    NewtonMeshGetVertexChannel :: proc(mesh : ^NewtonMesh, vertexStrideInByte : i32, outBuffer : ^dFloat) ---

    @(link_name="NewtonMeshGetNormalChannel")
    NewtonMeshGetNormalChannel :: proc(mesh : ^NewtonMesh, vertexStrideInByte : i32, outBuffer : ^dFloat) ---

    @(link_name="NewtonMeshGetBinormalChannel")
    NewtonMeshGetBinormalChannel :: proc(mesh : ^NewtonMesh, vertexStrideInByte : i32, outBuffer : ^dFloat) ---

    @(link_name="NewtonMeshGetUV0Channel")
    NewtonMeshGetUV0Channel :: proc(mesh : ^NewtonMesh, vertexStrideInByte : i32, outBuffer : ^dFloat) ---

    @(link_name="NewtonMeshGetUV1Channel")
    NewtonMeshGetUV1Channel :: proc(mesh : ^NewtonMesh, vertexStrideInByte : i32, outBuffer : ^dFloat) ---

    @(link_name="NewtonMeshGetVertexColorChannel")
    NewtonMeshGetVertexColorChannel :: proc(mesh : ^NewtonMesh, vertexStrideInByte : i32, outBuffer : ^dFloat) ---

    @(link_name="NewtonMeshHasNormalChannel")
    NewtonMeshHasNormalChannel :: proc(mesh : ^NewtonMesh) -> i32 ---

    @(link_name="NewtonMeshHasBinormalChannel")
    NewtonMeshHasBinormalChannel :: proc(mesh : ^NewtonMesh) -> i32 ---

    @(link_name="NewtonMeshHasUV0Channel")
    NewtonMeshHasUV0Channel :: proc(mesh : ^NewtonMesh) -> i32 ---

    @(link_name="NewtonMeshHasUV1Channel")
    NewtonMeshHasUV1Channel :: proc(mesh : ^NewtonMesh) -> i32 ---

    @(link_name="NewtonMeshHasVertexColorChannel")
    NewtonMeshHasVertexColorChannel :: proc(mesh : ^NewtonMesh) -> i32 ---

    @(link_name="NewtonMeshBeginHandle")
    NewtonMeshBeginHandle :: proc(mesh : ^NewtonMesh) -> rawptr ---

    @(link_name="NewtonMeshEndHandle")
    NewtonMeshEndHandle :: proc(mesh : ^NewtonMesh, handle : rawptr) ---

    @(link_name="NewtonMeshFirstMaterial")
    NewtonMeshFirstMaterial :: proc(mesh : ^NewtonMesh, handle : rawptr) -> i32 ---

    @(link_name="NewtonMeshNextMaterial")
    NewtonMeshNextMaterial :: proc(mesh : ^NewtonMesh, handle : rawptr, materialId : i32) -> i32 ---

    @(link_name="NewtonMeshMaterialGetMaterial")
    NewtonMeshMaterialGetMaterial :: proc(mesh : ^NewtonMesh, handle : rawptr, materialId : i32) -> i32 ---

    @(link_name="NewtonMeshMaterialGetIndexCount")
    NewtonMeshMaterialGetIndexCount :: proc(mesh : ^NewtonMesh, handle : rawptr, materialId : i32) -> i32 ---

    @(link_name="NewtonMeshMaterialGetIndexStream")
    NewtonMeshMaterialGetIndexStream :: proc(mesh : ^NewtonMesh, handle : rawptr, materialId : i32, index : ^i32) ---

    @(link_name="NewtonMeshMaterialGetIndexStreamShort")
    NewtonMeshMaterialGetIndexStreamShort :: proc(mesh : ^NewtonMesh, handle : rawptr, materialId : i32, index : ^i16) ---

    @(link_name="NewtonMeshCreateFirstSingleSegment")
    NewtonMeshCreateFirstSingleSegment :: proc(mesh : ^NewtonMesh) -> ^NewtonMesh ---

    @(link_name="NewtonMeshCreateNextSingleSegment")
    NewtonMeshCreateNextSingleSegment :: proc(mesh : ^NewtonMesh, segment : ^NewtonMesh) -> ^NewtonMesh ---

    @(link_name="NewtonMeshCreateFirstLayer")
    NewtonMeshCreateFirstLayer :: proc(mesh : ^NewtonMesh) -> ^NewtonMesh ---

    @(link_name="NewtonMeshCreateNextLayer")
    NewtonMeshCreateNextLayer :: proc(mesh : ^NewtonMesh, segment : ^NewtonMesh) -> ^NewtonMesh ---

    @(link_name="NewtonMeshGetTotalFaceCount")
    NewtonMeshGetTotalFaceCount :: proc(mesh : ^NewtonMesh) -> i32 ---

    @(link_name="NewtonMeshGetTotalIndexCount")
    NewtonMeshGetTotalIndexCount :: proc(mesh : ^NewtonMesh) -> i32 ---

    @(link_name="NewtonMeshGetFaces")
    NewtonMeshGetFaces :: proc(mesh : ^NewtonMesh, faceIndexCount : ^i32, faceMaterial : ^i32, faceIndices : ^rawptr) ---

    @(link_name="NewtonMeshGetVertexCount")
    NewtonMeshGetVertexCount :: proc(mesh : ^NewtonMesh) -> i32 ---

    @(link_name="NewtonMeshGetVertexStrideInByte")
    NewtonMeshGetVertexStrideInByte :: proc(mesh : ^NewtonMesh) -> i32 ---

    @(link_name="NewtonMeshGetVertexArray")
    NewtonMeshGetVertexArray :: proc(mesh : ^NewtonMesh) -> ^f64 ---

    @(link_name="NewtonMeshGetVertexBaseCount")
    NewtonMeshGetVertexBaseCount :: proc(mesh : ^NewtonMesh) -> i32 ---

    @(link_name="NewtonMeshSetVertexBaseCount")
    NewtonMeshSetVertexBaseCount :: proc(mesh : ^NewtonMesh, baseCount : i32) ---

    @(link_name="NewtonMeshGetFirstVertex")
    NewtonMeshGetFirstVertex :: proc(mesh : ^NewtonMesh) -> rawptr ---

    @(link_name="NewtonMeshGetNextVertex")
    NewtonMeshGetNextVertex :: proc(mesh : ^NewtonMesh, vertex : rawptr) -> rawptr ---

    @(link_name="NewtonMeshGetVertexIndex")
    NewtonMeshGetVertexIndex :: proc(mesh : ^NewtonMesh, vertex : rawptr) -> i32 ---

    @(link_name="NewtonMeshGetFirstPoint")
    NewtonMeshGetFirstPoint :: proc(mesh : ^NewtonMesh) -> rawptr ---

    @(link_name="NewtonMeshGetNextPoint")
    NewtonMeshGetNextPoint :: proc(mesh : ^NewtonMesh, point : rawptr) -> rawptr ---

    @(link_name="NewtonMeshGetPointIndex")
    NewtonMeshGetPointIndex :: proc(mesh : ^NewtonMesh, point : rawptr) -> i32 ---

    @(link_name="NewtonMeshGetVertexIndexFromPoint")
    NewtonMeshGetVertexIndexFromPoint :: proc(mesh : ^NewtonMesh, point : rawptr) -> i32 ---

    @(link_name="NewtonMeshGetFirstEdge")
    NewtonMeshGetFirstEdge :: proc(mesh : ^NewtonMesh) -> rawptr ---

    @(link_name="NewtonMeshGetNextEdge")
    NewtonMeshGetNextEdge :: proc(mesh : ^NewtonMesh, edge : rawptr) -> rawptr ---

    @(link_name="NewtonMeshGetEdgeIndices")
    NewtonMeshGetEdgeIndices :: proc(mesh : ^NewtonMesh, edge : rawptr, v0 : ^i32, v1 : ^i32) ---

    @(link_name="NewtonMeshGetFirstFace")
    NewtonMeshGetFirstFace :: proc(mesh : ^NewtonMesh) -> rawptr ---

    @(link_name="NewtonMeshGetNextFace")
    NewtonMeshGetNextFace :: proc(mesh : ^NewtonMesh, face : rawptr) -> rawptr ---

    @(link_name="NewtonMeshIsFaceOpen")
    NewtonMeshIsFaceOpen :: proc(mesh : ^NewtonMesh, face : rawptr) -> i32 ---

    @(link_name="NewtonMeshGetFaceMaterial")
    NewtonMeshGetFaceMaterial :: proc(mesh : ^NewtonMesh, face : rawptr) -> i32 ---

    @(link_name="NewtonMeshGetFaceIndexCount")
    NewtonMeshGetFaceIndexCount :: proc(mesh : ^NewtonMesh, face : rawptr) -> i32 ---

    @(link_name="NewtonMeshGetFaceIndices")
    NewtonMeshGetFaceIndices :: proc(mesh : ^NewtonMesh, face : rawptr, indices : ^i32) ---

    @(link_name="NewtonMeshGetFacePointIndices")
    NewtonMeshGetFacePointIndices :: proc(mesh : ^NewtonMesh, face : rawptr, indices : ^i32) ---

    @(link_name="NewtonMeshCalculateFaceNormal")
    NewtonMeshCalculateFaceNormal :: proc(mesh : ^NewtonMesh, face : rawptr, normal : ^f64) ---

    @(link_name="NewtonMeshSetFaceMaterial")
    NewtonMeshSetFaceMaterial :: proc(mesh : ^NewtonMesh, face : rawptr, matId : i32) ---

}

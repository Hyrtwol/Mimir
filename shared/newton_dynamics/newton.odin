package newton

foreign import "newton.lib"

NEWTON_MAJOR_VERSION :: 3
NEWTON_MINOR_VERSION :: 14

BroadPhaseType :: enum i32 {
	Generic    = 0,
	Persistent = 1,
}

BodyType :: enum i32 {
	Dynamic          = 0,
	Kinematic        = 1,
	DynamicAsymetric = 2,
}

SerializeId :: enum i32 {
	Sphere            = 0,
	Capsule           = 1,
	Cylinder          = 2,
	Chamfercylinder   = 3,
	Box               = 4,
	Cone              = 5,
	Convexhull        = 6,
	Null              = 7,
	Compound          = 8,
	Tree              = 9,
	Heightfield       = 10,
	ClothPatch        = 11,
	DeformableSolid   = 12,
	Usermesh          = 13,
	Scene             = 14,
	FracturedCompound = 15,
}

NewtonAllocMemory :: #type proc(sizeInBytes: i32) -> rawptr
NewtonFreeMemory :: #type proc(ptr: rawptr, sizeInBytes: i32)
NewtonWorldDestructorCallback :: #type proc(world: ^NewtonWorld)
NewtonPostUpdateCallback :: #type proc(world: ^NewtonWorld, timestep: dFloat)
NewtonCreateContactCallback :: #type proc(newtonWorld: ^NewtonWorld, contact: ^NewtonJoint)
NewtonDestroyContactCallback :: #type proc(newtonWorld: ^NewtonWorld, contact: ^NewtonJoint)
NewtonWorldListenerDebugCallback :: #type proc(world: ^NewtonWorld, listener: rawptr, debugContext: rawptr)
NewtonWorldListenerBodyDestroyCallback :: #type proc(world: ^NewtonWorld, listenerUserData: rawptr, body: ^NewtonBody)
NewtonWorldUpdateListenerCallback :: #type proc(world: ^NewtonWorld, listenerUserData: rawptr, timestep: dFloat)
NewtonWorldDestroyListenerCallback :: #type proc(world: ^NewtonWorld, listenerUserData: rawptr)
NewtonGetTimeInMicrosencondsCallback :: #type proc() -> i64
NewtonSerializeCallback :: #type proc(serializeHandle: rawptr, buffer: rawptr, size: i32)
NewtonDeserializeCallback :: #type proc(serializeHandle: rawptr, buffer: rawptr, size: i32)
NewtonOnBodySerializationCallback :: #type proc(body: ^NewtonBody, userData: rawptr, function: NewtonSerializeCallback, serializeHandle: rawptr)
NewtonOnBodyDeserializationCallback :: #type proc(body: ^NewtonBody, userData: rawptr, function: NewtonDeserializeCallback, serializeHandle: rawptr)
NewtonOnJointSerializationCallback :: #type proc(joint: ^NewtonJoint, function: NewtonSerializeCallback, serializeHandle: rawptr)
NewtonOnJointDeserializationCallback :: #type proc(body0: ^NewtonBody, body1: ^NewtonBody, function: NewtonDeserializeCallback, serializeHandle: rawptr)
NewtonOnUserCollisionSerializationCallback :: #type proc(userData: rawptr, function: NewtonSerializeCallback, serializeHandle: rawptr)
NewtonUserMeshCollisionDestroyCallback :: #type proc(userData: rawptr)
NewtonUserMeshCollisionRayHitCallback :: #type proc(lineDescData: ^NewtonUserMeshCollisionRayHitDesc) -> dFloat
NewtonUserMeshCollisionGetCollisionInfo :: #type proc(userData: rawptr, infoRecord: ^NewtonCollisionInfoRecord)
NewtonUserMeshCollisionAABBTest :: #type proc(userData: rawptr, boxP0: ^dFloat, boxP1: ^dFloat) -> i32
NewtonUserMeshCollisionGetFacesInAABB :: #type proc(userData: rawptr, p0: ^dFloat, p1: ^dFloat, vertexArray: ^^dFloat, vertexCount: ^i32, vertexStrideInBytes: ^i32, indexList: ^i32, maxIndexCount: i32, userDataList: ^i32) -> i32
NewtonUserMeshCollisionCollideCallback :: #type proc(collideDescData: ^NewtonUserMeshCollisionCollideDesc, continueCollisionHandle: rawptr)
NewtonTreeCollisionFaceCallback :: #type proc(_context: rawptr, polygon: ^dFloat, strideInBytes: i32, indexArray: ^i32, indexCount: i32) -> i32
NewtonCollisionTreeRayCastCallback :: #type proc(body: ^NewtonBody, treeCollision: ^NewtonCollision, intersection: dFloat, normal: ^dFloat, faceId: i32, usedData: rawptr) -> dFloat
NewtonHeightFieldRayCastCallback :: #type proc(body: ^NewtonBody, heightFieldCollision: ^NewtonCollision, intersection: dFloat, row: i32, col: i32, normal: ^dFloat, faceId: i32, usedData: rawptr) -> dFloat
NewtonCollisionCopyConstructionCallback :: #type proc(newtonWorld: ^NewtonWorld, collision: ^NewtonCollision, sourceCollision: ^NewtonCollision)
NewtonCollisionDestructorCallback :: #type proc(newtonWorld: ^NewtonWorld, collision: ^NewtonCollision)
NewtonTreeCollisionCallback :: #type proc(bodyWithTreeCollision: ^NewtonBody, body: ^NewtonBody, faceID: i32, vertexCount: i32, vertex: ^dFloat, vertexStrideInBytes: i32)
NewtonBodyDestructor :: #type proc(body: ^NewtonBody)
NewtonApplyForceAndTorque :: #type proc(body: ^NewtonBody, timestep: dFloat, threadIndex: i32)
NewtonSetTransform :: #type proc(body: ^NewtonBody, matrix4x4: ^dFloat, threadIndex: i32)
NewtonIslandUpdate :: #type proc(newtonWorld: ^NewtonWorld, islandHandle: rawptr, bodyCount: i32) -> i32
NewtonFractureCompoundCollisionOnEmitCompoundFractured :: #type proc(fracturedBody: ^NewtonBody)
NewtonFractureCompoundCollisionOnEmitChunk :: #type proc(chunkBody: ^NewtonBody, fracturexChunkMesh: ^NewtonFracturedCompoundMeshPart, fracturedCompountCollision: ^NewtonCollision)
NewtonFractureCompoundCollisionReconstructMainMeshCallBack :: #type proc(body: ^NewtonBody, mainMesh: ^NewtonFracturedCompoundMeshPart, fracturedCompountCollision: ^NewtonCollision)
NewtonWorldRayPrefilterCallback :: #type proc(body: ^NewtonBody, collision: ^NewtonCollision, userData: rawptr) -> u32
NewtonWorldRayFilterCallback :: #type proc(body: ^NewtonBody, shapeHit: ^NewtonCollision, hitContact: ^dFloat, hitNormal: ^dFloat, collisionID: i64, userData: rawptr, intersectParam: dFloat) -> dFloat
NewtonOnAABBOverlap :: #type proc(contact: ^NewtonJoint, timestep: dFloat, threadIndex: i32) -> i32
NewtonContactsProcess :: #type proc(contact: ^NewtonJoint, timestep: dFloat, threadIndex: i32)
NewtonOnCompoundSubCollisionAABBOverlap :: #type proc(contact: ^NewtonJoint, timestep: dFloat, body0: ^NewtonBody, collisionNode0: rawptr, body1: ^NewtonBody, collisionNode1: rawptr, threadIndex: i32) -> i32
NewtonOnContactGeneration :: #type proc(material: ^NewtonMaterial, body0: ^NewtonBody, collision0: ^NewtonCollision, body1: ^NewtonBody, collision1: ^NewtonCollision, contactBuffer: ^NewtonUserContactPoint, maxCount: i32, threadIndex: i32) -> i32
NewtonBodyIterator :: #type proc(body: ^NewtonBody, userData: rawptr) -> i32
NewtonJointIterator :: #type proc(joint: ^NewtonJoint, userData: rawptr)
NewtonCollisionIterator :: #type proc(userData: rawptr, vertexCount: i32, faceArray: ^dFloat, faceId: i32)
NewtonBallCallback :: #type proc(ball: ^NewtonJoint, timestep: dFloat)
NewtonHingeCallback :: #type proc(hinge: ^NewtonJoint, desc: ^NewtonHingeSliderUpdateDesc) -> u32
NewtonSliderCallback :: #type proc(slider: ^NewtonJoint, desc: ^NewtonHingeSliderUpdateDesc) -> u32
NewtonUniversalCallback :: #type proc(universal: ^NewtonJoint, desc: ^NewtonHingeSliderUpdateDesc) -> u32
NewtonCorkscrewCallback :: #type proc(corkscrew: ^NewtonJoint, desc: ^NewtonHingeSliderUpdateDesc) -> u32
NewtonUserBilateralCallback :: #type proc(userJoint: ^NewtonJoint, timestep: dFloat, threadIndex: i32)
NewtonUserBilateralGetInfoCallback :: #type proc(userJoint: ^NewtonJoint, info: ^NewtonJointRecord)
NewtonConstraintDestructor :: #type proc(me: ^NewtonJoint)
NewtonJobTask :: #type proc(world: ^NewtonWorld, userData: rawptr, threadIndex: i32)
NewtonReportProgress :: #type proc(normalizedProgressPercent: dFloat, userData: rawptr) -> i32

NewtonMesh :: struct {}

NewtonBody :: struct {}

NewtonWorld :: struct {}

NewtonJoint :: struct {}

NewtonMaterial :: struct {}

NewtonCollision :: struct {}

NewtonDeformableMeshSegment :: struct {}

NewtonFracturedCompoundMeshPart :: struct {}

NewtonCollisionMaterial :: struct {
	m_userId:    i64,
	m_userData:  NewtonMaterialData,
	m_userParam: [6]NewtonMaterialData,
}

NewtonBoxParam :: struct {
	m_x: dFloat,
	m_y: dFloat,
	m_z: dFloat,
}

NewtonSphereParam :: struct {
	m_radio: dFloat,
}

NewtonCapsuleParam :: struct {
	m_radio0: dFloat,
	m_radio1: dFloat,
	m_height: dFloat,
}

NewtonCylinderParam :: struct {
	m_radio0: dFloat,
	m_radio1: dFloat,
	m_height: dFloat,
}

NewtonConeParam :: struct {
	m_radio:  dFloat,
	m_height: dFloat,
}

NewtonChamferCylinderParam :: struct {
	m_radio:  dFloat,
	m_height: dFloat,
}

NewtonConvexHullParam :: struct {
	m_vertexCount:         i32,
	m_vertexStrideInBytes: i32,
	m_faceCount:           i32,
	m_vertex:              ^dFloat,
}

NewtonCompoundCollisionParam :: struct {
	m_chidrenCount: i32,
}

NewtonCollisionTreeParam :: struct {
	m_vertexCount: i32,
	m_indexCount:  i32,
}

NewtonDeformableMeshParam :: struct {
	m_vertexCount:        i32,
	m_triangleCount:      i32,
	m_vrtexStrideInBytes: i32,
	m_indexList:          ^u16,
	m_vertexList:         ^dFloat,
}

NewtonHeightFieldCollisionParam :: struct {
	m_width:             i32,
	m_height:            i32,
	m_gridsDiagonals:    i32,
	m_elevationDataType: i32,
	m_verticalScale:     dFloat,
	m_horizonalScale_x:  dFloat,
	m_horizonalScale_z:  dFloat,
	m_vertialElevation:  rawptr,
	m_atributes:         cstring,
}

NewtonSceneCollisionParam :: struct {
	m_childrenProxyCount: i32,
}

NewtonCollisionInfoRecord :: struct {
	m_offsetMatrix:      float4x4,
	m_collisionMaterial: NewtonCollisionMaterial,
	m_collisionType:     SerializeId, //i32,
	u:                   struct #raw_union {
		m_box:               NewtonBoxParam,
		m_cone:              NewtonConeParam,
		m_sphere:            NewtonSphereParam,
		m_capsule:           NewtonCapsuleParam,
		m_cylinder:          NewtonCylinderParam,
		m_chamferCylinder:   NewtonChamferCylinderParam,
		m_convexHull:        NewtonConvexHullParam,
		m_deformableMesh:    NewtonDeformableMeshParam,
		m_compoundCollision: NewtonCompoundCollisionParam,
		m_collisionTree:     NewtonCollisionTreeParam,
		m_heightField:       NewtonHeightFieldCollisionParam,
		m_sceneCollision:    NewtonSceneCollisionParam,
		m_paramArray:        [64]dFloat,
	},
}

NewtonJointRecord :: struct {
	m_attachmenMatrix_0: float4x4,
	m_attachmenMatrix_1: float4x4,
	m_minLinearDof:      float3,
	m_maxLinearDof:      float3,
	m_minAngularDof:     float3,
	m_maxAngularDof:     float3,
	m_attachBody_0:      ^NewtonBody,
	m_attachBody_1:      ^NewtonBody,
	m_extraParameters:   [64]dFloat,
	m_bodiesCollisionOn: i32,
	m_descriptionType:   [128]u8,
}

NewtonUserMeshCollisionCollideDesc :: struct {
	m_boxP0:               float4,
	m_boxP1:               float4,
	m_boxDistanceTravel:   float4,
	m_threadNumber:        i32,
	m_faceCount:           i32,
	m_vertexStrideInBytes: i32,
	m_skinThickness:       dFloat,
	m_userData:            rawptr,
	m_objBody:             ^NewtonBody,
	m_polySoupBody:        ^NewtonBody,
	m_objCollision:        ^NewtonCollision,
	m_polySoupCollision:   ^NewtonCollision,
	m_vertex:              ^dFloat,
	m_faceIndexCount:      ^i32,
	m_faceVertexIndex:     ^i32,
}

NewtonWorldConvexCastReturnInfo :: struct {
	m_point:       float4,
	m_normal:      float4,
	m_contactID:   i64,
	m_hitBody:     ^NewtonBody,
	m_penetration: dFloat,
}

NewtonUserMeshCollisionRayHitDesc :: struct {
	m_p0:        float4,
	m_p1:        float4,
	m_normalOut: float4,
	m_userIdOut: i64,
	m_userData:  rawptr,
}

NewtonHingeSliderUpdateDesc :: struct {
	m_accel:       dFloat,
	m_minFriction: dFloat,
	m_maxFriction: dFloat,
	m_timestep:    dFloat,
}

NewtonUserContactPoint :: struct {
	m_point:       float4,
	m_normal:      float4,
	m_shapeId0:    i64,
	m_shapeId1:    i64,
	m_penetration: dFloat,
	m_unused:      int3,
}

NewtonImmediateModeConstraint :: struct {
	m_jacobian01:     [8]JacobianPair, // [8][6]dFloat
	m_jacobian10:     [8]JacobianPair,
	m_minFriction:    [8]dFloat,
	m_maxFriction:    [8]dFloat,
	m_jointAccel:     [8]dFloat,
	m_jointStiffness: [8]dFloat,
}

JacobianPair :: struct {
	m_linear:  float3,
	m_angular: float3,
}

NewtonMeshDoubleData :: struct {
	m_data:          ^f64,
	m_indexList:     ^i32,
	m_strideInBytes: i32,
}

NewtonMeshFloatData :: struct {
	m_data:          ^dFloat,
	m_indexList:     ^i32,
	m_strideInBytes: i32,
}

NewtonMeshVertexFormat :: struct {
	m_faceCount:      i32,
	m_faceIndexCount: ^i32,
	m_faceMaterial:   ^i32,
	m_vertex:         NewtonMeshDoubleData,
	m_normal:         NewtonMeshFloatData,
	m_binormal:       NewtonMeshFloatData,
	m_uv0:            NewtonMeshFloatData,
	m_uv1:            NewtonMeshFloatData,
	m_vertexColor:    NewtonMeshFloatData,
}

NewtonMaterialData :: struct #raw_union {
	m_ptr:   rawptr,
	m_int:   i64,
	m_float: dFloat,
}

@(default_calling_convention = "c", link_prefix = "Newton")
foreign newton {
	@(link_name = "NewtonWorldGetVersion")
	GetVersion :: proc() -> i32 ---
	@(link_name = "NewtonWorldFloatSize")
	GetFloatSize :: proc() -> i32 ---
	GetMemoryUsed :: proc() -> i32 ---
	SetMemorySystem :: proc(malloc: NewtonAllocMemory, free: NewtonFreeMemory) ---
	Create :: proc() -> ^NewtonWorld ---
	Destroy :: proc(newtonWorld: ^NewtonWorld) ---
	DestroyAllBodies :: proc(newtonWorld: ^NewtonWorld) ---
	GetPostUpdateCallback :: proc(newtonWorld: ^NewtonWorld) -> NewtonPostUpdateCallback ---
	SetPostUpdateCallback :: proc(newtonWorld: ^NewtonWorld, callback: NewtonPostUpdateCallback) ---
	Alloc :: proc(sizeInBytes: i32) -> rawptr ---
	Free :: proc(ptr: rawptr) ---
	LoadPlugins :: proc(newtonWorld: ^NewtonWorld, plugInPath: cstring) ---
	UnloadPlugins :: proc(newtonWorld: ^NewtonWorld) ---
	CurrentPlugin :: proc(newtonWorld: ^NewtonWorld) -> rawptr ---
	GetFirstPlugin :: proc(newtonWorld: ^NewtonWorld) -> rawptr ---
	GetPreferedPlugin :: proc(newtonWorld: ^NewtonWorld) -> rawptr ---
	GetNextPlugin :: proc(newtonWorld: ^NewtonWorld, plugin: rawptr) -> rawptr ---
	GetPluginString :: proc(newtonWorld: ^NewtonWorld, plugin: rawptr) -> cstring ---
	SelectPlugin :: proc(newtonWorld: ^NewtonWorld, plugin: rawptr) ---
	GetContactMergeTolerance :: proc(newtonWorld: ^NewtonWorld) -> dFloat ---
	SetContactMergeTolerance :: proc(newtonWorld: ^NewtonWorld, tolerance: dFloat) ---
	InvalidateCache :: proc(newtonWorld: ^NewtonWorld) ---
	SetSolverIterations :: proc(newtonWorld: ^NewtonWorld, model: i32) ---
	GetSolverIterations :: proc(newtonWorld: ^NewtonWorld) -> i32 ---
	SetParallelSolverOnLargeIsland :: proc(newtonWorld: ^NewtonWorld, mode: i32) ---
	GetParallelSolverOnLargeIsland :: proc(newtonWorld: ^NewtonWorld) -> i32 ---
	GetBroadphaseAlgorithm :: proc(newtonWorld: ^NewtonWorld) -> BroadPhaseType ---
	SelectBroadphaseAlgorithm :: proc(newtonWorld: ^NewtonWorld, algorithmType: i32) ---
	ResetBroadphase :: proc(newtonWorld: ^NewtonWorld) ---
	Update :: proc(newtonWorld: ^NewtonWorld, timestep: dFloat) ---
	UpdateAsync :: proc(newtonWorld: ^NewtonWorld, timestep: dFloat) ---
	WaitForUpdateToFinish :: proc(newtonWorld: ^NewtonWorld) ---
	GetNumberOfSubsteps :: proc(newtonWorld: ^NewtonWorld) -> i32 ---
	SetNumberOfSubsteps :: proc(newtonWorld: ^NewtonWorld, subSteps: i32) ---
	GetLastUpdateTime :: proc(newtonWorld: ^NewtonWorld) -> dFloat ---
	SerializeToFile :: proc(newtonWorld: ^NewtonWorld, filename: cstring, bodyCallback: NewtonOnBodySerializationCallback, bodyUserData: rawptr) ---
	DeserializeFromFile :: proc(newtonWorld: ^NewtonWorld, filename: cstring, bodyCallback: NewtonOnBodyDeserializationCallback, bodyUserData: rawptr) ---
	SerializeScene :: proc(newtonWorld: ^NewtonWorld, bodyCallback: NewtonOnBodySerializationCallback, bodyUserData: rawptr, serializeCallback: NewtonSerializeCallback, serializeHandle: rawptr) ---
	DeserializeScene :: proc(newtonWorld: ^NewtonWorld, bodyCallback: NewtonOnBodyDeserializationCallback, bodyUserData: rawptr, serializeCallback: NewtonDeserializeCallback, serializeHandle: rawptr) ---
	FindSerializedBody :: proc(newtonWorld: ^NewtonWorld, bodySerializedID: i32) -> ^NewtonBody ---
	SetJointSerializationCallbacks :: proc(newtonWorld: ^NewtonWorld, serializeJoint: NewtonOnJointSerializationCallback, deserializeJoint: NewtonOnJointDeserializationCallback) ---
	GetJointSerializationCallbacks :: proc(newtonWorld: ^NewtonWorld, serializeJoint: ^NewtonOnJointSerializationCallback, deserializeJoint: ^NewtonOnJointDeserializationCallback) ---
	WorldCriticalSectionLock :: proc(newtonWorld: ^NewtonWorld, threadIndex: i32) ---
	WorldCriticalSectionUnlock :: proc(newtonWorld: ^NewtonWorld) ---
	SetThreadsCount :: proc(newtonWorld: ^NewtonWorld, threads: i32) ---
	GetThreadsCount :: proc(newtonWorld: ^NewtonWorld) -> i32 ---
	GetMaxThreadsCount :: proc(newtonWorld: ^NewtonWorld) -> i32 ---
	DispachThreadJob :: proc(newtonWorld: ^NewtonWorld, task: NewtonJobTask, usedData: rawptr, functionName: cstring) ---
	SyncThreadJobs :: proc(newtonWorld: ^NewtonWorld) ---
	AtomicAdd :: proc(ptr: ^i32, value: i32) -> i32 ---
	AtomicSwap :: proc(ptr: ^i32, value: i32) -> i32 ---
	Yield :: proc() ---
	SetIslandUpdateEvent :: proc(newtonWorld: ^NewtonWorld, islandUpdate: NewtonIslandUpdate) ---
	WorldForEachJointDo :: proc(newtonWorld: ^NewtonWorld, callback: NewtonJointIterator, userData: rawptr) ---
	WorldForEachBodyInAABBDo :: proc(newtonWorld: ^NewtonWorld, p0: ^dFloat, p1: ^dFloat, callback: NewtonBodyIterator, userData: rawptr) ---
	WorldSetUserData :: proc(newtonWorld: ^NewtonWorld, userData: rawptr) ---
	WorldGetUserData :: proc(newtonWorld: ^NewtonWorld) -> rawptr ---
	WorldAddListener :: proc(newtonWorld: ^NewtonWorld, nameId: cstring, listenerUserData: rawptr) -> rawptr ---
	WorldGetListener :: proc(newtonWorld: ^NewtonWorld, nameId: cstring) -> rawptr ---
	WorldListenerSetDebugCallback :: proc(newtonWorld: ^NewtonWorld, listener: rawptr, callback: NewtonWorldListenerDebugCallback) ---
	WorldListenerSetPostStepCallback :: proc(newtonWorld: ^NewtonWorld, listener: rawptr, callback: NewtonWorldUpdateListenerCallback) ---
	WorldListenerSetPreUpdateCallback :: proc(newtonWorld: ^NewtonWorld, listener: rawptr, callback: NewtonWorldUpdateListenerCallback) ---
	WorldListenerSetPostUpdateCallback :: proc(newtonWorld: ^NewtonWorld, listener: rawptr, callback: NewtonWorldUpdateListenerCallback) ---
	WorldListenerSetDestructorCallback :: proc(newtonWorld: ^NewtonWorld, listener: rawptr, callback: NewtonWorldDestroyListenerCallback) ---
	WorldListenerSetBodyDestroyCallback :: proc(newtonWorld: ^NewtonWorld, listener: rawptr, callback: NewtonWorldListenerBodyDestroyCallback) ---
	WorldListenerDebug :: proc(newtonWorld: ^NewtonWorld, _context: rawptr) ---
	WorldGetListenerUserData :: proc(newtonWorld: ^NewtonWorld, listener: rawptr) -> rawptr ---
	WorldListenerGetBodyDestroyCallback :: proc(newtonWorld: ^NewtonWorld, listener: rawptr) -> NewtonWorldListenerBodyDestroyCallback ---
	WorldSetDestructorCallback :: proc(newtonWorld: ^NewtonWorld, destructor: NewtonWorldDestructorCallback) ---
	WorldGetDestructorCallback :: proc(newtonWorld: ^NewtonWorld) -> NewtonWorldDestructorCallback ---
	WorldSetCollisionConstructorDestructorCallback :: proc(newtonWorld: ^NewtonWorld, constructor: NewtonCollisionCopyConstructionCallback, destructor: NewtonCollisionDestructorCallback) ---
	WorldSetCreateDestroyContactCallback :: proc(newtonWorld: ^NewtonWorld, createContact: NewtonCreateContactCallback, destroyContact: NewtonDestroyContactCallback) ---
	WorldRayCast :: proc(newtonWorld: ^NewtonWorld, p0: ^dFloat, p1: ^dFloat, filter: NewtonWorldRayFilterCallback, userData: rawptr, prefilter: NewtonWorldRayPrefilterCallback, threadIndex: i32) ---
	WorldConvexCast :: proc(newtonWorld: ^NewtonWorld, matrix4x4: ^dFloat, target: ^dFloat, shape: ^NewtonCollision, param: ^dFloat, userData: rawptr, prefilter: NewtonWorldRayPrefilterCallback, info: ^NewtonWorldConvexCastReturnInfo, maxContactsCount: i32, threadIndex: i32) -> i32 ---
	WorldCollide :: proc(newtonWorld: ^NewtonWorld, matrix4x4: ^dFloat, shape: ^NewtonCollision, userData: rawptr, prefilter: NewtonWorldRayPrefilterCallback, info: ^NewtonWorldConvexCastReturnInfo, maxContactsCount: i32, threadIndex: i32) -> i32 ---
	WorldGetBodyCount :: proc(newtonWorld: ^NewtonWorld) -> i32 ---
	WorldGetConstraintCount :: proc(newtonWorld: ^NewtonWorld) -> i32 ---
	WorldFindJoint :: proc(body0: ^NewtonBody, body1: ^NewtonBody) -> ^NewtonJoint ---
	IslandGetBody :: proc(island: rawptr, bodyIndex: i32) -> ^NewtonBody ---
	IslandGetBodyAABB :: proc(island: rawptr, bodyIndex: i32, p0: ^dFloat, p1: ^dFloat) ---
	MaterialCreateGroupID :: proc(newtonWorld: ^NewtonWorld) -> i32 ---
	MaterialGetDefaultGroupID :: proc(newtonWorld: ^NewtonWorld) -> i32 ---
	MaterialDestroyAllGroupID :: proc(newtonWorld: ^NewtonWorld) ---
	MaterialGetUserData :: proc(newtonWorld: ^NewtonWorld, id0: i32, id1: i32) -> rawptr ---
	MaterialSetSurfaceThickness :: proc(newtonWorld: ^NewtonWorld, id0: i32, id1: i32, thickness: dFloat) ---
	MaterialSetCallbackUserData :: proc(newtonWorld: ^NewtonWorld, id0: i32, id1: i32, userData: rawptr) ---
	MaterialSetContactGenerationCallback :: proc(newtonWorld: ^NewtonWorld, id0: i32, id1: i32, contactGeneration: NewtonOnContactGeneration) ---
	MaterialSetCompoundCollisionCallback :: proc(newtonWorld: ^NewtonWorld, id0: i32, id1: i32, compoundAabbOverlap: NewtonOnCompoundSubCollisionAABBOverlap) ---
	MaterialSetCollisionCallback :: proc(newtonWorld: ^NewtonWorld, id0: i32, id1: i32, aabbOverlap: NewtonOnAABBOverlap, process: NewtonContactsProcess) ---
	MaterialSetDefaultSoftness :: proc(newtonWorld: ^NewtonWorld, id0: i32, id1: i32, value: dFloat) ---
	MaterialSetDefaultElasticity :: proc(newtonWorld: ^NewtonWorld, id0: i32, id1: i32, elasticCoef: dFloat) ---
	MaterialSetDefaultCollidable :: proc(newtonWorld: ^NewtonWorld, id0: i32, id1: i32, state: i32) ---
	MaterialSetDefaultFriction :: proc(newtonWorld: ^NewtonWorld, id0: i32, id1: i32, staticFriction: dFloat, kineticFriction: dFloat) ---
	MaterialJointResetIntraJointCollision :: proc(newtonWorld: ^NewtonWorld, id0: i32, id1: i32) ---
	MaterialJointResetSelftJointCollision :: proc(newtonWorld: ^NewtonWorld, id0: i32, id1: i32) ---
	WorldGetFirstMaterial :: proc(newtonWorld: ^NewtonWorld) -> ^NewtonMaterial ---
	WorldGetNextMaterial :: proc(newtonWorld: ^NewtonWorld, material: ^NewtonMaterial) -> ^NewtonMaterial ---
	WorldGetFirstBody :: proc(newtonWorld: ^NewtonWorld) -> ^NewtonBody ---
	WorldGetNextBody :: proc(newtonWorld: ^NewtonWorld, curBody: ^NewtonBody) -> ^NewtonBody ---
	MaterialGetMaterialPairUserData :: proc(material: ^NewtonMaterial) -> rawptr ---
	MaterialGetContactFaceAttribute :: proc(material: ^NewtonMaterial) -> u32 ---
	MaterialGetBodyCollidingShape :: proc(material: ^NewtonMaterial, body: ^NewtonBody) -> ^NewtonCollision ---
	MaterialGetContactNormalSpeed :: proc(material: ^NewtonMaterial) -> dFloat ---
	MaterialGetContactForce :: proc(material: ^NewtonMaterial, body: ^NewtonBody, force: ^dFloat) ---
	MaterialGetContactPositionAndNormal :: proc(material: ^NewtonMaterial, body: ^NewtonBody, posit: ^dFloat, normal: ^dFloat) ---
	MaterialGetContactTangentDirections :: proc(material: ^NewtonMaterial, body: ^NewtonBody, dir0: ^dFloat, dir1: ^dFloat) ---
	MaterialGetContactTangentSpeed :: proc(material: ^NewtonMaterial, index: i32) -> dFloat ---
	MaterialGetContactMaxNormalImpact :: proc(material: ^NewtonMaterial) -> dFloat ---
	MaterialGetContactMaxTangentImpact :: proc(material: ^NewtonMaterial, index: i32) -> dFloat ---
	MaterialGetContactPenetration :: proc(material: ^NewtonMaterial) -> dFloat ---
	MaterialSetAsSoftContact :: proc(material: ^NewtonMaterial, relaxation: dFloat) ---
	MaterialSetContactSoftness :: proc(material: ^NewtonMaterial, softness: dFloat) ---
	MaterialSetContactThickness :: proc(material: ^NewtonMaterial, thickness: dFloat) ---
	MaterialSetContactElasticity :: proc(material: ^NewtonMaterial, restitution: dFloat) ---
	MaterialSetContactFrictionState :: proc(material: ^NewtonMaterial, state: i32, index: i32) ---
	MaterialSetContactFrictionCoef :: proc(material: ^NewtonMaterial, staticFrictionCoef: dFloat, kineticFrictionCoef: dFloat, index: i32) ---
	MaterialSetContactNormalAcceleration :: proc(material: ^NewtonMaterial, accel: dFloat) ---
	MaterialSetContactNormalDirection :: proc(material: ^NewtonMaterial, directionVector: ^dFloat) ---
	MaterialSetContactPosition :: proc(material: ^NewtonMaterial, position: ^dFloat) ---
	MaterialSetContactTangentFriction :: proc(material: ^NewtonMaterial, friction: dFloat, index: i32) ---
	MaterialSetContactTangentAcceleration :: proc(material: ^NewtonMaterial, accel: dFloat, index: i32) ---
	MaterialContactRotateTangentDirections :: proc(material: ^NewtonMaterial, directionVector: ^dFloat) ---
	MaterialGetContactPruningTolerance :: proc(contactJoint: ^NewtonJoint) -> dFloat ---
	MaterialSetContactPruningTolerance :: proc(contactJoint: ^NewtonJoint, tolerance: dFloat) ---
	CreateNull :: proc(newtonWorld: ^NewtonWorld) -> ^NewtonCollision ---
	CreateSphere :: proc(newtonWorld: ^NewtonWorld, radius: dFloat, shapeID: i32, offsetMatrix: ^dFloat) -> ^NewtonCollision ---
	CreateBox :: proc(newtonWorld: ^NewtonWorld, dx: dFloat, dy: dFloat, dz: dFloat, shapeID: i32, offsetMatrix: ^dFloat) -> ^NewtonCollision ---
	CreateCone :: proc(newtonWorld: ^NewtonWorld, radius: dFloat, height: dFloat, shapeID: i32, offsetMatrix: ^dFloat) -> ^NewtonCollision ---
	CreateCapsule :: proc(newtonWorld: ^NewtonWorld, radius0: dFloat, radius1: dFloat, height: dFloat, shapeID: i32, offsetMatrix: ^dFloat) -> ^NewtonCollision ---
	CreateCylinder :: proc(newtonWorld: ^NewtonWorld, radio0: dFloat, radio1: dFloat, height: dFloat, shapeID: i32, offsetMatrix: ^dFloat) -> ^NewtonCollision ---
	CreateChamferCylinder :: proc(newtonWorld: ^NewtonWorld, radius: dFloat, height: dFloat, shapeID: i32, offsetMatrix: ^dFloat) -> ^NewtonCollision ---
	CreateConvexHull :: proc(newtonWorld: ^NewtonWorld, count: i32, vertexCloud: ^dFloat, strideInBytes: i32, tolerance: dFloat, shapeID: i32, offsetMatrix: ^dFloat) -> ^NewtonCollision ---
	CreateConvexHullFromMesh :: proc(newtonWorld: ^NewtonWorld, mesh: ^NewtonMesh, tolerance: dFloat, shapeID: i32) -> ^NewtonCollision ---
	CollisionGetMode :: proc(convexCollision: ^NewtonCollision) -> i32 ---
	CollisionSetMode :: proc(convexCollision: ^NewtonCollision, mode: i32) ---
	ConvexHullGetFaceIndices :: proc(convexHullCollision: ^NewtonCollision, face: i32, faceIndices: ^i32) -> i32 ---
	ConvexHullGetVertexData :: proc(convexHullCollision: ^NewtonCollision, vertexData: ^^dFloat, strideInBytes: ^i32) -> i32 ---
	ConvexCollisionCalculateVolume :: proc(convexCollision: ^NewtonCollision) -> dFloat ---
	ConvexCollisionCalculateInertialMatrix :: proc(convexCollision: ^NewtonCollision, inertia: ^dFloat, origin: ^dFloat) ---
	ConvexCollisionCalculateBuoyancyVolume :: proc(convexCollision: ^NewtonCollision, matrix4x4: ^dFloat, fluidPlane: ^dFloat, centerOfBuoyancy: ^dFloat) -> dFloat ---
	CollisionDataPointer :: proc(convexCollision: ^NewtonCollision) -> rawptr ---
	CreateCompoundCollision :: proc(newtonWorld: ^NewtonWorld, shapeID: i32) -> ^NewtonCollision ---
	CreateCompoundCollisionFromMesh :: proc(newtonWorld: ^NewtonWorld, mesh: ^NewtonMesh, hullTolerance: dFloat, shapeID: i32, subShapeID: i32) -> ^NewtonCollision ---
	CompoundCollisionBeginAddRemove :: proc(compoundCollision: ^NewtonCollision) ---
	CompoundCollisionAddSubCollision :: proc(compoundCollision: ^NewtonCollision, convexCollision: ^NewtonCollision) -> rawptr ---
	CompoundCollisionRemoveSubCollision :: proc(compoundCollision: ^NewtonCollision, collisionNode: rawptr) ---
	CompoundCollisionRemoveSubCollisionByIndex :: proc(compoundCollision: ^NewtonCollision, nodeIndex: i32) ---
	CompoundCollisionSetSubCollisionMatrix :: proc(compoundCollision: ^NewtonCollision, collisionNode: rawptr, matrix4x4: ^dFloat) ---
	CompoundCollisionEndAddRemove :: proc(compoundCollision: ^NewtonCollision) ---
	CompoundCollisionGetFirstNode :: proc(compoundCollision: ^NewtonCollision) -> rawptr ---
	CompoundCollisionGetNextNode :: proc(compoundCollision: ^NewtonCollision, collisionNode: rawptr) -> rawptr ---
	CompoundCollisionGetNodeByIndex :: proc(compoundCollision: ^NewtonCollision, index: i32) -> rawptr ---
	CompoundCollisionGetNodeIndex :: proc(compoundCollision: ^NewtonCollision, collisionNode: rawptr) -> i32 ---
	CompoundCollisionGetCollisionFromNode :: proc(compoundCollision: ^NewtonCollision, collisionNode: rawptr) -> ^NewtonCollision ---
	CreateFracturedCompoundCollision :: proc(newtonWorld: ^NewtonWorld, solidMesh: ^NewtonMesh, shapeID: i32, fracturePhysicsMaterialID: i32, pointcloudCount: i32, vertexCloud: ^dFloat, strideInBytes: i32, materialID: i32, textureMatrix: ^dFloat, regenerateMainMeshCallback: NewtonFractureCompoundCollisionReconstructMainMeshCallBack, emitFracturedCompound: NewtonFractureCompoundCollisionOnEmitCompoundFractured, emitFracfuredChunk: NewtonFractureCompoundCollisionOnEmitChunk) -> ^NewtonCollision ---
	FracturedCompoundPlaneClip :: proc(fracturedCompound: ^NewtonCollision, plane: ^dFloat) -> ^NewtonCollision ---
	FracturedCompoundSetCallbacks :: proc(fracturedCompound: ^NewtonCollision, regenerateMainMeshCallback: NewtonFractureCompoundCollisionReconstructMainMeshCallBack, emitFracturedCompound: NewtonFractureCompoundCollisionOnEmitCompoundFractured, emitFracfuredChunk: NewtonFractureCompoundCollisionOnEmitChunk) ---
	FracturedCompoundIsNodeFreeToDetach :: proc(fracturedCompound: ^NewtonCollision, collisionNode: rawptr) -> i32 ---
	FracturedCompoundNeighborNodeList :: proc(fracturedCompound: ^NewtonCollision, collisionNode: rawptr, list: ^rawptr, maxCount: i32) -> i32 ---
	FracturedCompoundGetMainMesh :: proc(fracturedCompound: ^NewtonCollision) -> ^NewtonFracturedCompoundMeshPart ---
	FracturedCompoundGetFirstSubMesh :: proc(fracturedCompound: ^NewtonCollision) -> ^NewtonFracturedCompoundMeshPart ---
	FracturedCompoundGetNextSubMesh :: proc(fracturedCompound: ^NewtonCollision, subMesh: ^NewtonFracturedCompoundMeshPart) -> ^NewtonFracturedCompoundMeshPart ---
	FracturedCompoundCollisionGetVertexCount :: proc(fracturedCompound: ^NewtonCollision, meshOwner: ^NewtonFracturedCompoundMeshPart) -> i32 ---
	FracturedCompoundCollisionGetVertexPositions :: proc(fracturedCompound: ^NewtonCollision, meshOwner: ^NewtonFracturedCompoundMeshPart) -> ^dFloat ---
	FracturedCompoundCollisionGetVertexNormals :: proc(fracturedCompound: ^NewtonCollision, meshOwner: ^NewtonFracturedCompoundMeshPart) -> ^dFloat ---
	FracturedCompoundCollisionGetVertexUVs :: proc(fracturedCompound: ^NewtonCollision, meshOwner: ^NewtonFracturedCompoundMeshPart) -> ^dFloat ---
	FracturedCompoundMeshPartGetIndexStream :: proc(fracturedCompound: ^NewtonCollision, meshOwner: ^NewtonFracturedCompoundMeshPart, segment: rawptr, index: ^i32) -> i32 ---
	FracturedCompoundMeshPartGetFirstSegment :: proc(fractureCompoundMeshPart: ^NewtonFracturedCompoundMeshPart) -> rawptr ---
	FracturedCompoundMeshPartGetNextSegment :: proc(fractureCompoundMeshSegment: rawptr) -> rawptr ---
	FracturedCompoundMeshPartGetMaterial :: proc(fractureCompoundMeshSegment: rawptr) -> i32 ---
	FracturedCompoundMeshPartGetIndexCount :: proc(fractureCompoundMeshSegment: rawptr) -> i32 ---
	CreateSceneCollision :: proc(newtonWorld: ^NewtonWorld, shapeID: i32) -> ^NewtonCollision ---
	SceneCollisionBeginAddRemove :: proc(sceneCollision: ^NewtonCollision) ---
	SceneCollisionAddSubCollision :: proc(sceneCollision: ^NewtonCollision, collision: ^NewtonCollision) -> rawptr ---
	SceneCollisionRemoveSubCollision :: proc(compoundCollision: ^NewtonCollision, collisionNode: rawptr) ---
	SceneCollisionRemoveSubCollisionByIndex :: proc(sceneCollision: ^NewtonCollision, nodeIndex: i32) ---
	SceneCollisionSetSubCollisionMatrix :: proc(sceneCollision: ^NewtonCollision, collisionNode: rawptr, matrix4x4: ^dFloat) ---
	SceneCollisionEndAddRemove :: proc(sceneCollision: ^NewtonCollision) ---
	SceneCollisionGetFirstNode :: proc(sceneCollision: ^NewtonCollision) -> rawptr ---
	SceneCollisionGetNextNode :: proc(sceneCollision: ^NewtonCollision, collisionNode: rawptr) -> rawptr ---
	SceneCollisionGetNodeByIndex :: proc(sceneCollision: ^NewtonCollision, index: i32) -> rawptr ---
	SceneCollisionGetNodeIndex :: proc(sceneCollision: ^NewtonCollision, collisionNode: rawptr) -> i32 ---
	SceneCollisionGetCollisionFromNode :: proc(sceneCollision: ^NewtonCollision, collisionNode: rawptr) -> ^NewtonCollision ---
	CreateUserMeshCollision :: proc(newtonWorld: ^NewtonWorld, minBox: ^dFloat, maxBox: ^dFloat, userData: rawptr, collideCallback: NewtonUserMeshCollisionCollideCallback, rayHitCallback: NewtonUserMeshCollisionRayHitCallback, destroyCallback: NewtonUserMeshCollisionDestroyCallback, getInfoCallback: NewtonUserMeshCollisionGetCollisionInfo, getLocalAABBCallback: NewtonUserMeshCollisionAABBTest, facesInAABBCallback: NewtonUserMeshCollisionGetFacesInAABB, serializeCallback: NewtonOnUserCollisionSerializationCallback, shapeID: i32) -> ^NewtonCollision ---
	UserMeshCollisionContinuousOverlapTest :: proc(collideDescData: ^NewtonUserMeshCollisionCollideDesc, continueCollisionHandle: rawptr, minAabb: ^dFloat, maxAabb: ^dFloat) -> i32 ---
	CreateCollisionFromSerialization :: proc(newtonWorld: ^NewtonWorld, deserializeFunction: NewtonDeserializeCallback, serializeHandle: rawptr) -> ^NewtonCollision ---
	CollisionSerialize :: proc(newtonWorld: ^NewtonWorld, collision: ^NewtonCollision, serializeFunction: NewtonSerializeCallback, serializeHandle: rawptr) ---
	CollisionGetInfo :: proc(collision: ^NewtonCollision, collisionInfo: ^NewtonCollisionInfoRecord) ---
	CreateHeightFieldCollision :: proc(newtonWorld: ^NewtonWorld, width: i32, height: i32, gridsDiagonals: i32, elevationdatType: i32, elevationMap: rawptr, attributeMap: cstring, verticalScale: dFloat, horizontalScale_x: dFloat, horizontalScale_z: dFloat, shapeID: i32) -> ^NewtonCollision ---
	HeightFieldSetUserRayCastCallback :: proc(heightfieldCollision: ^NewtonCollision, rayHitCallback: NewtonHeightFieldRayCastCallback) ---
	CreateTreeCollision :: proc(newtonWorld: ^NewtonWorld, shapeID: i32) -> ^NewtonCollision ---
	CreateTreeCollisionFromMesh :: proc(newtonWorld: ^NewtonWorld, mesh: ^NewtonMesh, shapeID: i32) -> ^NewtonCollision ---
	TreeCollisionSetUserRayCastCallback :: proc(treeCollision: ^NewtonCollision, rayHitCallback: NewtonCollisionTreeRayCastCallback) ---
	TreeCollisionBeginBuild :: proc(treeCollision: ^NewtonCollision) ---
	TreeCollisionAddFace :: proc(treeCollision: ^NewtonCollision, vertexCount: i32, vertexPtr: ^dFloat, strideInBytes: i32, faceAttribute: i32) ---
	TreeCollisionEndBuild :: proc(treeCollision: ^NewtonCollision, optimize: i32) ---
	TreeCollisionGetFaceAttribute :: proc(treeCollision: ^NewtonCollision, faceIndexArray: ^i32, indexCount: i32) -> i32 ---
	TreeCollisionSetFaceAttribute :: proc(treeCollision: ^NewtonCollision, faceIndexArray: ^i32, indexCount: i32, attribute: i32) ---
	TreeCollisionForEachFace :: proc(treeCollision: ^NewtonCollision, forEachFaceCallback: NewtonTreeCollisionFaceCallback, _context: rawptr) ---
	TreeCollisionGetVertexListTriangleListInAABB :: proc(treeCollision: ^NewtonCollision, p0: ^dFloat, p1: ^dFloat, vertexArray: ^^dFloat, vertexCount: ^i32, vertexStrideInBytes: ^i32, indexList: ^i32, maxIndexCount: i32, faceAttribute: ^i32) -> i32 ---
	StaticCollisionSetDebugCallback :: proc(staticCollision: ^NewtonCollision, userCallback: NewtonTreeCollisionCallback) ---
	CollisionCreateInstance :: proc(collision: ^NewtonCollision) -> ^NewtonCollision ---
	CollisionGetType :: proc(collision: ^NewtonCollision) -> SerializeId ---
	CollisionIsConvexShape :: proc(collision: ^NewtonCollision) -> b32 ---
	CollisionIsStaticShape :: proc(collision: ^NewtonCollision) -> b32 ---
	CollisionSetUserData :: proc(collision: ^NewtonCollision, userData: rawptr) ---
	CollisionGetUserData :: proc(collision: ^NewtonCollision) -> rawptr ---
	CollisionSetUserID :: proc(collision: ^NewtonCollision, id: i64) ---
	CollisionGetUserID :: proc(collision: ^NewtonCollision) -> i64 ---
	CollisionGetMaterial :: proc(collision: ^NewtonCollision, userData: ^NewtonCollisionMaterial) ---
	CollisionSetMaterial :: proc(collision: ^NewtonCollision, userData: ^NewtonCollisionMaterial) ---
	CollisionGetSubCollisionHandle :: proc(collision: ^NewtonCollision) -> rawptr ---
	CollisionGetParentInstance :: proc(collision: ^NewtonCollision) -> ^NewtonCollision ---
	CollisionSetMatrix :: proc(collision: ^NewtonCollision, matrix4x4: ^dFloat) ---
	CollisionGetMatrix :: proc(collision: ^NewtonCollision, matrix4x4: ^dFloat) ---
	CollisionSetScale :: proc(collision: ^NewtonCollision, scaleX: dFloat, scaleY: dFloat, scaleZ: dFloat) ---
	CollisionGetScale :: proc(collision: ^NewtonCollision, scaleX: ^dFloat, scaleY: ^dFloat, scaleZ: ^dFloat) ---
	DestroyCollision :: proc(collision: ^NewtonCollision) ---
	CollisionGetSkinThickness :: proc(collision: ^NewtonCollision) -> dFloat ---
	CollisionSetSkinThickness :: proc(collision: ^NewtonCollision, thickness: dFloat) ---
	CollisionIntersectionTest :: proc(newtonWorld: ^NewtonWorld, collisionA: ^NewtonCollision, matrixA: ^dFloat, collisionB: ^NewtonCollision, matrixB: ^dFloat, threadIndex: i32) -> i32 ---
	CollisionPointDistance :: proc(newtonWorld: ^NewtonWorld, point: ^dFloat, collision: ^NewtonCollision, matrix4x4: ^dFloat, contact: ^dFloat, normal: ^dFloat, threadIndex: i32) -> i32 ---
	CollisionClosestPoint :: proc(newtonWorld: ^NewtonWorld, collisionA: ^NewtonCollision, matrixA: ^dFloat, collisionB: ^NewtonCollision, matrixB: ^dFloat, contactA: ^dFloat, contactB: ^dFloat, normalAB: ^dFloat, threadIndex: i32) -> i32 ---
	CollisionCollide :: proc(newtonWorld: ^NewtonWorld, maxSize: i32, collisionA: ^NewtonCollision, matrixA: ^dFloat, collisionB: ^NewtonCollision, matrixB: ^dFloat, contacts: ^dFloat, normals: ^dFloat, penetration: ^dFloat, attributeA: ^i64, attributeB: ^i64, threadIndex: i32) -> i32 ---
	CollisionCollideContinue :: proc(newtonWorld: ^NewtonWorld, maxSize: i32, timestep: dFloat, collisionA: ^NewtonCollision, matrixA: ^dFloat, velocA: ^dFloat, omegaA: ^dFloat, collisionB: ^NewtonCollision, matrixB: ^dFloat, velocB: ^dFloat, omegaB: ^dFloat, timeOfImpact: ^dFloat, contacts: ^dFloat, normals: ^dFloat, penetration: ^dFloat, attributeA: ^i64, attributeB: ^i64, threadIndex: i32) -> i32 ---
	CollisionSupportVertex :: proc(collision: ^NewtonCollision, dir: ^dFloat, vertex: ^dFloat) ---
	CollisionRayCast :: proc(collision: ^NewtonCollision, p0: ^dFloat, p1: ^dFloat, normal: ^dFloat, attribute: ^i64) -> dFloat ---
	CollisionCalculateAABB :: proc(collision: ^NewtonCollision, matrix4x4: ^dFloat, p0: ^dFloat, p1: ^dFloat) ---
	CollisionForEachPolygonDo :: proc(collision: ^NewtonCollision, matrix4x4: ^dFloat, callback: NewtonCollisionIterator, userData: rawptr) ---
	CollisionAggregateCreate :: proc(world: ^NewtonWorld) -> rawptr ---
	CollisionAggregateDestroy :: proc(aggregate: rawptr) ---
	CollisionAggregateAddBody :: proc(aggregate: rawptr, body: ^NewtonBody) ---
	CollisionAggregateRemoveBody :: proc(aggregate: rawptr, body: ^NewtonBody) ---
	CollisionAggregateGetSelfCollision :: proc(aggregate: rawptr) -> i32 ---
	CollisionAggregateSetSelfCollision :: proc(aggregate: rawptr, state: i32) ---
	SetEulerAngle :: proc(eulersAngles: ^dFloat, matrix4x4: ^dFloat) ---
	GetEulerAngle :: proc(matrix4x4: ^dFloat, eulersAngles0: ^dFloat, eulersAngles1: ^dFloat) ---
	CalculateSpringDamperAcceleration :: proc(dt: dFloat, ks: dFloat, x: dFloat, kd: dFloat, s: dFloat) -> dFloat ---
	CreateDynamicBody :: proc(newtonWorld: ^NewtonWorld, collision: ^NewtonCollision, matrix4x4: ^dFloat) -> ^NewtonBody ---
	CreateKinematicBody :: proc(newtonWorld: ^NewtonWorld, collision: ^NewtonCollision, matrix4x4: ^dFloat) -> ^NewtonBody ---
	CreateAsymetricDynamicBody :: proc(newtonWorld: ^NewtonWorld, collision: ^NewtonCollision, matrix4x4: ^dFloat) -> ^NewtonBody ---
	DestroyBody :: proc(body: ^NewtonBody) ---
	BodyGetSimulationState :: proc(body: ^NewtonBody) -> i32 ---
	BodySetSimulationState :: proc(bodyPtr: ^NewtonBody, state: i32) ---
	BodyGetType :: proc(body: ^NewtonBody) -> BodyType ---
	BodyGetCollidable :: proc(body: ^NewtonBody) -> i32 ---
	BodySetCollidable :: proc(body: ^NewtonBody, collidableState: i32) ---
	BodyAddForce :: proc(body: ^NewtonBody, force: ^dFloat) ---
	BodyAddTorque :: proc(body: ^NewtonBody, torque: ^dFloat) ---
	BodySetCentreOfMass :: proc(body: ^NewtonBody, com: ^dFloat) ---
	BodySetMassMatrix :: proc(body: ^NewtonBody, mass: dFloat, Ixx: dFloat, Iyy: dFloat, Izz: dFloat) ---
	BodySetFullMassMatrix :: proc(body: ^NewtonBody, mass: dFloat, inertiaMatrix: ^dFloat) ---
	BodySetMassProperties :: proc(body: ^NewtonBody, mass: dFloat, collision: ^NewtonCollision) ---
	BodySetMatrix :: proc(body: ^NewtonBody, matrix4x4: ^dFloat) ---
	BodySetMatrixNoSleep :: proc(body: ^NewtonBody, matrix4x4: ^dFloat) ---
	BodySetMatrixRecursive :: proc(body: ^NewtonBody, matrix4x4: ^dFloat) ---
	BodySetMaterialGroupID :: proc(body: ^NewtonBody, id: i32) ---
	BodySetContinuousCollisionMode :: proc(body: ^NewtonBody, state: u32) ---
	BodySetJointRecursiveCollision :: proc(body: ^NewtonBody, state: u32) ---
	BodySetOmega :: proc(body: ^NewtonBody, omega: ^dFloat) ---
	BodySetOmegaNoSleep :: proc(body: ^NewtonBody, omega: ^dFloat) ---
	BodySetVelocity :: proc(body: ^NewtonBody, velocity: ^dFloat) ---
	BodySetVelocityNoSleep :: proc(body: ^NewtonBody, velocity: ^dFloat) ---
	BodySetForce :: proc(body: ^NewtonBody, force: ^dFloat) ---
	BodySetTorque :: proc(body: ^NewtonBody, torque: ^dFloat) ---
	BodySetLinearDamping :: proc(body: ^NewtonBody, linearDamp: dFloat) ---
	BodySetAngularDamping :: proc(body: ^NewtonBody, angularDamp: ^dFloat) ---
	BodySetCollision :: proc(body: ^NewtonBody, collision: ^NewtonCollision) ---
	BodySetCollisionScale :: proc(body: ^NewtonBody, scaleX: dFloat, scaleY: dFloat, scaleZ: dFloat) ---
	BodyGetSleepState :: proc(body: ^NewtonBody) -> i32 ---
	BodySetSleepState :: proc(body: ^NewtonBody, state: i32) ---
	BodyGetAutoSleep :: proc(body: ^NewtonBody) -> i32 ---
	BodySetAutoSleep :: proc(body: ^NewtonBody, state: i32) ---
	BodyGetFreezeState :: proc(body: ^NewtonBody) -> i32 ---
	BodySetFreezeState :: proc(body: ^NewtonBody, state: i32) ---
	BodyGetGyroscopicTorque :: proc(body: ^NewtonBody) -> i32 ---
	BodySetGyroscopicTorque :: proc(body: ^NewtonBody, state: i32) ---
	BodySetDestructorCallback :: proc(body: ^NewtonBody, callback: NewtonBodyDestructor) ---
	BodyGetDestructorCallback :: proc(body: ^NewtonBody) -> NewtonBodyDestructor ---
	BodySetTransformCallback :: proc(body: ^NewtonBody, callback: NewtonSetTransform) ---
	BodyGetTransformCallback :: proc(body: ^NewtonBody) -> NewtonSetTransform ---
	BodySetForceAndTorqueCallback :: proc(body: ^NewtonBody, callback: NewtonApplyForceAndTorque) ---
	BodyGetForceAndTorqueCallback :: proc(body: ^NewtonBody) -> NewtonApplyForceAndTorque ---
	BodyGetID :: proc(body: ^NewtonBody) -> i32 ---
	BodySetUserData :: proc(body: ^NewtonBody, userData: rawptr) ---
	BodyGetUserData :: proc(body: ^NewtonBody) -> rawptr ---
	BodyGetWorld :: proc(body: ^NewtonBody) -> ^NewtonWorld ---
	BodyGetCollision :: proc(body: ^NewtonBody) -> ^NewtonCollision ---
	BodyGetMaterialGroupID :: proc(body: ^NewtonBody) -> i32 ---
	BodyGetSerializedID :: proc(body: ^NewtonBody) -> i32 ---
	BodyGetContinuousCollisionMode :: proc(body: ^NewtonBody) -> i32 ---
	BodyGetJointRecursiveCollision :: proc(body: ^NewtonBody) -> i32 ---
	BodyGetPosition :: proc(body: ^NewtonBody, pos: ^dFloat) ---
	BodyGetMatrix :: proc(body: ^NewtonBody, matrix4x4: ^dFloat) ---
	BodyGetRotation :: proc(body: ^NewtonBody, rotation: ^dFloat) ---
	BodyGetMass :: proc(body: ^NewtonBody, mass: ^dFloat, Ixx: ^dFloat, Iyy: ^dFloat, Izz: ^dFloat) ---
	BodyGetInvMass :: proc(body: ^NewtonBody, invMass: ^dFloat, invIxx: ^dFloat, invIyy: ^dFloat, invIzz: ^dFloat) ---
	BodyGetInertiaMatrix :: proc(body: ^NewtonBody, inertiaMatrix: ^dFloat) ---
	BodyGetInvInertiaMatrix :: proc(body: ^NewtonBody, invInertiaMatrix: ^dFloat) ---
	BodyGetOmega :: proc(body: ^NewtonBody, vector: ^dFloat) ---
	BodyGetVelocity :: proc(body: ^NewtonBody, vector: ^dFloat) ---
	BodyGetAlpha :: proc(body: ^NewtonBody, vector: ^dFloat) ---
	BodyGetAcceleration :: proc(body: ^NewtonBody, vector: ^dFloat) ---
	BodyGetForce :: proc(body: ^NewtonBody, vector: ^dFloat) ---
	BodyGetTorque :: proc(body: ^NewtonBody, vector: ^dFloat) ---
	BodyGetCentreOfMass :: proc(body: ^NewtonBody, com: ^dFloat) ---
	BodyGetPointVelocity :: proc(body: ^NewtonBody, point: ^dFloat, velocOut: ^dFloat) ---
	BodyApplyImpulsePair :: proc(body: ^NewtonBody, linearImpulse: ^dFloat, angularImpulse: ^dFloat, timestep: dFloat) ---
	BodyAddImpulse :: proc(body: ^NewtonBody, pointDeltaVeloc: ^dFloat, pointPosit: ^dFloat, timestep: dFloat) ---
	BodyApplyImpulseArray :: proc(body: ^NewtonBody, impuleCount: i32, strideInByte: i32, impulseArray: ^dFloat, pointArray: ^dFloat, timestep: dFloat) ---
	BodyIntegrateVelocity :: proc(body: ^NewtonBody, timestep: dFloat) ---
	BodyGetLinearDamping :: proc(body: ^NewtonBody) -> dFloat ---
	BodyGetAngularDamping :: proc(body: ^NewtonBody, vector: ^dFloat) ---
	BodyGetAABB :: proc(body: ^NewtonBody, p0: ^dFloat, p1: ^dFloat) ---
	BodyGetFirstJoint :: proc(body: ^NewtonBody) -> ^NewtonJoint ---
	BodyGetNextJoint :: proc(body: ^NewtonBody, joint: ^NewtonJoint) -> ^NewtonJoint ---
	BodyGetFirstContactJoint :: proc(body: ^NewtonBody) -> ^NewtonJoint ---
	BodyGetNextContactJoint :: proc(body: ^NewtonBody, contactJoint: ^NewtonJoint) -> ^NewtonJoint ---
	BodyFindContact :: proc(body0: ^NewtonBody, body1: ^NewtonBody) -> ^NewtonJoint ---
	ContactJointGetFirstContact :: proc(contactJoint: ^NewtonJoint) -> rawptr ---
	ContactJointGetNextContact :: proc(contactJoint: ^NewtonJoint, contact: rawptr) -> rawptr ---
	ContactJointGetContactCount :: proc(contactJoint: ^NewtonJoint) -> i32 ---
	ContactJointRemoveContact :: proc(contactJoint: ^NewtonJoint, contact: rawptr) ---
	ContactJointGetClosestDistance :: proc(contactJoint: ^NewtonJoint) -> dFloat ---
	ContactJointResetSelftJointCollision :: proc(contactJoint: ^NewtonJoint) ---
	ContactJointResetIntraJointCollision :: proc(contactJoint: ^NewtonJoint) ---
	ContactGetMaterial :: proc(contact: rawptr) -> ^NewtonMaterial ---
	ContactGetCollision0 :: proc(contact: rawptr) -> ^NewtonCollision ---
	ContactGetCollision1 :: proc(contact: rawptr) -> ^NewtonCollision ---
	ContactGetCollisionID0 :: proc(contact: rawptr) -> rawptr ---
	ContactGetCollisionID1 :: proc(contact: rawptr) -> rawptr ---
	JointGetUserData :: proc(joint: ^NewtonJoint) -> rawptr ---
	JointSetUserData :: proc(joint: ^NewtonJoint, userData: rawptr) ---
	JointGetBody0 :: proc(joint: ^NewtonJoint) -> ^NewtonBody ---
	JointGetBody1 :: proc(joint: ^NewtonJoint) -> ^NewtonBody ---
	JointGetInfo :: proc(joint: ^NewtonJoint, info: ^NewtonJointRecord) ---
	JointGetCollisionState :: proc(joint: ^NewtonJoint) -> i32 ---
	JointSetCollisionState :: proc(joint: ^NewtonJoint, state: i32) ---
	JointGetStiffness :: proc(joint: ^NewtonJoint) -> dFloat ---
	JointSetStiffness :: proc(joint: ^NewtonJoint, state: dFloat) ---
	DestroyJoint :: proc(newtonWorld: ^NewtonWorld, joint: ^NewtonJoint) ---
	JointSetDestructor :: proc(joint: ^NewtonJoint, destructor: NewtonConstraintDestructor) ---
	JointIsActive :: proc(joint: ^NewtonJoint) -> i32 ---
	CreateMassSpringDamperSystem :: proc(newtonWorld: ^NewtonWorld, shapeID: i32, points: ^dFloat, pointCount: i32, strideInBytes: i32, pointMass: ^dFloat, links: ^i32, linksCount: i32, linksSpring: ^dFloat, linksDamper: ^dFloat) -> ^NewtonCollision ---
	CreateDeformableSolid :: proc(newtonWorld: ^NewtonWorld, mesh: ^NewtonMesh, shapeID: i32) -> ^NewtonCollision ---
	DeformableMeshGetParticleCount :: proc(deformableMesh: ^NewtonCollision) -> i32 ---
	DeformableMeshGetParticleStrideInBytes :: proc(deformableMesh: ^NewtonCollision) -> i32 ---
	DeformableMeshGetParticleArray :: proc(deformableMesh: ^NewtonCollision) -> ^dFloat ---
	ConstraintCreateBall :: proc(newtonWorld: ^NewtonWorld, pivotPoint: ^dFloat, childBody: ^NewtonBody, parentBody: ^NewtonBody) -> ^NewtonJoint ---
	BallSetUserCallback :: proc(ball: ^NewtonJoint, callback: NewtonBallCallback) ---
	BallGetJointAngle :: proc(ball: ^NewtonJoint, angle: ^dFloat) ---
	BallGetJointOmega :: proc(ball: ^NewtonJoint, omega: ^dFloat) ---
	BallGetJointForce :: proc(ball: ^NewtonJoint, force: ^dFloat) ---
	BallSetConeLimits :: proc(ball: ^NewtonJoint, pin: ^dFloat, maxConeAngle: dFloat, maxTwistAngle: dFloat) ---
	ConstraintCreateHinge :: proc(newtonWorld: ^NewtonWorld, pivotPoint: ^dFloat, pinDir: ^dFloat, childBody: ^NewtonBody, parentBody: ^NewtonBody) -> ^NewtonJoint ---
	HingeSetUserCallback :: proc(hinge: ^NewtonJoint, callback: NewtonHingeCallback) ---
	HingeGetJointAngle :: proc(hinge: ^NewtonJoint) -> dFloat ---
	HingeGetJointOmega :: proc(hinge: ^NewtonJoint) -> dFloat ---
	HingeGetJointForce :: proc(hinge: ^NewtonJoint, force: ^dFloat) ---
	HingeCalculateStopAlpha :: proc(hinge: ^NewtonJoint, desc: ^NewtonHingeSliderUpdateDesc, angle: dFloat) -> dFloat ---
	ConstraintCreateSlider :: proc(newtonWorld: ^NewtonWorld, pivotPoint: ^dFloat, pinDir: ^dFloat, childBody: ^NewtonBody, parentBody: ^NewtonBody) -> ^NewtonJoint ---
	SliderSetUserCallback :: proc(slider: ^NewtonJoint, callback: NewtonSliderCallback) ---
	SliderGetJointPosit :: proc(slider: ^NewtonJoint) -> dFloat ---
	SliderGetJointVeloc :: proc(slider: ^NewtonJoint) -> dFloat ---
	SliderGetJointForce :: proc(slider: ^NewtonJoint, force: ^dFloat) ---
	SliderCalculateStopAccel :: proc(slider: ^NewtonJoint, desc: ^NewtonHingeSliderUpdateDesc, position: dFloat) -> dFloat ---
	ConstraintCreateCorkscrew :: proc(newtonWorld: ^NewtonWorld, pivotPoint: ^dFloat, pinDir: ^dFloat, childBody: ^NewtonBody, parentBody: ^NewtonBody) -> ^NewtonJoint ---
	CorkscrewSetUserCallback :: proc(corkscrew: ^NewtonJoint, callback: NewtonCorkscrewCallback) ---
	CorkscrewGetJointPosit :: proc(corkscrew: ^NewtonJoint) -> dFloat ---
	CorkscrewGetJointAngle :: proc(corkscrew: ^NewtonJoint) -> dFloat ---
	CorkscrewGetJointVeloc :: proc(corkscrew: ^NewtonJoint) -> dFloat ---
	CorkscrewGetJointOmega :: proc(corkscrew: ^NewtonJoint) -> dFloat ---
	CorkscrewGetJointForce :: proc(corkscrew: ^NewtonJoint, force: ^dFloat) ---
	CorkscrewCalculateStopAlpha :: proc(corkscrew: ^NewtonJoint, desc: ^NewtonHingeSliderUpdateDesc, angle: dFloat) -> dFloat ---
	CorkscrewCalculateStopAccel :: proc(corkscrew: ^NewtonJoint, desc: ^NewtonHingeSliderUpdateDesc, position: dFloat) -> dFloat ---
	ConstraintCreateUniversal :: proc(newtonWorld: ^NewtonWorld, pivotPoint: ^dFloat, pinDir0: ^dFloat, pinDir1: ^dFloat, childBody: ^NewtonBody, parentBody: ^NewtonBody) -> ^NewtonJoint ---
	UniversalSetUserCallback :: proc(universal: ^NewtonJoint, callback: NewtonUniversalCallback) ---
	UniversalGetJointAngle0 :: proc(universal: ^NewtonJoint) -> dFloat ---
	UniversalGetJointAngle1 :: proc(universal: ^NewtonJoint) -> dFloat ---
	UniversalGetJointOmega0 :: proc(universal: ^NewtonJoint) -> dFloat ---
	UniversalGetJointOmega1 :: proc(universal: ^NewtonJoint) -> dFloat ---
	UniversalGetJointForce :: proc(universal: ^NewtonJoint, force: ^dFloat) ---
	UniversalCalculateStopAlpha0 :: proc(universal: ^NewtonJoint, desc: ^NewtonHingeSliderUpdateDesc, angle: dFloat) -> dFloat ---
	UniversalCalculateStopAlpha1 :: proc(universal: ^NewtonJoint, desc: ^NewtonHingeSliderUpdateDesc, angle: dFloat) -> dFloat ---
	ConstraintCreateUpVector :: proc(newtonWorld: ^NewtonWorld, pinDir: ^dFloat, body: ^NewtonBody) -> ^NewtonJoint ---
	UpVectorGetPin :: proc(upVector: ^NewtonJoint, pin: ^dFloat) ---
	UpVectorSetPin :: proc(upVector: ^NewtonJoint, pin: ^dFloat) ---
	ConstraintCreateUserJoint :: proc(newtonWorld: ^NewtonWorld, maxDOF: i32, callback: NewtonUserBilateralCallback, childBody: ^NewtonBody, parentBody: ^NewtonBody) -> ^NewtonJoint ---
	UserJointGetSolverModel :: proc(joint: ^NewtonJoint) -> i32 ---
	UserJointSetSolverModel :: proc(joint: ^NewtonJoint, model: i32) ---
	UserJointMassScale :: proc(joint: ^NewtonJoint, scaleBody0: dFloat, scaleBody1: dFloat) ---
	UserJointSetFeedbackCollectorCallback :: proc(joint: ^NewtonJoint, getFeedback: NewtonUserBilateralCallback) ---
	UserJointAddLinearRow :: proc(joint: ^NewtonJoint, pivot0: ^dFloat, pivot1: ^dFloat, dir: ^dFloat) ---
	UserJointAddAngularRow :: proc(joint: ^NewtonJoint, relativeAngle: dFloat, dir: ^dFloat) ---
	UserJointAddGeneralRow :: proc(joint: ^NewtonJoint, jacobian0: ^JacobianPair, jacobian1: ^JacobianPair) ---
	UserJointSetRowMinimumFriction :: proc(joint: ^NewtonJoint, friction: dFloat) ---
	UserJointSetRowMaximumFriction :: proc(joint: ^NewtonJoint, friction: dFloat) ---
	UserJointCalculateRowZeroAcceleration :: proc(joint: ^NewtonJoint) -> dFloat ---
	UserJointGetRowAcceleration :: proc(joint: ^NewtonJoint) -> dFloat ---
	UserJointGetRowJacobian :: proc(joint: ^NewtonJoint, linear0: ^dFloat, angula0: ^dFloat, linear1: ^dFloat, angula1: ^dFloat) ---
	UserJointSetRowAcceleration :: proc(joint: ^NewtonJoint, acceleration: dFloat) ---
	UserJointSetRowMassDependentSpringDamperAcceleration :: proc(joint: ^NewtonJoint, spring: dFloat, damper: dFloat) ---
	UserJointSetRowMassIndependentSpringDamperAcceleration :: proc(joint: ^NewtonJoint, rowStiffness: dFloat, spring: dFloat, damper: dFloat) ---
	UserJointSetRowStiffness :: proc(joint: ^NewtonJoint, stiffness: dFloat) ---
	UserJoinRowsCount :: proc(joint: ^NewtonJoint) -> i32 ---
	UserJointGetGeneralRow :: proc(joint: ^NewtonJoint, index: i32, jacobian0: ^JacobianPair, jacobian1: ^JacobianPair) ---
	UserJointGetRowForce :: proc(joint: ^NewtonJoint, row: i32) -> dFloat ---
	MeshCreate :: proc(newtonWorld: ^NewtonWorld) -> ^NewtonMesh ---
	MeshCreateFromMesh :: proc(mesh: ^NewtonMesh) -> ^NewtonMesh ---
	MeshCreateFromCollision :: proc(collision: ^NewtonCollision) -> ^NewtonMesh ---
	MeshCreateTetrahedraIsoSurface :: proc(mesh: ^NewtonMesh) -> ^NewtonMesh ---
	MeshCreateConvexHull :: proc(newtonWorld: ^NewtonWorld, pointCount: i32, vertexCloud: ^dFloat, strideInBytes: i32, tolerance: dFloat) -> ^NewtonMesh ---
	MeshCreateVoronoiConvexDecomposition :: proc(newtonWorld: ^NewtonWorld, pointCount: i32, vertexCloud: ^dFloat, strideInBytes: i32, materialID: i32, textureMatrix: ^dFloat) -> ^NewtonMesh ---
	MeshCreateFromSerialization :: proc(newtonWorld: ^NewtonWorld, deserializeFunction: NewtonDeserializeCallback, serializeHandle: rawptr) -> ^NewtonMesh ---
	MeshDestroy :: proc(mesh: ^NewtonMesh) ---
	MeshSerialize :: proc(mesh: ^NewtonMesh, serializeFunction: NewtonSerializeCallback, serializeHandle: rawptr) ---
	MeshSaveOFF :: proc(mesh: ^NewtonMesh, filename: cstring) ---
	MeshLoadOFF :: proc(newtonWorld: ^NewtonWorld, filename: cstring) -> ^NewtonMesh ---
	MeshLoadTetrahedraMesh :: proc(newtonWorld: ^NewtonWorld, filename: cstring) -> ^NewtonMesh ---
	MeshFlipWinding :: proc(mesh: ^NewtonMesh) ---
	MeshApplyTransform :: proc(mesh: ^NewtonMesh, matrix4x4: ^dFloat) ---
	MeshCalculateOOBB :: proc(mesh: ^NewtonMesh, matrix4x4: ^dFloat, x: ^dFloat, y: ^dFloat, z: ^dFloat) ---
	MeshCalculateVertexNormals :: proc(mesh: ^NewtonMesh, angleInRadians: dFloat) ---
	MeshApplySphericalMapping :: proc(mesh: ^NewtonMesh, material: i32, aligmentMatrix: ^dFloat) ---
	MeshApplyCylindricalMapping :: proc(mesh: ^NewtonMesh, cylinderMaterial: i32, capMaterial: i32, aligmentMatrix: ^dFloat) ---
	MeshApplyBoxMapping :: proc(mesh: ^NewtonMesh, frontMaterial: i32, sideMaterial: i32, topMaterial: i32, aligmentMatrix: ^dFloat) ---
	MeshApplyAngleBasedMapping :: proc(mesh: ^NewtonMesh, material: i32, reportPrograssCallback: NewtonReportProgress, reportPrgressUserData: rawptr, aligmentMatrix: ^dFloat) ---
	CreateTetrahedraLinearBlendSkinWeightsChannel :: proc(tetrahedraMesh: ^NewtonMesh, skinMesh: ^NewtonMesh) ---
	MeshOptimize :: proc(mesh: ^NewtonMesh) ---
	MeshOptimizePoints :: proc(mesh: ^NewtonMesh) ---
	MeshOptimizeVertex :: proc(mesh: ^NewtonMesh) ---
	MeshIsOpenMesh :: proc(mesh: ^NewtonMesh) -> i32 ---
	MeshFixTJoints :: proc(mesh: ^NewtonMesh) ---
	MeshPolygonize :: proc(mesh: ^NewtonMesh) ---
	MeshTriangulate :: proc(mesh: ^NewtonMesh) ---
	MeshUnion :: proc(mesh: ^NewtonMesh, clipper: ^NewtonMesh, clipperMatrix: ^dFloat) -> ^NewtonMesh ---
	MeshDifference :: proc(mesh: ^NewtonMesh, clipper: ^NewtonMesh, clipperMatrix: ^dFloat) -> ^NewtonMesh ---
	MeshIntersection :: proc(mesh: ^NewtonMesh, clipper: ^NewtonMesh, clipperMatrix: ^dFloat) -> ^NewtonMesh ---
	MeshClip :: proc(mesh: ^NewtonMesh, clipper: ^NewtonMesh, clipperMatrix: ^dFloat, topMesh: ^^NewtonMesh, bottomMesh: ^^NewtonMesh) ---
	MeshConvexMeshIntersection :: proc(mesh: ^NewtonMesh, convexMesh: ^NewtonMesh) -> ^NewtonMesh ---
	MeshSimplify :: proc(mesh: ^NewtonMesh, maxVertexCount: i32, reportPrograssCallback: NewtonReportProgress, reportPrgressUserData: rawptr) -> ^NewtonMesh ---
	MeshApproximateConvexDecomposition :: proc(mesh: ^NewtonMesh, maxConcavity: dFloat, backFaceDistanceFactor: dFloat, maxCount: i32, maxVertexPerHull: i32, reportProgressCallback: NewtonReportProgress, reportProgressUserData: rawptr) -> ^NewtonMesh ---
	RemoveUnusedVertices :: proc(mesh: ^NewtonMesh, vertexRemapTable: ^i32) ---
	MeshBeginBuild :: proc(mesh: ^NewtonMesh) ---
	MeshBeginFace :: proc(mesh: ^NewtonMesh) ---
	MeshAddPoint :: proc(mesh: ^NewtonMesh, x: f64, y: f64, z: f64) ---
	MeshAddLayer :: proc(mesh: ^NewtonMesh, layerIndex: i32) ---
	MeshAddMaterial :: proc(mesh: ^NewtonMesh, materialIndex: i32) ---
	MeshAddNormal :: proc(mesh: ^NewtonMesh, x: dFloat, y: dFloat, z: dFloat) ---
	MeshAddBinormal :: proc(mesh: ^NewtonMesh, x: dFloat, y: dFloat, z: dFloat) ---
	MeshAddUV0 :: proc(mesh: ^NewtonMesh, u: dFloat, v: dFloat) ---
	MeshAddUV1 :: proc(mesh: ^NewtonMesh, u: dFloat, v: dFloat) ---
	MeshAddVertexColor :: proc(mesh: ^NewtonMesh, r: f32, g: f32, b: f32, a: f32) ---
	MeshEndFace :: proc(mesh: ^NewtonMesh) ---
	MeshEndBuild :: proc(mesh: ^NewtonMesh) ---
	MeshClearVertexFormat :: proc(format: ^NewtonMeshVertexFormat) ---
	MeshBuildFromVertexListIndexList :: proc(mesh: ^NewtonMesh, format: ^NewtonMeshVertexFormat) ---
	MeshGetPointCount :: proc(mesh: ^NewtonMesh) -> i32 ---
	MeshGetIndexToVertexMap :: proc(mesh: ^NewtonMesh) -> ^i32 ---
	MeshGetVertexDoubleChannel :: proc(mesh: ^NewtonMesh, vertexStrideInByte: i32, outBuffer: ^f64) ---
	MeshGetVertexChannel :: proc(mesh: ^NewtonMesh, vertexStrideInByte: i32, outBuffer: ^dFloat) ---
	MeshGetNormalChannel :: proc(mesh: ^NewtonMesh, vertexStrideInByte: i32, outBuffer: ^dFloat) ---
	MeshGetBinormalChannel :: proc(mesh: ^NewtonMesh, vertexStrideInByte: i32, outBuffer: ^dFloat) ---
	MeshGetUV0Channel :: proc(mesh: ^NewtonMesh, vertexStrideInByte: i32, outBuffer: ^dFloat) ---
	MeshGetUV1Channel :: proc(mesh: ^NewtonMesh, vertexStrideInByte: i32, outBuffer: ^dFloat) ---
	MeshGetVertexColorChannel :: proc(mesh: ^NewtonMesh, vertexStrideInByte: i32, outBuffer: ^dFloat) ---
	MeshHasNormalChannel :: proc(mesh: ^NewtonMesh) -> i32 ---
	MeshHasBinormalChannel :: proc(mesh: ^NewtonMesh) -> i32 ---
	MeshHasUV0Channel :: proc(mesh: ^NewtonMesh) -> i32 ---
	MeshHasUV1Channel :: proc(mesh: ^NewtonMesh) -> i32 ---
	MeshHasVertexColorChannel :: proc(mesh: ^NewtonMesh) -> i32 ---
	MeshBeginHandle :: proc(mesh: ^NewtonMesh) -> rawptr ---
	MeshEndHandle :: proc(mesh: ^NewtonMesh, handle: rawptr) ---
	MeshFirstMaterial :: proc(mesh: ^NewtonMesh, handle: rawptr) -> i32 ---
	MeshNextMaterial :: proc(mesh: ^NewtonMesh, handle: rawptr, materialId: i32) -> i32 ---
	MeshMaterialGetMaterial :: proc(mesh: ^NewtonMesh, handle: rawptr, materialId: i32) -> i32 ---
	MeshMaterialGetIndexCount :: proc(mesh: ^NewtonMesh, handle: rawptr, materialId: i32) -> i32 ---
	MeshMaterialGetIndexStream :: proc(mesh: ^NewtonMesh, handle: rawptr, materialId: i32, index: ^i32) ---
	MeshMaterialGetIndexStreamShort :: proc(mesh: ^NewtonMesh, handle: rawptr, materialId: i32, index: ^i16) ---
	MeshCreateFirstSingleSegment :: proc(mesh: ^NewtonMesh) -> ^NewtonMesh ---
	MeshCreateNextSingleSegment :: proc(mesh: ^NewtonMesh, segment: ^NewtonMesh) -> ^NewtonMesh ---
	MeshCreateFirstLayer :: proc(mesh: ^NewtonMesh) -> ^NewtonMesh ---
	MeshCreateNextLayer :: proc(mesh: ^NewtonMesh, segment: ^NewtonMesh) -> ^NewtonMesh ---
	MeshGetTotalFaceCount :: proc(mesh: ^NewtonMesh) -> i32 ---
	MeshGetTotalIndexCount :: proc(mesh: ^NewtonMesh) -> i32 ---
	MeshGetFaces :: proc(mesh: ^NewtonMesh, faceIndexCount: ^i32, faceMaterial: ^i32, faceIndices: ^rawptr) ---
	MeshGetVertexCount :: proc(mesh: ^NewtonMesh) -> i32 ---
	MeshGetVertexStrideInByte :: proc(mesh: ^NewtonMesh) -> i32 ---
	MeshGetVertexArray :: proc(mesh: ^NewtonMesh) -> ^f64 ---
	MeshGetVertexBaseCount :: proc(mesh: ^NewtonMesh) -> i32 ---
	MeshSetVertexBaseCount :: proc(mesh: ^NewtonMesh, baseCount: i32) ---
	MeshGetFirstVertex :: proc(mesh: ^NewtonMesh) -> rawptr ---
	MeshGetNextVertex :: proc(mesh: ^NewtonMesh, vertex: rawptr) -> rawptr ---
	MeshGetVertexIndex :: proc(mesh: ^NewtonMesh, vertex: rawptr) -> i32 ---
	MeshGetFirstPoint :: proc(mesh: ^NewtonMesh) -> rawptr ---
	MeshGetNextPoint :: proc(mesh: ^NewtonMesh, point: rawptr) -> rawptr ---
	MeshGetPointIndex :: proc(mesh: ^NewtonMesh, point: rawptr) -> i32 ---
	MeshGetVertexIndexFromPoint :: proc(mesh: ^NewtonMesh, point: rawptr) -> i32 ---
	MeshGetFirstEdge :: proc(mesh: ^NewtonMesh) -> rawptr ---
	MeshGetNextEdge :: proc(mesh: ^NewtonMesh, edge: rawptr) -> rawptr ---
	MeshGetEdgeIndices :: proc(mesh: ^NewtonMesh, edge: rawptr, v0: ^i32, v1: ^i32) ---
	MeshGetFirstFace :: proc(mesh: ^NewtonMesh) -> rawptr ---
	MeshGetNextFace :: proc(mesh: ^NewtonMesh, face: rawptr) -> rawptr ---
	MeshIsFaceOpen :: proc(mesh: ^NewtonMesh, face: rawptr) -> i32 ---
	MeshGetFaceMaterial :: proc(mesh: ^NewtonMesh, face: rawptr) -> i32 ---
	MeshGetFaceIndexCount :: proc(mesh: ^NewtonMesh, face: rawptr) -> i32 ---
	MeshGetFaceIndices :: proc(mesh: ^NewtonMesh, face: rawptr, indices: ^i32) ---
	MeshGetFacePointIndices :: proc(mesh: ^NewtonMesh, face: rawptr, indices: ^i32) ---
	MeshCalculateFaceNormal :: proc(mesh: ^NewtonMesh, face: rawptr, normal: ^f64) ---
	MeshSetFaceMaterial :: proc(mesh: ^NewtonMesh, face: rawptr, matId: i32) ---
}

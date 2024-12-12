package newton_glfw

import "core:fmt"
import newton "shared:newton_dynamics"

write_globals :: proc() {
	fmt.println("Globals:")
	fmt.printfln("  Version             : %.2f", f32(newton.GetVersion()) / 100)
	fmt.printfln("  FloatSize           : %v", newton.GetFloatSize())
	fmt.printfln("  MemoryUsed          : %v", newton.GetMemoryUsed())
}

write_world_count :: proc(world: ^newton.World) {
	fmt.println("World:")
	fmt.printfln("  BodyCount           : %v", newton.WorldGetBodyCount(world))
	fmt.printfln("  ConstraintCount     : %v", newton.WorldGetConstraintCount(world))
}

write_world :: proc(world: ^newton.World) {
	write_world_count(world)
	fmt.printfln("  BroadphaseAlgorithm : %v", newton.GetBroadphaseAlgorithm(world))
	fmt.printfln("  NumberOfSubsteps    : %v", newton.GetNumberOfSubsteps(world))
	fmt.printfln("  ThreadsCount        : %v", newton.GetThreadsCount(world))
	fmt.printfln("  MaxThreadsCount     : %v", newton.GetMaxThreadsCount(world))
	fmt.printfln("  UserData            : %v", newton.WorldGetUserData(world))
}

write_collision :: proc(collision: ^newton.Collision) {
	fmt.println("Collision:")
	fmt.printfln("  CollisionType       : %v", newton.CollisionGetType(collision))
	fmt.printfln("  IsConvexShape       : %v", newton.CollisionIsConvexShape(collision))
	fmt.printfln("  IsStaticShape       : %v", newton.CollisionIsStaticShape(collision))
	fmt.printfln("  Mode                : %v", newton.CollisionGetMode(collision))
	fmt.printfln("  Volume              : %v", newton.ConvexCollisionCalculateVolume(collision))
}

write_mesh :: proc(mesh: ^newton.Mesh) {
	fmt.println("Mesh:")
	fmt.printfln("  MeshGetPointCount      : %v", newton.MeshGetPointCount(mesh))
	fmt.printfln("  MeshGetTotalFaceCount  : %v", newton.MeshGetTotalFaceCount(mesh))
	fmt.printfln("  MeshGetTotalIndexCount : %v", newton.MeshGetTotalIndexCount(mesh))
	fmt.printfln("  MeshGetVertexCount     : %v", newton.MeshGetVertexCount(mesh))
}

write_body :: proc(body: ^newton.Body) {
	fmt.println("Body:")
	fmt.printfln("  BodyType            : %v", newton.BodyGetType(body))
	pos, rot: newton.float3
	newton.BodyGetPosition(body, &pos[0])
	newton.BodyGetRotation(body, &rot[0])
	fmt.printfln("  Position            : %v", pos)
	fmt.printfln("  Rotation            : %v", rot)
}

package main

import "core:fmt"
import newton "../../shared/newton_dynamics"

main :: proc() {
	fmt.print("Newton Dynamics\n")
	fmt.printf("Version    : %v\n", newton.GetVersion())
	fmt.printf("FloatSize  : %v\n", newton.GetFloatSize())
	fmt.printf("MemoryUsed : %v\n", newton.GetMemoryUsed())

	world := newton.Create()
	defer newton.Destroy(world)

	fmt.printf("ThreadsCount        : %v\n", newton.GetThreadsCount(world))
	fmt.printf("BroadphaseAlgorithm : %v\n", newton.GetBroadphaseAlgorithm(world))

	newton.DestroyAllBodies(world)

	f3 : newton.float3
	i3 : newton.int3
}

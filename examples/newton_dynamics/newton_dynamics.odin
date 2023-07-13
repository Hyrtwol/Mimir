package main

import "core:fmt"
import newton "../../shared/newton_dynamics"

main :: proc() {
	fmt.print("Newton Dynamics\n")
	fmt.printf("Version    : %v\n", newton.NewtonWorldGetVersion())
	fmt.printf("FloatSize  : %v\n", newton.NewtonWorldFloatSize())
	fmt.printf("MemoryUsed : %v\n", newton.NewtonGetMemoryUsed())

	world := newton.NewtonCreate()
	defer newton.NewtonDestroy(world)

	fmt.printf("ThreadsCount        : %v\n", newton.NewtonGetThreadsCount(world))
	fmt.printf("BroadphaseAlgorithm : %v\n", newton.NewtonGetBroadphaseAlgorithm(world))

	newton.NewtonDestroyAllBodies(world)
}

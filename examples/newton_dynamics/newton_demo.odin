package main

import "core:fmt"
import newton "shared:newton_dynamics"

main :: proc() {
	fmt.println("Newton Dynamics")
	defer fmt.println("Done.")

	fmt.println("Globals:")
	fmt.printfln("  Version             : %.2f", f32(newton.GetVersion()) / 100)
	fmt.printfln("  FloatSize           : %v", newton.GetFloatSize())
	fmt.printfln("  MemoryUsed          : %v", newton.GetMemoryUsed())

	world := newton.Create()
	defer newton.Destroy(world)

	fmt.println("World:")
	fmt.printfln("  BodyCount           : %v", newton.WorldGetBodyCount(world))
	fmt.printfln("  ConstraintCount     : %v", newton.WorldGetConstraintCount(world))
	fmt.printfln("  BroadphaseAlgorithm : %v", newton.GetBroadphaseAlgorithm(world))
	fmt.printfln("  ThreadsCount        : %v", newton.GetThreadsCount(world))
	fmt.printfln("  MaxThreadsCount     : %v", newton.GetMaxThreadsCount(world))

	{
		collision := newton.CreateBox(world, 2, 2, 2, 0, nil)
		defer newton.DestroyCollision(collision)

		mtx := newton.identity(newton.float4x4)
		body := newton.CreateDynamicBody(world, collision, &mtx)
		defer newton.DestroyBody(body)

		fmt.printfln("  BodyCount           : %v", newton.WorldGetBodyCount(world))
		fmt.printfln("  ConstraintCount     : %v", newton.WorldGetConstraintCount(world))

		fmt.println("Collision:")
		fmt.printfln("  CollisionType       : %v", newton.CollisionGetType(collision))
		fmt.printfln("  IsConvexShape       : %v", newton.CollisionIsConvexShape(collision))
		fmt.printfln("  IsStaticShape       : %v", newton.CollisionIsStaticShape(collision))

		dump_NewtonCollisionInfoRecord(collision)

		fmt.println("Body:")
		fmt.printfln("  BodyType            : %v", newton.BodyGetType(body))
	}

	fmt.printfln("  BodyCount           : %v", newton.WorldGetBodyCount(world))
	fmt.printfln("  ConstraintCount     : %v", newton.WorldGetConstraintCount(world))
	fmt.println("DestroyAllBodies:")
	newton.DestroyAllBodies(world)
	fmt.printfln("  BodyCount           : %v", newton.WorldGetBodyCount(world))
	fmt.printfln("  ConstraintCount     : %v", newton.WorldGetConstraintCount(world))

	// f3: newton.float3
	// i3: newton.int3
}

dump_NewtonCollisionInfoRecord :: proc(collision: ^newton.NewtonCollision) {
	cir: newton.NewtonCollisionInfoRecord
	newton.CollisionGetInfo(collision, &cir)
	fmt.println("CollisionInfoRecord:")
	fmt.printfln("  m_offsetMatrix      : %v", cir.m_offsetMatrix)
	fmt.printfln("  m_collisionMaterial : %v", cir.m_collisionMaterial)
	fmt.printfln("    m_userData        : %v", cir.m_collisionMaterial.m_userData)
	fmt.printfln("  m_collisionType     : %v", cir.m_collisionType)
	#partial switch cir.m_collisionType {
	case newton.SerializeId.Box:
		fmt.printfln("  m_box:                %v", cir.m_box)
	case newton.SerializeId.Cone:
		fmt.printfln("  m_cone:               %v", cir.m_cone)
	case newton.SerializeId.Sphere:
		fmt.printfln("  m_sphere:             %v", cir.m_sphere)
	case newton.SerializeId.Capsule:
		fmt.printfln("  m_capsule:            %v", cir.m_capsule)
	case newton.SerializeId.Cylinder:
		fmt.printfln("  m_cylinder:           %v", cir.m_cylinder)
	case newton.SerializeId.Chamfercylinder:
		fmt.printfln("  m_chamferCylinder:    %v", cir.m_chamferCylinder)
	case newton.SerializeId.Convexhull:
		fmt.printfln("  m_convexHull:         %v", cir.m_convexHull)
	case newton.SerializeId.DeformableSolid:
		fmt.printfln("  m_deformableMesh:     %v", cir.m_deformableMesh)
	case newton.SerializeId.Compound:
		fmt.printfln("  m_compoundCollision:  %v", cir.m_compoundCollision)
	case newton.SerializeId.Tree:
		fmt.printfln("  m_collisionTree:      %v", cir.m_collisionTree)
	case newton.SerializeId.Heightfield:
		fmt.printfln("  m_heightField:        %v", cir.m_heightField)
	case newton.SerializeId.Scene:
		fmt.printfln("  m_sceneCollision:     %v", cir.m_sceneCollision)
	case newton.SerializeId.Usermesh:
		fmt.printfln("  m_paramArray:         %v", cir.m_paramArray)
	case:
		fmt.println("  unknown")
	}
}

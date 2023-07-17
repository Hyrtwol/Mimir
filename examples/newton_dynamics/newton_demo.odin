package main

import "core:fmt"
import newton "../../shared/newton_dynamics"

main :: proc() {
	fmt.print("Newton Dynamics\n")

	fmt.print("Globals:\n")
	fmt.printf("  Version             : %v\n", newton.GetVersion())
	fmt.printf("  FloatSize           : %v\n", newton.GetFloatSize())
	fmt.printf("  MemoryUsed          : %v\n", newton.GetMemoryUsed())

	world := newton.Create()
	defer newton.Destroy(world)

	fmt.print("World:\n")
	fmt.printf("  BodyCount           : %v\n", newton.WorldGetBodyCount(world))
	fmt.printf("  ConstraintCount     : %v\n", newton.WorldGetConstraintCount(world))
	fmt.printf("  BroadphaseAlgorithm : %v\n", newton.GetBroadphaseAlgorithm(world))
	fmt.printf("  ThreadsCount        : %v\n", newton.GetThreadsCount(world))
	fmt.printf("  MaxThreadsCount     : %v\n", newton.GetMaxThreadsCount(world))

	{
		collision := newton.CreateBox(world, 2, 2, 2, 0, nil)
		defer newton.DestroyCollision(collision)

		fmt.printf("  BodyCount           : %v\n", newton.WorldGetBodyCount(world))
		fmt.printf("  ConstraintCount     : %v\n", newton.WorldGetConstraintCount(world))

		fmt.print("Collision:\n")
		fmt.printf("  CollisionType       : %v\n", newton.CollisionGetType(collision))
		fmt.printf("  IsConvexShape       : %v\n", newton.CollisionIsConvexShape(collision))
		fmt.printf("  IsStaticShape       : %v\n", newton.CollisionIsStaticShape(collision))

		{
			cir: newton.NewtonCollisionInfoRecord
			newton.CollisionGetInfo(collision, &cir)
			fmt.print("CollisionInfoRecord:\n")
			fmt.printf("  m_collisionType     : %v\n", cir.m_collisionType)
			fmt.printf("  m_collisionMaterial : %v\n", cir.m_collisionMaterial)
			#partial switch cir.m_collisionType {
			case newton.SerializeId.Box:
				fmt.printf("  m_box:                %v\n", cir.u.m_box)
			case newton.SerializeId.Cone:
				fmt.printf("  m_cone:               %v\n", cir.u.m_cone)
			case newton.SerializeId.Sphere:
				fmt.printf("  m_sphere:             %v\n", cir.u.m_sphere)
			case newton.SerializeId.Capsule:
				fmt.printf("  m_capsule:            %v\n", cir.u.m_capsule)
			case newton.SerializeId.Cylinder:
				fmt.printf("  m_cylinder:           %v\n", cir.u.m_cylinder)
			case newton.SerializeId.Chamfercylinder:
				fmt.printf("  m_chamferCylinder:    %v\n", cir.u.m_chamferCylinder)
			case newton.SerializeId.Convexhull:
				fmt.printf("  m_convexHull:         %v\n", cir.u.m_convexHull)
			case newton.SerializeId.DeformableSolid:
				fmt.printf("  m_deformableMesh:     %v\n", cir.u.m_deformableMesh)
			case newton.SerializeId.Compound:
				fmt.printf("  m_compoundCollision:  %v\n", cir.u.m_compoundCollision)
			case newton.SerializeId.Tree:
				fmt.printf("  m_collisionTree:      %v\n", cir.u.m_collisionTree)
			case newton.SerializeId.Heightfield:
				fmt.printf("  m_heightField:        %v\n", cir.u.m_heightField)
			case newton.SerializeId.Scene:
				fmt.printf("  m_sceneCollision:     %v\n", cir.u.m_sceneCollision)
			case newton.SerializeId.Usermesh:
				fmt.printf("  m_paramArray:         %v\n", cir.u.m_paramArray)
			case:
				fmt.print("  unknown\n")
			}
		}
	}

	fmt.printf("  BodyCount           : %v\n", newton.WorldGetBodyCount(world))
	fmt.printf("  ConstraintCount     : %v\n", newton.WorldGetConstraintCount(world))
	fmt.print("DestroyAllBodies:\n")
	newton.DestroyAllBodies(world)
	fmt.printf("  BodyCount           : %v\n", newton.WorldGetBodyCount(world))
	fmt.printf("  ConstraintCount     : %v\n", newton.WorldGetConstraintCount(world))

	f3: newton.float3
	i3: newton.int3
}

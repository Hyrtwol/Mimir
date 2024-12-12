package main

import "base:intrinsics"
import "core:fmt"
import "core:math/linalg"
import "core:os"
import newton "shared:newton_dynamics"
import "shared:obug"

dump_NewtonCollisionInfoRecord :: proc(collision: ^newton.Collision) {
	cir: newton.CollisionInfoRecord
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
		fmt.printfln("  unknown %v", cir.m_collisionType)
	}
}

run :: proc() -> (exit_code: int) {
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
		fmt.println("CreateBox:")
		collision := newton.CreateBox(world, 2, 2, 2, 0, nil)
		defer newton.DestroyCollision(collision)

		mtx := linalg.identity(newton.float4x4)
		body := newton.CreateDynamicBody(world, collision, &mtx)
		defer newton.DestroyBody(body)

		fmt.printfln("  BodyCount           : %v", newton.WorldGetBodyCount(world))
		fmt.printfln("  ConstraintCount     : %v", newton.WorldGetConstraintCount(world))

		fmt.println("Collision:")
		fmt.printfln("  CollisionType       : %v", newton.CollisionGetType(collision))
		fmt.printfln("  IsConvexShape       : %v", newton.CollisionIsConvexShape(collision))
		fmt.printfln("  IsStaticShape       : %v", newton.CollisionIsStaticShape(collision))
		fmt.printfln("  Mode                : %v", newton.CollisionGetMode(collision))

		dump_NewtonCollisionInfoRecord(collision)

		fmt.println("Body:")
		fmt.printfln("  BodyType            : %v", newton.BodyGetType(body))

		fmt.println("Mesh:")
		mesh := newton.MeshCreateFromCollision(collision)
		defer newton.MeshDestroy(mesh)

		fmt.printfln("  MeshHasNormalChannel   : %v", newton.MeshHasNormalChannel(mesh))
		fmt.printfln("  MeshHasBinormalChannel : %v", newton.MeshHasBinormalChannel(mesh))
		fmt.printfln("  MeshHasUV0Channel      : %v", newton.MeshHasUV0Channel(mesh))
		fmt.printfln("  MeshHasUV1Channel      : %v", newton.MeshHasUV1Channel(mesh))

		/*
		fmt.printfln("  MeshGetPointCount      : %v", newton.MeshGetPointCount(mesh))
		fmt.printfln("  MeshGetTotalFaceCount  : %v", newton.MeshGetTotalFaceCount(mesh))
		fmt.printfln("  MeshGetTotalIndexCount : %v", newton.MeshGetTotalIndexCount(mesh))
		fmt.printfln("  MeshGetVertexCount     : %v", newton.MeshGetVertexCount(mesh))
		newton.MeshTriangulate(mesh)
		fmt.println("Triangulate:")
		*/

		point_count := newton.MeshGetPointCount(mesh)
		fmt.printfln("  MeshGetPointCount      : %v", point_count)
		fmt.printfln("  MeshGetTotalFaceCount  : %v", newton.MeshGetTotalFaceCount(mesh))
		fmt.printfln("  MeshGetTotalIndexCount : %v", newton.MeshGetTotalIndexCount(mesh))
		fmt.printfln("  MeshGetVertexCount     : %v", newton.MeshGetVertexCount(mesh))

		vertex :: struct {
			pos: newton.float3,
			nml: newton.float3,
		}

		vertices := make([]vertex, point_count)
		defer delete(vertices)
		vertex_attrib := 0
		when intrinsics.type_has_field(vertex, "pos") {
			newton.MeshGetVertexChannel(mesh, size_of(vertex), &vertices[0].pos)
			vertex_attrib += 1
		}
		when intrinsics.type_has_field(vertex, "nml") {
			newton.MeshGetNormalChannel(mesh, size_of(vertex), &vertices[0].nml)
			vertex_attrib += 1
		}
		when intrinsics.type_has_field(vertex, "bnl") {
			newton.MeshGetBinormalChannel(mesh, size_of(vertex), &vertices[0].bnl)
			vertex_attrib += 1
		}
		when intrinsics.type_has_field(vertex, "uv0") {
			newton.MeshGetUV0Channel(mesh, size_of(vertex), &vertices[0].uv0)
			vertex_attrib += 1
		}
		when intrinsics.type_has_field(vertex, "uv1") {
			newton.MeshGetUV1Channel(mesh, size_of(vertex), &vertices[0].uv1)
			vertex_attrib += 1
		}
		when intrinsics.type_has_field(vertex, "col") {
			newton.MeshGetVertexColorChannel(mesh, size_of(vertex), &vertices[0].col)
			vertex_attrib += 1
		}
		fmt.printfln("vertex_attrib: %d", vertex_attrib)

		FF :: "% 10.5f"
		FF2 :: "% 8.5f"
		fmt.println("vertices: []vertex = {")
		for vtx in vertices {
			fmt.print("\t{")
			fmt.printf("{{" + FF + ", " + FF + ", " + FF + "}}", expand_values(vtx.pos))
			fmt.print(", ")
			fmt.printf("{{" + FF2 + ", " + FF2 + ", " + FF2 + "}}", expand_values(vtx.nml))
			fmt.println("},")
		}
		fmt.println("}")
		fmt.println()

		fmt.println("indices: [][3]u16 = {")
		for face := newton.MeshGetFirstFace(mesh); face != nil; face = newton.MeshGetNextFace(mesh, face) {
			if !newton.MeshIsFaceOpen(mesh, face) {
				num := newton.MeshGetFaceIndexCount(mesh, face)
				indices := make([]i32, num)
				defer delete(indices)
				newton.MeshGetFacePointIndices(mesh, face, &indices[0])
				fmt.print("\t{")
				for idx, i in indices {
					if i > 0 {fmt.print(", ")}
					fmt.printf("%4d", idx)
				}
				fmt.println("},")
			}
		}
		fmt.println("}")
	}

	fmt.printfln("  BodyCount           : %v", newton.WorldGetBodyCount(world))
	fmt.printfln("  ConstraintCount     : %v", newton.WorldGetConstraintCount(world))

	fmt.println("DestroyAllBodies:")
	newton.DestroyAllBodies(world)
	fmt.printfln("  BodyCount           : %v", newton.WorldGetBodyCount(world))
	fmt.printfln("  ConstraintCount     : %v", newton.WorldGetConstraintCount(world))

	// f3: newton.float3
	// i3: newton.int3
	return
}

main :: proc() {
	when intrinsics.is_package_imported("obug") {
		os.exit(obug.tracked_run(run))
	} else {
		os.exit(run())
	}
}

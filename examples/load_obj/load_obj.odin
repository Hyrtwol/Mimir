package main

import "base:intrinsics"
import "core:fmt"
import "core:io"
import "core:os"
import "core:path/filepath"
import "core:strings"
import oz "shared:objzero"
import "shared:obug"

wprint :: fmt.wprint
wprintln :: fmt.wprintln
wprintf :: fmt.wprintf
wprintfln :: fmt.wprintfln

progressCallback :: proc(filename: cstring, progress: i32) {
	fmt.printf("\rprogress: %d%%", progress)
}

print_indices :: proc(w: io.Writer, indices: []$A) where intrinsics.type_is_numeric(A) {
	wprintfln(w, "indices: [%v]%v = {{", len(indices), type_info_of(A))
	for v, i in indices {
		wprintf(w, "%3d" ,v)
		if i % 8 == 7 {
			wprintln(w, ",")
		} else {
			wprint(w, ", ")
		}
	}
	if len(indices) % 8 < 7 {
		wprintln(w)
	}
	wprintln(w, "}")
}


print_vertices_v1 :: proc(w: io.Writer, model: ^oz.objzModel) {
	FF :: "% 10.5f"
	vertices := oz.get_vertices(model)

	wprintfln(w, "vertices: [%v]float3 = {{", len(vertices))
	for v, i in vertices {
		wprintf(w, "{{" + FF + "," + FF + "," + FF + "}}", v.pos.x, v.pos.y, v.pos.z)
		if i % 4 == 3 {
			wprintln(w, ",")
		} else {
			wprint(w, ", ")
		}

	}
	wprintln(w, "}")

	if .OBJZ_FLAG_NORMALS in model.flags {
		wprintln(w, "")
		wprintfln(w, "normals: [%v]float3 = {{", len(vertices))
		for v, i in vertices {
			wprintf(w, "{{" + FF + "," + FF + "," + FF + "}}", v.normal.x, v.normal.y, v.normal.z)
			if i % 4 == 3 {
				wprintln(w, ",")
			} else {
				wprint(w, ", ")
			}
		}
		wprintln(w, "}")
	}
}

print_vertices :: proc(w: io.Writer, model: ^oz.objzModel) {
	FF :: "% 10.5f"
	vertices := oz.get_vertices(model)

	wprintfln(w, "vertices: [%v]vertex = {{", len(vertices))
	for v in vertices {

		wprint(w, "{")
		wprintf(w, "{{" + FF + "," + FF + "," + FF + "}}, ", v.pos.x, v.pos.y, v.pos.z)
		wprintf(w, "{{" + FF + "," + FF + "}}, ", v.texcoord.x, v.texcoord.y)
		wprintf(w, "{{" + FF + "," + FF + "," + FF + "}}", v.normal.x, v.normal.y, v.normal.z)

		wprintln(w, "},")

	}
	wprintln(w, "}")
}

printModel :: proc(w: io.Writer, model: ^oz.objzModel) {

	mats := oz.get_materials(model)
	for &mat, i in mats {
		wprintfln(w, "Material %u '%s'", i, cstring(&mat.name[0]))
		wprintfln(w, "   opacity: %v", mat.opacity)
		wprintfln(w, "   ambient: %v", mat.ambient)
		wprintfln(w, "   diffuse: %v", mat.diffuse)
		wprintfln(w, "   emission: %v", mat.emission)
		wprintfln(w, "   specular: %v", mat.specular)
		wprintfln(w, "   specularExponent: %v", mat.specularExponent)
		if (mat.ambientTexture[0] != 0) {
			wprintfln(w, "   ambientTexture: %s", cstring(&mat.ambientTexture[0]))
		}
		if (mat.bumpTexture[0] != 0) {
			wprintfln(w, "   bumpTexture: %s", cstring(&mat.bumpTexture[0]))
		}
		if (mat.diffuseTexture[0] != 0) {
			wprintfln(w, "   diffuseTexture: %s", cstring(&mat.diffuseTexture[0]))
		}
		if (mat.emissionTexture[0] != 0) {
			wprintfln(w, "   emissionTexture: %s", cstring(&mat.emissionTexture[0]))
		}
		if (mat.specularTexture[0] != 0) {
			wprintfln(w, "   specularTexture: %s", cstring(&mat.specularTexture[0]))
		}
		if (mat.specularExponentTexture[0] != 0) {
			wprintfln(w, "   specularExponentTexture: %s", cstring(&mat.specularExponentTexture[0]))
		}
		if (mat.opacityTexture[0] != 0) {
			wprintfln(w, "   opacityTexture: %s", cstring(&mat.opacityTexture[0]))
		}
	}

	objects := oz.get_objects(model)
	meshes := oz.get_meshes(model)
	for &object, i in objects {
		wprintfln(w, "// Object: %d '%s', %d triangles, %d vertices, %d meshes", i, cstring(&object.name[0]), object.numIndices / 3, object.numVertices, object.numMeshes)
		for j in 0 ..< object.numMeshes {
			mesh := &meshes[object.firstMesh + j]
			//wprintf(w, "   Mesh %u: '%s' material, %u triangles\n", j, mesh.materialIndex < 0 ? "<empty>" : mats[mesh.materialIndex].name, mesh.numIndices / 3);
			wprintf(w, "//   Mesh %d: ", j)
			if mesh.materialIndex < 0 {
				wprint(w, "<empty>", mesh.materialIndex)
			} else {
				wprintf(w, "'%s'", cstring(&mats[mesh.materialIndex].name[0]))
			}
			wprintfln(w, " material, %d triangles", mesh.numIndices / 3)
		}
	}

	wprintln(w, "")
	wprintln(w, "float2 :: [2]f32")
	wprintln(w, "float3 :: [3]f32")
	wprintln(w, "")
	wprintln(w, "vertex :: struct {")
	wprintln(w, "\tpos:      float3,")
	if .OBJZ_FLAG_TEXCOORDS in model.flags {
		wprintln(w, "\ttexcoord: float2,")
	}
	if .OBJZ_FLAG_NORMALS in model.flags {
		wprintln(w, "\tnormal:   float3,")
	}
	wprintln(w, "}")
	wprintln(w, "")

	print_vertices(w, model)

	wprintln(w, "")
	if .OBJZ_FLAG_INDEX32 in model.flags {
		indices_u32 := oz.get_indices_u32(model)
		print_indices(w, indices_u32)
	} else {
		indices_u16 := oz.get_indices_u16(model)
		print_indices(w, indices_u16)
	}
	wprintln(w, "")

	wprintln(w, "// model:")
	wprintfln(w, "// %v flags", model.flags)
	wprintfln(w, "// % 8d objects", model.numObjects)
	wprintfln(w, "// % 8d materials", model.numMaterials)
	wprintfln(w, "// % 8d meshes", model.numMeshes)
	wprintfln(w, "// % 8d vertices", model.numVertices)
	wprintfln(w, "// % 8d triangles (%d)", model.numIndices / 3, model.numIndices)

	//wprintln(w, "*/")
}

//cube :: "../data/models/cube/cube.obj"
//gazebo :: "../data/models/gazebo/gazebo.obj"
// input_path :: "../data/models/cow/cow.obj"
//output_path :: "load_obj.txt"

run :: proc() -> (exit_code: int) {
	fmt.println("objzero Reader")

	// gazebo, cow, cube
	input_path := "../data/models/cube/cube.obj"

	input_dir := filepath.dir(input_path, context.temp_allocator)
	input_name := filepath.stem(input_path)

	output_path := fmt.tprintf("%s/%s.odin", input_dir, input_name)
	output_path = filepath.clean(output_path, context.temp_allocator) or_else panic("filepath.clean")
	output_path = filepath.abs(output_path, context.temp_allocator) or_else panic("filepath.abs")

	clean_path := filepath.clean(input_path, context.temp_allocator) or_else panic("filepath.clean")
	clean_path = filepath.abs(clean_path, context.temp_allocator) or_else panic("filepath.abs")
	obj_file := strings.clone_to_cstring(clean_path, context.temp_allocator) or_else panic("strings.clone_to_cstring")

	fmt.printfln("reading %s", obj_file)
	fmt.printfln("writing %s", output_path)

	fd, fe := os.open(output_path, os.O_WRONLY | os.O_CREATE | os.O_TRUNC, 0)
	if fe != os.ERROR_NONE {return}
	defer os.close(fd)

	w := io.to_writer(os.stream_from_handle(fd))

	wprintfln(w, "package %s", input_name)
	wprintln(w)
	wprintfln(w, "// Object %s", obj_file)
	oz.objz_setProgress(progressCallback)
	obj := oz.objz_load(obj_file)
	if obj == nil {
		fmt.println("error:", oz.objz_getError())
		exit_code = -1
		return
	}
	defer oz.objz_destroy(obj)

	fmt.println()
	printModel(w, obj)

	fmt.println("Done.")
	return
}

main :: proc() {
	when intrinsics.is_package_imported("obug") {
		os.exit(obug.tracked_run(run))
	} else {
		os.exit(run())
	}
}

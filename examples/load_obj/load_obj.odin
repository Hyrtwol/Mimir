package main

import "base:intrinsics"
import "core:fmt"
import "core:io"
import "core:math/linalg"
import "core:os"
import "core:path/filepath"
import "core:strings"
import oz "shared:objzero"
import "shared:obug"

VERTEX_MODE :: 0
FLOAT1 :: "f32"
when VERTEX_MODE == 1 {
	FLOAT2 :: "float2"
	FLOAT3 :: "float3"
} else {
	FLOAT2 :: "[2]f32"
	FLOAT3 :: "[3]f32"
}
VERTEX_ELEM :: "\t%-8v : %v,"
MAT_ELEM :: "\t%-16v : %v,"

progressCallback :: proc(filename: cstring, progress: i32) {
	fmt.printf("\rprogress: %3d%% %s", progress, filename)
}

print_indices :: proc(w: io.Writer, indices: []$A) where intrinsics.type_is_numeric(A) {
	//fmt.wprintfln(w, "indices: [%v]%v = {{", len(indices), type_info_of(A))
	fmt.wprintfln(w, "indices: []%v = {{", type_info_of(A), flush = false)
	total := len(indices) - 1
	for v, i in indices {
		fmt.wprintf(w, "%4d", v, flush = false)
		if i % 3 == 2 {
			fmt.wprintln(w, ",", flush = false)
		} else {
			fmt.wprint(w, ", ", flush = false)
		}

		progressCallback("indices", i32(i * 100 / total))
	}
	if len(indices) % 3 != 0 {
		fmt.wprintln(w, flush = false)
	}
	fmt.wprintln(w, "}", flush = true)
	fmt.println()
}

print_triangles :: proc(w: io.Writer, indices: []$A) where intrinsics.type_is_numeric(A) {
	//fmt.wprintfln(w, "indices: [%v]%v = {{", len(indices), type_info_of(A))
	fmt.wprintfln(w, "indices: [][3]%v = {{", type_info_of(A), flush = false)
	total := len(indices)
	for i := 0; i < total - 2; i += 3 {
		fmt.wprintfln(w, "\t{{%4d, %4d, %4d}},", indices[i], indices[i + 1], indices[i + 2], flush = false)

		progressCallback("triangles", i32(i * 100 / total))
	}
	fmt.wprintln(w, "}", flush = true)
	progressCallback("triangles", 100)
	fmt.println()
}


print_vertices_v1 :: proc(w: io.Writer, model: ^oz.objzModel) {
	FF :: "% 10.5f"
	vertices := oz.get_default_vertices(model)

	fmt.wprintfln(w, "vertices: [%v]float3 = {{", len(vertices))
	for v, i in vertices {
		fmt.wprintf(w, "{{" + FF + "," + FF + "," + FF + "}}", v.pos.x, v.pos.y, v.pos.z)
		if i % 4 == 3 {
			fmt.wprintln(w, ",")
		} else {
			fmt.wprint(w, ", ")
		}

	}
	fmt.wprintln(w, "}")

	if .OBJZ_FLAG_NORMALS in model.flags {
		fmt.wprintln(w, "")
		fmt.wprintfln(w, "normals: [%v]float3 = {{", len(vertices))
		for v, i in vertices {
			fmt.wprintf(w, "{{" + FF + "," + FF + "," + FF + "}}", v.normal.x, v.normal.y, v.normal.z)
			if i % 4 == 3 {
				fmt.wprintln(w, ",")
			} else {
				fmt.wprint(w, ", ")
			}
		}
		fmt.wprintln(w, "}")
	}
}

print_vertices :: proc(w: io.Writer, model: ^oz.objzModel) {
	FF :: "% 10.5f"
	FF2 :: "% 8.5f"
	vertices := oz.get_default_vertices(model)

	do_texcoord := .OBJZ_FLAG_TEXCOORDS in model.flags
	do_normals := .OBJZ_FLAG_NORMALS in model.flags

	//fmt.wprintfln(w, "vertices: [%v]vertex = {{", len(vertices))
	fmt.wprintln(w, "vertices: []vertex = {", flush = false)
	total := len(vertices) - 1
	for &v, i in vertices {

		fmt.wprint(w, "\t{", flush = false)
		fmt.wprintf(w, "{{" + FF + "," + FF + "," + FF + "}}", v.pos.x, v.pos.y, v.pos.z, flush = false)
		if do_texcoord {fmt.wprintf(w, ", " + "{{" + FF2 + "," + FF2 + "}}", v.texcoord.x, v.texcoord.y, flush = false)}
		if do_normals {
			n := linalg.normalize(v.normal)
			fmt.wprintf(w, ", " + "{{" + FF2 + "," + FF2 + "," + FF2 + "}}", n.x, n.y, n.z, flush = false)
		}
		fmt.wprintln(w, "},", flush = false)

		progressCallback("vertices", i32(i * 100 / total))
	}
	fmt.wprintln(w, "}", flush = true)
	fmt.println()
}

MAT_COMPACT :: false

print_materials :: proc(w: io.Writer, model: ^oz.objzModel) {
	{
		fmt.wprintln(w, "material :: struct {", flush = false)
		fmt.wprintfln(w, MAT_ELEM, "name", "string", flush = false)
		fmt.wprintfln(w, MAT_ELEM, "ambient", FLOAT3, flush = false)
		fmt.wprintfln(w, MAT_ELEM, "diffuse", FLOAT3, flush = false)
		fmt.wprintfln(w, MAT_ELEM, "emission", FLOAT3, flush = false)
		fmt.wprintfln(w, MAT_ELEM, "specular", FLOAT3, flush = false)
		fmt.wprintfln(w, MAT_ELEM, "specularExponent", FLOAT1, flush = false)
		fmt.wprintfln(w, MAT_ELEM, "opacity", FLOAT1, flush = false)

		fmt.wprintln(w, "}", flush = false)
		fmt.wprintln(w, "")
	}
	mats := oz.get_materials(model)
	fmt.wprintln(w, "materials: []material = {", flush = false)
	total := len(mats)
	for &mat, i in mats {
		FF :: "%.5f"
		IND :: "\t"
		fmt.wprintln(w, IND + "{", flush = false)
		fmt.wprintfln(w, IND + IND + "name     = \"%s\",", cstring(&mat.name[0]), flush = false)
		fmt.wprintfln(w, IND + IND + "ambient  = {{" + FF + ", " + FF + ", " + FF + "}},", mat.ambient.x, mat.ambient.y, mat.ambient.z, flush = false)
		fmt.wprintfln(w, IND + IND + "diffuse  = {{" + FF + ", " + FF + ", " + FF + "}},", mat.diffuse.x, mat.diffuse.y, mat.diffuse.z, flush = false)
		fmt.wprintfln(w, IND + IND + "emission = {{" + FF + ", " + FF + ", " + FF + "}},", mat.emission.x, mat.emission.y, mat.emission.z, flush = false)
		fmt.wprintfln(w, IND + IND + "specular = {{" + FF + ", " + FF + ", " + FF + "}},", mat.specular.x, mat.specular.y, mat.specular.z, flush = false)
		fmt.wprintfln(w, IND + IND + "specularExponent = " + FF + ",", mat.specularExponent, flush = false)
		fmt.wprintfln(w, IND + IND + "opacity  = " + FF + ",", mat.opacity, flush = false)

		fmt.wprintln(w, IND + "},", flush = false)
		progressCallback("materials", i32((i + 1) * 100 / total))
	}
	fmt.wprintln(w, "}", flush = true)
	fmt.println()
}

printModel :: proc(w: io.Writer, model: ^oz.objzModel) {

	fmt.wprintln(w, "", flush = false)
	fmt.wprintln(w, "// model:", flush = false)
	//fmt.wprintfln(w, "// %v flags", model.flags)
	fmt.wprint(w, "// flags     ", flush = false)
	for f in model.flags {fmt.wprintf(w, " %v", f, flush = false)}
	fmt.wprintln(w, flush = false)
	fmt.wprintfln(w, "// objects   % 8d", model.numObjects, flush = false)
	fmt.wprintfln(w, "// materials % 8d", model.numMaterials, flush = false)
	fmt.wprintfln(w, "// meshes    % 8d", model.numMeshes, flush = false)
	fmt.wprintfln(w, "// vertices  % 8d", model.numVertices, flush = false)
	fmt.wprintfln(w, "// triangles % 8d (%d)", model.numIndices / 3, model.numIndices, flush = false)
	fmt.wprintln(w, "")

	when VERTEX_MODE == 1 {
		fmt.wprintln(w, "")
		fmt.wprintln(w, "float2 :: [2]f32")
		fmt.wprintln(w, "float3 :: [3]f32")
	}

	mats := oz.get_materials(model)
	if len(mats) > 0 {
		print_materials(w, model)
		fmt.wprintln(w, "")
	}

	{
		objects := oz.get_objects(model)
		meshes := oz.get_meshes(model)
		for &object, i in objects {
			fmt.wprintfln(w, "// Object: %d '%s', %d triangles, %d vertices, %d meshes", i, cstring(&object.name[0]), object.numIndices / 3, object.numVertices, object.numMeshes)
			for j in 0 ..< object.numMeshes {
				mesh := &meshes[object.firstMesh + j]
				//wprintf(w, "   Mesh %u: '%s' material, %u triangles\n", j, mesh.materialIndex < 0 ? "<empty>" : mats[mesh.materialIndex].name, mesh.numIndices / 3);
				fmt.wprintf(w, "//   Mesh %d: ", j, flush = false)
				if mesh.materialIndex < 0 {
					fmt.wprint(w, "<empty>", mesh.materialIndex, flush = false)
				} else {
					fmt.wprintf(w, "'%s'", cstring(&mats[mesh.materialIndex].name[0]), flush = false)
				}
				fmt.wprintfln(w, " material, %d triangles", mesh.numIndices / 3)
			}
		}
	}

	{
		fmt.wprintln(w, "", flush = false)
		fmt.wprintln(w, "vertex :: struct {", flush = false)
		fmt.wprintfln(w, VERTEX_ELEM, "pos", FLOAT3, flush = false)
		if .OBJZ_FLAG_TEXCOORDS in model.flags {
			fmt.wprintfln(w, VERTEX_ELEM, "texcoord", FLOAT2, flush = false)
		}
		if .OBJZ_FLAG_NORMALS in model.flags {
			fmt.wprintfln(w, VERTEX_ELEM, "normal", FLOAT3, flush = false)
		}
		fmt.wprintln(w, "}", flush = false)
		fmt.wprintln(w, "", flush = false)

		fmt.wprintfln(w, "vertex_flags :: 0b%8b", transmute(u32)model.flags, flush = false)
		fmt.wprintln(w, "")
	}

	print_vertices(w, model)

	fmt.wprintln(w, "")
	if .OBJZ_FLAG_INDEX32 in model.flags {
		indices_u32 := oz.get_indices_u32(model)
		//print_indices(w, indices_u32)
		print_triangles(w, indices_u32)
	} else {
		indices_u16 := oz.get_indices_u16(model)
		//print_indices(w, indices_u16)
		print_triangles(w, indices_u16)
	}
}

//output_path :: "load_obj.txt"

run :: proc() -> (exit_code: int) {
	fmt.println("objzero Reader")

	input_paths: []string = {
		"../data/models/cow/cow.obj",
		"../data/models/cube/cube.obj",
		"../data/models/gazebo/gazebo.obj",
		"../data/models/crisscross/crisscross.obj",
	}
	for input_path in input_paths {

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

		fmt.wprintfln(w, "package %s", input_name)
		fmt.wprintln(w)
		fmt.wprintfln(w, "// %s", filepath.base(input_path))
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
	}
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

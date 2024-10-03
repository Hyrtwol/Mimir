package main

import oz "shared:objzero"
import "base:intrinsics"
import "core:fmt"
import "core:io"
import "core:os"
import "core:path/filepath"
import "core:strings"
import "libs:obug"

//input_path :: "../data/models/cube.obj"
input_path :: "../data/models/gazebo.obj"
output_path :: "load_obj.txt"

wprintf :: fmt.wprintf
wprintfln :: fmt.wprintfln

progressCallback :: proc(filename: cstring, progress: i32) {
	fmt.printf("\rprogress: %d%%", progress)
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
		wprintfln(w, "Object: %d '%s', %d triangles, %d vertices, %d meshes", i, cstring(&object.name[0]), object.numIndices / 3, object.numVertices, object.numMeshes)
		for j in 0 ..< object.numMeshes {
			mesh := &meshes[object.firstMesh + j]
			//wprintf(w, "   Mesh %u: '%s' material, %u triangles\n", j, mesh.materialIndex < 0 ? "<empty>" : mats[mesh.materialIndex].name, mesh.numIndices / 3);
			wprintf(w, "   Mesh %d: ", j)
			if mesh.materialIndex < 0 {
				wprintf(w, "<empty>")
			} else {
				wprintf(w, "'%s'", cstring(&mats[mesh.materialIndex].name[0]))
			}
			wprintfln(w, " material, %d triangles", mesh.numIndices / 3)
		}
	}
	wprintfln(w, "%d objects", model.numObjects)
	wprintfln(w, "%d materials", model.numMaterials)
	wprintfln(w, "%d meshes", model.numMeshes)
	wprintfln(w, "%d vertices", model.numVertices)
	wprintfln(w, "%d triangles", model.numIndices / 3)
}

run :: proc() {
	fmt.println("objzero Reader")

	clean_path := filepath.clean(input_path, context.temp_allocator)
	clean_path, _ = filepath.abs(clean_path, context.temp_allocator)
	obj_file := strings.clone_to_cstring(clean_path, context.temp_allocator)

	fmt.printfln("writing %s", output_path)
	fd, fe := os.open(output_path, os.O_WRONLY | os.O_CREATE | os.O_TRUNC, 0)
	if fe != os.ERROR_NONE {return}
	defer os.close(fd)

	w := io.to_writer(os.stream_from_handle(fd))

	wprintfln(w, "Object %s", obj_file)
	fmt.printfln("reading %s", obj_file)
	oz.objz_setProgress(progressCallback)
	obj := oz.objz_load(obj_file)
	if obj == nil {
		fmt.println("error:", oz.objz_getError())
		return
	}
	defer oz.objz_destroy(obj)

	fmt.println()
	printModel(w, obj)

	fmt.println("Done.")
}

main :: proc() {
	when intrinsics.is_package_imported("obug") {
		obug.tracked_run(run)
	} else {
		run()
	}
}

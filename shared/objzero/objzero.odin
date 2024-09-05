package objzero

foreign import "objzero.lib"

import _c "core:c"
import "core:slice"

OBJZ_NAME_MAX :: 64

size_t :: _c.size_t
char64 :: [64]_c.char
float2 :: [2]f32
float3 :: [3]f32

default_vertex :: struct {
	pos:      float3,
	texcoord: float2,
	normal:   float3,
}

objzIndexFormat :: enum u32 {
	// OBJZ_INDEX_FORMAT_AUTO: objzModel indices are uint32_t if any index > UINT16_MAX, otherwise they are uint16_t.
	OBJZ_INDEX_FORMAT_AUTO = 0,
	// OBJZ_INDEX_FORMAT_U32: objzModel indices are always uint32_t.
	OBJZ_INDEX_FORMAT_U32  = 1,
}

objzReallocFunc :: #type proc(ptr: rawptr, size: size_t) -> rawptr
objzProgressFunc :: #type proc(filename: cstring, percent: i32)

objzMaterial :: struct {
	name:                    char64,
	ambient:                 float3,
	diffuse:                 float3,
	emission:                float3,
	specular:                float3,
	specularExponent:        f32,
	opacity:                 f32,
	ambientTexture:          char64,
	bumpTexture:             char64,
	diffuseTexture:          char64,
	emissionTexture:         char64,
	specularTexture:         char64,
	specularExponentTexture: char64,
	opacityTexture:          char64,
}

objzMesh :: struct {
	materialIndex: i32,
	firstIndex:    u32,
	numIndices:    u32,
}

objzObject :: struct {
	name:        char64,
	firstMesh:   u32,
	numMeshes:   u32,
	// If you want per-object vertices and indices, use these and subtract firstVertex from all the objzModel indices in firstIndex to firstIndex + numIndices - 1 range.
	firstIndex:  u32,
	numIndices:  u32,
	firstVertex: u32,
	numVertices: u32,
}

// OBJZ_FLAG_TEXCOORDS :: (1 << 0)
// OBJZ_FLAG_NORMALS :: (1 << 1)
// OBJZ_FLAG_INDEX32 :: (1 << 2)

objzModelFlag :: enum u32 {
	OBJZ_FLAG_TEXCOORDS,
	OBJZ_FLAG_NORMALS,
	OBJZ_FLAG_INDEX32,
}
objzModelFlags :: bit_set[objzModelFlag;u32]

objzModel :: struct {
	flags:        u32,
	// u32 if OBJZ_FLAG_INDEX32 flag is set, otherwise u16.
	// See: objz_setIndexFormat
	indices:      rawptr,
	numIndices:   u32,
	materials:    ^objzMaterial,
	numMaterials: u32,
	meshes:       ^objzMesh,
	numMeshes:    u32,
	objects:      ^objzObject,
	numObjects:   u32,
	// See: objz_setVertexFormat
	vertices:     rawptr,
	numVertices:  u32,
}

@(default_calling_convention = "c")
foreign objzero {

	objz_setRealloc :: proc(realloc: objzReallocFunc) ---

	objz_setProgress :: proc(progress: objzProgressFunc) ---

	// OBJZ_INDEX_FORMAT_AUTO: objzModel indices are uint32_t if any index > UINT16_MAX, otherwise they are uint16_t.
	// OBJZ_INDEX_FORMAT_U32: objzModel indices are always uint32_t.
	// Default is OBJZ_INDEX_FORMAT_AUTO.
	objz_setIndexFormat :: proc(format: objzIndexFormat = .OBJZ_INDEX_FORMAT_AUTO) ---

	// Default vertex data structure looks like this:

	// Vertex :: struct {
	// 	pos: float3,
	// 	texcoord: float2,
	// 	normal: float3,
	// }

	// Which is equivalent to:

	// objz_setVertexFormat(sizeof(Vertex), offsetof(Vertex, pos), offsetof(Vertex, texcoord), offsetof(Vertex, normal));

	// texcoordOffset - optional: set to SIZE_MAX to ignore
	// normalOffset - optional: set to SIZE_MAX to ignore

	objz_setVertexFormat :: proc(stride: size_t, positionOffset: size_t, texcoordOffset: size_t, normalOffset: size_t) ---

	objz_load :: proc(filename: cstring) -> ^objzModel ---

	objz_destroy :: proc(model: ^objzModel) ---

	objz_getError :: proc() -> cstring ---

}

get_materials :: #force_inline proc "contextless" (model: ^objzModel) -> []objzMaterial {
	return slice.from_ptr(model.materials, int(model.numMaterials))
}

get_objects :: #force_inline proc "contextless" (model: ^objzModel) -> []objzObject {
	return slice.from_ptr(model.objects, int(model.numObjects))
}

get_meshes :: #force_inline proc "contextless" (model: ^objzModel) -> []objzMesh {
	return slice.from_ptr(model.meshes, int(model.numMeshes))
}

// get_vertices :: #force_inline proc "contextless" (model: ^objzModel) -> []default_vertex {
// 	return slice.from_ptr(model.vertices, int(model.numVertices))
// }

// get_indices :: #force_inline proc "contextless" (model: ^objzModel) -> []i32 {
// 	return slice.from_ptr(model.indices, int(model.numIndices))
// }

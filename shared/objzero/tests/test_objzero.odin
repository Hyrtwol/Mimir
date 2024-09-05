package test_newton

import oz ".."
import "core:fmt"
import "core:testing"
import "shared:ounit"

expect_size :: ounit.expect_size
expect_value :: ounit.expect_value
expect_int :: ounit.expect_int
expect_flags :: ounit.expect_flags

@(test)
size_of_vectors :: proc(t: ^testing.T) {
	expect_size(t, oz.float2, 8)
	expect_size(t, oz.float3, 12)
	expect_size(t, oz.char64, 64)
}

@(test)
size_of_structs :: proc(t: ^testing.T) {
	expect_size(t, oz.objzMaterial, 568)
	expect_size(t, oz.objzMesh, 12)
	expect_size(t, oz.objzObject, 88)
	expect_size(t, oz.objzModel, 88)
}

@(test)
verify_objzModelFlag :: proc(t: ^testing.T) {
	expect_flags(t, oz.objzModelFlags{.OBJZ_FLAG_TEXCOORDS}, 1 << 0)
	expect_flags(t, oz.objzModelFlags{.OBJZ_FLAG_NORMALS}, 1 << 1)
	expect_flags(t, oz.objzModelFlags{.OBJZ_FLAG_INDEX32}, 1 << 2)
}

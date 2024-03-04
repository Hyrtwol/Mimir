package xatlas

import "core:bytes"
import "core:fmt"
import "core:runtime"
import "core:testing"
import "shared:ounit"

@(test)
verify_sizes :: proc(t: ^testing.T) {
	using ounit
	expect_size(t, xatlasChart, 24)
	expect_size(t, xatlasChart, 24)
	expect_size(t, xatlasVertex,20)
	expect_size(t, xatlasMesh,40)
	expect_size(t, xatlasAtlas,48)
	expect_size(t, xatlasMeshDecl, 96)
	expect_size(t, xatlasUvMeshDecl,48)
	expect_size(t, xatlasChartOptions, 48)
	expect_size(t, xatlasPackOptions, 24)
}

@(test)
can_construct :: proc(t: ^testing.T) {
	atlas := xatlasCreate()
	defer xatlasDestroy(atlas)

	testing.expect(t, atlas != nil)
}

@(test)
add_mesh :: proc(t: ^testing.T) {
	atlas := xatlasCreate()
	defer xatlasDestroy(atlas)
	assert(atlas != nil)

	// act:= Z80_MAXIMUM_CYCLES
	// exp:= 18446744073709551585
	// testing.expect(t, act == exp, fmt.tprintf("%v (should be: %v)", act, exp))
}

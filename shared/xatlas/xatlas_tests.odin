package xatlas

import "core:bytes"
import "core:fmt"
import "core:runtime"
import "core:testing"

@(test)
verify_sizes :: proc(t: ^testing.T) {
	act, exp: u32

	act = size_of(xatlasChart)
	exp = 24
	testing.expect(t, act == exp, fmt.tprintf("%v (should be: %v)", act, exp))

	act = size_of(xatlasVertex)
	exp = 20
	testing.expect(t, act == exp, fmt.tprintf("%v (should be: %v)", act, exp))

	act = size_of(xatlasMesh)
	exp = 40
	testing.expect(t, act == exp, fmt.tprintf("%v (should be: %v)", act, exp))

	act = size_of(xatlasAtlas)
	exp = 48
	testing.expect(t, act == exp, fmt.tprintf("%v (should be: %v)", act, exp))

	act = size_of(xatlasMeshDecl)
	exp = 96
	testing.expect(t, act == exp, fmt.tprintf("%v (should be: %v)", act, exp))

	act = size_of(xatlasUvMeshDecl)
	exp = 48
	testing.expect(t, act == exp, fmt.tprintf("%v (should be: %v)", act, exp))

	act = size_of(xatlasChartOptions)
	exp = 48
	testing.expect(t, act == exp, fmt.tprintf("%v (should be: %v)", act, exp))

	act = size_of(xatlasPackOptions)
	exp = 24
	testing.expect(t, act == exp, fmt.tprintf("%v (should be: %v)", act, exp))
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

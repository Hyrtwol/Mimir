package test_lightwave

//import "core:bytes"
//import "core:fmt"
//import "core:runtime"
import "core:testing"
//import "shared:ounit"
import lw ".."

box :: "../data/models/box.lwo"

@(private)
expect_u32 :: proc(t: ^testing.T, act, exp: u32) {
	testing.expectf(t, act == exp, "0x%8X (should be: 0x8X)", act, exp)
}
@(private)
expect_i32 :: proc(t: ^testing.T, act, exp: i32) {
	testing.expectf(t, act == exp, "0x%8X (should be: 0x8X)", act, exp)
}
@(private)
expect_it :: proc {
	expect_u32,
	expect_i32,
}

@(test)
verify_lwids :: proc(t: ^testing.T) {
	expect_it(t, lw.ID_FORM, lw.LWID_('F', 'O', 'R', 'M'))
	expect_it(t, lw.ID_LWO2, lw.LWID_('L', 'W', 'O', '2'))
	expect_it(t, lw.ID_LWOB, lw.LWID_('L', 'W', 'O', 'B'))
	expect_it(t, lw.ID_LAYR, lw.LWID_('L', 'A', 'Y', 'R'))
}

@(test)
can_construct :: proc(t: ^testing.T) {
	fail_id: u32 = 0
	fail_pos: i32 = 0
	obj := lw.lwGetObject(box, &fail_id, &fail_pos)
	defer if obj != nil {lw.lwFreeObject(obj)}

	testing.expectf(t, obj != nil, "obj is nil: %v # %v", fail_id, fail_pos)
	expect_it(t, fail_id, 0)
	expect_it(t, fail_pos, 0)

	//fmt.printf("lwo %v\n", obj)
	//fmt.printf("layer %v\n", obj.layer)
}

@(test)
load_box :: proc(t: ^testing.T) {
	act, exp: i32

	fail_id: u32 = 0
	fail_pos: i32 = 0
	obj := lw.lwGetObject(box, &fail_id, &fail_pos)
	defer if obj != nil {lw.lwFreeObject(obj)}

	testing.expectf(t, obj != nil, "obj is nil: %v # %v", fail_id, fail_pos)
	expect_it(t, fail_id, 0)
	expect_it(t, fail_pos, 0)

	expect_it(t, obj.nlayers, 1)
	expect_it(t, obj.nsurfs, 1)
	expect_it(t, obj.nenvs, 0)
	expect_it(t, obj.nclips, 0)

	testing.expectf(t, obj.layer != nil, "obj.layer is nil: %v # %v", fail_id, fail_pos)
	//fmt.printf("layer %v\n", obj.layer)

	expect_it(t, obj.layer^.point.count, 8)
	expect_it(t, obj.layer^.polygon.count, 6)
}

package test_misc

import "base:intrinsics"

@(test)
offset_ptr_u8 :: proc(t: ^testing.T) {
	buf: []u8 = {100, 101, 102, 103}

	p0, p1, p2: ^u8

	p0 = &buf[0]

	p1 = (^u8)(uintptr(p0) + 1)

	idx := 2
	p2 = (^u8)(uintptr(p0) + uintptr(idx))

	expect_value(t, p0, &buf[0])
	expect_value(t, p0^, 100)
	expect_value(t, p1, &buf[1])
	expect_value(t, p1^, 101)
	expect_value(t, p2, &buf[2])
	expect_value(t, p2^, 102)
	expect_value(t, raw_data(buf), &buf[0])
}

@(test)
offset_ptr_u32 :: proc(t: ^testing.T) {
	buf: []u32 = {100, 101, 102, 103}

	p0, p1, p2: ^u32

	p0 = &buf[0]

	p1 = (^u32)(uintptr(p0) + size_of(u32))

	idx := 2
	p2 = (^u32)(uintptr(p0) + uintptr(size_of(u32) * idx))

	expect_value(t, p0, &buf[0])
	expect_value(t, p0^, 100)
	expect_value(t, p1, &buf[1])
	expect_value(t, p1^, 101)
	expect_value(t, p2, &buf[2])
	expect_value(t, p2^, 102)
	expect_value(t, raw_data(buf), &buf[0])
}

@(test)
intrinsics_ptr_offset_u8 :: proc(t: ^testing.T) {
	buf: []u8 = {100, 101, 102, 103}
	idx := 2
	p0 := &buf[0]
	p2 := &buf[2]
	expect_value(t, intrinsics.ptr_offset(p0, idx), p2)
}

@(test)
intrinsics_ptr_offset_u32 :: proc(t: ^testing.T) {
	buf: []u32 = {100, 101, 102, 103}
	idx := 2
	p0 := &buf[0]
	p2 := &buf[2]
	expect_value(t, intrinsics.ptr_offset(p0, idx), p2)
}

@(test)
intrinsics_ptr_sub_u8 :: proc(t: ^testing.T) {
	buf: []u8 = {100, 101, 102, 103}
	p1 := &buf[1]
	p3 := &buf[3]
	expect_value(t, intrinsics.ptr_sub(p3, p1), 2)
}

@(test)
intrinsics_ptr_sub_u32 :: proc(t: ^testing.T) {
	buf: []u32 = {100, 101, 102, 103}
	p1 := &buf[1]
	p3 := &buf[3]
	expect_value(t, intrinsics.ptr_sub(p3, p1), 2)
}

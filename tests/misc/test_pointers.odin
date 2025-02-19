package test_misc

import "base:intrinsics"
import _t "core:testing"

@(test)
offset_ptr_u8 :: proc(t: ^T) {
	buf: []u8 = {100, 101, 102, 103}

	p0, p1, p2, p3: ^u8

	p0 = &buf[0]

	p1 = (^u8)(uintptr(p0) + 1)

	idx := 2
	p2 = (^u8)(uintptr(p0) + uintptr(idx))

	_t.expect_value(t, p0, &buf[0])
	_t.expect_value(t, p0^, 100)
	_t.expect_value(t, p1, &buf[1])
	_t.expect_value(t, p1^, 101)
	_t.expect_value(t, p2, &buf[2])
	_t.expect_value(t, p2^, 102)
	_t.expect_value(t, raw_data(buf), &buf[0])
}

@(test)
offset_ptr_u32 :: proc(t: ^T) {
	buf: []u32 = {100, 101, 102, 103}

	p0, p1, p2, p3: ^u32

	p0 = &buf[0]

	p1 = (^u32)(uintptr(p0) + size_of(u32))

	idx := 2
	p2 = (^u32)(uintptr(p0) + uintptr(size_of(u32) * idx))

	_t.expect_value(t, p0, &buf[0])
	_t.expect_value(t, p0^, 100)
	_t.expect_value(t, p1, &buf[1])
	_t.expect_value(t, p1^, 101)
	_t.expect_value(t, p2, &buf[2])
	_t.expect_value(t, p2^, 102)
	_t.expect_value(t, raw_data(buf), &buf[0])
}

@(test)
intrinsics_ptr_offset_u8 :: proc(t: ^T) {
	buf: []u8 = {100, 101, 102, 103}
	idx := 2
	p0 := &buf[0]
	p2 := &buf[2]
	_t.expect_value(t, intrinsics.ptr_offset(p0, idx), p2)
}

@(test)
intrinsics_ptr_offset_u32 :: proc(t: ^T) {
	buf: []u32 = {100, 101, 102, 103}
	idx := 2
	p0 := &buf[0]
	p2 := &buf[2]
	_t.expect_value(t, intrinsics.ptr_offset(p0, idx), p2)
}

@(test)
intrinsics_ptr_sub_u8 :: proc(t: ^T) {
	buf: []u8 = {100, 101, 102, 103}
	p1 := &buf[1]
	p3 := &buf[3]
	_t.expect_value(t, intrinsics.ptr_sub(p3, p1), 2)
}

@(test)
intrinsics_ptr_sub_u32 :: proc(t: ^T) {
	buf: []u32 = {100, 101, 102, 103}
	p1 := &buf[1]
	p3 := &buf[3]
	_t.expect_value(t, intrinsics.ptr_sub(p3, p1), 2)
}

package test_misc

import _t "core:testing"

@(test)
offset_ptr :: proc(t: ^T) {
	buf: []u8 = {100, 101, 102, 103}

	p0, p1, p2, p3: ^u8

	p0 = &buf[0]

	p1 = (^u8)(uintptr(p0) + 1)

	idx := 2
	p2 = (^u8)(uintptr(p0) + uintptr(idx))

	p3 = raw_data(buf)

	_t.expect_value(t, p0, &buf[0])
	_t.expect_value(t, p0^, 100)
	_t.expect_value(t, p1, &buf[1])
	_t.expect_value(t, p1^, 101)
	_t.expect_value(t, p2, &buf[2])
	_t.expect_value(t, p2^, 102)
	_t.expect_value(t, p3, &buf[0])
}

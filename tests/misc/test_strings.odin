package test_misc

import "core:unicode/utf16"
import ascii "shared:xterm"

@(test)
verify_ascii :: proc(t: ^testing.T) {
	expect_any_int(t, ascii.control_characters.BEL, '\a')
	expect_any_int(t, ascii.control_characters.BS , '\b')
	expect_any_int(t, ascii.control_characters.TAB, '\t')
	expect_any_int(t, ascii.control_characters.LF , '\n')
	expect_any_int(t, ascii.control_characters.VT , '\v')
	expect_any_int(t, ascii.control_characters.FF , '\f')
	expect_any_int(t, ascii.control_characters.CR , '\r')
}

@(test)
is_a_rune_the_same_as_in_csharp :: proc(t: ^testing.T) {
	r: rune

	r = rune('A')
	expect_value(t, u32(r) , 0x0041)

	r = rune('😃')
	expect_value(t, u32(r) , 0x0001_F603)

	r = rune('Δ')
	expect_value(t, u32(r) , 0x0000_0394)

	d: [8]u16
	n := utf16.encode_string(d[:], "😃")
	expect_value(t, n, 2)
	expect_value(t, d[0], 0xD83D)
	expect_value(t, d[1], 0xDE03)

	s := "😃"
	expect_value(t, len(s), 4)
	expect_value(t, s[0], 0xF0)
	expect_value(t, s[1], 0x9F)
	expect_value(t, s[2], 0x98)
	expect_value(t, s[3], 0x83)
}

@(test)
verify_cstrings :: proc(t: ^testing.T) {

	data: [10]u8 = "1234567890"
	expect_value(t, len(data), 10)
	cs : cstring = cstring(&data[0])
	//expect_value(t, cs[1], "2")
	ps := ([^]byte)(cs)
	expect_value(t, ps[1], '2')
}

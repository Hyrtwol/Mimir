package test_misc

import "core:fmt"
import "core:os"
import "core:bytes"
import "core:testing"
import "core:unicode/utf16"
import ascii "shared:xterm"
import "shared:ounit"

@(test)
verify_ascii :: proc(t: ^testing.T) {
	ounit.expect_value(t, ascii.control_characters.BEL, '\a')
	ounit.expect_value(t, ascii.control_characters.BS , '\b')
	ounit.expect_value(t, ascii.control_characters.TAB, '\t')
	ounit.expect_value(t, ascii.control_characters.LF , '\n')
	ounit.expect_value(t, ascii.control_characters.VT , '\v')
	ounit.expect_value(t, ascii.control_characters.FF , '\f')
	ounit.expect_value(t, ascii.control_characters.CR , '\r')
}

@(test)
is_a_rune_the_same_as_in_csharp :: proc(t: ^testing.T) {
	r: rune

	r = rune('A')
	ounit.expect_value(t, u32(r) , 0x0041)

	r = rune('😃')
	ounit.expect_value(t, u32(r) , 0x0001_F603)

	r = rune('Δ')
	ounit.expect_value(t, u32(r) , 0x0000_0394)

	d: [8]u16
	n := utf16.encode_string(d[:], "😃")
	ounit.expect_value(t, n, 2)
	ounit.expect_value(t, d[0], 0xD83D)
	ounit.expect_value(t, d[1], 0xDE03)

	s := "😃"
	ounit.expect_value(t, len(s), 4)
	ounit.expect_value(t, s[0], 0xF0)
	ounit.expect_value(t, s[1], 0x9F)
	ounit.expect_value(t, s[2], 0x98)
	ounit.expect_value(t, s[3], 0x83)
}

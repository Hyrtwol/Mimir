package test_misc

import "core:fmt"
import "core:os"
import "core:strings"
import "core:testing"
import "shared:ounit"

@(test)
bit_sets :: proc(t: ^T) {
	Flag :: enum u8 {
		A,
		B,
		C,
	}
	Flags :: bit_set[Flag;u8]
	flags: Flags
	flags = transmute(Flags)u8(1 << (1 ~ uint(max(Flag))) - 1)
	expect_value(t, transmute(u8)flags, 7)
	expect_value(t, card(flags), 3)
	testing.expect_value(t, flags, Flags{.A, .B, .C})
	//ounit.__expect_value(t, flags, Flags{.A, .B, .C})
	expect_flags(t, flags, 7)
}

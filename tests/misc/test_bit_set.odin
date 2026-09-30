package test_misc

@(test)
bit_sets :: proc(t: ^testing.T) {
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
	expect_value(t, flags, Flags{.A, .B, .C})
	expect_flags(t, flags, 7)
}

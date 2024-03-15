package ounit

import "core:testing"

@(private)
expect_u32 :: proc(t: ^testing.T, act, exp: u32, loc := #caller_location) {
	testing.expectf(t, act == exp, "0x%8X (should be: 0x%8X)", act, exp)
}

@(private)
expect_i32 :: proc(t: ^testing.T, act, exp: i32, loc := #caller_location) {
	testing.expectf(t, act == exp, "0x%8X (should be: 0x%8X)", act, exp)
}

expect_it :: proc {
	expect_u32,
	expect_i32,
}

equal :: proc(t: ^testing.T, #any_int act: int, #any_int exp: int, loc := #caller_location) {
	testing.expectf(t, act == exp, "0x%8X (should be: 0x%8X)", act, exp)
}

expect_size :: proc(t: ^testing.T, $act: typeid, exp: int, loc := #caller_location) {
	testing.expectf(t, size_of(act) == exp, "size_of(%v) should be %d was %d", typeid_of(act), exp, size_of(act), loc = loc)
}

expect_value :: proc(t: ^testing.T, #any_int act: u32, #any_int exp: u32, loc := #caller_location) {
	testing.expectf(t, act == exp, "0x%8X (should be: 0x%8X)", act, exp, loc = loc)
}

expect_valuei :: proc(t: ^testing.T, act: i32, exp: i32, loc := #caller_location) {
	testing.expectf(t, act == exp, "%d (should be: %d)", act, exp, loc = loc)
}

expect_valuef :: proc(t: ^testing.T, act, exp, delta: f32, loc := #caller_location) {
	testing.expectf(t, abs(act - exp) <= delta, "%f (should be: %f) %f", act, exp, abs(act - exp), loc = loc)
}

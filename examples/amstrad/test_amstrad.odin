package amstrad

import "core:fmt"
import "core:os"
import "core:bytes"
import "core:testing"
import "shared:ascii"
import a "shared:z80/amstrad"
import o "shared:ounit"

expect_value :: proc(t: ^testing.T, act: u8, exp: u8, loc := #caller_location) {
	testing.expectf(t, act == exp, "0b%8b (should be: 0b%8b)", act, exp, loc = loc)
}

@(test)
mode_0 :: proc(t: ^testing.T) {
	expect_value(t, MODE_0_P0(0b_0000), 0b_0000_0000)
	expect_value(t, MODE_0_P0(0b_0001), 0b_1000_0000)
	expect_value(t, MODE_0_P0(0b_0010), 0b_0000_1000)
	expect_value(t, MODE_0_P0(0b_0011), 0b_1000_1000)
	expect_value(t, MODE_0_P0(0b_0100), 0b_0010_0000)
	expect_value(t, MODE_0_P0(0b_0101), 0b_1010_0000)
	expect_value(t, MODE_0_P0(0b_0110), 0b_0010_1000)
	expect_value(t, MODE_0_P0(0b_0111), 0b_1010_1000)
	expect_value(t, MODE_0_P0(0b_1000), 0b_0000_0010)
	expect_value(t, MODE_0_P0(0b_1001), 0b_1000_0010)
	expect_value(t, MODE_0_P0(0b_1010), 0b_0000_1010)
	expect_value(t, MODE_0_P0(0b_1011), 0b_1000_1010)
	expect_value(t, MODE_0_P0(0b_1100), 0b_0010_0010)
	expect_value(t, MODE_0_P0(0b_1101), 0b_1010_0010)
	expect_value(t, MODE_0_P0(0b_1110), 0b_0010_1010)
	expect_value(t, MODE_0_P0(0b_1111), 0b_1010_1010)

	expect_value(t, MODE_0_P1(0b_0000), 0b_0000_0000)
	expect_value(t, MODE_0_P1(0b_0001), 0b_0100_0000)
	expect_value(t, MODE_0_P1(0b_0010), 0b_0000_0100)
	expect_value(t, MODE_0_P1(0b_0011), 0b_0100_0100)
	expect_value(t, MODE_0_P1(0b_0100), 0b_0001_0000)
	expect_value(t, MODE_0_P1(0b_0101), 0b_0101_0000)
	expect_value(t, MODE_0_P1(0b_0110), 0b_0001_0100)
	expect_value(t, MODE_0_P1(0b_0111), 0b_0101_0100)
	expect_value(t, MODE_0_P1(0b_1000), 0b_0000_0001)
	expect_value(t, MODE_0_P1(0b_1001), 0b_0100_0001)
	expect_value(t, MODE_0_P1(0b_1010), 0b_0000_0101)
	expect_value(t, MODE_0_P1(0b_1011), 0b_0100_0101)
	expect_value(t, MODE_0_P1(0b_1100), 0b_0001_0001)
	expect_value(t, MODE_0_P1(0b_1101), 0b_0101_0001)
	expect_value(t, MODE_0_P1(0b_1110), 0b_0001_0101)
	expect_value(t, MODE_0_P1(0b_1111), 0b_0101_0101)
}

@(test)
mode_1 :: proc(t: ^testing.T) {
	expect_value(t, MODE_1_P0(0b_0000), 0b_0000_0000)
	expect_value(t, MODE_1_P0(0b_0001), 0b_1000_0000)
	expect_value(t, MODE_1_P0(0b_0010), 0b_0000_1000)
	expect_value(t, MODE_1_P0(0b_0011), 0b_1000_1000)

	expect_value(t, MODE_1_P1(0b_0000), 0b_0000_0000)
	expect_value(t, MODE_1_P1(0b_0001), 0b_0100_0000)
	expect_value(t, MODE_1_P1(0b_0010), 0b_0000_0100)
	expect_value(t, MODE_1_P1(0b_0011), 0b_0100_0100)

	expect_value(t, MODE_1_P2(0b_0000), 0b_0000_0000)
	expect_value(t, MODE_1_P2(0b_0001), 0b_0010_0000)
	expect_value(t, MODE_1_P2(0b_0010), 0b_0000_0010)
	expect_value(t, MODE_1_P2(0b_0011), 0b_0010_0010)

	expect_value(t, MODE_1_P3(0b_0000), 0b_0000_0000)
	expect_value(t, MODE_1_P3(0b_0001), 0b_0001_0000)
	expect_value(t, MODE_1_P3(0b_0010), 0b_0000_0001)
	expect_value(t, MODE_1_P3(0b_0011), 0b_0001_0001)
}

@(test)
pixel_defines :: proc(t: ^testing.T) {
	p : [4]u8
	//p0, p1: u8
	for i:u8=0;i<27;i+=1 {
		// p0 = MODE_1_P0(i)
		// p1 = MODE_1_P1(i)
		// p2 = MODE_1_P2(i)
		// p3 = MODE_1_P3(i)
		p = {MODE_1_P0(i),MODE_1_P1(i),MODE_1_P2(i),MODE_1_P3(i)}
		//fmt.printf("P0: %2d %8b %8b %8b %8b\n", i, p.x, p.y, p.z, p.w)
		//fmt.printf("P0: %2d %2d %2d %2d %2d\n", i, p.x, p.y, p.z, p.w)
		fmt.printf("%8b %v\n", i, p)
	}
}

@(test)
verify_screen_size :: proc(t: ^testing.T) {
	size_16kb :: 0x04000
	o.expect_valuei(t, 16384, size_16kb)

	byte_size : [2]i32 = {80, 200}
	o.expect_valuei(t, byte_size.x * byte_size.y, 16000)

	o.expect_valuef(t, f32(a.size_16kb) / 80, 204.800, 0.1)
	o.expect_valuei(t, size_16kb - (80 * 204), 64)
}
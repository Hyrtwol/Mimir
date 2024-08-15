package test_canvas

import cv ".."
import "core:fmt"
import "core:math/linalg"
import win32 "core:sys/windows"
import "core:testing"
import o "shared:ounit"

expect_value :: proc(t: ^testing.T, act: cv.byte4, exp: cv.byte4, loc := #caller_location) {
	testing.expectf(t, act == exp, "%v (should be: %v)", act, exp, loc = loc)
}

@(test)
verify_w95_colors :: proc(t: ^testing.T) {
	o.expect_value(t, len(cv.W95_COLORS), 16)
	expect_value(t, cv.W95_BLACK, cv.byte4{0x00, 0x00, 0x00, 0xFF})
	expect_value(t, cv.W95_WHITE, cv.byte4{0xFF, 0xFF, 0xFF, 0xFF})
}

@(test)
verify_c64_colors :: proc(t: ^testing.T) {
	o.expect_value(t, len(cv.C64_COLORS), 16)
	expect_value(t, cv.C64_BLACK, cv.byte4{0x00, 0x00, 0x00, 0xFF})
	expect_value(t, cv.C64_WHITE, cv.byte4{0xFF, 0xFF, 0xFF, 0xFF})
	expect_value(t, cv.get_color_c64(.BLACK), cv.byte4{0x00, 0x00, 0x00, 0xFF})
	expect_value(t, cv.get_color_c64(.WHITE), cv.byte4{0xFF, 0xFF, 0xFF, 0xFF})
}

@(test)
verify_amstrad_colors :: proc(t: ^testing.T) {
	o.expect_value(t, len(cv.AMSTRAD_COLORS), 27)

	expect_value(t, cv.AMSTRAD_BLACK, cv.byte4{0x00, 0x00, 0x00, 0xFF})
	expect_value(t, cv.AMSTRAD_BRIGHT_WHITE, cv.byte4{0xFF, 0xFF, 0xFF, 0xFF})

	expect_value(t, cv.AMSTRAD_BLACK, cv.W95_BLACK)
	expect_value(t, cv.AMSTRAD_BLUE, cv.W95_NAVY)
	expect_value(t, cv.AMSTRAD_BRIGHT_BLUE, cv.W95_BLUE)
	expect_value(t, cv.AMSTRAD_RED, cv.W95_MAROON)
	expect_value(t, cv.AMSTRAD_MAGENTA, cv.W95_PURPLE)

	expect_value(t, cv.AMSTRAD_GREEN, cv.W95_GREEN)

	expect_value(t, cv.get_color(cv.AMSTRAD_COLOR.BLACK), cv.byte4{0x00, 0x00, 0x00, 0xFF})
	expect_value(t, cv.get_color(cv.AMSTRAD_COLOR.BRIGHT_WHITE), cv.byte4{0xFF, 0xFF, 0xFF, 0xFF})

	expect_value(t, cv.get_color_amstrad(.BLACK), cv.byte4{0x00, 0x00, 0x00, 0xFF})
	expect_value(t, cv.get_color_amstrad(.BRIGHT_WHITE), cv.byte4{0xFF, 0xFF, 0xFF, 0xFF})
}

@(private)
print_map :: proc(m: [3][3]i32) {
	prefix :: "// "
	format :: "% 2d"
	for y in i32(0) ..< 3 {
		fmt.println(prefix + "   +---+---+---+")
		iy := 2 - y
		fmt.printf(prefix + format + " ", iy - 1)
		cy := m[iy]
		for x in i32(0) ..< 3 {
			c := cy[x]
			fmt.print("|")
			if c >= 0 {
				fmt.printf(format + " ", c)
			} else {
				fmt.print("   ")
			}
		}
		fmt.println("|")
	}
	fmt.println(prefix + "   +---+---+---+")
	fmt.print(prefix + "  ")
	for y in i32(0) ..< 3 {
		fmt.printf("  " + format, y - 1)
	}
	fmt.println()
}

@(test)
direction4 :: proc(t: ^testing.T) {
	m: [3][3]i32
	for y in i32(0) ..< 3 {
		for x in i32(0) ..< 3 {
			m[y][x] = -1
		}
	}
	for i in i32(0) ..< 4 {
		d := cv.get_direction4(i) + 1
		m[d.y][d.x] = i
	}

	print_map(m)
}

@(test)
direction8 :: proc(t: ^testing.T) {
	m: [3][3]i32
	for y in i32(0) ..< 3 {
		for x in i32(0) ..< 3 {
			m[y][x] = -1
		}
	}
	for i in i32(0) ..< 8 {
		d := cv.get_direction8(i) + 1
		m[d.y][d.x] = i
	}

	print_map(m)
}

@(test)
to_color :: proc(t: ^testing.T) {
	o.expect_value(t, f32(255.99609375), cv.color_scale_f2b)

	expect_value(t, 000, cv.to_color(-0.10000))
	expect_value(t, 000, cv.to_color(+0.00000))
	expect_value(t, 000, cv.to_color(+0.00390))
	expect_value(t, 001, cv.to_color(+0.00391))
	expect_value(t, 127, cv.to_color(+0.50000))
	expect_value(t, 128, cv.to_color(+0.50001))
	expect_value(t, 254, cv.to_color(+0.99610))
	expect_value(t, 255, cv.to_color(+0.99611))
	expect_value(t, 255, cv.to_color(+1.00000))
	expect_value(t, 255, cv.to_color(+1.10000))

	expect_value(t, {0x3F, 0x7F, 0xBF, 0xFF}, cv.to_color(cv.float4{0.25, 0.5, 0.75, 1.0}))
}

@(test)
barycentric :: proc(t: ^testing.T) {
	tri := [3]cv.float2{cv.float2{150, 50}, cv.float2{80, 150}, cv.float2{50, 50}}
	fmt.println("t:", tri)
	ABC := cv.float3x3{tri[0].x, tri[0].y, 1, tri[1].x, tri[1].y, 1, tri[2].x, tri[2].y, 1}
	fmt.println("ABC:", ABC)

	a := linalg.matrix3x3_inverse_transpose(ABC)
	fmt.println("inverse_transpose:", a)

	testing.expectf(t, [3]f32{0.0099999998, -0, -0.0099999998} == a[0], "a[0]=%v", a[0])
	testing.expectf(t, [3]f32{-0.003, 0.0099999998, -0.0069999998} == a[1], "a[1]=%v", a[1])
	testing.expectf(t, [3]f32{-0.34999999, -0.5, 1.8499999} == a[2], "a[2]=%v", a[2])

	pp := cv.float3{10, 10, 10}
	b := cv.barycentric(&ABC, pp)
	fmt.println("barycentric:", b)

	testing.expectf(t, [3]f32{-3.43, -4.9, 18.33} == b, "b=%v", b)
}


@(test)
multiply :: proc(t: ^testing.T) {
	ABC := cv.float3x3{11, 12, 13, 21, 22, 23, 31, 32, 33}
	fmt.println("ABC:", ABC)

	b := ABC * cv.float3{1, 0, 0}
	fmt.println("multiply:", b)
	testing.expectf(t, [3]f32{11, 21, 31} == b, "b=%v", b)

}

/*
matrix4_perspective_f32_01: 0.78539819 1.33333337 1 10
proj : matrix[1.81065989, 0, -0, 0; 0, 2.4142134, -0, 0; 0, 0, -1.11111116, -1.11111116; 0, 0, -1, 0]
model: matrix[0, 0, 0, 0; 0, 0, 0, 0; 0, 0, 0, 0; 0, 0, 0, 0]
view : matrix[0.94868326, 0, -0.31622776, -0; -0.19611613, 0.78446448, -0.58834839, 1.1920929e-07; 0.24806947, 0.62017369, 0.7442084, -4.0311289; 0, 0, 0, 1]
proj : matrix[1.81065989, 0, 0, 0; 0, 2.4142134, 0, 0; 0, 0, 0, -1.11111116; 0, 0, 1, 0]
*/
delta :: 0.000001

@(test)
matrix4_perspective_f32 :: proc(t: ^testing.T) {
	flip_z_axis := true
	fov, aspect, near, far: f32 = 0.78539819, 1.33333337, 1, 10
	proj := cv.matrix4_perspective_f32(fov, aspect, near, far)
	fmt.println("proj:", proj)
	vn := cv.float4{0, 0, -near, 1}
	vf := cv.float4{0, 0, -far, 1}

	vn = proj * vn
	vn = cv.perspective_divide(vn)
	fmt.println("vn:", vn)
	vf = proj * vf
	vf = cv.perspective_divide(vf)
	fmt.println("vf:", vf)

	o.expect_valuef(t, vn.z, -1, delta)
	o.expect_valuef(t, vf.z, 1, delta)
}

@(test)
matrix4_perspective_f32_01 :: proc(t: ^testing.T) {
	flip_z_axis := true
	fov, aspect, near, far: f32 = 0.78539819, 1.33333337, 1, 10
	proj := cv.matrix4_perspective_f32_01(fov, aspect, near, far)
	fmt.println("proj:", proj)
	vn := cv.float4{0, 0, -near, 1}
	vf := cv.float4{0, 0, -far, 1}

	vn = proj * vn
	vn = cv.perspective_divide(vn)
	fmt.println("vn:", vn)
	vf = proj * vf
	vf = cv.perspective_divide(vf)
	fmt.println("vf:", vf)

	o.expect_valuef(t, vn.z, 0, delta)
	o.expect_valuef(t, vf.z, 1, delta)
}

@(test)
reverse_z_perspective :: proc(t: ^testing.T) {
	flip_z_axis := true
	fov, aspect: f32 = 0.78539819, 1.33333337
	near, far: f32 = 1, 10
	proj := cv.matrix4_perspective_f32_01(fov, aspect, far, near)
	fmt.println("proj:", proj)
	vn := cv.float4{0, 0, -near, 1}
	vf := cv.float4{0, 0, -far, 1}

	vn = proj * vn
	vn = cv.perspective_divide(vn)
	fmt.println("vn:", vn)
	vf = proj * vf
	vf = cv.perspective_divide(vf)
	fmt.println("vf:", vf)

	o.expect_valuef(t, vn.z, 1, delta)
	o.expect_valuef(t, vf.z, 0, delta)
}

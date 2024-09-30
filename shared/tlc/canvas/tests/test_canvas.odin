package test_canvas

import cv ".."
import "core:fmt"
import "core:math"
import "core:math/linalg"
import win32 "core:sys/windows"
import "core:testing"
import o "shared:ounit"

EPSILON :: o.EPSILON
expect_size :: o.expect_size
expect_value :: o.expect_scalar
expect_vector :: o.expect_vector

expect_color :: proc(t: ^testing.T, act: cv.byte4, exp: cv.byte4, loc := #caller_location) {
	//testing.expectf(t, act == exp, o.should_be_v, act, exp, loc = loc)
	expect_vector(t, act, exp, 0, loc)
}

@(test)
verify_type_sizes :: proc(t: ^testing.T) {
	expect_size(t, cv.sbyte, 1)
	expect_size(t, cv.byte, 1)
	expect_size(t, cv.short, 2)
	expect_size(t, cv.ushort, 2)
	expect_size(t, cv.integer, 4)
	expect_size(t, cv.cardinal, 4)
	// expect_size(t, cv.long  , 8)
	// expect_size(t, cv.ulong , 8)
	// expect_size(t, cv.nint  , 8)
	// expect_size(t, cv.nuint , 8)
	expect_size(t, cv.half, 2)
	expect_size(t, cv.float, 4)
	expect_size(t, cv.double, 8)
	// expect_size(t, cv.bool  , 1)
	// expect_size(t, cv.char  , 2)
	//expect_size(t, cv.string, 8)

	expect_size(t, cv.byte4, 4)
	expect_size(t, cv.int2, 8)
	expect_size(t, cv.int3, 12)
	expect_size(t, cv.uint2, 8)
	expect_size(t, cv.uint3, 12)
	expect_size(t, cv.float2, 8)
	expect_size(t, cv.float3, 12)
	expect_size(t, cv.float4, 16)
	expect_size(t, cv.double2, 16)
	expect_size(t, cv.double3, 24)

	expect_size(t, cv.float2x2, 16)
	expect_size(t, cv.float2x3, 24)
	expect_size(t, cv.float3x3, 36)
	expect_size(t, cv.float4x4, 64)

	expect_size(t, cv.color, 4)
	expect_value(t, cv.color_byte_size, 4)
	expect_value(t, cv.color_bit_count, 32)
}

@(test)
verify_w95_colors :: proc(t: ^testing.T) {
	expect_value(t, len(cv.W95_COLORS), 16)
	expect_color(t, cv.W95_BLACK, cv.byte4{0x00, 0x00, 0x00, 0xFF})
	expect_color(t, cv.W95_WHITE, cv.byte4{0xFF, 0xFF, 0xFF, 0xFF})
}

@(test)
verify_c64_colors :: proc(t: ^testing.T) {
	expect_value(t, len(cv.C64_COLORS), 16)
	expect_color(t, cv.C64_BLACK, cv.byte4{0x00, 0x00, 0x00, 0xFF})
	expect_color(t, cv.C64_WHITE, cv.byte4{0xFF, 0xFF, 0xFF, 0xFF})
	expect_color(t, cv.get_color_c64(.BLACK), cv.byte4{0x00, 0x00, 0x00, 0xFF})
	expect_color(t, cv.get_color_c64(.WHITE), cv.byte4{0xFF, 0xFF, 0xFF, 0xFF})
}

@(test)
verify_amstrad_colors :: proc(t: ^testing.T) {
	expect_value(t, len(cv.AMSTRAD_COLORS), 27)

	expect_color(t, cv.AMSTRAD_BLACK, cv.byte4{0x00, 0x00, 0x00, 0xFF})
	expect_color(t, cv.AMSTRAD_BRIGHT_WHITE, cv.byte4{0xFF, 0xFF, 0xFF, 0xFF})

	expect_color(t, cv.AMSTRAD_BLACK, cv.W95_BLACK)
	expect_color(t, cv.AMSTRAD_BLUE, cv.W95_NAVY)
	expect_color(t, cv.AMSTRAD_BRIGHT_BLUE, cv.W95_BLUE)
	expect_color(t, cv.AMSTRAD_RED, cv.W95_MAROON)
	expect_color(t, cv.AMSTRAD_MAGENTA, cv.W95_PURPLE)

	expect_color(t, cv.AMSTRAD_GREEN, cv.W95_GREEN)

	expect_color(t, cv.get_color(cv.AMSTRAD_COLOR.BLACK), cv.byte4{0x00, 0x00, 0x00, 0xFF})
	expect_color(t, cv.get_color(cv.AMSTRAD_COLOR.BRIGHT_WHITE), cv.byte4{0xFF, 0xFF, 0xFF, 0xFF})

	expect_color(t, cv.get_color_amstrad(.BLACK), cv.byte4{0x00, 0x00, 0x00, 0xFF})
	expect_color(t, cv.get_color_amstrad(.BRIGHT_WHITE), cv.byte4{0xFF, 0xFF, 0xFF, 0xFF})
}

@(private = "file")
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

// @(test)
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

// @(test)
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
	expect_value(t, f32(255.99609375), cv.color_scale_f2b)

	o.expect_u8(t, 000, cv.to_color(-0.10000))
	o.expect_u8(t, 000, cv.to_color(+0.00000))
	o.expect_u8(t, 000, cv.to_color(+0.00390))
	o.expect_u8(t, 001, cv.to_color(+0.00391))
	o.expect_u8(t, 127, cv.to_color(+0.50000))
	o.expect_u8(t, 128, cv.to_color(+0.50001))
	o.expect_u8(t, 254, cv.to_color(+0.99610))
	o.expect_u8(t, 255, cv.to_color(+0.99611))
	o.expect_u8(t, 255, cv.to_color(+1.00000))
	o.expect_u8(t, 255, cv.to_color(+1.10000))

	expect_color(t, {0x3F, 0x7F, 0xBF, 0xFF}, cv.to_color(cv.float4{0.25, 0.5, 0.75, 1.0}))
}

@(test)
cast_float2x3 :: proc(t: ^testing.T) {
	tri := [3]cv.float2{cv.float2{1, 2}, cv.float2{3, 4}, cv.float2{5, 6}}
	mx := transmute(cv.float2x3)tri
	o.expect_matrix(t, mx, cv.float2x3{1, 3, 5, 2, 4, 6}, EPSILON)
	o.expect_vector(t, mx[0], tri[0], EPSILON)
	o.expect_vector(t, mx[1], tri[1], EPSILON)
	o.expect_vector(t, mx[2], tri[2], EPSILON)
}

@(test)
cast_float3x2 :: proc(t: ^testing.T) {
	tri := [2]cv.float3{cv.float3{1, 2, 3}, cv.float3{4, 5, 6}}
	mx := transmute(cv.float3x2)tri
	o.expect_matrix(t, mx, cv.float3x2{1, 4, 2, 5, 3, 6}, EPSILON)
	o.expect_vector(t, mx[0], tri[0], EPSILON)
	o.expect_vector(t, mx[1], tri[1], EPSILON)
}

@(test)
cast_float3x3 :: proc(t: ^testing.T) {
	tri := [3]cv.float3{cv.float3{1, 2, 3}, cv.float3{4, 5, 6}, cv.float3{7, 8, 9}}
	mx := transmute(cv.float3x3)tri
	o.expect_matrix(t, mx, cv.float3x3{1, 4, 7, 2, 5, 8, 3, 6, 9}, EPSILON)
	o.expect_vector(t, mx[0], tri[0], EPSILON)
	o.expect_vector(t, mx[1], tri[1], EPSILON)
	o.expect_vector(t, mx[2], tri[2], EPSILON)
}

@(test)
barycentric :: proc(t: ^testing.T) {
	EPSILON :: o.EPSILON

	tri := [3]cv.float2{cv.float2{150, 50}, cv.float2{80, 150}, cv.float2{50, 50}}
	//fmt.println("t:", tri)
	o.expect_matrix(t, transmute(cv.float2x3)tri, cv.float2x3{150, 80, 50, 50, 150, 50}, EPSILON)
	o.expect_matrix(t, transmute(cv.float3x2)tri, cv.float3x2{150, 150, 50, 50, 80, 50}, EPSILON)

	ABC := cv.float3x3{tri[0].x, tri[0].y, 1, tri[1].x, tri[1].y, 1, tri[2].x, tri[2].y, 1}
	//fmt.println("ABC:", ABC)
	o.expect_matrix(t, ABC, cv.float3x3{150, 50, 1, 80, 150, 1, 50, 50, 1}, EPSILON)

	a := linalg.matrix3x3_inverse_transpose(ABC)
	//fmt.println("inverse_transpose:", a)
	o.expect_matrix(t, a, cv.float3x3{0.01, -0.003, -0.35, 0, 0.01, -0.5, -0.01, -0.007, 1.85}, EPSILON)

	// testing.expectf(t, [3]f32{0.0099999998, -0, -0.0099999998} == a[0], "a[0]=%v", a[0])
	// testing.expectf(t, [3]f32{-0.003, 0.0099999998, -0.0069999998} == a[1], "a[1]=%v", a[1])
	// testing.expectf(t, [3]f32{-0.34999999, -0.5, 1.8499999} == a[2], "a[2]=%v", a[2])

	o.expect_vector(t, [3]f32{0.01, -0, -0.01}, a[0], EPSILON)
	o.expect_vector(t, [3]f32{-0.003, 0.01, -0.007}, a[1], EPSILON)
	o.expect_vector(t, [3]f32{-0.35, -0.5, 1.85}, a[2], EPSILON)

	pp := cv.float3{10, 10, 10}
	b := cv.barycentric(&ABC, pp)
	fmt.println("barycentric:", b)

	//testing.expectf(t, [3]f32{-3.43, -4.9, 18.33} == b, "b=%v", b)
	o.expect_vector(t, [3]f32{-3.43, -4.9, 18.33}, b, EPSILON)
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

	o.expect_float(t, vn.z, -1, delta)
	o.expect_float(t, vf.z, 1, delta)
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

	o.expect_float(t, vn.z, 0, delta)
	o.expect_float(t, vf.z, 1, delta)
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

	o.expect_float(t, vn.z, 1, delta)
	o.expect_float(t, vf.z, 0, delta)
}

@(test)
rotate_y :: proc(t: ^testing.T) {
	identity2: cv.float2x2 = cv.identity(cv.float2x2)
	o.expect_matrix(t, identity2, cv.float2x2{1, 0, 0, 1}, EPSILON)

	identity3: cv.float3x3 = cv.identity(cv.float3x3)
	o.expect_matrix(t, identity3, cv.float3x3{1, 0, 0, 0, 1, 0, 0, 0, 1}, EPSILON)

	identity4: cv.float4x4 = cv.identity(cv.float4x4)
	o.expect_matrix(t, identity4, cv.float4x4{1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1}, EPSILON)

	rot4 := cv.matrix4_rotate_y_f32(0)
	o.expect_matrix(t, rot4, identity4, EPSILON)

	rot3 := cv.matrix3_rotate_f32(0, cv.float3_xunit)
	o.expect_matrix(t, rot3, identity3, EPSILON)

	rot2 := cv.matrix2_rotate_f32(0)
	o.expect_matrix(t, rot2, identity2, EPSILON)
	o.expect_vector(t, rot2[0], cv.float2_xunit, EPSILON)
	o.expect_vector(t, rot2[1], cv.float2_yunit, EPSILON)

	rot2 = cv.matrix2_rotate_f32(cv.HalfPI)
	o.expect_matrix(t, rot2, cv.float2x2{0, -1, 1, 0}, EPSILON)
	o.expect_vector(t, rot2[0], cv.float2_yunit, EPSILON)
	o.expect_vector(t, rot2[1], -cv.float2_xunit, EPSILON)

	rot2 = cv.matrix2_rotate_f32(cv.PI)
	o.expect_matrix(t, rot2, cv.float2x2{-1, 0, 0, -1}, EPSILON)
	o.expect_vector(t, rot2[0], -cv.float2_xunit, EPSILON)
	o.expect_vector(t, rot2[1], -cv.float2_yunit, EPSILON)

	rot2 = cv.matrix2_rotate_f32(-cv.HalfPI)
	o.expect_matrix(t, rot2, cv.float2x2{0, 1, -1, 0}, EPSILON)
	o.expect_vector(t, rot2[0], -cv.float2_yunit, EPSILON)
	o.expect_vector(t, rot2[1], cv.float2_xunit, EPSILON)
}

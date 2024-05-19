package test_misc

import "core:bytes"
import "core:fmt"
import "core:math"
import "core:math/linalg"
import "base:runtime"
import "core:testing"
import o "shared:ounit"

int2 :: [2]i32

@(test)
can_i_swizzle :: proc(t: ^testing.T) {
	v: int2 = {3, 7}
	o.expect_value(t, v[0], 3)
	o.expect_value(t, v[1], 7)
	o.expect_value(t, v.x, 3)
	o.expect_value(t, v.y, 7)
}

@(test)
swapping :: proc(t: ^testing.T) {

	a, b: u32 = 47, 1337

	// stack swap
	a, b = b, a

	o.expect_value(t, a, 1337)
	o.expect_value(t, b, 47)

	// xor swap
	a ~= b
	b ~= a
	a ~= b

	o.expect_value(t, a, 47)
	o.expect_value(t, b, 1337)

}

@(test)
min_max_uintptr :: proc(t: ^testing.T) {
	act := u64(max(uintptr))
	exp := max(u64)
	testing.expect(t, exp == act)
}

@(test)
min_max_consts :: proc(t: ^testing.T) {
	act := max(f32) //      =  340282320000000000000000000000000000000.000
	testing.expect(t, math.F32_MAX == act) // 3.402823466e+38 == 340282320000000000000000000000000000000.000
	testing.expect(t, math.F32_MAX == 3.402823466e+38) //  340282320000000000000000000000000000000.000 max(f32)
	testing.expectf(t, fmt.tprintf("%f", math.F32_MAX) == "340282346599999000000000000000000000000.000", "%f", math.F32_MAX)
}

// Float 32 puzzle

@(test)
min_max :: proc(t: ^testing.T) {
	act, exp, diff: f32
	delta: f32 = 1e32 //   =        100000000000000000000000000000000.000 this is way too big! 1e31 fails O.o

	act = min(f32) //      = -340282320000000000000000000000000000000.000
	exp = -3.4028232e38 // = -340282300000000000000000000000000000000.000 looks like this will truncate this to -3.402823e38 ? note math.F32_DIG=6
	diff = abs(act - exp)
	testing.expectf(t, diff < delta, "%f (should be: %f) %f", act, exp, diff) // fails with delta=1e31

	act = max(f32) //      =  340282320000000000000000000000000000000.000
	exp = 3.4028232e38 //  =  340282300000000000000000000000000000000.000 missing 0.0000002e38
	diff = abs(act - exp)
	testing.expectf(t, diff < delta, "%f (should be: %f) %f", act, exp, diff) // fails with delta=1e31

	delta = math.F32_EPSILON

	act = max(f32) //     3.4028232e38
	exp = 3.4028232e38 + 0.0000002e38
	diff = abs(act - exp)
	testing.expectf(t, diff < delta, "%f (should be: %f) %f", act, exp, diff) // works with delta=F32_EPSILON

	act = max(f32) //     3.4028232e38
	exp = 3.402823e38 + 0.0000004e38
	diff = abs(act - exp)
	testing.expectf(t, diff < delta, "%f (should be: %f) %f", act, exp, diff) // works with delta=F32_EPSILON

	act = max(f32) //     3.4028232e38
	exp = math.F32_MAX // 3.402823466e+38
	diff = abs(act - exp)
	testing.expectf(t, diff < delta, "%f (should be: %f) %f", act, exp, diff) // works with delta=F32_EPSILON
}

/*
from core\math\math.odin
F32_MAX        :: 3.402823466e+38
F32_DIG        :: 6

from C#
public const float MaxValue = 3.40282347e+38f;

from https://learn.microsoft.com/en-us/cpp/cpp/floating-limits?view=msvc-170
FLT_MAX         = 3.402823466e+38F                   (so C# != C++ :D)
FLT_DIG         = 6
"Number of digits, q, such that a floating-point number with q decimal digits can be rounded into a floating-point representation and back without loss of precision."

from https://en.cppreference.com/w/c/types/limits
FLT_MAX         = 3.402823e+38
FLT_DIG         = 6
FLT_DECIMAL_DIG = 9
"conversion from float/double/long double to decimal with at least FLT_DECIMAL_DIG/DBL_DECIMAL_DIG/LDBL_DECIMAL_DIG digits and back is the identity conversion:
this is the decimal precision required to serialize/deserialize a floating-point value.
Defined to at least 6, 10, and 10 respectively, or 9 for IEEE float and 17 for IEEE double (see also the C++ analog: max_digits10)"

btw usage of FLT_DECIMAL_DIG can be seen in https://github.com/odin-lang/Odin/blob/master/vendor/cgltf/src/cgltf_write.h#L108

a bit odd, i think Odin should allow 9 digits and avoid the rounding to 6 for f32 somehow?
lets say you wanna define PI as f32 as precise as you can. must be happening during compilation
don't think it's a big issue but just took me by surprise :p
*/

@(test)
find_epsilon_for_f64 :: proc(t: ^testing.T) {
	epsilon, next, one, oneplusnext: f64
	epsilon = 1
	next = epsilon / 2
	oneplusnext = 1 + next
	one = 1
	for oneplusnext != one {
		epsilon = next
		next = epsilon / 2
		oneplusnext = 1 + next
	}
	fmt.printfln("epsilon = %e", epsilon)
	testing.expect(t, math.F64_EPSILON == epsilon)
}

@(test)
find_epsilon_for_f32 :: proc(t: ^testing.T) // The AMD CPU finds the same epsilon for both float and double
{
	epsilon, next, one, oneplusnext: f32
	epsilon = 1
	next = epsilon / 2
	oneplusnext = 1 + next
	one = 1
	for oneplusnext != one {
		epsilon = next
		next = epsilon / 2
		oneplusnext = 1 + next
	}
	fmt.printfln("epsilon = %e", epsilon)
	testing.expect(t, math.F32_EPSILON == epsilon)
}

@(test)
find_epsilon_for_f16 :: proc(t: ^testing.T) {
	epsilon, next, one, oneplusnext: f16
	epsilon = 1
	next = epsilon / 2
	oneplusnext = 1 + next
	one = 1
	for oneplusnext != one {
		epsilon = next
		next = epsilon / 2
		oneplusnext = 1 + next
	}
	fmt.printfln("epsilon = %e", epsilon)
	testing.expect(t, 4.8828120e-04 == epsilon)
	//testing.expect(t, math.F16_EPSILON == epsilon) // fails as F16_EPSILON=0.00097656
	testing.expect(t, math.F16_EPSILON == epsilon * 2)
}

@(test)
float_01_to_byte :: proc(t: ^testing.T) {
	C :: 8
	M :: 256 * C
	S :: 256 - (1 / 255)
	b: [256]i32
	f: f32
	y: u8
	for i in 0 ..< M {
		f = f32(i) / M
		y = u8(f * S)
		b[y] += 1
	}

	for i in 0 ..< 256 {
		testing.expect(t, b[i] == C)
	}
}

@(test)
vector2_max :: proc(t: ^testing.T) {
	v1: int2 = {1, 4}
	v2: int2 = {3, 2}
	m: int2 = linalg.max(v1, v2)
	testing.expect(t, m == {3, 4})
}

/*
150 50 ; 80 150 ; 50 50
abc:150 50 1
80 150 1
50 50 1

det:10000
*/

mat3x3 :: linalg.Matrix3x3f32
vec2 :: linalg.Vector2f32
vec3 :: linalg.Vector3f32
vec4 :: linalg.Vector4f32
tri :: [3]vec2

@(test)
determinant_3x3 :: proc(t: ^testing.T) {
	tri: tri = {vec2{150, 50}, vec2{80, 150}, vec2{50, 50}}
	fmt.println("t:", tri)
	ABC := mat3x3{tri[0].x, tri[0].y, 1, tri[1].x, tri[1].y, 1, tri[2].x, tri[2].y, 1}
	fmt.println("ABC:", ABC)
	//if (ABC.det()<1e-3) return {-1,1,1}; // for a degenerate triangle generate negative coordinates, it will be thrown away by the rasterizator
	//if (lg.determinant(ABC)<1e-3) {return {-1,1,1}} // for a degenerate triangle generate negative coordinates, it will be thrown away by the rasterizator
	det := linalg.matrix3x3_determinant(ABC)
	fmt.println("det:", det)
	o.expect_valuef(t, det, 10000, 0.0001)
}

@(test)
adjugate_3x3 :: proc(t: ^testing.T) {
	tri: tri = {vec2{150, 50}, vec2{80, 150}, vec2{50, 50}}
	fmt.println("t:", tri)
	ABC := mat3x3{tri[0].x, tri[0].y, 1, tri[1].x, tri[1].y, 1, tri[2].x, tri[2].y, 1}
	fmt.println("ABC:", ABC)
	//if (ABC.det()<1e-3) return {-1,1,1}; // for a degenerate triangle generate negative coordinates, it will be thrown away by the rasterizator
	//if (lg.determinant(ABC)<1e-3) {return {-1,1,1}} // for a degenerate triangle generate negative coordinates, it will be thrown away by the rasterizator
	a := linalg.matrix3x3_adjugate(ABC)
	fmt.println("adjugate:", a)

	testing.expectf(t, [3]f32{100, -0, -100} == a[0], "a[0]=%v", a[0])
	testing.expectf(t, [3]f32{-30, 100, -70} == a[1], "a[1]=%v", a[1])
	testing.expectf(t, [3]f32{-3500, -5000, 18500} == a[2], "a[2]=%v", a[2])
}

@(test)
transpose_3x3 :: proc(t: ^testing.T) {
	tri: tri = {vec2{150, 50}, vec2{80, 150}, vec2{50, 50}}
	fmt.println("t:", tri)
	ABC := mat3x3{tri[0].x, tri[0].y, 1, tri[1].x, tri[1].y, 1, tri[2].x, tri[2].y, 1}
	fmt.println("ABC:", ABC)
	a := linalg.transpose(ABC)
	fmt.println("transpose:", a)

	testing.expectf(t, [3]f32{150, 50, 1} == a[0], "a[0]=%v", a[0])
	testing.expectf(t, [3]f32{80, 150, 1} == a[1], "a[1]=%v", a[1])
	testing.expectf(t, [3]f32{50, 50, 1} == a[2], "a[2]=%v", a[2])
}

@(test)
inverse_3x3 :: proc(t: ^testing.T) {
	tri: tri = {vec2{150, 50}, vec2{80, 150}, vec2{50, 50}}
	fmt.println("t:", tri)
	ABC := mat3x3{tri[0].x, tri[0].y, 1, tri[1].x, tri[1].y, 1, tri[2].x, tri[2].y, 1}
	fmt.println("ABC:", ABC)
	a := linalg.inverse(ABC)
	fmt.println("inverse:", a)

	testing.expectf(t, [3]f32{0.0099999998, -0.003, -0.34999999} == a[0], "a[0]=%v", a[0])
	testing.expectf(t, [3]f32{-0, 0.0099999998, -0.5} == a[1], "a[1]=%v", a[1])
	testing.expectf(t, [3]f32{-0.0099999998, -0.0069999998, 1.8499999} == a[2], "a[2]=%v", a[2])
}

@(test)
inverse_transpose_3x3 :: proc(t: ^testing.T) {
	tri: tri = {vec2{150, 50}, vec2{80, 150}, vec2{50, 50}}
	fmt.println("t:", tri)
	ABC := mat3x3{tri[0].x, tri[0].y, 1, tri[1].x, tri[1].y, 1, tri[2].x, tri[2].y, 1}
	fmt.println("ABC:", ABC)
	a := linalg.matrix3x3_inverse_transpose(ABC)
	fmt.println("inverse_transpose:", a)

	testing.expectf(t, [3]f32{0.0099999998, -0, -0.0099999998} == a[0], "a[0]=%v", a[0])
	testing.expectf(t, [3]f32{-0.003, 0.0099999998, -0.0069999998} == a[1], "a[1]=%v", a[1])
	testing.expectf(t, [3]f32{-0.34999999, -0.5, 1.8499999} == a[2], "a[2]=%v", a[2])
}

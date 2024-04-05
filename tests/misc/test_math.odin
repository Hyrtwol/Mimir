package test_misc

import "core:bytes"
import "core:fmt"
import "core:math"
import "core:runtime"
import "core:testing"
import o "shared:ounit"

vec2 :: [2]i32

@(test)
can_i_swizzle :: proc(t: ^testing.T) {
	v: vec2 = {3, 7}
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
	fmt.printf("epsilon = %e\n", epsilon)
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
	fmt.printf("epsilon = %e\n", epsilon)
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
	fmt.printf("epsilon = %e\n", epsilon)
	testing.expect(t, 4.8828120e-04 == epsilon)
	//testing.expect(t, math.F16_EPSILON == epsilon) // fails as F16_EPSILON=0.00097656
	testing.expect(t, math.F16_EPSILON == epsilon * 2)
}

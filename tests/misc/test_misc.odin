package test_misc

import "core:fmt"
import "core:os"
import "core:strings"
import "core:path/filepath"
import _t "core:testing"
import "shared:ounit"

//TODO investigate #config

T :: ounit.T
expectf :: ounit.expectf
expect_value :: ounit.expect_value
expect_u8 :: ounit.expect_u8
expect_scalar :: ounit.expect_scalar
expect_int :: ounit.expect_int
expect_any_int :: ounit.expect_any_int
expect_flags :: ounit.expect_flags
expect_size :: ounit.expect_size

@(test)
odin_pragma :: proc(t: ^T) {
	expect_value(t, filepath.base(#file), "test_misc.odin")
	expect_value(t, #procedure, "odin_pragma")
}

get_version :: proc() -> (res: int, err: bool) {
	return 666, false
}

@(test)
string_vs_cstring :: proc(t: ^T) {
	str: string = "Can i convert"

	//dst = strings.clone_to_cstring(str, allocator = context.temp_allocator)
	dst := strings.clone_to_cstring(str)
	defer delete(dst)

	//expect_value(t, v[0], 3)
	_t.expect(t, dst == "Can i convert")

	// NOTE: This is valid because 'clone_string' appends a NUL terminator
	// see core\encoding\json\unmarshal.odin unmarshal_string_token
	dst2 := cstring(raw_data(str))

	_t.expect(t, dst2 == "Can i convert")
}

// when
MODE :: 1

@(test)
when_to_use_when :: proc(t: ^T) {
	str: cstring
	when MODE == 1 {
		str = "Can i convert"
	} else {
		str = "Oh no"
	}

	_t.expectf(t, str == "Can i convert", "%v", str)

	// when ODIN_DEBUG {
	// 	fmt.println("Debug")
	// } else {
	// 	fmt.println("Release")
	// }
}

@(test)
when_to_use_config :: proc(t: ^T) {
	val: i32
	val = #config(LA_COUR, -1)
	_t.expectf(t, val == -1, "%v", val)
}

@(test)
when_to_use_defer :: proc(t: ^T) {

	res := 0
	{
		res = 10
		defer res = 20
		expect_int(t, res, 10)
	}
	expect_int(t, res, 20)
	{
		defer res = 30;res = 40 // note the ;
		expect_int(t, res, 40)
	}
	expect_int(t, res, 30)
}

@(test)
some_slice :: proc(t: ^T) {
	slice := []int{1, 4, 9, 7}
	expect_int(t, slice[1], 4)
	// fmt.printfln("%v", slice)
	// fmt.printfln("%v", slice[1:3])
	// fmt.printfln("%v", slice[1:])
	// fmt.printfln("%v", slice[:3])
}

// Add leading 0x or 0X for hexadecimal (%#x or %#X)
@(test)
format_hex :: proc(t: ^T) {
	val: u32
	exp, act: string

	val = 0xDEADBEEF
	exp = fmt.tprintf("0x%8X", val)
	act = fmt.tprintf("%#X", val)
	_t.expectf(t, exp == act, "%s != %s", exp, act) // all good

	/* not working atm
	val = 0xC0DE
	exp = fmt.tprintf("0x%8X", val)
	act = fmt.tprintf("%#10X", val) // using 10 to account for 0x
	_t.expectf(t, exp == act, "%s != %s", exp, act) // fails with 0x0000C0DE != 00000xC0DE
	*/
}

unroll_for_statement :: proc() {
	//fmt.println("\n#'#unroll for' statements")

	// '#unroll for' works the same as if the 'inline' prefix did not
	// exist but these ranged loops are explicitly unrolled which can
	// be very very useful for certain optimizations

	//fmt.println("Ranges")
	#unroll for x, i in 1 ..< 4 {
		//fmt.println(x, i)
	}
}

// some_slice := []int{1, 4, 9}

// %#X prefix hex

/*
	#partial switch cvtHeader.kind {
	case .LF_MFUNC_ID:fallthrough // legit because binary structure identical
	case .LF_FUNC_ID:
		cvtFuncId := read_with_trailing_name(&mi.ipiStream, CvtFuncId)
		scl.procedure = cvtFuncId.name
	}
*/

/*
foo :: proc(a: $T, b: $T2) -> T2 {

    when T == int && T2 == int {
        c := a + b
    } else when T == f64 && T2 == f64 {
        c := a + b
    } else when T == f64 && T2 == int {
        c := a + f64(b)
    } else when T == int && T2 == f64 {
        c := f64(a) + b
    }

    return c
}

main :: proc() {
    fmt.println( foo( 100, 10.5 ) )
    fmt.println( foo( 1, 1 ) )
    fmt.println( foo( 5.5, 6.4 ) )
}
*/

pow :: proc(x: i32) -> i32 {
	return x * x
}

sign :: proc(x: i32) -> i32 {
	return -1 if x < 0 else 1
}

callback :: #type proc(_: i32) -> i32

//@(test)
array_of_procs :: proc(t: ^_t.T) {
	callbacks := make([dynamic]callback, 0, 0)
	defer delete(callbacks)

	append(&callbacks, callback(pow))
	append(&callbacks, callback(pow))
	append(&callbacks, callback(pow))
	append(&callbacks, callback(sign))

	for cb, i in callbacks {
		if (cb != nil) {
			fmt.printfln("Result: %d", cb(i32(i)))
		}
	}
}

ta :: struct {
	aa: int,
}
tb :: struct {
	#subtype a: ta,
	bb: int,
}
tc :: struct {
	using a: ta,
	cc:      int,
}
td :: struct {
	a:  ta,
	dd: int,
}

do_ta :: proc(v: ^ta) {
	fmt.println("aa:", v.aa)
}

//@(test)
subtypes :: proc(t: ^_t.T) {
	expect_int(t, size_of(ta), 8)
	expect_int(t, size_of(tb), 16)
	expect_int(t, size_of(tc), 16)
	expect_int(t, size_of(td), 16)

	b := tb {
		bb = 2,
		a = {aa = 21},
	}
	expect_int(t, b.bb, 2)
	expect_int(t, b.a.aa, 21)
	expect_int(t, ta(b).aa, 21)
	do_ta(&b)

	c := tc {
		cc = 3,
		aa = 31,
	}
	expect_int(t, c.cc, 3)
	expect_int(t, c.aa, 31)
	expect_int(t, c.a.aa, 31)
	expect_int(t, ta(c).aa, 31)
	do_ta(&c)

	d := td {
		dd = 4,
		a = {aa = 41},
	}
	expect_int(t, d.dd, 4)
	expect_int(t, d.a.aa, 41)
	//do_ta(&d)
}

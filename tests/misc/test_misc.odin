package test_misc

import "core:fmt"
import "core:os"
import _t "core:testing"
import "core:strings"
import _u "shared:ounit"

//TODO investigate #config

get_version :: proc() -> (res: int, err: bool) {
	return 666, false
}

@(test)
string_vs_cstring :: proc(t: ^_t.T) {
	str: string = "Can i convert"
	dst: cstring

	dst = strings.clone_to_cstring(str)

	//expect_value(t, v[0], 3)
	_t.expect(t, dst == "Can i convert")

	// NOTE: This is valid because 'clone_string' appends a NUL terminator
	// see core\encoding\json\unmarshal.odin unmarshal_string_token
	dst = cstring(raw_data(str))

	_t.expect(t, dst == "Can i convert")
}

// when
MODE :: 1

@(test)
when_to_use_when :: proc(t: ^_t.T) {
	str: cstring
	when MODE == 1 {
		str = "Can i convert"
	} else {
		str = "Oh no"
	}

	_t.expectf(t, str == "Can i convert", "%v", str)

	when ODIN_DEBUG {
		fmt.println("Debug")
	} else {
		fmt.println("Release")
	}
}

@(test)
when_to_use_config :: proc(t: ^_t.T) {
	val : i32
	val = #config(LA_COUR,   -1)
	_t.expectf(t, val == -1, "%v", val)
}

@(test)
when_to_use_defer :: proc(t: ^_t.T) {

	res := 0
	{
		res = 10
		defer res = 20
		_u.expect_value_int(t, res, 10)
	}
	_u.expect_value_int(t, res, 20)
	{
		defer res = 30;res = 40
		_u.expect_value_int(t, res, 40)
	}
	_u.expect_value_int(t, res, 30)
}

@(test)
some_slice :: proc(t: ^_t.T) {
	slice := []int{1, 4, 9, 7}
	_u.expect_value_int(t, slice[1], 4)
	fmt.printfln("%v", slice)
	fmt.printfln("%v", slice[1:3])
	fmt.printfln("%v", slice[1:])
	fmt.printfln("%v", slice[:3])
}

// Add leading 0x or 0X for hexadecimal (%#x or %#X)
@(test)
format_hex :: proc(t: ^_t.T) {
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
	fmt.println("\n#'#unroll for' statements")

	// '#unroll for' works the same as if the 'inline' prefix did not
	// exist but these ranged loops are explicitly unrolled which can
	// be very very useful for certain optimizations

	fmt.println("Ranges")
	#unroll for x, i in 1..<4 {
		fmt.println(x, i)
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

callback :: #type proc(i32) -> i32

@(test)
array_of_procs :: proc(t: ^_t.T) {
	callbacks := make([dynamic]callback, 0, 0)
	defer delete(callbacks)

	append(&callbacks, callback(pow))
	append(&callbacks, callback(pow))
	append(&callbacks, callback(pow))
	append(&callbacks, callback(sign))

	for p, i in callbacks {
		if (p != nil) {
			fmt.printfln("Result: %d", p(i32(i)))
		}
	}
}

a :: struct  {
	aa : int,
}
b :: struct  {
	#subtype a: a,
	bb : int,
}

do_a :: proc(v: ^a) {
	fmt.println(v)
}

@(test)
subtypes :: proc(t: ^_t.T) {
	sut := b{bb = 2, a = { aa = 3}}
	_u.expect_value_int(t, sut.bb, 2)
	_u.expect_value_int(t, a(sut).aa, 3)
	do_a(&sut)
}

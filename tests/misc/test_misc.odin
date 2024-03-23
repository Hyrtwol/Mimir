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
}

@(test)
when_to_use_defer :: proc(t: ^_t.T) {

	res := 0

	{
		res = 10
		defer res = 20

		_u.expect(t, res, 10)
	}

	_u.expect(t, res, 20)

	{
		defer res = 30;res = 40

		_u.expect(t, res, 40)
	}

	_u.expect(t, res, 30)
}

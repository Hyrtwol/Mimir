package test_misc

import "core:fmt"
import "core:os"
import "core:testing"
import "core:strings"
import "shared:ounit"

get_version :: proc() -> (res: int, err: bool) {
	return 666, false
}

@(test)
string_vs_cstring :: proc(t: ^testing.T) {
	using ounit

	str: string = "Can i convert"
	dst: cstring

	dst = strings.clone_to_cstring(str)

	//expect_value(t, v[0], 3)
	testing.expect(t, dst == "Can i convert")

	// NOTE: This is valid because 'clone_string' appends a NUL terminator
	// see core\encoding\json\unmarshal.odin unmarshal_string_token
	dst = cstring(raw_data(str))

	testing.expect(t, dst == "Can i convert")
}

// when
MODE :: 1

@(test)
when_to_use_when :: proc(t: ^testing.T) {
	using ounit

	str: cstring
	when MODE == 1 {
		str = "Can i convert"
	} else {
		str = "Oh no"
	}

	testing.expectf(t, str == "Can i convert", "%v", str)
}

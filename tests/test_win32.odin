package test_mimir

import "core:bytes"
import "core:fmt"
import "core:testing"
import win32app "../shared/tlc/win32app"

@(test)
make_lresult_from_false :: proc(t: ^testing.T) {
	exp := 0
	result := win32app.MAKELRESULT(false)
	testing.expect(t, result == exp, fmt.tprintf("MAKELRESULT: %v -> %v (should be: %v)", false, result, exp))
}

@(test)
make_lresult_from_true :: proc(t: ^testing.T) {
	exp := 1
	result := win32app.MAKELRESULT(true)
	testing.expect(t, result == exp, fmt.tprintf("MAKELRESULT: %v -> %v (should be: %v)", false, result, exp))
}

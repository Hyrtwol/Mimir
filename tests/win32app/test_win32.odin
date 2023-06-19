package test_mimir

import "core:bytes"
import "core:fmt"
import "core:runtime"
import "core:testing"
import win32 "core:sys/windows"
import win32app "../../shared/tlc/win32app"

@(test)
make_lresult_from_false :: proc(t: ^testing.T) {
	exp := 0
	result := win32app.MAKELRESULT(false)
	testing.expect(t, exp == result, fmt.tprintf("MAKELRESULT: %v -> %v (should be: %v)", false, result, exp))
}

@(test)
make_lresult_from_true :: proc(t: ^testing.T) {
	exp := 1
	result := win32app.MAKELRESULT(true)
	testing.expect(t, exp == result, fmt.tprintf("MAKELRESULT: %v -> %v (should be: %v)", false, result, exp))
}

@(test)
wstring_convert :: proc(t: ^testing.T) {
	exp := "ABC"
	wstr := win32.utf8_to_wstring(exp)
	result, err := win32.wstring_to_utf8(wstr, 256, context.allocator)
	testing.expect(t, exp == result, fmt.tprintf("wstring_convert: %v (should be: %v)", result, exp))
	testing.expect(t, err == .None, fmt.tprintf("wstring_convert: error %v", err))
}

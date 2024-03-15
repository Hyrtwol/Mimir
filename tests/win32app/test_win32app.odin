package test_win32app

import "core:bytes"
import "core:fmt"
import "core:intrinsics"
import "core:runtime"
import win32 "core:sys/windows"
import "core:testing"
import o "shared:ounit"
import win32ex "shared:sys/windows"
import win32app "shared:tlc/win32app"

L :: intrinsics.constant_utf16_cstring
utf8_to_wstring :: win32.utf8_to_wstring

@(test)
make_lresult_from_false :: proc(t: ^testing.T) {
	exp := 0
	result := win32ex.MAKELRESULT(false)
	testing.expect(t, exp == result, fmt.tprintf("MAKELRESULT: %v -> %v (should be: %v)", false, result, exp))
}

@(test)
make_lresult_from_true :: proc(t: ^testing.T) {
	exp := 1
	result := win32ex.MAKELRESULT(true)
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

@(test)
min_max_msg :: proc(t: ^testing.T) {

	p := wstring_convert
	o.expect_value(t, min(win32app.MSG), 0x0001)
	o.expect_value(t, max(win32app.MSG), 0x0204)
	o.expect_value(t, max(win32app.MSG), 516)
	o.expect_value(t, size_of(p), 8)
	o.expect_value(t, int(max(win32app.MSG)) * size_of(p), 4128)

	o.expect_value(t, min(win32app.MSG), win32app.MSG.WM_CREATE)
	o.expect_value(t, max(win32app.MSG), win32app.MSG.WM_RBUTTONDOWN)
}

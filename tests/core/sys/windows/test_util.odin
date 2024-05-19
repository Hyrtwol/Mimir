package test_core_sys_windows

import "core:bytes"
import "core:fmt"
import "base:runtime"
import "core:testing"
import win32 "core:sys/windows"
import win32ex "shared:sys/windows"

@(test)
make_lresult_from_false :: proc(t: ^testing.T) {
	exp := 0
	result := win32ex.MAKELRESULT(false)
	testing.expectf(t, exp == result, "MAKELRESULT: %v -> %v (should be: %v)", false, result, exp)
}

@(test)
make_lresult_from_true :: proc(t: ^testing.T) {
	exp := 1
	result := win32ex.MAKELRESULT(true)
	testing.expectf(t, exp == result, "MAKELRESULT: %v -> %v (should be: %v)", false, result, exp)
}

@(test)
wstring_convert :: proc(t: ^testing.T) {
	exp := "ABC"
	wstr := win32.utf8_to_wstring(exp)
	result, err := win32.wstring_to_utf8(wstr, 256, context.allocator)
	testing.expectf(t, exp == result, "wstring_convert: %v (should be: %v)", result, exp)
	testing.expectf(t, err == .None, "wstring_convert: error %v", err)
}

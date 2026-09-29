package test_core_sys_windows

import "base:runtime"
import "core:testing"
import win32 "core:sys/windows"

@(test)
wstring_convert :: proc(t: ^testing.T) {
	str := "ABC"
	wstr : cstring16 = win32.utf8_to_wstring(str)
	testing.expect_value(t, len(wstr), 3)
	result, err := win32.wstring_to_utf8(wstr, -1)
	testing.expect_value(t, err, nil)
	testing.expect_value(t, result, str)
}

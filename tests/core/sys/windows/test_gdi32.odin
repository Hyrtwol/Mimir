package test_core_sys_windows

import "core:testing"
import win32 "core:sys/windows"

@(test)
verify_bitmapv5_sizes :: proc(t: ^testing.T) {
	act, exp: u32

	act = size_of(win32.FXPT2DOT30)
	exp = 4
	testing.expectf(t, act == exp, "%v (should be: %v)", act, exp)

	act = size_of(win32.CIEXYZ)
	exp = 12
	testing.expectf(t, act == exp, "%v (should be: %v)", act, exp)

	act = size_of(win32.CIEXYZTRIPLE)
	exp = 36
	testing.expectf(t, act == exp, "%v (should be: %v)", act, exp)

	act = size_of(win32.BITMAPV5HEADER)
	exp = 124
	testing.expectf(t, act == exp, "%v (should be: %v)", act, exp)
}

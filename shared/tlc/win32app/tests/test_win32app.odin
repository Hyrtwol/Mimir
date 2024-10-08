package test_win32app

import win32app ".."
import "base:intrinsics"
import "base:runtime"
import "core:bytes"
import "core:fmt"
import "core:mem"
import "core:strings"
import win32 "core:sys/windows"
import "core:testing"
import win32ex "libs:sys/windows"
import ot "shared:ounit"

L :: intrinsics.constant_utf16_cstring
wstring :: win32.wstring
utf8_to_wstring :: win32.utf8_to_wstring

@(test)
make_lresult_from_false :: proc(t: ^testing.T) {
	exp: win32.LRESULT = 0
	result := win32ex.MAKELRESULT(false)
	testing.expect(t, exp == result, fmt.tprintf("MAKELRESULT: %v -> %v (should be: %v)", false, result, exp))
}

@(test)
make_lresult_from_true :: proc(t: ^testing.T) {
	exp: win32.LRESULT = 1
	result := win32ex.MAKELRESULT(true)
	testing.expect(t, exp == result, fmt.tprintf("MAKELRESULT: %v -> %v (should be: %v)", false, result, exp))
}

@(test)
min_max_msg :: proc(t: ^testing.T) {

	p := min_max_msg
	ot.expect_any_int(t, min(win32app.WM_MSG), 0x0001)
	ot.expect_any_int(t, max(win32app.WM_MSG), 0x0204)
	ot.expect_any_int(t, max(win32app.WM_MSG), 516)
	ot.expect_value(t, size_of(p), 8)
	ot.expect_value(t, int(max(win32app.WM_MSG)) * size_of(p), 4128)

	ot.expect_value(t, min(win32app.WM_MSG), win32app.WM_MSG.WM_CREATE)
	ot.expect_value(t, max(win32app.WM_MSG), win32app.WM_MSG.WM_RBUTTONDOWN)
}

@(test)
verify_bitmap_headers :: proc(t: ^testing.T) {
	//ot.expect_size(t, xatlasChart, 24)
	size: [2]i32 = {300, 200}
	ppm: i32 = 666
	bpp: u16 = 4
	bmp5 := win32.BITMAPV5HEADER {
		bV5Size          = size_of(win32.BITMAPV5HEADER),
		bV5Width         = size.x,
		bV5Height        = -size.y, // minus for top-down
		bV5Planes        = 1,
		bV5BitCount      = bpp,
		bV5Compression   = win32.BI_BITFIELDS,
		bV5XPelsPerMeter = 1001,
		bV5YPelsPerMeter = 1002,
		bV5RedMask       = 0x000000FF,
		bV5GreenMask     = 0x0000FF00,
		bV5BlueMask      = 0x00FF0000,
		bV5AlphaMask     = 0xFF000000,
	}
	pbmp5 := &bmp5
	pbmp := cast(^win32.BITMAPINFOHEADER)pbmp5
	ot.expect_value(t, pbmp5.bV5Size, pbmp.biSize)
	ot.expect_value(t, pbmp5.bV5Width, pbmp.biWidth)
	ot.expect_value(t, pbmp5.bV5Height, pbmp.biHeight)
	ot.expect_value(t, pbmp5.bV5Planes, pbmp.biPlanes)
	ot.expect_value(t, pbmp5.bV5BitCount, pbmp.biBitCount)
	ot.expect_value(t, pbmp5.bV5Compression, pbmp.biCompression)
	ot.expect_value(t, pbmp5.bV5SizeImage, pbmp.biSizeImage)
	ot.expect_value(t, pbmp5.bV5XPelsPerMeter, pbmp.biXPelsPerMeter)
	ot.expect_value(t, pbmp5.bV5YPelsPerMeter, pbmp.biYPelsPerMeter)
	ot.expect_value(t, pbmp5.bV5ClrUsed, pbmp.biClrUsed)
	ot.expect_value(t, pbmp5.bV5ClrImportant, pbmp.biClrImportant)
}

@(test)
wstring_print :: proc(t: ^testing.T) {
	msg := "Hello!"
	f :: "tprintf %s"
	exp :: "tprintf Hello!"

	smsg: string = msg
	cmsg: cstring = cstring("Hello!")
	wmsg: wstring = L("Hello!")
	ot.expect_value(t, win32app.wstring_byte_size(wmsg), 12)
	ot.expect_value(t, win32app.wstring_len(wmsg), 6)


	cmsg = fmt.ctprintf(f, msg)
	wmsg = win32app.wtprintf(f, msg)
	smsg = fmt.tprintf(f, msg)

	testing.expectf(t, smsg == exp, "%v (should be: %v)", smsg, exp)
	testing.expectf(t, cmsg == exp, "%v (should be: %v)", cmsg, exp)

	wexp := L(exp)
	wexp_size := len(exp) * size_of(win32.WCHAR)

	testing.expect(t, win32app.wstring_equal(wmsg, wexp))

	str: strings.Builder
	strings.builder_init(&str, context.temp_allocator)
	fmt.sbprintf(&str, f, msg)
	wmsg = win32app.to_wstring(str)

	ot.expect_value(t, mem.compare_byte_ptrs((^u8)(&wmsg[0]), (^u8)(&wexp[0]), wexp_size), 0)
}

@(test)
check_mouse_key_state_flags :: proc(t: ^testing.T) {
	expect_state :: proc(t: ^testing.T, val: win32app.MOUSE_KEY_STATE, exp: u32) {
		testing.expect_value(t, transmute(u32)val, exp)
	}
	expect_state(t, {.MK_LBUTTON}, win32.MK_LBUTTON)
	expect_state(t, {.MK_RBUTTON}, win32.MK_RBUTTON)
	expect_state(t, {.MK_SHIFT}, win32.MK_SHIFT)
	expect_state(t, {.MK_CONTROL}, win32.MK_CONTROL)
	expect_state(t, {.MK_MBUTTON}, win32.MK_MBUTTON)
	expect_state(t, {.MK_XBUTTON1}, win32.MK_XBUTTON1)
	expect_state(t, {.MK_XBUTTON2}, win32.MK_XBUTTON2)
}

@(test)
verify_sizes :: proc(t: ^testing.T) {
	ot.expect_size(t, win32app.DWORD, 4)
	ot.expect_size(t, win32app.MOUSE_KEY_STATE, 4)
}

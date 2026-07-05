package test_owin

import owin ".."
import "base:intrinsics"
import "base:runtime"
import "core:bytes"
import "core:fmt"
import "core:mem"
import "core:strings"
import win32 "core:sys/windows"
import "core:testing"
import win32ex "libs:sys/windows"
import "shared:ounit"

L :: intrinsics.constant_utf16_cstring
wstring :: win32.wstring
utf8_to_wstring :: win32.utf8_to_wstring

expect_flags :: ounit.expect_flags
expect_size :: ounit.expect_size
expect_value :: ounit.expect_any_int

@(test)
verify_winnt :: proc(t: ^testing.T) {
	// winnt.h
	expect_size(t, owin.BYTE, 1)
	expect_size(t, owin.BOOL, 4)
	expect_size(t, owin.WORD, 2)
	expect_size(t, owin.LONG, 4)
	expect_size(t, owin.DWORD, 4)
	expect_size(t, owin.WCHAR, 2)
	expect_size(t, owin.HANDLE, 8)
	expect_size(t, owin.HRESULT, 4)
	expect_size(t, owin.HRESULT_DETAILS, 4)
}

@(test)
verify_sizes :: proc(t: ^testing.T) {
	expect_size(t, owin.CREATESTRUCTW, 80)
	expect_size(t, owin.CREATESTRUCT, 80)
}

@(test)
verify_consts :: proc(t: ^testing.T) {
	testing.expect_value(t, owin.HPEN_NULL, owin.HPEN(uintptr(5)))
	testing.expect_value(t, owin.HBRUSH_NULL, owin.HBRUSH(uintptr(1)))
	testing.expect_value(t, owin.LANGID_NEUTRAL_DEFAULT, 0x400)
	testing.expect_value(t, owin.LANGID_NEUTRAL_DEFAULT, win32.MAKELANGID(win32.LANG_NEUTRAL, win32.SUBLANG_DEFAULT))
}

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
verify_error_helpers :: proc(t: ^testing.T) {
	testing.expect_value(t, owin.SUCCEEDED(-1), false)
	testing.expect_value(t, owin.SUCCEEDED(0), true)
	testing.expect_value(t, owin.SUCCEEDED(1), true)

	testing.expect_value(t, owin.FAILED(-1), true)
	testing.expect_value(t, owin.FAILED(0), false)
	testing.expect_value(t, owin.FAILED(1), false)

	testing.expect_value(t, owin.IS_ERROR(-1), true)
	testing.expect_value(t, owin.IS_ERROR(0), false)
	testing.expect_value(t, owin.IS_ERROR(1), false)

	testing.expect_value(t, owin.HRESULT_CODE(0xFFFFCCCC), 0x0000CCCC)
	testing.expect_value(t, owin.HRESULT_FACILITY(0xFFFFCCCC), owin.FACILITY(0x00001FFF))
	testing.expect_value(t, owin.HRESULT_SEVERITY(0x12345678), owin.SEVERITY(0x00000000))
	testing.expect_value(t, owin.HRESULT_SEVERITY(0x87654321), owin.SEVERITY(0x00000001))

	testing.expect_value(t, u32(owin.MAKE_HRESULT(1, 2, 3)), 0x80020003)
}

@(test)
decode_hresult :: proc(t: ^testing.T) {
	hr := owin.DECODE_HRESULT(win32.E_INVALIDARG)
	testing.expect_value(t, hr.IsError, true)
	testing.expect_value(t, hr.R, false)
	testing.expect_value(t, hr.Customer, false)
	testing.expect_value(t, hr.N, false)
	testing.expect_value(t, hr.X, false)
	testing.expect_value(t, hr.Facility, owin.FACILITY.WIN32)
	testing.expect_value(t, hr.Code, u16(win32.System_Error.INVALID_PARAMETER))
}

@(test)
get_hresult_details :: proc(t: ^testing.T) {
	hr : owin.HRESULT_DETAILS
	hr = transmute(owin.HRESULT_DETAILS)(u32(win32.E_INVALIDARG))
	testing.expect_value(t, hr.IsError, true)
	testing.expect_value(t, hr.R, false)
	testing.expect_value(t, hr.Customer, false)
	testing.expect_value(t, hr.N, false)
	testing.expect_value(t, hr.X, false)
	testing.expect_value(t, hr.Facility, owin.FACILITY.WIN32)
	testing.expect_value(t, hr.Code, u16(win32.System_Error.INVALID_PARAMETER))
	ounit.expect_value_str(t, fmt.tprintf("%v", hr), "HRESULT_DETAILS{Code = 87, Facility = WIN32, X = false, N = false, Customer = false, R = false, IsError = true}")
}

@(test)
min_max_msg :: proc(t: ^testing.T) {

	p := min_max_msg
	ounit.expect_any_int(t, min(owin.WM_MSG), 0x0001)
	ounit.expect_any_int(t, max(owin.WM_MSG), 0x0214)
	ounit.expect_value(t, size_of(p), 8)
	ounit.expect_value(t, int(max(owin.WM_MSG)) * size_of(p), 4256)

	ounit.expect_value(t, min(owin.WM_MSG), owin.WM_MSG.WM_CREATE)
	ounit.expect_value(t, max(owin.WM_MSG), owin.WM_MSG.WM_SIZING)
}

@(test)
verify_bitmap_headers :: proc(t: ^testing.T) {
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
	ounit.expect_value(t, pbmp5.bV5Size, pbmp.biSize)
	ounit.expect_value(t, pbmp5.bV5Width, pbmp.biWidth)
	ounit.expect_value(t, pbmp5.bV5Height, pbmp.biHeight)
	ounit.expect_value(t, pbmp5.bV5Planes, pbmp.biPlanes)
	ounit.expect_value(t, pbmp5.bV5BitCount, pbmp.biBitCount)
	ounit.expect_value(t, pbmp5.bV5Compression, pbmp.biCompression)
	ounit.expect_value(t, pbmp5.bV5SizeImage, pbmp.biSizeImage)
	ounit.expect_value(t, pbmp5.bV5XPelsPerMeter, pbmp.biXPelsPerMeter)
	ounit.expect_value(t, pbmp5.bV5YPelsPerMeter, pbmp.biYPelsPerMeter)
	ounit.expect_value(t, pbmp5.bV5ClrUsed, pbmp.biClrUsed)
	ounit.expect_value(t, pbmp5.bV5ClrImportant, pbmp.biClrImportant)
}

@(test)
wstring_print :: proc(t: ^testing.T) {
	msg := "Hello!"
	f :: "tprintf %s"
	exp :: "tprintf Hello!"

	smsg: string = msg
	cmsg: cstring = cstring("Hello!")
	wmsg: wstring = L("Hello!")
	ounit.expect_value(t, owin.wstring_byte_size(wmsg), 12)
	ounit.expect_value(t, owin.wstring_len(wmsg), 6)


	cmsg = fmt.ctprintf(f, msg)
	wmsg = owin.wtprintf(f, msg)
	smsg = fmt.tprintf(f, msg)

	testing.expectf(t, smsg == exp, "%v (should be: %v)", smsg, exp)
	testing.expectf(t, cmsg == exp, "%v (should be: %v)", cmsg, exp)

	wexp: wstring = L(exp)
	wexp_size := len(exp) * size_of(win32.WCHAR)

	testing.expect(t, owin.wstring_equal(wmsg, wexp))

	str: strings.Builder
	strings.builder_init(&str, context.temp_allocator)
	fmt.sbprintf(&str, f, msg)
	wmsg = owin.to_wstring(str)

	// ounit.expect_value(t, mem.compare_byte_ptrs((^u8)(&wmsg[0]), (^u8)(&wexp[0]), wexp_size), 0)
	testing.expect_value(t, wmsg, wexp)
}

@(test)
check_mouse_key_state_flags :: proc(t: ^testing.T) {
	expect_state :: proc(t: ^testing.T, val: owin.MOUSE_KEY_STATE, exp: u32) {
		testing.expect_value(t, transmute(u32)val, exp)
	}
	expect_size(t, owin.MOUSE_KEY_STATE, 4)
	expect_state(t, {.MK_LBUTTON}, win32.MK_LBUTTON)
	expect_state(t, {.MK_RBUTTON}, win32.MK_RBUTTON)
	expect_state(t, {.MK_SHIFT}, win32.MK_SHIFT)
	expect_state(t, {.MK_CONTROL}, win32.MK_CONTROL)
	expect_state(t, {.MK_MBUTTON}, win32.MK_MBUTTON)
	expect_state(t, {.MK_XBUTTON1}, win32.MK_XBUTTON1)
	expect_state(t, {.MK_XBUTTON2}, win32.MK_XBUTTON2)
}

@(test)
verify_ws_ex_style :: proc(t: ^testing.T) {
	expect_flags(t, owin.WS_EX_STYLES{.WS_EX_DLGMODALFRAME}, 0x00000001)
	expect_flags(t, owin.WS_EX_STYLES{.WS_EX_NOPARENTNOTIFY}, 0x00000004)
	expect_flags(t, owin.WS_EX_STYLES{.WS_EX_TOPMOST}, 0x00000008)
	expect_flags(t, owin.WS_EX_STYLES{.WS_EX_ACCEPTFILES}, 0x00000010)
	expect_flags(t, owin.WS_EX_STYLES{.WS_EX_TRANSPARENT}, 0x00000020)
	expect_flags(t, owin.WS_EX_STYLES{.WS_EX_MDICHILD}, 0x00000040)
	expect_flags(t, owin.WS_EX_STYLES{.WS_EX_TOOLWINDOW}, 0x00000080)
	expect_flags(t, owin.WS_EX_STYLES{.WS_EX_WINDOWEDGE}, 0x00000100)
	expect_flags(t, owin.WS_EX_STYLES{.WS_EX_CLIENTEDGE}, 0x00000200)
	expect_flags(t, owin.WS_EX_STYLES{.WS_EX_CONTEXTHELP}, 0x00000400)
	expect_flags(t, owin.WS_EX_STYLES{.WS_EX_RIGHT}, 0x00001000)
	expect_flags(t, owin.WS_EX_STYLES{.WS_EX_RTLREADING}, 0x00002000)
	expect_flags(t, owin.WS_EX_STYLES{.WS_EX_LEFTSCROLLBAR}, 0x00004000)
	expect_flags(t, owin.WS_EX_STYLES{.WS_EX_CONTROLPARENT}, 0x00010000)
	expect_flags(t, owin.WS_EX_STYLES{.WS_EX_STATICEDGE}, 0x00020000)
	expect_flags(t, owin.WS_EX_STYLES{.WS_EX_APPWINDOW}, 0x00040000)
	expect_flags(t, owin.WS_EX_STYLES{.WS_EX_LAYERED}, 0x00080000)
	expect_flags(t, owin.WS_EX_STYLES{.WS_EX_NOINHERITLAYOUT}, 0x00100000)
	expect_flags(t, owin.WS_EX_STYLES{.WS_EX_NOREDIRECTIONBITMAP}, 0x00200000)
	expect_flags(t, owin.WS_EX_STYLES{.WS_EX_LAYOUTRTL}, 0x00400000)
	expect_flags(t, owin.WS_EX_STYLES{.WS_EX_COMPOSITED}, 0x02000000)
	expect_flags(t, owin.WS_EX_STYLES{.WS_EX_NOACTIVATE}, 0x08000000)
}

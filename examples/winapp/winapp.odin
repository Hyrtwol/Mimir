package main

import          "core:fmt"
import          "core:intrinsics"
import          "core:math/rand"
import          "core:runtime"
import win32    "core:sys/windows"
import win32app "shared:tlc/win32app"
import canvas   "shared:tlc/canvas"

L :: intrinsics.constant_utf16_cstring

TITLE 	:: "Mimir"
WIDTH  	:: 640
HEIGHT 	:: WIDTH * 9 / 16
CENTER  :: true
ZOOM  	:: 8

screen_buffer  :: canvas.screen_buffer

bitmap_handle : win32.HGDIOBJ // win32.HBITMAP
bitmap_size   : win32app.int2
bitmap_count  : i32
pvBits        : screen_buffer
pixel_size    : win32app.int2 : {ZOOM, ZOOM}

dib           : canvas.DIB
timer1_id     : win32.UINT_PTR
timer2_id     : win32.UINT_PTR

rng := rand.create(u64(intrinsics.read_cycle_counter()))

application :: struct {
	title: string,
	size : [2]i32,
	center: bool,
}

set_app :: #force_inline proc(hwnd: win32.HWND, app: ^application) {win32.SetWindowLongPtrW(hwnd, win32.GWLP_USERDATA, win32.LONG_PTR(uintptr(app)))}
get_app :: #force_inline proc(hwnd: win32.HWND) -> ^application {return (^application)(rawptr(uintptr(win32.GetWindowLongPtrW(hwnd, win32.GWLP_USERDATA))))}

decode_scrpos :: proc(lparam: win32.LPARAM) -> win32app.int2 {
	scrpos := win32app.decode_lparam(lparam) / ZOOM
	scrpos.y = bitmap_size.y - 1 - scrpos.y
	return scrpos
}

random_scrpos :: proc() -> win32app.int2 {
	return {rand.int31_max(bitmap_size.x, &rng), rand.int31_max(bitmap_size.y, &rng)}
}

setdot :: proc(pos: win32app.int2, col: canvas.byte4) {
	i := pos.y * bitmap_size.x + pos.x
	if i >= 0 && i < bitmap_count {
		pvBits[i] = col
	}
}

WM_CREATE :: proc(hwnd: win32.HWND, lparam: win32.LPARAM) -> win32.LRESULT {
	fmt.print("WM_CREATE\n")

	timer1_id = win32.SetTimer(hwnd, win32app.IDT_TIMER1, 1000, nil)
	if timer1_id == 0 {win32app.show_error_and_panic("No timer 1")}
	timer2_id = win32.SetTimer(hwnd, win32app.IDT_TIMER2, 3000, nil)
	if timer2_id == 0 {win32app.show_error_and_panic("No timer 2")}

	client_size := win32app.get_client_size(hwnd)
	bitmap_size = client_size / ZOOM

	hdc := win32.GetDC(hwnd)
	// todo defer win32.ReleaseDC(hwnd, hdc)

	pels_per_meter :: 3780
	ColorSizeInBytes :: 4
	BitCount :: ColorSizeInBytes * 8

	bmi_header := win32.BITMAPINFOHEADER {
		biSize = size_of(win32.BITMAPINFOHEADER),
		biWidth = bitmap_size.x,
		biHeight = bitmap_size.y,
		biPlanes = 1,
		biBitCount = BitCount,
		biCompression = win32.BI_RGB,
		biSizeImage = 0,
		biXPelsPerMeter = pels_per_meter,
		biYPelsPerMeter = pels_per_meter,
		biClrImportant = 0,
		biClrUsed = 0,
	}

	bitmap_handle = win32.HGDIOBJ(win32.CreateDIBSection(hdc, cast(^win32.BITMAPINFO)&bmi_header, 0, &pvBits, nil, 0))

	if pvBits != nil {
		bitmap_count = bitmap_size.x * bitmap_size.y
		canvas.fill_screen(pvBits, bitmap_count, {150, 100, 50, 255})
	} else {
		bitmap_size = {0, 0}
		bitmap_count = 0
	}

	win32.ReleaseDC(hwnd, hdc)

	return 0
}

WM_DESTROY :: proc(hwnd: win32.HWND) -> win32.LRESULT {
	fmt.print("WM_DESTROY\n")

	if timer1_id != 0 {
		if !win32.KillTimer(hwnd, timer1_id) {
			win32.MessageBoxW(nil, L("Unable to kill timer1"), L("Error"), win32.MB_OK)
		}
	}
	if timer2_id != 0 {
		if !win32.KillTimer(hwnd, timer2_id) {
			win32.MessageBoxW(nil, L("Unable to kill timer2"), L("Error"), win32.MB_OK)
		}
	}

	if bitmap_handle != nil {
		win32.DeleteObject(bitmap_handle)
	}
	bitmap_handle = nil
	bitmap_size = {0, 0}
	bitmap_count = 0
	pvBits = nil

	win32.PostQuitMessage(0)
	return 0
}

WM_ERASEBKGND :: proc(hwnd: win32.HWND, wparam: win32.WPARAM) -> win32.LRESULT {
	return 1
}

WM_CHAR :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	switch wparam {
	case '\x1b':	win32.DestroyWindow(hwnd)
	case:			fmt.printf("WM_CHAR %4d 0x%4x 0x%4x 0x%4x\n", wparam, wparam, win32.HIWORD(u32(lparam)), win32.LOWORD(u32(lparam)))
	}
	return 0
}

WM_SIZE :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	type := win32app.WM_SIZE_WPARAM(wparam)
	size := win32app.decode_lparam(lparam)
	new_title := fmt.tprintf("%s %v %v\n", TITLE, size, bitmap_size)
	win32.SetWindowTextW(hwnd, win32.utf8_to_wstring(new_title))
	return 0
}

WM_PAINT :: proc(hwnd: win32.HWND) -> win32.LRESULT {
	ps: win32.PAINTSTRUCT
	win32.BeginPaint(hwnd, &ps) // todo check if defer can be used for EndPaint
	defer win32.EndPaint(hwnd, &ps)

	hdc_source := win32.CreateCompatibleDC(ps.hdc)
	defer win32.DeleteDC(hdc_source)

	client_size := win32app.get_rect_size(&ps.rcPaint)
	win32.SelectObject(hdc_source, bitmap_handle)
	win32.StretchBlt(ps.hdc, 0, 0, client_size.x, client_size.y, hdc_source, 0, 0, bitmap_size.x, bitmap_size.y, win32.SRCCOPY)

	return 0
}

WM_TIMER :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	switch (wparam)
	{
		case win32app.IDT_TIMER1: setdot_invalidate(hwnd, random_scrpos(), canvas.COLOR_CYAN)
		case win32app.IDT_TIMER2: setdot_invalidate(hwnd, random_scrpos(), canvas.COLOR_YELLOW)
	}
	return 0
}

setdot_invalidate :: proc(hwnd: win32.HWND, pos: win32app.int2, col: canvas.byte4) {
	setdot(pos, col)
	win32.InvalidateRect(hwnd, nil, false)
}

decode_setdot :: proc(hwnd: win32.HWND, lparam: win32.LPARAM, col: canvas.byte4) {
	setdot_invalidate(hwnd, decode_scrpos(lparam), col)
}

// odinfmt: disable

handle_input :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	switch wparam {
	case 1: decode_setdot(hwnd, lparam, canvas.COLOR_RED)
	case 2: decode_setdot(hwnd, lparam, canvas.COLOR_BLUE)
	case 3: decode_setdot(hwnd, lparam, canvas.COLOR_GREEN)
	case: //fmt.printf("input %v %d\n", decode_scrpos(lparam), wparam)
	}
	return 0
}

wndproc :: proc "system" (hwnd: win32.HWND, msg: win32app.WM_MSG, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	context = runtime.default_context()
	switch msg {
	case .WM_CREATE:		return WM_CREATE(hwnd, lparam)
	case .WM_DESTROY:		return WM_DESTROY(hwnd)
	case .WM_ERASEBKGND:	return WM_ERASEBKGND(hwnd, wparam)
	case .WM_SIZE:			return WM_SIZE(hwnd, wparam, lparam)
	case .WM_PAINT:			return WM_PAINT(hwnd)
	case .WM_CHAR:			return WM_CHAR(hwnd, wparam, lparam)
	case .WM_TIMER:			return WM_TIMER(hwnd, wparam, lparam)
	case .WM_MOUSEMOVE:		return handle_input(hwnd, wparam, lparam)
	case .WM_LBUTTONDOWN:	return handle_input(hwnd, wparam, lparam)
	case .WM_RBUTTONDOWN:	return handle_input(hwnd, wparam, lparam)
	case:					return win32.DefWindowProcW(hwnd, win32.UINT(msg), wparam, lparam)
	}
}

// odinfmt: enable

main :: proc() {

	stopwatch := win32app.create_stopwatch()
	stopwatch->start()

	settings := win32app.create_window_settings(TITLE, WIDTH, HEIGHT, wndproc)
	win32app.run(&settings)

	stopwatch->stop()
	fmt.printf("Done! (%fs)\n", stopwatch->get_delta_seconds())
}

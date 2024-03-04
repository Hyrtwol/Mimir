package main

import          "core:fmt"
import          "core:intrinsics"
import          "core:math"
import          "core:math/linalg"
import hlm      "core:math/linalg/hlsl"
import          "core:math/noise"
import          "core:math/rand"
import          "core:mem"
import          "core:runtime"
import          "core:simd"
import          "core:strings"
import win32    "core:sys/windows"
import          "core:time"
import win32ex  "shared:sys/windows"
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

decode_scrpos :: proc(lparam: win32.LPARAM) -> win32app.int2 {
	scrpos := win32app.decode_lparam(lparam) / ZOOM
	scrpos.y = bitmap_size.y - 1 - scrpos.y
	return scrpos
}

setdot :: proc(pos: win32app.int2, col: canvas.byte4) {
	i := pos.y * bitmap_size.x + pos.x
	if i >= 0 && i < bitmap_count {
		pvBits[i] = col
	}
}

WM_CREATE :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	fmt.print("WM_CREATE\n")

	client_size := win32app.get_client_size(hwnd)
	bitmap_size = client_size / ZOOM

	hdc := win32.GetDC(hwnd)
	// todo defer win32.ReleaseDC(hwnd, hdc)

	PelsPerMeter :: 3780
	ColorSizeInBytes :: 4
	BitCount :: ColorSizeInBytes * 8

	bmiHeader := win32.BITMAPINFOHEADER {
		biSize = size_of(win32.BITMAPINFOHEADER),
		biWidth = bitmap_size.x,
		biHeight = bitmap_size.y,
		biPlanes = 1,
		biBitCount = BitCount,
		biCompression = win32.BI_RGB,
		biSizeImage = 0,
		biXPelsPerMeter = PelsPerMeter,
		biYPelsPerMeter = PelsPerMeter,
		biClrImportant = 0,
		biClrUsed = 0,
	}

	bitmap_handle = win32.HGDIOBJ(win32.CreateDIBSection(hdc, cast(^win32.BITMAPINFO)&bmiHeader, 0, &pvBits, nil, 0))

	if pvBits != nil {
		bitmap_count = bitmap_size.x * bitmap_size.y
		canvas.fill_screen(pvBits, bitmap_count, {150, 100, 50, 255})
	} else {
		bitmap_size = canvas.ZERO2
		bitmap_count = 0
	}

	win32.ReleaseDC(hwnd, hdc)

	timer1_id = win32.SetTimer(hwnd, win32app.IDT_TIMER1, 1000, nil)
	if timer1_id == 0 {
		win32app.show_error_and_panic("No timer 1")
	}
	timer2_id = win32.SetTimer(hwnd, win32app.IDT_TIMER2, 3000, nil)
	if timer2_id == 0 {
		win32app.show_error_and_panic("No timer 2")
	}

	return 0
}

WM_DESTROY :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
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
	bitmap_size = canvas.ZERO2
	bitmap_count = 0
	pvBits = nil

	win32.PostQuitMessage(0)
	return 0
}

WM_ERASEBKGND :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	return 1
}

WM_CHAR :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	fmt.printf("WM_CHAR %4d 0x%4x 0x%4x 0x%4x\n", wparam, wparam, win32.HIWORD(u32(lparam)), win32.LOWORD(u32(lparam)))
	switch wparam {
	case '\x1b':	win32.DestroyWindow(hwnd)
	case:
	}
	return 0
}

WM_SIZE :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	size := win32app.decode_lparam(lparam)
	newtitle := fmt.tprintf("%s %v %v\n", TITLE, size, bitmap_size)
	win32.SetWindowTextW(hwnd, win32.utf8_to_wstring(newtitle))
	return 0
}

WM_PAINT :: proc(hwnd: win32.HWND) -> win32.LRESULT {
	ps: win32.PAINTSTRUCT
	win32.BeginPaint(hwnd, &ps) // todo check if defer can be used for EndPaint
	defer win32.EndPaint(hwnd, &ps)

	hdc_source := win32ex.CreateCompatibleDC(ps.hdc)
	defer win32ex.DeleteDC(hdc_source)

	client_size := win32app.get_rect_size(&ps.rcPaint)
	win32.SelectObject(hdc_source, bitmap_handle)
	win32.StretchBlt(ps.hdc, 0, 0, client_size.x, client_size.y, hdc_source, 0, 0, bitmap_size.x, bitmap_size.y, win32.SRCCOPY)

	return 0
}

WM_TIMER :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	switch (wparam)
	{
	case win32app.IDT_TIMER1: fmt.print("TIK\n")
	case win32app.IDT_TIMER2: fmt.print("TOK\n")
	}
	return 0
}

decode_setdot :: proc(hwnd: win32.HWND, lparam: win32.LPARAM, col: canvas.byte4) {
	pos := decode_scrpos(lparam)
	setdot(pos, col)
	win32.InvalidateRect(hwnd, nil, false)
}

handle_input :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	switch wparam {
	case 1: decode_setdot(hwnd, lparam, canvas.COLOR_RED)
	case 2: decode_setdot(hwnd, lparam, canvas.COLOR_BLUE)
	case 3: decode_setdot(hwnd, lparam, canvas.COLOR_GREEN)
	case:   //fmt.printf("input %v %d\n", decode_scrpos(lparam), wparam)
	}
	return 0
}

wndproc :: proc "system" (hwnd: win32.HWND, msg: win32.UINT, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	context = runtime.default_context()
	switch msg {
	case win32.WM_CREATE:		return WM_CREATE(hwnd, wparam, lparam)
	case win32.WM_DESTROY:		return WM_DESTROY(hwnd, wparam, lparam)
	case win32.WM_ERASEBKGND:	return WM_ERASEBKGND(hwnd, wparam, lparam)
	case win32.WM_SIZE:			return WM_SIZE(hwnd, wparam, lparam)
	case win32.WM_PAINT:		return WM_PAINT(hwnd)
	case win32.WM_CHAR:			return WM_CHAR(hwnd, wparam, lparam)
	case win32.WM_TIMER:		return WM_TIMER(hwnd, wparam, lparam)
	case win32.WM_MOUSEMOVE:	return handle_input(hwnd, wparam, lparam)
	case win32.WM_LBUTTONDOWN:	return handle_input(hwnd, wparam, lparam)
	case win32.WM_RBUTTONDOWN:	return handle_input(hwnd, wparam, lparam)
	case:						return win32.DefWindowProcW(hwnd, msg, wparam, lparam)
	}
}

main :: proc() {
	settings := win32app.create_window_settings(TITLE, WIDTH, HEIGHT, wndproc)
	win32app.run(&settings)
}

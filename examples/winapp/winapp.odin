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
import win32app "../../shared/tlc/win32app"
import canvas   "../../shared/tlc/canvas"

L :: intrinsics.constant_utf16_cstring

TITLE 	:: "Mimir"
WIDTH  	:: 640
HEIGHT 	:: WIDTH * 9 / 16
CENTER  :: true
ZOOM  	:: 8

screenbuffer  :: canvas.screenbuffer

bitmap_handle : win32.HGDIOBJ // win32.HBITMAP
bitmap_size   : win32app.int2
bitmap_count  : i32
pvBits        : screenbuffer
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
	size := win32app.int2({win32.GET_X_LPARAM(lparam), win32.GET_Y_LPARAM(lparam)})
	newtitle := fmt.tprintf("%s %v %v\n", TITLE, size, bitmap_size)
	win32.SetWindowTextW(hwnd, win32.utf8_to_wstring(newtitle))
	return 0
}

WM_PAINT :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	ps: win32.PAINTSTRUCT
	hdc_target := win32.BeginPaint(hwnd, &ps) // todo check if defer can be used for EndPaint
	assert(hdc_target == ps.hdc)
	client_size := win32app.get_client_size(hwnd)
	assert(client_size == win32app.get_rect_size(&ps.rcPaint))

	hdc_source := win32app.CreateCompatibleDC(hdc_target)
	win32.SelectObject(hdc_source, bitmap_handle)
	win32.StretchBlt(
		hdc_target, 0, 0, client_size.x, client_size.y,
		hdc_source, 0, 0, bitmap_size.x, bitmap_size.y,
		win32.SRCCOPY,
	)
	win32app.DeleteDC(hdc_source)

	win32.EndPaint(hwnd, &ps)
	return 0
}

// https://learn.microsoft.com/en-us/windows/win32/winmsg/using-timers
WM_TIMER :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	switch (wparam)
	{
	case win32app.IDT_TIMER1: fmt.print("TIK\n")
	case win32app.IDT_TIMER2: fmt.print("TOK\n")
	}
	return 0
}

WM_MOUSEMOVE :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	return handle_input(hwnd, wparam, lparam)
}

WM_LBUTTONDOWN :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	return handle_input(hwnd, wparam, lparam)
}

WM_RBUTTONDOWN :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	return handle_input(hwnd, wparam, lparam)
}

handle_input :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	switch wparam {
	case 1:
		pos := decode_scrpos(lparam)
		setdot(pos, canvas.COLOR_RED)
		win32.InvalidateRect(hwnd, nil, false)
	case 2:
		pos := decode_scrpos(lparam)
		setdot(pos, canvas.COLOR_BLUE)
		win32.InvalidateRect(hwnd, nil, false)
	case 3:
		pos := decode_scrpos(lparam)
		setdot(pos, canvas.COLOR_GREEN)
		win32.InvalidateRect(hwnd, nil, false)
	case 4:
		fmt.printf("input %v %d\n", decode_scrpos(lparam), wparam)
	case:
		//fmt.printf("input %v %d\n", decode_scrpos(lparam), wparam)
	}
	return 0
}

wndproc :: proc "stdcall" ( hwnd: win32.HWND, msg: win32.UINT, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	context = runtime.default_context()
	switch msg {
	case win32.WM_CREATE:		return WM_CREATE(hwnd, wparam, lparam)
	case win32.WM_DESTROY:		return WM_DESTROY(hwnd, wparam, lparam)
	case win32.WM_ERASEBKGND:	return WM_ERASEBKGND(hwnd, wparam, lparam)
	case win32.WM_SIZE:			return WM_SIZE(hwnd, wparam, lparam)
	case win32.WM_PAINT:		return WM_PAINT(hwnd, wparam, lparam)
	case win32.WM_CHAR:			return WM_CHAR(hwnd, wparam, lparam)
	case win32.WM_MOUSEMOVE:	return WM_MOUSEMOVE(hwnd, wparam, lparam)
	case win32.WM_LBUTTONDOWN:	return WM_LBUTTONDOWN(hwnd, wparam, lparam)
	case win32.WM_RBUTTONDOWN:	return WM_RBUTTONDOWN(hwnd, wparam, lparam)
	case win32.WM_TIMER:		return WM_TIMER(hwnd, wparam, lparam)
	case:						return win32.DefWindowProcW(hwnd, msg, wparam, lparam)
	}
}

main :: proc() {
	settings : win32app.window_settings = {
		title = TITLE,
		window_size = {WIDTH, HEIGHT},
		center = CENTER,
	}
	win32app.run(&settings, wndproc)
}

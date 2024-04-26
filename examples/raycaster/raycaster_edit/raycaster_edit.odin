// vet
package raycaster_edit

import "core:fmt"
import "core:intrinsics"
import "core:runtime"
import win32 "core:sys/windows"
import cv "libs:tlc/canvas"
import win32app "libs:tlc/win32app"

L :: intrinsics.constant_utf16_cstring

TITLE :: "Raw Input"
ZOOM :: 24
WIDTH :: ZOOM * 32
HEIGHT :: WIDTH

application :: struct {
	// title: string,
	// size : [2]i32,
	// center: bool,
}
papp :: ^application

settings := win32app.create_window_settings(TITLE, {WIDTH, HEIGHT}, wndproc)
dib: win32app.DIB

mouse_pos: win32app.int2 = {0, 0}
is_active: bool = true
is_focused := false
cursor_state: i32 = 0

show_cursor :: proc(show: bool) {
	cursor_state = win32app.show_cursor(show)
	fmt.println(#procedure, cursor_state)
}

clip_cursor :: proc(hwnd: win32.HWND, clip: bool) -> bool {
	return win32app.clip_cursor(hwnd, clip)
}

// decode_scrpos :: proc(lparam: win32.LPARAM) -> win32app.int2 {
// 	size := win32app.decode_lparam(lparam)
// 	return size / ZOOM
// }

// set_dot :: proc(pos: win32app.int2, col: cv.byte4) {
// 	cv.canvas_set_dot(&dib.canvas, pos, col)
// }



WM_CREATE :: proc(hwnd: win32.HWND, lparam: win32.LPARAM) -> win32.LRESULT {
	fmt.println(#procedure)

	//show_cursor(false)

	client_size := win32app.get_client_size(hwnd)

	hdc := win32.GetDC(hwnd)
	defer win32.ReleaseDC(hwnd, hdc)

	dib = win32app.dib_create_v5(hdc, client_size / ZOOM)
	if dib.canvas.pvBits != nil {
		cv.canvas_clear(&dib, cv.W95_NAVY)
	}

	return 0
}

WM_DESTROY :: proc(hwnd: win32.HWND) -> win32.LRESULT {
	fmt.println(#procedure)
	clip_cursor(hwnd, false)
	if cursor_state < 1 {
		show_cursor(true)
	}
	win32app.dib_free_section(&dib)
	win32app.post_quit_message()
	return 0
}

WM_SIZE :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	settings.window_size = win32app.decode_lparam(lparam)
	win32app.set_window_textf(hwnd, "%s %v %v", TITLE, settings.window_size, dib.canvas.size)
	clip_cursor(hwnd, true)
	return 0
}

WM_PAINT :: proc(hwnd: win32.HWND) -> win32.LRESULT {
	ps: win32.PAINTSTRUCT
	win32.BeginPaint(hwnd, &ps) // todo check if defer can be used for EndPaint
	defer win32.EndPaint(hwnd, &ps)

	hdc_source := win32.CreateCompatibleDC(ps.hdc)
	defer win32.DeleteDC(hdc_source)

	client_size := win32app.get_rect_size(&ps.rcPaint)
	win32app.select_object(hdc_source, dib.hbitmap)
	bitmap_size := transmute(cv.int2)dib.canvas.size
	win32.StretchBlt(ps.hdc, 0, 0, client_size.x, client_size.y, hdc_source, 0, 0, bitmap_size.x, bitmap_size.y, win32.SRCCOPY)

	return 0
}


WM_CHAR :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	switch wparam {
	case '\x1b':	win32.DestroyWindow(hwnd)
	case:			fmt.printfln("WM_CHAR %4d 0x%4x 0x%4x 0x%4x", wparam, wparam, win32.HIWORD(u32(lparam)), win32.LOWORD(u32(lparam)))
	}
	return 0
}

wndproc :: proc "system" (hwnd: win32.HWND, msg: win32.UINT, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	context = runtime.default_context()
	// odinfmt: disable
	switch msg {
	case win32.WM_CREATE:		return WM_CREATE(hwnd, lparam)
	case win32.WM_DESTROY:		return WM_DESTROY(hwnd)
	case win32.WM_ERASEBKGND:	return 1
	case win32.WM_SIZE:			return WM_SIZE(hwnd, wparam, lparam)
	case win32.WM_PAINT:		return WM_PAINT(hwnd)
	case win32.WM_CHAR:			return WM_CHAR(hwnd, wparam, lparam)
	// case win32.WM_ACTIVATEAPP:	return WM_ACTIVATEAPP(hwnd, wparam, lparam)
	// case win32.WM_SETFOCUS:		return wm_focus(hwnd, wparam, true)
	// case win32.WM_KILLFOCUS:	return wm_focus(hwnd, wparam, false)
	case:						return win32.DefWindowProcW(hwnd, msg, wparam, lparam)
	}
	// odinfmt: enable
}

main :: proc() {

	app: application = {
		//size = {WIDTH, HEIGHT},
	}

	stopwatch := win32app.create_stopwatch()
	stopwatch->start()

	settings.app = &app
	win32app.run(&settings)

	stopwatch->stop()
	fmt.printfln("Done. %fs", stopwatch->get_elapsed_seconds())
}

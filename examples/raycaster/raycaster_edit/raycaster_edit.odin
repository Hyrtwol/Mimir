// vet
package raycaster_edit

import "base:intrinsics"
import "base:runtime"
import "core:fmt"
import win32 "core:sys/windows"
import cv "libs:tlc/canvas"
import owin "libs:tlc/win32app"

L :: intrinsics.constant_utf16_cstring

ZOOM :: 12
WIDTH :: ZOOM * 64
HEIGHT :: ZOOM * 64
FPS :: 20
IDT_TIMER1: win32.UINT_PTR : 10001

//COLOR :: cv.C64_COLOR
COLOR :: cv.W95_COLOR
//COLOR :: cv.AMSTRAD_COLOR

clear_color: COLOR = .BLACK
select: COLOR = .WHITE

application :: struct {
	#subtype settings: owin.window_settings,
}

dib: owin.DIB
// frame buffers
fbc :: 2
fbs: [fbc]owin.DIB
fps: f64 = 0
frame_counter := 0

timer_id: win32.UINT_PTR
stopwatch : owin.stopwatch

mouse_pos: owin.int2 = {0, 0}
is_active: bool = true
is_focused := false
cursor_state: i32 = 0

grid_color: u32 = 0x80808080

get_app :: #force_inline proc(hwnd: win32.HWND) -> ^application {
	app := owin.get_settings(hwnd, application)
	if app == nil {owin.show_error_and_panic("Missing app!")}
	return app
}

show_cursor :: proc(show: bool) {
	cursor_state = owin.show_cursor(show)
	fmt.println(#procedure, cursor_state)
}

set_window_text :: #force_inline proc(hwnd: win32.HWND) {
	app := get_app(hwnd)
	owin.set_window_text(hwnd, "%s %v %v FPS: %f", app.settings.title, app.settings.window_size, dib.canvas.size, fps)
}

decode_scrpos :: #force_inline proc "contextless" (lparam: win32.LPARAM) -> cv.int2 {
	return owin.decode_lparam_as_int2(lparam) / ZOOM
}

set_dot :: #force_inline proc "contextless" (pos: cv.int2, col: COLOR) {
	cv.canvas_set_dot(&dib.canvas, pos, cv.get_color(col))
}

WM_CREATE :: proc(hwnd: win32.HWND, lparam: win32.LPARAM) -> win32.LRESULT {
	fmt.println(#procedure)

	app := owin.get_settings_from_lparam(lparam, application)
	if app == nil {owin.show_error_and_panic("Missing app!")}
	owin.set_settings(hwnd, app)

	//show_cursor(false)

	client_size := owin.get_client_size(hwnd)
	fmt.println("client_size", client_size)

	hdc := win32.GetDC(hwnd)
	defer win32.ReleaseDC(hwnd, hdc)

	cc := cv.get_color(clear_color)
	for i in 0 ..< fbc {
		fbs[i] = owin.dib_create_v5(hdc, client_size)
		cv.canvas_clear(&fbs[i], cc)
	}

	dib = owin.dib_create_v5(hdc, client_size / ZOOM)
	cv.canvas_clear(&dib, cc)

	timer_id = owin.set_timer(hwnd, IDT_TIMER1, 1000 / FPS)

	return 0
}

WM_DESTROY :: proc(hwnd: win32.HWND) -> win32.LRESULT {
	app := get_app(hwnd)
	fmt.println(#procedure)
	owin.kill_timer(hwnd, &timer_id)
	// owin.clip_cursor(hwnd, false)
	// if cursor_state < 1 {show_cursor(true)}
	owin.dib_free(&dib)
	for i in 0 ..< fbc {
		owin.dib_free(&fbs[i])
	}
	owin.post_quit_message()
	return 0
}

WM_SIZE :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	app := get_app(hwnd)
	fmt.println(#procedure)
	app.settings.window_size = owin.decode_lparam_as_int2(lparam)
	set_window_text(hwnd)
	// owin.clip_cursor(hwnd, true)
	return 0
}

WM_TIMER :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	app := get_app(hwnd)

	frame_counter = (frame_counter + 1) & 1
	delta := stopwatch->get_delta_seconds()
	fps = f64(1 / delta)
	set_window_text(hwnd)

	hdc := win32.GetDC(hwnd)
	assert(hdc != nil)
	defer win32.ReleaseDC(hwnd, hdc)

	fb := fbs[frame_counter]
	fb_canvas_size := transmute(cv.int2)fb.canvas.size
	fb_hdc := win32.CreateCompatibleDC(hdc)
	assert(fb_hdc != nil)
	defer win32.DeleteDC(fb_hdc)

	old_obj := owin.select_object(fb_hdc, fb.hbitmap)
	defer owin.select_object(fb_hdc, old_obj)

	// paint dib to active fb
	{
		hdc_source := win32.CreateCompatibleDC(hdc)
		assert(hdc_source != nil)
		defer win32.DeleteDC(hdc_source)
		old_hdc_source_object := owin.select_object(hdc_source, dib.hbitmap)
		defer owin.select_object(hdc_source, old_hdc_source_object)

		owin.stretch_blt(fb_hdc, fb_canvas_size, hdc_source, transmute(cv.int2)dib.canvas.size)
	}
	// draw grid
	{
		dc_pen := win32.GetStockObject(win32.DC_PEN)
		old_dc_pen := owin.select_object(fb_hdc, dc_pen)
		defer owin.select_object(fb_hdc, old_dc_pen)
		old_pen := win32.SetDCPenColor(fb_hdc, grid_color)
		defer win32.SetDCPenColor(fb_hdc, old_pen)

		owin.draw_grid(fb_hdc, {0, 0}, {ZOOM, ZOOM}, fb_canvas_size)
	}

	owin.bit_blt(hdc, fb_canvas_size, fb_hdc)

	// owin.redraw_window(hwnd)

	return 0
}

WM_PAINT :: proc(hwnd: win32.HWND) -> win32.LRESULT {
	app := get_app(hwnd)

	ps: win32.PAINTSTRUCT
	win32.BeginPaint(hwnd, &ps)
	defer win32.EndPaint(hwnd, &ps)

	hdc_source := win32.CreateCompatibleDC(ps.hdc)
	defer win32.DeleteDC(hdc_source)

	fb := fbs[frame_counter]
	client_size := owin.get_rect_size(&ps.rcPaint)
	owin.select_object(hdc_source, fb.hbitmap)
	bitmap_size := transmute(cv.int2)fb.canvas.size
	win32.StretchBlt(ps.hdc, 0, 0, client_size.x, client_size.y, hdc_source, 0, 0, bitmap_size.x, bitmap_size.y, win32.SRCCOPY)

	return 0
}

WM_CHAR :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	switch wparam {
	case '\x1b':
		win32.DestroyWindow(hwnd)
	case '0' ..= '9':
		select = COLOR(u8(wparam) - u8('0'))
	case '.':
		select = COLOR((u8(select) + 1) % len(COLOR))
	case ',':
		select = COLOR((u8(select) - 1) % len(COLOR))
	case:
		fmt.printfln("WM_CHAR %4d 0x%4x 0x%4x 0x%4x", wparam, wparam, win32.HIWORD(u32(lparam)), win32.LOWORD(u32(lparam)))
	}
	return 0
}

handle_input :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	switch wparam {
	case 1:
		pos := decode_scrpos(lparam)
		set_dot(pos, select)
	case 2:
		pos := decode_scrpos(lparam)
		set_dot(pos, clear_color)
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
	case win32.WM_TIMER:        return WM_TIMER(hwnd, wparam, lparam)
	case win32.WM_PAINT:		return WM_PAINT(hwnd)
	case win32.WM_CHAR:			return WM_CHAR(hwnd, wparam, lparam)
	case win32.WM_MOUSEMOVE:	return handle_input(hwnd, wparam, lparam)
	case win32.WM_LBUTTONDOWN:	return handle_input(hwnd, wparam, lparam)
	case win32.WM_RBUTTONDOWN:	return handle_input(hwnd, wparam, lparam)
	// case win32.WM_ACTIVATEAPP:	return WM_ACTIVATEAPP(hwnd, wparam, lparam)
	// case win32.WM_SETFOCUS:		return WM_FOCUS(hwnd, wparam, true)
	// case win32.WM_KILLFOCUS:		return WM_FOCUS(hwnd, wparam, false)
	case:						return win32.DefWindowProcW(hwnd, msg, wparam, lparam)
	}
	// odinfmt: enable
}

main :: proc() {

	app := application {
		settings = owin.window_settings {
			options     = {.Center},
			dwStyle     = owin.DEFAULT_WS_STYLE,
			dwExStyle   = owin.DEFAULT_WS_EX_STYLE,
			sleep       = owin.DEFAULT_SLEEP,
			window_size = {WIDTH, HEIGHT},
			wndproc = wndproc,
		},
	}

	stopwatch = owin.create_stopwatch()
	stopwatch->start()

	owin.run(&app)

	stopwatch->stop()
	fmt.printfln("Done. %fs", stopwatch->get_elapsed_seconds())
}

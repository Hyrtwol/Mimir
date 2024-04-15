package canvasapp

import cv ".."
import "core:fmt"
import "core:intrinsics"
import "core:runtime"
import win32 "core:sys/windows"
import win32app "libs:tlc/win32app"

FPS :: 5

int2 :: cv.int2
color: cv.color
dib: cv.DIB

settings: win32app.window_settings = {
	// title       = title,
	window_size = {640, 480},
	center      = true,
	wndproc     = wndproc,
	dwStyle     = win32app.default_dwStyle,
	dwExStyle   = win32app.default_dwExStyle,
	//run         = run,
}

app_action :: #type proc(app: papp) -> int
on_idle :: proc(app: papp) -> int {
	fmt.println("on_idle:", app)
	return 0
}

application :: struct {
	pause:                   bool,
	//colors:    []color,
	size:                    int2,
	timer_id:                win32.UINT_PTR,
	tick:                    u32,
	//title:     wstring,
	hbitmap:                 win32.HBITMAP,
	// pvBits:   screen_buffer,
	create, update, destroy: app_action,
}
papp :: ^application

app: application = {
	size    = {320, 240},
	create  = on_idle,
	update  = on_idle,
	destroy = on_idle,
}

stopwatch := win32app.create_stopwatch()
fps: f64 = 0

set_app :: #force_inline proc(hwnd: win32.HWND, app: papp) {win32.SetWindowLongPtrW(hwnd, win32.GWLP_USERDATA, win32.LONG_PTR(uintptr(app)))}

get_app :: #force_inline proc(hwnd: win32.HWND) -> papp {
	app := (papp)(rawptr(uintptr(win32.GetWindowLongPtrW(hwnd, win32.GWLP_USERDATA))))
	if app == nil {win32app.show_error_and_panic("Missing app!")}
	return app
}

get_settings :: #force_inline proc(lparam: win32.LPARAM) -> win32app.psettings {
	pcs := (^win32.CREATESTRUCTW)(rawptr(uintptr(lparam)))
	if pcs == nil {win32app.show_error_and_panic("Missing pcs!");return nil}
	settings := (win32app.psettings)(pcs.lpCreateParams)
	if settings == nil {win32app.show_error_and_panic("Missing settings!")}
	return settings
}

WM_CREATE :: proc(hwnd: win32.HWND, lparam: win32.LPARAM) -> win32.LRESULT {
	settings := get_settings(lparam)
	app := (papp)(settings.app)
	if app == nil {win32app.show_error_and_panic("Missing app!");return 1}
	//fmt.printf("WM_CREATE %v %v %v\n", hwnd, pcs, app)
	set_app(hwnd, app)

	hdc := win32.GetDC(hwnd)
	defer win32.ReleaseDC(hwnd, hdc)

	dib = cv.dib_create_v5(hdc, app.size)
	if dib.canvas.pvBits == nil {win32app.show_error_and_panic("No DIB");return 1}
	cv.dib_clear(&dib, cv.COLOR_BLACK)

	app.create(app)

	/*
	cc := dib.canvas.pixel_count
	pp := dib.canvas.pvBits
	for i in 0..<cc {
		pp[i] = {u8(rand.int31_max(255, &rng)),u8(rand.int31_max(255, &rng)),u8(rand.int31_max(255, &rng)),0}
	}
	*/

	app.timer_id = win32app.set_timer(hwnd, win32app.IDT_TIMER1, 1000 / FPS)
	assert(app.timer_id != 0)

	stopwatch->start()

	return 0
}

WM_DESTROY :: proc(hwnd: win32.HWND) -> win32.LRESULT {
	app := get_app(hwnd)
	app.destroy(app)
	cv.dib_free_section(&dib)
	win32app.kill_timer(hwnd, &app.timer_id)
	assert(app.timer_id == 0)
	win32.PostQuitMessage(0)
	stopwatch->stop()
	return 0
}

WM_CHAR :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	switch wparam {
	case '\x1b':
		win32app.close_application(hwnd)
	}
	return 0
}

WM_SIZE :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	//app := get_app(hwnd)
	settings.window_size = win32app.decode_lparam(lparam)
	win32app.set_window_textf(hwnd, "%s %v %v FPS: %f", settings.title, settings.window_size, dib.canvas.size, fps)
	return 0
}

WM_TIMER :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	//fmt.printfln("WM_TIMER %v %v", hwnd, wparam)
	app := get_app(hwnd)
	delta := stopwatch->get_delta_seconds()
	fc := frame_counter
	frame_counter = 0
	fps = f64(fc) / delta
	win32app.set_window_textf(hwnd, "%s %v %v FPS: %f", settings.title, settings.window_size, dib.canvas.size, fps)
	//win32app.redraw_window(hwnd)
	return 0
}

frame_counter := 0

WM_PAINT :: proc(hwnd: win32.HWND) -> win32.LRESULT {
	frame_counter += 1
	return cv.wm_paint_dib(hwnd, dib.hbitmap, transmute(cv.int2)dib.canvas.size)
}

wndproc :: proc "system" (hwnd: win32.HWND, msg: win32.UINT, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	context = runtime.default_context()
	// odinfmt: disable
	switch msg {
	case win32.WM_CREATE:       return WM_CREATE(hwnd, lparam)
	case win32.WM_DESTROY:      return WM_DESTROY(hwnd)
	case win32.WM_ERASEBKGND:   return 1
	case win32.WM_SIZE:         return WM_SIZE(hwnd, wparam, lparam)
	case win32.WM_PAINT:        return WM_PAINT(hwnd)
	case win32.WM_CHAR:         return WM_CHAR(hwnd, wparam, lparam)
	case win32.WM_TIMER:        return WM_TIMER(hwnd, wparam, lparam)
	// case win32.WM_MOUSEMOVE:    return handle_input(hwnd, wparam, lparam)
	// case win32.WM_LBUTTONDOWN:  return handle_input(hwnd, wparam, lparam)
	// case win32.WM_RBUTTONDOWN:  return handle_input(hwnd, wparam, lparam)
	case:                       return win32.DefWindowProcW(hwnd, msg, wparam, lparam)
	}
	// odinfmt: enable
}

run :: proc() {
	settings.app = &app
	//inst, atom, hwnd := win32app.prepare_run(&settings)
	_, _, hwnd := win32app.prepare_run(&settings)
	res: int
	for win32app.pull_messages() {
		res = app.update(&app)
		if res == 1 {
			win32app.redraw_window(hwnd)
		}
	}
}

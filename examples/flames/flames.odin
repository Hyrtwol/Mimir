// vet
package main

import "core:fmt"
import "base:intrinsics"
import "core:math"
import "core:math/noise"
import "core:math/rand"
import "base:runtime"
import win32 "core:sys/windows"
import "core:time"
import cv "libs:tlc/canvas"
import win32app "libs:tlc/win32app"

L :: intrinsics.constant_utf16_cstring
byte4 :: cv.byte4
int2 :: cv.int2
double2 :: [2]f64
double3 :: [3]f64

DIB :: win32app.DIB
canvas :: cv.canvas

TITLE :: "Flames"
WIDTH: i32 : 160
HEIGHT: i32 : WIDTH * 3 / 4
PXLCNT: i32 : WIDTH * HEIGHT
ZOOM :: 8

settings : win32app.window_settings

stopwatch := win32app.create_stopwatch()
fps: f64 = 0
frame_counter := 0
delta, frame_time: f64 = 0, 0

TimerTickPS :: 1
timer_id: win32.UINT_PTR

flamebuffer: [PXLCNT]u8
palette: [256]byte4

dib: DIB
npos1: double3 = {0, 0, 0}
ndir1: double3 = {0.007, 0.009, 0.011}
npos2: double2 = {0, 0}
ndir2: double2 = {0.007, 0.003}
nseed: i64 = 12345

dib_update_func: proc(dib: ^canvas) = dib_flames

set_dot :: proc(x, y: i32, col: u8) {
	i := y * WIDTH + x
	if i >= 0 && i < PXLCNT {
		flamebuffer[i] = col
	}
}

set_big_dot :: proc(x, y: i32, col: u8, r: i32) {
	rr := r * r
	for iy in -r ..= r {
		dy := iy * iy
		for ix in -r ..= r {
			d := ix * ix + dy
			if d <= rr {
				set_dot(x + ix, y + iy, col)
			}
		}
	}
}

get_dot :: proc(x, y: i32) -> i32 {
	i := y * WIDTH + x
	if i >= 0 && i < PXLCNT {
		return i32(flamebuffer[i])
	}
	return 0
}

dib_flames :: proc(dib: ^canvas) {
	w, h := i32(dib.size.x), i32(dib.size.y)

	for y in 0 ..< h {
		for x in 0 ..< w {
			// add the values of the surrounding pixels
			c: i32 = get_dot(x, y + 1) + get_dot(x - 1, y + 1) + get_dot(x + 1, y + 1) + get_dot(x, y)
			// divide by the number of pixels added up
			c /= 4
			// decrement by the decay value
			if c > 0 {
				c -= 1
			}
			set_dot(x, y, u8(c))
		}
	}

	{
		// set a new bottom line
		i := w * (h - 1)
		for _ in 0 ..< w {
			flamebuffer[i] = u8(rand.int31_max(256))
			i += 1
		}
	}

	pixel_count, bits := dib.pixel_count, dib.pvBits
	for i in 0 ..< pixel_count {
		bits[i] = palette[flamebuffer[i]]
	}
}

cnp := noise.Vec3{0, 0, 0}
//n_scale := 0.01 // nice
n_scale := 0.02
//n_scale := 0.03

dib_flames_2 :: proc(dib: ^canvas) {
	w, h := i32(dib.size.x), i32(dib.size.y)

	for y in 0 ..< h {
		for x in 0 ..< w {
			// add the values of the surrounding pixels
			c: i32 = get_dot(x, y + 1) + get_dot(x - 1, y + 1) + get_dot(x + 1, y + 1) + get_dot(x, y)
			// divide by the number of pixels added up
			//c /= 4
			c >>= 2
			// decrement by the decay value
			if c > 0 {
				c -= 1
			}
			set_dot(x, y, u8(c))
		}
	}

	{
		// set a new bottom line
		np := cnp
		n: f32
		i := w * (h - 1)
		for x in 0 ..< w {
			np.x = f64(x) * n_scale
			n = noise.noise_3d_improve_xy(nseed, np)
			flamebuffer[i] = u8(n * 127.5 + 127.5)
			i += 1
		}
		cnp.y += n_scale
	}

	pixel_count, bits := dib.pixel_count, dib.pvBits
	for i in 0 ..< pixel_count {
		bits[i] = palette[flamebuffer[i]]
	}
}

set_window_text :: #force_inline proc(hwnd: win32.HWND) {
	win32app.set_window_text(hwnd, "%s %v %v FPS: %f", settings.title, settings.window_size, dib.canvas.size, fps)
}


WM_CREATE :: proc(hwnd: win32.HWND, lparam: win32.LPARAM) -> win32.LRESULT {
	fmt.println(#procedure, hwnd)

	hdc := win32.GetDC(hwnd)
	defer win32.ReleaseDC(hwnd, hdc)
	dib = win32app.dib_create_v5(hdc, {WIDTH, HEIGHT})
	if dib.canvas.pvBits == nil {win32app.show_error_and_panic("No DIB");return 1}
	cv.canvas_clear(&dib, cv.byte4{0, 0, 0, 255})

	timer_id = win32app.set_timer(hwnd, win32app.IDT_TIMER1, 1000 / TimerTickPS)
	assert(timer_id != 0)

	return 0
}

WM_DESTROY :: proc(hwnd: win32.HWND) -> win32.LRESULT {
	fmt.println(#procedure, hwnd)

	win32app.dib_free_section(&dib)
	win32app.kill_timer(hwnd, &timer_id)
	assert(timer_id == 0)
	win32app.post_quit_message(0)
	return 0
}

WM_SIZE :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	fmt.println(#procedure, hwnd)

	settings.window_size = win32app.decode_lparam_as_int2(lparam)
	set_window_text(hwnd)
	return 0
}

draw_dib :: #force_inline proc(hwnd: win32.HWND, hdc: win32.HDC) {
	win32app.draw_dib(hwnd, hdc, settings.window_size, &dib)
}

draw_frame :: proc(hwnd: win32.HWND) -> win32.LRESULT {
	dib_update_func(&dib.canvas)
	hdc := win32.GetDC(hwnd)
	if hdc != nil {
		defer win32.ReleaseDC(hwnd, hdc)
		draw_dib(hwnd, hdc)
	}
	return 0
}

WM_PAINT :: proc(hwnd: win32.HWND) -> win32.LRESULT {
	fmt.println(#procedure, hwnd)

	ps: win32.PAINTSTRUCT
	hdc := win32.BeginPaint(hwnd, &ps)
	if hdc != nil {
		defer win32.EndPaint(hwnd, &ps)
		draw_dib(hwnd, hdc)
	}
	return 0
}

WM_TIMER :: proc(hwnd: win32.HWND, wparam: win32.WPARAM) -> win32.LRESULT {
	// fmt.println(#procedure, hwnd, wparam)
	// app := get_app(hwnd)
	fps = f64(frame_counter) / frame_time
	frame_counter = 0
	frame_time = 0
	set_window_text(hwnd)
	return 0
}

WM_CHAR :: proc "contextless" (hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	switch wparam {
	case '\x1b':
		win32app.close_application(hwnd)
	case '1':
		dib_update_func = dib_flames
	case '2':
		dib_update_func = dib_flames_2
	}
	return 0
}

decode_input_position :: #force_inline proc "contextless" (lparam: win32.LPARAM) -> win32app.int2 {
	return win32app.decode_lparam_as_int2(lparam) / ZOOM
}

handle_input :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	switch wparam {
	case 1:
		pos := decode_input_position(lparam)
		set_dot(pos.x, pos.y, 255)
	case 2:
		pos := decode_input_position(lparam)
		set_big_dot(pos.x, pos.y, 255, 5)
	}
	return 0
}

wndproc :: proc "system" (hwnd: win32.HWND, msg: win32.UINT, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	context = runtime.default_context()
	// odinfmt: disable
	switch msg {
	case win32.WM_CREATE:      return WM_CREATE(hwnd, lparam)
	case win32.WM_DESTROY:     return WM_DESTROY(hwnd)
	case win32.WM_ERASEBKGND:  return 1
	case win32.WM_SIZE:        return WM_SIZE(hwnd, wparam, lparam)
	case win32.WM_PAINT:       return WM_PAINT(hwnd)
	case win32.WM_CHAR:        return WM_CHAR(hwnd, wparam, lparam)
	case win32.WM_TIMER:       return WM_TIMER(hwnd, wparam)
	case win32.WM_MOUSEMOVE:   return handle_input(hwnd, wparam, lparam)
	case win32.WM_LBUTTONDOWN: return handle_input(hwnd, wparam, lparam)
	case win32.WM_RBUTTONDOWN: return handle_input(hwnd, wparam, lparam)
	case:                      return win32.DefWindowProcW(hwnd, msg, wparam, lparam)
	}
	// odinfmt: enable
}

main :: proc() {
	calc_col :: proc(n: f64) -> u8 {return u8(n * (256 - (1 / 255)))}
	for i in 0 ..< 256 {
		f := (f64(i) / 255)
		palette[i] = {calc_col(math.pow(f, 0.5)), calc_col(math.pow(f, 1.25)), calc_col(math.pow(f, 3.0)), 255}
	}

	settings = win32app.create_window_settings(TITLE, WIDTH * ZOOM, HEIGHT * ZOOM, wndproc)
	settings.sleep = time.Millisecond * 4
	_, _, hwnd := win32app.prepare_run(&settings)
	stopwatch->start()
	for win32app.pull_messages() {
		delta = stopwatch->get_delta_seconds()
		frame_time += delta
		frame_counter += 1
		draw_frame(hwnd)
		time.sleep(settings.sleep)
	}
	stopwatch->stop()
	fmt.printfln("Done. %fs", stopwatch->get_elapsed_seconds())
	//fmt.println("settings:", settings)
}

package main

import "core:fmt"
import "core:intrinsics"
import "core:math"
import "core:math/rand"
import "core:math/noise"
import "core:runtime"
import win32 "core:sys/windows"
import cv "libs:tlc/canvas"
import win32app "libs:tlc/win32app"

L :: intrinsics.constant_utf16_cstring
byte4 :: cv.byte4
int2 :: cv.int2
double2 :: [2]f64
double3 :: [3]f64

DIB :: cv.DIB
canvas	:: cv.canvas

TITLE :: "Flames"
WIDTH: i32 : 160
HEIGHT: i32 : WIDTH * 3 / 4
PXLCNT: i32 : WIDTH * HEIGHT
ZOOM :: 4
FPS :: 20

settings := win32app.create_window_settings(TITLE, WIDTH * ZOOM, HEIGHT * ZOOM, wndproc)

rng := rand.create(1)
flamebuffer: [PXLCNT]u8
palette: [256]byte4

timer_id: win32.UINT_PTR
dib: DIB
npos1: double3 = {0, 0, 0}
ndir1: double3 = {0.007, 0.009, 0.011}
npos2: double2 = {0, 0}
ndir2: double2 = {0.007, 0.003}
nseed: i64 = 12345

dib_update_func: proc(dib: ^canvas) = dib_flames

setdot :: proc(x, y: i32, col: u8) {
	i := y * WIDTH + x
	if i >= 0 && i < PXLCNT {
		flamebuffer[i] = col
	}
}

setbigdot :: proc(x, y: i32, col: u8, r: i32) {
	rr := r * r
	for iy in -r ..= r {
		for ix in -r ..= r {
			d := ix * ix + iy * iy
			if d <= rr {
				setdot(x + ix, y + iy, col)
			}
		}
	}
}

getdot :: proc(x, y: i32) -> i32 {
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
			c: i32 = getdot(x, y + 1) + getdot(x - 1, y + 1) + getdot(x + 1, y + 1) + getdot(x, y)
			// divide by the number of pixels added up
			c /= 4
			// decrement by the decay value
			if c > 0 {
				c -= 1
			}
			setdot(x, y, u8(c))
		}
	}

	// set a new bottom line
	i := w * (h - 1)
	for _ in 0 ..< w {
		flamebuffer[i] = u8(rand.int31_max(256, &rng))
		i += 1
	}

	cnt := dib.pixel_count; p := dib.pvBits;
	for i in 0 ..< cnt {
		c := flamebuffer[i]
		p[i] = palette[c]
	}
}

cnp :=   noise.Vec3{0,0,0}
//n_scale := 0.01 // nice
n_scale := 0.03

dib_flames_2 :: proc(dib: ^canvas) {
	w, h := i32(dib.size.x), i32(dib.size.y)

	for y in 0 ..< h {
		for x in 0 ..< w {
			// add the values of the surrounding pixels
			c: i32 = getdot(x, y + 1) + getdot(x - 1, y + 1) + getdot(x + 1, y + 1) + getdot(x, y)
			// divide by the number of pixels added up
			//c /= 4
			c >>= 2
			// decrement by the decay value
			if c > 0 {
				c -= 1
			}
			setdot(x, y, u8(c))
		}
	}

	np := cnp
	n: f32
	// set a new bottom line
	i := w * (h - 1)
	for x in 0 ..< w {
		np.x = f64(x) * n_scale
		n = noise.noise_3d_improve_xy(nseed, np)
		flamebuffer[i] = u8(n*127.5 + 127.5)
		i += 1
	}
	cnp.y += n_scale

	cnt := dib.pixel_count; p := dib.pvBits;
	for i in 0 ..< cnt {
		c := flamebuffer[i]
		p[i] = palette[c]
	}
}


WM_CREATE :: proc(hwnd: win32.HWND, lparam: win32.LPARAM) -> win32.LRESULT {
	hdc := win32.GetDC(hwnd)
	defer win32.ReleaseDC(hwnd, hdc)

	dib = cv.dib_create_v5(hdc, {WIDTH, HEIGHT})
	if dib.canvas.pvBits == nil {win32app.show_error_and_panic("No DIB");return 1}
	cv.dib_clear(&dib, {0, 0, 0, 255})

	timer_id = win32app.set_timer(hwnd, win32app.IDT_TIMER1, 1000 / FPS)
	assert(timer_id != 0)

	return 0
}

WM_DESTROY :: proc(hwnd: win32.HWND) -> win32.LRESULT {
	cv.dib_free_section(&dib)
	win32app.kill_timer(hwnd, &timer_id)
	assert(timer_id == 0)
	win32.PostQuitMessage(0)
	return 0
}

WM_CHAR :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
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

WM_SIZE :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	size := win32app.decode_lparam(lparam)
	win32app.set_window_textf(hwnd, "%s %v %v FPS: %d", settings.title, size, dib.canvas.size, FPS)
	return 0
}

WM_TIMER :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	dib_update_func(&dib.canvas)
	win32app.redraw_window(hwnd)
	return 0
}

decode_scrpos :: #force_inline proc "contextless" (lparam: win32.LPARAM) -> win32app.int2 {
	return win32app.decode_lparam(lparam) / ZOOM
}

handle_input :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	switch wparam {
	case 1:
		pos := decode_scrpos(lparam)
		setdot(pos.x, pos.y, 255)
	case 2:
		pos := decode_scrpos(lparam)
		setbigdot(pos.x, pos.y, 255, 5)
	}
	return 0
}

wndproc :: proc "system" (hwnd: win32.HWND, msg: win32.UINT, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	context = runtime.default_context()
	// odinfmt: disable
	switch msg {
	case win32.WM_CREATE:       return WM_CREATE(hwnd, lparam)
	case win32.WM_DESTROY:      return WM_DESTROY(hwnd)
	case win32.WM_ERASEBKGND:   return 1
	case win32.WM_SIZE:         return WM_SIZE(hwnd, wparam, lparam)
	case win32.WM_PAINT:        return cv.wm_paint_dib(hwnd, dib.hbitmap, transmute(int2)dib.canvas.size)
	case win32.WM_CHAR:         return WM_CHAR(hwnd, wparam, lparam)
	case win32.WM_TIMER:        return WM_TIMER(hwnd, wparam, lparam)
	case win32.WM_MOUSEMOVE:    return handle_input(hwnd, wparam, lparam)
	case win32.WM_LBUTTONDOWN:  return handle_input(hwnd, wparam, lparam)
	case win32.WM_RBUTTONDOWN:  return handle_input(hwnd, wparam, lparam)
	case:                       return win32.DefWindowProcW(hwnd, msg, wparam, lparam)
	}
	// odinfmt: enable
}

main :: proc() {
	calc_col :: proc(n: f64) -> u8 {return u8(n * (256-(1 / 255)))}
	for i in 0 ..< 256 {
		f := (f64(i) / 255)
		palette[i] = {calc_col(math.pow(f, 0.5)), calc_col(math.pow(f, 1.25)), calc_col(math.pow(f, 3.0)), 255}
	}
	win32app.run(&settings)
}

package main

import "core:fmt"
import "core:intrinsics"
import "core:math"
//import "core:math/linalg"
import "core:math/noise"
import "core:math/rand"
import "core:mem"
import "core:runtime"
import "core:simd"
import "core:strings"
import win32 "core:sys/windows"
import "core:time"
import canvas "shared:tlc/canvas"
import win32app "shared:tlc/win32app"

L :: intrinsics.constant_utf16_cstring
byte4 :: canvas.byte4
int2 :: canvas.int2
double2 :: [2]f64
double3 :: [3]f64

DIB :: canvas.DIB

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

dib_update_func: proc(dib: ^DIB) = dib_flames

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

dib_flames :: proc(dib: ^DIB) {
	w := dib.size.x
	h := dib.size.y

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
	for x in 0 ..< w {
		c := u8(rand.int31_max(256, &rng))
		flamebuffer[i] = c
		i += 1
	}

	i = 0;p := dib.pvBits
	for y in 0 ..< h {
		for x in 0 ..< w {
			c := flamebuffer[i]
			p[i] = palette[c]
			i += 1
		}
	}
}

WM_CREATE :: proc(hwnd: win32.HWND, lparam: win32.LPARAM) -> win32.LRESULT {
	//fmt.printf("WM_CREATE %v %v\n", hwnd, (^win32.CREATESTRUCTW)(rawptr(uintptr(lparam))))

	timer_id = win32.SetTimer(hwnd, win32app.IDT_TIMER1, 1000 / FPS, nil)
	if timer_id == 0 {win32app.show_error_and_panic("No timer")}

	hdc := win32.GetDC(hwnd)
	defer win32.ReleaseDC(hwnd, hdc)

	dib = canvas.dib_create_v5(hdc, {WIDTH, HEIGHT})
	if dib.pvBits != nil {
		canvas.dib_clear(&dib, {0, 0, 0, 255})
	} else {
		win32app.show_error_and_panic("No DIB")
	}

	return 0
}

WM_DESTROY :: proc(hwnd: win32.HWND) -> win32.LRESULT {
	canvas.dib_free_section(&dib)

	if timer_id != 0 {
		if !win32.KillTimer(hwnd, timer_id) {
			win32.MessageBoxW(nil, L("Unable to kill timer"), L("Error"), win32.MB_OK)
			timer_id = 0
		}
	}

	win32.PostQuitMessage(0)
	return 0
}

WM_CHAR :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	switch wparam {
	case '\x1b':
		//win32.DestroyWindow(hwnd)
		win32.PostMessageW(hwnd, win32.WM_CLOSE, 0, 0)
	case '1':
		dib_update_func = dib_flames
	}
	return 0
}

WM_SIZE :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	size := win32app.decode_lparam(lparam)
	new_title := fmt.tprintf("%s %v %v FPS: %d\n", settings.title, size, dib.size, FPS)
	win32app.SetWindowText(hwnd, new_title)
	return 0
}

WM_TIMER :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	dib_update_func(&dib)
	win32app.RedrawWindowNow(hwnd)
	return 0
}

decode_scrpos :: proc(lparam: win32.LPARAM) -> win32app.int2 {
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
	case win32.WM_PAINT:        return canvas.wm_paint_dib(hwnd, dib.hbitmap, dib.size) // &dib->dib_paint(hwnd) maybe?
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
	calcol :: proc(n: f64) -> u8 {return u8(n * 255.999)}
	for i in 0 ..< 256 {
		f := f64(i) / 255
		palette[i] = {calcol(math.pow(f, 0.5)), calcol(math.pow(f, 1.25)), calcol(math.pow(f, 3.0)), 255}
	}
	win32app.run(&settings)
}

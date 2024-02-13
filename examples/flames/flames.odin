package main

import "core:fmt"
import "core:intrinsics"
import "core:math"
import "core:math/linalg"
import hlm "core:math/linalg/hlsl"
import "core:math/noise"
import "core:math/rand"
import "core:mem"
import "core:runtime"
import "core:simd"
import "core:strings"
import win32 "core:sys/windows"
import win32ex "shared:sys/windows"
import "core:time"
import win32app "shared:tlc/win32app"
import canvas "shared:tlc/canvas"

L :: intrinsics.constant_utf16_cstring
byte4 :: canvas.byte4
int2 :: canvas.int2
float2 :: hlm.float2
double2 :: hlm.double2
double3 :: hlm.double3
DIB :: canvas.DIB

TITLE 	:: "Flames"
WIDTH: i32 : 160
HEIGHT: i32 : WIDTH * 3 / 4
PXLCNT: i32 : WIDTH * HEIGHT
ZOOM: i32 : 4
FPS: u32 : 20

settings := win32app.create_window_settings(TITLE, WIDTH * ZOOM, HEIGHT * ZOOM, wndproc)

my_rand := rand.create(1)
flamebuffer: [PXLCNT]u8
palette: [256]byte4

timer_id: win32.UINT_PTR
dib: DIB
npos1: double3 = {0, 0, 0}
ndir1: double3 = {0.007, 0.009, 0.011}
npos2: double2 = {0, 0}
ndir2: double2 = {0.007, 0.003}
nseed: i64 = 12345

noise_func: proc(dib: ^DIB) = dib_noise1

setdot :: proc(x, y: i32, col: u8) {
	i := y * WIDTH + x
	if i >= 0 && i < PXLCNT {
		flamebuffer[i] = col
	}
}

setbigdot :: proc(x, y: i32, col: u8, r: i32) {
	rr := r*r
	for iy in -r ..= r {
		for ix in -r ..= r {
			d := ix*ix + iy*iy
			if d<=rr {
				setdot(x+ix, y+iy, col)
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

dib_noise1 :: proc(dib: ^DIB) {
	p := dib.pvBits
	w := dib.size.x
	h := dib.size.y

	i: i32

	i = 0
	for y in 0 ..< HEIGHT {
		for x in 0 ..< WIDTH {
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
	i = w * (HEIGHT - 1)
	for x in 0 ..< WIDTH {
		c := u8(rand.int31_max(256, &my_rand))
		flamebuffer[i] = c
		i += 1
	}

	i = 0
	for y in 0 ..< HEIGHT {
		for x in 0 ..< WIDTH {
			c := flamebuffer[i]
			p[i] = palette[c]
			i += 1
		}
	}
}

WM_CREATE :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	client_size := win32app.get_client_size(hwnd)

	hdc := win32.GetDC(hwnd)

	dib = canvas.dib_create_v5(hdc, {WIDTH, HEIGHT})
	if dib.pvBits != nil {
		canvas.dib_clear(&dib, {0, 0, 0, 255})
	} else {
		win32app.show_error_and_panic("No DIB")
	}

	win32.ReleaseDC(hwnd, hdc)

	timer_id = win32.SetTimer(hwnd, win32app.IDT_TIMER1, 1000 / FPS, nil)
	if timer_id == 0 {
		win32app.show_error_and_panic("No timer")
	}

	return 0
}

WM_DESTROY :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	if timer_id != 0 {
		if !win32.KillTimer(hwnd, timer_id) {
			win32.MessageBoxW(nil, L("Unable to kill timer"), L("Error"), win32.MB_OK)
		}
	}
	canvas.dib_free_section(&dib)
	win32.PostQuitMessage(0)
	return 0
}

WM_ERASEBKGND :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	return 1
}

WM_CHAR :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	switch wparam {
	case '\x1b':	win32.DestroyWindow(hwnd)
	case '1':		noise_func = dib_noise1
	}
	return 0
}

WM_SIZE :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	size := win32app.decode_lparam(lparam)
	newtitle := fmt.tprintf("%s %v %v FPS: %d\n", settings.title, size, dib.size, FPS)
	win32.SetWindowTextW(hwnd, win32.utf8_to_wstring(newtitle))
	return 0
}

WM_PAINT :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	ps: win32.PAINTSTRUCT
	win32.BeginPaint(hwnd, &ps)
	defer win32.EndPaint(hwnd, &ps)

	hdc_source := win32ex.CreateCompatibleDC(ps.hdc)
	defer win32ex.DeleteDC(hdc_source)

	win32.SelectObject(hdc_source, win32.HGDIOBJ(dib.hbitmap))
    client_size := win32app.get_rect_size(&ps.rcPaint)
	win32.StretchBlt(
		ps.hdc, 0, 0, client_size.x, client_size.y,
		hdc_source, 0, 0, dib.size.x, dib.size.y,
		win32.SRCCOPY,
	)

	return 0
}

WM_TIMER :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	noise_func(&dib)
	win32ex.RedrawWindow(hwnd, nil, nil, .RDW_INVALIDATE | .RDW_UPDATENOW)
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

wndproc :: proc "system" (
	hwnd: win32.HWND,
	msg: win32.UINT,
	wparam: win32.WPARAM,
	lparam: win32.LPARAM,
) -> win32.LRESULT {
	context = runtime.default_context()
	switch msg {
	case win32.WM_CREATE:		return WM_CREATE(hwnd, wparam, lparam)
	case win32.WM_DESTROY:		return WM_DESTROY(hwnd, wparam, lparam)
	case win32.WM_ERASEBKGND:	return WM_ERASEBKGND(hwnd, wparam, lparam)
	case win32.WM_SIZE:			return WM_SIZE(hwnd, wparam, lparam)
	case win32.WM_PAINT:		return WM_PAINT(hwnd, wparam, lparam)
	case win32.WM_CHAR:			return WM_CHAR(hwnd, wparam, lparam)
	case win32.WM_TIMER:		return WM_TIMER(hwnd, wparam, lparam)
	case win32.WM_MOUSEMOVE:	return WM_MOUSEMOVE(hwnd, wparam, lparam)
	case win32.WM_LBUTTONDOWN:	return WM_LBUTTONDOWN(hwnd, wparam, lparam)
	case win32.WM_RBUTTONDOWN:	return WM_RBUTTONDOWN(hwnd, wparam, lparam)
	case:						return win32.DefWindowProcW(hwnd, msg, wparam, lparam)
	}
}

tocol :: proc(n: f64) -> u8 {
	return u8(n * 255.999)
}

main :: proc() {
	for i in 0 ..< 256 {
		f: f64 = f64(i) / 255
		palette[i] = {tocol(math.pow(f, 0.5)), tocol(math.pow(f, 1.25)), tocol(math.pow(f, 3.0)), 255}
	}
	win32app.run(&settings)
}

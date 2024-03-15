package main

import          "core:fmt"
import          "core:intrinsics"
import          "core:math/noise"
import          "core:runtime"
import win32    "core:sys/windows"
import win32app "shared:tlc/win32app"
import canvas   "shared:tlc/canvas"

L       :: intrinsics.constant_utf16_cstring
byte4   :: [4]u8 //canvas.byte4
int2    :: [2]i32 //canvas.int2
float2  :: [2]f32 //canvas.float2
double2 :: [2]f64 //canvas.double2
double3 :: [3]f64 //canvas.double3
DIB     :: canvas.DIB

TITLE 	:: "Noise"
WIDTH  	:: 640
HEIGHT 	:: WIDTH * 9 / 16
ZOOM  	:: 4

settings := win32app.create_window_settings(TITLE, WIDTH, HEIGHT, wndproc)

timer_id : win32.UINT_PTR
dib      : DIB
npos1    : double3 = {0, 0, 0}
ndir1    : double3 = {0.007, 0.009, 0.011}
npos2    : double2 = {0, 0}
ndir2    : double2 = {0.007, 0.003}
nseed    : i64 = 12345

noise_func : proc(dib: ^DIB) = dib_noise1

dib_noise1 :: proc(dib: ^DIB) {
	p := dib.pvBits
	w := dib.size.x
	h := dib.size.y
	i: i32 = 0
	n, n1, n2: f32
	ni: u8 = 0
	pp: double3 = npos1
	ofs: double3 = {0, 0, 0}
	scale: f64 : 0.01
	for y in 0 ..< h {
		ofs.y = f64(y)
		for x in 0 ..< w {
			ofs.x = f64(x)
			np := pp + ofs * scale
			n1 = noise.noise_3d_improve_xy(nseed, noise.Vec3(np))
			n2 = noise.noise_3d_improve_xy(nseed, noise.Vec3(np * -2.0))
			n = (n1 * 2 / 3) + (n2 * 0.5 * 1 / 3)
			ni = u8(n * 127.995 + 127.995)
			p[i] = {ni, u8(n1 * 127.74 + 127.74), u8(n2 * 127.74 + 127.74), 255}
			i += 1
		}
	}
	npos1 += ndir1
}

dib_noise2 :: proc(dib: ^DIB) {
	p := dib.pvBits
	w := dib.size.x
	h := dib.size.y
	i: i32 = 0
	n, n1, n2: f32
	ni: u8 = 0
	pp: double2 = npos2
	ofs: double2
	scale: f64 : 0.01
	for y in 0 ..< h {
		ofs.y = f64(y)
		for x in 0 ..< w {
			ofs.x = f64(x)
			np := pp + ofs * scale
			n1 = noise.noise_2d(nseed, noise.Vec2(np))
			n2 = noise.noise_2d(nseed, noise.Vec2(np * -2.0))
			n = (n1 * 2 / 3) + (n2 * 0.5 * 1 / 3)
			ni = u8(n * 127.995 + 127.995)
			p[i] = {ni, ni, ni, 255}
			i += 1
		}
	}
	npos2 += ndir2
}

WM_CREATE :: proc(hwnd: win32.HWND, lparam: win32.LPARAM) -> win32.LRESULT {
	client_size := win32app.get_client_size(hwnd)

	hdc := win32.GetDC(hwnd)

	dib = canvas.dib_create_v5(hdc, client_size / ZOOM)
	if dib.pvBits != nil {
		canvas.dib_clear(&dib, {50, 150, 100, 255})
	} else {
		win32app.show_error_and_panic("No DIB")
	}

	win32.ReleaseDC(hwnd, hdc)

	timer_id = win32.SetTimer(hwnd, win32app.IDT_TIMER1, 50, nil)
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

WM_CHAR :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	switch wparam {
	case '\x1b':	win32.DestroyWindow(hwnd)
	case '1':	    noise_func = dib_noise1
	case '2':	    noise_func = dib_noise2
	}
	return 0
}

WM_SIZE :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	size := win32app.decode_lparam(lparam)
	title := fmt.tprintf("%s %v %v\n", settings.title, size, dib.size)
	win32.SetWindowTextW(hwnd, win32.utf8_to_wstring(title))
	return 0
}

WM_PAINT :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	ps: win32.PAINTSTRUCT
	hdc_target := win32.BeginPaint(hwnd, &ps)
	defer win32.EndPaint(hwnd, &ps)

	hdc_source := win32.CreateCompatibleDC(hdc_target)
	defer win32.DeleteDC(hdc_source)

	win32.SelectObject(hdc_source, win32.HGDIOBJ(dib.hbitmap))

    client_size := win32app.get_rect_size(&ps.rcPaint)
	win32.StretchBlt(
		hdc_target, 0, 0, client_size.x, client_size.y,
		hdc_source, 0, 0, dib.size.x, dib.size.y,
		win32.SRCCOPY)

	return 0
}

WM_TIMER :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	noise_func(&dib)
	win32.RedrawWindow(hwnd, nil, nil, .RDW_INVALIDATE | .RDW_UPDATENOW)
	return 0
}

wndproc :: proc "system" (hwnd: win32.HWND, msg: win32.UINT, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	context = runtime.default_context()
	switch msg {
	case win32.WM_CREATE:		return WM_CREATE(hwnd, lparam)
	case win32.WM_DESTROY:		return WM_DESTROY(hwnd, wparam, lparam)
	case win32.WM_ERASEBKGND:	return 1
	case win32.WM_SIZE:			return WM_SIZE(hwnd, wparam, lparam)
	case win32.WM_PAINT:		return WM_PAINT(hwnd, wparam, lparam)
	case win32.WM_CHAR:			return WM_CHAR(hwnd, wparam, lparam)
	case win32.WM_TIMER:		return WM_TIMER(hwnd, wparam, lparam)
	case:						return win32.DefWindowProcW(hwnd, msg, wparam, lparam)
	}
}

main :: proc() {
	win32app.run(&settings)
}

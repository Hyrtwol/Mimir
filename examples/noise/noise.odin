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

L       :: intrinsics.constant_utf16_cstring
byte4   :: canvas.byte4
int2    :: canvas.int2
float2  :: hlm.float2
double2 :: hlm.double2
double3 :: hlm.double3
DIB     :: canvas.DIB

TITLE 	:: "Noise"
WIDTH  	:: 640
HEIGHT 	:: WIDTH * 9 / 16
CENTER  :: true
ZOOM  	:: 4

timer_id : win32.UINT_PTR
dib      : DIB
npos     : double2 = {0, 0}
ndir     : double2 = {0.017, 0.013}
npos3    : double3 = {0, 0, 0}
ndir3    : double3 = {0.007, 0.009, 0.011}
nseed    : i64 = 12345

dib_noise2 :: proc(dib: ^DIB) {
	p := dib.pvBits
	w := dib.size.x
	h := dib.size.y
	i: i32 = 0
	n, n1, n2: f32
	ni: u8 = 0
	pp: double2 = npos
	ofs: double2
	scale: f64 : 0.01
	for y in 0 ..< h {
		ofs.y = f64(y)
		for x in 0 ..< w {
			ofs.x = f64(x)
			np := pp + ofs * scale
			n1 = noise.noise_2d(nseed, noise.Vec2(np))
			n2 = noise.noise_2d(nseed, noise.Vec2(np * 2))
			n = (n1 * 2 / 3) + (n2 * 0.5 * 1 / 3)
			ni = u8(n * 127.74 + 127.74)
			p[i] = {ni, ni, ni, 255}
			i += 1
		}
	}
	npos += ndir
}

dib_noise3 :: proc(dib: ^DIB) {
	p := dib.pvBits
	w := dib.size.x
	h := dib.size.y
	i: i32 = 0
	n, n1, n2: f32
	ni: u8 = 0
	pp: double3 = npos3
	ofs: double3 = {0, 0, 0}
	scale: f64 : 0.01
	for y in 0 ..< h {
		ofs.y = f64(y)
		for x in 0 ..< w {
			ofs.x = f64(x)
			np := pp + ofs * scale
			//n = noise.noise_3d_improve_xy(nseed, noise.Vec3(np))
			n1 = noise.noise_3d_improve_xy(nseed, noise.Vec3(np))
			n2 = noise.noise_3d_improve_xy(nseed, noise.Vec3(np * -2.0))
			n = (n1 * 2 / 3) + (n2 * 0.5 * 1 / 3)
			ni = u8(n * 127.74 + 127.74)
			p[i] = {ni, u8(n1 * 127.74 + 127.74), u8(n2 * 127.74 + 127.74), 255}
			i += 1
		}
	}
	npos3 += ndir3
}

WM_CREATE :: proc(hWnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	client_size := win32app.get_client_size(hWnd)

	hDC := win32.GetDC(hWnd)

	dib = canvas.dib_create(hDC, client_size / ZOOM)
	if dib.pvBits != nil {
		canvas.dib_clear(&dib, {50, 150, 100, 255})
	} else {
		win32app.show_error_and_panic("No DIB")
	}

	win32.ReleaseDC(hWnd, hDC)

	timer_id = win32.SetTimer(hWnd, win32app.IDT_TIMER1, 50, nil)
	if timer_id == 0 {
		win32app.show_error_and_panic("No timer")
	}

	return 0
}

WM_DESTROY :: proc(hWnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	if timer_id != 0 {
		if !win32.KillTimer(hWnd, timer_id) {
			win32.MessageBoxW(nil, L("Unable to kill timer"), L("Error"), win32.MB_OK)
		}
	}
	canvas.dib_free_section(&dib)
	win32.PostQuitMessage(0)
	return 0
}

WM_ERASEBKGND :: proc(hWnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	return 1
}

WM_CHAR :: proc(hWnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	switch wparam {
	case '\x1b':	win32.DestroyWindow(hWnd)
	case:
	}
	return 0
}

WM_SIZE :: proc(hWnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	size := win32app.int2({win32.GET_X_LPARAM(lparam), win32.GET_Y_LPARAM(lparam)})
	newtitle := fmt.tprintf("%s %v %v\n", TITLE, size, dib.size)
	win32.SetWindowTextW(hWnd, win32.utf8_to_wstring(newtitle))
	return 0
}

WM_PAINT :: proc(hWnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	ps: win32.PAINTSTRUCT
	hDC_target := win32.BeginPaint(hWnd, &ps)

	client_size := win32app.get_client_size(hWnd)

	hDC_source := win32app.CreateCompatibleDC(hDC_target)
	win32.SelectObject(hDC_source, win32.HGDIOBJ(dib.hbitmap))
	win32.StretchBlt(
		hDC_target, 0, 0, client_size.x, client_size.y,
		hDC_source, 0, 0, dib.size.x, dib.size.y,
		win32.SRCCOPY)
	win32app.DeleteDC(hDC_source)

	win32.EndPaint(hWnd, &ps)
	win32.ValidateRect(hWnd, nil)

	return 0
}

WM_TIMER :: proc(hWnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	dib_noise3(&dib)
	win32.InvalidateRect(hWnd, nil, false)
	return 0
}

wndproc :: proc "stdcall" (hWnd: win32.HWND, msg: win32.UINT, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	context = runtime.default_context()
	switch msg {
	case win32.WM_CREATE:		return WM_CREATE(hWnd, wparam, lparam)
	case win32.WM_DESTROY:		return WM_DESTROY(hWnd, wparam, lparam)
	case win32.WM_ERASEBKGND:	return WM_ERASEBKGND(hWnd, wparam, lparam)
	case win32.WM_SIZE:			return WM_SIZE(hWnd, wparam, lparam)
	case win32.WM_PAINT:		return WM_PAINT(hWnd, wparam, lparam)
	case win32.WM_CHAR:			return WM_CHAR(hWnd, wparam, lparam)
	case win32.WM_TIMER:		return WM_TIMER(hWnd, wparam, lparam)
	case:						return win32.DefWindowProcW(hWnd, msg, wparam, lparam)
	}
}

main :: proc() {
	win32app.run(TITLE, {WIDTH, HEIGHT}, CENTER, wndproc)
}

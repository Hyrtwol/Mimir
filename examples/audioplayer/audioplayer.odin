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
import win32ex  "shared:sys/windows"
import          "core:time"
import win32app "shared:tlc/win32app"
import canvas   "shared:tlc/canvas"

//L :: intrinsics.constant_utf16_cstring

TITLE 	:: "Audio Player"
WIDTH  	:: 640
HEIGHT 	:: WIDTH * 9 / 16
CENTER  :: true
ZOOM  	:: 8

settings : win32app.window_settings = {
	title = TITLE,
	window_size = {WIDTH, HEIGHT},
	center = CENTER,
}

// audio

NUM_BUFFERS             :: 8
WM_STOP_PLAY            :: win32.WM_USER
WM_PREPARE_NEXT_BUFFER  :: win32.WM_USER + 1
WAVE_DISPLAY_WIDTH      :: 512
WAVE_DISPLAY_HEIGHT     :: 128
WAVE_DISPLAY_COUNT      :: WAVE_DISPLAY_WIDTH * WAVE_DISPLAY_HEIGHT
NOISE_DISPLAY_WIDTH     :: 512
NOISE_DISPLAY_HEIGHT    :: 512
NOISE_DISPLAY_COUNT     :: NOISE_DISPLAY_WIDTH * NOISE_DISPLAY_HEIGHT

NumSamples      :: WAVE_DISPLAY_WIDTH * 4
MaxIndex        :: NumSamples - 1
MaxPeak         :: 255

TWaveDisplay    :: [WAVE_DISPLAY_COUNT]i32
PWaveDisplay    :: ^TWaveDisplay

TNoiseDisplay   :: [NOISE_DISPLAY_COUNT]i32
PNoiseDisplay   :: ^TNoiseDisplay

dib             : canvas.DIB
colidx          := 1
cols            := canvas.C64_COLORS

decode_scrpos :: proc(lparam: win32.LPARAM) -> win32app.int2 {
	size := win32app.decode_lparam(lparam)
	scrpos := size / ZOOM
	return scrpos
}

setdot :: proc(pos: win32app.int2, col: canvas.byte4) {
	i := pos.y * dib.size.x + pos.x
	if i >= 0 && i < dib.pixel_count {
		dib.pvBits[i] = col
	}
}

WM_CREATE :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	fmt.print("WM_CREATE\n")

	client_size := win32app.get_client_size(hwnd)

	hdc := win32.GetDC(hwnd)
	defer win32.ReleaseDC(hwnd, hdc)

	dib = canvas.dib_create_v5(hdc, client_size / ZOOM)
	if dib.pvBits != nil {
		canvas.dib_clear(&dib, {50, 100, 150, 255})
	}

	return 0
}

WM_DESTROY :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	fmt.print("WM_DESTROY\n")

	canvas.dib_free_section(&dib)

	win32.PostQuitMessage(0)
	return 0
}

WM_ERASEBKGND :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	return 1
}

WM_CHAR :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	//fmt.printf("WM_CHAR %4d 0x%4x 0x%4x 0x%4x\n", wparam, wparam, win32.HIWORD(u32(lparam)), win32.LOWORD(u32(lparam)))
	switch wparam {
	case '\x1b':	win32.DestroyWindow(hwnd)
	case '\t':		fmt.print("tab\n")
	case '\r':		fmt.print("return\n")
	case '1':		if colidx > 0 {colidx -= 1}
	case '2':		if colidx < 15 {colidx += 1}
	case '3':		cols = canvas.C64_COLORS
	case '4':		cols = canvas.W95_COLORS
	}
	return 0
}

WM_SIZE :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	size := win32app.decode_lparam(lparam)
	newtitle := fmt.tprintf("%s %v %v\n", TITLE, size, dib.size)
	win32.SetWindowTextW(hwnd, win32.utf8_to_wstring(newtitle))
	return 0
}

WM_PAINT :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	ps: win32.PAINTSTRUCT
	win32.BeginPaint(hwnd, &ps) // todo check if defer can be used for EndPaint
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
		setdot(pos, cols[colidx])
		win32.InvalidateRect(hwnd, nil, false)
	case 2:
		pos := decode_scrpos(lparam)
		setdot(pos, canvas.C64_BLUE)
		win32.InvalidateRect(hwnd, nil, false)
	case 3:
		pos := decode_scrpos(lparam)
		setdot(pos, canvas.C64_GREEN)
		win32.InvalidateRect(hwnd, nil, false)
	case 4:
		fmt.printf("input %v %d\n", decode_scrpos(lparam), wparam)
	case:
	}
	return 0
}

wndproc :: proc "system" (hwnd: win32.HWND, msg: win32.UINT, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
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
	case:						return win32.DefWindowProcW(hwnd, msg, wparam, lparam)
	}
}

main :: proc() {
	win32app.run(&settings, wndproc)
}

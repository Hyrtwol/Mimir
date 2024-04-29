// +vet
package main

import "core:fmt"
import "core:intrinsics"
import "core:math/rand"
import "core:runtime"
import win32 "core:sys/windows"
import cv "libs:tlc/canvas"
import win32app "libs:tlc/win32app"

L :: intrinsics.constant_utf16_cstring

TITLE 	:: "Mimir"
WIDTH  	:: 640
HEIGHT 	:: WIDTH * 9 / 16
CENTER  :: true
ZOOM  	:: 8

screen_buffer  :: cv.screen_buffer

bitmap_handle : win32.HGDIOBJ // win32.HBITMAP
bitmap_size   : win32app.int2
bitmap_count  : i32
pvBits        : screen_buffer
pixel_size    : win32app.int2 : {ZOOM, ZOOM}

dib           : win32app.DIB
timer1_id     : win32.UINT_PTR
timer2_id     : win32.UINT_PTR

rng := rand.create(u64(intrinsics.read_cycle_counter()))

application :: struct {
	// title: string,
	// size : [2]i32,
	// center: bool,
}
papp :: ^application

decode_scrpos :: proc(lparam: win32.LPARAM) -> win32app.int2 {
	pos := win32app.decode_lparam(lparam) / ZOOM
	pos.y = bitmap_size.y - 1 - pos.y
	return pos
}

random_scrpos :: proc() -> win32app.int2 {
	return {rand.int31_max(bitmap_size.x, &rng), rand.int31_max(bitmap_size.y, &rng)}
}

set_dot :: proc(pos: win32app.int2, col: cv.byte4) {
	i := u32(pos.y * bitmap_size.x + pos.x)
	if i < u32(bitmap_count) {
		pvBits[i] = col
	}
}

WM_CREATE :: proc(hwnd: win32.HWND, lparam: win32.LPARAM) -> win32.LRESULT {
	fmt.println(#procedure, hwnd)
	pcs := win32app.get_createstruct_from_lparam(lparam)
	if pcs == nil {win32app.show_error_and_panic("Missing pcs!");return 1}
	settings := win32app.psettings(pcs.lpCreateParams)
	if settings == nil {win32app.show_error_and_panic("Missing settings!");return 1}
	app := papp(settings.app)
	if app == nil {win32app.show_error_and_panic("Missing app!");return 1}
	win32app.set_settings(hwnd, settings)
	timer1_id = win32app.set_timer(hwnd, win32app.IDT_TIMER1, 1000)
	timer2_id = win32app.set_timer(hwnd, win32app.IDT_TIMER2, 3000)

	client_size := win32app.get_client_size(hwnd)
	bitmap_size = client_size / ZOOM

	{
		hdc := win32.GetDC(hwnd)
		defer win32.ReleaseDC(hwnd, hdc)
		color_byte_count :: 4
		color_bit_count :: color_byte_count * 8
		bmi_header := win32app.create_bmi_header(bitmap_size, false, color_bit_count)
		//fmt.printfln("bmi_header %v", bmi_header)
		bitmap_handle = win32.HGDIOBJ(win32.CreateDIBSection(hdc, cast(^win32.BITMAPINFO)&bmi_header, 0, &pvBits, nil, 0))
	}

	if pvBits != nil {
		bitmap_count = bitmap_size.x * bitmap_size.y
		cv.fill_screen(pvBits, bitmap_count, {0, 0, 0, 0})
	} else {
		bitmap_size = {0, 0}
		bitmap_count = 0
	}

	return 0
}

WM_DESTROY :: proc(hwnd: win32.HWND) -> win32.LRESULT {
	fmt.println(#procedure, hwnd)
	settings := win32app.get_settings(hwnd)
	if settings == nil {win32app.show_error_and_panic("Missing settings!");return 1}
	app := settings.app
	if app == nil {win32app.show_error_and_panic("Missing app!");return 1}
	win32app.kill_timer(hwnd, &timer1_id)
	win32app.kill_timer(hwnd, &timer2_id)
	win32app.delete_object(&bitmap_handle)
	bitmap_size = {0, 0}
	bitmap_count = 0
	pvBits = nil
	win32app.post_quit_message(0)
	return 0
}

WM_ERASEBKGND :: proc(hwnd: win32.HWND, wparam: win32.WPARAM) -> win32.LRESULT {
	return 1
}

WM_SETFOCUS :: proc(hwnd: win32.HWND, wparam: win32.WPARAM) -> win32.LRESULT {
	fmt.println(#procedure, hwnd, wparam)
	return 0
}

WM_KILLFOCUS :: proc(hwnd: win32.HWND, wparam: win32.WPARAM) -> win32.LRESULT {
	fmt.println(#procedure, hwnd, wparam)
	return 0
}

WM_CHAR :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	switch wparam {
	case '\x1b':	win32.DestroyWindow(hwnd)
	case:			fmt.printfln("WM_CHAR %4d 0x%4x 0x%4x 0x%4x", wparam, wparam, win32.HIWORD(u32(lparam)), win32.LOWORD(u32(lparam)))
	}
	return 0
}

WM_SIZE :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	settings := win32app.get_settings(hwnd)
	if settings == nil {return 1}
	type := win32app.WM_SIZE_WPARAM(wparam)
	fmt.println("type:", type)
	settings.window_size = win32app.decode_lparam(lparam)
	win32app.set_window_textf(hwnd, "%s %v %v", settings.title, settings.window_size, bitmap_size)
	return 0
}

ftn := win32.BLENDFUNCTION {
	BlendOp             = win32.AC_SRC_OVER,
	BlendFlags          = 0,
	SourceConstantAlpha = 128,
	AlphaFormat         = win32.AC_SRC_ALPHA,
}

WM_PAINT :: proc(hwnd: win32.HWND) -> win32.LRESULT {
	ps: win32.PAINTSTRUCT
	win32.BeginPaint(hwnd, &ps) // todo check if defer can be used for EndPaint
	defer win32.EndPaint(hwnd, &ps)

	hdc_source := win32.CreateCompatibleDC(ps.hdc)
	defer win32.DeleteDC(hdc_source)

	client_size := win32app.get_rect_size(&ps.rcPaint)
	//win32.SelectObject(hdc_source, bitmap_handle)
	//win32.StretchBlt(ps.hdc, 0, 0, client_size.x, client_size.y, hdc_source, 0, 0, bitmap_size.x, bitmap_size.y, win32.SRCCOPY)

	brush := win32.HBRUSH(win32.GetStockObject(win32.DC_BRUSH))

	col, org_color: win32.COLORREF

	col = win32.RGB(50, 100, 150)
	org_color = win32.SetDCBrushColor(ps.hdc, win32.COLORREF(col))
	win32.FillRect(ps.hdc, &ps.rcPaint, brush)
	win32.SetDCBrushColor(ps.hdc, org_color)

	//original := win32.SelectObject(ps.hdc, win32.GetStockObject(win32.DC_PEN))
	//defer win32.SelectObject(ps.hdc, original)

	col = win32.RGB(150, 100, 50)
	org_color = win32.SetDCBrushColor(ps.hdc, win32.COLORREF(col))
	rect := win32.RECT{40, 40, 240, 240}
	win32.FillRect(ps.hdc, &rect, brush)
	win32.SetDCBrushColor(ps.hdc, org_color)

	verts := [?]win32.TRIVERTEX {
		{300, 200, 0xff00, 0x8000, 0x0000, 0x0000},
		{400, 100, 0x9000, 0x0000, 0x9000, 0x0000},
		{500, 200, 0x0000, 0x8000, 0xff00, 0x0000},
		{600, 100, 0x0000, 0xff00, 0x0000, 0x0000},
	}
	mesh := [?]win32.GRADIENT_TRIANGLE {
		{0, 1, 2},
		{1, 2, 3},
	}
	win32.GradientFill(ps.hdc, &verts[0], win32.ULONG(len(verts)), &mesh[0], win32.ULONG(len(mesh)), win32.GRADIENT_FILL_TRIANGLE)

	txt := fmt.tprintf("Hello %#X", col)
	win32.TextOutW(ps.hdc, 50, 50, win32.utf8_to_wstring(txt), i32(len(txt)))

	win32.SelectObject(hdc_source, bitmap_handle)
	win32.AlphaBlend(ps.hdc, 0, 0, client_size.x, client_size.y, hdc_source, 0, 0, bitmap_size.x, bitmap_size.y, ftn)

	return 0
}

WM_TIMER :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	switch win32.UINT_PTR(wparam)
	{
		case win32app.IDT_TIMER1: set_dot_invalidate(hwnd, random_scrpos(), cv.COLOR_CYAN)
		case win32app.IDT_TIMER2: set_dot_invalidate(hwnd, random_scrpos(), cv.COLOR_YELLOW)
	}
	return 0
}

set_dot_invalidate :: proc(hwnd: win32.HWND, pos: win32app.int2, col: cv.byte4) {
	set_dot(pos, col)
	win32app.invalidate(hwnd)
}

decode_set_dot :: proc(hwnd: win32.HWND, lparam: win32.LPARAM, col: cv.byte4) {
	set_dot_invalidate(hwnd, decode_scrpos(lparam), col)
}

handle_input :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	// odinfmt: disable
	switch wparam {
	case 1: decode_set_dot(hwnd, lparam, cv.COLOR_RED)
	case 2: decode_set_dot(hwnd, lparam, cv.COLOR_BLUE)
	case 3: decode_set_dot(hwnd, lparam, cv.COLOR_GREEN)
	//case: fmt.println(#procedure, decode_scrpos(lparam), wparam)
	}
	// odinfmt: enable
	return 0
}

wndproc :: proc "system" (hwnd: win32.HWND, msg: win32app.WM_MSG, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	context = runtime.default_context()
	// odinfmt: disable
	switch msg {
	case .WM_CREATE:		return WM_CREATE(hwnd, lparam)
	case .WM_DESTROY:		return WM_DESTROY(hwnd)
	case .WM_ERASEBKGND:	return WM_ERASEBKGND(hwnd, wparam)
	case .WM_SETFOCUS:		return WM_SETFOCUS(hwnd, wparam)
	case .WM_KILLFOCUS:		return WM_KILLFOCUS(hwnd, wparam)
	case .WM_SIZE:			return WM_SIZE(hwnd, wparam, lparam)
	case .WM_PAINT:			return WM_PAINT(hwnd)
	case .WM_CHAR:			return WM_CHAR(hwnd, wparam, lparam)
	case .WM_TIMER:			return WM_TIMER(hwnd, wparam, lparam)
	case .WM_MOUSEMOVE:		return handle_input(hwnd, wparam, lparam)
	case .WM_LBUTTONDOWN:	return handle_input(hwnd, wparam, lparam)
	case .WM_RBUTTONDOWN:	return handle_input(hwnd, wparam, lparam)
	case:					return win32.DefWindowProcW(hwnd, win32.UINT(msg), wparam, lparam)
	}
	// odinfmt: enable
}

main :: proc() {

	app: application = {
		//size = {WIDTH, HEIGHT},
	}

	stopwatch := win32app.create_stopwatch()
	stopwatch->start()

	settings := win32app.create_window_settings(TITLE, win32app.int2{WIDTH, HEIGHT}, wndproc)
	settings.app = &app
	win32app.run(&settings)

	stopwatch->stop()
	fmt.printfln("Done. %fs", stopwatch->get_elapsed_seconds())
}

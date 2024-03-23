package amstrad

import "core:fmt"
import "core:intrinsics"
import "core:math/rand"
import "core:os"
import "core:runtime"
import win32 "core:sys/windows"
import canvas "shared:tlc/canvas"
import win32app "shared:tlc/win32app"
import z80 "shared:z80"

// aliases
L				:: intrinsics.constant_utf16_cstring
color			:: [4]u8
wstring			:: win32.wstring
utf8_to_wstring	:: win32.utf8_to_wstring
int2			:: [2]i32

IDT_TIMER1: win32.UINT_PTR : 10001

TITLE :: "Amstrad"
WIDTH :: 768
HEIGHT :: 272
HEIGHT_SCALE :: 2
FPS :: 10

SOX, SOY: i32 = (WIDTH - SCREEN_WIDTH) / 2, (HEIGHT - SCREEN_HEIGHT)

rng := rand.create(u64(intrinsics.read_cycle_counter()))

hbrGray: win32.HBRUSH

BITMAPINFO :: struct {
	bmiHeader: win32.BITMAPV5HEADER,
	bmiColors: color_palette,
}

app :: struct {
	pause:    bool,
	//colors:    []color,
	size:     int2,
	timer_id: win32.UINT_PTR,
	tick:     u32,
	//title:     wstring,
	hbitmap:  win32.HBITMAP,
	pvBits:   screen_buffer,
}
papp :: ^app

set_app :: #force_inline proc(hwnd: win32.HWND, app: papp) {win32.SetWindowLongPtrW(hwnd, win32.GWLP_USERDATA, win32.LONG_PTR(uintptr(app)))}

get_app :: #force_inline proc(hwnd: win32.HWND) -> papp {return (papp)(rawptr(uintptr(win32.GetWindowLongPtrW(hwnd, win32.GWLP_USERDATA))))}

WM_CREATE :: proc(hwnd: win32.HWND, lparam: win32.LPARAM) -> win32.LRESULT {
	pcs := (^win32.CREATESTRUCTW)(rawptr(uintptr(lparam)))
	if pcs == nil {win32app.show_error_and_panic("Missing pcs!");return 1}
	app := (papp)(pcs.lpCreateParams)
	if app == nil {win32app.show_error_and_panic("Missing app!");return 1}
	//fmt.printf("WM_CREATE %v %v %v\n", hwnd, pcs, app)
	set_app(hwnd, app)

	hbrGray = win32.HBRUSH(win32.GetStockObject(win32.BLACK_BRUSH))

	bitmap_info := BITMAPINFO {
		bmiHeader = win32.BITMAPV5HEADER {
			bV5Size          = size_of(win32.BITMAPV5HEADER),
			bV5Width         = SCREEN_WIDTH,
			bV5Height        = -(SCREEN_HEIGHT+5), // minus for top-down
			bV5Planes        = 1,
			bV5BitCount      = color_bits,
			bV5Compression   = win32.BI_RGB,
			bV5ClrUsed       = palette_count,
		},
	}

	bs: i32 = bitmap_info.bmiHeader.bV5Width * -bitmap_info.bmiHeader.bV5Height * i32(bitmap_info.bmiHeader.bV5BitCount) / 8
	fmt.printfln("dib byte size=%d ~ %d", bs, bs - 16384)

	for i in 0 ..< min(palette_count, 16) {
		ink := canvas.AMSTRAD_INK[i]
		//ink := rand.int31_max(27, &rng)
		bitmap_info.bmiColors[i] = canvas.AMSTRAD_COLORS[ink].bgra
	}

	{
		hdc := win32.GetDC(hwnd)
		defer win32.ReleaseDC(hwnd, hdc)

		app.hbitmap = win32.CreateDIBSection(hdc, cast(^win32.BITMAPINFO)&bitmap_info, win32.DIB_RGB_COLORS, &app.pvBits, nil, 0)

		//fmt.printf("app.hbitmap=%v %v\n", app.hbitmap, app.pvBits)
		//update_screen(app)
		//win32.FillRect(hdc)

		// if hbrGray != nil {
		// 	rect: win32.RECT
		// 	win32.GetClientRect(hwnd, &rect)
		// 	fmt.printf("rect=%v\n", rect)
		// 	win32.FillRect(hdc, &rect, hbrGray)
		// }
	}

	pvBits := app.pvBits
	if pvBits != nil {
		cc := min(screen_byte_count, len(p_image))
		for i in 0 ..< cc {
			pvBits[i] = p_image[i]
		}
	}

	app.timer_id = win32.SetTimer(hwnd, IDT_TIMER1, 1000 / FPS, nil)
	if app.timer_id == 0 {win32app.show_error_and_panic("No timer")}

	return 0
}

WM_DESTROY :: proc(hwnd: win32.HWND) -> win32.LRESULT {
	app := get_app(hwnd)
	//fmt.printf("WM_DESTROY %v\n%v\n", hwnd, app)
	if app == nil {win32app.show_error_and_panic("Missing app!");return 1}
	if app.timer_id != 0 {
		if !win32.KillTimer(hwnd, app.timer_id) {
			win32.MessageBoxW(nil, L("Unable to kill timer"), L("Error"), win32.MB_OK)
		}
		app.timer_id = 0
	}
	if app.hbitmap != nil {
		if !win32.DeleteObject(win32.HGDIOBJ(app.hbitmap)) {
			win32.MessageBoxW(nil, L("Unable to delete hbitmap"), L("Error"), win32.MB_OK)
		}
		app.hbitmap = nil
	}
	win32.PostQuitMessage(0) // exit code
	return 0
}

WM_ERASEBKGND :: proc(hwnd: win32.HWND, wparam: win32.WPARAM) -> win32.LRESULT {
	//return 1 // paint should fill out the client area so no need to erase the background
	if hbrGray != nil {
		hdc := win32.GetDC(hwnd)
		defer win32.ReleaseDC(hwnd, hdc)
		rect: win32.RECT
		win32.GetClientRect(hwnd, &rect)
		fmt.printf("rect=%v\n", rect)
		win32.FillRect(hdc, &rect, hbrGray)
	}
	return 0
}

WM_PAINT :: proc(hwnd: win32.HWND) -> win32.LRESULT {
	app := get_app(hwnd)
	if app == nil {return 0}

	ps: win32.PAINTSTRUCT
	win32.BeginPaint(hwnd, &ps)
	defer win32.EndPaint(hwnd, &ps)

	if (app.hbitmap != nil) {
		hdc_source := win32.CreateCompatibleDC(ps.hdc)
		defer win32.DeleteDC(hdc_source)

		win32.SelectObject(hdc_source, win32.HGDIOBJ(app.hbitmap))
		client_size := win32app.get_rect_size(&ps.rcPaint)
		//win32.BitBlt(ps.hdc, 0, 0, SCREEN_WIDTH, SCREEN_HEIGHT, hdc_source, 0, 0, win32.SRCCOPY)
		//win32.StretchBlt(ps.hdc, 0, 0, client_size.x, client_size.y, hdc_source, 0, 0, SCREEN_WIDTH, SCREEN_HEIGHT, win32.SRCCOPY)
		win32.StretchBlt(ps.hdc, SOX, SOY, SCREEN_WIDTH, SCREEN_HEIGHT * 2, hdc_source, 0, 0, SCREEN_WIDTH, SCREEN_HEIGHT, win32.SRCCOPY)
	}

	return 0
}

WM_TIMER :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	switch wparam {
	case IDT_TIMER1:
		app := get_app(hwnd)
		if app != nil {
			app.tick += 1

			if put_chars {update_screen_2(app)}

			win32.RedrawWindow(hwnd, nil, nil, .RDW_INVALIDATE | .RDW_UPDATENOW)
		}
	case:
		fmt.printf("WM_TIMER %v %v %v\n", hwnd, wparam, lparam)
	}
	return 0
}

// odinfmt: disable

WM_CHAR :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	switch wparam {
	case '\x1b':	win32.PostMessageW(hwnd, win32.WM_CLOSE, 0, 0)
	case '\t':		put_chars ~= true
	case: {
		app := get_app(hwnd)
		if app == nil {win32app.show_error_and_panic("Missing app!");return 1}
		//ch := u8(wparam)
		//fmt.printfln("WM_CHAR %x %d %v", wparam, ch, rune(ch))
		put_char(app.pvBits, u8(wparam))
	}
	}

	return 0
}

wndproc :: proc "system" (hwnd: win32.HWND, msg: win32.UINT, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	context = runtime.default_context()
	switch msg {
	case win32.WM_CREATE:		return WM_CREATE(hwnd, lparam)
	case win32.WM_DESTROY:		return WM_DESTROY(hwnd)
	case win32.WM_ERASEBKGND:	return WM_ERASEBKGND(hwnd, wparam)
	case win32.WM_PAINT:		return WM_PAINT(hwnd)
	case win32.WM_CHAR:			return WM_CHAR(hwnd, wparam, lparam)
	case win32.WM_TIMER:		return WM_TIMER(hwnd, wparam, lparam)
	case:						return win32.DefWindowProcW(hwnd, msg, wparam, lparam)
	}
}

// odinfmt: enable

run_app :: proc(app: papp) {

	settings := win32app.create_window_settings(TITLE, WIDTH, HEIGHT * HEIGHT_SCALE, wndproc)
	settings.app = app
	win32app.run(&settings)
}

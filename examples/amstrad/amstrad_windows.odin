#+build windows
package main

import "core:fmt"
import "base:intrinsics"
import "base:runtime"
import win32 "core:sys/windows"
import cv "libs:tlc/canvas"
import "libs:tlc/win32app"
import z "shared:z80"

// constants
IDT_TIMER1: win32.UINT_PTR : 10001

TITLE :: "Amstrad"
WIDTH :: 768
HEIGHT :: 272
SCREEN_HEIGHT_SCALE :: 2
SCREEN_SIZE :: screen_sizes_overscan[2]
FPS :: 10

// globals
SOX, SOY: i32 = (WIDTH - SCREEN_WIDTH) / 2, (HEIGHT - SCREEN_HEIGHT)

bkgnd_brush: win32.HBRUSH

BITMAPINFO :: struct {
	bmiHeader: win32.BITMAPV5HEADER,
	bmiColors: color_palette,
}

set_app :: #force_inline proc(hwnd: win32.HWND, app: papp) {
	win32.SetWindowLongPtrW(hwnd, win32.GWLP_USERDATA, win32.LONG_PTR(uintptr(app)))
}

get_app :: #force_inline proc(hwnd: win32.HWND) -> papp {
	app := (papp)(rawptr(uintptr(win32.GetWindowLongPtrW(hwnd, win32.GWLP_USERDATA))))
	if app == nil {win32app.show_error_and_panic("Missing app!")}
	return app
}

fill_screen_with_image :: proc(app: papp) {
	pvBits := app.pvBits
	if pvBits != nil {
		cc := min(screen_byte_count, len(p_image))
		for i in 0 ..< cc {
			pvBits[i] = p_image[i]
		}
	}
}

amstrad_colors := cv.AMSTRAD_COLORS
amstrad_ink := cv.AMSTRAD_INK

WM_CREATE :: proc(hwnd: win32.HWND, lparam: win32.LPARAM) -> win32.LRESULT {
	settings := win32app.get_settings_from_lparam(lparam)
	if settings == nil {win32app.show_error_and_panic("Missing settings");return 1}
	app := (papp)(settings.app)
	if app == nil {win32app.show_error_and_panic("Missing app!");return 1}
	set_app(hwnd, app)
	//fmt.println(#procedure, hwnd, pcs, app)

	bkgnd_brush = win32.HBRUSH(win32.GetStockObject(win32.BLACK_BRUSH))

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
		ink := amstrad_ink[i]
		//ink := rand.int31_max(27)
		bitmap_info.bmiColors[i] = amstrad_colors[ink].bgra
	}

	{
		hdc := win32.GetDC(hwnd)
		defer win32.ReleaseDC(hwnd, hdc)
		app.hbitmap = win32app.create_dib_section(hdc, cast(^win32.BITMAPINFO)&bitmap_info, .DIB_RGB_COLORS, &app.pvBits)
	}

	//fill_screen_with_image(app)
	if app.pvBits != nil {
		intrinsics.mem_copy(app.pvBits, &memory[0xC000], size_16kb)
	}

	app.timer_id = win32app.set_timer(hwnd, IDT_TIMER1, 1000 / FPS)

	if app.cpu != nil {
		z.z80_power(app.cpu, true)
		//fmt.printfln("CPU %v", app.cpu)
	}

	return 0
}

WM_DESTROY :: proc(hwnd: win32.HWND) -> win32.LRESULT {
	app := get_app(hwnd)
	//fmt.println(#procedure, hwnd, app)
	if app == nil {win32app.show_error_and_panic("Missing app!");return 1}
	win32app.kill_timer(hwnd, &app.timer_id)
	if !win32app.delete_object(&app.hbitmap) {win32app.show_message_box("Unable to delete hbitmap", "Error")}
	win32app.post_quit_message(0) // exit code
	return 0
}

WM_ERASEBKGND :: proc(hwnd: win32.HWND, wparam: win32.WPARAM) -> win32.LRESULT {
	//return 1 // paint should fill out the client area so no need to erase the background
	if bkgnd_brush != nil {
		hdc := win32.GetDC(hwnd)
		defer win32.ReleaseDC(hwnd, hdc)
		rect: win32.RECT
		win32.GetClientRect(hwnd, &rect)
		win32.FillRect(hdc, &rect, bkgnd_brush)
	}
	return 0
}

focused := false

WM_SETFOCUS :: proc(hwnd: win32.HWND, wparam: win32.WPARAM) -> win32.LRESULT {
	focused = true
	//fmt.printfln("WM_SETFOCUS %v %v %v", hwnd, wparam, focused)
	return 0
}

WM_KILLFOCUS :: proc(hwnd: win32.HWND, wparam: win32.WPARAM) -> win32.LRESULT {
	focused = false
	//fmt.printfln("WM_KILLFOCUS %v %v %v", hwnd, wparam, focused)
	return 0
}

WM_SIZE :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	settings := win32app.get_settings(hwnd)
	if settings == nil {return 1}
	type := win32app.WM_SIZE_WPARAM(wparam)
	settings.window_size = win32app.decode_lparam_as_int2(lparam)
	win32app.set_window_text(hwnd, "%s %v %v", settings.title, settings.window_size, type)
	return 0
}

WM_PAINT :: proc(hwnd: win32.HWND) -> win32.LRESULT {
	app := get_app(hwnd)
	if app == nil {return 0}

	ps: win32.PAINTSTRUCT
	hdc := win32.BeginPaint(hwnd, &ps)
	defer win32.EndPaint(hwnd, &ps)

	if (app.hbitmap != nil) {
		hdc_source := win32.CreateCompatibleDC(hdc)
		defer win32.DeleteDC(hdc_source)

		win32.SelectObject(hdc_source, win32.HGDIOBJ(app.hbitmap))
		//client_size := win32app.get_rect_size(&ps.rcPaint)
		win32.StretchBlt(hdc, SOX, SOY, SCREEN_WIDTH, SCREEN_HEIGHT * 2, hdc_source, 0, 0, SCREEN_WIDTH, SCREEN_HEIGHT, win32.SRCCOPY)
	}

	return 0
}

WM_TIMER :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	switch win32.UINT_PTR(wparam) {
	case IDT_TIMER1:
		app := get_app(hwnd)
		if app != nil {
			app.tick += 1
			if put_chars {update_screen_3(app)}
			win32.RedrawWindow(hwnd, nil, nil, .RDW_INVALIDATE | .RDW_UPDATENOW)
		}
	case:
		fmt.println(#procedure, hwnd, wparam, lparam)
	}
	return 0
}

WM_CHAR :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	/*
	switch wparam {
	//case '\x1b':	win32app.close_application(hwnd)
	//case '\t':	put_chars ~= true
	case: {
		app := get_app(hwnd)
		if app == nil {return 1}
		//ch := u8(wparam);fmt.printfln("WM_CHAR %x %d %v", wparam, ch, rune(ch))
		put_char(app.pvBits, u8(wparam))
	}
	}
	*/
	app := get_app(hwnd)
	if app == nil {return 1}
	put_char(app.pvBits, u8(wparam))
	return 0
}

handle_key_input :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	vk_code := win32.LOWORD(wparam) // virtual-key code
	key_flags := win32.HIWORD(lparam)
	repeat_count := win32.LOWORD(lparam) // repeat count, > 0 if several keydown messages was combined into one message
	scan_code := win32.WORD(win32.LOBYTE(key_flags)) // scan code
	is_extended_key := (key_flags & win32.KF_EXTENDED) == win32.KF_EXTENDED // extended-key flag, 1 if scancode has 0xE0 prefix
	if is_extended_key {scan_code = win32.MAKEWORD(scan_code, 0xE0)}
	was_key_down := (key_flags & win32.KF_REPEAT) == win32.KF_REPEAT // previous key-state flag, 1 on autorepeat
	is_key_released := (key_flags & win32.KF_UP) == win32.KF_UP // transition-state flag, 1 on keyup

	switch (vk_code)
	{
	case win32.VK_SHIFT: // converts to VK_LSHIFT or VK_RSHIFT
	case win32.VK_CONTROL: // converts to VK_LCONTROL or VK_RCONTROL
	case win32.VK_MENU:
		// converts to VK_LMENU or VK_RMENU
		vk_code = win32.LOWORD(win32.MapVirtualKeyW(win32.DWORD(scan_code), win32.MAPVK_VSC_TO_VK_EX))
		break
	}

	switch vk_code {
	case win32.VK_ESCAPE:
		if is_key_released {win32app.close_application(hwnd)}
	case win32.VK_F1:
		if is_key_released {put_chars ~= true}
	case win32.VK_F2:
		app := get_app(hwnd)
		if app == nil {return 1}
		fill_screen_with_image(app)
	case win32.VK_F3:
		app := get_app(hwnd)
		if app == nil {return 1}
		z.z80_instant_reset(app.cpu)
		fmt.printfln("pc=%d", app.cpu.pc)
	case win32.VK_F4:
		app := get_app(hwnd)
		if app == nil {return 1}
		z.z80_power(app.cpu, true)
		fmt.printfln("pc=%d", app.cpu.pc)
	case win32.VK_F9:
		print_screen_info()
	//case: fmt.printfln("key: %4d 0x%4X %8d ke: %t kd: %t kr: %t", vk_code, key_flags, scan_code, is_extended_key, was_key_down, is_key_released)
	}
	_ = was_key_down
	_ = repeat_count
	return 0
}

handle_sys_key_input :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	// F10 or ALT
	//fmt.printfln("sys key: %d 0x%8X", wparam, lparam)
	return 0
}

wndproc :: proc "system" (hwnd: win32.HWND, msg: win32.UINT, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	// odinfmt: disable
	context = runtime.default_context()
	switch msg {
	case win32.WM_CREATE:		return WM_CREATE(hwnd, lparam)
	case win32.WM_DESTROY:		return WM_DESTROY(hwnd)
	case win32.WM_ERASEBKGND:	return WM_ERASEBKGND(hwnd, wparam)
	case win32.WM_SETFOCUS:		return WM_SETFOCUS(hwnd, wparam)
	case win32.WM_KILLFOCUS:	return WM_KILLFOCUS(hwnd, wparam)
	//case win32.WM_SIZE:	return WM_SIZE(hwnd, wparam)
	case win32.WM_PAINT:		return WM_PAINT(hwnd)
	//case win32.WM_KEYDOWN:		return handle_key_input(hwnd, wparam, lparam)
	case win32.WM_KEYUP:		return handle_key_input(hwnd, wparam, lparam)
	//case win32.WM_SYSKEYDOWN:	return handle_sys_key_input(hwnd, wparam, lparam)
	//case win32.WM_SYSKEYUP:	return handle_sys_key_input(hwnd, wparam, lparam)
	case win32.WM_CHAR:			return WM_CHAR(hwnd, wparam, lparam)
	case win32.WM_TIMER:		return WM_TIMER(hwnd, wparam, lparam)
	case:						return win32.DefWindowProcW(hwnd, msg, wparam, lparam)
	}
	// odinfmt: enable
}

total: z.zusize = 0
reps := 0

run_app :: proc(app: papp) {

	settings := win32app.create_window_settings(TITLE, WIDTH, HEIGHT * SCREEN_HEIGHT_SCALE, wndproc)
	settings.app = app

	app.settings = settings

	inst := win32app.get_instance()
	atom := win32app.register_window_class(inst, settings.wndproc)
	_ = win32app.create_and_show_window(inst, atom, &settings)

	for win32app.pull_messages() {
		for running {
			total += z.z80_run(app.cpu, cycles_per_tick)
			reps += 1
		}
	}

}

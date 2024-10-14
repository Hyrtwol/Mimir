#+vet
package main

import "core:fmt"
import "base:intrinsics"
import "base:runtime"
import win32 "core:sys/windows"
import cv "libs:tlc/canvas"
import "libs:tlc/win32app"

L :: win32app.L

TITLE :: "Raw Input"
ZOOM :: 24
WIDTH :: ZOOM * 32
HEIGHT :: WIDTH

settings := win32app.create_window_settings({WIDTH, HEIGHT}, TITLE, wndproc)

dib: win32app.DIB
selected_color: i32 = 1
cols := cv.C64_COLORS

icon: win32.HICON

mouse_pos: win32app.int2 = {0, 0}
is_active: bool = true
is_focused := false
cursor_state: i32 = 0

show_cursor :: proc(show: bool) {
	cursor_state = win32app.show_cursor(show)
	fmt.println(#procedure, cursor_state)
}

clip_cursor :: proc(hwnd: win32.HWND, clip: bool) -> bool {
	return win32app.clip_cursor(hwnd, clip)
}

decode_scrpos :: proc(lparam: win32.LPARAM) -> win32app.int2 {
	size := win32app.decode_lparam_as_int2(lparam)
	return size / ZOOM
}

set_dot :: proc(pos: win32app.int2, col: cv.byte4) {
	cv.canvas_set_dot(&dib.canvas, pos, col)
}

WM_CREATE :: proc(hwnd: win32.HWND, lparam: win32.LPARAM) -> win32.LRESULT {
	fmt.println(#procedure)

	show_cursor(false)

	client_size := win32app.get_client_size(hwnd)

	hdc := win32.GetDC(hwnd)
	defer win32.ReleaseDC(hwnd, hdc)

	dib = win32app.dib_create_v5(hdc, client_size / ZOOM)
	if dib.canvas.pvBits != nil {
		cv.canvas_clear(&dib, cols[0])
	}

	return 0
}

WM_DESTROY :: proc(hwnd: win32.HWND) -> win32.LRESULT {
	fmt.println(#procedure)
	clip_cursor(hwnd, false)
	if cursor_state < 1 {
		show_cursor(true)
	}
	win32app.dib_free_section(&dib)
	win32app.post_quit_message()
	return 0
}

WM_SIZE :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	settings.window_size = win32app.decode_lparam_as_int2(lparam)
	win32app.set_window_text(hwnd, "%s %v %v", TITLE, settings.window_size, dib.canvas.size)
	clip_cursor(hwnd, true)
	return 0
}

pen_color: u32 = 0x80808080

WM_PAINT :: proc(hwnd: win32.HWND) -> win32.LRESULT {
	ps: win32.PAINTSTRUCT
	hdc := win32.BeginPaint(hwnd, &ps)
	if hdc == nil {return 1}
	defer win32.EndPaint(hwnd, &ps)

	hdc_source := win32.CreateCompatibleDC(ps.hdc)
	defer win32.DeleteDC(hdc_source)

	win32.SelectObject(hdc_source, win32.HGDIOBJ(dib.hbitmap))
	client_size := win32app.get_rect_size(&ps.rcPaint)
	dib_size := transmute(cv.int2)dib.canvas.size
	win32.StretchBlt(ps.hdc, 0, 0, client_size.x, client_size.y, hdc_source, 0, 0, dib_size.x, dib_size.y, win32.SRCCOPY)

	dc_pen := win32.GetStockObject(win32.DC_PEN)

	old_dc_pen := win32.SelectObject(hdc, dc_pen)
	old_pen := win32.SetDCPenColor(hdc, pen_color)

	win32app.draw_grid(hdc, {0, 0}, {ZOOM, ZOOM}, transmute(win32app.int2)dib.canvas.size)
	win32app.draw_marker(hdc, mouse_pos)

	win32.SetDCPenColor(hdc, old_pen)
	win32.SelectObject(hdc_source, old_dc_pen)

	if icon != nil {
		win32.DrawIcon(ps.hdc, mouse_pos.x + 10, mouse_pos.y + 10, icon)
	}

	return 0
}

WM_ACTIVATEAPP :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	active := wparam != 0
	fmt.println(#procedure, active, cursor_state)
	if is_active == active {return 0}
	is_active = active
	clip_cursor(hwnd, active)
	// if active {
	// } else {
	// }
	// sc := win32.ShowCursor(!is_active)
	// fmt.printf("ShowCursor:", sc)
	return 0
}

wm_focus :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, focused: bool) -> win32.LRESULT {
	is_focused = focused
	fmt.println(#procedure, /*hwnd, wparam,*/ is_focused)
	return 0
}

rawinput: win32.RAWINPUT = {}

put_it := 0

WM_INPUT :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	assert(win32.GET_RAWINPUT_CODE_WPARAM(wparam) == .RIM_INPUT)
	dwSize: win32.UINT
	win32.GetRawInputData(win32.HRAWINPUT(lparam), win32.RID_INPUT, nil, &dwSize, size_of(win32.RAWINPUTHEADER))
	if dwSize == 0 {return 0}
	if dwSize > size_of(win32.RAWINPUT) {win32app.show_error_and_panic("dwSize too big");return 0}

	raw := &rawinput

	if win32.GetRawInputData(win32.HRAWINPUT(lparam), win32.RID_INPUT, raw, &dwSize, size_of(win32.RAWINPUTHEADER)) != dwSize {
		win32app.show_error_and_panic("GetRawInputData Failed")
		return 0
	}

	switch raw.header.dwType {
	case win32.RIM_TYPEMOUSE:
		{
			mouse_delta: win32app.int2 = {raw.data.mouse.lLastX, raw.data.mouse.lLastY}
			mouse_pos += mouse_delta
			//cs := transmute(win32app.int2)(settings.window_size - 1)
			cs := settings.window_size - 1
			mouse_pos = {clamp(mouse_pos.x, 0, cs.x), clamp(mouse_pos.y, 0, cs.y)}
			//mouse_pos = clamp(mouse_pos, cv.float2_zero, cs)

			button_flags := raw.data.mouse.usButtonFlags
			if button_flags > 0 {
				switch button_flags {
				case win32.RI_MOUSE_BUTTON_1_DOWN:
					put_it = 1
				case win32.RI_MOUSE_BUTTON_1_UP:
					put_it = 0
				case win32.RI_MOUSE_BUTTON_2_DOWN:
					put_it = 2
				case win32.RI_MOUSE_BUTTON_2_UP:
					put_it = 0
				}
			}
			switch put_it {
			case 1:
				set_dot(mouse_pos / ZOOM, cols[selected_color])
			case 2:
				set_dot(mouse_pos / ZOOM, cols[0])
			}

			win32.RedrawWindow(hwnd, nil, nil, .RDW_INVALIDATE | .RDW_UPDATENOW)
		}
	case win32.RIM_TYPEKEYBOARD:
		{
			switch raw.data.keyboard.VKey {
			case win32.VK_ESCAPE:
				win32app.close_application(hwnd)
			case win32.VK_0 ..= win32.VK_9:
				selected_color = i32(raw.data.keyboard.VKey - win32.VK_0)
			case:
				fmt.println("keyboard:", raw.data.keyboard)
			}
		}
	case:
		fmt.println("dwType:", raw.header.dwType)
	}

	return 0
}

wndproc :: proc "system" (hwnd: win32.HWND, msg: win32.UINT, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	context = runtime.default_context()
	// odinfmt: disable
	switch msg {
	case win32.WM_CREATE:		return WM_CREATE(hwnd, lparam)
	case win32.WM_DESTROY:		return WM_DESTROY(hwnd)
	case win32.WM_ERASEBKGND:	return 1
	case win32.WM_SIZE:			return WM_SIZE(hwnd, wparam, lparam)
	case win32.WM_PAINT:		return WM_PAINT(hwnd)
	case win32.WM_ACTIVATEAPP:	return WM_ACTIVATEAPP(hwnd, wparam, lparam)
	//case win32.WM_ACTIVATE: return WM_ACTIVATE(hwnd, wparam, lparam)
	case win32.WM_SETFOCUS:		return wm_focus(hwnd, wparam, true)
	case win32.WM_KILLFOCUS:	return wm_focus(hwnd, wparam, false)
	case win32.WM_INPUT:		return WM_INPUT(hwnd, wparam, lparam)
	case:						return win32.DefWindowProcW(hwnd, msg, wparam, lparam)
	}
	// odinfmt: enable
}

main :: proc() {

	icon = win32.LoadIconW(nil, win32.wstring(win32._IDI_QUESTION))
	fmt.println("icon:", icon)

	rid := [2]win32.RAWINPUTDEVICE {
		{usUsagePage = win32.HID_USAGE_PAGE_GENERIC, usUsage = win32.HID_USAGE_GENERIC_MOUSE, dwFlags = win32.RIDEV_NOLEGACY, hwndTarget = nil},
		{usUsagePage = win32.HID_USAGE_PAGE_GENERIC, usUsage = win32.HID_USAGE_GENERIC_KEYBOARD, dwFlags = win32.RIDEV_NOLEGACY, hwndTarget = nil},
	}

	if (!win32.RegisterRawInputDevices(&rid[0], len(rid), size_of(rid[0]))) {
		win32app.show_error_and_panic("RegisterRawInputDevices Failed")
	}

	win32app.run(&settings)
}

#+vet
package main

import "base:intrinsics"
import "base:runtime"
import "core:fmt"
import "core:math/linalg"
import win32 "core:sys/windows"
import cv "libs:tlc/canvas"
import owin "libs:tlc/win32app"

L :: owin.L

TITLE :: "Raw Input"
ZOOM :: 24
WIDTH :: ZOOM * 32
HEIGHT :: WIDTH

application :: struct {
	#subtype settings: owin.window_settings,
}

dib: owin.DIB
selected_color: i32 = 1
cols := cv.C64_COLORS

icon: win32.HICON

mouse_pos: owin.int2 = {0, 0}
is_active: bool = true
is_focused := false
cursor_state: i32 = 0

show_cursor :: #force_inline proc(show: bool) {
	cursor_state = owin.show_cursor(show)
	fmt.println(#procedure, cursor_state)
}

clip_cursor :: #force_inline proc "contextless" (hwnd: win32.HWND, clip: bool) -> bool {
	return owin.clip_cursor(hwnd, clip)
}

decode_scrpos :: #force_inline proc "contextless" (lparam: win32.LPARAM) -> owin.int2 {
	size := owin.decode_lparam_as_int2(lparam)
	return size / ZOOM
}

set_dot :: #force_inline proc "contextless" (pos: owin.int2, col: cv.byte4) {
	cv.canvas_set_dot(&dib.canvas, pos, col)
}

get_app :: #force_inline proc(hwnd: win32.HWND) -> ^application {
	app := owin.get_settings(hwnd, application)
	if app == nil {owin.show_error_and_panic("Missing app!")}
	return app
}

WM_CREATE :: proc(hwnd: win32.HWND, lparam: win32.LPARAM) -> win32.LRESULT {
	app := owin.get_settings_from_lparam(lparam, application)
	if app == nil {owin.show_error_and_panic("Missing app!")}
	owin.set_settings(hwnd, app)
	fmt.println(#procedure)

	show_cursor(false)

	client_size := owin.get_client_size(hwnd)

	hdc := win32.GetDC(hwnd)
	defer win32.ReleaseDC(hwnd, hdc)

	dib = owin.dib_create_v5(hdc, client_size / ZOOM)
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
	owin.dib_free_section(&dib)
	owin.post_quit_message()
	return 0
}

WM_SIZE :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	app := get_app(hwnd)
	app.settings.window_size = owin.decode_lparam_as_int2(lparam)
	owin.set_window_text(hwnd, "%s %v %v", TITLE, app.settings.window_size, dib.canvas.size)
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

	owin.select_object(hdc_source, dib.hbitmap)
	client_size := owin.get_rect_size(&ps.rcPaint)
	dib_size := transmute(cv.int2)dib.canvas.size
	win32.StretchBlt(ps.hdc, 0, 0, client_size.x, client_size.y, hdc_source, 0, 0, dib_size.x, dib_size.y, win32.SRCCOPY)

	dc_pen := win32.GetStockObject(win32.DC_PEN)

	old_dc_pen := win32.SelectObject(hdc, dc_pen)
	old_pen := win32.SetDCPenColor(hdc, pen_color)

	owin.draw_grid(hdc, {0, 0}, {ZOOM, ZOOM}, transmute(owin.int2)dib.canvas.size)
	owin.draw_marker(hdc, mouse_pos)

	win32.SetDCPenColor(hdc, old_pen)
	win32.SelectObject(hdc_source, old_dc_pen)

	if icon != nil {
		win32.DrawIcon(ps.hdc, mouse_pos.x + 10, mouse_pos.y + 10, icon)
	}

	return 0
}

// Sent when a window belonging to a different application than the active window is about to be activated. The message is sent to the application whose window is being activated and to the application whose window is being deactivated.
// * wParam: Indicates whether the window is being activated or deactivated. This parameter is TRUE if the window is being activated; it is FALSE if the window is being deactivated.
// * lParam: The thread identifier. If the wParam parameter is TRUE, lParam is the identifier of the thread that owns the window being deactivated. If wParam is FALSE, lParam is the identifier of the thread that owns the window being activated.
// * Return: If an application processes this message, it should return zero.
WM_ACTIVATEAPP :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	active := wparam != 0
	fmt.println(#procedure, active, cursor_state)
	if is_active != active {
		is_active = active
		clip_cursor(hwnd, active)
	}
	return 0
}

// Sent to both the window being activated and the window being deactivated. If the windows use the same input queue, the message is sent synchronously, first to the window procedure of the top-level window being deactivated, then to the window procedure of the top-level window being activated. If the windows use different input queues, the message is sent asynchronously, so the window is activated immediately.
// * wParam: The low-order word specifies whether the window is being activated or deactivated. This parameter can be one of the following values. The high-order word specifies the minimized state of the window being activated or deactivated. A nonzero value indicates the window is minimized.
// * lParam: A handle to the window being activated or deactivated, depending on the value of the wParam parameter. If the low-order word of wParam is WA_INACTIVE, lParam is the handle to the window being activated. If the low-order word of wParam is WA_ACTIVE or WA_CLICKACTIVE, lParam is the handle to the window being deactivated. This handle can be NULL.
// * Return: If an application processes this message, it should return zero.
WM_ACTIVATE :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	activate := owin.WM_ACTIVATE_WPARAM(wparam)
	fmt.println(#procedure, activate, lparam)
	return 0
}

// wparam: A handle to the window that has lost the keyboard focus. This parameter can be NULL.
WM_FOCUS :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, focused: bool) -> win32.LRESULT {
	is_focused = focused
	fmt.println(#procedure, "hwnd=", hwnd, "wparam=", wparam, "is_focused=", is_focused)
	return 0
}

rawinput: win32.RAWINPUT = {}

put_it := 0

WM_INPUT :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	assert(win32.GET_RAWINPUT_CODE_WPARAM(wparam) == .RIM_INPUT)
	owin.get_raw_input_data(win32.HRAWINPUT(lparam), &rawinput)

	switch rawinput.header.dwType {
	case win32.RIM_TYPEMOUSE:
		app := get_app(hwnd)
		mouse_delta: owin.int2 = {rawinput.data.mouse.lLastX, rawinput.data.mouse.lLastY}
		mouse_pos += mouse_delta
		mouse_pos = linalg.clamp(mouse_pos, cv.int2_zero, app.settings.window_size - 1)
		button_flags := rawinput.data.mouse.usButtonFlags
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
		switch put_it {
		case 1:
			set_dot(mouse_pos / ZOOM, cols[selected_color])
		case 2:
			set_dot(mouse_pos / ZOOM, cols[0])
		}
		win32.RedrawWindow(hwnd, nil, nil, .RDW_INVALIDATE | .RDW_UPDATENOW)
	case win32.RIM_TYPEKEYBOARD:
		switch rawinput.data.keyboard.VKey {
		case win32.VK_ESCAPE:
			owin.close_application(hwnd)
		case win32.VK_0 ..= win32.VK_9:
			selected_color = i32(rawinput.data.keyboard.VKey - win32.VK_0)
		case:
			fmt.println("keyboard:", rawinput.data.keyboard)
		}
	case:
		fmt.println("dwType:", rawinput.header.dwType)
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
	case win32.WM_ACTIVATE:     return WM_ACTIVATE(hwnd, wparam, lparam)
	case win32.WM_SETFOCUS:		return WM_FOCUS(hwnd, wparam, true)
	case win32.WM_KILLFOCUS:	return WM_FOCUS(hwnd, wparam, false)

	case win32.WM_INPUT:		return WM_INPUT(hwnd, wparam, lparam)

	case win32.WM_CHAR:         panic("WM_CHAR")
	case win32.WM_KEYDOWN:      panic("WM_KEYDOWN")
	case win32.WM_KEYUP:        panic("WM_KEYUP")
	case win32.WM_MOUSEMOVE:    panic("WM_MOUSEMOVE")
	case win32.WM_LBUTTONDOWN:  panic("WM_LBUTTONDOWN")
	case win32.WM_RBUTTONDOWN:  panic("WM_RBUTTONDOWN")

	case:						return win32.DefWindowProcW(hwnd, msg, wparam, lparam)
	}
	// odinfmt: enable
}

main :: proc() {

	icon = win32.LoadIconW(nil, win32.wstring(win32._IDI_QUESTION))
	fmt.println("icon:", icon)

	settings := owin.create_window_settings({WIDTH, HEIGHT}, TITLE, wndproc)
	//owin.register_raw_input()
	settings.options += {.Raw_Input}
	owin.run(&settings)
}

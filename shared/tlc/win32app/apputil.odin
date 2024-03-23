// +build windows
package win32app

import "core:fmt"
import win32 "core:sys/windows"

int2 :: [2]i32

IDT_TIMER1: win32.UINT_PTR : 10001
IDT_TIMER2: win32.UINT_PTR : 10002
IDT_TIMER3: win32.UINT_PTR : 10003
IDT_TIMER4: win32.UINT_PTR : 10004

decode_lparam :: #force_inline proc "contextless" (lparam: win32.LPARAM) -> int2 {
	return {win32.GET_X_LPARAM(lparam), win32.GET_Y_LPARAM(lparam)}
}

// wtprintf :: proc(format: string, args: ..any) -> win32.wstring {
// 	str := fmt.tprintf(format, ..args)
// 	return utf8_to_wstring(str)
// }

show_messagebox :: proc(caption: string, text: string, type: UINT = win32.MB_ICONSTOP | win32.MB_OK) {
	win32.MessageBoxW(nil, utf8_to_wstring(text), utf8_to_wstring(caption), type)
}

show_messageboxf :: proc(caption: string, format: string, args: ..any) {
	show_messagebox(caption, fmt.tprintf(format, ..args))
}

show_error :: proc(msg: string, loc := #caller_location) {
	show_messageboxf("Panic", "%s\nLast error: %x\n%v\n", msg, win32.GetLastError(), loc)
}

show_error_and_panic :: proc(msg: string, loc := #caller_location) {
	show_error(msg, loc = loc)
	fmt.panicf("%s (Last error: %x)", msg, win32.GetLastError(), loc = loc)
}

get_rect_size :: #force_inline proc(rect: ^RECT) -> int2 {
	return {(rect.right - rect.left), (rect.bottom - rect.top)}
}

get_client_size :: proc(hwnd: HWND) -> int2 {
	rect: RECT
	win32.GetClientRect(hwnd, &rect)
	return get_rect_size(&rect)
}

adjust_window_size :: proc(size: int2, dwStyle, dwExStyle: u32) -> int2 {
	rect := RECT{0, 0, size.x, size.y}
	if win32.AdjustWindowRectEx(&rect, dwStyle, false, dwExStyle) {
		return get_rect_size(&rect)
	}
	return size
}

get_window_position :: proc(size: int2, center: bool) -> int2 {
	if center {
		if deviceMode: win32.DEVMODEW; win32.EnumDisplaySettingsW(nil, win32.ENUM_CURRENT_SETTINGS, &deviceMode) {
			dmsize: int2 = {i32(deviceMode.dmPelsWidth), i32(deviceMode.dmPelsHeight)} // is there an easier way to describe this?
			return (dmsize - size) / 2
		}
	}
	return {win32.CW_USEDEFAULT, win32.CW_USEDEFAULT}
}

get_instance :: proc() -> HINSTANCE {
	instance := win32.HINSTANCE(win32.GetModuleHandleW(nil))
	if (instance == nil) {
		show_error_and_panic("No instance")
	}
	return instance
}

register_window_class :: proc(instance: HINSTANCE, wndproc: win32.WNDPROC) -> win32.ATOM {

	icon: win32.HICON = win32.LoadIconW(instance, win32.MAKEINTRESOURCEW(1))
	if icon == nil {
		icon = win32.LoadIconW(nil, win32.wstring(win32._IDI_APPLICATION))
	}
	if icon == nil {
		icon = win32.LoadIconW(nil, win32.wstring(win32._IDI_QUESTION))
	}
	if (icon == nil) {
		show_error_and_panic("Missing icon")
	}

	cursor: win32.HCURSOR = win32.LoadCursorW(nil, win32.wstring(win32._IDC_ARROW))
	if (cursor == nil) {
		show_error_and_panic("Missing cursor")
	}

	wcx := win32.WNDCLASSEXW {
		cbSize        = size_of(win32.WNDCLASSEXW),
		style         = win32.CS_HREDRAW | win32.CS_VREDRAW | win32.CS_OWNDC,
		lpfnWndProc   = wndproc,
		cbClsExtra    = 0,
		cbWndExtra    = 0,
		hInstance     = instance,
		hIcon         = icon,
		hCursor       = cursor,
		hbrBackground = nil,
		lpszMenuName  = nil,
		lpszClassName = L("OdinMainClass"),
		hIconSm       = icon,
	}

	atom: win32.ATOM = win32.RegisterClassExW(&wcx)
	if atom == 0 {
		show_error_and_panic("Failed to register window class")
	}
	return atom
}

create_window :: proc(instance: win32.HINSTANCE, atom: win32.ATOM, dwStyle, dwExStyle: u32, settings: ^window_settings) -> win32.HWND {

	size := adjust_window_size(settings.window_size, dwStyle, dwExStyle)
	position := get_window_position(size, settings.center)

	hwnd: win32.HWND = win32.CreateWindowExW(
		dwExStyle,
		win32.LPCWSTR(uintptr(atom)),
		utf8_to_wstring(settings.title),
		dwStyle,
		position.x, position.y,
		size.x, size.y,
		nil, nil,
		instance,
		settings.app,
	)

	return hwnd
}

default_dwStyle :: win32.WS_OVERLAPPED | win32.WS_CAPTION | win32.WS_SYSMENU
default_dwExStyle :: win32.WS_EX_OVERLAPPEDWINDOW

window_settings :: struct {
	title:       string,
	window_size: int2,
	center:      bool,
	dwStyle:     u32,
	dwExStyle:   u32,
	wndproc:     win32.WNDPROC,
	run:         proc(this: ^window_settings) -> win32.HWND,
	app:         rawptr,
}

create_window_settings_default :: proc() -> window_settings {
	settings: window_settings = {
		title       = "Odin",
		window_size = {640, 480},
		center      = true,
		wndproc     = nil,
		dwStyle     = default_dwStyle,
		dwExStyle   = default_dwExStyle,
		run         = run,
	}
	return settings
}

create_window_settings_basic :: proc(title: string, width: i32, height: i32, wndproc: win32.WNDPROC) -> window_settings {
	settings: window_settings = {
		title       = title,
		window_size = {width, height},
		center      = true,
		wndproc     = wndproc,
		dwStyle     = default_dwStyle,
		dwExStyle   = default_dwExStyle,
		run         = run,
	}
	return settings
}

create_window_settings_app :: proc(title: string, width: i32, height: i32, wndproc: WNDPROC) -> window_settings {
	settings: window_settings = {
		title       = title,
		window_size = {width, height},
		center      = true,
		wndproc     = win32.WNDPROC(wndproc),
		dwStyle     = default_dwStyle,
		dwExStyle   = default_dwExStyle,
		run         = run,
	}
	return settings
}

create_window_settings :: proc {
	create_window_settings_default,
	create_window_settings_basic,
	create_window_settings_app,
}

register_and_create_window :: proc(settings: ^window_settings) -> win32.HWND {
	if settings.dwStyle == 0 {settings.dwStyle = default_dwStyle}
	if settings.dwExStyle == 0 {settings.dwExStyle = default_dwExStyle}
	instance := get_instance()
	assert(instance != nil)
	atom := register_window_class(instance, settings.wndproc)
	assert(atom != 0)
	hwnd := create_window(instance, atom, settings.dwStyle, settings.dwExStyle, settings)
	assert(hwnd != nil)
	return hwnd
}

create_and_show_window :: proc(instance: win32.HINSTANCE, atom: win32.ATOM, settings: ^window_settings) -> win32.HWND {
	if settings.dwStyle == 0 {settings.dwStyle = default_dwStyle}
	if settings.dwExStyle == 0 {settings.dwExStyle = default_dwExStyle}
	hwnd: win32.HWND = create_window(instance, atom, settings.dwStyle, settings.dwExStyle, settings)
	if hwnd == nil {
		show_error_and_panic("CreateWindowEx failed")
	}

	win32.ShowWindow(hwnd, win32.SW_SHOWDEFAULT)
	win32.UpdateWindow(hwnd)

	return hwnd
}

pull_messages :: proc() -> bool {
	msg: win32.MSG
	for win32.PeekMessageW(&msg, nil, 0, 0, win32.PM_REMOVE) {

		win32.TranslateMessage(&msg)
		win32.DispatchMessageW(&msg)

		if (msg.message == win32.WM_QUIT) {
			return false
		}
	}
	return true
}

loop_messages :: proc() {
	msg: win32.MSG
	for win32.GetMessageW(&msg, nil, 0, 0) {
		win32.TranslateMessage(&msg)
		win32.DispatchMessageW(&msg)
	}
}

/*run_wndproc :: proc(settings: ^window_settings, wndproc: win32.WNDPROC) -> win32.HWND {
	inst := get_instance()
	atom := register_window_class(inst, wndproc)
	hwnd := create_and_show_window(inst, atom, settings)
	loop_messages()
	return hwnd
}

run_settings :: proc(settings: ^window_settings) -> win32.HWND {
	inst := get_instance()
	atom := register_window_class(inst, settings.wndproc)
	hwnd := create_and_show_window(inst, atom, settings)
	loop_messages()
	return hwnd
}

run :: proc {
	run_settings,
	run_wndproc,
}*/

run :: proc(settings: ^window_settings) -> win32.HWND {
	inst := get_instance()
	atom := register_window_class(inst, settings.wndproc)
	hwnd := create_and_show_window(inst, atom, settings)
	loop_messages()
	return hwnd
}

// default no draw background erase
WM_ERASEBKGND_NODRAW :: #force_inline proc(hwnd: win32.HWND, wparam: win32.WPARAM/*A handle to the device context.*/) -> win32.LRESULT {
	return 1
}

RedrawWindowNow :: #force_inline proc(hwnd: HWND) -> BOOL{
	return win32.RedrawWindow(hwnd, nil, nil, .RDW_INVALIDATE | .RDW_UPDATENOW)
}

SetWindowText :: #force_inline proc(hwnd: HWND, text: string) -> BOOL{
	return win32.SetWindowTextW(hwnd, utf8_to_wstring(text))
}

set_timer :: proc(hwnd: win32.HWND, id_event: UINT_PTR, elapse: win32.UINT) -> win32.UINT_PTR {
	timer_id := win32.SetTimer(hwnd, id_event, elapse, nil)
	if timer_id == 0 {show_error_and_panic("No timer")}
	return timer_id
}

kill_timer :: proc(hwnd: win32.HWND, timer_id: ^win32.UINT_PTR) {
	if timer_id^ != 0 {
		if win32.KillTimer(hwnd, timer_id^) {
			timer_id^ = 0
		} else {
			show_messageboxf("Error", "Unable to kill timer %X", timer_id^)
		}
	}
}

package win32app

import "core:fmt"
import "core:intrinsics"
import hlm "core:math/linalg/hlsl"
import win32 "core:sys/windows"
import win32ex "shared:sys/windows"

L :: intrinsics.constant_utf16_cstring

int2 :: hlm.int2

IDT_TIMER1: win32ex.UINT_PTR : 10001
IDT_TIMER2: win32ex.UINT_PTR : 10002
IDT_TIMER3: win32ex.UINT_PTR : 10003
IDT_TIMER4: win32ex.UINT_PTR : 10004

decode_lparam :: #force_inline proc "contextless" (lparam: win32.LPARAM) -> int2 {
	return int2({win32.GET_X_LPARAM(lparam), win32.GET_Y_LPARAM(lparam)})
}

show_error_and_panic :: proc(msg: string) {
	last_error := win32.utf8_to_wstring(fmt.tprintf("%s\nLast error: %x\n", msg, win32.GetLastError()))
	win32.MessageBoxW(nil, last_error, L("Panic"), win32.MB_ICONSTOP | win32.MB_OK)
	panic(msg)
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
		icon = win32.LoadIconW(instance, win32.wstring(win32._IDI_APPLICATION))
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

	hwnd: win32.HWND = win32.CreateWindowExW(dwExStyle, win32.LPCWSTR(uintptr(atom)), win32.utf8_to_wstring(settings.title), dwStyle, position.x, position.y, size.x, size.y, nil, nil, instance, nil)

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
}

create_window_settings_default :: proc() -> window_settings {
	settings: window_settings = {
		title       = "Odin",
		window_size = {640, 480},
		center      = true,
		wndproc     = nil,
		dwStyle     = default_dwStyle,
		dwExStyle   = default_dwExStyle,
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
	}
	return settings
}

create_window_settings :: proc {
	create_window_settings_default,
	create_window_settings_basic,
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
	for result := win32.PeekMessageW(&msg, nil, 0, 0, win32.PM_REMOVE); result == win32.TRUE; result = win32.PeekMessageW(&msg, nil, 0, 0, win32.PM_REMOVE) {

		win32.TranslateMessage(&msg)
		win32.DispatchMessageW(&msg)

		if (msg.message == win32.WM_QUIT) {
			return false
		}
	}
	return true
}

main_loop :: proc(hwnd: win32.HWND) {
	msg: win32.MSG
	for result := win32.GetMessageW(&msg, hwnd, 0, 0); result == win32.TRUE; result = win32.GetMessageW(&msg, hwnd, 0, 0) {
		win32.TranslateMessage(&msg)
		win32.DispatchMessageW(&msg)
	}
}

run :: proc(settings: ^window_settings, wndproc: win32.WNDPROC) {
	inst := get_instance()
	atom := register_window_class(inst, wndproc)
	hwnd := create_and_show_window(inst, atom, settings)
	main_loop(hwnd)
}

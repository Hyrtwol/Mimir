package win32app

import			"core:fmt"
import			"core:intrinsics"
import			"core:math/linalg"
import hlm		"core:math/linalg/hlsl"
import			"core:runtime"
import			"core:strings"
import win32	"core:sys/windows"

show_error_and_panic :: proc(msg: string) {
	errormsg := win32.utf8_to_wstring(fmt.tprintf("%s\nLast error: %x\n", msg, win32.GetLastError()))
	win32.MessageBoxW(nil, errormsg, L("Panic"), win32.MB_ICONSTOP | win32.MB_OK)
	panic(msg)
}

decode_scrpos :: proc(lparam: win32.LPARAM) -> int2 {
	return int2({win32.GET_X_LPARAM(lparam), win32.GET_Y_LPARAM(lparam)})
}

get_rect_size :: proc(rect: ^win32.RECT) -> int2 {
	return {(rect.right - rect.left), (rect.bottom - rect.top)}
}

get_client_size :: proc(hWnd: win32.HWND) -> int2 {
	rect: win32.RECT
	win32.GetClientRect(hWnd, &rect)
	return get_rect_size(&rect)
}

adjust_window_size :: proc(size: int2, dwStyle, dwExStyle: u32) -> int2 {
	rect := win32.RECT{0, 0, size.x, size.y}
	if win32.AdjustWindowRectEx(&rect, dwStyle, false, dwExStyle) {
		return get_rect_size(&rect)
	}
	return size
}

CW_USEDEFAULT_INT2: int2 : {win32.CW_USEDEFAULT, win32.CW_USEDEFAULT}

get_window_position :: proc(size: int2, center: bool) -> int2 {
	if center {
		if deviceMode: win32.DEVMODEW; win32.EnumDisplaySettingsW(nil, win32.ENUM_CURRENT_SETTINGS, &deviceMode) == win32.TRUE {
			dmsize: int2 = {i32(deviceMode.dmPelsWidth), i32(deviceMode.dmPelsHeight)} // is there an easier way to describe this?
			return (dmsize - size) / 2
		}
	}
	return CW_USEDEFAULT_INT2
}

get_instance :: proc() -> win32.HINSTANCE {
	instance := win32.HINSTANCE(win32.GetModuleHandleW(nil))
	if (instance == nil) {
		show_error_and_panic("No instance")
	}
	return instance
}

register_window_class :: proc(instance: win32.HINSTANCE, wndproc: win32.WNDPROC) -> win32.ATOM {

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

create_window :: proc(instance: win32.HINSTANCE, atom: win32.ATOM, title: string, window_size: int2, center: bool) -> win32.HWND {

	dwStyle :: win32.WS_OVERLAPPED | win32.WS_CAPTION | win32.WS_SYSMENU
	dwExStyle :: win32.WS_EX_OVERLAPPEDWINDOW

	//dwStyle :: win32.WS_POPUP | win32.WS_BORDER
	//dwExStyle :: 0

	size := adjust_window_size(window_size, dwStyle, dwExStyle)
	position := get_window_position(size, center)

	hwnd: win32.HWND = win32.CreateWindowExW(
		dwExStyle,
		win32.LPCWSTR(uintptr(atom)),
		win32.utf8_to_wstring(title),
		dwStyle,
		position.x, position.y,
		size.x, size.y,
		nil,
		nil,
		instance,
		nil,
	)
	if hwnd == nil {
		show_error_and_panic("CreateWindowEx failed")
	}

	win32.ShowWindow(hwnd, win32.SW_SHOWDEFAULT)
	win32.UpdateWindow(hwnd)

	return hwnd
}

main_loop :: proc(hwnd: win32.HWND) {
	msg: win32.MSG
	for result := win32.GetMessageW(&msg, hwnd, 0, 0);
	    result == win32.TRUE;
	    result = win32.GetMessageW(&msg, hwnd, 0, 0) {
		win32.TranslateMessage(&msg)
		win32.DispatchMessageW(&msg)
	}
}

run :: proc(title: string, window_size: int2, center: bool, wndproc: win32.WNDPROC) {
	inst := get_instance()
	atom := register_window_class(inst, wndproc)
	hwnd := create_window(inst, atom, title, window_size, center)
	main_loop(hwnd)
}

package main

import          "core:fmt"
import          "core:intrinsics"
import			"core:os"
import          "core:runtime"
import win32    "core:sys/windows"
import win32app "../../shared/tlc/win32app"

L :: intrinsics.constant_utf16_cstring

TITLE 	:: "Mimir Hello"
WIDTH  	:: 320
HEIGHT 	:: WIDTH * 3 / 4
CENTER  :: true

hbrGray : win32.HBRUSH

write_hello_txt :: proc() {
	path := "hello.txt"
	fmt.printf("writing %s\n", path)
	data: []byte = {65,66,67,68} // "ABCD"
	ok := os.write_entire_file(path, data)
	fmt.printf("ok %v\n", ok)
}

WM_CREATE :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	fmt.print("WM_CREATE\n")

	hbrGray = win32.HBRUSH(win32.GetStockObject(win32.DKGRAY_BRUSH))

	clientRect: win32.RECT
	win32.GetClientRect(hwnd, &clientRect)
	fmt.printf("clientRect %d, %d, %d, %d\n", clientRect.left, clientRect.top, clientRect.right, clientRect.bottom)

	return 0
}

WM_DESTROY :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	fmt.print("WM_DESTROY\n")

	hbrGray = nil

	win32.PostQuitMessage(666) //exitcode?
	return 0
}

WM_ERASEBKGND :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	return 1 // paint should fill out the client area so no need to erase the background
}

WM_CHAR :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	//fmt.printf("WM_CHAR %4d 0x%4x 0x%4x 0x%4x\n", wparam, wparam, win32.HIWORD(u32(lparam)), win32.LOWORD(u32(lparam)))
	switch wparam {
	case '\x1b':	win32.DestroyWindow(hwnd)
	case '\t':		fmt.print("tab\n")
	case '\r':		fmt.print("return\n")
	case 'm':		win32app.PlaySoundW(L("62a.wav"), nil, win32app.SND_FILENAME);
	case 'p':		win32app.show_error_and_panic("Test Panic")
	}
	return 0
}

WM_SIZE :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	size := [2]i32{win32.GET_X_LPARAM(lparam), win32.GET_Y_LPARAM(lparam)}
	fmt.printf("WM_SIZE %v\n", size)
	return 0
}

WM_PAINT :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	ps: win32.PAINTSTRUCT
	win32.BeginPaint(hwnd, &ps) // todo check if defer can be used for EndPaint
	defer win32.EndPaint(hwnd, &ps)

	if hbrGray != nil {
		win32.FillRect(ps.hdc, &ps.rcPaint, hbrGray)
	}

	dtf : win32app.DrawTextFormat : .DT_SINGLELINE | .DT_CENTER | .DT_VCENTER
	win32app.DrawTextW(ps.hdc, L("Hello, Windows 98!"), -1, &ps.rcPaint, dtf)

	return 0
}

wndproc :: proc "system" (hwnd: win32.HWND,	msg: win32.UINT, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	context = runtime.default_context()
	switch msg {
	case win32.WM_CREATE:		return WM_CREATE(hwnd, wparam, lparam)
	case win32.WM_DESTROY:		return WM_DESTROY(hwnd, wparam, lparam)
	case win32.WM_ERASEBKGND:	return WM_ERASEBKGND(hwnd, wparam, lparam)
	case win32.WM_SIZE:			return WM_SIZE(hwnd, wparam, lparam)
	case win32.WM_PAINT:		return WM_PAINT(hwnd, wparam, lparam)
	case win32.WM_CHAR:			return WM_CHAR(hwnd, wparam, lparam)
	case:						return win32.DefWindowProcW(hwnd, msg, wparam, lparam)
	}
}

main :: proc() {

	instance := win32.HINSTANCE(win32.GetModuleHandleW(nil))
	if (instance == nil) {
		win32app.show_error_and_panic("No instance")
	}

	icon: win32.HICON = win32.LoadIconW(instance, win32.wstring(win32._IDI_APPLICATION))
	if icon == nil {
		icon = win32.LoadIconW(nil, win32.wstring(win32._IDI_QUESTION))
	}
	if (icon == nil) {
		win32app.show_error_and_panic("Missing icon")
	}

	cursor: win32.HCURSOR = win32.LoadCursorW(nil, win32.wstring(win32._IDC_ARROW))
	if (cursor == nil) {
		win32app.show_error_and_panic("Missing cursor")
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
		win32app.show_error_and_panic("Failed to register window class")
	}

	dwStyle :: win32.WS_OVERLAPPED | win32.WS_CAPTION | win32.WS_SYSMENU
	dwExStyle :: win32.WS_EX_OVERLAPPEDWINDOW

	size := [2]i32{WIDTH, HEIGHT}
	{
		// adjust size for style
		rect := win32.RECT{0, 0, size.x, size.y}
		if win32.AdjustWindowRectEx(&rect, dwStyle, false, dwExStyle) {
			size = {i32(rect.right - rect.left), i32(rect.bottom - rect.top)}
		}
	}
	fmt.printf("size %d, %d\n", size.x, size.y)

	position := [2]i32{i32(win32.CW_USEDEFAULT), i32(win32.CW_USEDEFAULT)}
	if CENTER {
		if deviceMode: win32.DEVMODEW; win32.EnumDisplaySettingsW(nil, win32.ENUM_CURRENT_SETTINGS, &deviceMode) == win32.TRUE {
			dmsize := [2]i32{i32(deviceMode.dmPelsWidth), i32(deviceMode.dmPelsHeight)} // is there an easier way to describe this?
			position = (dmsize - size) / 2
		}
	}
	fmt.printf("position %d, %d\n", position.x, position.y)

	hwnd: win32.HWND = win32.CreateWindowExW(
		dwExStyle,
		win32.LPCWSTR(uintptr(atom)),
		L(TITLE),
		dwStyle,
		position.x,
		position.y,
		size.x,
		size.y,
		nil,
		nil,
		instance,
		nil,
	)
	if hwnd == nil {
		win32app.show_error_and_panic("CreateWindowEx failed")
	}
	fmt.printf("hwnd %d\n", hwnd)

	// try to set the windows title again
	//win32.SetWindowTextW(hwnd, wtitle);
	//win32.SetWindowTextW(hwnd, win32.utf8_to_wstring("XYZ"));

	win32.ShowWindow(hwnd, win32.SW_SHOWDEFAULT)
	win32.UpdateWindow(hwnd)

	fmt.print("MainLoop\n")
	msg: win32.MSG
	for result := win32.GetMessageW(&msg, hwnd, 0, 0);
	    result == win32.TRUE;
	    result = win32.GetMessageW(&msg, hwnd, 0, 0) {
		win32.TranslateMessage(&msg)
		win32.DispatchMessageW(&msg)
	}

	fmt.print("Done!\n")
}

package main

import "core:fmt"
import "core:runtime"
import "core:strings"
import win32 "core:sys/windows"

// to learn and investigate how to interpo a dll or lib (cool that odin can import libs directly)
foreign import user32 "system:User32.lib"
//@(default_calling_convention="stdcall") // not sure if stdcall here is scoped to foreign only? moved it inline for now.
foreign user32 {

	DrawTextA :: proc "stdcall" (hDC: win32.HDC, lpchText: win32.LPCSTR, cchText: win32.c_int, lprc: win32.LPRECT, format: u32) -> win32.c_int ---
	DrawTextW :: proc "stdcall" (hDC: win32.HDC, lpchText: win32.LPCWSTR, cchText: win32.c_int, lprc: win32.LPRECT, format: u32) -> win32.c_int ---

    // had touble with lpClassName where it only show the first char so tried to use CreateWindowExA (without any luck)
    /*
	CreateWindowExA :: proc "stdcall" (
		dwExStyle: win32.DWORD,
		lpClassName: win32.LPVOID,
		//lpClassName: win32.LPVOID,
		lpWindowName: win32.LPCSTR,
		dwStyle: win32.DWORD,
		X: win32.c_int,
		Y: win32.c_int,
		nWidth: win32.c_int,
		nHeight: win32.c_int,
		hWndParent: win32.HWND,
		hMenu: win32.HMENU,
		hInstance: win32.HINSTANCE,
		lpParam: win32.LPVOID,
	) -> win32.HWND ---
	CreateWindowExW :: proc "stdcall" (
		dwExStyle: win32.DWORD,
		lpClassName: win32.LPVOID, // try with void
		lpWindowName: win32.LPCWSTR,
		dwStyle: win32.DWORD,
		X: win32.c_int,
		Y: win32.c_int,
		nWidth: win32.c_int,
		nHeight: win32.c_int,
		hWndParent: win32.HWND,
		hMenu: win32.HMENU,
		hInstance: win32.HINSTANCE,
		lpParam: win32.LPVOID,
	) -> win32.HWND ---
    */
}

TITLE 	:: "Mimir"
WIDTH  	:: 640
HEIGHT 	:: 480
CENTER  :: true;

wm_create :: proc(hWnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
    fmt.print("WM_CREATE\n")
    //_hbrGray = win32.HBRUSH(win32.GetStockObject(win32.GRAY_BRUSH))

    clientRect: win32.RECT
    win32.GetClientRect(hWnd, &clientRect)
    fmt.printf("clientRect %d, %d, %d, %d\n", clientRect.left, clientRect.top, clientRect.right, clientRect.bottom)

    hDC := win32.GetDC(hWnd);

    win32.ReleaseDC(hWnd, hDC); // todo check if defer can be used for releasing

    return 0 // win32.LRESULT(win32.FALSE) // how to cast FALSE to LRESULT ?
}

wm_destroy :: proc(hWnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT
{
    fmt.print("WM_DESTROY\n")
    win32.PostQuitMessage(666) // exitcode
    return 0
}

wm_erasebkgnd :: proc(hWnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT
{
    // paint should fill out the client area so no need to erase the background
    return 1 // win32.LRESULT(win32.TRUE) // how to cast TRUE to LRESULT ?
}

wm_char :: proc(hWnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT
{
    fmt.printf("WM_CHAR %4d 0x%8x 0x%8x\n", wparam, wparam, lparam)
    if wparam == 27 // esc
    {
        win32.DestroyWindow(hWnd);
    }
    return 0
}

wm_size :: proc(hWnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT
{
    fmt.print("WM_SIZE\n")
    return 0
}

wm_paint :: proc(hWnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT
{
    ps : win32.PAINTSTRUCT;
    hdc := win32.BeginPaint(hWnd, &ps) // todo check if defer can be used for EndPaint

    rect: win32.RECT
    win32.GetClientRect(hWnd, &rect)
    // if (_hbrGray != nil) win32.FillRect(hDC, ref rect, _hbrGray);

    DrawTextA(hdc, "Hello, Windows 98!", -1, &rect,
        //DrawTextFormat.DT_SINGLELINE | DrawTextFormat.DT_CENTER | DrawTextFormat.DT_VCENTER
        0x00000020 | 0x00000001 | 0x00000004 // todo add conts for DrawTextFormat
        )

    win32.EndPaint(hWnd, &ps)
    win32.ValidateRect(hWnd, nil)

    return 0
}

wndproc :: proc "stdcall" (hWnd: win32.HWND, msg: win32.UINT, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
    context = runtime.default_context()
    switch msg {
        case win32.WM_CREATE:     return wm_create(hWnd, wparam, lparam)
        case win32.WM_DESTROY:    return wm_destroy(hWnd, wparam, lparam)
        case win32.WM_ERASEBKGND: return wm_erasebkgnd(hWnd, wparam, lparam)
        case win32.WM_SIZE:       return wm_size(hWnd, wparam, lparam)
        case win32.WM_PAINT:      return wm_paint(hWnd, wparam, lparam)
        case win32.WM_CHAR:       return wm_char(hWnd, wparam, lparam)
        case:                     return win32.DefWindowProcA(hWnd, msg, wparam, lparam)
    }
}

main :: proc() {

    fmt.print("win32 test\n")

    className : win32.wstring = win32.utf8_to_wstring("Odin")

    instance := win32.HINSTANCE(win32.GetModuleHandleW(nil))
    fmt.printf("instance %d\n", instance)

    icon : win32.HICON = win32.LoadIconA(instance, win32.IDI_APPLICATION)
    // how do i use LoadIconW with win32.IDI_APPLICATION?
    // icon : win32.HICON = win32.LoadIconW(instance, win32.utf8_to_wstring(string(win32.IDI_APPLICATION)))
    fmt.printf("icon %d\n", icon)

    cursor : win32.HCURSOR = win32.LoadCursorA(nil, win32.IDC_ARROW)
    // how do i use LoadCursorW with win32.IDC_ARROW ?
    // cursor : win32.HCURSOR = win32.LoadCursorW(nil, win32.utf8_to_wstring(string(win32.IDC_ARROW)))
    fmt.printf("cursor %d\n", cursor)

    wndclass := win32.WNDCLASSEXW {
        cbSize = size_of(win32.WNDCLASSEXA),
        style = win32.CS_HREDRAW | win32.CS_VREDRAW | win32.CS_OWNDC,
        hInstance = instance,
        hIcon = icon,
        hIconSm = icon,
        hCursor = cursor,
        lpszClassName = className,
        lpfnWndProc = wndproc
        //hbrBackground = win32.HBRUSH(win32.GetStockObject(win32.GRAY_BRUSH))
    };

    atom : win32.ATOM = win32.RegisterClassExW(&wndclass);
    if atom == 0 {
        // todo call GetLastWin32Error
        panic("Failed to register window class")
    }
    fmt.printf("atom %d\n", atom)
    fmt.printf("lpwatom %d\n", win32.LPCWSTR(uintptr(atom)))

    dwStyle := win32.WS_OVERLAPPED | win32.WS_CAPTION | win32.WS_SYSMENU
    dwExStyle := win32.WS_EX_OVERLAPPEDWINDOW;

    size := [2]i32{WIDTH, HEIGHT}
    // adjust size for style
    rect := win32.RECT{0,0,size.x,size.y};
    if win32.AdjustWindowRectEx(&rect, dwStyle, false, dwExStyle)
    {
        size = [2]i32{i32(rect.right - rect.left), i32(rect.bottom - rect.top)}
    }
    fmt.printf("size %d, %d\n", size.x, size.y)

    position := [2]i32{i32(win32.CW_USEDEFAULT), i32(win32.CW_USEDEFAULT)}
    if CENTER
    {
        if deviceMode:win32.DEVMODEW ; win32.EnumDisplaySettingsW(nil, win32.ENUM_CURRENT_SETTINGS, &deviceMode) == win32.TRUE
        {
            dmsize := [2]i32{i32(deviceMode.dmPelsWidth), i32(deviceMode.dmPelsHeight)} // is there an easier way to describe this?
            position = (dmsize - size) / 2
        }
    }
    fmt.printf("position %d, %d\n", position.x, position.y)

    // app title
    wtitle : win32.wstring = win32.utf8_to_wstring(TITLE)
    fmt.printf("wtitle %d\n", wtitle)

    win32.MessageBoxW(nil, win32.utf8_to_wstring("Title should be " + TITLE), wtitle, win32.MB_OK)

    title1, err1 := win32.wstring_to_utf8(wtitle, 256, context.allocator)
    fmt.printf("title \"%s\"\n", title1) // is does print TITLE as expected
    assert(TITLE == title1)

    hwnd : win32.HWND = win32.CreateWindowExW(
                dwExStyle,
                win32.LPCWSTR(uintptr(atom)), // is this right? if so is there a better way to do this?
                wtitle, // the window title only shows the first char?!
                // i suspect it maps to CreateWindowExA somehow https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-createwindowexa
                dwStyle,
                position.x, position.y,
                size.x, size.y,
                nil,
                nil,
                instance,
                nil
            );
    /*
    // no luck with CreateWindowExA either
    hwnd : win32.HWND = CreateWindowExA(
            dwExStyle,
            win32.LPCWSTR(uintptr(atom)),
            title,
            dwStyle,
            position.x, position.y,
            size.x, size.y,
            nil,
            nil,
            instance,
            nil
        );
    */
    if hwnd == nil {
        // todo call GetLastWin32Error
        panic("CreateWindowEx failed")
    }
    fmt.printf("hwnd %d\n", hwnd)

    // try to set the windows title again
    //win32.SetWindowTextW(hwnd, wtitle);
    //win32.SetWindowTextW(hwnd, win32.utf8_to_wstring("XYZ")); // only shows X ?!?

    win32.ShowWindow(hwnd, win32.SW_SHOWDEFAULT)
    win32.UpdateWindow(hwnd)

    msg : win32.MSG // is there an easy way to zero out the msg struct ?
    res : win32.BOOL =  win32.TRUE
    //res : i32 = 1

    fmt.print("MainLoop\n")

    for res == win32.TRUE
    {
        // From https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-getmessagew#return-value
        // "If there is an error, the return value is -1. For example, the function fails if hWnd is an invalid window handle or lpMsg is an invalid pointer.
        // To get extended error information, call GetLastError."
        // how to handle the -1 ?
        res = win32.GetMessageW(&msg, hwnd, 0, 0)
        // if res == -1
        // {
        //     // handle the error and possibly exit
        //     //win32.MessageBoxW(nil, "User32.GetMessage returned -1", "Error", win32.MB_OK)
        //     //panic("GetMessage")
        // }
        // else
        if res == win32.TRUE
        {
            win32.TranslateMessage(&msg);
            win32.DispatchMessageW(&msg);
        }
    }
    //return msg.wParam.ToInt32();
    fmt.printf("wParam %d\n", msg.wParam)
    fmt.print("done!\n")
}

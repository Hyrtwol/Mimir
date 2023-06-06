package main

import fmt          "core:fmt"
import intrinsics   "core:intrinsics"
import math         "core:math"
import linalg       "core:math/linalg"
import hlm          "core:math/linalg/hlsl"
import noise        "core:math/noise"
import rand         "core:math/rand"
import mem          "core:mem"
import runtime      "core:runtime"
import simd         "core:simd"
import strings      "core:strings"
import win32        "core:sys/windows"
import win32app     "win32app"

L :: intrinsics.constant_utf16_cstring

TITLE 	:: "Mimir"
WIDTH  	:: 640 / 2
HEIGHT 	:: 480 / 2
CENTER  :: true

hbrGray : win32.HBRUSH

wm_create :: proc(hWnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
    fmt.print("WM_CREATE\n")

    hbrGray = win32.HBRUSH(win32.GetStockObject(win32.DKGRAY_BRUSH))

    clientRect: win32.RECT
    win32.GetClientRect(hWnd, &clientRect)
    fmt.printf("clientRect %d, %d, %d, %d\n", clientRect.left, clientRect.top, clientRect.right, clientRect.bottom)

    hDC := win32.GetDC(hWnd)
    //defer win32.ReleaseDC(hWnd, hDC)

    // todo

    win32.ReleaseDC(hWnd, hDC)
    return 0
}

wm_destroy :: proc(hWnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
    fmt.print("WM_DESTROY\n")

    hbrGray = nil

    win32.PostQuitMessage(666) // exitcode
    return 0
}

wm_erasebkgnd :: proc(hWnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
    return 1 // paint should fill out the client area so no need to erase the background
}

wm_char :: proc(hWnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
    fmt.printf("WM_CHAR %4d 0x%4x 0x%4x 0x%4x\n", wparam, wparam, win32.HIWORD(u32(lparam)), win32.LOWORD(u32(lparam)))
    switch wparam {
        case '\x1b': return win32app.MAKELRESULT(win32.DestroyWindow(hWnd))
        case '\t':   fmt.print("tab\n"); return 0
        case '\r':   fmt.print("return\n"); return 0
        case 'p':    win32app.show_error_and_panic("Test Panic"); return 0
        case:        return 0
    }
}

wm_size :: proc(hWnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
    size := [2]i32{win32.GET_X_LPARAM(lparam), win32.GET_Y_LPARAM(lparam)}
    fmt.printf("WM_SIZE %v\n", size)
    return 0
}

wm_paint :: proc(hWnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
    ps : win32.PAINTSTRUCT
    hdc := win32.BeginPaint(hWnd, &ps) // todo check if defer can be used for EndPaint

    rect: win32.RECT
    win32.GetClientRect(hWnd, &rect)

    if hbrGray != nil {
        win32.FillRect(hdc, &rect, hbrGray)
    }

    dtf :: win32app.DrawTextFormat.DT_SINGLELINE | win32app.DrawTextFormat.DT_CENTER | win32app.DrawTextFormat.DT_VCENTER
    win32app.DrawTextW(hdc, L("Hello, Windows 98!"), -1, &rect, dtf)

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
        case:                     return win32.DefWindowProcW(hWnd, msg, wparam, lparam)
    }
}

main :: proc() {

    instance := win32.HINSTANCE(win32.GetModuleHandleW(nil))
    if(instance == nil)
    {
        win32app.show_error_and_panic("No instance")
    }

    icon : win32.HICON = win32.LoadIconW(instance, win32.wstring(win32._IDI_APPLICATION))
    if icon == nil {
        icon = win32.LoadIconW(nil, win32.wstring(win32._IDI_QUESTION))
    }
    if(icon == nil)
    {
        win32app.show_error_and_panic("Missing icon")
    }

    cursor : win32.HCURSOR = win32.LoadCursorW(nil, win32.wstring(win32._IDC_ARROW))
    if(cursor == nil)
    {
        win32app.show_error_and_panic("Missing cursor")
    }

    wcx := win32.WNDCLASSEXW {
        cbSize = size_of(win32.WNDCLASSEXW),
        style = win32.CS_HREDRAW | win32.CS_VREDRAW | win32.CS_OWNDC,
        lpfnWndProc = wndproc,
        cbClsExtra = 0,
        cbWndExtra = 0,
        hInstance = instance,
        hIcon = icon,
        hCursor = cursor,
        hbrBackground = nil,
        lpszMenuName = nil,
        lpszClassName = L("OdinMainClass"),
        hIconSm = icon
    }

    atom : win32.ATOM = win32.RegisterClassExW(&wcx) // ATOM :: distinct WORD
    if atom == 0 {
        win32app.show_error_and_panic("Failed to register window class")
    }

    dwStyle := win32.WS_OVERLAPPED | win32.WS_CAPTION | win32.WS_SYSMENU
    dwExStyle := win32.WS_EX_OVERLAPPEDWINDOW

    size := win32app.adjust_window_size([2]i32{WIDTH, HEIGHT}, dwStyle, dwExStyle)
    position := win32app.get_window_position(size, CENTER);

    hwnd : win32.HWND = win32.CreateWindowExW(
        dwExStyle,
        win32.LPCWSTR(uintptr(atom)),
        L(TITLE),
        dwStyle,
        position.x, position.y,
        size.x, size.y,
        nil,
        nil,
        instance,
        nil)

    if hwnd == nil {
        win32app.show_error_and_panic("CreateWindowEx failed")
    }

    win32.ShowWindow(hwnd, win32.SW_SHOWDEFAULT)
    win32.UpdateWindow(hwnd)

    msg : win32.MSG
    for result := win32.GetMessageW(&msg, hwnd, 0, 0);
        result == win32.TRUE;
        result = win32.GetMessageW(&msg, hwnd, 0, 0) {
        win32.TranslateMessage(&msg)
        win32.DispatchMessageW(&msg)
    }
}

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
import win32app     "../../shared/tlc/win32app"

L :: intrinsics.constant_utf16_cstring

TITLE 	:: "Mimir 2"

ZOOM  	:: 8

WIDTH  	:: 640
//HEIGHT 	:: WIDTH * 3 / 4
HEIGHT 	:: WIDTH * 9 / 16
CENTER  :: true

hbrGray       : win32.HBRUSH
hbitmap       : win32.HGDIOBJ // win32.HBITMAP
hbitmap_size  : hlm.int2
hbitmap_count : i32
pvBits        : win32app.screenbuffer

fill_screen :: proc(p: win32app.screenbuffer, count: i32, col: win32app.byte4) {
    for i in 0..<count {
        p[i] = col
    }
}

fill_screen2 :: proc(p: win32app.screenbuffer, count: i32, col: win32app.byte4) {
    for i in 0..<count {
        p[i] = win32app.byte4{u8(i*17), u8(i*29), u8(i*37), 255}
    }
}

decode_scrpos :: proc(lparam: win32.LPARAM) -> hlm.int2 {
    size := hlm.int2({win32.GET_X_LPARAM(lparam), win32.GET_Y_LPARAM(lparam)})
    scrpos := size / ZOOM
    scrpos.y = (hbitmap_size.y - 1) - scrpos.y
    return scrpos
}

setdot :: proc(pos: hlm.int2, col: win32app.byte4) {
    i := pos.y * hbitmap_size.x + pos.x
    if i >= 0 && i < hbitmap_count {
        pvBits[i] =  col
    }
}

WM_CREATE :: proc(hWnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
    fmt.print("WM_CREATE\n")

    hbrGray = win32.HBRUSH(win32.GetStockObject(win32.DKGRAY_BRUSH))

    client_size := win32app.get_client_size(hWnd)
    hbitmap_size = client_size / ZOOM

    hDC := win32.GetDC(hWnd)
    // todo defer win32.ReleaseDC(hWnd, hDC)

    PelsPerMeter :: 3780
    BitPerByte :: 8
    ColorSizeInBytes :: 4

    bitmapInfo := win32.BITMAPINFO {
        bmiHeader = win32.BITMAPINFOHEADER {
            biSize = size_of(win32.BITMAPINFOHEADER),
            biWidth = hbitmap_size.x,
            biHeight = hbitmap_size.y,
            biPlanes = 1,
            biBitCount = ColorSizeInBytes * BitPerByte,
            biCompression = win32.BI_RGB,
            biSizeImage = 0,
            biXPelsPerMeter = PelsPerMeter,
            biYPelsPerMeter = PelsPerMeter,
            biClrImportant = 0,
            biClrUsed = 0
        }
    }

    hbitmap = win32.HGDIOBJ(win32.CreateDIBSection(hDC, &bitmapInfo, 0, &pvBits, nil, 0))

    if pvBits != nil {
        hbitmap_count = hbitmap_size.x * hbitmap_size.y
        //fill_screen(pvBits, hbitmap_count,win32app.BLUE)
        fill_screen(pvBits, hbitmap_count, {150, 100, 50, 255})
    }
    else {
        hbitmap_size = win32app.ZERO2;
        hbitmap_count = 0
    }

    win32.ReleaseDC(hWnd, hDC)
    return 0
}

WM_DESTROY :: proc(hWnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
    fmt.print("WM_DESTROY\n")

    if hbitmap != nil {
        win32.DeleteObject(hbitmap)
        hbitmap = nil
    }
    hbrGray = nil

    win32.PostQuitMessage(666) // exitcode
    return 0
}

WM_ERASEBKGND :: proc(hWnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
    return 1 // paint should fill out the client area so no need to erase the background
}

WM_CHAR :: proc(hWnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
    fmt.printf("WM_CHAR %4d 0x%4x 0x%4x 0x%4x\n", wparam, wparam, win32.HIWORD(u32(lparam)), win32.LOWORD(u32(lparam)))
    switch wparam {
        case '\x1b': win32.DestroyWindow(hWnd)
        case '\t':   fmt.print("tab\n")
        case '\r':   fmt.print("return\n")
        case 'p':    win32app.show_error_and_panic("Test Panic")
        case:
    }
    return 0
}

WM_SIZE :: proc(hWnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
    size := hlm.int2({win32.GET_X_LPARAM(lparam), win32.GET_Y_LPARAM(lparam)})
    fmt.printf("WM_SIZE %v %v\n", WM_SIZE, size)
    newtitle := fmt.tprintf("%s %v %v\n", TITLE, size, hbitmap_size)
    win32.SetWindowTextW(hWnd, win32.utf8_to_wstring(newtitle));
    return 0
}

WM_PAINT :: proc(hWnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
    ps : win32.PAINTSTRUCT
    hDC := win32.BeginPaint(hWnd, &ps) // todo check if defer can be used for EndPaint

    clientSize := win32app.get_client_size(hWnd)

    hDCBits := win32app.CreateCompatibleDC(hDC);
    win32.SelectObject(hDCBits, hbitmap);
    win32.StretchBlt(
         hDC, 0, 0, clientSize.x, clientSize.y, // dest
         hDCBits, 0, 0, hbitmap_size.x, hbitmap_size.y, // source
         win32.SRCCOPY)
    win32app.DeleteDC(hDCBits)

    win32.EndPaint(hWnd, &ps)
    win32.ValidateRect(hWnd, nil)

    return 0
}

WM_MOUSEMOVE :: proc(hWnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
    handle_input(hWnd, wparam, lparam)
    return 0
}

WM_LBUTTONDOWN :: proc(hWnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
    handle_input(hWnd, wparam, lparam)
    return 0
}

WM_RBUTTONDOWN :: proc(hWnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
    handle_input(hWnd, wparam, lparam)
    return 0
}

handle_input :: proc(hWnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) {
    switch wparam {
        case 1:
            pos := decode_scrpos(lparam)
            setdot(pos, win32app.RED)
            win32.InvalidateRect(hWnd, nil, false)
        case 2:
            pos := decode_scrpos(lparam)
            setdot(pos, win32app.BLUE)
            win32.InvalidateRect(hWnd, nil, false)
        case 3:
            pos := decode_scrpos(lparam)
            setdot(pos, win32app.GREEN)
            win32.InvalidateRect(hWnd, nil, false)
        case 4:
            fmt.printf("input %v %d\n", decode_scrpos(lparam), wparam)
        case:
            //fmt.printf("input %v %d\n", scrpos, wparam)
            //setdot(pos, win32app.byte4{u8(255), u8(255), u8(0), 255})
    }
}

wndproc :: proc "stdcall" (hWnd: win32.HWND, msg: win32.UINT, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
    context = runtime.default_context()
    switch msg {
        case win32.WM_CREATE:      return WM_CREATE(hWnd, wparam, lparam)
        case win32.WM_DESTROY:     return WM_DESTROY(hWnd, wparam, lparam)
        case win32.WM_ERASEBKGND:  return WM_ERASEBKGND(hWnd, wparam, lparam)
        case win32.WM_SIZE:        return WM_SIZE(hWnd, wparam, lparam)
        case win32.WM_PAINT:       return WM_PAINT(hWnd, wparam, lparam)
        case win32.WM_CHAR:        return WM_CHAR(hWnd, wparam, lparam)
        case win32.WM_MOUSEMOVE:   return WM_MOUSEMOVE(hWnd, wparam, lparam)
        case win32.WM_LBUTTONDOWN: return WM_LBUTTONDOWN(hWnd, wparam, lparam)
        case win32.WM_RBUTTONDOWN: return WM_RBUTTONDOWN(hWnd, wparam, lparam)
        case:                      return win32.DefWindowProcW(hWnd, msg, wparam, lparam)
    }
}

main :: proc() {
    win32app.run(TITLE, {WIDTH, HEIGHT}, CENTER, wndproc)
}

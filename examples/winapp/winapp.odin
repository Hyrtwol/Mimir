package main

import          "core:fmt"
import          "core:intrinsics"
import          "core:math"
import          "core:math/linalg"
import hlm      "core:math/linalg/hlsl"
import          "core:math/noise"
import          "core:math/rand"
import          "core:mem"
import          "core:runtime"
import          "core:simd"
import          "core:strings"
import win32    "core:sys/windows"
import          "core:time"
import win32app "../../shared/tlc/win32app"
import canvas   "../../shared/tlc/canvas"

L :: intrinsics.constant_utf16_cstring

TITLE 	:: "Mimir"
WIDTH  	:: 640
HEIGHT 	:: WIDTH * 9 / 16
CENTER  :: true
ZOOM  	:: 8

bitmap_handle : win32.HGDIOBJ // win32.HBITMAP
bitmap_size   : win32app.int2
bitmap_count  : i32
pvBits        : canvas.screenbuffer
pixel_size    : win32app.int2 : {ZOOM, ZOOM}

dib           : canvas.DIB

fill_screen2 :: proc(p: canvas.screenbuffer, count: i32) {
    for i in 0..<count {
        p[i] = canvas.byte4{u8(i*17), u8(i*29), u8(i*37), 255}
    }
}

decode_scrpos :: proc(lparam: win32.LPARAM) -> win32app.int2 {
    size := win32app.int2({win32.GET_X_LPARAM(lparam), win32.GET_Y_LPARAM(lparam)})
    scrpos := size / ZOOM
    scrpos.y = bitmap_size.y - 1 - scrpos.y
    return scrpos
}

setdot :: proc(pos: win32app.int2, col: canvas.byte4) {
    i := pos.y * bitmap_size.x + pos.x
    if i >= 0 && i < bitmap_count {
        pvBits[i] =  col
    }
}

WM_CREATE :: proc(hWnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
    fmt.print("WM_CREATE\n")

    client_size := win32app.get_client_size(hWnd)
    bitmap_size = client_size / ZOOM

    hDC := win32.GetDC(hWnd)
    // todo defer win32.ReleaseDC(hWnd, hDC)

    PelsPerMeter     :: 3780
    ColorSizeInBytes :: 4
    BitCount         :: ColorSizeInBytes * 8

    bitmapInfo := win32.BITMAPINFO {
        bmiHeader = win32.BITMAPINFOHEADER {
            biSize = size_of(win32.BITMAPINFOHEADER),
            biWidth = bitmap_size.x,
            biHeight = bitmap_size.y,
            biPlanes = 1,
            biBitCount = BitCount,
            biCompression = win32.BI_RGB,
            biSizeImage = 0,
            biXPelsPerMeter = PelsPerMeter,
            biYPelsPerMeter = PelsPerMeter,
            biClrImportant = 0,
            biClrUsed = 0
        }
    }

    bitmap_handle = win32.HGDIOBJ(win32.CreateDIBSection(hDC, &bitmapInfo, 0, &pvBits, nil, 0))

    if pvBits != nil {
        bitmap_count = bitmap_size.x * bitmap_size.y
        //fill_screen2(pvBits, bitmap_count)
        canvas.fill_screen(pvBits, bitmap_count, {150, 100, 50, 255})
    }
    else {
        bitmap_size = canvas.ZERO2;
        bitmap_count = 0
    }

    win32.ReleaseDC(hWnd, hDC)
    return 0
}

WM_DESTROY :: proc(hWnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
    fmt.print("WM_DESTROY\n")

    if bitmap_handle != nil {
        win32.DeleteObject(bitmap_handle)
    }
    bitmap_handle = nil
    bitmap_size = canvas.ZERO2;
    bitmap_count = 0
    pvBits = nil

    win32.PostQuitMessage(0)
    return 0
}

WM_ERASEBKGND :: proc(hWnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
    return 1
}

WM_CHAR :: proc(hWnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
    fmt.printf("WM_CHAR %4d 0x%4x 0x%4x 0x%4x\n", wparam, wparam, win32.HIWORD(u32(lparam)), win32.LOWORD(u32(lparam)))
    switch wparam {
        case '\x1b': win32.DestroyWindow(hWnd)
        case:
    }
    return 0
}

WM_SIZE :: proc(hWnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
    size := win32app.int2({win32.GET_X_LPARAM(lparam), win32.GET_Y_LPARAM(lparam)})
    fmt.printf("WM_SIZE %v %v\n", WM_SIZE, size)
    newtitle := fmt.tprintf("%s %v %v\n", TITLE, size, bitmap_size)
    win32.SetWindowTextW(hWnd, win32.utf8_to_wstring(newtitle));
    return 0
}

WM_PAINT :: proc(hWnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
    ps : win32.PAINTSTRUCT
    hDC_target := win32.BeginPaint(hWnd, &ps) // todo check if defer can be used for EndPaint

    client_size := win32app.get_client_size(hWnd)

    hDC_source := win32app.CreateCompatibleDC(hDC_target);
    win32.SelectObject(hDC_source, bitmap_handle);
    win32.StretchBlt(
        hDC_target, 0, 0, client_size.x, client_size.y,
        hDC_source, 0, 0, bitmap_size.x, bitmap_size.y,
        win32.SRCCOPY)
    win32app.DeleteDC(hDC_source)

    win32.EndPaint(hWnd, &ps)
    win32.ValidateRect(hWnd, nil)

    return 0
}

WM_MOUSEMOVE :: proc(hWnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
    return handle_input(hWnd, wparam, lparam)
}

WM_LBUTTONDOWN :: proc(hWnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
    return handle_input(hWnd, wparam, lparam)
}

WM_RBUTTONDOWN :: proc(hWnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
    return handle_input(hWnd, wparam, lparam)
}

handle_input :: proc(hWnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
    switch wparam {
        case 1:
            pos := decode_scrpos(lparam)
            setdot(pos, canvas.COLOR_RED)
            win32.InvalidateRect(hWnd, nil, false)
        case 2:
            pos := decode_scrpos(lparam)
            setdot(pos, canvas.COLOR_BLUE)
            win32.InvalidateRect(hWnd, nil, false)
        case 3:
            pos := decode_scrpos(lparam)
            setdot(pos, canvas.COLOR_GREEN)
            win32.InvalidateRect(hWnd, nil, false)
        case 4:
            fmt.printf("input %v %d\n", decode_scrpos(lparam), wparam)
        case:
            //fmt.printf("input %v %d\n", scrpos, wparam)
            //setdot(pos, canvas.byte4{u8(255), u8(255), u8(0), 255})
    }
    return 0
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

#+build windows
#+vet
package owin

import "base:intrinsics"
import win32 "core:sys/windows"
import cv "libs:tlc/canvas"

DIB :: struct {
	#subtype canvas: cv.canvas,
	hbitmap: win32.HBITMAP, // todo check if win32.HGDIOBJ is better here
}

@(private = "file")
dib_create_section_bitmap_info :: proc(dib: ^DIB, hdc: win32.HDC, pbmi: ^win32.BITMAPINFO) {
	dib.hbitmap = create_dib_section(hdc, pbmi, .DIB_RGB_COLORS, &dib.canvas.pvBits)
	if dib.hbitmap == nil || dib.canvas.pvBits == nil {
		cv.canvas_zero(&dib.canvas)
	}
}

@(private = "file")
dib_create_section_bitmap_info_header :: proc(dib: ^DIB, hdc: win32.HDC, pbmi: ^win32.BITMAPINFOHEADER) {
	dib_create_section_bitmap_info(dib, hdc, cast(^win32.BITMAPINFO)pbmi)
}

@(private = "file")
dib_create_section_bitmap_info_header_v5 :: proc(dib: ^DIB, hdc: win32.HDC, pbmi: ^win32.BITMAPV5HEADER) {
	dib_create_section_bitmap_info(dib, hdc, cast(^win32.BITMAPINFO)pbmi)
}

dib_create_section :: proc {
	dib_create_section_bitmap_info,
	dib_create_section_bitmap_info_header,
	dib_create_section_bitmap_info_header_v5,
}

dib_free_section :: proc(dib: ^DIB, loc := #caller_location) {
	if dib.hbitmap != nil {
		if !delete_object(&dib.hbitmap) {
			//fmt.panicf("Unable to delete object %v", dib.hbitmap, loc = loc)
			show_message_boxf("Error", "Unable to delete object %v", dib.hbitmap, loc)
		}
	}
	dib.hbitmap = nil
}

dib_create :: proc(hdc: win32.HDC, size: int2) -> DIB {
	bmp_header := win32.BITMAPINFOHEADER {
		biSize          = size_of(win32.BITMAPINFOHEADER),
		biWidth         = size.x,
		biHeight        = -size.y, // minus for top-down
		biPlanes        = 1,
		biBitCount      = cv.color_bit_count,
		biCompression   = win32.BI_RGB,
	}
	dib := DIB {
		canvas = {size = transmute(cv.uint2)size, pixel_count = size.x * size.y},
	}
	dib_create_section(&dib, hdc, &bmp_header)
	return dib
}

dib_create_v5 :: proc(hdc: win32.HDC, size: int2) -> DIB {
	bmp_v5_header := win32.BITMAPV5HEADER {
		bV5Size          = size_of(win32.BITMAPV5HEADER),
		bV5Width         = size.x,
		bV5Height        = -size.y, // minus for top-down
		bV5Planes        = 1,
		bV5BitCount      = cv.color_bit_count,
		bV5Compression   = win32.BI_BITFIELDS,
		bV5RedMask       = 0x000000FF,
		bV5GreenMask     = 0x0000FF00,
		bV5BlueMask      = 0x00FF0000,
		bV5AlphaMask     = 0xFF000000,
	}
	dib := DIB {
		canvas = {size = transmute(cv.uint2)size, pixel_count = size.x * size.y},
	}
	dib_create_section(&dib, hdc, &bmp_v5_header)
	return dib
}

draw_hgdiobj :: #force_inline proc "contextless" (hwnd: win32.HWND, hdc: win32.HDC, hdc_size: int2, hgdiobj: win32.HGDIOBJ, dest_size: int2) {
	hdc_source := win32.CreateCompatibleDC(hdc)
	defer win32.DeleteDC(hdc_source)
	select_object(hdc_source, hgdiobj)
	stretch_blt(hdc, hdc_size, hdc_source, dest_size)
}

draw_dib :: #force_inline proc "contextless" (hwnd: win32.HWND, hdc: win32.HDC, hdc_size: int2, dib: ^DIB) {
	draw_hgdiobj(hwnd, hdc, hdc_size, win32.HGDIOBJ(dib.hbitmap), transmute(int2)dib.canvas.size)
}

@(private = "file")
_wm_paint_hgdiobj :: proc "contextless" (hwnd: win32.HWND, hgdiobj: win32.HGDIOBJ, size: int2) -> win32.LRESULT {
	ps: win32.PAINTSTRUCT
	hdc := win32.BeginPaint(hwnd, &ps)
	if hdc == nil {return 1}
	defer win32.EndPaint(hwnd, &ps)

	client_size := get_rect_size(&ps.rcPaint)
	draw_hgdiobj(hwnd, hdc, client_size, hgdiobj, size)

	return 0
}

@(private = "file")
_wm_paint_hbitmap :: #force_inline proc "contextless" (hwnd: win32.HWND, hbitmap: win32.HBITMAP, size: int2) -> win32.LRESULT {
	return _wm_paint_hgdiobj(hwnd, win32.HGDIOBJ(hbitmap), size)
}

@(private = "file")
_wm_paint_dib :: #force_inline proc "contextless" (hwnd: win32.HWND, dib: DIB) -> win32.LRESULT {
	return _wm_paint_hbitmap(hwnd, dib.hbitmap, transmute(int2)dib.canvas.size)
}

wm_paint_dib :: proc {
	_wm_paint_hgdiobj,
	_wm_paint_hbitmap,
	_wm_paint_dib,
}

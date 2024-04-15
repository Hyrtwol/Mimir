package canvas

import "core:intrinsics"
import win32 "core:sys/windows"
import win32app "libs:tlc/win32app"

default_pels_per_meter: int2 : {3780, 3780}

DIB :: struct {
	#subtype canvas: canvas,
	hbitmap: win32.HBITMAP, // todo check if win32.HGDIOBJ is better here
}

dib_create_section_bitmap_info :: proc(dib: ^DIB, hdc: win32.HDC, pbmi: ^win32.BITMAPINFO) {
	dib.hbitmap = win32.CreateDIBSection(hdc, pbmi, win32.DIB_RGB_COLORS, &dib.canvas.pvBits, nil, 0)
	if dib.hbitmap == nil || dib.canvas.pvBits == nil {
		canvas_zero(&dib.canvas)
	}
}

dib_create_section_bitmap_info_header :: proc(dib: ^DIB, hdc: win32.HDC, pbmi: ^win32.BITMAPINFOHEADER) {
	dib_create_section_bitmap_info(dib, hdc, cast(^win32.BITMAPINFO)pbmi)
}

dib_create_section_bitmap_info_header_v5 :: proc(dib: ^DIB, hdc: win32.HDC, pbmi: ^win32.BITMAPV5HEADER) {
	dib_create_section_bitmap_info(dib, hdc, cast(^win32.BITMAPINFO)pbmi)
}

dib_create_section :: proc {
	dib_create_section_bitmap_info,
	dib_create_section_bitmap_info_header,
	dib_create_section_bitmap_info_header_v5,
}

dib_free_section :: proc(dib: ^DIB) {
	if dib.hbitmap != nil {
		win32.DeleteObject(win32.HGDIOBJ(dib.hbitmap))
	}
	dib.hbitmap = nil
	canvas_zero(&dib.canvas)
}

dib_create :: proc(hdc: win32.HDC, size: int2, pels_per_meter: int2 = default_pels_per_meter) -> DIB {
	bmp_header := win32.BITMAPINFOHEADER {
		biSize          = size_of(win32.BITMAPINFOHEADER),
		biWidth         = size.x,
		biHeight        = -size.y, // minus for top-down
		biPlanes        = 1,
		biBitCount      = color_bit_count,
		biCompression   = win32.BI_RGB,
		biSizeImage     = 0,
		biXPelsPerMeter = pels_per_meter.x,
		biYPelsPerMeter = pels_per_meter.y,
		biClrImportant  = 0,
		biClrUsed       = 0,
	}
	dib := DIB {
		canvas = {size = transmute(uint2)size, pixel_count = size.x * size.y},
	}
	dib_create_section(&dib, hdc, &bmp_header)
	return dib
}

dib_create_v5 :: proc(hdc: win32.HDC, size: int2, pels_per_meter: int2 = default_pels_per_meter) -> DIB {
	bmp_v5_header := win32.BITMAPV5HEADER {
		bV5Size          = size_of(win32.BITMAPV5HEADER),
		bV5Width         = size.x,
		bV5Height        = -size.y, // minus for top-down
		bV5Planes        = 1,
		bV5BitCount      = color_bit_count,
		bV5Compression   = win32.BI_BITFIELDS,
		bV5XPelsPerMeter = pels_per_meter.x,
		bV5YPelsPerMeter = pels_per_meter.y,
		bV5RedMask       = 0x000000FF,
		bV5GreenMask     = 0x0000FF00,
		bV5BlueMask      = 0x00FF0000,
		bV5AlphaMask     = 0xFF000000,
	}
	dib := DIB {
		canvas = {size = transmute(uint2)size, pixel_count = size.x * size.y},
	}
	dib_create_section(&dib, hdc, &bmp_v5_header)
	return dib
}

dib_clear :: proc(dib: ^DIB, col: byte4) {
	canvas_clear(&dib.canvas, col)
}

dib_set_dot :: proc(dib: ^DIB, pos: int2, col: byte4) {
	canvas_set_dot(&dib.canvas, pos, col)
}

@(private)
wm_paint_hgdiobj :: proc "contextless" (hwnd: win32.HWND, hgdiobj: win32.HGDIOBJ, size: int2) -> win32.LRESULT {
	ps: win32.PAINTSTRUCT
	hdc := win32.BeginPaint(hwnd, &ps)
	if hdc == nil {return 1}
	defer win32.EndPaint(hwnd, &ps)

	hdc_source := win32.CreateCompatibleDC(ps.hdc)
	if hdc_source == nil {return 2}
	defer win32.DeleteDC(hdc_source)

	win32.SelectObject(hdc_source, hgdiobj)
	client_size := win32app.get_rect_size(&ps.rcPaint)
	ok := win32.StretchBlt(ps.hdc, 0, 0, client_size.x, client_size.y, hdc_source, 0, 0, size.x, size.y, win32.SRCCOPY)

	//old_obj := win32.SelectObject(hdc_source, old_obj)

	return ok ? 0 : 3
}

@(private)
wm_paint_hbitmap :: #force_inline proc "contextless" (hwnd: win32.HWND, hbitmap: win32.HBITMAP, size: int2) -> win32.LRESULT {
	return wm_paint_hgdiobj(hwnd, win32.HGDIOBJ(hbitmap), size)
}

wm_paint_dib :: proc {
	wm_paint_hgdiobj,
	wm_paint_hbitmap,
}

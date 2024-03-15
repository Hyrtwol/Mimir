package canvas

//import "core:fmt"
import "core:intrinsics"
//import "core:runtime"
//import "core:strings"
import win32 "core:sys/windows"
import win32app "shared:tlc/win32app"

ColorSizeInBytes :: 4
BitCount :: ColorSizeInBytes * 8

DIB :: struct {
	hbitmap:     win32.HBITMAP, // todo check if win32.HGDIOBJ is better here
	pvBits:      screen_buffer,
	size:        int2,
	pixel_count: i32,
}

dib_create_section :: proc(dib: ^DIB, hdc: win32.HDC, pbmi: ^win32.BITMAPINFO) {
	dib.hbitmap = win32.CreateDIBSection(hdc, pbmi, win32.DIB_RGB_COLORS, &dib.pvBits, nil, 0)
	if dib.pvBits == nil {
		dib.size = {0, 0}
		dib.pixel_count = 0
	}
}

dib_free_section :: proc(dib: ^DIB) {
	if dib.hbitmap != nil {
		win32.DeleteObject(win32.HGDIOBJ(dib.hbitmap))
	}
	dib.hbitmap = nil
	dib.pvBits = nil
	dib.size = {0, 0}
	dib.pixel_count = 0
}

dib_create :: proc(hdc: win32.HDC, size: int2) -> DIB {
	PelsPerMeter :: 3780
	bmi_header := win32.BITMAPINFOHEADER {
		biSize          = size_of(win32.BITMAPINFOHEADER),
		biWidth         = size.x,
		biHeight        = size.y,
		biPlanes        = 1,
		biBitCount      = BitCount,
		biCompression   = win32.BI_RGB,
		biSizeImage     = 0,
		biXPelsPerMeter = PelsPerMeter,
		biYPelsPerMeter = PelsPerMeter,
		biClrImportant  = 0,
		biClrUsed       = 0,
	}
	dib := DIB {
		size        = size,
		pixel_count = size.x * size.y,
	}
	dib_create_section(&dib, hdc, cast(^win32.BITMAPINFO)&bmi_header)
	return dib
}

dib_create_v5 :: proc(hdc: win32.HDC, size: int2) -> DIB {
	bmiV5Header := win32.BITMAPV5HEADER {
		bV5Size        = size_of(win32.BITMAPV5HEADER),
		bV5Width       = size.x,
		bV5Height      = -size.y, // minus for top-down
		bV5Planes      = 1,
		bV5BitCount    = BitCount,
		bV5Compression = win32.BI_BITFIELDS,
		bV5RedMask     = 0x000000ff,
		bV5GreenMask   = 0x0000ff00,
		bV5BlueMask    = 0x00ff0000,
		bV5AlphaMask   = 0xff000000,
	}
	dib := DIB {
		size        = size,
		pixel_count = size.x * size.y,
	}
	dib_create_section(&dib, hdc, cast(^win32.BITMAPINFO)&bmiV5Header)
	return dib
}

dib_clear :: proc(dib: ^DIB, col: byte4) {
	fill_screen(dib.pvBits, dib.pixel_count, col)
}

dib_setdot :: proc(dib: ^DIB, pos: int2, col: byte4) {
	i := pos.y * dib.size.x + pos.x
	if i >= 0 && i < dib.pixel_count {
		dib.pvBits[i] = col
	}
}

/*dib_paint :: proc(dib: ^DIB, hwnd: win32.HWND)-> win32.LRESULT {
	ps: win32.PAINTSTRUCT
	win32.BeginPaint(hwnd, &ps)
	defer win32.EndPaint(hwnd, &ps)

	hdc_source := win32.CreateCompatibleDC(ps.hdc)
	defer win32.DeleteDC(hdc_source)

	win32.SelectObject(hdc_source, win32.HGDIOBJ(dib.hbitmap))
	client_size := win32app.get_rect_size(&ps.rcPaint)
	win32.StretchBlt(ps.hdc, 0, 0, client_size.x, client_size.y, hdc_source, 0, 0, dib.size.x, dib.size.y, win32.SRCCOPY)

	return 0
}*/

@(private)
wm_paint_hgdiobj :: proc(hwnd: win32.HWND, hgdiobj: win32.HGDIOBJ, size: int2)-> win32.LRESULT {
	ps: win32.PAINTSTRUCT
	win32.BeginPaint(hwnd, &ps)
	defer win32.EndPaint(hwnd, &ps)

	hdc_source := win32.CreateCompatibleDC(ps.hdc)
	defer win32.DeleteDC(hdc_source)

	win32.SelectObject(hdc_source, hgdiobj)
	client_size := win32app.get_rect_size(&ps.rcPaint)
	win32.StretchBlt(ps.hdc, 0, 0, client_size.x, client_size.y, hdc_source, 0, 0, size.x, size.y, win32.SRCCOPY)

	return 0
}

@(private)
wm_paint_hbitmap :: #force_inline proc(hwnd: win32.HWND, hbitmap: win32.HBITMAP, size: int2)-> win32.LRESULT {
	return wm_paint_hgdiobj(hwnd, win32.HGDIOBJ(hbitmap), size)
}

wm_paint_dib :: proc {
	wm_paint_hgdiobj,
	wm_paint_hbitmap,
}

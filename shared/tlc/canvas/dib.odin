package canvas

import          "core:fmt"
import          "core:intrinsics"
import          "core:math/linalg"
import hlm      "core:math/linalg/hlsl"
import          "core:runtime"
import          "core:strings"
import win32    "core:sys/windows"
import win32ex  "shared:sys/windows"

ColorSizeInBytes :: 4
BitCount         :: ColorSizeInBytes * 8

DIB :: struct {
	hbitmap:     win32.HBITMAP, // todo check if win32.HGDIOBJ is better here
	pvBits:      screen_buffer,
	size:        int2,
	pixel_count: i32,
}

dib_create_section :: proc(dib: ^DIB, hdc: win32.HDC, pbmi: ^win32.BITMAPINFO) {
	dib.hbitmap = win32.CreateDIBSection(hdc, pbmi, win32.DIB_RGB_COLORS, &dib.pvBits, nil, 0)
	if dib.pvBits == nil {
		dib.size = ZERO2
		dib.pixel_count = 0
	}
}

dib_free_section :: proc(dib: ^DIB) {
	if dib.hbitmap != nil {
		win32.DeleteObject(win32.HGDIOBJ(dib.hbitmap))
	}
	dib.hbitmap = nil
	dib.pvBits = nil
	dib.size = ZERO2
	dib.pixel_count = 0
}

dib_create :: proc(hdc: win32.HDC, size: int2) -> DIB {
	PelsPerMeter :: 3780
	bmiHeader := win32.BITMAPINFOHEADER {
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
	dib_create_section(&dib, hdc, cast(^win32.BITMAPINFO)&bmiHeader)
	return dib
}

dib_create_v5 :: proc(hdc: win32.HDC, size: int2) -> DIB {
	bmiV5Header := win32ex.BITMAPV5HEADER {
		bV5Size        = size_of(win32ex.BITMAPV5HEADER),
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

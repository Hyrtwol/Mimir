package test_misc

import "core:image/pcx"
import "core:os"

@(test)
load_pcx :: proc(t: ^testing.T) {

	expect_size(t, pcx.PCXHeader, 128)
	expect_size(t, pcx.PCXColor, 3)
	expect_size(t, pcx.PCXPalette, 768)
	expect_size(t, pcx.PCX, 40)

	path := "C:\\dev\\odin\\Odin\\tests\\core\\assets\\PCX\\bill.pcx"

	buffer := os.read_entire_file(path, context.temp_allocator) or_else panic("os.read_entire_file_from_filename")

	expect_value(t, len(buffer), 1393)

	header := (^pcx.PCXHeader)(&buffer[0])
	// fmt.printfln("header: %#v", header)
	expect_value(t, header.id, pcx.PCX_MAGIC)
	expect_value(t, header.version, 5)
	expect_value(t, header.encoding, pcx.PCX_Encoding.RLE)
	expect_value(t, header.bits_per_px, 8)
	expect_value(t, header.min, [2]i16{0, 0})
	expect_value(t, header.max, [2]i16{63, 63})
	expect_value(t, header.res, [2]i16{72, 72})
	expect_value(t, header.planes, 1)
	expect_value(t, header.bytes_per_line, 64)
	expect_value(t, header.palette_type, 1)
	expect_value(t, header.screen_size, [2]i16{0, 0})
	pal := [16]pcx.PCXColor{{0, 0, 0}, {0, 0, 0}, {0, 0, 0}, {0, 0, 0}, {0, 0, 0}, {0, 0, 0}, {0, 0, 0}, {0, 0, 0}, {0, 0, 0}, {0, 0, 0}, {255, 115, 0}, {253, 227, 187}, {240, 214, 174}, {60, 113, 254}, {255, 255, 255}, {0, 0, 0}}
	expect_value(t, header.pal, pal)

	//fmt.println("pal:", header.pal)

	// data := buffer[128:]

	dim := ([2]int)(header.max - header.min + 1)
	expect_value(t, dim, [2]int{64, 64})
	bpp := int(8 / header.bits_per_px)
	expect_value(t, bpp, 1)
	pitch := int(header.bytes_per_line) * int(header.planes) * bpp
	expect_value(t, pitch, 64)
	size := dim.x * dim.y * bpp
	expect_value(t, size, 4096)

	palofs := len(buffer) - size_of(pcx.PCXPalette) - 1
	expect_value(t, palofs, 624)
	expect_value(t, buffer[palofs], pcx.PAL_MAGIC)
	palette := (^pcx.PCXPalette)(&buffer[palofs + 1])
	//fmt.println("palette", palette)
	expect_value(t, len(palette^), 256)
}

package amstrad

import "core:math/rand"

int2			:: [2]i32
color			:: [4]u8
color_bits		:: 1
palette_count	:: 16 // 1 << color_bits
color_palette	:: [palette_count]color

SCREEN_WIDTH  	:: 640
SCREEN_HEIGHT 	:: 200
screen_pixel_count :: SCREEN_WIDTH * SCREEN_HEIGHT
screen_byte_count :: screen_pixel_count * color_bits / 8

screen_buffer	:: [^]u8

/*
#define MODE_1_P0(c) (((c & 2) >> 1) << 3) | ((c & 1) << 7)
#define MODE_1_P1(c) (((c & 2) >> 1) << 2) | ((c & 1) << 6)
#define MODE_1_P2(c) (((c & 2) >> 1) << 1) | ((c & 1) << 5)
#define MODE_1_P3(c) (((c & 2) >> 1) << 0) | ((c & 1) << 4)

#define MODE_0_P0(c) ((c & 8) >> 2) | ((c & 4) << 3) | ((c & 2) << 2) | ((c & 1) << 7)
#define MODE_0_P1(c) ((c & 8) >> 3) | ((c & 4) << 2) | ((c & 2) << 1) | ((c & 1) << 6)
*/

MODE_1_P0 :: #force_inline proc "contextless" (c: u8) -> u8 {return (((c & 2) >> 1) << 3) | ((c & 1) << 7)}
MODE_1_P1 :: #force_inline proc "contextless" (c: u8) -> u8 {return (((c & 2) >> 1) << 2) | ((c & 1) << 6)}
MODE_1_P2 :: #force_inline proc "contextless" (c: u8) -> u8 {return (((c & 2) >> 1) << 1) | ((c & 1) << 5)}
MODE_1_P3 :: #force_inline proc "contextless" (c: u8) -> u8 {return (((c & 2) >> 1) << 0) | ((c & 1) << 4)}

MODE_0_P0 :: #force_inline proc "contextless" (c: u8) -> u8 {return ((c & 8) >> 2) | ((c & 4) << 3) | ((c & 2) << 2) | ((c & 1) << 7)}
MODE_0_P1 :: #force_inline proc "contextless" (c: u8) -> u8 {return ((c & 8) >> 3) | ((c & 4) << 2) | ((c & 2) << 1) | ((c & 1) << 6)}

//MODE_1_PS :: #force_inline proc "contextless" (c: u8) -> u8 {return	(((c & 2) >> 1) << 3) | ((c & 1) << 7)}

/*
+-----------+---------------------------------------+-----------------------------------------------------------------------------------+
|           |           Byte/Pixel structure        |                                                                                   |
|-----------+----+----+----+----+----+----+----+----+-------------------------------+---------------------------------------------------|
| VM (Mode) | 7  | 6  | 5  | 4  | 3  | 2  | 1  | 0  | On screen display             | Details                                           |
|-----------+----+----+----+----+----+----+----+----+---------------+---------------+---------------------------------------------------|
| %00 (0)   | A0 | B0 | A2 | B2 | A1 | B1 | A3 | B3 | A             | B             | 4bits/pixels (16 colors), 2 pixels/byte (160×200) |
|-----------+----+----+----+----+----+----+----+----+-------+-------+-------+-------+---------------------------------------------------|
| %01 (1)   | A0 | B0 | C0 | D0 | A1 | B1 | C1 | D1 | A     | B     | C     | D     | 2bits/pixels (4 colors), 4 pixels/byte (320×200)  |
|-----------+----+----+----+----+----+----+----+----+---+---+---+---+---+---+---+---+---------------------------------------------------|
| %10 (2)   | A  | B  | C  | D  | E  | F  | G  | H  | A | B | C | D | E | F | G | H | 1bit/pixel (2 colors), 8 pixels/byte (640×200)    |
+-----------+----+----+----+----+----+----+----+----+---+---+---+---+---+---+---+---+---------------------------------------------------+

M0: byte -> byte (4 bpp)
M1: byte -> word (4 bpp)
M2: byte -> byte (1 bpp)

Overscan modes (192x272, 384x272, 768x272),

*/

screen_sizes_mode : [3][2]i32 : {
	{160,200},
	{320,200},
	{640,200},
}
screen_sizes_overscan : [3][2]i32 : {
	{192,272},
	{384,272},
	{768,272},
}

screen_size_mode :: screen_sizes_mode[2]
screen_size_overscan :: screen_sizes_overscan[2]

screen_size :: struct {
	size: int2,
	bpp:  i32,
}
screen_sizes: [3]screen_size : {{size = {160, 200}, bpp = 4}, {size = {320, 200}, bpp = 4}, {size = {640, 200}, bpp = 4}}


update_screen_1 :: proc(app: papp) {
	pvBits := app.pvBits
	if pvBits != nil {
		for i in 0 ..< screen_byte_count {
			//pvBits[i] = u8(i & 255)
			pvBits[i] = u8(rand.int31_max(255, &rng))
		}
	}
}

cursor_x, cursor_y: i32 = 0, 0
ci: u8 = 0

put_char :: proc(pvBits: screen_buffer, char: u8) {

	if char == 13 {
		cursor_x = 80
	} else {

		ch := i32(char) * 8
		sy := cursor_x + cursor_y * (80 * 8)
		for i in 0 ..< 8 {
			pvBits[sy] = amstrad_font[ch]
			sy += 80
			ch += 1
		}

		cursor_x += 1
	}
	if cursor_x >= 80 {
		cursor_x = 0
		cursor_y += 1
		if cursor_y >= 25 {
			cursor_y = 0
		}
	}
}

update_screen_2 :: proc(app: papp) {
	//fnt := amstrad_font
	pvBits := app.pvBits
	if pvBits == nil {return}

	for _ in 0 ..< 60 {
		ch := u8(rand.int31_max(256, &rng))
		put_char(pvBits, ch)
	}
}

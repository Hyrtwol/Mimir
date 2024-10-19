package canvas

import "core:math"

// odinfmt: disable

// Color Palette

COLOR_BLACK     : byte4 : { 0x00, 0x00, 0x00, 0xFF }
COLOR_RED       : byte4 : { 0x00, 0x00, 0xFF, 0xFF }
COLOR_GREEN     : byte4 : { 0x00, 0xFF, 0x00, 0xFF }
COLOR_CYAN		: byte4 : { 0x00, 0xFF, 0xFF, 0xFF }
COLOR_BLUE      : byte4 : { 0xFF, 0x00, 0x00, 0xFF }
COLOR_YELLOW	: byte4 : { 0xFF, 0xFF, 0x00, 0xFF }
COLOR_MAGENTA	: byte4 : { 0xFF, 0x00, 0xFF, 0xFF }
COLOR_WHITE     : byte4 : { 0xFF, 0xFF, 0xFF, 0xFF }

COLORS:= [8]byte4 {
	COLOR_BLACK,
	COLOR_RED,
	COLOR_GREEN,
	COLOR_CYAN,
	COLOR_BLUE,
	COLOR_YELLOW,
	COLOR_MAGENTA,
	COLOR_WHITE,
}

COLOR :: enum u8 {
	BLACK,
	RED,
	GREEN,
	CYAN,
	BLUE,
	YELLOW,
	MAGENTA,
	WHITE,
}

// Windows 95 Palette

W95_BLACK       : byte4 : { 0x00, 0x00, 0x00, 0xFF }
W95_MAROON      : byte4 : { 0x80, 0x00, 0x00, 0xFF }
W95_GREEN       : byte4 : { 0x00, 0x80, 0x00, 0xFF }
W95_OLIVE       : byte4 : { 0x80, 0x80, 0x00, 0xFF }
W95_NAVY        : byte4 : { 0x00, 0x00, 0x80, 0xFF }
W95_PURPLE      : byte4 : { 0x80, 0x00, 0x80, 0xFF }
W95_TEAL        : byte4 : { 0x00, 0x80, 0x80, 0xFF }
W95_SILVER      : byte4 : { 0xC0, 0xC0, 0xC0, 0xFF }
W95_GRAY        : byte4 : { 0x80, 0x80, 0x80, 0xFF }
W95_RED         : byte4 : { 0xFF, 0x00, 0x00, 0xFF }
W95_LIME        : byte4 : { 0x00, 0xFF, 0x00, 0xFF }
W95_YELLOW      : byte4 : { 0xFF, 0xFF, 0x00, 0xFF }
W95_BLUE        : byte4 : { 0x00, 0x00, 0xFF, 0xFF }
W95_FUCHSIA     : byte4 : { 0xFF, 0x00, 0xFF, 0xFF }
W95_AQUA        : byte4 : { 0x00, 0xFF, 0xFF, 0xFF }
W95_WHITE       : byte4 : { 0xFF, 0xFF, 0xFF, 0xFF }

W95_COLORS:= [16]byte4 {
	W95_BLACK,
	W95_MAROON,
	W95_GREEN,
	W95_OLIVE,
	W95_NAVY,
	W95_PURPLE,
	W95_TEAL,
	W95_SILVER,
	W95_GRAY,
	W95_RED,
	W95_LIME,
	W95_YELLOW,
	W95_BLUE,
	W95_FUCHSIA,
	W95_AQUA,
	W95_WHITE,
}

W95_COLOR :: enum u8 {
	BLACK,
	MAROON,
	GREEN,
	OLIVE,
	NAVY,
	PURPLE,
	TEAL,
	SILVER,
	GRAY,
	RED,
	LIME,
	YELLOW,
	BLUE,
	FUCHSIA,
	AQUA,
	WHITE,
}

// C64 Palette

C64_BLACK       : byte4 : { 0x00, 0x00, 0x00, 0xFF }
C64_WHITE       : byte4 : { 0xFF, 0xFF, 0xFF, 0xFF }
C64_RED         : byte4 : { 0x68, 0x37, 0x2B, 0xFF }
C64_CYAN	    : byte4 : { 0x70, 0xA4, 0xB2, 0xFF }
C64_PURPLE      : byte4 : { 0x6F, 0x3D, 0x86, 0xFF }
C64_GREEN       : byte4 : { 0x58, 0x8D, 0x43, 0xFF }
C64_BLUE	    : byte4 : { 0x35, 0x28, 0x79, 0xFF }
C64_YELLOW      : byte4 : { 0xB8, 0xC7, 0x6F, 0xFF }
C64_ORANGE      : byte4 : { 0x6F, 0x4F, 0x25, 0xFF }
C64_BROWN       : byte4 : { 0x43, 0x39, 0x00, 0xFF }
C64_LIGHT_RED	: byte4 : { 0x9A, 0x67, 0x59, 0xFF }
C64_DARK_GREY   : byte4 : { 0x44, 0x44, 0x44, 0xFF }
C64_GREY	    : byte4 : { 0x6C, 0x6C, 0x6C, 0xFF }
C64_LIGHT_GREEN : byte4 : { 0x9A, 0xD2, 0x84, 0xFF }
C64_LIGHT_BLUE  : byte4 : { 0x6C, 0x5E, 0xB5, 0xFF }
C64_LIGHT_GREY	: byte4 : { 0x95, 0x95, 0x95, 0xFF }

C64_COLORS:= [16]byte4 {
	C64_BLACK,
	C64_WHITE,
	C64_RED,
	C64_CYAN,
	C64_PURPLE,
	C64_GREEN,
	C64_BLUE,
	C64_YELLOW,
	C64_ORANGE,
	C64_BROWN,
	C64_LIGHT_RED,
	C64_DARK_GREY,
	C64_GREY,
	C64_LIGHT_GREEN,
	C64_LIGHT_BLUE,
	C64_LIGHT_GREY,
}

C64_COLOR :: enum u8 {
	BLACK,
	WHITE,
	RED,
	CYAN,
	PURPLE,
	GREEN,
	BLUE,
	YELLOW,
	ORANGE,
	BROWN,
	LIGHT_RED,
	DARK_GREY,
	GREY,
	LIGHT_GREEN,
	LIGHT_BLUE,
	LIGHT_GREY,
}

// Amstrad Palette

// https://www.cpcwiki.eu/index.php/Video_modes#Colours_and_Palettes

/*
Firmware Number	Hardware Number	Color Name	R %	G %	B %	Hexadecimal	RGB value

0	54h				Black			0	0	0		#000000		  0/  0/  0
1	44h (or 50h)	Blue			0	0	50		#000080		  0/  0/128
2	55h				Bright Blue		0	0	100		#0000FF		  0/  0/255
3	5Ch				Red				50	0	0		#800000		128/  0/  0
4	58h				Magenta			50	0	50		#800080		128/  0/128
5	5Dh				Mauve			50	0	100		#8000FF		128/  0/255
6	4Ch				Bright Red		100	0	0		#FF0000		255/  0/  0
7	45h (or 48h)	Purple			100	0	50		#ff0080		255/  0/128
8	4Dh				Bright Magenta	100	0	100		#FF00FF		255/  0/255
9	56h				Green			0	50	0		#008000		  0/128/  0
10	46h				Cyan			0	50	50		#008080		  0/128/128
11	57h				Sky Blue		0	50	100		#0080FF		  0/128/255
12	5Eh				Yellow			50	50	0		#808000		128/128/  0
13	40h (or 41h)	White			50	50	50		#808080		128/128/128
14	5Fh				Pastel Blue		50	50	100		#8080FF		128/128/255
15	4Eh				Orange			100	50	0		#FF8000		255/128/  0
16	47h				Pink			100	50	50		#FF8080		255/128/128
17	4Fh				Pastel Magenta	100	50	100		#FF80FF		255/128/255
18	52h				Bright Green	0	100	0		#00FF00		  0/255/  0
19	42h (or 51h)	Sea Green		0	100	50		#00FF80		  0/255/128
20	53h				Bright Cyan		0	100	100		#00FFFF		  0/255/255
21	5Ah				Lime			50	100	0		#80FF00		128/255/  0
22	59h				Pastel Green	50	100	50		#80FF80		128/255/128
23	5Bh				Pastel Cyan		50	100	100		#80FFFF		128/255/255
24	4Ah				Bright Yellow	100	100	0		#FFFF00		255/255/  0
25	43h (or 49h)	Pastel Yellow	100	100	50		#FFFF80		255/255/128
26	4Bh				Bright White	100	100	100		#FFFFFF		255/255/255
*/

AMSTRAD_BLACK			: byte4 : { 0x00, 0x00, 0x00, 0xFF }
AMSTRAD_BLUE			: byte4 : { 0x00, 0x00, 0x80, 0xFF }
AMSTRAD_BRIGHT_BLUE		: byte4 : { 0x00, 0x00, 0xFF, 0xFF }
AMSTRAD_RED				: byte4 : { 0x80, 0x00, 0x00, 0xFF }
AMSTRAD_MAGENTA			: byte4 : { 0x80, 0x00, 0x80, 0xFF }
AMSTRAD_MAUVE			: byte4 : { 0x80, 0x00, 0xFF, 0xFF }
AMSTRAD_BRIGHT_RED		: byte4 : { 0xFF, 0x00, 0x00, 0xFF }
AMSTRAD_PURPLE			: byte4 : { 0xff, 0x00, 0x80, 0xFF }
AMSTRAD_BRIGHT_MAGENTA	: byte4 : { 0xFF, 0x00, 0xFF, 0xFF }
AMSTRAD_GREEN			: byte4 : { 0x00, 0x80, 0x00, 0xFF }
AMSTRAD_CYAN			: byte4 : { 0x00, 0x80, 0x80, 0xFF }
AMSTRAD_SKY_BLUE		: byte4 : { 0x00, 0x80, 0xFF, 0xFF }
AMSTRAD_YELLOW			: byte4 : { 0x80, 0x80, 0x00, 0xFF }
AMSTRAD_WHITE			: byte4 : { 0x80, 0x80, 0x80, 0xFF }
AMSTRAD_PASTEL_BLUE		: byte4 : { 0x80, 0x80, 0xFF, 0xFF }
AMSTRAD_ORANGE			: byte4 : { 0xFF, 0x80, 0x00, 0xFF }
AMSTRAD_PINK			: byte4 : { 0xFF, 0x80, 0x80, 0xFF }
AMSTRAD_PASTEL_MAGENTA	: byte4 : { 0xFF, 0x80, 0xFF, 0xFF }
AMSTRAD_BRIGHT_GREEN	: byte4 : { 0x00, 0xFF, 0x00, 0xFF }
AMSTRAD_SEA_GREEN		: byte4 : { 0x00, 0xFF, 0x80, 0xFF }
AMSTRAD_BRIGHT_CYAN		: byte4 : { 0x00, 0xFF, 0xFF, 0xFF }
AMSTRAD_LIME			: byte4 : { 0x80, 0xFF, 0x00, 0xFF }
AMSTRAD_PASTEL_GREEN	: byte4 : { 0x80, 0xFF, 0x80, 0xFF }
AMSTRAD_PASTEL_CYAN		: byte4 : { 0x80, 0xFF, 0xFF, 0xFF }
AMSTRAD_BRIGHT_YELLOW	: byte4 : { 0xFF, 0xFF, 0x00, 0xFF }
AMSTRAD_PASTEL_YELLOW	: byte4 : { 0xFF, 0xFF, 0x80, 0xFF }
AMSTRAD_BRIGHT_WHITE	: byte4 : { 0xFF, 0xFF, 0xFF, 0xFF }

AMSTRAD_COLORS:= [27]byte4 {
	AMSTRAD_BLACK,
	AMSTRAD_BLUE,
	AMSTRAD_BRIGHT_BLUE,
	AMSTRAD_RED,
	AMSTRAD_MAGENTA,
	AMSTRAD_MAUVE,
	AMSTRAD_BRIGHT_RED,
	AMSTRAD_PURPLE,
	AMSTRAD_BRIGHT_MAGENTA,
	AMSTRAD_GREEN,
	AMSTRAD_CYAN,
	AMSTRAD_SKY_BLUE,
	AMSTRAD_YELLOW,
	AMSTRAD_WHITE,
	AMSTRAD_PASTEL_BLUE,
	AMSTRAD_ORANGE,
	AMSTRAD_PINK,
	AMSTRAD_PASTEL_MAGENTA,
	AMSTRAD_BRIGHT_GREEN,
	AMSTRAD_SEA_GREEN,
	AMSTRAD_BRIGHT_CYAN,
	AMSTRAD_LIME,
	AMSTRAD_PASTEL_GREEN,
	AMSTRAD_PASTEL_CYAN,
	AMSTRAD_BRIGHT_YELLOW,
	AMSTRAD_PASTEL_YELLOW,
	AMSTRAD_BRIGHT_WHITE,
}

AMSTRAD_COLOR :: enum u8 {
	BLACK,
	BLUE,
	BRIGHT_BLUE,
	RED,
	MAGENTA,
	MAUVE,
	BRIGHT_RED,
	PURPLE,
	BRIGHT_MAGENTA,
	GREEN,
	CYAN,
	SKY_BLUE,
	YELLOW,
	WHITE,
	PASTEL_BLUE,
	ORANGE,
	PINK,
	PASTEL_MAGENTA,
	BRIGHT_GREEN,
	SEA_GREEN,
	BRIGHT_CYAN,
	LIME,
	PASTEL_GREEN,
	PASTEL_CYAN,
	BRIGHT_YELLOW,
	PASTEL_YELLOW,
	BRIGHT_WHITE,
}

/*
Ink Color
Paper/Pen No.	Mode 0	Mode 1	Mode 2
		0		 1		 1		 1
		1		24		24		24
		2		20		20		 1
		3		 6		 6		24
		4		26		 1		 1
		5		 0		24		24
		6		 2		20		 1
		7		 8		 6		24
		8		10		 1		 1
		9		12		24		24
		10		14		20		 1
		11		16		 6		24
		12		18		 1		 1
		13		22		24		24
		14		1,24*	20		 1
		15		16,11*	 6		24
*Flashing
*/

// odinfmt: enable

AMSTRAD_INK := [16]byte{1, 24, 20, 6, 26, 0, 2, 8, 10, 12, 14, 16, 18, 22, 1, 16}


get_color_basic :: #force_inline proc "contextless" (col: COLOR) -> byte4 {
	return COLORS[col]
}

get_color_w95 :: #force_inline proc "contextless" (col: W95_COLOR) -> byte4 {
	return W95_COLORS[col]
}

get_color_c64 :: #force_inline proc "contextless" (col: C64_COLOR) -> byte4 {
	return C64_COLORS[col]
}

get_color_amstrad :: #force_inline proc "contextless" (col: AMSTRAD_COLOR) -> byte4 {
	return AMSTRAD_COLORS[col]
}

get_color :: proc {
	get_color_basic,
	get_color_w95,
	get_color_c64,
	get_color_amstrad,
}


// 256-(1/256) = 65535/256 = 255.99609375
color_scale_f2b :: f32(65535) / 256
color_scale_b2f :: 1 / f32(255)

to_color_float :: #force_inline proc "contextless" (color: float) -> byte {
	return byte(clamp(color, 0, 1) * color_scale_f2b)
}

to_color_byte :: #force_inline proc "contextless" (color: byte) -> float {
	return float(color) * color_scale_b2f
}

to_color_float3 :: #force_inline proc "contextless" (color: float3) -> byte4 {
	return {to_color_float(color.x), to_color_float(color.y), to_color_float(color.z), 255}
}

to_color_float4 :: #force_inline proc "contextless" (color: float4) -> byte4 {
	return {to_color_float(color.x), to_color_float(color.y), to_color_float(color.z), to_color_float(color.w)}
}

to_color_byte4 :: #force_inline proc "contextless" (color: byte4) -> float4 {
	return {to_color_byte(color.x), to_color_byte(color.y), to_color_byte(color.z), to_color_byte(color.w)}
}

to_color :: proc {
	to_color_float,
	to_color_float3,
	to_color_float4,
	to_color_byte4,
}

@(private = "file")
two_pi_over_3 :: f32(2) * math.PI / 3.0

color_hue_float4 :: #force_inline proc "contextless" (hue: f32, scale: f32 = 1, bias: f32 = 0) -> float4 {
	half_scale := scale * 0.5
	hue_g := hue + two_pi_over_3
	hue_b := hue_g + two_pi_over_3
	return {
		(f32)((math.sin(hue) + 1.0) * half_scale + bias),
		(f32)((math.sin(hue_g) + 1.0) * half_scale + bias),
		(f32)((math.sin(hue_b) + 1.0) * half_scale + bias),
		scale + bias,
	}
}

color_hue :: #force_inline proc "contextless" (hue: f32, scale: f32 = 1, bias: f32 = 0) -> byte4 {
	return to_color(color_hue_float4(hue, scale, bias))
}

get_amstrad_ink_color :: #force_inline proc "contextless" (ink: int) -> byte4 {
	return AMSTRAD_COLORS[AMSTRAD_INK[ink]].bgra
}

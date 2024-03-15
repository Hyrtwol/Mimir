package amstrad

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
*/

screen_size :: struct {
	size: [2]i32,
	bpp:  i32,
}
screen_sizes: [3]screen_size : {{size = {160, 200}, bpp = 4}, {size = {320, 200}, bpp = 4}, {size = {640, 200}, bpp = 4}}

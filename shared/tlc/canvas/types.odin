package canvas

import win32app "../win32app"

byte4 :: distinct [4]u8
int2  :: win32app.int2
ZERO2 : int2 : {0, 0}
screen_buffer :: [^]byte4

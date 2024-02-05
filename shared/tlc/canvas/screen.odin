package canvas

screen_buffer :: [^]byte4

fill_screen :: proc(p: screen_buffer, count: i32, col: byte4) {
	for i in 0 ..< count {
		p[i] = col
	}
}

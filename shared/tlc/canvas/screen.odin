package canvas

screen_buffer :: [^]color

fill_screen :: proc(p: screen_buffer, count: i32, col: color) {
	for i in 0 ..< count {
		p[i] = col
	}
}

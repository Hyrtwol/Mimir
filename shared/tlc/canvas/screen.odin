package canvas

fill_screen :: proc(p: screen_buffer, count: i32, col: byte4) {
	for i in 0 ..< count {
		p[i] = col
	}
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

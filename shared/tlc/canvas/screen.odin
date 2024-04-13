package canvas

screen_buffer :: [^]color

fill_screen :: #force_inline proc "contextless" (p: screen_buffer, count: i32, col: color) {
	for i in 0 ..< count {
		p[i] = col
	}
}

canvas :: struct {
	pvBits:      screen_buffer,
	size:        uint2,
	pixel_count: i32,
}

canvas_zero :: proc(c: ^canvas) {
	c.pvBits = nil
	c.size = {0, 0}
	c.pixel_count = 0
}

canvas_clear :: proc(c: ^canvas, col: byte4) {
	fill_screen(c.pvBits, c.pixel_count, col)
}

canvas_setdot :: proc(c: ^canvas, pos: int2, col: byte4) {
	p := transmute(uint2)pos
	if p.x < c.size.x && p.y < c.size.y {
		i := p.y * c.size.x + p.x
		c.pvBits[i] = col
	}
}

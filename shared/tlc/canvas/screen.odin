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

canvas_zero :: #force_inline proc "contextless" (c: ^canvas) {
	c.pvBits = nil
	c.size = {0, 0}
	c.pixel_count = 0
}

canvas_clear :: #force_inline proc "contextless" (c: ^canvas, col: byte4) {
	fill_screen(c.pvBits, c.pixel_count, col)
}

@(private)
canvas_set_dot_uint2 :: #force_inline proc "contextless" (c: ^canvas, p: uint2, col: byte4) {
	if p.x < c.size.x && p.y < c.size.y {
		c.pvBits[p.y * c.size.x + p.x] = col
	}
}

@(private)
canvas_set_dot_int2 :: #force_inline proc "contextless" (c: ^canvas, pos: int2, col: byte4) {
	canvas_set_dot_uint2(c, transmute(uint2)pos, col)
}

canvas_set_dot :: proc  {
	canvas_set_dot_uint2,
	canvas_set_dot_int2,
}

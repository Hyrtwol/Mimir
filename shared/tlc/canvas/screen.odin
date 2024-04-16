// +vet
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

canvas_set_dot :: proc {
	canvas_set_dot_uint2,
	canvas_set_dot_int2,
}

@(private)
color_fade_to_black :: #force_inline proc "contextless" (cp: ^color) {
	if transmute(u32)(cp^) > 0 {
		if cp.r > 0 {cp.r -= 1}
		if cp.g > 0 {cp.g -= 1}
		if cp.b > 0 {cp.b -= 1}
		if cp.a > 0 {cp.a -= 1}
	}
}

@(private)
canvas_fade_to_black :: proc(c: ^canvas) {
	cc := c.pixel_count
	bp := c.pvBits
	for i in 0 ..< cc {
		color_fade_to_black(&bp[i])
	}
}

fade_to_black :: proc {
	color_fade_to_black,
	canvas_fade_to_black,
}

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

canvas_zero :: #force_inline proc "contextless" (cv: ^canvas) {
	cv.pvBits = nil
	cv.size = {0, 0}
	cv.pixel_count = 0
}

canvas_clear :: #force_inline proc "contextless" (cv: ^canvas, col: byte4) {
	fill_screen(cv.pvBits, cv.pixel_count, col)
}

@(private)
canvas_set_dot_uint2 :: #force_inline proc "contextless" (cv: ^canvas, pos: uint2, col: byte4) {
	if pos.x < cv.size.x && pos.y < cv.size.y {
		cv.pvBits[pos.y * cv.size.x + pos.x] = col
	}
}

@(private)
canvas_set_dot_int2 :: #force_inline proc "contextless" (cv: ^canvas, pos: int2, col: byte4) {
	canvas_set_dot_uint2(cv, transmute(uint2)pos, col)
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
canvas_fade_to_black :: proc(cv: ^canvas) {
	cc := cv.pixel_count
	bp := cv.pvBits
	for i in 0 ..< cc {
		color_fade_to_black(&bp[i])
	}
}

fade_to_black :: proc {
	color_fade_to_black,
	canvas_fade_to_black,
}

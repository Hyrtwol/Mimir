// +vet
package canvas

import "core:math/linalg"

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
canvas_set_dot_xy :: #force_inline proc "contextless" (cv: ^canvas, #any_int x, y: u32, col: byte4) {
	if x < u32(cv.size.x) && y < u32(cv.size.y) {
		cv.pvBits[y * cv.size.x + x] = col
	}
}

@(private)
canvas_set_dot_uint2 :: #force_inline proc "contextless" (cv: ^canvas, pos: uint2, col: byte4) {
	canvas_set_dot_xy(cv, pos.x, pos.y, col)
}

@(private)
canvas_set_dot_int2 :: #force_inline proc "contextless" (cv: ^canvas, pos: int2, col: byte4) {
	canvas_set_dot_xy(cv, u32(pos.x), u32(pos.y), col)
}

@(private)
canvas_set_dot_float2 :: #force_inline proc "contextless" (cv: ^canvas, pos: float2, col: byte4) {
	canvas_set_dot_xy(cv, u32(pos.x), u32(pos.y), col)
}

canvas_set_dot :: proc {
	canvas_set_dot_xy,
	canvas_set_dot_uint2,
	canvas_set_dot_int2,
	canvas_set_dot_float2,
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

canvas_size :: #force_inline proc "contextless" (cv: ^canvas) -> (x, y: i32) {
	return i32(cv.size.x), i32(cv.size.y)
}

canvas_max :: #force_inline proc "contextless" (cv: ^canvas) -> (x, y: i32) {
	return i32(cv.size.x) - 1, i32(cv.size.y) - 1
}

// barycentric :: #force_inline proc "contextless" (abc: ^float3x3, x, y: i32) -> float3 {
// 	return linalg.inverse_transpose(abc^) * float3{f32(x), f32(y), 1}
// }
barycentric :: #force_inline proc "contextless" (abc: ^float3x3, x, y: f32) -> float3 {
	return linalg.inverse_transpose(abc^) * float3{x, y, 1}
}

triangle :: [3]float2

draw_triangle :: proc(pc: ^canvas, pts: triangle) {
	abc := float3x3{pts[0].x, pts[0].y, 1, pts[1].x, pts[1].y, 1, pts[2].x, pts[2].y, 1}
	if (linalg.determinant(abc) < 1e-3) {return}

	iw, ih := canvas_size(pc)
	bboxmin: int2 = {iw - 1, ih - 1}
	bboxmax: int2 = {0, 0}
	for i in 0 ..< 3 {
		p := to_int2(pts[i])
		bboxmin = linalg.min(bboxmin, p)
		bboxmax = linalg.max(bboxmax, p)
	}

	x1, x2 := bboxmin.x, bboxmax.x
	y1, y2 := bboxmin.y, bboxmax.y
	for x in x1 ..= x2 {
		for y in y1 ..= y2 {
			//bc_screen := barycentric(&abc, x, y)
			//bc_screen := barycentric(&abc, f32(x)-0.5, f32(y)-0.5)
			bc_screen := barycentric(&abc, f32(x), f32(y))
			if (bc_screen.x < 0 || bc_screen.y < 0 || bc_screen.z < 0) {
				//canvas_set_dot(pc, x, y, W95_NAVY)
				continue
			}
			canvas_set_dot(pc, x, y, to_color(bc_screen))
		}
	}
}

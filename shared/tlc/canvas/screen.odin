// vet
package canvas

import "core:math/linalg"
import "core:mem"

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

@(private = "file")
canvas_clear_color :: #force_inline proc "contextless" (cv: ^canvas, col: byte4) {
	fill_screen(cv.pvBits, cv.pixel_count, col)
}

@(private = "file")
canvas_clear_fast :: #force_inline proc "contextless" (cv: ^canvas) {
	mem.zero(raw_data(cv.pvBits), int(cv.pixel_count * 4))
}

canvas_clear :: proc {
	canvas_clear_color,
	canvas_clear_fast,
}

@(private = "file")
canvas_set_dot_xy :: #force_inline proc "contextless" (cv: ^canvas, #any_int x, y: u32, col: byte4) {
	if x < u32(cv.size.x) && y < u32(cv.size.y) {
		cv.pvBits[y * cv.size.x + x] = col
	}
}

@(private = "file")
canvas_set_dot_uint2 :: #force_inline proc "contextless" (cv: ^canvas, pos: uint2, col: byte4) {
	canvas_set_dot_xy(cv, pos.x, pos.y, col)
}

@(private = "file")
canvas_set_dot_int2 :: #force_inline proc "contextless" (cv: ^canvas, pos: int2, col: byte4) {
	canvas_set_dot_xy(cv, u32(pos.x), u32(pos.y), col)
}

@(private = "file")
canvas_set_dot_float2 :: #force_inline proc "contextless" (cv: ^canvas, pos: float2, col: byte4) {
	canvas_set_dot_xy(cv, u32(pos.x), u32(pos.y), col)
}

canvas_set_dot :: proc {
	canvas_set_dot_xy,
	canvas_set_dot_uint2,
	canvas_set_dot_int2,
	canvas_set_dot_float2,
}

@(private = "file")
color_fade_to_black :: #force_inline proc "contextless" (cp: ^color) {
	if transmute(u32)(cp^) > 0 {
		if cp.r > 0 {cp.r -= 1}
		if cp.g > 0 {cp.g -= 1}
		if cp.b > 0 {cp.b -= 1}
		if cp.a > 0 {cp.a -= 1}
	}
}

@(private = "file")
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

get_canvas_size :: #force_inline proc "contextless" (cv: ^canvas) -> int2 {
	return transmute(int2)cv.size
}

get_canvas_size_xy :: #force_inline proc "contextless" (cv: ^canvas) -> (x, y: i32) {
	return i32(cv.size.x), i32(cv.size.y)
}

canvas_max_xy :: #force_inline proc "contextless" (cv: ^canvas) -> (x, y: i32) {
	return i32(cv.size.x) - 1, i32(cv.size.y) - 1
}

canvas_max :: #force_inline proc "contextless" (cv: ^canvas) -> int2 {
	return {i32(cv.size.x) - 1, i32(cv.size.y) - 1}
}

canvas_aspect :: #force_inline proc "contextless" (cv: ^canvas) -> f32 {
	return f32(cv.size.x) / f32(cv.size.y)
}

@(private = "file")
min_max_int2_from_float4 :: #force_inline proc "contextless" (min, max: ^int2, v: float4) {
	p := to_int2(v.xy)
	min^ = linalg.min(min^, p)
	max^ = linalg.max(max^, p)
}

@(private = "file")
min_max_int2_from_float2 :: #force_inline proc "contextless" (min, max: ^int2, v: float2) {
	p := to_int2(v)
	min^ = linalg.min(min^, p)
	max^ = linalg.max(max^, p)
}

@(private)
bbox_min_max :: #force_inline proc "contextless" (pc: ^canvas, pts: [3]float4) -> (x1, x2, y1, y2: i32) {
	bbmin, bbmax: int2 = canvas_max(pc), int2{0, 0}
	for i in 0 ..< 3 {
		min_max_int2_from_float4(&bbmin, &bbmax, pts[i])
	}
	x1, x2, y1, y2 = bbmin.x, bbmax.x, bbmin.y, bbmax.y
	return
}

// for debug // minz, maxz: f32 = 1000, -1000

// https://mathworld.wolfram.com/BarycentricCoordinates.html
barycentric :: #force_inline proc "contextless" (abc: ^float3x3, pp: float3) -> float3 {
	return linalg.matrix3x3_inverse_transpose(abc^) * pp
}

draw_triangle_epsilon :: 1e-3
draw_triangle_epsilon3 :: float3{draw_triangle_epsilon, draw_triangle_epsilon, draw_triangle_epsilon}

VS_INPUT :: struct {
	position: float3,
	normal:   float3,
	texcoord: float2,
}

VS_OUTPUT :: struct {
	position: float4,
	normal:   float3,
	texcoord: float2,
}

vertex_shader :: #type proc(shader: ^Shader, input: ^VS_INPUT, output: ^VS_OUTPUT)
pixel_shader :: #type proc(shader: ^Shader, bc_clip: float3, color: ^byte4) -> bool

Model :: struct {
	trans: float4x4,
	color: float4,
	tex:   i32,
}
Shader :: struct {
	model:           ^Model,
	model_view:      float4x4,
	proj_view_model: float4x4,
	//it_model_view: float4x4,
	it_model_view:   float3x3,
	uniform_l:       float3, // light direction in view coordinates
	varying_uv:      float2x3, // triangle uv coordinates, written by the vertex shader, read by the fragment shader
	varying_nrm:     float3x3, // normal per vertex to be interpolated by FS
	view_tri:        float3x3, // triangle in view coordinates
	vs:              vertex_shader,
	ps:              pixel_shader,
}

draw_triangle :: proc(pc: ^canvas, zbuffer: []f32, viewport: ^float4x4, clip_verts: ^float4x3, shader: ^Shader) {

	clip_z := float3{clip_verts[0].z, clip_verts[1].z, clip_verts[2].z}
	if clip_z.x < 0 && clip_z.y < 0 && clip_z.z < 0 {return}
	if clip_z.x > 1 && clip_z.y > 1 && clip_z.z > 1 {return}

	// triangle screen coordinates before persp. division
	pts := viewport^ * clip_verts^
	// triangle screen coordinates after perps. division
	pts2: [3]float4 = {pts[0] / pts[0].w, pts[1] / pts[1].w, pts[2] / pts[2].w}

	abc := float3x3{pts2[0].x, pts2[0].y, 1, pts2[1].x, pts2[1].y, 1, pts2[2].x, pts2[2].y, 1}
	det := linalg.determinant(abc)
	if det < 1e-3 {return}

	cmin, cmax: int2 = {0, 0}, canvas_max(pc)
	bbmin, bbmax: int2 = cmax, cmin
	for i in 0 ..< 3 {
		min_max_int2_from_float4(&bbmin, &bbmax, pts2[i])
	}

	if bbmax.x < 0 || bbmin.x > cmax.x || bbmax.y < 0 || bbmin.y > cmax.y {return}

	bbmin = linalg.max(bbmin, cmin)
	bbmax = linalg.min(bbmax, cmax)
	x1, x2, y1, y2 := bbmin.x, bbmax.x, bbmin.y, bbmax.y

	// inverse transpose abc
	//it_abc := linalg.matrix_mul(linalg.adjugate(abc), 1 / det) // linalg.matrix3x3_inverse_transpose(abc)
	it_abc := linalg.matrix_mul(linalg.cofactor(abc), 1 / det) // linalg.matrix3x3_inverse_transpose(abc)

	iw := i32(pc.size.x)
	bits := pc.pvBits
	pp: float3 = {0, 0, 1}
	iy: i32
	color: byte4
	for y in y1 ..= y2 {
		pp.y = f32(y) + 0.5
		iy = y * iw
		for x in x1 ..= x2 {
			pp.x = f32(x) + 0.5
			bc_screen := it_abc * pp // barycentric(&abc, pp)
			if bc_screen.x < 0 || bc_screen.y < 0 || bc_screen.z < 0 {continue}

			bc_clip := float3{bc_screen.x / pts[0].w, bc_screen.y / pts[1].w, bc_screen.z / pts[2].w}
			bc_clip = bc_clip / (bc_clip.x + bc_clip.y + bc_clip.z) // check https://github.com/ssloy/tinyrenderer/wiki/Technical-difficulties-linear-interpolation-with-perspective-deformations

			frag_depth := linalg.dot(clip_z, bc_clip)
			if frag_depth < 0 || frag_depth >= 1 {continue}
			// minz, maxz = min(minz, frag_depth), max(maxz, frag_depth)

			idx := iy + x
			zp := &zbuffer[idx]
			if frag_depth < zp^ {continue}

			if shader->ps(bc_clip, &color) {continue} 	// fragment shader can discard current fragment

			zp^ = frag_depth
			//bits[idx] = to_color(frag_depth)
			//bits[idx] = to_color(bc_clip)
			bits[idx] = color
		}
	}
}

draw_hline :: #force_inline proc "contextless" (cv: ^canvas, #any_int x1, x2, y: u32, col: byte4) {
	if x1 < u32(cv.size.x) && x2 < u32(cv.size.x) && y < u32(cv.size.y) {
		w := cv.size.x
		i := y * w + x1
		for _ in x1 ..= x2 {
			cv.pvBits[i] = col
			i += 1
		}
	}
}

draw_vline :: #force_inline proc "contextless" (cv: ^canvas, #any_int x, y1, y2: u32, col: byte4) {
	if x < u32(cv.size.x) && y1 < u32(cv.size.y) && y2 < u32(cv.size.y) {
		w := cv.size.x
		i := y1 * w + x
		for _ in y1 ..= y2 {
			cv.pvBits[i] = col
			i += w
		}
	}
}

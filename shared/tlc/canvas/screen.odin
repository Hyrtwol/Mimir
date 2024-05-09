// vet
package canvas

import "core:fmt"
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

canvas_max_xy :: #force_inline proc "contextless" (cv: ^canvas) -> (x, y: i32) {
	return i32(cv.size.x) - 1, i32(cv.size.y) - 1
}

canvas_max :: #force_inline proc "contextless" (cv: ^canvas) -> int2 {
	return {i32(cv.size.x) - 1, i32(cv.size.y) - 1}
}

canvas_aspect :: #force_inline proc "contextless" (cv: ^canvas) -> f32 {
	return f32(cv.size.x) / f32(cv.size.y)
}

@(private)
min_max_int2_from_float4 :: #force_inline proc "contextless" (min, max: ^int2, v: float4) {
	p := to_int2(v.xy)
	min^ = linalg.min(min^, p)
	max^ = linalg.max(max^, p)
}

@(private)
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

// https://mathworld.wolfram.com/BarycentricCoordinates.html
barycentric :: #force_inline proc "contextless" (abc: ^float3x3, pp: float3) -> float3 {
	return linalg.matrix3x3_inverse_transpose(abc^) * pp
}

draw_triangle_epsilon :: 1e-3
draw_triangle_epsilon3 :: float3{draw_triangle_epsilon, draw_triangle_epsilon, draw_triangle_epsilon}

draw_triangle :: proc(pc: ^canvas, zbuffer: []f32, viewport: ^float4x4, clip_verts: [3]float4) {

	pts2: [3]float4 = {viewport^ * clip_verts[0], viewport^ * clip_verts[1], viewport^ * clip_verts[2]}
	abc := float3x3{pts2[0].x, pts2[0].y, 1, pts2[1].x, pts2[1].y, 1, pts2[2].x, pts2[2].y, 1}
	//abc := float3x3{clip_verts[0].x, clip_verts[0].y, 1, clip_verts[1].x, clip_verts[1].y, 1, clip_verts[2].x, clip_verts[2].y, 1}
	det := linalg.determinant(abc)
	if det < 1e-3 {return}

	clip_z := float3{clip_verts[0].z, clip_verts[1].z, clip_verts[2].z}
	if clip_z.x < 0 && clip_z.y < 0 && clip_z.z < 0 {return}
	if clip_z.x > 1 && clip_z.y > 1 && clip_z.z > 1 {return}

	cmax := canvas_max(pc)
	bbmin, bbmax: int2 = cmax, int2{0, 0}
	for i in 0 ..< 3 {
		min_max_int2_from_float4(&bbmin, &bbmax, pts2[i])
	}
	bbmin = linalg.max(bbmin, int2{0, 0})
	bbmax = linalg.min(bbmax, cmax)
	x1, x2, y1, y2 := bbmin.x, bbmax.x, bbmin.y, bbmax.y

	//it_abc := linalg.matrix3x3_inverse_transpose(abc)
	it_abc := linalg.matrix_mul(linalg.adjugate(abc), 1 / det)

	//fx, fy: f32
	pp: float3 = {0, 0, 1}
	//idx,
	iy: i32
	iw := i32(pc.size.x)
	bits := pc.pvBits
	for y in y1 ..= y2 {
		pp.y = f32(y) + 0.5
		iy = y * iw
		for x in x1 ..= x2 {
			pp.x = f32(x) + 0.5
			//bc_screen := barycentric(&abc, pp)
			bc_screen := it_abc * pp

			if bc_screen.x < -draw_triangle_epsilon || bc_screen.y < -draw_triangle_epsilon || bc_screen.z < -draw_triangle_epsilon {continue}
			//if linalg.any(linalg.less_than(bc_screen, draw_triangle_epsilon3)) {continue}

			/*
			//bc_clip := float3{bc_screen.x / pts[0].w, bc_screen.y / pts[1].w, bc_screen.z / pts[2].w}
			bc_clip := float3{bc_screen.x / clip_verts[0].w, bc_screen.y / clip_verts[1].w, bc_screen.z / clip_verts[2].w}
			bc_clip = bc_clip / (bc_clip.x + bc_clip.y + bc_clip.z)
			//double frag_depth = float3{clip_verts[0].z, clip_verts[1].z, clip_verts[2].z}*bc_clip
			frag_depth := linalg.dot(clip_z, bc_clip)
			*/
			frag_depth := linalg.dot(clip_z, bc_screen)
			if frag_depth < 0 || frag_depth >= 1 {continue}
			// minz, maxz = min(minz, frag_depth), max(maxz, frag_depth)s

			idx := iy + x
			if frag_depth < zbuffer[idx] {continue}
			zbuffer[idx] = frag_depth
			//bits[idx] = to_color(frag_depth)
			bits[idx] = to_color(bc_screen)
		}
	}
}

minz, maxz: f32 = 1000, -1000

/*
	vec3 bc_screen = barycentric(pts2, {static_cast<double>(x), static_cast<double>(y)});
	vec3 bc_clip   = {bc_screen.x/pts[0][3], bc_screen.y/pts[1][3], bc_screen.z/pts[2][3]};
	bc_clip = bc_clip/(bc_clip.x+bc_clip.y+bc_clip.z); // check https://github.com/ssloy/tinyrenderer/wiki/Technical-difficulties-linear-interpolation-with-perspective-deformations
	double frag_depth = vec3{clip_verts[0][2], clip_verts[1][2], clip_verts[2][2]}*bc_clip;
	if (bc_screen.x<0 || bc_screen.y<0 || bc_screen.z<0 || frag_depth > zbuffer[x+y*image.width()]) continue;
	TGAColor color;
	if (shader.fragment(bc_clip, color)) continue; // fragment shader can discard current fragment
	zbuffer[x+y*image.width()] = frag_depth;
	image.set(x, y, color);
*/

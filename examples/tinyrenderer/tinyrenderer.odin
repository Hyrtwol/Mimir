//
package tinyrenderer

import "core:fmt"
import "core:intrinsics"
import "core:math"
import lg "core:math/linalg"
import "core:math/rand"
import win32 "core:sys/windows"
import cv "libs:tlc/canvas"
import ca "libs:tlc/canvas_app"

_ :: fmt

vec2 :: lg.Vector2f32
vec3 :: lg.Vector3f32
vec4 :: lg.Vector4f32
mat3x3 :: lg.Matrix3x3f32
mat4x4 :: lg.Matrix4x4f32
byte4 :: cv.byte4
int2 :: cv.int2

width: i32 : 160
height: i32 : width * 3 / 4
ZOOM :: 8

fov :: math.PI / 4

rng := rand.create(u64(intrinsics.read_cycle_counter()))

ModelView: mat4x4
Viewport: mat4x4
Projection: mat4x4



// odinfmt: disable

light_dir := vec3{1, 1, 1} // light source
eye       := vec3{1, 1, 3} // camera position
center    := vec3{0, 0, 0} // camera direction
up        := vec3{0, 1, 0} // camera up vector

create_viewport :: #force_inline proc "contextless" (mx: ^mat4x4, x, y, w, h: f32) {
	mx^ = {
		w/2, 0  , 0  , x+w/2,
		0  , h/2, 0  , y+h/2,
		0  , 0  , 1  , 0    ,
		0  , 0  , 0  , 1    ,
	}
}

// // check https://en.wikipedia.org/wiki/Camera_matrix
// create_projection :: #force_inline proc "contextless" (mx: ^mat4x4, f: f32) {
// 	mx^ = {
// 		1,  0,    0, 0,
// 		0, -1,    0, 0,
// 		0,  0,    1, 0,
// 		0,  0, -1/f, 0,
// 	}
// }

// // odinfmt: enable

viewport :: proc(x, y, w, h: i32) {
	create_viewport(&Viewport, f32(x), f32(y), f32(w), f32(h))
}

// projection :: proc(f: f32) {
// 	create_projection(&Projection, f)
// }

// // check https://github.com/ssloy/tinyrenderer/wiki/Lesson-5-Moving-the-camera
// lookat :: proc(eye, center, up: vec3) {
// 	z := lg.normalize(center - eye)
// 	x := lg.normalize(lg.cross(up, z))
// 	y := lg.normalize(lg.cross(z, x))
// 	mx_inv: mat4x4 = {x.x, x.y, x.z, 0, y.x, y.y, y.z, 0, z.x, z.y, z.z, 0, 0, 0, 0, 1}
// 	mx_tr: mat4x4 = {1, 0, 0, -eye.x, 0, 1, 0, -eye.y, 0, 0, 1, -eye.z, 0, 0, 0, 1}
// 	ModelView = mx_inv * mx_tr
// }

barycentric :: #force_inline proc "contextless" (abc: ^mat3x3, x, y: i32) -> vec3 {
	return lg.inverse_transpose(abc^) * vec3{f32(x), f32(y), 1}
}

IShader :: struct {}

//fragment :: proc(shader: ^IShader, bc_clip :vec3, color: ^byte4) -> bool {return false}
fragment_shader :: #type proc(shader: ^IShader, bc_clip: vec3, color: ^byte4) -> bool

//triangle :: proc(const vec4 clip_verts[3], IShader &shader, TGAImage &image, std::vector<double> &zbuffer) {
triangle :: proc(clip_verts: [3]vec4, shader: ^IShader, image: ^cv.canvas, zbuffer: []f64, fragment: fragment_shader) {
	pts: [3]vec4 = {Viewport * clip_verts[0], Viewport * clip_verts[1], Viewport * clip_verts[2]} // triangle screen coordinates before persp. division
	pts2: cv.triangle = {vec2(pts[0].xy / pts[0][3]), vec2(pts[1].xy / pts[1][3]), vec2(pts[2].xy / pts[2][3])} // triangle screen coordinates after  perps. division

	abc := mat3x3{pts2[0].x, pts2[0].y, 1, pts2[1].x, pts2[1].y, 1, pts2[2].x, pts2[2].y, 1}

	iw, ih := cv.canvas_size(image)
	bboxmin: int2 = {iw - 1, ih - 1}
	bboxmax: int2 = {0, 0}
	for i in 0 ..< 3 {
		bboxmin = lg.min(bboxmin, cv.to_int2_floor(pts2[i]))
		bboxmax = lg.max(bboxmax, cv.to_int2_ceil(pts2[i]))
	}

	//#pragma omp parallel for
	// for (int x=std::max(bboxmin[0], 0); x<=std::min(bboxmax[0], image.width()-1); x++) {
	//     for (int y=std::max(bboxmin[1], 0); y<=std::min(bboxmax[1], image.height()-1); y++) {
	pp2 := &pts2
	x1 := max(bboxmin[0], 0)
	x2 := min(bboxmax[0], iw - 1)
	y1 := max(bboxmin[1], 0)
	y2 := min(bboxmax[1], ih - 1)
	xy: vec2
	for x in x1 ..= x2 {
		xy.x = f32(x)
		for y in y1 ..= y2 {
			xy.y = f32(y)
			iz := x + y * iw

			bc_screen: vec3 = barycentric(&abc, x, y)
			bc_clip: vec3 = {bc_screen.x / pts[0][3], bc_screen.y / pts[1][3], bc_screen.z / pts[2][3]}
			bc_clip = bc_clip / (bc_clip.x + bc_clip.y + bc_clip.z) // check https://github.com/ssloy/tinyrenderer/wiki/Technical-difficulties-linear-interpolation-with-perspective-deformations
			// double frag_depth = vec3{clip_verts[0][2], clip_verts[1][2], clip_verts[2][2]}*bc_clip;
			//frag_depth :f64= vec3{clip_verts[0][2], clip_verts[1][2], clip_verts[2][2]} * bc_clip
			frag_depth := f64(lg.dot(vec3{clip_verts[0][2], clip_verts[1][2], clip_verts[2][2]}, bc_clip))
			if (bc_screen.x < 0 || bc_screen.y < 0 || bc_screen.z < 0 || frag_depth > zbuffer[x + y * iw]) {continue}
			color: byte4
			//if shader.fragment(bc_clip, &color) {continue} // fragment shader can discard current fragment
			if fragment(shader, bc_clip, &color) {continue} 	// fragment shader can discard current fragment
			zbuffer[x + y * iw] = frag_depth
			//image.set(x, y, color);
			cv.canvas_set_dot(image, x, y, color)
		}
	}
}

decode_mouse_pos :: #force_inline proc "contextless" (app: ca.papp) -> vec2 {
	v := app.mouse_pos
	return {f32(v.x), f32(v.y)} / ZOOM
}

testpts: cv.triangle = {vec2{120, 30}, vec2{80, 100}, vec2{30, 30}}

vertices := [?]cv.float3{{-1, 0, 0}, {1, 0, 0}, {0, -1, 0}, {0, 1, 0}, {0, 0, -1}, {0, 0, 1}}
triangles := [?]cv.int3{{3, 4, 0}, {3, 0, 5}, {3, 5, 1}, {3, 1, 4}, {2, 0, 4}, {2, 5, 0}, {2, 1, 5}, {2, 4, 1}}

on_create :: proc(app: ca.papp) -> int {
	pc := &ca.dib.canvas
	width, height := cv.canvas_size(pc)
	aspect: f32 = 1 // f32(width) / f32(height)

	ModelView = lg.matrix4_look_at(eye, center, up)
	viewport(20, 0, height, height) // build the Viewport matrix
	//Viewport = lg.matrix4_look_at(eye, center, up)
	//viewport(width / 8, height / 8, width * 3 / 4, height * 3 / 4) // build the Viewport matrix
	//projection(lg.distance(eye, center)) // build the Projection matrix
	Projection = lg.matrix4_perspective(fov, aspect, 0.1, 2)
	fmt.println("ModelView:", ModelView)
	fmt.println("Viewport:", Viewport)
	fmt.println("Projection:", Projection)
	return 0
}

on_update :: proc(app: ca.papp) -> int {

	#partial switch app.mouse_buttons {
	case .MK_LBUTTON:
		testpts[0] = decode_mouse_pos(app)
	case .MK_RBUTTON:
		testpts[1] = decode_mouse_pos(app)
	case .MK_MBUTTON:
		testpts[2] = decode_mouse_pos(app)
	}

	pc := &ca.dib.canvas
	cv.canvas_clear(pc, cv.COLOR_BLACK)

	eye.x = math.sin(f32(app.tick) * 0.01) * 3
	//lookat(eye, center, up)
	ModelView = lg.matrix4_look_at(eye, center, up)

	for t in triangles {
		v0, v1, v2 := cv.to_float4(vertices[t.x]), cv.to_float4(vertices[t.y]), cv.to_float4(vertices[t.z])

		// v0 = Projection * v0
		// v1 = Projection * v1
		// v2 = Projection * v2

		v0 = ModelView * v0
		v1 = ModelView * v1
		v2 = ModelView * v2

		v0 = Viewport * v0
		v1 = Viewport * v1
		v2 = Viewport * v2

		v0 = v0 / v0.w
		v1 = v1 / v1.w
		v2 = v2 / v2.w

		// v0 = Projection * v0
		// v1 = Projection * v1
		// v2 = Projection * v2

		tri: cv.triangle = {v0.xy, v1.xy, v2.xy}
		cv.draw_triangle(pc, tri)
	}

	//cv.draw_triangle(pc, testpts)

	return 0
}

main :: proc() {
	ca.app.size = {width, height}
	ca.app.create = on_create
	ca.app.update = on_update
	ca.settings.window_size = ca.app.size * ZOOM
	ca.run()
	fmt.println("app:", ca.app)
}

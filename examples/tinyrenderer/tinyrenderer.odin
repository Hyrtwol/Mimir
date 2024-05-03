// vet
package tinyrenderer

import "core:fmt"
import "core:intrinsics"
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
// FPS :: 20
rng := rand.create(u64(intrinsics.read_cycle_counter()))

// width  : i32 : 800; // output image size
// height : i32 : 800;

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

// check https://en.wikipedia.org/wiki/Camera_matrix
create_projection :: #force_inline proc "contextless" (mx: ^mat4x4, f: f32) {
	mx^ = {
		1,  0,    0, 0,
		0, -1,    0, 0,
		0,  0,    1, 0,
		0,  0, -1/f, 0,
	}
}

// odinfmt: enable

viewport :: proc(x, y, w, h: i32) {
	create_viewport(&Viewport, f32(x), f32(y), f32(w), f32(h))
}

projection :: proc(f: f32) {
	create_projection(&Projection, f)
}

// check https://github.com/ssloy/tinyrenderer/wiki/Lesson-5-Moving-the-camera
lookat :: proc(eye, center, up: vec3) {
	z := lg.normalize(center - eye)
	x := lg.normalize(lg.cross(up, z))
	y := lg.normalize(lg.cross(z, x))
	mx_inv: mat4x4 = {x.x, x.y, x.z, 0, y.x, y.y, y.z, 0, z.x, z.y, z.z, 0, 0, 0, 0, 1}
	mx_tr: mat4x4 = {1, 0, 0, -eye.x, 0, 1, 0, -eye.y, 0, 0, 1, -eye.z, 0, 0, 0, 1}
	ModelView = mx_inv * mx_tr
}

// barycentric :: proc(tri: ^cv.triangle, P: vec2) -> vec3 {
// 	abc := mat3x3{tri[0].x, tri[0].y, 1, tri[1].x, tri[1].y, 1, tri[2].x, tri[2].y, 1}
// 	// for a degenerate triangle generate negative coordinates, it will be thrown away by the rasterizator
// 	if (lg.determinant(abc) < 1e-3) {return {-1, 1, 1}}
// 	//return ABC.invert_transpose() * embed<3>(P);
// 	return lg.inverse_transpose(abc) * vec3{P.x, P.y, 1}
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

	//int bboxmin[2] = {image.width()-1, image.height()-1};
	//mx, my := cv.canvas_max(pc)
	// iw := i32(image.size.x)
	// ih := i32(image.size.y)
	iw, ih := cv.canvas_size(image)
	bboxmin: int2 = {iw - 1, ih - 1}
	bboxmax: int2 = {0, 0}
	for i in 0 ..< 3 {
		// for j in 0..<2 {
		//     bboxmin[j] = lg.min(bboxmin[j], i32(pts2[i][j]))
		//     bboxmax[j] = lg.max(bboxmax[j], i32(pts2[i][j]))
		// }
		// bboxmin = lg.min(bboxmin, transmute(int2)pts2[i])
		// bboxmax = lg.max(bboxmax, transmute(int2)pts2[i])
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

testpts: cv.triangle = {vec2{120, 30}, vec2{81, 100}, vec2{30, 50}}
/*
            mesh.vertices = new[]
            {
                new Vector3(-half.x, 0, 0),
                new Vector3( half.x, 0, 0),
                new Vector3( 0,-half.y, 0), //2
                new Vector3( 0, half.y, 0),
                new Vector3( 0, 0,-half.z), //4
                new Vector3( 0, 0, half.z)
            };
*/
vertices:= [?]cv.float3{
	{-1, 0, 0},
	{ 1, 0, 0},
	{ 0,-1, 0},
	{ 0, 1, 0},
	{ 0, 0,-1},
	{ 0, 0, 1},
}
triangles := [?]cv.int3{
	{3, 4, 0},
	{3, 0, 5},
	{3, 5, 1},
	{3, 1, 4},
	{2, 0, 4},
	{2, 5, 0},
	{2, 1, 5},
	{2, 4, 1},
}

on_create :: proc(app: ca.papp) -> int {
	// size := ca.dib.canvas.size
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

	cv.draw_triangle(pc, testpts)

	// if app.tick & 0x10 == 0 {
	// 	cv.canvas_set_dot(pc, testpts[0], cv.COLOR_BLUE)
	// 	cv.canvas_set_dot(pc, testpts[1], cv.COLOR_GREEN)
	// 	cv.canvas_set_dot(pc, testpts[2], cv.COLOR_RED)
	// } else {
	// 	cv.canvas_set_dot(pc, testpts[0], cv.COLOR_BLACK)
	// 	cv.canvas_set_dot(pc, testpts[1], cv.COLOR_BLACK)
	// 	cv.canvas_set_dot(pc, testpts[2], cv.COLOR_BLACK)
	// }
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

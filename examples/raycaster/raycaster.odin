// +vet
package raycaster

import "core:fmt"
import "core:intrinsics"
import "core:math/rand"
import "core:time"
import cv "libs:tlc/canvas"
import ca "libs:tlc/canvas/app"
//import win32app "libs:tlc/win32app"

WIDTH: i32 : 320
HEIGHT: i32 : WIDTH * 3 / 4
ZOOM :: 4
FPS :: 20

rng := rand.create(u64(intrinsics.read_cycle_counter()))

// pics_data :: struct {
// 	data: []u8,
// 	w, h: i32,
// 	ps: i32,
// 	size: i32,
// 	count: i32,
// }

// _pics := pics_data{
// 	data = #load("pics.dat"),
// 	w = 64,
// 	h = 64,
// 	ps = size_of(cv.byte4),
// 	//count = i32(len(_pics.data)) / _pics.size,
// 	//size = _pics.w * _pics.h * _pics.ps,
// }

pics := #load("pics.dat")
pics_w, pics_h: i32 = 64, 64
pics_ps: i32 = size_of(cv.byte4)
pics_size := pics_w * pics_h * pics_ps
pics_count := i32(len(pics)) / pics_size

xo: i32 = 0
po: i32 = rand.int31_max(pics_count, &rng)

ray2i: struct {
	pos, dir: cv.int2,
}

ray2f: struct {
	pos, dir: cv.float2,
}

on_create :: proc(app: ca.papp) -> int {
	return 0
}

on_destroy :: proc(app: ca.papp) -> int {
	return 0
}

xof : f64 = 0

on_update :: proc(app: ca.papp) -> int {
	xof += ca.delta * 64
	xo = i32(xof)

	pc := &ca.dib.canvas
	for _ in 0 ..< 500 {
		pos := cv.random_position(pc.size, &rng)
		//col := cv.random_color(&rng)
		//cv.canvas_set_dot(pc, pos, col)
		cv.canvas_set_dot(pc, pos, cv.COLOR_BLACK)
	}

	k: i32 : 4
	c: cv.byte4
	p: cv.int2
	for iii in 0 ..< k {
		ii := (iii + po) % pics_count
		i := pics_size * ii
		yo := pics_h * iii
		for y in 0 ..< pics_h {
			p.y = y + yo
			for x in 0 ..< pics_w {
				p.x = x + xo
				c = (^cv.byte4)(&pics[i])^
				if transmute(u32)(c) > 0 {
					cv.canvas_set_dot(pc, p, c)
				}
				i += pics_ps
			}
		}
	}

	//xo += 1
	//if xo >= 256 + pics_w {
	// 	xo = -pics_w
	// 	po += 1
	//}
	if xof >= f64(256 + pics_w) {
		xof = f64(-pics_w)
		po += 1
	}

	time.sleep(time.Millisecond)

	return 1 // repaint
}

main :: proc() {
	fmt.println("Raycaster")
	fmt.printfln("Images: %d x (%dx%d@%d:%d) = %d", pics_count, pics_w, pics_w, pics_ps*8, pics_size, pics_count * pics_size)
	ca.app.size = {WIDTH, HEIGHT}
	ca.app.create = on_create
	ca.app.update = on_update
	ca.app.destroy = on_destroy
	ca.settings.window_size = ca.app.size * ZOOM
	ca.run()
	fmt.println("Done.")
}

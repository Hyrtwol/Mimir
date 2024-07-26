// +vet
package raycaster

import "core:fmt"
import "base:intrinsics"
import "core:math/rand"
import "core:time"
import cv "libs:tlc/canvas"
import ca "libs:tlc/canvas_app"

USE_DELTA :: true
USE_RANDOM_COLORS :: false

WIDTH: i32 : 320
HEIGHT: i32 : WIDTH * 3 / 4
ZOOM :: 4
FPS :: 20

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
//pics_w: i32 : 64
pics_w: i32 : 32
pics_h: i32 : pics_w
pics_ps: i32 : size_of(cv.byte4)
pics_size: i32 : pics_w * pics_h * pics_ps
pics_count := i32(len(pics)) / pics_size
pics_buf_size :: pics_w * pics_h
pics_buf :: [pics_buf_size]cv.byte4
#assert(pics_ps == 4)
when pics_w == 64 {
	#assert(pics_size == 16384)
	#assert(pics_buf_size == 4096)
	#assert(size_of(pics_buf) == 16384)
} else when pics_w == 32 {
	#assert(pics_size == 4096)
	#assert(pics_buf_size == 1024)
	#assert(size_of(pics_buf) == 4096)
}

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

xo: i32 = -pics_w
po: i32 = rand.int31_max(pics_count)
xof: f32 = 0

on_update :: proc(app: ca.papp) -> int {
	when USE_DELTA {
		xof += app.delta * 64
		if xof >= f32(WIDTH) {
			xof = f32(-pics_w)
			po += 1
		}
		xo = i32(xof)
	} else {
		xo += 1
		if xo >= WIDTH {
			xo = -pics_w
			po += 1
		}
	}

	pc := &ca.dib.canvas
	for _ in 0 ..< 500 {
		pos := cv.random_position(pc.size)
		when USE_RANDOM_COLORS {
			cv.canvas_set_dot(pc, pos, cv.random_color())
		} else {
			cv.canvas_set_dot(pc, pos, cv.COLOR_BLACK)
		}
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

	return 0
}

main :: proc() {
	fmt.println("Raycaster")
	fmt.printfln("Images: %d x (%dx%d@%d:%d) = %d", pics_count, pics_w, pics_w, pics_ps * 8, pics_size, pics_count * pics_size)
	ca.app.size = {WIDTH, HEIGHT}
	ca.app.create = on_create
	ca.app.update = on_update
	ca.app.destroy = on_destroy
	ca.settings.window_size = ca.app.size * ZOOM
	ca.settings.sleep = time.Millisecond * 6
	ca.run()
	fmt.println("Done.")
}

// +vet
package raycaster

import "core:intrinsics"
import "core:fmt"
import "core:math/rand"
import "core:time"
import cv "libs:tlc/canvas"
import ca "libs:tlc/canvas/app"

WIDTH: i32 : 320
HEIGHT: i32 : WIDTH * 3 / 4
ZOOM :: 2
FPS :: 20

rng := rand.create(u64(intrinsics.read_cycle_counter()))

pics := #load("pics.dat")
pics_w, pics_h: i32 = 64, 64
pics_ps : i32 = size_of(cv.byte4)
pics_size := pics_w * pics_h * pics_ps
pics_count := i32(len(pics)) / pics_size

xo : i32 = 0
po : i32 = rand.int31_max(pics_count, &rng)

on_update :: proc(app: ca.papp) -> int {
	pc := &ca.dib.canvas
	for _ in 0 ..< 500 {
		pos := cv.random_position(pc.size, &rng)
		col := cv.random_color(&rng)
		cv.canvas_set_dot(pc, pos, col)
	}

	c: ^cv.byte4
	p: cv.int2
	for iii in i32(0)..< 4 {
		ii := (iii+po) % pics_count
		i := pics_size * ii
		yo := pics_h * iii
		for y in 0 ..< pics_h {
			p.y = y + yo
			for x in 0 ..< pics_w {
				p.x = x + xo
				c = (^cv.byte4)(&pics[i])
				if transmute(u32)(c^) > 0 {
					cv.canvas_set_dot(pc, p, c^)
				}
				i += pics_ps
			}
		}
	}

	//xo = (xo+1) & 0xFF
	xo += 1
	if xo >= 256 {
		xo = 0
		po += 1
	}

	time.sleep(time.Millisecond)

	return 1 // repaint
}

main :: proc() {
	fmt.println("pics_count:", pics_count)
	ca.app.size = {WIDTH, HEIGHT}
	ca.app.update = on_update
	ca.settings.window_size = ca.app.size * ZOOM
	ca.run()
}

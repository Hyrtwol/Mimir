// +vet
package movers

import "base:intrinsics"
import "core:math/rand"
import cv "libs:tlc/canvas"
import ca "libs:tlc/canvas_app"

WIDTH: i32 : 320
HEIGHT: i32 : WIDTH * 3 / 4
ZOOM :: 4
FPS :: 20

rng := rand.create(u64(intrinsics.read_cycle_counter()))

dude_count :: 4 * 100
dude :: struct {
	pos: cv.int2,
	col: cv.byte4,
}
dudes: [dude_count]dude

on_create :: proc(app: ca.papp) -> int {
	size := ca.dib.canvas.size
	for &d in dudes {
		d.pos = cv.random_position(size, &rng)
		d.col = cv.random_color(&rng)
	}
	return 0
}

on_update :: proc(app: ca.papp) -> int {
	pc := &ca.dib.canvas
	pp: ^ cv.int2
	dir:  cv.int2
	mx, my := cv.canvas_max_xy(pc)
	for &d in dudes {
		pp = &d.pos
		dir = cv.get_direction4(rand.int31_max(8, &rng))
		pp^ += dir
		if pp.x < 0 {pp.x = mx} else if pp.x > mx {pp.x = 0}
		if pp.y < 0 {pp.y = my} else if pp.y > my {pp.y = 0}
		cv.canvas_set_dot(pc, d.pos, d.col)
	}
	cv.fade_to_black(pc)
	return 0
}

main :: proc() {
	ca.app.size = {WIDTH, HEIGHT}
	ca.app.create = on_create
	ca.app.update = on_update
	ca.settings.window_size = ca.app.size * ZOOM
	ca.run()
}

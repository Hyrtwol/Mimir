#+vet
package movers

import "base:intrinsics"
import "core:os"
import "core:math/rand"
import cv "libs:tlc/canvas"
import ca "libs:tlc/canvas_app"

WIDTH: i32 : 320
HEIGHT: i32 : WIDTH * 3 / 4
ZOOM :: 4

dude_count :: 4 * 100
dude :: struct {
	pos: cv.int2,
	col: cv.byte4,
	dir: i32,
}
dudes: [dude_count]dude

dirs: [8]cv.int2 = {{1, 0}, {1, 1}, {0, 1}, {-1, 1}, {-1, 0}, {-1, -1}, {0, -1}, {1, -1}}

on_create :: proc(app: ^ca.application) -> int {
	size := ca.dib.canvas.size
	for &d in dudes {
		d.pos = cv.random_position(size)
		d.col = cv.random_color()
		d.dir = rand.int31_max(8)
	}
	return 0
}

on_update :: proc(app: ^ca.application) -> int {
	pc := &ca.dib.canvas
	pp: ^cv.int2
	mx, my := cv.canvas_max_xy(pc)
	for &d in dudes {
		pp = &d.pos
		d.dir += rand.int31_max(3) - 1
		pp^ += dirs[(d.dir >> 1) & 7]
		if pp.x < 0 {pp.x = mx} else if pp.x > mx {pp.x = 0}
		if pp.y < 0 {pp.y = my} else if pp.y > my {pp.y = 0}
		cv.canvas_set_dot(pc, d.pos, d.col)
	}
	cv.fade_to_black(pc)
	return 0
}

main :: proc() {
	app := ca.default_application
	app.size = {WIDTH, HEIGHT}
	app.create = on_create
	app.update = on_update
	app.settings.window_size = app.size * ZOOM
	exit_code := ca.run(&app)
	os.exit(exit_code)
}

#+vet
package movers

import "base:intrinsics"
import "core:math/rand"
import "core:os"
import cv "libs:tlc/canvas"
import ca "libs:tlc/canvas_app"
import "shared:obug"

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

wrap_scalar :: #force_inline proc "contextless" (v: ^i32, size: i32)  {
 	if v^ < 0 {v^ += size} else if v^ >= size {v^ -= size}
}

wrap_vector :: #force_inline proc "contextless" (v: ^[$N]i32, size: [N]i32)  {
	#unroll	for i in 0 ..< N {
		wrap_scalar(&v[i], size[i])
	}
}

on_update :: proc(app: ^ca.application) -> int {
	pc := &ca.dib.canvas
	pp: ^cv.int2
	siz := cv.get_canvas_size(pc)
	for &d in dudes {
		pp = &d.pos
		d.dir += rand.int31_max(3) - 1
		pp^ += dirs[(d.dir >> 1) & 7]
		wrap_vector(pp, siz)
		cv.canvas_set_dot(pc, d.pos, d.col)
	}
	cv.fade_to_black(pc)
	return 0
}

run :: proc() -> (exit_code: int) {
	app := ca.default_application
	app.size = {WIDTH, HEIGHT}
	app.create = on_create
	app.update = on_update
	app.settings.window_size = app.size * ZOOM
	exit_code = ca.run(&app)
	return
}

main :: proc() {
	when intrinsics.is_package_imported("obug") {
		os.exit(obug.tracked_run(run))
	} else {
		os.exit(run())
	}
}

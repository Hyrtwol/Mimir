// +vet
package raycaster

import "core:fmt"
import "core:math/rand"
import "core:intrinsics"
import "core:time"
import cv "libs:tlc/canvas"
import ca "libs:tlc/canvas/app"

int2 :: cv.int2

TITLE :: "Raycaster"
WIDTH: i32 : 320
HEIGHT: i32 : WIDTH * 3 / 4
PXLCNT: i32 : WIDTH * HEIGHT
ZOOM :: 2
FPS :: 20

rng := rand.create(u64(intrinsics.read_cycle_counter()))

on_create :: proc(app: ca.papp) -> int {
	fmt.println("user_create:", app)
	return 0
}

on_destroy :: proc(app: ca.papp) -> int {
	fmt.println("on_destroy:", app)
	return 0
}

on_update :: proc(app: ca.papp) -> int {
	//fmt.println("on_update:", app)
	pc := &ca.dib.canvas
	pos : cv.int2
	col : cv.byte4
	for _ in 0..<1000 {
		pos = {rand.int31_max(i32(pc.size.x), &rng), rand.int31_max(i32(pc.size.y), &rng)}
		col = {u8(rand.int31_max(255, &rng)), u8(rand.int31_max(255, &rng)), u8(rand.int31_max(255, &rng)), 0}
		cv.canvas_set_dot(pc, pos, col)
	}

	time.sleep(time.Millisecond)
	//time.sleep(time.Microsecond)

	return 1 // repaint
}

main :: proc() {
	ca.app.size = {WIDTH, HEIGHT}
	ca.app.create = on_create
	ca.app.update = on_update
	ca.app.destroy = on_destroy
	ca.settings.title = TITLE
	ca.settings.window_size = ca.app.size * ZOOM
	ca.run()
}

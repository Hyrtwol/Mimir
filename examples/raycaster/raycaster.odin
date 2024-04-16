// +vet
package raycaster

import "core:math/rand"
import "core:intrinsics"
import "core:time"
import cv "libs:tlc/canvas"
import ca "libs:tlc/canvas/app"

WIDTH: i32 : 320
HEIGHT: i32 : WIDTH * 3 / 4
ZOOM :: 2
FPS :: 20

rng := rand.create(u64(intrinsics.read_cycle_counter()))

on_update :: proc(app: ca.papp) -> int {
	pc := &ca.dib.canvas
	pos : cv.int2
	col : cv.byte4
	for _ in 0..<1000 {
		pos = {rand.int31_max(i32(pc.size.x), &rng), rand.int31_max(i32(pc.size.y), &rng)}
		col = {u8(rand.int31_max(255, &rng)), u8(rand.int31_max(255, &rng)), u8(rand.int31_max(255, &rng)), 0}
		cv.canvas_set_dot(pc, pos, col)
	}

	time.sleep(time.Millisecond)

	return 1 // repaint
}

main :: proc() {
	ca.app.size = {WIDTH, HEIGHT}
	ca.app.update = on_update
	ca.settings.window_size = ca.app.size * ZOOM
	ca.run()
}

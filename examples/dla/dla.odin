// +vet
// https://en.wikipedia.org/wiki/Diffusion-limited_aggregation
package dla

// D:\dev\pascal\Delphi7\DLA\DLAMain.pas

import "core:math/rand"
import "core:intrinsics"
import "core:time"
import cv "libs:tlc/canvas"
import ca "libs:tlc/canvas/app"

int2 :: cv.int2

TITLE :: "Diffusion Limited Aggregation"
WIDTH: i32 : 320
HEIGHT: i32 : WIDTH * 3 / 4
PXLCNT: i32 : WIDTH * HEIGHT
ZOOM :: 2
FPS :: 20

rng := rand.create(u64(intrinsics.read_cycle_counter()))

point_count :: 50000

world_radius :: 1024
rh :: world_radius / 2
rl :: (world_radius - 4) / 2
rm :: world_radius - 2

rofs := 10

map_size :: world_radius * world_radius
map_: [world_radius][world_radius]u32
//map_: [map_size]u32
bmp: rawptr //TBitmap32; //lcBitmap;
cnt: i32
maxrad, maxrad2, maxrad3: i32

dude_count :: 4

dude :: struct {
	pos: int2
}
dudes: [dude_count]dude

on_create :: proc(app: ca.papp) -> int {
	//fmt.println("user_create:", app)
	pc := &ca.dib.canvas
	/*
	w, h := pc.size.x, pc.size.y
	pos: cv.int2
	//col : cv.byte4 = {0,0,0,0}
	for y in 0 ..< h {
		pos.y = i32(y)
		for x in 0 ..< w {
			pos.x = i32(x)
			cv.canvas_set_dot(pc, pos, cv.byte4{u8(x), u8(y), 0, 0})
		}
	}
	*/
	for i in 0 ..< dude_count {
		dudes[i].pos = cv.random_position(pc.size, &rng)
	}
	return 0
}

on_destroy :: proc(app: ca.papp) -> int {
	//fmt.println("on_destroy:", app)
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

// +vet
// https://en.wikipedia.org/wiki/Diffusion-limited_aggregation
package dla

// D:\dev\pascal\Delphi7\DLA\DLAMain.pas

import "core:intrinsics"
import "core:math/rand"
import "core:time"
import cv "libs:tlc/canvas"
import ca "libs:tlc/canvas/app"

int2 :: cv.int2
uint2 :: cv.uint2
byte4 :: cv.byte4

WIDTH: i32 : 256 * 2
HEIGHT: i32 : WIDTH
ZOOM :: 2
FPS :: 20

rng := rand.create(u64(intrinsics.read_cycle_counter()))

point_count :: 50000

world_radius :: WIDTH
rh :: world_radius / 2
rl :: (world_radius - 4) / 2
rm :: world_radius - 2

rofs := 10

map_size :: world_radius * world_radius
//map_: [world_radius][world_radius]u8
_map: [map_size]u8
bmp: rawptr //TBitmap32; //lcBitmap;
cnt: i32
maxrad, maxrad2, maxrad3: i32

dude_count :: 2 * 100
dude :: struct {
	pos: int2,
	col: byte4,
}
dudes: [dude_count]dude

get_dude_move :: #force_inline proc "contextless" (dir: i32) -> int2 {
	// U{0,+1} R{+1,0} D{0,-1} L{-1,0}
	@static dude_moves: [5]i32 = {0, 1, 0, -1, 0}
	return ((^int2)(&dude_moves[dir & 3]))^
}

on_create :: proc(app: ca.papp) -> int {
	//fmt.println("user_create:", app)
	for i in 0..<map_size {
		_map[i] = 0
	}
	size := ca.dib.canvas.size
	for &d in dudes {
		d.pos = cv.random_position(size, &rng)
		d.col = cv.random_color(&rng)
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
	pp: ^int2
	dir: int2
	mx, my := i32(pc.size.x - 1), i32(pc.size.y - 1)

	for &d in dudes {
		pp = &d.pos
		dir = get_dude_move(rand.int31_max(4, &rng))
		pp^ += dir
		if pp.x < 0 {pp.x = mx} else if pp.x > mx {pp.x = 0}
		if pp.y < 0 {pp.y = my} else if pp.y > my {pp.y = 0}
	}

	for &d in dudes {
		cv.canvas_set_dot(pc, d.pos, d.col)
	}

	cv.fade_to_black(pc)

	time.sleep(time.Millisecond * 1)

	return 1 // repaint
}

main :: proc() {
	ca.app.size = {WIDTH, HEIGHT}
	ca.app.create = on_create
	ca.app.update = on_update
	ca.app.destroy = on_destroy
	ca.settings.title = "Diffusion Limited Aggregation"
	ca.settings.window_size = ca.app.size * ZOOM
	ca.run()
}

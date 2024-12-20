#+vet
// https://en.wikipedia.org/wiki/Diffusion-limited_aggregation
package dla

import "base:intrinsics"
import "core:math"
import "core:math/rand"
import "core:os"
import cv "libs:tlc/canvas"
import ca "libs:tlc/canvas_app"
import "shared:obug"

int2 :: cv.int2
uint2 :: cv.uint2
byte4 :: cv.byte4

DIR4 :: false

ZOOM :: 2
WIDTH: i32 : (256 * 3) / ZOOM
HEIGHT: i32 : WIDTH

point_count :: 50000

world_radius :: u32(WIDTH)
world_radius_mask :: world_radius - 1
rh :: world_radius / 2
rl :: (world_radius - 4) / 2
rm :: world_radius - 2

rofs: i32 = 10

map_size :: world_radius * world_radius
dla_map: [map_size]u8
bmp: rawptr
cnt: i32
maxrad, maxrad2, maxrad3: i32
origo := uint2{u32(rh), u32(rh)}

dude_count :: 1 * 100
dude :: struct {
	pos: int2,
	col: byte4,
}
dudes: [dude_count]dude

map_set_dot :: #force_inline proc "contextless" (pos: uint2, val: u8) {
	if pos.x < world_radius && pos.y < world_radius {
		dla_map[pos.y * world_radius + pos.x] = val
	}
}
map_get_dot :: #force_inline proc "contextless" (x, y: u32) -> u8 {
	if x < world_radius && y < world_radius {
		return dla_map[y * world_radius + x]
	}
	return 0
}

map_is_free :: #force_inline proc "contextless" (x, y: u32) -> bool {
	if x < world_radius && y < world_radius {
		return dla_map[y * world_radius + x] == 0
	}
	return true
}

map_check_free4 :: #force_inline proc "contextless" (x, y: u32) -> bool {
	// odinfmt: disable
	return							map_is_free(x  ,y+1) &&
	       map_is_free(x+1,y  ) &&	                        map_is_free(x-1,y  ) &&
	       							map_is_free(x  ,y-1)
	// odinfmt: enable
}

map_check_free8 :: #force_inline proc "contextless" (x, y: u32) -> bool {
	// odinfmt: disable
	return map_is_free(x+1,y+1) &&	map_is_free(x  ,y+1) &&	map_is_free(x-1,y+1) &&
	       map_is_free(x+1,y  ) &&	                        map_is_free(x-1,y  ) &&
	       map_is_free(x+1,y-1) &&	map_is_free(x  ,y-1) &&	map_is_free(x-1,y-1)
	// odinfmt: enable
}

random_position :: #force_inline proc() -> int2 {
	radius := f32(maxrad)
	theta := rand.float32() * math.PI * 2
	x, y := math.cos(theta) * radius, math.sin(theta) * radius
	x, y = math.round(x), math.round(y)
	return int2{i32(x), i32(y)} + transmute(int2)origo
}


on_create :: proc(app: ^ca.application) -> int {
	//fmt.println(#procedure, app)
	pc := &ca.dib.canvas
	for i in 0 ..< map_size {
		dla_map[i] = 0
	}
	map_set_dot(origo, 1)
	cv.canvas_set_dot(pc, origo, cv.COLOR_WHITE)

	cnt = point_count
	//rofs = i32(rl)
	//rofs = i32(world_radius / 8)
	rofs = 10
	maxrad = rofs // + rh div 2;
	maxrad2 = maxrad * maxrad // math.sqr(maxrad)
	i := maxrad + rofs
	maxrad3 = i * i

	//size := ca.dib.canvas.size
	for &d in dudes {
		//d.pos = cv.random_position(size)
		d.pos = random_position()
		d.col = cv.random_color()
	}
	return 0
}

on_destroy :: proc(app: ^ca.application) -> int {
	//fmt.println(#procedure, app)
	return 0
}

when DIR4 {
	get_direction :: cv.get_direction4
	map_check_free :: map_check_free4
} else {
	get_direction :: cv.get_direction8
	map_check_free :: map_check_free8
}

on_update :: proc(app: ^ca.application) -> int {
	pc := &ca.dib.canvas
	pp: ^int2
	dir: int2
	mx, my := i32(pc.size.x - 1), i32(pc.size.y - 1)

	for _ in 0 ..< 16 * 4 {
		for &d in dudes {
			pp = &d.pos
			dir = get_direction(rand.int31_max(8))
			np := pp^ + dir

			dv := np - transmute(int2)origo
			r := dv.x * dv.x + dv.y * dv.y

			if r > maxrad3 {
				d.pos = random_position()
				continue
			}

			if np.x < 0 {np.x = mx} else if np.x > mx {np.x = 0}
			if np.y < 0 {np.y = my} else if np.y > my {np.y = 0}

			if map_check_free(u32(np.x), u32(np.y)) {
				pp^ = np
			} else {
				map_set_dot(transmute(uint2)np, 1)
				//cv.canvas_set_dot(pc, np, d.col)
				cv.canvas_set_dot(pc, np, cv.COLOR_WHITE)

				dv = np - transmute(int2)origo
				r = dv.x * dv.x + dv.y * dv.y
				if r > maxrad2 {
					maxrad = i32(math.round_f32(math.sqrt_f32(f32(r))))
					maxrad2 = maxrad * maxrad
					i := maxrad + rofs
					if i > i32(rl) {
						i = i32(rl)
					}
					maxrad3 = i * i //Sqr(i);
					//fmt.println("hit", maxrad, maxrad2, maxrad3)
				}

				d.pos = random_position()
				d.col = cv.random_color()
			}
		}
	}

	for &d in dudes {
		cv.canvas_set_dot(pc, d.pos, d.col)
	}

	{
		cc := pc.pixel_count
		bp := pc.pvBits
		for i in 0 ..< cc {
			if dla_map[i] == 0 {
				cv.fade_to_black(&bp[i])
			}
		}
	}

	return 0
}

run :: proc() -> (exit_code: int) {
	app := ca.default_application
	app.size = {WIDTH, HEIGHT}
	app.create = on_create
	app.update = on_update
	app.destroy = on_destroy
	app.settings.window_size = app.size * ZOOM
	app.settings.title = "Diffusion Limited Aggregation"
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

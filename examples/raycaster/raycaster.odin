// https://lodev.org/cgtutor/raycasting.html
#+vet
package raycaster

import "base:intrinsics"
import "core:fmt"
import "core:slice"
import "core:math/linalg"
import win32 "core:sys/windows"
import "core:time"
import cv "libs:tlc/canvas"
import ca "libs:tlc/canvas_app"
import "shared:obug"

byte4 :: cv.byte4
int2 :: cv.int2
vector2 :: cv.float2
vector3 :: cv.float3
scalar :: cv.float
matrix2_rotate :: linalg.matrix2_rotate_f32

FPS :: 20
ZOOM :: 4

screenWidth: i32 : (640 * 2) / ZOOM
screenHeight: i32 : screenWidth * 3 / 4

mapWidth: i32 : 24
mapHeight: i32 : 24
worldMapT :: [mapWidth][mapHeight]u8
worldMap: worldMapT

plane_scale: scalar = 0.66

heading: scalar = cv.PI
//pos: vector2 = {22, 11.5}
pos: vector3 = {22, 11.5, 0.5}
dir: vector2
plane: vector2

pitch: scalar = 0 // looking up/down, expressed in screen pixels the horizon shifts
//posZ: scalar = 0.5 // vertical camera strafing up/down, for jumping/crouching. 0 means standard height. Expressed in screen pixels a wall at distance 1 shifts

@(private = "file")
reciprocal_abs_scalar :: #force_inline proc "contextless" (v: scalar) -> scalar {
	return (v == 0) ? 1e30 : abs(1 / v)
}

@(private = "file")
reciprocal_abs_vector :: #force_inline proc "contextless" (v: vector2) -> vector2 {
	return vector2{reciprocal_abs(v.x), reciprocal_abs(v.y)}
}

reciprocal_abs :: proc {
	reciprocal_abs_scalar,
	reciprocal_abs_vector,
}

//arrays used to sort the sprites
sprite_index :: struct {
	sprite: ^Sprite,
	dist:  scalar,
}
sprite_order: [numSprites]sprite_index

init_sprites :: proc() {
	for i in 0 ..< numSprites {
		sprite_order[i] = {&sprites[i], 0}
	}
}

sort_sprites_from_far_to_close :: proc() {
	sprite_sort_by_dist :: proc(l, r: sprite_index) -> bool {
		return l.dist > r.dist
	}
	for &spr_idx in sprite_order {
		dif := pos.xy - spr_idx.sprite.pos
		spr_idx.dist = linalg.dot(dif, dif)
	}
	slice.stable_sort_by(sprite_order[:], sprite_sort_by_dist)
}

// on_create :: proc(app: ca.papp) -> int {
// 	assert(pics_count > 0)
// 	return 0
// }

// on_destroy :: proc(app: ca.papp) -> int {
// 	return 0
// }

handle_input :: proc(app: ca.papp) {
	frameTime := scalar(app.delta)
	//speed modifiers
	moveSpeed := frameTime * 5.0 //the constant value is in squares/second
	rotSpeed := frameTime * 3.0 //the constant value is in radians/second
	keys := &app.keys

	if keys[win32.VK_RIGHT] {
		heading -= rotSpeed
	}
	if keys[win32.VK_LEFT] {
		heading += rotSpeed
	}
	if keys[win32.VK_UP] {
		move := dir * moveSpeed
		if (worldMap[int(pos.x + move.x)][int(pos.y)] == 0) {pos.x += move.x}
		if (worldMap[int(pos.x)][int(pos.y + move.y)] == 0) {pos.y += move.y}
	}
	if keys[win32.VK_DOWN] {
		move := dir * -moveSpeed
		if (worldMap[int(pos.x + move.x)][int(pos.y)] == 0) {pos.x += move.x}
		if (worldMap[int(pos.x)][int(pos.y + move.y)] == 0) {pos.y += move.y}
	}

	if keys[win32.VK_A] {
		pitch -= 1
	}
	if keys[win32.VK_Z] {
		pitch += 1
	}
	if keys[win32.VK_S] {
		pos.z -= 1
	}
	if keys[win32.VK_X] {
		pos.z += 1
	}
}

run_mode : enum {flat, textured, floor, sprites, pitch} : .pitch

run :: proc() {
	fmt.println("Raycaster")
	fmt.printfln("Images: %d x (%dx%d@%d:%d) = %d", pics_count, pics_w, pics_h, pics_ps * 8, pics_byte_size, pics_count * pics_byte_size)
	app :=  ca.default_application
	app.size = {screenWidth, screenHeight}
	when run_mode == .flat {
		//app.create = on_create
		app.update = on_update_raycaster_flat
		worldMap = worldmap_flat
	} else when run_mode == .textured {
		//app.create = on_create
		app.update = on_update_raycaster_textured
		worldMap = worldmap_textured
	} else when run_mode == .floor {
		//app.create = on_create
		app.update = on_update_raycaster_floor
		worldMap = worldmap_floor
	} else when run_mode == .sprites {
		app.create = on_create_raycaster_sprites
		app.update = on_update_raycaster_sprites
		worldMap = worldmap_sprites
	} else when run_mode == .pitch {
		app.create = on_create_raycaster_pitch
		app.update = on_update_raycaster_pitch
		worldMap = worldmap_pitch
	}
	//app.destroy = on_destroy
	app.settings.window_size = app.size * ZOOM
	app.settings.sleep = time.Millisecond * 5
	ca.run(&app)
	fmt.println("Done.")
}

main :: proc() {
	when intrinsics.is_package_imported("obug") {
		obug.exit(obug.tracked_run(run))
	} else {
		run()
	}
}

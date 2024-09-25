#+vet
package raycaster

import "base:intrinsics"
import "core:fmt"
import "core:math/linalg"
import win32 "core:sys/windows"
import "core:time"
import cv "libs:tlc/canvas"
import ca "libs:tlc/canvas_app"

byte4 :: cv.byte4
vector2 :: cv.float2
scalar :: cv.float
matrix2_rotate :: linalg.matrix2_rotate_f32

FPS :: 20
ZOOM :: 4

screenWidth: i32 : (640 * 2) / ZOOM
screenHeight: i32 : screenWidth * 3 / 4

mapWidth: i32 : 24
mapHeight: i32 : 24
worldMapT :: [mapWidth][mapHeight]i32
worldMap: worldMapT

plane_scale: scalar = 0.66

heading: scalar = cv.PI
pos: vector2 = {22, 11.5}
dir: vector2
plane: vector2

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
}

main :: proc() {
	fmt.println("Raycaster")
	fmt.printfln("Images: %d x (%dx%d@%d:%d) = %d", pics_count, pics_w, pics_h, pics_ps * 8, pics_byte_size, pics_count * pics_byte_size)
	ca.app.size = {screenWidth, screenHeight}
	//ca.app.create = on_create
	//ca.app.update = on_update_raycaster_flat;worldMap = worldmap_flat
	//ca.app.update = on_update_raycaster_textured;worldMap = worldmap_textured
	//ca.app.update = on_update_raycaster_floor;worldMap = worldmap_floor
	//ca.app.create = on_create_raycaster_sprites
	//ca.app.update = on_update_raycaster_sprites;worldMap = worldmap_sprites
	ca.app.create = on_create_raycaster_pitch
	ca.app.update = on_update_raycaster_pitch;worldMap = worldmap_pitch
	//ca.app.destroy = on_destroy
	ca.settings.window_size = ca.app.size * ZOOM
	ca.settings.sleep = time.Millisecond * 5
	ca.run()
	fmt.println("Done.")
}

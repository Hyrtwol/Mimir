// https://lodev.org/cgtutor/raycasting2.html
#+vet
package raycaster

import "core:math"
import cv "libs:tlc/canvas"
import ca "libs:tlc/canvas_app"

worldmap_floor: World_Map =
{
	{8,8,8,8,8,8,8,8,8,8,8,4,4,6,4,4,6,4,6,4,4,4,6,4},
	{8,0,0,0,0,0,0,0,0,0,8,4,0,0,0,0,0,0,0,0,0,0,0,4},
	{8,0,3,3,0,0,0,0,0,8,8,4,0,0,0,0,0,0,0,0,0,0,0,6},
	{8,0,0,3,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,6},
	{8,0,3,3,0,0,0,0,0,8,8,4,0,0,0,0,0,0,0,0,0,0,0,4},
	{8,0,0,0,0,0,0,0,0,0,8,4,0,0,0,0,0,6,6,6,0,6,4,6},
	{8,8,8,8,0,8,8,8,8,8,8,4,4,4,4,4,4,6,0,0,0,0,0,6},
	{7,7,7,7,0,7,7,7,7,0,8,0,8,0,8,0,8,4,0,4,0,6,0,6},
	{7,7,0,0,0,0,0,0,7,8,0,8,0,8,0,8,8,6,0,0,0,0,0,6},
	{7,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,8,6,0,0,0,0,0,4},
	{7,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,8,6,0,6,0,6,0,6},
	{7,7,0,0,0,0,0,0,7,8,0,8,0,8,0,8,8,6,4,6,0,6,6,6},
	{7,7,7,7,0,7,7,7,7,8,8,4,0,6,8,4,8,3,3,3,0,3,3,3},
	{2,2,2,2,0,2,2,2,2,4,6,4,0,0,6,0,6,3,0,0,0,0,0,3},
	{2,2,0,0,0,0,0,2,2,4,0,0,0,0,0,0,4,3,0,0,0,0,0,3},
	{2,0,0,0,0,0,0,0,2,4,0,0,0,0,0,0,4,3,0,0,0,0,0,3},
	{1,0,0,0,0,0,0,0,1,4,4,4,4,4,6,0,6,3,3,0,0,0,3,3},
	{2,0,0,0,0,0,0,0,2,2,2,1,2,2,2,6,6,0,0,5,0,5,0,5},
	{2,2,0,0,0,0,0,2,2,2,0,0,0,2,2,0,5,0,5,0,0,0,5,5},
	{2,0,0,0,0,0,0,0,2,0,0,0,0,0,2,5,0,5,0,5,0,5,0,5},
	{1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,5},
	{2,0,0,0,0,0,0,0,2,0,0,0,0,0,2,5,0,5,0,5,0,5,0,5},
	{2,2,0,0,0,0,0,2,2,2,0,0,0,2,2,0,5,0,5,0,0,0,5,5},
	{2,2,2,2,1,2,2,2,2,2,2,1,2,2,2,5,5,5,5,5,5,5,5,5},
}

on_update_raycaster_floor :: proc(app: ^ca.application) -> int {

	handle_input(app)
	// rot := matrix2_rotate(heading)
	// dir = rot[0]
	// plane = rot[1] * -plane_scale

	canvas := &ca.dib.canvas
	cv.canvas_clear(canvas)

	w, h := app.size.x, app.size.y
	h_half := h / 2

	// WALL CASTING
	wm := scalar(w) - 1
	for x in 0 ..< w {
		// calculate ray position and direction
		cameraX := (2 * scalar(x) / wm) - 1 //x-coordinate in camera space
		ray_dir := dir + (plane * cameraX)

		// which box of the map we're in
		mapX, mapY := i32(pos.x), i32(pos.y)

		// length of ray from current position to next x or y-side
		sideDistX, sideDistY: scalar

		// length of ray from one x or y-side to next x or y-side
		// these are derived as:
		// deltaDistX = sqrt(1 + (ray_dir.y * ray_dir.y) / (ray_dir.x * ray_dir.x))
		// which can be simplified to abs(|ray_dir| / ray_dir.x) and abs(|ray_dir| / ray_dir.y)
		// where |ray_dir| is the length of the vector (ray_dir.x, ray_dir.y). Its length,
		// unlike (dir.x, dir.y) is not 1, however this does not matter, only the
		// ratio between deltaDistX and deltaDistY matters, due to the way the DDA
		// stepping further below works. So the values can be computed as below.
		deltaDist := cv.reciprocal_abs(ray_dir)

		// what direction to step in x or y-direction (either +1 or -1)
		stepX, stepY: i32

		// calculate step and initial sideDist
		if ray_dir.x < 0 {
			stepX = -1
			sideDistX = (pos.x - scalar(mapX)) * deltaDist.x
		} else {
			stepX = 1
			sideDistX = (scalar(mapX) + 1 - pos.x) * deltaDist.x
		}
		if ray_dir.y < 0 {
			stepY = -1
			sideDistY = (pos.y - scalar(mapY)) * deltaDist.y
		} else {
			stepY = 1
			sideDistY = (scalar(mapY) + 1 - pos.y) * deltaDist.y
		}

		side: i32 // was a NS or a EW wall hit?
		//perform DDA
		for hit: i32 = 0; hit == 0; {
			//jump to next map square, either in x-direction, or in y-direction
			if sideDistX < sideDistY {
				sideDistX += deltaDist.x
				mapX += stepX
				side = 0
			} else {
				sideDistY += deltaDist.y
				mapY += stepY
				side = 1
			}
			//Check if ray has hit a wall
			if (world_map[mapX][mapY] > 0) {hit = 1}
		}
		//Calculate distance projected on camera direction. This is the shortest distance from the point where the wall is
		//hit to the camera plane. Euclidean to center camera point would give fisheye effect!
		//This can be computed as (mapX - pos.x + (1 - stepX) / 2) / ray_dir.x for side == 0, or same formula with Y
		//for size == 1, but can be simplified to the code below thanks to how sideDist and deltaDist are computed:
		//because they were left scaled to |ray_dir|. sideDist is the entire length of the ray above after the multiple
		//steps, but we subtract deltaDist once because one step more into the wall was taken above.
		perpendicular_wall_distance: scalar = side == 0 ? sideDistX - deltaDist.x : sideDistY - deltaDist.y

		//Calculate height of line to draw on screen
		line_height := (i32)(scalar(h) / perpendicular_wall_distance)
		line_height_half := line_height / 2

		pitch: i32 = 0 //100

		//calculate lowest and highest pixel to fill in current stripe
		drawStart, drawEnd: i32
		drawStart = -line_height_half + h_half
		drawEnd = line_height_half + h_half
		if drawStart < 0 {drawStart = 0}
		if drawEnd >= h {drawEnd = h - 1}

		//texturing calculations
		texNum := world_map[mapX][mapY] - 1 //1 subtracted from it so that texture 0 can be used!
		tex := get_texture(texNum)

		//calculate value of wallX
		wallX: scalar //where exactly the wall was hit
		if side == 0 {wallX = pos.y + perpendicular_wall_distance * ray_dir.y} else {wallX = pos.x + perpendicular_wall_distance * ray_dir.x}
		wallX -= math.floor(wallX)

		//x coordinate on the texture
		texX := i32(wallX * scalar(pics_w))
		if side == 0 && ray_dir.x > 0 {texX = pics_wm - texX}
		if side == 1 && ray_dir.y < 0 {texX = pics_wm - texX}

		// TODO: an integer-only bresenham or DDA like algorithm could make the texture coordinate stepping faster
		// How much to increase the texture coordinate per screen pixel
		step: scalar = scalar(pics_h) / scalar(line_height)
		// Starting texture coordinate
		texPos := scalar(drawStart - pitch - h_half + line_height_half) * step
		for y in drawStart ..< drawEnd {
			// Cast the texture coordinate to integer, and mask with (pics_h - 1) in case of overflow
			texY := i32(texPos) & pics_hm
			texPos += step
			color := tex[pics_w * texY + texX]
			// make color darker for y-sides: R, G and B byte each divided through two with a "shift" and an "and"
			if (side == 1) {color /= 2}
			cv.canvas_set_dot(canvas, x, y, color)
		}

		//FLOOR CASTING
		floorXWall, floorYWall: scalar //x, y position of the floor texel at the bottom of the wall
		//4 different wall directions possible
		if (side == 0) {
			if (ray_dir.x > 0) {
				floorXWall = scalar(mapX)
				floorYWall = scalar(mapY) + wallX
			} else {
				floorXWall = scalar(mapX) + 1.0
				floorYWall = scalar(mapY) + wallX
			}
		} else {
			if (ray_dir.y > 0) {
				floorXWall = scalar(mapX) + wallX
				floorYWall = scalar(mapY)
			} else {
				floorXWall = scalar(mapX) + wallX
				floorYWall = scalar(mapY) + 1.0
			}
		}

		distWall, distPlayer, currentDist: scalar

		distWall = perpendicular_wall_distance
		distPlayer = 0.0

		if (drawEnd < 0) {drawEnd = h} 	//becomes < 0 when the integer overflows

		//draw the floor from drawEnd to the bottom of the screen
		for y in drawEnd + 1 ..< h {
			currentDist = scalar(h) / scalar(2 * y - h) //you could make a small lookup table for this instead

			weight: scalar = (currentDist - distPlayer) / (distWall - distPlayer)

			currentFloorX: scalar = weight * floorXWall + (1.0 - weight) * pos.x
			currentFloorY: scalar = weight * floorYWall + (1.0 - weight) * pos.y

			checkerBoardPattern: i32 = (i32(currentFloorX) + i32(currentFloorY)) & 1
			floorTexture: i32 = checkerBoardPattern == 0 ? 3 : 4

			floorTexX, floorTexY: i32
			floorTexX = i32(currentFloorX * scalar(pics_w)) & pics_wm
			floorTexY = i32(currentFloorY * scalar(pics_h)) & pics_hm
			texIdx := pics_w * floorTexY + floorTexX

			//floor
			cv.canvas_set_dot(canvas, x, y, get_texture_color(floorTexture, texIdx) / 2)
			//ceiling (symmetrical)
			cv.canvas_set_dot(canvas, x, h - y, get_texture_color(6, texIdx))

			// cv.canvas_set_dot(canvas, x, y, sample(&textures[floorTexture], currentFloorX, currentFloorY) / 2)
			// cv.canvas_set_dot(canvas, x, h - y, sample(&textures[6], currentFloorX, currentFloorY))
		}
	}

	return 0
}

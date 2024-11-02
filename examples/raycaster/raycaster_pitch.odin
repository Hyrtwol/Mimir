#+vet
// https://lodev.org/cgtutor/raycasting4.html

package raycaster

import "core:math"
import "core:math/linalg"
import cv "libs:tlc/canvas"
import ca "libs:tlc/canvas_app"

worldmap_pitch: World_Map = {
	{8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 4, 4, 6, 4, 4, 6, 4, 6, 4, 4, 4, 6, 4},
	{8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 8, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4},
	{8, 0, 3, 3, 0, 0, 0, 0, 0, 8, 8, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 6},
	{8, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 6},
	{8, 0, 3, 3, 0, 0, 0, 0, 0, 8, 8, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4},
	{8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 8, 4, 0, 0, 0, 0, 0, 6, 6, 6, 0, 6, 4, 6},
	{8, 8, 8, 8, 0, 8, 8, 8, 8, 8, 8, 4, 4, 4, 4, 4, 4, 6, 0, 0, 0, 0, 0, 6},
	{7, 7, 7, 7, 0, 7, 7, 7, 7, 0, 8, 0, 8, 0, 8, 0, 8, 4, 0, 4, 0, 6, 0, 6},
	{7, 7, 0, 0, 0, 0, 0, 0, 7, 8, 0, 8, 0, 8, 0, 8, 8, 6, 0, 0, 0, 0, 0, 6},
	{7, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 8, 6, 0, 0, 0, 0, 0, 4},
	{7, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 8, 6, 0, 6, 0, 6, 0, 6},
	{7, 7, 0, 0, 0, 0, 0, 0, 7, 8, 0, 8, 0, 8, 0, 8, 8, 6, 4, 6, 0, 6, 6, 6},
	{7, 7, 7, 7, 0, 7, 7, 7, 7, 8, 8, 4, 0, 6, 8, 4, 8, 3, 3, 3, 0, 3, 3, 3},
	{2, 2, 2, 2, 0, 2, 2, 2, 2, 4, 6, 4, 0, 0, 6, 0, 6, 3, 0, 0, 0, 0, 0, 3},
	{2, 2, 0, 0, 0, 0, 0, 2, 2, 4, 0, 0, 0, 0, 0, 0, 4, 3, 0, 0, 0, 0, 0, 3},
	{2, 0, 0, 0, 0, 0, 0, 0, 2, 4, 0, 0, 0, 0, 0, 0, 4, 3, 0, 0, 0, 0, 0, 3},
	{1, 0, 0, 0, 0, 0, 0, 0, 1, 4, 4, 4, 4, 4, 6, 0, 6, 3, 3, 0, 0, 0, 3, 3},
	{2, 0, 0, 0, 0, 0, 0, 0, 2, 2, 2, 1, 2, 2, 2, 6, 6, 0, 0, 5, 0, 5, 0, 5},
	{2, 2, 0, 0, 0, 0, 0, 2, 2, 2, 0, 0, 0, 2, 2, 0, 5, 0, 5, 0, 0, 0, 5, 5},
	{2, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 2, 5, 0, 5, 0, 5, 0, 5, 0, 5},
	{1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 5},
	{2, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 2, 5, 0, 5, 0, 5, 0, 5, 0, 5},
	{2, 2, 0, 0, 0, 0, 0, 2, 2, 2, 0, 0, 0, 2, 2, 0, 5, 0, 5, 0, 0, 0, 5, 5},
	{2, 2, 2, 2, 1, 2, 2, 2, 2, 2, 2, 1, 2, 2, 2, 5, 5, 5, 5, 5, 5, 5, 5, 5},
}

on_create_raycaster_pitch :: proc(app: ^ca.application) -> int {
	assert(len(textures) > 0)
	init_sprites()
	return 0
}

on_update_raycaster_pitch :: proc(app: ^ca.application) -> int {

	rot := matrix2_rotate(heading)
	dir = rot[0]
	plane = rot[1] * -plane_scale

	canvas := &ca.dib.canvas
	cv.canvas_clear(canvas)

	w, h := app.size.x, app.size.y
	w_half, h_half := scalar(w) / 2, scalar(h) / 2

	// WALL CASTING
	wm := scalar(w) - 1
	for x in 0 ..< w {
		// calculate ray position and direction
		cameraX := (2 * scalar(x) / wm) - 1 // x-coordinate in camera space -1 to 1
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
		line_height := scalar(h) / perpendicular_wall_distance
		line_height_half := line_height / 2

		//calculate lowest and highest pixel to fill in current stripe
		drawStart, drawEnd: i32
		{
			drawStart = i32(-line_height_half + h_half + pitch + (pos.z / perpendicular_wall_distance))
			drawEnd = i32(line_height_half + h_half + pitch + (pos.z / perpendicular_wall_distance))
			if drawStart < 0 {drawStart = 0}
			if drawEnd >= h {drawEnd = h - 1}
		}

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
		step: scalar = scalar(pics_h) / line_height
		// Starting texture coordinate
		texPos := (scalar(drawStart) - pitch - (pos.z / perpendicular_wall_distance) - h_half + line_height_half) * step
		for y in drawStart ..= drawEnd {
			// Cast the texture coordinate to integer, and mask with (pics_h - 1) in case of overflow
			texY := i32(texPos) & pics_hm
			texPos += step
			color := tex[pics_w * texY + texX]
			//color := sample(tex, texX, texY)
			// make color darker for y-sides: R, G and B byte each divided through two with a "shift" and an "and"
			if (side == 1) {color /= 2}
			cv.canvas_set_dot(canvas, x, y, color)
		}

		//FLOOR CASTING
		floor_wall: vector2 //x, y position of the floor texel at the bottom of the wall
		//4 different wall directions possible
		if (side == 0) {
			if (ray_dir.x > 0) {
				floor_wall = {scalar(mapX), scalar(mapY) + wallX}
			} else {
				floor_wall = {scalar(mapX) + 1, scalar(mapY) + wallX}
			}
		} else {
			if (ray_dir.y > 0) {
				floor_wall = {scalar(mapX) + wallX, scalar(mapY)}
			} else {
				floor_wall = {scalar(mapX) + wallX, scalar(mapY) + 1}
			}
		}

		distWall, distPlayer, currentDist: scalar

		distWall = perpendicular_wall_distance
		distPlayer = 0.0

		if (drawEnd < 0) {drawEnd = h} 	//becomes < 0 when the integer overflows

		currentFloor: vector2

		//ceiling
		for y in 0 ..< drawStart {
			currentDist = (scalar(h) - (2 * pos.z)) / (scalar(h) - 2 * (scalar(y) - pitch))
			weight := (currentDist - distPlayer) / (distWall - distPlayer)
			currentFloor = linalg.lerp(pos.xy, floor_wall, weight)
			texIdx := texture_index(currentFloor)
			cv.canvas_set_dot(canvas, x, y, get_texture_color(6, texIdx))
		}

		//floor
		for y in drawEnd + 1 ..< h {
			currentDist = (scalar(h) + (2 * pos.z)) / (2 * (scalar(y) - pitch) - scalar(h))
			weight := (currentDist - distPlayer) / (distWall - distPlayer)
			currentFloor = linalg.lerp(pos.xy, floor_wall, weight)
			// currentFloor *= 2
			floorTexture: i32 = ((i32(currentFloor.x) + i32(currentFloor.y)) & 1) + 3 // checkerBoardPattern
			texIdx := texture_index(currentFloor)
			cv.canvas_set_dot(canvas, x, y, get_texture_color(floorTexture, texIdx) / 2)
		}

		//SET THE ZBUFFER FOR THE SPRITE CASTING
		z_buffer[x] = perpendicular_wall_distance
	}

	//SPRITE CASTING
	sort_sprites_from_far_to_close()

	//after sorting the sprites, do the projection and draw them
	for &spr_idx in sprite_order {
		//translate sprite position to relative to camera
		spr := spr_idx.sprite
		sprimg := get_texture(spr.texture)
		sprpos := spr.pos - pos.xy

		//transform sprite with the inverse camera matrix
		// [ plane.x   dir.x ] -1                                           [  dir.y    -dir.x   ]
		// [                 ]       =  1/(plane.x*dir.y-dir.x*plane.y) *   [                    ]
		// [ plane.y   dir.y ]                                              [ -plane.y   plane.x ]

		invDet: scalar = 1 / (plane.x * dir.y - dir.x * plane.y) //required for correct matrix multiplication

		transformX := invDet * (dir.y * sprpos.x - dir.x * sprpos.y)
		transformY := invDet * (-plane.y * sprpos.x + plane.x * sprpos.y) //this is actually the depth inside the screen, that what Z is in 3D, the distance of sprite to player, matching sqrt(spriteDistance[i])

		spriteScreenX := i32(w_half * (1 + transformX / transformY))

		//parameters for scaling and moving the sprites
		uDiv :: 1
		vDiv :: 1
		vMove :: 0
		vMoveScreen := i32(vMove / transformY + pitch + pos.z / transformY)

		//calculate height of the sprite on screen
		spriteHeight: i32 = abs(i32(scalar(h) / transformY)) / vDiv //using "transformY" instead of the real distance prevents fisheye
		//calculate lowest and highest pixel to fill in current stripe
		drawStartY: i32 = -spriteHeight / 2 + h / 2 + vMoveScreen
		if (drawStartY < 0) {drawStartY = 0}
		drawEndY: i32 = spriteHeight / 2 + h / 2 + vMoveScreen
		if (drawEndY >= h) {drawEndY = h - 1}

		//calculate width of the sprite
		spriteWidth: i32 = abs(i32(scalar(h) / transformY)) / uDiv // same as height of sprite, given that it's square
		drawStartX := -spriteWidth / 2 + spriteScreenX
		if (drawStartX < 0) {drawStartX = 0}
		drawEndX := spriteWidth / 2 + spriteScreenX
		if (drawEndX > w) {drawEndX = w}

		//loop through every vertical stripe of the sprite on screen
		for stripe in drawStartX ..< drawEndX {
			texX := (256 * (stripe - (-spriteWidth / 2 + spriteScreenX)) * pics_w / spriteWidth) / 256
			texX &= pics_wm // avoid random crash
			//the conditions in the if are:
			//1) it's in front of camera plane so you don't see things behind you
			//2) it's on the screen (left)
			//3) it's on the screen (right)
			//4) z_buffer, with perpendicular distance
			if transformY > 0 && stripe > 0 && stripe < w && transformY < z_buffer[stripe] {
				for y in drawStartY ..< drawEndY { 	//for every pixel of the current stripe
					d := (y - vMoveScreen) * 256 - h * 128 + spriteHeight * 128 //256 and 128 factors to avoid floats
					texY := ((d * pics_h) / spriteHeight) / 256
					texY &= pics_hm // avoid random crash
					color := sprimg[pics_w * texY + texX] //get current color from the texture
					//paint pixel if it isn't black, black is the invisible color
					if color.a > 127 {
						cv.canvas_set_dot(canvas, stripe, y, color)
					}
				}
			}
		}
	}

	handle_input(app)
	return 0
}

// https://lodev.org/cgtutor/raycasting4.html
#+vet
package raycaster

import "core:math"
import "core:slice"
import "core:math/linalg"
import cv "libs:tlc/canvas"
import ca "libs:tlc/canvas_app"

worldmap_pitch: worldMapT = {
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

on_create_raycaster_pitch :: proc(app: ca.papp) -> int {
	assert(pics_count > 0)
	for i in 0 ..< numSprites {
		sprite_order[i] = {&sprite[i], 0}
	}
	return 0
}

on_update_raycaster_pitch :: proc(app: ca.papp) -> int {

	rot := matrix2_rotate(heading)
	dir = rot[0]
	plane = rot[1] * -plane_scale

	canvas := &ca.dib.canvas
	cv.canvas_clear(canvas)

	w, h := app.size.x, app.size.y
	h_half := h / 2

	// WALL CASTING
	wm := scalar(w) //- 1
	for x in 0 ..< w {
		// calculate ray position and direction
		cameraX := (2 * scalar(x) / wm) - 1 //x-coordinate in camera space
		rayDir := dir + (plane * cameraX)

		// which box of the map we're in
		mapX, mapY := i32(pos.x), i32(pos.y)

		// length of ray from current position to next x or y-side
		sideDistX, sideDistY: scalar

		// length of ray from one x or y-side to next x or y-side
		// these are derived as:
		// deltaDistX = sqrt(1 + (rayDirY * rayDirY) / (rayDirX * rayDirX))
		// deltaDistY = sqrt(1 + (rayDirX * rayDirX) / (rayDirY * rayDirY))
		// which can be simplified to abs(|rayDir| / rayDirX) and abs(|rayDir| / rayDirY)
		// where |rayDir| is the length of the vector (rayDirX, rayDirY). Its length,
		// unlike (dir.x, dir.y) is not 1, however this does not matter, only the
		// ratio between deltaDistX and deltaDistY matters, due to the way the DDA
		// stepping further below works. So the values can be computed as below.
		deltaDist := reciprocal_abs(rayDir)
		//perpWallDist: scalar

		// what direction to step in x or y-direction (either +1 or -1)
		stepX, stepY: i32

		hit: i32 = 0 // was there a wall hit?
		side: i32 // was a NS or a EW wall hit?

		// calculate step and initial sideDist
		if rayDir.x < 0 {
			stepX = -1
			sideDistX = (pos.x - scalar(mapX)) * deltaDist.x
		} else {
			stepX = 1
			sideDistX = (scalar(mapX) + 1.0 - pos.x) * deltaDist.x
		}
		if rayDir.y < 0 {
			stepY = -1
			sideDistY = (pos.y - scalar(mapY)) * deltaDist.y
		} else {
			stepY = 1
			sideDistY = (scalar(mapY) + 1.0 - pos.y) * deltaDist.y
		}
		//perform DDA
		for hit == 0 {
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
			if (worldMap[mapX][mapY] > 0) {hit = 1}
		}
		//Calculate distance projected on camera direction. This is the shortest distance from the point where the wall is
		//hit to the camera plane. Euclidean to center camera point would give fisheye effect!
		//This can be computed as (mapX - pos.x + (1 - stepX) / 2) / rayDirX for side == 0, or same formula with Y
		//for size == 1, but can be simplified to the code below thanks to how sideDist and deltaDist are computed:
		//because they were left scaled to |rayDir|. sideDist is the entire length of the ray above after the multiple
		//steps, but we subtract deltaDist once because one step more into the wall was taken above.
		perpWallDist: scalar = side == 0 ? sideDistX - deltaDist.x : sideDistY - deltaDist.y

		//Calculate height of line to draw on screen
		lineHeight := scalar(h) / perpWallDist
		lineHeight_half := lineHeight / 2

		// pitch :: 0.5 //100

		//calculate lowest and highest pixel to fill in current stripe
		//drawStart := i32(-lineHeight_half + scalar(h_half))
		drawStart := i32(-lineHeight_half + scalar(h_half) + pitch + (posZ / perpWallDist))
		if drawStart < 0 {drawStart = 0}
		//drawEnd := i32(lineHeight_half + scalar(h_half))
		drawEnd := i32(lineHeight_half + scalar(h_half) + pitch + (posZ / perpWallDist))
		if drawEnd >= h {drawEnd = h - 1}

		//texturing calculations
		texNum := worldMap[mapX][mapY] - 1 //1 subtracted from it so that texture 0 can be used!
		tex := textures[texNum]

		//calculate value of wallX
		wallX: scalar //where exactly the wall was hit
		if side == 0 {wallX = pos.y + perpWallDist * rayDir.y} else {wallX = pos.x + perpWallDist * rayDir.x}
		wallX -= math.floor(wallX)

		//x coordinate on the texture
		texX := i32(wallX * scalar(pics_w))
		if side == 0 && rayDir.x > 0 {texX = pics_wm - texX}
		if side == 1 && rayDir.y < 0 {texX = pics_wm - texX}

		// TODO: an integer-only bresenham or DDA like algorithm could make the texture coordinate stepping faster
		// How much to increase the texture coordinate per screen pixel
		step : scalar = scalar(pics_h) / scalar(lineHeight)
		// Starting texture coordinate
		//texPos := (scalar(drawStart) - scalar(pitch) - scalar(h_half) + lineHeight_half) * step
		//texPos := (scalar(drawStart) - pitch - scalar(h_half) + lineHeight_half) * step
		texPos := (scalar(drawStart) - pitch - (posZ / perpWallDist) - scalar(h_half) + lineHeight_half) * step
		texPos += 0.01
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
		floorWall: vector2 //x, y position of the floor texel at the bottom of the wall
		//4 different wall directions possible
		if (side == 0) {
			if (rayDir.x > 0) {
				floorWall = {scalar(mapX), scalar(mapY) + wallX}
			} else {
				floorWall = {scalar(mapX) + 1.0, scalar(mapY) + wallX}
			}
		} else {
			if (rayDir.y > 0) {
				floorWall = {scalar(mapX) + wallX, scalar(mapY)}
			} else {
				floorWall = {scalar(mapX) + wallX, scalar(mapY) + 1.0}
			}
		}

		distWall, distPlayer, currentDist: scalar

		distWall = perpWallDist
		distPlayer = 0.0

		if (drawEnd < 0) {drawEnd = h} 	//becomes < 0 when the integer overflows

		currentFloor : vector2

		for y in 0 ..< drawStart {
			currentDist = (scalar(h) - (2 * posZ)) / (scalar(h) - 2 * (scalar(y) - pitch))

			weight: scalar = (currentDist - distPlayer) / (distWall - distPlayer)

			currentFloor = linalg.lerp(pos, floorWall, weight)
			texIdx := texture_index(currentFloor)

			//ceiling
			cv.canvas_set_dot(canvas, x, y, textures[6][texIdx])
		}

		for y in drawEnd + 1 ..< h {
			currentDist = (scalar(h) + (2 * posZ)) / (2 * (scalar(y) - pitch) - scalar(h))

			weight: scalar = (currentDist - distPlayer) / (distWall - distPlayer)

			currentFloor = linalg.lerp(pos, floorWall, weight)
			texIdx := texture_index(currentFloor)

			checkerBoardPattern: i32 = (i32(currentFloor.x) + i32(currentFloor.y)) & 1
			floorTexture: i32 = checkerBoardPattern == 0 ? 3 : 4

			//floor
			cv.canvas_set_dot(canvas, x, y, textures[floorTexture][texIdx] / 2)
		}

		//SET THE ZBUFFER FOR THE SPRITE CASTING
		ZBuffer[x] = perpWallDist //perpendicular distance is used
	}

	//SPRITE CASTING
	//sort sprites from far to close
	for &spr_idx in sprite_order {
		dif := pos - spr_idx.sprite.pos
		spr_idx.dist = linalg.dot(dif, dif)
	}
	slice.stable_sort_by(sprite_order[:], sprite_sort)

	//after sorting the sprites, do the projection and draw them
	for &spr_idx in sprite_order {
		//translate sprite position to relative to camera
		spr := spr_idx.sprite
		sprimg := textures[spr.texture]
		sprpos := spr.pos - pos

		//transform sprite with the inverse camera matrix
		// [ planeX   dirX ] -1                                       [ dirY      -dirX ]
		// [               ]       =  1/(planeX*dirY-dirX*planeY) *   [                 ]
		// [ planeY   dirY ]                                          [ -planeY  planeX ]

		invDet := 1 / scalar(plane.x * dir.y - dir.x * plane.y) //required for correct matrix multiplication

		transformX := scalar(invDet * (dir.y * sprpos.x - dir.x * sprpos.y))
		transformY := scalar(invDet * (-plane.y * sprpos.x + plane.x * sprpos.y)) //this is actually the depth inside the screen, that what Z is in 3D, the distance of sprite to player, matching sqrt(spriteDistance[i])

		spriteScreenX := i32((scalar(w) / 2) * (1 + transformX / transformY))

		//parameters for scaling and moving the sprites
		uDiv :: 1
		vDiv :: 1
		vMove :: 0
		vMoveScreen := i32(vMove / transformY + pitch + posZ / transformY)

		//calculate height of the sprite on screen
		spriteHeight: i32 = abs(i32(scalar(h) / transformY)) / vDiv //using "transformY" instead of the real distance prevents fisheye
		//calculate lowest and highest pixel to fill in current stripe
		drawStartY := i32(-spriteHeight / 2 + h / 2 + vMoveScreen)
		if (drawStartY < 0) {drawStartY = 0}
		drawEndY := i32(spriteHeight / 2 + h / 2 + vMoveScreen)
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
			//4) ZBuffer, with perpendicular distance
			if (transformY > 0 && stripe > 0 && stripe < w && transformY < ZBuffer[stripe]) {
				for y in drawStartY ..< drawEndY { 	//for every pixel of the current stripe
					d := (y - vMoveScreen) * 256 - h * 128 + spriteHeight * 128 //256 and 128 factors to avoid floats
					texY := ((d * pics_h) / spriteHeight) / 256
					texY &= pics_hm // avoid random crash
					color := sprimg[pics_w * texY + texX] //get current color from the texture
					//paint pixel if it isn't black, black is the invisible color
					if color.a > 0 {
						cv.canvas_set_dot(canvas, stripe, y, color)
					}
				}
			}
		}
	}

	handle_input(app)
	return 0
}

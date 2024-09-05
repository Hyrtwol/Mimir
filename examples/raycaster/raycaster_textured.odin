// +vet
package raycaster

import "core:math"
import cv "libs:tlc/canvas"
import ca "libs:tlc/canvas_app"

worldmap_textured: worldMapT =
{
	{4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,7,7,7,7,7,7,7,7},
	{4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,7,0,0,0,0,0,0,7},
	{4,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,7},
	{4,0,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,7},
	{4,0,3,0,0,0,0,0,0,0,0,0,0,0,0,0,7,0,0,0,0,0,0,7},
	{4,0,4,0,0,0,0,5,5,5,5,5,5,5,5,5,7,7,0,7,7,7,7,7},
	{4,0,5,0,0,0,0,5,0,5,0,5,0,5,0,5,7,0,0,0,7,7,7,1},
	{4,0,6,0,0,0,0,5,0,0,0,0,0,0,0,5,7,0,0,0,0,0,0,8},
	{4,0,7,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,7,7,7,1},
	{4,0,8,0,0,0,0,5,0,0,0,0,0,0,0,5,7,0,0,0,0,0,0,8},
	{4,0,0,0,0,0,0,5,0,0,0,0,0,0,0,5,7,0,0,0,7,7,7,1},
	{4,0,0,0,0,0,0,5,5,5,5,0,5,5,5,5,7,7,7,7,7,7,7,1},
	{6,6,6,6,6,6,6,6,6,6,6,0,6,6,6,6,6,6,6,6,6,6,6,6},
	{8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,4},
	{6,6,6,6,6,6,0,6,6,6,6,0,6,6,6,6,6,6,6,6,6,6,6,6},
	{4,4,4,4,4,4,0,4,4,4,6,0,6,2,2,2,2,2,2,2,3,3,3,3},
	{4,0,0,0,0,0,0,0,0,4,6,0,6,2,0,0,0,0,0,2,0,0,0,2},
	{4,0,0,0,0,0,0,0,0,0,0,0,6,2,0,0,5,0,0,2,0,0,0,2},
	{4,0,0,0,0,0,0,0,0,4,6,0,6,2,0,0,0,0,0,2,2,0,2,2},
	{4,0,6,0,6,0,0,0,0,4,6,0,0,0,0,0,5,0,0,0,0,0,0,2},
	{4,0,0,5,0,0,0,0,0,4,6,0,6,2,0,0,0,0,0,2,2,0,2,2},
	{4,0,6,0,6,0,0,0,0,4,6,0,6,2,0,0,5,0,0,2,0,0,0,2},
	{4,0,0,0,0,0,0,0,0,4,6,0,6,2,0,0,0,0,0,2,0,0,0,2},
	{4,4,4,4,4,4,4,4,4,4,1,1,1,2,2,2,2,2,2,3,3,3,3,3},
}

on_update_raycaster_textured :: proc(app: ca.papp) -> int {

	rot := matrix2_rotate(heading)
	dir = rot[0]
	plane = rot[1] * -plane_scale

	canvas := &ca.dib.canvas
	cv.canvas_clear(canvas)

	w, h := app.size.x, app.size.y
	h_half := h / 2

	wm := scalar(w) - 1
	for x in 0 ..< w {
		// calculate ray position and direction
		cameraX := (2 * scalar(x) / wm) - 1 //f64(w) - 1; //x-coordinate in camera space
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
		//  Division through zero is prevented, even though technically that's not
		//  needed in C++ with IEEE 754 floating point values.
		// deltaDistX := reciprocal_abs(rayDir.x)
		// deltaDistY := reciprocal_abs(rayDir.y)
		deltaDist := vector2{reciprocal_abs(rayDir.x), reciprocal_abs(rayDir.y)}
		perpWallDist: scalar

		// what direction to step in x or y-direction (either +1 or -1)
		stepX, stepY: i32

		hit: i32 = 0 // was there a wall hit?
		side: i32 // was a NS or a EW wall hit?

		// calculate step and initial sideDist
		if (rayDir.x < 0) {
			stepX = -1
			sideDistX = (pos.x - scalar(mapX)) * deltaDist.x
		} else {
			stepX = 1
			sideDistX = (scalar(mapX) + 1.0 - pos.x) * deltaDist.x
		}
		if (rayDir.y < 0) {
			stepY = -1
			sideDistY = (pos.y - scalar(mapY)) * deltaDist.y
		} else {
			stepY = 1
			sideDistY = (scalar(mapY) + 1.0 - pos.y) * deltaDist.y
		}
		//perform DDA
		for hit == 0 {
			//jump to next map square, either in x-direction, or in y-direction
			if (sideDistX < sideDistY) {
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
		if (side == 0) {perpWallDist = (sideDistX - deltaDist.x)} else {perpWallDist = (sideDistY - deltaDist.y)}

		//Calculate height of line to draw on screen
		lineHeight := (i32)(scalar(h) / perpWallDist)
		lineHeight_half := lineHeight / 2

		pitch: i32 = 0 //100

		//calculate lowest and highest pixel to fill in current stripe
		drawStart := -lineHeight_half + h_half
		if (drawStart < 0) {drawStart = 0}
		drawEnd := lineHeight_half + h_half
		if (drawEnd >= h) {drawEnd = h - 1}

		//texturing calculations
		texNum := worldMap[mapX][mapY] - 1 //1 subtracted from it so that texture 0 can be used!
		tex := textures[texNum]

		//calculate value of wallX
		wallX: scalar //where exactly the wall was hit
		if (side == 0) {wallX = pos.y + perpWallDist * rayDir.y} else {wallX = pos.x + perpWallDist * rayDir.x}
		wallX -= math.floor(wallX)

		//x coordinate on the texture
		texX := i32(wallX * scalar(pics_w))
		if (side == 0 && rayDir.x > 0) {texX = pics_w - texX - 1}
		if (side == 1 && rayDir.y < 0) {texX = pics_w - texX - 1}

		// TODO: an integer-only bresenham or DDA like algorithm could make the texture coordinate stepping faster
		// How much to increase the texture coordinate per screen pixel
		step: scalar = scalar(pics_h) / scalar(lineHeight)
		// Starting texture coordinate
		texPos := scalar(drawStart - pitch - h_half + lineHeight_half) * step
		//for(int y = drawStart; y < drawEnd; y++)
		for y in drawStart ..< drawEnd {
			// Cast the texture coordinate to integer, and mask with (pics_h - 1) in case of overflow
			texY := i32(texPos) & (pics_h - 1)
			texPos += step
			color := tex[pics_w * texY + texX]
			//make color darker for y-sides: R, G and B byte each divided through two with a "shift" and an "and"
			if (side == 1) {color /= 2}
			cv.canvas_set_dot(canvas, x, y, color)
		}
	}

	handle_input(app)
	return 0
}

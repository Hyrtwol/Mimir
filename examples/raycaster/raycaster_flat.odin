// https://lodev.org/cgtutor/raycasting.html
#+vet
package raycaster

import cv "libs:tlc/canvas"
import ca "libs:tlc/canvas_app"

worldmap_flat: World_Map =
{
	{1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},
	{1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
	{1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
	{1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
	{1,0,0,0,0,0,2,2,2,2,2,0,0,0,0,3,0,3,0,3,0,0,0,1},
	{1,0,0,0,0,0,2,0,0,0,2,0,0,0,0,0,0,0,0,0,0,0,0,1},
	{1,0,0,0,0,0,2,0,0,0,2,0,0,0,0,3,0,0,0,3,0,0,0,1},
	{1,0,0,0,0,0,2,0,0,0,2,0,0,0,0,0,0,0,0,0,0,0,0,1},
	{1,0,0,0,0,0,2,2,0,2,2,0,0,0,0,3,0,3,0,3,0,0,0,1},
	{1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
	{1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
	{1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
	{1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
	{1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,3,0,0,0,1},
	{1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,3,3,0,0,1},
	{1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
	{1,4,4,4,4,4,4,4,4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
	{1,4,0,4,0,0,0,0,4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
	{1,4,0,0,0,0,5,0,4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
	{1,4,0,4,0,0,0,0,4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
	{1,4,0,4,4,4,4,4,4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
	{1,4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
	{1,4,4,4,4,4,4,4,4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
	{1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},
}

on_update_raycaster_flat :: proc(app: ^ca.application) -> int {

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
		line_height := (i32)(scalar(h) / perpendicular_wall_distance)
		line_height_half := line_height / 2

		//calculate lowest and highest pixel to fill in current stripe
		drawStart, drawEnd: i32
		{
			drawStart = -line_height_half + h_half
			drawEnd = line_height_half + h_half
			if drawStart < 0 {drawStart = 0}
			if drawEnd >= h {drawEnd = h - 1}
		}

		//choose wall color
		color: byte4
		switch (world_map[mapX][mapY])
		{
		case 1:
			color = cv.COLOR_RED
		case 2:
			color = cv.COLOR_GREEN
		case 3:
			color = cv.COLOR_BLUE
		case 4:
			color = cv.COLOR_WHITE
		case:
			color = cv.COLOR_YELLOW
		}

		//give x and y sides different brightness
		if side == 1 {color = color / 2}

		//draw the pixels of the stripe as a vertical line
		cv.draw_vline(canvas, x, drawStart, drawEnd, color)
	}

	return 0
}

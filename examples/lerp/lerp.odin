package main

import "vendor:raylib"
import "core:reflect"
import "core:fmt"
import "core:strings"
import "core:math"
import "core:math/linalg"
import "core:math/ease"

main :: proc() {
	WINDOW_X :: 800
	WINDOW_Y :: 480
	raylib.InitWindow(
		WINDOW_X,
		WINDOW_Y,
		"Interpolation example. Use left and right arrows to cycle between interpolation modes.",
	)

	SPEED :: 0.5


	// 0.0 .. 1.0
	timer: f32 = 0.0
	e := ease.Ease.Linear

	for !raylib.WindowShouldClose() {
		delta_time := raylib.GetFrameTime()

		// Cycle between easing functions
		if raylib.IsKeyPressed(.LEFT) {
			e = ease.Ease((int(e) - 1) %% len(ease.Ease))
			timer = 0
		}

		if raylib.IsKeyPressed(.RIGHT) {
			e = ease.Ease((int(e) + 1) %% len(ease.Ease))
			timer = 0
		}

		if raylib.IsKeyPressed(.SPACE) {
			timer = 0
		}

		// Increment the timer
		timer = clamp(timer + SPEED * delta_time, 0.0, 1.0)

		val := ease.ease(e, timer)

		raylib.BeginDrawing()
		raylib.ClearBackground({45, 40, 60, 255})

		NUM_POINTS :: 256
		Y_MORE :: 0.15
		for i in 0 ..< NUM_POINTS - 1 {
			x := f32(i) / NUM_POINTS
			y := 1.0 - Y_MORE - ease.ease(e, x) * (1.0 - Y_MORE * 2)
			x_next := f32(i + 1) / NUM_POINTS
			y_next := 1.0 - Y_MORE - ease.ease(e, x_next) * (1.0 - Y_MORE * 2)
			raylib.DrawLineEx(
				{x * WINDOW_X, y * WINDOW_Y},
				{x_next * WINDOW_X, y_next * WINDOW_Y},
				5.0,
				{200, 200, 220, 100},
			)
		}

		raylib.DrawLineEx({0, Y_MORE * WINDOW_Y}, {WINDOW_X, Y_MORE * WINDOW_Y}, 2.0, {200, 200, 220, 50})
		raylib.DrawLineEx(
			{0, (1.0 - Y_MORE) * WINDOW_Y},
			{WINDOW_X, (1.0 - Y_MORE) * WINDOW_Y},
			2.0,
			{200, 200, 220, 50},
		)

		raylib.DrawCircleV({val * WINDOW_X, WINDOW_Y * 0.5}, 40, raylib.RED)

		raylib.DrawText(
			text = strings.clone_to_cstring(
				fmt.tprint("Easing function: <", reflect.enum_string(e), ">"),
				context.temp_allocator,
			),
			posX = 5,
			posY = 5,
			fontSize = 20,
			color = raylib.WHITE,
		)

		raylib.EndDrawing()
	}

	raylib.CloseWindow()
}

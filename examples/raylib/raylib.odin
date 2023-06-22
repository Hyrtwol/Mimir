package main

import rl "vendor:raylib"

main :: proc() {
	W :: 600
	H :: 400

	rl.InitWindow(W, H, "Window")
	render_texture := rl.LoadRenderTexture(W, H)

	for !rl.WindowShouldClose() {
		rl.BeginTextureMode(render_texture)
		rl.DrawRectangle(32, 32, 32, 32, rl.WHITE)
		rl.EndTextureMode()

		rl.BeginDrawing()
		rl.ClearBackground(rl.GetColor(0))
		rl.DrawTexturePro(render_texture.texture, {0, 0, W, H}, {0, 0, W, H}, {0, 0}, 0, rl.WHITE)
		rl.EndDrawing()
	}
}

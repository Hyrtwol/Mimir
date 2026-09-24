package textures

import "core:image"
import "core:image/png"
import "core:image/tga"

_ :: png
_ :: tga

texture_def :: struct {
	size: [2]i32,
	data: []u8,
}

create_textures :: proc() -> (texture_data: [dynamic]texture_def, err: image.Error) {
	texture_data = make([dynamic]texture_def, 0, 0) or_return
	return
}

delete_textures :: proc(texture_data: [dynamic]texture_def) {
	for td in texture_data {delete(td.data)}
	delete(texture_data)
}

load_texture_from_image :: proc(img: ^image.Image) -> (tex_def: texture_def, err: image.Error) {
	tex_def.size = {i32(img.width), i32(img.height)}
	tex_def.data = make([]u8, len(img.pixels.buf))
	copy(tex_def.data, img.pixels.buf[:])
	return
}

load_texture_from_bytes :: proc(data: []u8, options := image.Options{.alpha_add_if_missing}) -> (tex_def: texture_def, err: image.Error) {
	img := image.load_from_bytes(data, options) or_return
	defer image.destroy(img)
	tex_def = load_texture_from_image(img) or_return
	return
}

load_texture_data :: proc(texture_data: ^[dynamic]texture_def, image_data: [][]u8) -> (err: image.Error) {
	for data in image_data {
		tex_def := load_texture_from_bytes(data) or_return
		append(texture_data, tex_def) or_return
	}
	return
}

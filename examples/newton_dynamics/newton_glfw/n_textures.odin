package newton_glfw

import "core:fmt"
import "core:image"
import "core:image/png"
import newton "shared:newton_dynamics"

_ :: png
_ :: newton

@(private = "file")
image_file_bytes := [?][]u8 {
	#load("../../../data/images/floor_d01.png"),
	#load("../../../data/images/uv_checker_x.png"),
	#load("../../../data/images/uv_checker_y.png"),
	#load("../../../data/images/uv_checker_z.png"),
	#load("../../../data/images/uv_checker_w.png"),
}

@(private = "file")
image_count :: len(image_file_bytes)

texture_def :: struct {
	size: [2]i32,
	data: []u8,
}

load_texture_data :: proc(texture_data: ^[dynamic]texture_def) {
	options := image.Options{.alpha_add_if_missing}
	for ti in 0 ..< image_count {
		img: ^image.Image
		err: image.Error

		img, err = image.load_from_bytes(image_file_bytes[ti], options)
		if err != nil {
			fmt.println("ERROR: Image:", "failed to load.")
			return
		}
		defer image.destroy(img)

		// Copy bytes from icon buffer into slice.
		data := make([]u8, len(img.pixels.buf))
		for b, i in img.pixels.buf {
			data[i] = b
		}

		tex_def := texture_def {
			size = {i32(img.width), i32(img.height)},
			data = data,
		}
		append(texture_data, tex_def)
	}
}

create_textures :: proc() {

}

// +vet
package main

import "core:fmt"
import "core:image"
import "core:image/png"
import "core:image/tga"
import "core:os"
import "core:path/filepath"
import xt "shared:xterm"

_ :: png
_ :: tga

dot_alpha: bool = false

load_image :: proc(image_path: string) {
	path := filepath.clean(image_path)
	img, err := image.load_from_file(path)
	if err != nil || img == nil {
		fmt.println("Image load error:", err, path)
		return
	}
	defer image.destroy(img)

	fmt.printfln("path: %s size: %d x %d channels: %d depth: %d", path, img.width, img.height, img.channels, img.depth)
	xt.print_image(img, dot_alpha)
}

main :: proc() {

	pattern := "*.png"

	if len(os.args) > 1 {
		pattern = os.args[1]
	}

	pics_path, ok := filepath.abs(filepath.join({"..", "examples", "raycaster", "pics"}))
	if ok {
		path_pattern := filepath.join({pics_path, pattern}, context.temp_allocator)
		matches, err := filepath.glob(path_pattern, context.temp_allocator)
		if err == nil {
			for path in matches {
				fmt.println(path)
				load_image(path)
			}
		}
	}

	fmt.println("Done.")
}

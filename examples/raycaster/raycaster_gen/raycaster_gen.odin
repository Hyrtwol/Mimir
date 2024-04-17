// +vet
package main

import "core:fmt"
import "core:image"
import "core:image/png"
import "core:image/tga"
import "core:os"
import fp "core:path/filepath"
import xt "shared:xterm"

_ :: png
_ :: tga

dot_alpha: bool = false

load_image :: proc(image_path: string) {
	path := fp.clean(image_path)
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

	// be os nice
	pics_path, ok := fp.abs(fp.join({"..", "examples", "raycaster", "pics"}))
	if ok {
		path_pattern := fp.join({pics_path, pattern}, context.temp_allocator)
		matches, err := fp.glob(path_pattern, context.temp_allocator)
		if err == nil {
			for path in matches {
				fmt.println(path)
				load_image(path)
			}
		}
	}

	fmt.println("Done.")
}

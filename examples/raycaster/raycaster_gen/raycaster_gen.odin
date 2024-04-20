// +vet
package main

import "core:bytes"
import "core:fmt"
import "core:image"
import "core:image/png"
import "core:image/tga"
import "core:os"
import fp "core:path/filepath"
import xt "shared:xterm"

_ :: png
_ :: tga

rgb :: [3]u8
rgba :: [4]u8
int2 :: [2]i32

dot_alpha: bool = false

write_image :: proc(fd: ^os.Handle, img: ^image.Image) {

	pix: []byte = bytes.buffer_to_bytes(&img.pixels)

	if len(pix) == 0 || len(pix) < img.width * img.height * int(img.channels) {
		//return 1
		panic("pix!!!")
	}
	fmt.println("pix:", len(pix))

	//os.write(fd, bytes)
	dp := img.depth
	ch := img.channels
	w, h := img.width, img.height
	wb := w * ch
	cb: rgba = {0, 0, 0, 0xFF}

	switch dp {
	case 8:
		switch ch {
		case 3:
			i, yb: int
			for k in 0 ..< h {
				yb = k * wb
				for x in 0 ..< w {
					i = x * ch
					(^rgb)(&cb)^ = ((^rgb)(&pix[yb + i]))^
					os.write(fd^, cb[:])
				}
			}
		case 4:
			i, yb: int
			for k in 0 ..< h {
				yb = k * wb
				for x in 0 ..< w {
					i = x * ch
					cb = ((^rgba)(&pix[yb + i]))^
					if cb.a == 0 {
						cb = {0, 0, 0, 0}
					}
					os.write(fd^, cb[:])
				}
			}
		}
	}
}

print_image :: proc(image_path: string, fd: ^os.Handle) {
	path := fp.clean(image_path)
	img, err := image.load_from_file(path)
	if err != nil || img == nil {
		fmt.println("Image load error:", err, path)
		return
	}
	defer image.destroy(img)

	fmt.printfln("path: %s size: %d x %d channels: %d depth: %d", path, img.width, img.height, img.channels, img.depth)
	xt.print_image(img, dot_alpha)
	write_image(fd, img)
}

gen_pics :: proc(output_name: string, pattern: string) -> int {
	ok: bool
	output_path, pics_path: string
	output_path, ok = fp.abs(fp.join({"..", "examples", "raycaster", output_name}))
	if !ok {
		fmt.eprintln("abs error:", output_name)
		return 1
	}
	fmt.printfln("writing %s", output_path)
	fd, ferr := os.open(output_path, os.O_WRONLY | os.O_CREATE | os.O_TRUNC, 0)
	if ferr != 0 {
		fmt.eprintln("open error:", ferr)
		return 1
	}
	defer os.close(fd)
	// be os nice
	pics_path, ok = fp.abs(fp.join({"..", "examples", "raycaster", "pics"}))
	if ok {
		path_pattern := fp.join({pics_path, pattern}, context.temp_allocator)
		matches, err := fp.glob(path_pattern, context.temp_allocator)
		if err == nil {
			for path in matches {
				fmt.println(path)
				print_image(path, &fd)
			}
		}
	}
	return 0
}


main :: proc() {
	pattern := "*.png" if len(os.args) <= 1 else os.args[1]
	hr := gen_pics("pics.dat", pattern)
	fmt.println("Done.", hr)
	os.exit(int(hr))
}

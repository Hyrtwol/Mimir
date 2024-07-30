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
import si "vendor:stb/image"

_ :: png
_ :: tga
_ :: si

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
	fmt.println("added:", len(pix), img.width, img.height, img.channels, img.depth)

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

print_and_write_image :: proc(path: string,fd: ^os.Handle, img: ^image.Image) {
	fmt.printfln("path: %s size: %d x %d channels: %d depth: %d", path, img.width, img.height, img.channels, img.depth)
	xt.print_image(img, dot_alpha)
	write_image(fd, img)
}

print_image :: proc(image_path: string, fd: ^os.Handle) {
	path := fp.clean(image_path)
	img, err := image.load_from_file(path)
	if err != nil || img == nil {
		fmt.println("Image load error:", err, path)
		return
	}
	defer image.destroy(img)

	img2 := new(image.Image)
	defer image.destroy(img2)

	img2.width = img.width / 2
	img2.height = img.height / 2
	img2.channels = img.channels
	img2.depth = img.depth
	img2.which = img.which

	if resize(&img2.pixels.buf, img2.width * img2.height * 4) != nil {
		panic("resize")
	}

	pix := ([^]u8)(&img.pixels.buf[0])
	pix2 := ([^]u8)(&img2.pixels.buf[0])

	{
		ch := img.channels
		switch ch {
			case 3:
			case 4:
				colors := ([^]rgba)(pix)
				cnt := img.width*img.height
				cb: ^rgba
				for i in 0..<cnt {
					cb = ((^rgba)(&colors[i]))
					if cb^.a < 4 {
						cb^ = {0, 0, 0, 0}
						//cb^ = {255, 0, 255, 0}
					}
				}
		}
	}

	res := si.resize_uint8(pix, i32(img.width), i32(img.height), 0, pix2, i32(img2.width), i32(img2.height), 0, i32(img.channels))
	assert(res == 1)

	print_and_write_image(path, fd, img2)
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
	fd, fe := os.open(output_path, os.O_WRONLY | os.O_CREATE | os.O_TRUNC, 0)
	if fe != 0 {
		fmt.eprintln("open error:", fe)
		return 1
	}
	defer os.close(fd)

	pics_path, ok = fp.abs(fp.join({"..", "examples", "raycaster", "pics"}))
	if ok {
		path_pattern := fp.join({pics_path, pattern}, context.temp_allocator)
		matches, err := fp.glob(path_pattern, context.temp_allocator)
		if err == nil {
			for path in matches {
				//fmt.println(path)
				print_image(path, &fd)
			}
		}
	}
	return 0
}


main :: proc() {
	pattern := "*.png" if len(os.args) <= 1 else os.args[1]
	exit_code := gen_pics("pics.dat", pattern)
	fmt.println("Done.", exit_code)
	os.exit(exit_code)
}

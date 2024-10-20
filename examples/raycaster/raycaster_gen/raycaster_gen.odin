#+vet
package main

import "base:intrinsics"
import "core:bytes"
import "core:fmt"
import "core:image"
import "core:image/png"
import "core:image/tga"
import "core:reflect"
import "core:os"
import fp "core:path/filepath"
import "core:strings"
import xt "shared:xterm"
import si "vendor:stb/image"
//
import "shared:obug"

texWidth :: 64

_ :: png
_ :: tga
_ :: si

rgb :: [3]u8
rgba :: [4]u8
int2 :: [2]i32

dot_alpha: bool = false

pics_path: string

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

print_and_write_image :: proc(path: string, fd: ^os.Handle, img: ^image.Image) {
	fmt.printfln("path: %s size: %d x %d channels: %d depth: %d", path, img.width, img.height, img.channels, img.depth)
	xt.print_image(img, dot_alpha)
	write_image(fd, img)
}

print_image :: proc(image_path: string, fd: ^os.Handle) {
	path := fp.clean(image_path, context.temp_allocator)
	img, err := image.load_from_file(path)
	if img == nil || err != nil {
		fmt.println("Image load error:", err, path)
		return
	}
	defer image.destroy(img)

	imgFinal := img

	when texWidth == 32 {

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

		{
			ch := img.channels
			switch ch {
			case 3:
			case 4:
				colors := ([^]rgba)(pix)
				cnt := img.width * img.height
				cb: ^rgba
				for i in 0 ..< cnt {
					cb = ((^rgba)(&colors[i]))
					if cb^.a < 4 {
						cb^ = {0, 0, 0, 0}
					}
				}
			}
		}

		pix2 := ([^]u8)(&img2.pixels.buf[0])
		res := si.resize_uint8(pix, i32(img.width), i32(img.height), 0, pix2, i32(img2.width), i32(img2.height), 0, i32(img.channels))
		assert(res == 1)
		imgFinal = img2
	}

	print_and_write_image(path, fd, imgFinal)
}

gen_pics :: proc(output_name: string, image_paths: []string) -> int {
	output_path := fp.abs(fp.join({"..", "examples", "raycaster", output_name}, context.temp_allocator), context.temp_allocator) or_else panic("abs")
	fmt.printfln("writing %s", output_path)
	fd, fe := os.open(output_path, os.O_WRONLY | os.O_CREATE | os.O_TRUNC, 0)
	if fe != os.ERROR_NONE {
		fmt.eprintln("open error:", fe)
		return 1
	}
	defer os.close(fd)

	for path in image_paths {
		print_image(path, &fd)
	}

	fmt.printfln("wrote %s", output_path)
	return 0
}

gen_pics_scan :: proc(output_name: string, pattern: string) -> int {
	image_paths := fp.glob(fp.join({pics_path, pattern}, context.temp_allocator), context.temp_allocator) or_else panic("glob")
	return gen_pics(output_name, image_paths)
}

join_pics_path :: proc(image_paths: []string, allocator := context.allocator) {
	for i in 0 ..< len(image_paths) {
		image_paths[i] = fp.join({pics_path, image_paths[i]}, allocator)
	}
}

gen_pics_from_filelist :: proc(output_name: string, input_file: string) -> int {
	data := os.read_entire_file_from_filename(input_file, context.temp_allocator) or_else panic("read_entire_file_from_filename")
	newline :: "\r\n"
	image_paths := strings.split(string(data), newline, context.temp_allocator) or_else panic("split")
	join_pics_path(image_paths, context.temp_allocator)
	return gen_pics(output_name, image_paths)
}

gen_pics_from_list :: proc(output_name: string) -> int {
	image_paths: []string = {
		// textures
		"eagle.png", // 0
		"redbrick.png", // 1
		"purplestone.png", // 2
		"greystone.png", // 3
		"bluestone.png", // 4
		"mossy.png", // 5
		"wood.png", // 6
		"colorstone.png", // 7
		// sprite textures
		"barrel.png", // 8
		"pillar.png", // 9
		"greenlight.png", // 10
	}
	join_pics_path(image_paths, context.temp_allocator)
	return gen_pics(output_name, image_paths)
}

run_mode :: enum {nop, scan, from_filelist, from_list}

run :: proc() -> (exit_code: int) {
	mode: run_mode = .from_list
	if len(os.args) > 1 {
		m, ok := reflect.enum_from_name(run_mode, os.args[1])
		if !ok {
			fmt.println("Invalid arg", os.args[1])
			exit_code = -1
			return
		}
		mode = m
	}

	pics_path = fp.abs(fp.join({"..", "data", "images", "pics"}, context.temp_allocator), context.temp_allocator) or_else panic("abs")
	output_name := fmt.tprintf("pics%d.dat", texWidth)

	#partial switch mode {
	case .scan:
		pattern := "*.png" if len(os.args) <= 1 else os.args[1]
		exit_code = gen_pics_scan(output_name, pattern)
	case .from_filelist:
		exit_code = gen_pics_from_filelist(output_name, "texture_list.txt")
	case .from_list:
		exit_code = gen_pics_from_list(output_name)
	case:
		fmt.println("Invalid mode", mode, output_name)
		exit_code = -1
	}

	fmt.println("Done.", exit_code)
	return
}

main :: proc() {
	when intrinsics.is_package_imported("obug") {
		os.exit(obug.tracked_run(run))
	} else {
		os.exit(run())
	}
}

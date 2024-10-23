#+vet
package raycaster

import "core:slice"
import pics "pics64"

pics_w: i32 : pics.pics_w
pics_h: i32 : pics.pics_h
pics_wm: i32 : pics_w - 1
pics_hm: i32 : pics_h - 1

pics_pixel_byte_size: i32 : size_of(byte4)
pics_buf_pixel_count: i32 : pics_w * pics_h
pics_buf_byte_size: i32 : pics_buf_pixel_count * pics_pixel_byte_size
pics_buf :: [pics_buf_pixel_count]byte4

pics_size :: vector2{scalar(pics_w), scalar(pics_h)}

textures: []pics_buf = slice.from_ptr((^pics_buf)(&pics.pics_data[0]), len(pics.pics_data) / int(pics_buf_byte_size))

texture_index :: #force_inline proc "contextless" (uv: vector2) -> i32 {
	return (i32(uv.x * pics_size.x) & pics_wm) + (i32(uv.y * pics_size.y) & pics_hm) * pics_w
}

get_texture_color :: #force_inline proc "contextless" (tex, idx: i32) -> byte4 {
	return textures[tex][idx]
}

get_texture :: #force_inline proc "contextless" (#any_int tex: int) -> ^pics_buf {
	return &textures[tex]
}

get_texture_count :: #force_inline proc "contextless" () -> i32 {
	return i32(len(textures))
}

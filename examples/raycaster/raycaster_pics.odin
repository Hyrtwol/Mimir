#+vet
package raycaster

import "core:slice"
import pics "pics64"

// pics_data :: struct {
// 	data: []u8,
// 	w, h: i32,
// 	ps: i32,
// 	size: i32,
// 	count: i32,
// }

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

// sample_uv :: proc(tex: ^pics_buf, uv: float2) -> byte4 {
// 	uvf := linalg.fract(uv)
// 	x, y := i32(uvf.x * f32(pics_w)), i32(uvf.y * f32(pics_h))
// 	tidx := (y & pics_hm) * pics_w + (x & pics_wm)
// 	return (^byte4)(&tex[tidx])^
// }

// sample :: proc(tex: ^pics_buf, u, v: scalar) -> byte4 {
// 	//uvf := linalg.fract(uv)
// 	//x, y := i32(math.floor(u) * f32(pics_w)), i32(math.floor(v) * f32(pics_h))
// 	x, y := i32(u * f32(pics_w)), i32(v * f32(pics_h))
// 	tidx := (y & pics_hm) * pics_w + (x & pics_wm)
// 	return (^byte4)(&tex[tidx])^
// }

texture_index :: #force_inline proc "contextless" (uv: vector2) -> i32 {
	return (i32(uv.x * pics_size.x) & pics_wm) + (i32(uv.y * pics_size.y) & pics_hm) * pics_w
}

sample :: #force_inline proc "contextless" (tex: ^pics_buf, uv: vector2) -> byte4 {
	idx := texture_index(uv)
	return (^byte4)(&tex[idx])^
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

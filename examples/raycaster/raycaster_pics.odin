#+vet
package raycaster

import "core:slice"

// pics_data :: struct {
// 	data: []u8,
// 	w, h: i32,
// 	ps: i32,
// 	size: i32,
// 	count: i32,
// }

pics_w: i32 : 64
pics_h: i32 : pics_w
pics_wm: i32 : pics_w - 1
pics_hm: i32 : pics_h - 1
pics_ps: i32 : size_of(byte4)
pics_byte_size: i32 : pics_w * pics_h * pics_ps
pics_buf_size :: pics_w * pics_h
pics_buf :: [pics_buf_size]byte4

pics_size :: vector2{scalar(pics_w), scalar(pics_h)}

#assert(pics_ps == 4)
when pics_w == 64 {
	pics := #load("pics64.dat")
	#assert(pics_byte_size == 16384)
	#assert(pics_buf_size == 4096)
	#assert(size_of(pics_buf) == 16384)
} else when pics_w == 32 {
	pics := #load("pics32.dat")
	#assert(pics_byte_size == 4096)
	#assert(pics_buf_size == 1024)
	#assert(size_of(pics_buf) == 4096)
}

pics_count := i32(len(pics)) / pics_byte_size
textures: []pics_buf = slice.from_ptr((^pics_buf)(&pics[0]), int(pics_count))

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

texture_index :: #force_inline proc "contextless" (uv : vector2) -> i32 {
	return (i32(uv.x * pics_size.x) & pics_wm) +
	       (i32(uv.y * pics_size.y) & pics_hm) * pics_w
}

sample :: #force_inline proc "contextless" (tex: ^pics_buf, uv : vector2) -> byte4 {
	tidx := texture_index(uv)
	return (^byte4)(&tex[tidx])^
}

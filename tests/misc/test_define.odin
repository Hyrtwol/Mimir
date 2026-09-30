package test_misc

@(test)
use_define :: proc(t: ^testing.T) {

	vertex :: struct {
		pos: [3]f32,
		nml: [3]f32,
	}

	vertex_attrib := 0
	when #defined(vertex) {
		vertex_attrib += 1
	}
	when #defined(vertex.pos) {
		vertex_attrib += 2
	}
	when #defined(vertex.nml) {
		vertex_attrib += 4
	}
	when #defined(vertex.uv0) {
		vertex_attrib += 8
	}

	expect_value(t, vertex_attrib, 1) // fails with: expected vertex_attrib to be 7, got 1
}

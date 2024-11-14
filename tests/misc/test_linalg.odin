package test_misc

import "core:fmt"
import "core:math"
import "core:math/linalg"
import _t "core:testing"

@(test)
calc_projection :: proc(t: ^T) {

	WIDTH :: 1920 / 2
	HEIGHT :: WIDTH * 9 / 16
	fov, aspect, near, far: f32 = math.RAD_PER_DEG * 53, WIDTH / HEIGHT, 1, 9
	h : f32 = 1

	projection1, projection2: linalg.Matrix4x4f32
	projection1 = {
		2 * near / aspect, 0, 0, 0,
		0, 2 * near / h, 0, 0,
		0, 0, far / (far - near), near * far / (near - far),
		0, 0, 1, 0,
	}
	projection2 = linalg.matrix4_perspective_f32(fov, aspect, near, far, false)
	fmt.println("projection1:", projection1)
	fmt.println("projection2:", projection2)

	_t.expect_value(t, projection1[0, 0], 2)
}

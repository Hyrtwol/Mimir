package neural_network

import "core:math/rand"

random_matrix :: proc(v: ^matrix[$M, $N]f32) #no_bounds_check {
	for j in 0 ..< N {
		for i in 0 ..< M {
			v[i, j] = rand.float32() * 2 - 1
		}
	}
}

random_vector :: proc(v: ^[$N]f32) #no_bounds_check {
	for i in 0 ..< N {
		v[i] = rand.float32() * 2 - 1
	}
}

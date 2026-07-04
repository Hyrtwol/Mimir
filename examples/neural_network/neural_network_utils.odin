package neural_network

import "core:math/rand"

random_scalar :: #force_inline proc(v: ^f32) #no_bounds_check {
	v^ = rand.float32() * 2 - 1
}

random_vector :: #force_inline proc(v: ^[$N]f32) #no_bounds_check {
	for i in 0 ..< N {
		random_scalar(&v[i])
	}
}

random_matrix :: #force_inline proc(v: ^matrix[$M, $N]f32) #no_bounds_check {
	for j in 0 ..< N {
		random_vector(&v[j])
	}
}

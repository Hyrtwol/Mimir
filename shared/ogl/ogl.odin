package ogl

import glm "core:math/linalg/glsl"
import gl "vendor:OpenGL"

float3 :: glm.vec3
mat4 :: glm.mat4

Perspective :: struct {
	fov:       f32,
	aspect:    f32,
	near, far: f32,
}

Camera :: struct {
	eye:    float3,
	center: float3,
	up:     float3,
}

camera_look_at :: proc(camera: ^Camera) -> mat4 {
	return glm.mat4LookAt(eye = camera.eye, centre = camera.center, up = camera.up)
}

perspective_projection :: proc(perspective: ^Perspective) -> mat4 {
	return glm.mat4Perspective(perspective.fov, perspective.aspect, perspective.near, perspective.far)
}

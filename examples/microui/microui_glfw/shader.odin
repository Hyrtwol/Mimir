package main

import "core:fmt"
import glm "core:math/linalg/glsl"
import gl "vendor:OpenGL"

Shader :: struct {
    program_id : u32,
    uniforms :   gl.Uniforms,
}

shader_from_source_strings :: proc(vertex_source, fragment_source : string) -> (Shader, bool) {
    shader : Shader
    program_id, program_ok := gl.load_shaders_source(vertex_source, fragment_source)
    if !program_ok {
        fmt.eprintln("Failed to create GLSL program!")
    }

    shader.program_id = program_id
    shader.uniforms = gl.get_uniforms_from_program(program_id)

    return shader, program_ok
}

cleanup_shader :: proc(shader : Shader) {
    gl.DeleteProgram(shader.program_id)
    delete(shader.uniforms)
}

use_shader :: proc(shader : Shader) {
    gl.UseProgram(shader.program_id)
}

set_shader_uniform_mat4 :: proc(shader : Shader, name : string, m : ^glm.mat4) {
    gl.UniformMatrix4fv(shader.uniforms[name].location, 1, false, auto_cast m)
}

set_shader_uniform_int :: proc(shader : Shader, name : string, i : i32) {
    gl.Uniform1i(shader.uniforms[name].location, i)
}

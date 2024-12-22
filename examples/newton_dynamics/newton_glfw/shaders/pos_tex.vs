#version 330 core

layout(location=0) in vec3 a_position;
layout(location=1) in vec2 a_texcoord;

out vec4 v_color;
out vec2 v_texcoord;

uniform mat4 u_transform;

void main() {
	gl_Position = u_transform * vec4(a_position, 1.0);
	v_color = vec4(a_texcoord, 0.0, 1.0);
    v_texcoord = a_texcoord;
}

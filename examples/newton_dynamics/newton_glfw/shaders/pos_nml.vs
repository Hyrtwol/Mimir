#version 330 core

layout(location=0) in vec3 a_position;
layout(location=1) in vec3 a_normal;

out vec4 v_color;
out vec2 v_texcoord;
out vec3 v_normal;
out vec3 FragPos;

uniform mat4 u_transform;
uniform mat4 u_proj_view;
//uniform vec3 bbb;

void main() {
    FragPos = vec3(u_transform * vec4(a_position, 1.0));
	gl_Position = (u_proj_view) * vec4(FragPos, 1.0);
	v_color = vec4(a_normal * 0.5 + 0.5, 1.0);
    v_texcoord = a_position.xz;
    //v_normal = a_normal;
    v_normal = mat3(transpose(inverse(u_transform))) * a_normal;
}

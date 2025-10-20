#version 330 core

in vec4 v_color;
in vec2 v_texcoord;

out vec4 o_color;

uniform vec3 lightPos;
uniform sampler2D some_texture;

void main() {
	//o_color = v_color;
    o_color = texture(some_texture, v_texcoord);
}

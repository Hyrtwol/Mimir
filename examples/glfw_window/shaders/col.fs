#version 330 core

in vec4 v_color;

out vec4 o_color;

uniform vec4 lightPos;

void main() {
	//o_color = v_color;
	o_color = lightPos;
    //o_color.y = 1;
}

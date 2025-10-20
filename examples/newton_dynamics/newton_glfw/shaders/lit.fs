#version 330 core

in vec4 v_color;
in vec2 v_texcoord;
in vec3 v_normal;
in vec3 FragPos;

out vec4 o_color;

uniform vec3 lightPos;
uniform vec3 ambient;
uniform sampler2D main_texture;

void main() {
    vec3 norm = normalize(v_normal);
    vec3 lightDir = normalize(lightPos - FragPos);

    float diff = max(dot(norm, lightDir), 0.1);
    //vec3 diffuse = diff * lightColor;
	//o_color = v_color;
    //o_color = texture(main_texture, v_texcoord) * diff;
	//o_color += lightPos;
    vec3 result = ambient + texture(main_texture, v_texcoord).rgb * diff;
    o_color = vec4(result, 1.0);
}

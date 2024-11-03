package glfw_window

vertex_sources : []string = {
	vertex_source_pos,
	vertex_source_pos_tex,
	vertex_source_pos_nml,
	vertex_source_pos_tex_nml,
}

vertex_source_pos := string(#load("shaders/pos.vs"))
vertex_source_pos_tex := string(#load("shaders/pos_tex.vs"))
vertex_source_pos_nml := string(#load("shaders/pos_nml.vs"))
vertex_source_pos_tex_nml := string(#load("shaders/pos_tex_nml.vs"))
fragment_source := string(#load("shaders/color.fs"))

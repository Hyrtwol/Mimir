//
// https://en.wikipedia.org/wiki/Camera_matrix
// https://github.com/ssloy/tinyrenderer/wiki/Lesson-5-Moving-the-camera
// https://learn.microsoft.com/en-us/windows/win32/direct3d10/d3d10-graphics-programming-guide-resources-coordinates
package tinyrenderer

import "base:intrinsics"
//import "core:container/queue"
//import "core:fmt"
//import "core:math"
import lg "core:math/linalg"
//import "core:math/rand"
//import "core:mem"
//import win32 "core:sys/windows"
import cv "libs:tlc/canvas"
//import ca "libs:tlc/canvas_app"

ps_texture_wip :: proc(shader: ^cv.IShader, bc_clip: float3, color: ^byte4) -> bool {
	// per-vertex normal interpolation
	bn: float3 = lg.normalize(shader.varying_nrm * bc_clip)
	// tex coord interpolation
	uv: float2 = shader.varying_uv * bc_clip
	//uv: float2 = bc_clip.xy

	texcol := sample2D(uv)
	if texcol.a == 0 {return true}

	/*
	// for the math refer to the tangent space normal mapping lecture
	// https://github.com/ssloy/tinyrenderer/wiki/Lesson-6bis-tangent-space-normal-mapping
	// float3x3 AI = float3x3{ {view_tri.col(1) - view_tri.col(0), view_tri.col(2) - view_tri.col(0), bn} }.invert();
	A: float3x3
	A[0] = shader.view_tri[1] - shader.view_tri[0]
	A[1] = shader.view_tri[2] - shader.view_tri[0]
	A[2] = bn
	AI := lg.inverse(A)
	// float3 i = AI * float3{varying_uv[0][1] - varying_uv[0][0], varying_uv[0][2] - varying_uv[0][0], 0};
	i := AI * float3{shader.varying_uv[1].x - shader.varying_uv[0].x, shader.varying_uv[2].x - shader.varying_uv[0].x, 0}
	// float3 j = AI * float3{varying_uv[1][1] - varying_uv[1][0], varying_uv[1][2] - varying_uv[1][0], 0};
	j := AI * float3{shader.varying_uv[1].y - shader.varying_uv[0].y, shader.varying_uv[2].y - shader.varying_uv[1].y, 0}
	// float3x3 B = float3x3{ {i.normalized(), j.normalized(), bn} }.transpose();
	B: float3x3
	B[0] = lg.normalize(i)
	B[1] = lg.normalize(j)
	B[2] = bn
	B = lg.transpose(B)
	*/

	// float3 n = (B * model.normal(uv)).normalized(); // transform the normal from the texture to the tangent space
	// double diff = std::max(0., n*uniform_l); // diffuse light intensity
	// float3 r = (n*(n*uniform_l)*2 - uniform_l).normalized(); // reflected light direction, specular mapping is described here: https://github.com/ssloy/tinyrenderer/wiki/Lesson-6-Shaders-for-the-software-renderer
	// double spec = std::pow(std::max(-r.z, 0.), 5+sample2D(model.specular(), uv)[0]); // specular intensity, note that the camera lies on the z-axis (in view), therefore simple -r.z
	// TGAColor c = sample2D(model.diffuse(), uv);
	// for (int i : {0,1,2})
	//     gl_FragColor[i] = std::min<int>(10 + c[i]*(diff + spec), 255); // (a bit of ambient light, diff + spec), clamp the result

	d := lg.dot(shader.uniform_l, bn)
	//d := lg.dot(light_dir, bn)
	d = clamp(d, 0.2, 1)

	//c := d * 0.8 + 0.2
	//col := float4{uv.x, uv.y, 0, 1}


	col := cv.to_color_byte4(texcol)

	//col := shader.model.color
	col *= shader.model.color
	//col *= texcol
	col *= d
	//col += 0.1
	//col = texcol
	//col = lg.clamp(col, 0, 1)
	color^ = cv.to_color(col)

	//color^ = (^cv.byte4)(&pics_data[tidx])^
	return false
}

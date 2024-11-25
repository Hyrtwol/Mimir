// Based off Minimal D3D11 pt2 https://gist.github.com/d7samurai/aee35fd5d132c51e8b0a78699cbaa1e4
package minimal_d3d11_pt2

import "base:intrinsics"
import "base:runtime"
import "core:fmt"
import "core:os"
import "core:math/linalg"
import hlm "core:math/linalg/hlsl"
import win32 "core:sys/windows"
import owin "libs:tlc/win32app"
import owin_dxgi "libs:tlc/win32app/owin_dxgi"
import d3d11 "vendor:directx/d3d11"
import d3dc "vendor:directx/d3d_compiler"
import dxgi "vendor:directx/dxgi"

TITLE :: "Minimal D3D11 pt2"
WIDTH :: 1920 / 2
HEIGHT :: WIDTH * 9 / 16
SHADER_FILE :: "shaders.hlsl"

float2 :: hlm.float2
float3 :: hlm.float3
float4 :: hlm.float4
float4x4 :: hlm.float4x4

panic_if_failed :: owin.panic_if_failed

frame_buffer_clear_color := float4{0.025, 0.025, 0.025, 1.0}

Constants :: struct #align (16) {
	projection:   float4x4,
	light_vector: float4,
	rotate:       float4,
	scale:        float4,
	translate:    float4,
}

wndproc :: proc "system" (hwnd: win32.HWND, msg: win32.UINT, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	context = runtime.default_context()
	switch msg {
	case win32.WM_DESTROY:
		owin.post_quit_message(0);return 0
	case win32.WM_ERASEBKGND:
		return 1 // skip
	case win32.WM_CHAR:
		switch wparam {
		case '\x1b':
			win32.DestroyWindow(hwnd) // ESC
		}
		return 0
	case:
		return win32.DefWindowProcW(hwnd, msg, wparam, lparam)
	}
}

run :: proc() -> (exit_code: int) {

	settings := owin.default_window_settings
	settings.window_size = {WIDTH, HEIGHT}
	settings.title = TITLE
	settings.wndproc = wndproc
	_, _, hwnd := owin.register_and_create_window(&settings)
	if hwnd == nil {owin.show_error_and_panic("register_and_create_window failed")}

	//-- Create Device --//

	feature_levels := [?]d3d11.FEATURE_LEVEL{._11_1}
	base_device: ^d3d11.IDevice
	base_device_context: ^d3d11.IDeviceContext
	panic_if_failed(d3d11.CreateDevice(nil, .HARDWARE, nil, {.BGRA_SUPPORT}, &feature_levels[0], len(feature_levels), d3d11.SDK_VERSION, &base_device, nil, &base_device_context))
	assert(base_device != nil);assert(base_device_context != nil)

	device: ^d3d11.IDevice
	panic_if_failed(base_device->QueryInterface(d3d11.IDevice_UUID, (^rawptr)(&device)))
	assert(device != nil)

	device_context: ^d3d11.IDeviceContext
	panic_if_failed(base_device_context->QueryInterface(d3d11.IDeviceContext_UUID, (^rawptr)(&device_context)))
	assert(device_context != nil)

	//-- Adapter Factory --//

	dxgi_factory: ^dxgi.IFactory2 = nil
	{
		dxgi_device: ^dxgi.IDevice
		panic_if_failed(device->QueryInterface(dxgi.IDevice_UUID, (^rawptr)(&dxgi_device)))
		assert(dxgi_device != nil)

		dxgi_adapter: ^dxgi.IAdapter
		panic_if_failed(dxgi_device->GetAdapter(&dxgi_adapter))
		assert(dxgi_adapter != nil)

		panic_if_failed(dxgi_adapter->GetParent(dxgi.IFactory2_UUID, (^rawptr)(&dxgi_factory)))
	}
	assert(dxgi_factory != nil)

	//-- Swap Chain --//

	swap_chain: ^dxgi.ISwapChain1 = nil
	{
		swap_chain_desc := dxgi.SWAP_CHAIN_DESC1 {
			Width = 0, // use window width
			Height = 0, // use window height
			Format = .B8G8R8A8_UNORM, // can't specify _SRGB here when using DXGI_SWAP_EFFECT_FLIP_* ...
			Stereo = false,
			SampleDesc = {Count = 1, Quality = 0},
			BufferUsage = {.RENDER_TARGET_OUTPUT},
			BufferCount = 2,
			Scaling = .NONE,
			SwapEffect = .FLIP_DISCARD,
			AlphaMode = .UNSPECIFIED,
			Flags = {},
		}
		panic_if_failed(dxgi_factory->CreateSwapChainForHwnd(device, hwnd, &swap_chain_desc, nil, nil, &swap_chain))
	}
	assert(swap_chain != nil)
	//defer swap_chain->Release()

	//-- Frame Buffer --//

	frame_buffer_tex: ^d3d11.ITexture2D
	panic_if_failed(swap_chain->GetBuffer(0, d3d11.ITexture2D_UUID, (^rawptr)(&frame_buffer_tex)))
	assert(frame_buffer_tex != nil)

	frame_buffer_desc: d3d11.RENDER_TARGET_VIEW_DESC = {
		Format        = .B8G8R8A8_UNORM_SRGB, // ... so do this to get _SRGB swap chain (rendertarget view)
		ViewDimension = .TEXTURE2D,
	}

	frame_buffer_rtv: ^d3d11.IRenderTargetView
	panic_if_failed(device->CreateRenderTargetView(frame_buffer_tex, &frame_buffer_desc, &frame_buffer_rtv))
	assert(frame_buffer_rtv != nil)

	//-- Frame Depth Buffer --//

	depth_buffer_desc: d3d11.TEXTURE2D_DESC
	frame_buffer_tex->GetDesc(&depth_buffer_desc) // copy from frame buffer properties
	depth_buffer_desc.Format = .D24_UNORM_S8_UINT
	depth_buffer_desc.BindFlags = {.DEPTH_STENCIL}

	depth_buffer_tex: ^d3d11.ITexture2D
	panic_if_failed(device->CreateTexture2D(&depth_buffer_desc, nil, &depth_buffer_tex))
	assert(depth_buffer_tex != nil)

	depth_buffer_dsv: ^d3d11.IDepthStencilView
	panic_if_failed(device->CreateDepthStencilView(depth_buffer_tex, nil, &depth_buffer_dsv))
	assert(depth_buffer_dsv != nil)

	///////////////////////////////////////////////////////////////////////////////////////////////

	vs_blob: ^d3d11.IBlob
	panic_if_failed(d3dc.Compile(raw_data(shaders_hlsl), len(shaders_hlsl), SHADER_FILE, nil, nil, "vs_main", "vs_5_0", 0, 0, &vs_blob, nil))
	assert(vs_blob != nil)

	vertex_shader: ^d3d11.IVertexShader
	panic_if_failed(device->CreateVertexShader(vs_blob->GetBufferPointer(), vs_blob->GetBufferSize(), nil, &vertex_shader))
	assert(vertex_shader != nil)

	// odinfmt: disable
	input_element_desc := [?]d3d11.INPUT_ELEMENT_DESC {
		{"POS", 0, .R32G32B32_FLOAT, 0,                            0, .VERTEX_DATA,   0},
		{"NOR", 0, .R32G32B32_FLOAT, 0, d3d11.APPEND_ALIGNED_ELEMENT, .VERTEX_DATA,   0},
		{"TEX", 0, .R32G32_FLOAT,    0, d3d11.APPEND_ALIGNED_ELEMENT, .VERTEX_DATA,   0},
		{"ROT", 0, .R32G32B32_UINT,  1, d3d11.APPEND_ALIGNED_ELEMENT, .INSTANCE_DATA, 1}, // change every instance
		{"COL", 0, .R32G32B32_FLOAT, 2, d3d11.APPEND_ALIGNED_ELEMENT, .INSTANCE_DATA, 4}, // change every 4th instance, i.e. every face
	}
	// odinfmt: enable
	input_layout: ^d3d11.IInputLayout
	panic_if_failed(device->CreateInputLayout(&input_element_desc[0], len(input_element_desc), vs_blob->GetBufferPointer(), vs_blob->GetBufferSize(), &input_layout))
	assert(input_layout != nil)

	//-- framebuffer_ps --//

	ps_blob: ^d3d11.IBlob
	panic_if_failed(d3dc.Compile(raw_data(shaders_hlsl), len(shaders_hlsl), SHADER_FILE, nil, nil, "ps_main", "ps_5_0", 0, 0, &ps_blob, nil))
	assert(ps_blob != nil)

	pixel_shader: ^d3d11.IPixelShader
	panic_if_failed(device->CreatePixelShader(ps_blob->GetBufferPointer(), ps_blob->GetBufferSize(), nil, &pixel_shader))
	assert(pixel_shader != nil)

	///////////////////////////////////////////////////////////////////////////////////////////////

	rasterizer_desc := d3d11.RASTERIZER_DESC {
		FillMode = .SOLID,
		CullMode = .BACK,
	}
	rasterizer_state: ^d3d11.IRasterizerState
	panic_if_failed(device->CreateRasterizerState(&rasterizer_desc, &rasterizer_state))
	assert(rasterizer_state != nil)

	sampler_desc := d3d11.SAMPLER_DESC {
		Filter         = .MIN_MAG_MIP_POINT,
		AddressU       = .WRAP,
		AddressV       = .WRAP,
		AddressW       = .WRAP,
		ComparisonFunc = .NEVER,
	}
	sampler_state: ^d3d11.ISamplerState
	panic_if_failed(device->CreateSamplerState(&sampler_desc, &sampler_state))
	assert(sampler_state != nil)

	//-- Depth Stencil --//

	depth_stencil_desc := d3d11.DEPTH_STENCIL_DESC {
		DepthEnable    = true,
		DepthWriteMask = .ALL,
		DepthFunc      = .LESS,
	}
	depth_stencil_state: ^d3d11.IDepthStencilState
	panic_if_failed(device->CreateDepthStencilState(&depth_stencil_desc, &depth_stencil_state))
	assert(depth_stencil_state != nil)

	//-- Constant Buffer --//

	constant_buffer_desc := d3d11.BUFFER_DESC {
		ByteWidth      = size_of(Constants),
		Usage          = .DYNAMIC,
		BindFlags      = {.CONSTANT_BUFFER},
		CPUAccessFlags = {.WRITE},
	}
	//fmt.println("constant_buffer_desc:", constant_buffer_desc)
	constant_buffer: ^d3d11.IBuffer
	panic_if_failed(device->CreateBuffer(&constant_buffer_desc, nil, &constant_buffer))
	assert(constant_buffer != nil)

	//-- Vertex Buffer --//

	vertex_buffer_desc := d3d11.BUFFER_DESC {
		ByteWidth = size_of(vertex_data),
		Usage     = .IMMUTABLE,
		BindFlags = {.VERTEX_BUFFER},
	}

	vertex_buffer_data := d3d11.SUBRESOURCE_DATA {
		pSysMem     = &vertex_data[0],
		SysMemPitch = vertex_buffer_desc.ByteWidth,
	}

	vertex_buffer: ^d3d11.IBuffer
	panic_if_failed(device->CreateBuffer(&vertex_buffer_desc, &vertex_buffer_data, &vertex_buffer))
	assert(vertex_buffer != nil)

	index_buffer_desc := d3d11.BUFFER_DESC {
		ByteWidth = size_of(index_data),
		Usage     = .IMMUTABLE,
		BindFlags = {.INDEX_BUFFER},
	}

	index_buffer_data := d3d11.SUBRESOURCE_DATA {
		pSysMem     = &index_data[0],
		SysMemPitch = index_buffer_desc.ByteWidth,
	}

	index_buffer: ^d3d11.IBuffer
	panic_if_failed(device->CreateBuffer(&index_buffer_desc, &index_buffer_data, &index_buffer))
	assert(index_buffer != nil)

	//-- Instance Buffer --//

	instanceBufferDesc: d3d11.BUFFER_DESC = {
		Usage     = .IMMUTABLE,
		BindFlags = {.VERTEX_BUFFER},
	}

	instanceData: d3d11.SUBRESOURCE_DATA = {}

	instanceRotationBuffer: ^d3d11.IBuffer

	instanceBufferDesc.ByteWidth = size_of(instance_rotation_data)
	instanceData.pSysMem = &instance_rotation_data[0]

	panic_if_failed(device->CreateBuffer(&instanceBufferDesc, &instanceData, &instanceRotationBuffer))
	assert(instanceRotationBuffer != nil)

	instanceColorBuffer: ^d3d11.IBuffer

	instanceBufferDesc.ByteWidth = size_of(instance_color_data)
	instanceData.pSysMem = &instance_color_data[0]

	panic_if_failed(device->CreateBuffer(&instanceBufferDesc, &instanceData, &instanceColorBuffer))
	assert(instanceColorBuffer != nil)

	///////////////////////////////////////////////////////////////////////////////////////////////

	texture_desc := d3d11.TEXTURE2D_DESC {
		Width = TEXTURE_WIDTH,
		Height = TEXTURE_HEIGHT,
		MipLevels = 1,
		ArraySize = 1,
		Format = .R8G8B8A8_UNORM_SRGB,
		SampleDesc = {Count = 1},
		Usage = .IMMUTABLE,
		BindFlags = {.SHADER_RESOURCE},
	}

	texture_data := d3d11.SUBRESOURCE_DATA {
		pSysMem     = &texture_data[0],
		SysMemPitch = TEXTURE_WIDTH * size_of(u32),
	}

	texture: ^d3d11.ITexture2D
	panic_if_failed(device->CreateTexture2D(&texture_desc, &texture_data, &texture))
	assert(texture != nil)

	texture_view: ^d3d11.IShaderResourceView
	panic_if_failed(device->CreateShaderResourceView(texture, nil, &texture_view))
	assert(texture_view != nil)

	///////////////////////////////////////////////////////////////////////////////////////////////

	buffers: [3]^d3d11.IBuffer = {vertex_buffer, instanceRotationBuffer, instanceColorBuffer}
	// vertex (float3 position, float3 normal, float2 texcoord), instance rotation (uint3 rotation), instance color (float3 color)
	vertex_buffer_stride: [3]u32 = {8 * size_of(f32), 3 * size_of(u32), 3 * size_of(f32)}
	vertex_buffer_offset: [3]u32 = {0, 0, 0}

	viewport := d3d11.VIEWPORT{0, 0, f32(depth_buffer_desc.Width), f32(depth_buffer_desc.Height), 0, 1}

	// w := viewport.Width / viewport.Height
	h := f32(1)
	// n := f32(1)
	// f := f32(9)
	// fov, aspect, near, far: f32 = math.RAD_PER_DEG * 60, viewport.Width / viewport.Height, 1, 9
	fov, aspect, near, far: f32 = 1, viewport.Width / viewport.Height, 1, 9
	fmt.println("fov, aspect, near, far:", fov, aspect, near, far)

	constants: Constants

	// constants.projection = {
	// 	2 * near / aspect, 0, 0, 0,
	// 	0, 2 * near / h, 0, 0,
	// 	0, 0, far / (far - near), 1,
	// 	0, 0, near * far / (near - far), 0,
	// } // projection matrix
	// fmt.println("projection:", constants.projection)

	constants.projection = linalg.transpose( linalg.matrix4_perspective_f32(fov, aspect, near, far, false) )
	fmt.println("projection:", constants.projection)

	constants.light_vector = {1.0, -1.0, 1.0, 0.0}
	constants.rotate = {0.0, 0.0, 0.0, 0.0}
	constants.scale = {1.0, 1.0, 1.0, 0.0}
	constants.translate = {0.0, 0.0, 4.0, 0.0}

	owin.show_and_update_window(hwnd)

	msg: win32.MSG
	for owin.pull_messages(&msg) {

		constants.rotate += {0.005, 0.009, 0.001, 0.0}

		//-- Update Constants --//
		{
			mappedSubresource: d3d11.MAPPED_SUBRESOURCE
			panic_if_failed(device_context->Map(constant_buffer, 0, .WRITE_DISCARD, {}, &mappedSubresource))
			defer device_context->Unmap(constant_buffer, 0)
			(^Constants)(mappedSubresource.pData)^ = constants
		}

		//-- Render Frame --//

		device_context->ClearRenderTargetView(frame_buffer_rtv, &frame_buffer_clear_color)
		device_context->ClearDepthStencilView(depth_buffer_dsv, {.DEPTH}, 1, 0)

		device_context->IASetPrimitiveTopology(.TRIANGLELIST)
		device_context->IASetInputLayout(input_layout)
		device_context->IASetVertexBuffers(0, 3, &buffers[0], &vertex_buffer_stride[0], &vertex_buffer_offset[0])
		device_context->IASetIndexBuffer(index_buffer, .R32_UINT, 0)

		device_context->VSSetShader(vertex_shader, nil, 0)
		device_context->VSSetConstantBuffers(0, 1, &constant_buffer)

		device_context->RSSetViewports(1, &viewport)
		device_context->RSSetState(rasterizer_state)

		device_context->PSSetShader(pixel_shader, nil, 0)
		device_context->PSSetShaderResources(0, 1, &texture_view)
		device_context->PSSetSamplers(0, 1, &sampler_state)

		device_context->OMSetRenderTargets(1, &frame_buffer_rtv, depth_buffer_dsv)
		device_context->OMSetDepthStencilState(depth_stencil_state, 0)
		device_context->OMSetBlendState(nil, nil, transmute(u32)d3d11.COLOR_WRITE_ENABLE_ALL) // use default blend mode (i.e. disable)

		///////////////////////////////////////////////////////////////////////////////////////////////

		device_context->DrawIndexedInstanced(len(index_data), 24, 0, 0, 0)

		///////////////////////////////////////////////////////////////////////////////////////////

		panic_if_failed(swap_chain->Present(1, {}))
	}

	exit_code = int(msg.wParam)
	fmt.println("Done.")
	return
}

shaders_hlsl := #load(SHADER_FILE)



// odinfmt: disable

TEXTURE_WIDTH  :: 2
TEXTURE_HEIGHT :: 2

texture_data := [TEXTURE_WIDTH*TEXTURE_HEIGHT]u32{
	0xfffffff, 0xff7f7f7f,
	0xff7f7f7, 0xffffffff,
}

vertex_data := [?]f32{
	// pos.x, pos.y, pos.z, nor.x, nor.y, nor.z, tex.u, tex.v, ...
    -1.00,  1.00, -1.00,  0.0,  0.0, -1.0,  0.0,  0.0,
	 1.00,  1.00, -1.00,  0.0,  0.0, -1.0,  9.5,  0.0,
     0.58,  0.58, -1.00,  0.0,  0.0, -1.0,  7.5,  2.0,
	-0.58,  0.58, -1.00,  0.0,  0.0, -1.0,  2.0,  2.0,
    -0.58,  0.58, -1.00,  0.0, -1.0,  0.0,  0.0,  0.0,
	 0.58,  0.58, -1.00,  0.0, -1.0,  0.0,  0.0,  0.0,
     0.58,  0.58, -0.58,  0.0, -1.0,  0.0,  0.0,  0.0,
	-0.58,  0.58, -0.58,  0.0, -1.0,  0.0,  0.0,  0.0,
}

index_data := [?]u32{ 0, 1, 3, 1, 2, 3, 4, 5, 7, 5, 6, 7 }

instance_rotation_data := [?]u32{
	// rot.x, rot.y, rot.z, ... in multiples of 90 degrees
	0, 0, 0, 0, 0, 1, 0, 0, 2, 0, 0, 3,
	1, 0, 0, 1, 1, 0, 1, 2, 0, 1, 3, 0,
	2, 0, 0, 2, 0, 1, 2, 0, 2, 2, 0, 3,
	3, 0, 0, 3, 1, 0, 3, 2, 0, 3, 3, 0,
	1, 0, 1, 1, 1, 1, 1, 2, 1, 1, 3, 1,
	1, 0, 3, 1, 1, 3, 1, 2, 3, 1, 3, 3,
 }

instance_color_data := [?]f32{
	// col.r, col.g, col.b, ...
	0.973, 0.480, 0.002,
	0.897, 0.163, 0.011,
	0.612, 0.000, 0.069,
	0.127, 0.116, 0.408,
	0.000, 0.254, 0.637,
	0.001, 0.447, 0.067,
}

// odinfmt: enable

main :: proc() {
	when intrinsics.is_package_imported("obug") {
		os.exit(obug.tracked_run(run))
	} else {
		os.exit(run())
	}
}

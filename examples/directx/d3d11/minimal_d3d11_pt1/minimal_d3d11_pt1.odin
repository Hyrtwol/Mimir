// Based off Minimal D3D11 https://gist.github.com/d7samurai/261c69490cce0620d0bfc93003cd1052
package minimal_d3d11_pt1

import "base:intrinsics"
import "base:runtime"
import "core:fmt"
import "core:os"
import "core:math"
import "core:math/linalg"
import win32 "core:sys/windows"
import owin "libs:tlc/win32app"
import owin_dxgi "libs:tlc/win32app/owin_dxgi"
import d3d11 "vendor:directx/d3d11"
import d3dc "vendor:directx/d3d_compiler"
import dxgi "vendor:directx/dxgi"
import "shared:obug"

_ :: owin_dxgi

TITLE :: "Minimal D3D11 pt1"
WIDTH :: 1920 / 2
HEIGHT :: WIDTH * 9 / 16
SHADER_FILE :: "shaders.hlsl"

float :: f32
float2 :: [2]float
float3 :: [3]float
float4 :: [4]float
float4x4 :: matrix[4, 4]float

panic_if_failed :: owin.panic_if_failed

Constants :: struct #align (16) {
	transform:    float4x4,
	projection:   float4x4,
	light_vector: float3,
}

wndproc :: proc "system" (hwnd: win32.HWND, msg: win32.UINT, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	context = runtime.default_context()
	switch msg {
	case win32.WM_DESTROY:
		owin.post_quit_message();return 0
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
	base_device: ^d3d11.IDevice = nil
	base_device_context: ^d3d11.IDeviceContext = nil
	panic_if_failed(d3d11.CreateDevice(nil, .HARDWARE, nil, {.BGRA_SUPPORT}, &feature_levels[0], len(feature_levels), d3d11.SDK_VERSION, &base_device, nil, &base_device_context))
	assert(base_device != nil);assert(base_device_context != nil)

	device: ^d3d11.IDevice = nil
	panic_if_failed(base_device->QueryInterface(d3d11.IDevice_UUID, (^rawptr)(&device)))
	assert(device != nil)

	device_context: ^d3d11.IDeviceContext = nil
	panic_if_failed(base_device_context->QueryInterface(d3d11.IDeviceContext_UUID, (^rawptr)(&device_context)))
	assert(device_context != nil)

	//-- Adapter Factory --//

	dxgi_factory: ^dxgi.IFactory2 = nil
	{
		raw_device: rawptr
		panic_if_failed(device->QueryInterface(dxgi.IDevice_UUID, &raw_device))
		dxgi_device: ^dxgi.IDevice = (^dxgi.IDevice)(raw_device)
		//panic_if_failed(device->QueryInterface(dxgi.IDevice_UUID, (^rawptr)(&dxgi_device)))
		assert(dxgi_device != nil)

		dxgi_adapter: ^dxgi.IAdapter = nil
		panic_if_failed(dxgi_device->GetAdapter(&dxgi_adapter))
		assert(dxgi_adapter != nil)

		panic_if_failed(dxgi_adapter->GetParent(dxgi.IFactory2_UUID, (^rawptr)(&dxgi_factory)))
	}
	assert(dxgi_factory != nil)

	//-- Swap Chain --//

	swap_chain_desc := dxgi.SWAP_CHAIN_DESC1 {
		Width = 0, // use window width
		Height = 0, // use window height
		Format = .B8G8R8A8_UNORM_SRGB,
		Stereo = false,
		SampleDesc = {Count = 1, Quality = 0},
		BufferUsage = {.RENDER_TARGET_OUTPUT},
		BufferCount = 2,
		Scaling = .STRETCH,
		SwapEffect = .DISCARD, // prefer DXGI_SWAP_EFFECT_FLIP_DISCARD, see Minimal D3D11 pt2
		AlphaMode = .UNSPECIFIED,
		Flags = {},
	}
	swap_chain: ^dxgi.ISwapChain1 = nil
	panic_if_failed(dxgi_factory->CreateSwapChainForHwnd(device, hwnd, &swap_chain_desc, nil, nil, &swap_chain))
	assert(swap_chain != nil)
	//defer swap_chain->Release()

	//-- Frame Buffer --//

	frame_buffer_tex: ^d3d11.ITexture2D = nil
	panic_if_failed(swap_chain->GetBuffer(0, d3d11.ITexture2D_UUID, (^rawptr)(&frame_buffer_tex)))
	assert(frame_buffer_tex != nil)

	frame_buffer_rtv: ^d3d11.IRenderTargetView = nil
	panic_if_failed(device->CreateRenderTargetView(frame_buffer_tex, nil, &frame_buffer_rtv))
	assert(frame_buffer_rtv != nil)

	//-- Frame Depth Buffer --//

	depth_buffer_desc: d3d11.TEXTURE2D_DESC
	frame_buffer_tex->GetDesc(&depth_buffer_desc) // copy from frame buffer properties
	depth_buffer_desc.Format = .D24_UNORM_S8_UINT
	depth_buffer_desc.BindFlags = {.DEPTH_STENCIL}

	depth_buffer_tex: ^d3d11.ITexture2D = nil
	panic_if_failed(device->CreateTexture2D(&depth_buffer_desc, nil, &depth_buffer_tex))
	assert(depth_buffer_tex != nil)

	depth_buffer_dsv: ^d3d11.IDepthStencilView = nil
	panic_if_failed(device->CreateDepthStencilView(depth_buffer_tex, nil, &depth_buffer_dsv))
	assert(depth_buffer_dsv != nil)

	//-- framebuffer_vs --//

	vs_blob: ^d3d11.IBlob = nil
	d3dc.Compile(raw_data(shaders_hlsl), len(shaders_hlsl), SHADER_FILE, nil, nil, "vs_main", "vs_5_0", 0, 0, &vs_blob, nil)
	assert(vs_blob != nil)

	vertex_shader: ^d3d11.IVertexShader = nil
	device->CreateVertexShader(vs_blob->GetBufferPointer(), vs_blob->GetBufferSize(), nil, &vertex_shader)

	// odinfmt: disable
	input_element_desc := [?]d3d11.INPUT_ELEMENT_DESC {
		{"POS", 0, .R32G32B32_FLOAT, 0,                            0, .VERTEX_DATA, 0},
		{"NOR", 0, .R32G32B32_FLOAT, 0, d3d11.APPEND_ALIGNED_ELEMENT, .VERTEX_DATA, 0},
		{"TEX", 0, .R32G32_FLOAT,    0, d3d11.APPEND_ALIGNED_ELEMENT, .VERTEX_DATA, 0},
		{"COL", 0, .R32G32B32_FLOAT, 0, d3d11.APPEND_ALIGNED_ELEMENT, .VERTEX_DATA, 0},
	}
	// odinfmt: enable
	input_layout: ^d3d11.IInputLayout
	device->CreateInputLayout(&input_element_desc[0], len(input_element_desc), vs_blob->GetBufferPointer(), vs_blob->GetBufferSize(), &input_layout)

	//-- framebuffer_ps --//

	ps_blob: ^d3d11.IBlob
	panic_if_failed(d3dc.Compile(raw_data(shaders_hlsl), len(shaders_hlsl), SHADER_FILE, nil, nil, "ps_main", "ps_5_0", 0, 0, &ps_blob, nil))
	assert(ps_blob != nil)

	pixel_shader: ^d3d11.IPixelShader
	panic_if_failed(device->CreatePixelShader(ps_blob->GetBufferPointer(), ps_blob->GetBufferSize(), nil, &pixel_shader))

	//-- debug_vs --//

	debug_vs_blob: ^d3d11.IBlob
	panic_if_failed(d3dc.Compile(raw_data(shaders_hlsl), len(shaders_hlsl), SHADER_FILE, nil, nil, "debug_vs", "vs_5_0", 0, 0, &debug_vs_blob, nil))
	assert(debug_vs_blob != nil)

	debug_vs: ^d3d11.IVertexShader
	panic_if_failed(device->CreateVertexShader(debug_vs_blob->GetBufferPointer(), debug_vs_blob->GetBufferSize(), nil, &debug_vs))
	assert(debug_vs != nil)

	//-- debug_ps --//

	debug_ps_blob: ^d3d11.IBlob
	panic_if_failed(d3dc.Compile(raw_data(shaders_hlsl), len(shaders_hlsl), SHADER_FILE, nil, nil, "debug_ps", "ps_5_0", 0, 0, &debug_ps_blob, nil))
	assert(debug_ps_blob != nil)

	debug_ps: ^d3d11.IPixelShader
	panic_if_failed(device->CreatePixelShader(debug_ps_blob->GetBufferPointer(), debug_ps_blob->GetBufferSize(), nil, &debug_ps))
	assert(debug_ps != nil)

	///////////////////////////////////////////////////////////////////////////////////////////////

	rasterizer_desc := d3d11.RASTERIZER_DESC {
		FillMode = .SOLID,
		CullMode = .BACK,
	}
	rasterizer_state: ^d3d11.IRasterizerState
	panic_if_failed(device->CreateRasterizerState(&rasterizer_desc, &rasterizer_state))

	sampler_desc := d3d11.SAMPLER_DESC {
		Filter         = .MIN_MAG_MIP_POINT,
		AddressU       = .WRAP,
		AddressV       = .WRAP,
		AddressW       = .WRAP,
		ComparisonFunc = .NEVER,
	}
	sampler_state: ^d3d11.ISamplerState
	panic_if_failed(device->CreateSamplerState(&sampler_desc, &sampler_state))

	depth_stencil_desc := d3d11.DEPTH_STENCIL_DESC {
		DepthEnable    = true,
		DepthWriteMask = .ALL,
		DepthFunc      = .LESS,
	}
	depth_stencil_state: ^d3d11.IDepthStencilState
	panic_if_failed(device->CreateDepthStencilState(&depth_stencil_desc, &depth_stencil_state))

	///////////////////////////////////////////////////////////////////////////////////////////////

	constant_buffer_desc := d3d11.BUFFER_DESC {
		ByteWidth      = size_of(Constants),
		Usage          = .DYNAMIC,
		BindFlags      = {.CONSTANT_BUFFER},
		CPUAccessFlags = {.WRITE},
	}
	constant_buffer: ^d3d11.IBuffer
	panic_if_failed(device->CreateBuffer(&constant_buffer_desc, nil, &constant_buffer))

	vertex_buffer_desc := d3d11.BUFFER_DESC {
		ByteWidth = size_of(vertex_data),
		Usage     = .IMMUTABLE,
		BindFlags = {.VERTEX_BUFFER},
	}
	vertex_buffer: ^d3d11.IBuffer
	panic_if_failed(device->CreateBuffer(&vertex_buffer_desc, &d3d11.SUBRESOURCE_DATA{pSysMem = &vertex_data[0], SysMemPitch = size_of(vertex_data)}, &vertex_buffer))

	index_buffer_desc := d3d11.BUFFER_DESC {
		ByteWidth = size_of(index_data),
		Usage     = .IMMUTABLE,
		BindFlags = {.INDEX_BUFFER},
	}
	index_buffer: ^d3d11.IBuffer
	device->CreateBuffer(&index_buffer_desc, &d3d11.SUBRESOURCE_DATA{pSysMem = &index_data[0], SysMemPitch = size_of(index_data)}, &index_buffer)

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
		SysMemPitch = TEXTURE_WIDTH * 4,
	}

	texture: ^d3d11.ITexture2D
	panic_if_failed(device->CreateTexture2D(&texture_desc, &texture_data, &texture))
	assert(texture != nil)

	texture_view: ^d3d11.IShaderResourceView
	panic_if_failed(device->CreateShaderResourceView(texture, nil, &texture_view))
	assert(texture_view != nil)

	///////////////////////////////////////////////////////////////////////////////////////////////

	vertex_buffer_stride: u32 = 11 * size_of(u32)
	vertex_buffer_offset: u32 = 0

	model_rotation := float3{0.0, 0.0, 0.0}
	model_translation := float3{0.0, 0.0, 4.0}

	owin.show_and_update_window(hwnd)

	client_size := owin.get_client_size(hwnd)
	fmt.println("client_size", client_size, depth_buffer_desc.Width, depth_buffer_desc.Height)

	msg: win32.MSG
	for owin.pull_messages(&msg) {

		viewport := d3d11.VIEWPORT{0, 0, f32(depth_buffer_desc.Width), f32(depth_buffer_desc.Height), 0, 1}
		fov, aspect, near, far: f32 = math.RAD_PER_DEG * 53, viewport.Width / viewport.Height, 1, 9
		//fmt.println("fov, aspect, near, far:", fov, aspect, near, far)
		//h : f32 = 1
		rotate := linalg.matrix4_from_euler_angles_xyz_f32(expand_values(model_rotation))
		translate := linalg.matrix4_translate_f32(model_translation)

		model_rotation += {0.005, 0.009, 0.001}

		//-- Update Constants --//
		{
			mapped_subresource: d3d11.MAPPED_SUBRESOURCE
			panic_if_failed(device_context->Map(constant_buffer, 0, .WRITE_DISCARD, {}, &mapped_subresource))
			defer device_context->Unmap(constant_buffer, 0)
			constants := (^Constants)(mapped_subresource.pData)
			constants.transform = translate * rotate
			constants.light_vector = {+1, -1, +1}
			// constants.projection = {
			// 	2 * near / aspect, 0, 0, 0,
			// 	0, 2 * near / h, 0, 0,
			// 	0, 0, far / (far - near), near * far / (near - far),
			// 	0, 0, 1, 0,
			// }
			// fmt.println("projection:", constants.projection)
			constants.projection = linalg.matrix4_perspective_f32(fov, aspect, near, far, false)
			// fmt.println("projection:", constants.projection)
		}

		//-- Render Frame --//

		device_context->ClearRenderTargetView(frame_buffer_rtv, &[4]f32{0.25, 0.5, 1.0, 1.0})
		device_context->ClearDepthStencilView(depth_buffer_dsv, {.DEPTH}, 1, 0)

		device_context->IASetPrimitiveTopology(.TRIANGLELIST)
		device_context->IASetInputLayout(input_layout)
		device_context->IASetVertexBuffers(0, 1, &vertex_buffer, &vertex_buffer_stride, &vertex_buffer_offset)
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

		device_context->DrawIndexed(len(index_data), 0, 0)

		///////////////////////////////////////////////////////////////////////////////////////////

		//device_context->OMSetDepthStencilState(nil, 0)
		device_context->IASetPrimitiveTopology(.TRIANGLESTRIP)
		device_context->PSSetShaderResources(0, 1, &texture_view)
		device_context->VSSetShader(debug_vs, nil, 0)
		device_context->PSSetShader(debug_ps, nil, 0)
		device_context->Draw(4, 0)

		///////////////////////////////////////////////////////////////////////////////////////////

		panic_if_failed(swap_chain->Present(1, {}))
		//owin_dxgi.present(swap_chain)
	}

	exit_code = int(msg.wParam)
	fmt.println("Done.")
	return
}

shaders_hlsl := #load(SHADER_FILE)

main :: proc() {
	when intrinsics.is_package_imported("obug") {
		os.exit(obug.tracked_run(run))
	} else {
		os.exit(run())
	}
}

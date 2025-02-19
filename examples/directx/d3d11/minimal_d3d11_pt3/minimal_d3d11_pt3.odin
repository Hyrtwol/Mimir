// Based off Minimal D3D11 pt3 https://gist.github.com/d7samurai/abab8a580d0298cb2f34a44eec41d39d
package minimal_d3d11_pt3

import "base:intrinsics"
import "base:runtime"
import "core:fmt"
import "core:os"
import "core:math"
import "core:math/linalg"
//import hlm "core:math/linalg/hlsl"
import win32 "core:sys/windows"
import owin "libs:tlc/win32app"
import "shared:obug"
import d3d11 "vendor:directx/d3d11"
import d3dc "vendor:directx/d3d_compiler"
import dxgi "vendor:directx/dxgi"
import owin_dxgi "libs:tlc/win32app/owin_dxgi"

TITLE :: "Minimal D3D11 pt3"
WIDTH :: 1920 / 2
HEIGHT :: WIDTH * 9 / 16
SHADER_FILE :: "shaders.hlsl"

float :: f32
float2 :: [2]float
float3 :: [3]float
float4 :: [4]float
float4x4 :: matrix[4, 4]float

panic_if_failed :: owin.panic_if_failed

show_shadowmap := true

frame_buffer_clear_color := float4{0.01, 0.02, 0.03, 1.0}
ModelRotationStep: float4 = {0.001, 0.005, 0.003, 0}
nullSRV: ^d3d11.IShaderResourceView = nil // null srv used for unbinding resources

// todo figure out why it dont work with align 16 and matching the vectors from the shader, for now all are float4
Constants :: struct #align (16) {
	CameraProjection: float4x4,
	LightProjection:  float4x4,
	LightRotation:    float4,
	ModelRotation:    float4,
	ModelTranslation: float4,
	ShadowmapSize:    float4,
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
		case 's':
			show_shadowmap = !show_shadowmap
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
		dxgi_device: ^dxgi.IDevice = nil
		panic_if_failed(device->QueryInterface(dxgi.IDevice_UUID, (^rawptr)(&dxgi_device)))
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
	swap_chain: ^dxgi.ISwapChain1 = nil
	panic_if_failed(dxgi_factory->CreateSwapChainForHwnd(device, hwnd, &swap_chain_desc, nil, nil, &swap_chain))
	assert(swap_chain != nil)
	//defer swap_chain->Release()

	//-- Frame Buffer --//

	frame_buffer_tex: ^d3d11.ITexture2D = nil
	panic_if_failed(swap_chain->GetBuffer(0, d3d11.ITexture2D_UUID, (^rawptr)(&frame_buffer_tex)))
	assert(frame_buffer_tex != nil)

	frame_buffer_desc: d3d11.RENDER_TARGET_VIEW_DESC = {
		Format        = .B8G8R8A8_UNORM_SRGB, // ... so do this to get _SRGB swap chain (rendertarget view)
		ViewDimension = .TEXTURE2D,
	}

	frame_buffer_rtv: ^d3d11.IRenderTargetView = nil
	panic_if_failed(device->CreateRenderTargetView(frame_buffer_tex, &frame_buffer_desc, &frame_buffer_rtv))
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

	//-- Shadowmap Depth Buffer --//

	shadowmapDepthDesc: d3d11.TEXTURE2D_DESC = {
		Width = 2048,
		Height = 2048,
		MipLevels = 1,
		ArraySize = 1,
		Format = .R32_TYPELESS,
		SampleDesc = dxgi.SAMPLE_DESC{Count = 1},
		Usage = .DEFAULT,
		BindFlags = {.DEPTH_STENCIL, .SHADER_RESOURCE},
	}
	//fmt.println("shadowmapDepthDesc:", shadowmapDepthDesc)
	shadowmapDepthTexture: ^d3d11.ITexture2D = nil
	panic_if_failed(device->CreateTexture2D(&shadowmapDepthDesc, nil, &shadowmapDepthTexture))
	assert(shadowmapDepthTexture != nil)

	shadowmapDSVdesc: d3d11.DEPTH_STENCIL_VIEW_DESC = {
		Format        = .D32_FLOAT,
		ViewDimension = .TEXTURE2D,
	}
	//fmt.println("shadowmapDSVdesc:", shadowmapDSVdesc)
	shadowmapDSV: ^d3d11.IDepthStencilView = nil
	panic_if_failed(device->CreateDepthStencilView(shadowmapDepthTexture, &shadowmapDSVdesc, &shadowmapDSV))
	assert(shadowmapDSV != nil)

	shadowmapSRVdesc: d3d11.SHADER_RESOURCE_VIEW_DESC = {
		Format = .R32_FLOAT,
		ViewDimension = .TEXTURE2D,
		Texture2D = d3d11.TEX2D_SRV{MipLevels = 1},
	}

	shadowmapSRV: ^d3d11.IShaderResourceView = nil
	panic_if_failed(device->CreateShaderResourceView(shadowmapDepthTexture, &shadowmapSRVdesc, &shadowmapSRV))
	assert(shadowmapSRV != nil)

	//-- Constant Buffer --//

	constantBufferDesc := d3d11.BUFFER_DESC {
		ByteWidth      = size_of(Constants),
		Usage          = .DYNAMIC,
		BindFlags      = {.CONSTANT_BUFFER},
		CPUAccessFlags = {.WRITE},
	}

	constantBuffer: ^d3d11.IBuffer = nil
	panic_if_failed(device->CreateBuffer(&constantBufferDesc, nil, &constantBuffer))
	assert(constantBuffer != nil)

	//-- Vertex Buffer --//

	vertexBufferDesc := d3d11.BUFFER_DESC {
		ByteWidth           = size_of(vertexData),
		Usage               = .IMMUTABLE,
		BindFlags           = {.SHADER_RESOURCE}, // using regular shader resource as vertex buffer for manual vertex fetch
		MiscFlags           = {.BUFFER_STRUCTURED},
		StructureByteStride = 5 * size_of(f32), // 5 floats per vertex (float3 position, float2 texcoord)
	}

	vertexBufferData := d3d11.SUBRESOURCE_DATA {
		pSysMem     = &vertexData[0],
		SysMemPitch = vertexBufferDesc.ByteWidth,
	}

	vertexBuffer: ^d3d11.IBuffer = nil
	panic_if_failed(device->CreateBuffer(&vertexBufferDesc, &vertexBufferData, &vertexBuffer))
	assert(vertexBuffer != nil)

	vertexBufferSRVdesc: d3d11.SHADER_RESOURCE_VIEW_DESC = {
		Format = .UNKNOWN,
		ViewDimension = .BUFFER,
		Buffer = d3d11.BUFFER_SRV{NumElements = vertexBufferDesc.ByteWidth / vertexBufferDesc.StructureByteStride},
	}

	vertexBufferSRV: ^d3d11.IShaderResourceView = nil
	panic_if_failed(device->CreateShaderResourceView(vertexBuffer, &vertexBufferSRVdesc, &vertexBufferSRV))
	assert(vertexBufferSRV != nil)

	//-- Depth Stencil --//

	depthStencilDesc: d3d11.DEPTH_STENCIL_DESC = {
		DepthEnable    = true,
		DepthWriteMask = .ALL,
		DepthFunc      = .LESS,
	}
	depthStencilState: ^d3d11.IDepthStencilState = nil
	panic_if_failed(device->CreateDepthStencilState(&depthStencilDesc, &depthStencilState))
	assert(depthStencilState != nil)

	//-- Rasterizer States --//

	rasterizerDesc := d3d11.RASTERIZER_DESC {
		FillMode = .SOLID,
		CullMode = .BACK,
	}
	cullBackRS: ^d3d11.IRasterizerState = nil
	panic_if_failed(device->CreateRasterizerState(&rasterizerDesc, &cullBackRS))
	assert(cullBackRS != nil)

	rasterizerDesc.CullMode = .FRONT
	cullFrontRS: ^d3d11.IRasterizerState = nil
	panic_if_failed(device->CreateRasterizerState(&rasterizerDesc, &cullFrontRS))
	assert(cullFrontRS != nil)


	compile_flags: u32 = 0

	//-- framebuffer_vs --//

	framebufferVSBlob: ^d3d11.IBlob = nil
	panic_if_failed(d3dc.Compile(raw_data(shaders_hlsl), len(shaders_hlsl), SHADER_FILE, nil, nil, "framebuffer_vs", "vs_5_0", compile_flags, 0, &framebufferVSBlob, nil))
	assert(framebufferVSBlob != nil)

	framebufferVS: ^d3d11.IVertexShader = nil
	panic_if_failed(device->CreateVertexShader(framebufferVSBlob->GetBufferPointer(), framebufferVSBlob->GetBufferSize(), nil, &framebufferVS))
	assert(framebufferVS != nil)

	//-- framebuffer_ps --//

	framebufferPSBlob: ^d3d11.IBlob = nil
	panic_if_failed(d3dc.Compile(raw_data(shaders_hlsl), len(shaders_hlsl), SHADER_FILE, nil, nil, "framebuffer_ps", "ps_5_0", compile_flags, 0, &framebufferPSBlob, nil))
	assert(framebufferPSBlob != nil)

	framebufferPS: ^d3d11.IPixelShader = nil
	panic_if_failed(device->CreatePixelShader(framebufferPSBlob->GetBufferPointer(), framebufferPSBlob->GetBufferSize(), nil, &framebufferPS))
	assert(framebufferPS != nil)

	//-- shadowmap_vs --//

	shadowmapVSBlob: ^d3d11.IBlob = nil
	panic_if_failed(d3dc.Compile(raw_data(shaders_hlsl), len(shaders_hlsl), SHADER_FILE, nil, nil, "shadowmap_vs", "vs_5_0", compile_flags, 0, &shadowmapVSBlob, nil))
	assert(shadowmapVSBlob != nil)

	shadowmapVS: ^d3d11.IVertexShader = nil
	panic_if_failed(device->CreateVertexShader(shadowmapVSBlob->GetBufferPointer(), shadowmapVSBlob->GetBufferSize(), nil, &shadowmapVS))
	assert(shadowmapVS != nil)

	//-- debug_vs --//

	debug_vs_blob: ^d3d11.IBlob = nil
	panic_if_failed(d3dc.Compile(raw_data(shaders_hlsl), len(shaders_hlsl), SHADER_FILE, nil, nil, "debug_vs", "vs_5_0", compile_flags, 0, &debug_vs_blob, nil))
	assert(debug_vs_blob != nil)

	debug_vs: ^d3d11.IVertexShader = nil
	panic_if_failed(device->CreateVertexShader(debug_vs_blob->GetBufferPointer(), debug_vs_blob->GetBufferSize(), nil, &debug_vs))
	assert(debug_vs != nil)

	//-- debug_ps --//

	debug_ps_blob: ^d3d11.IBlob = nil
	panic_if_failed(d3dc.Compile(raw_data(shaders_hlsl), len(shaders_hlsl), SHADER_FILE, nil, nil, "debug_ps", "ps_5_0", compile_flags, 0, &debug_ps_blob, nil))
	assert(debug_ps_blob != nil)

	debug_ps: ^d3d11.IPixelShader = nil
	panic_if_failed(device->CreatePixelShader(debug_ps_blob->GetBufferPointer(), debug_ps_blob->GetBufferSize(), nil, &debug_ps))
	assert(debug_ps != nil)

	//-- Viewport --//

	framebufferVP: d3d11.VIEWPORT = {0, 0, f32(depth_buffer_desc.Width), f32(depth_buffer_desc.Height), 0, 1}
	shadowmapVP: d3d11.VIEWPORT = {0, 0, f32(shadowmapDepthDesc.Width), f32(shadowmapDepthDesc.Height), 0, 1}

	//-- Constant Buffer --//
	fov, aspect, near, far: f32 = math.RAD_PER_DEG * 60, framebufferVP.Width / framebufferVP.Height, 1, 20
	fmt.println("fov, aspect, near, far:", fov, aspect, near, far)

	constants: Constants = {
		// camera projection matrix (perspective)
		// CameraProjection = float4x4{
		// 	2.0 / (framebufferVP.Width / framebufferVP.Height), 0, 0, 0,
		// 	0, 2, 0, 0,
		// 	0, 0, 1.125, 1,
		// 	0, 0, -1.125, 0,
		// },
		CameraProjection = linalg.transpose( linalg.matrix4_perspective_f32(fov, aspect, near, far, false) ),
		// light projection matrix (orthographic)
		LightProjection  = float4x4{0.5, 0, 0, 0, 0, 0.5, 0, 0, 0, 0, 0.125, 0, 0, 0, -0.125, 1},
		LightRotation    = {0.8, 0.6, 0.0, 0},
		ModelRotation    = {0.0, 0.0, 0.0, 0},
		ModelTranslation = {0.0, 0.0, 4.0, 0},
		ShadowmapSize    = {shadowmapVP.Width, shadowmapVP.Height, 0, 0},
	}
	fmt.println("projection:", constants.CameraProjection)
	// constants.CameraProjection = linalg.transpose( linalg.matrix4_perspective_f32(fov, aspect, near, far, false) )
	// fmt.println("projection:", constants.CameraProjection)

	fmt.println("constants:", constants)

	//-- Main Loop --//

	owin.show_and_update_window(hwnd)

	msg: win32.MSG
	for owin.pull_messages(&msg) {

		constants.ModelRotation += ModelRotationStep

		//-- Update Constants --//
		{
			mappedSubresource: d3d11.MAPPED_SUBRESOURCE
			panic_if_failed(device_context->Map(constantBuffer, 0, .WRITE_DISCARD, {}, &mappedSubresource))
			defer device_context->Unmap(constantBuffer, 0)
			(^Constants)(mappedSubresource.pData)^ = constants
		}

		//-- Render Shadowmap --//

		device_context->ClearDepthStencilView(shadowmapDSV, {.DEPTH}, 1, 0)

		device_context->OMSetRenderTargets(0, nil, shadowmapDSV) // null rendertarget for depth only
		device_context->OMSetDepthStencilState(depthStencilState, 0)

		device_context->IASetPrimitiveTopology(.TRIANGLESTRIP) // using triangle strip this time

		device_context->VSSetConstantBuffers(0, 1, &constantBuffer)
		device_context->VSSetShaderResources(0, 1, &vertexBufferSRV)
		device_context->VSSetShader(shadowmapVS, nil, 0)

		device_context->RSSetViewports(1, &shadowmapVP)
		device_context->RSSetState(cullFrontRS)

		device_context->PSSetShader(nil, nil, 0) // null pixelshader for depth only

		device_context->DrawInstanced(8, 24, 0, 0) // render shadowmap (light pov)

		//-- Render Frame --//

		device_context->ClearRenderTargetView(frame_buffer_rtv, &frame_buffer_clear_color)
		device_context->ClearDepthStencilView(depth_buffer_dsv, {.DEPTH}, 1, 0)

		device_context->OMSetRenderTargets(1, &frame_buffer_rtv, depth_buffer_dsv)

		device_context->VSSetShader(framebufferVS, nil, 0)

		device_context->RSSetViewports(1, &framebufferVP)
		device_context->RSSetState(cullBackRS)

		device_context->PSSetShaderResources(1, 1, &shadowmapSRV)
		device_context->PSSetShader(framebufferPS, nil, 0)

		device_context->DrawInstanced(8, 24, 0, 0) // render framebuffer (camera pov)

		//-- Render Shadowmap to Frame (debug) --//
		if show_shadowmap {
			device_context->VSSetShader(debug_vs, nil, 0)
			device_context->PSSetShader(debug_ps, nil, 0)
			device_context->Draw(4, 0)
		}

		//-- Reset Shader Resources --//

		device_context->PSSetShaderResources(1, 1, &nullSRV) // release shadowmap as srv to avoid srv/dsv conflict

		//-- End Of Frame --//

		panic_if_failed(swap_chain->Present(1, {}))
	}

	exit_code = int(msg.wParam)
	fmt.println("Done.")
	return
}

shaders_hlsl := #load(SHADER_FILE)


// odinfmt: disable

// pos.x, pos.y, pos.z, tex.u, tex.v, ...
vertexData := [?]f32{
	-1   , 1   , -1   , 0  , 0,
	 1   , 1   , -1   , 9.5, 0,
	-0.58, 0.58, -1   , 2  , 2,
	 0.58, 0.58, -1   , 7.5, 2,
	-0.58, 0.58, -1   , 0  , 0,
	 0.58, 0.58, -1   , 0  , 0,
	-0.58, 0.58, -0.58, 0  , 0,
	 0.58, 0.58, -0.58, 0  , 0,
}
// odinfmt: enable

main :: proc() {
	when intrinsics.is_package_imported("obug") {
		os.exit(obug.tracked_run(run))
	} else {
		os.exit(run())
	}
}

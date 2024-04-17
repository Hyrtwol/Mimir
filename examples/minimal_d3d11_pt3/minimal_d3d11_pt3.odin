package minimal_d3d11_pt3

import "base:intrinsics"
import "core:fmt"
import hlm "core:math/linalg/hlsl"
import "core:runtime"
import win32 "core:sys/windows"
import win32app "libs:tlc/win32app"
import d3d11 "vendor:directx/d3d11"
import d3dc "vendor:directx/d3d_compiler"
import dxgi "vendor:directx/dxgi"

// Based off Minimal D3D11 pt3 https://gist.github.com/d7samurai/abab8a580d0298cb2f34a44eec41d39d

TITLE :: "Minimal D3D11 pt3"
WIDTH :: 1920 / 2
HEIGHT :: WIDTH * 9 / 16
SHADER_FILE :: "shaders.hlsl"

float2 :: hlm.float2
float3 :: hlm.float3
float4 :: hlm.float4
float4x4 :: hlm.float4x4

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
		{win32app.post_quit_message(0);return 0}
	case win32.WM_ERASEBKGND:
		return 1 // skip
	case win32.WM_CHAR:
		{
			switch wparam {
			case '\x1b':
				win32.DestroyWindow(hwnd) // ESC
			case 's':
				show_shadowmap = !show_shadowmap
			}
			return 0
		}
	case:
		return win32.DefWindowProcW(hwnd, msg, wparam, lparam)
	}
}

main :: proc() {

	settings := win32app.create_window_settings(TITLE, WIDTH, HEIGHT, wndproc)
	hwnd := win32app.register_and_create_window(&settings)
	assert(hwnd != nil)

	//-- Create Device --//

	feature_levels := [?]d3d11.FEATURE_LEVEL{._11_1}
	base_device: ^d3d11.IDevice
	base_device_context: ^d3d11.IDeviceContext
	hr := d3d11.CreateDevice(nil, .HARDWARE, nil, {.BGRA_SUPPORT}, &feature_levels[0], len(feature_levels), d3d11.SDK_VERSION, &base_device, nil, &base_device_context)
	assert(hr == 0);assert(base_device != nil);assert(base_device_context != nil)

	device: ^d3d11.IDevice
	hr = base_device->QueryInterface(d3d11.IDevice_UUID, (^rawptr)(&device))
	assert(hr == 0);assert(device != nil)

	device_context: ^d3d11.IDeviceContext
	hr = base_device_context->QueryInterface(d3d11.IDeviceContext_UUID, (^rawptr)(&device_context))
	assert(hr == 0);assert(device_context != nil)

	//-- Adapter Factory --//

	dxgi_device: ^dxgi.IDevice
	hr = device->QueryInterface(dxgi.IDevice_UUID, (^rawptr)(&dxgi_device))
	assert(hr == 0);assert(dxgi_device != nil)

	dxgi_adapter: ^dxgi.IAdapter
	hr = dxgi_device->GetAdapter(&dxgi_adapter)
	assert(hr == 0);assert(dxgi_adapter != nil)

	dxgi_factory: ^dxgi.IFactory2
	hr = dxgi_adapter->GetParent(dxgi.IFactory2_UUID, (^rawptr)(&dxgi_factory))
	assert(hr == 0);assert(dxgi_factory != nil)

	//-- Swap Chain --//

	swap_chain_desc := dxgi.SWAP_CHAIN_DESC1 {
		Width = 0, // use window width
		Height = 0, // use window height
		Format = .B8G8R8A8_UNORM, // can't specify _SRGB here when using DXGI_SWAP_EFFECT_FLIP_* ...
		Stereo = false,
		SampleDesc = {Count = 1, Quality = 0},
		BufferUsage = {.RENDER_TARGET_OUTPUT},
		BufferCount = 2,
		Scaling = .STRETCH,
		SwapEffect = .FLIP_DISCARD,
		AlphaMode = .UNSPECIFIED,
		Flags = {},
	}
	swap_chain: ^dxgi.ISwapChain1
	hr = dxgi_factory->CreateSwapChainForHwnd(device, hwnd, &swap_chain_desc, nil, nil, &swap_chain)
	assert(hr == 0);assert(swap_chain != nil)
	//defer swap_chain->Release()

	//-- Frame Buffer --//

	frame_buffer_tex: ^d3d11.ITexture2D
	hr = swap_chain->GetBuffer(0, d3d11.ITexture2D_UUID, (^rawptr)(&frame_buffer_tex))
	assert(hr == 0);assert(frame_buffer_tex != nil)

	frame_buffer_desc: d3d11.RENDER_TARGET_VIEW_DESC = {
		Format        = .B8G8R8A8_UNORM_SRGB, // ... so do this to get _SRGB swap chain (rendertarget view)
		ViewDimension = .TEXTURE2D,
	}

	frame_buffer_rtv: ^d3d11.IRenderTargetView
	hr = device->CreateRenderTargetView(frame_buffer_tex, &frame_buffer_desc, &frame_buffer_rtv)
	assert(hr == 0);assert(frame_buffer_rtv != nil)

	//-- Frame Depth Buffer --//

	depth_buffer_desc: d3d11.TEXTURE2D_DESC
	frame_buffer_tex->GetDesc(&depth_buffer_desc) // copy from frame buffer properties
	depth_buffer_desc.Format = .D24_UNORM_S8_UINT
	depth_buffer_desc.BindFlags = {.DEPTH_STENCIL}

	depth_buffer_tex: ^d3d11.ITexture2D
	hr = device->CreateTexture2D(&depth_buffer_desc, nil, &depth_buffer_tex)
	assert(hr == 0);assert(depth_buffer_tex != nil)

	depth_buffer_dsv: ^d3d11.IDepthStencilView
	hr = device->CreateDepthStencilView(depth_buffer_tex, nil, &depth_buffer_dsv)
	assert(hr == 0);assert(depth_buffer_dsv != nil)

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
	//fmt.printf("%s %v\n", "shadowmapDepthDesc", shadowmapDepthDesc)
	shadowmapDepthTexture: ^d3d11.ITexture2D
	hr = device->CreateTexture2D(&shadowmapDepthDesc, nil, &shadowmapDepthTexture)
	assert(hr == 0);assert(shadowmapDepthTexture != nil)

	shadowmapDSVdesc: d3d11.DEPTH_STENCIL_VIEW_DESC = {
		Format        = .D32_FLOAT,
		ViewDimension = .TEXTURE2D,
	}
	//fmt.printf("%s %v\n", "shadowmapDSVdesc", shadowmapDSVdesc)
	shadowmapDSV: ^d3d11.IDepthStencilView
	hr = device->CreateDepthStencilView(shadowmapDepthTexture, &shadowmapDSVdesc, &shadowmapDSV)
	assert(hr == 0);assert(shadowmapDSV != nil)

	shadowmapSRVdesc: d3d11.SHADER_RESOURCE_VIEW_DESC = {
		Format = .R32_FLOAT,
		ViewDimension = .TEXTURE2D,
		Texture2D = d3d11.TEX2D_SRV{MipLevels = 1},
	}

	shadowmapSRV: ^d3d11.IShaderResourceView
	hr = device->CreateShaderResourceView(shadowmapDepthTexture, &shadowmapSRVdesc, &shadowmapSRV)
	assert(hr == 0);assert(shadowmapSRV != nil)

	//-- Constant Buffer --//

	constantBufferDesc := d3d11.BUFFER_DESC {
		ByteWidth      = size_of(Constants),
		Usage          = .DYNAMIC,
		BindFlags      = {.CONSTANT_BUFFER},
		CPUAccessFlags = {.WRITE},
	}

	constantBuffer: ^d3d11.IBuffer
	hr = device->CreateBuffer(&constantBufferDesc, nil, &constantBuffer)
	assert(hr == 0);assert(constantBuffer != nil)

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

	vertexBuffer: ^d3d11.IBuffer
	hr = device->CreateBuffer(&vertexBufferDesc, &vertexBufferData, &vertexBuffer)
	assert(hr == 0);assert(vertexBuffer != nil)

	vertexBufferSRVdesc: d3d11.SHADER_RESOURCE_VIEW_DESC = {
		Format = .UNKNOWN,
		ViewDimension = .BUFFER,
		Buffer = d3d11.BUFFER_SRV{NumElements = vertexBufferDesc.ByteWidth / vertexBufferDesc.StructureByteStride},
	}

	vertexBufferSRV: ^d3d11.IShaderResourceView
	hr = device->CreateShaderResourceView(vertexBuffer, &vertexBufferSRVdesc, &vertexBufferSRV)
	assert(hr == 0);assert(vertexBufferSRV != nil)

	//-- Depth Stencil --//

	depthStencilDesc: d3d11.DEPTH_STENCIL_DESC = {
		DepthEnable    = true,
		DepthWriteMask = .ALL,
		DepthFunc      = .LESS,
	}
	depthStencilState: ^d3d11.IDepthStencilState
	hr = device->CreateDepthStencilState(&depthStencilDesc, &depthStencilState)
	assert(hr == 0);assert(depthStencilState != nil)

	//-- Rasterizer States --//

	rasterizerDesc := d3d11.RASTERIZER_DESC {
		FillMode = .SOLID,
		CullMode = .BACK,
	}
	cullBackRS: ^d3d11.IRasterizerState
	hr = device->CreateRasterizerState(&rasterizerDesc, &cullBackRS)
	assert(hr == 0);assert(cullBackRS != nil)

	rasterizerDesc.CullMode = .FRONT
	cullFrontRS: ^d3d11.IRasterizerState
	hr = device->CreateRasterizerState(&rasterizerDesc, &cullFrontRS)
	assert(hr == 0);assert(cullFrontRS != nil)

	//-- framebuffer_vs --//

	framebufferVSBlob: ^d3d11.IBlob
	hr = d3dc.Compile(raw_data(shaders_hlsl), len(shaders_hlsl), SHADER_FILE, nil, nil, "framebuffer_vs", "vs_5_0", 0, 0, &framebufferVSBlob, nil)
	assert(hr == 0);assert(framebufferVSBlob != nil)

	framebufferVS: ^d3d11.IVertexShader
	hr = device->CreateVertexShader(framebufferVSBlob->GetBufferPointer(), framebufferVSBlob->GetBufferSize(), nil, &framebufferVS)
	assert(hr == 0);assert(framebufferVS != nil)

	//-- framebuffer_ps --//

	framebufferPSBlob: ^d3d11.IBlob
	hr = d3dc.Compile(raw_data(shaders_hlsl), len(shaders_hlsl), SHADER_FILE, nil, nil, "framebuffer_ps", "ps_5_0", 0, 0, &framebufferPSBlob, nil)
	assert(hr == 0);assert(framebufferPSBlob != nil)

	framebufferPS: ^d3d11.IPixelShader
	hr = device->CreatePixelShader(framebufferPSBlob->GetBufferPointer(), framebufferPSBlob->GetBufferSize(), nil, &framebufferPS)
	assert(hr == 0);assert(framebufferPS != nil)

	//-- shadowmap_vs --//

	shadowmapVSBlob: ^d3d11.IBlob
	hr = d3dc.Compile(raw_data(shaders_hlsl), len(shaders_hlsl), SHADER_FILE, nil, nil, "shadowmap_vs", "vs_5_0", 0, 0, &shadowmapVSBlob, nil)
	assert(hr == 0);assert(shadowmapVSBlob != nil)

	shadowmapVS: ^d3d11.IVertexShader
	hr = device->CreateVertexShader(shadowmapVSBlob->GetBufferPointer(), shadowmapVSBlob->GetBufferSize(), nil, &shadowmapVS)
	assert(hr == 0);assert(shadowmapVS != nil)

	//-- debug_vs --//

	debug_vs_blob: ^d3d11.IBlob
	hr = d3dc.Compile(raw_data(shaders_hlsl), len(shaders_hlsl), SHADER_FILE, nil, nil, "debug_vs", "vs_5_0", 0, 0, &debug_vs_blob, nil)
	assert(hr == 0);assert(debug_vs_blob != nil)

	debug_vs: ^d3d11.IVertexShader
	hr = device->CreateVertexShader(debug_vs_blob->GetBufferPointer(), debug_vs_blob->GetBufferSize(), nil, &debug_vs)
	assert(hr == 0);assert(debug_vs != nil)

	//-- debug_ps --//

	debug_ps_blob: ^d3d11.IBlob
	hr = d3dc.Compile(raw_data(shaders_hlsl), len(shaders_hlsl), SHADER_FILE, nil, nil, "debug_ps", "ps_5_0", 0, 0, &debug_ps_blob, nil)
	assert(hr == 0);assert(debug_ps_blob != nil)

	debug_ps: ^d3d11.IPixelShader
	hr = device->CreatePixelShader(debug_ps_blob->GetBufferPointer(), debug_ps_blob->GetBufferSize(), nil, &debug_ps)
	assert(hr == 0);assert(debug_ps != nil)

	//-- Viewport --//

	framebufferVP: d3d11.VIEWPORT = {0, 0, f32(depth_buffer_desc.Width), f32(depth_buffer_desc.Height), 0, 1}
	shadowmapVP: d3d11.VIEWPORT = {0, 0, f32(shadowmapDepthDesc.Width), f32(shadowmapDepthDesc.Height), 0, 1}

	//-- Constant Buffer --//

	constants: Constants = {
		// camera projection matrix (perspective)
		CameraProjection = float4x4{2.0 / (framebufferVP.Width / framebufferVP.Height), 0, 0, 0, 0, 2, 0, 0, 0, 0, 1.125, 1, 0, 0, -1.125, 0},
		// light projection matrix (orthographic)
		LightProjection  = float4x4{0.5, 0, 0, 0, 0, 0.5, 0, 0, 0, 0, 0.125, 0, 0, 0, -0.125, 1},
		LightRotation    = {0.8, 0.6, 0.0, 0},
		ModelRotation    = {0.0, 0.0, 0.0, 0},
		ModelTranslation = {0.0, 0.0, 4.0, 0},
		ShadowmapSize    = {shadowmapVP.Width, shadowmapVP.Height, 0, 0},
	}

	fmt.printf("%s %v\n", "constants", constants)

	//-- Main Loop --//

	win32.ShowWindow(hwnd, win32.SW_SHOWDEFAULT)
	win32.UpdateWindow(hwnd)

	for win32app.pull_messages() {

		constants.ModelRotation += ModelRotationStep

		//-- Update Constants --//
		{
			mappedSubresource: d3d11.MAPPED_SUBRESOURCE
			hr = device_context->Map(constantBuffer, 0, .WRITE_DISCARD, {}, &mappedSubresource)
			assert(hr == 0)
			(^Constants)(mappedSubresource.pData)^ = constants
			device_context->Unmap(constantBuffer, 0)
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

		device_context->ClearRenderTargetView(frame_buffer_rtv, transmute(^[4]f32)&frame_buffer_clear_color) // [4]f32
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

		swap_chain->Present(1, {})
	}

	fmt.print("DONE\n")
	//os.exit(int(msg.wParam))
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

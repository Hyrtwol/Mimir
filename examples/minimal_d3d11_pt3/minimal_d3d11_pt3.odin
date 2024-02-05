package minimal_d3d11_pt3

import "core:runtime"
import "core:fmt"
import "base:intrinsics"
import D3D11 "vendor:directx/d3d11"
import DXGI "vendor:directx/dxgi"
import d3dc "vendor:directx/d3d_compiler"
import glm "core:math/linalg/glsl"
import win32 "core:sys/windows"
import win32ex "shared:sys/windows"
import win32app "shared:tlc/win32app"

// Based off Minimal D3D11 pt3 https://gist.github.com/d7samurai/abab8a580d0298cb2f34a44eec41d39d

TITLE 	:: "Minimal D3D11 pt3"
WIDTH  	:: 1920 / 2
HEIGHT 	:: WIDTH * 9 / 16
CENTER  :: true

WM_CREATE :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	fmt.printf("WM_CREATE %v\n", hwnd)
	return 0
}

WM_DESTROY :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	fmt.printf("WM_DESTROY %v\n", hwnd)
	win32.PostQuitMessage(0)
	return 0
}

WM_ERASEBKGND :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	fmt.printf("WM_ERASEBKGND %v\n", hwnd)
	return 1
}

WM_SIZE :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	size := win32app.decode_lparam(lparam)
	newtitle := fmt.tprintf("%s %v\n", TITLE, size)
	fmt.printf("WM_SIZE %v\n", size)
	win32.SetWindowTextW(hwnd, win32.utf8_to_wstring(newtitle))
	return 0
}

WM_CHAR :: proc(hwnd: win32.HWND, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	switch wparam {
	case '\x1b': win32.DestroyWindow(hwnd) // ESC
	}
	return 0
}

wndproc :: proc "system" (hwnd: win32.HWND, msg: win32.UINT, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	context = runtime.default_context()
	switch msg {
	case win32.WM_CREATE:		return WM_CREATE(hwnd, wparam, lparam)
	case win32.WM_DESTROY:		return WM_DESTROY(hwnd, wparam, lparam)
	case win32.WM_ERASEBKGND:	return WM_ERASEBKGND(hwnd, wparam, lparam)
	case win32.WM_SIZE:			return WM_SIZE(hwnd, wparam, lparam)
	case win32.WM_CHAR:			return WM_CHAR(hwnd, wparam, lparam)
	case:						return win32.DefWindowProcW(hwnd, msg, wparam, lparam)
	}
}

main :: proc() {

	settings : win32app.window_settings = {
		title = TITLE,
		window_size = {WIDTH, HEIGHT},
		center = CENTER,
	}

	inst := win32app.get_instance()
	assert(inst != nil)
	atom := win32app.register_window_class(inst, wndproc)
	assert(atom != 0)
	hwnd := win32app.create_window(inst, atom, win32app.default_dwStyle, win32app.default_dwExStyle, &settings)
	assert(hwnd != nil)
	//if hwnd == nil { win32app.show_error_and_panic("CreateWindowEx failed") }

	///////////////////////////////////////////////////////////////////////////////////////////////

	feature_levels := [?]D3D11.FEATURE_LEVEL{._11_0}

	base_device: ^D3D11.IDevice
	base_device_context: ^D3D11.IDeviceContext

	hr := D3D11.CreateDevice(nil, .HARDWARE, nil, {.BGRA_SUPPORT}, &feature_levels[0], len(feature_levels), D3D11.SDK_VERSION, &base_device, nil, &base_device_context)
	assert(hr == 0)
	assert(base_device != nil)
	assert(base_device_context != nil)

	///////////////////////////////////////////////////////////////////////////////////////////////

	device: ^D3D11.IDevice
	hr = base_device->QueryInterface(D3D11.IDevice_UUID, (^rawptr)(&device))
	assert(hr == 0)
	assert(device != nil)

	device_context: ^D3D11.IDeviceContext
	hr = base_device_context->QueryInterface(D3D11.IDeviceContext_UUID, (^rawptr)(&device_context))
	assert(hr == 0)
	assert(device_context != nil)

	///////////////////////////////////////////////////////////////////////////////////////////////

	dxgi_device: ^DXGI.IDevice
	hr = device->QueryInterface(DXGI.IDevice_UUID, (^rawptr)(&dxgi_device))
	assert(hr == 0)
	assert(dxgi_device != nil)

	dxgi_adapter: ^DXGI.IAdapter
	hr = dxgi_device->GetAdapter(&dxgi_adapter)
	assert(hr == 0)
	assert(dxgi_adapter != nil)

	dxgi_factory: ^DXGI.IFactory2
	hr = dxgi_adapter->GetParent(DXGI.IFactory2_UUID, (^rawptr)(&dxgi_factory))
	assert(hr == 0)
	assert(dxgi_factory != nil)

	///////////////////////////////////////////////////////////////////////////////////////////////

	swapchain_desc := DXGI.SWAP_CHAIN_DESC1{
		Width  = 0, // use window width
		Height = 0, // use window height
		Format = .B8G8R8A8_UNORM, // can't specify _SRGB here when using DXGI_SWAP_EFFECT_FLIP_* ...
		Stereo = false,
		SampleDesc = {
			Count   = 1,
			Quality = 0,
		},
		BufferUsage = {.RENDER_TARGET_OUTPUT},
		BufferCount = 2,
		Scaling     = .STRETCH,
		SwapEffect  = .FLIP_DISCARD,
		AlphaMode   = .UNSPECIFIED,
		Flags       = {},
	}

	swapchain: ^DXGI.ISwapChain1
	hr = dxgi_factory->CreateSwapChainForHwnd(device, hwnd, &swapchain_desc, nil, nil, &swapchain)
	assert(hr == 0)
	assert(swapchain != nil)

	///////////////////////////////////////////////////////////////////////////////////////////////

	framebufferTexture: ^D3D11.ITexture2D
	hr = swapchain->GetBuffer(0, D3D11.ITexture2D_UUID, (^rawptr)(&framebufferTexture))
	assert(hr == 0)
	assert(framebufferTexture != nil)

    framebufferDesc: D3D11.RENDER_TARGET_VIEW_DESC = {
    	Format        = .B8G8R8A8_UNORM_SRGB, // ... so do this to get _SRGB swapchain (rendertarget view)
    	ViewDimension = .TEXTURE2D,
	}

	framebufferRTV: ^D3D11.IRenderTargetView
	hr = device->CreateRenderTargetView(framebufferTexture, &framebufferDesc, &framebufferRTV)
	assert(hr == 0)
	assert(framebufferRTV != nil)

    ///////////////////////////////////////////////////////////////////////////////////////////////

	framebufferDepthDesc: D3D11.TEXTURE2D_DESC
	framebufferTexture->GetDesc(&framebufferDepthDesc) // copy from framebuffer properties
	framebufferDepthDesc.Format = .D24_UNORM_S8_UINT
	framebufferDepthDesc.BindFlags = {.DEPTH_STENCIL}

	//fmt.printf("%s %v\n", "framebufferDepthDesc", framebufferDepthDesc)

	framebufferDepthTexture: ^D3D11.ITexture2D
	hr = device->CreateTexture2D(&framebufferDepthDesc, nil, &framebufferDepthTexture)
	assert(hr == 0)
	assert(framebufferDepthTexture != nil)

	framebufferDSV: ^D3D11.IDepthStencilView
	hr = device->CreateDepthStencilView(framebufferDepthTexture, nil, &framebufferDSV)
	assert(hr == 0)
	assert(framebufferDSV != nil)

	///////////////////////////////////////////////////////////////////////////////////////////////

	shadowmapDepthDesc: D3D11.TEXTURE2D_DESC = {
		Width            = 2048,
		Height           = 2048,
		MipLevels        = 1,
		ArraySize        = 1,
		Format           = .R32_TYPELESS,
		SampleDesc		 = DXGI.SAMPLE_DESC { Count = 1 },
		Usage            = .DEFAULT,
		BindFlags        = { .DEPTH_STENCIL, .SHADER_RESOURCE },
	}

	//fmt.printf("%s %v\n", "shadowmapDepthDesc", shadowmapDepthDesc)

    shadowmapDepthTexture: ^D3D11.ITexture2D

    hr = device->CreateTexture2D(&shadowmapDepthDesc, nil, &shadowmapDepthTexture)
	assert(hr == 0)
	assert(shadowmapDepthTexture!=nil)

	shadowmapDSVdesc: D3D11.DEPTH_STENCIL_VIEW_DESC = {
		Format        = .D32_FLOAT,
		ViewDimension = .TEXTURE2D,
	}
	//fmt.printf("%s %v\n", "shadowmapDSVdesc", shadowmapDSVdesc)
    shadowmapDSV: ^D3D11.IDepthStencilView
    hr = device->CreateDepthStencilView(shadowmapDepthTexture, &shadowmapDSVdesc, &shadowmapDSV)
	assert(hr == 0, fmt.tprintf("%s %x\n", "CreateDepthStencilView", u32(hr)))
	assert(shadowmapDSV!=nil)

    shadowmapSRVdesc: D3D11.SHADER_RESOURCE_VIEW_DESC = {
    	Format              = .R32_FLOAT,
    	ViewDimension       = .TEXTURE2D,
    	Texture2D           = D3D11.TEX2D_SRV { MipLevels = 1 },
	}

    shadowmapSRV: ^D3D11.IShaderResourceView
    hr = device->CreateShaderResourceView(shadowmapDepthTexture, &shadowmapSRVdesc, &shadowmapSRV)
	assert(hr == 0)
	assert(shadowmapSRV!=nil)

	///////////////////////////////////////////////////////////////////////////////////////////////

	Constants :: struct #align(16) {
		CameraProjection:	glm.mat4,
		LightProjection:	glm.mat4,
		LightRotation:		glm.vec4,
		ModelRotation:		glm.vec4,
		ModelTranslation:	glm.vec4,
		ShadowmapSize:		glm.vec4,
	}

	constantBufferDesc := D3D11.BUFFER_DESC {
		ByteWidth      = size_of(Constants),
		Usage          = .DYNAMIC,
		BindFlags      = {.CONSTANT_BUFFER},
		CPUAccessFlags = {.WRITE},
	}

	constantBuffer: ^D3D11.IBuffer
	hr = device->CreateBuffer(&constantBufferDesc, nil, &constantBuffer)
	assert(hr == 0)

	///////////////////////////////////////////////////////////////////////////////////////////////

	vertexBufferDesc := D3D11.BUFFER_DESC {
		ByteWidth = size_of(vertexData),
		Usage     = .IMMUTABLE,
		BindFlags = {.SHADER_RESOURCE}, // using regular shader resource as vertex buffer for manual vertex fetch
		MiscFlags = {.BUFFER_STRUCTURED},
		StructureByteStride = 5 * size_of(f32), // 5 floats per vertex (float3 position, float2 texcoord)
	}

	vertexBufferData := D3D11.SUBRESOURCE_DATA{ pSysMem = &vertexData[0], SysMemPitch = vertexBufferDesc.ByteWidth }

	vertexBuffer: ^D3D11.IBuffer
	hr = device->CreateBuffer(&vertexBufferDesc, &vertexBufferData, &vertexBuffer)
	assert(hr == 0)

    vertexBufferSRVdesc: D3D11.SHADER_RESOURCE_VIEW_DESC = {
		Format        = .UNKNOWN,
		ViewDimension = .BUFFER,
		Buffer        = D3D11.BUFFER_SRV { NumElements = vertexBufferDesc.ByteWidth / vertexBufferDesc.StructureByteStride },
	}

    vertexBufferSRV: ^D3D11.IShaderResourceView
    hr = device->CreateShaderResourceView(vertexBuffer, &vertexBufferSRVdesc, &vertexBufferSRV)
	assert(hr == 0)

	///////////////////////////////////////////////////////////////////////////////////////////////

    depthStencilDesc : D3D11.DEPTH_STENCIL_DESC = {
    	DepthEnable    = true,
    	DepthWriteMask = .ALL,
    	DepthFunc      = .LESS,
	}

    depthStencilState: ^D3D11.IDepthStencilState
    hr = device->CreateDepthStencilState(&depthStencilDesc, &depthStencilState)
	assert(hr == 0)

	///////////////////////////////////////////////////////////////////////////////////////////////

	rasterizerDesc := D3D11.RASTERIZER_DESC{
		FillMode = .SOLID,
		CullMode = .BACK,
	}
	cullBackRS: ^D3D11.IRasterizerState
	hr = device->CreateRasterizerState(&rasterizerDesc, &cullBackRS)
	assert(hr == 0)

    rasterizerDesc.CullMode = .FRONT

	cullFrontRS: ^D3D11.IRasterizerState
	hr = device->CreateRasterizerState(&rasterizerDesc, &cullFrontRS)
	assert(hr == 0)

	///////////////////////////////////////////////////////////////////////////////////////////////

	framebufferVSBlob: ^D3D11.IBlob
	hr = d3dc.Compile(raw_data(shaders_hlsl), len(shaders_hlsl), "shaders.hlsl", nil, nil, "framebuffer_vs", "vs_5_0", 0, 0, &framebufferVSBlob, nil)
	assert(framebufferVSBlob != nil)
	assert(hr == 0)

	framebufferVS: ^D3D11.IVertexShader
	hr = device->CreateVertexShader(framebufferVSBlob->GetBufferPointer(), framebufferVSBlob->GetBufferSize(), nil, &framebufferVS)
	assert(hr == 0)

	///////////////////////////////////////////////////////////////////////////////////////////////

	framebufferPSBlob: ^D3D11.IBlob
	hr = d3dc.Compile(raw_data(shaders_hlsl), len(shaders_hlsl), "shaders.hlsl", nil, nil, "framebuffer_ps", "ps_5_0", 0, 0, &framebufferPSBlob, nil)
	assert(hr == 0)
	assert(framebufferPSBlob != nil)

	framebufferPS: ^D3D11.IPixelShader
	hr = device->CreatePixelShader(framebufferPSBlob->GetBufferPointer(), framebufferPSBlob->GetBufferSize(), nil, &framebufferPS)
	assert(hr == 0)

	///////////////////////////////////////////////////////////////////////////////////////////////

	shadowmapVSBlob: ^D3D11.IBlob
	hr = d3dc.Compile(raw_data(shaders_hlsl), len(shaders_hlsl), "shaders.hlsl", nil, nil, "shadowmap_vs", "vs_5_0", 0, 0, &shadowmapVSBlob, nil)
	assert(hr == 0)
	assert(shadowmapVSBlob != nil)

	shadowmapVS: ^D3D11.IVertexShader
	hr = device->CreateVertexShader(shadowmapVSBlob->GetBufferPointer(), shadowmapVSBlob->GetBufferSize(), nil, &shadowmapVS)
	assert(hr == 0)

	///////////////////////////////////////////////////////////////////////////////////////////////

	debug_vs_blob: ^D3D11.IBlob
	hr = d3dc.Compile(raw_data(shaders_hlsl), len(shaders_hlsl), "shaders.hlsl", nil, nil, "debug_vs", "vs_5_0", 0, 0, &debug_vs_blob, nil)
	assert(debug_vs_blob != nil)
	assert(hr == 0)

	debug_vs: ^D3D11.IVertexShader
	hr = device->CreateVertexShader(debug_vs_blob->GetBufferPointer(), debug_vs_blob->GetBufferSize(), nil, &debug_vs)
	assert(hr == 0)
	assert(debug_vs != nil)

	///////////////////////////////////////////////////////////////////////////////////////////////

	debug_ps_blob: ^D3D11.IBlob
	hr = d3dc.Compile(raw_data(shaders_hlsl), len(shaders_hlsl), "shaders.hlsl", nil, nil, "debug_ps", "ps_5_0", 0, 0, &debug_ps_blob, nil)
	assert(hr == 0)
	assert(debug_ps_blob != nil)

	debug_ps: ^D3D11.IPixelShader
	hr = device->CreatePixelShader(debug_ps_blob->GetBufferPointer(), debug_ps_blob->GetBufferSize(), nil, &debug_ps)
	assert(hr == 0)
	assert(debug_ps != nil)

	///////////////////////////////////////////////////////////////////////////////////////////////

	//framebufferClear : glm.vec4 = { 0.025, 0.025, 0.025, 1.0 }
	framebufferClear : [4]f32 = { 0.025, 0.025, 0.025, 1.0 }

	framebufferVP : D3D11.VIEWPORT = {0, 0, f32(framebufferDepthDesc.Width), f32(framebufferDepthDesc.Height), 0, 1}
	shadowmapVP   : D3D11.VIEWPORT = {0, 0, f32(shadowmapDepthDesc.Width)  , f32(shadowmapDepthDesc.Height)  , 0, 1}

    nullSRV : ^D3D11.IShaderResourceView = nil // null srv used for unbinding resources

	///////////////////////////////////////////////////////////////////////////////////////////////

	constants : Constants = {
		// camera projection matrix (perspective)
		CameraProjection = glm.mat4 {
			2.0 / (framebufferVP.Width / framebufferVP.Height), 0, 0, 0,
			0, 2,  0,     0,
			0, 0,  1.125, 1,
			0, 0, -1.125, 0 },
		// light projection matrix (orthographic)
		LightProjection = glm.mat4 {
			0.5, 0  ,  0,     0,
			0  , 0.5,  0,     0,
			0  , 0  ,  0.125, 0,
			0  , 0  , -0.125, 1 },
		//LightProjection  = glm.mat4Ortho3d(-1,1,-1,1,-1,1),
		LightRotation    = { 0.8, 0.6, 0.0, 0 },
		ModelRotation    = { 0.0, 0.0, 0.0, 0 },
		ModelTranslation = { 0.0, 0.0, 4.0, 0 },
		ShadowmapSize    = { shadowmapVP.Width, shadowmapVP.Height, 0, 0 },
	}

	fmt.printf("%s %v\n", "constants", constants)
	fmt.printf("%s %v\n", "mat4Ortho3d", glm.mat4Ortho3d(-1,1,-1,1,-1,1))

	ModelRotationStep : glm.vec4 = { 0.001, 0.005, 0.003, 0 }

	///////////////////////////////////////////////////////////////////////////////////////////////

	win32.ShowWindow(hwnd, win32.SW_SHOWDEFAULT)
	win32.UpdateWindow(hwnd)

	for ;win32app.pull_messages(); {

        ///////////////////////////////////////////////////////////////////////////////////////////

        constants.ModelRotation += ModelRotationStep

        ///////////////////////////////////////////////////////////////////////////////////////////

		mappedSubresource: D3D11.MAPPED_SUBRESOURCE
		hr = device_context->Map(constantBuffer, 0, .WRITE_DISCARD, {}, &mappedSubresource)
		assert(hr == 0)
		(^Constants)(mappedSubresource.pData)^ = constants
		// {
		// 	c := (^Constants)(mappedSubresource.pData)
		// 	c.CameraProjection = glm.transpose(constants.CameraProjection)
		// 	c.LightProjection = glm.transpose(constants.LightProjection)
		// 	c.LightRotation = constants.LightRotation
		// 	c.ModelRotation = constants.ModelRotation
		// 	c.ModelTranslation = constants.ModelTranslation
		// 	c.ShadowmapSize = constants.ShadowmapSize
		// }
		device_context->Unmap(constantBuffer, 0)

		///////////////////////////////////////////////////////////////////////////////////////////////

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

		///////////////////////////////////////////////////////////////////////////////////////////////

        device_context->DrawInstanced(8, 24, 0, 0) // render shadowmap (light pov)

        ///////////////////////////////////////////////////////////////////////////////////////////

        device_context->ClearRenderTargetView(framebufferRTV, &framebufferClear)
        device_context->ClearDepthStencilView(framebufferDSV, {.DEPTH}, 1, 0)

        device_context->OMSetRenderTargets(1, &framebufferRTV, framebufferDSV)

        device_context->VSSetShader(framebufferVS, nil, 0)

        device_context->RSSetViewports(1, &framebufferVP)
        device_context->RSSetState(cullBackRS)

        device_context->PSSetShaderResources(1, 1, &shadowmapSRV)
        device_context->PSSetShader(framebufferPS, nil, 0)

        ///////////////////////////////////////////////////////////////////////////////////////////

        device_context->DrawInstanced(8, 24, 0, 0) // render framebuffer (camera pov)

        ///////////////////////////////////////////////////////////////////////////////////////////

        device_context->PSSetShaderResources(1, 1, &shadowmapSRV)
        device_context->VSSetShader(debug_vs, nil, 0)
        device_context->PSSetShader(debug_ps, nil, 0)
		device_context->Draw(4, 0)

        ///////////////////////////////////////////////////////////////////////////////////////////

        device_context->PSSetShaderResources(1, 1, &nullSRV) // release shadowmap as srv to avoid srv/dsv conflict

        ///////////////////////////////////////////////////////////////////////////////////////////

		swapchain->Present(1, {})
	}

	fmt.print("DONE\n")
}

shaders_hlsl := #load("shaders.hlsl")

// pos.x, pos.y, pos.z, tex.u, tex.v, ...
vertexData := [?]f32 {
	-1    ,  1    , -1    , 0   , 0 ,
	 1    ,  1    , -1    , 9.5 , 0 ,
	-0.58 ,  0.58 , -1    , 2   , 2 ,
	 0.58 ,  0.58 , -1    , 7.5 , 2 ,
	-0.58 ,  0.58 , -1    , 0   , 0 ,
     0.58 ,  0.58 , -1    , 0   , 0 ,
	-0.58 ,  0.58 , -0.58 , 0   , 0 ,
     0.58 ,  0.58 , -0.58 , 0   , 0 ,
}

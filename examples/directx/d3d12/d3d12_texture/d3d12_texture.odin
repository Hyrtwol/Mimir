// Based off Simple d3d12 triangle example in Odin https://gist.github.com/jakubtomsu/ecd83e61976d974c7730f9d7ad3e1fd0
package d3d12_texture

import model "../../../../data/models/cube"
import "base:intrinsics"
import "base:runtime"
import "core:fmt"
import "core:mem"
import "core:os"
import win32 "core:sys/windows"
import owin "libs:tlc/win32app"
import "shared:obug"
import d3d12 "vendor:directx/d3d12"
import d3dc "vendor:directx/d3d_compiler"
import dxgi "vendor:directx/dxgi"
import owin_dxgi "libs:tlc/win32app/owin_dxgi"

TITLE :: "D3D12 texture"
WIDTH :: 1920 / 2
HEIGHT :: WIDTH * 9 / 16
SHADER_FILE :: "shaders_tx.hlsl"

NUM_RENDERTARGETS :: 2

int3 :: owin.int3
float3 :: owin.float3

FrameCount: u32 : 3
TextureWidth: u32 : 256
TextureHeight: u32 : 256
TexturePixelSize: u32 : 4 // The number of bytes used to represent a pixel in the texture.

// This fence is used to wait for frames to finish
fence_value: u64
fence: ^d3d12.IFence
fence_event: win32.HANDLE
frame_index: u32
swap_chain: ^dxgi.ISwapChain3
queue: ^d3d12.ICommandQueue

m_commandList: ^d3d12.IGraphicsCommandList

panic_if_failed :: owin.panic_if_failed

wndproc :: proc "system" (hwnd: win32.HWND, msg: win32.UINT, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	context = runtime.default_context()
	switch msg {
	case win32.WM_DESTROY:
		owin.post_quit_message();return 0
	case win32.WM_ERASEBKGND:
		return 1 // skip
	case win32.WM_CHAR:
		switch wparam {
		case '\x1b': // ESC
			owin.close_application(hwnd)
		// case 's':
		// 	show_shadowmap = !show_shadowmap
		}
		return 0
	case:
		return win32.DefWindowProcW(hwnd, msg, wparam, lparam)
	}
}

OnInit :: proc() {}
LoadPipeline :: proc() {}
LoadAssets :: proc() {}

GenerateTextureData :: proc() -> []u8 {
	rowPitch := TextureWidth * TexturePixelSize
	cellPitch := rowPitch >> 3 // The width of a cell in the checkboard texture.
	cellHeight := TextureWidth >> 3 // The height of a cell in the checkerboard texture.
	textureSize := rowPitch * TextureHeight

	pData := make([]u8, textureSize)

	for n: u32 = 0; n < textureSize; n += TexturePixelSize {
		x := n % rowPitch
		y := n / rowPitch
		i := x / cellPitch
		j := y / cellHeight

		if i % 2 == j % 2 {
			pData[n] = 0x00 // R
			pData[n + 1] = 0x00 // G
			pData[n + 2] = 0x00 // B
			pData[n + 3] = 0xff // A
		} else {
			pData[n] = 0xff // R
			pData[n + 1] = 0xff // G
			pData[n + 2] = 0xff // B
			pData[n + 3] = 0xff // A
		}
	}
	return pData
}

OnRender :: proc() {}
OnDestroy :: proc() {
	// Ensure that the GPU is no longer referencing resources that are about to be
	// cleaned up by the destructor.
	WaitForPreviousFrame()

	win32.CloseHandle(fence_event)
}

PopulateCommandList :: proc() {}

WaitForPreviousFrame :: proc() {
	// WAITING FOR THE FRAME TO COMPLETE BEFORE CONTINUING IS NOT BEST PRACTICE.
	// This is code implemented as such for simplicity. The D3D12HelloFrameBuffering
	// sample illustrates how to use fences for efficient resource usage and to
	// maximize GPU utilization.

	current_fence_value := fence_value
	panic_if_failed(queue->Signal(fence, current_fence_value))
	fence_value += 1
	completed := fence->GetCompletedValue()
	if completed < current_fence_value {
		panic_if_failed(fence->SetEventOnCompletion(current_fence_value, fence_event))
		win32.WaitForSingleObject(fence_event, win32.INFINITE)
	}
	frame_index = swap_chain->GetCurrentBackBufferIndex()
}

run :: proc() -> (exit_code: int) {

	settings := owin.default_window_settings
	settings.window_size = {WIDTH, HEIGHT}
	settings.title = TITLE
	settings.wndproc = wndproc
	_, _, hwnd := owin.register_and_create_window(&settings)
	if hwnd == nil {owin.show_error_and_panic("register_and_create_window failed")}
	hr: win32.HRESULT

	// Init DXGI factory. DXGI is the link between the window and DirectX
	factory: ^dxgi.IFactory7

	{
		flags: dxgi.CREATE_FACTORY = {}
		when ODIN_DEBUG {flags |= {.DEBUG}}
		panic_if_failed(dxgi.CreateDXGIFactory2(flags, dxgi.IFactory7_UUID, cast(^rawptr)&factory))
	}

	// Find the DXGI adapter (GPU)
	MINIMUM_FEATURE_LEVEL :: d3d12.FEATURE_LEVEL._12_0
	adapter: ^dxgi.IAdapter1
	for i: u32 = 0; factory->EnumAdapters1(i, &adapter) != dxgi.ERROR_NOT_FOUND; i += 1 {
		desc: dxgi.ADAPTER_DESC1
		adapter->GetDesc1(&desc)
		if .SOFTWARE in desc.Flags {continue}

		hr = d3d12.CreateDevice(adapter, MINIMUM_FEATURE_LEVEL, dxgi.IDevice_UUID, nil)
		if win32.SUCCEEDED(hr) {
			break
		} else {
			fmt.println("Failed to create device", hr)
		}
	}

	if adapter == nil {
		fmt.println("Could not find hardware adapter")
		return
	}

	// Create D3D12 device that represents the GPU
	device: ^d3d12.IDevice
	panic_if_failed(d3d12.CreateDevice(adapter, MINIMUM_FEATURE_LEVEL, d3d12.IDevice_UUID, (^rawptr)(&device)))
	// queue: ^d3d12.ICommandQueue

	{
		desc := d3d12.COMMAND_QUEUE_DESC {
			Type = .DIRECT,
		}
		panic_if_failed(device->CreateCommandQueue(&desc, d3d12.ICommandQueue_UUID, (^rawptr)(&queue)))
	}

	// Create the swap chain, it's the thing that contains render targets that we draw into. It has 2 render targets (NUM_RENDERTARGETS), giving us double buffering.
	{
		swap_chain_desc := dxgi.SWAP_CHAIN_DESC1 {
			Width = u32(settings.window_size.x),
			Height = u32(settings.window_size.y),
			Format = .R8G8B8A8_UNORM,
			SampleDesc = {Count = 1, Quality = 0},
			BufferUsage = {.RENDER_TARGET_OUTPUT},
			BufferCount = NUM_RENDERTARGETS,
			Scaling = .NONE,
			SwapEffect = .FLIP_DISCARD,
			AlphaMode = .UNSPECIFIED,
		}
		panic_if_failed(factory->CreateSwapChainForHwnd(queue, hwnd, &swap_chain_desc, nil, nil, (^^dxgi.ISwapChain1)(&swap_chain)))
	}

	frame_index = swap_chain->GetCurrentBackBufferIndex()

	// Descriptors describe the GPU data and are allocated from a Descriptor Heap
	rtv_descriptor_heap: ^d3d12.IDescriptorHeap
	{
		desc := d3d12.DESCRIPTOR_HEAP_DESC {
			NumDescriptors = NUM_RENDERTARGETS,
			Type           = .RTV,
			Flags          = {},
		}
		panic_if_failed(device->CreateDescriptorHeap(&desc, d3d12.IDescriptorHeap_UUID, (^rawptr)(&rtv_descriptor_heap)))
	}

	srv_descriptor_heap: ^d3d12.IDescriptorHeap
	{
		desc := d3d12.DESCRIPTOR_HEAP_DESC {
			NumDescriptors = 1,
			Type           = .CBV_SRV_UAV,
			Flags          = {.SHADER_VISIBLE},
		}
		panic_if_failed(device->CreateDescriptorHeap(&desc, d3d12.IDescriptorHeap_UUID, (^rawptr)(&srv_descriptor_heap)))
	}

	// Fetch the two render targets from the swap chain
	targets: [NUM_RENDERTARGETS]^d3d12.IResource

	{
		rtv_descriptor_size: u32 = device->GetDescriptorHandleIncrementSize(.RTV)

		rtv_descriptor_handle: d3d12.CPU_DESCRIPTOR_HANDLE
		rtv_descriptor_heap->GetCPUDescriptorHandleForHeapStart(&rtv_descriptor_handle)

		for i: u32 = 0; i < NUM_RENDERTARGETS; i += 1 {
			panic_if_failed(swap_chain->GetBuffer(i, d3d12.IResource_UUID, (^rawptr)(&targets[i])))
			device->CreateRenderTargetView(targets[i], nil, rtv_descriptor_handle)
			rtv_descriptor_handle.ptr += uint(rtv_descriptor_size)
		}
	}

	// The command allocator is used to create the command list that is used to tell the GPU what to draw
	command_allocator: ^d3d12.ICommandAllocator
	panic_if_failed(device->CreateCommandAllocator(.DIRECT, d3d12.ICommandAllocator_UUID, (^rawptr)(&command_allocator)))

	/*
    From https://docs.microsoft.com/en-us/windows/win32/direct3d12/root-signatures-overview:

        A root signature is configured by the app and links command lists to the resources the shaders require.
        The graphics command list has both a graphics and compute root signature. A compute command list will
        simply have one compute root signature. These root signatures are independent of each other.
    */
	root_signature: ^d3d12.IRootSignature

	{
		range := d3d12.DESCRIPTOR_RANGE1 {
			RangeType = .SRV,
			NumDescriptors = 1,
			BaseShaderRegister = 0,
			RegisterSpace = 0,
			Flags = {.DATA_STATIC},
			OffsetInDescriptorsFromTableStart = d3d12.DESCRIPTOR_RANGE_OFFSET_APPEND,
		}
		ranges := []d3d12.DESCRIPTOR_RANGE1 {range}

		rootParameter := d3d12.ROOT_PARAMETER1 {
			ParameterType = .DESCRIPTOR_TABLE,
			ShaderVisibility = .PIXEL,
			DescriptorTable = {
				NumDescriptorRanges = u32(len(ranges)),
				pDescriptorRanges = &ranges[0],
			},
		}
		rootParameters := []d3d12.ROOT_PARAMETER1 {rootParameter}

		sampler := d3d12.STATIC_SAMPLER_DESC {
			Filter           = .MIN_MAG_MIP_POINT,
			AddressU         = .BORDER,
			AddressV         = .BORDER,
			AddressW         = .BORDER,
			MipLODBias       = 0,
			MaxAnisotropy    = 0,
			ComparisonFunc   = .NEVER,
			BorderColor      = .TRANSPARENT_BLACK,
			MinLOD           = 0,
			MaxLOD           = max(f32),
			ShaderRegister   = 0,
			RegisterSpace    = 0,
			ShaderVisibility = .PIXEL,
		}

		samplers: []d3d12.STATIC_SAMPLER_DESC = {sampler}
		fmt.printfln("samplers: %#v", samplers)

		desc := d3d12.VERSIONED_ROOT_SIGNATURE_DESC {
			Version = ._1_1,
		}

		desc.Desc_1_1.Flags = {.ALLOW_INPUT_ASSEMBLER_INPUT_LAYOUT}
		desc.Desc_1_1.NumParameters = u32(len(rootParameters))
		if desc.Desc_1_1.NumParameters > 0 {
			desc.Desc_1_1.pParameters = &rootParameters[0]
		}

		desc.Desc_1_1.NumStaticSamplers = u32(len(samplers))
		if desc.Desc_1_1.NumStaticSamplers > 0 {
			desc.Desc_1_1.pStaticSamplers = &samplers[0]
		}

		serialized_desc: ^d3d12.IBlob
		panic_if_failed(d3d12.SerializeVersionedRootSignature(&desc, &serialized_desc, nil))
		panic_if_failed(device->CreateRootSignature(0, serialized_desc->GetBufferPointer(), serialized_desc->GetBufferSize(), d3d12.IRootSignature_UUID, (^rawptr)(&root_signature)))
		serialized_desc->Release()
	}

	// The pipeline contains the shaders etc to use
	pipeline: ^d3d12.IPipelineState

	{
		compile_flags: u32 = 0
		when ODIN_DEBUG {
			compile_flags |= u32(d3dc.D3DCOMPILE.DEBUG)
			compile_flags |= u32(d3dc.D3DCOMPILE.SKIP_OPTIMIZATION)
		}

		vs: ^d3d12.IBlob = nil
		ps: ^d3d12.IBlob = nil

		panic_if_failed(d3dc.Compile(raw_data(shaders_hlsl), len(shaders_hlsl), SHADER_FILE, nil, nil, "VSMain", "vs_5_0", compile_flags, 0, &vs, nil))
		panic_if_failed(d3dc.Compile(raw_data(shaders_hlsl), len(shaders_hlsl), SHADER_FILE, nil, nil, "PSMain", "ps_5_0", compile_flags, 0, &ps, nil))

		// This layout matches the vertices data defined further down
		vertex_format: []d3d12.INPUT_ELEMENT_DESC = {
			{SemanticName = "POSITION", Format = .R32G32B32_FLOAT, InputSlotClass = .PER_VERTEX_DATA},
			//{SemanticName = "COLOR", Format = .R32G32B32A32_FLOAT, AlignedByteOffset = size_of(f32) * 3, InputSlotClass = .PER_VERTEX_DATA},
			{SemanticName = "TEXCOORD", Format = .R32G32_FLOAT, AlignedByteOffset = size_of(f32) * 3, InputSlotClass = .PER_VERTEX_DATA},
			{SemanticName = "NORMAL", Format = .R32G32B32_FLOAT, AlignedByteOffset = size_of(f32) * 5, InputSlotClass = .PER_VERTEX_DATA},
		}

		default_blend_state := d3d12.RENDER_TARGET_BLEND_DESC {
			BlendEnable           = false,
			LogicOpEnable         = false,
			SrcBlend              = .ONE,
			DestBlend             = .ZERO,
			BlendOp               = .ADD,
			SrcBlendAlpha         = .ONE,
			DestBlendAlpha        = .ZERO,
			BlendOpAlpha          = .ADD,
			LogicOp               = .NOOP,
			RenderTargetWriteMask = u8(d3d12.COLOR_WRITE_ENABLE_ALL),
		}

		pipeline_state_desc := d3d12.GRAPHICS_PIPELINE_STATE_DESC {
			pRootSignature = root_signature,
			// VS = {pShaderBytecode = vs->GetBufferPointer(), BytecodeLength = vs->GetBufferSize()},
			// PS = {pShaderBytecode = ps->GetBufferPointer(), BytecodeLength = ps->GetBufferSize()},
			VS = d3d12.CD3DX12_SHADER_BYTECODE(vs),
			PS = d3d12.CD3DX12_SHADER_BYTECODE(ps),
			StreamOutput = {},
			BlendState = {
				AlphaToCoverageEnable = false,
				IndependentBlendEnable = false,
				//RenderTarget = {0 = default_blend_state, 1 ..< 7 = {}}
				RenderTarget = {0 ..< 7 = default_blend_state},
			},
			SampleMask = 0xFFFFFFFF,
			RasterizerState = d3d12.CD3DX12_RASTERIZER_DESC_DEFAULT,
			// RasterizerState = {
			// 	FillMode = .SOLID,
			// 	CullMode = .BACK,
			// 	FrontCounterClockwise = false,
			// 	DepthBias = 0,
			// 	DepthBiasClamp = 0,
			// 	SlopeScaledDepthBias = 0,
			// 	DepthClipEnable = true,
			// 	MultisampleEnable = false,
			// 	AntialiasedLineEnable = false,
			// 	ForcedSampleCount = 0,
			// 	ConservativeRaster = .OFF,
			// },
			DepthStencilState = {DepthEnable = false, StencilEnable = false},
			InputLayout = {pInputElementDescs = &vertex_format[0], NumElements = u32(len(vertex_format))},
			PrimitiveTopologyType = .TRIANGLE,
			NumRenderTargets = 1,
			RTVFormats = {0 = .R8G8B8A8_UNORM, 1 ..< 7 = .UNKNOWN},
			DSVFormat = .UNKNOWN,
			SampleDesc = {Count = 1, Quality = 0},
		}

		panic_if_failed(device->CreateGraphicsPipelineState(&pipeline_state_desc, d3d12.IPipelineState_UUID, (^rawptr)(&pipeline)))

		vs->Release()
		ps->Release()
	}

	// Create the command list.
	panic_if_failed(device->CreateCommandList(0, .DIRECT, command_allocator, pipeline, d3d12.ICommandList_UUID, (^rawptr)(&m_commandList)))
	//panic_if_failed(m_commandList->Close())

	vertex_buffer: ^d3d12.IResource
	vertex_buffer_view: d3d12.VERTEX_BUFFER_VIEW

	{
		// The position and color data for the triangle's vertices go together per-vertex
		// vertices := [?]f32 {
		//     // pos            color
		//      0.0 , 0.5, 0.0,  1,0,0,0,
		//      0.5, -0.5, 0.0,  0,1,0,0,
		//     -0.5, -0.5, 0.0,  0,0,1,0,
		// }

		vertex :: model.vertex
		vertices := [?]vertex {
			// pos            color
			{{0.0, 0.5, 0.0}, {1, 0}, {1, 0, 0}},
			{{0.5, -0.5, 0.0}, {0, 1}, {0, 1, 0}},
			{{-0.5, -0.5, 0.0}, {1, 1}, {0, 0, 1}},
		}

		heap_props := d3d12.CD3DX12_HEAP_PROPERTIES(.UPLOAD)

		fmt.println("size_of(vertex):", size_of(vertex))
		vertex_buffer_size := len(vertices) * size_of(vertices[0])
		fmt.println("vertex_buffer_size:", vertex_buffer_size)

		resource_desc := d3d12.RESOURCE_DESC {
			Dimension = .BUFFER,
			Alignment = 0,
			Width = u64(vertex_buffer_size),
			Height = 1,
			DepthOrArraySize = 1,
			MipLevels = 1,
			Format = .UNKNOWN,
			SampleDesc = {Count = 1, Quality = 0},
			Layout = .ROW_MAJOR,
			Flags = {},
		}

		panic_if_failed(device->CreateCommittedResource(
			&heap_props,
			{},
			&resource_desc,
			d3d12.RESOURCE_STATE_GENERIC_READ,
			nil,
			d3d12.IResource_UUID, (^rawptr)(&vertex_buffer)))

		gpu_data: rawptr
		read_range: d3d12.RANGE

		panic_if_failed(vertex_buffer->Map(0, &read_range, &gpu_data))
		mem.copy(gpu_data, &vertices[0], vertex_buffer_size)
		vertex_buffer->Unmap(0, nil)

		vertex_buffer_view = d3d12.VERTEX_BUFFER_VIEW {
			BufferLocation = vertex_buffer->GetGPUVirtualAddress(),
			//StrideInBytes  = u32(vertex_buffer_size / 3),
			StrideInBytes  = u32(size_of(vertex)),
			SizeInBytes    = u32(vertex_buffer_size),
		}
	}

	// Note: ComPtr's are CPU objects but this resource needs to stay in scope until
	// the command list that references it has finished executing on the GPU.
	// We will flush the GPU at the end of this method to ensure the resource is not
	// prematurely destroyed.
	//ComPtr<ID3D12Resource> textureUploadHeap;
	//textureUploadHeap : d3d12.RESOURCE_DESC
	m_texture: ^d3d12.IResource
	textureUploadHeap: ^d3d12.IResource

	// Create the texture.
	if true {
        // Describe and create a Texture2D.
		textureDesc: d3d12.RESOURCE_DESC = {
			MipLevels = 1,
			Format = .R8G8B8A8_UNORM,
			Width = u64(TextureWidth),
			Height = TextureHeight,
			Flags = {},
			DepthOrArraySize = 1,
			SampleDesc = {Count = 1, Quality = 0},
			Dimension = .TEXTURE2D,
		}
		ppd := d3d12.CD3DX12_HEAP_PROPERTIES(.DEFAULT)
		panic_if_failed(device->CreateCommittedResource(
			&ppd,
			{},
			&textureDesc,
			{.COPY_DEST},
			nil,
			d3d12.IResource_UUID,
			(^rawptr)(&m_texture)))
		fmt.println("m_texture:", m_texture)

		uploadBufferSize := d3d12.GetRequiredIntermediateSize(m_texture, 0, 1)
		//fmt.println("uploadBufferSize:", uploadBufferSize)
		assert(uploadBufferSize == 262144)

		pp := d3d12.CD3DX12_HEAP_PROPERTIES(.UPLOAD)
		buf: d3d12.RESOURCE_DESC = d3d12.CD3DX12_RESOURCE_DESC_BUFFER(uploadBufferSize)
		panic_if_failed(device->CreateCommittedResource(
			&pp,
			{},
			&buf,
			d3d12.RESOURCE_STATE_GENERIC_READ,
			nil,
			d3d12.IResource_UUID,
			(^rawptr)(&textureUploadHeap)))
		assert(textureUploadHeap != nil)

        // Copy data to the intermediate upload heap and then schedule a copy
        // from the upload heap to the Texture2D.
		texture := GenerateTextureData()
		defer delete(texture)

		textureData: d3d12.SUBRESOURCE_DATA = {}
		textureData.pData = &texture[0]
		textureData.RowPitch = i64(TextureWidth) * i64(TexturePixelSize)
		textureData.SlicePitch = textureData.RowPitch * i64(TextureHeight)

		// UpdateSubresources(m_commandList.Get(), m_texture.Get(), textureUploadHeap.Get(), 0, 0, 1, &textureData);

		res := d3d12.UpdateSubresources3(m_commandList, m_texture, textureUploadHeap, 0, 0, 1, &textureData)
		assert(res > 0)

		// auto trans = CD3DX12_RESOURCE_BARRIER::Transition(m_texture.Get(), D3D12_RESOURCE_STATE_COPY_DEST, D3D12_RESOURCE_STATE_PIXEL_SHADER_RESOURCE);
		trans := d3d12.RESOURCE_BARRIER {
			Type  = .TRANSITION,
			Flags = {},
		}
		trans.Transition = {
			pResource   = m_texture,
			StateBefore = {.COPY_DEST},
			StateAfter  = {.PIXEL_SHADER_RESOURCE},
			Subresource = d3d12.RESOURCE_BARRIER_ALL_SUBRESOURCES,
		}
		m_commandList->ResourceBarrier(1, &trans)

		// Describe and create a SRV for the texture.
		srvDesc: d3d12.SHADER_RESOURCE_VIEW_DESC = {
			Shader4ComponentMapping = d3d12.DEFAULT_SHADER_4_COMPONENT_MAPPING,
			Format = textureDesc.Format,
			ViewDimension = .TEXTURE2D,
			Texture2D = {MipLevels = 1},
		}
		// rtv_descriptor_heap
		srv_descriptor_handle: d3d12.CPU_DESCRIPTOR_HANDLE
		srv_descriptor_heap->GetCPUDescriptorHandleForHeapStart(&srv_descriptor_handle)
		fmt.println("srv_descriptor_handle", srv_descriptor_handle)
		device->CreateShaderResourceView(m_texture, &srvDesc, srv_descriptor_handle)
	}

    // Close the command list and execute it to begin the initial GPU setup.
	panic_if_failed(m_commandList->Close())
	{
		m_commandLists := [?]^d3d12.IGraphicsCommandList{m_commandList}
		queue->ExecuteCommandLists(len(m_commandLists), (^^d3d12.ICommandList)(&m_commandLists[0]))
	}

    // Create synchronization objects and wait until assets have been uploaded to the GPU.
	{
		panic_if_failed(device->CreateFence(fence_value, {}, d3d12.IFence_UUID, (^rawptr)(&fence)))
		fence_value += 1
		manual_reset: win32.BOOL = false
		initial_state: win32.BOOL = false
		fence_event = win32.CreateEventW(nil, manual_reset, initial_state, nil)
		if fence_event == nil {
			fmt.println("Failed to create fence event")
			return
		}

		// Wait for the command list to execute; we are reusing the same command
		// list in our main loop but for now, we just want to wait for setup to
		// complete before continuing.
		WaitForPreviousFrame()
	}

	owin.show_and_update_window(hwnd)

	msg: win32.MSG
	for owin.pull_messages(&msg) {

		panic_if_failed(command_allocator->Reset())
		panic_if_failed(m_commandList->Reset(command_allocator, pipeline))

		window_size := settings.window_size
		viewport := d3d12.VIEWPORT {
			Width  = f32(window_size.x),
			Height = f32(window_size.y),
		}
		scissor_rect := d3d12.RECT {
			left   = 0,
			right  = window_size.x,
			top    = 0,
			bottom = window_size.y,
		}

		// This state is reset every time the cmd list is reset, so we need to rebind it
		m_commandList->SetGraphicsRootSignature(root_signature)
		m_commandList->RSSetViewports(1, &viewport)
		m_commandList->RSSetScissorRects(1, &scissor_rect)

		to_render_target_barrier := d3d12.RESOURCE_BARRIER {
			Type  = .TRANSITION,
			Flags = {},
		}

		to_render_target_barrier.Transition = {
			pResource   = targets[frame_index],
			StateBefore = d3d12.RESOURCE_STATE_PRESENT,
			StateAfter  = {.RENDER_TARGET},
			Subresource = d3d12.RESOURCE_BARRIER_ALL_SUBRESOURCES,
		}

		m_commandList->ResourceBarrier(1, &to_render_target_barrier)

		rtv_handle: d3d12.CPU_DESCRIPTOR_HANDLE
		rtv_descriptor_heap->GetCPUDescriptorHandleForHeapStart(&rtv_handle)

		if (frame_index > 0) {
			s := device->GetDescriptorHandleIncrementSize(.RTV)
			rtv_handle.ptr += uint(frame_index * s)
		}

		m_commandList->OMSetRenderTargets(1, &rtv_handle, false, nil)

		// Record commands.
		clear_color := [4]f32{0.05, 0.05, 0.05, 1.0}
		m_commandList->ClearRenderTargetView(rtv_handle, &clear_color, 0, nil)
		m_commandList->IASetPrimitiveTopology(.TRIANGLELIST)
		m_commandList->IASetVertexBuffers(0, 1, &vertex_buffer_view)
		m_commandList->DrawInstanced(3, 1, 0, 0)

		// Indicate that the back buffer will now be used to present.
		to_present_barrier := to_render_target_barrier
		to_present_barrier.Transition.StateBefore = {.RENDER_TARGET}
		to_present_barrier.Transition.StateAfter = d3d12.RESOURCE_STATE_PRESENT

		m_commandList->ResourceBarrier(1, &to_present_barrier)

		panic_if_failed(m_commandList->Close())

		// execute
		{
			m_commandLists := [?]^d3d12.IGraphicsCommandList{m_commandList}
			queue->ExecuteCommandLists(len(m_commandLists), (^^d3d12.ICommandList)(&m_commandLists[0]))
		}

		// // present
		// {
		// 	params: dxgi.PRESENT_PARAMETERS = {}
		// 	panic_if_failed(swap_chain->Present1(1, {}, &params))
		// }
		owin_dxgi.present(swap_chain)

		WaitForPreviousFrame()
	}

	exit_code = int(msg.wParam)
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

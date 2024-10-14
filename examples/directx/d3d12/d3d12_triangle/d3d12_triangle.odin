// Based off Simple d3d12 triangle example in Odin https://gist.github.com/jakubtomsu/ecd83e61976d974c7730f9d7ad3e1fd0
package d3d12_triangle

import "base:intrinsics"
import "base:runtime"
import "core:fmt"
import "core:mem"
import "core:os"
import win32 "core:sys/windows"
import "libs:tlc/win32app"
import "shared:obug"
import d3d12 "vendor:directx/d3d12"
import d3dc "vendor:directx/d3d_compiler"
import dxgi "vendor:directx/dxgi"

TITLE :: "D3D12 triangle"
WIDTH :: 1920 / 2
HEIGHT :: WIDTH * 9 / 16
SHADER_FILE :: "shaders.hlsl"

NUM_RENDERTARGETS :: 2

check :: proc(res: d3d12.HRESULT, message: string) {
	if win32.SUCCEEDED(res) {
		return
	}

	fmt.printfln("%v. Error code: %0x\n%#v", message, u32(res), win32.HRESULT(res))
	os.exit(-1)
}

wndproc :: proc "system" (hwnd: win32.HWND, msg: win32.UINT, wparam: win32.WPARAM, lparam: win32.LPARAM) -> win32.LRESULT {
	context = runtime.default_context()
	switch msg {
	case win32.WM_DESTROY:
		win32app.post_quit_message();return 0
	case win32.WM_ERASEBKGND:
		return 1 // skip
	case win32.WM_CHAR:
		switch wparam {
		case '\x1b':
			//win32.DestroyWindow(hwnd) // ESC
			win32app.close_application(hwnd)
		// case 's':
		// 	show_shadowmap = !show_shadowmap
		}
		return 0
	case:
		return win32.DefWindowProcW(hwnd, msg, wparam, lparam)
	}
}

run :: proc() {

	hr: d3d12.HRESULT

	settings := win32app.default_window_settings()
	settings.window_size = {WIDTH, HEIGHT}
	settings.title = TITLE
	settings.wndproc = wndproc

	_, _, hwnd := win32app.register_and_create_window(&settings)

	assert(hwnd != nil)

	// Init DXGI factory. DXGI is the link between the window and DirectX
	factory: ^dxgi.IFactory7

	{
		flags: dxgi.CREATE_FACTORY = {}

		when ODIN_DEBUG {
			flags |= {.DEBUG}
		}

		hr = dxgi.CreateDXGIFactory2(flags, dxgi.IFactory7_UUID, cast(^rawptr)&factory)
		check(hr, "Failed creating factory")
	}

	//error_not_found := dxgi.HRESULT(-142213123)
	// error_not_found := dxgi.ERROR_NOT_FOUND
	// s,f,e := win32.DECODE_HRESULT(error_not_found)
	// fmt.printfln("error_not_found: 0x%X %v, %d (0x%X), 0x%X", u32(error_not_found), s, u32(f), u32(f),u32(e))
	// enf := win32.MAKE_HRESULT(win32.SEVERITY.ERROR, 1, 0x1785, 0xFFFD)
	// fmt.printfln("error_not_found: 0x%X", u32(enf))
	// fmt.printfln("in32.FACILITY.DXGI: %d 0x%X", u32(win32.FACILITY.DXGI), u32(win32.FACILITY.DXGI))
	//assert(error_not_found == dxgi.ERROR_NOT_FOUND)

	// res2 := factory->EnumAdapters1(10, &adapter)
	// s, f, e := win32.DECODE_HRESULT(res2)
	// fmt.printfln("EnumAdapters1: 0x%X %v, %v (0x%X), 0x%X", u32(res2), s, f, u32(f),u32(e))
	// assert(res2 == dxgi.ERROR_NOT_FOUND)

	// Find the DXGI adapter (GPU)
	MINIMUM_FEATURE_LEVEL :: d3d12.FEATURE_LEVEL._12_0
	adapter: ^dxgi.IAdapter1
	for i: u32 = 0; factory->EnumAdapters1(i, &adapter) != dxgi.ERROR_NOT_FOUND; i += 1 {
		desc: dxgi.ADAPTER_DESC1
		adapter->GetDesc1(&desc)
		if .SOFTWARE in desc.Flags {
			continue
		}

		hr = d3d12.CreateDevice((^dxgi.IUnknown)(adapter), MINIMUM_FEATURE_LEVEL, dxgi.IDevice_UUID, nil)
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
	hr = d3d12.CreateDevice(adapter, MINIMUM_FEATURE_LEVEL, d3d12.IDevice_UUID, (^rawptr)(&device))
	check(hr, "Failed to create device")
	queue: ^d3d12.ICommandQueue

	{
		desc := d3d12.COMMAND_QUEUE_DESC {
			Type = .DIRECT,
		}

		hr = device->CreateCommandQueue(&desc, d3d12.ICommandQueue_UUID, (^rawptr)(&queue))
		check(hr, "Failed creating command queue")
	}

	// Create the swap chain, it's the thing that contains render targets that we draw into. It has 2 render targets (NUM_RENDERTARGETS), giving us double buffering.
	swap_chain: ^dxgi.ISwapChain3

	{
		window_size := settings.window_size
		swap_chain_desc := dxgi.SWAP_CHAIN_DESC1 {
			Width = u32(window_size.x),
			Height = u32(window_size.y),
			Format = .R8G8B8A8_UNORM,
			SampleDesc = {Count = 1, Quality = 0},
			BufferUsage = {.RENDER_TARGET_OUTPUT},
			BufferCount = NUM_RENDERTARGETS,
			Scaling = .NONE,
			SwapEffect = .FLIP_DISCARD,
			AlphaMode = .UNSPECIFIED,
		}

		hr = factory->CreateSwapChainForHwnd((^dxgi.IUnknown)(queue), hwnd, &swap_chain_desc, nil, nil, (^^dxgi.ISwapChain1)(&swap_chain))
		check(hr, "Failed to create swap chain")
	}

	frame_index := swap_chain->GetCurrentBackBufferIndex()

	// Descripors describe the GPU data and are allocated from a Descriptor Heap
	rtv_descriptor_heap: ^d3d12.IDescriptorHeap

	{
		desc := d3d12.DESCRIPTOR_HEAP_DESC {
			NumDescriptors = NUM_RENDERTARGETS,
			Type           = .RTV,
			Flags          = {},
		}

		hr = device->CreateDescriptorHeap(&desc, d3d12.IDescriptorHeap_UUID, (^rawptr)(&rtv_descriptor_heap))
		check(hr, "Failed creating descriptor heap")
	}

	// Fetch the two render targets from the swap chain
	targets: [NUM_RENDERTARGETS]^d3d12.IResource

	{
		rtv_descriptor_size: u32 = device->GetDescriptorHandleIncrementSize(.RTV)

		rtv_descriptor_handle: d3d12.CPU_DESCRIPTOR_HANDLE
		rtv_descriptor_heap->GetCPUDescriptorHandleForHeapStart(&rtv_descriptor_handle)

		for i: u32 = 0; i < NUM_RENDERTARGETS; i += 1 {
			hr = swap_chain->GetBuffer(i, d3d12.IResource_UUID, (^rawptr)(&targets[i]))
			check(hr, "Failed getting render target")
			device->CreateRenderTargetView(targets[i], nil, rtv_descriptor_handle)
			rtv_descriptor_handle.ptr += uint(rtv_descriptor_size)
		}
	}

	// The command allocator is used to create the commandlist that is used to tell the GPU what to draw
	command_allocator: ^d3d12.ICommandAllocator
	hr = device->CreateCommandAllocator(.DIRECT, d3d12.ICommandAllocator_UUID, (^rawptr)(&command_allocator))
	check(hr, "Failed creating command allocator")

	/*
    From https://docs.microsoft.com/en-us/windows/win32/direct3d12/root-signatures-overview:

        A root signature is configured by the app and links command lists to the resources the shaders require.
        The graphics command list has both a graphics and compute root signature. A compute command list will
        simply have one compute root signature. These root signatures are independent of each other.
    */
	root_signature: ^d3d12.IRootSignature

	{
		desc := d3d12.VERSIONED_ROOT_SIGNATURE_DESC {
			Version = ._1_0,
		}

		desc.Desc_1_0.Flags = {.ALLOW_INPUT_ASSEMBLER_INPUT_LAYOUT}
		serialized_desc: ^d3d12.IBlob
		hr = d3d12.SerializeVersionedRootSignature(&desc, &serialized_desc, nil)
		check(hr, "Failed to serialize root signature")
		hr = device->CreateRootSignature(0, serialized_desc->GetBufferPointer(), serialized_desc->GetBufferSize(), d3d12.IRootSignature_UUID, (^rawptr)(&root_signature))
		check(hr, "Failed creating root signature")
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

		hr = d3dc.Compile(raw_data(shaders_hlsl), len(shaders_hlsl), SHADER_FILE, nil, nil, "VSMain", "vs_4_0", compile_flags, 0, &vs, nil)
		check(hr, "Failed to compile vertex shader")

		hr = d3dc.Compile(raw_data(shaders_hlsl), len(shaders_hlsl), SHADER_FILE, nil, nil, "PSMain", "ps_4_0", compile_flags, 0, &ps, nil)
		check(hr, "Failed to compile pixel shader")

		// This layout matches the vertices data defined further down
		vertex_format: []d3d12.INPUT_ELEMENT_DESC = {
			{SemanticName = "POSITION", Format = .R32G32B32_FLOAT, InputSlotClass = .PER_VERTEX_DATA},
			{SemanticName = "COLOR", Format = .R32G32B32A32_FLOAT, AlignedByteOffset = size_of(f32) * 3, InputSlotClass = .PER_VERTEX_DATA},
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
			VS = {pShaderBytecode = vs->GetBufferPointer(), BytecodeLength = vs->GetBufferSize()},
			PS = {pShaderBytecode = ps->GetBufferPointer(), BytecodeLength = ps->GetBufferSize()},
			StreamOutput = {},
			BlendState = {AlphaToCoverageEnable = false, IndependentBlendEnable = false, RenderTarget = {0 = default_blend_state, 1 ..< 7 = {}}},
			SampleMask = 0xFFFFFFFF,
			RasterizerState = {
				FillMode = .SOLID,
				CullMode = .BACK,
				FrontCounterClockwise = false,
				DepthBias = 0,
				DepthBiasClamp = 0,
				SlopeScaledDepthBias = 0,
				DepthClipEnable = true,
				MultisampleEnable = false,
				AntialiasedLineEnable = false,
				ForcedSampleCount = 0,
				ConservativeRaster = .OFF,
			},
			DepthStencilState = {DepthEnable = false, StencilEnable = false},
			InputLayout = {pInputElementDescs = &vertex_format[0], NumElements = u32(len(vertex_format))},
			PrimitiveTopologyType = .TRIANGLE,
			NumRenderTargets = 1,
			RTVFormats = {0 = .R8G8B8A8_UNORM, 1 ..< 7 = .UNKNOWN},
			DSVFormat = .UNKNOWN,
			SampleDesc = {Count = 1, Quality = 0},
		}

		hr = device->CreateGraphicsPipelineState(&pipeline_state_desc, d3d12.IPipelineState_UUID, (^rawptr)(&pipeline))
		check(hr, "Pipeline creation failed")

		vs->Release()
		ps->Release()
	}

	// Create the commandlist that is reused further down.
	cmdlist: ^d3d12.IGraphicsCommandList
	hr = device->CreateCommandList(0, .DIRECT, command_allocator, pipeline, d3d12.ICommandList_UUID, (^rawptr)(&cmdlist))
	check(hr, "Failed to create command list")
	hr = cmdlist->Close()
	check(hr, "Failed to close command list")

	vertex_buffer: ^d3d12.IResource
	vertex_buffer_view: d3d12.VERTEX_BUFFER_VIEW

	{
		// The position and color data for the triangle's vertices go together per-vertex
        vertices := [?]f32 {
            // pos            color
             0.0 , 0.5, 0.0,  1,0,0,0,
             0.5, -0.5, 0.0,  0,1,0,0,
            -0.5, -0.5, 0.0,  0,0,1,0,
        }

		heap_props := d3d12.HEAP_PROPERTIES {
			Type = .UPLOAD,
		}

		vertex_buffer_size := len(vertices) * size_of(vertices[0])

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

		hr = device->CreateCommittedResource(&heap_props, {}, &resource_desc, d3d12.RESOURCE_STATE_GENERIC_READ, nil, d3d12.IResource_UUID, (^rawptr)(&vertex_buffer))
		check(hr, "Failed creating vertex buffer")

		gpu_data: rawptr
		read_range: d3d12.RANGE

		hr = vertex_buffer->Map(0, &read_range, &gpu_data)
		check(hr, "Failed creating verex buffer resource")

		mem.copy(gpu_data, &vertices[0], vertex_buffer_size)
		vertex_buffer->Unmap(0, nil)

		vertex_buffer_view = d3d12.VERTEX_BUFFER_VIEW {
			BufferLocation = vertex_buffer->GetGPUVirtualAddress(),
			StrideInBytes  = u32(vertex_buffer_size / 3),
			SizeInBytes    = u32(vertex_buffer_size),
		}
	}

	// This fence is used to wait for frames to finish
	fence_value: u64
	fence: ^d3d12.IFence
	fence_event: win32.HANDLE

	{
		hr = device->CreateFence(fence_value, {}, d3d12.IFence_UUID, (^rawptr)(&fence))
		check(hr, "Failed to create fence")
		fence_value += 1
		manual_reset: win32.BOOL = false
		initial_state: win32.BOOL = false
		fence_event = win32.CreateEventW(nil, manual_reset, initial_state, nil)
		if fence_event == nil {
			fmt.println("Failed to create fence event")
			return
		}
	}

	win32app.show_and_update_window(hwnd)
	for win32app.pull_messages() {

		//main_loop: for {
		//	for e: sdl.Event; sdl.PollEvent(&e); {
		// #partial switch e.type {
		// case .QUIT:
		// 	break main_loop
		// case .WINDOWEVENT:
		// This is equivalent to WM_PAINT in win32 API
		//if e.window.event == .EXPOSED {
		hr = command_allocator->Reset()
		check(hr, "Failed resetting command allocator")

		hr = cmdlist->Reset(command_allocator, pipeline)
		check(hr, "Failed to reset command list")

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

		// This state is reset everytime the cmd list is reset, so we need to rebind it
		cmdlist->SetGraphicsRootSignature(root_signature)
		cmdlist->RSSetViewports(1, &viewport)
		cmdlist->RSSetScissorRects(1, &scissor_rect)

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

		cmdlist->ResourceBarrier(1, &to_render_target_barrier)

		rtv_handle: d3d12.CPU_DESCRIPTOR_HANDLE
		rtv_descriptor_heap->GetCPUDescriptorHandleForHeapStart(&rtv_handle)

		if (frame_index > 0) {
			s := device->GetDescriptorHandleIncrementSize(.RTV)
			rtv_handle.ptr += uint(frame_index * s)
		}

		cmdlist->OMSetRenderTargets(1, &rtv_handle, false, nil)

		// clear backbuffer
		clearcolor := [?]f32{0.05, 0.05, 0.05, 1.0}
		cmdlist->ClearRenderTargetView(rtv_handle, &clearcolor, 0, nil)

		// draw call
		cmdlist->IASetPrimitiveTopology(.TRIANGLELIST)
		cmdlist->IASetVertexBuffers(0, 1, &vertex_buffer_view)
		cmdlist->DrawInstanced(3, 1, 0, 0)

		to_present_barrier := to_render_target_barrier
		to_present_barrier.Transition.StateBefore = {.RENDER_TARGET}
		to_present_barrier.Transition.StateAfter = d3d12.RESOURCE_STATE_PRESENT

		cmdlist->ResourceBarrier(1, &to_present_barrier)

		hr = cmdlist->Close()
		check(hr, "Failed to close command list")

		// execute
		cmdlists := [?]^d3d12.IGraphicsCommandList{cmdlist}
		queue->ExecuteCommandLists(len(cmdlists), (^^d3d12.ICommandList)(&cmdlists[0]))

		// present
		{
			flags: dxgi.PRESENT = {}
			params: dxgi.PRESENT_PARAMETERS
			hr = swap_chain->Present1(1, flags, &params)
			check(hr, "Present failed")
		}

		// wait for frame to finish
		{
			current_fence_value := fence_value

			hr = queue->Signal(fence, current_fence_value)
			check(hr, "Failed to signal fence")

			fence_value += 1
			completed := fence->GetCompletedValue()

			if completed < current_fence_value {
				hr = fence->SetEventOnCompletion(current_fence_value, fence_event)
				check(hr, "Failed to set event on completion flag")
				win32.WaitForSingleObject(fence_event, win32.INFINITE)
			}

			frame_index = swap_chain->GetCurrentBackBufferIndex()
		}
		//}
	}
	//}
}

shaders_hlsl := #load(SHADER_FILE)

main :: proc() {
	when intrinsics.is_package_imported("obug") {
		obug.exit(obug.tracked_run(run))
	} else {
		run()
	}
}

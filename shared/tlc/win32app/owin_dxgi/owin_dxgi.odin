package owin_dxgi

import dxgi "vendor:directx/dxgi"
import owin ".."

@(private = "file")
present1 :: proc(swap_chain: ^dxgi.ISwapChain1, flags: dxgi.PRESENT = {}) {
	owin.panic_if_failed(swap_chain->Present(1, flags))
}

@(private = "file")
present3 :: proc(swap_chain: ^dxgi.ISwapChain3, flags: dxgi.PRESENT = {}, params: dxgi.PRESENT_PARAMETERS = {}) {
	params := params
	owin.panic_if_failed(swap_chain->Present1(1, flags, &params))
}

present :: proc {
	present1,
	present3,
}

// get_factory2 :: proc(dxgi_device: ^dxgi.IDevice) -> ^dxgi.IFactory2 {}
get_dxgi_factory2 :: proc(raw_device: rawptr) -> ^dxgi.IFactory2 {
	dxgi_device: ^dxgi.IDevice = (^dxgi.IDevice)(raw_device)
	//owin.panic_if_failed(device->QueryInterface(dxgi.IDevice_UUID, (^rawptr)(&dxgi_device)))
	assert(dxgi_device != nil)

	dxgi_adapter: ^dxgi.IAdapter = nil
	owin.panic_if_failed(dxgi_device->GetAdapter(&dxgi_adapter))
	assert(dxgi_adapter != nil)

	dxgi_factory: ^dxgi.IFactory2 = nil
	owin.panic_if_failed(dxgi_adapter->GetParent(dxgi.IFactory2_UUID, (^rawptr)(&dxgi_factory)))

	return dxgi_factory
}

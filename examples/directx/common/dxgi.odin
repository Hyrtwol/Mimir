package directx_common

import dxgi "vendor:directx/dxgi"

@(private = "file")
present1 :: proc(swap_chain: ^dxgi.ISwapChain1, flags: dxgi.PRESENT = {}) {
	panic_if_failed(swap_chain->Present(1, flags))
}

@(private = "file")
present3 :: proc(swap_chain: ^dxgi.ISwapChain3, flags: dxgi.PRESENT = {}, params: dxgi.PRESENT_PARAMETERS = {}) {
	params := params
	panic_if_failed(swap_chain->Present1(1, flags, &params))
}

present :: proc {
	present1,
	present3,
}

// get_factory2 :: proc(dxgi_device: ^dxgi.IDevice) -> ^dxgi.IFactory2 {}


#pragma comment(lib, "user32")
#pragma comment(lib, "d3d11")
#pragma comment(lib, "d3dcompiler")

///////////////////////////////////////////////////////////////////////////////////////////////////

#include <windows.h>
#include <d3d11_1.h>
#include <d3dcompiler.h>

///////////////////////////////////////////////////////////////////////////////////////////////////

#define TITLE "Minimal D3D11 pt2 by d7samurai"

///////////////////////////////////////////////////////////////////////////////////////////////////

UINT TextureData[] = { 0xffffffff, 0xff7f7f7f, 0xff7f7f7f, 0xffffffff }; // 2x2 pixels

float VertexData[] = // pos.x, pos.y, pos.z, nor.x, nor.y, nor.z, tex.u, tex.v, ...
{
    -1.00f,  1.00f, -1.00f,  0.0f,  0.0f, -1.0f,  0.0f,  0.0f,  1.00f,  1.00f, -1.00f,  0.0f,  0.0f, -1.0f,  9.5f,  0.0f,
     0.58f,  0.58f, -1.00f,  0.0f,  0.0f, -1.0f,  7.5f,  2.0f, -0.58f,  0.58f, -1.00f,  0.0f,  0.0f, -1.0f,  2.0f,  2.0f,
    -0.58f,  0.58f, -1.00f,  0.0f, -1.0f,  0.0f,  0.0f,  0.0f,  0.58f,  0.58f, -1.00f,  0.0f, -1.0f,  0.0f,  0.0f,  0.0f,
     0.58f,  0.58f, -0.58f,  0.0f, -1.0f,  0.0f,  0.0f,  0.0f, -0.58f,  0.58f, -0.58f,  0.0f, -1.0f,  0.0f,  0.0f,  0.0f,
};

UINT IndexData[] = { 0, 1, 3, 1, 2, 3, 4, 5, 7, 5, 6, 7 };

UINT InstanceRotationData[] = { 0, 0, 0, 0, 0, 1, 0, 0, 2, 0, 0, 3, 1, 0, 0, 1, 1, 0, 1, 2, 0, 1, 3, 0, 2, 0, 0, 2, 0, 1, 2, 0, 2, 2, 0, 3, 3, 0, 0, 3, 1, 0, 3, 2, 0, 3, 3, 0, 1, 0, 1, 1, 1, 1, 1, 2, 1, 1, 3, 1, 1, 0, 3, 1, 1, 3, 1, 2, 3, 1, 3, 3 }; // rot.x, rot.y, rot.z, ... in multiples of 90 degrees

float InstanceColorData[] = { 0.973f, 0.480f, 0.002f, 0.897f, 0.163f, 0.011f, 0.612f, 0.000f, 0.069f, 0.127f, 0.116f, 0.408f, 0.000f, 0.254f, 0.637f, 0.001f, 0.447f, 0.067f }; // col.r, col.g, col.b, ...

///////////////////////////////////////////////////////////////////////////////////////////////////

int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nShowCmd)
{
    WNDCLASSA wndClass = { 0, DefWindowProcA, 0, 0, 0, 0, 0, 0, 0, TITLE };

    RegisterClassA(&wndClass);

    HWND window = CreateWindowExA(0, TITLE, TITLE, WS_POPUP | WS_MAXIMIZE | WS_VISIBLE, 0, 0, 0, 0, nullptr, nullptr, nullptr, nullptr);

    ///////////////////////////////////////////////////////////////////////////////////////////////

    D3D_FEATURE_LEVEL featureLevels[] = { D3D_FEATURE_LEVEL_11_0 };

    ID3D11Device* baseDevice;
    ID3D11DeviceContext* baseDeviceContext;

    D3D11CreateDevice(nullptr, D3D_DRIVER_TYPE_HARDWARE, nullptr, D3D11_CREATE_DEVICE_BGRA_SUPPORT, featureLevels, ARRAYSIZE(featureLevels), D3D11_SDK_VERSION, &baseDevice, nullptr, &baseDeviceContext);

    ///////////////////////////////////////////////////////////////////////////////////////////////

    ID3D11Device1* device;

    baseDevice->QueryInterface(__uuidof(ID3D11Device1), reinterpret_cast<void**>(&device));

    ID3D11DeviceContext1* deviceContext;

    baseDeviceContext->QueryInterface(__uuidof(ID3D11DeviceContext1), reinterpret_cast<void**>(&deviceContext));

    ///////////////////////////////////////////////////////////////////////////////////////////////

    IDXGIDevice1* dxgiDevice;

    device->QueryInterface(__uuidof(IDXGIDevice1), reinterpret_cast<void**>(&dxgiDevice));

    IDXGIAdapter* dxgiAdapter;

    dxgiDevice->GetAdapter(&dxgiAdapter);

    IDXGIFactory2* dxgiFactory;

    dxgiAdapter->GetParent(__uuidof(IDXGIFactory2), reinterpret_cast<void**>(&dxgiFactory));

    ///////////////////////////////////////////////////////////////////////////////////////////////

    DXGI_SWAP_CHAIN_DESC1 swapChainDesc;
    swapChainDesc.Width              = 0; // use window width
    swapChainDesc.Height             = 0; // use window height
    swapChainDesc.Format             = DXGI_FORMAT_B8G8R8A8_UNORM; // can't specify _SRGB here when using DXGI_SWAP_EFFECT_FLIP_* ...;
    swapChainDesc.Stereo             = FALSE;
    swapChainDesc.SampleDesc.Count   = 1;
    swapChainDesc.SampleDesc.Quality = 0;
    swapChainDesc.BufferUsage        = DXGI_USAGE_RENDER_TARGET_OUTPUT;
    swapChainDesc.BufferCount        = 2;
    swapChainDesc.Scaling            = DXGI_SCALING_STRETCH;
    swapChainDesc.SwapEffect         = DXGI_SWAP_EFFECT_FLIP_DISCARD;
    swapChainDesc.AlphaMode          = DXGI_ALPHA_MODE_UNSPECIFIED;
    swapChainDesc.Flags              = 0;

    IDXGISwapChain1* swapChain;

    dxgiFactory->CreateSwapChainForHwnd(device, window, &swapChainDesc, nullptr, nullptr, &swapChain);

    ///////////////////////////////////////////////////////////////////////////////////////////////

    ID3D11Texture2D* frameBuffer;

    swapChain->GetBuffer(0, __uuidof(ID3D11Texture2D), reinterpret_cast<void**>(&frameBuffer));

    D3D11_RENDER_TARGET_VIEW_DESC framebufferDesc = {};
    framebufferDesc.Format        = DXGI_FORMAT_B8G8R8A8_UNORM_SRGB; // ... so do this to get _SRGB swapchain
    framebufferDesc.ViewDimension = D3D11_RTV_DIMENSION_TEXTURE2D;

    ID3D11RenderTargetView* frameBufferView;

    device->CreateRenderTargetView(frameBuffer, &framebufferDesc, &frameBufferView);

    ///////////////////////////////////////////////////////////////////////////////////////////////

    D3D11_TEXTURE2D_DESC depthBufferDesc;

    frameBuffer->GetDesc(&depthBufferDesc); // copy from framebuffer properties

    depthBufferDesc.Format    = DXGI_FORMAT_D24_UNORM_S8_UINT;
    depthBufferDesc.BindFlags = D3D11_BIND_DEPTH_STENCIL;

    ID3D11Texture2D* depthBuffer;

    device->CreateTexture2D(&depthBufferDesc, nullptr, &depthBuffer);

    ID3D11DepthStencilView* depthBufferView;

    device->CreateDepthStencilView(depthBuffer, nullptr, &depthBufferView);

    ///////////////////////////////////////////////////////////////////////////////////////////////

    ID3DBlob* vsBlob;

    D3DCompileFromFile(L"shaders.hlsl", nullptr, nullptr, "vs_main", "vs_5_0", 0, 0, &vsBlob, nullptr);

    ID3D11VertexShader* vertexShader;

    device->CreateVertexShader(vsBlob->GetBufferPointer(), vsBlob->GetBufferSize(), nullptr, &vertexShader);

    D3D11_INPUT_ELEMENT_DESC inputElementDesc[] = // float3 position, float3 normal, float2 texcoord, uint3 rotation, float3 color
    {
        { "POS", 0, DXGI_FORMAT_R32G32B32_FLOAT, 0,                            0, D3D11_INPUT_PER_VERTEX_DATA,   0 },
        { "NOR", 0, DXGI_FORMAT_R32G32B32_FLOAT, 0, D3D11_APPEND_ALIGNED_ELEMENT, D3D11_INPUT_PER_VERTEX_DATA,   0 },
        { "TEX", 0, DXGI_FORMAT_R32G32_FLOAT,    0, D3D11_APPEND_ALIGNED_ELEMENT, D3D11_INPUT_PER_VERTEX_DATA,   0 },
        { "ROT", 0, DXGI_FORMAT_R32G32B32_UINT,  1, D3D11_APPEND_ALIGNED_ELEMENT, D3D11_INPUT_PER_INSTANCE_DATA, 1 }, // change every instance
        { "COL", 0, DXGI_FORMAT_R32G32B32_FLOAT, 2, D3D11_APPEND_ALIGNED_ELEMENT, D3D11_INPUT_PER_INSTANCE_DATA, 4 }, // change every 4th instance, i.e. every face
    };

    ID3D11InputLayout* inputLayout;

    device->CreateInputLayout(inputElementDesc, ARRAYSIZE(inputElementDesc), vsBlob->GetBufferPointer(), vsBlob->GetBufferSize(), &inputLayout);

    ///////////////////////////////////////////////////////////////////////////////////////////////

    ID3DBlob* psBlob;

    D3DCompileFromFile(L"shaders.hlsl", nullptr, nullptr, "ps_main", "ps_5_0", 0, 0, &psBlob, nullptr);

    ID3D11PixelShader* pixelShader;

    device->CreatePixelShader(psBlob->GetBufferPointer(), psBlob->GetBufferSize(), nullptr, &pixelShader);

    ///////////////////////////////////////////////////////////////////////////////////////////////

    D3D11_RASTERIZER_DESC1 rasterizerDesc = {};
    rasterizerDesc.FillMode = D3D11_FILL_SOLID;
    rasterizerDesc.CullMode = D3D11_CULL_BACK;

    ID3D11RasterizerState1* rasterizerState;

    device->CreateRasterizerState1(&rasterizerDesc, &rasterizerState);

    ///////////////////////////////////////////////////////////////////////////////////////////////

    D3D11_SAMPLER_DESC samplerDesc = {};
    samplerDesc.Filter         = D3D11_FILTER_MIN_MAG_MIP_POINT;
    samplerDesc.AddressU       = D3D11_TEXTURE_ADDRESS_WRAP;
    samplerDesc.AddressV       = D3D11_TEXTURE_ADDRESS_WRAP;
    samplerDesc.AddressW       = D3D11_TEXTURE_ADDRESS_WRAP;
    samplerDesc.ComparisonFunc = D3D11_COMPARISON_NEVER;

    ID3D11SamplerState* samplerState;

    device->CreateSamplerState(&samplerDesc, &samplerState);

    ///////////////////////////////////////////////////////////////////////////////////////////////

    D3D11_DEPTH_STENCIL_DESC depthStencilDesc = {};
    depthStencilDesc.DepthEnable    = TRUE;
    depthStencilDesc.DepthWriteMask = D3D11_DEPTH_WRITE_MASK_ALL;
    depthStencilDesc.DepthFunc      = D3D11_COMPARISON_LESS;

    ID3D11DepthStencilState* depthStencilState;

    device->CreateDepthStencilState(&depthStencilDesc, &depthStencilState);

    ///////////////////////////////////////////////////////////////////////////////////////////////

    struct float4 { float x, y, z, w; };

    struct Constants
    {
        float4 Projection[4];
        float4 LightVector;
        float4 Rotate;
        float4 Scale;
        float4 Translate;
    };

    D3D11_BUFFER_DESC constantBufferDesc = {};
    constantBufferDesc.ByteWidth      = sizeof(Constants) + 0xf & 0xfffffff0; // ensure constant buffer size is multiple of 16 bytes
    constantBufferDesc.Usage          = D3D11_USAGE_DYNAMIC;
    constantBufferDesc.BindFlags      = D3D11_BIND_CONSTANT_BUFFER;
    constantBufferDesc.CPUAccessFlags = D3D11_CPU_ACCESS_WRITE;

    ID3D11Buffer* constantBuffer;

    device->CreateBuffer(&constantBufferDesc, nullptr, &constantBuffer);

    ///////////////////////////////////////////////////////////////////////////////////////////////

    D3D11_BUFFER_DESC vertexBufferDesc = {};
    vertexBufferDesc.ByteWidth = sizeof(VertexData);
    vertexBufferDesc.Usage     = D3D11_USAGE_IMMUTABLE;
    vertexBufferDesc.BindFlags = D3D11_BIND_VERTEX_BUFFER;

    D3D11_SUBRESOURCE_DATA vertexData = { VertexData };

    ID3D11Buffer* vertexBuffer;

    device->CreateBuffer(&vertexBufferDesc, &vertexData, &vertexBuffer);

    ///////////////////////////////////////////////////////////////////////////////////////////////

    D3D11_BUFFER_DESC indexBufferDesc = {};
    indexBufferDesc.ByteWidth = sizeof(IndexData);
    indexBufferDesc.Usage     = D3D11_USAGE_IMMUTABLE;
    indexBufferDesc.BindFlags = D3D11_BIND_INDEX_BUFFER;

    D3D11_SUBRESOURCE_DATA indexData = { IndexData };

    ID3D11Buffer* indexBuffer;

    device->CreateBuffer(&indexBufferDesc, &indexData, &indexBuffer);

    ///////////////////////////////////////////////////////////////////////////////////////////////

    D3D11_BUFFER_DESC instanceBufferDesc = {};
    instanceBufferDesc.Usage     = D3D11_USAGE_IMMUTABLE;
    instanceBufferDesc.BindFlags = D3D11_BIND_VERTEX_BUFFER;

    D3D11_SUBRESOURCE_DATA instanceData = {};

    ID3D11Buffer* instanceRotationBuffer;

    instanceBufferDesc.ByteWidth = sizeof(InstanceRotationData);
    instanceData.pSysMem         = { InstanceRotationData };

    device->CreateBuffer(&instanceBufferDesc, &instanceData, &instanceRotationBuffer);

    ID3D11Buffer* instanceColorBuffer;

    instanceBufferDesc.ByteWidth = sizeof(InstanceColorData);
    instanceData.pSysMem         = { InstanceColorData };

    device->CreateBuffer(&instanceBufferDesc, &instanceData, &instanceColorBuffer);

    ///////////////////////////////////////////////////////////////////////////////////////////////

    D3D11_TEXTURE2D_DESC textureDesc = {};
    textureDesc.Width            = 2;
    textureDesc.Height           = 2;
    textureDesc.MipLevels        = 1;
    textureDesc.ArraySize        = 1;
    textureDesc.Format           = DXGI_FORMAT_R8G8B8A8_UNORM_SRGB;
    textureDesc.SampleDesc.Count = 1;
    textureDesc.Usage            = D3D11_USAGE_IMMUTABLE;
    textureDesc.BindFlags        = D3D11_BIND_SHADER_RESOURCE;

    D3D11_SUBRESOURCE_DATA textureData = {};
    textureData.pSysMem          = TextureData;
    textureData.SysMemPitch      = 2 * sizeof(UINT); // texture is 2 pixels wide, 4 bytes per pixel

    ID3D11Texture2D* texture;

    device->CreateTexture2D(&textureDesc, &textureData, &texture);

    ID3D11ShaderResourceView* textureView;

    device->CreateShaderResourceView(texture, nullptr, &textureView);

    ///////////////////////////////////////////////////////////////////////////////////////////////

    FLOAT backgroundColor[4] = { 0.025f, 0.025f, 0.025f, 1.0f };

    ID3D11Buffer* buffers[] = { vertexBuffer, instanceRotationBuffer, instanceColorBuffer };
    UINT          strides[] = { 8 * sizeof(float), 3 * sizeof(UINT), 3 * sizeof(float) }; // vertex (float3 position, float3 normal, float2 texcoord), instance rotation (uint3 rotation), instance color (float3 color)
    UINT          offsets[] = { 0, 0, 0 };

    D3D11_VIEWPORT viewport = { 0.0f, 0.0f, static_cast<float>(depthBufferDesc.Width), static_cast<float>(depthBufferDesc.Height), 0.0f, 1.0f };

    ///////////////////////////////////////////////////////////////////////////////////////////////

    float w = viewport.Width / viewport.Height; // width (aspect ratio)
    float h = 1.0f;                             // height
    float n = 1.0f;                             // near
    float f = 9.0f;                             // far

    Constants constants   = { 2 * n / w, 0, 0, 0, 0, 2 * n / h, 0, 0, 0, 0, f / (f - n), 1, 0, 0, n * f / (n - f), 0 }; // projection matrix

    constants.LightVector = {  1.0f, -1.0f,  1.0f };
    constants.Rotate      = {  0.0f,  0.0f,  0.0f };
    constants.Scale       = {  1.0f,  1.0f,  1.0f };
    constants.Translate   = {  0.0f,  0.0f,  4.0f };

    ///////////////////////////////////////////////////////////////////////////////////////////////

    while (true)
    {
        MSG msg;

        while (PeekMessageA(&msg, nullptr, 0, 0, PM_REMOVE))
        {
            if (msg.message == WM_KEYDOWN) return 0;
            DispatchMessageA(&msg);
        }

        ///////////////////////////////////////////////////////////////////////////////////////////

        constants.Rotate.x += 0.005f;
        constants.Rotate.y += 0.009f;
        constants.Rotate.z += 0.001f;

        ///////////////////////////////////////////////////////////////////////////////////////////

        D3D11_MAPPED_SUBRESOURCE mappedSubresource;

        deviceContext->Map(constantBuffer, 0, D3D11_MAP_WRITE_DISCARD, 0, &mappedSubresource);

        *reinterpret_cast<Constants*>(mappedSubresource.pData) = constants;

        deviceContext->Unmap(constantBuffer, 0);

        ///////////////////////////////////////////////////////////////////////////////////////////

        deviceContext->ClearRenderTargetView(frameBufferView, backgroundColor);
        deviceContext->ClearDepthStencilView(depthBufferView, D3D11_CLEAR_DEPTH, 1.0f, 0);

        deviceContext->IASetPrimitiveTopology(D3D11_PRIMITIVE_TOPOLOGY_TRIANGLELIST);
        deviceContext->IASetInputLayout(inputLayout);
        deviceContext->IASetVertexBuffers(0, 3, buffers, strides, offsets);
        deviceContext->IASetIndexBuffer(indexBuffer, DXGI_FORMAT_R32_UINT, 0);

        deviceContext->VSSetShader(vertexShader, nullptr, 0);
        deviceContext->VSSetConstantBuffers(0, 1, &constantBuffer);

        deviceContext->RSSetViewports(1, &viewport);
        deviceContext->RSSetState(rasterizerState);

        deviceContext->PSSetShader(pixelShader, nullptr, 0);
        deviceContext->PSSetShaderResources(0, 1, &textureView);
        deviceContext->PSSetSamplers(0, 1, &samplerState);

        deviceContext->OMSetRenderTargets(1, &frameBufferView, depthBufferView);
        deviceContext->OMSetDepthStencilState(depthStencilState, 0);
        deviceContext->OMSetBlendState(nullptr, nullptr, 0xffffffff); // use default blend mode (i.e. disable)

        ///////////////////////////////////////////////////////////////////////////////////////////

        deviceContext->DrawIndexedInstanced(ARRAYSIZE(IndexData), 24, 0, 0, 0);

        ///////////////////////////////////////////////////////////////////////////////////////////

        swapChain->Present(1, 0);
    }
}

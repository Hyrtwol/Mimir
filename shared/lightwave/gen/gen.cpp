#define WIN32_LEAN_AND_MEAN // Exclude rarely-used stuff from Windows headers
//#include <windows.h>
//#include <timeapi.h>
//#include <mmeapi.h>
//#include <windns.h>
//#include <commdlg.h>
#include <stdio.h>
#include <stdlib.h>
#include <lwo2.h>
#include <iostream>
#include <fstream>
#include <filesystem>
#include <map>
using namespace std;
using namespace std::filesystem;

#define test_proc_begin() out << endl << "@(test)" << endl << __func__ << " :: proc(t: ^testing.T) {" << endl
#define test_proc_end() out << "}" << endl
#define test_proc_using(name) out << '\t' << "using " << name << endl
#define test_proc_comment(comment) out << '\t' << "// " << comment << endl

#define expect_size(s)out << '\t' << "expect_size(t, " << #s << ", " << sizeof(s) << ")" << endl
#define expect_value(s)out << '\t' << "expect_value(t, " << #s << ", " << "0x" << std::uppercase << std::setfill('0') << std::setw(8) << std::hex << s << ")" << endl

//void verify_win32_type_sizes(ofstream& out) {
//	test_proc_begin();
//	test_proc_comment("minwindef.h");
//	expect_size(ULONG);
//	expect_size(PULONG);
//	expect_size(USHORT);
//	expect_size(PUSHORT);
//	expect_size(UCHAR);
//	//expect_size(PUCHAR);
//	//expect_size(PSZ);
//
//	expect_size(DWORD);
//	expect_size(BOOL);
//	expect_size(BYTE);
//	expect_size(WORD);
//	//expect_size(FLOAT);
//	//expect_size(PFLOAT);
//	expect_size(PBOOL);
//	expect_size(LPBOOL);
//	expect_size(PBYTE);
//	expect_size(LPBYTE);
//	expect_size(PINT);
//	expect_size(LPINT);
//	//expect_size(PWORD);
//	expect_size(LPWORD);
//	//expect_size(LPLONG);
//	expect_size(PDWORD);
//	expect_size(LPDWORD);
//	expect_size(LPVOID);
//	expect_size(LPCVOID);
//
//	expect_size(INT);
//	expect_size(UINT);
//	expect_size(PUINT);
//
//	expect_size(UINT_PTR);
//	expect_size(LONG_PTR);
//
//	expect_size(HANDLE);
//	expect_size(WPARAM);
//	expect_size(LPARAM);
//	expect_size(LRESULT);
//
//	expect_size(LPHANDLE);
//	expect_size(HGLOBAL);
//	//expect_size(HLOCAL);
//	//expect_size(GLOBALHANDLE);
//	//expect_size(LOCALHANDLE);
//
//	expect_size(ATOM);
//	expect_size(HKEY);
//	expect_size(PHKEY);
//	//expect_size(HMETAFILE);
//	expect_size(HINSTANCE);
//	expect_size(HMODULE);
//	expect_size(HRGN);
//	expect_size(HRSRC);
//	//expect_size(HSPRITE);
//	//expect_size(HLSURF);
//	//expect_size(HSTR);
//	//expect_size(HTASK);
//	//expect_size(HWINSTA);
//	//expect_size(HKL);
//	//expect_size(HFILE);
//
//	test_proc_comment("windef.h");
//	expect_size(HWND);
//	expect_size(HHOOK);
//	expect_size(HGDIOBJ);
//	expect_size(HBITMAP);
//	expect_size(HBRUSH);
//	expect_size(HFONT);
//	expect_size(HICON);
//	expect_size(HMENU);
//	expect_size(HCURSOR);
//	expect_size(COLORREF);
//	expect_size(RECT);
//	expect_size(POINT);
//	expect_size(SIZE);
//
//	test_proc_comment("winnt.h");
//	expect_size(CHAR);
//	expect_size(SHORT);
//	expect_size(LONG);
//	expect_size(INT);
//	expect_size(WCHAR);
//	//expect_size(LONGLONG);
//	expect_size(ULONGLONG);
//	expect_size(LARGE_INTEGER);
//	expect_size(PLARGE_INTEGER);
//	expect_size(ULARGE_INTEGER);
//	expect_size(PULARGE_INTEGER);
//	expect_size(BOOLEAN);
//	expect_size(HANDLE);
//	expect_size(PHANDLE);
//	expect_size(HRESULT);
//	//expect_size(CCHAR);
//	//expect_size(LCID);
//	//expect_size(LANGID);
//	expect_size(LUID);
//	expect_size(SECURITY_INFORMATION);
//
//	test_proc_comment("fileapi.h");
//	expect_size(WIN32_FILE_ATTRIBUTE_DATA);
//
//	test_proc_comment("minwinbase.h");
//	expect_size(SYSTEMTIME);
//	expect_size(WIN32_FIND_DATAW);
//	expect_size(CRITICAL_SECTION);
//	//expect_size(PROCESS_HEAP_ENTRY);
//	expect_size(REASON_CONTEXT);
//
//	test_proc_comment("guiddef.h");
//	expect_size(GUID);
//	test_proc_comment("commdlg.h");
//	expect_size(OPENFILENAMEW);
//
//	//test_proc_comment("windns.h");
//	//expect_size(DNS_RECORDA);
//	//expect_size(DNS_RECORDW);
//
//	test_proc_end();
//}
//
//void verify_user32_struct_sizes(ofstream& out) {
//	test_proc_begin();
//	test_proc_comment("winuser.h");
//	expect_size(MSG);
//	expect_size(WINDOWPOS);
//	expect_size(PAINTSTRUCT);
//	expect_size(MOUSEINPUT);
//	expect_size(KEYBDINPUT);
//	expect_size(HARDWAREINPUT);
//	expect_size(INPUT);
//	//expect_size(ICONINFO);
//	//expect_size(CURSORSHAPE);
//	//expect_size(ICONINFOEXW);
//
//	expect_size(RAWINPUTHEADER);
//	expect_size(RAWHID);
//	expect_size(RAWMOUSE);
//	expect_size(RAWKEYBOARD);
//	expect_size(RAWINPUT);
//	expect_size(RAWINPUTDEVICE);
//	expect_size(RAWINPUTDEVICELIST);
//
//	expect_size(RID_DEVICE_INFO_HID);
//	expect_size(RID_DEVICE_INFO_KEYBOARD);
//	expect_size(RID_DEVICE_INFO_MOUSE);
//	expect_size(RID_DEVICE_INFO);
//
//	expect_size(WINDOWPLACEMENT);
//	expect_size(WINDOWINFO);
//	expect_size(DRAWTEXTPARAMS);
//
//	test_proc_end();
//}
//
//void verify_gdi32_struct_sizes(ofstream& out) {
//	test_proc_begin();
//	test_proc_comment("wingdi.h");
//	expect_size(DEVMODEW);
//	//expect_size(RGBTRIPLE);
//	expect_size(RGBQUAD);
//	expect_size(PIXELFORMATDESCRIPTOR);
//	expect_size(BITMAPINFOHEADER);
//	expect_size(BITMAP);
//	expect_size(BITMAPV5HEADER);
//	expect_size(CIEXYZTRIPLE);
//	expect_size(CIEXYZ);
//	expect_size(FXPT2DOT30);
//	expect_size(TEXTMETRICW);
//	expect_size(POINTFLOAT);
//	expect_size(GLYPHMETRICSFLOAT);
//	test_proc_end();
//}
//
//void verify_winmm_struct_sizes(ofstream& out) {
//	test_proc_begin();
//	test_proc_comment("timeapi.h");
//	expect_size(TIMECAPS);
//	test_proc_comment("mmsyscom.h");
//	expect_size(MMTIME);
//	test_proc_comment("mmeapi.h");
//	expect_size(WAVEFORMATEX);
//	expect_size(WAVEHDR);
//	expect_size(WAVEINCAPSW);
//	expect_size(WAVEOUTCAPSW);
//	test_proc_end();
//}
//
//void verify_wgl_struct_sizes(ofstream& out) {
//	test_proc_begin();
//	test_proc_comment("wingdi.h");
//	expect_size(LAYERPLANEDESCRIPTOR);
//	expect_size(GLYPHMETRICSFLOAT);
//	test_proc_end();
//}

void verify_struct_sizes(ofstream& out) {
    test_proc_begin();
    test_proc_using("ot");

    expect_size(lwNode);
    expect_size(lwPlugin);
    expect_size(lwKey);
    expect_size(lwEnvelope);
    expect_size(lwEParam);
    expect_size(lwVParam);
    expect_size(lwClipStill);
    expect_size(lwClipSeq);
    expect_size(lwClipAnim);
    expect_size(lwClipXRef);
    expect_size(lwClipCycle);
    expect_size(lwClip);
    expect_size(lwTMap);
    expect_size(lwImageMap);
    expect_size(lwProcedural);
    expect_size(lwGradKey);
    expect_size(lwGradient);
    expect_size(lwTexture);
    expect_size(lwTParam);
    expect_size(lwCParam);
    expect_size(Glow);
    expect_size(lwRMap);
    expect_size(lwLine);
    expect_size(lwSurface);
    expect_size(lwVMap);
    expect_size(lwVMapPt);
    expect_size(lwPoint);
    expect_size(lwPolVert);
    expect_size(lwPolygon);
    expect_size(lwPointList);
    expect_size(lwPolygonList);
    expect_size(lwLayer);
    expect_size(lwTagList);
    expect_size(lwObject);

    test_proc_end();
}

//void verify_error_codes(ofstream& out) {
//	test_proc_begin();
//	test_proc_comment("winerror.h");
//
//	expect_value(ERROR_SUCCESS);
//	expect_value(NO_ERROR);
//	expect_value(SEC_E_OK);
//	out << endl;
//	expect_value(ERROR_INVALID_FUNCTION);
//	expect_value(ERROR_FILE_NOT_FOUND);
//	expect_value(ERROR_PATH_NOT_FOUND);
//	expect_value(ERROR_ACCESS_DENIED);
//	expect_value(ERROR_INVALID_HANDLE);
//	expect_value(ERROR_NOT_ENOUGH_MEMORY);
//	expect_value(ERROR_INVALID_BLOCK);
//	expect_value(ERROR_BAD_ENVIRONMENT);
//	expect_value(ERROR_BAD_FORMAT);
//	expect_value(ERROR_INVALID_ACCESS);
//	expect_value(ERROR_INVALID_DATA);
//	expect_value(ERROR_OUTOFMEMORY);
//	expect_value(ERROR_INVALID_DRIVE);
//	expect_value(ERROR_CURRENT_DIRECTORY);
//	expect_value(ERROR_NO_MORE_FILES);
//	expect_value(ERROR_SHARING_VIOLATION);
//	expect_value(ERROR_LOCK_VIOLATION);
//	expect_value(ERROR_HANDLE_EOF);
//	expect_value(ERROR_NOT_SUPPORTED);
//	expect_value(ERROR_FILE_EXISTS);
//	expect_value(ERROR_INVALID_PARAMETER);
//	expect_value(ERROR_BROKEN_PIPE);
//	expect_value(ERROR_CALL_NOT_IMPLEMENTED);
//	expect_value(ERROR_INSUFFICIENT_BUFFER);
//	expect_value(ERROR_INVALID_NAME);
//	expect_value(ERROR_BAD_ARGUMENTS);
//	expect_value(ERROR_LOCK_FAILED);
//	expect_value(ERROR_ALREADY_EXISTS);
//	expect_value(ERROR_NO_DATA);
//	expect_value(ERROR_ENVVAR_NOT_FOUND);
//	expect_value(ERROR_OPERATION_ABORTED);
//	expect_value(ERROR_IO_PENDING);
//	expect_value(ERROR_NO_UNICODE_TRANSLATION);
//	expect_value(ERROR_TIMEOUT);
//	expect_value(ERROR_DATATYPE_MISMATCH);
//	expect_value(ERROR_UNSUPPORTED_TYPE);
//	expect_value(ERROR_NOT_SAME_OBJECT);
//	expect_value(ERROR_PIPE_CONNECTED);
//	expect_value(ERROR_PIPE_BUSY);
//	out << endl;
//	expect_value(S_OK);
//	expect_value(E_NOTIMPL);
//	expect_value(E_NOINTERFACE);
//	expect_value(E_POINTER);
//	expect_value(E_ABORT);
//	expect_value(E_FAIL);
//	expect_value(E_UNEXPECTED);
//	expect_value(E_ACCESSDENIED);
//	expect_value(E_HANDLE);
//	expect_value(E_OUTOFMEMORY);
//	expect_value(E_INVALIDARG);
//	// out << endl;
//	// expect_value(SEVERITY_SUCCESS);
//	// expect_value(SEVERITY_ERROR);
//	// out << endl;
//	// expect_value(FACILITY_NULL);
//
//	test_proc_end();
//}

//void verify_error_helpers(ofstream& out) {
//	test_proc_begin();
//	test_proc_comment("winerror.h");
//
//	expect_value(SUCCEEDED(-1));
//	expect_value(SUCCEEDED(0));
//	expect_value(SUCCEEDED(1));
//	out << endl;
//	expect_value(FAILED(-1));
//	expect_value(FAILED(0));
//	expect_value(FAILED(1));
//	out << endl;
//	expect_value(IS_ERROR(-1));
//	expect_value(IS_ERROR(0));
//	expect_value(IS_ERROR(1));
//	out << endl;
//	expect_value(HRESULT_CODE(0xFFFFCCCC));
//	expect_value(HRESULT_FACILITY(0xFFFFCCCC));
//	expect_value(HRESULT_SEVERITY(0x12345678));
//	expect_value(HRESULT_SEVERITY(0x87654321));
//	out << endl;
//	expect_value(MAKE_HRESULT(1, 2, 3));
//
//	test_proc_end();
//}

void lightwave(ofstream& out) {
    out << "package " << __func__
        << " // generated by " << path(__FILE__).filename().replace_extension("").string() << endl
        << endl;

    out << "import \"core:testing\"" << endl
        << "import ot \"shared:ounit\"" << endl;

    verify_struct_sizes(out);
}

int main(int argc, char* argv[]) {
    if (argc < 2) { cout << "Usage: " << path(argv[0]).filename().string() << " <odin-output-file>" << endl; return -1; }
    auto filepath = path(argv[1]);
    cout << "Writing " << filepath.string() << endl;
    ofstream out(filepath);
    lightwave(out);
    out.close();
}

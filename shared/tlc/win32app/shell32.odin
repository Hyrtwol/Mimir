// +build windows
package win32app

foreign import shell32 "system:Shell32.lib"

@(default_calling_convention="stdcall")
foreign shell32 {
	SHChangeNotify :: proc(wEventId: LONG, uFlags: UINT, dwItem1: LPCVOID, dwItem2: LPCVOID) ---
}

SHCNRF_InterruptLevel     :: 0x0001
SHCNRF_ShellLevel         :: 0x0002
SHCNRF_RecursiveInterrupt :: 0x1000
SHCNRF_NewDelivery        :: 0x8000

SHCNE_RENAMEITEM          :: 0x00000001
SHCNE_CREATE              :: 0x00000002
SHCNE_DELETE              :: 0x00000004
SHCNE_MKDIR               :: 0x00000008
SHCNE_RMDIR               :: 0x00000010
SHCNE_MEDIAINSERTED       :: 0x00000020
SHCNE_MEDIAREMOVED        :: 0x00000040
SHCNE_DRIVEREMOVED        :: 0x00000080
SHCNE_DRIVEADD            :: 0x00000100
SHCNE_NETSHARE            :: 0x00000200
SHCNE_NETUNSHARE          :: 0x00000400
SHCNE_ATTRIBUTES          :: 0x00000800
SHCNE_UPDATEDIR           :: 0x00001000
SHCNE_UPDATEITEM          :: 0x00002000
SHCNE_SERVERDISCONNECT    :: 0x00004000
SHCNE_UPDATEIMAGE         :: 0x00008000
SHCNE_DRIVEADDGUI         :: 0x00010000
SHCNE_RENAMEFOLDER        :: 0x00020000
SHCNE_FREESPACE           :: 0x00040000

SHCNE_EXTENDED_EVENT      :: 0x04000000

SHCNE_ASSOCCHANGED        :: 0x08000000

SHCNE_DISKEVENTS          :: 0x0002381F
SHCNE_GLOBALEVENTS        :: 0x0C0581E0
SHCNE_ALLEVENTS           :: 0x7FFFFFFF
SHCNE_INTERRUPT           :: 0x80000000

SHCNEE_ORDERCHANGED       :: 2
SHCNEE_MSI_CHANGE         :: 4
SHCNEE_MSI_UNINSTALL      :: 5

SHCNF_IDLIST              :: 0x0000
SHCNF_PATHA               :: 0x0001
SHCNF_PRINTERA            :: 0x0002
SHCNF_DWORD               :: 0x0003
SHCNF_PATHW               :: 0x0005
SHCNF_PRINTERW            :: 0x0006
SHCNF_TYPE                :: 0x00FF
SHCNF_FLUSH               :: 0x1000
SHCNF_FLUSHNOWAIT         :: 0x3000

SHCNF_NOTIFYRECURSIVE     :: 0x10000

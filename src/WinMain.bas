#include once "windows.bi"
#include once "win\commctrl.bi"
#include once "win\commdlg.bi"
#include once "win\ole2.bi"
#include once "win\shlobj.bi"
#include once "crt.bi"
#include once "GenerateDialog.bi"
#include once "resources.rh"
#include once "Registry.bi"

#ifdef UNICODE
#ifndef WZString
#define WZString WString
#endif
#MACRO LongIntToString(buf, Value)
_i64tow ((Value), (buf), 10)
#ENDMACRO
#MACRO LongToString(buf, Value)
_itow ((Value), (buf), 10)
#ENDMACRO
#else
#ifndef WZString
#define WZString ZString
#endif
#MACRO LongIntToString(buf, Value)
_i64toa ((Value), (buf), 10)
#ENDMACRO
#MACRO LongToString(buf, Value)
_itoa ((Value), (buf), 10)
#ENDMACRO
#endif

Const SettingsLength = 9
Const CompilerPathString = __TEXT("CompilerPath")
Const GeneratorPathString = __TEXT("GeneratorPath")
Const ProjectPathString = __TEXT("ProjectPath")
Const SourcePathString = __TEXT("Src")
Const OutNameString = __TEXT("Out")
Const MainModuleString = __TEXT("Module")
Const FileTypeString = __TEXT("FileType")
Const SubSystemString = __TEXT("SubSystem")
Const UnicodeString = __TEXT("Unicode")

Const STRING_BUFFER_CAPACITY = 255

Type MainForm
	hInst As HINSTANCE
	pSettings As SettingsItem Ptr
End Type

Private Function OpenFileShowDialog( _
		ByVal hInst As HINSTANCE, _
		ByVal hOwner As HWND, _
		ByVal pbuf As TCHAR Ptr, _
		ByVal pFileOffset As Integer Ptr, _
		ByVal pFileExtension As Integer Ptr _
	) As Boolean

	Dim FileFilter As WZString * (STRING_BUFFER_CAPACITY + 1) = Any
	LoadString( _
		hInst, _
		IDS_FILTER, _
		@FileFilter, _
		STRING_BUFFER_CAPACITY _
	)

	Dim Caption As WZString * (STRING_BUFFER_CAPACITY + 1) = Any
	LoadString( _
		hInst, _
		IDS_SELECTFILE, _
		@Caption, _
		STRING_BUFFER_CAPACITY _
	)

	pbuf[0] = 0

	#if WINVER >= &h0500
		Dim dwSize As DWORD = SizeOf(OPENFILENAME)
	#else
		' HACK for win95
		Dim dwSize As DWORD = OPENFILENAME_SIZE_VERSION_400
	#endif

	Dim fn As OPENFILENAME = Any
	ZeroMemory(@fn, dwSize)

	fn.lStructSize = dwSize
	fn.hwndOwner = hOwner
	fn.lpstrFilter = @FileFilter
	fn.nFilterIndex = 1
	fn.lpstrFile = pbuf
	fn.nMaxFile = MAX_PATH
	fn.lpstrTitle = @Caption
	fn.Flags = OFN_FILEMUSTEXIST Or OFN_PATHMUSTEXIST

	Dim resGetFile As BOOL = GetOpenFileName(@fn)

	If resGetFile = 0 Then
		Dim dwError As DWORD = CommDlgExtendedError()
		If dwError Then
			' DisplayError(this->hInst, hWin, dwError, IDS_OPENFILENAME)
			Return False
		End If
	End If

	*pFileOffset = CInt(fn.nFileOffset)
	*pFileExtension = CInt(fn.nFileExtension)

	If pbuf[0] = 0 Then
		Return False
	End If

	Return True

End Function

Private Function OpenFolderShowDialog( _
		ByVal hInst As HINSTANCE, _
		ByVal hWin As HWND, _
		ByVal folderPath As TCHAR Ptr _
	) As Boolean

    Dim bi As BROWSEINFO = Any
	ZeroMemory(@bi, SizeOf(BROWSEINFO))

 	Dim Caption As WZString * (STRING_BUFFER_CAPACITY + 1) = Any
	LoadString( _
		hInst, _
		IDS_SELECTFILE, _
		@Caption, _
		STRING_BUFFER_CAPACITY _
	)

	bi.hwndOwner = hWin
    bi.lpszTitle = @Caption
    bi.ulFlags = BIF_RETURNONLYFSDIRS Or BIF_EDITBOX

    Dim pidl As LPITEMIDLIST = SHBrowseForFolder(@bi)

	If pidl Then
		Dim resFolder As BOOL = SHGetPathFromIDList(pidl, folderPath)

        If resFolder Then
            CoTaskMemFree(pidl)
            Return True
		End If

        CoTaskMemFree(pidl)
    End If

	Return False

End Function

Private Sub SelectProjectPath_OnClick( _
		ByVal self As MainForm Ptr, _
		ByVal hWin As HWND _
	)

    Dim folderPath As WZString * (MAX_PATH + 1) = Any
	Dim resOpen As Boolean = OpenFolderShowDialog( _
		self->hInst, _
		hWin, _
		@folderPath _
	)

	If resOpen = False Then
		Exit Sub
	End If

	SetDlgItemText( _
		hWin, _
		IDC_TXT_PROJECTPATH, _
		@folderPath _
	)

End Sub

Private Sub SelectGeneratorPath_OnClick( _
		ByVal self As MainForm Ptr, _
		ByVal hWin As HWND _
	)

	Dim buf As WZString * (STRING_BUFFER_CAPACITY + 1) = Any
	Dim nFileOffset As Integer = Any
	Dim nFileExtension As Integer = Any
	Dim resOpen As Boolean = OpenFileShowDialog( _
		self->hInst, _
		hWin, _
		@buf, _
		@nFileOffset, _
		@nFileExtension _
	)

	If resOpen = False Then
		Exit Sub
	End If

	SetDlgItemText( _
		hWin, _
		IDC_TXT_GENERATOR, _
		@buf _
	)

End Sub

Private Sub SelectCompilerPath_OnClick( _
		ByVal self As MainForm Ptr, _
		ByVal hWin As HWND _
	)

	Dim buf As WZString * (STRING_BUFFER_CAPACITY + 1) = Any
	Dim nFileOffset As Integer = Any
	Dim nFileExtension As Integer = Any
	Dim resOpen As Boolean = OpenFileShowDialog( _
		self->hInst, _
		hWin, _
		@buf, _
		@nFileOffset, _
		@nFileExtension _
	)

	If resOpen = False Then
		Exit Sub
	End If

	' If nFileOffset Then
	' 	Dim IndexPrev As Integer = nFileOffset - 1
	' 	Dim OldValue As Integer = buf[IndexPrev]
	' 	buf[IndexPrev] = Asc("/")

	' 	SetDlgItemText( _
	' 		hWin, _
	' 		IDC_EDT_RESOURCE, _
	' 		@buf[IndexPrev] _
	' 	)

	' 	buf[IndexPrev] = OldValue
	' End If

	SetDlgItemText( _
		hWin, _
		IDC_TXT_COMPILER, _
		@buf _
	)

	' this->IsTemporaryFile = FileType.DiskFile

	' If nFileExtension Then
	' 	Dim ExtensionWithDotOffset As Integer = nFileExtension - 1
	' 	Dim pExt As TCHAR Ptr = @buf.szText(ExtensionWithDotOffset)

	' 	Dim bufContentType As FileNameBuffer = Any
	' 	Dim hrContentType As HRESULT = GetContentTypeOfFileExtension( _
	' 		@bufContentType.szText(0), _
	' 		pExt, _
	' 		MAX_PATH _
	' 	)

	' 	If SUCCEEDED(hrContentType) Then
	' 		SetDlgItemText( _
	' 			hWin, _
	' 			IDC_EDT_TYPE, _
	' 			@bufContentType.szText(0) _
	' 		)
	' 	End If
	' End If

End Sub

Private Sub CreateMakefile_OnClick( _
		ByVal self As MainForm Ptr, _
		ByVal hWin As HWND _
	)

	Dim GeneratorProcessName As WZString * (MAX_PATH + 1) = Any
	GetDlgItemText( _
		hWin, _
		IDC_TXT_GENERATOR, _
		@GeneratorProcessName, _
		MAX_PATH _
	)

	Dim CompilerProcessName As WZString * (MAX_PATH + 1) = Any
	GetDlgItemText( _
		hWin, _
		IDC_TXT_COMPILER, _
		@CompilerProcessName, _
		MAX_PATH _
	)

	Dim ProjectPath As WZString * (MAX_PATH + 1) = Any
	GetDlgItemText( _
		hWin, _
		IDC_TXT_PROJECTPATH, _
		@ProjectPath, _
		MAX_PATH _
	)

	Dim SourcePath As WZString * (MAX_PATH + 1) = Any
	GetDlgItemText( _
		hWin, _
		IDC_TXT_SRCPATH, _
		@SourcePath, _
		MAX_PATH _
	)

	Dim OutputFilename As WZString * (MAX_PATH + 1) = Any
	GetDlgItemText( _
		hWin, _
		IDC_TXT_EXENAME, _
		@OutputFilename, _
		MAX_PATH _
	)

	Dim MainModuleName As WZString * (MAX_PATH + 1) = Any
	GetDlgItemText( _
		hWin, _
		IDC_TXT_MODULENAME, _
		@MainModuleName, _
		MAX_PATH _
	)

	' "args": [
	' 	/* "-makefile", "Makefile", */
	' 	"-src", "src",
	' 	"-fbc-path", "C:\\Program Files (x86)\\FreeBASIC-1.10.1-winlibs-gcc-9.3.0",
	' 	/* include path */
	' 	"-i", "C:\\Program Files (x86)\\FreeBASIC-1.10.1-winlibs-gcc-9.3.0\\inc",
	' 	"-fbc", "fbc64.exe",
	' 	"-out", "cmf-gui",
	' 	/* Main module filename */
	' 	"-module", "WinMain",
	' 	"-exetype", "exe",
	' 	/* console, windows, native */
	' 	"-subsystem", "windows",
	' 	"-emitter", "gcc",
	' 	"-fix", "true",
	' 	"-unicode", "true",
	' 	"-wrt", "true",
	' 	"-addressaware", "true",
	' 	"-multithreading", "false",
	' 	"-usefilesuffix", "true",
	' 	"-pedantic", "true",
	' 	"-create-environment-file", "true",
	' 	"-winver", "1280",
	' ],

	' Создать дочерний процесс

	' Выдать результат — показать диалог прогресса
	' чтобы нельзя было переместиться в основное окно и запустить когда не готово
	' Диалог создаёт процесс и запускает его
	' Диалог только данные для процесса получает

End Sub

Private Sub MainDialog_OnUnload( _
		ByVal self As MainForm Ptr, _
		ByVal hWin As HWND _
	)

	For i As Integer = 0 To SettingsLength - 1

		Select Case self->pSettings[i].Value.vType

			Case SettingsValueType.ValueTypeString
				Dim Length As UINT = GetDlgItemText( _
					hWin, _
					self->pSettings[i].Value.ControlId, _
					@self->pSettings[i].Value.Buffer, _
					SettingsValueItemMaxLength _
				)
				self->pSettings[i].Value.Length = CInt(Length)

			Case SettingsValueType.ValueTypeInt32
				If self->pSettings[i].Value.ControlId = IDC_CHK_UNICODE Then
					self->pSettings[i].Value.Value32 = SendDlgItemMessage( _
						hWin, _
						self->pSettings[i].Value.ControlId, _
						BM_GETCHECK, _
						0, _
						0 _
					)
				Else
					self->pSettings[i].Value.Value32 = SendDlgItemMessage( _
						hWin, _
						self->pSettings[i].Value.ControlId, _
						CB_GETCURSEL, _
						0, _
						0 _
					)
				End If
		End Select
	Next

	SaveSettings( _
		self->pSettings, _
		SettingsLength _
	)

End Sub

Private Sub MainDialog_OnLoad( _
		ByVal self As MainForm Ptr, _
		ByVal hWin As HWND _
	)

	For i As Integer = IDS_FILETYPE_EXE To IDS_FILETYPE_WASM32
		Dim FileType As WZString * (STRING_BUFFER_CAPACITY + 1) = Any
		LoadString( _
			self->hInst, _
			i, _
			@FileType, _
			STRING_BUFFER_CAPACITY _
		)

		SendDlgItemMessage( _
			hWin, IDC_CBB_FILETYPE, CB_ADDSTRING, 0, Cast(LPARAM, @FileType) _
		)
		SendDlgItemMessage( _
			hWin, IDC_CBB_FILETYPE, CB_SETCURSEL, 0, 0 _
		)
	Next

	For i As Integer = IDS_SUBSYSTEM_CONSOLE To IDS_SUBSYSTEM_NATIVE
		Dim szSubSystem As WZString * (STRING_BUFFER_CAPACITY + 1) = Any
		LoadString( _
			self->hInst, _
			i, _
			@szSubSystem, _
			STRING_BUFFER_CAPACITY _
		)

		SendDlgItemMessage( _
			hWin, IDC_CBB_SUBSYSTEM, CB_ADDSTRING, 0, Cast(LPARAM, @szSubSystem) _
		)
		SendDlgItemMessage( _
			hWin, IDC_CBB_SUBSYSTEM, CB_SETCURSEL, 0, 0 _
		)
	Next

	Dim resSuccess As Boolean = LoadSettings( _
		self->pSettings, _
		SettingsLength _
	)

	If resSuccess Then
		For i As Integer = 0 To SettingsLength - 1

			If self->pSettings[i].Value.ErrorCode = 0 Then

				Select Case self->pSettings[i].Value.vType

					Case SettingsValueType.ValueTypeString
						SetDlgItemText( _
							hWin, _
							self->pSettings[i].Value.ControlId, _
							@self->pSettings[i].Value.Buffer _
						)

					Case SettingsValueType.ValueTypeInt32
						If self->pSettings[i].Value.ControlId = IDC_CHK_UNICODE Then
							SendDlgItemMessage( _
								hWin, _
								self->pSettings[i].Value.ControlId, _
								BM_SETCHECK, _
								self->pSettings[i].Value.Value32, _
								0 _
							)
						Else
							SendDlgItemMessage( _
								hWin, _
								self->pSettings[i].Value.ControlId, _
								CB_SETCURSEL, _
								self->pSettings[i].Value.Value32, _
								0 _
							)
						End If
				End Select
			End If
		Next
	End If

End Sub

Private Function MainDialogProc( _
		ByVal hWin As HWND, _
		ByVal uMsg As UINT, _
		ByVal wParam As WPARAM, _
		ByVal lParam As LPARAM _
	)As INT_PTR

	Dim self As MainForm Ptr = Any

	If uMsg = WM_INITDIALOG Then
		self = Cast(MainForm Ptr, lParam)
		SetWindowLongPtr(hWin, GWLP_USERDATA, Cast(LONG_PTR, self))
		MainDialog_OnLoad(self, hWin)

		Return True
	End If

	self = Cast(MainForm Ptr, GetWindowLongPtr(hWin, GWLP_USERDATA))
	If self = NULL Then
		Return False
	End If

	Select Case uMsg

		Case WM_COMMAND

			Dim Reason As WORD = HIWORD(wParam)
			Dim ControlId As WORD = LOWORD(wParam)

			Select Case Reason

				Case BN_CLICKED
					' Menu or Button

					Select Case ControlId

						Case IDC_SELECT_PROJECTPATH
							SelectProjectPath_OnClick(self, hWin)

						Case IDC_SELECT_COMPILER
							SelectCompilerPath_OnClick(self, hWin)

						Case IDC_SELECT_GENERATOR
							SelectGeneratorPath_OnClick(self, hWin)

						Case IDC_CMD_CREATE
							CreateMakefile_OnClick(self, hWin)

						Case IDCANCEL
							EndDialog(hWin, IDCANCEL)

						Case Else
							Return False

					End Select

				Case Else
					Return False

			End Select

		Case WM_DESTROY
			MainDialog_OnUnload(self, hWin)

		Case Else
			Return False

	End Select

	Return TRUE

End Function

Private Function EnableVisualStyles( _
	)As HRESULT

	Dim icc As INITCOMMONCONTROLSEX = Any
	icc.dwSize = SizeOf(INITCOMMONCONTROLSEX)
	icc.dwICC = ICC_ANIMATE_CLASS Or _
		ICC_BAR_CLASSES Or _
		ICC_COOL_CLASSES Or _
		ICC_DATE_CLASSES Or _
		ICC_HOTKEY_CLASS Or _
		ICC_INTERNET_CLASSES Or _
		ICC_LINK_CLASS Or _
		ICC_LISTVIEW_CLASSES Or _
		ICC_NATIVEFNTCTL_CLASS Or _
		ICC_PAGESCROLLER_CLASS Or _
		ICC_PROGRESS_CLASS Or _
		ICC_STANDARD_CLASSES Or _
		ICC_TAB_CLASSES Or _
		ICC_TREEVIEW_CLASSES Or _
		ICC_UPDOWN_CLASS Or _
		ICC_USEREX_CLASSES Or _
	ICC_WIN95_CLASSES

	Dim res As BOOL = InitCommonControlsEx(@icc)
	If res = 0 Then
		Dim dwError As DWORD = GetLastError()
		Return HRESULT_FROM_WIN32(dwError)
	End If

	Return S_OK

End Function

Private Function CreateSettings( _
	) As SettingsItem Ptr

	Dim pSettings As SettingsItem Ptr = Allocate(SizeOf(SettingsItem) * SettingsLength)
	If pSettings = 0 Then
		Return 0
	End If

	pSettings[0].Key = @CompilerPathString
	pSettings[0].Value.ControlId = IDC_TXT_COMPILER
	pSettings[0].Value.vType = SettingsValueType.ValueTypeString

	pSettings[1].Key = @ProjectPathString
	pSettings[1].Value.ControlId = IDC_TXT_PROJECTPATH
	pSettings[1].Value.vType = SettingsValueType.ValueTypeString

	pSettings[2].Key = @SourcePathString
	pSettings[2].Value.ControlId = IDC_TXT_SRCPATH
	pSettings[2].Value.vType = SettingsValueType.ValueTypeString

	pSettings[3].Key = @OutNameString
	pSettings[3].Value.ControlId = IDC_TXT_EXENAME
	pSettings[3].Value.vType = SettingsValueType.ValueTypeString

	pSettings[4].Key = @MainModuleString
	pSettings[4].Value.ControlId = IDC_TXT_MODULENAME
	pSettings[4].Value.vType = SettingsValueType.ValueTypeString

	pSettings[5].Key = @FileTypeString
	pSettings[5].Value.ControlId = IDC_CBB_FILETYPE
	pSettings[5].Value.vType = SettingsValueType.ValueTypeInt32

	pSettings[6].Key = @SubSystemString
	pSettings[6].Value.ControlId = IDC_CBB_SUBSYSTEM
	pSettings[6].Value.vType = SettingsValueType.ValueTypeInt32

	pSettings[7].Key = @UnicodeString
	pSettings[7].Value.ControlId = IDC_CHK_UNICODE
	pSettings[7].Value.vType = SettingsValueType.ValueTypeInt32

	pSettings[8].Key = @GeneratorPathString
	pSettings[8].Value.ControlId = IDC_TXT_GENERATOR
	pSettings[8].Value.vType = SettingsValueType.ValueTypeString

	Return pSettings

End Function

Private Function tWinMain( _
		Byval hInst As HINSTANCE, _
		ByVal hPrevInstance As HINSTANCE, _
		ByVal lpCmdLine As LPCTSTR, _
		ByVal iCmdShow As Long _
	)As Integer

	Dim hrStyles As HRESULT = EnableVisualStyles()
	If FAILED(hrStyles) Then
		Return 1
	End If

	Dim hrCoInit As HRESULT = CoInitialize(NULL)
	If FAILED(hrCoInit) Then
		Return 1
	End If

	Dim param As MainForm = Any
	param.hInst = hInst

	param.pSettings = CreateSettings()
	If param.pSettings = 0 Then
		Return 1
	End If

	Dim resDialog As INT_PTR = DialogBoxParam( _
		hInst, _
		MAKEINTRESOURCE(IDD_DLG_MAIN), _
		HWND_DESKTOP, _
		@MainDialogProc, _
		Cast(LPARAM, @param) _
	)

	Deallocate(param.pSettings)

	CoUninitialize()

	If resDialog = -1 Then
		Return 1
	End If

	Return 0

End Function

Dim hInst As HMODULE = GetModuleHandle(NULL)
Dim hPrevInstance As HINSTANCE = NULL

' The program does not process command line parameters
Dim Arguments As LPTSTR = NULL

Dim RetCode As Long = tWinMain( _
	hInst, _
	hPrevInstance, _
	Arguments, _
	SW_SHOW _
)

End(RetCode)

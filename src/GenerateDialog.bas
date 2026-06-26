#include once "GenerateDialog.bi"
#include once "resources.rh"

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

Type Pipes
	hStdInRead As Handle
	hStdInWrite As Handle    ' parent writing
	hStdOutRead As Handle    ' parent reading
	hStdOutWrite As Handle
End Type

Private Function SetPipes( _
		ByVal pPipes As Pipes Ptr _
	) As Boolean

	Dim saAttr As SECURITY_ATTRIBUTES = Any
	With saAttr
		.nLength = SizeOf(SECURITY_ATTRIBUTES)
		.lpSecurityDescriptor = NULL
		.bInheritHandle = TRUE
	End With

	' Read
	Dim resCreate As BOOL = CreatePipe( _
		@pPipes->hStdInRead, _
		@pPipes->hStdInWrite, _
		@saAttr, _
		0 _
	)

	If resCreate Then
		Dim resSetInfoIn2 As BOOL = SetHandleInformation( _
			pPipes->hStdInWrite, _
			HANDLE_FLAG_INHERIT, _
			0 _
		)

		If resSetInfoIn2 Then
			' Write
			Dim resCreate2 As BOOL = CreatePipe( _
				@pPipes->hStdOutRead, _
				@pPipes->hStdOutWrite, _
				@saAttr, _
				0 _
			)

			If resCreate2 Then
				Dim resSetInfoOut1 As BOOL = SetHandleInformation( _
					pPipes->hStdOutRead, _
					HANDLE_FLAG_INHERIT, _
					0 _
				)

				If resSetInfoOut1 Then
					Return True
				End If

				CloseHandle(pPipes->hStdOutRead)
				CloseHandle(pPipes->hStdOutWrite)
			End If
		End If

		CloseHandle(pPipes->hStdInRead)
		CloseHandle(pPipes->hStdInWrite)
	End If

	Return False

End Function

Private Sub ReadChild( _
		ByVal hWin As HWND, _
		ByVal hFile As HANDLE _
	)

	Do
		Dim Buffer As ZString * (2048) = Any
		Dim ReadBytesCount As DWORD = Any
		Dim resRead As BOOL = ReadFile( _
			hFile, _
			@Buffer, _
			2048 - 1, _
			@ReadBytesCount, _
			NULL _
		)
		If resRead = 0 Then
			' Dim dwError As DWORD = GetLastError()
			Exit Do
		End If

		If ReadBytesCount = 0 Then
			Exit Do
		End If

		Buffer[ReadBytesCount] = 0

		SetDlgItemTextA(hWin, IDC_TXT_PROGRESS, @Buffer)

	Loop

End Sub

Private Sub WriteChild( _
		ByVal hWin As HWND, _
		ByVal hFile As HANDLE _
	)

End Sub

Private Sub CreateCommandLine( _
		ByVal bufCommandLine As WZString Ptr, _
		ByVal ProcessName As WZString Ptr _
	)

	lstrcpy(bufCommandLine, ProcessName)

	' "args": [
	' 	"-makefile", "Makefile",
	' 	"-src", "src",
	' 	"-fbc-path", "C:\\Program Files (x86)\\FreeBASIC-1.10.1-winlibs-gcc-9.3.0",
	' 	/* "-i", "C:\\Program Files (x86)\\FreeBASIC-1.10.1-winlibs-gcc-9.3.0\\inc", */
	' 	"-fbc", "fbc64.exe",
	' 	"-out", "cmf-gui",
	' 	/* Main module filename */
	' 	"-module", "WinMain",
	' 	"-exetype", "exe",
	' 	/* console, windows, native */
	' 	"-subsystem", "windows",
	' 	"-emitter", "gcc",
	' 	"-fix", "false",
	' 	"-unicode", "true",
	' 	"-wrt", "true",
	' 	"-addressaware", "true",
	' 	"-multithreading", "false",
	' 	"-usefilesuffix", "false",
	' 	"-pedantic", "true",
	' 	"-create-environment-file", "false",
	' 	"-winver", "1280",
	' 	"-createdirs", "false",
	' 	"-asm", "intel",
	' 	/* "-tmpdir", "D:\\Temp", */
	' 	"-useldlinker", "true",
	' 	"-flto", "false",
	' 	"-target-triplet", "x86_64-w64-mingw32",
	' ],

End Sub

Private Sub GenerateDialog_OnLoad( _
		ByVal self As GenerateParameter Ptr, _
		ByVal hWin As HWND _
	)

	Dim tPipes As Pipes = Any
	Dim resSetPipes As Boolean = SetPipes(@tPipes)
	If resSetPipes = False Then
		MessageBox( _
			hWin, _
			__TEXT("Can not create pipes"), _
			__TEXT("Error!"), _
			MB_ICONERROR _
		)

		Exit Sub
	End If

	Dim siStartInfo As STARTUPINFO = Any
	ZeroMemory(@siStartInfo, SizeOf(STARTUPINFO))

	With siStartInfo
		.cb = SizeOf(STARTUPINFO)
		.dwFlags = STARTF_USESTDHANDLES
		.hStdInput = tPipes.hStdInRead
		.hStdOutput = tPipes.hStdOutWrite
		.hStdError = tPipes.hStdOutWrite
	End With

	Dim piProcInfo As PROCESS_INFORMATION = Any

	Dim CommandLine As WZString * (MAX_PATH + 1) = Any
	CreateCommandLine( _
		@CommandLine, _
		self->GeneratorProcessName _
	)

	Dim resCreate As BOOL = CreateProcess( _
		self->GeneratorProcessName, _
		@CommandLine, _
		NULL, _
		NULL, _
		True, _
		CREATE_NO_WINDOW, _
		NULL, _
		self->CurrentDirectory, _
		@siStartInfo, _
		@piProcInfo _
	)

	If resCreate = 0 Then
		Dim dwError As DWORD = GetLastError()

		CloseHandle(tPipes.hStdInRead)
		CloseHandle(tPipes.hStdInWrite)
		CloseHandle(tPipes.hStdOutRead)
		CloseHandle(tPipes.hStdOutWrite)

		Dim nCode As Long = CLng(dwError)
		Dim buf As WZString * (128) = Any
		LongToString(@buf, nCode)

		MessageBox(hWin, @buf, __TEXT("Process"), MB_ICONERROR)
	End If

	CloseHandle(piProcInfo.hThread)

	' Write Any data to Child Process
	WriteChild(hWin, tPipes.hStdInWrite)
	CloseHandle(tPipes.hStdInWrite)
	CloseHandle(tPipes.hStdOutWrite)

	ReadChild(hWin, tPipes.hStdOutRead)
	CloseHandle(tPipes.hStdInRead)
	CloseHandle(tPipes.hStdOutRead)

	Dim ExitCode As DWORD = Any
	GetExitCodeProcess( _
		piProcInfo.hProcess, _
		@ExitCode _
	)

	Dim nCode As Long = CLng(ExitCode)
	Dim buf As WZString * (128) = Any
	LongToString(@buf, nCode)

	MessageBox(hWin, @buf, __TEXT("Process Exit Code"), MB_ICONINFORMATION)

	CloseHandle(piProcInfo.hProcess)

End Sub

Function GenerateDialogProc( _
		ByVal hWin As HWND, _
		ByVal uMsg As UINT, _
		ByVal wParam As WPARAM, _
		ByVal lParam As LPARAM _
	)As INT_PTR

	Dim self As GenerateParameter Ptr = Any

	If uMsg = WM_INITDIALOG Then
		self = Cast(GenerateParameter Ptr, lParam)
		SetWindowLongPtr(hWin, GWLP_USERDATA, Cast(LONG_PTR, self))
		GenerateDialog_OnLoad(self, hWin)

		Return True
	End If

	self = Cast(GenerateParameter Ptr, GetWindowLongPtr(hWin, GWLP_USERDATA))
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

						Case IDCANCEL
							EndDialog(hWin, IDCANCEL)

						Case Else
							Return False

					End Select

				Case Else
					Return False

			End Select

		Case WM_DESTROY
			' MainDialog_OnUnload(self, hWin)

		Case Else
			Return False

	End Select

	Return TRUE

End Function

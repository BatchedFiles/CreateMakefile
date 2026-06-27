#include once "GenerateDialog.bi"
#include once "win\commctrl.bi"
#include once "win\windowsx.bi"
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

#define WM_USER_APPENDTEXT WM_USER + 1

Type Pipes
	hStdInRead As Handle
	hStdInWrite As Handle    ' parent writing
	hStdOutRead As Handle    ' parent reading
	hStdOutWrite As Handle
End Type

Type ChildProcessParam
	hWin As HWND
	hStdInWrite As HANDLE
	hStdOutWrite As HANDLE
	hStdOutRead As HANDLE
	hStdInRead As HANDLE
	hProcess As HANDLE
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
		Dim Buffer As ZString * 2048 = Any

		Dim ReadBytesCount As DWORD = Any
		Dim resRead As BOOL = ReadFile( _
			hFile, _
			@Buffer, _
			2048 - 1, _
			@ReadBytesCount, _
			NULL _
		)
		If resRead = 0 Then
			Exit Do
		End If

		If ReadBytesCount = 0 Then
			Exit Do
		End If

		Buffer[ReadBytesCount] = 0

		Dim pBuffer As WZString Ptr = Allocate((ReadBytesCount + 1) * SizeOf(WZString))

		If pBuffer = 0 Then
			Continue Do
		End If

		#ifdef UNICODE
			MultiByteToWideChar( _
				CP_OEMCP, 0, _
				@Buffer, _
				-1, _
				pBuffer, _
				(ReadBytesCount + 1) _
			)
		#else
			CopyMemory(@Buffer, pBuffer, ReadBytesCount + 1)
		#endif

		PostMessage( _
			hWin, _
			WM_USER_APPENDTEXT, _
			0, Cast(LPARAM, pBuffer) _
		)

	Loop

End Sub

Private Sub WriteChild( _
		ByVal hWin As HWND, _
		ByVal hFile As HANDLE _
	)

End Sub

Private Sub CreateCommandLine( _
		ByVal bufCommandLine As WZString Ptr, _
		ByVal ProcessName As WZString Ptr, _
		ByVal FbcPath As WZString Ptr, _
		ByVal FbcName As WZString Ptr, _
		ByVal SourceFolder As WZString Ptr, _
		ByVal MainModuleName As WZString Ptr, _
		ByVal OutProgramName As WZString Ptr _
	)

	Const FormatString = __TEXT( """%s"" " & _
		"-fbc-path ""%s"" " & _
		"-fbc ""%s"" " & _
		"-src ""%s"" " & _
		"-module ""%s"" " & _
		"-out ""%s"" " _
	)
		' -unicode true ^
		' -winver 1281 ^

		' -exetype exe ^
		' -subsystem console ^

		' -multithreading false ^

		' -usefilesuffix true ^
		' -tmpdir D:\Temp ^

		' -pedantic false ^
		' -fix false ^
		' -emitter gcc ^
		' -asm intel ^

		' -addressaware true ^
		' -useldlinker true ^
		' -flto false ^
		' -target-triplet x86_64-w64-mingw32
		' -wrt false ^
		' -wcrt false ^

		' -createdirs false ^
		' -makefile Makefile ^
		' -create-environment-file true ^
	wsprintf( _
		bufCommandLine, _
		@FormatString, _
		ProcessName, _
		FbcPath, _
		FbcName, _
		SourceFolder, _
		MainModuleName, _
		OutProgramName _
	)

End Sub

Private Function ReadChildProcess( _
		ByVal lpParameter As Any Ptr _
	) As DWORD

	Dim pParam As ChildProcessParam Ptr = lpParameter

	' Write Any data to Child Process
	WriteChild(pParam->hWin, pParam->hStdInWrite)
	CloseHandle(pParam->hStdInWrite)
	CloseHandle(pParam->hStdOutWrite)

	ReadChild(pParam->hWin, pParam->hStdOutRead)
	CloseHandle(pParam->hStdInRead)
	CloseHandle(pParam->hStdOutRead)

	Dim ExitCode As DWORD = Any
	GetExitCodeProcess( _
		pParam->hProcess, _
		@ExitCode _
	)

	Dim nCode As Long = CLng(ExitCode)
	Dim buf As WZString * (128) = Any
	LongToString(@buf, nCode)

	MessageBox(NULL, @buf, __TEXT("Process Exit Code"), MB_ICONINFORMATION)

	CloseHandle(pParam->hProcess)

	Deallocate(pParam)

	Return 0

End Function

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

	Dim CommandLine As WZString Ptr = Allocate(SizeOf(WZString) * 1024)
	If CommandLine = NULL Then
		MessageBox( _
			hWin, _
			__TEXT("Can not allocate memory"), _
			__TEXT("Error!"), _
			MB_ICONERROR _
		)

		Exit Sub
	End If

	CreateCommandLine( _
		CommandLine, _
		self->GeneratorProcessName, _
		self->CompilerPath, _
		self->FbcCompilerName, _
		self->SourceFolder, _
		self->MainModuleName, _
		self->OutputFileName _
	)

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

	Dim resCreate As BOOL = CreateProcess( _
		self->GeneratorProcessName, _
		CommandLine, _
		NULL, _
		NULL, _
		True, _
		CREATE_NO_WINDOW, _
		NULL, _
		self->CurrentDirectory, _
		@siStartInfo, _
		@piProcInfo _
	)

	Deallocate(CommandLine)

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

	Dim lpParameter As ChildProcessParam Ptr = Allocate(SizeOf(ChildProcessParam))
	If lpParameter = NULL Then
		Exit Sub
	End If

	lpParameter->hWin = hWin
	lpParameter->hStdInWrite = tPipes.hStdInWrite
	lpParameter->hStdOutWrite = tPipes.hStdOutWrite
	lpParameter->hStdOutRead = tPipes.hStdOutRead
	lpParameter->hStdInRead = tPipes.hStdInRead
	lpParameter->hProcess = piProcInfo.hProcess

	CreateThread( _
		NULL, _
		0, _
		@ReadChildProcess, _
		lpParameter, _
		0, _
		NULL _
	)

End Sub

Private Sub AppendText( _
		ByVal hWin As HWND, _
		ByVal nControl As UINT, _
		ByVal lptszText As LPTSTR _
	)

	Dim OldTextLength As Long = SendDlgItemMessage( _
		hWin, nControl, WM_GETTEXTLENGTH, _
		0, 0 _
	)

	SendDlgItemMessage( _
		hWin, nControl, EM_SETSEL, _
		OldTextLength, OldTextLength _
	)
	SendDlgItemMessage( _
		hWin, nControl, EM_REPLACESEL, _
		0, Cast(LPARAM, lptszText) _
	)
	SendDlgItemMessage( _
		hWin, nControl, EM_SCROLLCARET, _
		0, 0 _
	)

End Sub

Private Sub txtProgress_AppendText( _
		ByVal self As GenerateParameter Ptr, _
		ByVal hWin As HWND, _
		ByVal lpText As LPTSTR _
	)

	AppendText(hWin, IDC_TXT_PROGRESS, lpText)

	Deallocate(lpText)

	' SetDlgItemTextA(hWin, IDC_TXT_PROGRESS, @Buffer)
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

		Case WM_USER_APPENDTEXT
			txtProgress_AppendText(self, hWin, Cast(LPTSTR, lParam))

		' Case WM_DESTROY
		' 	GenerateDialog_OnUnload(self, hWin)

		Case Else
			Return False

	End Select

	Return TRUE

End Function

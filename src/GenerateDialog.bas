#include once "GenerateDialog.bi"
#include once "resources.rh"

Sub GenerateDialog_OnLoad( _
		ByVal self As GenerateParameter Ptr, _
		ByVal hWin As HWND _
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

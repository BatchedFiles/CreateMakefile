#include once "GenerateDialog.bi"
#include once "resources.rh"

Type GenerateForm
	hInst As HINSTANCE
End Type

Function GenerateDialogProc( _
		ByVal hWin As HWND, _
		ByVal uMsg As UINT, _
		ByVal wParam As WPARAM, _
		ByVal lParam As LPARAM _
	)As INT_PTR

	Dim self As GenerateForm Ptr = Any

	If uMsg = WM_INITDIALOG Then
		self = Cast(GenerateForm Ptr, lParam)
		SetWindowLongPtr(hWin, GWLP_USERDATA, Cast(LONG_PTR, self))
		' MainDialog_OnLoad(self, hWin)

		Return True
	End If

	self = Cast(GenerateForm Ptr, GetWindowLongPtr(hWin, GWLP_USERDATA))
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

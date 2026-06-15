#include once "Registry.bi"
#include once "windows.bi"

Const RegistrySection = __TEXT("Software\BatchedFiles\CreateMakefile")

Function LoadSettings( _
		ByVal pVector As SettingsItem Ptr, _
		ByVal Length As Integer _
	)As Boolean

	Dim hRegistryKey As HKEY = Any
	Dim resOpen As LSTATUS = RegOpenKeyEx( _
		HKEY_CURRENT_USER, _
		@RegistrySection, _
		0, _
		KEY_READ, _
		@hRegistryKey _
	)

	If resOpen <> ERROR_SUCCESS Then
		Return False
	End If

	For i As Integer = 0 To Length - 1

		Dim pData As BYTE Ptr = Any
		Dim cbReadedBytes As DWORD = Any

		Select Case pVector[i].Value.vType

			Case SettingsValueType.ValueTypeInt32
				pData = CPtr(BYTE Ptr, @pVector[i].Value.Value32)
				cbReadedBytes = SizeOf(Long)

			Case SettingsValueType.ValueTypeBinary
				pData = CPtr(BYTE Ptr, @pVector[i].Value.Bytes(0))
				cbReadedBytes = SettingsValueItemMaxLength

			Case Else ' SettingsValueType.ValueTypeString
				pData = CPtr(BYTE Ptr, @pVector[i].Value.Buffer)
				cbReadedBytes = (SettingsValueItemMaxLength + 1) * SizeOf(WZString)

		End Select

		Dim RegistryValueType As DWORD = Any

		Dim resQuery As LSTATUS = RegQueryValueEx( _
			hRegistryKey, _
			pVector[i].Key, _
			0, _
			@RegistryValueType, _
			pData, _
			@cbReadedBytes _
		)

		If resQuery = ERROR_SUCCESS Then

			Select Case RegistryValueType

				Case REG_SZ
					If cbReadedBytes Then
						Dim ValueLength As Integer = (cbReadedBytes \ SizeOf(WZString)) - 1

						pVector[i].Value.Buffer[ValueLength] = 0
						pVector[i].Value.Length = ValueLength
					Else
						pVector[i].Value.Buffer[0] = 0
						pVector[i].Value.Length = 0
					End If

				Case Else ' REG_DWORD
					pVector[i].Value.Length = cbReadedBytes

			End Select
		Else
			pVector[i].Value.Value32 = 0
			pVector[i].Value.Length = 0
		End If
	Next

	RegCloseKey(hRegistryKey)

	Return True

End Function

Function SaveSettings( _
		ByVal pVector As SettingsItem Ptr, _
		ByVal Length As Integer _
	)As Boolean

	Dim hRegistryKey As HKEY = Any
	Dim resOpen As LSTATUS = RegCreateKeyEx( _
		HKEY_CURRENT_USER, _
		@RegistrySection, _
		0, _
		NULL, _
		REG_OPTION_NON_VOLATILE, _
		KEY_WRITE, _
		NULL, _
		@hRegistryKey, _
		NULL _
	)

	If resOpen = ERROR_SUCCESS Then

		For i As Integer = 0 To Length - 1

			Dim pData As BYTE Ptr = Any
			Dim cbWriteBytes As DWORD = Any
			Dim RegistryValueType As DWORD = Any

			Select Case pVector[i].Value.vType

				Case SettingsValueType.ValueTypeInt32
					pData = CPtr(BYTE Ptr, @pVector[i].Value.Value32)
					cbWriteBytes = SizeOf(Long)
					RegistryValueType = REG_DWORD

				Case SettingsValueType.ValueTypeBinary
					pData = CPtr(BYTE Ptr, @pVector[i].Value.Bytes(0))
					cbWriteBytes = pVector[i].Value.Length
					RegistryValueType = REG_BINARY

				Case Else ' SettingsValueType.ValueTypeString
					pData = CPtr(BYTE Ptr, @pVector[i].Value.Buffer)
					cbWriteBytes = (pVector[i].Value.Length + 1) * SizeOf(WZString)
					RegistryValueType = REG_SZ

			End Select

			RegSetValueEx( _
				hRegistryKey, _
				pVector[i].Key, _
				0, _
				RegistryValueType, _
				pData, _
				cbWriteBytes _
			)
		Next

		RegCloseKey(hRegistryKey)

		Return True
	End If

	Return False

End Function

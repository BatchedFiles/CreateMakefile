#ifndef REGISTRY_BI
#define REGISTRY_BI

#ifdef UNICODE
#ifndef WZString
#define WZString WString
#endif
#else
#ifndef WZString
#define WZString ZString
#endif
#endif

' MAX_PATH = 260
Const SettingsValueItemMaxLength = 260

Enum SettingsValueType
	ValueTypeInt32
	ValueTypeBinary
	ValueTypeString
End Enum

Type ValueItem
	vType As SettingsValueType
	Length As Integer
	Union
		Value32 As Long
		Buffer As WZString * (SettingsValueItemMaxLength + 1)
		Bytes(0 To SettingsValueItemMaxLength - 1) As Byte
	End Union
	ControlId As Integer
End Type

Type SettingsItem
	Key As WZString Ptr
	Value As ValueItem
End Type

Declare Function LoadSettings( _
	ByVal pVector As SettingsItem Ptr, _
	ByVal Length As Integer _
)As Boolean

Declare Function SaveSettings( _
	ByVal pVector As SettingsItem Ptr, _
	ByVal Length As Integer _
)As Boolean

#endif
#ifndef GENERATEDIALOG_BI
#define GENERATEDIALOG_BI

#include once "windows.bi"

Enum Subsystem
	SUBSYSTEM_CONSOLE
	SUBSYSTEM_WINDOW
	SUBSYSTEM_NATIVE
End Enum

Enum ExecutableType
	OUTPUT_FILETYPE_EXE
	OUTPUT_FILETYPE_DLL
	OUTPUT_FILETYPE_LIBRARY
	OUTPUT_FILETYPE_WASM32
	OUTPUT_FILETYPE_WASM64
End Enum

Enum CodeEmitter
	CODE_EMITTER_GCC
	CODE_EMITTER_GAS
	CODE_EMITTER_GAS64
	CODE_EMITTER_LLVM
	CODE_EMITTER_WASM32
	CODE_EMITTER_WASM64
End Enum

Enum FixCode
	NOT_FIX_EMITTED_CODE
	FIX_EMITTED_CODE
End Enum

Enum UseUnicode
	DEFINE_ANSI
	DEFINE_UNICODE
End Enum

Enum UseFbRuntime
	DEFINE_FB_RUNTIME
	DEFINE_WITHOUT_FB_RUNTIME
End Enum

Enum UseCRuntime
	DEFINE_C_RUNTIME
	DEFINE_WITHOUT_C_RUNTIME
End Enum

Enum ProcessAddressSpace
	LARGE_ADDRESS_UNAWARE
	LARGE_ADDRESS_AWARE
End Enum

Enum MultiThreading
	DEFINE_SINGLETHREADING_RUNTIME
	DEFINE_MULTITHREADING_RUNTIME
End Enum

Enum UseSettingsEnvironment
	SETTINGS_ENVIRONMENT_ALWAYS
	DO_NOT_USE_SETTINGS_ENVIRONMENT
End Enum

Const WINVER_XP = 1281
Const WINVER_DEFAULT = WINVER_XP

Type GenerateParameter
	MakefileFileName As TCHAR Ptr
	SourceFolder As TCHAR Ptr
	CompilerPath As TCHAR Ptr
	IncludePath As TCHAR Ptr
	FbcCompilerName As TCHAR Ptr
	OutputFileName As TCHAR Ptr
	MainModuleName As TCHAR Ptr
	ExeType As ExecutableType
	FileSubsystem As Subsystem
	Emitter As CodeEmitter
	FixEmittedCode As FixCode
	UnicodeFlag As UseUnicode
	UseFbRuntimeLibrary As UseFbRuntime
	UseCRuntimeLibrary As UseCRuntime
	AddressAware As ProcessAddressSpace
	ThreadingMode As MultiThreading
	UseEnvironmentFile As UseSettingsEnvironment
	MinimalOSVersion As Integer
	UseFileSuffix As Boolean
	Pedantic As Boolean
	CreateDirs As Boolean
End Type

Type GenerateForm
	hInst As HINSTANCE
End Type

Declare Function GenerateDialogProc( _
	ByVal hWin As HWND, _
	ByVal uMsg As UINT, _
	ByVal wParam As WPARAM, _
	ByVal lParam As LPARAM _
)As INT_PTR

#endif

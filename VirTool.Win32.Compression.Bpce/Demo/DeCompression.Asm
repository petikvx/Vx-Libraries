;===============================================================================;
;			Options and Includes					;
;===============================================================================;
.386										;
option casemap:none								;
.model flat,stdcall								;
include \tools\masm32\include\windows.inc					;
;===============================================================================;
;===============================================================================;
;				Code Section					;
;===============================================================================;
.code
start:
	jmp Begin
	include d:\tools\masm32\bin\BPCompressionEngine\APIBlocks.asm;����� ��� ��������� ������� API
	include d:\tools\masm32\bin\BPCompressionEngine\Api.asm;������� �������
	include d:\tools\masm32\bin\BPCompressionEngine\Buffers.asm
;Bill Prisoner Compression Engine
	include d:\tools\masm32\bin\BPCompressionEngine\bpce.inc
;===============================================================================;
;MapFile proc FileName:DWORD,FileSize:DWORD,Delta:DWORD
;��������: �������� ����� �� ���
;����:
;	FileName - ��� �����
;	FileSize - ������ �����
;�����:
;	���� ��� ������������ ����, 0 - ���� ������
;===============================================================================;
MapFile proc FileName:DWORD,FileSize:DWORD,Delta:DWORD
LOCAL hFile:DWORD
LOCAL hMap:DWORD
LOCAL hMapping:DWORD

	startproc
	mov ebx,Delta
	mov hMap,0
;��������� ����
	push NULL
	push FILE_ATTRIBUTE_NORMAL
	push OPEN_ALWAYS
	push NULL
	push FILE_SHARE_WRITE or FILE_SHARE_READ 
	push GENERIC_WRITE or GENERIC_READ
	push FileName
	apiproc _CreateFileA
;�������� �� ������������ �������� �����
	.if eax==-1
		jmp End1
	.endif
	mov hFile,eax
;������� ������ "�������� �����"
	push NULL
	push FileSize
	push NULL
	push PAGE_READWRITE
	push NULL
	push eax
	apiproc _CreateFileMappingA
;�������� �� ������������ �������� ��������
	.if eax==0
		jmp End2
	.endif
	mov hMapping,eax
;���������� ���� �� �������� ������������
	push 0
	push 0
	push 0
	push FILE_MAP_ALL_ACCESS
	push eax	
	apiproc _MapViewOfFile
	.if eax==0
		mov hMap,0
		jmp End3
	.endif
	mov hMap,eax
End3:
	push hMapping
	apiproc _CloseHandle 
End2:
	push hFile
	apiproc _CloseHandle 
End1:  
	mov eax,hMap
	endproc
	ret
MapFile endp
;===============================================================================;

;===============================================================================;
;				     ������					;
;===============================================================================;
;===============================================================================;
;				     ������					;
;===============================================================================;
	user32Str		db		"user32.dll",0
	comdlg32Str		db		"comdlg32.dll",0
	FilterString		db		"All Files",0,"*.*",0,0
;===============================================================================;
;				     ����������					;
;===============================================================================;
	KernelBase		dd		0
	hMap			dd 		0
	hMap2			dd 		0
	WorkBuffer		dd 		0
	CompressBuffer		dd 		0
	hFile 			dd		0
	FileSize		dd		0
	ofn2  			OPENFILENAME	<0>
	ofn   			OPENFILENAME 	<0>
	StringBuffer		dd		0
;===============================================================================;
;ZeroMemory proc Address:DWORD,Size:DWORD
;��������: ��������� ������� ������
;����:
;	Address - ����� ��� �������
;	Size - ���������� ���������� ����
;===============================================================================;
ZeroMemory proc Address:DWORD,Size1:DWORD
	push edi
	mov eax,0
	mov edi,Address
	mov ecx,Size1
	rep stosb
	pop edi
	ret
ZeroMemory endp
;===============================================================================;
Begin:
;��������� �������� � �����
	startproc
;��������� ������
	GetDelta
;���� KERNEL32.DLL
	GetKernelBase
	mov dword ptr [ebp+KernelBase],eax
;�������� ������ API ��� KERNEL32.DLL
	push ebp
	push eax
	lea ebx,[ebp+address]
	push ebx	
	lea ebx,[ebp+imp]
	push ebx
	push 43
	call GetAPIs
;��������� ���������� user32
	lea eax,[ebp+user32Str]
	push eax
	api _GetModuleHandleA

	.IF eax==0
		lea eax,[ebp+user32Str]
		push eax
		api _LoadLibraryA
	.ENDIF
;�������� ������ API ��� user32.DLL
	push ebp
	push eax
	lea eax,[ebp+address2]
	push eax	
	lea eax,[ebp+imp2]
	push eax
	push 2
	call GetAPIs
;��������� ���������� comdlg32
	lea eax,[ebp+comdlg32Str]
	push eax
	api _GetModuleHandleA

	.IF eax==0
		lea eax,[ebp+comdlg32Str]
		push eax
		api _LoadLibraryA
	.ENDIF
;�������� ������ API ��� comdlg32.DLL
	push ebp
	push eax
	lea eax,[ebp+address3]
	push eax	
	lea eax,[ebp+imp3]
	push eax
	push 1
	call GetAPIs
;�������� ��� ����� ��� ����������
	lea esi,[ebp+ofn]
	assume esi:ptr OPENFILENAME
	mov [esi].lStructSize,SIZEOF OPENFILENAME
	mov [esi].hWndOwner,0

	push 0
	api _GetModuleHandleA
	mov dword ptr [esi].hInstance,eax
	lea eax,[ebp+FilterString]
	mov [esi].lpstrFilter, eax
	push ebp
	call AllocBuffer;����� ��� ������ � ������ �����
	mov dword ptr [ebp+StringBuffer],eax

	mov [esi].lpstrFile,eax
	mov [esi].nMaxFile,255
	mov [esi].Flags, OFN_FILEMUSTEXIST or OFN_PATHMUSTEXIST or OFN_LONGNAMES or OFN_EXPLORER or OFN_HIDEREADONLY
	mov [esi].lpstrTitle, 0

	push esi
        api _GetOpenFileNameA
;�������� ��� ����� ��� ������ ������
	lea esi,[ebp+ofn2]
	assume esi:ptr OPENFILENAME
	mov [esi].lStructSize,SIZEOF OPENFILENAME
	mov [esi].hWndOwner,0

	push 0
	api _GetModuleHandleA
	mov dword ptr [esi].hInstance,eax
	lea eax,[ebp+FilterString]
	mov [esi].lpstrFilter, eax
	push ebp
	call AllocBuffer;����� ��� ������ � ������ �����
	mov dword ptr [ebp+StringBuffer],eax

	mov [esi].lpstrFile,eax
	mov [esi].nMaxFile,255
	mov [esi].Flags, OFN_PATHMUSTEXIST or OFN_LONGNAMES or OFN_EXPLORER or OFN_HIDEREADONLY
	mov [esi].lpstrTitle, 0

	push esi
        api _GetOpenFileNameA
;�������� �����
	push ebp
	push 0
	push dword ptr [ebp+ofn.lpstrFile]
	call MapFile
	mov dword ptr [ebp+hMap],eax
;�������� ������� �����
	push PAGE_READWRITE
	push MEM_RESERVE or MEM_COMMIT
	push 512000000
	push NULL
	api _VirtualAlloc
	mov dword ptr [ebp+WorkBuffer],eax
;����� ��� ������ ������
	push PAGE_READWRITE
	push MEM_RESERVE or MEM_COMMIT
	push 104851010
	push NULL
	api _VirtualAlloc
	mov dword ptr [ebp+CompressBuffer],eax
;�������� ������ �����
	push NULL
	push FILE_ATTRIBUTE_NORMAL
	push OPEN_EXISTING
	push NULL
	push FILE_SHARE_WRITE or FILE_SHARE_READ 
	push GENERIC_WRITE or GENERIC_READ
	push dword ptr [ebp+ofn.lpstrFile]
	api _CreateFileA
	mov dword ptr [ebp+hFile],eax
	
	push 0
	push eax
	api _GetFileSize
	mov dword ptr [ebp+FileSize],eax
;�������� �����
	push ebp

	mov ecx,dword ptr [ebp+hMap]
	assume ecx:ptr Header
	push [ecx].DecompressSize
	push dword ptr [ebp+ofn2.lpstrFile]
	call MapFile
	mov dword ptr [ebp+hMap2],eax
;������� ������� �����	
	mov eax,0
	mov ecx,256*33
	mov edi,dword ptr [ebp+WorkBuffer]
	rep stosb
;��������� ���
	push dword ptr [ebp+WorkBuffer]
	push dword ptr [ebp+hMap]
	push dword ptr [ebp+hMap2]
	call bp_decompress
;������� ��������
	push hMap
	api _UnmapViewOfFile
	
	push hMap2
	api _UnmapViewOfFile
;��������� �������
	push 0
	api _ExitProcess
ToEnd:
	endproc
end start
;===============================================================================;
;				End Program					;
;===============================================================================;
;

#FSCTL_IS_VOLUME_DIRTY = $90078
#VOLUME_IS_DIRTY = 1

; ChrisR
; https://www.purebasic.fr/english/viewtopic.php?p=654558#p654558
Procedure IsVolumeDirty(Drive.s)
	Protected hDevice, Dirty.l, BytesReturned.l 
	Protected Result = -1   ; -1 = Error (eg: missing admin rights or drive not found)
	
	hDevice = CreateFile_("\\.\" + Left(Drive, 1) + ":", #GENERIC_READ, #FILE_SHARE_READ | #FILE_SHARE_WRITE, #Null, #OPEN_EXISTING, #FILE_ATTRIBUTE_NORMAL, #Null)
	If hDevice <> #INVALID_HANDLE_VALUE
		If DeviceIoControl_(hDevice, #FSCTL_IS_VOLUME_DIRTY, #Null, 0, @Dirty, SizeOf(Dirty), @BytesReturned, #Null)
			Result = Dirty & #VOLUME_IS_DIRTY ; =1
		EndIf
		CloseHandle_(hDevice)
	EndIf
	
	ProcedureReturn Result
EndProcedure


Procedure KillProcess_hWin(hwin)
	Protected phandle, result, PID
	GetWindowThreadProcessId_(hwin, @PID)
	phandle = OpenProcess_(#PROCESS_TERMINATE, #False, PID)
	If phandle <> #Null
		result = TerminateProcess_(phandle, 1) ; успех <> 0
		CloseHandle_(phandle)
	EndIf
	ProcedureReturn result
EndProcedure


Procedure SaveFile_Buff(File.s, *Buff, Size)
	Protected Result = #False
	Protected ID = CreateFile(#PB_Any, File)
	If ID
		If WriteData(ID, *Buff, Size) = Size
			Result = #True
		EndIf
		CloseFile(ID)
	EndIf
	ProcedureReturn Result
EndProcedure


; Windows1251 в 866
Procedure.s ToOem(String$)
	Protected Ret$, *Buff, SizeBuff
	If Asc(String$)
		SizeBuff = Len(String$)
		*Buff = AllocateMemory(SizeBuff + 1)
		PokeS(*Buff, String$, SizeBuff, #PB_Ascii)
		CharToOemBuffA(*Buff, *Buff, SizeBuff)
		Ret$ = PeekS(*Buff, SizeBuff, #PB_Ascii)
		FreeMemory(*Buff)
	EndIf
	ProcedureReturn Ret$
EndProcedure


; Найти окно CMD запущенное от своего ChkDskGui и задать его размер. На данный момент не используется.
; Procedure InstanceToWnd(iPid)
; 	Protected hWnd = FindWindow_(0, 0)
; 	Protected iPid1, ThreadID
; 	While hWnd <> 0
; 		If GetParent_(hWnd) = 0
; 			ThreadID = GetWindowThreadProcessId_(hWnd, @iPid1)
; 			If iPid1 = iPid
; 				Break
; 			EndIf
; 		EndIf
; 		hWnd = GetWindow_(hWnd, #GW_HWNDNEXT)
; 	Wend
; 	ProcedureReturn hWnd
; EndProcedure
; IDE Options = PureBasic 6.04 LTS (Windows - x64)
; CursorPosition = 11
; Folding = -
; EnableXP
; UseIcon = ChkDskGui.ico
; Executable = ChkDskGui_x64.exe
; CompileSourceDirectory
; IncludeVersionInfo
; VersionField0 = 3.5.0.0
; VersionField2 = AZJIO
; VersionField3 = ChkDskGui
; VersionField4 = 3.5
; VersionField6 = ChkDskGui
; VersionField9 = AZJIO
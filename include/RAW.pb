EnableExplicit

; https://usbtor.ru/viewtopic.php?p=76839#76839
; https://www.purebasic.fr/english/viewtopic.php?p=153623#p153623

;Чтение размера RAW диска
Structure DISK_GEOMETRY
	Cylinders.q
	MediaType.l
	TracksPerCylinder.l
	SectorsPerTrack.l
	BytesPerSector.l
EndStructure

Structure DISK_GEOMETRY_EX Extends DISK_GEOMETRY
	DiskSize.q
	byte.b[1]
EndStructure

#FILE_ANY_ACCESS = 0
#METHOD_BUFFERED = 0
#IOCTL_DISK_BASE = 7

Macro CTL_CODE(DeviceType, Function, Method, Access)
	((DeviceType)<<16)|((Access)<<14)|((Function)<<2)|(Method)
EndMacro

#IOCTL_DISK_GET_DRIVE_GEOMETRY_EX = CTL_CODE(#IOCTL_DISK_BASE, $28, #METHOD_BUFFERED, #FILE_ANY_ACCESS)

Declare.q GetDriveSize(Drive.s)

Procedure.q GetDriveSize(Drive.s)
	Protected device.l, bytes.l, os.OSVERSIONINFO, disk.DISK_GEOMETRY_EX
	os\dwOSVersionInfoSize = SizeOf(OSVERSIONINFO)
	device = CreateFile_("\\.\" + Drive, #GENERIC_READ|#GENERIC_WRITE, #FILE_SHARE_READ|#FILE_SHARE_WRITE, 0, #OPEN_EXISTING, 0, 0)
	If device <> #INVALID_HANDLE_VALUE
		DeviceIoControl_(device, #IOCTL_DISK_GET_DRIVE_GEOMETRY_EX, 0, 0, @disk, SizeOf(disk), @bytes, 0)
		CloseHandle_(device)
	EndIf
	ProcedureReturn disk\Disksize
EndProcedure
; IDE Options = PureBasic 5.70 LTS (Windows - x64)
; CursorPosition = 29
; Folding = -
; EnableXP
; UseIcon = ChkDskGui.ico
; Executable = ChkDskGui_x64.exe
; IncludeVersionInfo
; VersionField0 = 3.5.0.0
; VersionField2 = AZJIO
; VersionField3 = ChkDskGui
; VersionField4 = 3.5
; VersionField6 = ChkDskGui
; VersionField9 = AZJIO
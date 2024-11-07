;- TOP
; Author AZJIO 
; ChkDskGui v4.3  (07.11.2024)

; последнее обновление:
; Улучшение читаемости кода: числа в гаджетах, окнах, меню, пунктах, шрифтах, изображениях сделал именованными константами.
; Для x86 сделал отключение перенаправления в системную папку в случае если в SysWOW64 отсутствует chkdsk. Запускает x64.

; игнор ошибок работает с SEM_FAILCRITICALERRORS
; байтовые флаги заменил на integer
; причесал исходник по отступам и убрал неиспользуемы переменные
; Добавлена иконка "?" для сбойных/неизвестных дисков
; Игнорирование ошибок при чтении пустых картридеров
; Добавлено MBR/GPT
; Исправил двойной клик
; Запрет проверки файловых систем EXT3/EXT4, чекбокс скрыт
; Добавлено клик по пункту ставит галку в чекбокс
; Добавлена полоса заполненности дисков
; Добавлены фирменные названия дисков
; Правильное определение дисков с несколькими разделами
; Определение размера диска со сбоем в ФС
; Сортировка списка дисков
; Двойной клик по строке списка дисков открывает диск в проводнике
; Удалено игнорирование дисков по отсутствию файловой системы
; Добавление в меню дисков
; Добавлено обновление списка при вставке/извлечении флешки

EnableExplicit


Define *Lang, UserIntLang, ForceLang, Lang_ini$
If OpenLibrary(0, "kernel32.dll")
	*Lang = GetFunction(0, "GetUserDefaultUILanguage")
	If *Lang And CallFunctionFast(*Lang) = 1049 ; ru
		UserIntLang = 1
	EndIf
	CloseLibrary(0)
EndIf


;- ● En
#CountStrLang = 55
Global Dim Lng.s(#CountStrLang)
Lng(1) = "Error"
Lng(2) = "No disc found"
Lng(3) = "-Disk-"
Lng(4) = "- N -"
Lng(5) = "Type"
Lng(6) = "- Disc label -"
Lng(7) = "- FS -"
Lng(8) = "Size"
Lng(9) = "- Name -"
Lng(10) = "- Usage -"
Lng(11) = "\F - Fix disk errors"
Lng(12) = "\R - Recovery of bad sectors"
Lng(13) = "\X - Forced volume disconnection"
Lng(14) = "Select all drives"
Lng(15) = "Start"
Lng(16) = "Copy to clipboard for Win+R"
Lng(17) = "Menu"
Lng(18) = "Check drives now"
Lng(19) = "Physical disks are better"
Lng(20) = "checked in different streams,"
Lng(21) = "saving time"
Lng(22) = "Copy command line"
Lng(23) = "Full line for Win+R"
Lng(24) = "Short line for Win+R"
Lng(25) = "For bat file"
Lng(26) = "Registry"
Lng(27) = "Checking the selected drives when booting the OS"
Lng(28) = "View BootExecute in the registry"
Lng(29) = "eventvwr.exe (check log)"
Lng(30) = "Delete ChkDskGui in the disk menu"
Lng(31) = "Add ChkDskGui to the disc menu"
Lng(32) = "(admin)"
Lng(33) = "Create ini"
Lng(34) = "Help chkdsk.exe"
Lng(35) = "Help ChkDskGui"
Lng(36) = "Download ChkDskGui Help"
Lng(37) = "Message"
Lng(38) = "Run from admin and select drive"
Lng(39) = "Run from admin"
Lng(40) = "Need to select a drive"
Lng(41) = "Added to the registry:"
Lng(42) = "Cannot add to registry"
Lng(43) = "Overwrite ini?"
Lng(44) = "Run"
Lng(45) = "ChkDskGui (connected -"
Lng(46) = "ChkDskGui (disconnected -"
Lng(47) = "Help"
Lng(48) = "About"
Lng(49) = "Author"
Lng(50) = "Version"
Lng(51) = "Want to visit the topic for updates?"
Lng(52) = "Open in Explorer"
Lng(53) = "Continue?"
Lng(54) = "Fixed"
Lng(55) = "Rem  "


;- # Constants

#Desktop = 0
#Window = 0

Enumeration
	#Menu0
	#Menu1
EndEnumeration

Enumeration
	#Font0
	#Font1
	#Font2
EndEnumeration

Enumeration
	#img0
	#img1
	#img2
EndEnumeration

Enumeration
	#LIG
	#chF
	#chR
	#chX
	#StatusBar
	#btnMenu
	#btnStart
	#btnNot ; удалить
	#chAll
EndEnumeration

Enumeration
	#mStart
	#mComLineFull
	#mComLineBrief
	#mEventvwr
	#mBootExecute
	#mHelpChkdsk
	#mCheckingSel
	#mHelpGUI
	#mBatFile
	#mCreateINI
	#mDiscMenu
	#mAbout
	#mOpen
EndEnumeration

; константы и структуры MBR/GPT
; https://www.purebasic.fr/english/viewtopic.php?t=25663&p=220673

#PARTITION_STYLE_MBR = 0
#PARTITION_STYLE_GPT = 1
#PARTITION_STYLE_RAW = 2
#IOCTL_DISK_GET_DRIVE_LAYOUT_EX = $70050

;- ● Structure

Structure PARTITION_INFORMATION_GPT Align #PB_Structure_AlignC
	Partitiontype.GUID
	PartitionId.GUID
	Attributes.q
	Name.b[36]
EndStructure

Structure PARTITION_INFORMATION_MBR Align #PB_Structure_AlignC
	PartitionType.b
	BootIndicator.b
	RecognizedPartition.b
	HiddenSectors.l
EndStructure

Structure DRIVE_LAYOUT_INFORMATION_GPT Align #PB_Structure_AlignC
	PartitionStyle.GUID
	StartingUsableOffset.LARGE_INTEGER
	UsableLength.LARGE_INTEGER
	MaxPartitionCount.l
EndStructure

Structure DRIVE_LAYOUT_INFORMATION_MBR Align #PB_Structure_AlignC
	DiskId.l
	PartitionCount.l
EndStructure

Structure PARTITION_INFORMATION_EX Align #PB_Structure_AlignC
	PartitionStyle.l
	StartingOffset.LARGE_INTEGER
	PartitionLength.LARGE_INTEGER
	PartitionNumber.l
	RewritePartition.b
	StructureUnion
		ppmbr.PARTITION_INFORMATION_MBR
		ppgpt.PARTITION_INFORMATION_GPT
	EndStructureUnion
EndStructure

Structure DRIVE_LAYOUT_INFORMATION_EX Align #PB_Structure_AlignC
	PartitionStyle.l
	PartitionCount.l
	StructureUnion
		pdmbr.DRIVE_LAYOUT_INFORMATION_MBR
		pdgpt.DRIVE_LAYOUT_INFORMATION_GPT
	EndStructureUnion
	PartitionEntry.PARTITION_INFORMATION_EX[255]
EndStructure
; конец => константы и структуры MBR/GPT

Global hListView, lvi.LV_ITEM
Global indexSort = 1
Global SortOrder = 1

Structure STORAGE_PROPERTY_QUERY
	PropertyId.l
	QueryType.l
	AdditionalParameters.l
EndStructure

Structure STORAGE_DEVICE_DESCRIPTOR
	Version.l
	Size.l
	DeviceType.b
	DeviceTypeModifier.b
	RemovableMedia.b
	CommandQueueing.b
	VendorIdOffset.l
	ProductIdOffset.l
	ProductRevisionOffset.l
	SerialNumberOffset.l
	BusType.w
	RawPropertiesLength.l
	RawDeviceProperties.b
	Reserved.b[1024]
EndStructure

Import "user32.lib"
	OemToCharBuffA(*Buff, *Buff1, SizeBuff)
	CharToOemBuffA(*Buff, *Buff1, SizeBuff)
EndImport

;- ● Declare
Declare HelpChkdsk() ; справка по командам chkdsk.exe
Declare GetDrives(List Drive.s()) ; получает буквы существующих дисков
Declare.s ComboListDrive(Drive2$) ; получает инфу о дисках
Declare InstanceToWnd(iPid)
; Declare.s FormatSizeDisk(Num.q) ; делает размер в формат гигабайты
Declare.s DriveGetNumber(DriveLetter$) ; получает номера дисков в формате [0:1]
Declare.s DriveGetName(DriveLetter$)   ; получает название дисков
Declare.s GetComString()      ; получает ком-строку
Declare.s ReadProgramStringOem(iPid)   ; читает строку и перекодирует её в Win-1251
Declare MyWindowCallback(WindowId, Message, wParam, lParam)
Declare.s GetCommand(fill = 0)
Declare.s ToOem(String$)
Declare SaveFile_Buff(File.s, *Buff, Size)
Declare Insert_Command(d)
Declare Del_item_LV(Mask.l)
Declare Add_item_LV(Drive2$)
Declare Add_item_LV_Mask(Mask.l)
Declare align_col_LV()
Declare RegToMenuDisk()
Declare RegJump(valie.s)
Declare KillProcess_hWin(hwin)
Declare RegExistsKey()
Declare DuplicateDriveTest()
Declare align_Windows()
Declare HideCheckBox(gadget, item)
Declare.s Get_MBR_GPT(DriveNum$)

;- ● IncludeFile
XIncludeFile "include\Sort.pb"
XIncludeFile "include\SetCoor.pb"
XIncludeFile "include\RAW.pb"
XIncludeFile "include\ListProgress.pb"

; Сохранение размера и координат часть 1
Declare SaveINI() ; Сохранения в ini
				  ; Для подсказок часть 1 из 3-х
Declare AddGadgetToolTip(GadgetID.l, ToolText$, MaxWidth.l = 0, Balloon.l = 1, WindowID.l = -1)
;- ● Global
Global NewMap hToolTips.l()

; размеры неклиентской области окна (заголовок и границы окна)
Global caption_h, BorderX, BorderY
caption_h = GetSystemMetrics_(#SM_CYCAPTION) ; высота заголовка
BorderX = GetSystemMetrics_(#SM_CXFRAME) * 2 ; ширина (толщина) вертикальных границ
BorderY = GetSystemMetrics_(#SM_CYFRAME) * 2 + caption_h ; высота (толщина) горизонтальных границ + заголовок

Global NewList Drive.s()
Global MaxDeviceNumber = 0
Global Dim MBR_GPT.s(0)
; MBR_GPT(0) = "GPT"
Define DiskCur$
Global Admin = IsUserAnAdmin_()


Define i
Global CountDisk, cmd$ = "cmd.exe", drives_avail

; добавил код перенаправления Wow64DisableWow64FsRedirection.
; Исправить получение системного диска, так как каталог юзера может находится не на диске с папкой Windows.
; компиляция взависимости от x86 или x64 (костыли для кривых WinPE)
CompilerIf #PB_Compiler_Processor = #PB_Processor_x86 ; если ChkDskGui-x86
	Global hKrnDLL, *Func, RedirectRequired
	
	Procedure Is64BitOS()
		Protected HDLL, IsWow64Process_, Is64BitOS
		
		If SizeOf(Integer) = 8
			Is64BitOS = 1   ; this is a 64 bit exe
		Else
			HDll = OpenLibrary(#PB_Any, "kernel32.dll")
			If HDll
				IsWow64Process_ = GetFunction(HDll, "IsWow64Process")
				If IsWow64Process_
					CallFunctionFast(IsWow64Process_, GetCurrentProcess_(), @Is64BitOS)
				EndIf
				CloseLibrary(HDll)
			EndIf
		EndIf
		
		ProcedureReturn Is64BitOS
	EndProcedure
	
	Procedure GetCmdPath()
		Protected sysdisk$, IsWow64ProcessFlag
		hKrnDLL = OpenLibrary(#PB_Any, "Kernel32.dll")
		If hKrnDLL
			*Func = GetFunction(hKrnDLL, "IsWow64Process")
			If *Func
				CallFunctionFast(*Func, GetCurrentProcess_(), @IsWow64ProcessFlag)
				*Func = 0
				If IsWow64ProcessFlag And SizeOf(Integer) = 4
					*Func = GetFunction(hKrnDLL, "Wow64DisableWow64FsRedirection")
					If *Func
						sysdisk$ = Left(GetUserDirectory(#PB_Directory_Programs), 3) + "Windows\"
						CallFunctionFast(*Func, 0) ; отключили перенаправление
						If FileSize(sysdisk$ + "SysWOW64\cmd.exe") > 1 And FileSize(sysdisk$ + "SysWOW64\chkdsk.exe") > 1
							; cmd$ = "cmd.exe" ; по факту будет использоваться нативный x32 и ничего делать не нужно
							ProcedureReturn
						ElseIf FileSize(sysdisk$ + "System32\cmd.exe") > 1 And FileSize(sysdisk$ + "System32\chkdsk.exe") > 1
; 							если нативный способ урезан, то запускаем x64
							cmd$ = sysdisk$ + "System32\cmd.exe"
							RedirectRequired = 1 ; требуется перенаправление, так как x86 запускает 64-битную версию cmd.exe
						ElseIf FileSize(sysdisk$ + "SysWOW64\cmd64.exe") > 0 ; костыль для какой то WinPE
							cmd$ = "cmd64.exe"
						EndIf
						If RedirectRequired = 0
							CallFunctionFast(*Func, 1) ; включили перенаправление
						EndIf
					EndIf
				EndIf
			EndIf
			
			If RedirectRequired = 0
				CloseLibrary(hKrnDLL) 
			EndIf
			
		EndIf
	EndProcedure

	If Is64BitOS() And OSVersion() >= #PB_OS_Windows_Vista ; если запущен на Windpws-x64
		GetCmdPath()
	EndIf
CompilerEndIf

; Debug RedirectRequired
; Debug cmd$

; Создаём структуру, для выравнивания в колонке размера списка дисков
Global ListViewSpalte.LV_COLUMN
ListViewSpalte\mask = #LVCF_FMT


Global ini$
Global ignore$ = ""
Global fINI = 1
Global StartDisk = 2
Global FontSize = 9
Global Color$ = "1e"
Global Font1$ = "Consolas"
Global Font2$ = "Segoe UI"
Global AlignWin = 1

; без копирования
Procedure Limit(*Value.integer, Min, Max)
	Protected res
	If *Value\i < Min
		*Value\i = Min
		res = 1
	ElseIf *Value\i > Max
		*Value\i = Max
		res = 1
	EndIf
	ProcedureReturn res
EndProcedure

;- ● ini
; получаем путь к ини по имени программы
; ini$ = GetPathPart(ProgramFilename()) + GetFilePart(ProgramFilename(), #PB_FileSystem_NoExtension) + ".ini"
; ini$ = ReplaceString(ProgramFilename(), ".exe", ".ini")
ini$ = Left(ProgramFilename(), Len(ProgramFilename()) - 3) + "ini"
ExamineDesktops()
If FileSize(ini$) > 3 And OpenPreferences(ini$) And PreferenceGroup("set")
	StartDisk = ReadPreferenceInteger("StartDisk", 2)
	If Limit(@StartDisk, 0, 25)
		WritePreferenceInteger("StartDisk" , StartDisk) ; Сразу исправляем неверные данные
	EndIf
	FontSize = ReadPreferenceInteger("FontSize", 9)
	If Limit(@FontSize, 7, 15)
		WritePreferenceInteger("FontSize" , FontSize)
	EndIf
	indexSort = ReadPreferenceInteger("indexSort", 1)
	If Limit(@indexSort, -1, 7)
		WritePreferenceInteger("indexSort" , indexSort)
	EndIf
	AlignWin = ReadPreferenceInteger("align", 1)
	If Limit(@AlignWin, 0, 1)
		WritePreferenceInteger("align" , AlignWin)
	EndIf
	SortOrder = ReadPreferenceInteger("SortOrder", 1)
	If Not(SortOrder = 1 Or SortOrder = -1)
		SortOrder = 1
		WritePreferenceInteger("SortOrder" , 1)
	EndIf
	Color$ = ReadPreferenceString("Color", "1e")
	If Val("$" + Color$) > 255 Or Val("$" + Color$) < 1
		Color$ = "1e"
		WritePreferenceString("Color" , "1e")
	EndIf
	Font1$ = ReadPreferenceString("Font1", "Consolas")
	Font2$ = ReadPreferenceString("Font2", "Segoe UI")

	ignore$ = ReadPreferenceString("ignore", "")
	ForceLang = ReadPreferenceInteger("ForceLang", ForceLang)


	With cs
		\m = ReadPreferenceInteger("WinM", 0)
		\x = ReadPreferenceInteger("WinX", (DesktopWidth(#Desktop) - 692) / 2)
		\y = ReadPreferenceInteger("WinY", (DesktopHeight(#Desktop) - 210) / 2)
		\w = ReadPreferenceInteger("WinW", 692)
		\h = ReadPreferenceInteger("WinH", 210)
	EndWith

	ClosePreferences()
	;  	Debug Color$
	;  	Debug Val("$" + Color$)
	; 	Debug FontSize
	; 	Debug ini$
	;  	Debug Font1$
	;  	Debug Font2$
	;  	Debug GUI_H
	; 	MessageRequester("Координаты до", Str(cs\x) + #CRLF$ + Str(cs\y) + #CRLF$ + Str(cs\w) + #CRLF$ + Str(cs\h))
	_SetCoor(@cs, 692, 210, 3, 0, 0) ; Выравниваем если прочитали из ini
									 ; 	MessageRequester("Координаты после", Str(cs\x) + #CRLF$ + Str(cs\y) + #CRLF$ + Str(cs\w) + #CRLF$ + Str(cs\h))
	fINI = 0
EndIf



; Здесь нужно прочитать флаг из ini-файла определяющий принудительный язык, где
; 0 - автоматически
; -1 - принудительно первый
; 1 - принудительно второй
; Тем самым будучи в России можно выбрать англ язык или будучи в союзных республиках выбрать русский язык
If ForceLang = 1
	UserIntLang = 0
ElseIf ForceLang = 2
	UserIntLang = 1
EndIf

Procedure SetLangTxt(PathLang$)
	Protected file_id, Format, i, tmp$
	
	file_id = ReadFile(#PB_Any, PathLang$) 
	If file_id ; Если удалось открыть дескриптор файла, то
		Format = ReadStringFormat(file_id) ;  перемещаем указатель после метки BOM
		i=0
		While Eof(file_id) = 0        ; Цикл, пока не будет достигнут конец файла. (Eof = 'Конец файла')
			tmp$ =  ReadString(file_id, Format) ; читаем строку
								  ; If Left(tmp$, 1) = ";"
								  ; Continue
								  ; EndIf
; 			tmp$ = ReplaceString(tmp$ , #CR$ , "") ; коррекция если в Windows
			tmp$ = RTrim(tmp$ , #CR$) ; коррекция если в Windows
			If Asc(tmp$) And Asc(tmp$) <> ';'
				i+1
				If i > #CountStrLang ; массив Lng() уже задан, но если строк больше нужного, то не разрешаем лишнее
					Break
				EndIf
; 				Lng(i) = UnescapeString(tmp$) ; позволяет в строке иметь экранированные метасимволы, \n \t и т.д.
				Lng(i) = ReplaceString(tmp$, "\n", #LF$) ; В ini-файле проблема только с переносами, поэтому заменяем только \n
			Else
				Continue
			EndIf
		Wend
		CloseFile(file_id)
	EndIf
	; Else
	; SaveFile_Buff(PathLang$, ?LangFile, ?LangFileend - ?LangFile)
EndProcedure

; Если языковой файл существует, то использует его
; Lang_ini$ = GetPathPart(ProgramFilename()) + "Lang.ini"
; Lang_ini$ = GetPathPart(ProgramFilename()) + GetFilePart(ProgramFilename(), #PB_FileSystem_NoExtension) + "_Lang.ini"
Lang_ini$ = Left(ProgramFilename(), Len(ProgramFilename()) - 4) + "_Lang.ini"
If FileSize(Lang_ini$) > 100
	UserIntLang = 0
	SetLangTxt(Lang_ini$)
EndIf

;- ● Ru
If UserIntLang
	Lng(1) = "Ошибка"
	Lng(2) = "Не найдено ни одного диска"
	Lng(3) = "-Диск-"
	Lng(4) = "- № -"
	Lng(5) = "-Тип-"
	Lng(6) = "- Метка диска -"
	Lng(7) = "-FS-"
	Lng(8) = "Размер"
	Lng(9) = "     - Имя - "
	Lng(10) = "- Занято -"
	Lng(11) = "\F - Исправление ошибок на диске"
	Lng(12) = "\R - Восстановление поврежденных секторов"
	Lng(13) = "\X - Принудительное отключение тома"
	Lng(14) = "Выделить все диски"
	Lng(15) = "Старт"
	Lng(16) = "Скопировать в буфер обмена для Win+R"
	Lng(17) = "Меню"
	Lng(18) = "Проверка дисков сейчас"
	Lng(19) = "Физические диски лучше"
	Lng(20) = "в разных потоках выполнить"
	Lng(21) = "экономя время"
	Lng(22) = "Копировать ком-строку"
	Lng(23) = "Полную для Win+R"
	Lng(24) = "Краткую для Win+R"
	Lng(25) = "Для bat-файла"
	Lng(26) = "Реестр"
	Lng(27) = "Проверка выбранных при загрузке ОС"
	Lng(28) = "Посмотреть BootExecute в реестре"
	Lng(29) = "eventvwr.exe (лог проверки)"
	Lng(30) = "Удалить ChkDskGui в меню дисков"
	Lng(31) = "Добавить ChkDskGui в меню дисков"
	Lng(32) = "(админ)"
	Lng(33) = "Создать ini"
	Lng(34) = "Справка chkdsk.exe"
	Lng(35) = "Справка ChkDskGui"
	Lng(36) = "Скачать справку ChkDskGui"
	Lng(37) = "Сообщение"
	Lng(38) = "Запустите от админа и выберите диск"
	Lng(39) = "Запустите от админа"
	Lng(40) = "Нужно выбрать диск"
	Lng(41) = "Добавлено в реестр:"
	Lng(42) = "Не удаётся добавить в реестр"
	Lng(43) = "Перезаписать ini?"
	Lng(44) = "Выполнить"
	Lng(45) = "ChkDskGui (подключен "
	Lng(46) = "ChkDskGui (отключен "
	Lng(47) = "Справка"
	Lng(48) = "О программе"
	Lng(49) = "Автор"
	Lng(50) = "Версия"
	Lng(51) = "Хотите посетить тему обсуждения" + #CRLF$ + "и узнать об обновлениях?"
	Lng(52) = "Открыть в Проводнике"
	Lng(53) = "Продолжить?"
	Lng(54) = "Fixed"
	Lng(55) = "Rem  "
EndIf

;- ● DataSection
DataSection
	DiskFixed:
	IncludeBinary "image\Fixed.ico"

	DiskRem:
	IncludeBinary "image\Rem.ico"

	DiskUnk:
	IncludeBinary "image\Unk.ico"

	ini:
	IncludeBinary "sample.ini"
	iniend:
EndDataSection

; отключаем флаг ошибок
Define tmp
Define hKey
; отключаем мессаги с выводом ошибок перед тем как сканировать диски
SetErrorMode_(#SEM_FAILCRITICALERRORS)

; Запрос дисков и информации
GetDrives(Drive()) ; добавляем буквы всех дисков
				   ; ComboListDrive(Drive()) ; добавляем остальную инфу к дискам и удаляем диски если они не FIXED REMOVABLE

; проверка налиия дисков, мало ли вдруг только рам-диски будут в системе из-за отсутствия драйверов

CountDisk = ListSize(Drive())
If Not CountDisk
	MessageRequester(Lng(1), Lng(2))
	End ; Выход, так как нет смысла дальнейшего выполнения скрипта
EndIf

If fINI
	; 	DesktopW = DesktopWidth(#Desktop)
	; 	DesktopH = DesktopHeight(#Desktop)
	With cs
		\h = 24 + 18 * CountDisk + 100 ; подсчитали усреднённо на Win10 при 18 - высота пункта, 24 - высота названия колонок, 100 остальное.
									   ;  		\h = 24 + 18 * CountDisk + 58 + BorderY ; MessageRequester(Lng(37), Str(BorderY))
		\w = 692
		\x = (DesktopWidth(#Desktop) - \w) / 2
		\y = (DesktopHeight(#Desktop) - \h) / 2
		\m = 0
	EndWith
EndIf

Global hGUI ;, hListView
Define k, res$, TrgS, info$, disk$, valie.s, hwnd, fMenuDisk
Define SelDisk$

; Procedure heightLV()
;   Protected header, rect.RECT, headerRect.RECT
;     header = SendMessage_(hListView,#LVM_GETHEADER,0,0)                 ; get header control
;     GetClientRect_(header,headerRect.RECT)                                     ; get size of header control
;     SendMessage_(hListView, #LVM_GETITEMRECT, 0, @rect)				   ; get rect for item 0
;     ProcedureReturn headerRect\bottom - headerRect\top + (rect\bottom - rect\top) * CountDisk
;     ProcedureReturn rect\bottom - rect\top ; 18
;     ProcedureReturn headerRect\bottom - headerRect\top ; 24
; EndProcedure

; Создаём окно
;-┌──GUI──┐
hGUI = OpenWindow(#Window, cs\x, cs\y, cs\w, cs\h, "ChkDskGui", #PB_Window_MinimizeGadget | #PB_Window_MaximizeGadget | #PB_Window_SizeGadget | #PB_Window_Invisible)




If hGUI
; 	HideWindow(#Window, #True)
	; 	загружаем иконки 16х16 в системный список изображений
	CatchImage(#img0, ?DiskFixed)
	CatchImage(#img1, ?DiskRem)
	CatchImage(#img2, ?DiskUnk)
	; Левый столбец. Список со значками с чек-боксом, выделять однос строкой
	hListView = ListIconGadget(#LIG, 5, 5, cs\w - 10, cs\h - 90, Lng(3), 60, #PB_ListIcon_CheckBoxes | #PB_ListIcon_FullRowSelect)

	; 	Стиль списка дисков, чёрный
	; 	SetGadgetColor(#LIG, #PB_Gadget_BackColor , RGB(55, 55, 55))
	; 	SetGadgetColor(#LIG, #PB_Gadget_FrontColor , RGB(180, 180, 180))

	; Устанавливает шрифт
	If OSVersion() >= #PB_OS_Windows_7
		If LoadFont(#Font0, Font1$, FontSize)
			SetGadgetFont(#LIG, FontID(#Font0))
		Else ; иначе, если Consolas не существует
			If LoadFont(#Font0, "Courier New", FontSize)
				SetGadgetFont(#LIG, FontID(#Font0))
			EndIf
		EndIf
	Else
		If LoadFont(#Font0, "Courier New", FontSize)
			SetGadgetFont(#LIG, FontID(#Font0))
		EndIf
	EndIf

	SetGadgetAttribute(#LIG, #PB_ListIcon_DisplayMode, #PB_ListIcon_Report) ; вид списка - таблица
																		 ; Добавить ещё 5 колонок
	AddGadgetColumn(#LIG, 1, Lng(4), 50)
	AddGadgetColumn(#LIG, 2, Lng(5), 52)
	AddGadgetColumn(#LIG, 3, Lng(6), 125)
	AddGadgetColumn(#LIG, 4, Lng(7), 55)
	AddGadgetColumn(#LIG, 5, Lng(8), 100)
	AddGadgetColumn(#LIG, 6, Lng(9), 230)
	AddGadgetColumn(#LIG, 7, "-", 55)
	AddGadgetColumn(#LIG, 8, Lng(10), 90)

	Global lpFreeBytesAvailable.q
	Global lpTotalNumberOfBytes.q
	i = 0
	ForEach Drive()
; 		If Mid(Drive(), 10, 3) = "Fix" ; у этоге есть баг, если дисков будет 10, то отступ символа будет 11 вместо 10
		Select StringField(Drive(), 3, Chr(10))
			Case Lng(54)
				AddGadgetItem(#LIG, -1, Drive(), ImageID(#img0))
			Case Lng(55)
				AddGadgetItem(#LIG, -1, Drive(), ImageID(#img1))
			Default
				AddGadgetItem(#LIG, -1, Drive(), ImageID(#img2))
		EndSelect
; 		res$ = StringField(Drive(), 3, Chr(10))
; 		If res$ = Lng(54)
; 			AddGadgetItem(#LIG, -1, Drive(), ImageID(#img0))
; 		ElseIf res$ = Lng(55)
; 			AddGadgetItem(#LIG, -1, Drive(), ImageID(#img1))
; 		Else
; 			AddGadgetItem(#LIG, -1, Drive(), ImageID(#img2))
; 		EndIf
		; перерисовка заполненности диска
		If GetDiskFreeSpaceEx_(Left(Drive(), 2), @lpFreeBytesAvailable, @lpTotalNumberOfBytes, 0)
			If lpTotalNumberOfBytes > 0 ; чтобы не было сбоя при неопределении диска, на 0 делить нельзя
; 				UpdateProgress(#LIG, i, 8, (lpTotalNumberOfBytes-lpFreeBytesAvailable) * 99.9 / lpTotalNumberOfBytes)
				UpdateProgress(#LIG, i, 8, Round((lpTotalNumberOfBytes - lpFreeBytesAvailable) * 100 / lpTotalNumberOfBytes , #PB_Round_Nearest))
			Else
				UpdateProgress(#LIG, i, 8, 1)
			EndIf
		Else
			UpdateProgress(#LIG, i, 8, 0)
		EndIf

		If Left(GetGadgetItemText(#LIG, i, 4) , 3) = "EXT"
			HideCheckBox(#LIG, i)
		EndIf
		i + 1
		; конец => перерисовка заполненности диска
	Next

	align_col_LV()

	; 	Вычисление ширины окна
	align_Windows()
; 	конец => Вычисление ширины окна


	; сортировка
	UpdatelParam()
	ForceSort()
	; сортировка конец

	ClearList(Drive())

	If LoadFont(#Font1, Font2$, FontSize) ; шрифт для чекбоксов
		SetGadgetFont(#PB_Default, FontID(#Font1))
	EndIf
	

;- ├ CheckBox / Button
	CheckBoxGadget(#chF, 10, cs\h - 80, cs\w - 190, 20, Lng(11)) : SetGadgetState(#chF, #PB_Checkbox_Checked)
	CheckBoxGadget(#chR, 10, cs\h - 60, cs\w - 190, 20, Lng(12))
	CheckBoxGadget(#chX, 10, cs\h - 40, cs\w - 190, 20, Lng(13)) : SetGadgetState(#chX, #PB_Checkbox_Checked)
	HyperLinkGadget(#StatusBar, 20, cs\h - 17, cs\w - 200, 17, "", $FF0000) ; строка состояния
	CheckBoxGadget(#chAll, cs\w - 179, cs\h - 80, 170, 20, Lng(14))

	If LoadFont(#Font2, Font2$, FontSize + 3) ; увеличенный шрифт для кнопок
		SetGadgetFont(#PB_Default, FontID(#Font2))
	EndIf
	ButtonGadget(#btnMenu, cs\w - 137, cs\h - 52, 24, 24, Chr($25BC)) ; "v"
	ButtonGadget(#btnStart, cs\w - 110, cs\h - 52, 100, 42, Lng(15))
	; 	ButtonGadget(7, cs\w - 179, cs\h - 52, 26, 42, "i")
	; 	SetActiveGadget(6)
	SetGadgetText(#StatusBar, "chkdsk.exe " + DiskCur$ + GetComString())

	; Для подсказок часть 2 из 3-х
	AddGadgetToolTip(#StatusBar, Lng(16), 300, 0)
	AddGadgetToolTip(#btnMenu, Lng(17), 300, 0)
	; 	AddGadgetToolTip(5, "Справка по ключам chkdsk.exe", 300, 0)
	AddGadgetToolTip(#btnStart, Lng(18), 300, 0)
	; 	AddGadgetToolTip(7, "Импорт в реестр для проверки" + #CRLF$ + "во время загрузки системы", 300, 0)
	AddGadgetToolTip(#chAll, Lng(19) + #CRLF$ + Lng(20) + #CRLF$ + Lng(21), 300, 0)

;- ├ Menu
	If CreatePopupMenu(#Menu0) ; Создаёт всплывающее меню
						  ; 		MenuItem(1, "Вставить краткую ком-строку в окно Выполнить")
						  ; 		MenuItem(2, "Вставить полную ком-строку в окно Выполнить")
		OpenSubMenu(Lng(22))
		MenuItem(#mComLineFull, Lng(23) + #TAB$ + "Ctrl+Shift+C")
		MenuItem(#mComLineBrief, Lng(24))
		MenuItem(#mBatFile, Lng(25))
		CloseSubMenu()
		OpenSubMenu(Lng(26))
		MenuItem(#mCheckingSel, Lng(27))
		MenuItem(#mBootExecute, Lng(28))
		MenuItem(#mEventvwr, Lng(29))

		fMenuDisk = RegExistsKey()
		If fMenuDisk
			MenuItem(#mDiscMenu, Lng(30))
		Else
			MenuItem(#mDiscMenu, Lng(31))
		EndIf
		CloseSubMenu()
		MenuItem(#mCreateINI, Lng(33))
		MenuItem(#mHelpChkdsk, Lng(34) + #TAB$ + "F2")
		MenuItem(#mHelpGUI, Lng(35) + #TAB$ + "F1")
		MenuItem(#mAbout, Lng(48))
		; 		MenuBar()
	EndIf

	; 	деактивируем если нет справки
	If FileSize(GetPathPart(ProgramFilename()) + "ChkDskGui.chm") < 1
		; 		DisableMenuItem(#Menu0, 7, 1)
		SetMenuItemText(#Menu0, #mHelpGUI, Lng(36))
	EndIf
	If Not Admin
		SetMenuItemText(#Menu0, #mCheckingSel, Lng(27) + " " + Lng(32))
		DisableMenuItem(#Menu0, #mCheckingSel, 1)
		If fMenuDisk
			SetMenuItemText(#Menu0, #mDiscMenu, Lng(30) + " " + Lng(32))
		Else
			SetMenuItemText(#Menu0, #mDiscMenu, Lng(31) + " " + Lng(32))
		EndIf

		DisableMenuItem(#Menu0, #mDiscMenu, 1)
	EndIf
	If CreatePopupMenu(#Menu1) ; Создаёт всплывающее меню
		MenuItem(#mOpen, Lng(52))
	EndIf
	; 	CheckBoxGadget(#chAll, 3, 128, 17, 17, "")

	; Устанавливает шрифт
	; 	If LoadFont(1, Font2$, FontSize)
	; 		For k = 1 To 4
	; 			SetGadgetFont(k, FontID(1))
	; 		Next
	; 		SetGadgetFont(8, FontID(1))
	; 	EndIf
	; 	If LoadFont(2, Font2$, FontSize+3)
	; 		For k = 5 To 7
	; 			SetGadgetFont(k, FontID(2))
	; 		Next
	; 	EndIf



	SetWindowCallback(@MyWindowCallback())
	; 	ResizeWindow(#Window, #PB_Ignore , #PB_Ignore , WinW , WinH)
	If cs\m ; флаг окно на весь экран
		SetWindowState(#Window, #PB_Window_Maximize)
	EndIf

	; 	Поддержка ком-строки
	tmp = CountProgramParameters()
	If tmp
		SelDisk$ = Left(ProgramParameter(), 2)
		For k = 0 To CountGadgetItems(#LIG) - 1
			If GetGadgetItemText(#LIG, k) = SelDisk$
				SetGadgetItemState(#LIG , k , #PB_ListIcon_Checked)
			EndIf
		Next
	EndIf
	HideWindow(#Window, #False)
	
	AddKeyboardShortcut(#Window, #PB_Shortcut_F1, #mHelpGUI) ; F1
	AddKeyboardShortcut(#Window, #PB_Shortcut_F2, #mHelpChkdsk) ; F2
	AddKeyboardShortcut(#Window, #PB_Shortcut_Control | #PB_Shortcut_Shift | #PB_Shortcut_C, #mComLineFull) ; Ctrl+Shift+C
; 	AddKeyboardShortcut(#Window, #PB_Shortcut_Control | #PB_Shortcut_E, #mOpen) ; Ctrl+E
	AddKeyboardShortcut(#Window, #PB_Shortcut_Return, #mStart) ; Enter
  

;-┌──Loop──┐
	Repeat
		Select WaitWindowEvent()
			Case #PB_Event_RightClick       ; нажата правая кнопка мыши =>
				DisplayPopupMenu(#Menu0, WindowID(#Window))  ; покажем всплывающее Меню
			Case #PB_Event_RestoreWindow
				cs\m = 0
			Case #PB_Event_MaximizeWindow
				cs\m = 1

;- ├ Gadget
			Case #PB_Event_Gadget
				Select EventGadget()
					Case #LIG
						i = GetGadgetState(#LIG)
						If i <> -1
							DiskCur$ = GetGadgetItemText(#LIG, i)
						EndIf
						Select EventType()
							Case #PB_EventType_RightClick
								DisplayPopupMenu(#Menu1, WindowID(#Window))  ; покажем всплывающее Меню
							Case #PB_EventType_LeftClick
								i = GetGadgetState(#LIG)
								If i <> -1
									tmp = 0
									If Not GetGadgetItemState(#LIG, i) & #PB_ListIcon_Checked
; 										If Left(GetGadgetItemText(#LIG, i, 4) , 3) = "EXT"
; 										If Left(GetGadgetItemText(#LIG, i, 4) , 3) = "FAT"
; 											Continue
; 										EndIf
										tmp = #PB_ListIcon_Checked
									EndIf
									SetGadgetItemState(#LIG , i , tmp)
								EndIf
							Case #PB_EventType_LeftDoubleClick
								RunProgram("explorer.exe", DiskCur$ + "\", "")
						EndSelect
						SetGadgetText(#StatusBar, "chkdsk.exe " + DiskCur$ + GetComString())
					Case #chF
						If GetGadgetState(#chF) = #PB_Checkbox_Unchecked
							SetGadgetState(#chR, #PB_Checkbox_Unchecked)
							SetGadgetState(#chX, #PB_Checkbox_Unchecked)
						EndIf
						SetGadgetText(#StatusBar, "chkdsk.exe " + DiskCur$ + GetComString())
					Case #chR
						SetGadgetState(#chF, #PB_Checkbox_Checked)
						SetGadgetText(#StatusBar, "chkdsk.exe " + DiskCur$ + GetComString())
					Case #chX
						If GetGadgetState(#chX) = #PB_Checkbox_Checked
							SetGadgetState(#chF, #PB_Checkbox_Checked)
						EndIf
						SetGadgetText(#StatusBar, "chkdsk.exe " + DiskCur$ + GetComString())
						; 				Case #StatusBar
						;
					Case #StatusBar
						SetClipboardText(cmd$ + " /c (" + GetGadgetText(#StatusBar) + " & Pause)")
					Case #btnMenu ; ?
						DisplayPopupMenu(#Menu0, WindowID(#Window))  ; покажем всплывающее Меню
					Case #btnStart          ; Старт
						res$ = GetCommand(0)
						If Not Asc(res$)
							Continue
						EndIf
						; SetClipboardText("cmd.exe /c (Title Check Disk " + info$ + " & @Echo off & @Echo. & Color " + Color$ + " & chkdsk.exe " + disk$ + GetComString() + " & set /p Ok=^>^>)")
						; cmd.exe /c (Title Check Disk "тут инфа о диске" & @Echo off & @Echo. & Color f0 & chkdsk.exe Z: /F /X & set /p Ok=^>^>)
						; MessageRequester("Выбранные", res$)

						RunProgram(cmd$, "/c (" + res$ + " set /p Ok=^>^>)", GetPathPart(ProgramFilename()))
						; Delay(500)
						; WindowName.s="Check Disk " + info$
						; handle=FindWindow_(0,WindowName)
						; If handle
						; 	MoveWindow_(handle, 5, 210+5, 800, 600, 0)
						; 	MessageRequester("???", "сработало ли условие")
						; EndIf
						; MoveWindow_(hGUI, 5, 5, 480, 210, 0)

						;
						; ThreadID=RunProgram("cmd.exe","","",#PB_Program_Open)
						; Sleep_(2000)
						; iPid=ProgramID(ThreadID)
						; hWnd=InstanceToWnd(iPid)
						; MoveWindow_(hWnd, 5, 5, 480, 210, 0)
						; Sleep_(2000)
						; MoveWindow_(hWnd, 5, 5, 210, 480, 0)
						; Sleep_(2000)
						; MoveWindow_(hWnd, 200, 200, 480, 210, 0)
						; Sleep_(2000)
						; MoveWindow_(hWnd, 200, 200, 640, 480, 0)
					Case #chAll
						tmp = 0
						If GetGadgetState(#chAll) = #PB_Checkbox_Checked
							tmp = #PB_ListIcon_Checked
						EndIf
						For k = 0 To CountGadgetItems(#LIG) - 1
							SetGadgetItemState(#LIG, k , tmp)
						Next
				EndSelect





;- ├ Menu
			Case #PB_Event_Menu        ; кликнут элемент всплывающего Меню
				Select EventMenu()    ; получим кликнутый элемент Меню...
					Case #mStart
						res$ = GetCommand(0)
						If Not Asc(res$)
							Continue
						EndIf
						RunProgram(cmd$, "/c (" + res$ + " set /p Ok=^>^>)", GetPathPart(ProgramFilename()))
					Case #mComLineFull
						Insert_Command(1)
					Case #mComLineBrief
						Insert_Command(2)
					Case #mEventvwr
						RunProgram("eventvwr.exe")
						SetClipboardText("Wininit")
					Case #mBootExecute ; посмотреть в реестре
						RegJump("HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager")
					Case #mHelpChkdsk
						HelpChkdsk()
					Case #mCheckingSel ; i импорт рег-данных
						TrgS = 0
						info$ = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
						For k = 0 To CountGadgetItems(#LIG) - 1
							If (GetGadgetItemState(#LIG, k) & #PB_ListIcon_Checked)
								info$ = ReplaceString(info$, Left(GetGadgetItemText(#LIG, k), 1), "")
								TrgS + 1
								; 					MessageRequester(Lng(37), info$)
							EndIf
						Next
						If Not TrgS And Not Admin
							MessageRequester(Lng(37), Lng(38))
							Continue
						ElseIf Not Admin
							MessageRequester(Lng(37), Lng(39))
							Continue
						ElseIf Not TrgS
							MessageRequester(Lng(37), Lng(40))
							Continue
						EndIf
						; 					MessageRequester(Lng(37), info$)
						If #ERROR_SUCCESS = RegOpenKeyEx_(#HKEY_LOCAL_MACHINE, "SYSTEM\CurrentControlSet\Control\Session Manager", 0, #KEY_WRITE, @hKey)
							valie.s = "autocheck autochk /p /K:" + info$ + " *"
							;  res$="autocheck autochk /p \??\C:"
							RegSetValueEx_(hKey, @"BootExecute", 0, #REG_EXPAND_SZ, @valie, StringByteLength(valie, #PB_Unicode))
							RegCloseKey_(hKey)
							MessageRequester(Lng(37), Lng(41) + #CRLF$ + #CRLF$ + valie.s)
						Else
							MessageRequester(Lng(37), Lng(42))
						EndIf
					Case #mHelpGUI
						res$ = GetPathPart(ProgramFilename()) + "ChkDskGui.chm"
						If FileSize(res$) > 11
							RunProgram("hh.exe", res$ + "::/html/control.htm", GetPathPart(ProgramFilename()))
							; SetMenuItemText(#Menu0, 7, Lng(35))
						Else
							; DisableMenuItem(#Menu0, 7, 1)
							If MessageRequester(Lng(36), Lng(53), #PB_MessageRequester_YesNo) = #PB_MessageRequester_Yes
								RunProgram("https://yadi.sk/d/XFgMC4xByJKRiA")
							EndIf
							
							; SetMenuItemText(#Menu0, 7, "Скачать справку")
						EndIf
					Case #mBatFile
						res$ = GetCommand(3)
						If Not Bool(res$)
							Continue
						EndIf
						res$ + "set /p Ok=^>^>"
						res$ = ReplaceString(res$, "&", #CRLF$)
						; 						ReplaceString(res$, "Гб", "ѓЎ")
						res$ = ToOem(res$)
						; 						CharToOem_(String$, String$)
						; 						OemToChar_(String$, String$)
						SetClipboardText(res$)
					Case #mCreateINI
						If FileSize(ini$) <> -1
							If #PB_MessageRequester_No = MessageRequester(Lng(37), Lng(43), #MB_YESNO | #MB_ICONQUESTION | #MB_DEFBUTTON2)
								Continue
							EndIf
						EndIf
						SaveFile_Buff(ini$, ?ini, ?iniend - ?ini)
					Case #mDiscMenu
						RegToMenuDisk()
					Case #mOpen
						i = GetGadgetState(#LIG)
						If i <> -1
							DiskCur$ = GetGadgetItemText(#LIG, i)
							RunProgram("explorer.exe", DiskCur$ + "\", "")
						EndIf
					Case #mAbout
						If MessageRequester(Lng(48), Lng(49) + " AZJIO" + #CRLF$ + Lng(50) + " 4.3  (07.11.2024)" + #CRLF$ + #CRLF$ + Lng(51), #MB_OKCANCEL) = #IDOK
							RunProgram("https://usbtor.ru/viewtopic.php?t=1478")
						EndIf
; 						MessageRequester("Размеры окна", Str(WindowHeight(#Window, #PB_Window_FrameCoordinate)) + " " + Str(WindowWidth(#Window, #PB_Window_FrameCoordinate)))
				EndSelect
			Case #PB_Event_CloseWindow
				SaveINI()
				CompilerIf #PB_Compiler_Processor = #PB_Processor_x86 ; если ChkDskGui-x86
					If RedirectRequired
						CallFunctionFast(*Func, 1) ; включили перенаправление
						CloseLibrary(hKrnDLL) 
					EndIf
				CompilerEndIf
				End
		EndSelect
	ForEver
;-└──Loop──┘
EndIf

End

Procedure RegExistsKey()
	Protected hKey
	If #ERROR_SUCCESS = RegOpenKeyEx_(#HKEY_CLASSES_ROOT, "Drive\shell\ChkDskGui\command", 0, #KEY_READ, @hKey)
		RegCloseKey_(hKey)
		ProcedureReturn 1
	Else
		ProcedureReturn 0
	EndIf
EndProcedure

Procedure RegJump(valie.s)
	Protected hKey
	If #ERROR_SUCCESS = RegOpenKeyEx_(#HKEY_CURRENT_USER, "Software\Microsoft\Windows\CurrentVersion\Applets\Regedit", 0, #KEY_WRITE, @hKey)
		RegSetValueEx_(hKey, @"LastKey", 0, #REG_SZ, @valie, StringByteLength(valie, #PB_Unicode))
		RegCloseKey_(hKey)
		hKey = FindWindowEx_(0, 0, "RegEdit_RegEdit", 0)
		If hKey
			KillProcess_hWin(hKey)
		EndIf
		RunProgram("regedit.exe")
	EndIf
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

Procedure Insert_Command(d)
	Protected res$, hwnd, k
	res$ = GetCommand(d)
	If Not Bool(res$)
		ProcedureReturn
	EndIf
	SetClipboardText(cmd$ + " /c (" + res$ + " set /p Ok=^>^>)")
	hwnd = FindWindow_("Shell_TrayWnd", "")
	If hwnd
		SendMessage_(hwnd, #WM_COMMAND, $191, 0)
	Else
		RunProgram("RUNDLL32", "SHELL32.DLL,#61", "")
	EndIf
	; Вот так мы ищем окно с шагом 60 мсек 30 раз
	k = 0
	Repeat
		hwnd = FindWindowEx_(0, 0, "#32770", Lng(44)) ; Запуск программы
		Delay(60)
		k + 1
		If k > 30
			Break
		EndIf
	Until hwnd
	If hwnd
		; 	SendMessage_(GetDlgItem_(hwnd, 12298),#WM_SETTEXT,0, res$)
		hwnd = FindWindowEx_(hwnd, 0, "ComboBox", 0)
		SendMessage_(hwnd, #WM_SETTEXT, 0, cmd$ + " /c (" + res$ + " set /p Ok=^>^>)")
		; 	SendMessage_(hwnd, #WM_SETTEXT,0, Str(GetDlgCtrlID_(hwnd))) ; получить идентификатор
	EndIf
	; SendMessage_(0, #WM_KEYDOWN, #VK_LWIN, 0)
	; SendMessage_(0, #WM_KEYDOWN, $52, 0)
	; SendMessage_(0, #WM_KEYUP, $52, 0)
	; SendMessage_(0, #WM_KEYUP, #VK_LWIN, 0)
EndProcedure

Procedure RegToMenuDisk()
	Protected hKey, KeyInfo, valie.s
	If RegExistsKey() ; если существует, то удаляем
		If #ERROR_SUCCESS = RegDeleteKey_(#HKEY_CLASSES_ROOT, "Drive\shell\ChkDskGui\command")
			If #ERROR_SUCCESS = RegDeleteKey_(#HKEY_CLASSES_ROOT, "Drive\shell\ChkDskGui")
				; 				MessageRequester(Lng(37),"Запись удалена",0)
				SetMenuItemText(#Menu0, #mDiscMenu, Lng(31))
			EndIf
		EndIf
	Else ; иначе добавляем
		If #ERROR_SUCCESS = RegCreateKeyEx_(#HKEY_CLASSES_ROOT, "Drive\shell\ChkDskGui", 0, 0, #REG_OPTION_NON_VOLATILE, #KEY_ALL_ACCESS, 0, @hKey, @KeyInfo)
			valie = "ChkDskGui"
			RegSetValueEx_(hKey, @"", 0, #REG_SZ, @valie, StringByteLength(valie, #PB_Unicode))
			valie = Chr(34) + ProgramFilename() + Chr(34)
			RegSetValueEx_(hKey, @"Icon", 0, #REG_SZ, @valie, StringByteLength(valie, #PB_Unicode))
			RegCloseKey_(hKey)
		EndIf

		If #ERROR_SUCCESS = RegCreateKeyEx_(#HKEY_CLASSES_ROOT, "Drive\shell\ChkDskGui\command", 0, 0, #REG_OPTION_NON_VOLATILE, #KEY_ALL_ACCESS, 0, @hKey, @KeyInfo)
			valie = Chr(34) + ProgramFilename() + Chr(34) + " " + Chr(34) + "%1" + Chr(34)
			RegSetValueEx_(hKey, @"", 0, #REG_SZ, @valie, StringByteLength(valie, #PB_Unicode))
			RegCloseKey_(hKey)
			SetMenuItemText(#Menu0, #mDiscMenu, Lng(30))
		EndIf
	EndIf
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

Procedure.s GetCommand(fill = 0)
	Protected res$ = "", TrgS = 0, k, info$, disk$
	For k = 0 To CountGadgetItems(#LIG) - 1
		info$ = ""
		If GetGadgetItemState(#LIG, k) & #PB_ListIcon_Checked
			disk$ = GetGadgetItemText(#LIG, k)
			info$ = disk$ + "  " + GetGadgetItemText(#LIG, k, 1) + "  " + GetGadgetItemText(#LIG, k, 2) + "  " + GetGadgetItemText(#LIG, k, 3) + "  " + GetGadgetItemText(#LIG, k, 4) + "  " + GetGadgetItemText(#LIG, k, 5)

			Select fill
				Case 0
					res$ + "Title Check Disk " + info$ + " & @Echo off & @Echo. & @Echo. & @Echo ====================================================== & @Echo Test " + info$ + " & @Echo ====================================================== & @Echo. & @Echo. & Color " + Color$ + " & chkdsk.exe " + disk$ + GetComString() + "&"
				Case 1
					res$ + "Title " + info$ + " & @Echo off & @Echo." + info$ + " & @Echo. & Color " + Color$ + " & chkdsk.exe " + disk$ + GetComString() + "&"
				Case 2
					res$ + "@Echo off & @Echo." + info$ + " & @Echo. & Color " + Color$ + " & chkdsk.exe " + disk$ + GetComString() + "&"
				Case 3
					res$ + "Title Check Disk " + info$ + " & @Echo off & @Echo. & @Echo. & @Echo ====================================================== & @Echo Test " + info$ + " & @Echo ====================================================== & @Echo. & @Echo. & Color " + Color$ + " & chkdsk.exe " + disk$ + GetComString() + "&"

					; 				Default
					; 					MessageRequester(Lng(37), Text$)
			EndSelect

			TrgS + 1
		EndIf
	Next
	If Not TrgS
		MessageRequester(Lng(37), Lng(40))
		res$ = ""
	EndIf
	ProcedureReturn res$
EndProcedure

Procedure Add_item_LV(Drive2$)
	Drive2$ = ComboListDrive(Drive2$)
	If Drive2$ <> "-"
; 		If Mid(Drive2$, 10, 3) = "Fix"
; 			AddGadgetItem(#LIG, -1, Drive2$, ImageID(#img0))
; 		Else
; 			AddGadgetItem(#LIG, -1, Drive2$, ImageID(#img1))
; 		EndIf
; 		If StringField(Drive2$, 3, Chr(10)) = Lng(54)
; 			AddGadgetItem(#LIG, -1, Drive2$, ImageID(#img0))
; 		Else
; 			AddGadgetItem(#LIG, -1, Drive2$, ImageID(#img1))
; 		EndIf
		Select StringField(Drive2$, 3, Chr(10))
			Case Lng(54)
				AddGadgetItem(#LIG, -1, Drive2$, ImageID(#img0))
			Case Lng(55)
				AddGadgetItem(#LIG, -1, Drive2$, ImageID(#img1))
			Default
				AddGadgetItem(#LIG, -1, Drive2$, ImageID(#img2))
		EndSelect

		; перерисовка заполненности диска
		Protected i = SendMessage_(hListView, #LVM_GETITEMCOUNT, 0, 0) - 1
		If GetDiskFreeSpaceEx_(Left(Drive2$, 2), @lpFreeBytesAvailable, @lpTotalNumberOfBytes, 0)
			If lpTotalNumberOfBytes > 0 ; чтобы не было сбоя при неопределении диска, на 0 делить нельзя
; 				UpdateProgress(#LIG, i, 8, (lpTotalNumberOfBytes-lpFreeBytesAvailable) *100 / lpTotalNumberOfBytes)
				UpdateProgress(#LIG, i, 8, Round((lpTotalNumberOfBytes - lpFreeBytesAvailable) * 100 / lpTotalNumberOfBytes , #PB_Round_Nearest))
			Else
				UpdateProgress(#LIG, i, 8, 1)
			EndIf
		Else
			UpdateProgress(#LIG, i, 8, 0)
		EndIf
		; конец => перерисовка заполненности диска
	EndIf
EndProcedure

Procedure Add_item_LV_Mask(Mask.l)
	Protected i, letter.s, title.s
	For i = StartDisk To 25
		If ((Mask >> i) & 1) ; проверить каждый флаг
			letter = Chr(i + 65)
			title + letter + ": "
			Add_item_LV(letter) ; получить букву и отправить на добавление
		EndIf
	Next
	DuplicateDriveTest()
	align_col_LV()
	align_Windows()
	SetWindowTitle(#Window, Lng(45) + title + ")")

	; 	сортировка
	UpdatelParam()
	SortOrder = -SortOrder
	ForceSort()
EndProcedure

Procedure DuplicateDriveTest()
	Protected k, letter.s
	Protected NewMap Disk.i()
	For k = 0 To CountGadgetItems(#LIG) - 1
		letter = GetGadgetItemText(#LIG, k, 0)
		If FindMapElement(Disk(), letter)
			RemoveGadgetItem(#LIG, k)
		Else
			AddMapElement(Disk(), letter)
		EndIf
	Next
EndProcedure

; Procedure DuplicateDriveTest()
; 	Protected k, letter.s, LastLetter.s
; 	For k = 0 To CountGadgetItems(#LIG)-1
; 		letter = GetGadgetItemText(#LIG, k, 0)
; 		If letter = LastLetter
; 			RemoveGadgetItem(#LIG, k)
; 		Else
; 			LastLetter = letter
; 		EndIf
; 	Next
; EndProcedure

Procedure Del_item_LV(Mask.l)
	Protected k, Count, letter.s, title.s;, z
	Count = CountGadgetItems(#LIG)
	For k = Count - 1 To 0 Step -1
		; 		If GetGadgetItemText(#LIG, k) = Drive2$+":" Or (drives_avail >> Asc(Left(GetGadgetItemText(#LIG, k), 1)) - 65) & 0
		; 		Debug Str(Asc(Left(GetGadgetItemText(#LIG, k), 1)) - 65)
		letter = Left(GetGadgetItemText(#LIG, k), 1)
		If (Mask >> (Asc(letter) - 65)) & 1
			RemoveGadgetItem(#LIG, k)
			title + letter + ": "
			; 			z + 1
		EndIf
	Next
	SetWindowTitle(#Window, Lng(46) + title + ")")
	; 	CountDisk - z ; потому что не используем по коду
	align_col_LV()
	align_Windows()
EndProcedure


Procedure align_col_LV()
	Protected k
	ListViewSpalte\fmt = #LVCFMT_RIGHT ; Указываем в поле fmt структуры константу для выравнивания
	SendMessage_(hListView, #LVM_SETCOLUMN, 5, @ListViewSpalte) ; Выслать сообщение, где 5 - индекс колонки
	; 	Выровнять ширину колонок, чтобы уместился текст
	For k = 0 To 7
		If k = 3 ; кроме колонки "Метка диска"
			Continue
		EndIf
		SetGadgetItemAttribute(#LIG, 2, #PB_ListIcon_ColumnWidth , #LVSCW_AUTOSIZE, k)
	Next
; 	If Not Admin ; для колонки "MBR/GPT" без админа ширина 0
; 		SetGadgetItemAttribute(#LIG, 2, #PB_ListIcon_ColumnWidth , 0, 7)
; 	EndIf
; 	SetGadgetItemAttribute(#LIG, 2, #PB_ListIcon_ColumnWidth , #LVSCW_AUTOSIZE_USEHEADER, 7)
EndProcedure

Procedure align_Windows()
	Protected i, Height, ColumnWidth = 0
	Height = 24 + 18 * SendMessage_(hListView, #LVM_GETITEMCOUNT, 0, 0) - 1 + 100
; 	If Not fINI Or AlignWin ; если нет ini или выравнивание=1, то
; 	If Not fINI And AlignWin ; если нет ini и выравнивание=1, то
	If AlignWin
		For i = 0 To 8
			ColumnWidth + SendMessage_(hListView, #LVM_GETCOLUMNWIDTH, i, 0)
		Next
		ColumnWidth + 10
		ResizeGadget(#LIG, #PB_Ignore, #PB_Ignore, ColumnWidth, #PB_Ignore)
		ColumnWidth + 10
; 		ResizeWindow(#Window, #PB_Ignore, #PB_Ignore, ColumnWidth, Height)
		ResizeWindow(#Window, (DesktopWidth(#Desktop) - ColumnWidth) / 2, (DesktopHeight(#Desktop) - Height) / 2, ColumnWidth, Height)
		PostMessage_(hGUI, #WM_SIZE, 0, 0)
	EndIf
EndProcedure

; MessageRequester("Размеры окна", Str(WindowHeight(#Window, #PB_Window_FrameCoordinate)) + " " + Str(WindowWidth(#Window, #PB_Window_FrameCoordinate)))

Procedure HideCheckBox(gadget, item)
	Protected lvi.LVITEM
	lvi\iItem = item
	lvi\mask = #LVIF_STATE
	lvi\stateMask = #LVIS_STATEIMAGEMASK
	SendMessage_(GadgetID(#LIG), #LVM_SETITEM, 0, @lvi)
EndProcedure

Procedure MyWindowCallback(WindowId, Message, wParam, lParam)
;-┌──MyWindowCallback──┐
	Protected Result = #PB_ProcessPureBasicEvents, Mask, Drive.s, h, w, *pDBHDR.DEV_BROADCAST_HDR, *pDBV.DEV_BROADCAST_VOLUME
	Protected *ptr.MINMAXINFO
	Protected tmp
	Protected *msg.NMHDR, *pnmv.NM_LISTVIEW ; для сортировки
	Protected row, col
	Protected *LVCDHeader.NMLVCUSTOMDRAW ; прогресс заполнения дисков
	Select Message
;- ├ WM_NOTIFY
		Case #WM_NOTIFY ; для сортировки
			*msg.NMHDR = lParam
			Select *msg\code
				Case #LVN_COLUMNCLICK
					If *msg\hwndFrom = hListView
						*pnmv.NM_LISTVIEW = lParam
						If indexSort <> *pnmv\iSubItem
							SortOrder = 1
						EndIf
						indexSort = *pnmv\iSubItem
						ForceSort()
					EndIf
; 				При изменении пункта с типом файловой системы EXT3/EXT4, пункт теряет галку и скрывается
				Case #LVN_ITEMCHANGED
					If *msg\hwndFrom = hListView
						*pnmv.NM_LISTVIEW = lParam
						If Left(GetGadgetItemText(#LIG, *pnmv\iItem, 4) , 3) = "EXT"
; 							Нет необходимости диактивировать пункт, так как после скрытия он не обслуживается
; 							If GetGadgetItemState(#LIG, *pnmv\iItem) & #PB_ListIcon_Checked
; 								SetGadgetItemState(#LIG, *pnmv\iItem , 0)
; 							EndIf
							HideCheckBox(#LIG, *pnmv\iItem)
						EndIf
					EndIf


; перерисовка заполненности диска
;- ├ NM_CUSTOMDRAW
				Case #NM_CUSTOMDRAW
					*LVCDHeader.NMLVCUSTOMDRAW = lParam
					row = *LVCDHeader\nmcd\dwItemSpec
					col = *LVCDHeader\iSubItem
					If col = 8
						Select *LVCDHeader\nmcd\dwDrawStage
							Case #CDDS_PREPAINT
								Result = #CDRF_NOTIFYITEMDRAW
							Case #CDDS_ITEMPREPAINT
								Result = #CDRF_NOTIFYSUBITEMDRAW
							Case #CDDS_SUBITEMPREPAINT
								DrawProgressBar(lParam)
								Result = #CDRF_SKIPDEFAULT
						EndSelect
					EndIf
			EndSelect
; конец => перерисовка заполненности диска


;- ├ WM_DEVICECHANGE
		Case #WM_DEVICECHANGE ; Изменение при подключении внешних дисков.
			Result = #True
			Select wParam
				Case #DBT_DEVICEARRIVAL, #DBT_DEVICEREMOVECOMPLETE
					*pDBHDR.DEV_BROADCAST_HDR = lParam
					If *pDBHDR\dbch_devicetype = #DBT_DEVTYP_VOLUME
						*pDBV.DEV_BROADCAST_VOLUME = lParam
						Mask = *pDBV\dbcv_unitmask

						Select wParam
							Case #DBT_DEVICEARRIVAL
								; Debug Bin(drives_avail)
								; Debug Bin(Mask)
								tmp = drives_avail
								drives_avail | Mask
								If tmp <> drives_avail
									Add_item_LV_Mask(Mask)
								EndIf
							Case #DBT_DEVICEREMOVECOMPLETE
								drives_avail ! (Mask & drives_avail)
								Del_item_LV(Mask)
						EndSelect
					EndIf
			EndSelect
		Case #WM_GETMINMAXINFO ; Минимальный, максимальный размера окна. Смотреть WindowBounds
			Result = 0
			*ptr.MINMAXINFO = lParam
			*ptr\ptMinTrackSize\y = 160 + BorderY ;42
			*ptr\ptMinTrackSize\x = 480 + BorderX ;16
		Case #WM_EXITSIZEMOVE       ; Изменение размера окна и перемещение после события.
			If Not cs\m         ; если окно не на весь экран, то кешируем массив
				cs\x = WindowX(#Window, #PB_Window_FrameCoordinate)
				cs\y = WindowY(#Window, #PB_Window_FrameCoordinate)
				cs\w = WindowWidth(#Window)     ; Новая ширина окна.
				cs\h = WindowHeight(#Window)     ; Новая высота окна.
			EndIf
;- ├ WM_SIZE
		Case #WM_SIZE         ; Изменение размера окна.
			w = WindowWidth(#Window)      ; Новая ширина окна.
			h = WindowHeight(#Window)      ; Новая высота окна.
			ResizeGadget(#LIG, #PB_Ignore, #PB_Ignore, w - 10, h - 90)
			ResizeGadget(#chF, #PB_Ignore, h - 80, w - 190, #PB_Ignore)
			ResizeGadget(#chR, #PB_Ignore, h - 60, w - 190, #PB_Ignore)
			ResizeGadget(#chX, #PB_Ignore, h - 40, w - 190, #PB_Ignore)
			ResizeGadget(#StatusBar, #PB_Ignore, h - 17, w - 200, #PB_Ignore)
			; 			ResizeGadget(5, w - 150, h - 52, 37, 42)
			ResizeGadget(#btnMenu, w - 137, h - 52, 24, #PB_Ignore)
			ResizeGadget(#btnStart, w - 110, h - 52, 100, #PB_Ignore)
			; 			ResizeGadget(7, w - 179, h - 52, 26, 42)
			ResizeGadget(#chAll, w - 179, h - 80, 170, #PB_Ignore)
; 			SetGadgetItemAttribute(#LIG, 0, #PB_ListIcon_ColumnWidth, w - 530, 3)
	EndSelect
	ProcedureReturn Result
;-└──MyWindowCallback──┘
EndProcedure

Procedure InstanceToWnd(iPid)
	Protected hWnd = FindWindow_(0, 0)
	Protected iPid1, ThreadID
	While hWnd <> 0
		If GetParent_(hWnd) = 0
			ThreadID = GetWindowThreadProcessId_(hWnd, @iPid1)
			If iPid1 = iPid
				Break
			EndIf
		EndIf
		hWnd = GetWindow_(hWnd, #GW_HWNDNEXT)
	Wend
	ProcedureReturn hWnd
EndProcedure

; Получить буквы дисков
Procedure GetDrives(List Drive.s())
	Protected i, Drive2$
	drives_avail = GetLogicalDrives_()

	; 	игнорирование дисков
	Protected Dim Arr.s{1}(0)
	Protected LenStr, Mask = 0
	If ignore$
		; 		ignore$ = UCase(ignore$)
		LenStr = Len(ignore$)
		ReDim Arr(LenStr - 1)
		PokeS(Arr(), UCase(ignore$), -1, #PB_String_NoZero)
		For i = 0 To LenStr - 1
			Mask + (1 << (Asc(Arr(i)) - 65))
		Next
	EndIf
	; 	Mask & drives_avail ; убираем из маски лишние флаги (1 в 0), т.е. в маске остаются только существующие диски
	; 	drives_avail ! Mask	; одинаковые флаги (1 и 1) в масках сбрасываются в 0
	drives_avail ! (Mask & drives_avail) ; игнор одним выражением
										 ; 	игнорирование дисков => конец

	For i = StartDisk To 25
		If ((drives_avail >> i) & 1)
			Drive2$ = ComboListDrive(Chr(i + 65))
			If Drive2$ <> "-"
				AddElement(Drive())
				Drive() = Drive2$
			EndIf
		EndIf
	Next
EndProcedure

Procedure TestVirtual(Drive2$)
	Protected lpDeviceName.s, lpTargetPath.s
	lpDeviceName = Mid(Drive2$, 1, 2)
	lpTargetPath = Space(#MAX_PATH)
	QueryDosDevice_(@lpDeviceName, @lpTargetPath, #MAX_PATH)
	If Left(lpTargetPath, 7) <> "\Device" Or (Left(lpTargetPath, 15) = "\Device\Ramdisk" And lpDeviceName = "X:")
		ProcedureReturn 1
	Else
		ProcedureReturn 0
	EndIf
EndProcedure

Procedure.s ComboListDrive(Drive2$)
	Protected.l type, i
	Protected.s Lfwrk, FileSystem, VolName, r = Chr(10)
	Protected.q total_bytes
	Lfwrk = Drive2$ + ":\"
	type = GetDriveType_(Lfwrk)
	FileSystem = Space(256)
	VolName = Space(256)
	Select type
		Case #DRIVE_REMOVABLE
			Drive2$ + ":" + r + "[" + DriveGetNumber(Drive2$ + ":") + "]" + r + Lng(55)
		Case #DRIVE_FIXED
			Drive2$ + ":" + r + "[" + DriveGetNumber(Drive2$ + ":") + "]" + r + Lng(54)
		Case #DRIVE_REMOTE, #DRIVE_CDROM, #DRIVE_RAMDISK
			ProcedureReturn "-"
		Case #DRIVE_NO_ROOT_DIR
			ProcedureReturn Drive2$ + ":" + r + "[" + DriveGetNumber(Drive2$ + ":") + "]" + r + "No_Root_Dir"
		Case #DRIVE_UNKNOWN
			ProcedureReturn Drive2$ + ":" + r + "[" + DriveGetNumber(Drive2$ + ":") + "]" + r + "Unknown"
		Default
			ProcedureReturn Drive2$ + ":" + r + "[" + DriveGetNumber(Drive2$ + ":") + "]" + r + "---"
	EndSelect

	If Mid(Drive2$, 5, 3) = "?:?" And TestVirtual(Drive2$)
		ProcedureReturn "-"
	EndIf

	If GetVolumeInformation_(@Lfwrk, @VolName, 255, 0, 0, 0, @FileSystem, 255)
		Drive2$ + r + VolName + r + FileSystem
		; 		Drive2$ = DriveGetNumber(Left(Drive2$,1) + ":") + "  " + Drive2$
		If (GetDiskFreeSpaceEx_(Lfwrk, 0, @total_bytes, 0))
			; TO DO FormatNumber() Done
			; Drive2$ + "  "+  Str(total_bytes/1048576)+ " Мб"
; 			Drive2$ + r + StrF(ValF(StrF(total_bytes / 1024)) / 1048576, 3)
			Drive2$ + r + FormatNumber(total_bytes / 1073741824, 3, ".", "")
		Else
			Drive2$ + r + "---"
		EndIf
	Else
		Drive2$ + r + "---" + r + "---"
		If OSVersion() < #PB_OS_Windows_Vista
			total_bytes = GetDriveSize(Left(Drive2$, 2))
			If total_bytes
				Drive2$ + r + FormatNumber(total_bytes / 1073741824, 3, ".", "")
			Else
				Drive2$ + r + "---"
			EndIf
		Else
			Drive2$ + r + "---"
		EndIf
	EndIf
	Drive2$ + r + DriveGetName(Left(Drive2$, 2))
	Drive2$ + r + Get_MBR_GPT(StringField(Drive2$, 2, Chr(10)))
; 	Debug Drive2$

	ProcedureReturn Drive2$
EndProcedure

;Получение номера диска и раздела, из буквы раздела
Procedure.s Get_MBR_GPT(DriveNum$)
	Protected tmp, res$
	tmp = FindString(DriveNum$, ":", 2, #PB_String_CaseSensitive)
	res$ = Mid(DriveNum$, 2, tmp - 2)
	If res$ = "?"
		ProcedureReturn "---"
	EndIf
	tmp = Val(res$)
	If MBR_GPT(tmp) <> ""
		ProcedureReturn MBR_GPT(tmp)
	EndIf

	res$ = "---"
	Protected pdl.DRIVE_LAYOUT_INFORMATION_EX, Bytes.l, hDrive
	hDrive = CreateFile_("\\.\PhysicalDrive" + tmp, 0, #FILE_SHARE_READ | #FILE_SHARE_WRITE, 0, #OPEN_EXISTING, 0, 0)
; 	hDrive = CreateFile_("\\.\PhysicalDrive" + tmp, #GENERIC_READ, #FILE_SHARE_READ | #FILE_SHARE_WRITE, 0, #OPEN_EXISTING, 0, 0)
	If hDrive <> #INVALID_HANDLE_VALUE
		If DeviceIoControl_(hDrive, #IOCTL_DISK_GET_DRIVE_LAYOUT_EX, 0, 0, @pdl, SizeOf(pdl), @Bytes, 0)
			Select pdl\PartitionStyle
				Case #PARTITION_STYLE_MBR
					res$ = "MBR"
				Case #PARTITION_STYLE_GPT
					res$ = "GPT"
				Case #PARTITION_STYLE_RAW
					res$ = "RAW"
			EndSelect
		EndIf
		CloseHandle_(hDrive)
	EndIf
	MBR_GPT(tmp) = res$
	ProcedureReturn res$
EndProcedure

;Получение номера диска и раздела, из буквы раздела
Procedure.s DriveGetNumber(DriveLetter$)
	Protected DriveInfo.STORAGE_DEVICE_NUMBER, Nul , Ret$ = "?:?", hDevice
	hDevice = CreateFile_("\\.\" + DriveLetter$, 0, 0, 0, #OPEN_EXISTING, #FILE_ATTRIBUTE_NORMAL, #NUL)
	If hDevice <> #INVALID_HANDLE_VALUE
		If DeviceIoControl_(hDevice, #IOCTL_STORAGE_GET_DEVICE_NUMBER, 0, 0, DriveInfo, SizeOf(STORAGE_DEVICE_NUMBER), @Nul, #NUL)
			Ret$ = Str(DriveInfo\DeviceNumber) + ":" + Str(DriveInfo\PartitionNumber)
			If DriveInfo\DeviceNumber > MaxDeviceNumber
				MaxDeviceNumber = DriveInfo\DeviceNumber
				ReDim MBR_GPT(MaxDeviceNumber)
			EndIf
		EndIf
		CloseHandle_(hDevice)
	EndIf
	ProcedureReturn Ret$
EndProcedure

;Получение названия диска
Procedure.s DriveGetName(DriveLetter$)

	#IOCTL_STORAGE_QUERY_PROPERTY = $2D1400

	Protected dwOutBytes, hDevice, p, Ret$
	Protected udtQuery.STORAGE_PROPERTY_QUERY
	Protected udtOut.STORAGE_DEVICE_DESCRIPTOR

	hDevice = CreateFile_("\\.\" + DriveLetter$, 0, #FILE_SHARE_READ | #FILE_SHARE_WRITE, 0, #OPEN_EXISTING, #NUL, #NUL)
; 	hDevice = CreateFile_("\\.\" + DriveLetter$, #GENERIC_READ, #FILE_SHARE_READ | #FILE_SHARE_WRITE, 0, #OPEN_EXISTING, #NUL, #NUL)
	If hDevice <> #INVALID_HANDLE_VALUE
		For p = 0 To 1023
			udtOut\Reserved[p] = 0
		Next p

		If DeviceIoControl_(hDevice, #IOCTL_STORAGE_QUERY_PROPERTY, udtQuery, SizeOf(udtQuery), @udtOut, SizeOf(udtout), @dwOutBytes, 0)
			; Debug "udtOut\RemovableMedia = " + Str(udtOut\RemovableMedia) ; 1 = диск может быть извлечён
			; Debug "udtOut\Bustype = " + Str(udtOut\Bustype) ; тип шины, к которой подключено устройство, т.е. флешка = #BusTypeUsb, обычный hdd = #BusTypeSata
			; 			If udtOut\SerialNumberOffset
			; 				Debug "SerialNumber = " + LTrim(PeekS(udtOut + udtOut\SerialNumberOffset, -1, #PB_Ascii))
			; 			EndIf
			If udtOut\VendorIdOffset
				Ret$ + Trim(PeekS(udtOut + udtOut\VendorIdOffset, -1, #PB_Ascii)) + " "
			EndIf
			If udtOut\ProductIdOffset
				Ret$ + Trim(PeekS(udtOut + udtOut\ProductIdOffset, -1, #PB_Ascii))
			EndIf
			; 			If udtOut\ProductRevisionOffset
			; 				Debug "ProductRevision = " + PeekS(udtOut + udtOut\ProductRevisionOffset, -1, #PB_Ascii)
			; 			EndIf
		EndIf
		CloseHandle_(hDevice)
	EndIf
	ProcedureReturn Ret$
EndProcedure

Procedure.s GetComString()
	Protected.s ComStr = ""
	If GetGadgetState(1)
		ComStr + " /F"
	EndIf
	If GetGadgetState(2)
		ComStr + " /R"
	EndIf
	If GetGadgetState(3)
		ComStr + " /X"
	EndIf
	ProcedureReturn ComStr
EndProcedure

; X:\Windows\System32\
Procedure HelpChkdsk()
	Protected Prog = RunProgram("chkdsk.exe", "/?", "", #PB_Program_Open | #PB_Program_Read | #PB_Program_Hide)
	Protected Output$ = ""
	If Prog
		While ProgramRunning(Prog)
			Output$ + ReadProgramStringOem(Prog)
		Wend
		CloseProgram(Prog)
	EndIf
	Output$ = ReplaceString(Output$, #CRLF$ + #CRLF$ + #CRLF$, #CRLF$ + #CRLF$) ; чтобы на экран умещалось
	Output$ = ReplaceString(Output$, #CRLF$ + "                      ", " ")   ; чтобы на экран умещалось

	If Len(Output$) > 20
		MessageRequester(Lng(47), Output$)
	Else
		RunProgram(cmd$, "/c (Title Check Disk Help & @Echo off & Color " + Color$ + " & chkdsk.exe /? & set /p Ok=^>^>)", "")
	EndIf
EndProcedure


Procedure.s ReadProgramStringOem(iPid)
	Protected Ret$ = "", *Buff, SizeBuff = AvailableProgramOutput(iPid)
	If SizeBuff > 0
		*Buff = AllocateMemory(SizeBuff)
		ReadProgramData(iPid, *Buff, SizeBuff)
		OemToCharBuffA(*Buff, *Buff, SizeBuff) ; 866 в Windows1251
		Ret$ = PeekS(*Buff, SizeBuff, #PB_Ascii)
		FreeMemory(*Buff)
	EndIf
	ProcedureReturn Ret$
EndProcedure

; Windows1251 в 866
Procedure.s ToOem(String$)
	Protected Ret$ = "", *Buff, SizeBuff = Len(String$)
	If SizeBuff > 0
		*Buff = AllocateMemory(SizeBuff + 1)
		PokeS(*Buff, String$, SizeBuff, #PB_Ascii)
		CharToOemBuffA(*Buff, *Buff, SizeBuff)
		Ret$ = PeekS(*Buff, SizeBuff, #PB_Ascii)
		FreeMemory(*Buff)
	EndIf
	ProcedureReturn Ret$
EndProcedure

; Для подсказок часть 3 из 3-х
Procedure AddGadgetToolTip(GadgetID.l, ToolText$, MaxWidth.l = 0, Balloon.l = 1, WindowID.l = -1)
	Protected cWndFlags.l = #TTS_NOPREFIX | #TTS_BALLOON
	Protected hToolTip, tti.TOOLINFO

	If WindowID = -1 And IsGadget(GadgetID) ; Позволяет вводить либо PB-#Gadget, либо Gadget-ID
		GadgetID = GadgetID(GadgetID)

		If hToolTips(Str(GadgetID)) <> 0 : DestroyWindow_(hToolTips(Str(GadgetID))) : EndIf

	ElseIf WindowID > -1 And IsWindow(WindowID)
		WindowID = WindowID(WindowID)
	EndIf

	;> Удаляет флаг #TTS_BALLOON если вы хотите прямоугольную всплывающую подсказку, в соответствии с переменной Balloon.
	If Balloon = 0 : cWndFlags = #TTS_NOPREFIX : EndIf

	hToolTip = CreateWindowEx_(0, "ToolTips_Class32", "", cWndFlags, 0, 0, 0, 0, 0, 0, GetModuleHandle_(0), 0)

	hToolTips(Str(GadgetID)) = hToolTip
	; 	Назначаем цвета в соответствии со стандартным цветом в ОС
	SendMessage_(hToolTip, #TTM_SETTIPTEXTCOLOR, GetSysColor_(#COLOR_INFOTEXT), 0)
	SendMessage_(hToolTip, #TTM_SETTIPBKCOLOR, GetSysColor_(#COLOR_INFOBK), 0)
	tti.TOOLINFO\cbSize = SizeOf(TOOLINFO)
	tti\uFlags = #TTF_SUBCLASS | #TTF_IDISHWND
	;> Вот где многострочный текст вступает в игру, установив maxWidth
	SendMessage_(hToolTip, #TTM_SETMAXTIPWIDTH, 0, MaxWidth)

	tti\hWnd = GadgetID
	tti\uId = GadgetID
	tti\hinst = 0
	tti\lpszText = @Tooltext$

	If WindowID <> -1
		tti\hWnd = WindowID
		tti\uFlags = #TTF_SUBCLASS
		GetClientRect_(WindowID, @tti\rect)
	EndIf

	SendMessage_(hToolTip, #TTM_ADDTOOL, 0, tti)

	SendMessage_(hToolTip, #TTM_SETDELAYTIME, #TTDT_AUTOPOP, 15000)
	SendMessage_(hToolTip, #TTM_UPDATE , 0, 0)
EndProcedure



Procedure SaveINI()
	If OpenPreferences(ini$) And PreferenceGroup("set")
		With cs
			WritePreferenceInteger("WinM" , \m)
			WritePreferenceInteger("WinX" , \x)
			WritePreferenceInteger("WinY" , \y)
			WritePreferenceInteger("WinW" , \w)
			WritePreferenceInteger("WinH" , \h)
		EndWith
		WritePreferenceInteger("SortOrder", -SortOrder)
		WritePreferenceInteger("indexSort", indexSort)
		ClosePreferences()
	EndIf
EndProcedure

; IDE Options = PureBasic 6.04 LTS (Windows - x64)
; CursorPosition = 273
; FirstLine = 269
; Folding = ------
; Optimizer
; EnableXP
; EnableAdmin
; DPIAware
; UseIcon = image\ChkDskGui.ico
; Executable = ChkDskGui.exe
; CompileSourceDirectory
; Compiler = PureBasic 6.04 LTS - C Backend (Windows - x64)
; DisableCompileCount = 4
; EnableBuildCount = 0
; EnableExeConstant
; IncludeVersionInfo
; VersionField0 = 4.3.0.%BUILDCOUNT
; VersionField2 = AZJIO
; VersionField3 = ChkDskGui
; VersionField4 = 4.3.0
; VersionField6 = ChkDskGui
; VersionField9 = AZJIO
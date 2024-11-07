
; AZJIO
; http://purebasic.info/phpBB3ex/viewtopic.php?p=91697#p91697

EnableExplicit

Structure coord_size
	m.l
	x.l
	y.l
	w.l
	h.l
EndStructure

Structure rect_6
	left.l
	top.l
	right.l
	bottom.l
	width.l
	height.l
EndStructure
Global cs.coord_size

; Вычисление координат и размеров окна на старте
Declare __Coor2(*Len1.long, *Len2.long, *Len3.long)
Declare __Coor1(*WorkRect1.rect_6, *iWidth.long, *iHeight.long, *BorderX.long, *BorderY.long, *iStyle.long, *Margin.long)
Declare _SetCoor(*cs1.coord_size, MinWidth = 0, MinHeight = 0, iStyle = 2, Fixed = 0, Margin = 0)


; _SetCoor Корректирует координаты для отображения окна в рабочей области экрана
;		iStyle - Стиль окна, который определяет ширину границ
;                  0 - Окно без границ, ширина границы 0 пиксел
;                  1 - Окно со стилем WS_BORDER, обычно ширина этой границы 1 пиксел
;                  2 - Окно не изменяемое в размерах, обычно ширина этой границы 3 пиксел
;                  3 - Окно изменяемое в размерах (WS_OVERLAPPEDWINDOW), обычно ширина этой границы 4 пиксел
;		Fixed - Исправляет координаты окна при помещении его справа или снизу при отсутствии стиля $WS_CAPTION или $WS_DLGFRAME
;		Margin - Отступ от краёв
Procedure _SetCoor(*cs1.coord_size, MinWidth = 0, MinHeight = 0, iStyle = 2, Fixed = 0, Margin = 0)
	Protected Xtmp, Ytmp, BorderX = 0, BorderY = 0, WorkRect.rect_6;, tr1, tr2
	If Fixed
		Fixed = GetSystemMetrics_(#SM_CYCAPTION) ; + #SM_CYCAPTION
		*cs1\h - Fixed
	EndIf
	If MinWidth And *cs1\w < MinWidth
		*cs1\w = MinWidth ; ограничение ширины
	EndIf
	If MinHeight And *cs1\h < MinHeight
		*cs1\h = MinHeight ; ограничение высоты
	EndIf
	; 	If *cs1\x = -12345
	; 		tr1 = 1
	; 	EndIf
	; 	If *cs1\y = -12345
	; 		tr2 = 1
	; 	EndIf

	__Coor1(@WorkRect, @cs\w, @cs\h, @BorderX, @BorderY, @iStyle, @Margin)
	__Coor2(@cs\x, @cs\w, @WorkRect\width)
	__Coor2(@cs\y, @cs\h, @WorkRect\height)

	*cs1\w = *cs1\w - BorderX - Margin
	*cs1\h = *cs1\h - BorderY - Margin + Fixed
	; 	ExamineDesktops()
	; 	If tr1 ; пустая строка передать ключ что строки пусты
	; 		*cs1\x = (DesktopWidth(0) - *cs1\w -  WorkRect\left - Margin)/2 + WorkRect\left + Margin / 2
	; 	Else
	*cs1\x = *cs1\x + WorkRect\left + Margin / 2
	; 	EndIf
	; 	If tr2 ; пустая строка передать ключ что строки пусты
	; 		*cs1\y = (DesktopHeight(0) - *cs1\h -  WorkRect\top - Margin)/2 + WorkRect\top + Margin / 2
	; 	Else
	*cs1\y = *cs1\y + WorkRect\top + Margin / 2
	; 	EndIf
EndProcedure   ;==>_SetCoor

; Вот так выглядит передача чисел типа integer ссылкой, где integer это встроенная структура, а \l её элемент
Procedure __Coor1(*WorkRect1.rect_6, *iWidth.long, *iHeight.long, *BorderX.long, *BorderY.long, *iStyle.long, *Margin.long)
	Protected iX = 7, iY = 8
	If *iStyle\l
		Select *iStyle\l
			Case 1
				iX = 5 ; SMCXBORDER
				iY = 6 ; SMCYBORDER
			Case 2
				iX = 7 ; SMCXDLGFRAME
				iY = 8 ; SMCYDLGFRAME
			Case 3
				iX = 32 ; SMCXFRAME
				iY = 33	; SMCYFRAME
		EndSelect
		*BorderX\l = GetSystemMetrics_(iX) * 2
		*BorderY\l = GetSystemMetrics_(iY) * 2 + GetSystemMetrics_(#SM_CYCAPTION)
	Else
		*BorderY\l = GetSystemMetrics_(#SM_CYCAPTION)
	EndIf
	*iWidth\l + *BorderX\l
	*iHeight\l + *BorderY\l

	SystemParametersInfo_(#SPI_GETWORKAREA, 0, *WorkRect1.rect_6, 0)
	With *WorkRect1
		\width = \right - \left ; ширина Рабочей области
		\height = \bottom - \top; высота Рабочей области
	EndWith
	*Margin\l * 2			 ; Вычисление наибольшего отступа

	If *Margin\l > (*WorkRect1\width - *iWidth\l)
		*Margin\l = *WorkRect1\width - *iWidth\l
	EndIf
	If *Margin\l > (*WorkRect1\height - *iHeight\l)
		*Margin\l = *WorkRect1\height - *iHeight\l
	EndIf
	If *Margin\l < 0
		*Margin\l = 0
	EndIf

	*iWidth\l + *Margin\l
	*iHeight\l + *Margin\l
EndProcedure   ;==>__Coor1

; Вот так выглядит передача чисел типа integer ссылкой, где integer это встроенная структура, а \l её элемент
Procedure __Coor2(*Len1.long, *Len2.long, *Len3.long)
	If *Len1\l < 0
		*Len1\l = 0
	EndIf
	If *Len2\l >= *Len3\l
		*Len2\l = *Len3\l
		*Len1\l = 0
	EndIf
	If *Len1\l > *Len3\l - *Len2\l
		*Len1\l = *Len3\l - *Len2\l
	EndIf
EndProcedure   ;==>__Coor2

; IDE Options = PureBasic 5.70 LTS (Windows - x64)
; CursorPosition = 3
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
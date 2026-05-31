

Global Main_References, hHeader

; Global bgWin = $3f3f3f
; Global background = $222222
; Global foreground = $aaaaaa
Global background = $EEFFFF
Global foreground = $0
Global ForeColorHeader = $0
Global BackColorHeader = $bbffff
Global BackColorBrushHeader = CreateSolidBrush_(BackColorHeader)
; Global SelRectColor = $0078D4
; Global SelRectBrush = CreateSolidBrush_(SelRectColor)
Global borderHeader = $009999
Global hLinePen = CreatePen_(#PS_SOLID, 2, borderHeader) ; перо для линий в заголовке таблицы
; Global OldObject



Procedure Callback_Header(hWnd, Message, wParam, lParam)
	Protected *Header.HD_NOTIFY, SelectedLine, *lvCD.NMLVCUSTOMDRAW
	Protected *nmhdr.NMHDR, text$, *pnmcd.NMCUSTOMDRAW, hdi.hd_item
	Protected subItemRect.RECT, hDC, i
	Protected Result = CallWindowProc_(Main_References, hWnd, Message, wParam, lParam)


	*Header = lParam
	*nmhdr = lParam
	*lvCD = lParam
	Select Message
; 		Case #WM_NCDESTROY ; удаление кистей, после закрытия программы
; 			DeleteObject_(BackColorBrushHeader)
; 			DeleteObject_(SelRectBrush)
		Case #WM_NOTIFY
			Select *Header\hdr\code
				Case #HDN_ITEMCLICK
					If *Header\hdr\code = #HDN_ITEMCLICK
						;ColumnClicked=*Header\iItem
						SelectedLine = Val(GetGadgetItemText(#LIG, -1, 0))
						If SelectedLine > 0
; 							JumpToLine(SelectedLine)
						EndIf
					EndIf
				Case #NM_CUSTOMDRAW
					If *nmhdr\hwndFrom = hHeader
						*pnmcd.NMCUSTOMDRAW = lParam
						Select *pnmcd\dwDrawStage
							Case #CDDS_PREPAINT
								result = #CDRF_NOTIFYITEMDRAW
							Case #CDDS_ITEMPREPAINT
								text$ = GetGadgetItemText(GetDlgCtrlID_(hWnd), -1, *pnmcd\dwItemSpec)
								hdi\mask = #HDI_TEXT
								hdi\psztext = @text$
								hdi\cchtextmax = Len(text$)
								SetBkMode_(*pnmcd\hdc, #TRANSPARENT)
								FillRect_(*pnmcd\hdc, *pnmcd\rc, BackColorBrushHeader)
								; FrameRect_(*lvCD\nmcd\hdc, *pnmcd\rc, SelRectBrush) ; рисует рамку
								
								; рисует линию справа и снизу
								SendMessage_(GadgetID(#LIG), #LVM_GETSUBITEMRECT, *lvCD\nmcd\dwItemSpec, @subItemRect) ; в итоге переписываем структуру прямоугольника
								With *pnmcd\rc
									SelectObject_(*lvCD\nmcd\hdc, hLinePen)
									MoveToEx_(*lvCD\nmcd\hdc, \right, \top, 0)
									LineTo_(*lvCD\nmcd\hdc, \right, \bottom)
									LineTo_(*lvCD\nmcd\hdc, \left, \bottom)
; 									Рисуем значок
									If *pnmcd\dwItemSpec = indexSort
; 										Тут рисует пустую фигуру треугольник
										If SortOrder = -1
											MoveToEx_(*lvCD\nmcd\hdc, \left + 1, \top + 1, 0)
											LineTo_(*lvCD\nmcd\hdc, \left + 6, \top + 6)
											LineTo_(*lvCD\nmcd\hdc, \left + 11, \top + 1)
; 											LineTo_(*lvCD\nmcd\hdc, \left + 1, \top + 1)
										Else
											MoveToEx_(*lvCD\nmcd\hdc, \left + 1, \top + 6, 0)
											LineTo_(*lvCD\nmcd\hdc, \left + 6, \top + 1)
											LineTo_(*lvCD\nmcd\hdc, \left + 11, \top + 6)
; 											LineTo_(*lvCD\nmcd\hdc, \left + 1, \top + 6)
										EndIf
; 										Тут рисует пустую фигуру треугольник
; 										If SortOrder = -1
; 											MoveToEx_(*lvCD\nmcd\hdc, \left + 1, \top + 1, 0)
; 											LineTo_(*lvCD\nmcd\hdc, \left + 6, \top + 6)
; 											LineTo_(*lvCD\nmcd\hdc, \left + 11, \top + 1)
; 											LineTo_(*lvCD\nmcd\hdc, \left + 1, \top + 1)
; 										Else
; 											MoveToEx_(*lvCD\nmcd\hdc, \left + 1, \top + 6, 0)
; 											LineTo_(*lvCD\nmcd\hdc, \left + 6, \top + 1)
; 											LineTo_(*lvCD\nmcd\hdc, \left + 11, \top + 6)
; 											LineTo_(*lvCD\nmcd\hdc, \left + 1, \top + 6)
; 										EndIf
; 										тут рисует заполненный треугольник с помощью линий
; 										If SortOrder = -1
; 											For i = 1 To 5
; 												MoveToEx_(*lvCD\nmcd\hdc, \left + i, \top + i, 0) ; не рисует, а перемещает точку
; 												LineTo_(*lvCD\nmcd\hdc, \left + 10 - i, \top + i)
; ; 												MoveToEx_(*lvCD\nmcd\hdc, \left + (10 - i), \top + i, 0)
; ; 												LineTo_(*lvCD\nmcd\hdc, \left + i, \top + i)
; 											Next
; 										Else
; 											For i = 1 To 5
; 												MoveToEx_(*lvCD\nmcd\hdc, \left + 10 - i, \top + (6 - i), 0) ; не рисует, а перемещает точку
; 												LineTo_(*lvCD\nmcd\hdc, \left + i, \top + 6 - i)
; 											Next
; 										EndIf
									EndIf
								EndWith
								
; 								сдвигаем текст после закрашивания прямоуголников
; 								If *lvCD\nmcd\dwItemSpec
; 									InflateRect_(*pnmcd\rc, -8, 0)
; ; 									text$ = LTrimChar(text$, " " + #TAB$)
; 								Else
; 									InflateRect_(*pnmcd\rc, -4, 0)
; 								EndIf
								SetTextColor_(*pnmcd\hdc, ForeColorHeader)
								*pnmcd\rc\top + 2
								DrawText_(*pnmcd\hdc, @text$, Len(text$), *pnmcd\rc, #DT_CENTER | #DT_VCENTER | #DT_END_ELLIPSIS)
								result = #CDRF_SKIPDEFAULT
						EndSelect
					EndIf
			EndSelect
	EndSelect
	ProcedureReturn Result
EndProcedure



Procedure IsHex(*text)
	Protected flag = 1, *c.Character = *text

	If *c\c = 0
		ProcedureReturn 0
	EndIf

	Repeat
		If Not ((*c\c >= '0' And *c\c <= '9') Or (*c\c >= 'a' And *c\c <= 'f') Or (*c\c >= 'A' And *c\c <= 'F'))
			flag = 0
			Break
		EndIf
		*c + SizeOf(Character)
	Until Not *c\c

; 	Debug flag
	ProcedureReturn flag
EndProcedure

Procedure RGBtoBGR(c)
; 	ProcedureReturn RGB(Blue(c), Green(c), Red(c))
	ProcedureReturn ((c & $00FF00) | ((c & $0000FF) << 16) | ((c & $FF0000) >> 16))
EndProcedure

; def если пустая строка или больше 6 или 5 или 4
; def в BGR, не RGB, то есть готовое для применения
; Color$ это RGB прочитанный из ini с последующим преобразованием в BGR
Procedure ColorValidate(Color$, def = 0)
	Protected tmp$, tmp2$, i
; 	Debug Color$
	i = Len(Color$)
	If i <= 6 And IsHex(@Color$)
		Select i
			Case 6
; 				def = Val("$" + Color$)
; 				RGBtoBGR2(@def)
				def = RGBtoBGR(Val("$" + Color$))
			Case 1
				def = Val("$" + LSet(Color$, 6, Color$))
			Case 2
				def = Val("$" + Color$ + Color$ + Color$)
			Case 3
; 				сразу переворачиваем в BGR
				For i = 3 To 1 Step -1
					tmp$ = Mid(Color$, i, 1)
					tmp2$ + tmp$ + tmp$
				Next
				def = Val("$" + tmp2$)
		EndSelect
	EndIf
; 	Debug Hex(def)
	ProcedureReturn def
EndProcedure
; IDE Options = PureBasic 6.04 LTS (Windows - x64)
; CursorPosition = 16
; FirstLine = 12
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
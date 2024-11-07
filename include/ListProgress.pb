; функция переисовки упрощена для работы с программой, универсальный оригинал ищите на форуме

#CDDS_SUBITEMPREPAINT = #CDDS_SUBITEM|#CDDS_ITEMPREPAINT 
Global FontDefault = GetStockObject_(#DEFAULT_GUI_FONT)

Procedure DrawProgressBar(*LVCDHeader.NMLVCUSTOMDRAW)
	Protected Progress, Color, brush, x.f, hMemoryDC, hMemoryDC_1, hBitmap_1, hBitmap, String.s
	Protected rc.RECT, Text.RECT, BoxLeft.RECT, BoxRight.RECT, hPen
	Shared FontDefault
	
	rc\left=#LVIR_BOUNDS
	rc\top=*LVCDHeader\iSubItem
	; 	получить квадрат/ящик подпункта (отступы и размеры)
	SendMessage_(*LVCDHeader\nmcd\hdr\hwndfrom,#LVM_GETSUBITEMRECT,*LVCDHeader\nmcd\dwItemSpec,@rc)
	If rc\left >= 0 And rc\left < rc\right
		;  можно явно указать #ListIcon при одном гаджете
		Progress = Val(GetGadgetItemText(0 , *LVCDHeader\nmcd\dwItemSpec, 8))
		
		x = (rc\right - rc\left - 2) * Progress / 100
; 		x = Round((rc\right - rc\left) * Progress / 100, #PB_Round_Nearest)

		If Progress >= 91 ; определить цвет по процентам
						 ; Color = $8080FF
			Color = $2627DB
		Else
			; Color = $FF9900
			Color = $DBA025
		EndIf
; 		Debug Progress
		
		; Полоса прогресса - блок слева
		brush = CreateSolidBrush_(Color) ; создаём кисть
		If brush
			If rc\right >= rc\left + x
				BoxLeft\left=rc\left + 1
				BoxLeft\right = rc\left + x
				BoxLeft\bottom = rc\bottom - 2
				BoxLeft\top = rc\top + 1
			EndIf
			FillRect_(*LVCDHeader\nmcd\hdc, @BoxLeft, brush)
			DeleteObject_(brush)
		EndIf
		

		If Progress < 100 ; не рисовать блок справа если процент достиг 100
			; Полоса пустоты - блок справа
			brush = CreateSolidBrush_($E6E6E6) ; создаём кисть (ccffff)
			If brush
				BoxRight\left=rc\left + x
				BoxRight\right = rc\right - 1
				BoxRight\bottom = rc\bottom - 2
				BoxRight\top = rc\top + 1
				FillRect_(*LVCDHeader\nmcd\hdc, @BoxRight, brush)
			EndIf
			DeleteObject_(brush)
		EndIf
		
		; Рисуем границы
		hPen = CreatePen_(0, 1, $BCBCBC)
		If hPen
			SelectObject_(*LVCDHeader\nmcd\hdc, hPen)
			MoveToEx_(*LVCDHeader\nmcd\hdc, rc\left, rc\bottom - 2, 0)
			LineTo_(*LVCDHeader\nmcd\hdc, rc\left, rc\top)
			LineTo_(*LVCDHeader\nmcd\hdc, rc\right - 2, rc\top)
			LineTo_(*LVCDHeader\nmcd\hdc, rc\right - 2, rc\bottom - 2)
			LineTo_(*LVCDHeader\nmcd\hdc, rc\left, rc\bottom - 2)
			DeleteObject_(hPen)
		EndIf
		
		hMemoryDC = CreateCompatibleDC_(*LVCDHeader\nmcd\hdc)
		If hMemoryDC
			hMemoryDC_1 = CreateCompatibleDC_(*LVCDHeader\nmcd\hdc)
			If hMemoryDC_1
				
				hBitmap_1 = CreateCompatibleBitmap_(*LVCDHeader\nmcd\hdc, rc\right-rc\left, rc\bottom-rc\top)
				If hBitmap_1
					Text.RECT
					Text\left = 0
					Text\top = 1
					Text\right = Text\left + x
					Text\bottom = rc\bottom - rc\top
					SelectObject_(hMemoryDC_1, hBitmap_1)
					brush = CreateSolidBrush_(Color)
					If brush
						FillRect_(hMemoryDC_1, @Text, brush)
						DeleteObject_(brush)
					EndIf
					
					; рисуем текст
					hBitmap = CreateBitmap_(rc\right-rc\left, rc\bottom-rc\top, 1, 1, 0)
					If hBitmap
						SelectObject_(hMemoryDC, hBitmap)
						SelectObject_(hMemoryDC, FontDefault)
						SetTextColor_(hMemoryDC, $FFFFFF)
						SetBkColor_(hMemoryDC, $0)
						String.s = Str(Progress)+"%"
						Text.RECT
						Text\left = 0
						Text\top = 1
						Text\right = rc\right-rc\left
						Text\bottom = rc\bottom-rc\top
						DrawText_(hMemoryDC, String, Len(String), @Text, #DT_CENTER)
						MaskBlt_(hMemoryDC_1, Text\left, Text\top, Text\right-Text\left, Text\bottom-Text\top, hMemoryDC, 0, 0, hBitmap, 0, 0 ,#SRCINVERT)
						BitBlt_(*LVCDHeader\nmcd\hdc, rc\left, rc\top, rc\right-rc\left, rc\bottom-rc\top, hMemoryDC_1, 0, 0, #SRCINVERT)
						
						DeleteObject_(hBitmap)
					EndIf
					DeleteObject_(hBitmap_1)
				EndIf
				DeleteDC_(hMemoryDC_1)
			EndIf
			DeleteDC_(hMemoryDC)
		EndIf
		
	EndIf
EndProcedure

Procedure UpdateProgress(Gadget, Item, Column, Progress) 
	Protected rc.RECT 
	; 	MessageRequester("", Str(Gadget) + " " + Str(Item) + " " + Str(Progress))
	SetGadgetItemText(Gadget , Item , Str(Progress), Column)
	rc\left=#LVIR_BOUNDS 
	rc\top=Column 
	SendMessage_(hListView,#LVM_GETSUBITEMRECT,Item,@rc) 
	InvalidateRect_(hListView, @rc, #True) 
EndProcedure
; IDE Options = PureBasic 5.70 LTS (Windows - x86)
; CursorPosition = 16
; Folding = -
; EnableAsm
; EnableXP
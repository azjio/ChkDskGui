
; http://purebasic.info/phpBB3ex/viewtopic.php?p=94468#p94468
; https://www.purebasic.fr/english/viewtopic.php?t=88729

EnableExplicit

Structure PB_ListIconItem
	UserData.i
EndStructure


Declare CompareFunc(*item1.PB_ListIconItem, *item2.PB_ListIconItem, lParamSort)
Declare UpdatelParam()
Declare ForceSort()

Procedure ForceSort()
	If indexSort < 6 Or indexSort > -1
		SendMessage_(hListView, #LVM_SORTITEMS, indexSort, @CompareFunc())
		UpdatelParam()
		SortOrder = -SortOrder
	EndIf
EndProcedure


Procedure CompareFunc(*item1.PB_ListIconItem, *item2.PB_ListIconItem, lParamSort)
	Protected text1$, text2$, result
	text1$ = GetGadgetItemText(#LIG, *item1\UserData, lParamSort)
	text2$ = GetGadgetItemText(#LIG, *item2\UserData, lParamSort)
	If lParamSort = 5
; 		Сортировка по колонке 5 (размер)
		If ValD(text1$) > ValD(text2$)
			result = 1
		Else
			result = -1
		EndIf
	Else
; 		Сортировка по колонкам кроме 5 (текстовые)
		result = CompareMemoryString(@text1$, @text2$, #PB_String_NoCase)
	EndIf
	ProcedureReturn result * SortOrder
EndProcedure


Procedure UpdatelParam()
	Protected i
	For i = 0 To CountGadgetItems(#LIG) - 1
		SetGadgetItemData(#LIG, i, i)
	Next
EndProcedure

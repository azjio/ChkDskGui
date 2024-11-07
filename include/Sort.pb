
; http://purebasic.info/phpBB3ex/viewtopic.php?p=94468#p94468

EnableExplicit

Structure PB_ListIconItem
	UserData.i
EndStructure

#LVM_SETEXTENDEDLISTVIEWSTYLE = #LVM_FIRST + 54
#LVM_GETEXTENDEDLISTVIEWSTYLE = #LVM_FIRST + 55

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
	Protected *Buffer1, *Buffer2, *Seeker1, *Seeker2, result.d, done, char1, char2, Num1.d, Num2.d
	#SizeChar = SizeOf(Character)
	#MemSize = 256
	*Buffer1 = AllocateMemory(#MemSize * #SizeChar)
	*Buffer2 = AllocateMemory(#MemSize * #SizeChar)
	result = 0
	lvi\iSubItem = lParamSort
	lvi\pszText = *Buffer1
	lvi\cchTextMax = #MemSize
	lvi\Mask = #LVIF_TEXT
	SendMessage_(hListView, #LVM_GETITEMTEXT, *item1\UserData, @lvi)
	lvi\pszText = *Buffer2
	SendMessage_(hListView, #LVM_GETITEMTEXT, *item2\UserData, @lvi)
	*Seeker1 = *Buffer1
	*Seeker2 = *Buffer2
	If lParamSort = 5
		Num1 = ValD(PeekS(*Seeker1))
		Num2 = ValD(PeekS(*Seeker2))
		If SortOrder = -1
			result = Round((Num1-Num2), #PB_Round_Down) * SortOrder
		Else
			result = Round((Num1-Num2), #PB_Round_Up) * SortOrder
		EndIf
	Else
		done = 1
		While done
			char1 = Asc(UCase(Chr(PeekC(*Seeker1))))
			char2 = Asc(UCase(Chr(PeekC(*Seeker2))))
			result = (char1-char2) * SortOrder
			If result<>0 Or (*Seeker1-*Buffer1)>(#MemSize - 1) * #SizeChar
				done = 0
			EndIf
			*Seeker1+ #SizeChar
			*Seeker2+ #SizeChar
		Wend
	EndIf
	FreeMemory(*Buffer1)
	FreeMemory(*Buffer2)
	ProcedureReturn result
EndProcedure

Procedure UpdatelParam()
	Protected i
	For i = 0 To SendMessage_(hListView, #LVM_GETITEMCOUNT, 0, 0) - 1
		SetGadgetItemData(GetDlgCtrlID_(hListView), i, i)
	Next
EndProcedure

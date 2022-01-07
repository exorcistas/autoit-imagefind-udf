#include <../ImageFind_UDF.au3>

_ImageFind_CreateImageSnapshot()
EXAMPLE()
;~ MousePos()

Func EXAMPLE()
	Local $result = _ImageFind_SearchDesktop("Capture.bmp", 15)
		If @error Then Exit MsgBox(48, "_ImageFind_SearchDesktop", "Failed to search image on desktop." & @CRLF & "Function returned error: " & @error & " and value: " & $result)
	
	Local $aCoord[0]
	$aCoord = _ImageFind_GetCenterPosition($result)
	MouseMove($aCoord[0], $aCoord[1], 1)
EndFunc

Func MousePos()
	While 1	
		$x = _WinAPI_GetMousePosX()
		$y = _WinAPI_GetMousePosY()
		ConsoleWrite($x & "/" & $y & @CRLF)

		Sleep(1000)
	WEnd
EndFunc
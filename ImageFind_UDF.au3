#cs # ImageFind_UDF # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	Name..................: ImageFind UDF
	Description...........: Functions for searching image (BMP format) to determine position on screen
	Documentation.........: https://www.autoitscript.com/forum/files/file/471-image-search-udf/

	Dependencies..........: ImageFind DLL
	Limitations...........: Image and search area scale must match, otherwise image will not be recognized

	Author................: exorcistas@github.com
	Credits...............: VIP @ AutoIt (https://www.autoitscript.com/forum/profile/103606-vip/)
	Modified..............: 2020-10-03
	Version...............: v1.0
#ce ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#include-once
#include <Misc.au3>
#include <WinAPIGdi.au3>
#include <ScreenCapture.au3>
#include <GuiConstantsEx.au3>
#include <WindowsConstants.au3>
#include <WinAPISys.au3>

#Region GLOBAL_VARIABLES
	Global Const $_ImageFind_DLL_x32 = "ImageFind_x32.dll"
	Global Const $_ImageFind_DLL_x64 = "ImageFind_x64.dll"
	Global $_ImageFind_DLL_ROOT_FOLDER = @ScriptDir & "\"

	Global $_ImageFind_DLL_PATH = (@AutoItX64) ? $_ImageFind_DLL_ROOT_FOLDER & $_ImageFind_DLL_x64 : $_ImageFind_DLL_x32

	Global Const $_FULL_DESKTOP_WIDTH = _WinAPI_GetSystemMetrics(78)
	Global Const $_FULL_DESKTOP_HEIGHT = _WinAPI_GetSystemMetrics(79)
	
	Global $_ImageFind_DEBUG = True
#EndRegion GLOBAL_VARIABLES

#Region FUNCTIONS_LIST
#cs	===================================================================================================================================
%% CORE %%
	_ImageFind_SearchDesktop($_sImagePath, $_iColorTolerance = 0)
	_ImageFind_SearchArea($_sImagePath, $_iStartPosX1, $_iStartPosY1, $_iEndPosX2, $_iEndPosY2, $_iColorTolerance = 0)
	_ImageFind_GetCenterPosition($_aResult)
	_ImageFind_CreateImageSnapshot($_sImagePathToSave = @ScriptDir & "\Capture.bmp")

%% INTERNAL %%
 	__ImageFind_DLLCall($_sImagePath, $_iColorTolerance, $_iStartPosX1, $_iStartPosY1, $_iEndPosX2, $_iEndPosY2)
#ce	===================================================================================================================================
#EndRegion FUNCTIONS_LIST

#Region FUNCTIONS
	#cs #FUNCTION# ====================================================================================================================
		Name...............: _ImageFind_SearchDesktop($_sImagePath, $_iColorTolerance = 0)
		Description .......: Searches image match on entire Desktop (multi-monitor mode)

		Parameters.........: {$_sImagePath} - 		Full path to bitmap (BMP) image to search for on screen
                             {$_iColorTolerance}-	Integer value (0-255) to set tolerance for color mismatch

		Return values .....: Success:	see: _ImageFind_SearchArea()
                             Failure:	False; @error

		Author ............: exorcistas@github.com
		Modified...........: 2020-10-02
	#ce ===============================================================================================================================
	Func _ImageFind_SearchDesktop($_sImagePath, $_iColorTolerance = 0)
		Local $_Result = _ImageFind_SearchArea($_sImagePath, -$_FULL_DESKTOP_WIDTH, -$_FULL_DESKTOP_HEIGHT, $_FULL_DESKTOP_WIDTH, $_FULL_DESKTOP_HEIGHT, $_iColorTolerance)
			If @error Then Return SetError(@error, @extended, $_Result)
		
		Return $_Result
	EndFunc

	#cs #FUNCTION# ====================================================================================================================
		Name...............: _ImageFind_SearchArea($_sImagePath, $_iStartPosX1, $_iStartPosY1, $_iEndPosX2, $_iEndPosY2, $_iColorTolerance = 0)
		Description .......: Searches image match in specified area (coordinates on screen)

		Parameters.........: {$_sImagePath} - 		Full path to bitmap (BMP) image to search for on screen
                             {$_iColorTolerance}-	Integer value (0-255) to set tolerance for color mismatch
                             {$_iStartPosX1} -		Coordinates for search area
                             {$_iStartPosY1}
                             {$_iEndPosX2}
                             {$_iEndPosY2}

		Return values .....: Success:	string with output coordinates, delimited by "|". First value determines success if (1)
                             Failure:	False; @error
		
		Author ............: exorcistas@github.com
		Modified...........: 2020-10-02
	#ce ===============================================================================================================================
	Func _ImageFind_SearchArea($_sImagePath, $_iStartPosX1, $_iStartPosY1, $_iEndPosX2, $_iEndPosY2, $_iColorTolerance = 0)
		Local $_Result = __ImageFind_DLLCall($_sImagePath, $_iColorTolerance, $_iStartPosX1, $_iStartPosY1, $_iEndPosX2, $_iEndPosY2)
			If @error Then Return SetError(@error, @extended, $_Result)
		
		Return $_Result
	EndFunc

	#cs #FUNCTION# ====================================================================================================================
		Name...............: _ImageFind_GetCenterPosition($_aResult)
		Description .......: Takes 4-point area coordinates and calculates center X/Y position

		Parameters.........: {$_aResult} - output receiver from _ImageFind_Search* functions

		Return values .....: Success:	array with X [0] and Y [1] coordinates
                             Failure:	False; @error

		Author ............: exorcistas@github.com
		Modified...........: 2020-10-02
	#ce ===============================================================================================================================
	Func _ImageFind_GetCenterPosition($_aResult)
		If NOT IsArray($_aResult) Then Return SetError(1, 0, False)

		Local $_aTemp = StringSplit($_aResult[0],  "|")
		ReDim $_aResult[2]

		;-- Calculate center X/Y coordinates:
		$_aResult[0] = Round(Number($_aTemp[2]) + (Number($_aTemp[4]/2)) )
		$_aResult[1] = Round(Number($_aTemp[3]) + (Number($_aTemp[5]/2)) )

		Return $_aResult
	EndFunc

	#cs #FUNCTION# ====================================================================================================================
		Name...............: _ImageFind_CreateImageSnapshot($_sImagePathToSave = @ScriptDir & "\Capture.bmp")
		Description .......: Function to capture mouse-selected area from screen and save to bitmap for searching

		Parameters.........: {$_sImagePathToSave} - Full path location to save image. Image extension should always be ".bmp" - bitmap

		Return values .....: Success:	Returns 1
                             Failure:	False; @error
                             Cancelled by user:	Returns 0

		Notes .............: Use left mouse button and draw are to capture; Right mouse button cancels function

		Author ............: exorcistas@github.com
		Modified...........: 2020-10-02
	#ce ===============================================================================================================================
	Func _ImageFind_CreateImageSnapshot($_sImagePathToSave = @ScriptDir & "\Capture.bmp")
		ToolTip('(Press RMB for EXIT) select area to create image snippet ...', 1, 1)

		Local $_hMask, $_hMasterMask
		Local $_hUserDLL = DllOpen("user32.dll")

		Local $_hOverlayGUI = GUICreate("Test", $_FULL_DESKTOP_WIDTH*2, $_FULL_DESKTOP_HEIGHT*2, -$_FULL_DESKTOP_WIDTH, -1, $WS_POPUP, $WS_EX_TOPMOST)
			WinSetTrans($_hOverlayGUI, "", 8)
			GUISetCursor(3, 1, $_hOverlayGUI)
			GUISetState(@SW_SHOW, $_hOverlayGUI)
			

		Local $_hDrawGUI = GUICreate("", $_FULL_DESKTOP_WIDTH*2, $_FULL_DESKTOP_HEIGHT*2, -$_FULL_DESKTOP_WIDTH, -1, $WS_POPUP, $WS_EX_TOOLWINDOW + $WS_EX_TOPMOST)
			GUISetBkColor(0x000000, -1)

		While Not _IsPressed("01", $_hUserDLL)
			Sleep(10)
			If _IsPressed("02", $_hUserDLL) Then Return 0
		WEnd

		;-- Get start position:
		Local $_aMousePos = MouseGetPos()
		Local $_iX1 = $_aMousePos[0]
		Local $_iY1 = $_aMousePos[1]

		;-- Get end position:
		While _IsPressed("01", $_hUserDLL)
			$_aMousePos = MouseGetPos()
			$_hMasterMask = _WinAPI_CreateRectRgn(0, 0, 0, 0)
			$_hMask = _WinAPI_CreateRectRgn($_iX1, $_aMousePos[1], $_aMousePos[0], $_aMousePos[1] + 1)
				_WinAPI_CombineRgn($_hMasterMask, $_hMask, $_hMasterMask, 2)
				_WinAPI_DeleteObject($_hMask)

			$_hMask = _WinAPI_CreateRectRgn($_iX1, $_iY1, $_iX1 + 1, $_aMousePos[1])
				_WinAPI_CombineRgn($_hMasterMask, $_hMask, $_hMasterMask, 2)
				_WinAPI_DeleteObject($_hMask)

			$_hMask = _WinAPI_CreateRectRgn($_iX1 + 1, $_iY1 + 1, $_aMousePos[0], $_iY1)
				_WinAPI_CombineRgn($_hMasterMask, $_hMask, $_hMasterMask, 2)
				_WinAPI_DeleteObject($_hMask)

			$_hMask = _WinAPI_CreateRectRgn($_aMousePos[0], $_iY1, $_aMousePos[0] + 1, $_aMousePos[1])
				_WinAPI_CombineRgn($_hMasterMask, $_hMask, $_hMasterMask, 2)
				_WinAPI_DeleteObject($_hMask)

			_WinAPI_SetWindowRgn($_hDrawGUI, $_hMasterMask)
			If WinGetState($_hDrawGUI) < 15 Then GUISetState()
			Sleep(10)
		WEnd

		Local $_iX2 = $_aMousePos[0]
		Local $_iY2 = $_aMousePos[1]
		Local $_iTemp
		If $_iX2 < $_iX1 Then
			$_iTemp = $_iX1
			$_iX1 = $_iX2
			$_iX2 = $_iTemp
		EndIf
		If $_iY2 < $_iY1 Then
			$_iTemp = $_iY1
			$_iY1 = $_iY2
			$_iY2 = $_iTemp
		EndIf

		GUIDelete($_hDrawGUI)
		GUIDelete($_hOverlayGUI)
		DllClose($_hUserDLL)

		If $_ImageFind_DEBUG Then ConsoleWrite("[_ImageFind_CreateImageSnapshot]:	X1 = " & $_iX1 & ";	Y1 = " & $_iY1 & ";	X2 = " & $_iX2 & ";	Y2 = " & $_iY2 & @CRLF)
		_ScreenCapture_SetBMPFormat(4)
		_ScreenCapture_Capture($_sImagePathToSave, $_iX1, $_iY1, $_iX2, $_iY2, False)
		Sleep(200)

		Return 1
	EndFunc
#EndRegion FUNCTIONS

#Region INTERNAL
	Func __ImageFind_DLLCall($_sImagePath, $_iColorTolerance, $_iStartPosX1, $_iStartPosY1, $_iEndPosX2, $_iEndPosY2)
		If NOT FileExists($_ImageFind_DLL_PATH) Then Return SetError(1, 1, False)
		If NOT FileExists($_sImagePath) Then Return SetError(1, 2, False)

		;-- Control min/max input values:
		If $_iColorTolerance < 0 Then 
			$_iColorTolerance = 0
		ElseIf $_iColorTolerance > 255 Then
			$_iColorTolerance = 255
		EndIf
		
		If $_iColorTolerance > 0 Then $_sImagePath = "*" & $_iColorTolerance & " " & $_sImagePath
		
		Local $_Result = DllCall($_ImageFind_DLL_PATH, "str", "ImageSearch", "int", $_iStartPosX1, "int", $_iStartPosY1, "int", $_iEndPosX2, "int", $_iEndPosY2, "str", $_sImagePath)

			;-- Exception on DLL call:
			If ((NOT IsArray($_Result)) OR @error) Then Return SetError(2, @error, False)

			;-- Image not found:
			If Int($_Result[0]) = 0 Then Return SetError(3, 0, False)

			If $_ImageFind_DEBUG Then ConsoleWrite("[__ImageFind_DLLCall]:	" & $_Result[0] & @CRLF)
		
		Return $_Result
	EndFunc
#EndRegion INTERNAL
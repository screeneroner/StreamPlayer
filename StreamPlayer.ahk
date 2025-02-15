;——————————————————————————————————————————————————————————————————————————————————————————————————————————
; This code is free software: you can redistribute it and/or modify  it under the terms of the 
; version 3 GNU General Public License as published by the Free Software Foundation.
; 
; This code is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY without even 
; the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. 
; See the GNU General Public License for more details (https://www.gnu.org/licenses/gpl-3.0.html)
;
; WARNING TO USERS AND MODIFIERS
;
; This script contains "Buy me a coffee" links to honor the author's hard work and dedication in creating
; all the features present in this code. Removing or altering these links not only violates the GPL license
; but also disregards the significant effort put into making this script valuable for the community.
;
; If you find value in this script and would like to show appreciation to the author,
; kindly consider visiting the site below and treating the author to a few cups of coffee:
;
; https://www.buymeacoffee.com/screeneroner
;
; Your honor and gratitude is greatly appreciated.
;——————————————————————————————————————————————————————————————————————————————————————————————————————————


/*
 StreamPlayer: Tray-based video player using mpv and yt-dlp for streaming video content.
    - mpv: https://mpv.io/
    - yt-dlp: https://github.com/yt-dlp/yt-dlp

 HOW IT WORKS:
 1. Command-Line Support:
    - If a URL is passed as a command-line argument, it will start playing immediately.
    - If no argument is passed, the script displays a tray menu for stream selection.
 
 2. Tray Menu Options:
    - Toggle Mute: Mutes or unmutes the current video.
    - Toggle Play: Pauses or resumes the current video.
    - Refresh List: Reloads the stream list from the .lst file.
    - Buy Me a Coffee: Opens a support webpage in the default browser.
    - Exit: Closes the player and exits the application.

 3. Stream List (`.lst` File):
    - The deafult `ScriptName.lst` file must be in the same folder with script to do not give it in params.
	- The `.lst` file may be located anywhere. Use full path to point it in the command line during launch.
    - Each line should have the format: `MenuItemName | URL`
    - Lines without a `|` are treated as comments and ignored.
*/


#Persistent
#SingleInstance, Force
SetWorkingDir, %A_ScriptDir%
streamList := {}  ; Associative array to store title-url pairs

;——————————————————————————————————————————————————————————————————————————————————————————————————————————
; Get script name without extension and append .lst
; The script will look for a .lst file with the same name as the script.
SplitPath, A_ScriptFullPath, , , , scriptNameNoExt
file_path := scriptNameNoExt . ".lst"

;——————————————————————————————————————————————————————————————————————————————————————————————————————————
; Initialize geometry with default values
; These values will be used if the window position cannot be detected.
mpv_x := 10
mpv_y := 10
mpv_width := 480
mpv_height := 270
; Registry key path for storing geometry
regPath := "HKCU\Software\StreamPlayer"
LoadGeometry() ; Load saved geometry at startup


;——————————————————————————————————————————————————————————————————————————————————————————————————————————
; Initialize the tray menu and set an icon for the tray.
; Load the list of available streams at startup.
Menu, Tray, NoStandard
Menu, Tray, Icon, Shell32.dll, 130
RefreshList()  

;——————————————————————————————————————————————————————————————————————————————————————————————————————————
; Check for a command-line parameter.
; If it's a URL (starts with "http"), play it immediately.
; Otherwise, show the tray menu to choose what to play.
if (A_Args.Length() > 0)
{
    param := A_Args[1]
    if (InStr(param, "http") = 1)
        LoadStreamByUrl(param)  ; Launch mpv with the URL
} else {
	Menu, Tray, Show  ; Show the menu at startup
}

;——————————————————————————————————————————————————————————————————————————————————————————————————————————
; Read the .lst file and populates the tray menu with stream options.
; Each line in the .lst file should have the format: MenuItemName | URL
; Lines without a "|" will be treated as comments and ignored.
RefreshList() {
    global streamList, file_path
    Menu, Tray, DeleteAll
    Menu, Tray, Add, Toggle Mute, ToggleMute
	Menu, Tray, Icon, Toggle Mute, shell32.dll, 3

    Menu, Tray, Add, Toggle Play, TogglePlay
	Menu, Tray, Icon, Toggle Play, shell32.dll, 262
    Menu, Tray, Default, Toggle Play
    Menu, Tray, Add  ; Separator
    streamList := {}

    if !FileExist(file_path) {
        ; Create the default .lst file with example content
        FileAppend, Limitless Music for Work | https://www.youtube.com/watch?v=D4gm0xA6t9c`n, %file_path%
        MsgBox, 64, Info, Default file created: %file_path%
    }
    
    loop, Read, %file_path%
    {
        line := A_LoopReadLine
        if (InStr(line, "|")) {
            StringSplit, part, line, |
            title := Trim(part1)
            url := Trim(part2)
            streamList[title] := url
            Menu, Tray, Add, %title%, LoadStream
			Menu, Tray, Icon, %title%, shell32.dll, 130
        }
    }
    
    Menu, Tray, Add  ; Separator
    Menu, Tray, Add, Refresh List, RefreshList
	Menu, Tray, Icon, Refresh List, shell32.dll, 239
    Menu, Tray, Add  ; Separator
	Menu, Tray, Add, Buy me a coffee, BuyCoffee
	Menu, Tray, Icon, Buy me a coffee, shell32.dll, 160    
	Menu, Tray, Add, Exit, ExitScript
	Menu, Tray, Icon, Exit, shell32.dll, 28
}

;——————————————————————————————————————————————————————————————————————————————————————————————————————————
; Play a stream by its title from the tray menu. 
LoadStream(itemTitle) {
    global streamList
    url := streamList[itemTitle]
    CloseMpv()  ; Save window position if it exists, then close mpv    
    LoadStreamByUrl(url)
}

;——————————————————————————————————————————————————————————————————————————————————————————————————————————
; Play a stream by a given URL using mpv and yt-dlp.
LoadStreamByUrl(url) {
    global mpv_x, mpv_y, mpv_width, mpv_height
    LoadGeometry()
    ;cmd = %ComSpec% /c yt-dlp -f best "%url%" -o - | mpv --force-window=yes --no-keepaspect-window --cache=yes --demuxer-max-bytes=100MiB --demuxer-max-back-bytes=20MiB --geometry=%mpv_width%x%mpv_height%+%mpv_x%+%mpv_y% --title="StreamPlayer" -
    cmd = %ComSpec% /c yt-dlp -f best "%url%" -o - |
    cmd .= " mpv --force-window=yes"
    cmd .= " --no-keepaspect-window"
    cmd .= " --cache=yes"
    cmd .= " --demuxer-max-bytes=100MiB"
    cmd .= " --demuxer-max-back-bytes=20MiB"
    cmd .= " --geometry=" . mpv_width . "x" . mpv_height . "+" . mpv_x . "+" . mpv_y
    cmd .= " --title=""StreamPlayer"" -"
    Run, %cmd%, , Hide
}

;——————————————————————————————————————————————————————————————————————————————————————————————————————————
; Load mpv window geometry from system registry
LoadGeometry() {
    global mpv_x, mpv_y, mpv_width, mpv_height, regPath
    ; Try to read each value from the registry. Use a default if not found.
    RegRead, mpv_x, %regPath%, X
    RegRead, mpv_y, %regPath%, Y
    RegRead, mpv_width, %regPath%, Width
    RegRead, mpv_height, %regPath%, Height
    mpv_x := (mpv_x = "") ? 10 : mpv_x
    mpv_y := (mpv_y = "") ? 10 : mpv_y
    mpv_width := (mpv_width = "") ? 480 : mpv_width
    mpv_height := (mpv_height = "") ? 270 : mpv_height
}

;——————————————————————————————————————————————————————————————————————————————————————————————————————————
; Save mpv window geometry to system registry
SaveGeometry() {
    global mpv_x, mpv_y, mpv_width, mpv_height, regPath
    RegWrite, REG_DWORD, %regPath%, X, %mpv_x%
    RegWrite, REG_DWORD, %regPath%, Y, %mpv_y%
    RegWrite, REG_DWORD, %regPath%, Width, %mpv_width%
    RegWrite, REG_DWORD, %regPath%, Height, %mpv_height%
}

;——————————————————————————————————————————————————————————————————————————————————————————————————————————
; Save the current mpv window's position and size for later use.
SaveWindowPosition() {
    global mpv_x, mpv_y, mpv_width, mpv_height
    if WinExist("StreamPlayer") {
        WinGetPos, mpv_x, mpv_y, mpv_width, mpv_height, StreamPlayer
    } else {
        mpv_x := 10
        mpv_y := 10
        mpv_width := 480
        mpv_height := 270
    }
    SaveGeometry()  ; Save to the registry
}


;——————————————————————————————————————————————————————————————————————————————————————————————————————————
; Close the current mpv instance and saves its position.
; Ensures the process is fully terminated within a 5-second timeout.
CloseMpv() {
    global
    Process, Exist, mpv.exe
    if ErrorLevel {
        SaveWindowPosition()  ; Save position before closing
        Process, Close, mpv.exe
        timeout := A_TickCount + 5000  ; 5-second timeout
        Loop {
            Process, Exist, mpv.exe
            if ErrorLevel = 0
                break
            if (A_TickCount > timeout) 
                break            
            Sleep, 200
        }
    }
}

;——————————————————————————————————————————————————————————————————————————————————————————————————————————
; Toggle mute for the current mpv instance by sending the "m" key.
ToggleMute() {
    if WinExist("StreamPlayer") 
        ControlSend,, m, StreamPlayer    
}

;——————————————————————————————————————————————————————————————————————————————————————————————————————————
; Toggle play/pause for the current mpv instance by sending the spacebar key.
TogglePlay() {
    if WinExist("StreamPlayer") 
        ControlSend,, {SPACE}, StreamPlayer    
}

;——————————————————————————————————————————————————————————————————————————————————————————————————————————
; Open a "Buy Me a Coffee" webpage in the default browser.
BuyCoffee() {
    Run, https://www.buymeacoffee.com/screeneroner
}

;——————————————————————————————————————————————————————————————————————————————————————————————————————————
; Close the application and ensures mpv is terminated.
ExitScript() {
    SaveGeometry()  ; Save geometry before exiting
    CloseMpv()  ; Close mpv on exit
    ExitApp
}

OnExit("ExitScript")

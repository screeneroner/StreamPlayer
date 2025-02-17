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

; v1.00 2025-02-15 Initial Release
; v1.01 2025-02-15 Window positioning fix
; v1.02 2025-02-16 Added On top and On desktop
; v2.00 2025-02-17 Fully reworked code + new features
global winTitle := "StreamPlayer v2.00"

/*
# StreamPlayer

A lightweight tray application for playing video streaming. 
This script provides an easy way to launch, control, and organize online streams directly from the system tray. 
With this app, you can easily manage and play your favorite online streams without opening a browser 
or dealing with unnecessary distractions. Whether you enjoy music, podcasts, or live news, 
this script lets you organize and launch streams directly from the system tray. 
No more searching for links every time—just right-click the tray icon, pick your stream, and enjoy!

You can also customize your stream list, toggle MPV’s Always On Top mode, or keep it pinned behind all windows 
for a distraction-free experience. Your last window position and size are always remembered, 
so the player launches exactly where you left it.

Simple, lightweight, and efficient—just the way a streaming tool should be.


# Features

Stream Management: Load and play online streams via MPV and yt-dlp.
Tray Menu Integration: Access all functions from a system tray menu.
Always On Top / On Desktop Modes: Keep the player in view or push it behind other windows.
Playback Controls: Play/Pause, Mute, and Stop MPV directly from the tray.
Persistent Window Settings: Remembers the last window position and size.


# How It Works

Load and Manage Streams
Reads a predefined stream list file (.lst) and populates the system tray menu. You may use default StreamPlayer.lst in the same folder or pass to the StreamPlayer in the command line during its start a full path to any file in any location.
Streams are launched using yt-dlp and played in MPV.
Play Controls
Select a stream from the tray menu to play it.
Toggle playback (Play/Pause), Mute, and Stop MPV directly from the menu.


# Window Management

Options to toggle Always On Top or On Desktop modes.
Saves MPV’s window position and size on exit.
Reloads the last known window geometry on the next launch.
Preparing the Stream PlayList File
The script relies on a .lst file to load streams into the tray menu. If the file does not exist, a default one is created.

# File Format
Each line represents a stream entry. Supported formats:
Title | URL → Adds a clickable stream entry.
- Category → Creates a category heading in the menu.
--- → Adds a separator between sections.

Example:
- Music Stations  
Lo-Fi Beats | https://www.youtube.com/watch?v=5qap5aO4i9A  
Jazz Café | https://www.youtube.com/watch?v=D4gm0xA6t9c  
---  

- News Channels  
BBC Live | https://www.bbc.co.uk/news/live  

Clicking on a stream entry will launch MPV with the specified URL. Categories (- Category) act as labels and cannot be clicked. --- adds visual separators between sections.


# Installation & Usage

Install MPV and yt-dlp (Ensure they are available in your system path). Actually, you only need two executable files: yt-dlp.exe and mpv.exe.
mpv: https://mpv.io/
yt-dlp: https://github.com/yt-dlp/yt-dlp
Run the StreamPlayer.exe
Access the tray menu to select and control streams.
Modify the .lst file to customize your streams.
Enjoy a simple, organized streaming experience! 

*/

#Persistent
#SingleInstance, Force
SetWorkingDir, %A_ScriptDir%

streamList := {}  ; Associative array to store title-url pairs
global desktopMode := ""  ; Initialize desktopMode as an empty string
global currentUrl := ""
global ipcPipe := A_Temp . "\mpvsocket"  ; IPC pipe for mpv communication in the system temp folder
global regPath := "HKCU\Software\StreamPlayer"  ; Registry key path for storing geometry

global isOnTop := false, isOnDesktop := false


;——————————————————————————————————————————————————————————————————————————————————————————————————————————
; Toggles the mute state of the StreamPlayer window.
; If the StreamPlayer window exists, it sends the "m" key to mute/unmute the player.
ToggleMute() {
    global winTitle
    if WinExist(winTitle) 
        ControlSend,, m, StreamPlayer 
}

; Toggles play/pause of the StreamPlayer.
; Sends the space key to the StreamPlayer window if it exists.
TogglePlay() {
    global winTitle
    if WinExist(winTitle) 
        ControlSend,, {SPACE}, StreamPlayer  
}

; Toggles the "Always On Top" state of the StreamPlayer window.
; Updates the isOnTop variable and ensures isOnDesktop is disabled if needed.
; Adjusts the menu icons accordingly and applies the window setting.
ToggleOnTop() {
    global isOnTop, isOnDesktop, winTitle
    if WinExist(winTitle) {
        isOnTop := !isOnTop    
        isOnDesktop := isOnTop ? false : isOnDesktop
        SetMenuTogglers()

        state := isOnTop ? "On" : "Off"        
        WinSet, AlwaysOnTop, %state%, StreamPlayer
    }
}

; Toggles the "On Desktop" state of the StreamPlayer window.
; Ensures isOnTop is disabled if needed.
; Updates the menu icons accordingly and sets a timer to keep the window at the bottom.
ToggleOnDesktop() {
    global isOnTop, isOnDesktop, winTitle
    if WinExist(winTitle) {
        isOnDesktop := !isOnDesktop
        isOnTop := isOnDesktop ? false : isOnTop
        SetMenuTogglers()

        state := isOnDesktop ? 1000 : "Off"
        SetTimer, KeepOnDesktop, %state%
    }
}

; Updates the tray menu icons based on the toggled states (On Top or On Desktop).
; Adjusts the menu icon state and stores the settings in the registry.
SetMenuTogglers() {
    global isOnTop, isOnDesktop
    check := isOnTop ? 145 : 132
    Menu, Tray, Icon, On Top, shell32.dll, %check%
    check := isOnDesktop ? 145 : 132
    Menu, Tray, Icon, On Desktop, shell32.dll, %check%
    RegWrite, REG_DWORD, %regPath%, isOnTop, % isOnTop ? 1 : 0
    RegWrite, REG_DWORD, %regPath%, isOnDesktop, % isOnDesktop ? 1 : 0    
}

; Keeps the StreamPlayer window at the bottom of the Z-order if "On Desktop" is enabled.
; If the window exists and isOnDesktop is true, it forces the window to the bottom.
; Otherwise, it turns off the timer to stop enforcing the position.
KeepOnDesktop() {
    global winTitle
    if WinExist(winTitle) {  ; Ensure the window exists
        WinGet, hwnd, ID, %winTitle%  ; Get the unique window handle
        if (isOnDesktop) {
            WinSet, Bottom, , ahk_id %hwnd%  ; Move only the StreamPlayer window to the bottom
        } else {
            SetTimer, KeepOnDesktop, Off  ; Stop running the function if isOnDesktop is false
        }
    }
}

;——————————————————————————————————————————————————————————————————————————————————————————————————————————


; Get script name without extension and append .lst
SplitPath, A_ScriptFullPath, , , , scriptNameNoExt
file_path := scriptNameNoExt . ".lst"

; Initialize tray menu
Menu, Tray, NoStandard
Menu, Tray, Icon, Shell32.dll, 130
LoadGeometry()
RefreshList()

; Handle command-line arguments
if (A_Args.Length() > 0) {
    param := A_Args[1]
    if (InStr(param, "http") = 1)
        StartStream(param)
} else {
    Menu, Tray, Show
}

;——————————————————————————————————————————————————————————————————————————————————————————————————————————
; Loads the mpv window's position and size from the system registry.
; This function reads the stored X, Y coordinates, width, and height from the registry.
; If no values are found, it sets default values (10,10 for position and 480x270 for size).
; Also loads the "Always On Top" and "On Desktop" settings from the registry.
LoadGeometry() {
    global mpv_x, mpv_y, mpv_width, mpv_height, regPath, isOnTop, isOnDesktop

    ; Try to read each value from the registry. Use a default if not found.
    RegRead, mpv_x, %regPath%, X
    RegRead, mpv_y, %regPath%, Y
    RegRead, mpv_width, %regPath%, Width
    RegRead, mpv_height, %regPath%, Height

    ; Assign default values if the registry read fails.
    mpv_x := (mpv_x = "") ? 10 : mpv_x
    mpv_y := (mpv_y = "") ? 10 : mpv_y
    mpv_width := (mpv_width = "") ? 480 : mpv_width
    mpv_height := (mpv_height = "") ? 270 : mpv_height

    ; Load and convert the "Always On Top" and "On Desktop" states from registry.
    RegRead, isOnTop, %regPath%, isOnTop
    isOnTop := (isOnTop = 1)

    RegRead, isOnDesktop, %regPath%, isOnDesktop
    isOnDesktop := (isOnDesktop = 1)

    ; Uncomment for debugging:
    ; msgbox % "LOADED: " . mpv_width . "x" . mpv_height . "+" . mpv_x . "+" . mpv_y . " | " . isOnTop . " | " . isOnDesktop
}
;——————————————————————————————————————————————————————————————————————————————————————————————————————————
; Saves the current mpv window's geometry (position and size) to the system registry.
; If the StreamPlayer window exists, it retrieves its position and size.
; Otherwise, it falls back to default values (10,10 for position and 480x270 for size).
; Also stores the "Always On Top" and "On Desktop" settings in the registry.
SaveGeometry() {
    global mpv_x, mpv_y, mpv_width, mpv_height, regPath, winTitle, isOnTop, isOnDesktop

    ; Check if the StreamPlayer window exists
    if WinExist(winTitle) {
        WinGet, hwnd, ID, StreamPlayer
        VarSetCapacity(rect, 16, 0)

        ; Try to get the window's client area coordinates
        if DllCall("GetClientRect", "ptr", hwnd, "ptr", &rect) {
            ; Convert client coordinates to screen coordinates
            DllCall("ClientToScreen", "ptr", hwnd, "ptr", &rect)
            mpv_x := NumGet(rect, 0, "Int"), mpv_y := NumGet(rect, 4, "Int")
            mpv_width := NumGet(rect, 8, "Int"), mpv_height := NumGet(rect, 12, "Int")
        } else {
            ; Fallback values if retrieval fails
            mpv_x := 10, mpv_y := 10, mpv_width := 480, mpv_height := 270
        }
    } else {
        ; Default values if window does not exist
        mpv_x := 10, mpv_y := 10, mpv_width := 480, mpv_height := 270
    }

    ; Save values to the registry
    RegWrite, REG_DWORD, %regPath%, X, %mpv_x%
    RegWrite, REG_DWORD, %regPath%, Y, %mpv_y%
    RegWrite, REG_DWORD, %regPath%, Width, %mpv_width%
    RegWrite, REG_DWORD, %regPath%, Height, %mpv_height%
    RegWrite, REG_DWORD, %regPath%, isOnTop, % isOnTop ? 1 : 0
    RegWrite, REG_DWORD, %regPath%, isOnDesktop, % isOnDesktop ? 1 : 0

    ; Uncomment for debugging:
    ; msgbox % "SAVED: " . mpv_width . "x" . mpv_height . "+" . mpv_x . "+" . mpv_y
}

;——————————————————————————————————————————————————————————————————————————————————————————————————————————
; Refreshes the tray menu with available streams from a .lst file.
; - Clears and rebuilds the tray menu.
; - Adds toggles for window behavior (On Top, On Desktop, Mute, Play/Pause).
; - Loads stream list from a specified file and populates the menu with stream options.
; - If the file does not exist, it creates a default one.
; File may contain the following line types
; - "Menu item text | URL"-- line with | that generates a menu item
; - " - Menu item text" -- line starting with "-". Used as a named separator in the menu to group items.
; - "---" -- line with "---" creates a default separator in the menu.
RefreshList() {
    global streamList, file_path

    ; Clear the existing tray menu
    Menu, Tray, DeleteAll

    ; Add window control toggles to the tray menu
    Menu, Tray, Add, On Top, ToggleOnTop
    Menu, Tray, Icon, On Top, shell32.dll, 15
    Menu, Tray, Add, On Desktop, ToggleOnDesktop
    Menu, Tray, Icon, On Desktop, shell32.dll, 233
    Menu, Tray, Add, Toggle Mute, ToggleMute
    Menu, Tray, Icon, Toggle Mute, shell32.dll, 3
    Menu, Tray, Add, Toggle Play, TogglePlay
    Menu, Tray, Icon, Toggle Play, shell32.dll, 262
    Menu, Tray, Default, Toggle Play
    Menu, Tray, Add  ; Separator

    ; Initialize stream list storage
    streamList := {}

    ; Check if the stream list file exists, create a default one if missing
    if !FileExist(file_path) {
        FileAppend, Limitless Music for Work | https://www.youtube.com/watch?v=D4gm0xA6t9c`n, %file_path%
        MsgBox, 64, Info, Default file created: %file_path%
    }

    ; Read and parse the stream list file
    Loop, Read, %file_path%
    {
        line := Trim(A_LoopReadLine)

        if (SubStr(line, 1, 3) = "---") {
            ; Add a separator line in the menu
            Menu, Tray, Add  
        } else if (SubStr(line, 1, 1) = "-") {
            ; Add a non-clickable menu item (category label)
            Menu, Tray, Add, % SubStr(line, 2), DoNothing
        } else if (InStr(line, "|")) {
            ; Parse and add a stream entry (title | URL)
            StringSplit, part, line, |
            title := Trim(part1)
            url := Trim(part2)
            streamList[title] := url

            ; Add stream entry to the tray menu
            Menu, Tray, Add, %title%, LoadStream
            Menu, Tray, Icon, %title%, shell32.dll, 130
        }
    }

    ; Add a refresh option to update the list dynamically
    Menu, Tray, Add  ; Separator
    Menu, Tray, Add, Refresh List, RefreshList
    Menu, Tray, Icon, Refresh List, shell32.dll, 239

    ; Add donation and exit options
    Menu, Tray, Add, Buy me a coffee, BuyCoffee
    Menu, Tray, Icon, Buy me a coffee, shell32.dll, 160    
    Menu, Tray, Add, Exit, ExitScript
    Menu, Tray, Icon, Exit, shell32.dll, 28

    ; Update menu icons based on current window state
    SetMenuTogglers()
}

; Placeholder function for non-interactive menu items
DoNothing() {
    return
}

;——————————————————————————————————————————————————————————————————————————————————————————————————————————
; Loads and starts a stream based on the selected title from the tray menu.
; - Checks if the selected stream title exists in the stream list.
; - If found, updates the current URL and displays a tooltip with the stream title.
; - Calls the `StartStream` function to play the selected stream.
; - If the stream is not found, an error message is displayed.
LoadStream(title) {
    global streamList, currentUrl

    ; Check if the selected title exists in the stream list
    if streamList.HasKey(title) {
        currentUrl := streamList[title]
        
        ; Show a tooltip with the stream title
        Menu, Tray, Tip , % winTitle . "`n" . title

        ; Start the selected stream
        StartStream(currentUrl)
    } else {
        ; Display an error message if the stream title is not found
        MsgBox, 48, Error, Stream not found for: %title%
    }
}

;——————————————————————————————————————————————————————————————————————————————————————————————————————————
; Starts a stream using yt-dlp and MPV.
; - Closes any existing MPV instance to save window geometry.
; - Loads saved geometry settings (position, size) before launching.
; - Constructs and executes a command to stream a video using yt-dlp piped into MPV.
; - Configures MPV settings for window behavior, cropping, and allowing screensaver activity.
; - Waits for the MPV window to appear and applies "On Top" or "On Desktop" settings if enabled.
StartStream(url) {
    global mpv_x, mpv_y, mpv_width, mpv_height, currentUrl, winTitle, isOnTop, isOnDesktop

    CloseMpv() ; Close any existing MPV instance to save window geometry
    LoadGeometry() ; Load stored window position and size

    currentUrl := url

    ; Construct command to stream via yt-dlp and play in MPV
    cmd := ComSpec . " /c yt-dlp -o - """ . currentUrl . """ |"
    cmd .= " mpv --force-window=yes --no-keepaspect-window --no-border --no-osc"
    cmd .= " --panscan=1.0" ; Crop video to prevent black bars on the sides
    cmd .= " --no-stop-screensaver -" ; Allow screensaver to run while MPV is playing
    cmd .= " --geometry=" . mpv_width . "x" . mpv_height . "+" . mpv_x . "+" . mpv_y
    cmd .= " --title=""" . winTitle . """"
    cmd .= " -"

    ; Debugging Output (Uncomment to check the full command)
    ; MsgBox % cmd

    ; Run the command and hide the console window
    Run, %cmd%, , Hide
    WinWait, %winTitle%, , 10  ; Wait for up to 10 seconds for the MPV window to appear

    ; Apply "Always On Top" setting if enabled
    if (isOnTop == 1) {
        isOnTop := false
        ToggleOnTop()  ; Call toggler function
    }

    ; Apply "On Desktop" setting if enabled
    if (isOnDesktop == 1) {
        isOnDesktop := false
        ToggleOnDesktop()  ; Call toggler function
    }
}

;——————————————————————————————————————————————————————————————————————————————————————————————————————————
; Closes the current MPV instance and ensures it is fully terminated.
; - Checks if an MPV process (`mpv.exe`) is running.
; - If found, saves the current window geometry before closing MPV.
; - Sends a termination command to MPV and waits up to 5 seconds for it to fully exit.
CloseMpv() {
    Process, Exist, mpv.exe
    if ErrorLevel {  ; If MPV is running
        SaveGeometry()  ; Save the current window position and size

        Process, Close, mpv.exe  ; Attempt to close MPV
        timeout := A_TickCount + 5000  ; Set a 5-second timeout

        ; Wait loop to ensure MPV has exited
        Loop {
            Process, Exist, mpv.exe
            if (ErrorLevel = 0 || A_TickCount > timeout)
                break  ; Exit loop if MPV is closed or timeout is reached            
            Sleep, 200  ; Wait for 200ms before checking again
        }
    }
}

;——————————————————————————————————————————————————————————————————————————————————————————————————————————
; Opens the "Buy Me a Coffee" donation page in the default web browser.
; - Allows users to support the developer by making a donation.
BuyCoffee() {
    Run, https://www.buymeacoffee.com/screeneroner  ; Open donation link
}
;——————————————————————————————————————————————————————————————————————————————————————————————————————————

;——————————————————————————————————————————————————————————————————————————————————————————————————————————
; Exits the script safely.
; - Ensures that the MPV instance is properly closed before exiting.
; - Calls `CloseMpv()` to terminate MPV and save its window geometry.
; - Ends the AutoHotkey script with `ExitApp`.
ExitScript() {
    CloseMpv()  ; Ensure MPV is closed before exiting
    ExitApp  ; Terminate the script
}
;——————————————————————————————————————————————————————————————————————————————————————————————————————————

;——————————————————————————————————————————————————————————————————————————————————————————————————————————
; Registers the `ExitScript` function to be called when the script exits.
; - Ensures MPV is properly closed before the script terminates.
; - Automatically triggers `ExitScript()` when the script is closed manually or unexpectedly.
OnExit("ExitScript")

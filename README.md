# StreamPlayer

Tray-based video player using mpv and yt-dlp for streaming video content.
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

Note: If you have concerns about suspicious actions from the pre-built executable, feel free to review the source code and compile it yourself.

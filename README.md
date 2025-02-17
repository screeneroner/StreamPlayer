# StreamPlayer

A lightweight tray application for playing video streaming. This script provides an easy way to launch, control, and organize online streams directly from the system tray.
With this app, you can easily **manage and play your favorite online streams** without opening a browser or dealing with unnecessary distractions. Whether you enjoy **music, podcasts, or live news**, this script lets you **organize and launch streams directly from the system tray**.  No more searching for links every time—just **right-click the tray icon, pick your stream, and enjoy**!   

You can also **customize your stream list**, toggle MPV’s **Always On Top** mode, or keep it **pinned behind all windows** for a distraction-free experience. **Your last window position and size are always remembered**, so the player launches exactly where you left it.  

Simple, lightweight, and efficient—just the way a streaming tool should be.

## Features
- **Stream Management:** Load and play online streams via MPV and yt-dlp.  
- **Tray Menu Integration:** Access all functions from a system tray menu.  
- **Always On Top / On Desktop Modes:** Keep the player in view or push it behind other windows.  
- **Playback Controls:** Play/Pause, Mute, and Stop MPV directly from the tray.  
- **Persistent Window Settings:** Remembers the last window position and size.  
---

## How It Works

### Load and Manage Streams  
- Reads a predefined stream list file (`.lst`) and populates the system tray menu. You may use **default StreamPlayer.lst** in the same folder or pass to the StreamPlayer in the command line during its start a full path to any file in any location.
- Streams are launched using **yt-dlp** and played in **MPV**.  

### Play Controls  
- Select a stream from the **tray menu** to play it.  
- Toggle playback (**Play/Pause**), **Mute**, and **Stop** MPV directly from the menu.  

### Window Management  
- Options to toggle **Always On Top** or **On Desktop** modes.  
- Saves **MPV’s window position and size** on exit.  
- Reloads the last known window geometry on the next launch.  

---

## Preparing the Stream PlayList File  

The script relies on a `.lst` file to load streams into the tray menu. If the file does not exist, a default one is created.  

### File Format  
Each line represents a stream entry. Supported formats:  
- `Title | URL` → Adds a clickable stream entry.  
- `- Category` → Creates a **category heading** in the menu.  
- `---` → Adds a **separator** between sections.  

### Example:
```text
- Music Stations  
Lo-Fi Beats | https://www.youtube.com/watch?v=5qap5aO4i9A  
Jazz Café | https://www.youtube.com/watch?v=D4gm0xA6t9c  

---  

- News Channels  
BBC Live | https://www.bbc.co.uk/news/live  
```

Clicking on a stream entry will launch MPV with the specified URL.
Categories (- Category) act as labels and cannot be clicked.
--- adds visual separators between sections.

## Installation & Usage
- Install MPV and yt-dlp (Ensure they are available in your system path). Actually, you only **need two executable files**: **yt-dlp.exe** and **mpv.exe**. 
  - mpv: https://mpv.io/
  - yt-dlp: https://github.com/yt-dlp/yt-dlp
- Run the **StreamPlayer.exe**
- Access the tray menu to select and control streams.
- Modify the .lst file to customize your streams.
- Enjoy a simple, organized streaming experience! 🎶

_Note: If you have concerns about suspicious actions from the pre-built executable, feel free to review the source code and compile it yourself._

> Work In Progress
## Faria Powershell Custom Setup Config Script - Version Details
This text file includes all the details and configurations about each version of the script.

### All Versions
- Uninstall bloat windows apps. (Note: does not uninstall Microsoft Store and Xbox App)
  - Media Player.
  - Copilot.
  - Bing.
  - Clipchamp.
  - Teams.
  - News.
  - Weather.
  - Outlook.
  - OneDrive.
  - Solitaire.
  - Sticky Notes.
  - Power Automate.
  - Cortana.
  - To Do.
  - Phone Link.
- Disables Microsoft telemetry and optimises Windows services.
- Disables BitLocker and decrypts all drives.
- Other custom set Windows preferences.
  - Desktop preferences.
    - Set wallpaper mode to Picture.
    - Set default Windows wallpaper.
    - Show classic desktop icons.
    - Show Windows Build/Version at the bottom right corner. (Optional, will ask User.)
  - File Explorer preferences.
    - Show hidden files.
    - Show file extension.
  - Taskbar preferences.
    - Search Bar to Icon.
    - Aligment to the left. (Windows 11 only.)
  - Power options.
    - Power plan set to Ultimate Performance.
    - Timeouts set to never.
    - Disable hard disk turning off by setting the value to 0.
    - Disable/Uncheck all Power Managment options for all Network adapters.
  - Advanced system settings, Performance Settings, Custom Preset.
    - Show thumbnails instead of icons.
    - Show translucent selection rectangle.
    - Show window contents while dragging.
    - Smooth edges of screen fonts.
    - Use drop shadows for icon labels on the desktop.
  - Enables legacy component DirectPlay.


### Optional - will ask User
- Other custom set Windows preferences.
  - Desktop preferences.
    - Show Windows Build/Version at the bottom right corner.
- Show Verbose Status. (Display more additional information when booting or shutting down and logging in or logging out Windows.)
- Set Quad9 (9.9.9.9 - https://quad9.net/) and Cloudflare (1.1.1.1 - https://www.cloudflare.com) DNS servers.
- Installs extra programs.
  - Microsoft Distributions/Redistributables (Visual C++, .NET Core, .NET Runtime, Windows Desktop Runtime - Nowadays most apps will require you to install one of these so this will just install all the necessaries.)
  - Powershell 7
  - 7zip
  - Java
  - Notepad++
  - VLC Media Player

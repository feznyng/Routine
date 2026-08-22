; Inno Setup script for the Routine Windows installer.
; Built by .github/workflows/release.yml:
;   ISCC.exe /DAppVersion=1.2.3 windows\packaging\routine.iss

#define MyAppName "Routine"
#define MyAppPublisher "SolidSoft LLC"
#define MyAppURL "https://github.com/ajan/routine"
#define MyAppExeName "routine_blocker.exe"

#ifndef AppVersion
  #define AppVersion "0.0.0"
#endif

[Setup]
; AppId must never change across releases — it is how Windows recognises an
; upgrade rather than a second parallel installation.
AppId={{8F3A2B14-9C6D-4E71-B0A5-2D7E4C918F63}
AppName={#MyAppName}
AppVersion={#AppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
; Per-user install avoids a UAC prompt entirely, which is one less scary dialog
; while the binary is unsigned. Switch to "admin" if you ever need machine-wide.
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog
OutputDir=..\..\dist
OutputBaseFilename=Routine-{#AppVersion}-setup
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
UninstallDisplayIcon={app}\{#MyAppExeName}

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "Create a &desktop shortcut"; GroupDescription: "Additional shortcuts:"

[Files]
; Ships the whole Flutter release folder — the VC++ runtime DLLs Flutter drops
; in here are why no redistributable prerequisite is needed.
Source: "..\..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; \
  Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "Launch {#MyAppName}"; \
  Flags: nowait postinstall skipifsilent

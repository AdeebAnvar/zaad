; ZAAD POS — Inno Setup (maintain alongside repo)
;
; Prerequisites:
; 1. Build Flutter Windows release (client/build/windows/x64/runner/Release).
; 2. Place VC++ installers in .\redist\ next to this .iss file:
;      vc_redist.x64.exe   — https://aka.ms/vs/17/release/vc_redist.x64.exe
;      vc_redist.x86.exe   — https://aka.ms/vs/17/release/vc_redist.x86.exe
; 3. Open this script from the Inno IDE and Compile.
;
; [{#RepoRoot}] = parent folder of .\installer (project root).

#ifndef RepoRoot
  #define RepoRoot ".."
#endif

[Setup]
AppName=Zaad POS
AppVersion=1.0.0+69
AppId=ZaadPOS
DefaultDirName=C:\POS
DefaultGroupName=Zaad POS
OutputDir=output
OutputBaseFilename=zaad_pos_setup
Compression=lzma
SolidCompression=yes
CloseApplications=yes
UsePreviousAppDir=yes
PrivilegesRequired=admin
SetupIconFile=favicon.ico

[Tasks]
Name: "desktopicon"; Description: "Create a desktop shortcut"

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Files]

; VC++ Runtime (staging only — not installed under C:\POS)
Source: "redist\vc_redist.x64.exe"; DestDir: "{tmp}"; Flags: deleteafterinstall skipifsourcedoesntexist; Check: IsWin64
Source: "redist\vc_redist.x86.exe"; DestDir: "{tmp}"; Flags: deleteafterinstall skipifsourcedoesntexist; Check: not IsWin64

Source: "{#RepoRoot}\client\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: recursesubdirs ignoreversion

; Server (+ node_modules, node-x64, node-x86)
Source: "{#RepoRoot}\server\*"; DestDir: "{app}\server"; Flags: recursesubdirs ignoreversion

[Icons]
Name: "{group}\Zaad POS"; Filename: "{app}\pos.exe"
Name: "{userdesktop}\Zaad POS"; Filename: "{app}\pos.exe"; Tasks: desktopicon

[Run]
; Prefer explicit install order: VC++ handled in Code (before these).
; Offline installs: ensure server\node_modules is complete in the staged tree.
Filename: "{app}\server\node-x64\npm.cmd"; Parameters: "install"; WorkingDir: "{app}\server"; Check: IsWin64; StatusMsg: "Installing server Node dependencies..."; Flags: runhidden waituntilterminated
Filename: "{app}\server\node-x86\npm.cmd"; Parameters: "install"; WorkingDir: "{app}\server"; Check: not IsWin64; StatusMsg: "Installing server Node dependencies..."; Flags: runhidden waituntilterminated

Filename: "{app}\server\node-x64\node.exe"; Parameters: "server.js"; WorkingDir: "{app}\server"; Check: IsWin64; StatusMsg: "Starting POS server (64-bit)..."; Flags: runhidden nowait

Filename: "{app}\server\node-x86\node.exe"; Parameters: "server.js"; WorkingDir: "{app}\server"; Check: not IsWin64; StatusMsg: "Starting POS server (32-bit)..."; Flags: runhidden nowait

Filename: "{cmd}"; Parameters: "/c echo cd /d ""{app}\server"" ^&^& ""{app}\server\node-x64\node.exe"" server.js > ""{userstartup}\zaad_server.bat"""; Check: IsWin64; StatusMsg: "Configuring auto-start..."; Flags: runhidden
Filename: "{cmd}"; Parameters: "/c echo cd /d ""{app}\server"" ^&^& ""{app}\server\node-x86\node.exe"" server.js > ""{userstartup}\zaad_server.bat"""; Check: not IsWin64; StatusMsg: "Configuring auto-start..."; Flags: runhidden

Filename: "{app}\pos.exe"; Description: "Launch Zaad POS"; Flags: nowait postinstall skipifsilent

[Code]

function ExecVcRedist(const ExePath: string): Boolean;
var
  Code: Integer;
begin
  Result := True;
  if not FileExists(ExePath) then
  begin
    Log('VC++ Redistributable not bundled: ' + ExePath);
    Exit;
  end;
  if Exec(ExePath, '/install /quiet /norestart', '', SW_HIDE,
          ewWaitUntilTerminated, Code) then
    Result := (Code = 0) or (Code = 3010) or (Code = 1638)
  else
    Result := False;
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssPostInstall then
  begin
    if IsWin64 then
      ExecVcRedist(ExpandConstant('{tmp}\vc_redist.x64.exe'))
    else
      ExecVcRedist(ExpandConstant('{tmp}\vc_redist.x86.exe'));
  end;
end;

set PATH=C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.15.26726\bin\HostX86\x86;C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\Common7\IDE;C:\Program Files (x86)\Windows Kits\10\bin;C:\D\dmd2\windows\bin;%PATH%
"C:\Program Files (x86)\VisualD\pipedmd.exe" -deps "Win32\Debug LDC\RogueDServer.dep" dmd -g -gf -debug -X -Xf"Win32\Debug LDC\RogueDServer.json" -I..\RogueDBase -c -of"Win32\Debug LDC\RogueDServer.obj" GameInstance.d RogueDServer.d Server.d
if %errorlevel% neq 0 goto reportError

set LIB="C:\D\dmd2\windows\bin\..\lib"
echo. > C:\Users\Leszek\source\repos\RogueD\ROGUED~3\Win32\DEBUGL~1\ROGUED~1.RSP
echo "Win32\Debug LDC\RogueDServer.obj","Win32\Debug LDC\RogueDServer.exe","Win32\Debug LDC\RogueDServer.map",user32.lib+ >> C:\Users\Leszek\source\repos\RogueD\ROGUED~3\Win32\DEBUGL~1\ROGUED~1.RSP
echo kernel32.lib/NOMAP/CO/NOI/DELEXE /SUBSYSTEM:CONSOLE >> C:\Users\Leszek\source\repos\RogueD\ROGUED~3\Win32\DEBUGL~1\ROGUED~1.RSP

"C:\Program Files (x86)\VisualD\pipedmd.exe" -deps "Win32\Debug LDC\RogueDServer.lnkdep" C:\D\dmd2\windows\bin\link.exe @C:\Users\Leszek\source\repos\RogueD\ROGUED~3\Win32\DEBUGL~1\ROGUED~1.RSP
if %errorlevel% neq 0 goto reportError
if not exist "Win32\Debug LDC\RogueDServer.exe" (echo "Win32\Debug LDC\RogueDServer.exe" not created! && goto reportError)

goto noError

:reportError
echo Building Win32\Debug LDC\RogueDServer.exe failed!

:noError

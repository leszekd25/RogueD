set PATH=C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Tools\MSVC\14.15.26726\bin\HostX86\x86;C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\Common7\IDE;C:\Program Files (x86)\Windows Kits\10\bin;C:\D\dmd2\windows\bin;%PATH%

echo utility\ConIO.d >"Win32\Release LDC\RogueDBase.build.rsp"
echo utility\Geometry.d >>"Win32\Release LDC\RogueDBase.build.rsp"
echo utility\IntMath.d >>"Win32\Release LDC\RogueDBase.build.rsp"
echo Cell.d >>"Win32\Release LDC\RogueDBase.build.rsp"
echo Connections.d >>"Win32\Release LDC\RogueDBase.build.rsp"
echo Entity.d >>"Win32\Release LDC\RogueDBase.build.rsp"
echo Level.d >>"Win32\Release LDC\RogueDBase.build.rsp"
echo Messages.d >>"Win32\Release LDC\RogueDBase.build.rsp"
echo Player.d >>"Win32\Release LDC\RogueDBase.build.rsp"
echo RogueDBase.d >>"Win32\Release LDC\RogueDBase.build.rsp"

"C:\Program Files (x86)\VisualD\pipedmd.exe" -deps "Win32\Release LDC\RogueDBase.dep" dmd -O -inline -release -X -Xf"Win32\Release LDC\RogueDBase.json" -c -of"Win32\Release LDC\RogueDBase.obj" @"Win32\Release LDC\RogueDBase.build.rsp"
if %errorlevel% neq 0 goto reportError

set LIB="C:\D\dmd2\windows\bin\..\lib"
echo. > C:\Users\Leszek\source\repos\RogueD\ROGUED~1\Win32\RELEAS~1\ROGUED~1.RSP
echo "Win32\Release LDC\RogueDBase.obj","Win32\Release LDC\RogueDBase.exe","Win32\Release LDC\RogueDBase.map",user32.lib+ >> C:\Users\Leszek\source\repos\RogueD\ROGUED~1\Win32\RELEAS~1\ROGUED~1.RSP
echo kernel32.lib/NOMAP/NOI/DELEXE /SUBSYSTEM:CONSOLE >> C:\Users\Leszek\source\repos\RogueD\ROGUED~1\Win32\RELEAS~1\ROGUED~1.RSP

"C:\Program Files (x86)\VisualD\pipedmd.exe" -deps "Win32\Release LDC\RogueDBase.lnkdep" C:\D\dmd2\windows\bin\link.exe @C:\Users\Leszek\source\repos\RogueD\ROGUED~1\Win32\RELEAS~1\ROGUED~1.RSP
if %errorlevel% neq 0 goto reportError
if not exist "Win32\Release LDC\RogueDBase.exe" (echo "Win32\Release LDC\RogueDBase.exe" not created! && goto reportError)

goto noError

:reportError
echo Building Win32\Release LDC\RogueDBase.exe failed!

:noError

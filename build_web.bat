@echo off


if "%EMSCRIPTEN_SDK_DIR%"=="" set EMSCRIPTEN_SDK_DIR=%EMSDK%

set OUT_DIR=build\web
if not exist %OUT_DIR% mkdir %OUT_DIR%

set EMSDK_QUIET=1
call "%EMSCRIPTEN_SDK_DIR%\emsdk_env.bat"

odin build source\main_web -target:js_wasm32 -build-mode:obj -define:RAYLIB_WASM_LIB=env.o -define:RAYGUI_WASM_LIB=env.o -define:R3D_WASM_LIB=env.o -out:%OUT_DIR%\game.wasm.o
IF %ERRORLEVEL% NEQ 0 exit /b 1

for /f "delims=" %%i in ('odin root') do set "ODIN_PATH=%%i"

copy "%ODIN_PATH%\core\sys\wasm\js\odin.js" "%OUT_DIR%"

set files=%OUT_DIR%\game.wasm.o "%ODIN_PATH%\vendor\raylib\wasm\libraylib.a" "%ODIN_PATH%\vendor\raylib\wasm\libraygui.a"

set flags=-sEXPORTED_RUNTIME_METHODS=['HEAPF32','HEAPF64','HEAP_DATA_VIEW','HEAP8','HEAP16','HEAP32','HEAPU8','HEAPU16','HEAPU32','stringToNewUTF8'] -sEXPORTED_FUNCTIONS=['_malloc','_free','_main'] -sINITIAL_MEMORY=67108864 --shell-file source\main_web\index_template.html

emcc %files% -o %OUT_DIR%\index.html %flags%
IF %ERRORLEVEL% NEQ 0 exit /b 1

echo Web build created in %OUT_DIR%
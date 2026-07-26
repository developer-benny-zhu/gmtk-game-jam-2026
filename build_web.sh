#!/bin/bash -eu

EMSCRIPTEN_SDK_DIR="${EMSCRIPTEN_SDK_DIR:-${EMSDK:-$HOME/repos/emsdk}}"
OUT_DIR="build/web"

mkdir -p $OUT_DIR

export EMSDK_QUIET=1
[[ -f "$EMSCRIPTEN_SDK_DIR/emsdk_env.sh" ]] && . "$EMSCRIPTEN_SDK_DIR/emsdk_env.sh"

odin build source/main_web -target:js_wasm32 -build-mode:obj -define:RAYLIB_WASM_LIB=env.o -define:RAYGUI_WASM_LIB=env.o -define:R3D_WASM_LIB=env.o -out:$OUT_DIR/game.wasm.o

ODIN_PATH=$(odin root)

cp $ODIN_PATH/core/sys/wasm/js/odin.js $OUT_DIR

files="$OUT_DIR/game.wasm.o ${ODIN_PATH}/vendor/raylib/wasm/libraylib.a ${ODIN_PATH}/vendor/raylib/wasm/libraygui.a"

flags="-sEXPORTED_RUNTIME_METHODS=['HEAPF32','HEAPF64','HEAP_DATA_VIEW','HEAP8','HEAP16','HEAP32','HEAPU8','HEAPU16','HEAPU32','stringToNewUTF8'] -sEXPORTED_FUNCTIONS=['_malloc','_free','_main'] -sINITIAL_MEMORY=67108864 --shell-file source/main_web/index_template.html"

emcc $files -o $OUT_DIR/index.html $flags

echo "Web build created in ${OUT_DIR}"
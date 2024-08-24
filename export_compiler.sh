#!/bin/bash

out=`realpath $1`
cd `dirname "$0"`/src/js

rm final.js
cat >> final.js <<EOF
export default (function(ogConsoleLog) {
// Miscellaneous globals defined by puzzlescript
let colorPalettesAliases, colorPalettes, forceRegenImages, lastDownTarget;
let canvasResize = () => {}
let consolePrint = () => {}
let consoleError = () => {}
let clearInputHistory = () => {}
let killAudioButton = () => {}
let consoleCacheDump = () => {}
let canDump = false
let canSetHTMLColors = false
let IDE = false
let window = {}
let canvas = {}
window.canvas = canvas
let console = {
    log: () => {}
}
window.console = console
let document = {}
let elements = {}
document.getElementById = (id) => {
    if (!elements[id]) elements[id] = {"innerHTML": ""}
    return elements[id]
}

// Puzzlescript+
let loadedCustomFont;
EOF

cat storagewrapper.js >> final.js
cat globalVariables.js >> final.js
# cat debug_off.js >> final.js
cat font.js >> final.js
cat rng.js >> final.js
# cat riffwave.js >> final.js
# cat sfxr.js >> final.js
cat codemirror/stringstream.js >> final.js
cat >> final.js <<EOF
window.CodeMirror = CodeMirror
EOF
cat colors.js >> final.js
# cat graphics.js >> final.js
cat engine.js >> final.js
cat parser.js >> final.js
cat compiler.js | sed 's/setGameState/debugGameState/g' >> final.js
cat ../../extra_commands.js >> final.js

cat >> final.js <<EOF
delete CellPattern.prototype.toJSON
let storedByDebugGameState = null;
let debugGameState = (state, command, randomseed) => {
    storedByDebugGameState = state;
    // ogConsoleLog(JSON.stringify(state))
}

function recusiveSerialize(state) {
    if (typeof state !== "object" || state == null) return state;
    if (Array.isArray(state)) return state.map(x => recusiveSerialize(x))

    if (typeof state.toJSON !== "undefined") return state.toJSON()
    var toret = {};
    Object.keys(state).map(k => state.hasOwnProperty(k) && (toret[k] = recusiveSerialize(state[k])))
    return toret
}

return function(text) {
    compile(undefined, text);
    if (document.getElementById("errormessage").innerHTML) throw Error(document.getElementById("errormessage"))

    var game = recusiveSerialize(storedByDebugGameState);

    // extra commands
    parseGameTxt(text);
    modifyGame(game);

    return game
}
})(console.log)
EOF

echo $out
mv final.js $out

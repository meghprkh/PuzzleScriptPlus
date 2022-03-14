#!/bin/bash

inp=`realpath $1`
out=`realpath $2`


if command -v node &>/dev/null; then
    JS_RUNTIME="node"
elif command -v deno &>/dev/null; then
    JS_RUNTIME="deno run"
elif command -v qjs &>/dev/null; then
    JS_RUNTIME="qjs"
else
    echo "No JS runtime found in path"
    exit 1
fi

cd `dirname "$0"`/src/js


###########################################
#                BASE JSON                #
###########################################

rm final.js
cat >> final.js <<EOF
// Miscellaneous globals defined by puzzlescript
let colorPalettesAliases, colorPalettes, forceRegenImages, lastDownTarget;
let canvasResize = () => {}
let consolePrint = () => {}
let consoleError = console.error
let clearInputHistory = () => {}
let killAudioButton = () => {}
let consoleCacheDump = () => {}
let canDump = false
let canSetHTMLColors = false
let IDE = false
if (typeof(window) === 'undefined') {
    // quickjs or nodejs
    var window = {}
}
let canvas = {}
window.canvas = canvas
let ogConsoleLog = console.log
console.log = () => {}
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

cat >> final.js <<EOF
delete CellPattern.prototype.toJSON
let debugGameState = (state, command, randomseed) => {
    ogConsoleLog(JSON.stringify(state))
}

var game = \`
EOF

cat $inp >> final.js

cat >> final.js <<EOF
\`
game = game.substr(1) // Remove newline added at start due to bash
compile("restart", game, 0)
if (document.getElementById("errormessage").innerHTML) console.error(document.getElementById("errormessage"))
EOF

$JS_RUNTIME final.js > $out
rm final.js


###########################################
#              EXTRA COMMANDS             #
###########################################

rm extra_commands_final.js
cat ../../extra_commands.js >> extra_commands_final.js
cat >> extra_commands_final.js << EOF
var game_txt = \`
EOF
cat $inp >> extra_commands_final.js
cat >> extra_commands_final.js <<EOF
\`
var game = \`
EOF
sed -i 's/\\/\\\\/g' $out
cat $out >> extra_commands_final.js
cat >> extra_commands_final.js <<EOF
\`
game_txt = game_txt.substring(1)
game = JSON.parse(game)
parseGameTxt(game_txt)
modifyGame(game)
console.log(JSON.stringify(game))
EOF

$JS_RUNTIME extra_commands_final.js > $out
rm extra_commands_final.js


###########################################
#              PRETTIFY JSON              #
###########################################

if command -v prettier &>/dev/null; then
    prettier --write $out
else
    echo "Prettier not found. Could not format $2"
fi

// line number to extra commands
let extra_commands = {}

function parseExtraCommands(comment) {
    return comment
      .split("#")
      .filter((x) => !!x)
      .map((x) => [
        x.substring(0, x.indexOf(" ")).trim(),
        x.substring(x.indexOf(" ")).trim(),
      ]);
  }

function parseGameTxt(game_txt) {
    let state = "pre_rules"
    let lines = game_txt.split("\n")
    for (let lineNo = 1; lineNo <= lines.length; lineNo++) {
        let line = lines[lineNo - 1]
        if (line.trim() === "RULES") state = "rules"
        if (line.trim() === "WINCONDITIONS" && state === "rules") break
        if (state != "rules") continue

        const match = line.match(/\(([^\(\)]*)\)\s*$/)
        if (match) {
            extra_commands[lineNo] = parseExtraCommands(match[1])
        }
    }
}

function modifyGame(game) {
    game.rules = game.rules.map(ruleGroup => ruleGroup.map(rule => {
        const lineNo = rule[3]
        const commandsIndex = 7

        if (extra_commands[lineNo]) {
            rule[commandsIndex] = [...rule[commandsIndex], ...extra_commands[lineNo]]
        }

        return rule
    }))

    return game
}

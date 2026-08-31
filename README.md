# StarCustomChat: Roleplay

This plugin for [StarCustomChat](https://github.com/KrashV/StarCustomChat) is dedicated to the roleplay aspects of the game. It consists of the following modules:

## Edit message
You can edit the message using the context menu. The changes will only be seen by the players on the same planet as you.

## Proximity chat
You can specify the stagehand that would receive the message and then resend it to people around, or you can skip the stagehand and send the message around your character. 
![Proximity chat showcase](https://i.imgur.com/fbnNKF0.png)
*Obviously, only people with the mod installed will receive this message*

## OOC chat
A simple tab that automatically adds double brackets around your message (( )). Also places the OOC messages in a separate channel which you can turn off.
![OOC chat showcase](https://i.imgur.com/AeTFO7a.png)


## RP Chat

This plugin brings an ability to color the \*Actions* and %Thoughts% within messsages into custom, user-specific colors.

![RP Color Codes showcase](https://i.imgur.com/ZXh5DKo.png)

Also, people with the Admin permissions can fire an Announcement message in your face, that will ignore all your filters and will have the scary red color.

![I came to make an announcement](https://i.imgur.com/PLWKb4a.png)

*Now you can truly make an announcement about what exactly Shadow the Hedgehog did to your wife*

## RP Languages

> This requires Starbound server administrators to set up the language support on their side

> People without the mod will see the normal message - with some extra spaces in it - when you use this functionality.

You can specify the language your character will be speaking in "Quotation marks", so that the characters who don't know this language might find it hard to read.

![RP Languages](https://i.imgur.com/FxM7l4p.png)


### Stagehand example

#### editmessage.json.patch

Should be located at "/interface/scripted/starcustomchat/plugins/languages/languages.json.patch" and contain the following:

```diff
[
  { "op": "replace", "path": "/parameters/stagehandType", "value": "STAGEHAND_NAME"}
]
```

#### myserverchatstagehand.lua

The code is very similar to the description in [StarCustomChat](https://github.com/KrashV/StarCustomChat?tab=readme-ov-file#stagehand-configuration):

```lua
function init()
  local purpose = config.getParameter("message")
  local data = config.getParameter("data")
  if purpose == "retrieveLanguages" then
    sendToPlayer(data.playerId, root.assetJson("/your/path/to/the/languages/json/file"))
  end
end
```

The example of the json file is provided below.  Note that a new `transformation` section may be supplied for
fine‑grained control over how a message is mangled depending on
player proficiency; the old `difficulty`/`specialCharacters` fields are
still supported and will be converted into a simple shuffle rule for
backwards compatibility.

```json
{
    "CoolServ_DR": {
      "name": "Draconic",
      "difficulty": 3,
      "prefix": "🐉",
      "description": "Language of dragons, kobolds and other liz-zards",
      "transformation": {
        "rules": [
          {
            "knowledgeThreshold": 0.0,
            "strategy": "shuffle",
            "specialCharacters": ["ç","ñ"],
            "onlySpecialCharacters": true,
            "shuffleIntensity": 1
          },
          {
            "knowledgeThreshold": 0.5,
            "strategy": "substitute",
            "map": {"a":"@","e":"3","o":"0"}
          },
          {
            "knowledgeThreshold": 0.8,
            "strategy": "drop",
            "dropRate": 0.3,
            "dropChars": ["a", "e", "i", "o", "u"]
          },
          {
            "knowledgeThreshold": 0.9,
            "strategy": "repeat",
            "repeatRate": 0.2,
            "repeatChars": ["s", "t", "r"]
          },
          {
            "knowledgeThreshold": 0.95,
            "strategy": "chain",
            "steps": [
              {"strategy": "substitute", "map": {"a":"@", "e":"3"}},
              {"strategy": "drop", "dropRate": 0.5, "dropChars": ["@"]}
            ]
          },
          {
            "knowledgeThreshold": 1.0,
            "strategy": "none"
          }
        ]
      }
    },
    "CoolServ_EL": {
      "name": "Elvish",
      "difficulty": 5
    },
    "CoolServ_AF": {
      "name": "Infernal",
      "directives": "^#FF0000;^shadow;",
      "difficulty": 10,
      "specialCharacters": ["ç", "ñ", "ß", "ø", "å", "æ", "œ", "ý", "ÿ"],
      "transformation": {
        "rules": [
          {
            "knowledgeThreshold": 0.0,
            "strategy": "shuffle",
            "shuffleIntensity": 0.75
          },
          {
            "knowledgeThreshold": 0.8,
            "strategy": "substitute",
            "map": {"x":"×","z":"ʐ"}
          }
        ]
      }
    },
    "CoolServ_CO": {
      "name": "Common",
      "difficulty": 0
    }
}
```
* **Key** [Mandatory] - A unique language code. It must be unique not only within one server but across all servers. Users will not see this directly.
* **Name** [Mandatory] - The name of the language displayed to the user.
* **Description** [Optional] - A description of the language that appears on the settings tab.
* **Prefix** [Optional] - The prefix that will be appended to the translated message, to better distinguish it from the regular language.
* **Color** [Optional] - The colour of the translated text.
* **Font** [Optional] - The font of the translated text.
* **Directives** [Optional] - The directives applied to the text. It is applied after the **Color** and **Font**.
* **Difficulty** [Optional] - The number of increments of "learning" (*pressing the "up" button on the knowledge spinner*) required to learn the language. If omitted, the default value is `1`. A value of `0` means the language is known to everyone and does not require learning.
* **SpecialCharacters** [Optional] - A list of characters that can appear in the message, beyond the standard ASCII alphabet.  This is preserved for compatibility and affects the default shuffle strategy when no explicit transformation is provided.
* **Transformation** [Optional] - An object containing a `rules` array.  Each rule defines a `knowledgeThreshold` (fraction of difficulty, between 0 and 1) and a `strategy` (`shuffle`, `substitute`, `none`, etc.).
  Rules are evaluated in ascending order; the first one whose threshold is
  greater than or equal to the player's current knowledge fraction is used.
  See the section above for a complete description.

### Advanced transformation rules

Server administrators can now craft complex degradation behaviour by stacking
multiple rules.  For example, a language might use complete word obfuscation
when the player has no familiarity, gradually switch to simple character
substitutions at mid‑levels and finally show the clear text when the player
is fluent.

Supported strategies currently include:

* `shuffle` – randomly jumbles whole words.  Accepts `specialCharacters` and
  `shuffleIntensity` parameters identical to the legacy system.
* `substitute` – performs a character-by-character replacement using a
  supplied `map` table.
* `drop` – randomly removes letters from words. Accepts a `dropRate` parameter
  (number between 0 and 1, default 0.5) specifying the fraction of letters to drop,
  and optionally a `dropChars` array to limit dropping to specific characters only.
* `repeat` – randomly duplicates letters in words. Accepts a `repeatRate` parameter
  (number between 0 and 1, default 0.3) specifying the chance per letter to repeat,
  and optionally a `repeatChars` array to limit repeating to specific characters only.
* `chain` – applies a sequence of other strategies in order. Accepts a `steps` array,
  where each step is an object with `strategy` and its parameters (e.g., `{"strategy": "substitute", "map": {...}}`).
* `none` – leaves the text untouched (typically used at the top of the rule
  list).

Future strategies may be added; unknown strategies are ignored, ensuring
older clients continue to function even if they download a configuration
that includes new methods.

Administrators should create the JSON file referenced by the stagehand and
place it on the server filesystem.  The standard stagehand example above
already handles the `retrieveLanguages` message, so no changes are required to
the Lua stagehand code when adding transformation rules.



--[[
  Transformation system

  The server can define a `transformation` section for each language taking one of
  two forms:

  1. Simple parameters (legacy behaviour, preserved for compatibility):
     {
       difficulty = 3,
       specialCharacters = {"å", "æ"},
     }

     This still feeds into the default "shuffle" strategy used previously.

  2. Detailed rules list:
     "transformation": {
       "rules": [
         {
           "knowledgeThreshold": 0.0,          -- fraction in [0,1]
           "strategy": "shuffle",           -- shuffle, substitute, none, custom etc.
           "specialCharacters": true,         -- only for shuffle
           "shuffleIntensity": 1              -- optional override
         },
         {
           "knowledgeThreshold": 0.5,
           "strategy": "substitute",
           "map": {"a":"@", "b":"8"}
         },
         {
           "knowledgeThreshold": 1.0,
           "strategy": "none"
         }
       ]
     }

  The client will select the first rule whose threshold is >= knowledge fraction,
  giving admins precise control over how sentences degrade as the player learns
  the language.  Strategies beyond the builtin ones can be added here later.
]]

-- helpers for the new transformation system
function pickRuleForFraction(rules, fraction)
  if not rules or #rules == 0 then return nil end

  table.sort(rules, function(a, b)
    return (a.knowledgeThreshold or 0) < (b.knowledgeThreshold or 0)
  end)

  -- Pick the rule with the highest threshold that is still <= player knowledge
  local chosen = nil
  for _, rule in ipairs(rules) do
    if (rule.knowledgeThreshold or 0) <= fraction then
      chosen = rule
    end
  end
  return chosen
end

function applyShuffle(content, shuffleIntensity, specialCharacters, onlySpecialCharacters)
  local obfuscatedContent = {}
  for word in content:gmatch("%S+") do
    if math.random() < shuffleIntensity then
      local obfuscatedWord = obfuscateWord(word, specialCharacters, onlySpecialCharacters)
      table.insert(obfuscatedContent, obfuscatedWord)
    else
      table.insert(obfuscatedContent, word)
    end
  end
  return table.concat(obfuscatedContent, " ")
end

function applySubstitution(content, map)
  if not map or next(map) == nil then
    return content
  end

  local substituted = {}
  for i, c in utf8.codes(content) do
    local char = utf8.char(c)
    char = map[char] or char
    table.insert(substituted, char)
  end

  return table.concat(substituted)
end

function applyDrop(content, dropRate, dropChars)
  if not dropRate or dropRate <= 0 then
    return content
  end

  local charSet = starcustomchat.utils.listToSet(dropChars)

  local dropped = {}
  for word in content:gmatch("%S+") do
    local newWord = {}
    for i, c in utf8.codes(word) do
      local char = utf8.char(c)

      if #dropChars == 0 or not charSet[char] or math.random() > dropRate then
        table.insert(newWord, char)
      end
    end
    table.insert(dropped, table.concat(newWord))
  end

  return table.concat(dropped, " ")
end

function applyRepeat(content, repeatRate, repeatChars)
  if not repeatRate or repeatRate <= 0 then
    return content
  end

  local charSet = starcustomchat.utils.listToSet(repeatChars)

  local repeated = {}
  for word in content:gmatch("%S+") do
    local newWord = {}
    for i, c in utf8.codes(word) do
      local char = utf8.char(c)
      table.insert(newWord, char)
      if (#repeatChars == 0 or charSet[char]) and math.random() < repeatRate then
        table.insert(newWord, char)  -- repeat the letter
      end
    end
    table.insert(repeated, table.concat(newWord))
  end

  return table.concat(repeated, " ")
end


function transformContent(content, rule)

  if rule.strategy == "shuffle" then
    return applyShuffle(content, rule.shuffleIntensity, rule.specialCharacters or {}, rule.onlySpecialCharacters)
  elseif rule.strategy == "substitute" then
    return applySubstitution(content, rule.map)
  elseif rule.strategy == "drop" then
    return applyDrop(content, rule.dropRate, rule.dropChars or {})
  elseif rule.strategy == "repeat" then
    return applyRepeat(content, rule.repeatRate, rule.repeatChars or {})
  elseif rule.strategy == "chain" then
    for _, subrule in ipairs(rule.steps) do 
      content = transformContent(content, subrule)
    end
    return content
  else
    -- unrecognised strategy: fall back to raw text so nothing breaks
    return content
  end
end


function applyTransformation(content, myLevel, langConfig)
  -- difficulty 0 means nobody needs transformation
  local difficulty = langConfig.difficulty or 1
  if difficulty == 0 then
    return content
  end

  myLevel = myLevel or 0
  local fraction = math.min(myLevel / difficulty, 1)

  -- legacy path: if there is no explicit transformation.rules, pretend we have
  -- a single shuffle rule using old behaviour so that existing server files
  -- continue to work.
  local rule
  if langConfig.transformation and langConfig.transformation.rules then
    rule = pickRuleForFraction(langConfig.transformation.rules, fraction)
  else
    -- build a synthetic rule for backwards compatibility
    rule = {
      strategy = "shuffle",
      specialCharacters = langConfig.specialCharacters,
      shuffleIntensity = 1 - fraction,
      difficulty = difficulty
    }
  end

  if not rule or rule.strategy == "none" then
    return content
  end

  return transformContent(content, rule)
end

function shuffleFunction(content, myLevel, difficulty, specialCharacters)
  -- old API kept for compatibility; delegate to the new system using a
  -- synthetic configuration object.
  local fakeConfig = {
    difficulty = difficulty or 1,
    specialCharacters = specialCharacters
  }
  return applyTransformation(content, myLevel, fakeConfig)
end

function obfuscateWord(word, specialCharacters, onlyPassedSpecialChars)
  local obfuscatedWord = {}
  local similarCharacters = {
    -- Lowercase English
    ["a"] = "@", ["b"] = "8", ["c"] = "(", ["d"] = "|)", ["e"] = "3", ["f"] = "ph", ["g"] = "9", ["h"] = "#", ["i"] = "!", 
    ["j"] = ";", ["k"] = "|<", ["l"] = "1", ["m"] = "/\\/\\", ["n"] = "|\\|", ["o"] = "0", ["p"] = "|*", ["q"] = "9", 
    ["r"] = "2", ["s"] = "$", ["t"] = "+", ["u"] = "|_|", ["v"] = "\\/", ["w"] = "\\/\\/", ["x"] = "%", ["y"] = "`/", ["z"] = "2",
  
    -- Uppercase English
    ["A"] = "@", ["B"] = "8", ["C"] = "(", ["D"] = "|)", ["E"] = "3", ["F"] = "PH", ["G"] = "9", ["H"] = "#", ["I"] = "!", 
    ["J"] = ";", ["K"] = "|<", ["L"] = "1", ["M"] = "/\\/\\", ["N"] = "|\\|", ["O"] = "0", ["P"] = "|*", ["Q"] = "9", 
    ["R"] = "2", ["S"] = "$", ["T"] = "+", ["U"] = "|_|", ["V"] = "\\/", ["W"] = "\\/\\/", ["X"] = "%", ["Y"] = "`/", ["Z"] = "2",
  
    -- Lowercase Russian
    ["а"] = "@", ["б"] = "6", ["в"] = "B", ["г"] = "r", ["д"] = "g", ["е"] = "3", ["ё"] = "e", ["ж"] = "X", ["з"] = "3", 
    ["и"] = "u", ["й"] = "u~", ["к"] = "k", ["л"] = "JI", ["м"] = "M", ["н"] = "H", ["о"] = "0", ["п"] = "n", ["р"] = "p", 
    ["с"] = "c", ["т"] = "T", ["у"] = "y", ["ф"] = "o", ["х"] = "x", ["ц"] = "u", ["ч"] = "4", ["ш"] = "w", ["щ"] = "w~", 
    ["ъ"] = "b", ["ы"] = "bl", ["ь"] = "b", ["э"] = "3", ["ю"] = "10", ["я"] = "R",
  
    -- Uppercase Russian
    ["А"] = "@", ["Б"] = "6", ["В"] = "B", ["Г"] = "r", ["Д"] = "g", ["Е"] = "3", ["Ё"] = "E", ["Ж"] = "X", ["З"] = "3", 
    ["И"] = "U", ["Й"] = "U~", ["К"] = "K", ["Л"] = "JI", ["М"] = "M", ["Н"] = "H", ["О"] = "0", ["П"] = "N", ["Р"] = "P", 
    ["С"] = "C", ["Т"] = "T", ["У"] = "Y", ["Ф"] = "O", ["Х"] = "X", ["Ц"] = "U", ["Ч"] = "4", ["Ш"] = "W", ["Щ"] = "W~", 
    ["Ъ"] = "B", ["Ы"] = "BL", ["Ь"] = "B", ["Э"] = "3", ["Ю"] = "10", ["Я"] = "R"
  }

  for i, c in utf8.codes(word) do
    local char = utf8.char(c)
    if not char:match("[%s%p%c]") then
      -- Replace with a visually similar character or random special character
      if math.random() < 0.5 and not onlyPassedSpecialChars then
        char = similarCharacters[char] or char
      else
        char = getRandomCharacter(specialCharacters, onlyPassedSpecialChars)
      end
    end
    table.insert(obfuscatedWord, char)
  end

  return table.concat(obfuscatedWord)
end


function getRandomCharacter(specialCharacters, onlyPassedSpecialChars)
    if onlyPassedSpecialChars then
        return specialCharacters[math.random(#specialCharacters)]
    else
        local randomChars = {
            "A", "a", "B", "b", "C", "c", "D", "d", "E", "e", "F", "f", "G", "g", "H", "h",
            "I", "i", "J", "j", "K", "k", "L", "l", "M", "m", "N", "n", "O", "o", "P", "p",
            "Q", "q", "R", "r", "S", "s", "T", "t", "U", "u", "V", "v", "W", "w", "X", "x",
            "Y", "y", "Z", "z", "'", table.unpack(specialCharacters)
        }
        return randomChars[math.random(#randomChars)]
    end
end

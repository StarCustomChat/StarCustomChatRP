require "/interface/scripted/starcustomchat/plugin.lua"
require "/interface/scripted/starcustomchat/plugins/languages/languageUtils.lua"

languages = PluginClass:new(
  { name = "languages" }
)

function languages:init(chat)
  PluginClass.init(self, chat)

  widget.setButtonEnabled("lytLeftMenu.saButtons.btnSelectRPLanguage", false)
  self.defaultLi = ""
  self.languagesLevels = player.getProperty("scc_rp_languages", {})
  self.serverLanguagesData = nil
end

function languages:registerStagehandHandlers(handlers)
  if handlers and handlers["retrieveLanguages"] then
    starcustomchat.utils.createStagehandWithData(self.stagehandType, {
      message = "retrieveLanguages",
      data = {
        playerId = player.id()
      }
    })
  end
end

function languages:registerMessageHandlers()

  starcustomchat.utils.setMessageHandler( "scc_rp_languages", function(_, _, serverLanguagesData)
    if serverLanguagesData then
      self.serverLanguagesData = serverLanguagesData
      widget.setButtonEnabled("lytLeftMenu.saButtons.btnSelectRPLanguage", true)
      widget.setData("lytLeftMenu.saButtons.btnSelectRPLanguage", {
        displayText = "chat.buttons.language"
      })
      self:populateLanguageList()
    end
  end)
end

function languages:openSettings(settingsInterface)
  settingsInterface.serverLanguagesData = self.serverLanguagesData
end

function languages:populateLanguageList()
  widget.clearListItems("lytSelectLanguage.saLanguages.listChatLanguages")

  self.defaultLi = widget.addListItem("lytSelectLanguage.saLanguages.listChatLanguages")
  widget.setText("lytSelectLanguage.saLanguages.listChatLanguages." .. self.defaultLi .. ".name", starcustomchat.utils.getTranslation("chat.language.disabled"))

  local foundSelected = false
  for code, langConfig in pairs(self.serverLanguagesData) do 
    local li = widget.addListItem("lytSelectLanguage.saLanguages.listChatLanguages")

    local difficulty = self.serverLanguagesData[code].difficulty or 1
    local percProf
    if difficulty == 0 then
      percProf = 100
    else
      percProf = (self.languagesLevels[code] and self.languagesLevels[code].knowledge or 0) / difficulty * 100
    end

    local data = {
      code = code,
      displayPlainText = (langConfig.description and langConfig.description .. " " or "") .. starcustomchat.utils.getTranslation("tooltips.languages.proficiency", string.format("%.0f%%", percProf))
    }
    
    widget.setProgress("lytSelectLanguage.saLanguages.listChatLanguages." .. li .. ".lagnuageProgress", percProf / 100)
    widget.setText("lytSelectLanguage.saLanguages.listChatLanguages." .. li .. ".name", langConfig.name)
    widget.setData("lytSelectLanguage.saLanguages.listChatLanguages." .. li, data)
    widget.setData("lytSelectLanguage.saLanguages.listChatLanguages." .. li .. ".background", data)
    
    if code == self.selectedLanguage then
      widget.setListSelected("lytSelectLanguage.saLanguages.listChatLanguages", li)
      foundSelected = true
    end
  end
  
  -- Only select default if we didn't find the previously selected language
  if not foundSelected then
    widget.setListSelected("lytSelectLanguage.saLanguages.listChatLanguages", self.defaultLi)
  end
end

function languages:formatIncomingMessage(message)

  if self.serverLanguagesData and message.text and message.data and message.data.SCCRPLanguageCode then
    math.randomseed(tonumber(message.uuid))
    local code = message.data.SCCRPLanguageCode
    local languageConfig = self.serverLanguagesData[code]

    local hasContent = false
    message.text = message.text:gsub('%b""', function(quoted)
      hasContent = true
      local content = quoted:sub(2, -2)
      local knowledge = self.languagesLevels[code] and self.languagesLevels[code].knowledge or 0
      content = applyTransformation(content, languageConfig and knowledge, languageConfig)
      content = (self.serverLanguagesData[code].prefix and self.serverLanguagesData[code].prefix .. " " or "") .. content

      local languageStyle = (self.serverLanguagesData[code].color and ("^" .. self.serverLanguagesData[code].color .. ";") or "") .. 
        (self.serverLanguagesData[code].font and ("^font=" .. self.serverLanguagesData[code].font .. ";") or "") .. 
        (self.serverLanguagesData[code].directives or "")

      return '"' .. starcustomchat.utils.styleText(message, languageStyle, content) .. '"'
    end)

    if not hasContent then
      message.data.SCCRPLanguageName = nil
      message.data.SCCRPLanguageCode = nil
    end
  end

  math.randomseed(os.time())
  return message
end

function languages:onCreateTooltip(screenPosition)
  local selectedMessage = self.customChat:selectMessage(screenPosition)
  if selectedMessage and selectedMessage.data and selectedMessage.data.SCCRPLanguageName then
    return starcustomchat.utils.getTranslation("tooltips.languages.name", selectedMessage.data.SCCRPLanguageName)
  end
end

function languages:formatOutcomingMessage(message)
  if self.serverLanguagesData and self.selectedLanguage and message.text then
    local originalText = message.text
    local hasContent = false

    local transformedText = originalText:gsub('%b""', function(quoted)
      hasContent = true
      -- when echoing to self we always treat the language as fully unknown
      return applyTransformation(quoted, 0, self.serverLanguagesData[self.selectedLanguage] or {})
    end)

    if hasContent then
      message.data = message.data or {} 
      message.data.SCCRPLanguageCode = self.selectedLanguage
      message.data.SCCRPLanguageName = self.serverLanguagesData[self.selectedLanguage].name

      message.silent = true
      if message.mode ~= "Whisper" then
        player.say(transformedText)
      end
    end
  end
  return message
end

function languages:onSettingsUpdate(data)
  self.languagesLevels = player.getProperty("scc_rp_languages", {})
  if self.serverLanguagesData then
    self:populateLanguageList()
  end
end

function languages:onCustomButtonClick(btnName, data)
  if btnName == "btnSelectRPLanguage" then
    widget.setVisible("lytSelectLanguage", not widget.active("lytSelectLanguage"))
  elseif btnName == "listChatLanguages" then
    local li = widget.getListSelected("lytSelectLanguage.saLanguages.listChatLanguages")
    if li then
      local data = widget.getData("lytSelectLanguage.saLanguages.listChatLanguages." .. li)
      if data and data.code then
        local code = data.code
        -- Only proceed if the selection actually changed
        if self.selectedLanguage == code then
          return
        end
        if self.serverLanguagesData and self.serverLanguagesData[code] then
          if (not self.serverLanguagesData[code].difficulty or self.serverLanguagesData[code].difficulty ~= 0) 
          and (not self.languagesLevels[code] or self.languagesLevels[code].knowledge == 0) then
            starcustomchat.utils.alert("chat.alerts.languages.unknown", self.serverLanguagesData[code].name)
            widget.setListSelected("lytSelectLanguage.saLanguages.listChatLanguages", self.defaultLi)
            self.selectedLanguage = nil
          else
            self.selectedLanguage = code
            starcustomchat.utils.alert("chat.alerts.languages.selected", self.serverLanguagesData[code].name)
            widget.setVisible("lytSelectLanguage", false)
          end
        end
      else
        self.selectedLanguage = nil
        widget.setVisible("lytSelectLanguage", false)
      end
    end

    local languageName = self.selectedLanguage and self.serverLanguagesData[self.selectedLanguage].name or nil

    widget.setButtonImages("lytLeftMenu.saButtons.btnSelectRPLanguage", {
      base = string.format("/interface/scripted/starcustomchat/plugins/languages/interface/languages%s.png", self.selectedLanguage and "selected" or ""),
      hover = string.format("/interface/scripted/starcustomchat/plugins/languages/interface/languages%shover.png",  self.selectedLanguage and "selected" or "")
    })

    widget.setData("lytLeftMenu.saButtons.btnSelectRPLanguage", {
      displayText = "chat.buttons.language",
      displayPlainText = languageName
    })

    self:onLocaleChange()
  end
end

function languages:onLocaleChange()
  local hint = starcustomchat.utils.getTranslation("chat.textbox.hint")
  local languageName = self.selectedLanguage and self.serverLanguagesData[self.selectedLanguage].name or nil

  self.customChat:setHint(hint .. (languageName and " (" .. languageName ..")" or ""))
end

function languages:onChatScroll(screenPosition)
  return widget.active("lytSelectLanguage") and widget.inMember("lytSelectLanguage", screenPosition)
end
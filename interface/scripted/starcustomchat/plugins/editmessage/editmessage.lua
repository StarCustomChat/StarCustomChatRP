require "/interface/scripted/starcustomchat/plugin.lua"

editmessage = PluginClass:new(
  { name = "editmessage" }
)

function editmessage:init(chat)
  PluginClass.init(self, chat)
  self.editingMessage = config.getParameter("editingMessage")

  if self.editingMessage then
    local text = string.gsub(self.editingMessage.text, "\n", "    ")
    self.customChat:openSubMenu("edit", starcustomchat.utils.getTranslation("chat.editing.hint"), 
    starcustomchat.utils.cropMessage(text, self.trimLength))
  end

  self.stagehandEnabled = false
end

function editmessage:registerStagehandHandlers(handlers)
  self.stagehandEnabled = handlers and handlers["editMessage"]
end

function editmessage:onLocaleChange()
  if self.editingMessage then
    local text = string.gsub(self.editingMessage.text, "\n", "    ")
    self.customChat:openSubMenu("edit", 
      starcustomchat.utils.getTranslation("chat.editing.hint"), 
      starcustomchat.utils.cropMessage(text, self.trimLength))
  end
end

function editmessage:update(dt)
  if self.editingMessage then
    self.customChat:highlightMessage(self.editingMessage, self.highlightEditColor)
  end
end

function editmessage:onSubMenuReopen(type)
  if type ~= "edit" then
    self.editingMessage = nil
  end
end

function editmessage:onTextboxEnter()
  if self.editingMessage then
    local data = {
      text = self.customChat:getText(),
      uuid = self.editingMessage.uuid,
      connection = self.editingMessage.connection,
      mode = self.editingMessage.mode,
      nickname = self.editingMessage.nickname
    }
    if self.stagehandEnabled and self.stagehandType and self.stagehandType ~= "" then
      starcustomchat.utils.createStagehandWithData(self.stagehandType, {message = "editMessage", data = data})
    else
      for _, pl in ipairs(world.playerQuery(world.entityPosition(player.id()), 100)) do 
        world.sendEntityMessage(pl, "scc_edit_message", data)
      end
    end

    self.customChat:closeSubMenu()
    self.editingMessage = nil
    return true
  end
end

function editmessage:onTextboxEscape()
  if self.editingMessage then
    self.customChat:closeSubMenu()
    self.editingMessage = nil
    return false
  end
end

function editmessage:contextMenuButtonFilter(buttonName, screenPosition, selectedMessage)
  if selectedMessage and buttonName == "edit" and not selectedMessage.image then
    return selectedMessage and starcustomchat.utils.connectionToEntityId(selectedMessage.connection) == player.id() and selectedMessage.uuid and selectedMessage.mode ~= "CommandResult" 
  end
end

function editmessage:contextMenuButtonClick(buttonName, selectedMessage)
  if selectedMessage and buttonName == "edit" then
    self.editingMessage = selectedMessage

    local cleartext = starcustomchat.utils.clearMetatags(selectedMessage.text)
    
    self.customChat:openSubMenu("edit", 
      starcustomchat.utils.getTranslation("chat.editing.hint"), 
      starcustomchat.utils.cropMessage(string.gsub(cleartext, "\n", "    "), self.trimLength))
    self.customChat:focusInput()
    self.customChat:setText(cleartext)
  end
end

function editmessage:processEvents(events)
  for _, event in ipairs(events) do 
    if event.type == "KeyDown" and event.data.key == "Up" then
      if self.customChat:hasFocusInput() and self.customChat:getText() == "" and not self.customChat:getSubMenuType() then
        local myConnection = starcustomchat.utils.entityIdToConnection(player.id())
        local messages = self.customChat:findMessagesByConnection(myConnection)

        if #messages > 0 then
          local selectedMessage = messages[1]

          if selectedMessage and selectedMessage.uuid and selectedMessage.mode ~= "CommandResult" and not selectedMessage.image then
            self.editingMessage = selectedMessage

            local cleartext = starcustomchat.utils.clearMetatags(selectedMessage.text)
            self.customChat:openSubMenu("edit",
              starcustomchat.utils.getTranslation("chat.editing.hint"),
              starcustomchat.utils.cropMessage(string.gsub(cleartext, "\n", "    "), self.trimLength))
            self.customChat:focusInput()
            self.customChat:setText(cleartext)
            self.customChat:scrollToMessage(self.customChat:findMessageByUUID(selectedMessage.uuid), 20)
          end
        end
      end
    end
  end
end

function editmessage:onSubMenuClose(buttonName, data)
  if self.editingMessage then
    self.editingMessage = nil
    self.customChat:blurInput()
    self.customChat:setText("")
  end
end
local Players=game:GetService("Players")
local TextChatService=game:GetService("TextChatService")
local Commands=require(game:GetService("ReplicatedStorage").Shared.Meeseeks.Commands)
local Chat={}
function Chat.start(callback)
 -- TextChatCommand suppresses command messages; arbitrary player text is never echoed by NPCs.
 local reserved={}
 for _,command in TextChatService:GetDescendants() do
  if command:IsA("TextChatCommand") then reserved[command.PrimaryAlias:lower()]=true; reserved[command.SecondaryAlias:lower()]=true end
 end
 local aliases={ms=true,meeseeks=true}
 for alias in Commands.Aliases do aliases[alias]=true end
 for alias in aliases do
  if not reserved["/"..alias] then
   local command=Instance.new("TextChatCommand")
   command.Name,command.PrimaryAlias,command.Parent="Meeseeks_"..alias,"/"..alias,TextChatService
   command.Triggered:Connect(function(source,text)
    local player=source and Players:GetPlayerByUserId(source.UserId)
    if player then callback(player,text) end
   end)
  else warn("Meeseeks chat alias already used: /"..alias.."; use /ms <command>") end
 end
 -- Legacy only: prevents modern chat from issuing every command twice.
 if TextChatService.ChatVersion==Enum.ChatVersion.LegacyChatService then
  local function added(player) player.Chatted:Connect(function(text) callback(player,text) end) end
  Players.PlayerAdded:Connect(added); for _,player in Players:GetPlayers() do added(player) end
 end
end
return Chat

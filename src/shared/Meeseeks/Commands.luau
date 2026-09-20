local Commands = {}
Commands.Aliases = {dance="dance",follow="follow",followme="follow",come="comehere",comehere="comehere",
 stop="stop",jump="jump",wave="wave",sit="sit",point="point",despawn="despawn",attack="attack",kill="attack"}
function Commands.parse(text)
 if type(text) ~= "string" or #text > 120 then return nil end
 local words = {}
 for word in text:lower():gmatch("%S+") do table.insert(words, word) end
 local first = table.remove(words,1)
 if not first or first:sub(1,1) ~= "/" then return nil end
 first = first:sub(2)
 if first == "ms" or first == "meeseeks" then first = table.remove(words,1) end
 local command = Commands.Aliases[first]
 if not command then return nil end
 local rest = table.concat(words," ")
 if rest == "" or ((command == "follow" or command == "comehere") and rest == "me")
  or (command == "attack" and (rest == "person in front of me" or rest == "in front of me" or rest == "target in front of me")) then return command end
 return nil
end
return Commands

local NETMSG_TYPE_BITS = 6        --- skip first 6 bits is this, so just bf:SetCurBit(6) or b f :SetCurBit(NET_MSG_TYPE_BITS)
local NET_TICK_SCALEUP = 100000.0 --- used by net_Tick

--- used by clc_ClientInfo
local MAX_CUSTOM_FILES = 4          -- max 4 files
local MAX_CUSTOM_FILE_SIZE52428 = 8 -- Half a megabyte

--- used by clc_Move
local NUM_NEW_COMMAND_BITS = 4
local MAX_NEW_COMMANDS = ((1 << NUM_NEW_COMMAND_BITS) - 1)       -- 15
local NUM_BACKUP_COMMAND_BITS = 3
local MAX_BACKUP_COMMANDS = ((1 << NUM_BACKUP_COMMAND_BITS) - 1) -- 7

---@enum E_NetMessageTypes
local E_NetMessageTypes = {
   net_NOP = 0,               -- nop command used for padding | Values = none /shrug
   net_Disconnect = 1,        -- disconnect, last message in connection | Values: disconnect reason(?) Read/WriteString(32)
   net_File = 2,              -- file transmission message request/deny | Values: transferId = ReadInt(32)
   net_Tick = 3,              -- send last world tick | skip first 6 bits, Values: m_nTick = ReadInt(32), m_flHostFrameTime = ReadInt(16)/NET_TICK_SCALEUP, m_flHostFrameTimeStdDeviation = ReadInt(16)/NET_TICK_SCALEUP
   net_StringCmd = 4,         -- a string command | skip first 6 bits, Values: m_szCommand = ReadString(32)
   net_SetConVar = 5,         -- sends one/multiple convar settings | skip first 6 bits, Values: numvars = ReadInt(8) -> loop -> for i = 0, numvars do name = ReadString(32) value = ReadString(32) end
   net_SignonState = 6,       -- signals current signon state | skip first 6 bits, Values: m_nSignonState = ReadInt(8), m_nSpawnCount = ReadInt(32)
   clc_ClientInfo = 8,        -- client info (table CRC etc) | skip first 6 bits, Values: m_nServerCount = ReadInt(32), m_nSendTableCRC = ReadInt(32), m_bIsHLTV = ReadBit() == 1 and true or false, m_nFriendsID = ReadInt(32), m_FriendsName = ReadString(32), m_nCustomFiles is a loop -> for i = 1, MAX_CUSTOM_FILES do if bf:ReadBit() > 0 then m_nCustomFiles[i] = ReadInt(32) else m_nCustomFiles[i] = 0 end end
   clc_Move = 9,              -- CUserCmd | skip first 6 bits, Values: m_nNewCommands = ReadInt(NUM_NEW_COMMAND_BITS), m_nBackupCommands = ReadInt(NUM_BACKUP_COMMAND_BITS), m_nLength = ReadInt(16), m_DataIn = bf?
   clc_VoiceData = 10,        -- Voicestream data from a client | skip first 6 bits, Values: ?
   clc_BaselineAck = 11,      -- client acknowledges a new baseline seqnr | skip first 6 bits, m_nBaselineTick = ReadInt(32), m_nBaselineNr = ReadInt(1)?
   clc_ListenEvents = 12,     -- client acknowledges a new baseline seqnr | im not gonna bother with this one :skull:
   clc_RespondCvarValue = 13, -- client is responding to a svc_GetCvarValue message. | skip first 6 bits, m_iCookie = ReadInt(32), m_eStatusCode = ReadInt(4), m_szCvarName = ReadString(32), m_szCvarValue = ReadString(32)
   clc_FileCRCCheck = 14,     -- client is sending a file's CRC to the server to be verified. | im not gonna bother with this one too :skull: read the source if you want
   clc_SaveReplay = 15,       -- client is sending a save replay request to the server. | skip first 6 bits, Values: m_szFilename = ReadString(32), m_nStartSendByte = ReadInt(32)?, m_flPostDeathRecordTime = ReadFloat(32)?
   clc_CmdKeyValues = 16,     -- i am not gonna bother with this one :skull:
   c_FileMD5Check = 17,       -- client is sending a file's MD5 to the server to be verified. | skip first 6 bits... yeah no just read the source
}

---
local E_NetMessageValues = {
   --nop command used for padding
   net_NOP = function() end,

   -- disconnect, last message in connection
   ---@param bf BitBuffer
   net_Disconnect = function(bf)
      bf:SetCurBit(NETMSG_TYPE_BITS)
      local reason, endpos = bf:ReadString(32)
      bf:SetCurBit(NETMSG_TYPE_BITS)
      return reason, endpos
   end,

   -- file transmission message request/deny
   ---@param bf BitBuffer
   net_File = function(bf)
      bf:SetCurBit(NETMSG_TYPE_BITS)
      local transferId, endpos = bf:ReadInt(32)
      bf:SetCurBit(NETMSG_TYPE_BITS)
      return transferId, endpos
   end,

   -- send last world tick
   ---@param bf BitBuffer
   net_Tick = function(bf)
      bf:SetCurBit(NETMSG_TYPE_BITS)
      local values = {}
      values.m_nTick = bf:ReadInt(32)
      values.m_flHostFrameTime = bf:ReadInt(16) / NET_TICK_SCALEUP
      values.m_flHostFrameTimeStdDeviation = bf:ReadInt(16) / NET_TICK_SCALEUP
      local endpos = bf:GetCurBit()
      bf:SetCurBit(NETMSG_TYPE_BITS)
      return values, endpos
   end,

   -- a string command
   ---@param bf BitBuffer
   net_StringCmd = function(bf)
      bf:SetCurBit(NETMSG_TYPE_BITS)
      local m_szCommand, endpos = bf:ReadString(32)
      bf:SetCurBit(NETMSG_TYPE_BITS)
      return m_szCommand, endpos
   end,

   -- sends one/multiple convar settings
   ---@param bf BitBuffer
   net_SetConVar = function(bf)
      bf:SetCurBit(NETMSG_TYPE_BITS)
      local numvars, endpos = bf:ReadInt(8)
      local cvars = {}
      for i = 0, numvars do
         local name = bf:ReadString(32)
         local value = bf:ReadString(32)
         cvars[i] = { name = name, value = value }
      end
      bf:SetCurBit(NETMSG_TYPE_BITS)
      return cvars, numvars, endpos
   end,

   -- signals current signon state
   ---@param bf BitBuffer
   net_SignonState = function(bf)
      bf:SetCurBit(NETMSG_TYPE_BITS)
      local values = {}
      ---@type E_SignonState
      values.m_nSignonState = bf:ReadInt(8)
      values.m_nSpawnCount = bf:ReadInt(32)
      local endpos = bf:GetCurBit()
      bf:SetCurBit(NETMSG_TYPE_BITS)
      return values, endpos
   end,

   ---@param bf BitBuffer
   -- client info (table CRC etc)
   clc_ClientInfo = function(bf)
      bf:SetCurBit(NETMSG_TYPE_BITS)
      local values = {}
      values.m_nServerCount = bf:ReadInt(32)
      values.m_nSendTableCRC = bf:ReadInt(32)
      values.m_bIsHLTV = bf:ReadBit() == 1 and true or false
      values.m_nFriendsID = bf:ReadInt(32)
      values.m_nFriendsName = bf:ReadString(32)
      values.m_nCustomFiles = {}
      for i = 1, MAX_CUSTOM_FILES do
         if bf:ReadBit() ~= 0 then
            values.m_nCustomFiles[i] = bf:ReadInt(32)
         else
            values.m_nCustomFiles[i] = 0
         end
      end

      local endpos = bf:GetCurBit()
      bf:SetCurBit(NETMSG_TYPE_BITS)
      return values, endpos
   end,

   -- CUserCmd
   ---@param bf BitBuffer
   clc_Move = function(bf)
      bf:SetCurBit(NETMSG_TYPE_BITS)
      local values = {}
      values.m_nNewCommands = bf:ReadInt(NUM_NEW_COMMAND_BITS)
      values.m_nBackupCommands = bf:ReadInt(NUM_BACKUP_COMMAND_BITS)
      values.m_nLength = bf:ReadInt(16)
      local endpos = bf:GetCurBit()
      bf:SetCurBit(NETMSG_TYPE_BITS)
      return values, endpos
   end,

   -- client acknowledges a new baseline seqnr
   ---@param bf BitBuffer
   clc_BaselineAck = function(bf)
      bf:SetCurBit(NETMSG_TYPE_BITS)
      local values = {}
      values.m_nBaselineTick = bf:ReadInt(32)
      values.m_nBaselineNr = bf:ReadInt(1) --- is this right? shouldn't it be bf:ReadBit()?
      local endpos = bf:GetCurBit()
      bf:SetCurBit(NETMSG_TYPE_BITS)
      return values, endpos
   end,

   -- client is responding to a svc_GetCvarValue message.
   ---@param bf BitBuffer
   clc_RespondCvarValue = function(bf)
      bf:SetCurBit(NETMSG_TYPE_BITS)
      local values = {}
      values.m_iCookie = bf:ReadInt(32)
      values.m_eStatusCode = bf:ReadInt(4)
      values.m_szCvarName = bf:ReadString(32)
      values.m_szCvarValue = bf:ReadString(32)
      local endpos = bf:GetCurBit()
      bf:SetCurBit(NETMSG_TYPE_BITS)
      return values, endpos
   end,

   -- client is sending a save replay request to the server.
   ---@param bf BitBuffer
   clc_SaveReplay = function(bf)
      bf:SetCurBit(NETMSG_TYPE_BITS)
      local values = {}
      values.m_szFilename = bf:ReadString(32)
      values.m_nStartSendByte = bf:ReadInt(32)
      values.m_flPostDeathRecordTime = bf:ReadFloat(32)
      local endpos = bf:GetCurBit()
      bf:SetCurBit(NETMSG_TYPE_BITS)
      return values, endpos
   end
}

--- an example, idk if its working tho lol
---@param msg NetMessage
callbacks.Register("SendNetMsg", function(msg)
   if msg:GetType() == E_NetMessageTypes.clc_Move then
      local bf = BitBuffer()
      bf:SetCurBit(0)
      msg:WriteToBitBuffer(bf)
      local clc_move = E_NetMessageValues.clc_Move(bf)
      local m_nNewCommands, m_nBackupCommands, m_nLength = clc_move.m_nNewCommands, clc_move.m_nBackupCommands,
          clc_move.m_nLength
      print(string.format("%s, %s, %s", m_nNewCommands, m_nBackupCommands, m_nLength))

      bf:SetCurBit(NETMSG_TYPE_BITS) --- skip the msg type so we dont write on the wrong position

      --- changing the values now

      --- change m_nNewCommands
      bf:WriteInt(15, NUM_NEW_COMMAND_BITS)
      --- change m_nBackupCommands
      bf:WriteInt(7, NUM_BACKUP_COMMAND_BITS)

      --- dont forget to reset bf to the msg type or it will send garbage data and server possibly kick us
      bf:SetCurBit(NETMSG_TYPE_BITS)

      --- write to msg what is in the bf
      msg:ReadFromBitBuffer(bf)

      --- delete the bitbuffer as its not needed anymore
      bf:Delete()
   end
   return true
end)

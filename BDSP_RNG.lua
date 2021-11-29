-- Find game Base address and Main address
local mainAddr
local baseAddr

do
 local seedAddressScan = createMemScan()
 local foundList = createFoundList(seedAddressScan)
 seedAddressScan.firstScan(soExactValue, vtQword, 0, "04B2A5E830444F4D", "", 0, 0x7FFFFFFFFFFF,
                           "", fsmNotAligned, nil, true, false, false, false)
 seedAddressScan.waitTillDone()
 foundList.initialize()

 mainAddr = tonumber(foundList.Address[1], 16) - 0x8
 baseAddr = mainAddr - 0x8004000

 foundList.destroy()
 seedAddressScan.destroy()
end



-- Set addresses
local function getPlayerPrefsProviderInstanceAddr()
 local diamondPlayerPrefsProviderInstanceAddr = 0x4C49098
 local pearlPlayerPrefsProviderInstanceAddr = 0x4E60170

 if readQword(mainAddr + diamondPlayerPrefsProviderInstanceAddr) == 0 then
  return pearlPlayerPrefsProviderInstanceAddr
 else
  return diamondPlayerPrefsProviderInstanceAddr
 end
end

local function getPlayerPrefsProviderAddr()
 local playerPrefsProviderInstanceAddr = readQword(mainAddr + getPlayerPrefsProviderInstanceAddr())
 playerPrefsProviderInstanceAddr = readQword(playerPrefsProviderInstanceAddr + baseAddr + 0x18)
 playerPrefsProviderInstanceAddr = readQword(playerPrefsProviderInstanceAddr + baseAddr + 0xC0)
 playerPrefsProviderInstanceAddr = readQword(playerPrefsProviderInstanceAddr + baseAddr + 0x28)
 playerPrefsProviderInstanceAddr = readQword(playerPrefsProviderInstanceAddr + baseAddr + 0xB8)

 return readQword(playerPrefsProviderInstanceAddr + baseAddr)
end

local s0Addr = readQword(mainAddr + 0x4F8CCD0) + baseAddr
local s1Addr = s0Addr + 0x8
local IDsAddr = getPlayerPrefsProviderAddr() + baseAddr + 0xE8
local isEggReadyFlagAddr = getPlayerPrefsProviderAddr() + baseAddr + 0x458
local eggSeedAddr = isEggReadyFlagAddr + 0x8
local eggStepsCounterAddr = eggSeedAddr + 0x8



-- Set trainer info
local TID = bAnd(readInteger(IDsAddr), 0xFFFF)
local SID = bShr(readInteger(IDsAddr), 16)
local G8TID = bAnd((SID << 16) | TID, 0xFFFFFFFF) % 1000000
local TSV = bShr((TID ~ SID), 4)



-- XorShift class
XorShift = {}
XorShift.__index = XorShift

function XorShift.new(s0, s1)
 local o = setmetatable({}, XorShift)
 o.initS0 = s0
 o.initS1 = s1
 o.s0 = s0
 o.s1 = s1
 o.advances = 0

 return o
end

function XorShift:next()
 local t = bAnd(self.s0, 0xFFFFFFFF)
 local s = bShr(self.s1, 32)

 t = t ~ bAnd(bShl(t, 11), 0xFFFFFFFF)
 t = t ~ bShr(t, 8)
 t = t ~ (s ~ bShr(s, 19))

 self.s0 = bAnd(bOr(bShl(bAnd(self.s1, 0xFFFFFFFF), 32), bShr(self.s0, 32)), 0xFFFFFFFFFFFFFFFF)
 self.s1 = bAnd(bOr(bShl(t, 32), bShr(self.s1, 32)), 0xFFFFFFFFFFFFFFFF)
 self.advances = self.advances + 1

 return bAnd(((t % 0xFFFFFFFF) + 0x80000000), 0xFFFFFFFF)
end

function XorShift:print()
 print(string.format("Initial Seed:\nS[0]: %016X  S[1]: %016X", self.initS0, self.initS1))
 print("")
 print(string.format("Current Seed:\nS[0]: %016X  S[1]: %016X", self.s0, self.s1))
 print("")
 print(string.format("Advances: %d", self.advances))
 print("\n")
end

local initRNG = XorShift.new(readQword(s0Addr), readQword(s1Addr))



-- Printing functions
local function printEggInfo()
 local isEggReady = readQword(isEggReadyFlagAddr) == 0x01
 local eggStepsCounter = 180 - readBytes(eggStepsCounterAddr)

 if not isEggReady then
  print("Egg Steps Counter: "..eggStepsCounter)
  print("Egg is not ready")
 end

 if isEggReady then
  local eggSeed = readInteger(eggSeedAddr)
  print("Egg generated, go get it!")
  print(string.format("Egg Seed: %08X", eggSeed))
 elseif eggStepsCounter == 1 then
  print("Next step might generate an egg!")
 elseif eggStepsCounter == 180 then
  print("180th step taken")
 else
  print("Keep on steppin'")
 end

 print("\n")
end

local function printTrainerInfo()
 print(string.format("G8TID: %d", G8TID))
 print(string.format("TID: %d", TID))
 print(string.format("SID: %d", SID))
 print(string.format("TSV: %d", TSV))
end

local function printRngInfo()
 local currS0 = readQword(s0Addr)
 local currS1 = readQword(s1Addr)
 local skips = 0

 while (currS0 ~= initRNG.s0 or currS1 ~= initRNG.s1) and skips < 99999 do
  initRNG:next()
  GetLuaEngine().MenuItem5.doClick()
  initRNG:print()
  printEggInfo()
  printTrainerInfo()
  skips = skips + 1
 end
end



-- Timer function
local function aTimerTick(timer)
 if isKeyPressed(VK_0) or isKeyPressed(VK_NUMPAD0) then
  timer.destroy()
 end

 printRngInfo()
end



-- Main
initRNG:print()
printEggInfo()
printTrainerInfo()

local aTimer = nil
local timerInterval = 500

aTimer = createTimer(getMainForm())
aTimer.Interval = timerInterval
aTimer.OnTimer = aTimerTick
aTimer.Enabled = true
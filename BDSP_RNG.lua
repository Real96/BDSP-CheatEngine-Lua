local mainAddr
local baseAddr



-- Find game Base address and Main address
do
 local seedAddressScan = createMemScan()
 local foundList = createFoundList(seedAddressScan)
 seedAddressScan.firstScan(soExactValue, vtQword, 0, "04B2A5E830444F4D", "", 0, 0x7fffffffffff,
                           "", fsmNotAligned, nil, true, false, false, false)
 seedAddressScan.waitTillDone()
 foundList.initialize()
 
 mainAddr = tonumber(foundList.Address[1], 16) - 0x8
 baseAddr = mainAddr - 0x8004000
 
 foundList.destroy()
 seedAddressScan.destroy()
end



-- Set addresses
local s0Addr = readQword(mainAddr + 0x4F8CCD0) + baseAddr
local s1Addr = s0Addr + 0x8

local playerPrefsProviderInstanceAddr

do
 local diamondPlayerPrefsProviderInstanceAddr = 0x4C49098
 local pearlPlayerPrefsProviderInstanceAddr = 0x4E60170
 playerPrefsProviderInstanceAddr = diamondPlayerPrefsProviderInstanceAddr

 if readQword(mainAddr + playerPrefsProviderInstanceAddr) == 0 then
  playerPrefsProviderInstanceAddr = pearlPlayerPrefsProviderInstanceAddr
 end
end

local isEggReadyFlagAddr

do
 local tmpAddr = readQword(mainAddr + playerPrefsProviderInstanceAddr)
 tmpAddr = readQword(tmpAddr + baseAddr + 0x18)
 tmpAddr = readQword(tmpAddr + baseAddr + 0xc0)
 tmpAddr = readQword(tmpAddr + baseAddr + 0x28)
 tmpAddr = readQword(tmpAddr + baseAddr + 0xb8)
 tmpAddr = readQword(tmpAddr + baseAddr)
 isEggReadyFlagAddr = tmpAddr + baseAddr + 0x458
end

local eggSeedAddr = isEggReadyFlagAddr + 0x8
local eggStepsCounterAddr = eggSeedAddr + 0x8



-- XorShift class
XorShift = {}
XorShift.__index = XorShift

function XorShift.new(s0, s1)
 local o = setmetatable({}, XorShift)
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
 print(string.format("S[0]: %016X  S[1]: %016X", self.s0, self.s1))
 print(string.format("Advances: %d", self.advances))
 print("")
end

local initRNG = XorShift.new(readQword(s0Addr), readQword(s1Addr))
initRNG:print()



--[[BDSPGenerator = {}
BDSPGenerator.__index = BDSPGenerator

function BDSPGenerator.new(s0, s1)
 local o = setmetatable({}, BDSPGenerator)
 o.currRNG = XorShift.new(s0, s1)

 return o
end

function BDSPGenerator:isShiny()
 local currRNG = XorShift.new(self.currRNG.s0, self.currRNG.s1)
 local pid = currRNG:next()
 local shinyRand = currRNG:next()

 return (bAnd(pid, 0xFFF0) ~ bShr(pid, 0x10) ~ bShr(shinyRand, 0x10) ~ bAnd(shinyRand, 0xFFF0)) < 0x10
end

function BDSPGenerator:printShinyAdvances()
 while not self:isShiny() do
  self.currRNG:next()
 end

 print(string.format("Next Shiny advances: %d", self.currRNG.advances))
 print("")
 print("")
end]]



--[[local function printCurrInfo(s0, s1)
 local currRNG = XorShift.new(s0, s1)
 local currPID = currRNG:next()
 local currShinyRand = currRNG:next()
 print(string.format("PID: %08X - Shiny Rand: %08X", currPID, currShinyRand))
 print("")
end]]

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
end

local function printRngInfo()
 local currS0 = readQword(s0Addr)
 local currS1 = readQword(s1Addr)
 local skips = 0

 while (currS0 ~= initRNG.s0 or currS1 ~= initRNG.s1) and skips < 99999 do
  initRNG:next()
  GetLuaEngine().MenuItem5.doClick()
  initRNG:print()
  --printCurrInfo(currS0, currS1)
  printEggInfo()
  skips = skips + 1

  --if currS0 == initRNG.s0 and currS1 == initRNG.s1 then
  --end
 end

 --local generator = BDSPGenerator.new(currS0, currS1)
 --generator:printShinyAdvances()
end

--printCurrInfo(readQword(s0Addr), readQword(s1Addr))
printEggInfo()
--local generator = BDSPGenerator.new(readQword(s0Addr), readQword(s1Addr))
--generator:printShinyAdvances()

local aTimer = nil
local timerInterval = 500

local function aTimerTick(timer)
 if isKeyPressed(VK_0) or isKeyPressed(VK_NUMPAD0) then
  timer.destroy()
 end

 printRngInfo()
end

aTimer = createTimer(getMainForm())
aTimer.Interval = timerInterval
aTimer.OnTimer = aTimerTick
aTimer.Enabled = true
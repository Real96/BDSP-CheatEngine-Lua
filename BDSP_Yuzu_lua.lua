local s0Addr = 0x20D001810E0
local s1Addr = 0x20D001810E8



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
 print(string.format("Advances: %d", self.advances))
 print(string.format("S[0]: %016X  S[1]: %016X", self.s0, self.s1))
end

local initRNG = XorShift.new(readPointer(s0Addr), readPointer(s1Addr))



BDSPGenerator = {}
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
end



local function printAdvances()
 local currS0 = readPointer(s0Addr)
 local currS1 = readPointer(s1Addr)

 while currS0 ~= initRNG.s0 or currS1 ~= initRNG.s1 do
  initRNG:next()

  if currS0 == initRNG.s0 and currS1 == initRNG.s1 then
   initRNG:print()
   local generator = BDSPGenerator.new(currS0, currS1)
   generator:printShinyAdvances()
  end
 end
end



local aTimer = nil
local timerInterval = 100

local function aTimerTick(timer)
 if isKeyPressed(VK_NUMPAD0) then
  timer.destroy()
 end

 printAdvances()
end

aTimer = createTimer(getMainForm())
aTimer.Interval = timerInterval
aTimer.OnTimer = aTimerTick
aTimer.Enabled = true
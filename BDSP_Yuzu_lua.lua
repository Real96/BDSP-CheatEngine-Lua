local s0Addr = 0x258361810E0
local s1Addr = 0x258361810E8

local initS0 = readPointer(s0Addr)
local initS1 = readPointer(s1Addr)
local advances = 0

print(string.format("Advances: %d", advances))
print(string.format("S[0]: %016X  S[1]: %016X", initS0, initS1))
print("")

local aTimer = nil
local timerInterval = 100

function next()
 t = bAnd(initS0, 0xFFFFFFFF)
 s = bShr(initS1, 32)

 t = t ~ bAnd(bShl(t, 11), 0xFFFFFFFF)
 t = t ~ bShr(t, 8)
 t = t ~ (s ~ bShr(s, 19))

 initS0 = bOr(bShl(bAnd(initS1, 0xFFFFFFFF), 32), bShr(initS0, 32))
 initS1 = bOr(bShl(t, 32), bShr(initS1, 32))

 return bAnd(((t % 0xFFFFFFFF) + 0x80000000), 0xFFFFFFFF)
end

local function showAdvances()
 local s0 = readPointer(s0Addr)
 local s1 = readPointer(s1Addr)

 while initS0 ~= s0 or initS1 ~= s1 do
  next()
  advances = advances + 1

  if initS0 == s0 or initS1 == s1 then
   print(string.format("Advances: %d", advances))
   print(string.format("S[0]: %016X  S[1]: %016X", s0, s1))
   print("")
  end
 end
end

local function aTimerTick(timer)
 if isKeyPressed(VK_NUMPAD0) then
  timer.destroy()
 end

 showAdvances()
end

aTimer = createTimer(getMainForm())
aTimer.Interval = timerInterval
aTimer.OnTimer = aTimerTick
aTimer.Enabled = true
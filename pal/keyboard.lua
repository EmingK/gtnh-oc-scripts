-- using ncurses key code. different from oc!

local keyboard = {
  keys = {}
}

keyboard.keys["1"]           = 0x31
keyboard.keys["2"]           = 0x32
keyboard.keys["3"]           = 0x33
keyboard.keys["4"]           = 0x34
keyboard.keys["5"]           = 0x35
keyboard.keys["6"]           = 0x36
keyboard.keys["7"]           = 0x37
keyboard.keys["8"]           = 0x38
keyboard.keys["9"]           = 0x39
keyboard.keys["0"]           = 0x30
keyboard.keys.a               = 0x61
keyboard.keys.b               = 0x62
keyboard.keys.c               = 0x63
keyboard.keys.d               = 0x64
keyboard.keys.e               = 0x65
keyboard.keys.f               = 0x66
keyboard.keys.g               = 0x67
keyboard.keys.h               = 0x68
keyboard.keys.i               = 0x69
keyboard.keys.j               = 0x6a
keyboard.keys.k               = 0x6b
keyboard.keys.l               = 0x6c
keyboard.keys.m               = 0x6d
keyboard.keys.n               = 0x6e
keyboard.keys.o               = 0x6f
keyboard.keys.p               = 0x70
keyboard.keys.q               = 0x71
keyboard.keys.r               = 0x72
keyboard.keys.s               = 0x73
keyboard.keys.t               = 0x74
keyboard.keys.u               = 0x75
keyboard.keys.v               = 0x76
keyboard.keys.w               = 0x77
keyboard.keys.x               = 0x78
keyboard.keys.y               = 0x79
keyboard.keys.z               = 0x7a

--keyboard.keys.apostrophe      = 0x28
--keyboard.keys.at              = 0x91
keyboard.keys.back            = 0x7f -- backspace
keyboard.keys.backslash       = 0x5c
--keyboard.keys.capital         = 0x3A -- capslock
keyboard.keys.colon           = 0x3c
keyboard.keys.comma           = 0x2c
keyboard.keys.enter           = 0x0a
keyboard.keys.equals          = 0x3d
keyboard.keys.grave           = 0x60 -- accent grave
keyboard.keys.lbracket        = 0x5b
-- we do not support direct modifiers with curses :-(
-- keyboard.keys.lcontrol        = 0x1D
-- keyboard.keys.lmenu           = 0x38 -- left Alt
-- keyboard.keys.lshift          = 0x2A
keyboard.keys.minus           = 0x2d
--keyboard.keys.numlock         = 0x45
--keyboard.keys.pause           = 0xC5
keyboard.keys.period          = 0x2e
keyboard.keys.rbracket        = 0x5d
--keyboard.keys.rcontrol        = 0x9D
--keyboard.keys.rmenu           = 0xB8 -- right Alt
--keyboard.keys.rshift          = 0x36
--keyboard.keys.scroll          = 0x46 -- Scroll Lock
keyboard.keys.semicolon       = 0x3b
keyboard.keys.slash           = 0x2f -- / on main keyboard
keyboard.keys.space           = 0x20
-- keyboard.keys.stop            = 0x95
keyboard.keys.tab             = 0x09
keyboard.keys.underline       = 0x5f

-- Keypad (and numpad with numlock off)
keyboard.keys.up              = 0x103
keyboard.keys.down            = 0x102
keyboard.keys.left            = 0x104
keyboard.keys.right           = 0x105
keyboard.keys.home            = 0x106
keyboard.keys["end"]          = 0x168
keyboard.keys.pageUp          = 0x153
keyboard.keys.pageDown        = 0x152
keyboard.keys.insert          = 0x14b
keyboard.keys.delete          = 0x14a

-- Function keys
keyboard.keys.f1              = 0x109
keyboard.keys.f2              = 0x10a
keyboard.keys.f3              = 0x10b
keyboard.keys.f4              = 0x10c
keyboard.keys.f5              = 0x10d
keyboard.keys.f6              = 0x10e
keyboard.keys.f7              = 0x10f
keyboard.keys.f8              = 0x110
keyboard.keys.f9              = 0x111
keyboard.keys.f10             = 0x112
keyboard.keys.f11             = 0x113
keyboard.keys.f12             = 0x114
keyboard.keys.f13             = 0x115
keyboard.keys.f14             = 0x116
keyboard.keys.f15             = 0x117
keyboard.keys.f16             = 0x118
keyboard.keys.f17             = 0x119
keyboard.keys.f18             = 0x11a
keyboard.keys.f19             = 0x11b

-- Japanese keyboards
-- keyboard.keys.kana            = 0x70
-- keyboard.keys.kanji           = 0x94
-- keyboard.keys.convert         = 0x79
-- keyboard.keys.noconvert       = 0x7B
-- keyboard.keys.yen             = 0x7D
-- keyboard.keys.circumflex      = 0x90
-- keyboard.keys.ax              = 0x96

-- my dev machine does not have a Numpad :-(
-- keyboard.keys.numpad0         = 0x52
-- keyboard.keys.numpad1         = 0x4F
-- keyboard.keys.numpad2         = 0x50
-- keyboard.keys.numpad3         = 0x51
-- keyboard.keys.numpad4         = 0x4B
-- keyboard.keys.numpad5         = 0x4C
-- keyboard.keys.numpad6         = 0x4D
-- keyboard.keys.numpad7         = 0x47
-- keyboard.keys.numpad8         = 0x48
-- keyboard.keys.numpad9         = 0x49
-- keyboard.keys.numpadmul       = 0x37
-- keyboard.keys.numpaddiv       = 0xB5
-- keyboard.keys.numpadsub       = 0x4A
-- keyboard.keys.numpadadd       = 0x4E
-- keyboard.keys.numpaddecimal   = 0x53
-- keyboard.keys.numpadcomma     = 0xB3
-- keyboard.keys.numpadenter     = 0x9C
-- keyboard.keys.numpadequals    = 0x8D

-- Create inverse mapping for name lookup.
setmetatable(keyboard.keys,
{
  __index = function(tbl, k)
    if type(k) ~= "number" then return end
    for name,value in pairs(tbl) do
      if value == k then
        return name
      end
    end
  end
})

return keyboard

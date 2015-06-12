local err,warn,info,log = luatexbase.provides_module({
  name        = 'hangulromanize',
  date        = '2015/06/11',
  version     = 0.1,
  description = 'Hangul romanization as per Revised system',
  author      = 'Dohyun Kim',
  license     = 'public domain',
})

hangulromanize = hangulromanize or {}
local hangulromanize = hangulromanize

local LC = { [0] =
  "g", "kk", "n",  "d", "tt", "r", "m", "b", "pp", "s", "ss", "",
  "j", "jj", "ch", "k", "t",  "p", "h",
}

local MV = { [0] =
  "a",  "ae", "ya", "yae", "eo", "e",  "yeo", "ye", "o", "wa", "wae", "oe",
  "yo", "u",  "wo", "we",  "wi", "yu", "eu",  "ui", "i",
}

local TC = { [0] =
  "",   "G",  "kk", "ks", "n", "nj", "nh", "D", "R",  "lG", "lm", "lB",
  "ls", "lt", "lp", "lh", "m", "B",  "ps", "s", "ss", "ng", "j",  "ch",
  "k",  "t",  "p",  "h",
}

local TCNV = { G = "k", D = "t", B = "p", R = "l", }

local LC_A = { [0] =
  "g", "kk", "n", "d", "tt", "l", "m", "b", "pp", "s", "ss", "-",
  "j", "jj", "ch", "k", "t", "p", "h",
}

local TC_A = { [0] =
  "",  "g",  "kk", "gs", "n", "nj", "nh", "d", "l",  "lg", "lm", "lb",
  "ls", "lt", "lp", "lh", "m", "b",  "bs", "s", "ss", "ng", "j",  "ch",
  "k",  "t",  "p",  "h",
}

local HYPH = {
  bss = true, gss = true, jj  = true, kk = true, kkk = true, lpp = true,
  lss = true, ltt = true, njj = true, pp = true, ss  = true, sss = true,
  tt  = true,
}

local R2LC = { }; for i = 0, #LC_A do R2LC[ LC_A[i] ] = i end
local R2MV = { }; for i = 0, #MV   do R2MV[ MV[i]   ] = i end
local R2TC = { }; for i = 0, #TC_A do R2TC[ TC_A[i] ] = i end

require "unicode"
local utfchar = unicode.utf8.char
local concat  = table.concat
local floor   = math.floor
local tsprint = tex.sprint

local split = function (sep, str)
  local t = { }
  str = str:gsub("(.-)"..sep, function(aa,bb)
    t[ #t + 1 ] = aa
    if bb then
      t[ #t + 1 ] = bb
    end
    return ""
  end)
  t[ #t + 1 ] = str -- last item might be empty, which we accept.
  return t
end

local jamo2syll = function (cho, jung, jong)
  return utfchar ((cho * 21 + jung) * 28 + jong + 0xAC00);
end

local hangulize = function (str)
  local hanguls = { }
  for _,roman in ipairs(str:lower():explode("-")) do
    local cho, jung, jong;
    local roms = split("([aeiouwy]+)", roman)

    for i = 1, #roms do
      rom = roms[ i ]:gsub("[^a-z]","")

      if i % 2 == 0 then -- MV
        jung = R2MV[ rom ]
      elseif i == 1 then -- LC
        rom = rom == "" and "-" or rom
        cho = R2LC[ rom ]
      elseif i == #roms then -- TC
        jong = R2TC[ rom ]
        hanguls[ #hanguls + 1 ] = jamo2syll(cho, jung, jong)
      else -- TC..LC
        local done
        for k,v in pairs(R2TC) do
          for kk,vv in pairs(R2LC) do
            if (rom == k..kk) then
              jong = R2TC[ k ]
              hanguls[ #hanguls + 1 ] = jamo2syll(cho, jung, jong)
              cho  = R2LC[ kk ]
              done = true
              break
            end
            if done then break end
          end
        end
      end
    end
  end
  return concat(hanguls)
end

local romanize = function (academy, capital, str)
  local romans, last = { }, nil
  local L_C = academy and LC_A or LC
  local T_C = academy and TC_A or TC

  for ch in str:utfvalues() do
    if ch >= 0xAC00 and ch <= 0xD7A3 then
      ch = ch - 0xAC00
      local cho  = L_C[ floor( ch / 588) ]
      local jung = MV [ floor((ch % 588) / 28) ]
      local jong = T_C[ floor( ch % 28) ]

      if academy and last and HYPH[ last..cho ] then
        romans[ #romans + 1 ] = "-"
      end
      last = jong

      if academy and #romans == 0 and cho == "-" then
      else
        romans[ #romans + 1 ] = cho
      end
      romans[ #romans + 1 ] = jung
      romans[ #romans + 1 ] = jong
    else
      romans[ #romans + 1 ] = utfchar(ch)
      last = nil
    end
  end
  local roman = concat(romans)

  if not academy then
    roman = roman:gsub("([GDBR])(%-?[aeiouwy])", function(aa,bb)
      return aa:lower()..bb
    end)
    roman = roman:gsub("([GDBR])", function(aa) return TCNV[ aa ] end)
    roman = roman:gsub("lr","ll")
  end

  if capital then
    roman = roman:gsub("^%l",string.upper)
  end
  return roman
end

hangulromanize.romanize  = function(...) tsprint(romanize (...)) end
hangulromanize.hangulize = function(...) tsprint(hangulize(...)) end

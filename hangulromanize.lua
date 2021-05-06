luatexbase.provides_module({
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
  "",   "g",  "kk", "gs", "n", "nj", "nh", "d", "l",  "lg", "lm", "lb",
  "ls", "lt", "lp", "lh", "m", "b",  "bs", "s", "ss", "ng", "j",  "ch",
  "k",  "t",  "p",  "h",
}

local HYPH = {
  bss = true, gss = true, jj  = true, kk = true, kkk = true, lpp = true,
  lss = true, ltt = true, njj = true, pp = true, ss  = true, sss = true,
  tt  = true,
}

local R2LC = { }; for i = 0, #LC_A do R2LC[ LC_A[i] ] = i end
local R2MV = { }; for i = 0, #MV   do R2MV[ MV  [i] ] = i end
local R2TC = { }; for i = 0, #TC_A do R2TC[ TC_A[i] ] = i end

local utfchar = utf8.char
local concat  = table.concat
local insert  = table.insert
local tsprint = tex.sprint

local function split (sep, str)
  local t = { }
  str = str:gsub("(.-)"..sep, function(aa,bb)
    insert(t, aa)
    if bb then
      insert(t, bb)
    end
    return ""
  end)
  insert(t, str) -- last item might be empty, which we accept.
  return t
end

local function jamo2syll (cho, jung, jong)
  return utfchar ((cho * 21 + jung) * 28 + jong + 0xAC00)
end

local function hangulize (str)
  local hanguls = { }
  for j, word in ipairs(split("([^A-Za-z%-]+)",str)) do
    if j % 2 == 0 then
      insert(hanguls, word) -- non-hangul chars
    else
      for _,roman in ipairs(word:lower():explode("-")) do
        local cho, jung, jong
        local roms = split("([aeiouwy]+)", roman)

        for i, rom in ipairs(roms) do
          rom = rom:gsub("[^a-z]","")

          if i % 2 == 0 then -- MV
            jung = R2MV[ rom ]
          elseif i == 1 then -- LC
            rom = rom == "" and "-" or rom
            cho = R2LC[ rom ]
          elseif i == #roms then -- TC
            jong = R2TC[ rom ]
            insert(hanguls, jamo2syll(cho, jung, jong))
          else -- TC..LC
            local done
            for k in pairs(R2TC) do
              for kk in pairs(R2LC) do
                if rom == k..kk then
                  jong = R2TC[ k ]
                  insert(hanguls, jamo2syll(cho, jung, jong))
                  cho  = R2LC[ kk ]
                  done = true
                  break
                end
              end
              if done then break end
            end
          end
        end
      end
    end
  end
  return concat(hanguls)
end

local function romanize (academy, capital, str)
  local romans, last = { }, nil
  local L_C = academy and LC_A or LC
  local T_C = academy and TC_A or TC

  for ch in str:utfvalues() do
    if ch >= 0xAC00 and ch <= 0xD7A3 then
      ch = ch - 0xAC00
      local cho  = L_C[ ch // 588 ]
      local jung = MV [ ch %  588 // 28 ]
      local jong = T_C[ ch %   28 ]

      if academy and last and HYPH[ last..cho ] then
        insert(romans, "-")
      end

      if academy and not last and cho == "-" then
        -- the first char of a word
      else
        insert(romans, cho)
      end
      insert(romans, jung)
      insert(romans, jong)

      last = jong
    else
      insert(romans, utfchar(ch))
      last = nil
    end
  end
  local roman = concat(romans)

  if not academy then
    roman = roman:gsub("[GDBR]%-?[aeiouwy]", string.lower)
    roman = roman:gsub("[GDBR]", TCNV)
    roman = roman:gsub("lr","ll")
  end

  if capital then
    roman = roman:gsub("^%l",string.upper)
  end
  return roman
end

hangulromanize.romanize  = function(...) tsprint(romanize (...)) end
hangulromanize.hangulize = function(...) tsprint(hangulize(...)) end

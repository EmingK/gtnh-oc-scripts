--[[
  Copyright (c) 2025 Eming Kwok

  This source code is licensed under the MIT license found in the
  LICENSE file in the root directory of this source tree.
]]

--[[
  Internationalization

  This module provides multi language support.
]]
local i18n = {}
local langTable = {}

--[[
  Global function: _T

  Get a translated text for input translation key.
  Must be called after i18n init.
]]
function _T(k)
  return langTable[k] or k
end

local baseModule

function i18n.reload(lang)
  local langCode = lang or i18n.langList.default

  for name, code in pairs(i18n.langList) do
    if name ~= 'default' and code == langCode then
      langCode = code
      i18n.current = name
      break
    end
  end

  langTable = require(baseModule..'/lang_'..langCode)
end

--[[
  Initialize i18n system.

  @param base: The base i18n module dir. This dir's init module is imported
               to get a full list of supported languages. The init module
               should export a table, of which the key is the display name,
               and value is the module name of translation file.
  @param lang: Selected language. Will be imported via `${base}/lang_${lang}`.
]]
function i18n.setup(base, lang)
  baseModule = base
  i18n.langList = require(base)
  i18n.reload(lang)
end

return i18n

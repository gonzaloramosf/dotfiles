#!/usr/bin/env bash

# Symbolic hotkey parameters are (character, virtual key code, modifiers).
# Special keys use the 65535 character sentinel. On current macOS versions,
# arrow shortcuts also include the function-key bit (8388608) in their mask.
readonly MODIFIER_CONTROL=262144
readonly MODIFIER_OPTION=524288
readonly MODIFIER_COMMAND=1048576
readonly MODIFIER_FUNCTION=8388608

set_symbolic_hotkey() {
  local id="$1"
  local enabled="$2"
  local character="$3"
  local key_code="$4"
  local modifiers="$5"
  local enabled_xml='<false/>'
  local hotkey_xml

  if [[ "$enabled" == true ]]; then
    enabled_xml='<true/>'
  fi

  # XML preserves the boolean and integer types. The old OpenStep-style value
  # made `defaults` store every scalar as a string, which macOS can ignore.
  hotkey_xml="<dict>
    <key>enabled</key>${enabled_xml}
    <key>value</key>
    <dict>
      <key>parameters</key>
      <array>
        <integer>${character}</integer>
        <integer>${key_code}</integer>
        <integer>${modifiers}</integer>
      </array>
      <key>type</key><string>standard</string>
    </dict>
  </dict>"

  defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys \
    -dict-add "$id" "$hotkey_xml"
}

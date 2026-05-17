# CyrHUD Console Port Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Produce a console-only fork of the CyrHUD ESO addon at `addon/CyrHUDConsole/` that runs on Xbox/PSN UI, with the PC version untouched.

**Architecture:** Side-by-side copy with surgical edits. `classes/`, `lang/`, `textures/` are byte-identical copies of the PC source. `CyrHUD.lua`, `Info.lua`, and `Label.lua` get targeted edits; `bindings.xml` is dropped; `menu.lua` (LibAddonMenu-2) is replaced by `settings.lua` (LibHarvensAddonSettings). Mouse-drag and quest-tracker code paths are stripped. Position becomes a six-preset dropdown.

**Tech Stack:** ESO addon Lua (API 101049), LibHarvensAddonSettings (`libs/LibHarvensAddonSettings/`) for the settings panel. Validation done with ESOLua's `luac -p` static parser (`libs/ESOLua/src/luac`) — there is no headless ESO runtime, so testing is **static syntax + grep audits**, not behavioral.

**Spec:** `docs/superpowers/specs/2026-05-17-cyrhud-console-port-design.md`

---

## Conventions (read once before starting)

- **Source of truth for copies:** `/home/sammy/Public/repo/ESO/addon/CyrHUD/`. Every file in `addon/CyrHUDConsole/classes/`, `addon/CyrHUDConsole/lang/`, and `addon/CyrHUDConsole/textures/` must originate from this directory.
- **Luac path:** `/home/sammy/Public/repo/ESO/libs/ESOLua/src/luac` (already built; verify with `ls -la libs/ESOLua/src/luac`; if missing run `make -C libs/ESOLua/src linux`).
- **Working directory:** all commands assume `cwd = /home/sammy/Public/repo/ESO`. Use absolute paths to be safe.
- **Commit style:** match the existing commit on `main` (`Add design spec for CyrHUD console port`). Use conventional sentence-style summary + body explaining *why*, plus the trailer `Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>`.
- **DO NOT touch `addon/CyrHUD/`.** Any edit to that directory is a bug.

## File map

| Path | Disposition |
|---|---|
| `addon/CyrHUDConsole/CyrHUDConsole.addon` | Create — new manifest |
| `addon/CyrHUDConsole/CyrHUD.lua` | Create — edited copy of PC `CyrHUD.lua` |
| `addon/CyrHUDConsole/settings.lua` | Create — Harvens settings panel (replaces `menu.lua`) |
| `addon/CyrHUDConsole/classes/Info.lua` | Create — edited copy (fonts + width) |
| `addon/CyrHUDConsole/classes/Label.lua` | Create — edited copy (row height) |
| `addon/CyrHUDConsole/classes/Battle.lua` | Create — byte-identical copy |
| `addon/CyrHUDConsole/classes/Graveyards.lua` | Create — byte-identical copy |
| `addon/CyrHUDConsole/classes/Locations.lua` | Create — byte-identical copy |
| `addon/CyrHUDConsole/classes/MovingObjectives.lua` | Create — byte-identical copy |
| `addon/CyrHUDConsole/classes/PatrollingHorrors.lua` | Create — byte-identical copy |
| `addon/CyrHUDConsole/classes/RankingBar.lua` | Create — byte-identical copy |
| `addon/CyrHUDConsole/classes/ScoringBar.lua` | Create — byte-identical copy |
| `addon/CyrHUDConsole/lang/{en,de,fr,jp,ru,zh}.lua` | Create — byte-identical copies |
| `addon/CyrHUDConsole/textures/*.dds` | Create — byte-identical copies |
| `addon/CyrHUDConsole/LICENSE` | Create — byte-identical copy |
| `addon/CyrHUDConsole/GPLv2` | Create — byte-identical copy |

PC source files that are **deliberately not present** in the console build: `bindings.xml`, `menu.lua`.

---

## Task 1: Scaffold the addon directory with verbatim asset copies

**Files:**
- Create: `addon/CyrHUDConsole/classes/` (Battle.lua, Graveyards.lua, Locations.lua, MovingObjectives.lua, PatrollingHorrors.lua, RankingBar.lua, ScoringBar.lua — 7 byte-identical files)
- Create: `addon/CyrHUDConsole/lang/` (en.lua, de.lua, fr.lua, jp.lua, ru.lua, zh.lua — 6 byte-identical files)
- Create: `addon/CyrHUDConsole/textures/` (all `.dds` files from PC textures dir)
- Create: `addon/CyrHUDConsole/LICENSE`, `addon/CyrHUDConsole/GPLv2`

These files never diverge from PC. We copy them in bulk and verify with `cmp`.

- [ ] **Step 1: Create the destination directory tree**

```bash
mkdir -p /home/sammy/Public/repo/ESO/addon/CyrHUDConsole/classes
mkdir -p /home/sammy/Public/repo/ESO/addon/CyrHUDConsole/lang
mkdir -p /home/sammy/Public/repo/ESO/addon/CyrHUDConsole/textures
```

- [ ] **Step 2: Copy classes (skipping Info.lua and Label.lua which are edited in later tasks)**

```bash
cd /home/sammy/Public/repo/ESO/addon/CyrHUD/classes
for f in Battle.lua Graveyards.lua Locations.lua MovingObjectives.lua PatrollingHorrors.lua RankingBar.lua ScoringBar.lua; do
    cp "$f" /home/sammy/Public/repo/ESO/addon/CyrHUDConsole/classes/"$f"
done
```

- [ ] **Step 3: Copy lang files**

```bash
cp /home/sammy/Public/repo/ESO/addon/CyrHUD/lang/*.lua \
   /home/sammy/Public/repo/ESO/addon/CyrHUDConsole/lang/
```

- [ ] **Step 4: Copy textures**

```bash
cp /home/sammy/Public/repo/ESO/addon/CyrHUD/textures/*.dds \
   /home/sammy/Public/repo/ESO/addon/CyrHUDConsole/textures/
```

- [ ] **Step 5: Copy LICENSE and GPLv2**

```bash
cp /home/sammy/Public/repo/ESO/addon/CyrHUD/LICENSE \
   /home/sammy/Public/repo/ESO/addon/CyrHUDConsole/LICENSE
cp /home/sammy/Public/repo/ESO/addon/CyrHUD/GPLv2 \
   /home/sammy/Public/repo/ESO/addon/CyrHUDConsole/GPLv2
```

- [ ] **Step 6: Verify the copies are byte-identical**

Run:
```bash
cd /home/sammy/Public/repo/ESO
fail=0
for f in classes/Battle.lua classes/Graveyards.lua classes/Locations.lua classes/MovingObjectives.lua classes/PatrollingHorrors.lua classes/RankingBar.lua classes/ScoringBar.lua lang/en.lua lang/de.lua lang/fr.lua lang/jp.lua lang/ru.lua lang/zh.lua LICENSE GPLv2; do
    if ! cmp -s "addon/CyrHUD/$f" "addon/CyrHUDConsole/$f"; then
        echo "MISMATCH: $f"; fail=1
    fi
done
ls addon/CyrHUD/textures | sort > /tmp/pc_tex.txt
ls addon/CyrHUDConsole/textures | sort > /tmp/co_tex.txt
diff /tmp/pc_tex.txt /tmp/co_tex.txt || fail=1
echo "fail=$fail"
```

Expected output: every cmp silent, no MISMATCH line, no diff output, `fail=0`.

- [ ] **Step 7: Static-syntax-check the copied Lua files**

```bash
cd /home/sammy/Public/repo/ESO
for f in addon/CyrHUDConsole/classes/*.lua addon/CyrHUDConsole/lang/*.lua; do
    libs/ESOLua/src/luac -p "$f" || echo "FAIL: $f"
done
echo done
```

Expected output: only `done` printed; no `FAIL:` lines.

- [ ] **Step 8: Commit**

```bash
cd /home/sammy/Public/repo/ESO
git add addon/CyrHUDConsole/
git commit -m "$(cat <<'EOF'
Scaffold CyrHUDConsole addon with verbatim asset copies

These files do not diverge from the PC source: the rendering classes
(except Info/Label which are edited next), all lang/, all textures,
and the license files. Copied byte-for-byte so future PC-side bug
fixes can be re-applied mechanically.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

Expected: a commit creating ~15 lua files, 18 dds files, and 2 license files. Run `git log --stat -1` and confirm the only directory touched is `addon/CyrHUDConsole/`.

---

## Task 2: Edit `classes/Info.lua` — gamepad fonts and wider HUD

**Files:**
- Create: `addon/CyrHUDConsole/classes/Info.lua` (edited copy of `addon/CyrHUD/classes/Info.lua`)

Three lines diverge from PC: the two font fields and the HUD width. Everything else (colors, icons, gauges, alliance tables) is identical.

- [ ] **Step 1: Copy the PC source as a starting point**

```bash
cp /home/sammy/Public/repo/ESO/addon/CyrHUD/classes/Info.lua \
   /home/sammy/Public/repo/ESO/addon/CyrHUDConsole/classes/Info.lua
```

- [ ] **Step 2: Replace the two font lines**

Edit `addon/CyrHUDConsole/classes/Info.lua`. Find this line:

```lua
CyrHUD.info.fontMain = GetString(SI_CYRHUD_FONT)
```

Replace with:

```lua
CyrHUD.info.fontMain = "ZoFontGamepad36"
```

Find:

```lua
CyrHUD.info.fontSmall = GetString(SI_CYRHUD_FONT_SMALL)
```

Replace with:

```lua
CyrHUD.info.fontSmall = "ZoFontGamepad27"
```

- [ ] **Step 3: Replace the width constant**

Find:

```lua
CyrHUD.width = 280
```

Replace with:

```lua
CyrHUD.width = 320
```

- [ ] **Step 4: Verify the edits**

```bash
cd /home/sammy/Public/repo/ESO
grep -n 'fontMain\|fontSmall\|CyrHUD.width' addon/CyrHUDConsole/classes/Info.lua
```

Expected output:
```
addon/CyrHUDConsole/classes/Info.lua:42:CyrHUD.width = 320
addon/CyrHUDConsole/classes/Info.lua:52:CyrHUD.info.fontMain = "ZoFontGamepad36"
addon/CyrHUDConsole/classes/Info.lua:53:CyrHUD.info.fontSmall = "ZoFontGamepad27"
```

(Line numbers may shift by ±1 if the source file changes; the three values must match.)

Confirm nothing else changed:
```bash
diff /home/sammy/Public/repo/ESO/addon/CyrHUD/classes/Info.lua \
     /home/sammy/Public/repo/ESO/addon/CyrHUDConsole/classes/Info.lua
```

Expected output: exactly three changed lines, all matching the edits above.

- [ ] **Step 5: Syntax-check**

```bash
/home/sammy/Public/repo/ESO/libs/ESOLua/src/luac -p \
  /home/sammy/Public/repo/ESO/addon/CyrHUDConsole/classes/Info.lua && echo OK
```

Expected: `OK`

- [ ] **Step 6: Commit**

```bash
cd /home/sammy/Public/repo/ESO
git add addon/CyrHUDConsole/classes/Info.lua
git commit -m "$(cat <<'EOF'
CyrHUDConsole: use gamepad fonts and wider HUD in Info.lua

Console UI doesn't load the keyboard CHAT_FONT that SI_CYRHUD_FONT
resolves to. Hardcode ZoFontGamepad36/27, which are the canonical
gamepad fonts (stable across recent API versions). Bump the panel
width from 280 to 320 so the wider gamepad glyphs don't truncate
keep names.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 3: Edit `classes/Label.lua` — taller rows for TV viewing distance

**Files:**
- Create: `addon/CyrHUDConsole/classes/Label.lua` (edited copy of `addon/CyrHUD/classes/Label.lua`)

The row height literal `35` appears twice in `Label.new`: once in `SetDimensions(CyrHUD.width, 35)` and once in the anchor expression `self.num*35-5`. Both become `42`.

- [ ] **Step 1: Copy the PC source**

```bash
cp /home/sammy/Public/repo/ESO/addon/CyrHUD/classes/Label.lua \
   /home/sammy/Public/repo/ESO/addon/CyrHUDConsole/classes/Label.lua
```

- [ ] **Step 2: Replace the dimension literal**

In `addon/CyrHUDConsole/classes/Label.lua`, find:

```lua
    self.main:SetDimensions(CyrHUD.width, 35)
```

Replace with:

```lua
    self.main:SetDimensions(CyrHUD.width, 42)
```

- [ ] **Step 3: Replace the anchor literal**

Find:

```lua
    self.main:SetAnchor(TOPLEFT, CyrHUD_UI, TOPLEFT, 0, self.num*35-5)
```

Replace with:

```lua
    self.main:SetAnchor(TOPLEFT, CyrHUD_UI, TOPLEFT, 0, self.num*42-5)
```

- [ ] **Step 4: Verify both edits and that nothing else changed**

```bash
cd /home/sammy/Public/repo/ESO
diff addon/CyrHUD/classes/Label.lua addon/CyrHUDConsole/classes/Label.lua
```

Expected output: exactly two changed lines, both showing 35 → 42 in the contexts above.

```bash
grep -c "35" addon/CyrHUDConsole/classes/Label.lua
```

Expected output: `0` — the file should have no remaining literal `35`. (If the count is nonzero, check whether something legitimate like `img35`/`txt35` appears; in that case use `grep -n '\b35\b'` and only the row-height instances must be 42.)

- [ ] **Step 5: Syntax-check**

```bash
/home/sammy/Public/repo/ESO/libs/ESOLua/src/luac -p \
  /home/sammy/Public/repo/ESO/addon/CyrHUDConsole/classes/Label.lua && echo OK
```

Expected: `OK`

- [ ] **Step 6: Commit**

```bash
cd /home/sammy/Public/repo/ESO
git add addon/CyrHUDConsole/classes/Label.lua
git commit -m "$(cat <<'EOF'
CyrHUDConsole: 42px row height in Label.lua

Gamepad fonts (ZoFontGamepad36/27, set in Info.lua) need taller rows
to avoid clipping. 35 -> 42, applied to both the SetDimensions call
and the per-row vertical anchor expression in Label.new.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 4: Create the trimmed `CyrHUD.lua`

**Files:**
- Create: `addon/CyrHUDConsole/CyrHUD.lua` (edited copy of `addon/CyrHUD/CyrHUD.lua`)

This is the biggest task. We copy the PC `CyrHUD.lua` and apply six surgical edits:

1. Remove `saveWindowPosition` (a top-level function).
2. Remove `disableQuestTrackers` / `reEnableQuestTrackers` and their call sites.
3. Remove drag handlers from `addonInit`.
4. Replace freeform anchor reading with preset-lookup logic + a new `applyAnchorPreset` helper.
5. Trim `cfg` defaults: drop position fields and quest-tracker flags; add `position = "TOP_RIGHT"`.
6. Switch SavedVariables namespace + remove the `/cyrhud` slash and the `CyrHUD.toggle` function.

All other code (events, keep scanning, battles, graveyards, etc.) is preserved verbatim.

- [ ] **Step 1: Copy the PC source as a starting point**

```bash
cp /home/sammy/Public/repo/ESO/addon/CyrHUD/CyrHUD.lua \
   /home/sammy/Public/repo/ESO/addon/CyrHUDConsole/CyrHUD.lua
```

- [ ] **Step 2: Add the ANCHOR_PRESETS table and `applyAnchorPreset` helper near the top**

Find this block near line 27 (after the `keepsToObjectivesMap = {}` line):

```lua
CyrHUD.keepsToObjectivesMap = {}
```

Insert immediately **before** that line:

```lua
----------------------------------------------
-- Console anchor presets
----------------------------------------------
CyrHUD.ANCHOR_PRESETS = {
    TOP_RIGHT    = { self = TOPRIGHT,    anchor = TOPRIGHT,    x = -40, y =   80 },
    TOP_LEFT     = { self = TOPLEFT,     anchor = TOPLEFT,     x =  40, y =   80 },
    MIDDLE_RIGHT = { self = RIGHT,       anchor = RIGHT,       x = -40, y =    0 },
    MIDDLE_LEFT  = { self = LEFT,        anchor = LEFT,        x =  40, y =    0 },
    BOTTOM_RIGHT = { self = BOTTOMRIGHT, anchor = BOTTOMRIGHT, x = -40, y = -120 },
    BOTTOM_LEFT  = { self = BOTTOMLEFT,  anchor = BOTTOMLEFT,  x =  40, y = -120 },
}

function CyrHUD.applyAnchorPreset()
    if not CyrHUD.ui then return end
    local key = CyrHUD.cfg and CyrHUD.cfg.position or "TOP_RIGHT"
    local preset = CyrHUD.ANCHOR_PRESETS[key] or CyrHUD.ANCHOR_PRESETS.TOP_RIGHT
    CyrHUD.ui:ClearAnchors()
    CyrHUD.ui:SetAnchor(preset.self, GuiRoot, preset.anchor, preset.x, preset.y)
end

```

- [ ] **Step 3: Remove `saveWindowPosition`**

Find this entire function and delete it (the whole block, including the trailing blank line):

```lua
function CyrHUD.saveWindowPosition( window )
    local _, sP, _, aP, x, y = window:GetAnchor()
    CyrHUD.cfg.anchPoint = aP
    CyrHUD.cfg.selfPoint = sP
    CyrHUD.cfg.xoff = x
    CyrHUD.cfg.yoff = y
end
```

- [ ] **Step 4: Remove the two quest-tracker calls inside `init`**

In `CyrHUD:init()`, find:

```lua
    --Init UI
    self:disableQuestTrackers()
    self.ui:SetHidden(false)
```

Replace with:

```lua
    --Init UI
    self.ui:SetHidden(false)
```

- [ ] **Step 5: Remove the disable/reEnable tracker block from `refresh`**

In `CyrHUD:refresh()`, find:

```lua
	if self.campaign ~= GetCurrentCampaignId() then 
	    self:disableQuestTrackers()
	    CyrHUD.imperialKeeps = nil -- reset imperial keeps/ Imperial City Districts
```

Replace with (drop only the `self:disableQuestTrackers()` call, preserve the rest):

```lua
	if self.campaign ~= GetCurrentCampaignId() then 
	    CyrHUD.imperialKeeps = nil -- reset imperial keeps/ Imperial City Districts
```

- [ ] **Step 6: Remove the `disableQuestTrackers` and `reEnableQuestTrackers` function bodies**

Delete this entire block (both functions, including any leading/trailing blank lines that belong to them):

```lua
function CyrHUD:disableQuestTrackers()
    self.trackers = self.trackers or {}

    if IsInCyrodiil() then
		--Ravalox Questtracker
		if QuestTrackerWin then
			self.trackers.QuestTrackerWin = self.trackers.QuestTrackerWin or QuestTrackerWin:IsHidden() -- Tracker hidden state before CyrHUD init to restore on CyrHUD deinit  
			QuestTrackerWin:SetHidden(self.cfg.ravTrackerDisableCyro)
		end

		--ZOs build in game quest tracker
		self.trackers.ZO_FocusedQuestTrackerPanel = self.trackers.ZO_FocusedQuestTrackerPanel or ZO_FocusedQuestTrackerPanel:IsHidden() -- Tracker hidden state before CyrHUD init to restore on CyrHUD deinit  
		ZO_FocusedQuestTrackerPanel:SetHidden(self.cfg.zosTrackerDisableCyro)
		
	elseif IsInImperialCity() then
		--Ravalox Questtracker
		if QuestTrackerWin then
			self.trackers.QuestTrackerWin = self.trackers.QuestTrackerWin or QuestTrackerWin:IsHidden() -- Tracker hidden state before CyrHUD init to restore on CyrHUD deinit  
			QuestTrackerWin:SetHidden(self.cfg.ravTrackerDisableIC)
		end

		--ZOs build in game quest tracker
		self.trackers.ZO_FocusedQuestTrackerPanel = self.trackers.ZO_FocusedQuestTrackerPanel or ZO_FocusedQuestTrackerPanel:IsHidden() -- Tracker hidden state before CyrHUD init to restore on CyrHUD deinit  
		ZO_FocusedQuestTrackerPanel:SetHidden(self.cfg.zosTrackerDisableIC)
	end
end

function CyrHUD:reEnableQuestTrackers()
    if self.trackers then
        for k,v in pairs(self.trackers) do
            if _G[k] ~= nil then _G[k]:SetHidden(false) end
        end
    end
end
```

- [ ] **Step 7: Remove the `self:reEnableQuestTrackers()` call from `deinit`**

In `CyrHUD:deinit()`, find:

```lua
function CyrHUD:deinit()
    self:reEnableQuestTrackers()

    EVENT_MANAGER:UnregisterForUpdate(CyrHUD.addonVars.name.."KeepCheck")
```

Replace with:

```lua
function CyrHUD:deinit()
    EVENT_MANAGER:UnregisterForUpdate(CyrHUD.addonVars.name.."KeepCheck")
```

- [ ] **Step 8: Remove the `CyrHUD.toggle` function and slash command**

Find:

```lua
function CyrHUD.toggle()
    local self = CyrHUD

    if self.visible then
        self:deinit()
    else
        self:init()
    end
end


SLASH_COMMANDS["/cyrhud"] = CyrHUD.toggle
```

Delete the entire block (function + the slash registration line).

- [ ] **Step 9: Update `addonInit` defaults**

In `CyrHUD.addonInit`, find:

```lua
    --Init saved variables
    local def = {
        xoff = -10,
        yoff = 60,
        ravTrackerDisableCyro = false,
		zosTrackerDisableCyro = false,
		ravTrackerDisableIC = false,
		zosTrackerDisableIC = false,
		hideImpBattles = false,
		hideBridgesAndMilegates = false,
		hidePatrollingHorrors = false,
		enableInCyro = true,
		enableInIC = true,
        showPopBars = false,
    }

    self.cfg = ZO_SavedVars:NewAccountWide("CyrHUD_SavedVars", 1.0, "config", def)
```

Replace with:

```lua
    --Init saved variables
    local def = {
        position = "TOP_RIGHT",
        hideImpBattles = false,
        hideBridgesAndMilegates = false,
        hidePatrollingHorrors = false,
        enableInCyro = true,
        enableInIC = true,
        showPopBars = false,
    }

    self.cfg = ZO_SavedVars:NewAccountWide("CyrHUDConsole_SavedVars", 1.0, "config", def)
```

- [ ] **Step 10: Strip drag handlers and replace anchor block in `addonInit`**

Find:

```lua
    --Create UI
    self.ui = WINDOW_MANAGER:CreateTopLevelWindow("CyrHUD_UI")
    self.ui:SetWidth(CyrHUD.width)
    self.ui:SetMouseEnabled(true)
    self.ui:SetMovable(true)
    self.ui:SetClampedToScreen(true)
    self.ui:SetHandler("OnMoveStop", self.saveWindowPosition)

    --local _, pt, relTo, relPt = CyrHUD_UI:GetAnchor()
    self.ui:ClearAnchors()
    self.ui:SetAnchor(CyrHUD.cfg.selfPoint or TOPLEFT,
        GuiRoot, CyrHUD.cfg.anchPoint or TOPRIGHT,
        CyrHUD.cfg.xoff, CyrHUD.cfg.yoff)
```

Replace with:

```lua
    --Create UI (console: no mouse, no drag)
    self.ui = WINDOW_MANAGER:CreateTopLevelWindow("CyrHUD_UI")
    self.ui:SetWidth(CyrHUD.width)
    self.ui:SetClampedToScreen(true)

    CyrHUD.applyAnchorPreset()
```

- [ ] **Step 11: Replace the LibAddonMenu registration with a settings.lua hand-off**

Still in `addonInit`, find:

```lua
    --Create settings menu
    local LAM = LibAddonMenu2
    LAM:RegisterAddonPanel(CyrHUD.addonVars.name .. "-LAM", self.menuPanel)
    LAM:RegisterOptionControls(CyrHUD.addonVars.name .. "-LAM", self.menuOptions)
    self.initLAM = true
```

Replace with:

```lua
    --Create settings menu (console: Harvens — see settings.lua)
    if CyrHUD.registerSettings then
        CyrHUD.registerSettings()
    end
    self.initLAM = true  -- name kept so playerInit() below still no-ops on re-entry
```

(The `initLAM` name is kept literally because `playerInit` checks `if not self.initLAM then self.addonInit() end`. Renaming would need a second edit; keeping it is harmless.)

- [ ] **Step 12: Remove the commented April-fools block at the end of `addonInit`**

Find the trailing commented block in `addonInit`:

```lua
    --[[if (GetDate() % 1000)== 401 then
        --NOTE: If you see this before 4/1, please don't share
        table.insert(self.menuOptions,{
            type = "checkbox",
            name = GetString(SI_CYRHUD_APRIL1),
            tooltip = GetString(SI_CYRHUD_APRIL1_TOOLTIP),
            getFunc = function() return CyrHUD.cfg.aprOff or false end,
            setFunc = function(v) CyrHUD.cfg.aprOff = v; CyrHUD:refresh() end,
        })
    end]]
```

Delete the entire commented block. (It references `self.menuOptions`, which no longer exists.)

- [ ] **Step 13: Static-syntax-check the result**

```bash
/home/sammy/Public/repo/ESO/libs/ESOLua/src/luac -p \
  /home/sammy/Public/repo/ESO/addon/CyrHUDConsole/CyrHUD.lua && echo OK
```

Expected: `OK`. If it fails, the error message names a line number — use Read on that line to see what's malformed.

- [ ] **Step 14: Audit that the right things are gone and the right things are present**

```bash
cd /home/sammy/Public/repo/ESO
echo "== should be EMPTY =="
grep -nE 'SetMouseEnabled|SetMovable|OnMoveStop|saveWindowPosition|disableQuestTrackers|reEnableQuestTrackers|QuestTrackerWin|ZO_FocusedQuestTrackerPanel|LibAddonMenu2|LAM:Register|SLASH_COMMANDS\["/cyrhud"\]|menuOptions|menuPanel|CyrHUD_SavedVars' addon/CyrHUDConsole/CyrHUD.lua
echo "== should be NON-EMPTY =="
grep -nE 'ANCHOR_PRESETS|applyAnchorPreset|CyrHUDConsole_SavedVars|registerSettings|position = "TOP_RIGHT"' addon/CyrHUDConsole/CyrHUD.lua
```

Expected output:
- The first grep must print **nothing** after the `== should be EMPTY ==` header. If it prints anything, the trim is incomplete — go back to the relevant step.
- The second grep must print **at least 5 matches** after the `== should be NON-EMPTY ==` header.

- [ ] **Step 15: Commit**

```bash
cd /home/sammy/Public/repo/ESO
git add addon/CyrHUDConsole/CyrHUD.lua
git commit -m "$(cat <<'EOF'
CyrHUDConsole: strip keyboard-only code from CyrHUD.lua

Six surgical edits relative to the PC source:
- new ANCHOR_PRESETS table + applyAnchorPreset() helper
- saveWindowPosition() removed (no drag on console)
- disableQuestTrackers/reEnableQuestTrackers and call sites removed
  (the PC tracker globals don't exist in the gamepad UI)
- mouse/move handlers stripped from addonInit
- cfg defaults reduced; SavedVars renamed to CyrHUDConsole_SavedVars;
  freeform anchor replaced with cfg.position dropdown key
- CyrHUD.toggle() and SLASH_COMMANDS["/cyrhud"] removed; lifecycle
  is now driven entirely by playerInit() reacting to AvA presence.

LAM registration is replaced by a call to CyrHUD.registerSettings()
which settings.lua (next commit) will define.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 5: Create `settings.lua` — Harvens panel

**Files:**
- Create: `addon/CyrHUDConsole/settings.lua`

This module exposes `CyrHUD.registerSettings()`, which `CyrHUD.lua` calls during `addonInit`. It builds one Harvens panel with two sections and seven controls.

- [ ] **Step 1: Write the file**

Write `addon/CyrHUDConsole/settings.lua` with this content:

```lua
-- CyrHUDConsole settings.lua — Harvens panel
-- Replaces the PC menu.lua (LibAddonMenu-2) since LAM doesn't exist on console.

CyrHUD = CyrHUD or {}

local POSITION_ITEMS = {
    { name = "TOP_RIGHT"    },
    { name = "TOP_LEFT"     },
    { name = "MIDDLE_RIGHT" },
    { name = "MIDDLE_LEFT"  },
    { name = "BOTTOM_RIGHT" },
    { name = "BOTTOM_LEFT"  },
}

function CyrHUD.registerSettings()
    if CyrHUD._settingsRegistered then return end
    CyrHUD._settingsRegistered = true

    local LHAS = LibHarvensAddonSettings
    if not LHAS then
        d("|cFF0000[CyrHUDConsole] LibHarvensAddonSettings not loaded — settings panel unavailable")
        return
    end

    local panel = LHAS:AddAddon("CyrHUD", { allowDefaults = true })

    panel:AddSetting({
        type = LHAS.ST_SECTION,
        label = GetString(SI_CAMPAIGNRULESETTYPE1),   -- "Cyrodiil"
    })

    panel:AddSetting({
        type = LHAS.ST_CHECKBOX,
        label = GetString(SI_ITEM_ACTION_USE) .. " CyrHUD",
        default = true,
        getFunction = function() return CyrHUD.cfg.enableInCyro end,
        setFunction = function(v) CyrHUD.cfg.enableInCyro = v; CyrHUD.playerInit() end,
    })

    panel:AddSetting({
        type = LHAS.ST_CHECKBOX,
        label = GetString(SI_CYRHUD_POPBAR),
        tooltip = GetString(SI_CYRHUD_POPBAR_INFO),
        default = false,
        getFunction = function() return CyrHUD.cfg.showPopBars end,
        setFunction = function(v) CyrHUD.cfg.showPopBars = v; CyrHUD:reconfigureLabels() end,
    })

    panel:AddSetting({
        type = LHAS.ST_CHECKBOX,
        label = GetString(SI_CYRHUD_HIDE_BRIDGESANDMILEGATES),
        tooltip = GetString(SI_CYRHUD_HIDE_BRIDGESANDMILEGATES_INFO),
        default = false,
        getFunction = function() return CyrHUD.cfg.hideBridgesAndMilegates end,
        setFunction = function(v) CyrHUD.cfg.hideBridgesAndMilegates = v; CyrHUD:reconfigureLabels() end,
    })

    panel:AddSetting({
        type = LHAS.ST_SECTION,
        label = GetString(SI_CAMPAIGNRULESETTYPE4),   -- "Imperial City"
    })

    panel:AddSetting({
        type = LHAS.ST_CHECKBOX,
        label = GetString(SI_ITEM_ACTION_USE) .. " CyrHUD",
        default = true,
        getFunction = function() return CyrHUD.cfg.enableInIC end,
        setFunction = function(v) CyrHUD.cfg.enableInIC = v; CyrHUD.playerInit() end,
    })

    panel:AddSetting({
        type = LHAS.ST_CHECKBOX,
        label = GetString(SI_CYRHUD_HIDE_IC),
        tooltip = GetString(SI_CYRHUD_HIDE_IC_INFO),
        default = false,
        getFunction = function() return CyrHUD.cfg.hideImpBattles end,
        setFunction = function(v) CyrHUD.cfg.hideImpBattles = v; CyrHUD:reconfigureLabels() end,
    })

    panel:AddSetting({
        type = LHAS.ST_CHECKBOX,
        label = GetString(SI_GAMECAMERAACTIONTYPE24) .. " " ..
                GetString(SI_CAMPAIGNRULESETTYPE4) .. " " ..
                GetString(SI_CUSTOMERSERVICESUBMITFEEDBACKSUBCATEGORIES501),
        default = false,
        getFunction = function() return CyrHUD.cfg.hidePatrollingHorrors end,
        setFunction = function(v)
            CyrHUD.cfg.hidePatrollingHorrors = v
            CyrHUD:refresh()
            CyrHUD:reconfigureLabels()
        end,
    })

    panel:AddSetting({
        type = LHAS.ST_SECTION,
        label = "Display",
    })

    panel:AddSetting({
        type = LHAS.ST_DROPDOWN,
        label = "HUD position",
        items = POSITION_ITEMS,
        default = "TOP_RIGHT",
        getFunction = function() return CyrHUD.cfg.position end,
        setFunction = function(_, _, data)
            CyrHUD.cfg.position = data.name
            CyrHUD.applyAnchorPreset()
        end,
    })
end
```

Notes for the implementer:
- Harvens' dropdown `setFunction` signature is `(combobox, name, data)` — we use only `data.name` (the third arg) because that's the stable identifier.
- Harvens' `items` for `ST_DROPDOWN` is a list of tables, each with a `name` field. The library passes them straight to `ZO_ComboBox:AddEntry` which expects that shape (verified in `libs/LibHarvensAddonSettings/Console/Settings.lua:147–151`).
- The string IDs (`SI_CAMPAIGNRULESETTYPE1`, `SI_CYRHUD_POPBAR`, etc.) are the same ones the PC menu used, defined in `lang/en.lua` (copied verbatim in Task 1) and the localized files.

- [ ] **Step 2: Syntax-check**

```bash
/home/sammy/Public/repo/ESO/libs/ESOLua/src/luac -p \
  /home/sammy/Public/repo/ESO/addon/CyrHUDConsole/settings.lua && echo OK
```

Expected: `OK`

- [ ] **Step 3: Audit**

```bash
cd /home/sammy/Public/repo/ESO
grep -c "LibHarvensAddonSettings\|LHAS" addon/CyrHUDConsole/settings.lua
grep -c "LibAddonMenu" addon/CyrHUDConsole/settings.lua
```

Expected: first command prints a number ≥ 8; second command prints `0`.

- [ ] **Step 4: Commit**

```bash
cd /home/sammy/Public/repo/ESO
git add addon/CyrHUDConsole/settings.lua
git commit -m "$(cat <<'EOF'
CyrHUDConsole: add Harvens settings panel

settings.lua replaces the PC menu.lua. Exposes CyrHUD.registerSettings()
which CyrHUD.lua calls during addonInit. One panel, three sections
(Cyrodiil / Imperial City / Display), seven controls — same options
as the PC menu minus the quest-tracker submenu (not relevant on
console). The HUD position dropdown writes cfg.position and calls
applyAnchorPreset() so the move is visible immediately.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 6: Create `CyrHUDConsole.addon` manifest

**Files:**
- Create: `addon/CyrHUDConsole/CyrHUDConsole.addon`

- [ ] **Step 1: Write the manifest**

Write `addon/CyrHUDConsole/CyrHUDConsole.addon`:

```
## APIVersion: 101049
## Title: CyrHUD (Console)
## Version: 2026.05.17
## Author: Sasky, |c4779ce@aldericon|r, |c3CB371@Masteroshi430|r — console port
## SavedVariables: CyrHUDConsole_SavedVars
## DependsOn: LibHarvensAddonSettings>=20107

lang/en.lua
lang/$(language).lua

classes/Info.lua
classes/Label.lua
classes/Battle.lua
classes/MovingObjectives.lua
classes/Graveyards.lua
classes/PatrollingHorrors.lua
classes/ScoringBar.lua
classes/RankingBar.lua
classes/Locations.lua

CyrHUD.lua
settings.lua
```

Differences from the PC `CyrHUD.addon`:
- Title gains `" (Console)"` suffix.
- SavedVariables → `CyrHUDConsole_SavedVars`.
- DependsOn → `LibHarvensAddonSettings>=20107` (was LAM).
- `bindings.xml` not listed.
- `menu.lua` not listed; `settings.lua` added.

- [ ] **Step 2: Verify the manifest mentions only files we actually shipped**

```bash
cd /home/sammy/Public/repo/ESO/addon/CyrHUDConsole
echo "== files referenced in manifest =="
grep -E '\.(lua|xml)$' CyrHUDConsole.addon | sort
echo "== files on disk =="
find . -name '*.lua' -not -path './lang/*' | sort
find . -path './lang/*.lua' | sort
```

Expected: every `.lua` listed in the manifest's load order exists on disk. (The `lang/$(language).lua` line is templated — that's expected.)

- [ ] **Step 3: Commit**

```bash
cd /home/sammy/Public/repo/ESO
git add addon/CyrHUDConsole/CyrHUDConsole.addon
git commit -m "$(cat <<'EOF'
CyrHUDConsole: add manifest

Console-targeted manifest: DependsOn swaps LibAddonMenu-2.0 -> Lib-
HarvensAddonSettings. SavedVariables namespace is CyrHUDConsole_-
SavedVars so it can never collide with the PC build's saves. The
bindings.xml and menu.lua entries are absent because the console
port doesn't ship those files.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 7: Final cross-cutting verification

This task contains no edits — it's the end-to-end verification described in the spec's "Verification plan" section. Run all checks; if any fail, return to the relevant task above.

- [ ] **Step 1: Syntax-check every Lua file in the console build**

```bash
cd /home/sammy/Public/repo/ESO
fail=0
for f in addon/CyrHUDConsole/*.lua addon/CyrHUDConsole/classes/*.lua addon/CyrHUDConsole/lang/*.lua; do
    libs/ESOLua/src/luac -p "$f" || { echo "FAIL: $f"; fail=1; }
done
echo "syntax_fail=$fail"
```

Expected: `syntax_fail=0`.

- [ ] **Step 2: Negative audit — keyboard-mode code is gone**

```bash
cd /home/sammy/Public/repo/ESO
grep -rnE 'SetMouseEnabled|SetMovable|OnMoveStop|SLASH_COMMANDS\["/cyrhud"\]|LibAddonMenu2|LAM:Register|QuestTrackerWin|ZO_FocusedQuestTrackerPanel' addon/CyrHUDConsole/
```

Expected: **no output**. If anything matches, the corresponding edit in Tasks 2–5 didn't land.

- [ ] **Step 3: Positive audit — console replacements landed**

```bash
cd /home/sammy/Public/repo/ESO
grep -rnE 'LibHarvensAddonSettings|ZoFontGamepad|ANCHOR_PRESETS|applyAnchorPreset|cfg\.position|CyrHUDConsole_SavedVars' addon/CyrHUDConsole/
```

Expected: **multiple matches** (at least one each of the six tokens above).

- [ ] **Step 4: Diff sanity — verbatim copies really are verbatim**

```bash
cd /home/sammy/Public/repo/ESO
ok=1
for f in classes/Battle.lua classes/Graveyards.lua classes/Locations.lua classes/MovingObjectives.lua classes/PatrollingHorrors.lua classes/RankingBar.lua classes/ScoringBar.lua lang/en.lua lang/de.lua lang/fr.lua lang/jp.lua lang/ru.lua lang/zh.lua LICENSE GPLv2; do
    if ! cmp -s "addon/CyrHUD/$f" "addon/CyrHUDConsole/$f"; then
        echo "DIVERGED: $f"; ok=0
    fi
done
echo "verbatim_ok=$ok"
```

Expected: `verbatim_ok=1`.

- [ ] **Step 5: Expected divergence — Info.lua and Label.lua differ from PC**

```bash
cd /home/sammy/Public/repo/ESO
cmp -s addon/CyrHUD/classes/Info.lua  addon/CyrHUDConsole/classes/Info.lua  && echo "BUG: Info.lua should differ"
cmp -s addon/CyrHUD/classes/Label.lua addon/CyrHUDConsole/classes/Label.lua && echo "BUG: Label.lua should differ"
echo "checked"
```

Expected: only `checked` printed. Any `BUG:` line means an edit was reverted.

- [ ] **Step 6: Manifest sanity**

```bash
cd /home/sammy/Public/repo/ESO
test -f addon/CyrHUDConsole/CyrHUDConsole.addon && echo "manifest_present=1"
grep -c "LibHarvensAddonSettings" addon/CyrHUDConsole/CyrHUDConsole.addon
grep -c "LibAddonMenu" addon/CyrHUDConsole/CyrHUDConsole.addon
test ! -f addon/CyrHUDConsole/bindings.xml && echo "no_bindings_xml=1"
test ! -f addon/CyrHUDConsole/menu.lua && echo "no_menu_lua=1"
```

Expected:
```
manifest_present=1
1
0
no_bindings_xml=1
no_menu_lua=1
```

- [ ] **Step 7: Confirm PC source was not touched**

Use the spec commit as the baseline — every Task commit lands after it:

```bash
cd /home/sammy/Public/repo/ESO
SPEC_COMMIT=$(git log --format=%H --grep='design spec for CyrHUD console port' -n1)
echo "baseline: $SPEC_COMMIT"
git diff "$SPEC_COMMIT"..HEAD --name-only -- addon/CyrHUD/
```

Expected: the `baseline:` line prints a SHA, and the `git diff` produces **no output**. Anything in `addon/CyrHUD/` (without the `Console` suffix) means a Task accidentally modified the PC source — revert the offending commit before continuing.

- [ ] **Step 8: Tag the work**

```bash
cd /home/sammy/Public/repo/ESO
git tag -a cyrhud-console-v2026.05.17 -m "Initial console port of CyrHUD"
git log --oneline -10
```

Expected: a tag named `cyrhud-console-v2026.05.17` pointing at the last commit, and a clean linear history of the seven Task commits + the original spec commit.

---

## Post-implementation handoff

The console build can be sanity-checked at runtime by the user on a console / gamepad-mode PTS install. A one-line debug print is **not** added by this plan (the spec's optional `d("[CyrHUDConsole] loaded …")` was descoped to keep the trim minimal). If the user wants it, add this single line at the end of `CyrHUDConsole/CyrHUD.lua`:

```lua
d("[CyrHUDConsole] loaded — IsConsoleUI=" .. tostring(IsConsoleUI and IsConsoleUI() or false))
```

(Not a required step — only do this if the user asks.)

# CyrHUD console port — design

**Date:** 2026-05-17
**Status:** Approved (brainstorming)
**Source addon:** `addon/CyrHUD/` (PC, API 101049, v2026.04.12)
**Target:** `addon/CyrHUDConsole/` — a separate, standalone console-only addon

## Goal

Produce a console-compatible fork of CyrHUD. The fork drops all keyboard-mode
code paths (mouse drag, LibAddonMenu-2, keyboard quest-tracker hacks,
keyboard fonts) and replaces the affected pieces with console-friendly
equivalents. The PC version is left untouched.

## Non-goals

- A unified codebase that drives both PC and console. (Explicitly out of
  scope — the user chose "console-only fork".)
- Rewriting the rendering classes. They already use console-compatible
  primitives (`WINDOW_MANAGER:CreateControl`, `CT_BACKDROP`, `CT_TEXTURE`,
  `CT_LABEL`).
- New features beyond what the PC addon already provides.

## Background

CyrHUD is a Cyrodiil/Imperial City PvP HUD. It draws a stack of rows
showing:
- Active keep/outpost/town battles with attacker/defender info
- Held elder scrolls and Volendrung carriers (moving objectives)
- Recent kill clusters per location (graveyards)
- Imperial City patrolling-horror boss timers
- Campaign scoring bar and per-character ranking bar

On PC, the HUD is a top-level mouse-draggable window. Settings live in a
LibAddonMenu-2 panel; a `/cyrhud` slash command and a `CYRHUD_TOGGLE`
keybind hide/show the window.

These four things are PC-only:
1. **LibAddonMenu-2** — no addon settings page exists on console.
2. **`bindings.xml`** — works on console but is being dropped per the
   "always-on while in AvA" decision.
3. **`SetMouseEnabled` / `SetMovable` / `OnMoveStop`** — there is no
   mouse on console; the drag flow is impossible.
4. **Keyboard font lookups (`SI_CYRHUD_FONT`)** — resolve to keyboard
   fonts that are unreadable on a TV at couch distance.

Everything else (the `classes/` rendering layer, the saved-variable
schema apart from the position fields, all event subscriptions) is
already console-safe.

## Deployment shape

A **side-by-side copy with surgical edits**. The new addon lives at
`addon/CyrHUDConsole/` and ships independently. The `classes/`, `lang/`,
and `textures/` folders are copied verbatim from PC. Only the manifest,
`CyrHUD.lua`, `Info.lua`, and the settings file diverge.

The global Lua namespace stays `CyrHUD` (so the copied `classes/`
files work unchanged). SavedVariables use a distinct name
(`CyrHUDConsole_SavedVars`) so the PC and console builds cannot collide
if a future tool ever extracts saves cross-platform.

```
addon/CyrHUDConsole/
├── CyrHUDConsole.addon       NEW — rewritten manifest
├── CyrHUD.lua                MODIFIED — see "Trims" below
├── settings.lua              NEW — replaces menu.lua, uses Harvens
├── classes/
│   ├── Battle.lua            copied verbatim
│   ├── Graveyards.lua        copied verbatim
│   ├── Info.lua              MODIFIED — fonts + width
│   ├── Label.lua             MODIFIED — row height literal
│   ├── Locations.lua         copied verbatim
│   ├── MovingObjectives.lua  copied verbatim
│   ├── PatrollingHorrors.lua copied verbatim
│   ├── RankingBar.lua        copied verbatim
│   └── ScoringBar.lua        copied verbatim
├── lang/                     copied verbatim (en/de/fr/jp/ru/zh)
├── textures/                 copied verbatim
├── LICENSE                   copied
└── GPLv2                     copied
```

Files **not** present in the console build: `bindings.xml`, `menu.lua`.

### Manifest

```
## Title: CyrHUD (Console)
## APIVersion: 101049
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

Differences from `CyrHUD.addon`:
- `## SavedVariables` namespace changed.
- `## DependsOn` swaps `LibAddonMenu-2.0>=40` → `LibHarvensAddonSettings>=20107`.
- `bindings.xml` and `menu.lua` lines removed; `settings.lua` added.

## What gets stripped from CyrHUD.lua

Located in the file by line in the current PC source for the implementer:

| Location | What | Why |
|---|---|---|
| `addonInit` (around L1071–1074) | `SetMouseEnabled(true)`, `SetMovable(true)`, `SetHandler("OnMoveStop", …)` | No mouse on console. |
| `saveWindowPosition` (around L452–458) | Whole function | Drag is gone, so there's nothing to save. |
| `disableQuestTrackers` / `reEnableQuestTrackers` (around L977–1010) | Both functions and their call sites in `init` (around L823) and `deinit` (around L1013) | `QuestTrackerWin` is a PC-only third-party addon; `ZO_FocusedQuestTrackerPanel` is the keyboard tracker. Console has its own. |
| `bindings.xml` + the `CyrHUD.toggle` slash binding (around L1033–1044) | Delete keybind file; drop `SLASH_COMMANDS["/cyrhud"]` registration; keep `CyrHUD.toggle` function only if used internally (it isn't, once auto-show owns lifecycle) | Per "always on while in AvA + setting toggle" decision. |
| `playerInit` zone/AvA gating (around L1100–1125) | Keep — this already does auto-show/hide based on `IsPlayerInAvAWorld()`, `IsInImperialCity()`, and the per-zone enable flags. This becomes the **only** way the HUD is shown. |
| `cfg` defaults (around L1051–1064) | Remove `xoff`, `yoff`, `anchPoint`, `selfPoint`, `ravTrackerDisableCyro`, `zosTrackerDisableCyro`, `ravTrackerDisableIC`, `zosTrackerDisableIC`. Add `position = "TOP_RIGHT"`. |
| Anchor setup (around L1077–1080) | Read from preset table instead of `cfg.xoff/yoff/anchPoint/selfPoint`. |

The remaining 90 %+ of `CyrHUD.lua` (event registration, keep-scanning,
battle/objective/graveyard/horror lifecycle, status-bar refresh,
`printAll` ordering by keep type, etc.) is unchanged.

## Anchor preset system

Replace the freeform anchor save state with a single string-valued
`position` setting. The mapping table lives in `CyrHUD.lua`:

```lua
CyrHUD.ANCHOR_PRESETS = {
    TOP_RIGHT     = { self = TOPRIGHT,    anchor = TOPRIGHT,    x = -40,  y =  80 },
    TOP_LEFT      = { self = TOPLEFT,     anchor = TOPLEFT,     x =  40,  y =  80 },
    MIDDLE_RIGHT  = { self = RIGHT,       anchor = RIGHT,       x = -40,  y =   0 },
    MIDDLE_LEFT   = { self = LEFT,        anchor = LEFT,        x =  40,  y =   0 },
    BOTTOM_RIGHT  = { self = BOTTOMRIGHT, anchor = BOTTOMRIGHT, x = -40,  y = -120 },
    BOTTOM_LEFT   = { self = BOTTOMLEFT,  anchor = BOTTOMLEFT,  x =  40,  y = -120 },
}
```

Rationale for the offsets:
- 40 px lateral inset clears typical TV overscan (~5 %).
- 80 px top inset clears the gamepad compass + buff icons.
- 120 px bottom inset clears the gamepad ability bar + ultimate.

Applied in `addonInit` (replacing the freeform anchor block):

```lua
local preset = CyrHUD.ANCHOR_PRESETS[CyrHUD.cfg.position]
                or CyrHUD.ANCHOR_PRESETS.TOP_RIGHT
self.ui:ClearAnchors()
self.ui:SetAnchor(preset.self, GuiRoot, preset.anchor, preset.x, preset.y)
```

The setting panel exposes a dropdown of the six keys, with the values
re-anchored immediately on change (via `CyrHUD.ui:ClearAnchors()` +
`SetAnchor` in the Harvens `setFunction`).

## Font / sizing changes

`classes/Info.lua`:

```lua
CyrHUD.info.fontMain  = "ZoFontGamepad36"   -- was GetString(SI_CYRHUD_FONT)
CyrHUD.info.fontSmall = "ZoFontGamepad27"   -- was GetString(SI_CYRHUD_FONT_SMALL)
CyrHUD.width          = 320                  -- was 280
```

`classes/Label.lua` (in `Label.new`, line ~46): row height literal
`35` → `42`, and the `self.num*35-5` anchor expression follows.
That's the only structural change in `Label.lua`.

No texture or color changes. The DDS files in `textures/` and the
`/esoui/art/...` lookups in `Info.lua` work the same on both platforms.

## Settings panel (LibHarvensAddonSettings)

`settings.lua` (new file). Single panel, six options grouped under two
headers, mirroring the PC menu minus the quest-tracker submenu:

```
[Cyrodiil]
  ☐ Enable in Cyrodiil
  ☐ Show population bars
  ☐ Hide bridges and milegates

[Imperial City]
  ☐ Enable in Imperial City
  ☐ Hide Imperial City district battles
  ☐ Hide patrolling horrors

[Display]
  HUD position: [ TOP_RIGHT ▼ ]
```

Implementation pattern (Harvens — see
`libs/LibHarvensAddonSettings/Main.lua`):

```lua
local settings = LibHarvensAddonSettings:AddAddon("CyrHUD")
settings.allowDefaults = true

settings:AddSetting({
    type    = LibHarvensAddonSettings.ST_CHECKBOX,
    label   = GetString(SI_ITEM_ACTION_USE) .. " CyrHUD (Cyrodiil)",
    default = true,
    getFunction = function() return CyrHUD.cfg.enableInCyro end,
    setFunction = function(v) CyrHUD.cfg.enableInCyro = v; CyrHUD.playerInit() end,
})
-- ... (one block per option) ...

settings:AddSetting({
    type    = LibHarvensAddonSettings.ST_DROPDOWN,
    label   = "HUD position",
    default = "TOP_RIGHT",
    items   = { "TOP_RIGHT", "TOP_LEFT", "MIDDLE_RIGHT",
                "MIDDLE_LEFT", "BOTTOM_RIGHT", "BOTTOM_LEFT" },
    getFunction = function() return CyrHUD.cfg.position end,
    setFunction = function(v)
        CyrHUD.cfg.position = v
        CyrHUD.applyAnchorPreset()    -- helper added in CyrHUD.lua
    end,
})
```

`CyrHUD.applyAnchorPreset()` is a small new function that re-runs the
anchor block from `addonInit` so the dropdown updates the HUD live.

## Init flow

```
EVENT_ADD_ON_LOADED("CyrHUDConsole")
  └─ CyrHUD.addonInit()
       ├─ ZO_SavedVars:NewAccountWide("CyrHUDConsole_SavedVars", ...)
       ├─ build top-level CyrHUD_UI window (no mouse, no move)
       ├─ apply anchor preset from cfg.position
       └─ settings.register()  -- builds the Harvens panel

EVENT_PLAYER_ACTIVATED
  └─ CyrHUD.playerInit()
       ├─ if IsPlayerInAvAWorld() and zone-toggle allows: CyrHUD:init()
       └─ else: CyrHUD:deinit()
```

The existing `init`/`deinit` symmetry survives. `init` now means "begin
event subscriptions and show the window"; `deinit` means "stop and
hide". The user never calls these directly anymore.

## Removed behaviors and how they degrade

| Removed | What the user loses | Mitigation |
|---|---|---|
| Mouse drag | Pixel-perfect positioning | 6 preset anchors; covers the common spots |
| `CYRHUD_TOGGLE` keybind | One-press hide during a fight | Setting panel toggle per zone; HUD also auto-hides outside AvA |
| `/cyrhud` slash | Devs can't quick-toggle from chat | Add a no-arg dev slash later if needed; not in scope |
| Quest-tracker hiding | Quest tracker stays visible over the HUD | Console gamepad UI manages tracker visibility itself; not our place |

## Verification plan

Static-only (no ESO client available locally):

1. **Syntax**: `libs/ESOLua/src/luac -p` on every `.lua` file in
   `addon/CyrHUDConsole/`.
2. **Audit**: `grep -nE 'SetMouseEnabled|SetMovable|OnMoveStop|SLASH_COMMANDS\["/cyrhud"\]|LibAddonMenu2|LAM:Register|QuestTrackerWin|ZO_FocusedQuestTrackerPanel'`
   against `addon/CyrHUDConsole/` must return zero hits.
3. **Reverse audit**: `grep -nE 'LibHarvensAddonSettings|ZoFontGamepad|ANCHOR_PRESETS|cfg.position'`
   against `addon/CyrHUDConsole/` must return non-zero hits (proves the
   replacements landed).
4. **Diff sanity**: every file in `addon/CyrHUDConsole/classes/` except
   `Info.lua` and `Label.lua` must be byte-identical to its
   `addon/CyrHUD/classes/` counterpart.

At runtime (manual, by the user on console after deploy), one line
logged at addon-loaded time so the build can be confirmed:

```lua
d("[CyrHUDConsole] loaded — IsConsoleUI=" .. tostring(IsConsoleUI and IsConsoleUI() or false))
```

## Risk register

- **Harvens dropdown sort order**: Harvens may sort items
  alphabetically. The preset keys are chosen so alphabetical order is
  acceptable; verify in testing.
- **`ZoFontGamepad36` may not exist on older API versions**: API
  101049 is what the source manifest targets and these fonts have been
  stable for years; fallback handled by the engine (it falls back to a
  default font silently).
- **Empty `cfg.position` on first run**: defaulted to `"TOP_RIGHT"`
  via `ZO_SavedVars` `def` table — same pattern as existing PC
  defaults.
- **`CyrHUDConsole_SavedVars` conflicts with a hypothetical
  pre-existing namespace**: name is unique to this fork; no risk.

## Out of scope (and why)

- Per-row hide settings beyond what the PC version already has.
- A combined PC/console codebase.
- Touching `classes/` rendering logic — already verified
  console-compatible.
- A custom keybind layer for opening the settings panel — Harvens hooks
  into Settings → Addons natively on console.
- Telemetry, analytics, version-check announcements (the PC version
  doesn't have them either).

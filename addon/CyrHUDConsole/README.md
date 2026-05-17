# CyrHUD (Console)

A console port of **CyrHUD**, an Elder Scrolls Online PvP HUD that surfaces the
state of Cyrodiil and Imperial City at a glance.

This is the Xbox / PlayStation build. The original PC addon is on ESOUI:
<https://www.esoui.com/downloads/info559-CyrHUD.html>.

## Credits

Original CyrHUD addon by:

- **Sasky** (Scott Yeskie) — original author
- **@aldericon**
- **Baertram**
- **@Masteroshi430**

The console port was produced from their work. All the rendering logic, keep
data, localization, and game-state interpretation in this addon is theirs;
the port only adapts the surface (drag → preset anchors, LibAddonMenu-2 →
LibHarvensAddonSettings, keyboard fonts → gamepad fonts) so the same HUD runs
on console UI.

## What it does

When you're in Cyrodiil or Imperial City, the HUD draws a stack of rows on
the side of the screen, one per active situation. Rows appear and disappear
on their own as the campaign evolves. The kinds of rows you'll see:

- **Keep / outpost / town / bridge / milegate battles** — which alliance is
  attacking, which is defending, how long the fight has been going, and
  whether resources (farm/mine/lumber) are also under attack. Click a keep
  name to drop a waypoint on it.
- **Elder Scrolls and Volendrung** — when a scroll or Volendrung is dropped
  or carried, you see who's holding it and for how long.
- **Graveyards** — recent kill clusters per location. Once a location passes
  10 total deaths, the HUD shows which alliance is winning that engagement.
  Stale graveyards age out automatically.
- **Imperial City Patrolling Horrors** — respawn timers for the deadly
  district bosses. Updated when one dies in front of you or when you spot
  one alive.
- **Scoring bar** — current AD / EP / DC campaign scores, with low-pop and
  low-score underdog indicators when active.
- **Ranking bar** — your personal Alliance Rank and AP progress.

## Console-specific behavior

This build differs from the PC version in a few places:

- **Settings live under Settings → Addons → CyrHUD**, served by
  LibHarvensAddonSettings (PC uses LibAddonMenu-2, which doesn't exist on
  console). All the toggles you'd expect are there: enable in Cyrodiil,
  enable in Imperial City, hide IC district battles, hide bridges and
  milegates, hide patrolling horrors, population bars, and HUD position.
- **The HUD always shows when you're in AvA** — there is no keybind toggle
  and no `/cyrhud` slash command. To hide it, untick the per-zone enable
  in the settings panel.
- **HUD position is a six-preset dropdown** — top-right, top-left,
  middle-right, middle-left, bottom-right, bottom-left — because you can't
  drag a window with a controller.
- **Quest-tracker auto-hide is gone** — the PC version optionally hid the
  Ravalox and ZOS quest trackers while CyrHUD was visible. Those PC
  trackers don't exist in the console gamepad UI; the console tracker
  manages its own visibility.

## Installing

1. Make sure **LibHarvensAddonSettings** is installed (it's a required
   dependency — the settings panel won't appear without it).
2. Copy the `CyrHUDConsole/` folder into your `AddOns/` directory:
   - Xbox / PlayStation: same place as any other console addon.
3. Launch the game, head into Cyrodiil or Imperial City, and the HUD
   appears.

## Configuration

Settings → Addons → CyrHUD. Available options:

- **Enable in Cyrodiil** / **Enable in Imperial City** — show or hide the
  HUD in each zone independently.
- **Population bars for flags** — show population bars instead of plain
  alliance flags in the summary row.
- **Hide bridges and milegates** — drop the Cyrodiil bridge / milegate
  rows from the HUD.
- **Hide Imperial City district battles** — drop IC district battles from
  the HUD.
- **Hide Patrolling Horrors** — stop tracking IC boss timers.
- **HUD position** — pick one of six preset corners / edges.

## License

GPL v2, inherited from the original CyrHUD. See `LICENSE` and `GPLv2`
in this folder.

## Reporting issues

Bugs that exist in the upstream PC addon are best reported on the original
addon's ESOUI page. Bugs that are specific to the console port (visible only
on console, or introduced by the port itself — settings panel, anchor
presets, fonts, etc.) should be reported against this repository.

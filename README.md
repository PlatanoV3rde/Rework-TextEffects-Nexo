# Rework-TextEffects-Nexo Extended (1.21.1)

Version focused specifically on **Minecraft Java 1.21 / 1.21.1** and intended to be merged by Nexo as an external pack.

## Notes
- Uses `pack_format: 34`
- Removes the `overlay_1_21_2` path and any 1.21.2+ specific structure
- Ports extra animations into the older `rendertype_text` path used by the original Rework pack
- Includes `rendertype_text` and `rendertype_text_intensity`

## Recommended Nexo setting while testing
```yml
Pack:
  obfuscation:
    type: SIMPLE
    cache: false
```

## Install with Nexo
Place this zip in `plugins/Nexo/pack/external_packs` and regenerate the pack.

## Original colors preserved
| Effect | Hex |
|---|---|
| No Shadow | `#4E5C24` |
| Rainbow | `#E6FFFE` |
| Wobble | `#E6FFFA` |
| Rainbow + Wobble | `#E6FBFE` |
| Jump | `#E6FBFA` |
| Rainbow + Jump | `#E6F7FE` |
| Blinking | `#E6F7FA` |

## Extra effects added
| Effect | Hex |
|---|---|
| Shake | `#E6FFF6` |
| Pulse | `#E6FFF2` |
| Spin | `#E6FBF6` |
| Fade | `#E6FBF2` |
| Iterating | `#E6F7F6` |
| Glitch | `#E6F7F2` |
| Scale | `#E6F3FE` |
| Gradient | `#E6F3F6` |
| Dynamic Gradient | `#E6F3F2` |
| Lava | `#E6EFFE` |
| Sequential Spin | `#E6EFFA` |


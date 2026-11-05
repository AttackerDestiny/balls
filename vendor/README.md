# WindUI

Upstream: https://github.com/Footagesus/WindUI

Release: 1.6.66

Asset: https://github.com/Footagesus/WindUI/releases/download/1.6.66/main.lua

SHA-256: `125b5dc3e5f02baf8008504879eef517ca29405c21255497e84da696fac51fc7`

The stored release file is unmodified. Its embedded banner says v1.6.65; the release tag and asset used here are 1.6.66. `build-script.py` embeds its MIT license and replaces only the icon-loading paths in the generated bundle: WindUI's own icon adapter reads the bundled Lucide data instead of downloading an icon library and six packs. Integration code is in `windui.module.luau`.

Lucide icon asset mapping: https://github.com/Footagesus/Icons/blob/main/lucide/dist/Icons.lua, retrieved November 4, 2026. Stored in `Lucide-icons.lua` with the upstream MIT license in `Icons-LICENSE.txt`. The standalone script does not fetch this mapping at runtime.

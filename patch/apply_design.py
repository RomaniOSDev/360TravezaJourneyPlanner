#!/usr/bin/env python3
import json
import shutil
from pathlib import Path

DESKTOP = Path("/Users/sanya/Desktop")
ROOT = DESKTOP / "360TravezaJourneyPlanner"


def color_json(r, g, b):
    return {
        "colors": [
            {
                "color": {
                    "color-space": "srgb",
                    "components": {
                        "alpha": "1.000",
                        "red": f"{r:.3f}",
                        "green": f"{g:.3f}",
                        "blue": f"{b:.3f}",
                    },
                },
                "idiom": "universal",
            }
        ],
        "info": {"author": "xcode", "version": 1},
    }


def write_color(path, r, g, b):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(color_json(r, g, b), indent=2) + "\n")


copies = [
    ("patch/361/Theme.swift", "361ClimariqWeatherCompass/361ClimariqWeatherCompass/Utilities/Theme.swift"),
    ("patch/361/HUD.swift", "361ClimariqWeatherCompass/361ClimariqWeatherCompass/Components/HUD.swift"),
    ("patch/361/ContentView.swift", "361ClimariqWeatherCompass/361ClimariqWeatherCompass/Views/ContentView.swift"),
    ("patch/361/ForecastPane.swift", "361ClimariqWeatherCompass/361ClimariqWeatherCompass/Views/ForecastPane.swift"),
    ("patch/361/LogAndSettings.swift", "361ClimariqWeatherCompass/361ClimariqWeatherCompass/Views/LogAndSettings.swift"),
    ("patch/362/Theme.swift", "362NutrivibeMealAssistant/362NutrivibeMealAssistant/Utilities/Theme.swift"),
    ("patch/362/KitchenChrome.swift", "362NutrivibeMealAssistant/362NutrivibeMealAssistant/Components/KitchenChrome.swift"),
    ("patch/362/ContentView.swift", "362NutrivibeMealAssistant/362NutrivibeMealAssistant/Views/ContentView.swift"),
    ("patch/362/BlendAndRecipes.swift", "362NutrivibeMealAssistant/362NutrivibeMealAssistant/Views/BlendAndRecipes.swift"),
    ("patch/362/MarketTimersSettings.swift", "362NutrivibeMealAssistant/362NutrivibeMealAssistant/Views/MarketTimersSettings.swift"),
    ("patch/363/Theme.swift", "363ZyloftHarmonySuite/363ZyloftHarmonySuite/Utilities/Theme.swift"),
    ("patch/363/MagazineCard.swift", "363ZyloftHarmonySuite/363ZyloftHarmonySuite/Components/MagazineCard.swift"),
    ("patch/363/ContentView.swift", "363ZyloftHarmonySuite/363ZyloftHarmonySuite/Views/ContentView.swift"),
    ("patch/363/StudioViews.swift", "363ZyloftHarmonySuite/363ZyloftHarmonySuite/Views/StudioViews.swift"),
]

for src, dst in copies:
    source = ROOT / src
    dest = DESKTOP / dst
    dest.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(source, dest)
    print(f"copied {dst}")

# 361 CRT: cyan + amber on charcoal
a361 = DESKTOP / "361ClimariqWeatherCompass/361ClimariqWeatherCompass/Assets.xcassets"
write_color(a361 / "AppPrimary.colorset/Contents.json", 0.050, 0.760, 0.820)
write_color(a361 / "AppAccent.colorset/Contents.json", 0.960, 0.700, 0.140)
write_color(a361 / "AppSurface.colorset/Contents.json", 0.070, 0.090, 0.110)

# 362 butcher paper: cream + terracotta
a362 = DESKTOP / "362NutrivibeMealAssistant/362NutrivibeMealAssistant/Assets.xcassets"
write_color(a362 / "AppBackground.colorset/Contents.json", 0.976, 0.945, 0.890)
write_color(a362 / "AppPrimary.colorset/Contents.json", 0.720, 0.290, 0.180)
write_color(a362 / "AppAccent.colorset/Contents.json", 0.820, 0.550, 0.220)
write_color(a362 / "AppSurface.colorset/Contents.json", 0.995, 0.980, 0.950)

# 363 newspaper: ink + crimson on cream
a363 = DESKTOP / "363ZyloftHarmonySuite/363ZyloftHarmonySuite/Assets.xcassets"
write_color(a363 / "AppPrimary.colorset/Contents.json", 0.080, 0.080, 0.080)
write_color(a363 / "AppAccent.colorset/Contents.json", 0.720, 0.120, 0.140)
write_color(a363 / "AppSurface.colorset/Contents.json", 1.000, 1.000, 1.000)

print("colors updated")

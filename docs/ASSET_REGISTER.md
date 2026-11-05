# Asset Register

**Project:** Hill Climb 2D  
**Engine:** Godot 4.7+ Stable  
**Status:** Feature & Bug Correction Integration Complete / Production Ready  

---

## 1. Registered Core Assets

| Asset Name | Path | Type | Source / Author | License | Usage | Status |
|---|---|---|---|---|---|---|
| `icon.svg` | `res://icon.svg` | Vector Graphic | Godot Engine default | CC0 / MIT | Project icon | Active |
| `Vehicle Chassis Polygon` | Internal to `Vehicle.tscn` | Procedural 2D Polygon | Member 1 & 2 Prototype | Original (MIT) | Vehicle body visual | Active |
| `Wheel Visual Polygons` | Internal to `Vehicle.tscn` | Procedural 2D Polygon | Member 1 & 2 Prototype | Original (MIT) | Wheels & rim visuals | Active |
| `Enhanced Test Track` | `res://scenes/terrain/TestTrack.tscn` | Layered 2D Geometry | Member 3 Deliverable | Original (MIT) | Subsoil, ground, grass, rocks, landmark signposts | Active |
| `Modular Terrain Segment` | `res://scenes/terrain/TerrainSegment.tscn` | Procedural 2D Geometry | Member 3 Deliverable | Original (MIT) | Synchronized collision & visuals, 9 terrain archetypes, 0-gap boundary tangents | Production Ready |
| `Procedural Track System` | `res://scenes/terrain/ProceduralTrack.tscn` | Procedural Scene & Generator | Member 3 Deliverable | Original (MIT) | Endless track generation, segment pooling, adaptive difficulty, safe pickup distribution | Production Ready |
| `Multi-Layer Parallax Env` | `res://scenes/environment/ParallaxEnvironment.tscn` | Layered 2D Parallax | Member 3 Deliverable | Original (MIT) | Sky atmosphere haze, single sun with halo, drifting clouds, mountains, forested hills | Production Ready |
| `Collectible Coin Pickup` | `res://scenes/pickups/Coin.tscn` | Area2D + Particles | Member 3 Deliverable | Original (MIT) | Golden coin, aura pulse, sparkle burst particles, floating value popup | Production Ready |
| `Fuel Canister Pickup` | `res://scenes/pickups/FuelPickup.tscn` | Area2D + Particles | Member 3 Deliverable | Original (MIT) | Red canister with cap & handle, emerald aura, fuel vapor burst particles, refuel popup | Production Ready |
| `Modern Telemetry HUD` | `res://scenes/ui/HUD.tscn` | 2D UI Control Layout | Core & Expansion | Original (MIT) | Responsive glassmorphic panels, distance metric, fuel bar, speedometer, nitro bar, coins | Production Ready |

---

## 2. Integrated Update Assets (`res://assets/`)

### 2.1 Nitro Effects (`res://assets/effects/nitro/`)

| Asset File | Format | Source / Author | License | Runtime Usage |
|---|---|---|---|---|
| `nitro_bottle.png` | PNG | Kenney / OpenGameArt | CC0 | Visual nitro indicator icon in HUD |
| `nitro_bottle.svg` | SVG | Kenney / Vector Source | CC0 | Scalable vector source |
| `nitro_boost.png` | PNG | Kenney / OpenGameArt | CC0 | Primary Nitro HUD action button icon |
| `nitro_boost.svg` | SVG | Kenney / Vector Source | CC0 | Scalable vector source |
| `nitro_flame.png` | PNG | OpenGameArt | CC0 | Vehicle rear exhaust flame (attached backwards) |
| `nitro_flame.svg` | SVG | Vector Source | CC0 | Scalable vector source |
| `nitro_flame_burst.png` | PNG | OpenGameArt | CC0 | Instant boost burst flash effect on ignition |
| `nitro_flame_burst.svg` | SVG | Vector Source | CC0 | Scalable vector source |
| `nitro_flame_01.png` | PNG | OpenGameArt | CC0 | Animated exhaust flame loop frame 1 |
| `nitro_flame_02.png` | PNG | OpenGameArt | CC0 | Animated exhaust flame loop frame 2 |
| `nitro_flame_03.png` | PNG | OpenGameArt | CC0 | Animated exhaust flame loop frame 3 |
| `nitro_flame_blue.png` | PNG | Prinsu-Kun | CC-BY 3.0 | High-energy secondary flame variation |
| `nitro_particle_spark.png`| PNG | OpenGameArt | CC0 | Trailing spark emission particles |

### 2.2 Speedometer UI (`res://assets/ui/speedometer/`)

| Asset File | Format | Source / Author | License | Runtime Usage |
|---|---|---|---|---|
| `speedometer_background.png` | PNG | Kenney / UI Pack | CC0 | Speedometer gauge circular dial base |
| `speedometer_racing_background.png` | PNG | OpenGameArt | CC0 | High-contrast racing dial base (0-220 km/h) |
| `speedometer_needle.png` | PNG | Kenney / UI Pack | CC0 | Radial needle source asset |
| `speedometer_needle.svg` | SVG | Kenney / Vector Source | CC0 | Radial needle vector source |
| `speedometer_needle_centered.png` | PNG | Custom Processed | CC0 | Pre-centered pivot needle sprite for accurate rotation |
| `speedometer_needle_centered.svg` | SVG | Custom Processed | CC0 | Pre-centered needle vector source |
| `speedometer_preview.png` | PNG | Documentation | CC0 | Visual reference & UI verification preview |

### 2.3 One-Wheel Scooter Vehicle (`res://assets/vehicles/one_wheel_scooter/`)

| Asset File | Format | Source / Author | License | Runtime Usage |
|---|---|---|---|---|
| `one_wheel_scooter.png` | PNG | OpenGameArt | CC0 | Complete composite vehicle preview / UI selection card |
| `one_wheel_scooter_body.png` | PNG | OpenGameArt | CC0 | Chassis sprite with rider foot deck and steer column |
| `one_wheel_scooter_body.svg` | SVG | Vector Source | CC0 | Chassis vector source |
| `one_wheel_scooter_wheel.png` | PNG | OpenGameArt | CC0 | High-grip central single wheel sprite |
| `one_wheel_scooter_wheel.svg` | SVG | Vector Source | CC0 | Single wheel vector source |

### 2.4 Snowfall Effects (`res://assets/effects/snowfall/`)

| Asset File | Format | Source / Author | License | Runtime Usage |
|---|---|---|---|---|
| `snowflake_01.png` | PNG | OpenGameArt | CC0 | Crystalline snowflake particle sprite |
| `snowflake_02.png` | PNG | OpenGameArt | CC0 | Detailed snowflake particle sprite |
| `snowflake_02.svg` | SVG | Vector Source | CC0 | Detailed snowflake vector source |
| `snowflake_03.png` | PNG | OpenGameArt | CC0 | Star snowflake particle sprite |
| `snowflake_03.svg` | SVG | Vector Source | CC0 | Star snowflake vector source |
| `snowflake_pixel.png` | PNG | OpenGameArt | CC0 | Pixel snow flake particle for varied depth |
| `snow_particle_blur.png` | PNG | OpenGameArt | CC0 | Soft-focus blurred background snowflake particle |
| `snowstorm_overlay.png` | PNG | OpenGameArt | CC0 | Fullscreen blizzard alpha overlay texture |
| `fog_overlay.png` | PNG | OpenGameArt | CC0 | Atmospheric misty fog screen overlay |

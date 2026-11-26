# THE PARADOX MARKET — Chapter I: The Last Harvest

A playable 3D cinematic dystopian science-fiction story game prototype built in **Godot 4 (GDScript)** using the **Forward+** renderer.

> **2089.** Ecological collapse, relentless alkali dust storms, and the *Fusarium-9* blight have erased almost every crop on Earth except hardy pale corn. Atmospheric physicist and spacecraft pilot **Dr. Elias Vance** prepares to leave his wife **Clara** and ten-year-old daughter **Maya** to pursue an impossible gravitational anomaly beyond Saturn — a doorway into an interdimensional bazaar known as **the Paradox Market**.

---

## Requirements & Running the Project

1. **Install Godot 4.3 or newer** (standard GDScript edition — no .NET/C# or external plugins required).
   - Tested structure compatible with **Godot 4.3, 4.4, and 4.5+**.
2. Open the Godot Project Manager and click **Import**.
3. Browse to this folder (`/Users/jivika/Desktop/game_dev`) and select **`project.godot`**.
4. Click **Import & Edit**. Godot will automatically import the procedural `.png` textures, `.wav` audio streams, and `.gdshader` shaders on first load.
5. Press **F5** (or click the **Play** button) to launch `res://scenes/main/MainMenu.tscn`.

> **Renderer Note:** The project is configured for **Forward+** (`volumetric_fog`, ACES filmic tonemapping, soft directional shadows, SSAO, bloom glow). If running on older integrated GPUs that do not support Forward+, switch the renderer in the top-right corner of the Godot editor to **Compatibility**; all gameplay, shaders, lighting, and UI remain functional.

---

## Controls

| Input | Action |
| :--- | :--- |
| **W / A / S / D** (or Arrow Keys) | Move Dr. Elias Vance |
| **Mouse** | Orbit third-person camera (`SpringArm3D` with collision) |
| **Shift** | Sprint (smooth FOV widening + faster footsteps) |
| **E** | Interact (open doors, inspect memories, talk to Maya, use consoles) |
| **Space / Enter / Left Click** | Advance dialogue / close memory inspection card |
| **1 / 2** (or Click) | Select emotional dialogue responses |
| **Escape** | Pause menu (Resume, Save Progress, Load Last Save, Main Menu) |

---

## End-to-End Prototype Flow & Testing Checklist

Play through **Chapter I** (~10–15 minutes with full exploration & reading) and verify every beat:

1. **Main Menu (`MainMenu.tscn`)**: Live 3D dusty cornfield diorama backdrop. Click **Begin Chapter I** (or **Continue Saved Progress** once a save exists).
2. **Cinematic Opening**: Aerial sweep over the swaying 2089 cornfields toward the weathered Vance Farmhouse and distant Horizon Outpost 09 spire, followed by Elias's opening monologue.
3. **Cornfield Exploration**: Regain third-person control on the dirt access track. Optionally inspect **Field Soil Core #14** (`E`) along the road before approaching the farmhouse porch.
4. **Farmhouse & Family Memories**: Open the hinged **Farmhouse Front Door** (`E`) and explore both rooms:
   - *Living Room*: Inspect the **Framed Family Porch Photograph** on the mantel and **Clara's Farewell Note & 2041 Botanical Archive Photo** on the kitchen table.
   - *Maya's Bedroom*: Inspect **Maya's Sketch ("The Tall Corn")** on her desk and **Maya's Star Drawing ("Dad's Door to Green")** pinned above the desk.
5. **Conversation with Maya**: Speak with **Maya Vance** (`E`) in her bedroom. Choose how Elias reassures her (honest math vs. a promise of a blue sky); she gives Elias her brass compass and the mission advances to **Horizon Outpost 09**.
6. **Journey to Horizon Outpost 09**: Exit via the back porch door (North) or front door and follow the pulsing red perimeter beacons north to the research bunker. Open the sliding **Outpost 09 Airlock** (`E`).
7. **Gravitational Anomaly Scientific Puzzle**: Inside the bunker (note metallic footsteps & muffled exterior dust storm), optionally read the **Outpost 09 Flight Manifest**, then interact with the central **Telemetry Array** (`E`):
   - Tune **Carrier Frequency**, **Gravitational Phase**, and **Harmonic Amplitude** until the amber carrier wave overlaps the cyan anomalous wave (**Coherence >= 92%**).
   - Click **LOCK HARMONIC [READY]** across all **3 progressive harmonics** to decode the fold coordinates and unlock the Launch Terminal.
8. **Cinematic Spacecraft Launch**: Interact with the glowing **Launch Control Terminal** overlooking the reinforced viewport (`E`) to trigger a multi-shot launch sequence of ***Aethelgard IV*** (retracting gantry clamps, radio farewell, thruster ignition, and ascent through the dust layer).
9. **Cosmic Entity Encounter & Entering the Paradox Market (`ParadoxMarketArrival.tscn`)**: In deep space beyond Saturn, encounter the abstract, formless **Cosmic Entity (*The Threshold*)**, choose Elias's philosophical offer, watch the interdimensional rift open, and fly *Aethelgard IV* into **the Paradox Market** to reach the Chapter I completion screen.
10. **Save & Load Verification**: At any point during exploration, press **Escape → Save Story Progress** (writes `user://paradox_market_save.json`). Return to the Main Menu and click **Continue Saved Progress** to resume with exact player coordinates, discovered memories, and mission state restored.

---

## Project Architecture

```text
/
├── project.godot                        # Forward+ config, InputMap, Autoloads
├── icon.svg
├── assets/
│   ├── audio/                           # Procedural placeholder WAV loops & SFX
│   ├── textures/                        # Procedural placeholder PNG storytelling art
│   └── shaders/                         # Custom GLSL shaders (wind, entity, rift, film grade)
├── scenes/
│   ├── main/
│   │   ├── MainMenu.tscn                # Live 3D title screen
│   │   └── Chapter1World.tscn           # Complete playable Earth world
│   ├── characters/
│   │   ├── Player.tscn                  # Dr. Elias Vance (CharacterBody3D + SpringArm3D)
│   │   └── DaughterNPC.tscn             # Maya Vance (interactable NPC)
│   ├── environment/
│   │   ├── DyingEarthEnvironment.tscn   # Forward+ sky/fog, sun, ground, cornfield, dust
│   │   ├── Farmhouse.tscn               # Explorable interior + Maya + memories
│   │   ├── ResearchFacility.tscn        # Outpost 09 bunker, viewport, gantry, Aethelgard IV
│   │   └── ParadoxMarketArrival.tscn    # Orbital void, Cosmic Entity, Paradox Market finale
│   ├── interactables/
│   │   ├── InteractableProp.tscn        # Reusable base interactable prefab
│   │   └── MemoryInspectProp.tscn       # Reusable memory item prefab
│   └── ui/
│       ├── HUD.tscn                     # Minimal HUD, waypoint, letterbox, memory card
│       ├── DialogueBox.tscn             # Signal-driven story dialogue box
│       ├── PauseMenu.tscn               # Escape pause menu + Save/Load
│       └── SignalPuzzleUI.tscn          # Real-time oscilloscope scientific puzzle
└── scripts/
    ├── systems/                         # Autoloads: GameState, MissionManager, DialogueManager, AudioManager + StoryData
    ├── player/                          # PlayerController
    ├── characters/                      # CharacterVisuals, DaughterNPC
    ├── environment/                     # CornfieldGenerator, DyingEarthController, FarmhouseBuilder, FacilityBuilder, ParadoxMarketSequence
    ├── interaction/                     # Interactable, MemoryItem, DoorInteractable, AnomalyConsole, LaunchTerminal
    ├── sequences/                       # Chapter1Director, MainMenuController
    └── ui/                              # HUDController, DialogueUI, PauseMenu, SignalPuzzleUI, WaveformScope
```

---

## Clearly Identified Placeholder Assets

To ensure this prototype runs completely out-of-the-box with zero broken external dependencies, the following assets are **procedurally generated placeholders** ready for drop-in replacement by production art/audio:

- **3D Character Models (`scripts/characters/character_visuals.gd`)**: Articulated primitive rigs for Dr. Elias Vance and Maya Vance with procedural breathing and walk/sprint gait. Replace `VisualRoot` with rigged `.glb` meshes + `AnimationTree` when ready.
- **3D Architecture, Corn & Spacecraft (`cornfield_generator.gd`, `farmhouse_builder.gd`, `facility_builder.gd`, `paradox_market_sequence.gd`)**: Modular procedural PBR meshes with matching `StaticBody3D` colliders, wind vertex shader (`corn_wind.gdshader`), and custom cosmic/portal GLSL shaders (`cosmic_entity.gdshader`, `portal_rift.gdshader`).
- **Storytelling Textures (`assets/textures/*.png`)**: Procedurally generated vintage family photograph (`photo_family_porch.png`), archival Earth landscape (`photo_green_earth.png`), Maya's crayon drawings (`drawing_maya_stars.png`, `drawing_maya_corn.png`), facility telemetry screen (`facility_signal_screen.png`), and soft dust mote sprite (`dust_particle.png`).
- **Audio Loops & SFX (`assets/audio/*.wav`)**: Procedurally synthesized dust wind, melancholic sci-fi Earth theme, launch rumble, cosmic resonance drone, Paradox Market Lydian ambience, footsteps, UI chimes, and puzzle harmonic lock tones.

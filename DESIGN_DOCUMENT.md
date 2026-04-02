# EXIT 13: NIGHT AUDITOR - Complete Game Design Document

## Executive Summary

EXIT 13: NIGHT AUDITOR is a premium-quality 3D first-person horror-management game that fuses authentic night-shift work simulation with psychological horror. Players experience the graveyard shift at a haunted highway service plaza, where mundane tasks like operating a cash register and checking in motel guests become increasingly corrupted by supernatural events tied to a tragic highway accident.

**Target Platform**: PC (Windows, Linux, macOS)
**Engine**: Godot 4.3+
**Genre**: First-Person Horror-Management Simulation
**Play Time**: 10-14 hours (Story Mode) + Endless Mode
**Target Audience**: Fans of horror games, simulation games, and narrative-driven experiences

## Core Concept

The game's unique selling proposition is the **fusion of authentic labor simulation with system-corrupting horror**. Unlike games that add chores to horror or layer horror onto management, EXIT 13 makes the job itself vulnerable and the horror emerge from familiar systems behaving impossibly.

### Key Differentiators

1. **Original Setting**: Highway service plaza (motel + gas station + convenience store) vs. retail-only or office settings
2. **Original Protagonist**: Mara Velez, a suspended emergency dispatcher with specific trauma
3. **Original Horror DNA**: Highway echoes, impossible travelers, system corruption vs. company mascots or found footage
4. **Original Mechanics**: Motel room assignment, fuel pump authorization, power grid management, CCTV contradiction system
5. **Original Story**: Mile 87 pileup mystery, choice-driven narrative with 4 distinct endings

## Gameplay Pillars

### 1. Authentic Work Simulation
Every task must feel like real work with proper depth:
- Cash register with item scanning, payment processing, receipt printing
- Motel booking with guest data, room assignment, key dispensing
- Fuel pump authorization and monitoring
- Facility maintenance (restocking, cleaning, repairs)
- Power grid management with circuit breakers
- Security monitoring via CCTV

### 2. System Corruption Horror
Fear emerges when familiar systems behave wrong:
- Receipt prints for customers who haven't arrived
- CCTV shows player in wrong location
- Guests request rooms that don't exist
- Power fails in impossible patterns
- Radio predicts events before they occur
- Time loops and temporal anomalies

### 3. Environmental Storytelling
Truth revealed through work, not cutscenes:
- Guest registry contradictions
- Maintenance logs describing impossible events
- Dispatcher audio cassettes from the crash
- CCTV footage evidence
- Police reports and incident files
- Found objects from victims

### 4. Escalating Dread
Tension built through repetition and broken patterns:
- Chapter 1: Subtle wrongness, player questions reality
- Chapter 2: Clear anomalies, pattern recognition
- Chapter 3: Direct confrontation with supernatural
- Chapter 4: Investigation and truth-seeking
- Chapter 5: All systems corrupted, final choice

### 5. Meaningful Player Agency
Decisions shape survival and narrative:
- Help stranded travelers or exploit them
- Investigate anomalies or ignore them
- Maintain composure or spiral into paranoia
- Trust the owner, police, or mysterious radio voice
- Collect evidence or focus on profit

## Game Loop Architecture

### Micro Loop (5-10 minutes)
1. Customer/guest arrives
2. Player performs service task
3. Horror event interrupts or corrupts task
4. Player investigates or returns to work
5. Task completion rewards progress

### Macro Loop (Shift - 15-30 minutes real time)
1. Clock in, read shift notes
2. Check facility status (occupancy, fuel, power, weather)
3. Perform 8-15 service tasks
4. Handle 3-5 horror events
5. Manage 1-2 critical incidents (power failure, suspicious guest)
6. Clock out, reconcile till, review evidence
7. Purchase upgrades
8. Advance story

### Meta Loop (Chapter - 2-3 hours)
1. Story setup introduces new elements
2. New horror event types unlock
3. Facility deterioration or improvement based on choices
4. Major story revelation
5. Chapter-ending set piece event
6. Choice with long-term consequences
7. Apartment scene for reflection

## Systems Deep Dive

### Shift Management System
**Purpose**: Control time flow, objectives, and shift structure

**Features**:
- 8-hour shifts (10 PM to 6 AM game time)
- Time scale: 60:1 (1 real second = 60 game seconds)
- Shift phases affect horror intensity (midnight, dead hours, pre-dawn)
- Dynamic objective generation based on chapter and player performance
- End-of-shift reconciliation with performance scoring

**Implementation**: ShiftManager singleton tracks time, spawns objectives, manages shift flow

### Event Director System
**Purpose**: Schedule and trigger horror events with proper pacing

**Features**:
- 80+ unique horror events across 7 categories
- Intensity-based eligibility filtering
- Cooldown system prevents repetition
- Chapter-gated event unlocking
- Weighted random selection (favors lower intensity)
- Minimum 5-minute, maximum 10-minute intervals between events

**Event Categories**:
1. Environmental Distortion (lights flicker, machines activate, temperature changes)
2. Customer Anomalies (wrong reflections, impossible requests, victim echoes)
3. CCTV Contradictions (shows player elsewhere, phantom vehicles, timeline errors)
4. Radio/Phone Horror (predictions, emergency calls, victim voices)
5. Room Impossibilities (occupied rooms empty, boarded rooms requested)
6. Power Manipulation (cascade failures, selective outages, breaker anomalies)
7. Scripted Set Pieces (major story events, high-intensity confrontations)

**Implementation**: EventDirector singleton with event library, eligibility checking, execution handlers

### Power Grid System
**Purpose**: Electrical zone management for gameplay and horror

**Features**:
- 4 zones: Store, Motel, Exterior, Basement
- Individual breaker control via breaker panel interactable
- Backup generator with manual activation
- Zone-specific equipment registration (lights, machines, computers)
- Horror-triggered failures (cascade, selective, total blackout)
- Light flickering for atmospheric effect

**Gameplay Impact**:
- Dark areas require flashlight (limited battery)
- Some tasks impossible without power (register, motel computer)
- Horror intensity increases in darkness
- Player must physically navigate to breaker room to restore power

**Implementation**: PowerGrid singleton managing zone states, light references, failure/restoration functions

### Weather System
**Purpose**: Dynamic atmospheric conditions affecting gameplay and horror

**Weather Types**:
1. Clear - Normal visibility, baseline horror
2. Light Rain - Audio ambience, reflective surfaces
3. Heavy Rain - Reduced visibility, increased horror intensity
4. Fog - Severe visibility reduction, isolation feeling
5. Storm - Lightning, power threats, high horror
6. Snow - Rare, can trigger impossible indoor snow event

**Gameplay Effects**:
- Visibility reduction affects exterior navigation
- Rain audio masks other sounds (horror advantage)
- Storms increase power failure chance
- Weather forecasts can be wrong (horror event)

**Implementation**: WeatherSystem node with particle effects, audio layers, environment fog control

### CCTV System
**Purpose**: Security monitoring that can show contradictions

**Features**:
- 16 cameras covering all major areas
- Monitor bank at security desk
- Individual camera viewing
- Playback/rewind capability
- Evidence capture function
- Horror events can corrupt feeds

**Camera Positions**:
1-4: Convenience store (aisles, register, entrance, stockroom)
5-8: Motel (lobby, corridor, parking, rooms exterior)
9-12: Fuel forecourt (pumps, approach, exit, dumpster)
13-16: Utility areas (breaker room, basement, maintenance, roof)

**Horror Integration**:
- Cameras show player at register when player is elsewhere
- Phantom customers visible only on camera
- Timeline discrepancies (shows past or future)
- Room 4 activity despite being boarded
- Cameras all show same looping footage

**Implementation**: CCTVSystem with camera array, texture rendering, playback buffer, anomaly injection

### Motel Booking System
**Purpose**: Guest check-in and room management

**Features**:
- 6 rooms total (1-6), Room 4 boarded and inaccessible
- 5 available rooms at max capacity
- Guest database with name, vehicle, payment method
- Room assignment algorithm
- Key dispensing (physical key objects)
- Checkout processing
- Complaint handling

**Horror Integration**:
- Guests request Room 4 despite it being boarded
- Occupancy board shows more guests than possible
- Guest checks out without ever checking in
- Same guest checks in twice
- Registry shows player's own name from 6 months ago

**Implementation**: MotelBooking interactable with room_occupancy dictionary, guest data structures, horror event triggers

### Cash Register System
**Purpose**: Transaction processing for convenience store

**Features**:
- Item scanning with barcode simulation
- Price calculation and total display
- Payment processing (cash, card)
- Change calculation
- Receipt printing
- Till balance tracking
- End-of-shift reconciliation

**Horror Integration**:
- Receipt prints for customer who hasn't arrived yet
- Receipt shows items customer didn't select
- Receipt includes personal information about player
- Till drawer opens by itself
- Transaction completes without player input
- Receipts print crash victim manifest items

**Implementation**: CashRegister interactable with transaction state machine, till balance, receipt generation

### Fuel Pump System
**Purpose**: Gasoline pump authorization and monitoring

**Features**:
- 4 pumps (2 diesel, 2 regular)
- Remote authorization from inside
- Fuel flow monitoring
- Payment capture
- Drive-off detection
- Pump malfunction alerts

**Horror Integration**:
- Car idles at pump but vanishes when approached
- Fuel flows backward (up instead of down)
- Pump activates without authorization
- CCTV shows car at pump but no car outside
- Pump never stops dispensing (infinite fuel)

**Implementation**: FuelPumpSystem with pump state array, authorization logic, flow simulation

## Story Structure

### Premise
Mara Velez, former emergency dispatcher, handles a massive pileup at Mile 87 six months ago. Multiple deaths, contradictory calls, chaos. She gave directions that may have sent responders to the wrong location. Suspended pending investigation. Breakdown. Therapy. Desperation.

She takes night auditor job at Exit 13 (Mile 13, same highway) for money and because she believes the plaza is connected to Mile 87 incident.

### Chapter Breakdown

**CHAPTER 1: ORIENTATION (Shifts 1-2)**
- **Focus**: Tutorial, establish baseline reality
- **Story**: Meet day manager Carla (notes only), learn the job
- **Horror Level**: Minimal - subtle wrongness (lights flicker, radio static)
- **Key Event**: Find dispatcher tape in office
- **Revelation**: Exit 13 has high employee turnover

**CHAPTER 2: PATTERNS (Shifts 3-5)**
- **Focus**: Horror escalates, pattern recognition
- **Story**: Guests with impossible requests, wrong vehicle registrations
- **Horror Level**: Medium - clear anomalies (CCTV contradictions, customer echoes)
- **Key Event**: Receipt prints "Mile 87 Survivor Group - Party of 6"
- **Revelation**: Some guests match crash victim descriptions

**CHAPTER 3: RECOGNITION (Shifts 6-8)**
- **Focus**: Direct confrontation with supernatural
- **Story**: Crash victims appear, don't know they're dead/trapped
- **Horror Level**: High - victims repeat final moments, Room 4 activity
- **Key Event**: Mara recognizes a victim she spoke to during crash
- **Choice Point**: Help victims move on (lower profit) or keep them (higher profit)
- **Revelation**: Exit 13 is a waystation for trapped souls

**CHAPTER 4: INVESTIGATION (Shifts 9-11)**
- **Focus**: Truth-seeking, evidence gathering
- **Story**: Basement archives unlock, old motel logs, police reports
- **Horror Level**: Very High - all systems corrupted, multiple simultaneous events
- **Key Event**: Discovery that plaza owner deliberately traps souls for profit
- **Choice Point**: Trust owner's explanation or seek help from police/radio voice
- **Revelation**: Mara's mistake at Mile 87 wasn't her fault - dispatch system was corrupted

**CHAPTER 5: CONVERGENCE (Shifts 12-14)**
- **Focus**: Final confrontation, choose ending
- **Story**: All victims return, highway loops to Exit 13, reality breaks down
- **Horror Level**: Maximum - all events possible, total corruption
- **Key Event**: Simulated pileup recreation at the plaza
- **Choice Point**: Final decision determines ending
- **Resolution**: One of four endings based on choices throughout

### Four Endings

**ENDING A: RELEASE** (True Good Ending)
- **Requirements**: Help 75%+ guests, collect all evidence, maintain high composure, confront owner
- **Outcome**: Mara performs ritual using evidence to release trapped souls, plaza burns, cleared by investigators
- **Final Scene**: Driving away at dawn as Exit 13 sign falls, radio plays normal traffic report
- **Unlocks**: "Truth Seeker" achievement, New Game+ with full evidence from start
- **Theme**: Truth and compassion triumph over exploitation

**ENDING B: CORRUPTION** (Bad Ending)
- **Requirements**: Exploit 75%+ guests, maximize profit >$10k, trust owner, buy all upgrades
- **Outcome**: Mara accepts owner's offer to become permanent auditor, merges with building, gains supernatural control but loses humanity
- **Final Scene**: Mara's reflection shows her as part of the architecture, new auditor arrives
- **Unlocks**: "Profiteer" achievement, Endless Mode with "Corrupted Plaza" variant
- **Theme**: Greed and fear lead to becoming the monster

**ENDING C: ESCAPE** (Neutral Ending)
- **Requirements**: Moderate choices, incomplete evidence <50%, moderate composure breaks
- **Outcome**: Mara quits during Shift 14, leaves town, but guilt and visions follow
- **Final Scene**: New apartment, hears Exit 13 on radio, victims still calling
- **Unlocks**: "Survivor" achievement, Anxiety modifiers for new playthrough
- **Theme**: Avoidance doesn't resolve trauma

**ENDING D: CYCLE** (Twist Ending)
- **Requirements**: Complete breakdown (composure <20%), trust radio voice fully, ignore evidence
- **Outcome**: Mara realizes she's been trapped at Exit 13 all along, becomes an echo like the victims
- **Final Scene**: Mara clocking in as previous shift's Mara clocks out, infinite loop
- **Unlocks**: "Echo" achievement, Ghost Mode for Endless (play as former auditor)
- **Theme**: Denial and obsession create prison

## Technical Specifications

### Performance Targets
- **Frame Rate**: 60 FPS on GTX 1060 / RX 580 equivalent
- **Resolution**: 1920x1080 native, scalable
- **Memory**: <5GB RAM usage
- **Load Time**: <10 seconds to gameplay
- **Build Size**: <2GB compressed

### Engine Configuration
- **Engine**: Godot 4.3+
- **Rendering**: Forward+ pipeline
- **Scripting**: GDScript (no C# dependencies)
- **Audio**: Godot AudioServer with spatial 3D
- **Physics**: Built-in Godot Physics
- **Navigation**: NavigationServer3D for AI

### Graphics Settings
- **Lighting**: Baked lightmaps for static, real-time for dynamic (player flashlight, flickering)
- **Shadows**: Directional light + 3-4 real-time shadow-casting lights max
- **Post-Processing**: Glow, fog, optional motion blur
- **MSAA**: 2x-4x configurable
- **Texture Quality**: Compressed, 2K max for environments

### File Structure
```
exit_13_night_auditor/
├── project.godot
├── icon.svg
├── assets/
│   ├── audio/
│   ├── models/
│   ├── textures/
│   └── fonts/
├── scenes/
│   ├── gameplay/
│   ├── ui/
│   └── apartment/
├── scripts/
│   ├── autoloads/
│   ├── player/
│   ├── systems/
│   ├── interactables/
│   ├── ai/
│   ├── story/
│   └── ui/
├── data/
│   ├── items/
│   ├── upgrades/
│   ├── npcs/
│   └── story/
└── shaders/
```

## Audio Design

### Ambient Layers
1. **Highway Drone**: Constant distant traffic, never stops
2. **Transformer Hum**: Electrical buzz, varies with power state
3. **HVAC**: Rattling AC units, motel-specific
4. **Weather**: Rain, wind, thunder as active

### Interactive Sounds
- **Footsteps**: 4 material types (concrete, tile, carpet, asphalt)
- **Doors**: Open, close, lock, unlock, force, slam
- **Register**: Beep, drawer, receipt printer
- **Objects**: Pickup, place, use (50+ unique)

### Horror Audio
- **Whispers**: Layered, unintelligible, directional
- **Radio Static**: Interference patterns, voice fragments
- **Distortion**: Audio time-stretch, pitch-shift
- **Stingers**: Musical cues for jump scares (used sparingly)
- **Impossible Sounds**: Reversed audio, children in empty spaces

### Music
- **Menu Theme**: Dark ambient, highway loneliness
- **Apartment**: Melancholy piano, safety feeling
- **Tension Tracks**: Subtle string drones, triggered contextually
- **Ending Themes**: 4 unique tracks for each ending

## Development Milestones

### Milestone 1: Foundation (COMPLETE)
✅ Project structure
✅ Player controller
✅ Interaction system
✅ Core singletons (GameManager, EventBus, SaveSystem, AudioManager)
✅ Main menu
✅ Basic greybox location

### Milestone 2: Core Gameplay (IN PROGRESS)
✅ Cash register system
✅ Motel booking system
✅ Fuel pump system
✅ Shift management
✅ Event director
⚠️ Customer AI (structure complete, pathfinding needs work)
⚠️ Inventory system (complete, needs integration)

### Milestone 3: Horror Implementation
⚠️ Power grid (complete)
⚠️ Weather system (complete)
⚠️ CCTV system (framework exists, rendering needed)
⚠️ All 80 horror events (10 implemented, 70 to go)
⬜ Scripted set pieces (0/8)
⬜ Audio integration (system ready, assets needed)

### Milestone 4: Story & Progression
⬜ Chapter system
⬜ Dialogue system
⬜ Choice tracking
⬜ Evidence collection
⬜ Apartment scenes
⬜ All story documents/tapes

### Milestone 5: Polish & Content
⬜ Full location art pass
⬜ All audio assets
⬜ UI/UX polish
⬜ Tutorial/onboarding
⬜ All upgrade implementations

### Milestone 6: Endings & Endless
⬜ 4 ending sequences
⬜ Endless mode rules
⬜ High score system
⬜ Procedural variation

### Milestone 7: Release
⬜ Performance optimization
⬜ Bug fixing
⬜ Playtesting
⬜ Achievements
⬜ Steam integration

## Conclusion

EXIT 13: NIGHT AUDITOR is a complete, original horror-management game with a strong foundation already implemented. The core systems are functional, the design is comprehensive, and the vision is clear. This document serves as both a design bible and implementation guide for completing the remaining work.

**Current Status**: 40% complete (all systems designed, 40% implemented)
**Next Priority**: Complete horror event implementation and story content
**Timeline to Alpha**: ~3 months with dedicated development
**Timeline to Release**: ~6 months with full team

The game is **legally safe** (no copied content), **technically sound** (proven Godot 4 systems), and **commercially viable** (proven genre + unique hooks).

# RickNMortyRS — Dimensional Fluid Lab

A Rojo/Luau portal-gun system with a handmade gray device, red switch, green glass energy chamber, traveling energy shots, animated green spiral portals, and liquid leakage on replacement. Geometry follows the supplied gun and portal references; no uploaded meshes or portal textures are required. Phoenix Protocol now adds death-triggered cloning in an adjacent laboratory. The original `default.project.json` and its service mappings are unchanged.

## Run in Roblox Studio

1. Pull this repository, then run `rojo serve default.project.json` from its root.
2. Open the intended place in Roblox Studio. Connect using the Rojo plugin, review its sync changes, and sync.
3. Press **Play** (not Run). The server generates the test chamber and puts **Portal Gun** in each player's Backpack. Equip it with the hotbar (`1` on PC, tap the tool on mobile).
4. Aim at a large flat face and click; on mobile, tap the world location. Aim sufficiently above the floor for the entire portal to fit. On a wall, roughly 6.5 studs above the chamber floor is a useful walking test height.
5. Place both portals, then walk/jump into their front sides. Use Studio's **Server & Clients** mode with two players for replication testing.

No manual RemoteEvents, Tools, StarterPack models, plugins other than Rojo, HTTP requests, or API-service settings are required. Generation happens during Play, so the chamber is not visible in Edit mode. If the place has additional SpawnLocations, remove/disable those in Studio or select the laboratory spawn for testing.

## Controls and A/B behavior

- PC: equip, aim, left click. Mobile: equip, tap the desired surface; UI taps are ignored. Dragging the camera is not a firing gesture. There is no A/B selection button.
- **Successful placements:** A → B → replace A → replace B → replace A, indefinitely. Each player has independent slots. Rejected shots leave the existing portals and next slot unchanged.
- Shots have a 0.42-second minimum interval and only one projectile in flight per player. Requests while busy are ignored. Portals become active after their 0.28-second opening animation.
- Both portals must exist. Anyone can traverse any player's linked pair; each pair always connects only its owner's A and B.
- A small HUD shows the next slot and rejection reason. Death/respawn and disconnect clear the owner's pair; respawn restarts at A.

## Placement rules and authority

The client sends a camera origin and unit direction, never a destination portal or teleport command. The server checks types, finite values, camera distance from the head (18 studs), equipped gun, living character, shot rate, head-to-camera visibility, camera ray, and muzzle obstruction. Maximum targeting range is 180 studs from the camera and character. Very distant third-person zoom is deliberately rejected.

Portals use a 7 × 10 stud oval. A 5 × 7 grid checks that the bounding rectangle plus a small margin lies on **one anchored, collidable, opaque block Part** with a consistent surface normal. Terrain, MeshParts, wedges, moving parts, transparent surfaces, ceilings, seams between separate parts, and tiny faces are rejected. Walls, slopes, and floors are supported. Set a Part's boolean `PortalSurface` attribute to `false` to prohibit portals; absent/true allows eligible geometry.

The server checks front clearance and nearby coplanar portal overlap. It revalidates at projectile impact before replacing the old slot. Moving, resizing, deleting, unanchoring, disabling collision on, or prohibiting a supporting Part closes its portal. New obstructions at an exit prevent traversal instead of placing the character inside them.

## Movement

Portal frames use local +Z as the outward surface normal. Transit applies `destination * rotationY(180°) * inverse(source)` to orientation, linear velocity, and angular velocity. Lateral entry offset is retained with the appropriate reversal, and exit depth accounts for the rotated avatar envelope. Falling into a floor portal therefore redirects downward momentum outward from a wall portal. An exceptional-speed safety cap is 240 studs/second.

A swept/predictive front-side capture test triggers before the supporting solid wall stops the avatar. A clearance query rejects blocked destinations. The server briefly takes network ownership while moving the character, then restores automatic ownership. A 0.65-second lock and exit-volume latch prevent immediate loops. Seated, dead, and anchored characters do not transit. NPCs and loose physics props are not implemented.

## Test chamber

`Chamber.luau` independently generates a laboratory around the starter spawn: opposing walls, a perpendicular wall, a freestanding face, large floor, raised deck, matte gray guide strips, stairs, and a 34-stud-high drop platform. Jump from the front of the high platform toward the lighter landing pad to test a floor-to-wall momentum launch. Place the destination wall portal before the jump.

Set `BuildTestChamber = false` in `Config.luau` when integrating into your own level. The original Rojo baseplate remains intact beneath the chamber.

## Structure

| Location | Responsibility |
| --- | --- |
| `src/server/init.server.luau` | Creates the remote and starts chamber/service |
| `src/server/Portal/Service.luau` | Per-player A/B state, request limits, impact scheduling, snapshots, cleanup |
| `src/server/Portal/Placement.luau` | Authoritative raycasts, surface fit, obstruction and overlap validation |
| `src/server/Portal/Transit.luau` | Crossing detection, exit clearance, momentum, network ownership and re-entry guards |
| `src/server/Portal/Chamber.luau` | Standalone chamber generator |
| `src/shared/Portal/Config.luau` | Dimensions, timing, colors, budgets and sound hooks |
| `src/shared/Portal/Math.luau` | Coordinate transforms, aperture and avatar extent calculations |
| `src/shared/Portal/Gun.luau` | Welded reference-inspired Tool model and chamber particles |
| `src/client/init.client.luau` | Client event routing and update loops |
| `src/client/Portal/Input.luau` | Mouse/touch targeting with GUI inset handling |
| `src/client/Portal/GunView.luau` | Recoil, idle movement, chamber flicker and hum |
| `src/client/Portal/Renderer.luau` | Opening/collapse, irregular rim, moving interior ribbons and distance budget |
| `src/client/Portal/Fluid.luau` | Droplets, gravity, collision splashes and glow fade |
| `src/client/Portal/Effects.luau` | Traveling projectiles, trails, bursts, positional sound and temporary-object limits |
| `src/client/Portal/Hud.luau` | Next-slot display, feedback and short transit flash |
| `tests/` | Offline compiler/build validation and production-module regression harness |

The starter `src/shared/Hello.luau` is retained but unused. Tests are outside the Rojo tree and are not shipped into the game.

## Visuals and performance

The gun silhouette uses a gray housing, inset sides, curved-looking handle, red switch, thumb dial, fasteners, capped translucent green chamber, neon core, suspended green filaments, cooling slots, a rounded handle heel and bubbles. Local grip motion supplies recoil without external animation IDs.

The chamber uses subdued gray walls, charcoal floors, matte guide strips, neutral signage and a slate spawn pad; none of its generated surfaces use Neon. Portal colors stay within dark, saturated and bright greens, including failed-shot effects (darker green, smaller burst). A/B are distinguished by a small letter, subtly different illumination and opposite swirl directions.

Each visible portal has 78 non-colliding, non-queryable Parts: an opaque dark-green oval, 28 thick irregular rim segments, 39 broad moving green ribbon segments and 10 pale-green fluid flecks. Each Part contains a built-in Sphere SpecialMesh so it can stretch independently along all three axes. Thin Ball Parts were the cause of the former dots-only appearance: their rendered spheres shrink to the smallest dimension instead of forming the requested flattened oval/ribbons. No uploaded mesh or texture is needed. The same corrected effect primitive gives droplets, splashes and projectile streaks their intended elongated/flattened shapes. Adjacent rim and spiral samples overlap into connected ribbons, with drifting green highlights, a pulsing dark center and an asymmetric closing squeeze. Contrast comes from matte interior greens and selective green neon highlights. Four low-rate green mist emitters add wisps (six particles/second per visible portal, lifetimes below one second); emission stops on collapse and destruction/culling cleans up the emitters. A 30 Hz animation loop avoids independent tweens/connections per segment. Only the nearest 12 portals within 260 studs are materialized; culled portals remain authoritative and reappear when approached. This is a visual budget, not a limit on server portal ownership.

Opening spreads the shape rapidly with an outward splash. Replacement collapses the old oval over 0.55 seconds, wobbles the rim and releases two waves of fluid. Client-only ballistic droplets raycast against geometry, spread into flattened splashes on contact, darken, and fade. At most 90 moving droplets and 130 temporary effect Parts exist per client; short Debris lifetimes also clean up shots and splashes. Active portal Parts are separate from this transient budget. Effects do not participate in physics or gameplay raycasts. A transit flash lasts 0.18 seconds at low opacity.

### Sounds/assets you supply

No external visual assets are required. Particles use the built-in Roblox sparkle and smoke textures. In `Config.Sounds`, replace the empty strings for `Fire`, `Impact`, `Fail`, `Open`, `Close`, `Transit`, and `Hum` with `rbxassetid://...` sound IDs permitted for your experience. **Audio is silent until these IDs are supplied.** `Hum` loops while your gun is equipped; other sounds play positionally. No unverified/free-model asset IDs are embedded.

## Validation and required manual tests

Offline validation tools used: Rojo 7.7.0, Luau 0.739, Lune 0.10.5. With `rojo`, `luau-compile`, and `lune` on PATH, run:

```sh
python tests/validate.py
```

The build validator compiles every runtime Luau file, builds a temporary `.rbxlx`, verifies expected mapped module names, then runs the regression harness. The harness executes production math, placement and service code with Lune's Roblox datatypes and fake world/service queries. It checks frame directions, momentum magnitude, inverse mapping, nonfinite input, fit/edge/miss/range/obstruction rejection, projectile timing, ABABA replacement, per-player independence, snapshots and respawn/disconnect cleanup. Regression checks now also require stretchable meshes on every portal surface, a full-size opaque backing and continuing swirl animation; these assertions guard the dots-only rendering regression without pretending to render the engine. Gun and chamber construction were also smoke-checked against Lune's instance/reflection support. Standalone Luau analysis found no diagnostics beyond its missing Roblox globals/types; it is not a Studio API typecheck.

**Roblox Studio was not available during implementation. There has been no live engine playtest or rendered visual approval.** Before publishing, run these checks:

- Inspect Output and Script Analysis after sync. Confirm the gun is visibly held, correctly oriented in R6/R15, and visible in first/third person.
- Fire five valid shots. Confirm A/B/A/B/A, projectile arrival before formation, and old portals leaking fluid on replacement. Reject an edge/tiny/blocked target between shots and confirm the next slot stays unchanged.
- Test mouse targeting across the screen, then Studio device emulation and a real phone/tablet. Taps should hit where touched; joystick, hotbar, jump, chat and camera drags must not fire. Check GUI-inset alignment in portrait and landscape.
- Enter both directions through opposing and perpendicular walls. Jump from the high platform through the landing-pad portal into a wall exit. Verify direction, velocity, camera recovery, clearance and absence of rapid re-entry.
- Put a collidable obstacle at the exit after placement; traversal should fail safely. Move/resize/delete a supporting wall and confirm closure. Try approaching from behind and near the oval edges.
- Test two players, joining after portals exist, rapid replacements, respawning mid-shot, disconnecting, and simulated network latency. Confirm each player's sequence remains separate and both clients see the same active pair.
- Replace portals repeatedly for several minutes. Inspect `Workspace.PortalClientEffects` on the client; short-lived drops/splashes should disappear and object counts should settle. Profile on the target mobile device, especially with multiple nearby players.
- Supply your sound IDs and verify permissions, volume, hum cleanup and failed-shot audio.

## If you still see rainbow outlines in Studio

The repository contains no `Highlight`, `SelectionBox`, wireframe adornment, or rainbow-color generator. The only former chamber neon accents were two green guide strips; these are now matte gray. Multicolored outlines around every object may therefore be an editor/debug visualization or an effect supplied by a plugin or by other objects already in your Studio place. This cannot be diagnosed conclusively from the repository alone.

Stop Play and clear the current Studio selection. In **Studio Settings → Physics**, check **AreAssembliesShown** first: Roblox documents this option as assigning each physics assembly a different outline color, which closely matches the reported symptom. Turn it off if enabled. Also check **AreSolverIslandsShown** (Physics) and **ShowBoundingBoxes** (Rendering), plus any enabled wireframe/collision overlays. Disable any active overlays and check again in Play; compare with the normal Roblox client if necessary. Also check for unrelated Highlights/SelectionBoxes already in the place. See the official [AreAssembliesShown reference](https://create.roblox.com/docs/reference/engine/classes/PhysicsSettings#AreAssembliesShown). Game scripts deliberately do not delete unrelated objects or attempt to change your editor settings. After pulling this change, stop and restart Play so the chamber and Tool are regenerated.

The earlier portal visual pass left the placement, per-player A/B state, teleportation, targeting, shared math, RemoteEvent protocol and Rojo mappings unchanged. Existing 64 offline checks and the Rojo/Luau build pass; live Studio appearance still needs inspection.

## Known limitations

The fluid is stylized procedural geometry and short-lived particles, not a fluid simulation or an exact reproduction of the source artwork. The center is an animated surface, not a live view into the other portal. Walls are not physically cut; crossing uses an avatar-envelope capture zone in front of the surface. Unusual avatar scales, accessories, slopes, extreme speeds, high latency and Roblox Humanoid auto-uprighting can affect the transition and need Studio tuning. The default Humanoid may upright a rotated character after a floor-to-wall exit; the initial velocity/orientation transform is preserved. Camera rotation is applied once and the default camera controller resumes afterward. StreamingEnabled integrations need separate testing. There are no console/gamepad controls yet.

API references: [Camera screen rays](https://create.roblox.com/docs/reference/engine/classes/Camera#ScreenPointToRay), [touch input](https://create.roblox.com/docs/reference/engine/classes/UserInputService#TouchTapInWorld), [network ownership](https://create.roblox.com/docs/reference/engine/classes/BasePart#SetNetworkOwner).

## Phoenix Protocol

Phoenix adds a real death-triggered cloning lifecycle beside the portal chamber. The reference informs the tall cylindrical storage tubes, translucent mint-green glass, rounded top, heavy mechanical rings and exposed plumbing. Five tubes are built initially. Walk around the west end of the portal-test walls and along the short walkway into the lab (roughly world Z = 90–150), or place linked portals on its large walls/floor.

**First join** still places you in the portal test area. **Every subsequent Humanoid death**, including the reset menu, enters:

`Died → transfer → tank activation → avatar loading inside tank → reconstruction → Normal or Breakout → control restored`

The orange/red **DEATH TEST / STEP HERE TO DIE** pad is at approximately `(26, 1.4, 90)`. Its server-side Touched handler checks that the touching model belongs to a player and sets the living Humanoid's Health to zero. It does not call a special resurrection path. Chamber exits and the emergency landing are separate from the pad, preventing automatic repeat deaths.

### Character lifecycle and recovery

Phoenix sets `Players.CharacterAutoLoads = false` during server startup and owns initial spawning and subsequent deaths. Before `LoadCharacterAsync`, it selects an exclusive hidden SpawnLocation **inside the assigned tank**. Roblox therefore creates the replacement at the tank, rather than visibly spawning it elsewhere and teleporting it afterward. CharacterAdded anchors/hides the body before normal Workspace parenting; later avatar descendants are hidden as well. After appearance/rig loading, the avatar is aligned inside the tube and fades back to its original per-part transparencies during reconstruction. The standard avatar loader preserves avatar appearance and default character scripts.

While reconstructing, the root is anchored, jumping/movement/autorotation are restricted, and an invisible ForceField protects against ordinary damage. Direct Health = 0/reset is still handled as another death. Movement values, transparencies and tool state are restored on success or recovery. The portal service has one new rejection guard for `PhoenixBusy`; portal alternation, placement, rendering and momentum logic are otherwise unchanged. The existing CharacterAdded path supplies the Portal Gun to the replacement as usual.

Each player receives an exclusive chamber. Five are available initially; additional players get additional tube rows and an extended lab floor/backdrop. Slots are reused after disconnect. There is no resurrection queue or shared active chamber. A quick later death cancels the previous generation and restarts the player's own chamber; delayed repair callbacks cannot reset a newer sequence.

Avatar loading has an 18-second timeout. The last good avatar is cached for fallback if Roblox's loading service fails. If there is no cached avatar yet, a basic emergency R6 rig provides a playable body; this exceptional fallback may lack the normal appearance/animations until a later successful load. A separate 30-second server watchdog handles stalled sequences. Recovery restores visibility and movement, resets the machine and uses the safe landing if necessary. A failed startup restores Roblox automatic respawning. The client has its own 34-second camera timeout, error cleanup and a replicated-state check for a missing completion event. Client messages can only request a rate-limited state sync; they cannot claim death, finish reconstruction, choose an exit or release a body.

### Exit variations and configuration

Edit **`src/shared/Phoenix/Config.luau`**. Restart Play after changing configuration.

```lua
ExitWeights = {Normal = 1, Breakout = 1}, -- 50/50; e.g. 3 and 1 gives 75/25
Debug = {ForceExitVariation = "Random"}, -- nil/"Random", "Normal", "Breakout"
```

The debug option only selects the exit. Death, transfer, avatar loading and reconstruction always run first. The normal sequence lasts roughly five seconds plus avatar-loading time; breakout is roughly seven seconds plus loading. Normal drains the fluid with a changing cylinder height/center, reduces bubbles, slides drips down the glass, unlocks clamps, lifts the glass and releases steam. Breakout starts with a successful wake-up, then pump/lock failure, three procedural glass strikes with accumulating cracks, a glass/fluid burst and a stumble out. It leaves lifted/bent locks, missing glass and an error display briefly before repair. The two exit timelines live in `Sequences.luau`, separate from lifecycle logic.

### Phoenix modules

| Path | Responsibility |
| --- | --- |
| `src/shared/Phoenix/Config.luau` | Probabilities, debug mode, timing, colors, effect limits and audio IDs |
| `src/shared/Phoenix/Policy.luau` | Variation selection, chamber allocation and generation validity |
| `src/shared/Phoenix/Motion.luau` | Continuous float/strike curves and shared impact timing |
| `src/server/Phoenix/Storage.luau` | Safe cosmetic reserve-avatar bodies in assigned idle tanks |
| `src/shared/Phoenix/Sequences.luau` | Modular Normal and Breakout stage lists |
| `src/server/Phoenix/Service.luau` | Death detection, generation cancellation, spawning, lifecycle and watchdog |
| `src/server/Phoenix/AvatarLoader.luau` | Bounded avatar loading, last-good avatar cache and emergency rig |
| `src/server/Phoenix/Body.luau` | Body hiding, anchoring, reconstruction fade and restoration |
| `src/server/Phoenix/Chamber.luau` | Server fluid/door/lock movement, status changes and reset |
| `src/server/Phoenix/Model.luau` | Tube, glass, dome, pump, hoses, cables, vents, panels and internal spawn |
| `src/server/Phoenix/Lab.luau` | Lab geometry, consoles, overflow rows, safe landing and Death Test Block |
| `src/client/Phoenix/init.luau` | Phoenix event routing and presentation cleanup |
| `src/client/Phoenix/Camera.luau` | Short transfer fade/glitch, chamber camera and control recovery |
| `src/client/Phoenix/Pose.luau` | Procedural shoulder/neck/torso movement and original-pose restoration |
| `src/client/Phoenix/Effects.luau` | Bubbles, sparks, steam, cracks, dripping/burst fluid, harmless shards and sound playback |

The existing Rojo service mappings are unchanged. New Phoenix folders are discovered through the existing src paths; `src/client/Phoenix/init.luau` becomes a ModuleScript containing its camera/pose/effect children. Runtime remotes are `PortalRemote` and the separate `PhoenixRemote`.

### Audio and animations

No uploaded animation assets are required. Pounding/waking/stumbling uses small additive Motor6D C0 poses for R6/R15 with original C0 restoration. Existing Animate scripts are temporarily paused locally during the pose and restored afterward. Custom rigs may need joint-name/axis adjustments.

Fill `Phoenix.Config.Sounds` with audio IDs your experience may use (`"rbxassetid://123..."`). All hooks default to silent and have explicit names:

`Transfer`, `Startup`, `ElectricalActivation`, `Bubbles`, `Pump`, `Drain`, `Locks`, `Open`, `Steam`, `Malfunction`, `Alarm`, `HitGlass`, `CrackGlass`, `BreakGlass`, `LiquidBurst`, `Sparks`, `Cooldown`.

Only Alarm loops, and it is removed shortly after escape or when its effect record is cleared. One-shot sounds have bounded lifetimes. Built-in sparkle/smoke textures provide the particle effects. No copyrighted audio IDs are bundled.

### Performance and limitations

Chamber structure and mechanical motion are replicated by the server. Cosmetic cracks, splashes, glass fragments, sparks and steam are client-only. Debris is anchored, non-colliding, non-touching and non-queryable; fluid is a visual approximation. There are at most 100 temporary cosmetic Parts per client, with short cleanup timers. A burst requests eight harmless glass fragments and fourteen droplets. Idle pump leaks have a rate of only 0.5 particles/second per chamber. Distant sequences beyond 230 studs skip cosmetic effects for observers. The client uses one camera/effects update and one PreSimulation pose update for Phoenix presentation, and the server watchdog checks twice a second rather than every frame.

Default-sized R6/R15 avatars are the target. Very large avatars, custom character scripts, custom movement/camera controllers, custom rigs and StreamingEnabled require integration testing. The normal exit is guided across the threshold before control returns; breakout uses a procedural lean/stumble, not a full ragdoll. Avatar service failures can show an emergency body. Tube construction is an approximation of the reference using built-in Roblox geometry. Live lighting, glass transparency and limb angles still require visual tuning in Studio.

### Validation status and Studio checklist

**Roblox Studio is not installed/accessible in the implementation environment. None of the live Studio tests below has been claimed as executed.** Automated validation passes all 31 runtime Luau files, the Rojo build/mapped modules, 64 existing portal checks and 44 Phoenix checks. Phoenix tests exercise production policy/controller code with a deterministic scheduler and service doubles, plus reflection-backed chamber construction, body restoration and avatar-loader timeout/fallback. They cover forced/random choices, simultaneous deaths, repeated/interrupting deaths, sequence exceptions, watchdog recovery, chamber reuse and ignored client completion/death claims. These tests cannot establish actual Roblox replication, character-loading order, touch physics, camera behavior or visual quality.

Run the existing offline command, `python tests/validate.py`, with the documented tools on PATH. A separate **manual-only** Studio runner is supplied at `tests/PhoenixStudio.server.luau`: during Play, paste it into a temporary Script in ServerScriptService. It intentionally kills the first test player three times to check forced Normal, forced Breakout and Random server lifecycles, movement release and Portal Gun restoration. Delete the temporary Script afterward. It is outside the Rojo tree and is not shipped with the game.

Before publishing, verify all of the following in Studio:

| Check | Action / expected result |
| --- | --- |
| 1–2: real touch death and trigger | Touch the Death Test Block; Health reaches 0 and transfer begins promptly |
| 3: other death causes | Use Reset Character and server-side Health = 0; both enter the same Phoenix flow |
| 4–5: actual tank reconstruction | Watch from a second client: no normal-spawn flash; your normal avatar forms inside its tank |
| 6–7: both exits | Observe draining/opening and malfunction/pounding/cracks/burst/stumble |
| 8–10: debug and random | Force Normal, force Breakout, then set Random and repeat; every run includes death and reconstruction |
| 11: movement | Walk, jump, equip/fire the Portal Gun after each exit; interrupt reconstruction with another death |
| 12: camera | Verify camera returns to Custom, subject follows the new Humanoid, fade clears, and movement input works |
| 13: repeatability | Die/resurrect at least five times, including reset during load/exit/cooldown |
| 14: cleanup | Repeated bursts leave no lasting shards/splats; inspect PhoenixClientEffects and check Output |
| 15: multiplayer | Two clients die together; each gets a different tube. Disconnect one mid-sequence, then join another |
| 16: portal preservation | Place A/B, traverse both ways, test momentum, then repeat after resurrection and portal into/out of the lab |

Also inspect portrait/landscape mobile UI, default R6 and R15 arm poses, character accessories, low graphics settings and artificial network latency. Test each configured sound's asset permissions once IDs have been supplied.

### Floating bodies, fluid and breakout polish

Assigned idle tanks now contain a cosmetic copy of their owner's avatar, floating above the tank floor with slow bobbing, relaxed legs and slight sway. Unassigned tanks contain fluid but no player body. The copy is removed as soon as the tank sequence starts, so the actual reconstructed character takes its place; a new reserve body appears after repair/cooldown (within one second). Stored bodies have no scripts or tools, cannot collide or trigger touch events, and are excluded from portal raycasts. Death detection and respawn ownership are unchanged.

Tanks reset **full**, with a stronger green liquid volume, a visible liquid surface, and seven slow rising bubbles per second. Both the surface and liquid level lower during normal drainage; breakout empties them with the existing splash burst. Live characters float while sealed inside the chamber. Cosmetic copies are animated only within the existing effect distance.

Breakout now uses three distinct wind-up/extension/contact/recoil strikes. The last strike stays extended until the glass fails. Arm, torso and leg poses blend continuously between phases; PreSimulation applies poses after the Animator to avoid animation fighting. First/second glass jolts, cracks and hit sounds share the contact timestamp; the final impact accompanies shattering. R6 shoulder rotations use torso axes as well as R15, rather than assuming their joint axes match. No uploaded animation is required.

Additional offline checks cover full/empty fluid, storage-body sanitization/cleanup and strike continuity. **Studio visual testing remains required:** force Breakout, inspect R6 and R15 hands meeting the glass, confirm liquid visibility on low/high graphics, verify reserve bodies disappear during reconstruction and return after repair, and check movement/camera restoration. Large/custom avatars can require pose or tank-size tuning.

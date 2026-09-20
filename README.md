# RickNMortyRS — Dimensional Fluid Lab

A Rojo/Luau portal-gun system with a handmade gray device, red switch, green glass energy chamber, traveling energy shots, animated green spiral portals, and liquid leakage on replacement. Geometry follows the supplied gun and portal references; no uploaded meshes or portal textures are required. The original `default.project.json` and its service mappings are unchanged.

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

Each visible portal has 68 non-colliding, non-queryable Parts: a dark oval, 28 irregular rim segments, and 39 moving green ribbon segments. Adjacent rim and spiral samples overlap into connected ribbons, with drifting green highlights, a pulsing dark center and an asymmetric closing squeeze. Contrast comes from matte interior greens and selective green neon highlights. Four low-rate green mist emitters add wisps (six particles/second per visible portal, lifetimes below one second); emission stops on collapse and destruction/culling cleans up the emitters. A 30 Hz animation loop avoids independent tweens/connections per segment. Only the nearest 12 portals within 260 studs are materialized; culled portals remain authoritative and reappear when approached. This is a visual budget, not a limit on server portal ownership.

Opening spreads the shape rapidly with an outward splash. Replacement collapses the old oval over 0.55 seconds, wobbles the rim and releases two waves of fluid. Client-only ballistic droplets raycast against geometry, spread into flattened splashes on contact, darken, and fade. At most 90 moving droplets and 130 temporary effect Parts exist per client; short Debris lifetimes also clean up shots and splashes. Active portal Parts are separate from this transient budget. Effects do not participate in physics or gameplay raycasts. A transit flash lasts 0.18 seconds at low opacity.

### Sounds/assets you supply

No external visual assets are required. Particles use the built-in Roblox sparkle and smoke textures. In `Config.Sounds`, replace the empty strings for `Fire`, `Impact`, `Fail`, `Open`, `Close`, `Transit`, and `Hum` with `rbxassetid://...` sound IDs permitted for your experience. **Audio is silent until these IDs are supplied.** `Hum` loops while your gun is equipped; other sounds play positionally. No unverified/free-model asset IDs are embedded.

## Validation and required manual tests

Offline validation tools used: Rojo 7.7.0, Luau 0.739, Lune 0.10.5. With `rojo`, `luau-compile`, and `lune` on PATH, run:

```sh
python tests/validate.py
```

The build validator compiles every runtime Luau file, builds a temporary `.rbxlx`, verifies expected mapped module names, then runs the regression harness. The harness executes production math, placement and service code with Lune's Roblox datatypes and fake world/service queries. It checks frame directions, momentum magnitude, inverse mapping, nonfinite input, fit/edge/miss/range/obstruction rejection, projectile timing, ABABA replacement, per-player independence, snapshots and respawn/disconnect cleanup. Gun and chamber construction were also smoke-checked against Lune's instance/reflection support. Standalone Luau analysis found no diagnostics beyond its missing Roblox globals/types; it is not a Studio API typecheck.

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

This visual pass leaves the placement, per-player A/B state, teleportation, targeting, shared math, RemoteEvent protocol and Rojo mappings unchanged. Existing 61 offline checks and the Rojo/Luau build pass; live Studio appearance still needs inspection.

## Known limitations

The fluid is stylized procedural geometry and short-lived particles, not a fluid simulation or an exact reproduction of the source artwork. The center is an animated surface, not a live view into the other portal. Walls are not physically cut; crossing uses an avatar-envelope capture zone in front of the surface. Unusual avatar scales, accessories, slopes, extreme speeds, high latency and Roblox Humanoid auto-uprighting can affect the transition and need Studio tuning. The default Humanoid may upright a rotated character after a floor-to-wall exit; the initial velocity/orientation transform is preserved. Camera rotation is applied once and the default camera controller resumes afterward. StreamingEnabled integrations need separate testing. There are no console/gamepad controls yet.

API references: [Camera screen rays](https://create.roblox.com/docs/reference/engine/classes/Camera#ScreenPointToRay), [touch input](https://create.roblox.com/docs/reference/engine/classes/UserInputService#TouchTapInWorld), [network ownership](https://create.roblox.com/docs/reference/engine/classes/BasePart#SetNetworkOwner).

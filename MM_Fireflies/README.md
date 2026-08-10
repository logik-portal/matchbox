# MM_Fireflies

## Description

Procedural fireflies - drifting movement, asymmetric flash (fast rise, slow decay, intermittent bursts). Generator over black - Screen or Add downstream onto your plate.
Setup:
- Count: number of fireflies
- Seed: reshuffle placement/timing
- EdgeMargin: inset of spawn field from frame edge
- DriftSpeed / DriftAmount: wander motion
- FlashSpeed / FlashRandomness / FlashAttack / FlashDecayPower / FlashSparsity: flash timing
- ColorR/G/B, Brightness, TwinkleVariation: look
- GlowSize, CoreSize, CoreBrightness: glow shape
- ZSpeed, ZNear, ZFar, Spread: depth travel - fireflies swoop in close/huge and recede into the distance, looping
- TargetX/Y, TargetLooseness: vanishing point fireflies travel toward/from - animate to fake a camera move's trajectory
- ShowTarget: red crosshair at the Target position, setup aid only - turn off before final render
- Hero: one always-lit firefly that weaves organically in front of the swarm, its own depth/wander/look, with its own Hero Target X/Y it's roughly attracted to
- Show Hero Target: blue crosshair at the Hero Target position, setup aid only - turn off before final render

## Flame Requirements

2015.0.0

## Supported Modes

- ❌ **Action**: Not supported
- ❌ **Transition**: Not supported
- ❌ **Timeline**: Not supported

## Shader Type

Matchbox

## Author

Marcus M

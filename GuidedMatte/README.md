# GuidedMatte

## Description

Guided Matte refines a rough matte using colour detail from a guide image, usually the original plate. The full RGB guided filter follows colour boundaries, including edges with similar luminance.
Connect the original plate to Guide / Plate and a monochrome mask to Rough Matte. Blur Width is like a search range, and Edge Detail controls the detail frequency to include.
Based on Rafael Silva’s **rs_GuidedBlur 1.3** Nuke gizmo, which in turn was based on *Guided Image Filtering* by Kaiming He, Jian Sun and Xiaoou Tang (ECCV 2010). Big thanks to Rafael for the original tool.
Flame version

## Flame Requirements

2025.2.3

## Supported Modes

- ❌ **Action**: Not supported
- ❌ **Transition**: Not supported
- ❌ **Timeline**: Not supported

## Shader Type

Matchbox

## Author

**Nils Crompton**

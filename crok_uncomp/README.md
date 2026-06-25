# crok_uncomp

## Description

This Matchbox shader uncompose a compositing scene into its original layer.
Version: 1.0
Input for Undo Blend:
- Front: wrongly comped element
- Back: clean BG without the element on it
- Matte: alpha of the composed element
Input for Remove Logo:
- Front: FG element which you want to remove
- Back: original scene with the element on it
- Matte: alpha channel of the element
Modus:
- Undo Blend: remove wrongly comped element from BG needs original matte of the element
- Remove Logo: removes semitransparent FG element from BG (needs a matte of the element)
Based on this great article: http://erwanleroy.com/compositing-elements-with-a-colored-background-or-how-to-invert-almost-any-comp-operation/
Matchbox done

## Flame Requirements

2015.0.0

## Supported Modes

- ❌ **Action**: Not supported
- ❌ **Transition**: Not supported
- ❌ **Timeline**: Not supported

## Shader Type

Matchbox

## Author

Ivar

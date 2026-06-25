# crok_beauty

## Description

This shader applies some freshness to the skin ;)
It's based on the awesome shader Ls_Dollface by Lewis
Input:
- Front: original fg
- Matte: external skin key
Skin:
- Color: pick the skin color of the talent
- Weights: adjust the tollerance values for the build in keyer
- Enable External Matte: enable the use of the optional external skin matte
- Soften: blurs the skin matte
Cleanup:
- Amount: amount of softening applied to the image
- Preserve Edges: amount of edge detection applied
- Dark spots: cleanup dark areas of the skin
- Highlights: clean up highlights on the skin
Restore Detail | Shine:
- Amount: restore highfrequency details
- Soften: soften the highpass filer
- Shine amount: applied a little bit of shine to the skin
- Blur Shine: soften the shine key
Color:
- Saturation: amount of saturation applied to the shine
- Hue Shift: amount of Hue shift applied to the image

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

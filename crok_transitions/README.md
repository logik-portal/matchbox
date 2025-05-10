# crok transitions

**Author:** Ivar Beer

**Shader Type:** Matchbox

**Action:** No

**Timeline:** Yes

**Transition:** No

**Minimum Flame Version:** 


## Description
Creates different dissolves.

Input:

    - From: incomming clip
    - To: outgoing clip

Setup:

Simple Fade:

Fade to Gray:

    - Phase: defines the kickin of the effect

Fade to Color:

    - Phase: defines the kickin of the effect
    - Fade to: defines the fade to color

Fade to GP:

    - Saturation Bias: defines the kickin of the saturation effect
    - Exposure Bias: defines the kickin of the exposure effect

Blur:

    - Size: defines the blur size
    - Quality: defines the blur quality

Wipe:

    - Smoothness: defines the wipe-gradient
    - Direction: defines the direction of the wipe

Circle:

    - Smoothness: defines the wipe-gradient
    - Invert: dissolves the other way around

Flash:

    - Phase: defines the kickin of the effect
    - Intensity: defines gain of the flash
    - Zoom Effect: defines some vignette type zoom effect
    - Velocity: velocity of the flash

Squares:

    - Smoothness: defines the wipe-gradient
    - Size: defines the square size

Morph:

    - Strength: how much distortion is applied

Cross Zoom:

    - Strength: how long the streaks are

Slide:

    - Direction: in which direction the images are moving (up, down, left, right )

Radial:

    - Smoothness: defines the wipe-gradient
    - Center: center of the circle wipe

Simple Flip:

    - Direction: defines the axis of the flip (horizontal, vertical)

Dreamy:

    - Amount: Wave Amount
    - Speed: how fast the waves are moving
    - Distortion: how much wave distortion is applied

BCC Misalignment:

    - RGB Offset: how much the RGB channels are offset
    - Noise: add an additional horizontal offset
    - Zoom: how much you zoom into the picture
    - Tint: add an additional colour tint
    - Saturation: adjust the saturation of the clips
    - Brightness: adjust the brightness of the transition effect
    - Contrast: adjust the contrast of the transition effect
    - Exposure: adjust the exposure of the transition effect

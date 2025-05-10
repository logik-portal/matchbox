# ColouredFrame

**Author:** Miles Essmiller and Ivar Beer

**Shader Type:** Matchbox

**Action:** No

**Timeline:** No

**Transition:** No

**Minimum Flame Version:** 


## Description
Creates Colors, Noise, Checkerboards, Colorbars, Colorwheels, Gradients and Shapesto get you started.

Input:

    - Front: source clip
    - Back: background clip
    - Matte: mask used for the applied effect
    - Strength: amount of effect being applied

Output:

    - Result: result clip
    - Matte: alpha channel

Type:

    Color:

        - Color: color of the generated frame
        - Selected Color Swatch: switch color circle on/off
        - Swatch Position: position of color circle
        - Palette: switch palette overlay on/off
        - Detail: palette color resolution

    Noise:

        - Color: switch colored noise on/off
        - Static: switch static frame on/off
        - Resolution: zoom in/out of the noise

    Checkerboard:

        - Color1: 1st color of the checkerboard
        - Color2: 2nd color of the checkerboard
        - Size: zoom in/out of the checkerboard
        - Aspect: adjust the aspect of the checkerboard
        - Palette: switch palette overlay on/off
        - Detail: palette color resolution

    Colorbars:

        - SMPTE: SMPTE style color bars
        - PAL: PAL style color bars
        - SMPTE2: SMPTE2 style color bars
        - 75%/100%: switch betweeen 75% and 100% brightness
        - Blue Only: show only the blue channel

    Colorwheel:

        - Size: adjust colorwheel size
        - Value: adjust the gain value
        - Position: position of colorwheel
        - Aspect: adjust the aspect of the colorwheel

    Gradient:

        - Horizontal/Vertical/Radial: switch between the different modes
        - Reverse Gradient: invert the selected gradient
        - Color1: 1st color of the gradient
        - Color2: 2nd color of the gradient
        - Palette: switch palette overlay on/off
        - Detail: palette color resolution

    Shapes:
        - Square/Circle: switch between different shapes
        - Size: zoom in/out of the shapes
        - Aspect: adjust the aspect of the shapes

    Grid:

        - Color1: grid color
        - Color2: bg color
        - Invert: invert color selection
        - Size: adjust grid size
        - Width: adjust grid width
        - Rotation: rotates the grid

    ST Map:

        Normal Map

    Reflection Map:

        - Speed: animation speed
        - Offset: offset animation in time
        - Static Chrome: static relection map
        - Zoom: Zoom in/out of the texture
        - Detail: fractal detail
        - Center: fractal center

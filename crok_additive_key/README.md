# crok additive key

**Author:** Erwan Leroy, Joel Osis and Ivar Beer

**Shader Type:** Matchbox

**Action:** No

**Timeline:** No

**Transition:** No

**Minimum Flame Version:** 


## Description
This is an Additive Keyer.

Input:

    - FG original: original fg
    - FG Despilled: despilled fg
    - Back: background
    - Matte: matte clip (needed for default Additive Key processing)
    - Matte Holdout: garbage matte input to define the region of interest (optional)
    - FG Clean: despilled clean green / blue sceen clip (optional)

    - Enable Joels Version: Enables a differnt kind of additive processing
    - Blend BG: Blends in the BG
    - BG Gamma: adjusts the gamma of the BG
    - BG Offset: offsets the BG

    - Global Restore: adjust the overall detail level
    - Restore Darks: dials in darker parts of the fg footage
    - Restore Highlight: dials in lighter parts of the fg footage
    - Desaturate Dark: desaturate the dark parts of the fg footage
    - Desaturate High: desaturate the light parts of the fg footage

    - Show Pixel Spread: shows the pixel spread image only
    - Size: adjust the size of the pixelspread

    - Enable Matte Denoise: denoise the incomming matte for cleaner edge details
    - Amount: amount of denoise applied to the matte
    - Radius: radius of the applied denoise effect

    - Output Background: just output the processed background for further comping
    - Clamp Output: clamp the output to values between 0 and 1

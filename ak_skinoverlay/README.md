# ak skinoverlay

**Author:** Jan Klier

**Shader Type:** Matchbox

**Action:** No

**Timeline:** No

**Transition:** No

**Minimum Flame Version:** 2017.0.0


## Description
Displays a hue difference overlay from the skintone line

	To use, add after Mastergrade or other operators, use as context view while adjusting grade.
	Goal is to center the skintone in image with the best overlay coverage. Either shift entire
	image or use curves and keyers to address only specific ranges.

	Boundary color are to making over and under more obvious.

	Adjust tolerance to your needs. Default of 1.5 is a narror range for precision.

	Utilize the HighPass Filter and the post processes to reduce a noisy mask.

	HighPass Filter ignors any pixels where either of the HSV values are below threshold, which
	often make for unreliable hue readings.

	Post processes can blur, erode or dialte the mask.

	The input gamma has no effect on the math of the mask, it soley influeces the overlay colors.

	Matchbox shader by Jan Klier https://www.janklier.com

	Blur filter based on Pyramid blur in ADSK shader samples
	Erode/Dialte filter based on code from https://github.com/kajott/GIPS'
        

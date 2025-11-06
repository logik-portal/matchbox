# ak_colorcompress

## Description

Color Compressor through hue rotation around reference point
	
	Use to pull hue, sat, and exposure of the entire image closer to the values of the reference
	color. Value of 0 is neutral. At maximum compression whole image will be solid of the reference
	color. It honors an input matte to enable keying and masking of the effect.

	The curve can be used to bias the effect strenght closer or further from the target color.
	
	Most common use cases are to remove color variations in skin and products. Default target
	color is skintone for that reason.
	
	This should look familiar to anyone who used Resolves Color Compressor.
	
	Matchbox shader by Jan Klier https://www.janklier.com

## Flame Requirements

2017.0

## Supported Modes

- ❌ **Action**: Not supported
- ❌ **Transition**: Not supported
- ❌ **Timeline**: Not supported

## Shader Type

Matchbox

## Author

Jan Klier

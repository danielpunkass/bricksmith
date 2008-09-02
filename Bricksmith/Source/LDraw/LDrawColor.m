//==============================================================================
//
// File:		LDrawColor.m
//
// Purpose:		A repository of methods and functions used to select LDraw 
//				colors. An LDraw color is defined by an index between 0-511.
//				They have been chosen somewhat arbirarily over LDraw's history.
//				
//				In Bricksmith, the color is represented by the enumeration 
//				LDrawColorT, which can be translated into RGBA or an NSColor by 
//				functions found here.
//
//				The original LDraw (and other compliant modellers) support 
//				dithering of basic colors. As these dithered colors do not 
//				represent real Lego hues, I have chosen not to bother 
//				supporting them here.
//
//  Created by Allen Smith on 2/26/05.
//  Copyright 2005. All rights reserved.
//==============================================================================
#import "LDrawColor.h"

@implementation LDrawColor


//========== LDrawColors =======================================================
//
// Purpose:		Returns a list of available LDraw color codes.
//
// Complaints:	This list should be based on the values of the enumeration 
//				LDrawColorT. Alas, I don't know of any way to ask the computer 
//				for the values of an enumeration, so instead I'm creating this 
//				list manually. Eeew.
//
//==============================================================================
+ (NSArray *) LDrawColors{
	//This is a good thing to generate with Grep!
	return [NSArray arrayWithObjects:
				[NSNumber numberWithInt: LDrawBlack ],
				[NSNumber numberWithInt: LDrawBlue ],
				[NSNumber numberWithInt: LDrawGreen ],
				[NSNumber numberWithInt: LDrawTeal ],
				[NSNumber numberWithInt: LDrawRed ],
				[NSNumber numberWithInt: LDrawDarkPink ],
				[NSNumber numberWithInt: LDrawBrown ],
				[NSNumber numberWithInt: LDrawGray ],
				[NSNumber numberWithInt: LDrawDarkGray ],
				[NSNumber numberWithInt: LDrawLightBlue ],
				[NSNumber numberWithInt: LDrawBrightGreen ],
				[NSNumber numberWithInt: LDrawTurquiose ],
				[NSNumber numberWithInt: LDrawLightRed ],
				[NSNumber numberWithInt: LDrawPink ],
				[NSNumber numberWithInt: LDrawYellow ],
				[NSNumber numberWithInt: LDrawWhite ],
				[NSNumber numberWithInt: LDrawCurrentColor ], //this is special
				[NSNumber numberWithInt: LDrawLightGreen ],
				[NSNumber numberWithInt: LDrawLightYellow ],
				[NSNumber numberWithInt: LDrawTan ],
				[NSNumber numberWithInt: LDrawLightViolet ],
				[NSNumber numberWithInt: LDrawPhosphorWhite ],
				[NSNumber numberWithInt: LDrawViolet ],
				[NSNumber numberWithInt: LDrawVioletBlue ],
				[NSNumber numberWithInt: LDrawEdgeColor ], //this is special
				[NSNumber numberWithInt: LDrawOrange ],
				[NSNumber numberWithInt: LDrawMagenta ],
				[NSNumber numberWithInt: LDrawLime ],
				[NSNumber numberWithInt: LDrawDarkTan ],
				[NSNumber numberWithInt: LDrawTransBlue ],
				[NSNumber numberWithInt: LDrawTransGreen ],
				[NSNumber numberWithInt: LDrawTransRed ],
				[NSNumber numberWithInt: LDrawTransViolet ],
				[NSNumber numberWithInt: LDrawTransGray ],
				[NSNumber numberWithInt: LDrawTransLightCyan ],
				[NSNumber numberWithInt: LDrawTransFluLime ],
				[NSNumber numberWithInt: LDrawTransPink ],
				[NSNumber numberWithInt: LDrawTransYellow ],
				[NSNumber numberWithInt: LDrawClear ],
				[NSNumber numberWithInt: LDrawTransFluOrange ],
				[NSNumber numberWithInt: LDrawReddishBrown ],
				[NSNumber numberWithInt: LDrawStoneGray ],
				[NSNumber numberWithInt: LDrawDarkStoneGray ],
				[NSNumber numberWithInt: LDrawPearlCopper ],
				[NSNumber numberWithInt: LDrawPearlGray ],
				[NSNumber numberWithInt: LDrawPearlSandBlue ],
				[NSNumber numberWithInt: LDrawPearlGold ],
				[NSNumber numberWithInt: LDrawRubberBlack ],
				[NSNumber numberWithInt: LDrawDarkBlue ],
				[NSNumber numberWithInt: LDrawRubberBlue ],
				[NSNumber numberWithInt: LDrawDarkGreen ],
				[NSNumber numberWithInt: LDrawDarkRed ],
				[NSNumber numberWithInt: LDrawRubberRed ],
				[NSNumber numberWithInt: LDrawChromeGold ],
				[NSNumber numberWithInt: LDrawSandRed ],
				[NSNumber numberWithInt: LDrawEarthOrange ],
				[NSNumber numberWithInt: LDrawSandViolet ],
				[NSNumber numberWithInt: LDrawRubberGray ],
				[NSNumber numberWithInt: LDrawSandGreen ],
				[NSNumber numberWithInt: LDrawSandBlue ],
				[NSNumber numberWithInt: LDrawChromeSilver ],
				[NSNumber numberWithInt: LDrawLightOrange ],
				[NSNumber numberWithInt: LDrawDarkOrange ],
				[NSNumber numberWithInt: LDrawElectricContact ],
				[NSNumber numberWithInt: LDrawLightGray ],
				[NSNumber numberWithInt: LDrawRubberWhite ],
				nil
			];
}

//========== LDrawColorNamePairs ===============================================
//
// Purpose:		Returns an array of dictionary records containing LDraw color 
//				codes and their corresponding names.
//
//==============================================================================
+ (NSArray *) LDrawColorNamePairs{
	NSArray			*colorCodes			= [LDrawColor LDrawColors];
	int				 numberColors		= [colorCodes count];
	NSMutableArray	*colorNamePairs		= [NSMutableArray arrayWithCapacity:numberColors];
	NSNumber		*currentColorCode	= nil;
	NSString		*nameKey			= nil; //key used in .strings file for color name.
	NSString		*colorName			= nil;
	NSDictionary	*currentRecord		= nil;
	int				 counter			= 0;
	
	for(counter = 0; counter < numberColors; counter++){
		
		currentColorCode = [colorCodes objectAtIndex:counter];
		
		//Find the color's name in the localized string file.
		// Color names are conveniently keyed.
		nameKey = [NSString stringWithFormat:@"LDraw: %d", [currentColorCode intValue]];
		colorName = NSLocalizedString(nameKey , nil);
		
		currentRecord = [NSDictionary dictionaryWithObjectsAndKeys:
							currentColorCode,			LDRAW_COLOR_CODE,
							colorName,					COLOR_NAME,
							nil ];
		[colorNamePairs addObject:currentRecord];
	}
	
	return colorNamePairs;
}


//========== colorForCode: =====================================================
//
// Purpose:		Returns the NSColor equivalent of colorCode.
//
//==============================================================================
+ (NSColor *) colorForCode:(LDrawColorT)colorCode{
	UInt8 components[4]; //rgba
	rgbaForCode(colorCode, (UInt8 *)&components);
	
	//Convert to NSColor, which wants values between 0.0 and 1.0.
	// For our purposes, we ignore alpha components. Since we are only using 
	// these colors to draw swatches in Cocoa, we get better looking swatches 
	// with no nasty side effects.
	NSColor *color = [NSColor colorWithDeviceRed:(float)components[0] / 255
										   green:(float)components[1] / 255
											blue:(float)components[2] / 255
//										   alpha:(float)components[3] / 255 ];
										   alpha:1.0 ];
	return color;
}


//========== rgbafForCode() =====================================================
//
// Purpose:		Returns the RGB/alpha components (in GLfloats) for the given 
//				LDraw color code.
//
// Notes:		GLfloats are supposedly faster.
//
//==============================================================================
void rgbafForCode(LDrawColorT colorCode, GLfloat *colorArray){
	UInt8	colorBytes[4];
	int		counter;
	
	rgbaForCode(colorCode, colorBytes);
	for(counter = 0; counter < 4; counter++)
		colorArray[counter] = colorBytes[counter] / 255.0; //convert to floats.
}


//========== rgbaForCode() =====================================================
//
// Purpose:		Returns the RGB/alpha components (in bytes) for the given 
//				LDraw color code.
//
// Notes:		Thank goodness for Grep.
//
//==============================================================================
void rgbaForCode(LDrawColorT colorCode, UInt8 *colorArray){

	switch(colorCode){
	
		case LDrawColorBogus:			//this doesn't exist, and should never be looked up!
		
		case LDrawBlack:				//color 0
			colorArray[0] = 33;
			colorArray[1] = 33;
			colorArray[2] = 33;
			colorArray[3] = 255;
			break;

		case LDrawBlue:					//color 1
			colorArray[0] = 0;
			colorArray[1] = 51;
			colorArray[2] = 178;
			colorArray[3] = 255;
			break;

		case LDrawGreen:				//color 2
			colorArray[0] = 0;
			colorArray[1] = 140;
			colorArray[2] = 20;
			colorArray[3] = 255;
			break;

		case LDrawTeal:					//color 3
			colorArray[0] = 0;
			colorArray[1] = 153;
			colorArray[2] = 159;
			colorArray[3] = 255;
			break;

		case LDrawRed:					//color 4
			colorArray[0] = 196;
			colorArray[1] = 0;
			colorArray[2] = 38;
			colorArray[3] = 255;
			break;

		case LDrawDarkPink:				//color 5
			colorArray[0] = 223;
			colorArray[1] = 102;
			colorArray[2] = 149;
			colorArray[3] = 255;
			break;

		case LDrawBrown:				//color 6
			colorArray[0] = 92;
			colorArray[1] = 32;
			colorArray[2] = 0;
			colorArray[3] = 255;
			break;

		case LDrawGray:					//color 7
			colorArray[0] = 193;
			colorArray[1] = 194;
			colorArray[2] = 193;
			colorArray[3] = 255;
			break;

		case LDrawDarkGray:				//color 8
			colorArray[0] = 99;
			colorArray[1] = 95;
			colorArray[2] = 82;
			colorArray[3] = 255;
			break;

		case LDrawLightBlue:			//color 9
			colorArray[0] = 107;
			colorArray[1] = 171;
			colorArray[2] = 220;
			colorArray[3] = 255;
			break;

		case LDrawBrightGreen:			//color 10
			colorArray[0] = 107;
			colorArray[1] = 238;
			colorArray[2] = 144;
			colorArray[3] = 255;
			break;

		case LDrawTurquiose:			//color 11
			colorArray[0] = 51;
			colorArray[1] = 166;
			colorArray[2] = 167;
			colorArray[3] = 255;
			break;

		case LDrawLightRed:				//color 12
			colorArray[0] = 255;
			colorArray[1] = 133;
			colorArray[2] = 122;
			colorArray[3] = 255;
			break;

		case LDrawPink:					//color 13
			colorArray[0] = 249;
			colorArray[1] = 164;
			colorArray[2] = 198;
			colorArray[3] = 255;
			break;

		case LDrawYellow:				//color 14
			colorArray[0] = 255;
			colorArray[1] = 220;
			colorArray[2] = 0;
			colorArray[3] = 255;
			break;

		case LDrawWhite:				//color 15
			colorArray[0] = 255;
			colorArray[1] = 255;
			colorArray[2] = 255;
			colorArray[3] = 255;
			break;

		case LDrawCurrentColor:			//color 16
			colorArray[0] = 255;		// this "color" will only appear when there is no 
			colorArray[1] = 255;		// color actually selected; otherwise, you'll see
			colorArray[2] = 206;		// that color not this one.
			colorArray[3] = 255;
			break;

		case LDrawLightGreen:			//color 17
			colorArray[0] = 186;
			colorArray[1] = 255;
			colorArray[2] = 206;
			colorArray[3] = 255;
			break;

		case LDrawLightYellow:			//color 18
			colorArray[0] = 253;
			colorArray[1] = 232;
			colorArray[2] = 150;
			colorArray[3] = 255;
			break;

		case LDrawTan:					//color 19
			colorArray[0] = 232;
			colorArray[1] = 207;
			colorArray[2] = 161;
			colorArray[3] = 255;
			break;

		case LDrawLightViolet:			//color 20
			colorArray[0] = 215;
			colorArray[1] = 196;
			colorArray[2] = 230;
			colorArray[3] = 255;
			break;

		case LDrawPhosphorWhite:		//color 21
			colorArray[0] = 224;
			colorArray[1] = 255;
			colorArray[2] = 176;
			colorArray[3] = 0.85 * 255;
			break;

		case LDrawViolet:				//color 22
			colorArray[0] = 129;
			colorArray[1] = 0;
			colorArray[2] = 123;
			colorArray[3] = 255;
			break;

		case LDrawVioletBlue:			//color 23
			colorArray[0] = 71;
			colorArray[1] = 50;
			colorArray[2] = 176;
			colorArray[3] = 255;
			break;

		case LDrawEdgeColor:			//color 24
			colorArray[0] = 136;		// this "color" will only appear when there is no 
			colorArray[1] = 136;		// color actually selected; otherwise, you'll see
			colorArray[2] = 125;		// a contrast to that color not this one.
			colorArray[3] = 255;
			break;
			
		case LDrawOrange:				//color 25
			colorArray[0] = 249;
			colorArray[1] = 96;
			colorArray[2] = 0;
			colorArray[3] = 255;
			break;

		case LDrawMagenta:				//color 26
			colorArray[0] = 216;
			colorArray[1] = 27;
			colorArray[2] = 109;
			colorArray[3] = 255;
			break;

		case LDrawLime:					//color 27
			colorArray[0] = 215;
			colorArray[1] = 240;
			colorArray[2] = 0;
			colorArray[3] = 255;
			break;

		case LDrawDarkTan:				//color 28
			colorArray[0] = 197;
			colorArray[1] = 151;
			colorArray[2] = 80;
			colorArray[3] = 255;
			break;

		case LDrawTransBlue:			//color 33
			colorArray[0] = 0;
			colorArray[1] = 32;
			colorArray[2] = 160;
			colorArray[3] = 0.45 * 255;
			break;

		case LDrawTransGreen:			//color 34
			colorArray[0] = 6;
			colorArray[1] = 100;
			colorArray[2] = 50;
			colorArray[3] = 0.45 * 255;
			break;

		case LDrawTransRed:				//color 36
			colorArray[0] = 196;
			colorArray[1] = 0;
			colorArray[2] = 38;
			colorArray[3] = 0.45 * 255;
			break;

		case LDrawTransViolet:			//color 37
			colorArray[0] = 100;
			colorArray[1] = 0;
			colorArray[2] = 97;
			colorArray[3] = 0.45 * 255;
			break;

		case LDrawTransGray:			//color 40
			colorArray[0] = 99;
			colorArray[1] = 95;
			colorArray[2] = 82;
			colorArray[3] = 0.45 * 255;
			break;

		case LDrawTransLightCyan:		//color 41
			colorArray[0] = 174;
			colorArray[1] = 239;
			colorArray[2] = 236;
			colorArray[3] = 0.45 * 255;
			break;

		case LDrawTransFluLime:			//color 42
			colorArray[0] = 192;
			colorArray[1] = 255;
			colorArray[2] = 0;
			colorArray[3] = 0.45 * 255;
			break;

		case LDrawTransPink:			//color 45
			colorArray[0] = 223;
			colorArray[1] = 102;
			colorArray[2] = 149;
			colorArray[3] = 0.45 * 255;
			break;

		case LDrawTransYellow:			//color 46
			colorArray[0] = 202;
			colorArray[1] = 176;
			colorArray[2] = 0;
			colorArray[3] = 0.45 * 255;
			break;

		case LDrawClear:				//color 47
			colorArray[0] = 255;
			colorArray[1] = 255;
			colorArray[2] = 255;
			colorArray[3] = 0.65 * 255;
			break;

		case LDrawTransFluOrange:		//color 57
			colorArray[0] = 249;
			colorArray[1] = 96;
			colorArray[2] = 0;
			colorArray[3] = 0.45 * 255;
			break;

		case LDrawReddishBrown:			//color 70
			colorArray[0] = 105;
			colorArray[1] = 64;
			colorArray[2] = 39;
			colorArray[3] = 255;
			break;

		case LDrawStoneGray:			//color 71
			colorArray[0] = 163;
			colorArray[1] = 162;
			colorArray[2] = 164;
			colorArray[3] = 255;
			break;

		case LDrawDarkStoneGray:		//color 72
			colorArray[0] = 99;
			colorArray[1] = 95;
			colorArray[2] = 97;
			colorArray[3] = 255;
			break;

		case LDrawPearlCopper:			//color 134
			colorArray[0] = 147;
			colorArray[1] = 135;
			colorArray[2] = 103;
			colorArray[3] = 255;
			break;

		case LDrawPearlGray:			//color 135
			colorArray[0] = 171;
			colorArray[1] = 173;
			colorArray[2] = 172;
			colorArray[3] = 255;
			break;

		case LDrawPearlSandBlue:		//color 137
			colorArray[0] = 106;
			colorArray[1] = 122;
			colorArray[2] = 150;
			colorArray[3] = 255;
			break;

		case LDrawPearlGold:			//color 142
			colorArray[0] = 215;
			colorArray[1] = 169;
			colorArray[2] = 75;
			colorArray[3] = 255;
			break;

		case LDrawRubberBlack:			//color 256
			colorArray[0] = 33;
			colorArray[1] = 33;
			colorArray[2] = 33;
			colorArray[3] = 255;
			break;

		case LDrawDarkBlue:				//color 272
			colorArray[0] = 0;
			colorArray[1] = 29;
			colorArray[2] = 104;
			colorArray[3] = 255;
			break;

		case LDrawRubberBlue:			//color 273
			colorArray[0] = 0;
			colorArray[1] = 51;
			colorArray[2] = 178;
			colorArray[3] = 255;
			break;

		case LDrawDarkGreen:			//color 288
			colorArray[0] = 39;
			colorArray[1] = 70;
			colorArray[2] = 44;
			colorArray[3] = 255;
			break;

		case LDrawDarkRed:				//color 320
			colorArray[0] = 120;
			colorArray[1] = 0;
			colorArray[2] = 28;
			colorArray[3] = 255;
			break;

		case LDrawRubberRed:			//color 324
			colorArray[0] = 196;
			colorArray[1] = 0;
			colorArray[2] = 38;
			colorArray[3] = 255;
			break;

		case LDrawChromeGold:			//color 334
			colorArray[0] = 225;
			colorArray[1] = 110;
			colorArray[2] = 19;
			colorArray[3] = 255;
			break;

		case LDrawSandRed:				//color 335
			colorArray[0] = 191;
			colorArray[1] = 135;
			colorArray[2] = 130;
			colorArray[3] = 255;
			break;

		case LDrawEarthOrange:			//color 366
			colorArray[0] = 209;
			colorArray[1] = 131;
			colorArray[2] = 4;
			colorArray[3] = 255;
			break;

		case LDrawSandViolet:			//color 373
			colorArray[0] = 132;
			colorArray[1] = 94;
			colorArray[2] = 132;
			colorArray[3] = 255;
			break;

		case LDrawRubberGray:			//color 375
			colorArray[0] = 193;
			colorArray[1] = 194;
			colorArray[2] = 193;
			colorArray[3] = 255;
			break;

		case LDrawSandGreen:			//color 378
			colorArray[0] = 160;
			colorArray[1] = 188;
			colorArray[2] = 172;
			colorArray[3] = 255;
			break;

		case LDrawSandBlue:				//color 379
			colorArray[0] = 106;
			colorArray[1] = 122;
			colorArray[2] = 150;
			colorArray[3] = 255;
			break;

		case LDrawChromeSilver:			//color 383
			colorArray[0] = 224;
			colorArray[1] = 224;
			colorArray[2] = 224;
			colorArray[3] = 255;
			break;

		case LDrawLightOrange:			//color 462
			colorArray[0] = 254;
			colorArray[1] = 159;
			colorArray[2] = 6;
			colorArray[3] = 255;
			break;

		case LDrawDarkOrange:			//color 484
			colorArray[0] = 179;
			colorArray[1] = 62;
			colorArray[2] = 0;
			colorArray[3] = 255;
			break;

		case LDrawElectricContact:		//color 494
			colorArray[0] = 208;
			colorArray[1] = 208;
			colorArray[2] = 208;
			colorArray[3] = 255;
			break;

		case LDrawLightGray:			//color 503
			colorArray[0] = 230;
			colorArray[1] = 227;
			colorArray[2] = 218;
			colorArray[3] = 255;
			break;

		case LDrawRubberWhite:			//color 511
			colorArray[0] = 255;
			colorArray[1] = 255;
			colorArray[2] = 255;
			colorArray[3] = 255;
			break;


			
	}
}

@end

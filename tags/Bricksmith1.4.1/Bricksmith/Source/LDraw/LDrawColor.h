//==============================================================================
//
// File:		LDrawColor.h
//
// Purpose:		A repository of methods, functions, and data types used to 
//				support LDraw colors.
//
//  Created by Allen Smith on 2/26/05.
//  Copyright 2005. All rights reserved.
//==============================================================================
#import <Cocoa/Cocoa.h>

#import <OpenGL/GL.h>

//Lists all LDraw Colors.
// LDraw colors are defined at www.ldraw.org.
// Each color has a name (in the Localized strings) and an RGBA value, which 
// can be looked up in rgbaForCode().
// Adding additional colors requires adding records in the aforementioned 
// places, as well as in the +LDrawColors method.
typedef enum {
	
	LDrawColorBogus				= -1, //used for uninitialized colors.

	LDrawBlack					= 0,
	LDrawBlue					= 1,
	LDrawGreen					= 2,
	LDrawTeal					= 3,
	LDrawRed					= 4,
	LDrawDarkPink				= 5,
	LDrawBrown					= 6,
	LDrawGray					= 7,
	LDrawDarkGray				= 8,
	LDrawLightBlue				= 9,
	LDrawBrightGreen			= 10,
	LDrawTurquiose				= 11,
	LDrawLightRed				= 12,
	LDrawPink					= 13,
	LDrawYellow					= 14,
	LDrawWhite					= 15,
	LDrawCurrentColor			= 16, //special non-color takes hue of whatever the previous color was.
	LDrawLightGreen				= 17,
	LDrawLightYellow			= 18,
	LDrawTan					= 19,
	LDrawLightViolet			= 20,
	LDrawPhosphorWhite			= 21,
	LDrawViolet					= 22,
	LDrawVioletBlue				= 23,
	LDrawEdgeColor				= 24, //special non-color contrasts the current color.
	LDrawOrange					= 25,
	LDrawMagenta				= 26,
	LDrawLime					= 27,
	LDrawDarkTan				= 28,
	LDrawTransBlue				= 33,
	LDrawTransGreen				= 34,
	LDrawTransRed				= 36,
	LDrawTransViolet			= 37,
	LDrawTransGray				= 40,
	LDrawTransLightCyan			= 41,
	LDrawTransFluLime			= 42,
	LDrawTransPink				= 45,
	LDrawTransYellow			= 46,
	LDrawClear					= 47,
	LDrawTransFluOrange			= 57,
	LDrawReddishBrown			= 70,
	LDrawStoneGray				= 71,
	LDrawDarkStoneGray			= 72,
	LDrawPearlCopper			= 134,
	LDrawPearlGray				= 135,
	LDrawPearlSandBlue			= 137,
	LDrawPearlGold				= 142,
	LDrawRubberBlack			= 256,
	LDrawDarkBlue				= 272,
	LDrawRubberBlue				= 273,
	LDrawDarkGreen				= 288,
	LDrawDarkRed				= 320,
	LDrawRubberRed				= 324,
	LDrawChromeGold				= 334,
	LDrawSandRed				= 335,
	LDrawEarthOrange			= 366,
	LDrawSandViolet				= 373,
	LDrawRubberGray				= 375,
	LDrawSandGreen				= 378,
	LDrawSandBlue				= 379,
	LDrawChromeSilver			= 383,
	LDrawLightOrange			= 462,
	LDrawDarkOrange				= 484,
	LDrawElectricContact		= 494,
	LDrawLightGray				= 503,
	LDrawRubberWhite			= 511
	
} LDrawColorT;



//Protocol for classes that accept colors.
// This protocol is adopted by classes such as LDrawPart and LDrawQuadrilateral.
@protocol LDrawColorable

-(LDrawColorT) LDrawColor;
- (void) setLDrawColor:(LDrawColorT)newColor;

@end


//The class itself is a collection of static methods to do things with colors.
@interface LDrawColor : NSObject {

}

+ (NSArray *) LDrawColors;
+ (NSArray *) LDrawColorNamePairs;
+ (NSColor *) colorForCode:(LDrawColorT)colorCode;
+ (NSString *) nameForLDrawColor:(LDrawColorT) colorCode;
void rgbaForCode(LDrawColorT colorCode, UInt8 *colorArray);
void rgbafForCode(LDrawColorT colorCode, GLfloat *colorArray);
void complimentColor(GLfloat *originalColor, GLfloat *complimentColor);

@end

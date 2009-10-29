//==============================================================================
//
// File:		ColorLibrary.h
//
// Purpose:		A repository of methods, functions, and data types used to 
//				support LDraw colors.
//
// Modified:	2/26/05 Allen Smith. Creation date (LDrawColor.m)
//				3/16/08 Allen Smith. Moved to ColorLibrary as part of 
//							ldconfig.ldr support. 
//
//  Copyright 2005. All rights reserved.
//==============================================================================
#import <Cocoa/Cocoa.h>

#import <OpenGL/GL.h>

// Forward declarations
@class LDrawColor;


////////////////////////////////////////////////////////////////////////////////
//
// Enumeration:	LDrawColorT
//
// Purpose:		Provides named symbols for many commenly-accepted/official LDraw 
//				color codes. 
//
// Notes:		LDraw colors are defined by the ldconfig.ldr file distributed 
//				with LDraw. 
//
//				The list below is mainly a relic from the days before Bricksmith 
//				supported dynamic !COLOUR definitions, but it has been given a 
//				stay of execution due to the fact that it makes debugging 
//				prettier. Its maintenance is not guaranteed. 
//
//				LDrawColorBogus is not defined by LDraw.org; it is a 
//				Bricksmithism used for uninitialized or error colors. 
//
////////////////////////////////////////////////////////////////////////////////
typedef enum
{	
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


////////////////////////////////////////////////////////////////////////////////
//
// Protocol:	LDrawColorable
//
// Notes:		This protocol is adopted by classes that accept colors, such as 
//				LDrawPart and LDrawQuadrilateral. 
//
////////////////////////////////////////////////////////////////////////////////
@protocol LDrawColorable

-(LDrawColorT) LDrawColor;
- (void) setLDrawColor:(LDrawColorT)newColor;

@end


////////////////////////////////////////////////////////////////////////////////
//
// Class:		ColorLibrary
//
////////////////////////////////////////////////////////////////////////////////
@interface ColorLibrary : NSObject
{
	NSMutableDictionary	*colors; // keys are LDrawColorT codes; objects are LDrawColors
}

// Initialization
+ (ColorLibrary *) sharedColorLibrary;

// Accessors
- (NSArray *) colors;
- (LDrawColor *) colorForCode:(LDrawColorT)colorCode;
- (void) getComplimentRGBA:(GLfloat *)complimentRGBA forCode:(LDrawColorT)colorCode;

// Registering Colors
- (void) addColor:(LDrawColor *)newColor;

// Utilities
+ (NSString *) ldconfigPath;

void complimentColor(GLfloat *originalColor, GLfloat *complimentColor);

@end

//==============================================================================
//
// File:		LDrawColor.h
//
// Purpose:		Defines a LDraw color code and its attributes. These come from 
//				parsing !COLOUR directives in ldconfig.ldr. 
//
// Modified:	3/16/08 Allen Smith.
//
//==============================================================================
#import <Cocoa/Cocoa.h>
#import <OpenGL/gl.h>

#import "LDrawMetaCommand.h"
#import "ColorLibrary.h"

typedef enum LDrawColorMaterial
{
	LDrawColorMaterialNone			= 0,
	LDrawColorMaterialChrome		= 1,
	LDrawColorMaterialPearlescent	= 2,
	LDrawColorMaterialRubber		= 3,
	LDrawColorMaterialMatteMetallic	= 4,
	LDrawColorMaterialMetal			= 5,
	LDrawColorMaterialCustom		= 6,

} LDrawColorMaterialT;


////////////////////////////////////////////////////////////////////////////////
//
// Class:	LDrawColor
//
// Notes:	This does NOT conform to LDrawColorable, because we do not want 
//			color picker changes affecting the values of these objects. 
//
////////////////////////////////////////////////////////////////////////////////
@interface LDrawColor : LDrawMetaCommand
{
	LDrawColorT			 colorCode;
	GLfloat				 colorRGBA[4];		// range [0.0 - 1.0]
	LDrawColorT			 edgeColorCode;		// == LDrawColorBogus if not used
	GLfloat				 edgeColorRGBA[4];
	BOOL				 hasExplicitAlpha;
	BOOL				 hasLuminance;
	uint8_t				 luminance;
	LDrawColorMaterialT	 material;
	NSString			*materialParameters;
	NSString			*name;
}

// Accessors

- (LDrawColorT)			colorCode;
- (LDrawColorT)			edgeColorCode;
- (void)				getColorRGBA:(GLfloat *)inComponents;
- (void)				getEdgeColorRGBA:(GLfloat *)inComponents;
- (NSString *)			localizedName;
- (uint8_t)				luminance;
- (LDrawColorMaterialT)	material;
- (NSString *)			materialParameters;
- (NSString *)			name;

- (void) setColorCode:(LDrawColorT)newCode;
- (void) setColorRGBA:(GLfloat *)newComponents;
- (void) setEdgeColorCode:(LDrawColorT)newCode;
- (void) setEdgeColorRGBA:(GLfloat *)newComponents;
- (void) setLuminance:(uint8_t)newValue;
- (void) setMaterial:(LDrawColorMaterialT)newValue;
- (void) setMaterialParameters:(NSString *)newValue;
- (void) setName:(NSString *)newName;

// Utilities
- (NSComparisonResult) HSVACompare:(LDrawColor *)otherColor;
- (NSString *) hexStringForRGB:(GLfloat *)components;
- (BOOL) scanHexString:(NSScanner *)hexScanner intoRGB:(GLfloat *)components;

@end

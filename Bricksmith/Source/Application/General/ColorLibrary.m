//==============================================================================
//
// File:		ColorLibrary.m
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
#import "ColorLibrary.h"

#import "LDrawColor.h"
#import "LDrawFile.h"
#import "LDrawModel.h"
#import "MacLDraw.h"

@implementation ColorLibrary

static ColorLibrary	*sharedColorLibrary	= nil;


#pragma mark -
#pragma mark INITIALIZATION
#pragma mark -

//---------- sharedColorLibrary --------------------------------------[static]--
//
// Purpose:		Returns the global color library available to all LDraw objects. 
//				The colors are dynamically read from ldconfig.ldr. 
//
//------------------------------------------------------------------------------
+ (ColorLibrary *) sharedColorLibrary
{
	NSString	*ldconfigPath	= nil;
	LDrawFile	*ldconfigFile	= nil;
	GLfloat		 nonColor[4]	= {0};

	if(sharedColorLibrary == nil)
	{
		//---------- Read colors in ldconfig.ldr -------------------------------
		
		// Read it in.
		ldconfigPath		= [self ldconfigPath];
		ldconfigFile		= [LDrawFile fileFromContentsAtPath:ldconfigPath];
		
		// "Draw" it so that all the colors are recorded in the library
		[ldconfigFile draw:DRAW_NO_OPTIONS parentColor:nonColor];
		
		sharedColorLibrary	= [[[ldconfigFile activeModel] colorLibrary] retain];
		
		
		//---------- Special Colors --------------------------------------------
		// These meta-colors are chameleons that are interpreted based on the 
		// context. But we still need to create entries for them in the library 
		// so that they can be selected in the color palette. 
		
		LDrawColor	*currentColor			= [[[LDrawColor alloc] init] autorelease];
		LDrawColor	*edgeColor				= [[[LDrawColor alloc] init] autorelease];
		GLfloat		 currentColorRGBA[4]	= {1.0, 1.0, 0.81, 1.0};
		GLfloat		 edgeColorRGBA[4]		= {0.75, 0.75, 0.75, 1.0};
		
		// Make the "current color" a blah sort of beige. We display parts in 
		// the part browser using this "color"; that's the only time we'll ever 
		// see it. 
		[currentColor	setColorCode:LDrawCurrentColor];
		[currentColor	setColorRGBA:currentColorRGBA];
		
		// The edge color is never seen in models, but it still appears in the 
		// color panel, so we need to give it something. 
		[edgeColor		setColorCode:LDrawEdgeColor];
		[edgeColor		setColorRGBA:edgeColorRGBA];
		
		// Register both special colors in the library
		[sharedColorLibrary addColor:currentColor];
		[sharedColorLibrary addColor:edgeColor];
	}
	
	return sharedColorLibrary;
	
}//end sharedColorLibrary


//========== init ==============================================================
//
// Purpose:		Initialize the object.
//
//==============================================================================
- (id) init
{
	self = [super init];
	
	colors = [[NSMutableDictionary alloc] init];
	
	return self;

}//end init


#pragma mark -
#pragma mark ACCESSORS
#pragma mark -

//========== colors ============================================================
//
// Purpose:		Returns a list of the LDrawColor objects registered in this 
//				library. 
//
//==============================================================================
- (NSArray *) colors
{
	return [self->colors allValues];
	
}//end LDrawColors


//========== colorForCode: =====================================================
//
// Purpose:		Returns the LDrawColor object representing colorCode, or nil if 
//				no such color number is registered. This method also searches 
//				the shared library, since its colors have global scope. 
//
//==============================================================================
- (LDrawColor *) colorForCode:(LDrawColorT)colorCode
{
	NSNumber	*key	= [NSNumber numberWithInteger:colorCode];
	LDrawColor	*color	= [self->colors objectForKey:key];
	
	if(color == nil && self != sharedColorLibrary)
	{
		color = [[ColorLibrary sharedColorLibrary] colorForCode:colorCode];
	}
	
	return color;
	
}//end colorForCode:


//========== complimentColorForCode: ===========================================
//
// Purpose:		Returns the color that should be used when the compliment color 
//				is requested for the given code. Compliment colors are usually 
//				used to draw lines on the edges of parts. 
//
// Notes:		It may seem odd to have the method in the Color Library rather 
//				than the color object itself. The reason is that a color may 
//				specify its compliment color either as actual color components 
//				or as another color code. Since colors have no actual knowledge 
//				of the library in which they are contained, we must look up the 
//				actual code here. 
//
//				Also note that the default ldconfig.ldr file defines most 
//				compliment colors as black, which is well and good for printed 
//				instructions, but less than stellar for onscreen display. The 
//				visual looks a lot more realistic when red has an edge color of, 
//				say, pink. 
//
//==============================================================================
- (void) getComplimentRGBA:(GLfloat *)complimentRGBA
				   forCode:(LDrawColorT)colorCode
{
	LDrawColor	*mainColor		= [self colorForCode:colorCode];
	LDrawColorT	 edgeColorCode	= LDrawColorBogus;
	
	if(mainColor != nil)
	{
		edgeColorCode	= [mainColor edgeColorCode];
		
		// If the color has a defined RGBA edge color, use it. Otherwise, look 
		// up the components of the color it points to. 
		if(edgeColorCode == LDrawColorBogus)
			[mainColor getEdgeColorRGBA:complimentRGBA];
		else
			[[self colorForCode:edgeColorCode] getColorRGBA:complimentRGBA];
	}
	
}//end complimentColorForCode:


#pragma mark -
#pragma mark REGISTERING COLORS
#pragma mark -

//========== addColor: =========================================================
//
// Purpose:		Adds the given color to the receiver.
//
//==============================================================================
- (void) addColor:(LDrawColor *)newColor
{
	LDrawColorT	 colorCode	= [newColor colorCode];
	NSNumber	*key		= [NSNumber numberWithInteger:colorCode];

	[self->colors setObject:newColor forKey:key];
	
}//end addColor:


#pragma mark -
#pragma mark UTILITIES
#pragma mark -

//---------- ldconfigPath --------------------------------------------[static]--
//
// Purpose:		Returns the path to LDraw/ldconfig.ldr, or maybe our fallback 
//				internal file. If this method returns a path that doesn't 
//				actually exist, it means somebody was messing with the 
//				application bundle. 
//
//------------------------------------------------------------------------------
+ (NSString *) ldconfigPath
{
	NSUserDefaults	*userDefaults	= [NSUserDefaults standardUserDefaults];
	NSFileManager	*fileManager	= [NSFileManager defaultManager];
	NSBundle		*mainBundle		= nil;
	NSString		*ldrawPath		= [userDefaults objectForKey:LDRAW_PATH_KEY];
	NSString		*installedPath	= [ldrawPath stringByAppendingPathComponent:@"LDConfig.ldr"];
	NSString		*builtInPath	= nil;
	NSString		*ldconfigPath	= nil;
	BOOL			 installSuccess	= NO;
	
	// Try in the LDraw folder first
	if(installedPath != nil) // could be nil if no LDraw folder is set in prefs
	{
		if([fileManager fileExistsAtPath:installedPath] == YES)
			ldconfigPath = installedPath;
	}
	
	// Try inside the application bundle instead
	if(ldconfigPath == nil)
	{
		mainBundle	= [NSBundle mainBundle];
		builtInPath	= [mainBundle pathForResource:@"LDConfig" ofType:@"ldr"];
		
		// Attempt to install it
		if(installedPath != nil)
			installSuccess = [fileManager copyPath:builtInPath toPath:installedPath handler:nil];
		
		if(installSuccess == YES)
			ldconfigPath = installedPath;
		else
			ldconfigPath = builtInPath;
	}
	
	return ldconfigPath;
	
}//end ldconfigPath


#pragma mark -
#pragma mark UTILITY FUNCTIONS
#pragma mark -

//========== complimentColor() =================================================
//
// Purpose:		Changes the given RGBA color into a "complimentary" color, which 
//				stands out in the original color, but maintains the same hue.
//
//==============================================================================
void complimentColor(GLfloat *originalColor, GLfloat *complimentColor)
{
	int		brightestIndex	= 0;
	float	brightness		= 0.0;
	
	// Isolate the color's brightness -- that is, its biggest component
	// (This is hacky math. Real HSB does NOT work this way!)
	if(		originalColor[1] > originalColor[0]
		&&	originalColor[1] > originalColor[2])
		brightestIndex = 1;
		
	else if(	originalColor[2] > originalColor[0]
			&&	originalColor[2] > originalColor[1])
		brightestIndex = 2;
	
	brightness = originalColor[brightestIndex];
	
	//compliment dark colors with light ones and light colors with dark ones.
	if(brightness > 0.5)
	{
		// Darken
		complimentColor[0] = originalColor[0] * 0.25;
		complimentColor[1] = originalColor[1] * 0.25;
		complimentColor[2] = originalColor[2] * 0.25;
	}
	else
	{
		// Lighten
		complimentColor[0] = originalColor[0] * 3.0;
		complimentColor[1] = originalColor[1] * 3.0;
		complimentColor[2] = originalColor[2] * 3.0;
	}
	
}//end complimentColor

@end

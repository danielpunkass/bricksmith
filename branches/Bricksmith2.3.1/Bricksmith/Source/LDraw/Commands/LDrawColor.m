//==============================================================================
//
// File:		LDrawColor.m
//
// Purpose:		Meta-command representing !COLOUR definitions. Color codes are 
//				most commonly encountered in ldconfig.ldr, but they may also 
//				appear within models for local scope. 
//
//				At a high level, colors should be retrieved from a ColorLibrary 
//				object. 
//
// Modified:	3/16/08 Allen Smith. Creation Date.
//
//==============================================================================
#import "LDrawColor.h"

#import "LDrawModel.h"
#import "LDrawStep.h"
#import "MacLDraw.h"

@implementation LDrawColor

#pragma mark -
#pragma mark INITIALIZATION
#pragma mark -

//========== init ==============================================================
//
// Purpose:		Initialize a new object. 
//
//==============================================================================
- (id) init
{
	self = [super init];
	
	[self setColorCode:LDrawColorBogus];
	[self setEdgeColorCode:LDrawColorBogus];
	[self setMaterial:LDrawColorMaterialNone];
	[self setName:@""];
	
	return self;
	
}//end init


//========== finishParsing: ====================================================
//
// Purpose:		+directiveWithString: is responsible for parsing out the line 
//				code and color command (i.e., "0 !COLOUR"); now we just have to 
//				finish the color-command specific syntax.
//
//==============================================================================
- (BOOL) finishParsing:(NSScanner *)scanner
{
	NSString	*field				= nil;
	int			scannedAlpha		= 0;
	int			scannedLuminance	= 0;
	float		parsedColor[4]		= {0.0};
	
	[scanner setCharactersToBeSkipped:[NSCharacterSet whitespaceCharacterSet]];
	
	// Name
	[scanner scanUpToCharactersFromSet:[NSCharacterSet whitespaceCharacterSet] intoString:&field];
	[self setName:field];
	
	// Color Code
	if([scanner scanString:LDRAW_COLOR_DEF_CODE intoString:nil] == NO)
		@throw [NSException exceptionWithName:@"BricksmithParseException" reason:@"Bad !COLOUR syntax" userInfo:nil];
	if([scanner scanInt:&self->colorCode] == NO)
		@throw [NSException exceptionWithName:@"BricksmithParseException" reason:@"Bad !COLOUR syntax" userInfo:nil];
	
	// Color Components
	if([scanner scanString:LDRAW_COLOR_DEF_VALUE intoString:nil] == NO)
		@throw [NSException exceptionWithName:@"BricksmithParseException" reason:@"Bad !COLOUR syntax" userInfo:nil];
	if([self scanHexString:scanner intoRGB:self->colorRGBA] == NO)
		@throw [NSException exceptionWithName:@"BricksmithParseException" reason:@"Bad !COLOUR syntax" userInfo:nil];
		
	// Edge
	if([scanner scanString:LDRAW_COLOR_DEF_EDGE intoString:nil] == NO)
		@throw [NSException exceptionWithName:@"BricksmithParseException" reason:@"Bad !COLOUR syntax" userInfo:nil];
	if([self scanHexString:scanner intoRGB:parsedColor] == YES)
		[self setEdgeColorRGBA:parsedColor];
	else
		[scanner scanInt:&self->edgeColorCode];
	
	// Optional Fields
	
	// - Alpha
	if([scanner scanString:LDRAW_COLOR_DEF_ALPHA intoString:nil] == YES)
	{
		[scanner scanInt:&scannedAlpha];
		self->colorRGBA[3]		= (float) scannedAlpha / 255;
		self->hasExplicitAlpha	= YES;
	}
	
	// - Luminance
	if([scanner scanString:LDRAW_COLOR_DEF_LUMINANCE intoString:nil] == YES)
	{
		[scanner scanInt:&scannedLuminance];
		[self setLuminance:scannedLuminance];
	}
	
	// - Material
	if([scanner scanString:LDRAW_COLOR_DEF_MATERIAL_CHROME intoString:nil] == YES)
		[self setMaterial:LDrawColorMaterialChrome];
		
	else if([scanner scanString:LDRAW_COLOR_DEF_MATERIAL_PEARLESCENT intoString:nil] == YES)
		[self setMaterial:LDrawColorMaterialPearlescent];
	
	else if([scanner scanString:LDRAW_COLOR_DEF_MATERIAL_RUBBER intoString:nil] == YES)
		[self setMaterial:LDrawColorMaterialRubber];
	
	else if([scanner scanString:LDRAW_COLOR_DEF_MATERIAL_MATTE_METALLIC intoString:nil] == YES)
		[self setMaterial:LDrawColorMaterialMatteMetallic];
	
	else if([scanner scanString:LDRAW_COLOR_DEF_MATERIAL_METAL intoString:nil] == YES)
		[self setMaterial:LDrawColorMaterialMetal];
	
	else if([scanner scanString:LDRAW_COLOR_DEF_MATERIAL_CUSTOM intoString:nil] == YES)
	{
		[self setMaterial:LDrawColorMaterialCustom];
		
		// eat whitespace
		[scanner setCharactersToBeSkipped:nil];
		[scanner scanCharactersFromSet:[NSCharacterSet whitespaceCharacterSet] intoString:nil];
		
		// Custom material parameters are implementation-defined and follow the 
		// MATERIAL keyword. Just scan them and save them; we can't do anything 
		// with them except write them back out when the file is saved. 
		field = [[scanner string] substringFromIndex:[scanner scanLocation]];
		[self setMaterialParameters:field];
	}
	
	return YES;
	
}//end lineWithDirectiveText


#pragma mark -
#pragma mark DIRECTIVES
#pragma mark -

//========== draw:parentColor: =================================================
//
// Purpose:		"Draws" the color.
//
//==============================================================================
- (void) draw:(NSUInteger) optionsMask parentColor:(GLfloat *)parentColor
{
	// Need to add this color to the model's color library.
	ColorLibrary *colorLibrary = [[(LDrawStep*)[self enclosingDirective] enclosingModel] colorLibrary];
	
	[colorLibrary addColor:self];
		
}//end draw:parentColor:


//========== write =============================================================
//
// Purpose:		Returns a line that can be written out to a file.
//				Line format:
//				0 !COLOUR name CODE x VALUE v EDGE e [ALPHA a] [LUMINANCE l] 
//					[ CHROME | PEARLESCENT | RUBBER | MATTE_METALLIC | 
//					  METAL | MATERIAL <params> ]</params> 
//
// Notes:		This does not try to preserve spacing a la ldconfig.ldr, mainly 
//				because %17@ doesn't work. 
//
//==============================================================================
- (NSString *) write
{
	NSMutableString *line = nil;
	
	line = [NSMutableString stringWithFormat:
							@"0 %@ %@ %@ %d %@ %@",
							//	|	  |		|
								LDRAW_COLOR_DEFINITION, self->name,
							//		  |		|
									  LDRAW_COLOR_DEF_CODE,	self->colorCode,
							//				|
											LDRAW_COLOR_DEF_VALUE,	[self hexStringForRGB:self->colorRGBA] ];
											
	if(self->edgeColorCode == LDrawColorBogus)
		[line appendFormat:@" %@ %@", LDRAW_COLOR_DEF_EDGE, [self hexStringForRGB:self->edgeColorRGBA]];
	else
		[line appendFormat:@" %@ %d", LDRAW_COLOR_DEF_EDGE, self->edgeColorCode];
		
	if(self->hasExplicitAlpha == YES)
		[line appendFormat:@" %@ %d", LDRAW_COLOR_DEF_ALPHA, (int)(self->colorRGBA[3] * 255)];
		
	if(self->hasLuminance == YES)
		[line appendFormat:@" %@ %d", LDRAW_COLOR_DEF_LUMINANCE, self->luminance];
	
	switch(self->material)
	{
		case LDrawColorMaterialNone:
			break;
			
		case LDrawColorMaterialChrome:
			[line appendFormat:@" %@", LDRAW_COLOR_DEF_MATERIAL_CHROME];
			break;		
		
		case LDrawColorMaterialPearlescent:
			[line appendFormat:@" %@", LDRAW_COLOR_DEF_MATERIAL_PEARLESCENT];
			break;		
			
		case LDrawColorMaterialRubber:
			[line appendFormat:@" %@", LDRAW_COLOR_DEF_MATERIAL_RUBBER];
			break;		
			
		case LDrawColorMaterialMatteMetallic:
			[line appendFormat:@" %@", LDRAW_COLOR_DEF_MATERIAL_MATTE_METALLIC];
			break;		
			
		case LDrawColorMaterialMetal:
			[line appendFormat:@" %@", LDRAW_COLOR_DEF_MATERIAL_METAL];
			break;		
			
		case LDrawColorMaterialCustom:
			[line appendFormat:@" %@ %@", LDRAW_COLOR_DEF_MATERIAL_CUSTOM, self->materialParameters];
			break;		
	}
	
	return line;
	
}//end write


#pragma mark -
#pragma mark DISPLAY
#pragma mark -

//========== browsingDescription ===============================================
//
// Purpose:		Returns a representation of the directive as a short string 
//				which can be presented to the user.
//
//==============================================================================
- (NSString *) browsingDescription
{
	return [self name];
	
}//end browsingDescription


//========== iconName ==========================================================
//
// Purpose:		Returns the name of image file used to display this kind of 
//				object, or nil if there is no icon.
//
//==============================================================================
- (NSString *) iconName
{
	return @"ColorDroplet";
	
}//end iconName


//========== inspectorClassName ================================================
//
// Purpose:		Returns the name of the class used to inspect this one.
//
//==============================================================================
- (NSString *) inspectorClassName
{
	return nil;
	
}//end inspectorClassName


#pragma mark -
#pragma mark ACCESSORS
#pragma mark -

//========== colorCode =========================================================
//==============================================================================
- (LDrawColorT) colorCode
{
	return self->colorCode;
	
}//end colorCode


//========== edgeColorCode =====================================================
//
// Purpose:		Return the LDraw color code to be used when drawing the 
//				compilement of this color. If the compliment is stored as actual 
//				components instead, this call will return LDrawColorBogus. When 
//				that code is encountered, you should instead call edgeColorRGBA 
//				for the actual color values. 
//
//==============================================================================
- (LDrawColorT) edgeColorCode
{
	return self->edgeColorCode;
	
}//end edgeColorCode


//========== getColorRGBA: =====================================================
//
// Purpose:		Fills the inComponents array with the RGBA components of this 
//				color. 
//
//==============================================================================
- (void) getColorRGBA:(GLfloat *)inComponents
{
	memcpy(inComponents, self->colorRGBA, sizeof(GLfloat) * 4);
	
}//end getColorRGBA:


//========== getEdgeColorRGBA: =================================================
//
// Purpose:		Returns the actual color components specified for the compliment 
//				of this color. 
//
// Notes:		These values MAY NOT BE VALID. To determine if they are in 
//				force, you must first call -edgeColorCode. If it returns a value 
//				other than LDrawColorBogus, look up the color for that code 
//				instead. Otherwise, use the values returned by this method. 
//
//==============================================================================
- (void) getEdgeColorRGBA:(GLfloat *)inComponents
{
	memcpy(inComponents, self->edgeColorRGBA, sizeof(GLfloat) * 4);
	
}//end getEdgeColorRGBA:


//========== localizedName =====================================================
//
// Purpose:		Returns the name for the specified color code. If possible, the 
//				name will be localized. For colors which have no localization 
//				defined, this will default to the actual color name from the 
//				config file, with any underscores converted to spaces. 
//
// Notes:		If, in some bizarre aberration, this color has a code 
//				corresponding to a standard LDraw code, but the color is NOT 
//				actually representing this color, you will get the localized 
//				name of the standard color. Deal with it. 
//
//==============================================================================
- (NSString *) localizedName
{
	NSString *nameKey	= nil;
	NSString *colorName	= nil;
	
	//Find the color's name in the localized string file.
	// Color names are conveniently keyed.
	nameKey		= [NSString stringWithFormat:@"LDraw: %d", colorCode];
	colorName	= NSLocalizedString(nameKey , nil);
	
	// If no localization was defined, then fall back on the name defined in the 
	// color directive. 
	if([colorName isEqualToString:nameKey])
	{
		// Since spaces are verboten in !COLOUR directives, color names tend to 
		// have a bunch of unsightly underscores in them. We don't want to show 
		// that to the user. 
		NSMutableString *fixedName = [[[self name] mutableCopy] autorelease];
		[fixedName replaceOccurrencesOfString:@"_" withString:@" " options:NSLiteralSearch range:NSMakeRange(0, [fixedName length])];
		colorName = fixedName;
		
		// Alas! 10.5 only!
//		colorName = [[self name] stringByReplacingOccurrencesOfString:@"_" withString:@" "];
	}
	
	return colorName;
	
}//end localizedName


//========== luminance =========================================================
//==============================================================================
- (uint8_t) luminance
{
	return self->luminance;
	
}//end luminance


//========== material ==========================================================
//==============================================================================
- (LDrawColorMaterialT) material
{
	return self->material;
	
}//end material


//========== materialParameters ================================================
//==============================================================================
- (NSString *) materialParameters
{
	return self->materialParameters;
	
}//end materialParameters


//========== name ==============================================================
//==============================================================================
- (NSString *) name
{
	return self->name;
	
}//end name


#pragma mark -

//========== setColorCode: =====================================================
//
// Purpose:		Sets the LDraw integer code for this color.
//
//==============================================================================
- (void) setColorCode:(LDrawColorT)newCode
{
	self->colorCode = newCode;

}//end setColorCode:


//========== setColorRGBA: =====================================================
//
// Purpose:		Sets the actual RGBA component values for this color. 
//
//==============================================================================
- (void) setColorRGBA:(GLfloat *)newComponents
{
	memcpy(self->colorRGBA, newComponents, sizeof(GLfloat[4]));
	
}//end setColorRGBA:


//========== setEdgeColorCode: =================================================
//
// Purpose:		Sets the code of the color to use as this color's compliment 
//				color. That value will have to be resolved by the color library. 
//
// Notes:		Edge colors may be specified either as real color components or 
//				as a color-code reference. Only one is valid. To signal that the 
//				components should be used instead of this color code, pass 
//				LDrawColorBogus. 
//
//==============================================================================
- (void) setEdgeColorCode:(LDrawColorT)newCode
{
	self->edgeColorCode = newCode;
	
}//end setEdgeColorCode:


//========== setEdgeColorRGBA: =================================================
//
// Purpose:		Sets actual color components for the edge color.
//
// Notes:		Edge colors may be specified either as real color components or 
//				as a color-code reference. Only one is valid. If you call this 
//				method, it is assumed you are choosing the components variation. 
//				The edge color code will automatically be set to 
//				LDrawColorBogus. 
//
//==============================================================================
- (void) setEdgeColorRGBA:(GLfloat *)newComponents
{
	memcpy(self->edgeColorRGBA, newComponents, sizeof(GLfloat[4]));
	
	// Disable the edge color code, since we have real color values for it now.
	[self setEdgeColorCode:LDrawColorBogus];
	
}//end setEdgeColorRGBA:


//========== setLuminance: =====================================================
//
// Purpose:		Brightness for colors that glow (range 0-255). Luminance is not 
//				generally used by LDraw renderers (including this one), but may 
//				be used for translation to other rendering systems. LUMINANCE is 
//				optional. 
//
//==============================================================================
- (void) setLuminance:(uint8_t)newValue
{
	self->luminance		= newValue;
	self->hasLuminance	= YES;
	
}//end setLuminance:


//========== setMaterial: ======================================================
//
// Purpose:		Sets the material associated with this color.
//
// Notes:		Bricksmith doesn't use this value, it just preserves it in the 
//				color directive. 
//
//==============================================================================
- (void) setMaterial:(LDrawColorMaterialT)newValue
{
	self->material = newValue;

}//end setMaterial:


//========== setMaterialParameters: ============================================
//
// Purpose:		Custom (implementation-dependent) values associated with a 
//				custom material. 
//
// Notes:		Bricksmith doesn't use this value, it just preserves it in the 
//				color directive. 
//
//==============================================================================
- (void) setMaterialParameters:(NSString *)newValue
{
	[newValue retain];
	[self->materialParameters release];
	
	self->materialParameters = newValue;
	
}//end setMaterialParameters:


//========== setName: ==========================================================
//
// Purpose:		Sets the name of the color. Spaces are represented by 
//				underscores. 
//
//==============================================================================
- (void) setName:(NSString *)newName
{
	[newName retain];
	[self->name release];
	
	self->name = newName;
	
}//end setName:


#pragma mark -
#pragma mark UTILITIES
#pragma mark -

//========== HSVACompare: ======================================================
//
// Purpose:		Orders colors according to their Hue, Saturation, and 
//				Brightness. 
//
//==============================================================================
- (NSComparisonResult) HSVACompare:(LDrawColor *)otherColor
{
	NSColor             *ourNSColor     = nil;
	NSColor             *otherNSColor   = nil;
	NSComparisonResult  result          = NSOrderedSame;
	
	ourNSColor      = [NSColor colorWithCalibratedRed:self->colorRGBA[0]
												green:self->colorRGBA[1]
												 blue:self->colorRGBA[2]
												alpha:self->colorRGBA[3] ];
	
	otherNSColor    = [NSColor colorWithCalibratedRed:otherColor->colorRGBA[0]
												green:otherColor->colorRGBA[1]
												 blue:otherColor->colorRGBA[2]
												alpha:otherColor->colorRGBA[3] ];
	
	// Hue
	if( [ourNSColor hueComponent] > [otherNSColor hueComponent] )
		result = NSOrderedDescending;
	else if( [ourNSColor hueComponent] < [otherNSColor hueComponent] )
		result = NSOrderedAscending;
	else
	{
		// Saturation
		if( [ourNSColor saturationComponent] > [otherNSColor saturationComponent] )
			result = NSOrderedDescending;
		else if( [ourNSColor saturationComponent] < [otherNSColor saturationComponent] )
			result = NSOrderedAscending;
		else
		{
			// Brightness
			if( [ourNSColor brightnessComponent] > [otherNSColor brightnessComponent] )
				result = NSOrderedDescending;
			else if( [ourNSColor brightnessComponent] < [otherNSColor brightnessComponent] )
				result = NSOrderedAscending;
			else
			{
				// Alpha
				if( [ourNSColor alphaComponent] > [otherNSColor alphaComponent] )
					result = NSOrderedDescending;
				else if( [ourNSColor alphaComponent] < [otherNSColor alphaComponent] )
					result = NSOrderedAscending;
				else
				{
					result = NSOrderedSame;
				}
			}
		}
	}
	
	return result;
	
}//end HSVACompare:


//========== hexStringForRGB: ==================================================
//
// Purpose:		Returns a hex string for the given RGB components, formatted in 
//				the syntax required by the LDraw Colour Definition Language 
//				extension. 
//
//==============================================================================
- (NSString *) hexStringForRGB:(GLfloat *)components
{
	NSString	*hexString	= [NSString stringWithFormat:@"#%02X%02X%02X",
													(int) (components[0] * 255),
													(int) (components[1] * 255),
													(int) (components[2] * 255) ];
	return hexString;

}//end hexStringForRGB:


//========== scanHexString:intoRGB: ============================================
//
// Purpose:		Parses the given Hexidecimal string into the first three 
//				elements of the components array, dividing each hexidecimal byte 
//				by 255. 
//
// Notes:		hexString must be prefixed by either "#" or "0x". The LDraw spec 
//				is not clear on the case of the hex letters; we will assume both 
//				are valid. 
//
// Example:		#77CC00 becomes (R = 0.4666; G = 0.8; B = 0.0)
//
//==============================================================================
- (BOOL) scanHexString:(NSScanner *)hexScanner intoRGB:(GLfloat *)components
{
	unsigned	hexBytes	= 0;
	BOOL		success		= NO;
	
	// Make sure it has the required prefix, whichever it might be
	if(		[hexScanner scanString:@"#"  intoString:nil] == YES
	   ||	[hexScanner scanString:@"0x" intoString:nil] == YES )
	{
		success = YES;
	}
	
	if(success == YES)
	{
		// Scan the hex bytes into a packed integer, because that's the easiest 
		// thing to do with this NSScanner API. 
		[hexScanner scanHexInt:&hexBytes];
		
		// Colors will be stored in the integer as follows: xxRRGGBB
		components[0] = (GLfloat) ((hexBytes >> 2 * 8) & 0xFF) / 255; // Red
		components[1] = (GLfloat) ((hexBytes >> 1 * 8) & 0xFF) / 255; // Green
		components[2] = (GLfloat) ((hexBytes >> 0 * 8) & 0xFF) / 255; // Blue
		components[3] = 1.0; // we shall assume alpha
	}
	
	return success;
	
}//end parseHexString:intoRGB:


#pragma mark -
#pragma mark DESTRUCTOR
#pragma mark -

//========== dealloc ===========================================================
//
// Purpose:		We're turning blue.
//
//==============================================================================
- (void) dealloc
{
	[materialParameters	release];
	[name				release];
	
	[super dealloc];
	
}//end dealloc


@end

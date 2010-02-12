//==============================================================================
//
// File:		LDrawUtilities.m
//
// Purpose:		Convenience routines for managing LDraw directives.
//
//  Created by Allen Smith on 2/28/06.
//  Copyright 2006. All rights reserved.
//==============================================================================
#import "LDrawUtilities.h"

#import "LDrawMetaCommand.h"
#import "LDrawPart.h"
#import "LDrawLine.h"
#import "LDrawTriangle.h"
#import "LDrawQuadrilateral.h"
#import "LDrawConditionalLine.h"
#import "LDrawContainer.h"

#import "LDrawApplication.h"
#import "BezierPathCategory.h"
#import "MacLDraw.h"
#import "PartLibrary.h"

@implementation LDrawUtilities

#pragma mark -
#pragma mark PARSING
#pragma mark -

//---------- classForLineType: ---------------------------------------[static]--
//
// Purpose:		Allows initializing the right kind of class based on the code 
//				found at the beginning of an LDraw line.
//
//------------------------------------------------------------------------------
+ (Class) classForLineType:(NSInteger)lineType
{
	Class classForType = nil;
	
	switch(lineType){
		case 0:
			classForType = [LDrawMetaCommand class];
			break;
		case 1:
			classForType = [LDrawPart class];
			break;
		case 2:
			classForType = [LDrawLine class];
			break;
		case 3:
			classForType = [LDrawTriangle class];
			break;
		case 4:
			classForType = [LDrawQuadrilateral class];
			break;
		case 5:
			classForType = [LDrawConditionalLine class];
			break;
		default:
			NSLog(@"unrecognized LDraw line type: %ld", (long)lineType);
	}
	
	return classForType;
	
}//end classForLineType:


//---------- parseColorCodeFromField: --------------------------------[static]--
//
// Purpose:		Returns the color code which is represented by the field.
//
// Notes:		This supports a nonstandard but fairly widely-supported 
//				extension which allows arbitrary RGB values to be specified in 
//				place of color codes. (MLCad, L3P, LDView, and others support 
//				this.) 
//
//------------------------------------------------------------------------------
+ (LDrawColorT) parseColorCodeFromField:(NSString *)colorField
									RGB:(GLfloat*)componentsOut
{
	LDrawColorT colorCode       = LDrawColorBogus;
	NSScanner   *scanner        = [NSScanner scannerWithString:colorField];
	unsigned    hexBytes        = 0;
	int         customCodeType  = 0;

	// Custom RGB?
	if([scanner scanString:@"0x" intoString:nil] == YES)
	{
		colorCode = LDrawColorCustomRGB;
		
		// The integer should be of the format:
		// 0x2RRGGBB for opaque colors
		// 0x3RRGGBB for transparent colors
		// 0x4RGBRGB for a dither of two 12-bit RGB colors
		// 0x5RGBxxx as a dither of one 12-bit RGB color with clear (for transparency).

		[scanner scanHexInt:&hexBytes];
		customCodeType = (hexBytes >> 3*8) & 0xFF;
		
		switch(customCodeType)
		{
			// Solid color
			case 2:
				componentsOut[0] = (GLfloat) ((hexBytes >> 2*8) & 0xFF) / 255; // Red
				componentsOut[1] = (GLfloat) ((hexBytes >> 1*8) & 0xFF) / 255; // Green
				componentsOut[2] = (GLfloat) ((hexBytes >> 0*8) & 0xFF) / 255; // Blue
				componentsOut[3] = (GLfloat) 1.0; // alpha
				break;
			
			// Transparent color
			case 3:
				componentsOut[0] = (GLfloat) ((hexBytes >> 2*8) & 0xFF) / 255; // Red
				componentsOut[1] = (GLfloat) ((hexBytes >> 1*8) & 0xFF) / 255; // Green
				componentsOut[2] = (GLfloat) ((hexBytes >> 0*8) & 0xFF) / 255; // Blue
				componentsOut[3] = (GLfloat) 0.5; // alpha
				break;
			
			// combined opaque color
			case 4:
				componentsOut[0] = (GLfloat) (((hexBytes >> 5*4) & 0xF) + ((hexBytes >> 2*4) & 0xF))/2 / 255; // Red
				componentsOut[0] = (GLfloat) (((hexBytes >> 4*4) & 0xF) + ((hexBytes >> 1*4) & 0xF))/2 / 255; // Green
				componentsOut[0] = (GLfloat) (((hexBytes >> 3*4) & 0xF) + ((hexBytes >> 0*4) & 0xF))/2 / 255; // Blue
				componentsOut[3] = (GLfloat) 1.0; // alpha
				break;
				
			// bad-looking transparent color
			case 5:
				componentsOut[0] = (GLfloat) ((hexBytes >> 5*4) & 0xF) / 15; // Red
				componentsOut[0] = (GLfloat) ((hexBytes >> 4*4) & 0xF) / 15; // Green
				componentsOut[0] = (GLfloat) ((hexBytes >> 3*4) & 0xF) / 15; // Blue
				componentsOut[3] = (GLfloat) 0.5; // alpha
				break;
			
			default:
				break;
		}
	}
	else
	{
		// Regular, standards-compliant LDraw color code
		colorCode = [colorField intValue];
	}
		
	return colorCode;
	
}//end parseColorCodeFromField:


//---------- readNextField:remainder: --------------------------------[static]--
//
// Purpose:		Given the portion of the LDraw line, read the first available 
//				field. Fields are separated by whitespace of any length.
//
//				If remainder is not NULL, return by indirection the remainder of 
//				partialDirective after the first field has been removed. If 
//				there is no remainder, an empty string will be returned.
//
//				So, given the line
//				1 8 -150 -8 20 0 0 -1 0 1 0 1 0 0 3710.DAT
//
//				remainder will be set to:
//				 8 -150 -8 20 0 0 -1 0 1 0 1 0 0 3710.DAT
//
// Notes:		This method is incapable of reading field strings with spaces 
//				in them!
//
//				A case could be made to replace this method with an NSScanner!
//				They don't seem to be as adept at scanning in unknown string 
//				tags though, which would make them difficult to use to 
//				distinguish between "0 WRITE blah" and "0 COMMENT blah".
//
//------------------------------------------------------------------------------
+ (NSString *) readNextField:(NSString *) partialDirective
				   remainder:(NSString **) remainder
{
	NSCharacterSet	*whitespaceCharacterSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
	NSRange			 rangeOfNextWhiteSpace;
	NSString		*fieldContents			= nil;
	
	//First, remove any heading whitespace.
	partialDirective		= [partialDirective stringByTrimmingCharactersInSet:whitespaceCharacterSet];
	//Find the beginning of the next field separation
	rangeOfNextWhiteSpace	= [partialDirective rangeOfCharacterFromSet:whitespaceCharacterSet];
	
	//The text between the beginning and the next field separator is the first 
	// field (what we are after).
	if(rangeOfNextWhiteSpace.location != NSNotFound)
	{
		fieldContents = [partialDirective substringToIndex:rangeOfNextWhiteSpace.location];
		//See if they want the rest of the line, sans the field we just parsed.
		if(remainder != NULL)
			*remainder = [partialDirective substringFromIndex:rangeOfNextWhiteSpace.location];
	}
	else
	{
		//There was no subsequent field separator; we must be at the end of the line.
		fieldContents = partialDirective;
		if(remainder != NULL)
			*remainder = [NSString string];
	}
	
	return fieldContents;
}//end readNextField


//---------- stringFromFile: -----------------------------------------[static]--
//
// Purpose:		Reads the contents of the file at the given path into a string. 
//				We try a few different encodings.
//
//------------------------------------------------------------------------------
+ (NSString *) stringFromFile:(NSString *)path
{
	NSData      *fileData   = [NSData dataWithContentsOfFile:path];
	NSString    *fileString = nil;
	
	//try UTF-8 first, because it's so nice.
	fileString = [[NSString alloc] initWithData:fileData
									   encoding:NSUTF8StringEncoding];
	
	//uh-oh. Maybe Windows Latin?
	if(fileString == nil)
		fileString = [[NSString alloc] initWithData:fileData
										   encoding:NSISOLatin1StringEncoding];
	return [fileString autorelease];
	
}//end stringFromFile


#pragma mark -
#pragma mark MISCELLANEOUS
#pragma mark -
//This is stuff that didn't really go anywhere else.

//---------- angleForViewOrientation: --------------------------------[static]--
//
// Purpose:		Returns the viewing angle in degrees for the given orientation.
//
//------------------------------------------------------------------------------
+ (Tuple3) angleForViewOrientation:(ViewOrientationT)orientation
{
	Tuple3 angle	= ZeroPoint3;

	switch(orientation)
	{
		case ViewOrientation3D:
			// This is MLCad's default 3-D viewing angle, which is arrived at by 
			// applying these rotations in order: z=0, y=45, x=23. 
			angle = V3Make(30.976, 40.609, 21.342);
			break;
	
		case ViewOrientationFront:
			angle = V3Make(0, 0, 0);
			break;
			
		case ViewOrientationBack:
			angle = V3Make(0, 180, 0);
			break;
			
		case ViewOrientationLeft:
			angle = V3Make(0, -90, 0);
			break;
			
		case ViewOrientationRight:
			angle = V3Make(0, 90, 0);
			break;
			
		case ViewOrientationTop:
			angle = V3Make(90, 0, 0);
			break;
			
		case ViewOrientationBottom:
			angle = V3Make(-90, 0, 0);
			break;
	}
	
	return angle;
	
}//end angleForViewOrientation:


//---------- boundingBox3ForDirectives: ------------------------------[static]--
//
// Purpose:		Returns the minimum and maximum points of the box which 
//				perfectly contains all the given objects. (Only objects which 
//				respond to -boundingBox3 will be tested.)
//
// Notes:		This method used to live in LDrawContainer, which was a very 
//				nice place. But I moved it here so that other interested parties 
//				could do bounds testing on ad-hoc collections of directives.
//
//------------------------------------------------------------------------------
+ (Box3) boundingBox3ForDirectives:(NSArray *)directives
{
	Box3        bounds              = InvalidBox;
	Box3        partBounds          = InvalidBox;
	id          currentDirective    = nil;
	NSUInteger  numberOfDirectives  = [directives count];
	NSUInteger  counter             = 0;
	
	for(counter = 0; counter < numberOfDirectives; counter++)
	{
		currentDirective = [directives objectAtIndex:counter];
		if([currentDirective respondsToSelector:@selector(boundingBox3)])
		{
			partBounds	= [currentDirective boundingBox3];
			bounds		= V3UnionBox(bounds, partBounds);
		}
	}
	
	return bounds;
	
}//end boundingBox3ForDirectives


//---------- dragImageWithOffset: ------------------------------------[static]--
//
// Purpose:		Returns the image used to denote drag-and-drop of parts. 
//
// Notes:		We don't use this image when dragging rows in the file contents, 
//				just when using physically moving parts within the model. 
//
//------------------------------------------------------------------------------
+ (NSImage *) dragImageWithOffset:(NSPointPointer)dragImageOffset
{
	NSImage	*brickImage			= [NSImage imageNamed:@"Brick"];
	CGFloat	 border				= 3;
	NSSize	 dragImageSize		= NSMakeSize([brickImage size].width + border*2, [brickImage size].height + border*2);
	NSImage	*dragImage			= [[NSImage alloc] initWithSize:dragImageSize];
	NSImage *arrowCursorImage	= [[NSCursor arrowCursor] image];
	NSSize	 arrowSize			= [arrowCursorImage size];
	
	[dragImage lockFocus];
		
		[[NSColor colorWithDeviceWhite:0.6 alpha:0.75] set];
		[[NSBezierPath bezierPathWithRect:NSMakeRect(0, 0, dragImageSize.width,dragImageSize.height) radiusPercentage:50.0] fill];
		
		[brickImage drawAtPoint:NSMakePoint(border, border) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
		
	[dragImage unlockFocus];
	
	if(dragImageOffset != NULL)
	{
		// Now provide an offset to move the image over so it looks like a badge 
		// next to the cursor: 
		//   ...Turns out the arrow cursor image is a 24 x 24 picture, and the 
		//   arrow itself occupies only a small part of the lefthand side of 
		//   that space. We have to resort to a hardcoded assumption that the 
		//   actual arrow picture fills only half the full image. 
		//   ...We subtract from y; that is the natural direction for a lowering 
		//   offset. In a flipped view, negate that value.  
		(*dragImageOffset).x +=  arrowSize.width/2;
		(*dragImageOffset).y -= (arrowSize.height/2 + [dragImage size].height/2);
	}
	
	return [dragImage autorelease];

}//end dragImageWithOffset:


//---------- gridSpacingForMode: -------------------------------------[static]--
//
// Purpose:		Translates the given grid spacing granularity into an actual 
//				number of LDraw units, according to the user's preferences. 
//
// Notes:		This value represents distances "along the studs"--that is, 
//			    horizontal along the brick. Vertical distances may be adjusted. 
//
//------------------------------------------------------------------------------
+ (float) gridSpacingForMode:(gridSpacingModeT)gridMode
{
	NSUserDefaults	*userDefaults	= [NSUserDefaults standardUserDefaults];
	float			 gridSpacing	= 0.0;
	
	switch(gridMode)
	{
		case gridModeFine:
			gridSpacing		= [userDefaults floatForKey:GRID_SPACING_FINE];
			break;
			
		case gridModeMedium:
			gridSpacing		= [userDefaults floatForKey:GRID_SPACING_MEDIUM];
			break;
			
		case gridModeCoarse:
			gridSpacing		= [userDefaults floatForKey:GRID_SPACING_COARSE];
			break;
	}
	
	return gridSpacing;
	
}//end gridSpacingForMode:


//---------- isLDrawFilenameValid: -----------------------------------[static]--
//
// Purpose:		The LDraw File Specification defines what makes a valid LDraw 
//				file name: http://www.ldraw.org/Article218.html#files 
//
//				Alas, these rules suck in MPD names too, thanks to the wording 
//				on Linetype 1 in the spec. 
//
// Notes:		The spec also has disparaging things to say about whitespace and 
//				special characters in filenames. To the spec I say: join the 
//				1990s. 
//
//------------------------------------------------------------------------------
+ (BOOL) isLDrawFilenameValid:(NSString *)fileName
{
	NSString	*extension	= [fileName pathExtension];
	BOOL		isValid		= NO;
	
	// Make sure it has a valid extension
	if(		extension == nil
	   ||	(	[extension isEqualToString:@"ldr"] == NO
			 &&	[extension isEqualToString:@"dat"] == NO )
	   )
	{
		isValid = NO;
	}
	else
		isValid = YES;
		
	return isValid;
	
}//end isLDrawFilenameValid:


//---------- updateNameForMovedPart: ---------------------------------[static]--
//
// Purpose:		If the specified part has been moved to a new number/name by 
//				LDraw.org, this method will update the part name to point to the 
//				new location.
//
//				Example:
//					193.dat (~Moved to 193a) becomes 193a.dat
//
//------------------------------------------------------------------------------
+ (void) updateNameForMovedPart:(LDrawPart *)movedPart
{
	NSString	*description	= [[LDrawApplication sharedPartLibrary] descriptionForPart:movedPart];
	NSString	*newName		= nil;
	
	if([description hasPrefix:LDRAW_MOVED_DESCRIPTION_PREFIX])
	{
		//isolate the new number and add the .dat library suffix.
		newName = [description substringFromIndex:[LDRAW_MOVED_DESCRIPTION_PREFIX length]];
		newName = [newName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
		newName = [newName stringByAppendingString:@".dat"];
		
		[movedPart setDisplayName:newName];
	}
	
}//end updateNameForMovedPart:


//---------- viewOrientationForAngle: --------------------------------[static]--
//
// Purpose:		Returns the viewing orientation for the given angle. If the 
//				angle is not a recognized head-on view, ViewOrientation3D will 
//				be returned. 
//
//------------------------------------------------------------------------------
+ (ViewOrientationT) viewOrientationForAngle:(Tuple3)rotationAngle
{
	ViewOrientationT    viewOrientation     = ViewOrientation3D;
	NSUInteger          counter             = 0;
	Tuple3              testAngle           = ZeroPoint3;
	ViewOrientationT    testOrientation     = ViewOrientation3D;
	
	ViewOrientationT    orientations[]      = {	ViewOrientationFront,
												ViewOrientationBack,
												ViewOrientationLeft,
												ViewOrientationRight,
												ViewOrientationTop,
												ViewOrientationBottom
											  };
	NSUInteger          orientationCount    = sizeof(orientations)/sizeof(ViewOrientationT);
	
	// See if the angle matches any of the head-on orientations.
	for(counter = 0; viewOrientation == ViewOrientation3D && counter < orientationCount; counter++)
	{
		testOrientation	= orientations[counter];
		testAngle		= [LDrawUtilities angleForViewOrientation:testOrientation];
		
		if( V3PointsWithinTolerance(rotationAngle, testAngle) == YES )
			viewOrientation = testOrientation;
	}
	
	return viewOrientation;
	
}//end viewOrientationForAngle:


@end

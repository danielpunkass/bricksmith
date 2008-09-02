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
#import "MacLDraw.h"
#import "PartLibrary.h"

@implementation LDrawUtilities

#pragma mark -
#pragma mark UTILITIES
#pragma mark -
//This is stuff that didn't really go anywhere else.

//========== boundingBox3 ======================================================
//
// Purpose:		Returns the minimum and maximum points of the box which 
//				perfectly contains all the given objects. (Only objects which 
//				respond to -boundingBox3 will be tested.)
//
// Notes:		This method used to live in LDrawContainer, which was a very 
//				nice place. But I moved it here so that other interested parties 
//				could do bounds testing on ad-hoc collections of directives.
//
//==============================================================================
+ (Box3) boundingBox3ForDirectives:(NSArray *)directives {
	Box3	bounds				= InvalidBox;
	Box3	partBounds			= {0};
	id		currentDirective	= nil;
	int		numberOfDirectives	= [directives count];
	int		counter				= 0;
	
	for(counter = 0; counter < numberOfDirectives; counter++){
		currentDirective = [directives objectAtIndex:counter];
		if([currentDirective respondsToSelector:@selector(boundingBox3)]) {
			partBounds = [currentDirective boundingBox3];
			
			bounds.min.x = MIN(bounds.min.x, partBounds.min.x);
			bounds.min.y = MIN(bounds.min.y, partBounds.min.y);
			bounds.min.z = MIN(bounds.min.z, partBounds.min.z);
			
			bounds.max.x = MAX(bounds.max.x, partBounds.max.x);
			bounds.max.y = MAX(bounds.max.y, partBounds.max.y);
			bounds.max.z = MAX(bounds.max.z, partBounds.max.z);
		}
	}
	
	return bounds;
}//end boundingBox3ForDirectives


//========== classForLineType ==================================================
//
// Purpose:		Allows initializing the right kind of class based on the code 
//				found at the beginning of an LDraw line.
//
//==============================================================================
+ (Class) classForLineType:(int)lineType
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
			NSLog(@"unrecognized LDraw line type: %d", lineType);
	}
	
	return classForType;
}

//========== readNextField: ====================================================
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
//==============================================================================
+ (NSString *) readNextField:(NSString *) partialDirective
				   remainder:(NSString **) remainder
{
	NSCharacterSet	*whitespaceCharacterSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
	NSRange			 rangeOfNextWhiteSpace;
	NSString		*fieldContents			= nil;
	
	//First, remove any heading whitespace.
	partialDirective = [partialDirective stringByTrimmingCharactersInSet:whitespaceCharacterSet];
	//Find the beginning of the next field separation
	rangeOfNextWhiteSpace = [partialDirective rangeOfCharacterFromSet:whitespaceCharacterSet];
	
	//The text between the beginning and the next field separator is the first 
	// field (what we are after).
	if(rangeOfNextWhiteSpace.location != NSNotFound){
		fieldContents = [partialDirective substringToIndex:rangeOfNextWhiteSpace.location];
		//See if they want the rest of the line, sans the field we just parsed.
		if(remainder != NULL)
			*remainder = [partialDirective substringFromIndex:rangeOfNextWhiteSpace.location];
	}
	else{
		//There was no subsequent field separator; we must be at the end of the line.
		fieldContents = partialDirective;
		if(remainder != NULL)
			*remainder = [NSString string];
	}
	
	return fieldContents;
}//end readNextField


//========== updateNameForMovedPart: ===========================================
//
// Purpose:		If the specified part has been moved to a new number/name by 
//				LDraw.org, this method will update the part name to point to the 
//				new location.
//
//				Example:
//					193.dat (~Moved to 193a) becomes 193a.dat
//
//==============================================================================
+ (void) updateNameForMovedPart:(LDrawPart *)movedPart
{
	NSString	*description	= [[LDrawApplication sharedPartLibrary] descriptionForPart:movedPart];
	NSScanner	*nameScanner	= [NSScanner scannerWithString:description];
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

@end

//==============================================================================
//
// File:		PartReport.m
//
// Purpose:		Holds the data necessary to generate a report of the parts in a 
//				model. We are interested in the quantities and colors of each 
//				type of part included.
//
//				A newly-allocated copy of this object should be passed into a 
//				model. The model will then register all its parts in the report.
//				The information in the report can then be analyzed.
//
//  Created by Allen Smith on 9/10/05.
//  Copyright 2005. All rights reserved.
//==============================================================================
#import "PartReport.h"

#import "LDrawApplication.h"
#import "LDrawPart.h"
#import "MacLDraw.h"
#import "PartLibrary.h"

@implementation PartReport

#pragma mark -
#pragma mark INITIALIZATION
#pragma mark -

//========== partReport ========================================================
//
// Purpose:		Returns an empty part report object, ready to be passed to a 
//				model to be filled up with information.
//
//==============================================================================
+ (PartReport *) partReport {
	return [[PartReport new] autorelease];
}

//========== init ==============================================================
//
// Purpose:		Creates a new part report object, ready to be passed to a model 
//				to be filled up with information.
//
//==============================================================================
- (id) init {
	self = [super init];
	
	partsReport = [NSMutableDictionary new];
	
	return self;
}


#pragma mark -
#pragma mark COLLECTING INFORMATION
#pragma mark -

//========== registerPart ======================================================
//
// Purpose:		We are being told to the add the specified part into our report.
//				
//				Our partReport dictionary is arranged as follows:
//				
//				Keys: Part Numbers <NSString>
//				Values: NSMutableDictionaries.
//					|
//					|-> Keys: LDrawColorT <NSNumber>
//						Values: NSNumbers indicating the quantity of parts
//							of this type and color
//
//==============================================================================
- (void) registerPart:(LDrawPart *)part {
	NSString			*partName		= [part referenceName];
	NSNumber			*partColor		= [NSNumber numberWithInt:[part LDrawColor]];
	
	NSMutableDictionary	*partRecord		= [self->partsReport objectForKey:partName];
	unsigned			 numberParts	= 0;

	
	if(partRecord == nil){
		//We haven't encountered one of these parts yet. Start counting!
		partRecord = [NSMutableDictionary dictionary];
		[self->partsReport setObject:partRecord forKey:partName];
	}
	
	//Now let's see how many parts wit this color we have so far. If we don't have 
	// any, this call will conveniently return 0.
	numberParts = [[partRecord objectForKey:partColor] intValue];
	
	//Update our tallies.
	self->totalNumberOfParts += 1;
	numberParts += 1;
	
	[partRecord setObject:[NSNumber numberWithUnsignedInt:numberParts]
				   forKey:partColor];
				   
}//end registerPart:


#pragma mark -
#pragma mark ACCESSING INFORMATION
#pragma mark -

//========== flattenedReport ===================================================
//
// Purpose:		Returns an array a part records ideally suited for displaying in 
//				a table view.
//
//				Each entry in the array is a dictionary containing the keys:
//				PART_NUMBER_KEY, LDRAW_COLOR_CODE, PART_QUANTITY
//
//==============================================================================
- (NSArray *) flattenedReport {
	
	NSMutableArray	*flattenedReport	= [NSMutableArray array];
	NSArray			*allPartNames		= [partsReport allKeys];
	NSDictionary	*quantitiesForPart	= nil;
	NSArray			*allColors			= nil;
	
	PartLibrary		*partLibrary		= [LDrawApplication sharedPartLibrary];
	
	NSDictionary	*currentPartRecord	= nil;
	NSString		*currentPartNumber	= nil;
	NSNumber		*currentPartColor	= nil;
	NSNumber		*currentPartQuantity= nil;
	NSString		*currentPartName	= nil; //for convenience.
	NSString		*currentColorName	= nil;
	
	int				 counter			= 0;
	int				 colorCounter		= 0;
	
	//Loop through every type of part in the report
	for(counter = 0; counter < [allPartNames count]; counter++){
		currentPartNumber	= [allPartNames objectAtIndex:counter];
		quantitiesForPart	= [partsReport objectForKey:currentPartNumber];
		allColors			= [quantitiesForPart allKeys];
		
		//For each type of part, find each color/quantity pair recorded for it.
		for(colorCounter = 0; colorCounter < [allColors count]; colorCounter++){
			currentPartColor	= [allColors objectAtIndex:colorCounter];
			currentPartQuantity	= [quantitiesForPart objectForKey:currentPartColor];
			
			currentPartName		= [partLibrary descriptionForPartName:currentPartNumber];
			currentColorName	= [LDrawColor nameForLDrawColor:[currentPartColor intValue]];
			
			//Now we have all the information we need. Flatten it into a single
			// record.
			currentPartRecord = [NSDictionary dictionaryWithObjectsAndKeys:
				currentPartNumber,		PART_NUMBER_KEY,
				currentPartName,		PART_NAME_KEY,
				currentPartColor,		LDRAW_COLOR_CODE,
				currentColorName,		COLOR_NAME,
				currentPartQuantity,	PART_QUANTITY,
				nil ];
			[flattenedReport addObject:currentPartRecord];
		}//end loop for color/quantity pairs within each part
	}//end part loop
	
	return flattenedReport;

}//end flattenedReport


//========== numberOfParts =====================================================
//
// Purpose:		Returns the total number of parts registered in this report.
//
//==============================================================================
- (unsigned) numberOfParts {
	return self->totalNumberOfParts;
}


#pragma mark -
#pragma mark DESTRUCTOR
#pragma mark -

//========== dealloc ===========================================================
//
// Purpose:		Quoth the Raven: "Nevermore!"
//
//==============================================================================
- (void) dealloc {
	[partsReport	release];
	
	[super dealloc];
}

@end

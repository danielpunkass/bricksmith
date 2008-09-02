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

#import "LDrawContainer.h"
#import "LDrawApplication.h"
#import "LDrawPart.h"
#import "MacLDraw.h"
#import "PartLibrary.h"

@implementation PartReport

#pragma mark -
#pragma mark INITIALIZATION
#pragma mark -

//---------- partReportForContainer: ---------------------------------[static]--
//
// Purpose:		Returns an empty part report object, ready to be passed to a 
//				model to be filled up with information.
//
//------------------------------------------------------------------------------
+ (PartReport *) partReportForContainer:(LDrawContainer *)container
{
	PartReport *partReport = [PartReport new];
	
	[partReport setLDrawContainer:container];
	
	return [partReport autorelease];
}//end partReportForContainer


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

//========== setLDrawContainer: ================================================
//
// Purpose:		Sets the object on which we will collect report data.
//
//==============================================================================
- (void) setLDrawContainer:(LDrawContainer *)newContainer
{
	[newContainer			retain];
	[self->reportedObject	release];
	
	self->reportedObject = newContainer;
	
}//end setLDrawContainer:


//========== getPieceCountReport ===============================================
//
// Purpose:		Produces a report detailing the number of pieces in the current
//				Container, as well as the attributes of those parts.
//
//==============================================================================
- (void) getPieceCountReport
{
	//unfortunately, the reporting responsibility falls on the container itself. 
	// The reason is that the parts we are reporting might wind up being MPD 
	// references, in which case we need to merge the report for the referenced 
	// submodel into *this* report.
	[reportedObject collectPartReport:self];
	
}//end getPieceCountReport


//========== getMissingPiecesReport ============================================
//
// Purpose:		Collects information about all the parts in the model which 
//				can't be found or have been moved.
//
//==============================================================================
- (void) getMissingPiecesReport
{
	PartLibrary		*partLibrary		= [LDrawApplication sharedPartLibrary];
	NSArray			*elements			= [self->reportedObject allEnclosedElements];
	id				 currentElement		= nil;
	LDrawModel		*partModel			= nil;
	NSString		*category			= nil;
	unsigned		 elementCount		= [elements count];
	unsigned		 counter			= 0;
	
	//clear out any previous reports.
	if(self->missingParts != nil)
		[missingParts release];
	if(self->movedParts != nil)
		[movedParts release];
		
	missingParts	= [[NSMutableArray alloc] init];
	movedParts		= [[NSMutableArray alloc] init];
	
	for(counter = 0; counter < elementCount; counter++)
	{
		currentElement = [elements objectAtIndex:counter];
		
		if( [currentElement isKindOfClass:[LDrawPart class]] )
		{
			//Missing?
			partModel = [partLibrary modelForPart:currentElement];
			if(partModel == nil)
				[missingParts addObject:currentElement];
			
			//Moved?
			category = [partLibrary categoryForPart:currentElement];
			if([category isEqualToString:LDRAW_MOVED_CATEGORY]) 
			   [movedParts addObject:currentElement];
		}
	}
}//end getMissingPiecesReport

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
- (void) registerPart:(LDrawPart *)part
{
	NSString			*partName			= [part referenceName];
	NSNumber			*partColor			= [NSNumber numberWithInt:[part LDrawColor]];
	
	NSMutableDictionary	*partRecord			= [self->partsReport objectForKey:partName];
	unsigned			 numberColoredParts	= 0;

	
	if(partRecord == nil){
		//We haven't encountered one of these parts yet. Start counting!
		partRecord = [NSMutableDictionary dictionary];
		[self->partsReport setObject:partRecord forKey:partName];
	}
	
	//Now let's see how many parts with this color we have so far. If we don't have 
	// any, this call will conveniently return 0.
	numberColoredParts = [[partRecord objectForKey:partColor] intValue];
	
	//Update our tallies.
	self->totalNumberOfParts += 1;
	numberColoredParts += 1;
	
	[partRecord setObject:[NSNumber numberWithUnsignedInt:numberColoredParts]
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


//========== missingParts ======================================================
//
// Purpose:		Returns an array of the LDrawParts in this file which are 
//				~Moved aliases to new files.
//
//==============================================================================
- (NSArray *) missingParts
{
	//haven't gotten the report yet; get it.
	if(self->missingParts == nil)
		[self getMissingPiecesReport];
	
	return self->missingParts;
}//end missingParts


//========== movedParts ========================================================
//
// Purpose:		Returns an array of the LDrawParts in this file which are 
//				~Moved aliases to new files.
//
//==============================================================================
- (NSArray *) movedParts
{
	//haven't gotten the report yet; get it.
	if(self->movedParts == nil)
		[self getMissingPiecesReport];
		
	return self->movedParts;
}//end movedParts


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
- (void) dealloc
{
	[reportedObject	release];
	[partsReport	release];
	
	[super dealloc];
}

@end

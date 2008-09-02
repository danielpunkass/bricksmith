//==============================================================================
//
// File:		PartReport.h
//
// Purpose:		Holds the data necessary to generate a report of the parts in a 
//				model. We are interested in the quantities and colors of each 
//				type of part included.
//
//  Created by Allen Smith on 9/10/05.
//  Copyright 2005. All rights reserved.
//==============================================================================
#import <Cocoa/Cocoa.h>

@class LDrawPart;

@interface PartReport : NSObject {
	NSMutableDictionary	*partsReport;			//see -registerPart: for a description of this data
	unsigned			 totalNumberOfParts;	//how many parts are in the model.
}

//Initialization
+ (PartReport *) partReport;

//Collecting Information
- (void) registerPart:(LDrawPart *)part;

//Accessing Information
- (NSArray *) flattenedReport;
- (unsigned) numberOfParts;

@end

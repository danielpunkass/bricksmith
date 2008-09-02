//==============================================================================
//
// File:		DimensionsPanel.m
//
// Purpose:		Dialog to display the dimensions for a model.
//
//  Created by Allen Smith on 8/21/05.
//  Copyright 2005. All rights reserved.
//==============================================================================
#import "DimensionsPanel.h"

#import "LDrawFile.h"
#import "LDrawMPDModel.h"
#import <math.h>

@implementation DimensionsPanel

#define STUDS_ROW_INDEX			0
#define INCHES_ROW_INDEX		1
#define CENTIMETERS_ROW_INDEX	2
#define LEGONIAN_FEET_ROW_INDEX	3

#define NUMBER_OF_UNITS			4

#define UNITS_COLUMN		@"UnitsIdentifier"
#define WIDTH_COLUMN		@"WidthIdentifier"
#define LENGTH_COLUMN		@"LengthIdentifier"
#define HEIGHT_COLUMN		@"HeightIdentifier"

#pragma mark -
#pragma mark INITIALIZATION
#pragma mark -


//========== dimensionPanelForFile: ============================================
//
// Purpose:		Creates a panel which displays the dimensions for the specified 
//				file. 
//
//==============================================================================
+ (DimensionsPanel *) dimensionPanelForFile:(LDrawFile *)fileIn
{
	DimensionsPanel *dimensions = nil;
	
	dimensions = [[DimensionsPanel alloc] initWithFile:fileIn];
	
	return [dimensions autorelease];
}


//========== initWithFile: =====================================================
//
// Purpose:		Make us an object. Load us our window.
//
// Notes:		Memory management is a bit tricky here. The receiver here is a 
//				throwaway object that exists soley to load a Nib file. We then 
//				junk the receiver and return a reference to the panel it loaded 
//				in the Nib. Tricky, huh?
//
//==============================================================================
- (id) initWithFile:(LDrawFile *)fileIn {

	self = [super init];
	
	[self setFile:fileIn];
	
	return self;
}


#pragma mark -
#pragma mark ACCESSORS
#pragma mark -

//========== activeModelName ===================================================
//
// Purpose:		Returns the name of the submodel in the file whose dimensions we 
//				are currently analyzing.
//
//==============================================================================
- (NSString *) activeModelName {
	return self->activeModelName;
}


//========== container =========================================================
//
// Purpose:		Returns the container whose dimensions we are analyzing.
//
//==============================================================================
- (LDrawFile *) file {
	return self->file;
}

//========== setActiveModelName: ===============================================
//
// Purpose:		Sets the name of the submodel in the file whose dimensions we 
//				are currently analyzing and updates the data view.
//
//==============================================================================
- (void) setActiveModelName:(NSString *)newName {
	[newName retain];
	[self->activeModelName release];
	activeModelName = newName;
	
	[dimensionsTable reloadData];
}


//========== panelNibName ======================================================
//
// Purpose:		For the benefit of our superclass, we need to identify the name 
//				of the Nib where my dialog comes from.
//
//==============================================================================
- (NSString *) panelNibName {
	return @"Dimensions";
}


//========== setContainer: =====================================================
//
// Purpose:		Returns the container whose dimensions we are analyzing.
//
//==============================================================================
- (void) setFile:(LDrawFile *)newFile {
	[newFile retain];
	[self->file release];
	
	file = newFile;
	[self setActiveModelName:[[newFile activeModel] modelName]];
}

#pragma mark -
#pragma mark TABLE VIEW
#pragma mark -

//**** NSTableDataSource ****
//========== numberOfRowsInTableView: ==========================================
//
// Purpose:		End the sheet (we are the sheet!)
//
//==============================================================================
- (int) numberOfRowsInTableView:(NSTableView *)aTableView {
	return NUMBER_OF_UNITS;
}


//**** NSTableDataSource ****
//========== tableView:objectValueForTableColumn:row: ==========================
//
// Purpose:		Return the appropriate dimensions.
//
//				This is downright ugly. Studs are different depending on whether 
//				they are horizontal or vertical. Oh yeah, and we want to display 
//				integers, floats, and strings in one table.
//
//==============================================================================
- (id)				tableView:(NSTableView *)tableView
	objectValueForTableColumn:(NSTableColumn *)tableColumn
						  row:(int)rowIndex
{
	id		object	= nil;
	Box3	bounds	= [[self->file modelWithName:self->activeModelName] boundingBox3];
	float	width	= 0;
	float	height	= 0;
	float	length	= 0;
	
	 // 1 stud = 3/8" = 20 LDraw units.
	float	studsPerLDU				= 1 / 20.0; //HORIZONTAL studs!
	float	inchesPerStud			= 5 / 16.0; //HORIZONTAL studs!
	float	inchesPerVerticalStud	= 3 / 8.0  +  1 / 16.0; //brick height + stud height.
	float	cmPerInch				= 2.54;
	float	legoInchPerInch			= 128 / 3.0; // Legonian Imperial Feet are a 3:128 scale.
	
	float	value					= 0;
	NSNumberFormatter *floatFormatter = [[NSNumberFormatter new] autorelease];
	
	[floatFormatter setPositiveFormat:@"0.0"];
	
	//If we got valid bounds, analyze them.
	if(V3EqualsBoxes(&bounds, (Box3*)&InvalidBox) == NO) {
		width	= bounds.max.x - bounds.min.x;
		height	= bounds.max.y - bounds.min.y;
		length	= bounds.max.z - bounds.min.z;
	}

	//Units Lable?
	if([[tableColumn identifier] isEqualToString:UNITS_COLUMN]) {
		switch(rowIndex){
			case STUDS_ROW_INDEX:			object = NSLocalizedString(@"Studs", nil);			break;
			case INCHES_ROW_INDEX:			object = NSLocalizedString(@"Inches", nil);			break;
			case CENTIMETERS_ROW_INDEX:		object = NSLocalizedString(@"Centimeters", nil);	break;
			case LEGONIAN_FEET_ROW_INDEX:	object = NSLocalizedString(@"LegonianFeet", nil);	break;
		}
	}
	//Dimension value, then.
	else {
		if([[tableColumn identifier] isEqualToString:WIDTH_COLUMN])
			value = width;
		else if([[tableColumn identifier] isEqualToString:LENGTH_COLUMN])
			value = length;
		else if([[tableColumn identifier] isEqualToString:HEIGHT_COLUMN])
			value = height;
			
		//Now we have the value in LDraw Units.
		// Convert to display units.
		switch(rowIndex){
			//oh dear. Studs are difficult.
			case STUDS_ROW_INDEX:
				if([[tableColumn identifier] isEqualToString:HEIGHT_COLUMN])
					value *= (studsPerLDU * inchesPerStud) / inchesPerVerticalStud; //get vertical studs.
				else
					value *= studsPerLDU; //get horizontal studs
				break;
				
			case INCHES_ROW_INDEX:			value *= studsPerLDU * inchesPerStud;					break;
			case CENTIMETERS_ROW_INDEX:		value *= studsPerLDU * inchesPerStud * cmPerInch;		break;
			case LEGONIAN_FEET_ROW_INDEX:	value *= studsPerLDU * inchesPerStud * legoInchPerInch;	break;
		}
		
		//Now, how are we going to display it?
		switch(rowIndex){
			case STUDS_ROW_INDEX:
				object = [NSNumber numberWithInt:ceil(value)];
				break;
			case INCHES_ROW_INDEX:
				object = [NSNumber numberWithFloat:value];
				object = [floatFormatter stringForObjectValue:object];
				break;
			case CENTIMETERS_ROW_INDEX:
				object = [NSNumber numberWithFloat:value];
				object = [floatFormatter stringForObjectValue:object];
				break;
			//This one's a doozy--format in feet and inches.
			case LEGONIAN_FEET_ROW_INDEX:
				object = [NSString stringWithFormat:	NSLocalizedString(@"FeetAndInchesFormat", nil),
														(int) floor(value / 12),	//feet
														(int) fmod(value, 12)		//inches
						];
				break;
		}
		
	}
		
	return object;
	
}//end tableView:objectValueForTableColumn:row:


#pragma mark -
#pragma mark DESTRUCTOR
#pragma mark -

//========== dealloc ===========================================================
//
// Purpose:		The end is nigh.
//
//==============================================================================
- (void) dealloc {
	
	[file				release];
	[activeModelName	release];
	
	[super dealloc];
}

@end

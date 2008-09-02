//==============================================================================
//
// File:		PieceCountPanel.m
//
// Purpose:		Dialog to display the dimensions for a model.
//
//  Created by Allen Smith on 8/21/05.
//  Copyright 2005. All rights reserved.
//==============================================================================
#import "PieceCountPanel.h"

#import "LDrawApplication.h"
#import "LDrawColor.h"
#import "LDrawColorCell.h"
#import "LDrawFile.h"
#import "LDrawGLView.h"
#import "LDrawMPDModel.h"
#import "MacLDraw.h"
#import "PartLibrary.h"
#import "PartReport.h"

@implementation PieceCountPanel

//========== awakeFromNib ======================================================
//
// Purpose:		Readies things that need to be readied. 
//
//==============================================================================
- (void) awakeFromNib {
	LDrawColorCell *colorCell = [[LDrawColorCell alloc] init];
	NSTableColumn *colorColumn = [pieceCountTable tableColumnWithIdentifier:LDRAW_COLOR_CODE];
	[colorColumn setDataCell:colorCell];
	
	[partPreview setAcceptsFirstResponder:NO];
	
	//Remember, this method is called twice for an LDrawColorPanel; the first time 
	// is for the File's Owner, which is promptly overwritten.
}


#pragma mark -
#pragma mark INITIALIZATION
#pragma mark -


//========== pieceCountPanelForFile: ===========================================
//
// Purpose:		Creates a panel which displays the dimensions for the specified 
//				file. 
//
//==============================================================================
+ (PieceCountPanel *) pieceCountPanelForFile:(LDrawFile *)fileIn
{
	PieceCountPanel *panel = nil;
	
	panel = [[PieceCountPanel alloc] initWithFile:fileIn];
	
	return [panel autorelease];
}


//========== initWithFile: =====================================================
//
// Purpose:		Make us an object. The superclass loads us our window.
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


//========== panelNibName ======================================================
//
// Purpose:		Returns the name of the Nib which contains the desired panel.
//				Called by our superclass.
//
//==============================================================================
- (NSString *) panelNibName {
	return @"PieceCountPanel";
}


//========== partReport: =======================================================
//
// Purpose:		Sets the name of the submodel in the file whose dimensions we 
//				are currently analyzing and updates the data view.
//
//==============================================================================
- (PartReport *) partReport {
	return self->partReport;
}


//========== setActiveModelName: ===============================================
//
// Purpose:		Sets the name of the submodel in the file whose dimensions we 
//				are currently analyzing and updates the data view.
//
//==============================================================================
- (void) setActiveModelName:(NSString *)newName {
	LDrawMPDModel	*activeModel	= nil;
	PartReport		*modelReport	= [PartReport partReport];
	
	//Update the model name.
	[newName retain];
	[self->activeModelName release];
	activeModelName = newName;
	
	//Get the report for the new model.
	activeModel = [self->file modelWithName:newName];
	[activeModel collectPartReport:modelReport];
	[self setPartReport:modelReport];
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


//========== setPartReport: ====================================================
//
// Purpose:		Sets the part report (containing all piece/color/quantity info)
//				that we are displaying.
//
// Notes:		You should never call this method directly.
//
//==============================================================================
- (void) setPartReport:(PartReport *)newPartReport {
	
	NSMutableArray *flattened = nil;
	
	//Update the part report
	[newPartReport retain];
	[self->partReport release];
	partReport = newPartReport;
	
	//Prepare some new data for the table view:
	flattened = [NSMutableArray arrayWithArray:[partReport flattenedReport]];
	[self setTableDataSource:flattened];
	
	[pieceCountTable reloadData];
}


//========== setTableDataSource: ===============================================
//
// Purpose:		The table displays a list of the parts in a category. The array
//				here is an array of part records containg names and 
//				descriptions.
//
//				The new parts are then displayed in the table.
//
//==============================================================================
- (void) setTableDataSource:(NSMutableArray *) newReport{
	
	//Sort the parts based on whatever the current sort order is for the table.
	[newReport sortUsingDescriptors:[pieceCountTable sortDescriptors]];
	
	//Swap out the variable
	[newReport retain];
	[flattenedReport release];
	
	flattenedReport = newReport;
	
	//Update the table
	[pieceCountTable reloadData];
	[self syncSelectionAndPartDisplayed];
	
}//end setTableDataSource


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
	return [flattenedReport count];
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
	NSString		*identifier	= [tableColumn identifier];
	NSDictionary	*partRecord	= [flattenedReport objectAtIndex:rowIndex];
	id				 object		= nil;
	
	object = [partRecord objectForKey:identifier];
	
//	if(		[identifier isEqualToString:PART_NUMBER_KEY]
//		||	[identifier isEqualToString:PART_QUANTITY]
//		||	[identifier isEqualToString:LDRAW_COLOR_CODE] )
//	{
//		object = [partRecord objectForKey:identifier];
//	}
//	
//	else if([identifier isEqualToString:PART_NAME_KEY])
//		object = [[LDrawApplication sharedPartLibrary] descriptionForPartName:[partRecord objectForKey:PART_NUMBER_KEY]];
//	
//	else if([identifier isEqualToString:COLOR_NAME])
//		object = [LDrawColor nameForLDrawColor:[[partRecord objectForKey:LDRAW_COLOR_CODE] intValue]];
	
	return object;
	
}//end tableView:objectValueForTableColumn:row:


//**** NSTableDataSource ****
//========== tableView:sortDescriptorsDidChange: ===============================
//
// Purpose:		Resort the table elements.
//
//==============================================================================
- (void)tableView:(NSTableView *)tableView sortDescriptorsDidChange:(NSArray *)oldDescriptors
{
	NSArray *newDescriptors = [tableView sortDescriptors];
	
	[flattenedReport sortUsingDescriptors:newDescriptors];
	[tableView reloadData];
}


//**** NSTableDataSource ****
//========== tableViewSelectionDidChange: ======================================
//
// Purpose:		A new selection! Update the part preview accordingly.
//
//==============================================================================
- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	[self syncSelectionAndPartDisplayed];
}


#pragma mark -
#pragma mark UTILITIES
#pragma mark -

//========== syncSelectionAndPartDisplayed =====================================
//
// Purpose:		Makes the current part displayed match the part selected in the 
//				table.
//
//==============================================================================
- (void) syncSelectionAndPartDisplayed
{
	NSDictionary	*partRecord			= nil;
	NSString		*partName			= nil;
	LDrawColorT		 partColor			= LDrawColorBogus;
	PartLibrary		*partLibrary		= [LDrawApplication sharedPartLibrary];
	id				 modelToView		= nil;
	int				 rowIndex			= [pieceCountTable selectedRow];
	
	if(rowIndex >= 0) {
		partRecord	= [flattenedReport objectAtIndex:rowIndex];
		partName	= [partRecord objectForKey:PART_NUMBER_KEY];
		partColor	= [[partRecord objectForKey:LDRAW_COLOR_CODE] intValue];
		
		modelToView = [partLibrary modelForName:partName];
		[partPreview setLDrawDirective:modelToView];
		[partPreview setLDrawColor:partColor];
	}
	
}//end syncSelectionAndPartDisplayed


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
	[partReport			release];
	[flattenedReport	release];
	
	[super dealloc];
}

@end

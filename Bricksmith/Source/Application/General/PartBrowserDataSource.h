//==============================================================================
//
// File:		PartBrowserDataSource.h
//
// Purpose:		Provides a standarized data source for part browser interface.
//
//  Created by Allen Smith on 2/17/05.
//  Copyright 2005. All rights reserved.
//==============================================================================
#import <Cocoa/Cocoa.h>

#import "LDrawGLView.h"

@class PartLibrary;

////////////////////////////////////////////////////////////////////////////////
//
// class PartBrowserDataSource
//
////////////////////////////////////////////////////////////////////////////////
@interface PartBrowserDataSource : NSObject
{
	IBOutlet NSComboBox		*categoryComboBox;
	IBOutlet NSSearchField	*searchField;
	IBOutlet NSTableView	*partsTable;
	IBOutlet LDrawGLView	*partPreview;

	PartLibrary     *partLibrary; //weak reference to the shared part catalog.
	NSArray         *categoryList;
	NSMutableArray  *tableDataSource;

}

//Accessors
- (NSString *) selectedPartName;
- (void) setPartLibrary:(PartLibrary *)partLibraryIn;
- (BOOL) setCategory:(NSString *)newCategory;
- (void) setCategoryList:(NSArray *)categoryList;
- (void) setTableDataSource:(NSMutableArray *) partsInCategory;

//Actions
- (IBAction) addPartClicked:(id)sender;
- (IBAction) categoryComboBoxChanged:(id)sender;
- (void) doubleClickedInPartTable:(id)sender;
- (IBAction) searchFieldChanged:(id)sender;

//Notifications
- (void) sharedPartCatalogDidChange:(NSNotification *)notification;

//Utilities
- (NSMutableArray *) filterPartRecords:(NSArray *)partRecords bySearchString:(NSString *)searchString;
- (void) syncSelectionAndPartDisplayed;
- (BOOL) writeSelectedPartToPasteboard:(NSPasteboard *)pasteboard;

@end

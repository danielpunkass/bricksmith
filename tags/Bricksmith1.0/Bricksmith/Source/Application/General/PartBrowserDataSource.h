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

@interface PartBrowserDataSource : NSObject {
	
	IBOutlet NSComboBox		*categoryComboBox;
	IBOutlet NSTableView	*partsTable;
	IBOutlet LDrawGLView	*partPreview;

	NSDictionary	*partCatalog; //weak reference to the shared part catalog.
	NSArray			*categoryList;
	NSMutableArray	*tableDataSource;

}

//Accessors
- (NSString *) selectedPart;
- (void) setPartCatalog:(NSDictionary *)newCatalog;
- (BOOL) setCategory:(NSString *)newCategory;
- (void) setCategoryList:(NSArray *)categoryList;
- (void) setTableDataSource:(NSMutableArray *) partsInCategory;

//Actions
- (IBAction) categoryComboBoxChanged:(id)sender;

//Notifications
- (void) sharedPartCatalogDidChange:(NSNotification *)notification;

//Utilities
- (void) syncSelectionAndPartDisplayed;

@end

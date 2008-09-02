//==============================================================================
//
// File:		PieceCountPanel.h
//
// Purpose:		Dialog to display the dimensions for a model.
//
//  Created by Allen Smith on 8/21/05.
//  Copyright 2005. All rights reserved.
//==============================================================================
#import <Cocoa/Cocoa.h>

#import "DialogPanel.h"

@class LDrawFile;
@class LDrawGLView;
@class PartReport;

@interface PieceCountPanel : DialogPanel{
	LDrawFile		*file;
	NSString		*activeModelName;
	PartReport		*partReport;
	NSMutableArray	*flattenedReport;
	
	IBOutlet NSTableView		*pieceCountTable;
	IBOutlet LDrawGLView		*partPreview;
}

//Initialization
+ (PieceCountPanel *) pieceCountPanelForFile:(LDrawFile *)fileIn;
- (id) initWithFile:(LDrawFile *)file;

//Accessors
- (NSString *) activeModelName;
- (LDrawFile *) file;
- (PartReport *) partReport;
- (void) setActiveModelName:(NSString *)newName;
- (void) setFile:(LDrawFile *)newFile;
- (void) setPartReport:(PartReport *)newPartReport;
- (void) setTableDataSource:(NSMutableArray *) newReport;

//Utilities
- (void) syncSelectionAndPartDisplayed;

@end

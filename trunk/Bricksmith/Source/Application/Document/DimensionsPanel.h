//==============================================================================
//
// File:		DimensionsPanel.h
//
// Purpose:		Dialog to display the dimensions for a model.
//
//  Created by Allen Smith on 8/21/05.
//  Copyright 2005. All rights reserved.
//==============================================================================
#import <Cocoa/Cocoa.h>

@class LDrawFile;

@interface DimensionsPanel : NSPanel{
	LDrawFile	*file;
	NSString	*activeModelName;
	
	IBOutlet DimensionsPanel	*dimensionsPanel;
	IBOutlet NSObjectController	*objectController;
	IBOutlet NSTableView		*dimensionsTable;
}

//Initialization
+ (DimensionsPanel *) dimensionPanelForFile:(LDrawFile *)fileIn;
- (id) initWithFile:(LDrawFile *)file;

//Accessors
- (NSString *) activeModelName;
- (LDrawFile *) file;
- (void) setActiveModelName:(NSString *)newName;
- (void) setFile:(LDrawFile *)newFile;

//Actions
- (IBAction) okButtonClicked:(id)sender;

@end

//==============================================================================
//
// File:		LDrawColorPanel.h
//
// Purpose:		Color-picker for Bricksmith.
//
//  Created by Allen Smith on 2/26/05.
//  Copyright 2005. All rights reserved.
//==============================================================================
#import <Cocoa/Cocoa.h>

#import "LDrawColor.h"

@class LDrawColorBar;


@interface LDrawColorPanel : NSPanel <LDrawColorable> {
	IBOutlet	LDrawColorPanel		*colorPanel;
	IBOutlet	LDrawColorBar		*colorBar;
	IBOutlet	NSTableView			*colorTable;
	IBOutlet	NSSearchField		*searchField;
	
				NSArray				*colorList;
				NSMutableArray		*viewingColors;
				
				//YES if we are in the middle of updating the color panel to 
				// reflect the current selection, NO any other time.
				BOOL				 updatingToReflectFile;
}

//Initialization
+ (LDrawColorPanel *) sharedColorPanel;

//Accessors
- (void) setViewingColors:(NSArray *)newList;
- (LDrawColorT) LDrawColor;
- (void) setLDrawColor:(LDrawColorT)newColor;

//Actions
- (IBAction) searchFieldChanged:(id)sender;
- (void) updateSelectionWithObjects:(NSArray *)selectedObjects;

//Utilities
- (NSArray *) colorsMatchingString:(NSString *)searchString;
- (int) indexOfColorCode:(LDrawColorT)colorCodeSought;


@end

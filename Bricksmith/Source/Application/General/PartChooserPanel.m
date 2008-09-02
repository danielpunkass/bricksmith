//==============================================================================
//
// File:		PartChooserPanel.m
//
// Purpose:		Presents a PartBrower in a dialog. It has a larger preview, so 
//				it isn't as cramped as the Parts drawer.
//
//  Created by Allen Smith on 4/3/05.
//  Copyright 2005. All rights reserved.
//==============================================================================
#import "PartChooserPanel.h"

#import "PartBrowserDataSource.h"

@implementation PartChooserPanel

#pragma mark -
#pragma mark INITIALIZATION
#pragma mark -

//========== partChooserPanel ==================================================
//
// Purpose:		Returns a brand new part chooser ready to run.
//
//==============================================================================
+ (PartChooserPanel *) partChooserPanel {
	return [[[PartChooserPanel alloc] init] autorelease];
}


//========== init ==============================================================
//
// Purpose:		Brings the LDraw part chooser panel to life.
//
//==============================================================================
- (id) init {
	
	[NSBundle loadNibNamed:@"PartChooser" owner:self];
	
	oldSelf = self;
	self = partChooserPanel; //this don't look good, but it works.
						//this takes the place of calling [super init]
						// Note that connections in the Nib file must be made 
						// to the partChooserPanel, not to the File's Owner!
	//[oldSelf autorelease];
			
	return self;
	
}


#pragma mark -
#pragma mark ACCESSORS
#pragma mark -


//========== selectedPart ======================================================
//
// Purpose:		Returns the name of the selected part file.
//				i.e., "3001.dat"
//
//==============================================================================
- (NSString *) selectedPart {
	
	return [partsBrowser selectedPart];;
}


#pragma mark -
#pragma mark ACTIONS
#pragma mark -


//========== runModal ==========================================================
//
// Purpose:		Displays the dialog, returing NSOKButton or NSCancelButton as 
//				appropriate.
//
//==============================================================================
- (int) runModal {
	int returnCode = [NSApp runModalForWindow:self];
	return returnCode;
}



//========== insertPartClicked: ================================================
//
// Purpose:		The dialog has ended and the part should be inserted.
//
//==============================================================================
- (IBAction) insertPartClicked:(id)sender {
	[NSApp stopModalWithCode:NSOKButton];	
}


//========== cancelClicked: ====================================================
//
// Purpose:		The dialog has ended and the part should NOT be inserted.
//
//==============================================================================
- (IBAction) cancelClicked:(id)sender {
	[NSApp stopModalWithCode:NSCancelButton];	
}


#pragma mark -
#pragma mark DESTRUCTOR
#pragma mark -

//========== dealloc ===========================================================
//
// Purpose:		We're checking out of this fleabag hotel.
//
//==============================================================================
- (void) dealloc {
	[oldSelf		release];
	[partsBrowser	release];
	
	[super dealloc];
}


@end

//==============================================================================
//
// File:		ObjectInspectionController.m
//
// Purpose:		Base class for all LDraw inspectors. Each inspector subclass 
//				should load an associated Nib file containing a window with the 
//				inspection controls for that class, and should implement the 
//				methods -finishedEditing: and -revert:.
//
//  Created by Allen Smith on 2/25/05.
//  Copyright 2005. All rights reserved.
//==============================================================================
#import "ObjectInspectionController.h"

#import "MacLDraw.h"

@implementation ObjectInspectionController

//========== init ==============================================================
//
// Purpose:		Subclass implementations should load a Nib file containing their 
//				inspector.
//
//==============================================================================
- (id) init {
	
	[super init];
	
	//Subclasses need to do something like this:
//	if(window == nil){
//		if ([NSBundle loadNibNamed:@"Inspector" owner:self] == NO) {
//			NSLog(@"Can't load Inspector nib file");
//		}
//		
//	}
//	
	return self;
}

#pragma mark -
#pragma mark ACCESSORS
#pragma mark -

//========== object ============================================================
//
// Purpose:		Returns the object this inspector is editing.
//
//==============================================================================
- (id) object{
	return editingObject;
}


//========== setObject =========================================================
//
// Purpose:		Sets up the object to edit. This is called when creating the 
//				class.
//
//==============================================================================
- (void) setObject:(id)newObject{
	
	//De-register any possible notification observer for the previous editing 
	// object. In normal circumstances, there never is a previous object, so 
	// this method is pointless. It is only here as a safeguard.
	[[NSNotificationCenter defaultCenter]
			removeObserver:self
					  name:LDrawDirectiveDidChangeNotification
					object:nil ];
	
	//Retain-release in preparation for changing the instance variable.
	[newObject retain];
	[editingObject release];
	
	//Update the the object being edited.
	editingObject = newObject;
	[self revert:self]; //calling revert should set the values of the palette.
	
	//We want to know when our object changes out from under us.
	[[NSNotificationCenter defaultCenter]
			addObserver:self
			   selector:@selector(directiveDidChange:)
				   name:LDrawDirectiveDidChangeNotification
				 object:newObject ];
}


//========== window ============================================================
//
// Purpose:		Returns the window in the Nib file that contains the inspection 
//				palette. Upon instantiation, this window will be eviscerated of 
//				its inspector palette, which will be transplanted into the 
//				shared inspector panel.
//
//==============================================================================
- (NSWindow *) window{
	return window;
}


#pragma mark -
#pragma mark ACTIONS
#pragma mark -

//========== finishedEditing: ==================================================
//
// Purpose:		Called in response to the conclusion of editing in the palette.
//
//==============================================================================
- (IBAction)finishedEditing:(id)sender{
	
	//Subclasses should implement this method to update their editing objects.

	[[NSNotificationCenter defaultCenter]
			postNotificationName:LDrawDirectiveDidChangeNotification
						  object:[self object]];
}

//========== revert ============================================================
//
// Purpose:		Restores the palette to reflect the state of the object.
//				This method is called automatically when the object to inspect 
//				is set. Subclasses should override this method to populate 
//				the data in their inspector palettes.
//
//==============================================================================
- (IBAction) revert:(id)sender{
	//does nothing, yet.
}


#pragma mark -
#pragma mark NOTIFICATIONS
#pragma mark -

//========== directiveDidChange: ===============================================
//
// Purpose:		Called when the directive we are inspecting is modified by 
//				some external action (like undo/redo).
//
//==============================================================================
- (void) directiveDidChange:(NSNotification *)notification{
	
	//Update our state so we are not stale.
	[self revert:self];
}

#pragma mark -
#pragma mark DESTRUCTOR
#pragma mark -

//========== dealloc ===========================================================
//
// Purpose:		We're booking a one-way cruise on Charon's ferry.
//
//==============================================================================
- (void) dealloc {
	
	//Cancel notification registration
	[[NSNotificationCenter defaultCenter] removeObserver:self ];
	
	//Release top-level nib objects and instance variables.
	[window			release];
	[editingObject	release];
	
	[super dealloc];
}

@end

//==============================================================================
//
// File:		LDrawApplication.h
//
// Purpose:		This is the "application controller." Here we find application-
//				wide instance variables and actions, as well as application 
//				delegate code for startup and shutdown.
//
//  Created by Allen Smith on 2/14/05.
//  Copyright 2005. All rights reserved.
//==============================================================================
/* LDrawApplication */

#import <Cocoa/Cocoa.h>

@class Inspector;
@class PartLibrary;
@class PartLibraryController;


////////////////////////////////////////////////////////////////////////////////
//
// class LDrawApplication
//
////////////////////////////////////////////////////////////////////////////////
@interface LDrawApplication : NSObject
{
	PartLibraryController	*partLibraryController;	// centralized location for part information.
	Inspector				*inspector;				// system for graphically inspecting classes.
	NSOpenGLContext			*sharedGLContext;		// OpenGL variables like display list numbers are shared through this.
}

//Actions
- (IBAction) doPreferences:(id)sender;
- (IBAction) doHelp:(id)sender;
- (IBAction) doKeyboardShortcutHelp:(id)sender;
- (IBAction) doGettingNewPartsHelp:(id)sender;
- (IBAction) showColors:(id)sender;
- (IBAction) showInspector:(id)sender;
- (IBAction) showMouseTools:(id)sender;

//Accessors
+ (Inspector *) sharedInspector;
+ (NSOpenGLContext *) sharedOpenGLContext;
+ (PartLibrary *) sharedPartLibrary;
+ (PartLibraryController *) sharedPartLibraryController;
- (Inspector *) inspector;
- (PartLibraryController *) partLibraryController;
- (NSOpenGLContext *) openGLContext;

//Utilities
- (NSString *) findLDrawPath;
- (void) openHelpAnchor:(NSString *)helpAnchor;

@end

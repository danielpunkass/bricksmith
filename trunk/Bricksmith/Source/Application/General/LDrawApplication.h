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

@interface LDrawApplication : NSObject
{
	PartLibrary		*partLibrary; //centralized location for part information.
	Inspector		*inspector; //system for graphically inspecting classes.
	NSOpenGLContext	*sharedGLContext; //OpenGL variables like display list numbers are shared through this.
}

//Actions
- (IBAction)doPreferences:(id)sender;
- (IBAction) showColors:(id)sender;
- (IBAction) showInspector:(id)sender;
- (IBAction) showMouseTools:(id)sender;

//Accessors
+ (Inspector *) sharedInspector;
+ (NSOpenGLContext *) sharedOpenGLContext;
+ (PartLibrary *) sharedPartLibrary;
- (Inspector *) inspector;
- (PartLibrary *) partLibrary;
- (NSOpenGLContext *) openGLContext;

//Utilities
- (NSString *) findLDrawPath;

@end

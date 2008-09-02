/* LDrawApplication */

#import <Cocoa/Cocoa.h>

#import "PartLibrary.h"

@class Inspector;

@interface LDrawApplication : NSObject
{
	PartLibrary		*partLibrary; //centralized location for part information.
	Inspector		*inspector; //system for graphically inspecting classes.
	NSOpenGLContext	*sharedGLContext;
}

//Actions
- (IBAction)doPreferences:(id)sender;
- (IBAction) showInspector:(id)sender;

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

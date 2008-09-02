/* LDrawApplication */

#import <Cocoa/Cocoa.h>

#import "PartLibrary.h"

@class Inspector;

@interface LDrawApplication : NSObject
{
	PartLibrary		*partLibrary; //centralized location for part information.
	Inspector		*inspector; //system for graphically inspecting classes.
}

//Actions
- (IBAction)doPreferences:(id)sender;
- (IBAction) showInspector:(id)sender;

//Accessors
+ (Inspector *) sharedInspector;
+ (PartLibrary *) sharedPartLibrary;
- (Inspector *) inspector;
- (PartLibrary *) partLibrary;

//Utilities
- (NSString *) findLDrawPath;

@end

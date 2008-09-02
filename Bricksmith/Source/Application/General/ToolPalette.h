//==============================================================================
//
// File:		ToolPalette.h
//
// Purpose:		Manages the current tool mode in effect when the mouse is used 
//				in an LDrawGLView.
//
//  Created by Allen Smith on 1/20/06.
//  Copyright 2006. All rights reserved.
//==============================================================================
#import <Cocoa/Cocoa.h>

@class LDrawColorWell;

////////////////////////////////////////////////////////////////////////////////
//
//		Types and Constants
//
////////////////////////////////////////////////////////////////////////////////

typedef enum {
	RotateSelectTool			= 0,	//click to select, drag to rotate
//	AddToSelectionTool			= 1,	//   check key directly, so we can click around in different views.
	PanScrollTool				= 2,	//"grabber" to scroll around while dragging
	SmoothZoomTool				= 3,	//zoom in and out based on drag direction
	ZoomInTool					= 4,	//click to zoom in
	ZoomOutTool					= 5		//click to zoom out
} ToolModeT;



////////////////////////////////////////////////////////////////////////////////
//
//		ToolPalette
//
////////////////////////////////////////////////////////////////////////////////
@interface ToolPalette : NSObject {

	ToolModeT				 baseToolMode;			//as selected in the palette
	ToolModeT				 effectiveToolMode;		//accounting for modifiers.
	
	//Event Tracking
	NSString				*currentKeyCharacters;	//identifies the current keys down, independent of modifiers (empty string if no keys down)
	unsigned int			 currentKeyModifiers;	//identifiers the current modifiers down (including device-dependent)

	//Nib connections
	IBOutlet NSPanel		*palettePanel;
	IBOutlet NSMatrix		*toolButtons;
	IBOutlet LDrawColorWell	*colorWell;
}


//Initialization
+ (ToolPalette *) sharedToolPalette;

//Accessors
+ (ToolModeT) toolMode;
- (ToolModeT) toolMode;

//Actions
- (void) showToolPalette:(id)sender;
- (IBAction) toolButtonClicked:(id)sender;

//Utilities
- (void) findCurrentToolMode;
+ (NSString *) keysForToolMode:(ToolModeT)toolMode modifiers:(unsigned int*)modifiersOut;
+ (BOOL) toolMode:(ToolModeT)toolMode matchesCharacters:(NSString *)characters modifiers:(unsigned int)modifiers;

@end

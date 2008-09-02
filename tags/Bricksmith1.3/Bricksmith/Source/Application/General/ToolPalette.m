//==============================================================================
//
// File:		ToolPalette.h
//
// Purpose:		Manages the current tool mode in effect when the mouse is used 
//				in an LDrawGLView. This object is the central clearinghouse for 
//				administering the current mouse-tool mode. It analyzes the 
//				keyboard events posted by BricksmithApplication, and then posts 
//				the appropriate LDrawMouseToolDidChangeNotifications, which are 
//				observed by LDrawGLView to do cursor tracking and event 
//				interpetation properly. 
//
//				By doing all this tracking in a global location, we allow all 
//				LDrawGLViews to have the same tool mode at once, rather than 
//				relying on who happens to be the first responder at the time.
//
//				Of course, for this class to do anything, an instance must first 
//				exist. LDrawApplication takes care of that for us at application 
//				startup.
//
//  Created by Allen Smith on 1/20/06.
//  Copyright 2006. All rights reserved.
//==============================================================================
#import "ToolPalette.h"

#import "LDrawColorPanel.h"
#import "LDrawColorWell.h"
#import "MacLDraw.h"
#import "StringCategory.h"

ToolPalette *sharedToolPalette = nil;

@implementation ToolPalette

//========== awakeFromNib ======================================================
//
// Purpose:		Do the things that Interface Builder cannot.
//
//==============================================================================
- (void) awakeFromNib
{
	NSNotificationCenter	*notificationCenter	= [NSNotificationCenter defaultCenter];
	NSUserDefaults			*userDefaults		= [NSUserDefaults standardUserDefaults];
	
	//Tweak the panel.
	
	NSRect paletteFrame = [self->palettePanel frame];
	NSRect buttonFrame	= [self->toolButtons frame];
	
	//narrow to the button width.
	paletteFrame.size.width = NSWidth(buttonFrame) + NSMinX(buttonFrame) * 2;
	[palettePanel setFrame:paletteFrame display:NO];
	[palettePanel setBecomesKeyOnlyIfNeeded:YES];
	
	//remove other window widgets (kosher by Human Interface Guidelines!)
	[[palettePanel standardWindowButton:NSWindowMiniaturizeButton]	setHidden:YES];
	[[palettePanel standardWindowButton:NSWindowZoomButton]			setHidden:YES];
	
	
	[self->colorWell setColorCode:[[LDrawColorPanel sharedColorPanel] LDrawColor]];
	
	
	[notificationCenter addObserver:self
						   selector:@selector(colorDidChange:)
							   name:LDrawColorDidChangeNotification
							 object:nil ];
							 
	[notificationCenter addObserver:self
						   selector:@selector(keyboardDidChange:)
							   name:LDrawKeyboardDidChangeNotification
							 object:nil ];
	
	//bring the palette onscreen
	if([userDefaults boolForKey:TOOL_PALETTE_HIDDEN] == NO)
		[palettePanel orderFront:self];
	
}//end awakeFromNib

#pragma mark -
#pragma mark INITIALIZATION
#pragma mark -

//---------- sharedToolPalette ---------------------------------------[static]--
//
// Purpose:		Returns the shared instance of the tool palette, which is used 
//				throughout the application, creating it if necessary.
//
//------------------------------------------------------------------------------
+ (ToolPalette *) sharedToolPalette {
	if(sharedToolPalette == nil)
		sharedToolPalette = [[ToolPalette alloc] init];
		
	return sharedToolPalette;
}


//========== init ==============================================================
//
// Purpose:		Bring us into the world.
//
//==============================================================================
- (id) init {
	self = [super init];
	
	baseToolMode			= RotateSelectTool;
	effectiveToolMode		= RotateSelectTool;
	currentKeyCharacters	= @"";
	currentKeyModifiers		= 0;
	
	[NSBundle loadNibNamed:@"ToolPalette" owner:self];
	
	return self;
}


#pragma mark -
#pragma mark ACCESSORS
#pragma mark -

//---------- toolMode ------------------------------------------------[static]--
//
// Purpose:		Returns the current effective tool mode, based on a base 
//				selection plus any modifiers and keys that may be down.
//
//------------------------------------------------------------------------------
+ (ToolModeT) toolMode
{
	return [[ToolPalette sharedToolPalette] toolMode];
}


//========== toolMode ==========================================================
//
// Purpose:		Returns the current effective tool mode, based on a base 
//				selection plus any modifiers and keys that may be down.
//
//==============================================================================
- (ToolModeT) toolMode
{
	return self->effectiveToolMode;
}


#pragma mark -
#pragma mark ACTIONS
#pragma mark -

//========== showToolPalette: ==================================================
//
// Purpose:		Brings the mouse Tool Palette onscreen.
//
//==============================================================================
- (void) showToolPalette:(id)sender
{
	NSUserDefaults	*userDefaults	= [NSUserDefaults standardUserDefaults];
	
	//record this preference.
	[userDefaults setBool:NO forKey:TOOL_PALETTE_HIDDEN];
	
	//open the window.
	[palettePanel orderFront:self];
	
}//end showToolPalette:


//========== toolButtonClicked =================================================
//
// Purpose:		The user has clicked a new tool button on the palette. This is 
//				the new "base" tool, which is in effect when no modifiers are 
//				pressed.
//
//==============================================================================
- (IBAction) toolButtonClicked:(id)sender
{
	ToolModeT newMode = [self->toolButtons selectedTag];
	self->baseToolMode = newMode;
	
	//update the new effective tool mode with this base and any current keys.
	[self findCurrentToolMode];
	
}//end toolButtonClicked:

#pragma mark -
#pragma mark NOTIFICATIONS
#pragma mark -

//========== colorDidChange: ===================================================
//
// Purpose:		The current color changed.
//
//==============================================================================
- (void) colorDidChange:(NSNotification *)notification{
	
	LDrawColorT	 newColor = [[LDrawColorPanel sharedColorPanel] LDrawColor];
	
	[self->colorWell setColorCode:newColor];
}


//========== keyboardDidChange: ================================================
//
// Purpose:		We are being notified (outside the responder chain) that the 
//				current state of the keyboard has changed. We need to adjust our 
//				tool mode based on that.
//
//				We get all keyUp/Down events through here, including command 
//				keys.
//
//==============================================================================
- (void) keyboardDidChange:(NSNotification *)notification
{
	NSEvent		*theEvent	= [notification object];
	NSString	*characters	= nil;
	
	switch([theEvent type]){
		
		case NSKeyDown:
			[self->currentKeyCharacters release];
			self->currentKeyCharacters = [[theEvent charactersIgnoringModifiers] retain];
			break;
		
		case NSKeyUp:
			[self->currentKeyCharacters release];
			self->currentKeyCharacters = @"";
			break;
			
		case NSFlagsChanged:
			self->currentKeyModifiers = [theEvent modifierFlags];
			break;
		
		default:
			NSLog(@"unrecognized keyboardDidChange event.");
			break;
	}
	
	[self findCurrentToolMode];
	
}//end keyboardDidChange:


#pragma mark -
#pragma mark WINDOW DELEGATE
#pragma mark -

//**** NSWindow ****
//========== windowShouldClose: ================================================
//
// Purpose:		The window's closing; we need to record this preference.
//
// Note:		This method is not called during application shutdown, so we can 
//				know that the user really is trying to close the window here.
//
//==============================================================================
- (BOOL)windowShouldClose:(id)sender
{
	NSUserDefaults	*userDefaults	= [NSUserDefaults standardUserDefaults];
	
	[userDefaults setBool:YES forKey:TOOL_PALETTE_HIDDEN];
	
	return YES;
}//end windowShouldClose:


#pragma mark -
#pragma mark UTILITIES
#pragma mark -

//========== findCurrentToolMode ===============================================
//
// Purpose:		Assesses the current state of the keyboard and sets the 
//				effective tool mode based on it.
//
//==============================================================================
- (void) findCurrentToolMode
{
	ToolModeT		 newToolMode;
	
	NSString		*baseCharacters			= nil;
	unsigned int	 baseModifiers			= 0;
	
	NSString		*effectiveCharacters	= nil;
	unsigned int	 effectiveModifiers		= 0;
	
	baseCharacters = [ToolPalette keysForToolMode: baseToolMode
										modifiers:&baseModifiers ];
	
	//the "effective keys" are the result of what we *would be pressing* to get 
	// the currently-selected tool, plus the keys we *actually are pressing*.
	effectiveCharacters	= [baseCharacters stringByAppendingString:self->currentKeyCharacters];
	effectiveModifiers	= (baseModifiers) | (self->currentKeyModifiers);

	//Zoom out (option-space-click)
	if( [ToolPalette toolMode:ZoomOutTool
			matchesCharacters:effectiveCharacters
					modifiers:effectiveModifiers] == YES)
	{
		newToolMode = ZoomOutTool;
	}
	//Zoom in (command-space-click)
	else if( [ToolPalette toolMode:ZoomInTool
				 matchesCharacters:effectiveCharacters
						 modifiers:effectiveModifiers] == YES)
	{
		newToolMode = ZoomInTool;
	}
	//Smooth Zoom (command-drag)
	else if( [ToolPalette toolMode:SmoothZoomTool
				 matchesCharacters:effectiveCharacters
						 modifiers:effectiveModifiers] == YES)
	{
		newToolMode = SmoothZoomTool;
	}
	//Panning (space-drag)
	else if( [ToolPalette toolMode:PanScrollTool
				 matchesCharacters:effectiveCharacters
						 modifiers:effectiveModifiers] == YES)
	{
		newToolMode = PanScrollTool;
	}
	//Multiple selection
//	else if( (self->currentKeyModifiers & NSShiftKeyMask) != 0 )
//	{
//		newToolMode = AddToSelectionTool;
//		//no special cursor for this, yet.
//	}
	
	//Rotate/select (no hot key; normal behavior)
	else
	{
		newToolMode = RotateSelectTool;
	}
	
	//Update the tool mode!
	if(self->effectiveToolMode != newToolMode)
	{
		self->effectiveToolMode = newToolMode;
		[self->toolButtons selectCellWithTag:newToolMode];
		
		//inform observers.
		[[NSNotificationCenter defaultCenter]
				postNotificationName:LDrawMouseToolDidChangeNotification
							  object:[NSNumber numberWithInt:effectiveToolMode] ];
	}
	
	
}//end findCurrentToolMode


//---------- keysForToolMode:modifiers: ------------------------------[static]--
//
// Purpose:		Returns the characters and assoiated modifier key flags which 
//				need to be held down in order to toggle to the specified 
//				toolMode.
//
// Parameters:	toolMode: mode to test
//				modifiersOut: on return, contains modifier flags from NSEvent 
//					associated with the toolMode. Do not pass NULL.
//
// Returns:		The characters (ignoring modifiers) associated with toolMode. 
//				If no characters are required, this will be an empty string.
//
//------------------------------------------------------------------------------
+ (NSString *) keysForToolMode:(ToolModeT)toolMode
					 modifiers:(unsigned int*)modifiersOut
{
	NSString *characters = nil; //characters required with this modifier
	
	switch(toolMode)
	{
		case RotateSelectTool:
			//this is the default tool; no keys required.
			characters = @"";
			*modifiersOut = 0;
			break;
			
		case PanScrollTool:
			//space
			characters = @" ";
			*modifiersOut = 0;
			break;
			
		case SmoothZoomTool:
			//command
			characters = @"";
			*modifiersOut = NSCommandKeyMask;
			break;
			
		case ZoomInTool:
			//command-space
			characters = @" ";
			*modifiersOut = NSCommandKeyMask;
			break;
			
		case ZoomOutTool:
			//option-space
			characters = @" ";
			*modifiersOut = NSAlternateKeyMask;
			break;
			
	}
	
	return characters;
	
}//end keysForToolMode:modifiers:


//---------- toolMode:matchesCharacters:modifiers: -------------------[static]--
//
// Purpose:		Tests whether the specified tool mode is associated with the 
//				given characters and modifiers.
//
//------------------------------------------------------------------------------
+ (BOOL) toolMode:(ToolModeT)toolMode
matchesCharacters:(NSString *)characters
		modifiers:(unsigned int)modifiers
{
	NSString		*testCharacters			= nil;
	unsigned int	 testModifiers			= 0;
	BOOL			 matches				= NO;
	
	testCharacters = [ToolPalette keysForToolMode: toolMode
										modifiers:&testModifiers ];
	
	//keys match exactly, modifiers must merely be present.
	if(		[characters containsString:testCharacters options:0]
		&&	(modifiers & testModifiers) == testModifiers )
	{
		matches = YES;
	}
	
	return matches;
	
}//end toolMode:matchesCharacters:modifiers:


#pragma mark -
#pragma mark DESTRUCTOR
#pragma mark -

//========== dealloc ===========================================================
//
// Purpose:		We're off to push up daisies.
//
//==============================================================================
- (void) dealloc {

	[[NSNotificationCenter defaultCenter] removeObserver:self];
	sharedToolPalette = nil;
	
	[palettePanel release];

	[super dealloc];
}

@end

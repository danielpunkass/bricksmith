//==============================================================================
//
// File:		BricksmithApplication.m
//
// Purpose:		Subclass of NSApplication allows us to do tricky things with 
//				events. I feel uncomfortable at best with the existence of this 
//				hacked subclass, so as little as possible should be in here.
//
// Notes:		Cocoa knows to use this subclass because we have specified its 
//				name in our Info.plist file.
//
//				Do not confuse this with LDrawApplication, an earlier class 
//				which should have been called LDrawApplicationController.
//
//  Created by Allen Smith on 11/29/05.
//  Copyright 2005. All rights reserved.
//==============================================================================
#import "BricksmithApplication.h"

#import "MacLDraw.h"

@implementation BricksmithApplication


//========== sendEvent =========================================================
//
// Purpose:		This is the central point for all events dispatched in the 
//				application.
//
//				We need to override it to grab NSKeyUp events generated while 
//				the command key is held down. We need those events so we can 
//				track keys properly for LDrawGLView's tool mode. Unfortunately, 
//				Cocoa seems to supress command-keyup events--at least, I never 
//				see them anywhere. All we do here is dispatch them to a custom 
//				method before they vanish into the ether.
//
//==============================================================================
- (void)sendEvent:(NSEvent *)theEvent
{
	//we want to track keyboard events in our own little place, completely 
	// separate from the responder chain.
	if(		[theEvent type] == NSKeyDown
		||	[theEvent type] == NSKeyUp
		||	[theEvent type] == NSFlagsChanged )
	{
		[[NSNotificationCenter defaultCenter]
							postNotificationName:LDrawKeyboardDidChangeNotification
										  object:theEvent ];
	}
/*
	//Intercept command-keyups, which NSApplication seems otherwise to 
	// completely discard.	
	if(		([theEvent modifierFlags] & NSCommandKeyMask) != 0
		&&	[theEvent type] == NSKeyUp )
	{
		//okay, we've got it. Now what do we do with it?
		
		//for command-keydown, NSApplication calls the private method 
		// -_handleKeyEquivalent:, which in turn calls -performKeyEquivalent: \
		// on the key window. That in turn starts traversing the view heirarchy.
		// In other words, a whole lot of views received the same message. This 
		// is different from other events, which are sent to the first 
		// responder first, and usually stop right there.
		
		//Well, to mimic that properly would require subclassing NSWindow and 
		// posing a subclass of NSView, all to add one lousy method. And for 
		// our limited case here, we really only want the first responder to 
		// respond anyway. So it's going to be okay to just send this one up 
		// the responder chain.
		[self sendAction:@selector(commandKeyUp:) to:nil from:theEvent];
		
		//P.S. That means that classes using -performKeyEvent: in tandem with 
		// this command-keyup hack had better check that they are the first 
		// responder before acting.
	}
*/	
	//Send all events, even command-keyups, to the application to do whatever 
	// it expects to do with them.
	[super sendEvent:theEvent];
	
}//end sendEvent:

@end

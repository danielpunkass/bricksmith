//==============================================================================
//
// File:		LDrawColorWell.m
//
// Purpose:		Widget to provide a means of choosing an LDraw color for an 
//				element. Actually, all this really does is bring up a color 
//				picker dialog. It generates the action messages to change colors, 
//				and the elements themselves are responsible for responding to 
//				them.
//
//  Created by Allen Smith on 2/27/05.
//  Copyright 2005. All rights reserved.
//==============================================================================
#import "LDrawColorWell.h"

#import "LDrawColorPanel.h"

@implementation LDrawColorWell

//========== drawRect: =========================================================
//
// Purpose:		Paints the represented color inside the button.
//
//==============================================================================
- (void)drawRect:(NSRect)aRect{
	
	
	[super drawRect:aRect];
	
	NSColor	*colorRepresented = [LDrawColor colorForCode:colorCode];
	NSRect	 colorRect = NSInsetRect(aRect, 4, 4);
	
	[colorRepresented set];
	NSRectFill(colorRect);
	
}

#pragma mark -
#pragma mark ACTIONS
#pragma mark -

//========== sendAction:to: ====================================================
//
// Purpose:		Whenever this color well is clicked, we want to pull up the 
//				color panel.
//
// Notes:		This class is a confusing thing. I'm not really sure what 
//				clicking on it means. Should it behave like an NSColorWell?
//				It doesn't now. It just sends its action off immediately after 
//				bringing up the color panel.
//
//==============================================================================
- (BOOL)sendAction:(SEL)theAction to:(id)theTarget{
	[[LDrawColorPanel sharedColorPanel] makeKeyAndOrderFront:self];
	
	[super sendAction:theAction to:theTarget];
}

#pragma mark -
#pragma mark ACCESSORS
#pragma mark -

//========== colorCode =========================================================
//
// Purpose:		Returns the LDraw color code represented by this button.
//
//==============================================================================
- (LDrawColorT) colorCode{
	return colorCode;
}

//========== colorForCode: =====================================================
//
// Purpose:		Sets the LDraw color code of the receiver to newColorCode and 
//				redraws the receiever.
//
//==============================================================================
- (void) setColorCode:(LDrawColorT) newColorCode{
	colorCode = newColorCode;
	[self setNeedsDisplay:YES];
}


@end

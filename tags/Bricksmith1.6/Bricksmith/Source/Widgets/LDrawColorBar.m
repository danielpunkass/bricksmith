//==============================================================================
//
// File:		LDrawColorBar.h
//
// Purpose:		Color view used to display an LDraw color. It's just a big 
//				rectangle; that's it. You can view the one and only specimen of 
//				this widget in the LDrawColorPanel (the big thing at the top).
//
//  Created by Allen Smith on 2/27/05.
//  Copyright (c) 2005. All rights reserved.
//==============================================================================
#import "LDrawColorBar.h"


@implementation LDrawColorBar


//========== drawRect: =========================================================
//
// Purpose:		Paints the represented color inside the bar, along with a small 
//				border.
//
//==============================================================================
- (void)drawRect:(NSRect)aRect{
	
	[super drawRect:aRect]; //does nothing.
	
	NSColor	*colorRepresented = [LDrawColor colorForCode:colorCode];
	
//	NSBezierPath *rectPath = [NSBezierPath bezierPathWithRect:aRect];
//	[rectPath stroke];
	
	[[NSColor grayColor] set];
	NSRectFill(aRect);
	
	[[NSColor whiteColor] set];
	NSRectFill(NSInsetRect(aRect, 1, 1));
	
	//We can let the OS do it, but I'm not going to. Basically, it's because 
	// their display of transparent colors is mind-bogglingly ugly.
	// You also get a little triangle in the corner when using device colors,
	// which I am for no apparent reason.
//	[colorRepresented drawSwatchInRect:NSInsetRect(aRect, 2, 2)];
	[colorRepresented set];
	NSRectFill(NSInsetRect(aRect, 2, 2));
	
}

#pragma mark -
#pragma mark ACCESSORS
#pragma mark -

//========== LDrawColor ========================================================
//
// Purpose:		Returns the LDraw color code represented by this button.
//
//==============================================================================
- (LDrawColorT) LDrawColor{
	return colorCode;
}

//========== setLDrawColor: ====================================================
//
// Purpose:		Sets the LDraw color code of the receiver to newColorCode and 
//				redraws the receiever.
//
//==============================================================================
- (void) setLDrawColor:(LDrawColorT) newColorCode{
		
	colorCode = newColorCode;
	
	//Create a tool tip to identify the LDraw color code.
	NSString *colorKey = [NSString stringWithFormat:@"LDraw: %d", colorCode];
	NSString *description = NSLocalizedString(colorKey, nil);
	[self setToolTip:[NSString stringWithFormat:@"LDraw %d\n%@", colorCode, description]];
	
	[self setNeedsDisplay:YES];
}



@end

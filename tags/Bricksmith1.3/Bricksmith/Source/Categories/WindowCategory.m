//==============================================================================
//
// Category: WindowCategory.m
//
//		Convenient window utility methods.
//
//  Created by Allen Smith on 3/12/05.
//  Copyright 2005. All rights reserved.
//==============================================================================
#import "WindowCategory.h"


@implementation NSWindow (WindowCategory)

//========== frameRectForContentSize: ==========================================
//
// Purpose:		Computes the frame rectangle (in screen coordinates) for 
//				the window if its content view has newSize.
//
//				This is a very handy utility method for windows with several 
//				differently-sized panes, like a preferences window.
//
//==============================================================================
- (NSRect) frameRectForContentSize:(NSSize)newSize{
	
	//Get the current size.
	NSSize currentContentSize	= [[self contentView] frame].size;
	//And the current frame, which takes into account the title bar and toolbar.
	NSRect newFrameRect			= [self frame];
	
	//Now adjust the frame by the difference between the size of its current 
	// contents and newSize.
	newFrameRect.size.width		+= newSize.width  - currentContentSize.width;
	newFrameRect.size.height	+= newSize.height - currentContentSize.height;
	
	newFrameRect.origin.y		-= newSize.height - currentContentSize.height;
	
	return newFrameRect;
}

@end

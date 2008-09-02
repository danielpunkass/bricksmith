//==============================================================================
//
// File:		LDrawDocumentWindow.m
//
// Purpose:		Window for LDraw. Provides minor niceties.
//
//  Created by Allen Smith on 4/4/05.
//  Copyright 2005. All rights reserved.
//==============================================================================
#import "LDrawDocumentWindow.h"


@implementation LDrawDocumentWindow


#pragma mark -
#pragma mark EVENTS
#pragma mark -

//========== keyDown: ==========================================================
//
// Purpose:		Time to do something exciting in response to a keypress.
//
//==============================================================================
- (void)keyDown:(NSEvent *)theEvent {
	
	unsigned int keycode = [theEvent keyCode];
	if(   keycode == 51 //delete
	   || keycode == 117 ) //forward delete
	{
		//Delete was pressed. How do we know? Why, the keycode is 51 of course.
		// It's obvious! Plain as day! It's so blindingly clear that it would 
		// be a total waste to document where these keycodes come from. Yup.
		[NSApp sendAction:@selector(delete:)
					   to:nil //just send it somewhere!
					 from:self]; //it's from us (we'll be the sender)
	}
}//end keyDown:



@end

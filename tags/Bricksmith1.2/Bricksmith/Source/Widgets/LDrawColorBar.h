//==============================================================================
//
// File:		LDrawColorBar.m
//
// Purpose:		Color view used to display an LDraw color. It's just a big 
//				rectangle; that's it. You can view the one and only specimen of 
//				this widget in the LDrawColorPanel (the big thing at the top).
//
//  Created by Allen Smith on 2/27/05.
//  Copyright (c) 2005. All rights reserved.
//==============================================================================
#import <Cocoa/Cocoa.h>

#import "LDrawColor.h"

@interface LDrawColorBar : NSView <LDrawColorable> {
	
	LDrawColorT colorCode;
}

//Accessors
- (LDrawColorT) LDrawColor;
- (void) setLDrawColor:(LDrawColorT) newColorCode;

@end

//==============================================================================
//
// File:		LDrawColorWell.h
//
// Purpose:		Provides a means of choosing an LDraw color for an element.
//
//  Created by Allen Smith on 2/27/05.
//  Copyright 2005. All rights reserved.
//==============================================================================
#import <Cocoa/Cocoa.h>

#import "LDrawColor.h"

@interface LDrawColorWell : NSButton {
	LDrawColorT colorCode;
}

//Accessors
- (LDrawColorT) colorCode;
- (void) setColorCode:(LDrawColorT) newColorCode;

@end

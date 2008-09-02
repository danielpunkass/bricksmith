//==============================================================================
//
// File:		LDrawColorCell.m
//
// Purpose:		Displays a swatch of an LDraw color in a cell.
//
//  Created by Allen Smith on 2/26/05.
//  Copyright 2005. All rights reserved.
//==============================================================================
#import "LDrawColorCell.h"

#import "LDrawColor.h"

@implementation LDrawColorCell

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	NSNumber	*cellObject = [self objectValue];
	LDrawColorT colorCode = [cellObject intValue]; //can't just call [self intValue] here; that only works on text contents.
	
	NSColor		*cellColor = [LDrawColor colorForCode:colorCode];
	[cellColor set];
	NSRectFillUsingOperation(cellFrame, NSCompositeSourceOver);
}

@end

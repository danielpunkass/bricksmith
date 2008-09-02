//==============================================================================
//
// File:		LDrawConditionalLine.m
//
// Purpose:		Conditional Line primitive command.
//
//  Created by Allen Smith on 2/19/05.
//  Copyright (c) 2005. All rights reserved.
//==============================================================================
#import "LDrawLine.h"


@interface LDrawConditionalLine : LDrawLine <NSCoding> {
	
	Point3		conditionalVertex1;
	Point3		conditionalVertex2;
}

+ (LDrawConditionalLine *) conditionalLineWithDirectiveText:(NSString *)directive;

//Accessors
- (Point3) conditionalVertex1;
- (Point3) conditionalVertex2;
-(void) setConditionalVertex1:(Point3)newVertex;
-(void) setConditionalVertex2:(Point3)newVertex;

@end

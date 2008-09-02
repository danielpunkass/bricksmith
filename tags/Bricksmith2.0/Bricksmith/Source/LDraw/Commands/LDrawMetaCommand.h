//==============================================================================
//
// File:		LDrawMetaCommand.m
//
// Purpose:		Basic holder for a meta-command.
//
//  Created by Allen Smith on 2/19/05.
//  Copyright (c) 2005. All rights reserved.
//==============================================================================
#import "LDrawDirective.h"

////////////////////////////////////////////////////////////////////////////////
//
// class LDrawMetaCommand
//
////////////////////////////////////////////////////////////////////////////////
@interface LDrawMetaCommand : LDrawDirective
{
	NSString		*commandString;
}

+ (LDrawMetaCommand *) commandWithDirectiveText:(NSString *)directive;
- (BOOL) finishParsing:(NSScanner *)scanner;

- (void) draw:(unsigned int) optionsMask parentColor:(GLfloat *)parentColor;
- (NSString *) write;

//Accessors
-(void) setStringValue:(NSString *)newString;
-(NSString *) stringValue;

@end

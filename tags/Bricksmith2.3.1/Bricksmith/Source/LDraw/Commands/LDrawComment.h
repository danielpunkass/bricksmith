//==============================================================================
//
// File:		LDrawComment.m
//
// Purpose:		Basic holder for a meta-command.
//
//  Created by Allen Smith on 3/12/05.
//  Copyright (c) 2005. All rights reserved.
//==============================================================================
#import "LDrawMetaCommand.h"

@interface LDrawComment : LDrawMetaCommand {
	
}

+ (LDrawComment *) commentWithDirectiveText:(NSString *)directive;

- (NSString *) write;

@end

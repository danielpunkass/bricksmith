//==============================================================================
//
// File:		LDrawComment.m
//
// Purpose:		A comment. It serves only as explanatory text in the model.
//
//				Line format:
//				0 WRITE message-text
//					or
//				0 PRINT message-text
//
//				where
//
//				* message-text is a comment string
//
//  Created by Allen Smith on 3/12/05.
//  Copyright (c) 2005. All rights reserved.
//==============================================================================
#import "LDrawComment.h"

#import "MacLDraw.h"

@implementation LDrawComment

#pragma mark -
#pragma mark INITIALIZATION
#pragma mark -

//========== commentWithDirectiveText: =========================================
//
// Purpose:		Given a line from an LDraw file, parse a basic comment line.
//
//				directive should have the format:
//
//				0 WRITE message-text
//					or
//				0 PRINT message-text
//
//==============================================================================
+ (LDrawComment *) commentWithDirectiveText:(NSString *)directive{
	return [LDrawComment directiveWithString:directive];
}


//========== directiveWithString: ==============================================
//
// Purpose:		Returns the LDraw directive based on lineFromFile, a single line 
//				of LDraw code from a file.
//
//==============================================================================
+ (id) directiveWithString:(NSString *)lineFromFile{
		
	LDrawComment	*parsedComment	= nil;
	NSString		*workingLine	= lineFromFile;
	NSString		*parsedField	= nil;
	
	
	//A malformed part could easily cause a string indexing error, which would 
	// raise an exception. We don't want this to happen here.
	NS_DURING
		//Read in the line code and advance past it.
		parsedField = [LDrawDirective readNextField:  workingLine
										  remainder: &workingLine ];
		//Only attempt to create the part if this is a valid line.
		if([parsedField intValue] == 0){
			//A comment must begin with a 
			parsedField = [LDrawDirective readNextField:  workingLine
											  remainder: &workingLine ];
			if([parsedField isEqualToString:LDRAW_COMMENT_WRITE] ||
			   [parsedField isEqualToString:LDRAW_COMMENT_PRINT]    )
			{
				parsedComment = [[LDrawComment new] autorelease];
		
				[parsedComment setStringValue:
						[workingLine stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
			}
											  
		}
		
	NS_HANDLER
		NSLog(@"the comment %@ was fatally invalid", lineFromFile);
		NSLog(@" raised exception %@", [localException name]);
	NS_ENDHANDLER
	
	return parsedComment;
}//end lineWithDirectiveText

#pragma mark -
#pragma mark DIRECTIVES
#pragma mark -

//========== write =============================================================
//
// Purpose:		Returns a line that can be written out to a file.
//				Line format:
//				0 WRITE comment-text
//
// Notes:		Bricksmith only attempts to write out one style of comments.
//
//==============================================================================
- (NSString *) write{
	return [NSString stringWithFormat:
				@"0 %@ %@",
				LDRAW_COMMENT_WRITE,
				[self stringValue]
			];
}//end write

#pragma mark -
#pragma mark DISPLAY
#pragma mark -

//========== browsingDescription ===============================================
//
// Purpose:		Returns a representation of the directive as a short string 
//				which can be presented to the user.
//
//==============================================================================
- (NSString *)browsingDescription
{
	return [self stringValue];
}


//========== iconName ==========================================================
//
// Purpose:		Returns the name of image file used to display this kind of 
//				object, or nil if there is no icon.
//
//==============================================================================
- (NSString *) iconName{
	return @"Comment";
}


//========== inspectorClassName ================================================
//
// Purpose:		Returns the name of the class used to inspect this one.
//
//==============================================================================
- (NSString *) inspectorClassName{
	return @"InspectionComment";
}


@end
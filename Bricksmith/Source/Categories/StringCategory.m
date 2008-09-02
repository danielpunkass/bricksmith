//==============================================================================
//
// File:		StringCategory.m
//
// Purpose:		Handy string utilities. Provides one-stop (Interface Builder-
//				compatible!) method for doing a numeric sort and other nice 
//				convenience methods.
//
//  Created by Allen Smith on 2/19/05.
//  Copyright 2005. All rights reserved.
//==============================================================================
#import "StringCategory.h"

@implementation NSString (StringCategory)


//========== containsString:options: ===========================================
//
// Purpose:		Handy for quick searches.
//
// Note:		Every string is reported as containing the empty string (@"").
//
//==============================================================================
- (BOOL) containsString:(NSString *)substring options:(unsigned)mask
{
	NSRange foundRange = [self rangeOfString:substring options:mask];
	
	if(		foundRange.location == NSNotFound
		&& [substring isEqualToString:@""] == NO)
	{
		return NO;
	}
	else
		return YES;
}


//========== CRLF ==============================================================
//
// Purpose:		Returns a DOS line-end marker, which is a hideous two characters 
//				in length.
//
//==============================================================================
+ (NSString *) CRLF{
	unichar CRLFchars[] = {0x000D, 0x000A}; //DOS linefeed.
	NSString *CRLF = [NSString stringWithCharacters:CRLFchars length:2];
	
	return CRLF;
}


//========== numericCompare: ===================================================
//
// Purpose:		Provides one-stop (Interface Builder-compatible!) method for 
//				doing a numeric sort.
//
//==============================================================================
- (NSComparisonResult)numericCompare:(NSString *)string
{
	return [self compare:string options:NSNumericSearch];
}

//========== separateByLine ====================================================
//
// Purpose:		Returns an array of all the lines in the string, with line 
//				terminators removed.
//
//==============================================================================
- (NSArray *) separateByLine
{
	NSMutableArray	*lines = [NSMutableArray array];
	unsigned		 stringLength = [self length];
	
	unsigned		 lineStartIndex = 0;
	unsigned		 nextlineStartIndex = 0;
	unsigned		 newlineIndex	= 0; //index of the first newline character in the line.
	
	NSString		*isolatedLine;
	int				 lineLength = 0;
	
	while(nextlineStartIndex < stringLength){
		//Read the first line. LDraw files are in DOS format. Oh the agony.
		// But Cocoa is nice to us.
		[self getLineStart: &lineStartIndex
					   end: &nextlineStartIndex
			   contentsEnd: &newlineIndex
				  forRange: NSMakeRange(nextlineStartIndex,1) ]; //that is, contains the first character.
		
		lineLength = newlineIndex - lineStartIndex;
		isolatedLine = [self substringWithRange:NSMakeRange(lineStartIndex, lineLength)];
		[lines addObject:isolatedLine];
	}
	
	return lines;
	
}//end separateStringByLine

@end


//==============================================================================
//
// File:		LDrawMetaCommand.m
//
// Purpose:		Meta-command holder.
//				Could do just about anything, but only in subclasses!
//
//				Line format:
//				0 command... 
//
//				where
//
//				* command is a string; it could mean anything.
//
//  Created by Allen Smith on 2/21/05.
//  Copyright (c) 2005. All rights reserved.
//==============================================================================
#import "LDrawMetaCommand.h"

#import "LDrawComment.h"

@implementation LDrawMetaCommand

#pragma mark -
#pragma mark INITIALIZATION
#pragma mark -

//========== commandWithDirectiveText: =========================================
//
// Purpose:		Given a line from an LDraw file, parse a basic meta-command line.
//
//				directive should have the format:
//
//				0 command... 
//
//==============================================================================
+ (LDrawMetaCommand *) commandWithDirectiveText:(NSString *)directive{
	return [LDrawMetaCommand directiveWithString:directive];
}


//========== directiveWithString: ==============================================
//
// Purpose:		Returns the LDraw directive based on lineFromFile, a single line 
//				of LDraw code from a file.
//
//==============================================================================
+ (id) directiveWithString:(NSString *)lineFromFile{
		
	LDrawMetaCommand	*parsedLDrawMetaCommand = nil;
	NSString			*workingLine = lineFromFile;
	NSString			*parsedField;
	
	//First try creating directives with all of the subclasses of this file.
	parsedLDrawMetaCommand = [LDrawComment directiveWithString:lineFromFile];
	
	if(parsedLDrawMetaCommand == nil){
		//A malformed part could easily cause a string indexing error, which would 
		// raise an exception. We don't want this to happen here.
		NS_DURING
			//Read in the line code and advance past it.
			parsedField = [LDrawDirective readNextField:  workingLine
											  remainder: &workingLine ];
			//Only attempt to create the part if this is a valid line.
			if([parsedField intValue] == 0){
				parsedLDrawMetaCommand = [[LDrawMetaCommand new] autorelease];
		
				[parsedLDrawMetaCommand setStringValue:workingLine];
			}
			
		NS_HANDLER
			NSLog(@"the meta-command %@ was fatally invalid", lineFromFile);
			NSLog(@" raised exception %@", [localException name]);
		NS_ENDHANDLER
		
	}
	
	return parsedLDrawMetaCommand;
}//end lineWithDirectiveText


//========== init ==============================================================
//
// Purpose:		Initialize an empty command.
//
//==============================================================================
- (id) init {
	self = [super init];
	[self setStringValue:@""];
	return self;
}


//========== initWithCoder: ====================================================
//
// Purpose:		Reads a representation of this object from the given coder,
//				which is assumed to always be a keyed decoder. This allows us to 
//				read and write LDraw objects as NSData.
//
//==============================================================================
- (id)initWithCoder:(NSCoder *)decoder
{
	const uint8_t *temporary = NULL; //pointer to a temporary buffer returned by the decoder.
	
	self = [super initWithCoder:decoder];
	
	commandString	= [[decoder decodeObjectForKey:@"commandString"] retain];
	
	return self;
}


//========== encodeWithCoder: ==================================================
//
// Purpose:		Writes a representation of this object to the given coder,
//				which is assumed to always be a keyed decoder. This allows us to 
//				read and write LDraw objects as NSData.
//
//==============================================================================
- (void)encodeWithCoder:(NSCoder *)encoder
{
	[super encodeWithCoder:encoder];
	
	[encoder encodeObject:commandString forKey:@"commandString"];
}


//========== copyWithZone: =====================================================
//
// Purpose:		Returns a duplicate of this file.
//
//==============================================================================
- (id) copyWithZone:(NSZone *)zone {
	
	LDrawMetaCommand *copied = (LDrawMetaCommand *)[super copyWithZone:zone];
	
	[copied setStringValue:[self stringValue]];
	
	return copied;
}


#pragma mark -
#pragma mark DIRECTIVES
#pragma mark -

//========== draw ==============================================================
//
// Purpose:		Draws the part.
//
//==============================================================================
- (void) draw:(unsigned int) optionsMask parentColor:(GLfloat *)parentColor{
	//[super draw];
}


//========== write =============================================================
//
// Purpose:		Returns a line that can be written out to a file.
//				Line format:
//				0 command... 
//
//==============================================================================
- (NSString *) write{
	return [NSString stringWithFormat:
				@"0 %@",
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
//	return NSLocalizedString(@"Unknown Metacommand", nil);
	return commandString;
}


//========== iconName ==========================================================
//
// Purpose:		Returns the name of image file used to display this kind of 
//				object, or nil if there is no icon.
//
//==============================================================================
- (NSString *) iconName{
	return @"Unknown";
}


//========== inspectorClassName ================================================
//
// Purpose:		Returns the name of the class used to inspect this one.
//
//==============================================================================
- (NSString *) inspectorClassName{
	return @"InspectionUnknownCommand";
}


#pragma mark -
#pragma mark ACCESSORS
#pragma mark -

//========== setStringValue: ===================================================
//
// Purpose:		updates the basic command string.
//
//==============================================================================
-(void) setStringValue:(NSString *)newString{
	[newString retain];
	[commandString release];
	
	commandString = newString;
}


//========== stringValue =======================================================
//
// Purpose:		
//
//==============================================================================
-(NSString *) stringValue{
	return commandString;
}

#pragma mark -
#pragma mark UTILITIES
#pragma mark -

//========== registerUndoActions ===============================================
//
// Purpose:		Registers the undo actions that are unique to this subclass, 
//				not to any superclass.
//
//==============================================================================
- (void) registerUndoActions:(NSUndoManager *)undoManager {
	
	[super registerUndoActions:undoManager];
	
	[[undoManager prepareWithInvocationTarget:self] setStringValue:[self stringValue]];
	
	//[undoManager setActionName:NSLocalizedString(@"UndoAttributesLine", nil)];
	// (unused for this class; a plain "Undo" will probably be less confusing.)
}


#pragma mark -
#pragma mark DESTRUCTOR
#pragma mark -

//========== dealloc ===========================================================
//
// Purpose:		Embraced by the light.
//
//==============================================================================
- (void) dealloc {
	[commandString release];
	
	[super dealloc];
}

@end

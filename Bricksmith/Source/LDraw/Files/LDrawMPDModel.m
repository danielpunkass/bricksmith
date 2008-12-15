//==============================================================================
//
// File:		LDrawMPDModel.m
//
// Purpose:		LDraw MPD (Multi-Part Document) models are the basic components 
//				of an LDrawFile. An MPD model is a discreet collection of parts 
//				(such as a car or a minifigure); each file can be composed of 
//				multiple models.
//
//				An MPD model is an extension of a basic LDraw model, with the 
//				addition of a name which can be used to refer to the entire 
//				model as a single part. (This is used, for instance, to insert 
//				the entire minifigure driver into his car.)
//
//				While the LDraw file format accommodates documents with only one 
//				(non-MPD) model, Bricksmith does not make such a distinction 
//				until the file is actually written to disk. For the sake of 
//				simplicity, all logical models within an LDrawFile *must* be 
//				MPD models.
//				
//
//  Created by Allen Smith on 2/19/05.
//  Copyright 2005. All rights reserved.
//==============================================================================
#import "LDrawMPDModel.h"

#import "LDrawFile.h"
#import "LDrawUtilities.h"
#import "MacLDraw.h"
#import "StringCategory.h"


@implementation LDrawMPDModel

#pragma mark -
#pragma mark INITIALIZATION
#pragma mark -

//---------- newModel ------------------------------------------------[static]--
//
// Purpose:		Creates a new model ready to be edited.
//
//------------------------------------------------------------------------------
+ (id) newModel
{
	LDrawMPDModel *newModel = [[LDrawMPDModel alloc] initNew];
	
	return [newModel autorelease];
	
}//end newModel


//---------- modelWithLines: -----------------------------------------[static]--
//
// Purpose:		Creates a new model file based on the lines from a file.
//				These lines of strings should only describe one model, not 
//				multiple ones.
//
//				The first line *must* be an MPD file delimiter.
//
//------------------------------------------------------------------------------
+ (id) modelWithLines:(NSArray *)lines
{
	LDrawMPDModel *newModel = [[LDrawMPDModel alloc] initWithLines:lines];
	
	return [newModel autorelease];
	
}//end modelWithLines:


//========== init ==============================================================
//
// Purpose:		Creates a blank submodel.
//
//==============================================================================
- (id) init
{
	[super init];
	
	modelName = @"";
	
	return self;
	
}//end init


//========== initNew ===========================================================
//
// Purpose:		Creates a submodel ready for editing.
//
//==============================================================================
- (id) initNew
{
	NSString	*newModelName	= nil;

	self = [super initNew];
	
	// Set the spec-compliant model name with extension
	newModelName = NSLocalizedString(@"UntitledModel", nil);
	[self setModelDisplayName:newModelName];
	
	return self;
	
}//end initNew


//========== initWithLines: ====================================================
//
// Purpose:		Creates a new model file based on the lines from a file.
//				These lines of strings should only describe one model, not 
//				multiple ones.
//
//				The first line does not need to be an MPD file delimiter. If 
//				you pass in a non-mpd submodel, this method simply wraps it in 
//				an MPD submodel object.
//
//==============================================================================
- (id) initWithLines:(NSArray *)lines
{						//get the line that should contain 0 FILE
	NSString		*mpdFileCommand		= [lines objectAtIndex:0];
	NSString		*mpdSubmodelName	= @"";
	BOOL			 isMPDModel			= NO;
	NSMutableArray	*nonMPDLines		= [NSMutableArray arrayWithArray:lines];

	if([mpdFileCommand hasPrefix:LDRAW_MPD_FILE_START_MARKER]) //does it contain 0 FILE?
		isMPDModel = YES; //it does start with 0 FILE; it is MPD.
	
	//Strip out the MPD commands for model parsing, and read in the model name.
	if(isMPDModel == YES)
	{
		//Extract MPD-specific data: the submodel name.
		// Make sure there is actually a name after the marker. There certainly 
		// should be, but let's be extra-special safe.
		int indexOfName = [LDRAW_MPD_FILE_START_MARKER length] + 1; // after "0 FILE "
		if([mpdFileCommand length] >= indexOfName)
		{
			mpdSubmodelName = [mpdFileCommand substringFromIndex:indexOfName];
			mpdSubmodelName = [mpdSubmodelName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
								//I've encountered models with extra whitespace around their names.
		}
		
		//Strip out the first line and the NOFILE command, if there is one.
		[nonMPDLines removeObjectAtIndex:0];
		[nonMPDLines removeObject:LDRAW_MPD_FILE_END_MARKER];
	}

	//Create a basic model.
	[super initWithLines:nonMPDLines]; //parses model into header and steps.
	
	//If it wasn't MPD, we still need a model name. We can get that via the 
	// parsed model.
	if(isMPDModel == NO)
	{
		mpdSubmodelName = [self modelDescription];
	}

	//And now set the MPD-specific attributes.
	[self setModelName:mpdSubmodelName];
	

	return self;

}//end initWithLines:


//========== initWithCoder: ====================================================
//
// Purpose:		Reads a representation of this object from the given coder,
//				which is assumed to always be a keyed decoder. This allows us to 
//				read and write LDraw objects as NSData.
//
//==============================================================================
- (id)initWithCoder:(NSCoder *)decoder
{
	self = [super initWithCoder:decoder];
	
	modelName = [[decoder decodeObjectForKey:@"modelName"] retain];
	
	return self;
	
}//end initWithCoder:


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
	
	[encoder encodeObject:modelName forKey:@"modelName"];
	
}//end encodeWithCoder:


//========== copyWithZone: =====================================================
//
// Purpose:		Returns a duplicate of this file.
//
//==============================================================================
- (id) copyWithZone:(NSZone *)zone
{
	LDrawMPDModel	*copied	= (LDrawMPDModel *)[super copyWithZone:zone];
	
	[copied setModelName:[self modelName]];
	
	return copied;
	
}//end copyWithZone:


#pragma mark -
#pragma mark DIRECTIVES
#pragma mark -

//========== write =============================================================
//
// Purpose:		Writes out the MPD submodel, wrapped in the MPD file commands.
//
//==============================================================================
- (NSString *) write
{
	NSString *CRLF = [NSString CRLF]; //we need a DOS line-end marker, because 
									  //LDraw is predominantly DOS-based.
	
	NSMutableString *written = [NSMutableString string];
	
	//Write it out as:
	//		0 FILE model_name
	//			....
	//		   model text
	//			....
	//		0 NOFILE
	[written appendFormat:@"%@ %@%@", LDRAW_MPD_FILE_START_MARKER, [self modelName], CRLF];
	[written appendFormat:@"%@%@", [super write], CRLF];
	[written appendString:LDRAW_MPD_FILE_END_MARKER];
	
	return written;
	
}//end write


//========== writeModel =============================================================
//
// Purpose:		Writes out the submodel, without the MPD file commands.
//
//==============================================================================
- (NSString *) writeModel
{
	return [super write];
	
}//end writeModel


#pragma mark -
#pragma mark DISPLAY
#pragma mark -

//========== browsingDescription ===============================================
//
// Purpose:		Returns a representation of the directive as a short string 
//				which can be presented to the user.
//
//==============================================================================
- (NSString *) browsingDescription
{
	// Chop off that hideous un-Maclike .ldr extension that the LDraw File 
	// Specification forces us to add. 
	return [[self modelName] stringByDeletingPathExtension];
	
}//end browsingDescription


//========== inspectorClassName ================================================
//
// Purpose:		Returns the name of the class used to inspect this one.
//
//==============================================================================
- (NSString *) inspectorClassName
{
	return @"InspectionMPDModel";
	
}//end inspectorClassName


#pragma mark -
#pragma mark ACCESSORS
#pragma mark -

//========== modelName =========================================================
//
// Purpose:		Retuns the name for this MPD file. The MPD name functions as 
//				the part name to describe the entire submodel.
//
//==============================================================================
- (NSString *) modelName
{
	return modelName;
	
}//end modelName


//========== setModelName: =====================================================
//
// Purpose:		Updates the name for this MPD file. The MPD name functions as 
//				the part name to describe the entire submodel.
//
//==============================================================================
- (void) setModelName:(NSString *)newModelName
{
	[newModelName retain];
	[modelName release];
	
	modelName = newModelName;
	
}//end setModelName:


//========== setModelDisplayName: ==============================================
//
// Purpose:		Unfortunately, we can't accept any old input for model names. 
//				This method accepts a user-entered string with arbitrary 
//				characters, and sets the model name to the closest 
//				representation thereof which is still LDraw-compliant. 
//
//				After calling this method, -browsingDescription will return a 
//				value as close to newDisplayName as possible. 
//
//==============================================================================
- (void) setModelDisplayName:(NSString *)newDisplayName
{
	NSString	*acceptableName	= [LDrawMPDModel ldrawCompliantNameForName:newDisplayName];
	
	[self setModelName:acceptableName];
	
}//end setModelDisplayName:


#pragma mark -
#pragma mark UTILITIES
#pragma mark -

//---------- ldrawCompliantNameForName: ------------------------------[static]--
//
// Purpose:		Unfortunately, we can't accept any old input for model names. 
//				This method accepts a user-entered string with arbitrary 
//				characters, and returns the model name or the closest 
//				representation thereof which is still LDraw-compliant. 
//
//------------------------------------------------------------------------------
+ (NSString *) ldrawCompliantNameForName:(NSString *)newDisplayName
{
	NSString	*acceptableName	= nil;
	
	// Since LDraw is space-delimited, we can't have whitespace at the beginning 
	// of the name. We'll chop of ending whitespace for good measure.
	acceptableName = [newDisplayName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	
	// The LDraw spec demands that the model name end with a valid LDraw 
	// extension. Yuck! 
	if([LDrawUtilities isLDrawFilenameValid:acceptableName] == NO)
	{
//		acceptableName = [acceptableName stringByAppendingPathExtension:@"ldr"];
		acceptableName = [acceptableName stringByAppendingString:@".ldr"];
	}
	
	return acceptableName;
	
}//end ldrawCompliantNameForName:


//========== registerUndoActions ===============================================
//
// Purpose:		Registers the undo actions that are unique to this subclass, 
//				not to any superclass.
//
//==============================================================================
- (void) registerUndoActions:(NSUndoManager *)undoManager
{
	LDrawFile		*enclosingFile		= [self enclosingFile];
	NSString		*oldName			= [self modelName];
	
	[super registerUndoActions:undoManager];
	
	// Changing the name of the model in an undo-aware way is pretty bothersome, 
	// because we have to track down any references to the model and change 
	// their names too. That operation is the responsibility of the LDrawFile, 
	// not us. 
	if(enclosingFile != nil)
	{
		[[undoManager prepareWithInvocationTarget:enclosingFile]
									 renameModel: self
										  toName: oldName ];
	}
	else
		[[undoManager prepareWithInvocationTarget:self] setModelName:oldName];
	
}//end registerUndoActions:


#pragma mark -
#pragma mark DESTRUCTOR
#pragma mark -

//========== dealloc ===========================================================
//
// Purpose:		Time to send the cows home.
//
//==============================================================================
- (void) dealloc
{
	[modelName	release];

	[super dealloc];
	
}//end dealloc


@end

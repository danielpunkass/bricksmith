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

#import "MacLDraw.h"
#import "StringCategory.h"


@implementation LDrawMPDModel

#pragma mark -
#pragma mark INITIALIZATION
#pragma mark -

//========== newModel ==========================================================
//
// Purpose:		Creates a new model ready to be edited.
//
//==============================================================================
+ (id) newModel {
	LDrawMPDModel *newModel = [[LDrawMPDModel alloc] initNew];
	

	return [newModel autorelease];
}


//========== modelWithLines: ===================================================
//
// Purpose:		Creates a new model file based on the lines from a file.
//				These lines of strings should only describe one model, not 
//				multiple ones.
//
//				The first line *must* be an MPD file delimiter.
//
//==============================================================================
+ (id) modelWithLines:(NSArray *)lines
{
	LDrawMPDModel *newModel = [[LDrawMPDModel alloc] initWithLines:lines];
	
	return [newModel autorelease];
}


//========== init ==============================================================
//
// Purpose:		Creates a blank submodel.
//
//==============================================================================
- (id) init {
	
	[super init];
	
	modelName = @"";
	
	return self;
}


//========== initNew ===========================================================
//
// Purpose:		Creates a submodel ready for editing.
//
//==============================================================================
- (id) initNew {
	
	[super initNew];
	
	[self setModelName:NSLocalizedString(@"UntitledModel", nil)];
	
	return self;
}

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
- (id) initWithLines:(NSArray *)lines {
	
	//get the line that should contain 0 FILE
	NSString		*mpdFileCommand = [lines objectAtIndex:0];
	NSString		*mpdSubmodelName = @"";
	BOOL			 isMPDModel = NO;
	NSMutableArray	*nonMPDLines = [NSMutableArray arrayWithArray:lines];

	if([mpdFileCommand hasPrefix:LDRAW_MPD_FILE_START_MARKER]) //does it contain 0 FILE?
		isMPDModel = YES; //it does start with 0 FILE; it is MPD.
	
	//Strip out the MPD commands for model parsing, and read in the model name.
	if(isMPDModel == YES){

		//Strip out the first line.
		[nonMPDLines removeObjectAtIndex:0];
		//Remove NOFILE command, if there is one.
		[nonMPDLines removeObject:LDRAW_MPD_FILE_END_MARKER];
		
		
		//Now extract MPD-specific data: the submodel name.
		int indexOfName = [LDRAW_MPD_FILE_START_MARKER length] + 1; // after "0 FILE "
		//Make sure there is actually a name after the marker. There certainly 
		// should be, but let's be extra-special safe.
		if([mpdFileCommand length] >= indexOfName)
			mpdSubmodelName = [mpdFileCommand substringFromIndex:indexOfName];
		
	}

	//Create a basic model.
	[super initWithLines:nonMPDLines]; //parses model into header and steps.
	
	//If it wasn't MPD, we still need a model name. We can get that via the 
	// parsed model.
	if(isMPDModel == NO)
		mpdSubmodelName = [self modelDescription];

	//And now set the MPD-specific attributes.
	[self setModelName:mpdSubmodelName];

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
	self = [super initWithCoder:decoder];
	
	modelName = [[decoder decodeObjectForKey:@"modelName"] retain];
	
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
	
	[encoder encodeObject:modelName forKey:@"modelName"];
}


//========== copyWithZone: =====================================================
//
// Purpose:		Returns a duplicate of this file.
//
//==============================================================================
- (id) copyWithZone:(NSZone *)zone {
	
	LDrawMPDModel	*copied	= (LDrawMPDModel *)[super copyWithZone:zone];
	
	[copied setModelName:[self modelName]];
	
	return copied;
}


#pragma mark -
#pragma mark DIRECTIVES
#pragma mark -

//========== write =============================================================
//
// Purpose:		Writes out the MPD submodel, wrapped in the MPD file commands.
//
//==============================================================================
- (NSString *) write{
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
}

//========== writeModel =============================================================
//
// Purpose:		Writes out the submodel, without the MPD file commands.
//
//==============================================================================
- (NSString *) writeModel{
	return [super write];
}

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
	return [self modelName];
}


//========== inspectorClassName ================================================
//
// Purpose:		Returns the name of the class used to inspect this one.
//
//==============================================================================
- (NSString *) inspectorClassName{
	return @"InspectionMPDModel";
}


#pragma mark -
#pragma mark ACCESSORS
#pragma mark -

//========== modelName =========================================================
//
// Purpose:		Retuns the name for this MPD file. The MPD name functions as 
//				the part name to describe the entire submodel.
//
//==============================================================================
- (NSString *)modelName{
	return modelName;
}


//========== setModelName: =====================================================
//
// Purpose:		Updates the name for this MPD file. The MPD name functions as 
//				the part name to describe the entire submodel.
//
//==============================================================================
- (void) setModelName:(NSString *)newModelName{
	[newModelName retain];
	[modelName release];
	
	modelName = newModelName;
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
	
	[[undoManager prepareWithInvocationTarget:self] setModelName:[self modelName]];
}


#pragma mark -
#pragma mark DESTRUCTOR
#pragma mark -

//========== dealloc ===========================================================
//
// Purpose:		Time to send the cows home.
//
//==============================================================================
- (void) dealloc {
	[modelName	release];

	[super dealloc];
}//end dealloc


@end

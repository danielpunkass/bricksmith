//==============================================================================
//
// File:		LDrawFile.h
//
// Purpose:		Represents an LDraw file, composed of one or more models.
//				In Bricksmith, each file is interpreted as a Multi-Part Document
//				having multiple submodels. Only LDrawMPDModels can be contained 
//				in the file's subdirective array. However, when the document is 
//				written out, the MPD commands are stripped if there is only 
//				one model in the file.
//
//  Created by Allen Smith on 2/19/05.
//  Copyright (c) 2005. All rights reserved.
//==============================================================================
#import "LDrawFile.h"

#import "LDrawMPDModel.h"
#import "MacLDraw.h"
#import "StringCategory.h"


@implementation LDrawFile

#pragma mark -
#pragma mark INITIALIZATION
#pragma mark -

//========== newFile ===========================================================
//
// Purpose:		Creates a new LDraw document ready for editing. It should 
//				include one submodel with one step inside it.
//
//==============================================================================
+ (LDrawFile *) newFile {
	return [[[LDrawFile alloc] initNew] autorelease];
}


//========== fileFromContentsOfFile: ===========================================
//
// Purpose:		Reads a file from the specified path. 
//
//==============================================================================
+ (LDrawFile *) fileFromContentsOfFile:(NSString *)path {
	NSString	*fileContents	= [NSString stringWithContentsOfFile:path];
	LDrawFile	*parsedFile		= nil;
	if(fileContents != nil)
		parsedFile = [LDrawFile parseFromFileContents:fileContents];
	return parsedFile;
}


//========== parseFromFileContents: ============================================
//
// Purpose:		Reads a file out of the raw file contents. 
//
//==============================================================================
+ (LDrawFile *) parseFromFileContents:(NSString *) fileContents
{
	LDrawFile	*newFile	= [[LDrawFile alloc] init];
	NSArray		*lines		= [fileContents separateByLine];
	NSArray		*models		= [LDrawFile parseModelsFromLines:lines];
	int			 counter;
	
	//Initialize the list of models.
	for(counter = 0; counter < [models count]; counter++)
		[newFile addSubmodel:[models objectAtIndex:counter]];
	
	if([models count] > 0)
		[newFile setActiveModel:[models objectAtIndex:0]];
	
	return newFile;
}

//========== parseModelsFromLines ==============================================
//
// Purpose:		Returns an array of MPD models culled out from the array of 
//				lines given in linesFromFile. If linesFromFile contains a single 
//				non-MPD model, it will be wrapped in an MPD model.
//
//==============================================================================
+ (NSArray *) parseModelsFromLines:(NSArray *) linesFromFile
{
	NSMutableArray	*models = [NSMutableArray array]; //array of parsed MPD models
	NSMutableArray	*currentModelLines = [NSMutableArray array]; //lines to parse into a model.
	LDrawMPDModel	*newModel; //the parsed result.
	
	int				 numberLines = [linesFromFile count];
	NSString		*currentLine;
	int				 counter;
	
	//Search through all the lines in the file, and separate them out into 
	// submodels.
	for(counter = 0; counter < numberLines; counter++){
		currentLine = [linesFromFile objectAtIndex:counter];
		if([currentLine hasPrefix:LDRAW_MPD_FILE_START_MARKER] == NO){
			//still part of the previous model.
			[currentModelLines addObject:currentLine];
		}
		else{
			//We did find a 0 FILE command; start a new model.
			// But watch out; the first line in an MPD file is 0 FILE, and we 
			// don't want to add in an empty model. So we check to see we have 
			// actually accumulated lines for the model first.
			if([currentModelLines count] > 0){
				//we have encountered a new submodel.
				// Parse the old submodel, then start collecting lines for the 
				// new one.
				newModel = [LDrawMPDModel modelWithLines:currentModelLines];
				[models addObject:newModel];
				
			}
			//Start collecting new lines.
			currentModelLines = [NSMutableArray array];
			[currentModelLines addObject:currentLine];
		}
	}
	
	//Add in the working model.
	if([currentModelLines count] > 0){
		newModel = [LDrawMPDModel modelWithLines:currentModelLines];
		[models addObject:newModel];
	}
	
	return models;

}//end parseModelsFromLines


//========== init ==============================================================
//
// Purpose:		Creates a new file with absolutely nothing in it.
//
//==============================================================================
- (id) init {
	self = [super init]; //initializes an empty list of subdirectives--in this 
						// case, the models in the file.

	activeModel = nil;
	
	return self;
}


//========== initNew ===========================================================
//
// Purpose:		Creates a new MPD file with one model.
//
//==============================================================================
- (id) initNew {

	//Create a completely blank file.
	[self init];
	
	//Fill it with one empty model.
	LDrawMPDModel *firstModel = [LDrawMPDModel newModel];
	[self addSubmodel:firstModel];
	
	[self setActiveModel:firstModel];
	
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
	
	//We don't encode the active model; it is just assumed to be the first 
	// model each time the file is created.
	LDrawMPDModel *firstModel = [[self submodels] objectAtIndex:0];
	[self setActiveModel:firstModel];
	
	return self;
}


//========== copyWithZone: =====================================================
//
// Purpose:		Returns a duplicate of this file.
//
//==============================================================================
- (id) copyWithZone:(NSZone *)zone {

	LDrawFile	*copiedFile			= (LDrawFile *)[super copyWithZone:zone];
	int			 indexOfActiveModel	= [self indexOfDirective:self->activeModel];
	id			 copiedActiveModel	= [[copiedFile subdirectives] objectAtIndex:indexOfActiveModel];
	
	[copiedFile setActiveModel:copiedActiveModel];
	
	return copiedFile;
}


#pragma mark -
#pragma mark DIRECTIVES
#pragma mark -

//========== draw ==============================================================
//
// Purpose:		Draw only the active model. The other submodels in an MPD file 
//				are only meant to be seen when they are part of the active 
//				submodel.
//
//==============================================================================
- (void) draw:(unsigned int) optionsMask parentColor:(GLfloat *)parentColor{
	[activeModel draw:optionsMask parentColor:parentColor];
}

//========== write =============================================================
//
// Purpose:		Write out all the submodels sequentially.
//
//==============================================================================
- (NSString *) write{
	NSMutableString	*written		= [NSMutableString string];
	NSString		*CRLF			= [NSString CRLF];
	LDrawMPDModel	*currentModel	= nil;
	NSArray			*modelsInFile	= [self subdirectives];
	int				 numberModels	= [modelsInFile count];
	int				 counter;
	
	//If there is only one submodel, this hardly qualifies as an MPD document.
	// So write out the single model without the MPD FILE/NOFILE wrapper.
	if(numberModels == 1){
		currentModel = [modelsInFile objectAtIndex:0];
		//Write out the model, without MPD wrappers.
		[written appendString:[currentModel writeModel]];
	}
	else{
		//Write out each MPD submodel, one after another.
		for(counter = 0; counter < numberModels; counter++){
			currentModel = [modelsInFile objectAtIndex:counter];
			[written appendString:[currentModel write]];
			[written appendString:CRLF];
		}
	}
	
	//Trim off any final newline characters.
	return [written stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}


#pragma mark -
#pragma mark ACCESSORS
#pragma mark -


//========== addSubmodel: ======================================================
//
// Purpose:		Adds a new submodel to the file. This method only accepts MPD 
//				models, because adding additional submodels is meaningless 
//				outside of MPD models.
//
//==============================================================================
- (void) addSubmodel:(LDrawMPDModel *)newSubmodel {
	[self insertDirective:newSubmodel atIndex:[[self subdirectives] count]];
}//end addSubmodel:


//========== modelNames ========================================================
//
// Purpose:		Returns the the names of all the submodels in the file.
//
//==============================================================================
- (NSArray *) modelNames {
	NSArray			*submodels		= [self subdirectives];
	int				 numberModels	= [submodels count];
	LDrawMPDModel	*currentModel	= nil;
	NSMutableArray	*modelNames		= [NSMutableArray array];
	int				 counter		= 0;
	
	//Look through the models and see if we find one.
	for(counter = 0; counter < numberModels; counter++){
		currentModel = [submodels objectAtIndex:counter];
		[modelNames addObject:[currentModel modelName]];
	}
	
	return modelNames;
}//end modelNames


//========== modelWithName: ====================================================
//
// Purpose:		Returns the submodel with the given name, or nil if one couldn't 
//				be found.
//
//==============================================================================
- (LDrawMPDModel *) modelWithName:(NSString *)soughtName {
	NSArray			*submodels		= [self subdirectives];
	int				 numberModels	= [submodels count];
	LDrawMPDModel	*currentModel	= nil;
	LDrawMPDModel	*foundModel		= nil;
	int				 counter		= 0;
	
	//Look through the models and see if we find one.
	for(counter = 0; counter < numberModels; counter++){
		currentModel = [submodels objectAtIndex:counter];
		//remember, we standardized on lower-case names for searching.
		if([[currentModel modelName] caseInsensitiveCompare:soughtName] == NSOrderedSame) {
			foundModel = currentModel;
			break;
		}
	}
	
	return foundModel;
}

//========== submodels =========================================================
//
// Purpose:		Returns an array of the LDrawModels (or more likely, the 
//				LDrawMPDModels) which constitute this file.
//
//==============================================================================
- (NSArray *) submodels{
	return [self subdirectives];
}


//========== activeModel =======================================================
//
// Purpose:		Returns the name of the currently-active model in the file.
//
//==============================================================================
- (LDrawMPDModel *) activeModel{
	return activeModel;
}//end activeModel


//========== setActiveModel: ===================================================
//
// Purpose:		Sets newModel to be the currently-active model in the file. 
//				The active model is the only one drawn.
//
//==============================================================================
- (void) setActiveModel:(LDrawMPDModel *)newModel{
	
	if([[self subdirectives] containsObject:newModel]){
		//Don't bother doing anything if we aren't really changing models.
		if(newModel != activeModel){
			NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
			
			[newModel retain];
			[activeModel release];
			
			//Update the active model and note that something happened.
			activeModel = newModel;
			[notificationCenter postNotificationName:LDrawFileActiveModelDidChangeNotification
											  object:self];
		}
	}
	else if (newModel == nil){
		[activeModel release];//why are we retaining?!
		activeModel = nil;
	}
	else
		NSLog(@"Attempted to set the active model to one which is not in the file!");
}//end setActiveModel


//========== setEnclosingDirective: ============================================
//
// Purpose:		In other containers, this method would set the object which 
//				encloses this one. LDrawFiles, however, are intended to be at 
//				the root of the LDraw container hierarchy, and thus calling this 
//				method should have no effect.
//
//==============================================================================
- (void) setEnclosingDirective:(LDrawContainer *)newParent{
	// Do Nothing.
}


//========== setEnclosingDirective: ============================================
//
// Purpose:		In other containers, this method would set the object which 
//				encloses this one. LDrawFiles, however, are intended to be at 
//				the root of the LDraw container hierarchy, and thus calling this 
//				method should have no effect.
//
//==============================================================================
- (void) removeDirective:(LDrawDirective *)doomedDirective {
	BOOL removedActiveModel = NO;
	
	if(doomedDirective == self->activeModel)
		removedActiveModel = YES;
		
	[super removeDirective:doomedDirective];
	
	if(removedActiveModel == YES) {
		if([[self submodels] count] > 0)
			[self setActiveModel:[[self submodels] objectAtIndex:0]];
		else
			[self setActiveModel:nil]; //this is probably not a good thing.
	}
	
}

#pragma mark -
#pragma mark UTILITIES
#pragma mark -

//========== boundingBox3 ======================================================
//
// Purpose:		Returns the minimum and maximum points of the box which 
//				perfectly contains the part of this file being displayed.
//
//==============================================================================
- (Box3) boundingBox3 {
	return [[self activeModel] boundingBox3];
}


//========== optimize ==========================================================
//
// Purpose:		Arranges the directives in such a way that the file will be 
//				drawn faster. This method should *never* be called on files 
//				which the user has created himself, since it reorganizes the 
//				file contents. It is intended only for parts read from the part  
//				library.
//
//==============================================================================
- (void) optimize {
	LDrawMPDModel	*currentModel	= nil;
	NSArray			*modelsInFile	= [self subdirectives];
	int				 numberModels	= [modelsInFile count];
	int				 counter;
	
	//Write out each MPD submodel, one after another.
	for(counter = 0; counter < numberModels; counter++){
		currentModel = [modelsInFile objectAtIndex:counter];
		[currentModel optimize];
	}

}


//========== setNeedsDisplay ===================================================
//
// Purpose:		A file can certainly be displayed in multiple views, and we 
//				don't really care to find out which ones here. So we just post 
//				a notification, and anyone can pick that up.
//
//==============================================================================
- (void) setNeedsDisplay {
	[[NSNotificationCenter defaultCenter]
			postNotificationName:LDrawFileDidChangeNotification
						  object:self];
}


#pragma mark -
#pragma mark DESTRUCTOR
#pragma mark -

//========== dealloc ===========================================================
//
// Purpose:		Takin' care o' business.
//
//==============================================================================
- (void) dealloc {
	[activeModel release];
	
	[super dealloc];
}


@end

//==============================================================================
//
// File:		LDrawModel.h
//
// Purpose:		Represents a collection of Lego bricks that form a single model.
//
//				Bricksmith imposes an arbitrary requirement that a model be 
//				composed of a series of steps. Each model must have at least one 
//				step in it, and only LDrawSteps can be put into the model's 
//				subdirective array. Each LDraw model contains at least one step 
//				even if it contains no 0 STEP commands, since the final step in 
//				the model is not required to have step marker. 
//
//  Created by Allen Smith on 2/19/05.
//  Copyright (c) 2005. All rights reserved.
//==============================================================================
#import "LDrawModel.h"

#import <string.h>
#import <AddressBook/AddressBook.h>

#import "ColorLibrary.h"
#import "LDrawConditionalLine.h"
#import "LDrawFile.h"
#import "LDrawLine.h"
#import "LDrawQuadrilateral.h"
#import "LDrawStep.h"
#import "LDrawTriangle.h"
#import "LDrawUtilities.h"
#import "MacLDraw.h"
#import "StringCategory.h"


@implementation LDrawModel


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
	LDrawModel *newModel = [[LDrawModel alloc] initNew];
	
	return [newModel autorelease];
	
}//end newModel


//---------- modelWithLines: -----------------------------------------[static]--
//
// Purpose:		Creates a new model file based on the lines from a file. These 
//				lines of strings should only describe one model, not multiple 
//				ones. 
//
//------------------------------------------------------------------------------
+ (id) modelWithLines:(NSArray *)lines
{
	LDrawModel *newModel = [[LDrawModel alloc] initWithLines:lines];
	
	return [newModel autorelease];
	
}//end modelWithLines:


//========== init ==============================================================
//
// Purpose:		Creates a new, completely blank model file.
//
//==============================================================================
- (id) init
{
	self = [super init];
	
	self->colorLibrary	= [[ColorLibrary alloc] init];
	[self setModelDescription:@""];
	[self setFileName:@""];
	[self setAuthor:@""];
	[self setLDrawRepositoryStatus:LDrawUnofficialModel];
	
	[self setStepDisplay:NO];
	
	return self;
	
}//end init


//========== initNew ===========================================================
//
// Purpose:		Creates a new model file ready for editing, with one step.
//
//==============================================================================
- (id) initNew
{
	//First, get a nice blank model.
	self = [self init];
	
	//Then fill it up with useful initial attributes
	[self setModelDescription:NSLocalizedString(@"UntitledModel", nil)];
	[self setFileName:@""];
	
	//Create the author name by looking up the name from the system.
	ABPerson *userInfo = [[ABAddressBook sharedAddressBook] me];
	NSString *firstName = [userInfo valueForProperty:kABFirstNameProperty];
	NSString *lastName  = [userInfo valueForProperty:kABLastNameProperty];
	if([firstName length] > 0 && [lastName length] > 0)
	{
		[self setAuthor:[NSString stringWithFormat:@"%@ %@", firstName, lastName]];
	}
	
	//Need to create a blank step.
	[self addStep];
	
	return self;
	
}//end initNew

//========== initWithLines: ====================================================
//
// Purpose:		Creates a new model file based on the lines from a file.
//				These lines of strings should only describe one model, not 
//				multiple ones.
//
//				This method divides the model into steps. A step may be ended 
//				by: 
//					* a 0 STEP line
//					* a 0 ROTSTEP line
//					* the end of the file
//
//				A STEP or ROTSTEP command is part of the step they end, so they 
//				are the last line IN the step. 
//
//				The final step marker is optional. Thus a file that has no step 
//				markers still has one step. 
//
//==============================================================================
- (id) initWithLines:(NSArray *)lines
{
	//Start with a nice blank model.
	self = [self init];
	
	//Try and get the header out of the file. If it's there, the lines returned 
	// will not contain it.
	lines = [self parseHeaderFromLines:lines];
	
	// Parse out steps. Each time we run into a new 0 STEP command, we finish 
	// the current step. 
	NSMutableArray	*currentStepLines	= [NSMutableArray array];
	LDrawStep		*newStep			= nil;
	NSString		*currentLine		= nil;
	int				 numberLines		= [lines count];
	int				 counter			= 0;
	
	for(counter = 0; counter < numberLines; counter++)
	{
		currentLine = [lines objectAtIndex:counter];
		[currentStepLines addObject:currentLine];
		
		// Check for the end of the step.
		if(		[currentLine hasPrefix:LDRAW_STEP ] == YES
		   ||	[currentLine hasPrefix:LDRAW_ROTATION_STEP] == YES 
		   ||	counter == (numberLines - 1) ) // test for end of file.
		{
			// We've hit the end of the step. Time to parse it and add it to the 
			// model. 
			newStep = [LDrawStep stepWithLines:currentStepLines];
			[self addStep:newStep];
			
			// Start a new step if we still have lines left.
			if(counter < (numberLines - 1))
				currentStepLines = [NSMutableArray array];
		}
	}
	
	return self;
	
}//end initWithLines:


//========== initWithCoder: ====================================================
//
// Purpose:		Reads a representation of this object from the given coder,
//				which is assumed to always be a keyed decoder. This allows us to 
//				read and write LDraw objects as NSData.
//
//==============================================================================
- (id) initWithCoder:(NSCoder *)decoder
{
	self = [super initWithCoder:decoder];
	
	modelDescription	= [[decoder decodeObjectForKey:@"modelDescription"] retain];
	fileName			= [[decoder decodeObjectForKey:@"fileName"] retain];
	author				= [[decoder decodeObjectForKey:@"author"] retain];
	ldrawDotOrgStatus	= [decoder decodeIntForKey:@"ldrawDotOrgStatus"];
	
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
	
	[encoder encodeObject:modelDescription	forKey:@"modelDescription"];
	[encoder encodeObject:fileName			forKey:@"fileName"];
	[encoder encodeObject:author			forKey:@"author"];
	[encoder encodeInt:ldrawDotOrgStatus	forKey:@"ldrawDotOrgStatus"];
	
}//end encodeWithCoder:


//========== copyWithZone: =====================================================
//
// Purpose:		Returns a duplicate of this file.
//
//==============================================================================
- (id) copyWithZone:(NSZone *)zone
{
	LDrawModel *copied = (LDrawModel *)[super copyWithZone:zone];
	
	[copied setModelDescription:[self modelDescription]];
	[copied setFileName:[self fileName]];
	[copied setAuthor:[self author]];
	[copied setLDrawRepositoryStatus:[self ldrawRepositoryStatus]];
	
	copied->colorLibrary = [[ColorLibrary alloc] init]; // just make a new one. It will get current colors on the next draw.
	[copied setStepDisplay:[self stepDisplay]];
	[copied setMaximumStepDisplayed:[self maximumStepDisplayed]];
	
	//I don't think we care about the cached bounds.
	
	return copied;
	
}//end copyWithZone:


#pragma mark -
#pragma mark DIRECTIVES
#pragma mark -

//========== draw:parentColor: =================================================
//
// Purpose:		Simply draw all the steps; they will worry about drawing all 
//				their constituents.
//
//==============================================================================
- (void) draw:(unsigned int) optionsMask parentColor:(GLfloat *)parentColor
{
	NSArray			*steps				= [self subdirectives];
	int				 maxIndex			= [self maxStepIndexToOutput];
	LDrawStep		*currentDirective	= nil;
	int				 counter			= 0;
	
	// Draw all the steps in the model
	for(counter = 0; counter <= maxIndex; counter++)
	{
		currentDirective = [steps objectAtIndex:counter];
		[currentDirective draw:optionsMask parentColor:parentColor];
	}
	
	// Draw Drag-and-Drop pieces if we've got 'em.
	if(self->draggingDirectives != nil)
		[self->draggingDirectives draw:optionsMask parentColor:parentColor];
		
}//end draw:parentColor:


//========== write =============================================================
//
// Purpose:		Writes out the MPD submodel, wrapped in the MPD file commands.
//
//==============================================================================
- (NSString *) write
{
	NSString		*CRLF			= [NSString CRLF]; //we need a DOS line-end marker, because 
														//LDraw is predominantly DOS-based.
	NSMutableString	*written		= [NSMutableString string];
	NSArray			*steps			= [self subdirectives];
	int				 numberSteps	= [steps count];
	LDrawStep		*currentStep	= nil;
	NSString		*stepOutput		= nil;
	int				 counter		= 0;
	
	//Write out the file header in all of its irritating glory.
	[written appendFormat:@"0 %@%@", [self modelDescription], CRLF];
	[written appendFormat:@"0 %@ %@%@", LDRAW_HEADER_NAME, [self fileName], CRLF];
	[written appendFormat:@"0 %@ %@%@", LDRAW_HEADER_AUTHOR, [self author], CRLF];
	if([self ldrawRepositoryStatus] == LDrawOfficialModel)
		[written appendFormat:@"0 %@%@", LDRAW_HEADER_OFFICIAL_MODEL, CRLF];
	else
		[written appendFormat:@"0 %@%@", LDRAW_HEADER_UNOFFICIAL_MODEL, CRLF];
		
	
	//Write out all the steps in the file.
	for(counter = 0; counter < numberSteps; counter++)
	{
		currentStep = [steps objectAtIndex:counter];
		
		//Skip the 0 STEP command for the last step; it is implied.
		if(counter == numberSteps - 1)
			stepOutput = [currentStep writeWithStepCommand:NO];
		else
			stepOutput = [currentStep write];
		
		[written appendFormat:@"%@%@", stepOutput, CRLF];
	}
	
	//Now remove that last CRLF.
	[written deleteCharactersInRange:NSMakeRange([written length] - [CRLF length], [CRLF length])];
	
	return written;

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
- (NSString *) browsingDescription
{
	return [self modelDescription];
	
}//end browsingDescription


//========== iconName ==========================================================
//
// Purpose:		Returns the name of image file used to display this kind of 
//				object, or nil if there is no icon.
//
//==============================================================================
- (NSString *) iconName
{
	return @"Document";
	
}//end iconName


#pragma mark -
#pragma mark ACCESSORS
#pragma mark -

//========== boundingBox3 ======================================================
//
// Purpose:		Returns the minimum and maximum points of the box which 
//				perfectly contains this object.
//
//				We optimize this calculation on models whose dimensions are 
//				known to be constant--parts from the library, for instance.
//
//==============================================================================
- (Box3) boundingBox3
{
	Box3 totalBounds	= InvalidBox;
	Box3 draggingBounds	= InvalidBox;

	if(self->cachedBounds != NULL)
		totalBounds = *cachedBounds;
	else
	{
		// Find the bounding box of all the normal members of this model
		totalBounds = [super boundingBox3];
		
		// If drag-and-drop objects are present, add them into the bounds.
		if(self->draggingDirectives != nil)
		{
			draggingBounds	= [LDrawUtilities boundingBox3ForDirectives:[self->draggingDirectives subdirectives]];
			totalBounds		= V3UnionBox(draggingBounds, totalBounds);
		}
	}
	
	return totalBounds;
		
}//end boundingBox3


//========== category ==========================================================
//
// Purpose:		Returns the category to which this model belongs. This is 
//				determined from the description field, which is the first line 
//				of the file for non-MPD documents. For instance:
//
//				0 Brick  2 x  4
//
//				This part would be in the category "Brick", and has the 
//				description "Brick  2 x  4".
//
//==============================================================================
- (NSString *) category
{
	NSString	*category	= nil;
	NSRange		 firstSpace;	//range of the category string in the first line.
	
	//The category name is the first word in the description.
	firstSpace = [(self->modelDescription) rangeOfString:@" "];
	if(firstSpace.location != NSNotFound)
		category = [modelDescription substringToIndex:firstSpace.location];
	else
		category = [NSString stringWithString:modelDescription];
	
	//Clean category name of any weird notational marks
	if([category hasPrefix:@"_"] || [category hasPrefix:@"~"])
		category = [category substringFromIndex:1];
		
	return category;
	
}//end category


//========== colorLibrary ======================================================
//
// Purpose:		Returns the color library object which accumulates the !COLOURS 
//				defined locally within the model. 
//
// Notes:		According to the LDraw color spec, local colors having scoping: 
//				they become active at the point of definition and fall out of 
//				scope at the end of the model. As a convenience in Bricksmith, 
//				the color library will still contain all the local model colors 
//				after a draw is complete--the library will not be purged just 
//				for scoping's sake. It may be purged at the beginning of 
//				drawing, however. 
//
//==============================================================================
- (ColorLibrary *) colorLibrary
{
	return self->colorLibrary;
	
}//end colorLibrary


//========== draggingDirectives ================================================
//
// Purpose:		Returns the objects that are currently being displayed as part 
//			    of drag-and-drop. 
//
//==============================================================================
- (NSArray *) draggingDirectives
{
	return [self->draggingDirectives subdirectives];
	
}//end draggingDirectives


//========== enclosingFile =====================================================
//
// Purpose:		Returns the file in which this model is stored.
//
//==============================================================================
- (LDrawFile *) enclosingFile
{
	return (LDrawFile *)[self enclosingDirective];
	
}//end enclosingFile


//========== modelDescription ==================================================
//
// Purpose:		Returns the model description, which is the first line of the 
//				model. (i.e., Brick 2 x 4)
//
//==============================================================================
- (NSString *)modelDescription
{
	return modelDescription;
	
}//end modelDescription


//========== fileName ==========================================================
//
// Purpose:		Returns the name the model is ostensibly saved under in the 
//				file system.
//
//==============================================================================
- (NSString *)fileName
{
	return fileName;
	
}//end fileName


//========== author ============================================================
//
// Purpose:		Returns the person who created the document.
//
//==============================================================================
- (NSString *)author
{
	return author;
	
}//end author


//========== ldrawRepositoryStatus =============================================
//
// Purpose:		Returns whether or not this is an official LDraw.org model.
//
//==============================================================================
- (LDrawDotOrgModelStatusT) ldrawRepositoryStatus
{
	return ldrawDotOrgStatus;
	
}//end ldrawRepositoryStatus


//========== maximumStepDisplayed ==============================================
//
// Purpose:		Returns the index of the last step drawn. The value only has 
//				meaning if the model is in step-display mode.
//
//==============================================================================
- (int) maximumStepDisplayed
{
	return self->currentStepDisplayed;
	
}//end maximumStepDisplayed


//========== stepDisplay =======================================================
//
// Purpose:		Returns YES if the receiver only displays the steps through 
//				the index of the currentStepDisplayed instance variable.
//
//==============================================================================
- (BOOL) stepDisplay
{
	return self->stepDisplayActive;
	
}//end stepDisplay


//========== steps =============================================================
//
// Purpose:		Returns the steps which constitute this model.
//
//==============================================================================
- (NSArray *) steps
{
	return [self subdirectives];
	
}//end steps


//========== visibleStep =======================================================
//
// Purpose:		Returns the last step which would be drawn if this model were 
//				drawn right now.
//
//==============================================================================
- (LDrawStep *) visibleStep
{
	NSArray		*steps		= [self steps];
	LDrawStep	*lastStep	= nil;
	
	if([self stepDisplay] == YES)
		lastStep = [steps objectAtIndex:[self maxStepIndexToOutput]];
	else
		lastStep = [steps lastObject];
	
	return lastStep;
	
}//end visibleStep


#pragma mark -

//========== setDraggingDirectives: ============================================
//
// Purpose:		Sets the parts which are being manipulated in the model via 
//			    drag-and-drop. 
//
//==============================================================================
- (void) setDraggingDirectives:(NSArray *)directives
{
	LDrawStep		*dragStep			= nil;
	LDrawDirective	*currentDirective	= nil;
	int				 counter			= 0;
	
	// When we get sent nil directives, nil out the drag step.
	if(directives != nil)
	{
		dragStep	= [LDrawStep emptyStep];
		
		// The law of Bricksmith is that all parts in a model must be enclosed in a 
		// step. Resistance is futile.
		for(counter = 0; counter < [directives count]; counter++)
		{
			currentDirective = [directives objectAtIndex:counter];
			[dragStep addDirective:currentDirective];
		}
		
		// Tell the element that it lives in us now. This is important for submodel 
		// references being dragged; without it, they have no way of resolving their 
		// part reference, and thus can't draw during their drag. 
		[dragStep setEnclosingDirective:self];
	}
	
	[dragStep retain];
	[self->draggingDirectives release];
	
	self->draggingDirectives = dragStep;
	
}//end setDraggingDirectives:


//========== setModelDescription: ==============================================
//
// Purpose:		Sets a new model description.
//
//==============================================================================
- (void) setModelDescription:(NSString *)newDescription
{
	[newDescription retain];
	[modelDescription release];
	
	modelDescription = newDescription;
	
}//end setModelDescription:


//========== setFileName: ======================================================
//
// Purpose:		Sets the name the model is ostensibly saved under in the 
//				file system. This may take on a rather different meaning in 
//				multi-part documents. It also has no real connection with the 
//				actual filesystem name.
//
//==============================================================================
- (void) setFileName:(NSString *)newName
{
	[newName retain];
	[fileName release];
	
	fileName = newName;
	
}//end setFileName:


//========== setAuthor: ========================================================
//
// Purpose:		Changes the name of the person who created the model.
//
//==============================================================================
- (void) setAuthor:(NSString *)newAuthor
{
	[newAuthor retain];
	[author release];
	
	author = newAuthor;
	
}//end setAuthor:


//========== setLDrawRepositoryStatus: =========================================
//
// Purpose:		Changes whether or not this is an official ldraw.org model.
//
//==============================================================================
- (void) setLDrawRepositoryStatus:(LDrawDotOrgModelStatusT) newStatus
{
	ldrawDotOrgStatus = newStatus;
	
}//end setLDrawRepositoryStatus:


//========== setMaximumStepDisplayed ===========================================
//
// Purpose:		Sets the index of the last step drawn. If the model is not 
//				currently in step-display mode, this call will automatically set 
//				it up to be. However, this method does not cause the received to 
//				be redisplayed.
//
//==============================================================================
- (void) setMaximumStepDisplayed:(int)stepIndex
{
	//Need to check and make sure this step number is not overflowing the bounds.
	int maximumIndex = [[self steps] count]-1;
	
	if(stepIndex > maximumIndex || stepIndex < 0)
		[NSException raise:NSRangeException format:@"index (%d) beyond maximum step index %d", stepIndex, maximumIndex];
	else
	{
		self->currentStepDisplayed = stepIndex;
		[self setStepDisplay:YES];
	}
	
}//end setMaximumStepDisplayed:


//========== setStepDisplay ====================================================
//
// Purpose:		Sets whether the receiver only displays the steps through 
//				the index of the currentStepDisplayed instance variable.
//
//==============================================================================
- (void) setStepDisplay:(BOOL)flag
{
	self->stepDisplayActive = flag;
	
}//end setStepDisplay:


#pragma mark -
#pragma mark ACTIONS
#pragma mark -

//========== addStep ===========================================================
//
// Purpose:		Creates a new blank step at the end of the model. Returns the 
//				new step created.
//
//==============================================================================
- (LDrawStep *) addStep
{
	LDrawStep *newStep = [LDrawStep emptyStep];
	
	[self addDirective:newStep]; //adds the step and tells it who it belongs to.
	
	return newStep;
	
}//end addStep


//========== addStep: ==========================================================
//
// Purpose:		Adds newStep at the end of the model.
//
//==============================================================================
- (void) addStep:(LDrawStep *)newStep
{
	[self addDirective:newStep];
	
}//end addStep:


//========== makeStepVisible: ==================================================
//
// Purpose:		Guarantees that the given step is visible in this model.
//
//==============================================================================
- (void) makeStepVisible:(LDrawStep *)step
{
	int stepIndex = [self indexOfDirective:step];
	
	if(		stepIndex != NSNotFound
		&&	stepIndex > [self maxStepIndexToOutput])
	{
		[self setMaximumStepDisplayed:stepIndex];
	}
}//end makeStepVisible


#pragma mark -
#pragma mark UTILITIES
#pragma mark -

//========== maxStepIndexToOutput ==============================================
//
// Purpose:		Returns the index of the last step which should be displayed,
//				or -1 if there are no steps to display. (The latter 
//				case should never happen.)
//
//==============================================================================
- (int) maxStepIndexToOutput
{
	NSArray	*steps		= [self subdirectives];
	int		 maxStep	= 0;
	
	//If step display is active, we want to display only as far as the specified 
	// step, or the maximum step if the one specified exceeds the number of steps.
	if(self->stepDisplayActive == YES)
		maxStep = MIN( [steps count] -1 , //subtract one to get last step index in model.
					   self->currentStepDisplayed);
	else
		maxStep = [steps count] - 1;
	
	return maxStep;
	
}//end maxStepIndexToOutput


//========== numberElements ====================================================
//
// Purpose:		Returns the number of elements found in this model. Currently 
//				this does not recurse into MPD submodels which have been 
//				included.
//
//==============================================================================
- (int) numberElements
{
	NSArray		*steps			= [self steps];
	LDrawStep	*currentStep	= nil;
	int			 numberElements	= 0;
	int			 counter		= 0;
	
	for(counter = 0; counter < [steps count]; counter++){
		currentStep = [steps objectAtIndex:counter];
		numberElements += [[currentStep subdirectives] count];
	}
	
	return numberElements;
	
}//end numberElements


//========== optimize ==========================================================
//
// Purpose:		Arranges the directives in such a way that the file will be 
//				drawn faster. This method should *never* be called on files 
//				which the user has created himself, since it reorganizes the 
//				file contents. It is intended only for parts read from the part  
//				library.
//
//				To optimize, we separate all the directives out by the type:
//				all triangles go in a step, all quadrilaterals go in their own 
//				step, etc.
//
//				Then when drawing, we need not call glBegin() each time.
//
//==============================================================================
- (void) optimize
{
	NSArray			*steps			= [self subdirectives];
	LDrawStep		*firstStep		= 0;
	NSArray			*directives		= nil;
	LDrawDirective	*currentObject	= 0;
	
	LDrawStep		*lines			= [LDrawStep emptyStepWithFlavor:LDrawStepLines];
	LDrawStep		*triangles		= [LDrawStep emptyStepWithFlavor:LDrawStepTriangles];
	LDrawStep		*quadrilaterals	= [LDrawStep emptyStepWithFlavor:LDrawStepQuadrilaterals];
	LDrawStep		*everythingElse	= [LDrawStep emptyStepWithFlavor:LDrawStepAnyDirectives];
	
	int				 directiveCount	= 0;
	int				 counter		= 0;
	
	//If there is more than one step in the model, then we shall assume that 
	// it has either a) already been optimized or b) been created by the user.
	// In either case, we don't want to call this method!
	if([steps count] == 1) 
	{
		firstStep		= [steps objectAtIndex:0];
		directives		= [firstStep subdirectives];
		directiveCount	= [directives count];
		
		//Sort out all the different types of directives into their own arrays.
		for(counter = 0; counter < directiveCount; counter++)
		{
			currentObject = [directives objectAtIndex:counter];
			if([currentObject isMemberOfClass:[LDrawLine class]])
				[lines addDirective:currentObject];
			else if([currentObject isKindOfClass:[LDrawTriangle class]])
				[triangles addDirective:currentObject];
			else if([currentObject isKindOfClass:[LDrawQuadrilateral class]])
				[quadrilaterals addDirective:currentObject];
			else if([currentObject isKindOfClass:[LDrawConditionalLine class]]) {
				//Die, miserable directives. Die!
			}
			else
				[everythingElse addDirective:currentObject];
		}
		
		[lines			optimize];
		[triangles		optimize];
		[quadrilaterals	optimize];
		
		//Now that we have everything separated, remove the main step 
		// (it's the one that has the entire model in it) and replace it 
		// with the categorized steps we've created.
		[self removeDirective:firstStep];
		
		if([[lines subdirectives] count] > 0)
			[self addDirective:lines];
		if([[triangles subdirectives] count] > 0)
			[self addDirective:triangles];
		if([[quadrilaterals subdirectives] count] > 0)
			[self addDirective:quadrilaterals];
		if([[everythingElse subdirectives] count] > 0)
			[self addDirective:everythingElse];
			
			
		//Optimizations complete; save some info.
		Box3 bounds = [self boundingBox3];
		self->cachedBounds = (Box3*)malloc( sizeof(Box3) );
		memcpy( cachedBounds, &bounds, sizeof(Box3) );
	}
}//end optimize


//========== parseHeaderFromLines: =============================================
//
// Purpose:		Given lines from an LDraw document, fill in the model header 
//				info. It should be of the following format:
//
//				0 7140 X-Wing Fighter
//				0 Name: main.ldr
//				0 Author: Tim Courtney <tim@zacktron.com>
//				0 LDraw.org Official Model Repository
//				0 http://www.ldraw.org/repository/official/
//
//				Note, however, that this information is *not* required, so it 
//				may not be there. Consequently, the code below is a nightmarish
//				unmaintainable mess.
//
//				Returns the contents of lines minus the lines that constituted 
//				the header.
//
//==============================================================================
- (NSArray *) parseHeaderFromLines:(NSArray *) lines
{
	NSMutableArray	*linesWithoutHeader = [NSMutableArray arrayWithArray:lines];
	NSString		*currentLine		= nil;
	int				 counter			= 0;
	
	@try
	{
		//First line. Should be a description of the model.
		currentLine = [lines objectAtIndex:0];
		if([self line:currentLine isValidForHeader:@""]){
			[self setModelDescription:[currentLine substringFromIndex:2]];
			[linesWithoutHeader removeObjectIdenticalTo:currentLine];
		}
		
		//There are at least three more lines in a valid header.
		// Read the first four lines, and try to get the model info out of 
		// them.
		for(counter = 1; counter < 4; counter++) {
			currentLine = [lines objectAtIndex:counter];
			
			//Second line. Should be file name.
			if([self line:currentLine isValidForHeader:@"Name: "]){
				[self setFileName:[currentLine substringFromIndex:[@"0 Name: " length]]];
				[linesWithoutHeader removeObjectIdenticalTo:currentLine];
			}
			//Third line. Should be author name.
			else if([self line:currentLine isValidForHeader:@"Author: "]){
				[self setAuthor:[currentLine substringFromIndex:[@"0 Author: " length]]];
				[linesWithoutHeader removeObjectIdenticalTo:currentLine];
			}
			//Fourth line. Should be officiality status.
			else if([self line:currentLine isValidForHeader:@""]){
				if([currentLine containsString:@"LDraw.org Official" options:NSCaseInsensitiveSearch])
					[self setLDrawRepositoryStatus:LDrawOfficialModel];
				else
					[self setLDrawRepositoryStatus:LDrawUnofficialModel];
				
				//If the model was flagged as either official or un-official, then this was 
				// part of the header and we delete it. Otherwise, who knows what it is?
				// Just leave it be then.
				if([currentLine containsString:@"official" options:NSCaseInsensitiveSearch])
					[linesWithoutHeader removeObjectIdenticalTo:currentLine];
			}
		}
	}	
	@catch(NSException *exception)
	{
		//Ran out of lines in the file. Oh well. We got what we got.
	}
		
	return linesWithoutHeader;
	
}//end parseHeaderFromLines


//========== line:isValidForHeader: ============================================
//
// Purpose:		Determines if the given line of LDraw is formatted to be the 
//				the specified field in a model header.
//
//==============================================================================
- (BOOL)		line:(NSString *)line
	isValidForHeader:(NSString *)headerKey
{
	BOOL isValid = NO;
	
	if( [line hasPrefix:[NSString stringWithFormat:@"0 %@", headerKey]] )
	{
		isValid = YES;
	}
	else
		isValid = NO;
		
	return isValid;
	
}//end line:isValidForHeader:


//========== registerUndoActions ===============================================
//
// Purpose:		Registers the undo actions that are unique to this subclass, 
//				not to any superclass.
//
//==============================================================================
- (void) registerUndoActions:(NSUndoManager *)undoManager
{
	[super registerUndoActions:undoManager];
	
	[[undoManager prepareWithInvocationTarget:self] setLDrawRepositoryStatus:[self ldrawRepositoryStatus]];
	[[undoManager prepareWithInvocationTarget:self] setAuthor:[self author]];
	[[undoManager prepareWithInvocationTarget:self] setFileName:[self fileName]];
	[[undoManager prepareWithInvocationTarget:self] setModelDescription:[self modelDescription]];
	
	[undoManager setActionName:NSLocalizedString(@"UndoAttributesModel", nil)];
	
}//end registerUndoActions:


#pragma mark -
#pragma mark DESTRUCTOR
#pragma mark -

//========== dealloc ===========================================================
//
// Purpose:		So I go to the pet store to buy a dog. And this guy sells me 
//				this puppy with three heads. Where in the world did he find a 
//				freak like that? So I says, "buddy, I want a normal dog." And 
//				the guy says, "Mister, where you're going, this dog *is* normal.
//				Weird.
//
//==============================================================================
- (void) dealloc
{
	[author				release];
	[colorLibrary		release];
	[fileName			release];
	[modelDescription	release];
	
	if(self->cachedBounds != NULL)
		free(cachedBounds);
	
	[super dealloc];
	
}//end dealloc


@end

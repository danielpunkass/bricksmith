//==============================================================================
//
// File:		LDrawStep.h
//
// Purpose:		Represents a collection of Lego bricks which compose a single 
//				step when constructing a model.
//
//				A step, of course, corresponds to a step in a set of Lego set 
//				instructions.
//
//				The subdirectives which make up a step are a list of 
//				LDrawDirectives including parts, primitives, and meta-commands.
//
//  Created by Allen Smith on 2/20/05.
//  Copyright (c) 2005. All rights reserved.
//==============================================================================
#import "LDrawStep.h"

#import "LDrawModel.h"
#import "LDrawUtilities.h"
#import "StringCategory.h"
#import "MacLDraw.h"


@implementation LDrawStep

#pragma mark -
#pragma mark INITIALIZATION
#pragma mark -

//========== emptyStep =========================================================
//
// Purpose:		Creates a new step ready to be edited, with nothing inside it.
//
//==============================================================================
+ (id) emptyStep {
	LDrawStep *newStep = [[LDrawStep alloc] init];
	
	return [newStep autorelease];
}


//========== emptyStepWithFlavor ===============================================
//
// Purpose:		Creates a new step ready to be edited, and prespecifies that 
//				only directives of the flavorType will be added.
//
//==============================================================================
+ (id) emptyStepWithFlavor:(LDrawStepFlavorT) flavorType {
	LDrawStep *newStep = [[LDrawStep alloc] init];
	[newStep setStepFlavor:flavorType];
	
	return [newStep autorelease];
}


//========== stepWithLines =====================================================
//
// Purpose:		Creates a new step ready to be edited, with nothing inside it.
//
//==============================================================================
+ (LDrawStep *) stepWithLines:(NSArray *)lines{
	LDrawStep		*newStep = [[LDrawStep alloc] init];
	
	NSString		*currentLine;
	NSString		*commandCodeString;
	int				 commandCode;
	Class			 CommandClass;
	id				 newDirective;
	int				 counter;
	
	//Convert each line into a directive, and add it to this step.
	for(counter = 0; counter < [lines count]; counter++){
		currentLine = [lines objectAtIndex:counter];
		if([currentLine length] > 0){
		
			commandCodeString = [LDrawUtilities readNextField:currentLine remainder:NULL];
			//We may need to check for nil here someday.
			commandCode = [commandCodeString intValue];
		
			CommandClass = [LDrawUtilities classForLineType:commandCode];
			
			newDirective = [CommandClass directiveWithString:currentLine];
			if(newDirective != nil)
				[newStep addDirective:newDirective];
		}//end has line data check
	}//end for
	
	return [newStep autorelease];
	
}//end stepWithLines:


//========== init ==============================================================
//
// Purpose:		Creates a new step ready to be edited, with nothing inside it.
//
//==============================================================================
- (id) init {
	[super init];
	
	stepFlavor = LDrawStepAnyDirectives;
	
	return self;
}


//========== copyWithZone: =====================================================
//
// Purpose:		Returns a duplicate of this file.
//
//==============================================================================
- (id) copyWithZone:(NSZone *)zone {
	
	LDrawStep	*copied	= (LDrawStep *)[super copyWithZone:zone];
	
	[copied setStepFlavor:self->stepFlavor];
	
	return copied;
}


#pragma mark -
#pragma mark DIRECTIVES
#pragma mark -

//========== draw ==============================================================
//
// Purpose:		Draw all the commands in the step.
//
//				Certain steps are marked as having been optimized for fast 
//				drawing. Such steps consist entirely of one kind of directive, 
//				so we need call glBegin only once for the entire step.
//
//==============================================================================
- (void) draw:(unsigned int) optionsMask parentColor:(GLfloat *)parentColor
{
	//step display lists are a thing of the past. It's better to display-optimize 
	// the entire part at once rather than six zillion little mini-lists.
	// see other comments in -[LDrawStep optimize]
	if(hasDisplayList == YES)
	{
		if((optionsMask & DRAW_REVERSE_NORMALS) != 0)
			glCallList(self->displayListInvertedNormalsTag);
		else
			glCallList(self->displayListTag);
			
		#if OPTIMIZE_STEPS
			glColor4fv(parentColor);
		#endif
	}
	else
	{
		NSArray			*commandsInStep		= [self subdirectives];
		int				 numberCommands		= [commandsInStep count];
		LDrawDirective	*currentDirective	= nil;
		int				 counter			= 0;
		
		//Check for optimized steps.
		if(stepFlavor == LDrawStepQuadrilaterals)
			glBegin(GL_QUADS);
		else if(stepFlavor == LDrawStepTriangles)
			glBegin(GL_TRIANGLES);
		else if(self->stepFlavor == LDrawStepLines)
			glBegin(GL_LINES);
		
		//If we have any specialized flavor above, then we have already begun 
		// drawing. This little tidbit must be passed on down to the lower reaches.
		if(stepFlavor != LDrawStepAnyDirectives){
			optionsMask |= DRAW_BEGUN;
		}
		
		//Draw each element in the step.
		for(counter = 0; counter < numberCommands; counter++){
			currentDirective = [commandsInStep objectAtIndex:counter];
			[currentDirective draw:optionsMask parentColor:parentColor];
		}
		
		//close drawing if we started it.
		if(stepFlavor != LDrawStepAnyDirectives)
			glEnd();
			
		#if OPTIMIZE_STEPS
			glColor4fv(parentColor);
		#endif
	}

}


//========== write =============================================================
//
// Purpose:		Write out all the commands in the step, prefaced by the line 
//				0 STEP
//
//==============================================================================
- (NSString *) write{
	return [self writeWithStepCommand:YES];
}

//========== writeWithStepCommand: =============================================
//
// Purpose:		Write out all the commands in the step. The output will be 
//				prefaced by the line 0 STEP if explicitStep is true. 
//				The reason this method exists is that we do not want to write 
//				the step command for the very first step in the file. That step 
//				is inferred rather than explicit.
//
//==============================================================================
- (NSString *) writeWithStepCommand:(BOOL) flag{
	
	NSMutableString	*written		= [NSMutableString string];
	NSString		*CRLF			= [NSString CRLF];
	
	NSArray			*commandsInStep = [self subdirectives];
	LDrawDirective	*currentCommand = nil;
	int				 numberCommands	= [commandsInStep count];
	int				 counter;
	
	//Start with 0 STEP
	if(flag == YES)
		[written appendFormat:@"%@%@", LDRAW_STEP, CRLF];
	
	//Write all the subcommands under it.
	for(counter = 0; counter < numberCommands; counter++){
		currentCommand = [commandsInStep objectAtIndex:counter];
		[written appendFormat:@"%@%@", [currentCommand write], CRLF];
	}
	
	//Now remove that last CRLF, if it's there.
	if([written hasSuffix:CRLF]){
		NSRange lastNewline = NSMakeRange([written length] - [CRLF length], [CRLF length]);
		[written deleteCharactersInRange:lastNewline];
	}
	
	return [written stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
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
	LDrawModel	*enclosingModel = [self enclosingModel];
	NSString	*description = nil;
	
	//If there is no parent model, just display the word step. This situtation 
	// would be highly irregular.
	if(enclosingModel == nil)
		description = NSLocalizedString(@"Step", nil);
	
	else{
		//Return the step number.
		NSArray *modelSteps = [enclosingModel steps];
		int		 stepIndex = [modelSteps indexOfObjectIdenticalTo:self];
		
		description = [NSString stringWithFormat:
							NSLocalizedString(@"StepDisplayWithNumber", nil),
							stepIndex + 1] ;
	}
	
	return description;
}//end browsingDescription


#pragma mark -
#pragma mark ACCESSORS
#pragma mark -

//========== addDirective: =====================================================
//
// Purpose:		Inserts the new directive at the end of the step.
//
//==============================================================================
- (void) addDirective:(LDrawDirective *)newDirective
{
	//might want to do some type checking here.
	[super addDirective:newDirective];
}

//========== enclosingModel ====================================================
//
// Purpose:		Returns the model of which this step is a part.
//
//==============================================================================
- (LDrawModel *) enclosingModel
{
	return (LDrawModel *)[self enclosingDirective];
}//end setModel:


//========== setModel: =========================================================
//
// Purpose:		Sets a reference to the model of which this step is a part.
//				Called automatically by -addStep:
//
//==============================================================================
- (void) setModel:(LDrawModel *)enclosingModel
{
	[self setEnclosingDirective:enclosingModel];
}//end setModel:


//========== setStepFlavor: ====================================================
//
// Purpose:		Sets the step flavor, which identifies the types of 
//				LDrawDirectives the step contains. Setting the flavor to a 
//				specific directive type will cause the step to draw its 
//				subdirectives inside one set of glBegin()/glEnd(), rather than 
//				starting a new group for each directive encountered.
//
//==============================================================================
- (void) setStepFlavor:(LDrawStepFlavorT)newFlavor {
	self->stepFlavor = newFlavor;
}


#pragma mark -
#pragma mark OPTIMIZE
#pragma mark -

//========== optimize ==========================================================
//
// Purpose:		Makes this step run faster by compiling its contents into a 
//				display list if possible.
//
// Notes:		This was a misguided optimization. It turns out to be preferable 
//				to simply display-list the entire part at once. Interestingly, 
//				this whole route caused nasty graphical glitches. Each vertex in 
//				the list needs to have a pre-associated color. Optimizing steps 
//				would only work assuming that each display list could be 
//				associated with a color *on the fly.* But we can't do that; the 
//				display list needs to have colors *cooked in.*
//
//				BUT! BUT! Optimizing steps also DRAMATICALLY reduces memory 
//				requirements, which means that huge models are actually usable.
//				So this is back in pending better ideas.
//
//==============================================================================
- (void) optimize
{
#ifdef OPTIMIZE_STEPS
	NSArray			*commandsInStep		= [self subdirectives];
	int				 numberCommands		= [commandsInStep count];
	id				 currentDirective	= nil;
	LDrawColorT		 currentColor		= LDrawColorBogus;
	LDrawColorT		 stepColor			= LDrawColorBogus;
	BOOL			 isColorOptimizable	= YES; //assume YES at first.
	int				 counter			= 0;
	
	//See if everything is the same color.
	for(counter = 0; counter < numberCommands; counter++)
	{
		currentDirective = [commandsInStep objectAtIndex:counter];
		
		if([currentDirective conformsToProtocol:@protocol(LDrawColorable)])
		{
			currentColor = [currentDirective LDrawColor];
			if(stepColor == LDrawColorBogus)
				stepColor = currentColor;
		}
		
		if(currentColor != stepColor) {
			isColorOptimizable = NO;
			break;
		}
		
	}
	
	//Put what we can in a display list. I haven't figured out how to overcome 
	// the hierarchical nature of LDraw with display lists yet, so our options 
	// are really very limited here.
	//
	//Another note: Display list IDs are by default unique to their context. 
	// We want them to be global to the application! Solution: we set up a 
	// shared context in LDrawApplication.
	if(		isColorOptimizable == YES
//		&&	(stepColor == LDrawCurrentColor || stepColor == LDrawEdgeColor)
		&&	numberCommands >= 4 )
	{
		if(stepColor == LDrawEdgeColor)
		{	//create 1 new, empty display list. These are almost certainly 
			// lines, and they don't care about normals.
			self->displayListTag				= glGenLists(1);
			self->displayListInvertedNormalsTag	= displayListTag;
			
			GLfloat glColor[4];
			rgbafForCode(LDrawEdgeColor, glColor);

			glNewList(displayListTag, GL_COMPILE);
				[self draw:DRAW_NO_OPTIONS parentColor:glColor];
			glEndList();
		}
		else
		{
			//Generate two sets of lists: non-inverted and inverted.
			// This way, we can use display lists even with the state-dependent
			// transformation matrix.
			self->displayListTag				= glGenLists(2);
			self->displayListInvertedNormalsTag	= displayListTag + 1;
			GLfloat glColor[4];
			rgbafForCode(stepColor, glColor);

			glNewList(displayListTag, GL_COMPILE);
				[self draw:DRAW_NO_OPTIONS parentColor:glColor];
			glEndList();
			
			glNewList(displayListInvertedNormalsTag, GL_COMPILE);
				[self draw:DRAW_REVERSE_NORMALS parentColor:glColor];
			glEndList();
		}
		
		//We have generated the list; we can now safely flag this step to be 
		// henceforth drawn via the list.
		self->hasDisplayList = YES;
		
	}//end if is optimizable
	
#endif
}//end optimize

#pragma mark -
#pragma mark DESTRUCTOR
#pragma mark -

//========== dealloc ===========================================================
//
// Purpose:		The Fat Lady has sung.
//
//==============================================================================
- (void) dealloc {
	
	[super dealloc];
}//end dealloc


@end

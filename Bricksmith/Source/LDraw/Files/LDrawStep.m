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
//				Steps may have rotations associated with them. A step rotation 
//				defines the viewing angle at which the step is intended to be 
//				displayed (for instance, upside-down). However, since steps are 
//				drawn in a pipeline, they can't actually draw their own 
//				rotations. It is the responsibility of the controller object to 
//				enforce the rotation defined by the step. In Bricksmith, step 
//				rotations are only honored when the model is being drawn in Step 
//				Display mode. 
//
//				The step rotation functionality was originally defined by MLCad.
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

//---------- emptyStep -----------------------------------------------[static]--
//
// Purpose:		Creates a new step ready to be edited, with nothing inside it.
//
//------------------------------------------------------------------------------
+ (id) emptyStep
{
	LDrawStep *newStep = [[LDrawStep alloc] init];
	
	return [newStep autorelease];
	
}//end emptyStep


//---------- emptyStepWithFlavor: ------------------------------------[static]--
//
// Purpose:		Creates a new step ready to be edited, and prespecifies that 
//				only directives of the flavorType will be added.
//
//------------------------------------------------------------------------------
+ (id) emptyStepWithFlavor:(LDrawStepFlavorT) flavorType
{
	LDrawStep *newStep = [LDrawStep emptyStep];
	[newStep setStepFlavor:flavorType];
	
	return newStep;
	
}//end emptyStepWithFlavor:


//---------- stepWithLines: ------------------------------------------[static]--
//
// Purpose:		Creates a new step ready to be edited, with nothing inside it.
//
//------------------------------------------------------------------------------
+ (LDrawStep *) stepWithLines:(NSArray *)lines
{
	LDrawStep		*newStep			= [[LDrawStep alloc] init];
	
	NSString		*currentLine		= nil;
	NSString		*commandCodeString	= nil;
	int				 commandCode		= 0;
	Class			 CommandClass		= Nil;
	id				 newDirective		= nil;
	int				 counter			= 0;
	int				 lastLineIndex		= [lines count] - 1; // index of last subdirective line.
	NSString		*lastLine			= [lines objectAtIndex:lastLineIndex];
	
	if([lastLine hasPrefix:LDRAW_STEP])
	{
		lastLineIndex -= 1;
	}
	else if([lastLine hasPrefix:LDRAW_ROTATION_STEP])
	{
		// Parse the rotation step.
		if( [newStep parseRotationStepFromLine:lastLine] == YES)
			lastLineIndex -= 1;
	}
	
	//Convert each line into a directive, and add it to this step.
	for(counter = 0; counter <= lastLineIndex; counter++)
	{
		currentLine = [lines objectAtIndex:counter];
		if([currentLine length] > 0)
		{
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
- (id) init
{
	[super init];
	
	stepRotationType	= LDrawStepRotationNone;
	rotationAngle		= ZeroPoint3;
	stepFlavor			= LDrawStepAnyDirectives;
	
	return self;
	
}//end init


//========== copyWithZone: =====================================================
//
// Purpose:		Returns a duplicate of this file.
//
//==============================================================================
- (id) copyWithZone:(NSZone *)zone
{
	LDrawStep	*copied	= (LDrawStep *)[super copyWithZone:zone];
	
	[copied setStepFlavor:self->stepFlavor];
	
	return copied;
	
}//end copyWithZone:


#pragma mark -
#pragma mark DIRECTIVES
#pragma mark -

//========== draw:parentColor: =================================================
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
		glCallList(self->displayListTag);
	}
	else
	{
		NSArray			*commandsInStep		= [self subdirectives];
		int				 numberCommands		= [commandsInStep count];
		LDrawDirective	*currentDirective	= nil;
		int				 counter			= 0;
		
		//Check for optimized steps.
		if(self->stepFlavor == LDrawStepQuadrilaterals)
			glBegin(GL_QUADS);
		else if(self->stepFlavor == LDrawStepTriangles)
			glBegin(GL_TRIANGLES);
		else if(self->stepFlavor == LDrawStepLines)
			glBegin(GL_LINES);
		
		//If we have any specialized flavor above, then we have already begun 
		// drawing. This little tidbit must be passed on down to the lower reaches.
		if(self->stepFlavor != LDrawStepAnyDirectives){
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
	}

}//end draw:parentColor:


//========== write =============================================================
//
// Purpose:		Write out all the commands in the step, prefaced by the line 
//				0 STEP
//
//==============================================================================
- (NSString *) write
{
	return [self writeWithStepCommand:YES];
	
}//end write


//========== writeWithStepCommand: =============================================
//
// Purpose:		Write out all the commands in the step. The output will be 
//				postfaced by the line 0 STEP if explicitStep is true. 
//				The reason this method exists is that we do not want to write 
//				the step command for the last step in the file. That step 
//				is inferred rather than explicit.
//
// Note:		flag is ignored if this is a rotation step. In that case, you 
//				get the step command no matter what.  
//
//==============================================================================
- (NSString *) writeWithStepCommand:(BOOL)flag
{
	NSMutableString	*written			= [NSMutableString string];
	NSString		*CRLF				= [NSString CRLF];
	
	NSArray			*commandsInStep		= [self subdirectives];
	LDrawDirective	*currentCommand		= nil;
	int				 numberCommands		= [commandsInStep count];
	int				 counter			= 0;
	
	// Write all the step's subdirectives
	for(counter = 0; counter < numberCommands; counter++)
	{
		currentCommand = [commandsInStep objectAtIndex:counter];
		[written appendFormat:@"%@%@", [currentCommand write], CRLF];
	}
	
	// End with 0 STEP or 0 ROTSTEP
	if(		flag == YES
		||	self->stepRotationType != LDrawStepRotationNone )
	{
		switch(self->stepRotationType)
		{
			case LDrawStepRotationNone:
				[written appendString:LDRAW_STEP];
				break;
			
			case LDrawStepRotationRelative:
				[written appendFormat:@"%@ %f %f %f %@",	LDRAW_ROTATION_STEP,
															self->rotationAngle.x, 
															self->rotationAngle.y, 
															self->rotationAngle.z, 
															LDRAW_ROTATION_RELATIVE ];
				break;
			
			case LDrawStepRotationAbsolute:
				[written appendFormat:@"%@ %f %f %f %@",	LDRAW_ROTATION_STEP,
															self->rotationAngle.x, 
															self->rotationAngle.y, 
															self->rotationAngle.z, 
															LDRAW_ROTATION_ABSOLUTE ];
				break;
			
			case LDrawStepRotationAdditive:
				[written appendFormat:@"%@ %f %f %f %@",	LDRAW_ROTATION_STEP,
															self->rotationAngle.x, 
															self->rotationAngle.y, 
															self->rotationAngle.z, 
															LDRAW_ROTATION_ADDITIVE ];
				break;
			
			case LDrawStepRotationEnd:
				[written appendFormat:@"%@ %@", LDRAW_ROTATION_STEP, LDRAW_ROTATION_END];
				break;
		}
	}
	
	//Now remove that last CRLF, if it's there.
	if([written hasSuffix:CRLF])
	{
		NSRange lastNewline = NSMakeRange([written length] - [CRLF length], [CRLF length]);
		[written deleteCharactersInRange:lastNewline];
	}
	
	return written;
	
}//end writeWithStepCommand:


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


//========== inspectorClassName ================================================
//
// Purpose:		Returns the name of the class used to inspect this one.
//
//==============================================================================
- (NSString *) inspectorClassName
{
	return @"InspectionStep";
	
}//end inspectorClassName


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
	
}//end addDirective:


//========== enclosingModel ====================================================
//
// Purpose:		Returns the model of which this step is a part.
//
//==============================================================================
- (LDrawModel *) enclosingModel
{
	return (LDrawModel *)[self enclosingDirective];
}//end enclosingModel


//========== rotationAngle =====================================================
//
// Purpose:		Returns the xyz angle in degrees of the rotation. The value must 
//				be interpreted according to the step rotation type. 
//
//==============================================================================
- (Tuple3) rotationAngle
{
	return self->rotationAngle;

}//end rotationAngle


//========== stepRotationType ==================================================
//
// Purpose:		Returns what kind of rotation is attached to this step.
//
//==============================================================================
- (LDrawStepRotationT) stepRotationType
{
	return self->stepRotationType;
	
}//end stepRotationType


#pragma mark -

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


//========== setRotationAngle: =================================================
//
// Purpose:		Sets the xyz angle (in degrees) of the receiver's rotation. The 
//				meaning of the value is determined by the step rotation type. 
//
//==============================================================================
- (void) setRotationAngle:(Tuple3)newAngle
{
	self->rotationAngle = newAngle;
	
}//end setRotationAngle:


//========== setStepFlavor: ====================================================
//
// Purpose:		Sets the step flavor, which identifies the types of 
//				LDrawDirectives the step contains. Setting the flavor to a 
//				specific directive type will cause the step to draw its 
//				subdirectives inside one set of glBegin()/glEnd(), rather than 
//				starting a new group for each directive encountered.
//
//==============================================================================
- (void) setStepFlavor:(LDrawStepFlavorT)newFlavor
{
	self->stepFlavor = newFlavor;
	
}//end setStepFlavor:


//========== setStepRotationType: ==============================================
//
// Purpose:		Sets the kind of rotation attached to this step.
//
// Notes:		Honoring a step rotation is the responsibility of the object 
//				drawing the model, not the step itself. 
//
//==============================================================================
- (void) setStepRotationType:(LDrawStepRotationT)newValue
{
	self->stepRotationType = newValue;
	
}//end setStepRotationType:


#pragma mark -
#pragma mark OPTIMIZE
#pragma mark -

//========== optimize ==========================================================
//
// Purpose:		Makes this step run faster by compiling its contents into a 
//				display list if possible.
//
// Notes:		Now that I'm creating a display list for the entire part at 
//				once, this optimization seems to provide no speed 
//				advantange--and maybe even a very, very slight disadvantage. 
//
//==============================================================================
- (void) optimize
{
#if OPTIMIZE_STEPS == 1
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
	
	// Obsolete notion. 
	// Notes:		This was a misguided optimization. It turns out to be 
	//				preferable to simply display-list the entire part at once. 
	//				Interestingly, this whole route caused nasty graphical 
	//				glitches. Each vertex in the list needs to have a 
	//				pre-associated color. Optimizing steps would only work 
	//				assuming that each display list could be associated with a 
	//				color *on the fly.* But we can't do that; the display list 
	//				needs to have colors *cooked in.*  
	
//	//Put what we can in a display list. I haven't figured out how to overcome 
//	// the hierarchical nature of LDraw with display lists yet, so our options 
//	// are really very limited here.
//	//
//	//Another note: Display list IDs are by default unique to their context. 
//	// We want them to be global to the application! Solution: we set up a 
//	// shared context in LDrawApplication.
//	if(		isColorOptimizable == YES
////		&&	(stepColor == LDrawCurrentColor || stepColor == LDrawEdgeColor)
//		&&	numberCommands >= 4 )
//	{
//		pthread_mutex_init(&displayListMutex, NULL);
//
//		// Generate only one display list. I used to create two; one for regular 
//		// normals and another for normals drown inside an inverted 
//		// transformation matrix. We don't need to do that anymore because we 
//		// have two light sources, pointed in exactly opposite directions, so 
//		// that both kinds of normals will be illuminated. 
//		self->displayListTag	= glGenLists(1);
//		GLfloat glColor[4];
//		rgbafForCode(stepColor, glColor);
//
//		glNewList(displayListTag, GL_COMPILE);
//			[self draw:DRAW_NO_OPTIONS parentColor:glColor];
//		glEndList();
//		
//		//We have generated the list; we can now safely flag this step to be 
//		// henceforth drawn via the list.
//		self->hasDisplayList = YES;
//		
//	}//end if is optimizable
	
#endif
}//end optimize


#pragma mark -
#pragma mark UTILITIES
#pragma mark -

//========== parseRotationStepFromLine: ========================================
//
// Purpose:		Parses out the rotation step values from the given line.
//
//				Rotation steps can have the following forms:
//
//					0 ROTSTEP angleX angleY angleZ		// implied REL
//					0 ROTSTEP angleX angleY angleZ REL
//					0 ROTSTEP angleX angleY angleZ ABS
//					0 ROTSTEP angleX angleY angleZ ADD
//					0 ROTSTEP END
//
// Returns:		YES on success.
//
//==============================================================================
- (BOOL) parseRotationStepFromLine:(NSString *)rotstep
{
	NSScanner	*scanner	= [NSScanner scannerWithString:rotstep];
	Tuple3		 angles		= ZeroPoint3;
	BOOL		 success	= YES;
	
	@try
	{
		if([scanner scanString:LDRAW_ROTATION_STEP intoString:NULL] == NO)
			@throw [NSException exceptionWithName:@"BricksmithParseException" reason:@"Bad ROTSTEP syntax" userInfo:nil];

		// Is it an end rotation?
		if([scanner scanString:LDRAW_ROTATION_END intoString:NULL] == YES)
		{
			[self setStepRotationType:LDrawStepRotationEnd];
		}
		else
		{
			//---------- Angles ------------------------------------------------
			
			if([scanner scanFloat:&(angles.x)] == NO)
				@throw [NSException exceptionWithName:@"BricksmithParseException" reason:@"Bad ROTSTEP syntax" userInfo:nil];

			if([scanner scanFloat:&(angles.y)] == NO)
				@throw [NSException exceptionWithName:@"BricksmithParseException" reason:@"Bad ROTSTEP syntax" userInfo:nil];

			if([scanner scanFloat:&(angles.z)] == NO)
				@throw [NSException exceptionWithName:@"BricksmithParseException" reason:@"Bad ROTSTEP syntax" userInfo:nil];
		
		
			//---------- Rotation Type -----------------------------------------
			
			if( [scanner scanString:LDRAW_ROTATION_ABSOLUTE intoString:NULL] == YES )
				[self setStepRotationType:LDrawStepRotationAbsolute];
			
			else if( [scanner scanString:LDRAW_ROTATION_ADDITIVE intoString:NULL] == YES )
				[self setStepRotationType:LDrawStepRotationAdditive];

			else if( [scanner scanString:LDRAW_ROTATION_RELATIVE intoString:NULL] == YES )
				[self setStepRotationType:LDrawStepRotationRelative];
			
			// if no type is explicitly specified, it is a relative rotation.
			else if( [scanner isAtEnd] == YES )
				[self setStepRotationType:LDrawStepRotationRelative];
			
			// there is some syntax we don't recognize. Abort parsing attempt.
			else
				@throw [NSException exceptionWithName:@"BricksmithParseException" reason:@"Bad ROTSTEP syntax" userInfo:nil];
				
			// Set the parsed angles if we successfully got the type.
			[self setRotationAngle:angles];
		}
	}
	@catch(NSException *exception)
	{
		success = NO;
	}
	
	return success;
	
}//end parseRotationStepFromLine:


//========== registerUndoActions ===============================================
//
// Purpose:		Registers the undo actions that are unique to this subclass, 
//				not to any superclass.
//
//==============================================================================
- (void) registerUndoActions:(NSUndoManager *)undoManager
{
	[super registerUndoActions:undoManager];
	
	[[undoManager prepareWithInvocationTarget:self] setRotationAngle:[self rotationAngle]];
	[[undoManager prepareWithInvocationTarget:self] setStepRotationType:[self stepRotationType]];
	
	[undoManager setActionName:NSLocalizedString(@"UndoAttributesStep", nil)];
	
}//end registerUndoActions:


#pragma mark -
#pragma mark DESTRUCTOR
#pragma mark -

//========== dealloc ===========================================================
//
// Purpose:		The Fat Lady has sung.
//
//==============================================================================
- (void) dealloc
{
	[super dealloc];
	
}//end dealloc


@end

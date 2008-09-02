//==============================================================================
//
// File:		LDrawDrawableElement.m
//
// Purpose:		Abstract superclass for all LDraw elements that can actually be 
//				drawn (polygons and parts). The class wraps common functionality 
//				such as color and mouse-selection.
//
//  Created by Allen Smith on 4/20/05.
//  Copyright (c) 2005. All rights reserved.
//==============================================================================
#import "LDrawDrawableElement.h"

#import "LDrawColor.h"
#import "LDrawContainer.h"
#import "MacLDraw.h"

@implementation LDrawDrawableElement

#pragma mark -
#pragma mark INITIALIZATION
#pragma mark -


//========== init ==============================================================
//
// Purpose:		Create a fresh object. This is the default initializer.
//
//==============================================================================
- (id) init {
	self = [super init];
	
	self->hidden = NO;
	
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
	
	[self setLDrawColor:[decoder decodeIntForKey:@"color"]];
	[self setHidden:[decoder decodeBoolForKey:@"hidden"]];
	
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
	
	[encoder encodeInt:color	forKey:@"color"];
	[encoder encodeBool:hidden	forKey:@"hidden"];
}



//========== copyWithZone: =====================================================
//
// Purpose:		Returns a duplicate of this file.
//
//==============================================================================
- (id) copyWithZone:(NSZone *)zone {
	
	LDrawDrawableElement *copied = (LDrawDrawableElement *)[super copyWithZone:zone];
	
	[copied setLDrawColor:[self LDrawColor]];
	
	return copied;
}


#pragma mark -
#pragma mark DIRECTIVES
#pragma mark -

//========== draw:optionsMask: =================================================
//
// Purpose:		Draws the part. This is a wrapper method that just sets up the 
//				drawing context (the color), then calls a subroutine which 
//				actually draws the element.
//
//==============================================================================
- (void) draw:(unsigned int) optionsMask parentColor:(GLfloat *)parentColor
{
	//[super draw]; //does nothing anyway; don't call it.
	
	if(self->hidden == NO)
	{
		//If the part is selected, we need to give some indication. We do this by 
		// drawing it as a wireframe instead of a filled color. This setting also 
		// conveniently applies to all referenced parts herein. 
		if(self->isSelected == YES)
			glPolygonMode(GL_FRONT_AND_BACK, GL_LINE);
		
		//Load names for mouse-selection, if that's the mode we're in.
		// Only elements contained within a step should ever wind up here.
		// Any other nestings are invalid.
		if((optionsMask & DRAW_HIT_TEST_MODE) != 0){
			LDrawContainer *enclosingStep = [self enclosingDirective];
			int partIndex = [enclosingStep indexOfDirective:self]; 
			int stepIndex = [[enclosingStep enclosingDirective] indexOfDirective:enclosingStep];
			glLoadName( stepIndex*STEP_NAME_MULTIPLIER + partIndex );
			//SERIOUS FLAW!!! This object is not required to have a parent. But 
			// currently, such an orphan would never be drawn. So life goes on.
			
			//Now that we have set a name for this element, we do not want any 
			// other subelements to override it. So we filter the selection 
			// mode flag out of the options we pass down.
			optionsMask = optionsMask ^ DRAW_HIT_TEST_MODE; //XOR
		}
		
		//Draw, for goodness sake!
		
		if(self->color == LDrawCurrentColor)
		{
			#if (OPTIMIZE_STEPS == 0)
				glColor4fv(parentColor); //restore the parent color. OFF IF STEP-OPTIMIZING.
			#endif
			
			//Just draw; don't fool with colors. A significant portion of our 
			// drawing code probably falls into this category.
			[self drawElement:optionsMask parentColor:parentColor];
		}
		else
		{
			#if (OPTIMIZE_STEPS == 0) //we don't HAVE the parent color when steps are optimized
				if(self->color == LDrawEdgeColor)
					complimentColor(parentColor, glColor);
			#endif
		
			glColor4fv(glColor); //set the color for this element.
			[self drawElement:optionsMask parentColor:glColor];
			#if OPTIMIZE_STEPS
				//restore the parent color. NO NEED. Each element does its own color now.
				glColor4fv(parentColor);
			#endif
		}
			
		//Done drawing a selected part? Then switch back to normal filled drawing.
		if(self->isSelected == YES)
			glPolygonMode(GL_FRONT_AND_BACK, GL_FILL);
		
	}
	
}//end draw:optionsMask:


//========== drawElement =======================================================
//
// Purpose:		Draws the actual drawable stuff (polygons, etc.) of the element. 
//				This is a subroutine of the -draw: method, which wraps some 
//				shared functionality such as setting colors.
//
//==============================================================================
- (void) drawElement:(unsigned int) optionsMask parentColor:(GLfloat *)parentColor{
	//implemented by subclasses.
}


#pragma mark -
#pragma mark ACCESSORS
#pragma mark -

//========== boundingBox3 ======================================================
//
// Purpose:		Returns the minimum and maximum points of the box which 
//				perfectly contains this object.
//
//==============================================================================
- (Box3) boundingBox3 {
	Box3 bounds = InvalidBox;
	
	//You shouldn't be here. Look in a subclass.
	
	return bounds;
}


//========== isHidden ==========================================================
//
// Purpose:		Returns whether this element will be drawn or not.
//
//==============================================================================
- (BOOL) isHidden {
	return self->hidden;
}

//========== LDrawColor ========================================================
//
// Purpose:		Returns the LDraw color code of the receiver.
//
//==============================================================================
-(LDrawColorT) LDrawColor{
	return color;
}//end color


//========== setHidden: ========================================================
//
// Purpose:		Sets whether this part will be drawn, or whether it will be 
//				skipped during drawing. This setting only affects drawing; 
//				hidden parts will always be written out. Also, note that 
//				hiddenness is a temporary state; it is not saved and restored.
//
//==============================================================================
- (void) setHidden:(BOOL) flag {
	self->hidden = flag;
}


//========== setLDrawColor: ====================================================
//
// Purpose:		Sets the color of this element.
//
//==============================================================================
-(void) setLDrawColor:(LDrawColorT)newColor
{
	self->color = newColor;
	
	//Look up the OpenGL color now so we don't have to whenever we draw.
	rgbafForCode(color, glColor);
	
}//end setColor


#pragma mark -
#pragma mark ACTIONS
#pragma mark -

//========== displacementForNudge: =============================================
//
// Purpose:		Returns the amount by which the element wants to move, given a 
//				"nudge" in the specified direction. A "nudge" is generated by 
//				pressing the arrow keys. If they feel it appropriate, subclasses 
//				are perfectly welcome to scale this value. (LDrawParts do this.)
//
//==============================================================================
- (Vector3) displacementForNudge:(Vector3)nudgeVector
{
	//possibly refined by subclasses.
	return nudgeVector;
}


//========== moveBy: ===========================================================
//
// Purpose:		Displace the receiver by the given amounts in each direction. 
//				The amounts in moveVector or relative to the element's current 
//				location.
//
//				Subclasses are required to move by exactly this amount. Any 
//				adjustments they wish to make need to be returned in 
//				-displacementForNudge:.
//
//==============================================================================
- (void) moveBy:(Vector3)moveVector
{
	//implemented by subclasses.
}

@end

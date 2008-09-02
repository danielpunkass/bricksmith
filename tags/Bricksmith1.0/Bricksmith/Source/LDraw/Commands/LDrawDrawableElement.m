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
	
	[encoder encodeInt:color forKey:@"color"];
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
- (void) draw:(unsigned int) optionsMask parentColor:(GLfloat *)parentColor{
	//[super draw]; //does nothing anyway; don't call it.
	
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
	
	if(color != LDrawCurrentColor){
		glColor4fv(glColor); //set the color for this element.
			[self drawElement:optionsMask parentColor:glColor];
		glColor4fv(parentColor); //restore the parent color.
	}
	else{
		//Just draw; don't fool with colors. A significant portion of our 
		// drawing code probably falls into this category.
		[self drawElement:optionsMask parentColor:parentColor];
	}
		
	//Done drawing a selected part? Then switch back to normal filled drawing.
	if(self->isSelected == YES)
		glPolygonMode(GL_FRONT_AND_BACK, GL_FILL);
	
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

//========== LDrawColor ========================================================
//
// Purpose:		Returns the LDraw color code of the receiver.
//
//==============================================================================
-(LDrawColorT) LDrawColor{
	return color;
}//end color


//========== setLDrawColor: ====================================================
//
// Purpose:		
//
//==============================================================================
-(void) setLDrawColor:(LDrawColorT)newColor{
	color = newColor;
	
	//Look up the OpenGL color now so we don't have to whenever we draw.
	rgbafForCode(color, glColor);
	
}//end setColor


#pragma mark -
#pragma mark ACTIONS
#pragma mark -

//========== nudge: ============================================================
//
// Purpose:		Moves the receiver in the specified direction. If they feel it 
//				appropriate, subclasses are perfectly welcome to scale this 
//				value. (LDrawParts do this.)
//
//==============================================================================
- (void) nudge:(Vector3)nudgeVector{
	//implemented by subclasses.
}

@end

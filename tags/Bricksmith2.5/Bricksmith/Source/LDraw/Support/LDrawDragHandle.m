//==============================================================================
//
// File:		LDrawDragHandle.m
//
// Purpose:		In-scene widget to manipulate a vertex.
//
// Modified:	02/25/2011 Allen Smith. Creation Date.
//
//==============================================================================
#import "LDrawDragHandle.h"

#import <OpenGL/OpenGL.h>

#import "MacLDraw.h"
#import "LDrawUtilities.h"


@implementation LDrawDragHandle

//========== initWithTag:position: =============================================
//
// Purpose:		Initialize the object with a tag to identify what vertex it is 
//				connected to. 
//
//==============================================================================
- (id) initWithTag:(NSInteger)tagIn
		  position:(Point3)positionIn
{
	self = [super init];
	if(self)
	{
		tag             = tagIn;
		position        = positionIn;
		initialPosition = positionIn;
		
		sphere          = gluNewQuadric();
	}
	
	return self;

}//end initWithTag:position:


#pragma mark -
#pragma mark ACCESSORS
#pragma mark -

//========== initialPosition ===================================================
//
// Purpose:		Returns the coordinate this handle what at when initialized.
//
//==============================================================================
- (Point3) initialPosition
{
	return self->initialPosition;
}


//========== isSelected ========================================================
//
// Purpose:		Drag handles only show up when their associated primitive is 
//				selected, so we always report being selected. This will make us 
//				more transparent to the view selection code. 
//
//==============================================================================
- (BOOL) isSelected
{
	return YES;
}


//========== position ==========================================================
//
// Purpose:		Returns the world-coordinate location of the handle.
//
//==============================================================================
- (Point3) position
{
	return self->position;
}


//========== tag ===============================================================
//
// Purpose:		Returns the identifier for this handle. Used to associate the 
//				handle with a vertex. 
//
//==============================================================================
- (NSInteger) tag
{
	return self->tag;
}


//========== target ============================================================
//
// Purpose:		Returns the object which owns the drag handle.
//
//==============================================================================
- (id) target
{
	return self->target;
}


#pragma mark -

//========== setAction: ========================================================
//
// Purpose:		Sets the method to invoke when the handle is repositioned.
//
//==============================================================================
- (void) setAction:(SEL)actionIn
{
	self->action = actionIn;
}


//========== setPosition:updateTarget: =========================================
//
// Purpose:		Updates the current handle position, and triggers the action if 
//				update flag is YES. 
//
//==============================================================================
- (void) setPosition:(Point3)positionIn
		updateTarget:(BOOL)update
{
	self->position = positionIn;
	
	if(update)
	{
		[NSApp sendAction:self->action to:self->target from:self];
	}
}//end setPosition:updateTarget:


//========== setTarget: ========================================================
//
// Purpose:		Sets the object to invoke the action on.
//
//==============================================================================
- (void) setTarget:(id)sender
{
	self->target = sender;
}


#pragma mark -
#pragma mark DRAWING
#pragma mark -

//========== draw:parentColor: =================================================
//
// Purpose:		Draw the drag handle.
//
//==============================================================================
- (void) draw:(NSUInteger) optionsMask parentColor:(LDrawColor *)parentColor
{
	if((optionsMask & DRAW_HIT_TEST_MODE) != 0)
	{
		GLuint hitTag = [LDrawUtilities makeHitTagForObject:self];
		glLoadName( hitTag );
	}
	
	glColor3f(0.50, 0.53, 1.0);
	
	glPushMatrix();
	{
		glTranslatef(self->position.x, self->position.y, self->position.z);
	
		// Draw it
		gluSphere(sphere, 
				  2,	// radius
				  8,	// slices
				  8		// stacks
				  );
	}
	glPopMatrix();
	
}//end draw:parentColor:


#pragma mark -
#pragma mark ACTIONS
#pragma mark -

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
	Point3 newPosition = V3Add(self->position, moveVector);
	
	[self setPosition:newPosition updateTarget:YES];
	
}//end moveBy:


#pragma mark -
#pragma mark DESTRUCTOR
#pragma mark -

//========== dealloc ===========================================================
//
// Purpose:		Party like it's May 21, 2011!
//
//==============================================================================
- (void) dealloc
{
	gluDeleteQuadric(sphere);

	[super dealloc];
}


@end

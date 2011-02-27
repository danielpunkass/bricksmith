//==============================================================================
//
// File:		LDrawDragHandle.h
//
// Purpose:		In-scene widget to manipulate a vertex.
//
// Modified:	02/25/2011 Allen Smith. Creation Date.
//
//==============================================================================
#import <Cocoa/Cocoa.h>
#import <OpenGL/glu.h>

#import "LDrawDirective.h"


////////////////////////////////////////////////////////////////////////////////
//
// LDrawDragHandle
//
////////////////////////////////////////////////////////////////////////////////
@interface LDrawDragHandle : LDrawDirective
{
	NSInteger   tag;
	Point3		position;
	
	GLUquadric	*sphere;
	
	id          target;
	SEL			action;
}

- (id) initWithTag:(NSInteger)tag position:(Point3)positionIn;

// Accessors
- (Point3) position;
- (NSInteger) tag;

- (void) setAction:(SEL)action;
- (void) setPosition:(Point3)positionIn updateTarget:(BOOL)update;
- (void) setTarget:(id)sender;

- (void) draw:(NSUInteger) optionsMask parentColor:(LDrawColor *)parentColor;

@end


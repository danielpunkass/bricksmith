//==============================================================================
//
// File:		LDrawGLView.m
//
// Purpose:		Draws an LDrawFile with OpenGL.
//
//				We also handle processing of mouse events related to the 
//				document. Certain user interactions must be handed off to an 
//				LDrawDocument in order for them to effect the object being 
//				drawn.
//
//				This class also provides for a number of mouse-based viewing 
//				tools triggered by hotkeys. However, we don't track them here! 
//				(We want *all* LDrawGLViews to respond to hotkeys at once.) So 
//				there is a symbiotic relationship with ToolPalette to track 
//				which tool mode we're in; we get notifications when it changes.
//
//  Created by Allen Smith on 4/17/05.
//  Copyright 2005. All rights reserved.
//==============================================================================
#import "LDrawGLView.h"

#import <GLUT/glut.h>
#import <OpenGL/glu.h>

#import "LDrawApplication.h"
#import "LDrawDirective.h"
#import "LDrawDocument.h"
#import "LDrawFile.h"
#import "LDrawModel.h"
#import "LDrawStep.h"
#import "MacLDraw.h"

@implementation LDrawGLView

//========== awakeFromNib ======================================================
//
// Purpose:		Set up our Cocoa viewing.
//
// Notes:		This method will get called twice: once because we load our 
//				accessory view from a Nib file, and once when this object is 
//				unpacked from the Nib in which it's stored.
//
//==============================================================================
- (void) awakeFromNib {
	id		superview	= [self superview];
	NSRect	visibleRect	= [self visibleRect];
	NSRect	frame		= [self frame];
	if([superview isKindOfClass:[NSClipView class]]){
		//Center the view inside its scrollers.
		[self scrollCenterToPoint:NSMakePoint( NSWidth(frame)/2, NSHeight(frame)/2 )];
		[superview setCopiesOnScroll:NO];
	}
	
	
	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	
	[notificationCenter addObserver:self
						   selector:@selector(mouseToolDidChange:)
							   name:LDrawMouseToolDidChangeNotification
							 object:nil ];
	
	//Machinery needed to draw Quartz overtop OpenGL. Sadly, it caused our view 
	// to become transparent when minimizing to the dock. In the end, I didn't 
	// need it anyway.
//	long backgroundOrder = -1;
//	[[self openGLContext] setValues:&backgroundOrder forParameter: NSOpenGLCPSurfaceOrder];
//
//
//	NSScrollView *scrollView = [self enclosingScrollView];
//	if(scrollView != nil){
//		NSLog(@"making stuff transparent");
//		[[self window] setOpaque:NO];
//		[[self window] setAlphaValue:.999f];
////		[[self superview] setDrawsBackground:NO];
////		[scrollView setDrawsBackground:NO];
//	}
}

#pragma mark -
#pragma mark INITIALIZATION
#pragma mark -

//========== initWithCoder: ====================================================
//
// Purpose:		Set up the beatiful OpenGL view.
//
//==============================================================================
- (id) initWithCoder: (NSCoder *) coder{
	
	NSOpenGLPixelFormatAttribute	pixelAttributes[]	= { NSOpenGLPFADoubleBuffer,
															NSOpenGLPFADepthSize, 32,
															nil};
	NSOpenGLContext					*context			= nil;
	NSOpenGLPixelFormat				*pixelFormat		= nil;
	long							swapInterval		= 15;
	
	self = [super initWithCoder: coder];
	
	//Yes, we have a nib file. Don't laugh. This view has an accessory menu.
	[NSBundle loadNibNamed:@"LDrawGLViewAccessories" owner:self];
	
	[self setAcceptsFirstResponder:YES];
	[self setLDrawColor:LDrawCurrentColor];
	cameraDistance			= -10000;
	isDragging				= NO;
	projectionMode			= ProjectionModePerspective;
	rotationDrawMode		= LDrawGLDrawNormal;
	viewingAngle			= ViewingAngle3D;
	
	
	//Set up our OpenGL context. We need to base it on a shared context so that 
	// display-list names can be shared globally throughout the application.
	pixelFormat = [[NSOpenGLPixelFormat alloc] initWithAttributes: pixelAttributes];
	
	context = [[NSOpenGLContext alloc] initWithFormat:pixelFormat
										 shareContext:[LDrawApplication sharedOpenGLContext]];
	[self setOpenGLContext:context];
//	[context setView:self]; //documentation says to do this, but it generates an error. Weird.
	[[self openGLContext] makeCurrentContext];
		
	[self setPixelFormat:pixelFormat];
	[[self openGLContext] setValues: &swapInterval
					   forParameter: NSOpenGLCPSwapInterval ];
			
	[pixelFormat release];
	
	return self;
}


//========== prepareOpenGL =====================================================
//
// Purpose:		The context is all set up; this is where we prepare our OpenGL 
//				state.
//
//==============================================================================
- (void)prepareOpenGL
{
	glClearColor(1.0, 1.0, 1.0, 1.0); //white background
	glEnable(GL_DEPTH_TEST);
	glEnable(GL_BLEND);
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
//	glEnable(GL_LINE_SMOOTH); //makes lines transparent! Bad!
	
	//
	// Define the lighting.
	//
	
	//Our light position is transformed by the modelview matrix. That means 
	// we need to have a standard model matrix loaded to get our light to 
	// land in the right place! But our modelview might have already been 
	// affected by someone calling -setViewingAngle:. So we restore the 
	// default here.
	glMatrixMode(GL_MODELVIEW);
	glLoadIdentity();
	glRotatef(180,1,0,0); //convert to standard, upside-down LDraw orientation.

	float position0[] = {0, -0.5, -1, 0};
	
//	float lightModelAmbient[4]    = {0.1, 0.1, 0.1, 0.0};
	float lightModelAmbient[4]    = {0.2, 0.2, 0.2, 0.0};
	
	float light0Ambient[4]     = { 0.0, 0.0, 0.0, 0.0 }; //don't set this. I think it highlights BFC-culling issues.
	float light0Diffuse[4]     = { 1.0, 1.0, 1.0, 1.0 };
	float light0Specular[4]    = { 0.6, 0.6, 0.6, 1.0 };
	
	glShadeModel(GL_SMOOTH);
	glEnable(GL_NORMALIZE);
	glEnable(GL_COLOR_MATERIAL);
	
	glLightModeli( GL_LIGHT_MODEL_LOCAL_VIEWER,	GL_FALSE);
	glLightModeli( GL_LIGHT_MODEL_TWO_SIDE,		GL_TRUE );
	glLightModelfv(GL_LIGHT_MODEL_AMBIENT,		lightModelAmbient);
	
	glLightfv(GL_LIGHT0, GL_AMBIENT,  light0Ambient);
	glLightfv(GL_LIGHT0, GL_DIFFUSE,  light0Diffuse);
	glLightfv(GL_LIGHT0, GL_SPECULAR, light0Specular);
	
	glEnable(GL_LIGHTING);
	glEnable(GL_LIGHT0);
	
	glLightfv(GL_LIGHT0, GL_POSITION, position0);
	glLineWidth(1);
	
	//Now that the light is positioned where we want it, we can restore the 
	// correct viewing angle.
	[self setViewingAngle:self->viewingAngle];
	
	
	
	//Attempts to make lighting look a little nicer. None of them quite looked 
	// right.
//	glColorMaterial(GL_FRONT_AND_BACK, GL_DIFFUSE);
//	//GL_DIFFUSE + Ambient (1,1,1) makes everything look muddy.
//	// Ambient (0,0,0) is vibrant, but generally too dark.
//	GLfloat ambient[4] = { 0.562, 0.562, 0.562, 1.0 };
//
//	//GL_AMBIENT + Diffuse (1,1,1) makes things look frozen in ice.
//	// Diffuse (0.5, 0.5, 0.5) makes colors pastel
//	// Diffuse (0,0,0) make the model look dark.
//	//GLfloat diffuse[4] = { 0.25, 0.25, 0.25, 1.0 };
//	//GLfloat specular[4]= { 0.08, 0.08, 0.08, 1.0 };
//	GLfloat specular[4]= { 0, 0, 0, 1.0 };
//	GLfloat shininess  = 24;
//	
//	glMaterialfv( GL_FRONT_AND_BACK, GL_AMBIENT, ambient );
//	//glMaterialfv( GL_FRONT_AND_BACK, GL_DIFFUSE, diffuse );
//	glMaterialfv( GL_FRONT_AND_BACK, GL_SPECULAR, specular );
//	glMaterialfv( GL_FRONT_AND_BACK, GL_SHININESS, &shininess );

}

#pragma mark -
#pragma mark DRAWING
#pragma mark -

//========== drawRect: =========================================================
//
// Purpose:		Draw the file into the view.
//
//==============================================================================
- (void) drawRect:(NSRect)rect {

	NSDate			*startTime	= [NSDate date];
	unsigned		 options	= DRAW_NO_OPTIONS;
	NSTimeInterval	 drawTime	= 0;
	
	//If we're rotating, we may need to simplify large models.
#if DEBUG_DRAWING == 0
	if(self->isDragging && self->rotationDrawMode == LDrawGLDrawExtremelyFast)
		options |= DRAW_BOUNDS_ONLY;
#endif //DEBUG_DRAWING
	
	//Load the model matrix to make sure we are applying the right stuff.
	glMatrixMode(GL_MODELVIEW);
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

	glLineWidth(1.1);
	glColor4fv(glColor);
	
	[self->fileBeingDrawn draw:options parentColor:glColor];

	glFlush();
	[[self openGLContext] flushBuffer];
	
	//If we just did a full draw, let's see if rotating needs to be done simply.
	drawTime = -[startTime timeIntervalSinceNow];
	if(self->isDragging == NO) {
		if( drawTime > SIMPLIFICATION_THRESHOLD )
			rotationDrawMode = LDrawGLDrawExtremelyFast;
		else
			rotationDrawMode = LDrawGLDrawNormal;
	}

#if DEBUG_DRAWING
	NSLog(@"draw time: %f", drawTime);
#endif //DEBUG_DRAWING
	

//	NSRect visibleRect = [self visibleRect];
//	[[NSColor colorWithCalibratedWhite:0.5 alpha:0.75] set];
////	[[NSColor clearColor] set];
//	NSRectFill(visibleRect);

}//end drawRect:


//========== isOpaque ==========================================================
//==============================================================================
//- (BOOL) isOpaque
//{
//	return NO;
//}

//========== isFlipped =========================================================
//
// Purpose:		This lets us appear in the upper-left of scroll views rather 
//				than the bottom. The view should draw just fine whether or not 
//				it is flipped, though.
//
//==============================================================================
- (BOOL) isFlipped {
	return YES;
}


#pragma mark -
#pragma mark ACCESSORS
#pragma mark -

//========== acceptsFirstResponder =============================================
//
// Purpose:		Allows us to pick up key events.
//
//==============================================================================
- (BOOL)acceptsFirstResponder {
	return self->acceptsFirstResponder;
}


//========== centerPoint =======================================================
//
// Purpose:		Returns the point (in frame coordinates) which is currently 
//				at the center of the visible rectangle. This is useful for 
//				determining the point being viewed in the scroll view.
//
//==============================================================================
- (NSPoint) centerPoint {
	NSRect visibleRect = [self visibleRect];
	return NSMakePoint( NSMidX(visibleRect), NSMidY(visibleRect) );
}


//========== getInverseMatrix ==================================================
//
// Purpose:		Returns the inverse of the current modelview matrix. You can 
//				multiply points by this matrix to convert screen locations (or 
//				vectors) to model points.
//
// Note:		This function filters out the translation which is caused by 
//				"moving" the camera with gluLookAt. That allows us to continue 
//				working with the model as if it's positioned at the origin, 
//				which means that points we generate with this matrix will 
//				correspond to points in the LDraw model itself.
//
//==============================================================================
- (Matrix4) getInverseMatrix {
	GLfloat	currentMatrix[16];
	Matrix4	transformation;
	Matrix4	inversed;
	
	glGetFloatv(GL_MODELVIEW_MATRIX, currentMatrix);
	transformation = matrix4FromGLMatrix4(currentMatrix); //convert to our utility library format
	
	//When using a perspective view, we must use gluLookAt to reposition the camera. 
	// That basically means translating the model. But all we're concerned about 
	// here is the *rotation*, so we'll zero out the translation components.
	transformation.element[3][0] = 0;
	transformation.element[3][1] = 0; //translation is in the bottom row of the matrix.
	transformation.element[3][2] = 0;
	
	inverse( &transformation, &inversed);
	
	return inversed;
}//end getInverseMatrix


//========== LDrawColor ========================================================
//
// Purpose:		Returns the LDraw color code of the receiver.
//
//==============================================================================
-(LDrawColorT) LDrawColor{
	return color;
}//end color


//========== projectionMode ====================================================
//
// Purpose:		Returns the current projection mode (perspective or 
//				orthographic) used in the view.
//
//==============================================================================
- (ProjectionModeT) projectionMode {
	return self->projectionMode;
}


//========== viewingAngle ======================================================
//
// Purpose:		Returns the current camera orientation for this view.
//
//==============================================================================
- (ViewingAngleT) viewingAngle{
	return viewingAngle;
}		


//========== zoomPercentage ====================================================
//
// Purpose:		Returns the percentage magnification being applied to the 
//				receiver. (200 means 2x magnification.) The scaling factor is
//				determined by the receiver's scroll view, not the GLView itself.
//				If the receiver is not contained within a scroll view, this 
//				method returns 100.
//
//==============================================================================
- (float) zoomPercentage {
	id			superview	= [self superview];
	float		zoomPercentage = 0;
	
	if([superview isKindOfClass:[NSClipView class]] == YES) {
		NSRect clipFrame	= [superview frame];
		NSRect clipBounds	= [superview bounds];
		
		if(NSWidth(clipBounds) != 0)
			zoomPercentage = NSWidth(clipFrame) / NSWidth(clipBounds);
		else
			zoomPercentage = 1; //avoid division by zero
			
		zoomPercentage *= 100; //convert to percent
	}
	else
		zoomPercentage = 100;
	
	return zoomPercentage;
}


//========== setAcceptsFirstResponder: =========================================
//
// Purpose:		Do we want to pick up key events?
//
//==============================================================================
- (void) setAcceptsFirstResponder:(BOOL)flag {
	self->acceptsFirstResponder = flag;
}


//========== setAutosaveName: ==================================================
//
// Purpose:		Sets the name under which this view saves its viewing 
//				configuration. Pass nil for no saving.
//
//==============================================================================
- (void) setAutosaveName:(NSString *)newName {
	[newName retain];
	[self->autosaveName release];
	autosaveName = newName;
}


//========== setLDrawColor: ====================================================
//
// Purpose:		Sets the base color for parts drawn by this view which have no 
//				color themselves.
//
//==============================================================================
-(void) setLDrawColor:(LDrawColorT)newColor{
	color = newColor;
	
	//Look up the OpenGL color now so we don't have to whenever we draw.
	rgbafForCode(color, glColor);
	
}//end setColor


//========== LDrawDirective: ===================================================
//
// Purpose:		Sets the file being drawn in this view.
//
//				We also do other housekeeping here associated with tracking the 
//				model. We also automatically center the model in the view.
//
//==============================================================================
- (void) setLDrawDirective:(LDrawDirective *) newFile {
	NSRect frame = NSZeroRect;
	
	//Update our variable.
	[newFile retain];
	[self->fileBeingDrawn release];
	fileBeingDrawn = newFile;
	
	[[NSNotificationCenter defaultCenter] //force redisplay with glOrtho too.
			postNotificationName:NSViewFrameDidChangeNotification
						  object:self ];
	[self resetFrameSize];
	frame = [self frame]; //now that it's been changed above.
	[self scrollCenterToPoint:NSMakePoint(NSWidth(frame)/2, NSHeight(frame)/2 )];
	[self setNeedsDisplay:YES];

	//Register for important notifications.
	[[NSNotificationCenter defaultCenter] removeObserver:self name:LDrawFileDidChangeNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:LDrawFileActiveModelDidChangeNotification object:nil];
		
	[[NSNotificationCenter defaultCenter]
			addObserver:self
			   selector:@selector(displayNeedsUpdating:)
				   name:LDrawFileDidChangeNotification
				 object:self->fileBeingDrawn ];
	
	[[NSNotificationCenter defaultCenter]
			addObserver:self
			   selector:@selector(displayNeedsUpdating:)
				   name:LDrawFileActiveModelDidChangeNotification
				 object:self->fileBeingDrawn ];
	

}//end setLDrawDirective:


//========== setProjectionMode: ================================================
//
// Purpose:		Sets the projection used when drawing the receiver:
//					- orthographic is like a Mercator map; it distorts deeper 
//									objects.
//					- perspective draws deeper objects toward a vanishing point; 
//									this is how humans see the world.
//
//==============================================================================
- (void) setProjectionMode:(ProjectionModeT) newProjectionMode
{
	self->projectionMode = newProjectionMode;
	
	glMatrixMode(GL_PROJECTION); //we are changing the projection, NOT the model!
	glLoadIdentity();
	[self makeProjection];
	
	[self setNeedsDisplay:YES];
	
} //end setProjectionMode:


//========== setViewingAngle: ==================================================
//
// Purpose:		Changes the camera position from which we view the model. 
//				i.e., ViewingAngleFront means we see the model head-on.
//
//==============================================================================
- (void) setViewingAngle:(ViewingAngleT) newAngle {

	self->viewingAngle = newAngle;
		
	//This method can get called from -prepareOpenGL, which is itself called 
	// from -makeCurrentContext. That's a recipe for infinite recursion. So, 
	// we only makeCurrentContext if we *need* to.
	if([NSOpenGLContext currentContext] != [self openGLContext])
		[[self openGLContext] makeCurrentContext];
	
	
	//Get the default angle.
	glMatrixMode(GL_MODELVIEW);
	glLoadIdentity();
	
	//The camera distance was set for us by -resetFrameSize, so as to be able 
	// to see the entire model.
	gluLookAt( 0, 0, cameraDistance, //camera location
			   0,0,0, //look-at point
			   0, -1, 0 ); //LDraw is upside down.
	
	//okay, now we are oriented looking at the front of the model.
	switch(newAngle){
		case ViewingAngle3D:
			
			glRotatef( 45, 0, 1, 0);
			glRotatef( 45, 1, 0, 1);
			
			break;
		case ViewingAngleFront:			glRotatef(  0, 0, 0, 0); break;
		case ViewingAngleBack:			glRotatef(180, 0, 1, 0); break;
		case ViewingAngleLeft:			glRotatef(-90, 0, 1, 0); break;
		case ViewingAngleRight:			glRotatef( 90, 0, 1, 0); break;
		case ViewingAngleTop:			glRotatef( 90, 1, 0, 0); break;
		case ViewingAngleBottom:		glRotatef(-90, 1, 0, 0); break;
	}
	
	[self setNeedsDisplay:YES];
	
}//end setViewingAngle:


//========== setZoomPercentage: ================================================
//
// Purpose:		Enlarges (or reduces) the magnification on this view. The center 
//				point of the original magnification remains the center point of 
//				the new magnification. Does absolutely nothing if this view 
//				isn't contained within a scroll view.
//
// Parameters:	newPercentage: new zoom; pass 100 for 100%, etc.
//
//==============================================================================
- (void) setZoomPercentage:(float) newPercentage {
	NSScrollView *scrollView = [self enclosingScrollView];
	
	if(scrollView != nil){
		NSClipView	*clipView		= [scrollView contentView];
		NSRect		 clipFrame		= [clipView frame];
		NSRect		 clipBounds		= [clipView bounds];
		NSPoint		 originalCenter	= [self centerPoint];
		
		newPercentage /= 100; //convert to a scale factor
		
		//Change the magnification level of the clip view, which has the effect 
		// of zooming us in and out.
		clipBounds.size.width	= NSWidth(clipFrame)  / newPercentage;
		clipBounds.size.height	= NSHeight(clipFrame) / newPercentage;
		[clipView setBounds:clipBounds]; //BREAKS AUTORESIZING. What to do?
		
		//Preserve the original view centerpoint. Note that the visible 
		// area has changed because we changed our zoom level.
		[self scrollCenterToPoint:originalCenter];
		[self resetFrameSize]; //ensures the canvas fills the whole scroll view
	}

}//end setZoomPercentage


#pragma mark -
#pragma mark ACTIONS
#pragma mark -

//========== viewingAngleSelected: =============================================
//
// Purpose:		The user has chosen a new viewing angle from a menu.
//				sender is the menu item, whose tag is the viewing angle.
//
//==============================================================================
- (IBAction) viewingAngleSelected:(id)sender {
	
	ViewingAngleT newAngle = [sender tag];
	
	[self setViewingAngle:newAngle];
	
	//We treat 3D as a request for perspective, but any straight-on view can 
	// logically be expected to be displayed orthographically.
	if(newAngle == ViewingAngle3D)
		[self setProjectionMode:ProjectionModePerspective];
	else
		[self setProjectionMode:ProjectionModeOrthographic];
	
}//end viewingAngleSelected:


//========== zoomIn: ===========================================================
//
// Purpose:		Enlarge the scale of the current LDraw view.
//
//==============================================================================
- (IBAction) zoomIn:(id)sender {
	float currentZoom = [self zoomPercentage];
	float newZoom = currentZoom * 2;
	[self setZoomPercentage:newZoom];
}


//========== zoomOut: ==========================================================
//
// Purpose:		Shrink the scale of the current LDraw view.
//
//==============================================================================
- (IBAction) zoomOut:(id)sender {
	float currentZoom = [self zoomPercentage];
	float newZoom = currentZoom / 2;
	[self setZoomPercentage:newZoom];
}


#pragma mark -
#pragma mark EVENTS
#pragma mark -

//========== becomeFirstResponder ==============================================
//
// Purpose:		This view is to become the first responder; we need to inform 
//				the rest of the file's views about this event.
//
//==============================================================================
- (BOOL) becomeFirstResponder {
	BOOL success = [super becomeFirstResponder];
	
	if(self->document != nil) {
		[document LDrawGLViewBecameFirstResponder:self];
	}
	
	return success;
}

//========== resetCursor =======================================================
//
// Purpose:		Force a mouse-cursor update. We call this whenever a significant 
//				event occurs, such as a click or keypress.
//
//==============================================================================
- (void) resetCursor {
	
	//It seems -invalidateCursorRectsForView: only causes -resetCursorRects to 
	// get called if there is currently a cursor in force. So we oblige it.
	[self addCursorRect:[self visibleRect] cursor:[NSCursor arrowCursor]];
	
	[[self window] invalidateCursorRectsForView:self];	
	
}//end resetCursor


//========== resetCursorRects ==================================================
//
// Purpose:		Update the document cursor to reflect the current state of 
//				events.
//
//				To simplify, we set a single cursor for the entire view. 
//				Whenever the mouse enters our frame, the AppKit automatically 
//				takes care of adjusting the cursor. This method itself is called 
//				by the AppKit when necessary. We also coax it into happening 
//				more frequently by invalidating. See -resetCursor.
//
//==============================================================================
- (void) resetCursorRects
{
	[super resetCursorRects];
	
	NSRect		 visibleRect	= [self visibleRect];
	BOOL		 isClicked		= NO; /*[[NSApp currentEvent] type] == NSLeftMouseDown;*/ //not enough; overwhelmed by repeating key events
	NSCursor	*cursor			= nil;
	NSImage		*cursorImage	= nil;
	ToolModeT	 toolMode		= [ToolPalette toolMode];
	
	switch(toolMode)
	{
		case RotateSelectTool:
			//just use the standard arrow cursor.
			cursor = [NSCursor arrowCursor];
			break;
		
		case PanScrollTool:
			if(self->isDragging == YES || isClicked == YES)
				cursor = [NSCursor closedHandCursor];
			else
				cursor = [NSCursor openHandCursor];
			break;
			
		case SmoothZoomTool:
			if(self->isDragging == YES) {
				cursorImage = [NSImage imageNamed:@"ZoomCursor"];
				cursor = [[[NSCursor alloc] initWithImage:cursorImage
												  hotSpot:NSMakePoint(7, 10)] autorelease];
			}
			else
				cursor = [NSCursor crosshairCursor];
			break;
			
		case ZoomInTool:
			cursorImage = [NSImage imageNamed:@"ZoomInCursor"];
			cursor = [[[NSCursor alloc] initWithImage:cursorImage
											  hotSpot:NSMakePoint(7, 10)] autorelease];
			break;
			
		case ZoomOutTool:
			cursorImage = [NSImage imageNamed:@"ZoomOutCursor"];
			cursor = [[[NSCursor alloc] initWithImage:cursorImage
											  hotSpot:NSMakePoint(7, 10)] autorelease];
			break;
		
	}
	
	//update the cursor based on the tool mode.
	if(cursor != nil)
	{
		//Make this cursor active over the entire document.
		[self addCursorRect:visibleRect cursor:cursor];
		[cursor setOnMouseEntered:YES];
		
		//okay, something very weird is going on here. When the cursor is inside 
		// a view and THE PARTS BROWSER DRAWER IS OPEN, merely establishing a 
		// cursor rect isn't enough. It's somehow instantly erased when the 
		// LDrawGLView inside the drawer redoes its own cursor rects. Even 
		// calling -set on the cursor often has little more effect than a brief 
		// flicker. I don't know why this is happening, but this hack seems to 
		// fix it.
		if([self mouse:[self convertPoint:[[self window] mouseLocationOutsideOfEventStream] fromView:nil]
				inRect:[self visibleRect] ] ) //mouse is inside view.
		{
			//[cursor set]; //not enough.
			[cursor performSelector:@selector(set) withObject:nil afterDelay:0];
		}
		
	}
		
}//end resetCursorRects


#pragma mark -

//========== keyDown: ==========================================================
//
// Purpose:		Certain key event have editorial significance. Like arrow keys, 
//				for instance. We need to assemble a sensible move request based 
//				on the arrow key pressed.
//
//==============================================================================
- (void)keyDown:(NSEvent *)theEvent
{
	NSString		*characters	= [theEvent characters];
	
//		[self interpretKeyEvents:[NSArray arrayWithObject:theEvent]];
	//We are circumventing the AppKit's key processing system here, because we 
	// may want to extend our keys to mean different things with different 
	// modifiers. It is easier to do that here than to pass it off to 
	// -interpretKeyEvent:. But beware of no-character keypresses like deadkeys.
	if([characters length] > 0) {
	
		unichar firstCharacter	= [characters characterAtIndex:0]; //the key pressed

		switch(firstCharacter) {
			
			case NSUpArrowFunctionKey:
			case NSDownArrowFunctionKey:
			case NSLeftArrowFunctionKey:
			case NSRightArrowFunctionKey:
				[self nudgeKeyDown:theEvent];
				break;
			
			case NSDeleteCharacter: //regular delete character, apparently.
			case NSDeleteFunctionKey: //forward delete--documented! My gosh!
				[NSApp sendAction:@selector(delete:)
							   to:nil //just send it somewhere!
							 from:self];
			default:
				break;
		}
		
	}

}//end keyDown:


//========== performKeyEquivalent: =============================================
//
// Purpose:		This is a command-key equivalent. Since we used the command key 
//				a bit, we need to intercept these separately--they don't come 
//				through key-down.
//
//				Return NO if we don't handle that, thus allowing the menu system 
//				to take a stab at it.
//
//==============================================================================
//- (BOOL) performKeyEquivalent:(NSEvent *)theEvent
//{
//	BOOL		handledEvent	= NO;
////	ToolModeT	startingTool	= self->toolMode;
//	
//	if([[self window] firstResponder] == self){
//		//This is a key-down event in disguise. We need to record the new characters.
//		[self->currentKeyCharacters release];
//		self->currentKeyCharacters = [[theEvent charactersIgnoringModifiers] retain];
//		[self resetCursor];
//		
//		//See if it's a recognized command key (logic duplicated from -resetCursorRects)
//		if([currentKeyCharacters isEqualToString:@" "]){
//		//if(self->toolMode != startingTool){ //doesn't work; resetCursorRects is called after this.
//			handledEvent = YES; //prevent a beep, and also stop further processing of this message.
//		}
//		else
//			//We didn't handle it.
//			handledEvent = [super performKeyEquivalent:theEvent];
//	}
//	else {
//		//We don't want it, since our meddling with command keys is strictly a 
//		// first-responder kind of behavior.
//		handledEvent = [super performKeyEquivalent:theEvent];
//	}
//	
//	
//	return handledEvent;
//	
//}//end performKeyEquivalent:


//========== nudgeKeyDown: =====================================================
//
// Purpose:		We have received a keypress intended to move bricks. We need to 
//				figure out which direction to move them in.
//
//==============================================================================
- (void) nudgeKeyDown:(NSEvent *)theEvent
{
	NSString		*characters	= [theEvent characters];

	[[self openGLContext] makeCurrentContext];
	
	if([characters length] > 0) {
		
		unichar firstCharacter	= [characters characterAtIndex:0]; //the key pressed
		Vector4 screenNudge		= {0,0,0,1}; //nudge in screen coordinates
		Vector4 modelNudge		= {0,0,0,1}; //screen nudge adjusted to model coordinates
		Vector3 adjustedNudge	= {0,0,0}; //model nudge constrained to one axis.
		
		//By holding down the option key, we transcend the two-plane limitation 
		// presented by the arrow keys. Option-presses mean movement along the 
		// z-axis. Note that move "in" to the screen (up arrow, right arrow) 
		// is a movement along the screen's negative z-axis.
		BOOL	isZMovement		= ([theEvent modifierFlags] & NSAlternateKeyMask) != 0;
		BOOL	isNudge			= NO;
		
		switch(firstCharacter) {
			
			case NSUpArrowFunctionKey:
				if(isZMovement == YES)
					screenNudge.z = -1;
				else
					screenNudge.y = 1;
				isNudge = YES;
				break;
				
			case NSDownArrowFunctionKey:
				if(isZMovement == YES)
					screenNudge.z =  1;
				else
					screenNudge.y = -1;
				isNudge = YES;
				break;
				
			case NSLeftArrowFunctionKey:
				if(isZMovement == YES)
					screenNudge.z =  1;
				else
					screenNudge.x = -1;
				isNudge = YES;
				break;
				
			case NSRightArrowFunctionKey:
				if(isZMovement == YES)
					screenNudge.z = -1;
				else
					screenNudge.x =  1;
				isNudge = YES;
				break;
				
			default:
				break;
		}
		
		//Convert this nudge into a meaningful movement based on the current 
		// view orientation.
		if(isNudge == YES) {
			//Get the inverse of the current transformation matrix, we can 
			// convert projection-coordinates back to the model coordinates they 
			// are displaying.
			Matrix4 inversed = [self getInverseMatrix];
			
			//Now we will convert what appears to be the vertical and horizontal axes 
			// into the actual model vectors they represent. We do this conversion 
			// from screen to model coordinates by multiplying our screen points by 
			// the modelview matrix inverse. That has the effect of "undoing" the 
			// model matrix on the screen point, leaving us a model point.
			V4MulPointByMatrix(&screenNudge, &inversed, &modelNudge);
			
			adjustedNudge = V3FromV4(&modelNudge);
			V3IsolateGreatestComponent(&adjustedNudge);
			
			if(document != nil)
				[document nudgeSelectionBy:adjustedNudge]; 
		}
	}
	
}//end nudgeKeyDown:

#pragma mark -

//========== mouseDown: ========================================================
//
// Purpose:		We received a mouseDown before a mouseDragged. Handy thought.
//
//==============================================================================
- (void)mouseDown:(NSEvent *)theEvent
{
	self->isDragging = NO; //not yet, anyway. If it does, that will be 
		//recorded in mouseDragged. Otherwise, this value will remain NO.
	
	[self resetCursor];
	
	if([ToolPalette toolMode] == SmoothZoomTool)
		[self mouseCenterClick:theEvent];
}	


//========== mouseDragged: =====================================================
//
// Purpose:		The user has dragged the mouse after clicking it.
//
//==============================================================================
- (void)mouseDragged:(NSEvent *)theEvent
{
	ToolModeT toolMode = [ToolPalette toolMode];

	self->isDragging = YES;
	[self resetCursor];
	
	//What to do?
	
	if(toolMode == PanScrollTool)
		[self panDragged:theEvent];
	
	else if(toolMode == SmoothZoomTool)
		[self zoomDragged:theEvent];
	
	else if(toolMode == RotateSelectTool)
		[self rotationDragged:theEvent];
	
}//end mouseDragged


//========== mouseUp: ==========================================================
//
// Purpose:		The mouse has been released. Figure out exactly what that means 
//				in the wider context of what the mouse did before now.
//
//==============================================================================
- (void)mouseUp:(NSEvent *)theEvent
{
	ToolModeT toolMode = [ToolPalette toolMode];

	if( toolMode == RotateSelectTool )
	{
		//We only want to select a part if this was NOT part of a mouseDrag event.
		// Otherwise, the selection should remain intact.
		if(self->isDragging == NO){
			[self mousePartSelection:theEvent];
		}
	}
	
	else if(	toolMode == ZoomInTool
			||	toolMode == ZoomOutTool )
		[self mouseZoomClick:theEvent];
	
	//Redraw from our dragging operations, if necessary.
	if(	self->isDragging == YES && rotationDrawMode == LDrawGLDrawExtremelyFast )
		[self setNeedsDisplay:YES];
		
	self->isDragging = NO; //not anymore.
	[self resetCursor];
	
}//end mouseUp:


//========== panDrag: ==========================================================
//
// Purpose:		Scroll the view as the mouse is dragged across it. This is 
//				triggered by holding down the shift key and dragging
//				(see -mouseDragged:).
//
//==============================================================================
- (void) panDragged:(NSEvent *)theEvent
{
	NSRect	visibleRect	= [self visibleRect];
	float	scaleFactor	= [self zoomPercentage] / 100;
	
	//scroll the opposite direction of pull.
	visibleRect.origin.x -= [theEvent deltaX] / scaleFactor;
	visibleRect.origin.y -= [theEvent deltaY] / scaleFactor;
	
	[self scrollRectToVisible:visibleRect];

}//end panDragged:


//========== rotationDragged: ==================================================
//
// Purpose:		Tis time to rotate the object!
//
//				We need to translate horizontal and vertical 2-dimensional mouse 
//				drags into 3-dimensional rotations.
//
//		 +---------------------------------+       ///  /- -\ \\\   (This thing is a sphere.)
//		 |             y /|\               |      /     /   \    \
//		 |                |                |    //      /   \     \\
//		 |                |vertical        |    |   /--+-----+-\   |
//		 |                |motion (around x)   |///    |     |   \\\|
//		 |                |              x |   |       |     |      |
//		 |<---------------+--------------->|   |       |     |      |
//		 |                |     horizontal |   |\\\    |     |   ///|
//		 |                |     motion     |    |   \--+-----+-/   |
//		 |                |    (around y)  |    \\     |     |    //
//		 |                |                |      \     \   /    /
//		 |               \|/               |       \\\  \   / ///
//		 +---------------------------------+          --------
//
//				But 2D motion is not 3D motion! We can't just say that 
//				horizontal drag = rotation around y (up) axis. Why? Because the 
//				y-axis may be laying horizontally due to the rotation!
//
//				The trick is to convert the y-axis *on the projection screen* 
//				back to a *vector in the model*. Then we can just call glRotate 
//				around that vector. The result that the model is rotated in the 
//				direction we dragged, no matter what its orientation!
//
//				Last Note: A horizontal drag from left-to-right is a 
//					counterclockwise rotation around the projection's y axis.
//					This means a positive number of degrees caused by a positive 
//					mouse displacement.
//					But, a vertical drag from bottom-to-top is a clockwise 
//					rotation around the projection's x-axis. That means a 
//					negative number of degrees cause by a positive mouse 
//					displacement. That means we must multiply our x-rotation by 
//					-1 in order to make it go the right direction.
//
//==============================================================================
- (void)rotationDragged:(NSEvent *)theEvent
{
	//Since there are multiple OpenGL rendering areas on the screen, we must 
	// explicitly indicate that we are drawing into ourself. Weird yes, but 
	// horrible things happen without this call.
	[[self openGLContext] makeCurrentContext];

	//Find the mouse displacement from the last known mouse point.
	NSPoint	newPoint		= [theEvent locationInWindow];
	float	deltaX			=   [theEvent deltaX];
	float	deltaY			= - [theEvent deltaY]; //Apple's delta is backwards, for some reason.
	float	viewWidth		= NSWidth([self frame]);
	float	viewHeight		= NSHeight([self frame]);
	
	//Get the percentage of the window we have swept over. Since half the window 
	// represents 180 degrees of rotation, we will eventually multiply this 
	// percentage by 180 to figure out how much to rotate.
	float	percentDragX	= deltaX / viewWidth;
	float	percentDragY	= deltaY / viewHeight;
	
	//Remember, dragging on y means rotating about x.
	float	rotationAboutY	= + ( percentDragX * 180 );
	float	rotationAboutX	= - ( percentDragY * 180 ); //multiply by -1,
				// as we need to convert our drag into a proper rotation 
				// direction. See notes in function header.
	
	//Get the current transformation matrix. By using its inverse, we can 
	// convert projection-coordinates back to the model coordinates they 
	// are displaying.
	Matrix4 inversed = [self getInverseMatrix];
	
	//Now we will convert what appears to be the vertical and horizontal axes 
	// into the actual model vectors they represent.
	Vector4 vectorX = {1,0,0,1}; //unit vector i along x-axis.
	Vector4 vectorY = {0,1,0,1}; //unit vector j along y-axis.
	Vector4 transformedVectorX;
	Vector4 transformedVectorY;
	
	//We do this conversion from screen to model coordinates by multiplying our 
	// screen points by the modelview matrix inverse. That has the effect of 
	// "undoing" the model matrix on the screen point, leaving us a model point.
	V4MulPointByMatrix(&vectorX, &inversed, &transformedVectorX);
	V4MulPointByMatrix(&vectorY, &inversed, &transformedVectorY);
	
	//Now rotate the model around the visual "up" and "down" directions.
	glMatrixMode(GL_MODELVIEW);
	glRotatef( rotationAboutY, transformedVectorY.x, transformedVectorY.y, transformedVectorY.z);
	glRotatef( rotationAboutX, transformedVectorX.x, transformedVectorX.y, transformedVectorX.z);
	
	[self setNeedsDisplay: YES];
	
}//end rotationDragged


//========== zoomDragged: ======================================================
//
// Purpose:		Drag up means zoom in, drag down means zoom out. 1 px = 1 %.
//
//==============================================================================
- (void) zoomDragged:(NSEvent *)theEvent
{
	float zoomChange	= -[theEvent deltaY];
	float currentZoom	= [self zoomPercentage];
	
	//Negative means down
	[self setZoomPercentage:currentZoom + zoomChange];
	
}//end zoomDragged:


//========== mouseCenterClick: =================================================
//
// Purpose:		We have received a mouseDown event which is intended to center 
//				our view on the point clicked.
//
//==============================================================================
- (void) mouseCenterClick:(NSEvent*)theEvent {
	
	NSPoint newCenter = [self convertPoint:[theEvent locationInWindow]
								  fromView:nil ];
	
	[self scrollCenterToPoint:newCenter];
}//end mouseCenterClick:


//========== mousePartSelection: ===============================================
//
// Purpose:		Time to see if we should select something in the model.
//				OpenGL has a selection mode in which it records the name-tag 
//				for anything that renders within the viewing area. We utilize 
//				this feature to find out what part was clicked on.
//
//	Notes:		There's a gotcha here. The click region is determined by 
//				isolating a 1-pixel square around the place where the mouse was 
//				clicked. This is done with gluPickMatrix.
//
//				The trouble is that gluPickMatrix works in viewport coordinates, 
//				which NONE of our Cocoa views are using! (Exception: GLViews 
//				outside a scroll view at 100% zoom level.) To avoid getting 
//				mired in the terrifying array of possible coordinate systems, 
//				we just convert both the click point and the LDraw visible rect 
//				to Window Coordinates.
//
//				Actually, I bet that is fundamentally wrong too. But it won't 
//				show up unless the window coordinate system is being modified. 
//				The ultimate solution is probably to convert to screen 
//				coordinates, because that's what OpenGL is using anyway.
//
//				Confused? So am I.
//
//==============================================================================
- (void)mousePartSelection:(NSEvent *)theEvent
{
	LDrawDirective	*clickedDirective	= nil;
	NSView			*referenceView		= nil;
	NSPoint			 viewClickedPoint	= [theEvent locationInWindow]; //window coordinates
	NSRect			 visibleRect		= [self convertRect:[self visibleRect] toView:nil]; //window coordinates.
	GLuint			 nameBuffer[512]	= {0};
	GLint			 viewport[4]		= {0};
	int				 numberOfHits		= 0;
	
	//Prepare OpenGL to record hits in the viewing area. We need to feed it 
	// a buffer which will be filled with the tags of things that got hit.
	[[self openGLContext] makeCurrentContext];
	glGetIntegerv(GL_VIEWPORT, viewport);
	glSelectBuffer(512, nameBuffer);
	glRenderMode(GL_SELECT); //switch to hit-testing mode.
	{
		//Prepare for recording names. These functions must be called 
		// *after* switching to render mode.
		glInitNames();
		glPushName(UINT_MAX); //0 would be a valid choice, after all...
		
		//Restrict our rendering area (and thus our hit-testing region) to 
		// a very small rectangle around the mouse position.
		glMatrixMode(GL_PROJECTION);
		glPushMatrix();
		
		glLoadIdentity();
		
			//Lastly, convert to viewport coordinates:
		float pickX = viewClickedPoint.x - NSMinX(visibleRect);
		float pickY = viewClickedPoint.y - NSMinY(visibleRect);
		
		gluPickMatrix(pickX,
					  pickY,
					  1, //width
					  1, //height
					  viewport);
		
		NSRect newFrame = [self frame];
			//Now load the common viewing frame
		[self makeProjection];
		
		glMatrixMode(GL_MODELVIEW);
		[self->fileBeingDrawn draw:DRAW_HIT_TEST_MODE parentColor:glColor];
		
		//Restore original viewing matrix after mangling for the hit area.
		glMatrixMode(GL_PROJECTION);
		glPopMatrix();
		
		glFlush();
		[[self openGLContext] flushBuffer];
		
		[self setNeedsDisplay:YES];
	}
	numberOfHits = glRenderMode(GL_RENDER);
	
	clickedDirective = [self getPartFromHits:nameBuffer hitCount:numberOfHits];
	//Notify our delegate about this momentous event.
	// It's okay to send nil; that means "deselect."
	// We want to add this to the current selection if the shift key is down.
	if([self->document respondsToSelector:@selector(LDrawGLView:wantsToSelectDirective:byExtendingSelection:)])
	{
		[self->document LDrawGLView:self
			 wantsToSelectDirective:clickedDirective
			   byExtendingSelection:(([theEvent modifierFlags] & NSShiftKeyMask) != 0) ];
	}
	
	
}//end mousePartSelection:


//========== mouseZoomClick: ===================================================
//
// Purpose:		Depending on the tool mode, we want to zoom in or out. We also 
//				want to center the view on whatever we clicked on.
//
//==============================================================================
- (void) mouseZoomClick:(NSEvent*)theEvent {
	
	ToolModeT	toolMode	= [ToolPalette toolMode];
	float		currentZoom	= [self zoomPercentage];
	float		newZoom		= 0;
	NSPoint		newCenter	= [self convertPoint:[theEvent locationInWindow]
										fromView:nil ];

	if(	toolMode == ZoomInTool )
		newZoom = currentZoom * 2;
	
	else if( toolMode == ZoomOutTool )
		newZoom = currentZoom / 2;
		
	[self setZoomPercentage:newZoom];
	[self scrollCenterToPoint:newCenter];
}//end mouseZoomClick:


#pragma mark -
#pragma mark MENUS
#pragma mark -

//========== validateMenuItem: =================================================
//
// Purpose:		We control our own contextual menu. Since all its actions point 
//				into this class, this is where we manage the menu items.
//
//==============================================================================
- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem
{
	if([menuItem tag] == self->viewingAngle)
		[menuItem setState:NSOnState];
	else
		[menuItem setState:NSOffState];
		
	return YES;
}//end validateMenuItem:


#pragma mark -
#pragma mark NOTIFICATIONS
#pragma mark -

//========== displayNeedsUpdating: =============================================
//
// Purpose:		Someone (likely our file) has notified us that it has changed, 
//				and thus we need to redraw.
//
//				We also use this opportunity to grow the canvas if necessary.
//
//==============================================================================
- (void) displayNeedsUpdating:(NSNotification *)notification {
	[self resetFrameSize]; //calls setNeedsDisplay
}//end displayNeedsUpdating


//========== mouseToolDidChange: ===============================================
//
// Purpose:		Someone (likely our file) has notified us that it has changed, 
//				and thus we need to redraw.
//
//				We also use this opportunity to grow the canvas if necessary.
//
//==============================================================================
- (void) mouseToolDidChange:(NSNotification *)notification {
	[self resetCursor];
}//end mouseToolDidChange


//========== reshape ===========================================================
//
// Purpose:		Something changed in the viewing department; we need to adjust 
//				our projection and viewing area.
//
//==============================================================================
- (void)reshape
{
	[[self openGLContext] makeCurrentContext];

	NSRect	visibleRect	= [self visibleRect];
	NSRect	frame		= [self frame];
	float	scaleFactor	= [self zoomPercentage] / 100;
	
	glMatrixMode(GL_PROJECTION); //we are changing the projection, NOT the model!
	glLoadIdentity();
	
//	NSLog(@"GL view(0x%X) reshaping; frame %@", self, NSStringFromRect(frame));

	//Make a new view based on the current viewable area
	[self makeProjection];

	glViewport(0,0, NSWidth(visibleRect) * scaleFactor, NSHeight(visibleRect) * scaleFactor );
	
}//end reshape


#pragma mark -
#pragma mark UTILITIES
#pragma mark -

//========== getPartFromHits:hitCount: =========================================
//
// Purpose:		Deduce the part that was clicked on, given the selection data 
//				returned from glMatrixMode(GL_SELECT). This hit data is created 
//				by OpenGL when we click the mouse.
//
// Parameters	numberHits is the number of hit records recorded in nameBuffer.
//					It seems to return -1 if the buffer overflowed.
//				nameBuffer is structured as follows:
//					nameBuffer[0] = number of names in first record
//					nameBuffer[1] = minimum depth hit in field of view
//					nameBuffer[2] = maximum depth hit in field of view
//					nameBuffer[3] = bottom entry on name stack
//						....
//					nameBuffer[n] = top entry on name stack
//					nameBuffer[n+1] = number names in second record
//						.... etc.
//
//				Each time something gets rendered into our picking region around 
//				the mouse (and it has a different name), it generates a hit 
//				record. So we have to investigate our buffer and figure out 
//				which hit was the nearest to the front (smallest minimum depth); 
//				that is the one we clicked on.
//
//==============================================================================
- (LDrawDirective *) getPartFromHits:(GLuint *)nameBuffer
							hitCount:(GLuint)numberHits
{
	LDrawDirective *clickedDirective = nil;
	
	//The hit record depths are mapped between 0 and UINT_MAX, where the maximum 
	// integer is the deepest point. We are looking for the shallowest point, 
	// because that's what we clicked on.
	GLuint	minimumDepth		= UINT_MAX;
	GLuint	closestName			= 0;
	int		numberNames			= 0;
	int		hitCounter			= 0;
	int		counter				= 0;
	int		hitRecordBaseIndex	= 0;
	
	//Process all the hits. In theory, each hit record can be of variable 
	// length, so the logic is a little messy. (In Bricksmith, each it record 
	// is exactly 4 entries long, but we're being all general here!)
	for(hitCounter = 0; hitCounter < numberHits; hitCounter++) {
		
		//We find hit records by reckoning them as starting at an 
		// offset in the buffer. hitRecordBaseIndex is the index of the 
		// first entry in the record.
		
		numberNames = nameBuffer[hitRecordBaseIndex + 0]; //first entry.
		//Is this hit closer than the last closest one?
		if(nameBuffer[hitRecordBaseIndex+1] < minimumDepth) {
			minimumDepth = nameBuffer[hitRecordBaseIndex+1];
			//If this was closer, we need to record the name!
			for(counter = 0; counter < numberNames; counter++){
				//Names start in the fourth entry of the hit.
				closestName = nameBuffer[hitRecordBaseIndex + 3 + counter];
				
				//By convention in Bricksmith, we only have one name per hit.
			}
		}
		
		//Advance past this entire hit record. (Three standard entries followed 
		// by a variable number of names per record.)
		hitRecordBaseIndex += 3 + numberNames;
	}
	
	//Match the closest name with the directive it represents. 
	// Note that 0 is a perfectly valid directive tag; our clue that we 
	// didn't find anything is if the number of hits is invalid.
	if(numberHits > 0) {
		//Name tags encode the indices at which the reside.
		int stepIndex = closestName / STEP_NAME_MULTIPLIER; //integer division
		int partIndex = closestName % STEP_NAME_MULTIPLIER;
		
		LDrawModel *enclosingModel = nil;
		LDrawStep *enclosingStep = nil;
		
		//Find the reference we seek. Note that the "fileBeingDrawn" is 
		// not necessarily a file, so we have to compensate.
		if([fileBeingDrawn isKindOfClass:[LDrawFile class]] == YES)
			enclosingModel = (LDrawModel *)[(LDrawFile*)fileBeingDrawn activeModel];
		else if([fileBeingDrawn isKindOfClass:[LDrawModel class]] == YES)
			enclosingModel = (LDrawModel *)fileBeingDrawn;
		
		if(enclosingModel != nil) {
			enclosingStep    = [[enclosingModel steps] objectAtIndex:stepIndex];
			clickedDirective = [[enclosingStep subdirectives] objectAtIndex:partIndex];
		}
	}
	
	return clickedDirective;
	
}//end getPartFromHits:hitCount:


//========== resetFrameSize: ===================================================
//
// Purpose:		We resize the canvas to accomodate the model. It automatically 
//				shrinks for small models and expands for large ones. Neat-o!
//
//==============================================================================
- (void) resetFrameSize {
	
	if([self->fileBeingDrawn respondsToSelector:@selector(boundingBox3)] ) {
		
		//We do not want to apply this resizing to a raw GL view.
		// It only makes sense for those in a scroll view. (The Part Browsers 
		// have been moved to scrollviews now too in order to allow zooming.)
		if([self enclosingScrollView] != nil){
			
			//Determine whether the canvas size needs to change.
			Point3	origin			= {0,0,0};
			NSPoint	centerPoint		= [self centerPoint];
			Box3	newBounds		= [(id)fileBeingDrawn boundingBox3]; //cast to silence warning.
			
			if(V3EqualsBoxes(&newBounds, &InvalidBox) == NO) {
				//
				// Find bounds size, based on model dimensions.
				//
				
				float	distance1		= V3DistanceBetween2Points(&origin, &(newBounds.min) );
				float	distance2		= V3DistanceBetween2Points(&origin, &(newBounds.max) );
				float	newSize			= MAX(distance1, distance2) + 40; //40 is just to provide a margin.
				NSSize	contentSize		= [[self enclosingScrollView] contentSize];
				GLfloat	currentMatrix[16];
				
				contentSize = [self convertSize:contentSize fromView:[self enclosingScrollView]];
				
				//We have the canvas resizing set to a fairly large granularity, so 
				// doesn't constantly change on people.
				newSize = ceil(newSize / 384) * 384;
				
				//
				// Reposition the Camera
				//
				
				//As the size of the model changes, we must move the camera in and out 
				// so as to view the entire model in the right perspective. Moving the 
				// camera is equivalent to translating the modelview matrix. (That's what 
				// gluLookAt does.) 
				// Note:	glTranslatef() doesn't work here. If M is the current matrix, 
				//			and T is the translation, it performs M = M x T. But we need 
				//			M = T x M, because OpenGL uses transposed matrices.
				//			Solution: set matrix manually. Is there a better one?
				[[self openGLContext] makeCurrentContext];
				glMatrixMode(GL_MODELVIEW);
				glGetFloatv(GL_MODELVIEW_MATRIX, currentMatrix);
				
				//As cameraDistance approaches infinity, the view approximates an 
				// orthographic projection. We want a fairly large number here to 
				// produce a small, only slightly-noticable perspective.
				self->cameraDistance = - (newSize) * CAMERA_DISTANCE_FACTOR;
				currentMatrix[12] = 0; //reset the camera location. Positions 12-14 of 
				currentMatrix[13] = 0; // the matrix hold the translation values.
				currentMatrix[14] = cameraDistance;
				glLoadMatrixf(currentMatrix); // It's easiest to set them directly.
				
				//
				// Resize the Frame
				//
				
				NSSize	oldFrameSize	= [self frame].size;
//				NSSize	newFrameSize	= NSMakeSize( newSize*2, newSize*2 );
				//Make the frame either just a little bit bigger than the size 
				// of the model, or the same as the scroll view, whichever is larger.
				NSSize	newFrameSize	= NSMakeSize( MAX(newSize*2, contentSize.width),
													  MAX(newSize*2, contentSize.height) );
				
				//The canvas size changes will effectively be distributed equally on 
				// all sides, because the model is always drawn in the center of the 
				// canvas. So, our effective viewing center will only change by half 
				// the size difference.
				centerPoint.x += (newFrameSize.width  - oldFrameSize.width)/2;
				centerPoint.y += (newFrameSize.height - oldFrameSize.height)/2;
				
				[self setFrameSize:newFrameSize];
				[self scrollCenterToPoint:centerPoint]; //must preserve this; otherwise, viewing is funky.
				
				//NSLog(@"minimum (%f, %f, %f); maximum (%f, %f, %f)", newBounds.min.x, newBounds.min.y, newBounds.min.z, newBounds.max.x, newBounds.max.y, newBounds.max.z);
			}//end valid bounds check
		}//end boundable check
	}
	
	[self setNeedsDisplay:YES];
}


//========== restoreConfiguration ==============================================
//
// Purpose:		Restores the viewing configuration (such as camera location and 
//				projection mode) based on data found in persistent storage. Only 
//				has effect if an autosave name has been specified.
//
//==============================================================================
- (void) restoreConfiguration {
	
	if(self->autosaveName != nil){
		
		NSUserDefaults	*userDefaults		= [NSUserDefaults standardUserDefaults];
		NSString		*viewingAngleKey	= [NSString stringWithFormat:@"%@ %@", LDRAW_GL_VIEW_ANGLE, self->autosaveName];
		NSString		*projectionModeKey	= [NSString stringWithFormat:@"%@ %@", LDRAW_GL_VIEW_PROJECTION, self->autosaveName];
		
		[self   setViewingAngle:[userDefaults integerForKey:viewingAngleKey] ];
		[self setProjectionMode:[userDefaults integerForKey:projectionModeKey] ];
	}
	
}//end restoreConfiguration


//========== makeProjection ====================================================
//
// Purpose:		Loads the viewing projection appropriate for our canvas size.
//
// Notes:		We intentially do NOT load the identity matrix here! This method 
//				merely *refines* the current projection matrix. By doing so, 
//				we can use this method with a preexisting pick matrix, to do 
//				hit-detection. See -mouseUp:.
//
//==============================================================================
- (void) makeProjection {
	//Since there are multiple OpenGL rendering areas on the screen, we must 
	// explicitly indicate that we are drawing into ourself. Weird yes, but 
	// horrible things happen without this call.
	[[self openGLContext] makeCurrentContext];
	
	NSRect	visibleRect		= [self visibleRect];
	NSRect	frame			= [self frame];
	float	fieldDepth		= 0;
	NSRect	visibilityPlane	= NSZeroRect; //
	
	//This is effectively equivalent to infinite field depth
	fieldDepth = MAX(NSHeight(frame), NSWidth(frame));
	
		//Once upon a time, I had a feature called "infinite field depth," as 
		// opposed to a depth that would clip the model. Eventually I concluded 
		// this was a bad idea. But for future reference, the maximum fieldDepth 
		// is about 1e6 (50,000 studs, >1300 ft; probably enough!); viewing 
		// goes haywire with bigger numbers.
	
	float y = NSMinY(visibleRect);
	if([self isFlipped] == YES)
		y = NSHeight(frame) - y - NSHeight(visibleRect);
	
	//The projection plane is stated in model coordinates.
	visibilityPlane.origin.x	= NSMinX(visibleRect) - NSWidth(frame)/2;
	visibilityPlane.origin.y	= y - NSHeight(frame)/2;
	visibilityPlane.size.width	= NSWidth(visibleRect);
	visibilityPlane.size.height	= NSHeight(visibleRect);
	
	glMatrixMode(GL_PROJECTION); //we are changing the projection, NOT the model!
	
	if(self->projectionMode == ProjectionModePerspective){
		
		//We want the model to appear "full size" at the origin. Since
		// perspective viewing is defined by a frustum (truncated pyramid),
		// we have to shrink the visibily plane--which is located on the 
		// near clipping plane--in such a way that a slice of the frustum 
		// through the origin will have the dimensions of the desired 
		// visibility plane. (Remember, slices grow *bigger* as they go 
		// deeper into the view. Since the origin is deeper, that means 
		// we need a near visibility plane that is *smaller* than the 
		// desired size at the origin.)
		float visibleProportion = (float) (CAMERA_DISTANCE_FACTOR - 1) / CAMERA_DISTANCE_FACTOR;
					//based on some trigonometry: cos viewingAngle = modelSize / 7*modelSize
		
		glFrustum(visibleProportion * NSMinX(visibilityPlane),	//left
				  visibleProportion * NSMaxX(visibilityPlane),	//right
				  visibleProportion * NSMinY(visibilityPlane),	//bottom
				  visibleProportion * NSMaxY(visibilityPlane),	//top
				  fabs(cameraDistance) - fieldDepth,	//near (closer points are clipped); distance from CAMERA LOCATION
				  fabs(cameraDistance) + fieldDepth		//far (points beyond this are clipped); distance from CAMERA LOCATION
				  );
	}
	else{
		glOrtho(NSMinX(visibilityPlane),	//left
				NSMaxX(visibilityPlane),	//right
				NSMinY(visibilityPlane),	//bottom
				NSMaxY(visibilityPlane),	//top
				fabs(cameraDistance) - fieldDepth,		//near (points beyond these are clipped)
				fabs(cameraDistance) + fieldDepth );	//far
	}
	
}//end makeProjection


//========== saveConfiguration =================================================
//
// Purpose:		Saves the viewing configuration (such as camera location and 
//				projection mode) into persistent storage. Only has effect if an 
//				autosave name has been specified.
//
//==============================================================================
- (void) saveConfiguration {

	if(self->autosaveName != nil){
		
		NSUserDefaults	*userDefaults		= [NSUserDefaults standardUserDefaults];
		NSString		*viewingAngleKey	= [NSString stringWithFormat:@"%@ %@", LDRAW_GL_VIEW_ANGLE, self->autosaveName];
		NSString		*projectionModeKey	= [NSString stringWithFormat:@"%@ %@", LDRAW_GL_VIEW_PROJECTION, self->autosaveName];
		
		[userDefaults setInteger:[self viewingAngle]	forKey:viewingAngleKey];
		[userDefaults setInteger:[self projectionMode]	forKey:projectionModeKey];
		
		[userDefaults synchronize]; //because we may be quitting, we have to force this here.
	}

}//end saveConfiguration


//========== scrollCenterToPoint ===============================================
//
// Purpose:		Scrolls the receiver (if it is inside a scroll view) so that 
//				newCenter is at the center of the viewing area. newCenter is 
//				given in frame coordinates.
//
//==============================================================================
- (void) scrollCenterToPoint:(NSPoint)newCenter {
	id		clipView		= [self superview];
	NSRect	visibleRect		= [self visibleRect];
	
	[self scrollPoint: NSMakePoint( newCenter.x - NSWidth(visibleRect)/2,
									newCenter.y - NSHeight(visibleRect)/2) ];
}


#pragma mark -
#pragma mark DESTRUCTOR
#pragma mark -

//========== dealloc ===========================================================
//
// Purpose:		glFinishForever();
//
//==============================================================================
- (void) dealloc {

	[self saveConfiguration];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[super dealloc];
}

@end

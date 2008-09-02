//==============================================================================
//
// File:		LDrawGLView.m
//
// Purpose:		Draws an LDrawFile with OpenGL.
//
//  Created by Allen Smith on 4/17/05.
//  Copyright 2005. All rights reserved.
//==============================================================================
#import "LDrawGLView.h"

#import <GLUT/glut.h>
#import <OpenGL/glu.h>
#import "LDrawDirective.h"
#import "LDrawDocument.h"
#import "LDrawFile.h"
#import "LDrawModel.h"
#import "LDrawStep.h"
#import "MacLDraw.h"
#import "MatrixMath.h"

@implementation LDrawGLView

//========== awakeFromNib ======================================================
//
// Purpose:		Set up our Cocoa viewing.
//
//==============================================================================
- (void) awakeFromNib {
	id		superview	= [self superview];
	NSRect	visibleRect	= [self visibleRect];
	NSRect	frame		= [self frame];
	if([superview isKindOfClass:[NSClipView class]]){
		//Center the view inside its scollers.
		[superview scrollToPoint:NSMakePoint( (NSWidth(frame) - NSWidth(visibleRect))/2, 
											  (NSHeight(frame) - NSHeight(visibleRect))/2 )];
		[superview setCopiesOnScroll:NO];
	}
		
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
	NSOpenGLPixelFormat				*pixelFormat;
	long							swapInterval		= 1;
	
	self = [super initWithCoder: coder];
	
	[self setHasInfiniteDepth:NO];
	[self setLDrawColor:LDrawCurrentColor];
	
	//Set up our OpenGL context
	
	pixelFormat = [[NSOpenGLPixelFormat alloc] initWithAttributes: pixelAttributes];
	[self setPixelFormat:pixelFormat];
	[[self openGLContext] setValues: &swapInterval
					   forParameter: NSOpenGLCPSwapInterval ];
			
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
	glEnable(GL_LINE_SMOOTH);
//	glEnableClientState(GL_VERTEX_ARRAY);
	
	//orient us correctly for an LDraw coordinate system, which is 
	// inexplicably upside-down.
	glMatrixMode(GL_MODELVIEW);
	glRotatef(180,1,0,0);
	
	//float position0[] = {1, -1, -1, 0};
	//float position0[] = {0, 0, 1, 0};
	float position0[] = {0, 0, -1, 0};
	
//	glShadeModel(GL_SMOOTH);
//	glEnable(GL_NORMALIZE);
//	glEnable(GL_LIGHTING);
//	glLightModeli( GL_LIGHT_MODEL_TWO_SIDE, GL_TRUE );
//	glEnable(GL_COLOR_MATERIAL);
//	glEnable(GL_LIGHT0);
	
	glLineWidth(2);
	
	glLightfv(GL_LIGHT0, GL_POSITION, position0);
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

//    NSRect bounds = [self bounds];
//    [[NSColor whiteColor] set];
//    NSRectFill(bounds);

	//Load the model matrix to make sure we are applying the right stuff.
	glMatrixMode(GL_MODELVIEW);
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

	glLineWidth(1.0);
	glColor4fv(glColor);
	
	[self->fileBeingDrawn draw:DRAW_NO_OPTIONS parentColor:glColor];
	

	glFlush();
	[[self openGLContext] flushBuffer];
	
	

//	NSRect visibleRect = [self visibleRect];
//	[[NSColor colorWithCalibratedWhite:0.5 alpha:0.75] set];
////	[[NSColor clearColor] set];
//	NSRectFill(visibleRect);

}


//- (BOOL) isOpaque
//{
//	return NO;
//}


#pragma mark -
#pragma mark ACCESSORS
#pragma mark -

//========== acceptsFirstResponder =============================================
//
// Purpose:		Allows us to pick up key events.
//
//==============================================================================
- (BOOL)acceptsFirstResponder {
	return YES;
}


//========== centerPoint =======================================================
//
// Purpose:		Returns the LDraw color code of the receiver.
//
//==============================================================================
- (NSPoint) centerPoint {
	NSRect visibleRect = [self visibleRect];
	return NSMakePoint( NSMidX(visibleRect), NSMidY(visibleRect) );
}


//========== hasInfiniteDepth ==================================================
//
// Purpose:		Returns whether the receiver has an inifinite field of depth.
//
//==============================================================================
- (BOOL) hasInfiniteDepth {
	return self->hasInfiniteDepth;
}


//========== LDrawColor ========================================================
//
// Purpose:		Returns the LDraw color code of the receiver.
//
//==============================================================================
-(LDrawColorT) LDrawColor{
	return color;
}//end color


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
		
		zoomPercentage = NSWidth(clipFrame) / NSWidth(clipBounds);
		zoomPercentage *= 100; //convert to percent
	}
	else
		zoomPercentage = 100;
	
	return zoomPercentage;
}


//========== hasInfiniteDepth ==================================================
//
// Purpose:		Sets whether the receiver has an inifinite field of depth.
//				If YES, then the projection matrix will not clip any points near 
//				or far from the viewer. If NO, the object being drawn will be 
//				clipped, in such a way that one can zoom inside it.
//
//==============================================================================
- (void) setHasInfiniteDepth:(BOOL)newSetting {
	self->hasInfiniteDepth = newSetting;
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
//==============================================================================
- (void) setLDrawDirective:(LDrawDirective *) newFile {
	[newFile retain];
	[self->fileBeingDrawn release];
	
	fileBeingDrawn = newFile;
	[[NSNotificationCenter defaultCenter] //force redisplay with glOrtho too.
			postNotificationName:NSViewFrameDidChangeNotification
						  object:self ];
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


//========== setZoomPercentage: ================================================
//
// Purpose:		Enlarges (or reduces) the magnification on this view. The center 
//				point of the original magnification remains the center point of 
//				the new magnification. Does absolutely nothing if this view 
//				isn't contained within a scroll view.
//
//==============================================================================
- (void) setZoomPercentage:(float) newPercentage {
	id		clipView		= [self superview];
	NSRect	clipFrame		= [clipView frame];
	NSRect	clipBounds		= [clipView bounds];
	NSPoint originalCenter	= [self centerPoint];
	
	if([clipView isKindOfClass:[NSClipView class]] == YES) {
		newPercentage /= 100; //convert to a scale factor
		
		//Change the magnification level of the clip view, which has the effect 
		// of zooming us in and out.
		clipBounds.size.width	= NSWidth(clipFrame)  / newPercentage;
		clipBounds.size.height	= NSHeight(clipFrame) / newPercentage;
		[clipView setBounds:clipBounds];
		
		//Preserve the original view centerpoint. Note that the visible 
		// area has changed because we changed our zoom level.
		[self scrollCenterToPoint:originalCenter];
	}
}//end setZoomPercentage


#pragma mark -
#pragma mark EVENTS
#pragma mark -

//========== becomeFirstResponder ==============================================
//
// Purpose:		This view is to become the first responder; we need to inform 
//				the rest of the file's views about this event.
//
//==============================================================================
- (BOOL)becomeFirstResponder {
	BOOL success = [super becomeFirstResponder];
	
	if(self->document != nil) {
		[document LDrawGLViewBecameFirstResponder:self];
	}
	
	return success;
}

//========== keyDown: ==========================================================
//
// Purpose:		Certain key event have editorial significance. Like arrow keys, 
//				for instance. We need to assemble a sensible move request based 
//				on the arrow key pressed.
//
//==============================================================================
- (void)keyDown:(NSEvent *)theEvent {
	unsigned short	keycode		= [theEvent keyCode];
	NSString		*characters	= [theEvent characters];
	
	
	[[self openGLContext] makeCurrentContext];
		
//		[self interpretKeyEvents:[NSArray arrayWithObject:theEvent]];
	//We are circumventing the AppKit's key processing system here, because we 
	// may want to extend our keys to mean different things with different 
	// modifiers. It is easier to do that here than to pass it off to 
	// -interpretKeyEvent:. But beware of no-character keypresses like deadkeys.
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
			
			case 127: //regular delete character, apparently.
			case NSDeleteFunctionKey: //forward delete--documented! My gosh!
				[NSApp sendAction:@selector(delete:)
							   to:nil //just send it somewhere!
							 from:self];
			default:
				break;
		}
		
		//Convert this nudge into a meaningful movement based on the current 
		// view orientation.
		if(isNudge == YES) {
			//Get the current transformation matrix. By using its inverse, we can 
			// convert projection-coordinates back to the model coordinates they 
			// are displaying.
			GLfloat	currentMatrix[16];
			Matrix4	transformation;
			Matrix4	inversed;
			
			glGetFloatv(GL_MODELVIEW_MATRIX, currentMatrix);
			transformation = matrix4FromGLMatrix4(currentMatrix); //convert to the format of our utility library
			inverse( &transformation, &inversed);
			
			
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

}//end keyDown:



//========== mouseDown: ========================================================
//
// Purpose:		We received a mouseDown before a mouseDragged. Handy thought.
//
//==============================================================================
- (void)mouseDown:(NSEvent *)theEvent
{
	self->mouseDidDrag = NO; //not yet, anyway. If it does, that will be 
		//recorded in mouseDragged. Otherwise, this value will remain NO.
}	


//========== mouseUp: ==========================================================
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
//				Actually, I bet this is fundamentally wrong too. But it won't 
//				show up unless the window coordinate system is being modified. 
//				The ultimate solution is probably to convert to screen 
//				coordinates, because that's what OpenGL is using anyway.
//
//				Confused? So am I.
//
//==============================================================================
- (void)mouseUp:(NSEvent *)theEvent
{
	LDrawDirective	*clickedDirective	= nil;
	NSView			*referenceView		= nil;
	NSPoint			 viewClickedPoint	= [theEvent locationInWindow]; //window coordinates
	NSRect			 visibleRect		= [self convertRect:[self visibleRect] toView:nil]; //window coordinates.
	GLuint			 nameBuffer[512]	= {0};
	GLint			 viewport[4]		= {0};
	int				 numberOfHits		= 0;
	
	//We only want to select a part if this was NOT part of a mouseDrag event.
	// Otherwise, the selection should remain intact.
	if(self->mouseDidDrag == NO){
		
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
				   byExtendingSelection:([theEvent modifierFlags] & NSShiftKeyMask) != 0 ];
		}
	}//end mouseDrag test.
	
}//end mouseUp:


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


//========== mouseDragged: =====================================================
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
//		 |                |motion (around x)     |   |///    |     |   \\\|
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
//					The means a positive number of degrees caused by a positive 
//					mouse displacement.
//					But, a vertical drag from bottom-to-top is a clockwise 
//					rotation around the projection's x-axis. That means a 
//					negative number of degrees cause by a positive mouse 
//					displacement. That means we must multiply our x-rotation by 
//					-1 in order to make it go the right direction.
//
//==============================================================================
- (void)mouseDragged:(NSEvent *)theEvent
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
	GLfloat	currentMatrix[16];
	Matrix4	transformation;
	Matrix4	inversed;
	
	glGetFloatv(GL_MODELVIEW_MATRIX, currentMatrix);
	transformation = matrix4FromGLMatrix4(currentMatrix); //convert to the format of our utility library
	inverse( &transformation, &inversed);
	
	
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
	
	//Now we dragged!
	self->mouseDidDrag = YES;
}


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

	if([self->fileBeingDrawn respondsToSelector:@selector(boundingBox3)] ) {
		//Only if we are drawing an actual document! Part Browsers will not want 
		// to do this!
		if(document != nil)
		{
			//Determine whether the canvas size needs to change.
			Point3	origin			= {0,0,0};
			NSPoint	centerPoint		= [self centerPoint];
			Box3	newBounds		= [(id)fileBeingDrawn boundingBox3]; //cast to silence warning.
			
			if(V3EqualsBoxes(&newBounds, (Box3*)&InvalidBox) == NO) {
				float	distance1		= V3DistanceBetween2Points(&origin, &(newBounds.min) );
				float	distance2		= V3DistanceBetween2Points(&origin, &(newBounds.max) );
				float	newSize			= MAX(distance1, distance2) + 40; //40 is just to provide a margin.
				
				//We have the canvas resizing set to a fairly large granularity, so 
				// doesn't constantly change on people.
				newSize = ceil(newSize / 384) * 384;
				
				NSSize	oldFrameSize	= [self frame].size;
				NSSize	newFrameSize	= NSMakeSize(newSize*2, newSize*2);

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
}//end displayNeedsUpdating


//========== reshape ===========================================================
//
// Purpose:		Something changed in the viewing department; we need to adjust 
//				our projection and viewing area.
//
//==============================================================================
- (void)reshape
{
	
	[[self openGLContext] makeCurrentContext];
	glMatrixMode(GL_PROJECTION); //we are changing the projection, NOT the model!

	NSRect	visibleRect	= [self visibleRect];
	NSRect	frame		= [self frame];
	float	scaleFactor	= [self zoomPercentage] / 100;
	
//	[self setFrameOrigin:NSMakePoint(100,100)];

//	NSLog(@"GL view(%d) reshaping; frame %@", [self hasInfiniteDepth], NSStringFromRect(frame));
	
	
	//Clear current view
	glLoadIdentity();
	
	//Make a new view based on the current viewable area
	[self makeProjection];

	glViewport(0,0, NSWidth(visibleRect) * scaleFactor, NSHeight(visibleRect) * scaleFactor );
}


#pragma mark -
#pragma mark UTILITIES
#pragma mark -

//========== makeProjection ====================================================
//
// Purpose:		Loads the viewing projection appropriate for our canvas size.
//
//==============================================================================
- (void) makeProjection {
	//Since there are multiple OpenGL rendering areas on the screen, we must 
	// explicitly indicate that we are drawing into ourself. Weird yes, but 
	// horrible things happen without this call.
	[[self openGLContext] makeCurrentContext];
	
	NSRect	visibleRect	= [self visibleRect];
	NSRect	frame		= [self frame];
	float	fieldDepth	= 0;
	
	if(self->hasInfiniteDepth == NO)
		fieldDepth = NSWidth(visibleRect);
	else
	{	//Uh, well, so much for "infinite". When I enter values much bigger than 
		// one million, the viewing goes haywire.
		// (50,000 studs, >1500 ft; probably enough!)
		fieldDepth = 1e6;
		//fieldDepth = INFINITY;
	}
	
	glMatrixMode(GL_PROJECTION); //we are changing the projection, NOT the model!
	glOrtho(NSMinX(visibleRect) - NSWidth(frame)/2,	//left
			NSMinX(visibleRect) - NSWidth(frame)/2 + NSWidth(visibleRect),	//right
			NSMinY(visibleRect) - NSHeight(frame)/2,	//bottom
			NSMinY(visibleRect) - NSHeight(frame)/2 + NSHeight(visibleRect),	//top
			-fieldDepth,	//near (points beyond these are clipped)
			fieldDepth );	//far
	
}//end makeProjection


//========== scrollCenterToPoint ===============================================
//
// Purpose:		Scrolls the receiver (if it is inside a scroll view) so that 
//				newCenter is at the center of the viewing area.
//
//==============================================================================
- (void) scrollCenterToPoint:(NSPoint)newCenter {
	id		clipView		= [self superview];
	NSRect	visibleRect		= [self visibleRect];
	
	if([clipView isKindOfClass:[NSClipView class]] == YES) {
		[clipView scrollPoint: NSMakePoint( newCenter.x - NSWidth(visibleRect)/2,
											newCenter.y - NSHeight(visibleRect)/2) ];
	}
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
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[super dealloc];
}

@end

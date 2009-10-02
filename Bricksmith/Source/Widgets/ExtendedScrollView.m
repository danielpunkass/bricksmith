//==============================================================================
//
// File:		ExtendedScrollView.m
//
// Purpose:		A scroll view which supports displaying placards in the 
//				scrollbar regions. 
//
// Modified:	04/19/2009 Allen Smith. Creation Date.
//
//==============================================================================
#import "ExtendedScrollView.h"


@implementation ExtendedScrollView

//========== setVerticalPlacard: ===============================================
//
// Purpose:		Sets the placard view for the top of the vertical scrollbar. 
//
// Notes:		Placards are little views which nestle inside scrollbar areas to 
//				provide additional compact document functionality. 
//
//==============================================================================
- (void) setVerticalPlacard:(NSView *)newPlacard
{
	NSScroller	*verticalScroller	= [self verticalScroller];
	NSView		*superview			= [verticalScroller superview];
	
	[newPlacard retain];
	
	[self->verticalPlacard removeFromSuperview];
	[self->verticalPlacard release];
	
	self->verticalPlacard = newPlacard;
	
	// Add to view hiearchy and re-layout.
	[superview addSubview:newPlacard];
	[self tile];
	[self setNeedsDisplay:YES];
	
}//end setVerticalPlacard:


//========== tile ==============================================================
//
// Purpose:		Lay out the components of the scroll view. This is our 
//				opportunity to make room for our poor placard.
//
//==============================================================================
- (void) tile
{
	[super tile];
	
	if(self->verticalPlacard != nil)
	{
		NSScroller	*verticalScroller	= [self verticalScroller];
		NSRect		scrollerFrame		= [verticalScroller frame];
		NSRect		placardFrame		= [self->verticalPlacard frame];
		
		// Make the placard fit in the scroller area
		placardFrame.origin.x   = NSMinX(scrollerFrame);
		placardFrame.origin.y   = 1; // allow the scroll view to draw its border
		placardFrame.size.width = NSWidth(scrollerFrame);
		
		// Reduce the scroller to make room for the placard
		scrollerFrame.size.height   -= NSMaxY(placardFrame) - 1;
		scrollerFrame.origin.y       = NSMaxY(placardFrame);
		
		// Add the placard
		[verticalScroller		setFrame:scrollerFrame];
		[self->verticalPlacard	setFrame:placardFrame];
	}
}//end tile


#pragma mark -
#pragma mark DESTRUCTOR
#pragma mark -

//========== dealloc ===========================================================
//
// Purpose:		Eulogy of a placard: "Here rests a good and noble sign."
//
//==============================================================================
- (void) dealloc
{
	[verticalPlacard release];
	[super dealloc];
	
}//end dealloc


@end

//==============================================================================
//
// File:		ExtendedScrollView.m
//
// Purpose:		A scroll view which supports displaying placards in the 
//				scrollbar regions, and other nice things.
//
// Modified:	04/19/2009 Allen Smith. Creation Date.
//
//==============================================================================
#import "ExtendedScrollView.h"


@implementation ExtendedScrollView

#pragma mark -
#pragma mark INITIALIZATION
#pragma mark -

//========== initWithFrame: ====================================================
//
// Purpose:		Create one.
//
//==============================================================================
- (id) initWithFrame:(NSRect)frame
{
	self = [super initWithFrame:frame];
	
	preservesScrollCenterDuringLiveResize = NO; // normal Cocoa scroll views don't.
	
	return self;
	
}//end initWithFrame:


#pragma mark -
#pragma mark ACCESSORS
#pragma mark -

//========== setFrame: =========================================================
//
// Purpose:		The size of the scrollview is to be changed, which means that 
//				the scrollbars will also move somehow too. 
//
//==============================================================================
- (void) setFrame:(NSRect)frameRect
{
	[super setFrame:frameRect];
	
	// If we are supposed to be keeping the scroll rect's center in the middle 
	// of the scroll view, then we'll need to rescroll it there now. 
	if(		self->preservesScrollCenterDuringLiveResize == YES
	   &&	[self inLiveResize] == YES 
	   &&	NSEqualPoints(self->documentScrollCenterPoint, NSZeroPoint)
	  )
	{
		NSView  *documentView   = [self documentView];
		NSRect  newVisibleRect  = [documentView visibleRect];
		
		newVisibleRect.origin.x = self->documentScrollCenterPoint.x - NSWidth(newVisibleRect)/2;
		newVisibleRect.origin.y = self->documentScrollCenterPoint.y - NSHeight(newVisibleRect)/2;
		
		newVisibleRect = NSIntegralRect(newVisibleRect);
		
		[documentView scrollRectToVisible:newVisibleRect];
	}
	
}//end setFrame:


//========== setKeepsScrollCenterDuringLiveResize: =============================
//
// Purpose:		Ordinarily, scroll views maintain the origin of the scroll area 
//				as they expand and contract. If this flag is set, the scroll 
//				view will instead keep the center of the document view's scroll 
//				rect at the center of the scroll view during live resize. 
//
//==============================================================================
- (void) setPreservesScrollCenterDuringLiveResize:(BOOL)flag
{
	self->preservesScrollCenterDuringLiveResize = flag;
}


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


#pragma mark -
#pragma mark LAYOUT
#pragma mark -

//========== reflectScrolledClipView: ==========================================
//
// Purpose:		Scrolling is happening, either by the user directly or by 
//				automatic view resizing. 
//
//==============================================================================
- (void) reflectScrolledClipView:(NSClipView *)aClipView
{
	[super reflectScrolledClipView:aClipView];
	
	// If the USER just scrolled the view, memorize his scrolled center so that 
	// we can preserve it during live resize if we are supposed to. 
	if([self inLiveResize] == NO)
	{
		NSView  *documentView       = [self documentView];
		NSRect  documentVisibleRect = [documentView visibleRect];
		NSPoint visibleCenter       = NSMakePoint(NSMidX(documentVisibleRect), NSMidY(documentVisibleRect));
		
		// Careful. Collapsed split views have no visible rect, and we don't 
		// want to save THAT! 
		if( NSEqualPoints(visibleCenter, NSZeroPoint) == NO)
		{
			self->documentScrollCenterPoint = visibleCenter;
		}
	}
}//end reflectScrolledClipView:


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

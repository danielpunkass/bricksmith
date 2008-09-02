//==============================================================================
//
// File:		IconTextCell.m
//
// Purpose:		Shows both text and an icon in a cell.
//
//				Adopted from an Apple example.
//
//  Created by Allen Smith on 2/24/05.
//  Copyright 2005. All rights reserved.
//==============================================================================
#import "IconTextCell.h"


@implementation IconTextCell

#pragma mark -
#pragma mark INITIALIZATION
#pragma mark -

//========== init ==============================================================
//
//==============================================================================
- (id) init {
	[super init];
	
	image = nil;
	imagePadding = 3.0;
	
	return self;
}


//========== initWithCoder: ====================================================
//
// Purpose:		Called by objects in a Nib file. They still need some defaults.
//
//==============================================================================
- (id)initWithCoder:(NSCoder *)decoder{
	[super initWithCoder:decoder];
	image = nil;
	imagePadding = 3.0;
	return self;
}


//========== copyWithZone: =====================================================
//
// Purpose:		Returns a duplicate of this cell. NSTableView calls this all the 
//				time. 
//
//==============================================================================
- (id) copyWithZone:(NSZone *)zone {
	IconTextCell *cell = (IconTextCell *)[super copyWithZone:zone];
	//The pitfall is that it releases it too. So we have to  retain our 
	// instance variables here.
    cell->image = [image retain];
	return cell;
}


#pragma mark -
#pragma mark CELL OVERRIDES
#pragma mark -

//========== cellSize ==========================================================
//
// Purpose:		Returns the minimum size for the cell. We need to take into 
//				account the image we have added.
//
//==============================================================================
- (NSSize)cellSize {
    NSSize cellSize = [super cellSize];
	
	if(image != nil)
		cellSize.width += [image size].width;
    cellSize.width += 2 * imagePadding;
	
    return cellSize;
}


//========== drawInteriorWithFrame:inView: =====================================
//
// Purpose:		Draw the image we have added, then let the superclass draw the 
//				text.
//
//==============================================================================
- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView{

	NSRect	textFrame = cellFrame;
	
    if (image != nil) {
		
		NSSize	imageSize;
		NSRect	imageFrame;
		
		//Divide the cell frame into the image portion and the text portion.
        imageSize = [image size];
        NSDivideRect(cellFrame,
					 &imageFrame, &textFrame,
					 imageSize.width + 2*imagePadding, NSMinXEdge);

		//dunno if we need this.
//		if ([self drawsBackground]) {
//            [[self backgroundColor] set];
//            NSRectFill(imageFrame);
//        }
		
		//Shift the image over by the amount of margins we need.
        imageFrame.origin.x += imagePadding;
        imageFrame.size = imageSize;
		//now center the image in the frame afforded us.
        if ([controlView isFlipped])
            imageFrame.origin.y += ceil( (NSHeight(cellFrame) + NSHeight(imageFrame)) / 2 );
        else
            imageFrame.origin.y += ceil( (NSHeight(cellFrame) - NSHeight(imageFrame)) / 2 );
		
		//Finally, draw the image.
        [image compositeToPoint:imageFrame.origin operation:NSCompositeSourceOver];
    }
	
	//Now draw the text.
    [super drawInteriorWithFrame:textFrame inView:controlView];
}

//========== selectWithFrame:inView:editor:delegate:start:length: ==============
//
// Purpose:		Selects the text to edit; much like editWithFrame
//
//==============================================================================
- (void)selectWithFrame:(NSRect)cellFrame
				 inView:(NSView *)controlView
				 editor:(NSText *)textObject
			   delegate:(id)anObject
				  start:(int)selectionStart
				 length:(int)selectionLength
{
	NSRect	textFrame = cellFrame;

    if (image != nil) {
        NSSize	imageSize;
        NSRect	imageFrame;
		
		//Divide the cell frame into the image portion and the text portion.
        imageSize = [image size];
        NSDivideRect(cellFrame,
					 &imageFrame, &textFrame,
					 imageSize.width + 2*imagePadding, NSMinXEdge);
	}


    [super selectWithFrame: textFrame
					inView: controlView
					editor: textObject
				  delegate: anObject
					 start: selectionStart
					length: selectionLength];
}


//========== editWithFrame:inView:editor:delegate:start:length: ================
//
// Purpose:		Edits the text in the cell. We want to only create an editing 
//				area as big as the text, so we have to subtract out the part 
//				devoted to the image.
//
//==============================================================================
- (void)editWithFrame:(NSRect)cellFrame
			   inView:(NSView *)controlView
			   editor:(NSText *)textObject
			 delegate:(id)anObject
				event:(NSEvent *)theEvent
{
	NSRect	textFrame = cellFrame;
	
	if (image != nil) {
        NSSize	imageSize;
        NSRect	imageFrame;
		
		//Divide the cell frame into the image portion and the text portion.
        imageSize = [image size];
        NSDivideRect(cellFrame,
					 &imageFrame, &textFrame,
					 imageSize.width + 2*imagePadding, NSMinXEdge);
	}
	
	
    [super editWithFrame: textFrame
				  inView: controlView
				  editor: textObject
				delegate: anObject
				   event:(NSEvent *)theEvent ];
}


#pragma mark -
#pragma mark ACCESSORS
#pragma mark -

//========== image ==============================================================
//
// Purpose:		Returns the image displayed along with the text in this cell.
//
//==============================================================================
- (NSImage *)image{
	return image;
}


//========== setImage: =========================================================
//
// Purpose:		Changes the image displayed along with the text in this cell.
//
//==============================================================================
- (void) setImage:(NSImage *)newImage{
	[newImage retain];
	[image release];
	image = newImage;
}

//========== imagePadding ======================================================
//
// Purpose:		Returns the horizontal margin of the image.
//
//==============================================================================
- (float) imagePadding{
	return imagePadding;
}


//========== setImagePadding: ==================================================
//
// Purpose:		Sets the number of pixels left blank on the left and right of 
//				the cell's image.
//
//==============================================================================
- (void) setImagePadding:(float)newAmount{
	imagePadding = newAmount;
}



#pragma mark -
#pragma mark DESTRUCTOR
#pragma mark -

//========== dealloc ===========================================================
//==============================================================================
- (void) dealloc{
	[image release];
	[super dealloc];
}


@end

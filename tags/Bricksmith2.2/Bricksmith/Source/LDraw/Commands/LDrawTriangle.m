//==============================================================================
//
// File:		LDrawTriangle.m
//
// Purpose:		Triangle command.
//				Draws a filled triangle between three points.
//
//				Line format:
//				3 colour x1 y1 z1 x2 y2 z2 x3 y3 z3 
//
//				where
//
//				* colour is a colour code: 0-15, 16, 24, 32-47, 256-511
//				* x1, y1, z1 is the position of the first point
//				* x2, y2, z2 is the position of the second point
//				* x3, y3, z3 is the position of the third point 
//
//  Created by Allen Smith on 2/19/05.
//  Copyright (c) 2005. All rights reserved.
//==============================================================================
#import "LDrawTriangle.h"

#import <OpenGL/GL.h>
#include <string.h>

#import "LDrawColor.h"
#import "LDrawUtilities.h"
#import "MacLDraw.h"

@implementation LDrawTriangle

#pragma mark -
#pragma mark INITIALIZATION
#pragma mark -

//---------- triangleWithDirectiveText: ------------------------------[static]--
//
// Purpose:		Given a line from an LDraw file, parse a triangle primitive.
//
//				directive should have the format:
//
//				3 colour x1 y1 z1 x2 y2 z2 x3 y3 z3 
//
//------------------------------------------------------------------------------
+ (LDrawTriangle *) triangleWithDirectiveText:(NSString *)directive
{
	return [LDrawTriangle directiveWithString:directive];
	
}//end triangleWithDirectiveText:


//---------- directiveWithString: ------------------------------------[static]--
//
// Purpose:		Returns the LDraw directive based on lineFromFile, a single line 
//				of LDraw code from a file.
//
//------------------------------------------------------------------------------
+ (id) directiveWithString:(NSString *)lineFromFile
{
	LDrawTriangle	*parsedTriangle = nil;
	NSString		*workingLine = lineFromFile;
	NSString		*parsedField;
	
	Point3		 workingVertex;
	
	//A malformed part could easily cause a string indexing error, which would 
	// raise an exception. We don't want this to happen here.
	@try
	{
		//Read in the line code and advance past it.
		parsedField = [LDrawUtilities readNextField:  workingLine
										  remainder: &workingLine ];
		//Only attempt to create the part if this is a valid line.
		if([parsedField intValue] == 3){
			parsedTriangle = [LDrawTriangle new];
			
			//Read in the color code.
			// (color)
			parsedField = [LDrawUtilities readNextField:  workingLine
											  remainder: &workingLine ];
			[parsedTriangle setLDrawColor:[parsedField intValue]];
			
			//Read Vertex 1.
			// (x1)
			parsedField = [LDrawUtilities readNextField:workingLine  remainder: &workingLine ];
			workingVertex.x = [parsedField floatValue];
			// (y1)
			parsedField = [LDrawUtilities readNextField:workingLine  remainder: &workingLine ];
			workingVertex.y = [parsedField floatValue];
			// (z1)
			parsedField = [LDrawUtilities readNextField:workingLine  remainder: &workingLine ];
			workingVertex.z = [parsedField floatValue];
			
			[parsedTriangle setVertex1:workingVertex];
				
			//Read Vertex 2.
			// (x2)
			parsedField = [LDrawUtilities readNextField:workingLine  remainder: &workingLine ];
			workingVertex.x = [parsedField floatValue];
			// (y2)
			parsedField = [LDrawUtilities readNextField:workingLine  remainder: &workingLine ];
			workingVertex.y = [parsedField floatValue];
			// (z2)
			parsedField = [LDrawUtilities readNextField:workingLine  remainder: &workingLine ];
			workingVertex.z = [parsedField floatValue];
			
			[parsedTriangle setVertex2:workingVertex];
			
			//Read Vertex 3.
			// (x3)
			parsedField = [LDrawUtilities readNextField:workingLine  remainder: &workingLine ];
			workingVertex.x = [parsedField floatValue];
			// (y3)
			parsedField = [LDrawUtilities readNextField:workingLine  remainder: &workingLine ];
			workingVertex.y = [parsedField floatValue];
			// (z3)
			parsedField = [LDrawUtilities readNextField:workingLine  remainder: &workingLine ];
			workingVertex.z = [parsedField floatValue];
			
			[parsedTriangle setVertex3:workingVertex];
			
		}
	}
	@catch(NSException *exception)
	{
		NSLog(@"the triangle primitive %@ was fatally invalid", lineFromFile);
		NSLog(@" raised exception %@", [exception name]);
	}
	
	return [parsedTriangle autorelease];
	
}//end directiveWithString


//========== initWithCoder: ====================================================
//
// Purpose:		Reads a representation of this object from the given coder,
//				which is assumed to always be a keyed decoder. This allows us to 
//				read and write LDraw objects as NSData.
//
//==============================================================================
- (id) initWithCoder:(NSCoder *)decoder
{
	const uint8_t *temporary = NULL; //pointer to a temporary buffer returned by the decoder.
	
	self = [super initWithCoder:decoder];
	
	//Decoding structures is a bit messy.
	temporary = [decoder decodeBytesForKey:@"vertex1" returnedLength:NULL];
	memcpy(&vertex1, temporary, sizeof(Point3));
	
	temporary = [decoder decodeBytesForKey:@"vertex2" returnedLength:NULL];
	memcpy(&vertex2, temporary, sizeof(Point3));
	
	temporary = [decoder decodeBytesForKey:@"vertex3" returnedLength:NULL];
	memcpy(&vertex3, temporary, sizeof(Point3));
	
	temporary = [decoder decodeBytesForKey:@"normal" returnedLength:NULL];
	memcpy(&normal, temporary, sizeof(Vector3));
	
	return self;
	
}//end initWithCoder:


//========== encodeWithCoder: ==================================================
//
// Purpose:		Writes a representation of this object to the given coder,
//				which is assumed to always be a keyed decoder. This allows us to 
//				read and write LDraw objects as NSData.
//
//==============================================================================
- (void) encodeWithCoder:(NSCoder *)encoder
{
	[super encodeWithCoder:encoder];
	
	[encoder encodeBytes:(void *)&vertex1 length:sizeof(Point3) forKey:@"vertex1"];
	[encoder encodeBytes:(void *)&vertex2 length:sizeof(Point3) forKey:@"vertex2"];
	[encoder encodeBytes:(void *)&vertex3 length:sizeof(Point3) forKey:@"vertex3"];
	[encoder encodeBytes:(void *)&normal  length:sizeof(Vector3) forKey:@"normal"];
	
}//end encodeWithCoder:


//========== copyWithZone: =====================================================
//
// Purpose:		Returns a duplicate of this file.
//
//==============================================================================
- (id) copyWithZone:(NSZone *)zone
{
	LDrawTriangle *copied = (LDrawTriangle *)[super copyWithZone:zone];
	
	[copied setVertex1:[self vertex1]];
	[copied setVertex2:[self vertex2]];
	[copied setVertex3:[self vertex3]];
	
	return copied;
	
}//end copyWithZone:


#pragma mark -
#pragma mark DIRECTIVES
#pragma mark -

//========== drawElement:parentColor: ==========================================
//
// Purpose:		Draws the graphic of the element represented. This call is a 
//				subroutine of -draw: in LDrawDrawableElement.
//
//==============================================================================
- (void) drawElement:(unsigned int) optionsMask withColor:(GLfloat *)drawingColor
{
	//Have we already begun drawing somewhere upstream? If so, all we need to 
	// do here is add the vertices.
	if((optionsMask & DRAW_BEGUN) != 0)
	{
		glColor4fv(drawingColor);
		glNormal3f(normal.x, normal.y, normal.z );
		glVertex3f(vertex1.x, vertex1.y, vertex1.z);
		
		glColor4fv(drawingColor);
		glNormal3f(normal.x, normal.y, normal.z );
		glVertex3f(vertex2.x, vertex2.y, vertex2.z);
		
		glColor4fv(drawingColor);
		glNormal3f(normal.x, normal.y, normal.z );
		glVertex3f(vertex3.x, vertex3.y, vertex3.z);
	}
	//Drawing not begun; we must start it explicitly.
	else
	{
		glBegin(GL_TRIANGLES);
			glColor4fv(drawingColor);
			glNormal3f(normal.x, normal.y, normal.z );
			glVertex3f(vertex1.x, vertex1.y, vertex1.z);
			
			glColor4fv(drawingColor);
			glNormal3f(normal.x, normal.y, normal.z );
			glVertex3f(vertex2.x, vertex2.y, vertex2.z);
			
			glColor4fv(drawingColor);
			glNormal3f(normal.x, normal.y, normal.z );
			glVertex3f(vertex3.x, vertex3.y, vertex3.z);
		glEnd();
	}
}//end drawElement:parentColor:


//========== write =============================================================
//
// Purpose:		Returns a line that can be written out to a file.
//				Line format:
//				3 colour x1 y1 z1 x2 y2 z2 x3 y3 z3 
//
//==============================================================================
- (NSString *) write
{
	return [NSString stringWithFormat:
				@"3 %3d %12f %12f %12f %12f %12f %12f %12f %12f %12f",
				color,
				
				vertex1.x,
				vertex1.y,
				vertex1.z,
				
				vertex2.x,
				vertex2.y,
				vertex2.z,
				
				vertex3.x,
				vertex3.y,
				vertex3.z
		
			];
}//end write


#pragma mark -
#pragma mark DISPLAY
#pragma mark -

//========== browsingDescription ===============================================
//
// Purpose:		Returns a representation of the directive as a short string 
//				which can be presented to the user.
//
//==============================================================================
- (NSString *) browsingDescription
{
	return NSLocalizedString(@"Triangle", nil);
	
}//end browsingDescription


//========== iconName ==========================================================
//
// Purpose:		Returns the name of image file used to display this kind of 
//				object, or nil if there is no icon.
//
//==============================================================================
- (NSString *) iconName
{
	return @"Triangle";
	
}//end iconName


//========== inspectorClassName ================================================
//
// Purpose:		Returns the name of the class used to inspect this one.
//
//==============================================================================
- (NSString *) inspectorClassName
{
	return @"InspectionTriangle";
	
}//end inspectorClassName


#pragma mark -
#pragma mark ACCESSORS
#pragma mark -

//========== boundingBox3 ======================================================
//
// Purpose:		Returns the minimum and maximum points of the box which 
//				perfectly contains this object.
//
//==============================================================================
- (Box3) boundingBox3
{
	Box3 bounds;
	
	//Compare first two points.
	bounds = V3BoundsFromPoints(vertex1, vertex2);

	//Now toss the third vertex into the mix.
	bounds.min.x = MIN(bounds.min.x, vertex3.x);
	bounds.min.y = MIN(bounds.min.y, vertex3.y);
	bounds.min.z = MIN(bounds.min.z, vertex3.z);
	
	bounds.max.x = MAX(bounds.max.x, vertex3.x);
	bounds.max.y = MAX(bounds.max.y, vertex3.y);
	bounds.max.z = MAX(bounds.max.z, vertex3.z);
	
	return bounds;
	
}//end boundingBox3


//========== position ==========================================================
//
// Purpose:		Returns some position for the element. This is used by 
//				drag-and-drop. This is not necessarily human-usable information.
//
//==============================================================================
- (Point3) position
{
	return self->vertex1;
	
}//end position


//========== vertex1 ===========================================================
//==============================================================================
- (Point3) vertex1
{
	return self->vertex1;
	
}//end vertex1


//========== vertex2 ===========================================================
//==============================================================================
- (Point3) vertex2
{
	return self->vertex2;
	
}//end vertex2


//========== vertex3 ===========================================================
//==============================================================================
- (Point3) vertex3
{
	return self->vertex3;
	
}//end vertex3


#pragma mark -

//========== setVertex1: =======================================================
//
// Purpose:		Sets the triangle's first vertex.
//
//==============================================================================
-(void) setVertex1:(Point3)newVertex
{
	self->vertex1 = newVertex;
	[self recomputeNormal];
	
}//end setVertex1:


//========== setVertex2: =======================================================
//
// Purpose:		Sets the triangle's second vertex.
//
//==============================================================================
-(void) setVertex2:(Point3)newVertex
{
	self->vertex2 = newVertex;
	[self recomputeNormal];
	
}//end setVertex2:


//========== setVertex3: =======================================================
//
// Purpose:		Sets the triangle's last vertex.
//
//==============================================================================
-(void) setVertex3:(Point3)newVertex
{
	self->vertex3 = newVertex;
	[self recomputeNormal];
	
}//end setVertex3:


#pragma mark -
#pragma mark ACTIONS
#pragma mark -

//========== moveBy: ===========================================================
//
// Purpose:		Moves the receiver in the specified direction.
//
//==============================================================================
- (void) moveBy:(Vector3)moveVector
{
	vertex1.x += moveVector.x;
	vertex1.y += moveVector.y;
	vertex1.z += moveVector.z;
	
	vertex2.x += moveVector.x;
	vertex2.y += moveVector.y;
	vertex2.z += moveVector.z;
	
	vertex3.x += moveVector.x;
	vertex3.y += moveVector.y;
	vertex3.z += moveVector.z;

}//end moveBy:

#pragma mark -
#pragma mark UTILITIES
#pragma mark -


//========== recomputeNormal ===================================================
//
// Purpose:		Finds the normal vector for this surface.
//
//==============================================================================
- (void) recomputeNormal
{
	Vector3 vector1, vector2;
	
	vector1 = V3Sub(self->vertex2, self->vertex1);
	vector2 = V3Sub(self->vertex3, self->vertex1);
	
	self->normal = V3Cross(vector1, vector2);
	
}//end recomputeNormal


//========== registerUndoActions ===============================================
//
// Purpose:		Registers the undo actions that are unique to this subclass, 
//				not to any superclass.
//
//==============================================================================
- (void) registerUndoActions:(NSUndoManager *)undoManager
{	
	[super registerUndoActions:undoManager];
	
	[[undoManager prepareWithInvocationTarget:self] setVertex3:[self vertex3]];
	[[undoManager prepareWithInvocationTarget:self] setVertex2:[self vertex2]];
	[[undoManager prepareWithInvocationTarget:self] setVertex1:[self vertex1]];
	
	[undoManager setActionName:NSLocalizedString(@"UndoAttributesTriangle", nil)];
	
}//end registerUndoActions:


@end

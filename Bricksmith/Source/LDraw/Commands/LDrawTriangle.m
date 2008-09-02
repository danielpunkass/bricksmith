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

//========== triangleWithDirectiveText: =========================================
//
// Purpose:		Given a line from an LDraw file, parse a triangle primitive.
//
//				directive should have the format:
//
//				3 colour x1 y1 z1 x2 y2 z2 x3 y3 z3 
//
//==============================================================================
+ (LDrawTriangle *) triangleWithDirectiveText:(NSString *)directive{
	return [LDrawTriangle directiveWithString:directive];
}

//========== directiveWithString: ==============================================
//
// Purpose:		Returns the LDraw directive based on lineFromFile, a single line 
//				of LDraw code from a file.
//
//==============================================================================
+ (id) directiveWithString:(NSString *)lineFromFile{
		
	LDrawTriangle	*parsedTriangle = nil;
	NSString		*workingLine = lineFromFile;
	NSString		*parsedField;
	
	Point3		 workingVertex;
	
	//A malformed part could easily cause a string indexing error, which would 
	// raise an exception. We don't want this to happen here.
	NS_DURING
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
		
	NS_HANDLER
		NSLog(@"the triangle primitive %@ was fatally invalid", lineFromFile);
		NSLog(@" raised exception %@", [localException name]);
	NS_ENDHANDLER
	
	return [parsedTriangle autorelease];
}//end triangleWithDirectiveText


//========== initWithCoder: ====================================================
//
// Purpose:		Reads a representation of this object from the given coder,
//				which is assumed to always be a keyed decoder. This allows us to 
//				read and write LDraw objects as NSData.
//
//==============================================================================
- (id)initWithCoder:(NSCoder *)decoder
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
	
	[encoder encodeBytes:(void *)&vertex1 length:sizeof(Point3) forKey:@"vertex1"];
	[encoder encodeBytes:(void *)&vertex2 length:sizeof(Point3) forKey:@"vertex2"];
	[encoder encodeBytes:(void *)&vertex3 length:sizeof(Point3) forKey:@"vertex3"];
	
}


//========== copyWithZone: =====================================================
//
// Purpose:		Returns a duplicate of this file.
//
//==============================================================================
- (id) copyWithZone:(NSZone *)zone {
	
	LDrawTriangle *copied = (LDrawTriangle *)[super copyWithZone:zone];
	
	[copied setVertex1:[self vertex1]];
	[copied setVertex2:[self vertex2]];
	[copied setVertex3:[self vertex3]];
	
	return copied;
}


#pragma mark -
#pragma mark DIRECTIVES
#pragma mark -

//========== drawElement =======================================================
//
// Purpose:		Draws the graphic of the element represented. This call is a 
//				subroutine of -draw: in LDrawDrawableElement.
//
//==============================================================================
- (void) drawElement:(unsigned int) optionsMask parentColor:(GLfloat *)parentColor {
	
	int normalMultiplier = 1;
	if((optionsMask & DRAW_REVERSE_NORMALS) != 0)
		normalMultiplier = -1;

	//Have we already begun drawing somewhere upstream? If so, all we need to 
	// do here is add the vertices.
	if((optionsMask & DRAW_BEGUN) != 0) {
		glNormal3f(normal.x * normalMultiplier,
				   normal.y * normalMultiplier,
				   normal.z * normalMultiplier );
		
		glVertex3f(vertex1.x, vertex1.y, vertex1.z);
		glVertex3f(vertex2.x, vertex2.y, vertex2.z);
		glVertex3f(vertex3.x, vertex3.y, vertex3.z);
	}
	//Drawing not begun; we must start it explicitly.
	else {
		glBegin(GL_TRIANGLES);
			glNormal3f(normal.x * normalMultiplier,
					   normal.y * normalMultiplier,
					   normal.z * normalMultiplier );
		
			glVertex3f(vertex1.x, vertex1.y, vertex1.z);
			glVertex3f(vertex2.x, vertex2.y, vertex2.z);
			glVertex3f(vertex3.x, vertex3.y, vertex3.z);
		glEnd();
	}
}


//========== write =============================================================
//
// Purpose:		Returns a line that can be written out to a file.
//				Line format:
//				3 colour x1 y1 z1 x2 y2 z2 x3 y3 z3 
//
//==============================================================================
- (NSString *) write{
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
- (NSString *)browsingDescription
{
	return NSLocalizedString(@"Triangle", nil);
}


//========== iconName ==========================================================
//
// Purpose:		Returns the name of image file used to display this kind of 
//				object, or nil if there is no icon.
//
//==============================================================================
- (NSString *) iconName{
	return @"Triangle";
}


//========== inspectorClassName ================================================
//
// Purpose:		Returns the name of the class used to inspect this one.
//
//==============================================================================
- (NSString *) inspectorClassName{
	return @"InspectionTriangle";
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
	Box3 bounds;
	
	//Compare first two points.
	V3BoundsFromPoints(&vertex1, &vertex2, &bounds);

	//Now toss the third vertex into the mix.
	bounds.min.x = MIN(bounds.min.x, vertex3.x);
	bounds.min.y = MIN(bounds.min.y, vertex3.y);
	bounds.min.z = MIN(bounds.min.z, vertex3.z);
	
	bounds.max.x = MAX(bounds.max.x, vertex3.x);
	bounds.max.y = MAX(bounds.max.y, vertex3.y);
	bounds.max.z = MAX(bounds.max.z, vertex3.z);
	
	return bounds;
}


//========== vertex1 ===========================================================
//
// Purpose:		Returns the triangle's first vertex.
//
//==============================================================================
- (Point3) vertex1{
	return vertex1;
}

//========== vertex2 ===========================================================
//
// Purpose:		
//
//==============================================================================
- (Point3) vertex2{
	return vertex2;
}

//========== vertex3 ===========================================================
//
// Purpose:		
//
//==============================================================================
- (Point3) vertex3{
	return vertex3;
}

//========== setVertex1: =======================================================
//
// Purpose:		
//
//==============================================================================
-(void) setVertex1:(Point3)newVertex{
	vertex1 = newVertex;
	[self recomputeNormal];
}//end setVertex1


//========== setVertex2: =======================================================
//
// Purpose:		
//
//==============================================================================
-(void) setVertex2:(Point3)newVertex{
	vertex2 = newVertex;
	[self recomputeNormal];
}//end setVertex2


//========== setVertex3: =======================================================
//
// Purpose:		
//
//==============================================================================
-(void) setVertex3:(Point3)newVertex{
	vertex3 = newVertex;
	[self recomputeNormal];
}//end setVertex3


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
- (void) recomputeNormal {
	Vector3 vector1, vector2;
	
	V3Sub(&(self->vertex2), &(self->vertex1), &vector1);
	V3Sub(&(self->vertex3), &(self->vertex1), &vector2);
	
	V3Cross(&vector1, &vector2, &(self->normal));
}


//========== registerUndoActions ===============================================
//
// Purpose:		Registers the undo actions that are unique to this subclass, 
//				not to any superclass.
//
//==============================================================================
- (void) registerUndoActions:(NSUndoManager *)undoManager {
	
	[super registerUndoActions:undoManager];
	
	[[undoManager prepareWithInvocationTarget:self] setVertex3:[self vertex3]];
	[[undoManager prepareWithInvocationTarget:self] setVertex2:[self vertex2]];
	[[undoManager prepareWithInvocationTarget:self] setVertex1:[self vertex1]];
	
	[undoManager setActionName:NSLocalizedString(@"UndoAttributesTriangle", nil)];
}


@end

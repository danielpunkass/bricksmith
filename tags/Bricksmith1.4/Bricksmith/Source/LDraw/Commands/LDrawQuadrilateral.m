//==============================================================================
//
// File:		LDrawQuadrilateral.m
//
// Purpose:		Quadrilateral command.
//				Draws a four-sided, filled shape between four points.
//
//				Line format:
//				4 colour x1 y1 z1 x2 y2 z2 x3 y3 z3 x4 y4 z4 
//
//				where
//
//				* colour is a colour code: 0-15, 16, 24, 32-47, 256-511
//				* x1, y1, z1 is the position of the first point
//				* x2, y2, z2 is the position of the second point
//				* x3, y3, z3 is the position of the third point
//				* x4, y4, z4 is the position of the fourth point 
//
//  Created by Allen Smith on 2/19/05.
//  Copyright (c) 2005. All rights reserved.
//==============================================================================
#import "LDrawQuadrilateral.h"

#import "LDrawUtilities.h"
#import "MacLDraw.h"

@implementation LDrawQuadrilateral

#pragma mark -
#pragma mark INITIALIZATION
#pragma mark -


//========== quadrilateralWithDirectiveText: =========================================
//
// Purpose:		Given a line from an LDraw file, parse a triangle primitive.
//
//				directive should have the format:
//
//				4 colour x1 y1 z1 x2 y2 z2 x3 y3 z3 x4 y4 z4 
//
//==============================================================================
+ (LDrawQuadrilateral *) quadrilateralWithDirectiveText:(NSString *)directive{
	return [LDrawQuadrilateral directiveWithString:directive];
}


//========== directiveWithString: ==============================================
//
// Purpose:		Returns the LDraw directive based on lineFromFile, a single line 
//				of LDraw code from a file.
//
//==============================================================================
+ (id) directiveWithString:(NSString *)lineFromFile{
	
	LDrawQuadrilateral	*parsedQuadrilateral = nil;
	NSString			*workingLine = lineFromFile;
	NSString			*parsedField;
	
	Point3			 workingVertex;
	
	//A malformed part could easily cause a string indexing error, which would 
	// raise an exception. We don't want this to happen here.
	NS_DURING
		//Read in the line code and advance past it.
		parsedField = [LDrawUtilities readNextField:  workingLine
										  remainder: &workingLine ];
		//Only attempt to create the part if this is a valid line.
		if([parsedField intValue] == 4){
			parsedQuadrilateral = [LDrawQuadrilateral new];
			
			//Read in the color code.
			// (color)
			parsedField = [LDrawUtilities readNextField:  workingLine
											  remainder: &workingLine ];
			[parsedQuadrilateral setLDrawColor:[parsedField intValue]];
			
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
			
			[parsedQuadrilateral setVertex1:workingVertex];
				
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
			
			[parsedQuadrilateral setVertex2:workingVertex];
			
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
			
			[parsedQuadrilateral setVertex3:workingVertex];
			
			//Read Vertex 4.
			// (x4)
			parsedField = [LDrawUtilities readNextField:workingLine  remainder: &workingLine ];
			workingVertex.x = [parsedField floatValue];
			// (y4)
			parsedField = [LDrawUtilities readNextField:workingLine  remainder: &workingLine ];
			workingVertex.y = [parsedField floatValue];
			// (z4)
			parsedField = [LDrawUtilities readNextField:workingLine  remainder: &workingLine ];
			workingVertex.z = [parsedField floatValue];
			
			[parsedQuadrilateral setVertex4:workingVertex];
			
			[parsedQuadrilateral fixBowtie];
		}
		
	NS_HANDLER
		NSLog(@"the quadrilateral primitive %@ was fatally invalid", lineFromFile);
		NSLog(@" raised exception %@", [localException name]);
	NS_ENDHANDLER
	
	return [parsedQuadrilateral autorelease];
}//end directiveWithString


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
	
	temporary = [decoder decodeBytesForKey:@"vertex4" returnedLength:NULL];
	memcpy(&vertex4, temporary, sizeof(Point3));
	
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
	[encoder encodeInt:color forKey:@"color"];
	[encoder encodeBytes:(void *)&vertex1 length:sizeof(Point3) forKey:@"vertex1"];
	[encoder encodeBytes:(void *)&vertex2 length:sizeof(Point3) forKey:@"vertex2"];
	[encoder encodeBytes:(void *)&vertex3 length:sizeof(Point3) forKey:@"vertex3"];
	[encoder encodeBytes:(void *)&vertex4 length:sizeof(Point3) forKey:@"vertex4"];
	
}


//========== copyWithZone: =====================================================
//
// Purpose:		Returns a duplicate of this file.
//
//==============================================================================
- (id) copyWithZone:(NSZone *)zone {
	
	LDrawQuadrilateral *copied = (LDrawQuadrilateral *)[super copyWithZone:zone];
	
	[copied setVertex1:[self vertex1]];
	[copied setVertex2:[self vertex2]];
	[copied setVertex3:[self vertex3]];
	[copied setVertex4:[self vertex4]];
	
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
		glVertex3f(vertex4.x, vertex4.y, vertex4.z);
	}
	//Drawing not begun; we must start it explicitly.
	else {
		glBegin(GL_QUADS);
			glNormal3f(normal.x * normalMultiplier,
					   normal.y * normalMultiplier,
					   normal.z * normalMultiplier );
		
			glVertex3f(vertex1.x, vertex1.y, vertex1.z);
			glVertex3f(vertex2.x, vertex2.y, vertex2.z);
			glVertex3f(vertex3.x, vertex3.y, vertex3.z);
			glVertex3f(vertex4.x, vertex4.y, vertex4.z);
		glEnd();
	}
}


//========== write =============================================================
//
// Purpose:		Returns a line that can be written out to a file.
//				Line format:
//				4 colour x1 y1 z1 x2 y2 z2 x3 y3 z3 x4 y4 z4 
//
//==============================================================================
- (NSString *) write{
	return [NSString stringWithFormat:
				@"4 %3d %12f %12f %12f %12f %12f %12f %12f %12f %12f %12f %12f %12f",
				color,
				
				vertex1.x,
				vertex1.y,
				vertex1.z,
				
				vertex2.x,
				vertex2.y,
				vertex2.z,
				
				vertex3.x,
				vertex3.y,
				vertex3.z,
		
				vertex4.x,
				vertex4.y,
				vertex4.z
		
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
	return NSLocalizedString(@"Quadrilateral", nil);
}


//========== iconName ==========================================================
//
// Purpose:		Returns the name of image file used to display this kind of 
//				object, or nil if there is no icon.
//
//==============================================================================
- (NSString *) iconName{
	return @"Quadrilateral";
}


//========== inspectorClassName ================================================
//
// Purpose:		Returns the name of the class used to inspect this one.
//
//==============================================================================
- (NSString *) inspectorClassName{
	return @"InspectionQuadrilateral";
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
	
	Box3 bounds12, bounds34, bounds;
	
	V3BoundsFromPoints(&vertex1, &vertex2, &bounds12);
	V3BoundsFromPoints(&vertex3, &vertex4, &bounds34);
	
	//Combine and we have the result. This is yucky.
	bounds.min.x = MIN(bounds12.min.x, bounds34.min.x);
	bounds.min.y = MIN(bounds12.min.y, bounds34.min.y);
	bounds.min.z = MIN(bounds12.min.z, bounds34.min.z);
	
	bounds.max.x = MAX(bounds12.max.x, bounds34.max.x);
	bounds.max.y = MAX(bounds12.max.y, bounds34.max.y);
	bounds.max.z = MAX(bounds12.max.z, bounds34.max.z);
	
	return bounds;
}


//========== vertex1 ===========================================================
//
// Purpose:		Returns the quadrilateral's first vertex.
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

//========== vertex2 ===========================================================
//
// Purpose:		
//
//==============================================================================
- (Point3) vertex4{
	return vertex4;
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


//========== setVertex4: =======================================================
//
// Purpose:		
//
//==============================================================================
-(void) setVertex4:(Point3)newVertex{
	vertex4 = newVertex;
	[self recomputeNormal];
}//end setVertex4


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
	
	vertex4.x += moveVector.x;
	vertex4.y += moveVector.y;
	vertex4.z += moveVector.z;

}//end moveBy:


#pragma mark -
#pragma mark UTILITIES
#pragma mark -

//========== fixBowtie =========================================================
//
// Purpose:		Four points in any order define a quadrilateral, but if you want 
//				to draw one in OpenGL, you need to be able to trace around the 
//				edges in order. If two vertices are out of order, you wind up 
//				with a "bowtie" shape, which needs to be corrected back into a
//				quadrilateral.
//
//					   4        3     3        4     4        2
//						+------+       +------+       +      +
//						|      |        \    /        |\    /|
//						|      |         \  /         | \  / |
//						|      |          \/          |  \/  |
//						|      |          /\          |  /\  |
//						|      |         /  \         | /  \ |
//						|      |        /    \        |/    \|
//						+------+       +------+       +      +
//					   1        2     1        2     1        3
//
//						correct         case 1         case 2
//									switch 3 & 4   switch 2 & 3
//
//==============================================================================
- (void) fixBowtie
{
	//If correct, the crosses of these three pairs should all point up.
	Vector3 vector1_2, vector1_4; //1 to 2, 1 to 4
	Vector3 vector3_4, vector3_2;
	Vector3 vector4_1, vector4_3;
	Vector3 cross1, cross3, cross4;
	
	V3Sub(&(self->vertex2), &(self->vertex1), &vector1_2);
	V3Sub(&(self->vertex4), &(self->vertex1), &vector1_4);
	V3Sub(&(self->vertex4), &(self->vertex3), &vector3_4);
	V3Sub(&(self->vertex2), &(self->vertex3), &vector3_2);
	V3Sub(&(self->vertex1), &(self->vertex4), &vector4_1);
	V3Sub(&(self->vertex3), &(self->vertex4), &vector4_3);
	
	V3Cross(&vector1_2, &vector1_4, &cross1);
	V3Cross(&vector3_4, &vector3_2, &cross3);
	V3Cross(&vector4_1, &vector4_3, &cross4);
	
	//When crosses point different directions, we have a bowtie. To test this, 
	// recall that cos x = (u • v) / (||u|| ||v||)
	// cos(180) = -1 and cos(0) = 1. So if u•v is negative, we have opposing 
	// vectors (since the denominator is always positive, we can ignore it).
	
	//If 1 & 4 point opposite directions, we have a case 1 bowtie
	if(V3Dot(&cross1, &cross4) < 0) {
		//vectors point in opposite directions
		Point3 swapPoint = self->vertex3;
		vertex3 = vertex4;
		vertex4 = swapPoint;
	}
	//If 3 & 4 point opposite directions, we have a case 2 bowtie
	else if(V3Dot(&cross3, &cross4) < 0){
		Point3 swapPoint = self->vertex2;
		vertex2 = vertex3;
		vertex3 = swapPoint;
	}
	
}//end fixBowtie


//========== recomputeNormal ===================================================
//
// Purpose:		Finds the normal vector for this surface.
//
//==============================================================================
- (void) recomputeNormal {
	Vector3 vector1, vector2;
	
	V3Sub(&(self->vertex2), &(self->vertex1), &vector1);
	V3Sub(&(self->vertex4), &(self->vertex1), &vector2);
	
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
	
	[[undoManager prepareWithInvocationTarget:self] setVertex4:[self vertex4]];
	[[undoManager prepareWithInvocationTarget:self] setVertex3:[self vertex3]];
	[[undoManager prepareWithInvocationTarget:self] setVertex2:[self vertex2]];
	[[undoManager prepareWithInvocationTarget:self] setVertex1:[self vertex1]];
	
	[undoManager setActionName:NSLocalizedString(@"UndoAttributesQuadrilateral", nil)];
}


@end
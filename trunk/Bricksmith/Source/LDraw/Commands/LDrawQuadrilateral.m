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

#import "LDrawStep.h"
#import "LDrawUtilities.h"
#import "MacLDraw.h"


@implementation LDrawQuadrilateral

#pragma mark -
#pragma mark INITIALIZATION
#pragma mark -

//========== initWithLines:beginningAtIndex: ===================================
//
// Purpose:		Returns the LDraw directive based on lineFromFile, a single line 
//				of LDraw code from a file.
//
//				directive should have the format:
//
//				4 colour x1 y1 z1 x2 y2 z2 x3 y3 z3 x4 y4 z4 
//
//==============================================================================
- (id) initWithLines:(NSArray *)lines
	beginningAtIndex:(NSUInteger)index
{
	NSString            *workingLine            = [lines objectAtIndex:index];
	NSString            *parsedField            = nil;
	Point3              workingVertex           = ZeroPoint3;
	LDrawColorT         colorCode               = LDrawColorBogus;
	GLfloat             customRGB[4]            = {0};
	
	self = [super initWithLines:lines beginningAtIndex:index];
	
	//A malformed part could easily cause a string indexing error, which would 
	// raise an exception. We don't want this to happen here.
	@try
	{
		//Read in the line code and advance past it.
		parsedField = [LDrawUtilities readNextField:  workingLine
										  remainder: &workingLine ];
		//Only attempt to create the part if this is a valid line.
		if([parsedField integerValue] == 4)
		{
			//Read in the color code.
			// (color)
			parsedField = [LDrawUtilities readNextField:  workingLine
											  remainder: &workingLine ];
			colorCode = [LDrawUtilities parseColorCodeFromField:parsedField RGB:customRGB];
			if(colorCode == LDrawColorCustomRGB)
				[self setRGBColor:customRGB];
			else
				[self setLDrawColor:colorCode];
			
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
			
			[self setVertex1:workingVertex];
				
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
			
			[self setVertex2:workingVertex];
			
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
			
			[self setVertex3:workingVertex];
			
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
			
			[self setVertex4:workingVertex];
			
			[self fixBowtie];
		}
		else
			@throw [NSException exceptionWithName:@"BricksmithParseException" reason:@"Bad quad syntax" userInfo:nil];
	}
	@catch(NSException *exception)
	{
		NSLog(@"the quadrilateral primitive %@ was fatally invalid", [lines objectAtIndex:index]);
		NSLog(@" raised exception %@", [exception name]);
		[self release];
		self = nil;
	}
	
	return self;
	
}//end initWithLines:beginningAtIndex:


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
	
	temporary = [decoder decodeBytesForKey:@"vertex4" returnedLength:NULL];
	memcpy(&vertex4, temporary, sizeof(Point3));
	
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
	[encoder encodeBytes:(void *)&vertex4 length:sizeof(Point3) forKey:@"vertex4"];
	[encoder encodeBytes:(void *)&normal length:sizeof(Vector3) forKey:@"normal"];
	
}//end encodeWithCoder:


//========== copyWithZone: =====================================================
//
// Purpose:		Returns a duplicate of this file.
//
//==============================================================================
- (id) copyWithZone:(NSZone *)zone
{
	LDrawQuadrilateral *copied = (LDrawQuadrilateral *)[super copyWithZone:zone];
	
	[copied setVertex1:[self vertex1]];
	[copied setVertex2:[self vertex2]];
	[copied setVertex3:[self vertex3]];
	[copied setVertex4:[self vertex4]];
	
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
- (void) drawElement:(NSUInteger) optionsMask withColor:(GLfloat *)drawingColor
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
		
		glColor4fv(drawingColor);
		glNormal3f(normal.x, normal.y, normal.z );
		glVertex3f(vertex4.x, vertex4.y, vertex4.z);
	}
	//Drawing not begun; we must start it explicitly.
	else
	{
		glBegin(GL_QUADS);
		
			glColor4fv(drawingColor);
			glNormal3f(normal.x, normal.y, normal.z );
			glVertex3f(vertex1.x, vertex1.y, vertex1.z);
			
			glColor4fv(drawingColor);
			glNormal3f(normal.x, normal.y, normal.z );
			glVertex3f(vertex2.x, vertex2.y, vertex2.z);
			
			glColor4fv(drawingColor);
			glNormal3f(normal.x, normal.y, normal.z );
			glVertex3f(vertex3.x, vertex3.y, vertex3.z);
			
			glColor4fv(drawingColor);
			glNormal3f(normal.x, normal.y, normal.z );
			glVertex3f(vertex4.x, vertex4.y, vertex4.z);
			
		glEnd();
	}
}//end drawElement:parentColor:


//========== write =============================================================
//
// Purpose:		Returns a line that can be written out to a file.
//				Line format:
//				4 colour x1 y1 z1 x2 y2 z2 x3 y3 z3 x4 y4 z4 
//
//==============================================================================
- (NSString *) write
{
	return [NSString stringWithFormat:
				@"4 %@ %@ %@ %@ %@ %@ %@ %@ %@ %@ %@ %@ %@",
				[LDrawUtilities outputStringForColorCode:self->color RGB:self->glColor],
				
				[LDrawUtilities outputStringForFloat:vertex1.x],
				[LDrawUtilities outputStringForFloat:vertex1.y],
				[LDrawUtilities outputStringForFloat:vertex1.z],
				
				[LDrawUtilities outputStringForFloat:vertex2.x],
				[LDrawUtilities outputStringForFloat:vertex2.y],
				[LDrawUtilities outputStringForFloat:vertex2.z],
				
				[LDrawUtilities outputStringForFloat:vertex3.x],
				[LDrawUtilities outputStringForFloat:vertex3.y],
				[LDrawUtilities outputStringForFloat:vertex3.z],
		
				[LDrawUtilities outputStringForFloat:vertex4.x],
				[LDrawUtilities outputStringForFloat:vertex4.y],
				[LDrawUtilities outputStringForFloat:vertex4.z]
		
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
	return NSLocalizedString(@"Quadrilateral", nil);
	
}//end browsingDescription


//========== iconName ==========================================================
//
// Purpose:		Returns the name of image file used to display this kind of 
//				object, or nil if there is no icon.
//
//==============================================================================
- (NSString *) iconName
{
	return @"Quadrilateral";
	
}//end iconName


//========== inspectorClassName ================================================
//
// Purpose:		Returns the name of the class used to inspect this one.
//
//==============================================================================
- (NSString *) inspectorClassName
{
	return @"InspectionQuadrilateral";
	
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
	Box3 bounds	= InvalidBox;
	
	bounds = V3BoundsFromPoints(vertex1, vertex2);
	bounds = V3UnionBoxAndPoint(bounds, vertex3);
	bounds = V3UnionBoxAndPoint(bounds, vertex4);
	
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


//========== vertex4 ===========================================================
//==============================================================================
- (Point3) vertex4
{
	return self->vertex4;
	
}//end vertex4


#pragma mark -

//========== setVertex1: =======================================================
//
// Purpose:		Sets the quadrilateral's first vertex.
//
//==============================================================================
-(void) setVertex1:(Point3)newVertex
{
	self->vertex1 = newVertex;
	[self recomputeNormal];
	
}//end setVertex1:


//========== setVertex2: =======================================================
//
// Purpose:		Sets the quadrilateral's second vertex.
//
//==============================================================================
-(void) setVertex2:(Point3)newVertex
{
	self->vertex2 = newVertex;
	[self recomputeNormal];
	
}//end setVertex2:


//========== setVertex3: =======================================================
//
// Purpose:		Sets the quadrilateral's third vertex.
//
//==============================================================================
-(void) setVertex3:(Point3)newVertex
{
	self->vertex3 = newVertex;
	[self recomputeNormal];
	
}//end setVertex3:


//========== setVertex4: =======================================================
//
// Purpose:		Sets the quadrilateral's fourth vertex.
//
//==============================================================================
-(void) setVertex4:(Point3)newVertex
{
	self->vertex4 = newVertex;
	[self recomputeNormal];
	
}//end setVertex4:


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
	
	vector1_2 = V3Sub(self->vertex2, self->vertex1);
	vector1_4 = V3Sub(self->vertex4, self->vertex1);
	vector3_4 = V3Sub(self->vertex4, self->vertex3);
	vector3_2 = V3Sub(self->vertex2, self->vertex3);
	vector4_1 = V3Sub(self->vertex1, self->vertex4);
	vector4_3 = V3Sub(self->vertex3, self->vertex4);
	
	cross1 = V3Cross(vector1_2, vector1_4);
	cross3 = V3Cross(vector3_4, vector3_2);
	cross4 = V3Cross(vector4_1, vector4_3);
	
	//When crosses point different directions, we have a bowtie. To test this, 
	// recall that cos x = (u • v) / (||u|| ||v||)
	// cos(180) = -1 and cos(0) = 1. So if u•v is negative, we have opposing 
	// vectors (since the denominator is always positive, we can ignore it).
	
	//If 1 & 4 point opposite directions, we have a case 1 bowtie
	if(V3Dot(cross1, cross4) < 0)
	{
		//vectors point in opposite directions
		Point3 swapPoint = self->vertex3;
		vertex3 = vertex4;
		vertex4 = swapPoint;
	}
	//If 3 & 4 point opposite directions, we have a case 2 bowtie
	else if(V3Dot(cross3, cross4) < 0)
	{
		Point3 swapPoint = self->vertex2;
		vertex2 = vertex3;
		vertex3 = swapPoint;
	}
	
}//end fixBowtie


//========== flattenIntoLines:triangles:quadrilaterals:other:currentColor: =====
//
// Purpose:		Appends the directive into the appropriate container. 
//
//==============================================================================
- (void) flattenIntoLines:(LDrawStep *)lines
				triangles:(LDrawStep *)triangles
		   quadrilaterals:(LDrawStep *)quadrilaterals
					other:(LDrawStep *)everythingElse
			 currentColor:(LDrawColorT)parentColor
		 currentTransform:(Matrix4)transform
		  normalTransform:(Matrix3)normalTransform
{
	[super flattenIntoLines:lines
				  triangles:triangles
			 quadrilaterals:quadrilaterals
					  other:everythingElse
			   currentColor:parentColor
		   currentTransform:transform
			normalTransform:normalTransform];
	
	self->vertex1   = V3MulPointByProjMatrix(self->vertex1, transform);
	self->vertex2   = V3MulPointByProjMatrix(self->vertex2, transform);
	self->vertex3   = V3MulPointByProjMatrix(self->vertex3, transform);
	self->vertex4   = V3MulPointByProjMatrix(self->vertex4, transform);
	
	self->normal    = V3MulPointByMatrix(self->normal, normalTransform);
	
	[quadrilaterals addDirective:self];
	
}//end flattenIntoLines:triangles:quadrilaterals:other:currentColor:


//========== recomputeNormal ===================================================
//
// Purpose:		Finds the normal vector for this surface.
//
//==============================================================================
- (void) recomputeNormal
{
	Vector3 vector1, vector2;
	
	vector1 = V3Sub(self->vertex2, self->vertex1);
	vector2 = V3Sub(self->vertex4, self->vertex1);
	
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
	
	[[undoManager prepareWithInvocationTarget:self] setVertex4:[self vertex4]];
	[[undoManager prepareWithInvocationTarget:self] setVertex3:[self vertex3]];
	[[undoManager prepareWithInvocationTarget:self] setVertex2:[self vertex2]];
	[[undoManager prepareWithInvocationTarget:self] setVertex1:[self vertex1]];
	
	[undoManager setActionName:NSLocalizedString(@"UndoAttributesQuadrilateral", nil)];
	
}//end registerUndoActions:


@end

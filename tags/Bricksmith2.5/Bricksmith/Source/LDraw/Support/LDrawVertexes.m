//==============================================================================
//
// File:		LDrawVertexes.m
//
// Purpose:		Receives primitives and transfers their vertexes into an 
//				OpenGL-optimized object. Drawing instances of this object will 
//				draw all the contained vertexes. 
//
// Notes:		OpenGL has historically offered several ways of submitting 
//				vertexes, most of which proved highly suboptimal for graphics 
//				cards. Regretfully, those were also the easiest ones to program. 
//
//				Since immediate mode is deprecated and on its way out (and 
//				display lists with it), Bricksmith must resort to this 
//				intermediary object which collects, packs into a buffer, and 
//				draws all the vertexes for a model's geometry. 
//
// Modified:	11/16/2010 Allen Smith. Creation Date.
//
//==============================================================================
#import "LDrawVertexes.h"

#import "LDrawLine.h"
#import "LDrawTriangle.h"
#import "LDrawQuadrilateral.h"
#import "MacLDraw.h"

static void DeleteOptimizationTags(struct OptimizationTags tags);

@implementation LDrawVertexes

//========== init ==============================================================
//
// Purpose:		Initialize the object.
//
//==============================================================================
- (id) init
{
    self = [super init];
    if (self)
	{
		self->lines                 = [[NSMutableArray alloc] init];
		self->triangles             = [[NSMutableArray alloc] init];
		self->quadrilaterals        = [[NSMutableArray alloc] init];
		self->everythingElse        = [[NSMutableArray alloc] init];
		
		self->colorOptimizations    = [[NSMutableDictionary alloc] init];
    }
    return self;
}


#pragma mark -
#pragma mark DRAWING
#pragma mark -

//========== draw:parentColor: =================================================
//
// Purpose:		Submits the vertex buffer object to OpenGL.
//
// Notes:		This instance is now the only routine in Bricksmith actually 
//				capable of drawing pixels. All the other draw routines just 
//				figure out what to draw; with the demise of immediate-mode 
//				rendering, no directive is actually capable of rendering itself 
//				in isolation. 
//
//==============================================================================
- (void) draw:(NSUInteger)optionsMask parentColor:(LDrawColor *)color
{
	id                      key     = color;
	NSValue                 *value  = [self->colorOptimizations objectForKey:key];
	struct OptimizationTags tags    = {};

	[value getValue:&tags];
	
	// Feh! VBOs+VAOs are 22% slower than display lists. So I'm using display 
	// lists even though everyone says not to. 
	//
	// On the bright side, the display list contains nothing but a VAO, so I 
	// have an "upgrade" path if needed! 
	
	if(tags.displayListTag)
	{
		glCallList(tags.displayListTag);
	}
	else
	{
		// Display lists with VAOs don't work on 10.5
	
		// Lines
		glBindVertexArrayAPPLE(tags.linesVAOTag);
		glDrawArrays(GL_LINES, 0, tags.lineCount * 2);
		
		// Triangles
		glBindVertexArrayAPPLE(tags.trianglesVAOTag);
		glDrawArrays(GL_TRIANGLES, 0, tags.triangleCount * 3);
		
		// Quadrilaterals
		glBindVertexArrayAPPLE(tags.quadsVAOTag);
		glDrawArrays(GL_QUADS, 0, tags.quadCount * 4);
	}
}


#pragma mark -
#pragma mark ACCESSORS
#pragma mark -

//========== isOptimizedForColor: ==============================================
//
// Purpose:		Has a cached optimization for the given color.
//
//==============================================================================
- (BOOL) isOptimizedForColor:(LDrawColor *)color
{
	id      key     = color;
	NSValue *value  = [self->colorOptimizations objectForKey:key];
	
	return (value != nil);
}


//========== setLines:triangles:quadrilaterals:other: ==========================
//
// Purpose:		Sets the primitives this container will be responsible for 
//				converting into a vertex array and drawing. 
//
//==============================================================================
- (void) setLines:(NSArray *)linesIn
		triangles:(NSArray *)trianglesIn
   quadrilaterals:(NSArray *)quadrilateralsIn
			other:(NSArray *)everythingElseIn
{
	[self->lines			removeAllObjects];
	[self->triangles		removeAllObjects];
	[self->quadrilaterals	removeAllObjects];
	[self->everythingElse	removeAllObjects];
	
	[self->lines			addObjectsFromArray:linesIn];
	[self->triangles		addObjectsFromArray:trianglesIn];
	[self->quadrilaterals	addObjectsFromArray:quadrilateralsIn];
	[self->everythingElse	addObjectsFromArray:everythingElseIn];
	
}//end setLines:triangles:quadrilaterals:other:


#pragma mark -

//========== addDirective: =====================================================
//
// Purpose:		Register a directive of an arbitrary type (type will be deduced 
//				correctly). 
//
//==============================================================================
- (void) addDirective:(LDrawDirective *)directive
{
	if([directive isMemberOfClass:[LDrawLine class]])
	{
		[self addLine:(LDrawLine*)directive];
	}
	else if([directive isKindOfClass:[LDrawTriangle class]])
	{
		[self addTriangle:(LDrawTriangle*)directive];
	}
	else if([directive isKindOfClass:[LDrawQuadrilateral class]])
	{
		[self addQuadrilateral:(LDrawQuadrilateral*)directive];
	}
	else
	{
		[self addOther:directive];
	}

}//end addDirective:


//========== addLine: ==========================================================
//
// Purpose:		Register a line to be included in the optimized vertexes. The 
//				object must be re-optimized now. 
//
//==============================================================================
- (void) addLine:(LDrawLine *)line
{
	[self->lines addObject:line];
}


//========== addTriangle: ======================================================
//
// Purpose:		Register a triangle to be included in the optimized vertexes. 
//				The object must be re-optimized now. 
//
//==============================================================================
- (void) addTriangle:(LDrawTriangle *)triangle
{
	[self->triangles addObject:triangle];
}


//========== addQuadrilateral: =================================================
//
// Purpose:		Register a quadrilateral to be included in the optimized 
//				vertexes. The object must be re-optimized now. 
//
//==============================================================================
- (void) addQuadrilateral:(LDrawQuadrilateral *)quadrilateral
{
	[self->quadrilaterals addObject:quadrilateral];
}


//========== addOther: =========================================================
//
// Purpose:		Register a other to be included in the optimized vertexes. The 
//				object must be re-optimized now. 
//
//==============================================================================
- (void) addOther:(LDrawDirective *)other
{
	[self->everythingElse addObject:other];
}


#pragma mark -

//========== removeDirective: ==================================================
//
// Purpose:		Register a directive of an arbitrary type (type will be deduced 
//				correctly). 
//
//==============================================================================
- (void) removeDirective:(LDrawDirective *)directive
{
	if([directive isMemberOfClass:[LDrawLine class]])
	{
		[self removeLine:(LDrawLine*)directive];
	}
	else if([directive isKindOfClass:[LDrawTriangle class]])
	{
		[self removeTriangle:(LDrawTriangle*)directive];
	}
	else if([directive isKindOfClass:[LDrawQuadrilateral class]])
	{
		[self removeQuadrilateral:(LDrawQuadrilateral*)directive];
	}
	else
	{
		[self removeOther:directive];
	}
	
}//end removeDirective:


//========== removeLine: =======================================================
//
// Purpose:		De-registers a line to be included in the optimized vertexes. 
//				The object must be re-optimized now. 
//
//==============================================================================
- (void) removeLine:(LDrawLine *)line
{
	[self->lines removeObjectIdenticalTo:line];
}


//========== removeTriangle: ===================================================
//
// Purpose:		De-registers a line to be included in the optimized vertexes. 
//				The object must be re-optimized now. 
//
//==============================================================================
- (void) removeTriangle:(LDrawTriangle *)triangle
{
	[self->triangles removeObjectIdenticalTo:triangle];
}


//========== removeQuadrilateral: ==============================================
//
// Purpose:		De-registers a quadrilateral to be included in the optimized 
//				vertexes. The object must be re-optimized now. 
//
//==============================================================================
- (void) removeQuadrilateral:(LDrawQuadrilateral *)quadrilateral
{
	[self->quadrilaterals removeObjectIdenticalTo:quadrilateral];
}


//========== removeOther: ======================================================
//
// Purpose:		De-registers a other to be included in the optimized vertexes. 
//				The object must be re-optimized now. 
//
//==============================================================================
- (void) removeOther:(LDrawDirective *)other
{
	[self->everythingElse removeObjectIdenticalTo:other];
}


#pragma mark -
#pragma mark OPTIMIZE
#pragma mark -

//========== optimizeOpenGLWithParentColor: ====================================
//
// Purpose:		The caller is asking this instance to optimize itself for faster 
//				drawing. 
//
//				OpenGL optimization is not thread-safe. No OpenGL optimization 
//				is ever performed during parsing because of the thread-safety 
//				limitation, so you are responsible for calling this method on 
//				newly-parsed models. 
//
//==============================================================================
- (void) optimizeOpenGLWithParentColor:(LDrawColor *)color
{
	VBOVertexData           *buffer                 = NULL;
	struct OptimizationTags tags                    = {};
	
	//---------- Lines VBO -----------------------------------------------------
	{
		glGenBuffers(1, &tags.linesVBOTag);
		glBindBuffer(GL_ARRAY_BUFFER, tags.linesVBOTag);
		
		size_t          linesBufferSize     = [self->lines count] * sizeof(VBOVertexData) * 2;
		VBOVertexData   *lineVertexes       = malloc(linesBufferSize);
		
		buffer = lineVertexes;
		for(LDrawQuadrilateral *currentDirective in self->lines)
		{
			if([currentDirective isHidden] == NO)
			{
				buffer = [currentDirective writeToVertexBuffer:buffer parentColor:color];
				tags.lineCount++;
			}
		}
		
		glBufferData(GL_ARRAY_BUFFER, linesBufferSize, lineVertexes, GL_STATIC_DRAW);
		free(lineVertexes);
		glBindBuffer(GL_ARRAY_BUFFER, 0);

		// Encapsulate in a VAO
		glGenVertexArraysAPPLE(1, &tags.linesVAOTag);
		glBindVertexArrayAPPLE(tags.linesVAOTag);
		glEnableClientState(GL_VERTEX_ARRAY);
		glEnableClientState(GL_NORMAL_ARRAY);
		glEnableClientState(GL_COLOR_ARRAY);
		glBindBuffer(GL_ARRAY_BUFFER, tags.linesVBOTag);
		glVertexPointer(3, GL_FLOAT, sizeof(VBOVertexData), NULL);
		glNormalPointer(GL_FLOAT,    sizeof(VBOVertexData), (GLvoid*)(sizeof(float)*3));
		glColorPointer(4, GL_FLOAT,  sizeof(VBOVertexData), (GLvoid*)(sizeof(float)*3 + sizeof(float)*3) );
	}
	
	//---------- Triangles VBO -------------------------------------------------
	{
		glGenBuffers(1, &tags.trianglesVBOTag);
		glBindBuffer(GL_ARRAY_BUFFER, tags.trianglesVBOTag);
		
		size_t          trianglesBufferSize = [self->triangles count] * sizeof(VBOVertexData) * 3;
		VBOVertexData   *triangleVertexes   = malloc(trianglesBufferSize);
		
		buffer = triangleVertexes;
		for(LDrawQuadrilateral *currentDirective in self->triangles)
		{
			if([currentDirective isHidden] == NO)
			{
				buffer = [currentDirective writeToVertexBuffer:buffer parentColor:color];
				tags.triangleCount++;
			}
		}
		
		glBufferData(GL_ARRAY_BUFFER, trianglesBufferSize, triangleVertexes, GL_STATIC_DRAW);
		free(triangleVertexes);
		glBindBuffer(GL_ARRAY_BUFFER, 0);
		
		// Encapsulate in a VAO
		glGenVertexArraysAPPLE(1, &tags.trianglesVAOTag);
		glBindVertexArrayAPPLE(tags.trianglesVAOTag);
		glEnableClientState(GL_VERTEX_ARRAY);
		glEnableClientState(GL_NORMAL_ARRAY);
		glEnableClientState(GL_COLOR_ARRAY);
		glBindBuffer(GL_ARRAY_BUFFER, tags.trianglesVAOTag);
		glVertexPointer(3, GL_FLOAT, sizeof(VBOVertexData), NULL);
		glNormalPointer(GL_FLOAT,    sizeof(VBOVertexData), (GLvoid*)(sizeof(float)*3));
		glColorPointer(4, GL_FLOAT,  sizeof(VBOVertexData), (GLvoid*)(sizeof(float)*3 + sizeof(float)*3) );
	}
	
	//---------- Quadrilaterals VBO --------------------------------------------
	{
		glGenBuffers(1, &tags.quadsVBOTag);
		glBindBuffer(GL_ARRAY_BUFFER, tags.quadsVBOTag);
		
		size_t          quadsBufferSize  = [self->quadrilaterals count] * sizeof(VBOVertexData) * 4;
		VBOVertexData   *quadVertexes   = malloc(quadsBufferSize);
		
		buffer = quadVertexes;
		for(LDrawQuadrilateral *currentDirective in self->quadrilaterals)
		{
			if([currentDirective isHidden] == NO)
			{
				buffer = [currentDirective writeToVertexBuffer:buffer parentColor:color];
				tags.quadCount++;
			}
		}
		
		glBufferData(GL_ARRAY_BUFFER, quadsBufferSize, quadVertexes, GL_STATIC_DRAW);
		free(quadVertexes);
		glBindBuffer(GL_ARRAY_BUFFER, 0);
		
		// Encapsulate in a VAO
		glGenVertexArraysAPPLE(1, &tags.quadsVAOTag);
		glBindVertexArrayAPPLE(tags.quadsVAOTag);
		glEnableClientState(GL_VERTEX_ARRAY);
		glEnableClientState(GL_NORMAL_ARRAY);
		glEnableClientState(GL_COLOR_ARRAY);
		glBindBuffer(GL_ARRAY_BUFFER, tags.quadsVBOTag);
		glVertexPointer(3, GL_FLOAT, sizeof(VBOVertexData), NULL);
		glNormalPointer(GL_FLOAT,    sizeof(VBOVertexData), (GLvoid*)(sizeof(float)*3));
		glColorPointer(4, GL_FLOAT,  sizeof(VBOVertexData), (GLvoid*)(sizeof(float)*3 + sizeof(float)*3) );
	}
	
	//---------- Wrap it all in a display list ---------------------------------
	
	// Display lists are 28% faster than VAOs. What the heck?
	
	// But you can't embed multiple VAOs in a display list on 10.5. (Not 
	// documented; experimentally determined.) 
	static SInt32  systemVersion  = 0;
	static BOOL    useDisplayList = YES;
	if(systemVersion == 0)
	{
		Gestalt(gestaltSystemVersion, &systemVersion);
		useDisplayList = (systemVersion >= 0x1060);
	}
	
	if(useDisplayList)
	{
		tags.displayListTag = glGenLists(1);
		glNewList(tags.displayListTag, GL_COMPILE);
		{
			// Lines
			glBindVertexArrayAPPLE(tags.linesVAOTag);
			glDrawArrays(GL_LINES, 0, tags.lineCount * 2);
			
			// Triangles
			glBindVertexArrayAPPLE(tags.trianglesVAOTag);
			glDrawArrays(GL_TRIANGLES, 0, tags.triangleCount * 3);
			
			// Quadrilaterals
			glBindVertexArrayAPPLE(tags.quadsVAOTag);
			glDrawArrays(GL_QUADS, 0, tags.quadCount * 4);
		}
		glEndList();
	}
	
	// Cache
	id      key     = color;
	NSValue *value  = [NSValue valueWithBytes:&tags objCType:@encode(struct OptimizationTags)];
	[self->colorOptimizations setObject:value forKey:key];
	
}//end optimizeOpenGL


//========== rebuildAllOptimizations ===========================================
//
// Purpose:		Regenerates the optimized OpenGL structures for all existing 
//				optimized colors. 
//
//==============================================================================
- (void) rebuildAllOptimizations
{
	NSArray *allColors = [self->colorOptimizations allKeys];
	
	[self removeAllOptimizations];
	
	// Rebuild all optimizations
	for(LDrawColor *color in allColors)
	{
		[self optimizeOpenGLWithParentColor:color];
	}
}//end rebuildAllOptimizations


//========== removeAllOptimizations ============================================
//
// Purpose:		Deletes all the optimizations for the vertexes.
//
//==============================================================================
- (void) removeAllOptimizations
{
	// Remove all existing optimizations
	for(LDrawColor *color in self->colorOptimizations)
	{
		NSValue                 *value  = [self->colorOptimizations objectForKey:color];
		struct OptimizationTags tags    = {};
		
		[value getValue:&tags];
		
		DeleteOptimizationTags(tags);
	}
	
	[self->colorOptimizations removeAllObjects];
	
}//end removeAllOptimizations


#pragma mark -
#pragma mark DESTRUCTOR
#pragma mark -

//========== dealloc ===========================================================
//
// Purpose:		It's a permanent flush.
//
//==============================================================================
- (void) dealloc
{
	[self removeAllOptimizations];
	
	[lines				release];
	[triangles			release];
	[quadrilaterals		release];
	[everythingElse		release];
	
	[colorOptimizations	release];

	[super dealloc];
	
}//end dealloc


@end


//========== DeleteOptimizationTags ============================================
//
// Purpose:		Removes the optimized objects in the tag list.
//
//==============================================================================
void DeleteOptimizationTags(struct OptimizationTags tags)
{
	if(tags.displayListTag != 0)
	{
		glDeleteLists(tags.displayListTag, 1);
		
		glDeleteBuffers(1, &tags.linesVBOTag);
		glDeleteBuffers(1, &tags.trianglesVBOTag);
		glDeleteBuffers(1, &tags.quadsVBOTag);
		
		glDeleteVertexArraysAPPLE(1, &tags.linesVAOTag);
		glDeleteVertexArraysAPPLE(1, &tags.trianglesVAOTag);
		glDeleteVertexArraysAPPLE(1, &tags.quadsVAOTag);
		
		tags.displayListTag     = 0;
		tags.linesVBOTag        = 0;
		tags.trianglesVBOTag    = 0;
		tags.quadsVBOTag        = 0;
		tags.linesVAOTag        = 0;
		tags.trianglesVAOTag    = 0;
		tags.quadsVAOTag        = 0;
	}
}
/*
 *  MatrixMath.h
 *
 * Stolen heavily from GraphicsGems.h  
 * Version 1.0 - Andrew Glassner
 * from "Graphics Gems", Academic Press, 1990
 */

#import <OpenGL/GL.h>

#pragma mark Data Types
#pragma mark -

//Transformation components; the data encoded in a transformation matrix.
typedef struct {
 	float scale_X;
 	float scale_Y;
 	float scale_Z;
 	float shear_XY;
 	float shear_XZ;
 	float shear_YZ;
 	float rotate_X; //in radians
 	float rotate_Y; //in radians
 	float rotate_Z; //in radians
 	float translate_X;
 	float translate_Y;
 	float translate_Z;
 	float perspective_X;
 	float perspective_Y;
 	float perspective_Z;
 	float perspective_W;
} TransformationComponents;


/*********************/
/* 3d geometry types */
/*********************/

typedef struct Point3Struct {	/* 3d point */
float x, y, z;
} Point3, Vector3, Tuple3;

typedef struct IntPoint3Struct {	/* 3d integer point */
int x, y, z;
} IntPoint3;


typedef struct Box3dStruct {		/* 3d box */
	Point3 min, max;
} Box3;


typedef struct Matrix3Struct {	/* 3-by-3 matrix */
	float element[3][3];
} Matrix3;

/*********************/
/* 4d geometry types */
/*********************/


//4-by-4 matrix
typedef struct Matrix4Struct {
	float element[4][4];
} Matrix4;

// 4-component vector
typedef struct {
	float x,y,z,w;
} Point4, Vector4;


#pragma mark -
#pragma mark Constants
#pragma mark -

#define PI				3.141592654
#define SMALL_NUMBER	1.e-8

extern const Box3						InvalidBox;
extern const TransformationComponents	IdentityComponents;

#pragma mark -
#pragma mark Macros
#pragma mark -
/***********************/
/* macros              */
/***********************/

//Radians to Degrees
#define degrees(radians) ( (radians) * 180/PI)

//Degrees to Radians
#define radians(degrees) ( (degrees) * PI/180)


/* find minimum of a and b */
// Defined for us by Objective-C
#if !defined(MIN)
#define MIN(a,b)	(((a)<(b))?(a):(b))	
#endif

/* find maximum of a and b */
#if !defined(MAX)
#define MAX(a,b)	(((a)>(b))?(a):(b))	
#endif

/* swap a and b (see Gem by Wyvill) */
#define SWAP(a,b)	{ a^=b; b^=a; a^=b; }

/* linear interpolation from l (when a=0) to h (when a=1)*/
/* (equal to (a*h)+((1-a)*l) */
#define LERP(a,l,h)	((l)+(((h)-(l))*(a)))

/* clamp the input to the specified range */
#define CLAMP(v,l,h)	((v)<(l) ? (l) : (v) > (h) ? (h) : v)


/****************************/
/* memory allocation macros */
/****************************/

/* create a new instance of a structure (see Gem by Hultquist) */
#define NEWSTRUCT(x)	(struct x *)(malloc((unsigned)sizeof(struct x)))

/* create a new instance of a type */
#define NEWTYPE(x)	(x *)(malloc((unsigned)sizeof(x)))

#pragma mark -
#pragma mark Prototypes
#pragma mark -

extern float	det2x2( float, float, float, float);

extern Vector3*	V3New(float x, float y, float z);
extern Vector3*	V3Duplicate(Vector3 *a);
extern Vector3	V3FromV4(Vector4 *originalVector);
extern float	V3SquaredLength(Vector3 *);
extern float	V3Length(Vector3 *);
extern float	V3Dot(Vector3 *a, Vector3 *b);
extern float	V3DistanceBetween2Points(Point3 *a, Point3 *b);
extern Vector3*	V3Normalize(Vector3 *);
extern Vector3*	V3Scale(Vector3 *, float);
extern Vector3*	V3Add(Vector3 *a, Vector3 *b, Vector3 *c);
extern Vector3*	V3Sub(Vector3 *a, Vector3 *b, Vector3 *c);
extern Vector3*	V3Lerp(Vector3 *lo, Vector3 *hi, float alpha, Vector3 *result);
extern Vector3*	V3Combine(Vector3 *a, Vector3 *b, Vector3 *result, float ascl, float bscl);
extern Vector3*	V3Mul(Vector3 *a, Vector3 *b, Vector3 *result);
extern Vector3*	V3Cross(Vector3 *a, Vector3 *b, Vector3 *c);
extern Point3	V3Midpoint(Point3 *point1, Point3 *point2);
extern Box3*	V3BoundsFromPoints();
extern int		V3EqualsBoxes(const Box3 *box1, const Box3 *box2);
extern Vector3*	V3IsolateGreatestComponent(Vector3 *vector);
extern Point3*	V3MulPointByMatrix();
extern Vector3*	V3MulPointByProjMatrix();
extern Matrix4*	V3MatMul(Matrix4 *a, Matrix4 *b, Matrix4 *c);
extern float	det3x3( float, float, float, float, float, float, float, float, float );

extern Vector4	V4FromV3(Vector3 *originalVector);
extern Matrix4	matrix4FromGLMatrix4(const GLfloat *glMatrix);
extern Matrix4	createTransformationMatrix(TransformationComponents *);
extern int		unmatrix( Matrix4 *, TransformationComponents *);
extern Matrix4*	rotateMatrix4(Matrix4 *original, Tuple3 *degreesToRotate, Matrix4 *result);
extern Matrix4*	translateMatrix4(Matrix4 *original, Vector3 *displacement, Matrix4 *result);
extern Matrix4*	transposeMatrix4(Matrix4 *, Matrix4 *);
extern Vector4*	V4MulPointByMatrix(Vector4 *, Matrix4 *, Vector4 *);
extern void		inverse( Matrix4 *, Matrix4 * );
extern void		adjoint( Matrix4 *, Matrix4 * );
extern float	det4x4( Matrix4 * );

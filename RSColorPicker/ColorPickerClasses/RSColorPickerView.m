//
//  RSColorPickerView.m
//  RSColorPicker
//
//  Created by Ryan Sullivan on 8/12/11.
//  Copyright 2011 Freelance Web Developer. All rights reserved.
//

#import "RSColorPickerView.h"
#import "BGRSLoupeLayer.h"
#import "RSBrightnessSlider.h"

// point-related macros
#define INNER_P(x) (x < 0 ? ceil(x) : floor(x))
#define IS_INSIDE(p) (round(p.x) >= 0 && round(p.x) < self.frame.size.width && round(p.y) >= 0 && round(p.y) < self.frame.size.height)

// Concept-code from http://www.easyrgb.com/index.php?X=MATH&H=21#text21
BMPixel pixelFromHSV(CGFloat H, CGFloat S, CGFloat V) {
	if (S == 0) {
		return BMPixelMake(V, V, V, 1.0);
	}
	CGFloat var_h = H * 6.0;
	if (var_h == 6.0) {
		var_h = 0.0;
	}
	CGFloat var_i = floor(var_h);
	CGFloat var_1 = V * (1.0 - S);
	CGFloat var_2 = V * (1.0 - S * (var_h - var_i));
	CGFloat var_3 = V * (1.0 - S * (1.0 - (var_h - var_i)));
	
	if (var_i == 0) {
		return BMPixelMake(V, var_3, var_1, 1.0);
	} else if (var_i == 1) {
		return BMPixelMake(var_2, V, var_1, 1.0);
	} else if (var_i == 2) {
		return BMPixelMake(var_1, V, var_3, 1.0);
	} else if (var_i == 3) {
		return BMPixelMake(var_1, var_2, V, 1.0);
	} else if (var_i == 4) {
		return BMPixelMake(var_3, var_1, V, 1.0);
	}
	return BMPixelMake(V, var_1, var_2, 1.0);
}
/**
 * Conversion from red, green and blue to hue, saturation and brightness
 * @Reference: Taken from ars/uicolor-utilities 
 * http://github.com/ars/uicolor-utilities
 */
void rgbToHsv(CGFloat r,   /* IN: Red */
              CGFloat g,   /* IN: Green */
              CGFloat b,   /* IN: Blue */
              CGFloat *pH, /* OUT: Hue */
              CGFloat *pS, /* OUT: Saturation */
              CGFloat *pV) /* OUT: Brightness */
{
	CGFloat h,s,v;
	
	// From Foley and Van Dam
	
	CGFloat max = MAX(r, MAX(g, b));
	CGFloat min = MIN(r, MIN(g, b));
	
	// Brightness
	v = max;
	
	// Saturation
	s = (max != 0.0f) ? ((max - min) / max) : 0.0f;
	
	if (s == 0.0f) {
		// No saturation, so undefined hue
		h = 0.0f;
	} else {
		// Determine hue
		CGFloat rc = (max - r) / (max - min);		// Distance of color from red
		CGFloat gc = (max - g) / (max - min);		// Distance of color from green
		CGFloat bc = (max - b) / (max - min);		// Distance of color from blue
		
		if (r == max) h = bc - gc;                // resulting color between yellow and magenta
		else if (g == max) h = 2 + rc - bc;			// resulting color between cyan and yellow
		else /* if (b == max) */ h = 4 + gc - rc;	// resulting color between magenta and cyan
		
		h *= 60.0f;									// Convert to degrees
		if (h < 0.0f) h += 360.0f;				// Make non-negative
		h /= 360.0f;                        // Convert to decimal
	}
	
	if (pH) *pH = h;
   if (pS) *pS = s;
   if (pV) *pV = v;
}

@interface RSColorPickerView () //Private Methods
-(void)setup;
-(void)genBitmap;
-(void)updateSelectionLocation;
-(CGPoint)validPointForTouch:(CGPoint)touchPoint;
@end


@implementation RSColorPickerView

@synthesize brightness, cropToCircle, delegate, isOrthoganal, brightnessSlider;
@dynamic selectionColor;

#pragma mark - Setup & Teardown
//--------------------------------------------------------------------------------------------------

- (id)initWithFrame:(CGRect)frame
{
	CGFloat sqr = fmin(frame.size.height, frame.size.width);
	frame.size = CGSizeMake(sqr, sqr);
	
	self = [super initWithFrame:frame];
	if (self) {
      [self setup];
	}
	return self;
}

// For Use with Nib.
-(id)initWithCoder:(NSCoder *)aDecoder{ 
	if((self = [super initWithCoder:aDecoder])){
      [self setup];
   }
   return self;
}

/**
 * Setup code preformed for both initWithCoder when used in a nib and initWithFrame 
 * when used progromaticly
 */
- (void)setup{
   cropToCircle = YES;
   badTouch = NO;
   bitmapNeedsUpdate = YES;
   
   CGFloat sqr = self.bounds.size.width;
   selection = CGPointMake(sqr/2, sqr/2);
   selectionView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 18.0, 18.0)];
   selectionView.backgroundColor = [UIColor clearColor];
   selectionView.layer.borderWidth = 2.0;
   selectionView.layer.borderColor = [UIColor colorWithWhite:0.1 alpha:1.0].CGColor;
   selectionView.layer.cornerRadius = 9.0;
   [self updateSelectionLocation];
   [self addSubview:selectionView];
   
   self.brightness = 1.0;
   rep = [[ANImageBitmapRep alloc] initWithSize:BMPointFromSize(self.frame.size)];
}

- (void)dealloc
{
	[rep release];
	[selectionView release];
   [loupeLayer release];
   loupeLayer = nil;
   self.brightnessSlider = nil;
   self.delegate = nil;
   
	[super dealloc];
}

#pragma mark - Display Properties
//--------------------------------------------------------------------------------------------------

-(void)setBrightness:(CGFloat)bright {
	brightness = bright;
	bitmapNeedsUpdate = YES;
	[self setNeedsDisplay];
}

-(void)setCropToCircle:(BOOL)circle {
	if (circle == cropToCircle) { return; }
	cropToCircle = circle;
   bitmapNeedsUpdate = YES;
	[self setNeedsDisplay];
}

-(void)setIsOrthoganal:(BOOL)isOrthoganal_{
   if (isOrthoganal_ == isOrthoganal){return;}
   isOrthoganal = isOrthoganal_;
   bitmapNeedsUpdate = YES;
   [self setNeedsDisplay];
}

#pragma mark - Drawing
//--------------------------------------------------------------------------------------------------

-(void)genBitmap {
	if (!bitmapNeedsUpdate) { return; }
	CGSize  size = self.frame.size;
	CGFloat radius = (size.width / 2.0);
	CGFloat relX = 0.0;
	CGFloat relY = 0.0;
	
	for (int x = 0; x < size.width; x++) {
		relX = (self.isOrthoganal ? x/size.width : x - radius);
		
		for (int y = 0; y < size.height; y++) {
			BMPixel thisPixel;
			
			if (isOrthoganal){
				relY = 1- y/size.width;
				thisPixel = pixelFromHSV(relX, relY, self.brightness);
			}else{
				relY = radius - y;
				
				CGFloat r_distance = sqrt((relX * relX)+(relY * relY));
				if (fabsf(r_distance) > radius && cropToCircle == YES) {
					[rep setPixel:BMPixelMake(0.0, 0.0, 0.0, 0.0) atPoint:BMPointMake(x, y)];
					continue;
				}
				r_distance = fmin(r_distance, radius);
				
				CGFloat angle = atan2(relY, relX);
				if (angle < 0.0) { angle = (2.0 * M_PI)+angle; }
				
				CGFloat perc_angle = angle / (2.0 * M_PI);
				thisPixel = pixelFromHSV(perc_angle, r_distance/radius, self.brightness);
			}
			[rep setPixel:thisPixel atPoint:BMPointMake(x, y)];
		}
	}
	bitmapNeedsUpdate = NO;
}


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
   [self genBitmap];
	[[rep image] drawInRect:rect];
}

#pragma mark - Setting and Getting of Color / Selection
//--------------------------------------------------------------------------------------------------

-(UIColor*)selectionColor {
   [self genBitmap];        //Make sure bitmap is uptodate before getting selection color
	return UIColorFromBMPixel([rep getPixelAtPoint:BMPointFromPoint(selection)]);
}
-(void)setSelectionColor:(UIColor*)color{
   const CGFloat *components = CGColorGetComponents(color.CGColor);
   
   CGFloat r,g,b;
	
   CGColorSpaceModel colorSpaceModel = CGColorSpaceGetModel(CGColorGetColorSpace(color.CGColor));
   
	switch (colorSpaceModel) {
		case kCGColorSpaceModelMonochrome:
			r = g = b = components[0];
			break;
		case kCGColorSpaceModelRGB:
			r = components[0];
			g = components[1];
			b = components[2];
			break;
		default:	// We don't know how to handle this model
         r = g = b = 0;
	}

   // Convert RGB to HSV
   CGFloat h,s,v;                   // Hue, Saturation, Brightness;
   CGSize size = self.bounds.size;
   
   rgbToHsv(r, g, b, &h, &s, &v);
   
   //Set Selection from HSV
   if (self.isOrthoganal){
      selection.x = h*size.width;
      selection.y = (1-s)*size.height;
   }else{
      [NSException raise:@"Impiment This Code" format:nil];
   }

   //Set Brightness
   self.brightness = v;
   
   [self updateSelectionLocation];
}


-(CGPoint)selection {
	return selection;
}

/**
 * Returns hue saturation and brightness from current selection
 */
-(void)selectionToHue:(CGFloat *)pH saturation:(CGFloat *)pS brightness:(CGFloat *)pV{
   
   [self genBitmap]; // Make sure bitmap is up to date before providing color
	
	//Get red green and blue from selection
	BMPixel pixel = [rep getPixelAtPoint:BMPointFromPoint(selection)];
	CGFloat r = pixel.red, b = pixel.blue, g = pixel.green;
	   
   rgbToHsv(r, g, b, pH, pS, pV);
}

-(UIColor*)colorAtPoint:(CGPoint)point {
   if (CGRectContainsPoint(self.bounds,point)){
      return UIColorFromBMPixel([rep getPixelAtPoint:BMPointFromPoint(point)]);
   }else{
      return self.backgroundColor;
   }
}

-(CGPoint)validPointForTouch:(CGPoint)touchPoint {
	if (!cropToCircle || isOrthoganal){
		//Constrain point to inside of bounds
		touchPoint.x = MIN(CGRectGetMaxX(self.bounds), touchPoint.x);
		touchPoint.x = MAX(CGRectGetMinX(self.bounds), touchPoint.x);
		touchPoint.y = MIN(CGRectGetMaxX(self.bounds), touchPoint.y);
		touchPoint.y = MAX(CGRectGetMinX(self.bounds), touchPoint.y);
		return touchPoint;
	};
	
	BMPixel pixel = BMPixelMake(0.0, 0.0, 0.0, 0.0);
	if (IS_INSIDE(touchPoint)) {
		pixel = [rep getPixelAtPoint:BMPointFromPoint(touchPoint)];
	}
	
	if (pixel.alpha > 0.0) {
		return touchPoint;
	}
	
	// the point is invalid, so we will put it in a valid location.
	CGFloat radius = (self.frame.size.width / 2.0);
	CGFloat relX = touchPoint.x - radius;
	CGFloat relY = radius - touchPoint.y;
	CGFloat angle = atan2(relY, relX);
	
	if (angle < 0) { angle = (2.0 * M_PI) + angle; }
	relX = INNER_P(cos(angle) * radius);
	relY = INNER_P(sin(angle) * radius);
	
	while (relX >= radius) { relX -= 1; }
	while (relX <= -radius) { relX += 1; }
	while (relY >= radius) { relY -= 1; }
	while (relY <= -radius) { relY += 1; }
	return CGPointMake(round(relX + radius), round(radius - relY));
}

-(void)updateSelectionLocation {
   selectionView.center = selection;
   [brightnessSlider updateBackground];

   [CATransaction setDisableActions:YES];
   loupeLayer.position = selection;
   [loupeLayer setNeedsDisplay];
}

#pragma mark - UIView Methods
//--------------------------------------------------------------------------------------------------

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
   
   //Lazily load loupeLayer
   if (!loupeLayer){
      loupeLayer = [[BGRSLoupeLayer layer] retain];
   }
   
	CGPoint point = [[touches anyObject] locationInView:self];
	CGPoint circlePoint = [self validPointForTouch:point];
	
	BMPixel checker = [rep getPixelAtPoint:BMPointFromPoint(point)];
	if (!(checker.alpha > 0.0)) {
		badTouch = YES;
		return;
	}
	badTouch = NO;
	
	BMPixel pixel = [rep getPixelAtPoint:BMPointFromPoint(circlePoint)];
	NSAssert(pixel.alpha >= 0.0, @"-validPointForTouch: returned invalid point.");
	
	selection = circlePoint;
	[delegate colorPickerDidChangeSelection:self];
   [loupeLayer appearInColorPicker:self];
	
   [self updateSelectionLocation];
}
-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
	if (badTouch) return;
	
	CGPoint point = [[touches anyObject] locationInView:self];
	CGPoint circlePoint = [self validPointForTouch:point];
	
	BMPixel pixel = [rep getPixelAtPoint:BMPointFromPoint(circlePoint)];
	NSAssert(pixel.alpha >= 0.0, @"-validPointForTouch: returned invalid point.");
	
	selection = circlePoint;
	[delegate colorPickerDidChangeSelection:self];
	[self updateSelectionLocation];
}
-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	if (badTouch) return;
	
	CGPoint point = [[touches anyObject] locationInView:self];
	CGPoint circlePoint = [self validPointForTouch:point];
	
	BMPixel pixel = [rep getPixelAtPoint:BMPointFromPoint(circlePoint)];
	NSAssert(pixel.alpha >= 0.0, @"-validPointForTouch: returned invalid point.");
	
	selection = circlePoint;
	[delegate colorPickerDidChangeSelection:self];
	[self updateSelectionLocation];
   [loupeLayer disapear];
}

@end

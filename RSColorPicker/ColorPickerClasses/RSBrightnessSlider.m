//
//  RSBrightnessSlider.m
//  RSColorPicker
//
//  Created by Ryan Sullivan on 8/12/11.
//  Copyright 2011 Freelance Web Developer. All rights reserved.
//

#import "RSBrightnessSlider.h"
#import "RSColorPickerView.h"
#import "ANImageBitmapRep.h"

/**
 * Creates Default Bitmap Context for drawing into.
 */
CGContextRef RSBitmapContextCreateDefault(CGSize size){
	
	size_t width = size.width;
	size_t height = size.height;
	
	size_t bytesPerRow = width * 4;        // bytes per row - one byte each for argb
	bytesPerRow += (16 - bytesPerRow%16)%16; // ensure it is a multiple of 16
	
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	CGContextRef ctx = CGBitmapContextCreate(NULL,         //Automatic Alocation
														  width,        //size_t width
														  height,       //size_t Height
														  8,            //size_t bitsPerComponent
														  bytesPerRow,  //size_t bytesPerRow
														  colorSpace,   //CGColorSpaceRef space
														  kCGImageAlphaPremultipliedFirst );//CGBitmapInfo bitmapInfo
	CGColorSpaceRelease(colorSpace);
	return ctx;
}

/**
 * Returns Image with hourglass looking slider that looks something like:
 *
 *  6 ______ 5
 *    \    /
 *   7 \  / 4
 *    ->||<--- cWidth (Center Width)
 *      ||
 *   8 /  \ 3
 *    /    \
 *  1 ------ 2
 */
UIImage* RSHourGlassThumbImage(CGSize size, CGFloat cWidth){
	
	//Set Size
	CGFloat width = size.width;
	CGFloat height = size.height;
	
	//Setup Context
	CGContextRef ctx = RSBitmapContextCreateDefault(size);
	
	//Set Colors
	CGContextSetFillColorWithColor(ctx, [UIColor blackColor].CGColor);
	CGContextSetStrokeColorWithColor(ctx, [UIColor whiteColor].CGColor);
		
	//Draw Slider, See Diagram above for point numbers
	CGFloat yDist83 = sqrtf(3)/2*width;
	CGFloat yDist74 = height - yDist83;
	CGPoint addLines[] = {
		CGPointMake(0, -1),                          //Point 1
		CGPointMake(width, -1),                      //Point 2
		CGPointMake(width/2+cWidth/2, yDist83),      //Point 3
		CGPointMake(width/2+cWidth/2, yDist74),      //Point 4
		CGPointMake(width, height+1),                //Point 5
		CGPointMake(0, height+1),                    //Point 6
		CGPointMake(width/2-cWidth/2, yDist74),      //Point 7
		CGPointMake(width/2-cWidth/2, yDist83)       //Point 8
	};
	//Fill Path
	CGContextAddLines(ctx, addLines, sizeof(addLines)/sizeof(addLines[0]));
	CGContextFillPath(ctx);
	
	//Stroke Path
	CGContextAddLines(ctx, addLines, sizeof(addLines)/sizeof(addLines[0]));
	CGContextClosePath(ctx);
	CGContextStrokePath(ctx);
	
	CGImageRef cgImage = CGBitmapContextCreateImage(ctx);
	CGContextRelease(ctx);
   
   UIImage* image = [UIImage imageWithCGImage:cgImage]; 
   CGImageRelease(cgImage);
	
	return image;
}

/**
 * Returns image that looks like a square arrow loop, something like:
 *
 * +-----+
 * | +-+ | ------------------------
 * | | | |                       |
 * ->| |<--- loopSize.width     loopSize.height
 * | | | |                       |
 * | +-+ | ------------------------
 * +-----+
 */
UIImage* RSArrowLoopThumbImage(CGSize size, CGSize loopSize){
   
   //Setup Rects
   CGRect outsideRect = CGRectMake(0, 0, size.width, size.height);
   CGRect insideRect;
   insideRect.size = loopSize;
   insideRect.origin.x = (size.width - loopSize.width)/2;
   insideRect.origin.y = (size.height - loopSize.height)/2;
   
   //Setup Context
	CGContextRef ctx = RSBitmapContextCreateDefault(size);
   
   //Set Colors
	CGContextSetFillColorWithColor(ctx, [UIColor blackColor].CGColor);
   CGContextSetStrokeColorWithColor(ctx, [UIColor whiteColor].CGColor);
   
   CGMutablePathRef loopPath = CGPathCreateMutable();
   CGPathAddRect(loopPath, nil, outsideRect);
   CGPathAddRect(loopPath, nil, insideRect);
   
   
   //Fill Path
   CGContextAddPath(ctx, loopPath);
   CGContextEOFillPath(ctx);
   
   //Stroke Path
   CGContextAddRect(ctx, insideRect);
   CGContextStrokePath(ctx);
   
   CGImageRef cgImage = CGBitmapContextCreateImage(ctx);
   
   //Memory
   CGPathRelease(loopPath);
   CGContextRelease(ctx);
   
   UIImage* image = [UIImage imageWithCGImage:cgImage]; 
   CGImageRelease(cgImage);
	
	return image;
}

 
@implementation RSBrightnessSlider
@synthesize useCustomSlider, isColorfull, colorPicker;

//Called when created using code
-(id)initWithFrame:(CGRect)frame {
	self = [super initWithFrame:frame];
	if (self) {
      [self setup];
	}
	return self;
}

//Called when created using IB
-(id)initWithCoder:(NSCoder *)aDecoder{
   self = [super initWithCoder:aDecoder];
   if (self){
      [self setup];
   }
   return self;
}
/**
 * Setup code preformed for both initWithCoder when used in a nib and initWithFrame 
 * when used progromaticly
 */
-(void)setup{
   self.minimumValue = 0.0;
   self.maximumValue = 1.0;
   self.continuous = YES;
   
   self.enabled = YES;
   self.userInteractionEnabled = YES;
   
   self.isColorfull     = NO;
   self.useCustomSlider = NO;
   
   [self addTarget:self action:@selector(myValueChanged:) forControlEvents:UIControlEventValueChanged];
}

-(void)setUseCustomSlider:(BOOL)use {
	useCustomSlider = use;
	if (use) {
		[self setupImages];
	}
}

-(void)myValueChanged:(id)notif {
	[self.colorPicker setBrightness:self.value];
}

-(void)setupImages {
	
	if (!self.useCustomSlider){return;} //Bail if not using custom slider
	
	CGFloat hue, saturation;
	if (isColorfull){
		[self.colorPicker selectionToHue:&hue saturation:&saturation brightness:nil];
	}else{
		hue = 0.0f; saturation = 0.0f;
	}
	
	ANImageBitmapRep *myRep = [[ANImageBitmapRep alloc] initWithSize:BMPointMake(self.frame.size.width, self.frame.size.height)];
	for (int x = 0; x < myRep.bitmapSize.x; x++) {
		CGFloat percGray = (CGFloat)x / (CGFloat)myRep.bitmapSize.x;
		for (int y = 0; y < myRep.bitmapSize.y; y++) {
			[myRep setPixel:pixelFromHSV(hue, saturation, percGray) atPoint:BMPointMake(x, y)];
		}
	}
	//[self setBackgroundColor:[UIColor colorWithPatternImage:[myRep image]]];
	[self setMinimumTrackImage:[myRep image] forState:UIControlStateNormal];
	[self setMaximumTrackImage:[myRep image] forState:UIControlStateNormal];
	
	[myRep release];
}

-(void)useCustomThumbImageOfStyle:(RSThumbImageStyle)style{
	
	CGSize sliderSize = self.bounds.size;
   UIImage* thumbImage;
   CGSize loopSize;
	
	switch (style) {
         
      case RSArrowLoopThumbImageStyle:
         sliderSize.width = 10;
         loopSize = CGSizeMake(4, sliderSize.height - 6);
         thumbImage = RSArrowLoopThumbImage(sliderSize, loopSize);
         break;
		default:
			sliderSize.width = 0.40f*sliderSize.height;
			thumbImage = RSHourGlassThumbImage(sliderSize,3);
			break;
	}
   [self setThumbImage:thumbImage forState:UIControlStateNormal];
   [self setThumbImage:thumbImage forState:UIControlStateHighlighted];
}

-(void)setColorPicker:(RSColorPickerView*)cp {
	colorPicker = cp;
	if (!colorPicker) { return; }
	self.value = [colorPicker brightness];
}

@end

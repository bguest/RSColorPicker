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

@implementation RSBrightnessSlider
@synthesize useCustomSlider, isColorfull;

-(id)initWithFrame:(CGRect)frame {
	self = [super initWithFrame:frame];
	if (self) {
		self.minimumValue = 0.0;
		self.maximumValue = 1.0;
		self.continuous = YES;
		
		self.enabled = YES;
		self.userInteractionEnabled = YES;
		
		self.isColorfull     = NO;
		self.useCustomSlider = NO;
		
		[self addTarget:self action:@selector(myValueChanged:) forControlEvents:UIControlEventValueChanged];
	}
	return self;
}

-(void)setUseCustomSlider:(BOOL)use {
	useCustomSlider = use;
	if (use) {
		[self setupImages];
	}
}

-(void)myValueChanged:(id)notif {
	[colorPicker setBrightness:self.value];
}

-(void)setupImages {
	
	if (!self.useCustomSlider){return;} //Bail if not using custom slider
	
	CGFloat hue, saturation;
	if (isColorfull){
		[colorPicker selectionToHue:&hue saturation:&saturation brightness:nil];
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

-(void)setColorPicker:(RSColorPickerView*)cp {
	colorPicker = cp;
	if (!colorPicker) { return; }
	self.value = [colorPicker brightness];
}

@end

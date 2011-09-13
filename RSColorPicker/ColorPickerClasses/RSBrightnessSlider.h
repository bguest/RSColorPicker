//
//  RSBrightnessSlider.h
//  RSColorPicker
//
//  Created by Ryan Sullivan on 8/12/11.
//  Copyright 2011 Freelance Web Developer. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {                   //Custom Thumb Image Slider Types
   RSHourGlassThumbImageStyle = 0,
   RSArrowLoopThumbImageStyle,
} RSThumbImageStyle;

@class RSColorPickerView;

@interface RSBrightnessSlider : UISlider {
	RSColorPickerView *colorPicker;
   
	BOOL useCustomSlider;
	BOOL isColorfull;
}
@property (nonatomic) BOOL isColorfull;
@property (nonatomic) BOOL useCustomSlider;

-(void)setupImages;
-(void)useCustomThumbImageOfStyle:(RSThumbImageStyle)style;

-(void)setColorPicker:(RSColorPickerView*)cp;

@end

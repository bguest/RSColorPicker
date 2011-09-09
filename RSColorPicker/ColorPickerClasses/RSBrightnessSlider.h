//
//  RSBrightnessSlider.h
//  RSColorPicker
//
//  Created by Ryan Sullivan on 8/12/11.
//  Copyright 2011 Freelance Web Developer. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RSColorPickerView;

@interface RSBrightnessSlider : UISlider {
	RSColorPickerView *colorPicker;
	BOOL useCustomSlider;
	BOOL isColorfull;
}
@property (nonatomic) BOOL isColorfull;
@property (nonatomic) BOOL useCustomSlider;

-(void)setupImages;

-(void)setColorPicker:(RSColorPickerView*)cp;

@end

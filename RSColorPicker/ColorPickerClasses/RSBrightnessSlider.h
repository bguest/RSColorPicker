//
//  RSBrightnessSlider.h
//  RSColorPicker
//
//  Created by Ryan Sullivan on 8/12/11.
//  Copyright 2011 Freelance Web Developer. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {    
   RSThumbImageStyleDefault = 0,   //Custom Thumb Image Slider Types
   RSThumbImageStyleHourGlass,
   RSThumbImageStyleArrowLoop,
} RSThumbImageStyle;

typedef enum { 
   RSSliderBackgroundStyleDefault = 0,
   RSSliderBackgroundStyleGrayscale,
   RSSliderBackgroundStyleColorfull,
} RSSliderBackgroundStyle;

@class RSColorPickerView;

@interface RSBrightnessSlider : UISlider {
	RSColorPickerView *__unsafe_unretained colorPicker;
   
   RSSliderBackgroundStyle backgroundStyle;
   RSThumbImageStyle thumbImageStyle;
}
@property (nonatomic) RSSliderBackgroundStyle backgroundStyle;
@property (nonatomic, unsafe_unretained) IBOutlet RSColorPickerView* colorPicker;

-(void)setup;
-(void)updateBackground;
-(void)useCustomThumbImageOfStyle:(RSThumbImageStyle)style;

@end

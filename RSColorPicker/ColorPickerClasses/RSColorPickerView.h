//
//  RSColorPickerView.h
//  RSColorPicker
//
//  Created by Ryan Sullivan on 8/12/11.
//  Copyright 2011 Freelance Web Developer. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

#import "ANImageBitmapRep.h"

BMPixel pixelFromHSV(CGFloat H, CGFloat S, CGFloat V);

@class RSColorPickerView, BGRSLoupeLayer, RSBrightnessSlider;
@protocol RSColorPickerViewDelegate <NSObject>

@required
-(void)colorPickerDidChangeSelection:(RSColorPickerView*)cp;

@end

@interface RSColorPickerView : UIView {
	ANImageBitmapRep *rep;
	CGFloat brightness;
	BOOL cropToCircle;
	BOOL isOrthoganal;	//YES ~> Square with saturation on Y axis
								//NO  ~> Saturation on radial axis
	
	UIView *selectionView;
   BGRSLoupeLayer* loupeLayer;
	CGPoint selection;
	
	BOOL badTouch;
	BOOL bitmapNeedsUpdate;
	
	id<RSColorPickerViewDelegate> __unsafe_unretained delegate;
}
-(CGPoint)selection;

@property (nonatomic, assign) BOOL cropToCircle, isOrthoganal;
@property (nonatomic, copy) UIColor* selectionColor;
@property (nonatomic) CGFloat brightness;
@property (nonatomic, unsafe_unretained) IBOutlet id<RSColorPickerViewDelegate> delegate;
@property (nonatomic, unsafe_unretained) IBOutlet RSBrightnessSlider* brightnessSlider;


-(void)selectionToHue:(CGFloat *)pH saturation:(CGFloat *)pS brightness:(CGFloat *)pV;
-(UIColor*)colorAtPoint:(CGPoint)point; //Returns UIColor at a point in the RSColorPickerView

@end

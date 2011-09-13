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

@class RSColorPickerView;
@protocol RSColorPickerViewDelegate <NSObject>
-(void)colorPickerDidChangeSelection:(RSColorPickerView*)cp;
@end

@interface RSColorPickerView : UIView {
	ANImageBitmapRep *rep;
	CGFloat brightness;
	BOOL cropToCircle;
	BOOL isOrthoganal;	//YES ~> Square with saturation on Y axis
								//NO  ~> Saturation on radial axis
	
	UIView *selectionView;
	CGPoint selection;
	
	BOOL badTouch;
	BOOL bitmapNeedsUpdate;
	
	id<RSColorPickerViewDelegate> delegate;
}

-(UIColor*)selectionColor;
-(CGPoint)selection;

@property (nonatomic, assign) BOOL cropToCircle, isOrthoganal;
@property (nonatomic, assign) CGFloat brightness;
@property (assign) id<RSColorPickerViewDelegate> delegate;

/**
 * Hue, saturation and briteness of the selected point
 * @Reference: Taken From ars/uicolor-utilities 
 * http://github.com/ars/uicolor-utilities
 */
-(void)selectionToHue:(CGFloat *)pH saturation:(CGFloat *)pS brightness:(CGFloat *)pV;


@end

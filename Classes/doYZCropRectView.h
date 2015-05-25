//
//  PECropRectView.h
//  PhotoCropEditor
//
//  Created by kishikawa katsumi on 2013/05/21.
//  Copyright (c) 2013 kishikawa katsumi. All rights reserved.
//

#import <UIKit/UIKit.h>

@class doYZCropRectView;
@protocol doYZCropRectViewDelegate <NSObject>

- (void)cropRectViewDidBeginEditing:(doYZCropRectView *)cropRectView;
- (void)cropRectViewEditingChanged:(doYZCropRectView *)cropRectView;
- (void)cropRectViewDidEndEditing:(doYZCropRectView *)cropRectView;

@end

@interface doYZCropRectView : UIView

@property (nonatomic,weak) id <doYZCropRectViewDelegate> delegate;
@property (nonatomic,assign) BOOL showsGridMajor;
@property (nonatomic,assign) BOOL showsGridMinor;

@end



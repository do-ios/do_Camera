//
//  PECropViewController.h
//  PhotoCropEditor
//
//  Created by kishikawa katsumi on 2013/05/19.
//  Copyright (c) 2013 kishikawa katsumi. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol doYZCropViewControllerDelegate;

@interface doYZCropViewController : UIViewController
@property (nonatomic,weak) id<doYZCropViewControllerDelegate> delegate;
@property (nonatomic,assign) UIImage *image;

@end

@protocol doYZCropViewControllerDelegate <NSObject>

- (void)cropViewController:(doYZCropViewController *)controller didFinishCroppingImage:(UIImage *)croppedImage;
- (void)cropViewControllerDidCancel:(doYZCropViewController *)controller;

@end

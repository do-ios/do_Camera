//
//  TYPEID_SM.m
//  DoExt_API
//
//  Created by @userName on @time.
//  Copyright (c) 2015年 DoExt. All rights reserved.
//

#import "do_Camera_SM.h"
#import <AVFoundation/AVFoundation.h>
#import <MobileCoreServices/UTCoreTypes.h>

#import "doJsonHelper.h"
#import "doServiceContainer.h"
#import "doILogEngine.h"
#import "doIApp.h"
#import "doISourceFS.h"
#import "doIDataFS.h"
#import "doIOHelper.h"
#import "doCallBackTask.h"
#import "doIPage.h"
#import "doUIModuleHelper.h"
#import "doYZCropViewController.h"

static NSString *usablePath = @"data://";

@interface do_Camera_SM ()<UINavigationControllerDelegate,UIImagePickerControllerDelegate,doYZCropViewControllerDelegate>{
    int imageWidth;
    int imageHeight;
    int imageQuality;
    BOOL isCut;
    BOOL facingFront;
    UIImagePickerController * pickerVC;
}
@property (nonatomic, strong ) UIImage *tempImage;
@property (nonatomic, strong) NSString * myCallbackFuncName;
@property (nonatomic, strong) doInvokeResult * myInvokeResult;
@property (nonatomic, strong) id<doIScriptEngine> myScriptEngine;

@end

@implementation do_Camera_SM
{
    NSString *_outPath;
}
#pragma mark -
#pragma mark - 同步异步方法的实现
/*
 1.参数节点
 NSDictionary *_dictParas = [parms objectAtIndex:0];
 在节点中，获取对应的参数
 NSString *title = [doJsonHelper GetOneText: _dictParas :@"title" :@"" ];
 说明：第一个参数为对象名，第二为默认值
 
 2.脚本运行时的引擎
 id<doIScriptEngine> _scritEngine = [parms objectAtIndex:1];
 
 同步：
 3.同步回调对象(有回调需要添加如下代码)
 doInvokeResult *_invokeResult = [parms objectAtIndex:2];
 回调信息
 如：（回调一个字符串信息）
 [_invokeResult SetResultText:((doUIModule *)_model).UniqueKey];
 异步：
 3.获取回调函数名(异步方法都有回调)
 NSString *_callbackName = [parms objectAtIndex:2];
 在合适的地方进行下面的代码，完成回调
 新建一个回调对象
 doInvokeResult *_invokeResult = [[doInvokeResult alloc] init];
 填入对应的信息
 如：（回调一个字符串）
 [_invokeResult SetResultText: @"异步方法完成"];
 [_scritEngine Callback:_callbackName :_invokeResult];
 */
#pragma mark - 实现异步方法
- (void)capture:(NSArray *)params
{
    NSDictionary * _dicParas = [params objectAtIndex:0];
    self.myScriptEngine = [params objectAtIndex:1];
    self.myCallbackFuncName = [params objectAtIndex:2];
    self.myInvokeResult = [[doInvokeResult alloc]init:nil];
    //图片宽度
    imageWidth = [doJsonHelper GetOneInteger: _dicParas :@"width" :-1];
    //图片高度
    imageHeight = [doJsonHelper GetOneInteger: _dicParas :@"height" :-1];
    
    if (imageWidth<=0) {
        imageWidth = -1;
    }
    if (imageHeight<=0) {
        imageHeight = -1;
    }
    //清晰度1-100
    imageQuality = [doJsonHelper GetOneInteger: _dicParas :@"quality" :100];
    imageQuality = imageQuality > 100 ? 100 : imageQuality;
    imageQuality = imageQuality < 1 ? 1 : imageQuality;
    //是否启动中间裁剪界面
    isCut = [doJsonHelper GetOneBoolean: _dicParas :@"iscut" :NO];
    //是否启动前置摄像头
    facingFront = [doJsonHelper GetOneBoolean: _dicParas :@"facingFront" :NO];
    //保存路径
    _outPath = [doJsonHelper GetOneText:_dicParas :@"outPath" :@""];
    
    if (_outPath.length>0) {
        if (![_outPath hasPrefix:usablePath]) {
            _outPath = @"";
        }
        if (_outPath.length>0) {
            _outPath = [_outPath substringFromIndex:[_outPath rangeOfString:usablePath].length];
        }
    }

    if(pickerVC == nil)
    {
        if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]){
            if ([[AVCaptureDevice class] respondsToSelector:@selector(authorizationStatusForMediaType:)]) {
                AVAuthorizationStatus authorizationStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
                if (authorizationStatus == AVAuthorizationStatusRestricted
                    || authorizationStatus == AVAuthorizationStatusDenied) {
                    // 没有权限
                    [[doServiceContainer Instance].LogEngine WriteError:nil:@"当前设备不支持相机功能",nil];
                    return;
                }
            }
            
            pickerVC = [[UIImagePickerController alloc]init];
            pickerVC.delegate = self;
            NSString *requiredMediaType = ( NSString *)kUTTypeImage;
            //        NSString *requiredMediaType1 = ( NSString *)kUTTypeMovie;
            NSArray *arrMediaTypes=[NSArray arrayWithObjects:requiredMediaType,nil];
            [pickerVC setMediaTypes:arrMediaTypes];
            //            [pickerVC setShowsCameraControls:YES];
            [pickerVC setSourceType:UIImagePickerControllerSourceTypeCamera];
            //            [pickerVC setCameraDevice:UIImagePickerControllerCameraDeviceRear];
            [pickerVC setCameraFlashMode:UIImagePickerControllerCameraFlashModeOff];
            [self presentViewController];
        }else{
            [[doServiceContainer Instance].LogEngine WriteError:nil:@"当前设备不支持相机功能",nil];
        }
    }
    else
    {
        [self presentViewController];
    }
}

- (void)presentViewController
{
    if (facingFront) {
        if ([UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceFront]) {
            pickerVC.cameraDevice = UIImagePickerControllerCameraDeviceFront;
        }
    }else
        pickerVC.cameraDevice = UIImagePickerControllerCameraDeviceRear;

    id<doIPage> pageModel = _myScriptEngine.CurrentPage;
    UIViewController * currentVC = (UIViewController *)pageModel.PageView;
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue]>=8.0) {
        currentVC.modalPresentationStyle=UIModalPresentationOverCurrentContext;
        pickerVC.modalPresentationStyle=UIModalPresentationOverCurrentContext;

    }
    // 更改UI的操作，必须回到主线程
    dispatch_async(dispatch_get_main_queue(), ^{
        [currentVC presentViewController:pickerVC animated:YES completion:^{
            NSLog(@"跳转成功!");
        }];
    });
    
}

#pragma mark - 私有方法，支持对外方法的实现
#pragma mark - UIImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    NSString * mediaType = [info objectForKey:UIImagePickerControllerMediaType];
    if([mediaType isEqualToString:@"public.image"] && picker.sourceType==UIImagePickerControllerSourceTypeCamera){
        @try {
            if(isCut)
            {
                self.tempImage = [info objectForKey:UIImagePickerControllerOriginalImage];
                [picker dismissViewControllerAnimated:YES completion:^{
                    [self openDoYZCropViewController];
                }];
            }
            else
            {
                self.tempImage = [info objectForKey:UIImagePickerControllerOriginalImage];
                [self saveImageToLocal];
            }
        }
        @catch (NSException *exception) {
            [_myInvokeResult SetException:exception];
        }
    }
    [picker dismissViewControllerAnimated:YES completion:^{
        _myInvokeResult = nil;
        _myScriptEngine = nil;
    } ];
}

- (void) saveImageToLocal
{
    NSData * imageData;
    CGSize size = CGSizeMake(imageWidth, imageHeight);;
    CGFloat hwRatio = self.tempImage.size.height/self.tempImage.size.width;
    CGFloat whRatio = self.tempImage.size.width/self.tempImage.size.height;
    if (-1 == imageHeight && -1 == imageWidth) {//保持原始比例
        size = CGSizeMake(self.tempImage.size.width, self.tempImage.size.height);
    }
    else
    {
        if(-1 == imageWidth)
        {
            size = CGSizeMake(imageHeight*whRatio, imageHeight);
        }
        if(-1 == imageHeight)
        {
            size = CGSizeMake(imageWidth, imageWidth*hwRatio);
        }
    }
    
    self.tempImage = [doUIModuleHelper imageWithImageSimple:self.tempImage scaledToSize:size ];
    
    if(!self.tempImage){
        [NSException raise:self.description format:@"使用照片失败",nil];
        return;
    }
    
    if(imageQuality<0) imageQuality = 1;
    if(imageQuality>100)imageQuality = 100;
    imageData = UIImageJPEGRepresentation(self.tempImage, imageQuality / 100.0);
    //写入本地
    NSString * dataFSRootPath = _myScriptEngine.CurrentApp.DataFS.RootPath;
    NSString * fileName = [NSString stringWithFormat:@"%@.jpg",[doUIModuleHelper stringWithUUID]];
    NSString * filePath = [NSString stringWithFormat:@"%@/temp/do_Camera",dataFSRootPath];
    NSString * relativePath = @"temp/do_Camera";
    NSString * fileFullName = [NSString stringWithFormat:@"%@/%@",filePath,fileName];

    if (_outPath.length>0) {
        filePath = [NSString stringWithFormat:@"%@/%@",dataFSRootPath,_outPath];
        relativePath = _outPath;

        NSString *pathExtension = filePath.pathExtension;
        NSString *lastCom = filePath.lastPathComponent;
        if (pathExtension.length==0) {
            fileFullName = [NSString stringWithFormat:@"%@/%@",filePath,fileName];
        }else{
            relativePath = [relativePath stringByDeletingLastPathComponent];
            fileName = lastCom;
            fileFullName = [NSString stringWithFormat:@"%@",filePath];
            filePath = [filePath stringByDeletingLastPathComponent];
        }
    }

    if (![doIOHelper ExistDirectory:filePath]) {
        [doIOHelper CreateDirectory:filePath];
    }
    
    [doIOHelper WriteAllBytes:fileFullName :imageData];
    NSString *resultText = [NSString stringWithFormat:@"data://%@/%@",relativePath,fileName];
    [_myInvokeResult SetResultText:resultText];
    [_myScriptEngine Callback:_myCallbackFuncName :_myInvokeResult];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [_myInvokeResult SetError:@"拍照取消"];
    [picker dismissViewControllerAnimated:YES completion:^{
        _myInvokeResult = nil;
        _myScriptEngine = nil;
    } ];
}

- (void) openDoYZCropViewController
{
    doYZCropViewController *vc = [[doYZCropViewController alloc]init];
    vc.image = self.tempImage;
    vc.delegate = self;
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:vc];
    id<doIPage> pageModel = _myScriptEngine.CurrentPage;
    UIViewController * currentVC = (UIViewController *)pageModel.PageView;
    // 更改UI的操作，必须回到主线程
    dispatch_async(dispatch_get_main_queue(), ^{
        [currentVC presentViewController:navigationController animated:YES completion:nil];
    });
}

-(void)cropViewController:(doYZCropViewController *)controller didFinishCroppingImage:(UIImage *)croppedImage
{
    self.tempImage = croppedImage;
    [self saveImageToLocal];
    [controller dismissViewControllerAnimated:YES completion:nil];
}
- (void)cropViewControllerDidCancel:(doYZCropViewController *)controller
{
    [controller dismissViewControllerAnimated:YES completion:nil];
}
@end

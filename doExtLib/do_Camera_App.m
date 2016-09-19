//
//  do_Camera_App.m
//  DoExt_SM
//
//  Created by @userName on @time.
//  Copyright (c) 2015年 DoExt. All rights reserved.
//

#import "do_Camera_App.h"
static do_Camera_App* instance;
@implementation do_Camera_App
@synthesize OpenURLScheme;
+(id) Instance
{
    if(instance==nil)
        instance = [[do_Camera_App alloc]init];
    return instance;
}
@end

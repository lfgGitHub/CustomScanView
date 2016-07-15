//
//  CustomScanView.h
//  MVVMTest
//
//  Created by 李富贵 on 16/7/7.
//  Copyright © 2016年 李富贵. All rights reserved.
//

#import <UIKit/UIKit.h>


typedef NS_ENUM(NSUInteger, SkipWay) {
    NAVIGATION_SKIP,//导航栏跳转
    MODAL_SKIP//模态跳转
};

//扫描结果回调
typedef void(^ScanResult)(id result);

@interface CustomScanView : UIViewController

@property(nonatomic,assign)SkipWay skipWay;

//扫描结果回调
@property(copy,nonatomic)ScanResult scanResult;

//关闭页面
-(void)close;

@end

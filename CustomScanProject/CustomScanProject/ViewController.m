//
//  ViewController.m
//  CustomScanProject
//
//  Created by 李富贵 on 16/7/7.
//  Copyright © 2016年 李富贵. All rights reserved.
//

#import "ViewController.h"
#import "CustomScanView.h"
#import <Masonry.h>

@interface ViewController ()
{

}

@property(strong,nonatomic)UILabel *resultLab;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor=[UIColor whiteColor];

    NSLog(@"viewDidLoad");
    
    UIButton *openScanBtn=[UIButton buttonWithType:UIButtonTypeCustom];
    [openScanBtn setTitle:@"扫描" forState:UIControlStateNormal];
    [openScanBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [openScanBtn addTarget:self action:@selector(openScanEvent) forControlEvents:UIControlEventTouchDown];
    [self.view addSubview:openScanBtn];
    
    [openScanBtn mas_makeConstraints:^(MASConstraintMaker *make){
        make.center.mas_equalTo(self.view);
        make.width.height.mas_equalTo(100);
    }];
    
    
    
    //扫描结果
    [self resultLab];
}

-(UILabel *)resultLab
{
    if(_resultLab==nil)
    {
        _resultLab=[[UILabel alloc]init];
        _resultLab.textColor=[UIColor blueColor];
        _resultLab.font=[UIFont systemFontOfSize:16];
        _resultLab.textAlignment=NSTextAlignmentCenter;
        [self.view addSubview:_resultLab];
        
        [_resultLab mas_makeConstraints:^(MASConstraintMaker *make){
            make.centerY.mas_equalTo(self.view).offset(40);
            make.width.mas_lessThanOrEqualTo(self.view);
            make.centerX.mas_equalTo(self.view);
            make.height.mas_lessThanOrEqualTo(100);
        }];
    }
    return _resultLab;
}

-(void)openScanEvent
{

    CustomScanView *customScanView=[[CustomScanView alloc]init];
    __weak typeof(customScanView) weakCustomScanView=customScanView;
    __weak typeof(self) weakSelf=self;
    customScanView.scanResult=^(NSString *result){
        NSLog(@"扫描结果===%@",result);
        [weakCustomScanView close];
        weakSelf.resultLab.text=[NSString stringWithFormat:@"扫描结果:%@",result];
    };
    customScanView.skipWay=NAVIGATION_SKIP;
    [self.navigationController pushViewController:customScanView animated:YES];
    
    //[self presentViewController:customScanView animated:YES completion:nil];
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

//
//  CustomScanView.m
//  MVVMTest
//
//  Created by 李富贵 on 16/7/7.
//  Copyright © 2016年 李富贵. All rights reserved.
//

#import "CustomScanView.h"
#import <AVFoundation/AVFoundation.h>
#import <Masonry.h>


//屏幕的宽度
#define ScreenWidth [[UIScreen mainScreen] bounds].size.width

// 判断当前设备是不是iPhone4或者4s
#define IPHONE4S    (([[UIScreen mainScreen] bounds].size.height)==480)

// 判断当前设备是不是iPhone5
#define IPHONE5    (([[UIScreen mainScreen] bounds].size.height)==568)

// 判断当前设备是不是iPhone6
#define IPHONE6    (([[UIScreen mainScreen] bounds].size.height)==667)

// 判断当前设备是不是iPhone6Plus
#define IPHONE6_PLUS    (([[UIScreen mainScreen] bounds].size.height)＝=736)

//判断是ipad
#define IPAD (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)

//导航栏高度
#define NAV_HEIGHT ScreenWidth>667?(44*1.5+20):(44+20)

//字体适配
#define fontSize(font) ScreenWidth<=320?[UIFont systemFontOfSize:font]:IPHONE6?[UIFont systemFontOfSize:(font+2)]:[UIFont systemFontOfSize:(font+3)]

//RGB转换
#define UIColorFromRGB(rgbValue) [UIColor \
colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 \
green:((float)((rgbValue & 0xFF00) >> 8))/255.0 \
blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

#define UMSYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

@interface CustomScanView ()<AVCaptureMetadataOutputObjectsDelegate,UINavigationControllerDelegate,UIImagePickerControllerDelegate>
{
    NSTimer *timer;
    NSInteger num;
    BOOL upOrdown;
}
//扫描容器
@property(strong,nonatomic)UIView *customContainerView;

//底部视图
@property(strong,nonatomic)UIView  *bottomView;

//扫描线视图
@property(strong,nonatomic)UIView *scanLineView;

//扫描框
@property(strong,nonatomic)UIView *scanBorderView;

//会话
@property(strong,nonatomic)AVCaptureSession *session;

//输入
@property(strong,nonatomic)AVCaptureDeviceInput *input;

//输出
@property(strong,nonatomic)AVCaptureMetadataOutput *output;

//容器图层
@property(strong,nonatomic)CALayer *containerLayer;

//预览图层
@property(strong,nonatomic)AVCaptureVideoPreviewLayer *previewLayer;

//备注
@property(strong,nonatomic)UILabel *remarkLab;

//闪光灯按钮
@property(strong,nonatomic)UIButton *lightBtn;

@end

@implementation CustomScanView
@synthesize scanResult,skipWay;

-(void)viewDidLoad
{
    [super viewDidLoad];
    
    //初始化数据
    [self initData];
    
    //创建导航栏
    [self createNavigation];
    
    //创建UI
    [self createUI];
    
    //扫描二维码或者条形码
    [self scanQRCode];
    
    //开始动画
    [self startAnimationEvent];
}

//初始化数据
-(void)initData
{
    self.navigationController.navigationBarHidden=YES;
    self.view.backgroundColor=[UIColor whiteColor];
    num = 0;
    upOrdown = NO;
    self.view.clipsToBounds=YES;
}

//创建导航栏
-(void)createNavigation
{
    //自定义的导航栏视图
    UIView *navView=[[UIView alloc]init];
    navView.backgroundColor=[UIColor whiteColor];
    [self.view addSubview:navView];
    
    [navView mas_makeConstraints:^(MASConstraintMaker *make){
        make.top.left.right.mas_equalTo(self.view);
        make.height.mas_equalTo(NAV_HEIGHT);
    }];

    //返回按钮
    UIButton *backBtn=[UIButton buttonWithType:UIButtonTypeCustom];
    [backBtn setTitle:@"返回" forState:UIControlStateNormal];
    [backBtn setTitleColor:UIColorFromRGB(0x7A7A7A) forState:UIControlStateNormal];
    [backBtn.titleLabel setFont:fontSize(15)];
    backBtn.backgroundColor=navView.backgroundColor;
    [backBtn addTarget:self action:@selector(backEvent) forControlEvents:UIControlEventTouchDown];
    [navView addSubview:backBtn];
    
    [backBtn mas_makeConstraints:^(MASConstraintMaker *make){
        make.left.mas_equalTo(navView).offset(15);
        make.width.mas_lessThanOrEqualTo(@200);
        make.bottom.mas_equalTo(navView);
        make.top.mas_equalTo(navView).offset(20);
    }];
    
    if(UMSYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0"))
    {
        //相册按钮
        UIButton *photoBtn=[UIButton buttonWithType:UIButtonTypeCustom];
        [photoBtn setTitle:@"相册" forState:UIControlStateNormal];
        [photoBtn setTitleColor:UIColorFromRGB(0x7A7A7A) forState:UIControlStateNormal];
        [photoBtn.titleLabel setFont:fontSize(15)];
         photoBtn.backgroundColor=navView.backgroundColor;
        [photoBtn addTarget:self action:@selector(photoEvent) forControlEvents:UIControlEventTouchDown];
        [navView addSubview:photoBtn];
        
        [photoBtn mas_makeConstraints:^(MASConstraintMaker *make){
            make.right.mas_equalTo(navView).offset(-15);
            make.width.mas_lessThanOrEqualTo(@200);
            make.bottom.mas_equalTo(navView);
            make.top.mas_equalTo(navView).offset(20);
        }];
    }
}

//创建UI
-(void)createUI
{
    //容器
    self.customContainerView=[[UIView alloc]init];
    self.customContainerView.clipsToBounds=YES;
    self.customContainerView.layer.borderColor=[UIColor colorWithRed:0 green:0 blue:0 alpha:0.4].CGColor;
    self.customContainerView.layer.borderWidth=ScreenWidth*0.2;
    [self.view addSubview:self.customContainerView];
    [self.customContainerView mas_makeConstraints:^(MASConstraintMaker *make){
        make.centerX.mas_equalTo(self.view);
        make.top.mas_equalTo(self.view).offset((NAV_HEIGHT));
        make.width.height.mas_equalTo(self.view.mas_width);
    }];
    
    CGFloat scanBorderWidth=ScreenWidth*0.6;
    //扫描边框
    self.scanBorderView=[[UIImageView alloc]init];
    self.scanBorderView.clipsToBounds=YES;
    self.scanBorderView.frame=CGRectMake(ScreenWidth*0.2,(NAV_HEIGHT)+ScreenWidth*0.2,scanBorderWidth,scanBorderWidth);
    [self.view addSubview:self.scanBorderView];
    
    //备注
    [self remarkLab];
    
    //四个框
    CGFloat buttonWH = 18;
    
    UIButton *topLeft = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, buttonWH, buttonWH)];
    [topLeft setImage:[UIImage imageNamed:@"ScanQR1"] forState:UIControlStateNormal];
    [self.scanBorderView addSubview:topLeft];
    
    UIButton *topRight = [[UIButton alloc] initWithFrame:CGRectMake(scanBorderWidth - buttonWH, 0, buttonWH, buttonWH)];
    [topRight setImage:[UIImage imageNamed:@"ScanQR2"] forState:UIControlStateNormal];
    [self.scanBorderView addSubview:topRight];
    
    UIButton *bottomLeft = [[UIButton alloc] initWithFrame:CGRectMake(0, scanBorderWidth - buttonWH, buttonWH, buttonWH)];
    [bottomLeft setImage:[UIImage imageNamed:@"ScanQR3"] forState:UIControlStateNormal];
    [self.scanBorderView addSubview:bottomLeft];
    
    UIButton *bottomRight = [[UIButton alloc] initWithFrame:CGRectMake(topRight.frame.origin.x, bottomLeft.frame.origin.y, buttonWH, buttonWH)];
    [bottomRight setImage:[UIImage imageNamed:@"ScanQR4"] forState:UIControlStateNormal];
    [self.scanBorderView addSubview:bottomRight];
    
    //扫描行
    self.scanLineView=[[UIView alloc]init];
    self.scanLineView.frame=CGRectMake(0,5,ScreenWidth*0.6,3);
    self.scanLineView.layer.contents=(id)[UIImage imageNamed:@"scanLine"].CGImage;
    [self.scanBorderView addSubview:self.scanLineView];
}


//扫描二维码或者条形码
-(void)scanQRCode
{
    // 1.判断输入能否添加到会话中
    if(![self.session canAddInput:self.input])
    {
        return;
    }
    // 2.判断输出能够添加到会话中
    if(![self.session canAddOutput:self.output])
    {
        return;
    }
    
    // 3.添加输入和输出到会话中
    [self.session addInput:self.input];
    [self.session addOutput:self.output];
    
    // 4.设置输出能够解析的数据类型
    // 注意点: 设置数据类型一定要在输出对象添加到会话之后才能设置
    self.output.metadataObjectTypes = self.output.availableMetadataObjectTypes;
    
    // 5.设置监听监听输出解析到的数据
    [self.output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    
    
    // 6.添加容器图层，设置蒙版
    self.containerLayer.frame=self.view.bounds;
    self.containerLayer.delegate=self;
    [self.view.layer addSublayer:self.containerLayer];
    
    // 7.添加预览图层
    [self.view.layer insertSublayer:self.previewLayer atIndex:0];
    self.previewLayer.frame=self.view.bounds;
    
    // 8、底部视图
    [self bottomView];
    
    // 9\闪光灯
    [self lightBtn];

    
    // 10.开始扫描
    [self.session startRunning];
    
}

-(AVCaptureSession *)session
{
    if(_session==nil)
    {
        _session=[[AVCaptureSession alloc]init];
    }
    return _session;
}

-(AVCaptureDeviceInput *)input
{
    if(_input==nil)
    {
        NSError *error;
        AVCaptureDevice *device=[AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        _input=[AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
        NSLog(@"input_error==%@",error);
        
        //在生成拍摄回话时原来直接设置的是最高清画质，但对于ipod 5这类低配设备是不支持的，故在此我采取了下面这种方式来设置画质。
        if ([device supportsAVCaptureSessionPreset:AVCaptureSessionPreset1920x1080]) {
            self.session.sessionPreset = AVCaptureSessionPreset1920x1080;//设置图像输出质量
        }else if ([device supportsAVCaptureSessionPreset:AVCaptureSessionPreset1280x720]){
            self.session.sessionPreset = AVCaptureSessionPreset1280x720;
        }else if ([device supportsAVCaptureSessionPreset:AVCaptureSessionPreset640x480]){
            self.session.sessionPreset = AVCaptureSessionPreset640x480;
        }else if ([device supportsAVCaptureSessionPreset:AVCaptureSessionPreset352x288]){
            self.session.sessionPreset = AVCaptureSessionPreset352x288;
        }
    }
    return _input;
}


// 设置输出对象解析数据时感兴趣的范围
// 默认值是 CGRect(x: 0, y: 0, width: 1, height: 1)
// 通过对这个值的观察, 我们发现传入的是比例
// 注意: 参照是以横屏的左上角为参照, 而不是以竖屏
//        out.rectOfInterest = CGRect(x: 0, y: 0, width: 0.5, height: 0.5)
-(AVCaptureMetadataOutput *)output
{
    if(_output==nil)
    {
        _output=[[AVCaptureMetadataOutput alloc]init];

        // 1.获取屏幕的frame
        CGRect viewRect = self.view.frame;
        // 2.获取扫描容器的frame

        CGRect containerRect =_scanBorderView.frame;
        
        NSLog(@"rect==%@",NSStringFromCGRect(containerRect));
        
        CGFloat x = containerRect.origin.y / viewRect.size.height;
        CGFloat y =containerRect.origin.x / viewRect.size.width;
        CGFloat width = containerRect.size.height / viewRect.size.height;
        CGFloat height = containerRect.size.width / viewRect.size.width;
        NSLog(@"x==%f,y==%f,width==%f,height==%f",x,y,width,height);
        _output.rectOfInterest = CGRectMake(x, y, width, height);
    }
    return _output;
}

//容器图层
-(CALayer *)containerLayer
{
    if(_containerLayer==nil)
    {
        _containerLayer=[CALayer layer];
       
    }
    return _containerLayer;
}


//预览layer
-(AVCaptureVideoPreviewLayer *)previewLayer
{
    if(_previewLayer==nil)
    {
        _previewLayer=[[AVCaptureVideoPreviewLayer alloc]initWithSession:self.session];
        //设置这个属性后才能正常显示尺寸
        [_previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    }
    return _previewLayer;
}

//备注
-(UILabel *)remarkLab
{
    if(_remarkLab==nil)
    {
        _remarkLab=[[UILabel alloc]init];
        _remarkLab.text=@"将二维码/条形码放入框内，可自行扫描";
        _remarkLab.font=fontSize(13);
        _remarkLab.textColor=[UIColor whiteColor];
        _remarkLab.backgroundColor=[UIColor clearColor];
        [self.view addSubview:_remarkLab];
        
        [_remarkLab mas_makeConstraints:^(MASConstraintMaker *make){
            make.top.mas_equalTo(self.scanBorderView.mas_bottom).offset(20);
            make.centerX.mas_equalTo(self.scanBorderView);
            make.width.mas_lessThanOrEqualTo(self.customContainerView);
            make.height.mas_lessThanOrEqualTo(200);
        }];
    }
    return _remarkLab;
}

//底部视图
-(UIView *)bottomView
{
    if(_bottomView==nil)
    {
        _bottomView=[[UIView alloc]init];
        _bottomView.backgroundColor=[UIColor colorWithRed:0 green:0 blue:0 alpha:0.4];
        [self.view addSubview:_bottomView];
        
        [_bottomView mas_makeConstraints:^(MASConstraintMaker *make){
            make.left.right.bottom.mas_equalTo(self.view);
            make.top.mas_equalTo(self.scanBorderView.mas_bottom).offset(ScreenWidth*0.2);
        }];
    }
    return _bottomView;
}

//闪光灯按钮
-(UIButton *)lightBtn
{
    if(_lightBtn==nil)
    {
        _lightBtn=[UIButton buttonWithType:UIButtonTypeCustom];
        [_lightBtn setBackgroundImage:[UIImage imageNamed:@"light_on"] forState:UIControlStateNormal];
        [_lightBtn setBackgroundImage:[UIImage imageNamed:@"light_off"] forState:UIControlStateSelected];
        [_lightBtn addTarget:self action:@selector(onOrOffLight:) forControlEvents:UIControlEventTouchDown];
        [self.bottomView addSubview:_lightBtn];
        
        [_lightBtn mas_makeConstraints:^(MASConstraintMaker *make){
            make.bottom.mas_equalTo(self.bottomView).offset(-40);
            make.width.height.mas_equalTo(48);
            make.centerX.mas_equalTo(self.bottomView);
        }];
    }
    return _lightBtn;
}

-(void)onOrOffLight:(UIButton *)sender
{
    BOOL flag=!sender.selected;
    sender.selected=flag;
    
    Class captureDeviceClass = NSClassFromString(@"AVCaptureDevice");
    if (captureDeviceClass != nil) {
        AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        
        if ([device hasTorch] && [device hasFlash]){
            
            [device lockForConfiguration:nil];
            if (flag) {
                [device setTorchMode:AVCaptureTorchModeOn];
                [device setFlashMode:AVCaptureFlashModeOn];
                
            } else {
                [device setTorchMode:AVCaptureTorchModeOff];
                [device setFlashMode:AVCaptureFlashModeOff];
            }
            [device unlockForConfiguration];
        }
    }
}

//开始动画
-(void)startAnimationEvent
{
    //多线程启动定时器
    [NSThread detachNewThreadSelector:@selector(startTimer) toTarget:self withObject:nil];
}

- (void)startTimer
{
    //定时器，设定时间过1.5秒，
    timer = [NSTimer scheduledTimerWithTimeInterval:.03 target:self selector:@selector(animation1) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop]run];
    
    
    
}

//扫描动画
-(void)animation1
{
    if (upOrdown == NO)
    {
        num ++;
        self.scanLineView.frame = CGRectMake(self.scanLineView.frame.origin.x,5+(3*num),self.scanLineView.frame.size.width, 3);
        if (3*num>= ScreenWidth*0.6-10)
        {
            upOrdown = YES;
        }
        
    }
    else
    {
        upOrdown=NO;
        num=0;
         self.scanLineView.frame=CGRectMake(0,5,ScreenWidth*0.6,3);
    }
    
}

#pragma mark --------AVCaptureMetadataOutputObjectsDelegate ---------
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    // id 类型不能点语法,所以要先去取出数组中对象
    AVMetadataMachineReadableCodeObject *object = [metadataObjects lastObject];
    
    if (object == nil) return;
    
    //NSLog(@"object==%@",object.type);
    // 清除之前的描边
    [self clearLayers];
    
    // 对扫描到的二维码进行描边
    AVMetadataMachineReadableCodeObject *obj = (AVMetadataMachineReadableCodeObject *)[self.previewLayer transformedMetadataObjectForMetadataObject:object];
    // 绘制描边
    [self drawLine:obj];
    
    if(self.scanResult)
    {
        if(timer!=nil)
        {
            [timer invalidate];
            timer=nil;
        }
        self.scanResult(object.stringValue);
    }
}

//描边
- (void)drawLine:(AVMetadataMachineReadableCodeObject *)objc
{
    NSArray *array = objc.corners;
    
    // 1.创建形状图层, 用于保存绘制的矩形
    CAShapeLayer *layer = [[CAShapeLayer alloc] init];
    
    // 设置线宽
    layer.lineWidth = 2;
    // 设置描边颜色
    layer.strokeColor = [UIColor greenColor].CGColor;
    layer.fillColor = [UIColor clearColor].CGColor;
    
    // 2.创建UIBezierPath, 绘制矩形
    UIBezierPath *path = [[UIBezierPath alloc] init];
    CGPoint point = CGPointZero;
    int index = 0;
    
    CFDictionaryRef dict = (__bridge CFDictionaryRef)(array[index++]);
    // 把点转换为不可变字典
    // 把字典转换为点，存在point里，成功返回true 其他false
    CGPointMakeWithDictionaryRepresentation(dict, &point);
    
    // 设置起点
    [path moveToPoint:point];
    
    // 2.2连接其它线段
    for (int i = 1; i<array.count; i++) {
        CGPointMakeWithDictionaryRepresentation((__bridge CFDictionaryRef)array[i], &point);
        [path addLineToPoint:point];
    }
    // 2.3关闭路径
    [path closePath];
    
    layer.path = path.CGPath;
    // 3.将用于保存矩形的图层添加到界面上
    [self.containerLayer addSublayer:layer];
}

//清除描边
- (void)clearLayers
{
    if (self.containerLayer.sublayers)
    {
        for (CALayer *subLayer in self.containerLayer.sublayers)
        {
            [subLayer removeFromSuperlayer];
        }
    }
}

//关闭页面
-(void)close;
{
    //返回事件
    [self backEvent];
}

//返回事件
-(void)backEvent
{
    if(skipWay==NAVIGATION_SKIP)
    {
        [self.navigationController popViewControllerAnimated:YES];
    }
    else if (skipWay==MODAL_SKIP)
    {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

//相册事件
-(void)photoEvent
{
    NSLog(@"***相册事件***");
    if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]){
        //1.初始化相册拾取器
        UIImagePickerController *controller = [[UIImagePickerController alloc] init];
        //2.设置代理
        controller.delegate = self;
        //3.设置资源：
        /**
         UIImagePickerControllerSourceTypePhotoLibrary,相册
         UIImagePickerControllerSourceTypeCamera,相机
         UIImagePickerControllerSourceTypeSavedPhotosAlbum,照片库
         */
        controller.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
        //4.随便给他一个转场动画
        controller.modalTransitionStyle=UIModalTransitionStyleFlipHorizontal;
        [self presentViewController:controller animated:YES completion:NULL];
        
    }else{
        
        UIAlertView * alert = [[UIAlertView alloc]initWithTitle:@"提示" message:@"设备不支持访问相册，请在设置->隐私->照片中进行设置！" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
        [alert show];
    }
}

#pragma mark -------- UIImagePickerControllerDelegate---------
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info
{
    //1.获取选择的图片
    UIImage *image = info[UIImagePickerControllerOriginalImage];
    //2.初始化一个监测器
    CIDetector*detector = [CIDetector detectorOfType:CIDetectorTypeQRCode context:nil options:@{ CIDetectorAccuracy : CIDetectorAccuracyHigh }];
    
    __weak typeof(self) weakSelf=self;
    [picker dismissViewControllerAnimated:YES completion:^{
        //监测到的结果数组
        NSArray *features = [detector featuresInImage:[CIImage imageWithCGImage:image.CGImage]];
        if (features.count >=1) {
            /**结果对象 */
            CIQRCodeFeature *feature = [features objectAtIndex:0];
            NSString *scannedResult = feature.messageString;
            if (weakSelf.scanResult)
            {
                if(timer!=nil)
                {
                    [timer invalidate];
                    timer=nil;
                }
                weakSelf.scanResult(scannedResult);
            }
        }
        else{
            
            //重新扫描
            [weakSelf.session startRunning];
            
            //开始动画
            [weakSelf startAnimationEvent];
            
            UIAlertView * alertView = [[UIAlertView alloc]initWithTitle:@"提示" message:@"该图片没有包含一个二维码或者信息已丢失！" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
            [alertView show];
            
        }
        
        
    }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker;
{
    __weak typeof(self) weakSelf=self;
    [picker dismissViewControllerAnimated:YES completion:^{
        //重新扫描
        [weakSelf.session startRunning];
        
        //开始动画
        [weakSelf startAnimationEvent];
    }];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    if(timer!=nil)
    {
        [timer invalidate];
        timer=nil;
    }
    
    [self.session stopRunning];
}

- (void)dealloc{
    
    // 删除预览图层
    if (self.previewLayer) {
        [self.previewLayer removeFromSuperlayer];
    }
    if (self.containerLayer) {
        self.containerLayer.delegate = nil;
    }
    
    if(self.output)
    {
       [self.output setMetadataObjectsDelegate:nil queue:dispatch_get_main_queue()];
        self.output=nil;
    }
    
    if(self.customContainerView)
    {
        [self.customContainerView removeFromSuperview];
        self.customContainerView=nil;
    }
    
    if(self.scanLineView)
    {
        [self.scanLineView removeFromSuperview];
        self.scanLineView=nil;
    }
    
    if(self.scanBorderView)
    {
        [self.scanBorderView removeFromSuperview];
        self.scanBorderView=nil;
    }
    
    if(self.remarkLab)
    {
        [self.remarkLab removeFromSuperview];
        self.remarkLab=nil;
    }
    
    if(self.lightBtn)
    {
        [self.lightBtn removeFromSuperview];
        self.lightBtn=nil;
    }
    
    if(self.session)
    {
        self.session=nil;
    }
    
    if(self.input)
    {
        self.customContainerView=nil;
    }
    
    
    NSLog(@"%@ will dealloc !",NSStringFromClass([self class]));
}

@end

/**
 * IoTStepFrame.m
 *
 * Copyright (c) 2014~2015 Xtreme Programming Group, Inc.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#import "IoTStepFrame.h"

@protocol IoTStepFrameDelegate <NSObject>
@optional

- (NSString *)IoTStepFrameCustomText:(IoTStepFrame *)sender;
- (BOOL)IoTStepFrameShouldCancelStep;

@end

@implementation UIViewController(IoTStepFrameExtend)

- (IoTStepFrame *)stepFrame
{
    for(IoTStepFrame *stepFrame in ProcessModel.stepFrames)
    {
        if([stepFrame.navCtrl.viewControllers indexOfObject:self] < stepFrame.navCtrl.viewControllers.count)
        {
            return stepFrame;
        }
    }
    return nil;
}

@end

@interface IoTStepFrame ()

@property (weak, nonatomic) IBOutlet UIView *stepView;
@property (weak, nonatomic) IBOutlet UIView *stepContentView;

//步骤标题
@property (weak, nonatomic) IBOutlet UIImageView *imgStep;
@property (strong, nonatomic) UILabel *textStep;

@end

@implementation IoTStepFrame

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:[IoTProcessModel resourceBundle]];
    if(self)
    {

    }
    return self;
}

- (id)initWithRootViewController:(UIViewController *)controller
{
    self = [super init];
    if(self)
    {
        _navCtrl = [[UINavigationController alloc] initWithRootViewController:controller];
        [_navCtrl setNavigationBarHidden:YES];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [self setCurrentStepIndex:_currentStepIndex];
    
    //效果修正
    self.textStep.text = @"";
    self.stepView.backgroundColor = ProcessModel.barTintColor;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    // 把 Navigation 框架加进去
    [self.stepContentView addSubview:_navCtrl.view];
    
    _navCtrl.view.frame = self.stepContentView.bounds;
    [_navCtrl.view setNeedsDisplay];

    [ProcessModel addStepFrame:self];
    [self setCurrentStepIndex:_currentStepIndex];
    [self.navigationController setNavigationBarHidden:YES];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark 步骤图片和文字
- (void)setSteps:(NSArray *)steps
{
    _steps = steps;
}

- (void)setCurrentStepIndex:(NSInteger)currentStepIndex
{
    //超出范围则重置，包括 _step.count == 0 的情况
    if(!(currentStepIndex >= 0 && currentStepIndex < _steps.count))
        currentStepIndex = 0;
        
    _currentStepIndex = currentStepIndex;
    
    //加载图片和文字
    NSDictionary *dict = _steps[currentStepIndex];
    if([dict isKindOfClass:[NSDictionary class]])
    {
        UIImage *image = [dict valueForKey:@"image"];
        NSString *text = [dict valueForKey:@"text"];
        NSDictionary *frames = [dict valueForKey:@"frames"];
        
        if(nil == self.textStep)
        {
            self.textStep = [[UILabel alloc] initWithFrame:CGRectZero];
            
            if(nil == ProcessModel.tintColor)
                self.textStep.textColor = [UIColor whiteColor];
            else
                self.textStep.textColor = ProcessModel.tintColor;
            
            self.textStep.font = [UIFont systemFontOfSize:14];
            [self.view addSubview:self.textStep];
        }
        
        self.imgStep.image = image;
        
        if([_navCtrl.viewControllers.lastObject respondsToSelector:@selector(IoTStepFrameCustomText:)])
        {
            self.textStep.text = [_navCtrl.viewControllers.lastObject IoTStepFrameCustomText:self];
        }
        else
        {
            self.textStep.text = text;
        }
        
        if([frames isKindOfClass:[NSDictionary class]])
        {
            NSValue *imageFrame = [frames valueForKey:@"image"];
            NSValue *textFrame = [frames valueForKey:@"text"];
            
            [UIView beginAnimations:nil context:nil];
            [UIView setAnimationsEnabled:YES];
            
            if(imageFrame)
                self.imgStep.frame = imageFrame.CGRectValue;
            
            if(textFrame)
                self.textStep.frame = textFrame.CGRectValue;
            
            [UIView commitAnimations];
        }
    }
}

#pragma mark 执行清理
- (IBAction)onCancel:(id)sender {
    [self cancel:YES];
}

- (void)cancel:(BOOL)animated
{
    if([_navCtrl.viewControllers.lastObject respondsToSelector:@selector(IoTStepFrameShouldCancelStep)])
    {
        if([_navCtrl.viewControllers.lastObject IoTStepFrameShouldCancelStep])
            return;
    }
    
    [ProcessModel removeStepFrame:self];
    [_navCtrl.view removeFromSuperview];
    _navCtrl = nil;
    [self.navigationController popViewControllerAnimated:animated];
}

- (void)cancelTo:(UIViewController *)controller animated:(BOOL)animated
{
    [ProcessModel removeStepFrame:self];

    [_navCtrl.view removeFromSuperview];
    _navCtrl = nil;
    
    if(![controller isKindOfClass:[UIViewController class]])
    {
        NSLog(@"warning: Can't push to this viewcontroller. Please check input param is valid.");
        return;
    }
    
    UINavigationController *navCtrl = self.navigationController;
    [navCtrl popViewControllerAnimated:NO];
    
    NSUInteger index = [navCtrl.viewControllers indexOfObject:controller];
    if(index < navCtrl.viewControllers.count)
        [navCtrl popToViewController:controller animated:YES];
    else
        [navCtrl pushViewController:controller animated:animated];
}

- (void)nextTo:(UIViewController *)controller animated:(BOOL)animated
{
    [self.navigationController pushViewController:controller animated:animated];
}

@end

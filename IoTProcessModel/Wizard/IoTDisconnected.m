//
//  IoTDisconnected.m
//  IoTProcessModel
//
//  Created by xpg on 14/12/23.
//  Copyright (c) 2014年 xpg. All rights reserved.
//

#import "IoTDisconnected.h"

@interface IoTDisconnected ()

@property (weak, nonatomic) IBOutlet UIView *mainView;

@end

@implementation IoTDisconnected

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:[IoTProcessModel resourceBundle]];
    if(self)
    {
        
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.mainView.layer.masksToBounds = YES;
    self.mainView.layer.cornerRadius = 5;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)show:(BOOL)animated
{
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationsEnabled:animated];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
    [[UIApplication sharedApplication].keyWindow addSubview:self.view];
    [UIView commitAnimations];
    
    self.view.frame = [UIApplication sharedApplication].keyWindow.frame;
}

- (void)hide:(BOOL)animated
{
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationsEnabled:animated];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
    [self.view removeFromSuperview];
    [UIView commitAnimations];
}

- (IBAction)onTap:(id)sender {
    [self hide:YES];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end

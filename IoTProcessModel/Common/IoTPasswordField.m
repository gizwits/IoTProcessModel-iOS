//
//  IoTPasswordField.m
//  IoTProcessModel
//
//  Created by xpg on 14/12/26.
//  Copyright (c) 2014年 xpg. All rights reserved.
//

#import "IoTPasswordField.h"

@interface IoTPasswordField()

@property (nonatomic, strong) UIButton *btnSwitch;

@end

@implementation IoTPasswordField

- (id)init
{
    self = [super init];
    if(self)
    {
        [self awakeFromNib];
    }
    return self;
}

- (void)awakeFromNib
{
    //按钮
    self.btnSwitch = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.btnSwitch setBackgroundImage:[IoTProcessModel imageWithFileName:@"switch_off"] forState:UIControlStateNormal];
    [self.btnSwitch setBackgroundImage:[IoTProcessModel imageWithFileName:@"switch_on"] forState:UIControlStateSelected];
    [self.btnSwitch addTarget:self action:@selector(onSwitch) forControlEvents:UIControlEventTouchUpInside];
    self.btnSwitch.frame = CGRectMake(0, 0, 41, 20);
    
    self.rightView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 46, 20)];
    [self.rightView addSubview:self.btnSwitch];
    self.rightViewMode = UITextFieldViewModeAlways;
}

- (void)onSwitch
{
    self.btnSwitch.selected = !self.btnSwitch.selected;
    self.secureTextEntry = !self.btnSwitch.selected;
    [self becomeFirstResponder];
}

@end

void initPasswordField()
{
    //这个方法，是加载xib之前用的
    NSLog(@"password field was inited.");
}

//
//  STDebugKitModuleSlowAnimations.m
//  STDebugKit
//
//  Created by Thomas Dupont on 09/09/13.

/***********************************************************************************
 *
 * Copyright (c) 2013 Thomas Dupont
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
 * FITNESS FOR A PARTICULAR PURPOSE AND NON INFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 ***********************************************************************************/

#import "STDebugKitModuleSlowAnimations.h"
#import "STDebugKit.h"

#import <QuartzCore/QuartzCore.h>

@interface STDebugKitModuleSlowAnimations ()

@property (nonatomic, strong) UISwitch* speedSwitch;

@end

@implementation STDebugKitModuleSlowAnimations

#ifdef STDebugKitModuleSlowAnimationsEnabled
+ (void)load
{
    STDebugTool* tool = [STDebugTool debugToolNamed:@"Slow Animations" viewControllerClass:[self class]];
#ifdef STDebugKitModuleSlowAnimationsOrder
    tool.order = STDebugKitModuleSlowAnimationsOrder;
#else
    tool.order = 999;
#endif
    [STDebugKit addGlobalDebugTool:tool];
}
#endif

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.view setBackgroundColor:[UIColor whiteColor]];
    
    self.title = @"Slow Animations";
    
    self.speedSwitch = [[UISwitch alloc] init];
    [self.speedSwitch addTarget:self action:@selector(handleSwitchChange:) forControlEvents:UIControlEventValueChanged];
    [self.speedSwitch setCenter:CGPointMake(self.view.bounds.size.width / 2.0, 30)];
    [self.speedSwitch setAutoresizingMask:(UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin)];
    [self.view addSubview:self.speedSwitch];
    
    CGFloat speed = [[[[[UIApplication sharedApplication] windows] objectAtIndex:0] layer] speed];
    
    [self.speedSwitch setOn:(speed != 1.0)];
}

- (void)handleSwitchChange:(UISwitch*)s
{
    [[[[[UIApplication sharedApplication] windows] objectAtIndex:0] layer] setSpeed:(self.speedSwitch.isOn ? 0.1f : 1.0f)];
}

@end

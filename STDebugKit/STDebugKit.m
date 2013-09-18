//
//  STDebugKit.m
//  STDebugKit
//
//  Created by Thomas Dupont on 03/09/13.

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

#import "STDebugKit.h"
#import "STDebugKit_private.h"

#import <QuartzCore/QuartzCore.h>

#import "STDebugKitRootViewController.h"

#ifndef STDebugKitButtonSize
#define STDebugKitButtonSize 40
#endif

#ifndef STDebugKitButtonPosition
#define STDebugKitButtonPosition CGPointMake(0,1)
#endif

#ifndef STDebugKitButtonColor
#define STDebugKitButtonColor [UIColor redColor]
#endif

#ifndef STDebugKitButtonBackgroundColor
#define STDebugKitButtonBackgroundColor [UIColor whiteColor]
#endif

@implementation STDebugKit

+ (STDebugKit*)sharedDebugKit
{
    static dispatch_once_t onceToken;
    static STDebugKit* gDebugKit = nil;;
    dispatch_once(&onceToken, ^{
        gDebugKit = [[STDebugKit alloc] init];
    });
    return gDebugKit;
}

- (id)init
{
    self = [super init];
    if (self)
    {
        self.contextActions = [[NSMutableDictionary alloc] init];
        self.globalActions = [[NSMutableArray alloc] init];
    }
    return self;
}

//TODO: Re frame button on root view frame change


+ (void)configure
{
    UIView* root = [[[UIApplication sharedApplication] delegate] window];
    CGRect appFrame = [[UIScreen mainScreen] applicationFrame];
    CGPoint origin = STDebugKitButtonPosition;
    origin.x = MAX(MIN(origin.x, 1), 0);
    origin.y = MAX(MIN(origin.y, 1), 0);
    
    UIView* view = [[UIView alloc] initWithFrame:CGRectMake(appFrame.origin.x + (appFrame.size.width - STDebugKitButtonSize) * origin.x,
                                                            appFrame.origin.y + (appFrame.size.height - STDebugKitButtonSize) * origin.y,
                                                            STDebugKitButtonSize, STDebugKitButtonSize)];
    [view setBackgroundColor:[UIColor clearColor]];
    [root addSubview:view];
    
    CAShapeLayer* shape = [CAShapeLayer layer];
    [shape setPath:[UIBezierPath bezierPathWithOvalInRect:view.bounds].CGPath];
    [shape setFillColor:STDebugKitButtonColor.CGColor];
    [view.layer addSublayer:shape];
    
    CAShapeLayer* shape2 = [CAShapeLayer layer];
    [shape2 setPath:[UIBezierPath bezierPathWithOvalInRect:CGRectInset(view.bounds, 2, 2)].CGPath];
    [shape2 setFillColor:STDebugKitButtonBackgroundColor.CGColor];
    [view.layer addSublayer:shape2];
    
    CAShapeLayer* s = [CAShapeLayer layer];
    
    CGFloat s_2 = STDebugKitButtonSize/2.0;
    CGFloat s_4 = STDebugKitButtonSize/4.0;
    CGFloat s_8 = STDebugKitButtonSize/8.0;
    CGFloat s_16 = STDebugKitButtonSize/16.0;
    CGFloat s_32 = STDebugKitButtonSize/32.0;
    
    UIBezierPath* path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(s_4 + s_16, s_2 + s_4 + s_16)];
    [path addArcWithCenter:CGPointMake(s_4, s_2 + s_4) radius:s_16 * sqrtf(2) startAngle:M_PI_4 endAngle:-3*M_PI_4 clockwise:YES];
    [path addLineToPoint:CGPointMake(s_2 - s_16, s_2 - s_16)];
    [path addArcWithCenter:CGPointMake(s_2 + s_8, s_2 - s_8) radius:s_8 * sqrtf(2) startAngle:11*(M_PI/12.0) endAngle:-4*(M_PI/12.0) clockwise:YES];
    [path addLineToPoint:CGPointMake(s_2 + s_8 - s_32, s_2 - s_8 - s_32)];
    [path addLineToPoint:CGPointMake(s_2 + s_8 + s_32, s_2 - s_8 + s_32)];
    [path addLineToPoint:CGPointMake(s_2 + s_8 + s_8 + s_32, s_2 - s_8 - s_16 - s_32)];
    [path addArcWithCenter:CGPointMake(s_2 + s_8, s_2 - s_8) radius:s_8 * sqrtf(2) startAngle:-2*(M_PI/12.0) endAngle:7*(M_PI/12.0) clockwise:YES];
    [path closePath];
    
    [s setPath:path.CGPath];
    [s setFillColor:STDebugKitButtonColor.CGColor];
    [view.layer addSublayer:s];
    
    UIPanGestureRecognizer* pan = [[UIPanGestureRecognizer alloc] initWithTarget:[self sharedDebugKit] action:@selector(handlePanGesture:)];
    [view addGestureRecognizer:pan];
    
    UITapGestureRecognizer* tap = [[UITapGestureRecognizer alloc] initWithTarget:[self sharedDebugKit] action:@selector(handleTapGesture:)];
    [view addGestureRecognizer:tap];
    
    [self sharedDebugKit].debugKitButton = view;
}

+ (void)addGlobalDebugTool:(STDebugTool*)debugTool
{
    [[self sharedDebugKit].globalActions addObject:debugTool];
}

+ (void)addContextDebugTool:(STDebugTool*)debugTool forKey:(NSString*)key
{
    NSMutableArray* actions = [[self sharedDebugKit].contextActions objectForKey:key];
    
    if (!actions)
    {
        actions = [[NSMutableArray alloc] init];
        [[self sharedDebugKit].contextActions setObject:actions forKey:key];
    }
    
    [actions addObject:debugTool];
}

+ (void)removeContextDebugToolForKey:(NSString*)key
{
    [[self sharedDebugKit].contextActions removeObjectForKey:key];
}

- (void)handlePanGesture:(UIPanGestureRecognizer*)pan
{
    UIView* view = pan.view;
    CGPoint translation = [pan translationInView:view.superview];
    
    CGPoint center = view.center;
    center.x += translation.x;
    center.y += translation.y;
    view.center = center;
    
    [pan setTranslation:CGPointZero inView:view.superview];
    
    if (pan.state == UIGestureRecognizerStateEnded || pan.state == UIGestureRecognizerStateCancelled)
    {
        CGRect frame = view.frame;
        CGRect appFrame = [[UIScreen mainScreen] applicationFrame];
        
        CGFloat x = 0;
        CGFloat y = 0;
        
        if (frame.origin.x < (appFrame.size.width + appFrame.origin.x) / 2.0)
        {
            x = appFrame.origin.x;
        }
        else
        {
            x = appFrame.origin.x + appFrame.size.width - frame.size.width;
        }
        
        if (frame.origin.y < (appFrame.size.height + appFrame.origin.y) / 2.0)
        {
            y = appFrame.origin.y;
        }
        else
        {
            y = appFrame.origin.y + appFrame.size.height - frame.size.height;
        }
        
        if (fabsf(x - frame.origin.x) < fabsf(y - frame.origin.y))
        {
            frame.origin.x = x;
            frame.origin.y = MIN(MAX(frame.origin.y, appFrame.origin.y), appFrame.origin.y + appFrame.size.height - frame.size.height);
        }
        else
        {
            frame.origin.y = y;
            frame.origin.x = MIN(MAX(frame.origin.x, appFrame.origin.x), appFrame.origin.x + appFrame.size.width - frame.size.width);
        }
        
        if (!CGRectEqualToRect(view.frame, frame))
        {
            [UIView animateWithDuration:0.2 animations:^{
                view.frame = frame;
            }];
        }
    }
}

- (void)handleTapGesture:(UITapGestureRecognizer*)pan
{
    if (self.debugKitViewController)
    {
        [self hideDebugKit];
    }
    else
    {
        [self displayDebugKit];
    }
}

- (void)displayDebugKit
{
    if (!self.debugKitViewController)
    {
        STDebugKitRootViewController* dkRoot = [[STDebugKitRootViewController alloc] initWithContextActions:self.contextActions globalActions:self.globalActions];
        UINavigationController* nav = [[UINavigationController alloc] initWithRootViewController:dkRoot];
        
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
        {
            nav.modalPresentationStyle = UIModalPresentationFormSheet;
        }
        
        UIViewController* root = [[[[UIApplication sharedApplication] delegate] window] rootViewController];
        
        if ([root presentedViewController])
        {
            root = [root presentedViewController];
        }
        
        [root presentViewController:nav animated:YES completion:nil];
        self.debugKitViewController = nav;
    }
}

- (void)hideDebugKit
{
    [self hideDebugKitWithCompletion:nil];
}

- (void)hideDebugKitWithCompletion:(dispatch_block_t)completion
{
    if (self.debugKitViewController)
    {
        [self.debugKitViewController dismissViewControllerAnimated:YES completion:^{
            self.debugKitViewController = nil;
            if (completion)
            {
                completion();
            }
        }];
    }
}

@end

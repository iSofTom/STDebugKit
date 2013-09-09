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

#import <QuartzCore/QuartzCore.h>

#import "STDebugKitRootViewController.h"

#ifndef STDebugKitButtonSize
#define STDebugKitButtonSize 40
#endif

@interface STDebugKit ()

@property (nonatomic, strong) NSMutableDictionary* contextActions;
@property (nonatomic, strong) NSMutableArray* globalActions;

+ (STDebugKit*)sharedDebugKit;

@end

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
    UIView* root = [[[[[UIApplication sharedApplication] delegate] window] rootViewController] view];
    CGSize rootSize = root.bounds.size;
    
    UIView* view = [[UIView alloc] initWithFrame:CGRectMake(rootSize.width - STDebugKitButtonSize, roundf(rootSize.height / 2.0 - STDebugKitButtonSize / 2.0), STDebugKitButtonSize, STDebugKitButtonSize)];
    [view setBackgroundColor:[UIColor clearColor]];
    [root addSubview:view];
    
    CAShapeLayer* shape = [CAShapeLayer layer];
    [shape setPath:[UIBezierPath bezierPathWithOvalInRect:view.bounds].CGPath];
    [shape setFillColor:[UIColor redColor].CGColor];
    [view.layer addSublayer:shape];
    
    CAShapeLayer* shape2 = [CAShapeLayer layer];
    [shape2 setPath:[UIBezierPath bezierPathWithOvalInRect:CGRectInset(view.bounds, 2, 2)].CGPath];
    [shape2 setFillColor:[UIColor whiteColor].CGColor];
    [view.layer addSublayer:shape2];
    
    CAShapeLayer* s = [CAShapeLayer layer];
    
    CGFloat q = STDebugKitButtonSize/4.0;
    CGFloat c = STDebugKitButtonSize/2.0;
    CGFloat w = STDebugKitButtonSize/16.0;
    CGFloat r = STDebugKitButtonSize/8.0;
    
    UIBezierPath* path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(q + w, c + q + w)];
    [path addArcWithCenter:CGPointMake(q, c + q) radius:w * sqrtf(2) startAngle:M_PI_4 endAngle:-3*M_PI_4 clockwise:YES];
    [path addLineToPoint:CGPointMake(c - w, c - w)];
    [path addArcWithCenter:CGPointMake(c - w + r, c - w - r) radius:r * sqrtf(2) startAngle:3*M_PI_4 endAngle:-M_PI_4 clockwise:YES];
    [path addLineToPoint:CGPointMake(c + r, c - w - w - r)];
    [path addArcWithCenter:CGPointMake(c + r + w, c - w - r) radius:w * sqrtf(2) startAngle:-3*M_PI_4 endAngle:M_PI_4 clockwise:NO];
    [path addLineToPoint:CGPointMake(c + w + r + r, c + w - r - r)];
    [path addArcWithCenter:CGPointMake(c + w + r, c + w - r) radius:r * sqrtf(2) startAngle:-M_PI_4 endAngle:3*M_PI_4 clockwise:YES];
    [path closePath];
    
    [s setPath:path.CGPath];
    [s setFillColor:[UIColor redColor].CGColor];
    [view.layer addSublayer:s];
    
    UIPanGestureRecognizer* pan = [[UIPanGestureRecognizer alloc] initWithTarget:[self sharedDebugKit] action:@selector(handlePanGesture:)];
    [view addGestureRecognizer:pan];
    
    UITapGestureRecognizer* tap = [[UITapGestureRecognizer alloc] initWithTarget:[self sharedDebugKit] action:@selector(handleTapGesture:)];
    [view addGestureRecognizer:tap];
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
        UIView* parent = view.superview;
        
        CGRect frame = view.frame;
        CGSize parentSize = parent.bounds.size;
        
        if (frame.origin.x < parentSize.width / 2.0)
        {
            frame.origin.x = 0;
        }
        else
        {
            frame.origin.x = parentSize.width - frame.size.width;
        }
        
        frame.origin.y = MIN(MAX(frame.origin.y, 0), parentSize.height - frame.size.height);
        
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
    STDebugKitRootViewController* dkRoot = [[STDebugKitRootViewController alloc] initWithContextActions:self.contextActions globalActions:self.globalActions];
    UINavigationController* nav = [[UINavigationController alloc] initWithRootViewController:dkRoot];
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
    {
        nav.modalPresentationStyle = UIModalPresentationFormSheet;
    }
    
    UIViewController* root = [[[[UIApplication sharedApplication] delegate] window] rootViewController];
    [root presentViewController:nav animated:YES completion:nil];
}

@end

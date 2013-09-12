//
//  STDebugKit_private.h
//  STDebugKitDemo
//
//  Created by Thomas Dupont on 11/09/13.
//  Copyright (c) 2013 iSofTom. All rights reserved.
//

#import "STDebugKit.h"

@interface STDebugKit ()

@property (nonatomic, strong) NSMutableDictionary* contextActions;
@property (nonatomic, strong) NSMutableArray* globalActions;
@property (nonatomic, strong) UIViewController* debugKitViewController;
@property (nonatomic, strong) UIView* debugKitButton;

+ (STDebugKit*)sharedDebugKit;

- (void)hideDebugKit;

@end

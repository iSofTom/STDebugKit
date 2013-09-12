//
//  STDebugKit.h
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

#import <Foundation/Foundation.h>

#import "STDebugTool.h"

#ifdef DEBUG
#define DebugKitConfigure() [STDebugKit configure];
#define DebugKitAddAction(name, block ...) [STDebugKit addContextDebugTool:[STDebugTool debugToolNamed:(name) action:(block)] forKey:[NSString stringWithFormat:@"%@-%p", NSStringFromClass([self class]), self]];
#define DebugKitAddViewController(name, viewController, block ...) {STDebugTool* tool = [STDebugTool debugToolNamed:(name) viewControllerClass:[viewController class]];[tool setToolAction:(block)];[STDebugKit addContextDebugTool:tool forKey:[NSString stringWithFormat:@"%@-%p", NSStringFromClass([self class]), self]];}
#define DebugKitRemove() [STDebugKit removeContextDebugToolForKey:[NSString stringWithFormat:@"%@-%p", NSStringFromClass([self class]), self]];
#else
#define DebugKitConfigure()
#define DebugKitAddAction(name, block ...)
#define DebugKitAddViewController(name, viewController, block ...)
#define DebugKitRemove()
#endif

/**
 *	STDebugKit offer access from several debug tools from everywhere
 *
 *  To configure it, simply add DebugKitConfigure() right before the return of your application:DidFinishLaunchingWithOptions: method.
 */
@interface STDebugKit : NSObject

+ (void)configure;

+ (void)addGlobalDebugTool:(STDebugTool*)debugTool;

+ (void)addContextDebugTool:(STDebugTool*)debugTool forKey:(NSString*)key;

+ (void)removeContextDebugToolForKey:(NSString*)key;

@end

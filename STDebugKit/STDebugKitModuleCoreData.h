//
//  STDebugKitModuleCoreData.h
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

#import <UIKit/UIKit.h>

/**
 - Module Core Data -
 Allow several actions on your database
 * Find objects based on a predicate
 * Count objects of a specific entity
 * Delete objects based on a predicate
 * Clear all instances of an entity
 
 This module use MagicalRecord.
 
 In order to use it, you should add the below define right before first import of STDebugKit
 #define STDebugKitModuleCoreDataEnabled
 */
@interface STDebugKitModuleCoreData : UIViewController

/**
 * You can use the STDebugKitModuleCoreData with your own NSManagedObjectContext.
 * The global module is always using the [NSManagedObjectContext defaultContext]
 * but you can add a context core data module:
 
 DebugKitAddViewController(@"CoreData", STDebugKitModuleCoreData, ^(id o){
    [(STDebugKitModuleCoreData*)o setUsingContext:self.context];
 });
 
 */
@property (nonatomic, strong) NSManagedObjectContext* usingContext;

@end

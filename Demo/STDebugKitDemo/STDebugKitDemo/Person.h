//
//  Person.h
//  STDebugKitDemo
//
//  Created by Thomas Dupont on 03/09/13.
//  Copyright (c) 2013 iSofTom. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Person : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * age;
@property (nonatomic, retain) NSManagedObject *firm;

@end

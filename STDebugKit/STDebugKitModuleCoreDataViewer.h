//
//  STDebugKitModuleCoreDataViewer.h
//  STDebugKitDemo
//
//  Created by Thomas Dupont on 17/09/13.
//  Copyright (c) 2013 iSofTom. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface STDebugKitModuleCoreDataObjectViewer : UIViewController

@property (nonatomic, strong) NSManagedObjectContext* usingContext;
@property (nonatomic, strong) NSManagedObjectID* objectId;

@end

@interface STDebugKitModuleCoreDataPredicateViewer : UIViewController

@property (nonatomic, strong) NSManagedObjectContext* usingContext;
@property (nonatomic, strong) NSPredicate* predicate;
@property (nonatomic, strong) Class entityClass;

@end

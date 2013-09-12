//
//  SecondViewController.m
//  STDebugKitDemo
//
//  Created by Thomas Dupont on 03/09/13.
//  Copyright (c) 2013 iSofTom. All rights reserved.
//

#import "SecondViewController.h"

#import "Firm.h"
#import "Person.h"
#import "STDebugKitModuleCoreData.h"

@interface SecondViewController ()

@property (nonatomic, strong) NSString* name;
@property (nonatomic, strong) NSManagedObjectContext* context;

@end

@implementation SecondViewController

- (id)initWithName:(NSString*)name
{
    self = [super init];
    if (self)
    {
        self.name = name;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    self.context = [NSManagedObjectContext contextWithParent:[NSManagedObjectContext contextWithParent:[NSManagedObjectContext defaultContext]]];
    
#ifdef __IPHONE_7_0
    if ([self respondsToSelector:@selector(setEdgesForExtendedLayout:)])
    {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
#endif
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    DebugKitAddAction(@"Log Name", ^(id o){
        [[[UIAlertView alloc] initWithTitle:@"Name" message:self.name delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
    })
    
    DebugKitAddViewController(@"CoreData", STDebugKitModuleCoreData, ^(id o){
        [(STDebugKitModuleCoreData*)o setUsingContext:self.context];
    });
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    DebugKitRemove()
}

- (IBAction)handleButtonTap:(id)sender
{
    [self insertInContext:self.context];
}

- (IBAction)handleGlobalInsertButtonTap:(id)sender
{
    [self insertInContext:[NSManagedObjectContext defaultContext]];
}

- (void)insertInContext:(NSManagedObjectContext*)ctx
{
    NSManagedObjectContext* context = [NSManagedObjectContext contextWithParent:ctx];
    
    [context performBlock:^{
        Firm* firm = [Firm createInContext:context];
        firm.name = @"Apple";
        
        Person* person = [Person createInContext:context];
        person.name = @"Steve";
        person.age = @21;
        person.firm = firm;
        
        person = [Person createInContext:context];
        person.name = @"Jony";
        person.age = @22;
        person.firm = firm;
        
        person = [Person createInContext:context];
        person.name = @"Scott";
        person.age = @23;
        person.firm = firm;
        
        if (context == [NSManagedObjectContext defaultContext])
        {
            [context saveToPersistentStoreWithCompletion:nil];
        }
        else
        {
            [context saveOnlySelfWithCompletion:nil];
        }
    }];
}

@end

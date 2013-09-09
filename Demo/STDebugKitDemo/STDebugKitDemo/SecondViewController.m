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

@interface SecondViewController ()

@property (nonatomic, strong) NSString* name;

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
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    DebugKitAdd(@"Log Name", ^{
        [[[UIAlertView alloc] initWithTitle:@"Name" message:self.name delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
    })
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    DebugKitRemove()
}

- (IBAction)handleButtonTap:(id)sender
{
    NSManagedObjectContext* context = [NSManagedObjectContext contextWithParent:[NSManagedObjectContext defaultContext]];
    
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
        
        [context saveToPersistentStoreWithCompletion:nil];
    }];
}

@end

//
//  STDebugKitModuleCoreDataViewer.m
//  STDebugKitDemo
//
//  Created by Thomas Dupont on 17/09/13.
//  Copyright (c) 2013 iSofTom. All rights reserved.
//

#import "STDebugKitModuleCoreDataViewer.h"

#import <QuartzCore/QuartzCore.h>

@interface STDebugKitModuleCoreDataObjectViewer () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView* tableView;
@property (nonatomic, strong) NSMutableArray* attributes;
@property (nonatomic, strong) NSMutableArray* attributesValues;
@property (nonatomic, strong) NSMutableArray* relationships;
@property (nonatomic, strong) NSMutableArray* relationshipsValues;

@end

@implementation STDebugKitModuleCoreDataObjectViewer

- (id)init
{
    self = [super init];
    if (self)
    {
        self.usingContext = [NSManagedObjectContext defaultContext];
        
        self.attributes = [[NSMutableArray alloc] init];
        self.attributesValues = [[NSMutableArray alloc] init];
        self.relationships = [[NSMutableArray alloc] init];
        self.relationshipsValues = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
#ifdef __IPHONE_7_0
    if ([self respondsToSelector:@selector(setEdgesForExtendedLayout:)])
    {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
#endif
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds];
    [self.tableView setAutoresizingMask:(UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight)];
    [self.view addSubview:self.tableView];
    [self.tableView setDelegate:self];
    [self.tableView setDataSource:self];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self.attributes removeAllObjects];
    [self.attributesValues removeAllObjects];
    [self.relationships removeAllObjects];
    [self.relationshipsValues removeAllObjects];
    
    NSManagedObject* object = [self.usingContext objectWithID:self.objectId];
    NSEntityDescription* entity = object.entity;
    
    NSDictionary* attributes = [entity attributesByName];
    
    for (NSString* attribute in [attributes allKeys])
    {
        NSObject* value = [object valueForKey:attribute];
        if (value)
        {
            NSString* valueStr = [NSString stringWithFormat:@"%@", value];
            if (valueStr)
            {
                [self.attributes addObject:attribute];
                [self.attributesValues addObject:valueStr];
            }
        }
    }
    
    NSDictionary* relationships = [entity relationshipsByName];
    
    for (NSString* relationship in [relationships allKeys])
    {
        NSObject* value = [object valueForKey:relationship];
        
        [self.relationships addObject:relationship];
        
        if ([value isKindOfClass:[NSManagedObject class]])
        {
            [self.relationshipsValues addObject:[(NSManagedObject*)value objectID]];
        }
        else if ([value isKindOfClass:[NSSet class]] || [value isKindOfClass:[NSOrderedSet class]])
        {
            NSRelationshipDescription* desc = [relationships objectForKey:relationship];
            NSEntityDescription* entity = desc.destinationEntity;
            NSRelationshipDescription* invert = desc.inverseRelationship;
            NSString* entityName = entity.name;
            
            if (entityName && invert)
            {
                NSPredicate* predicate = [NSPredicate predicateWithFormat:@"%K = %@", invert.name, object];
                
                [self.relationshipsValues addObject:@[entityName, predicate]];
            }
            else
            {
                [self.relationshipsValues addObject:[NSNull null]];
            }
        }
        else
        {
            [self.relationshipsValues addObject:[NSNull null]];
        }
    }
    
    [self.tableView reloadData];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0)
    {
        return [self.attributes count];
    }
    else
    {
        return [self.relationships count];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString* identifier = @"identifier";
    
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    
    if (!cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:identifier];
    }
    
    if (indexPath.section == 0)
    {
        [cell setAccessoryType:UITableViewCellAccessoryNone];
        cell.textLabel.text = [self.attributes objectAtIndex:indexPath.row];
        cell.detailTextLabel.text = [self.attributesValues objectAtIndex:indexPath.row];
    }
    else
    {
        cell.textLabel.text = [self.relationships objectAtIndex:indexPath.row];
        cell.detailTextLabel.text = nil;
        
        if ([[self.relationshipsValues objectAtIndex:indexPath.row] isKindOfClass:[NSManagedObjectID class]])
        {
            [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
        }
        else if ([[self.relationshipsValues objectAtIndex:indexPath.row] isKindOfClass:[NSArray class]])
        {
            [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
        }
        else
        {
            [cell setAccessoryType:UITableViewCellAccessoryNone];
        }
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0)
    {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
    else
    {
        if ([[self.relationshipsValues objectAtIndex:indexPath.row] isKindOfClass:[NSManagedObjectID class]])
        {
            NSManagedObjectID* objectId = [self.relationshipsValues objectAtIndex:indexPath.row];
            STDebugKitModuleCoreDataObjectViewer* viewer = [[STDebugKitModuleCoreDataObjectViewer alloc] init];
            viewer.usingContext = self.usingContext;
            viewer.objectId = objectId;
            [self.navigationController pushViewController:viewer animated:YES];
        }
        else if ([[self.relationshipsValues objectAtIndex:indexPath.row] isKindOfClass:[NSArray class]])
        {
            NSArray* array = [self.relationshipsValues objectAtIndex:indexPath.row];
            
            NSString* entityName = [array objectAtIndex:0];
            NSPredicate* predicate = [array objectAtIndex:1];
            
            STDebugKitModuleCoreDataPredicateViewer* viewer = [[STDebugKitModuleCoreDataPredicateViewer alloc] init];
            viewer.usingContext = self.usingContext;
            viewer.predicate = predicate;
            viewer.entityClass = NSClassFromString(entityName);
            [self.navigationController pushViewController:viewer animated:YES];
        }
        else
        {
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 24;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0)
    {
        return @"Attributes";
    }
    else
    {
        return @"Relationships";
    }
}

@end

@interface STDebugKitModuleCoreDataPredicateViewer () <UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate, UIPickerViewDataSource, UIPickerViewDelegate>

@property (nonatomic, strong) UITableView* tableView;
@property (nonatomic, strong) NSFetchedResultsController* fetchedResultsController;
@property (nonatomic, strong) NSString* sortKey;
@property (nonatomic, strong) UIButton* attributeButton;
@property (nonatomic, strong) UIView* touchCatcherView;
@property (nonatomic, strong) UIPickerView* pickerView;
@property (nonatomic, strong) NSMutableArray* data;

@end

@implementation STDebugKitModuleCoreDataPredicateViewer

- (id)init
{
    self = [super init];
    if (self)
    {
        self.usingContext = [NSManagedObjectContext defaultContext];
        self.data = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
#ifdef __IPHONE_7_0
    if ([self respondsToSelector:@selector(setEdgesForExtendedLayout:)])
    {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
#endif
    
    [self.view setBackgroundColor:[UIColor whiteColor]];
    
    self.attributeButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [self.attributeButton setFrame:CGRectMake(20, 10, self.view.bounds.size.width - 40, 40)];
    [self.attributeButton setAutoresizingMask:(UIViewAutoresizingFlexibleWidth)];
    [self.attributeButton setTitle:@"Choose Attribute" forState:UIControlStateNormal];
    [self.attributeButton addTarget:self action:@selector(handleAttributeButtonTap:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.attributeButton];
    
    NSArray* digits = [[[UIDevice currentDevice] systemVersion] componentsSeparatedByString:@"."];
    if ([digits count] > 0 && [digits[0] intValue] > 6)
    {
        [self.attributeButton setBackgroundColor:[UIColor whiteColor]];
        [self.attributeButton.layer setCornerRadius:5];
        [self.attributeButton.layer setBorderColor:[UIColor lightGrayColor].CGColor];
        [self.attributeButton.layer setBorderWidth:1];
    }
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 60, self.view.bounds.size.width, self.view.bounds.size.height - 60)];
    [self.tableView setAutoresizingMask:(UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight)];
    [self.view addSubview:self.tableView];
    [self.tableView setDelegate:self];
    [self.tableView setDataSource:self];
    
    self.touchCatcherView = [[UIView alloc] initWithFrame:self.view.bounds];
    [self.touchCatcherView setAutoresizingMask:(UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight)];
    [self.view addSubview:self.touchCatcherView];
    [self.touchCatcherView setBackgroundColor:[UIColor blackColor]];
    [self.touchCatcherView setAlpha:0.3f];
    [self.touchCatcherView setHidden:YES];
    
    [self.touchCatcherView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTouchCatcherTap:)]];
    
    self.pickerView = [[UIPickerView alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height - 216, self.view.bounds.size.width, 216)];
    [self.pickerView setBackgroundColor:[UIColor whiteColor]];
    [self.pickerView setAutoresizingMask:(UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleTopMargin)];
    [self.view addSubview:self.pickerView];
    [self.pickerView setDataSource:self];
    [self.pickerView setDelegate:self];
    [self.pickerView setHidden:YES];
}

- (void)reloadFetchedResultsController
{
    self.fetchedResultsController = nil;
    if (self.sortKey)
    {
        self.title = [NSString stringWithFormat:@"%i object(s)", [self.entityClass countOfEntitiesWithPredicate:self.predicate inContext:self.usingContext]];
        self.fetchedResultsController = [self.entityClass fetchAllSortedBy:self.sortKey ascending:YES withPredicate:self.predicate groupBy:nil delegate:self inContext:self.usingContext];
    }
    [self.tableView reloadData];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self.data removeAllObjects];
    
    NSEntityDescription* entity = [NSEntityDescription entityForName: NSStringFromClass(self.entityClass) inManagedObjectContext:self.usingContext];
    NSDictionary* attributes = [entity attributesByName];
    
    for (NSString* attribute in [attributes allKeys])
    {
        [self.data addObject:attribute];
    }
    
    if ([self.data count] > 0)
    {
        [self.pickerView reloadAllComponents];
        [self updateAttributeButtonWithTitleAtIndex:0];
    }
    else
    {
        [[[UIAlertView alloc] initWithTitle:@"Error" message:@"No attributes found" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Ok", nil] show];
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [[self.fetchedResultsController sections] count];
}

- (NSInteger)tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section
{
    if ([[self.fetchedResultsController sections] count] > 0)
    {
        id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:section];
        return [sectionInfo numberOfObjects];
    }
    else
    {
        return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString* identifier = @"identifier";
    
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    
    if (!cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:identifier];
        [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
    }
    
    NSManagedObject* object = [self.fetchedResultsController objectAtIndexPath:indexPath];
    id o = [object valueForKey:self.sortKey];
    
    cell.textLabel.text = [NSString stringWithFormat:@"%@", o];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSManagedObject* object = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    if (object)
    {
        NSManagedObjectID* objectId = object.objectID;
        STDebugKitModuleCoreDataObjectViewer* viewer = [[STDebugKitModuleCoreDataObjectViewer alloc] init];
        viewer.usingContext = self.usingContext;
        viewer.objectId = objectId;
        [self.navigationController pushViewController:viewer animated:YES];
    }
    else
    {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView reloadData];
}

- (void)displayPicker
{
    __block CGRect pickerFrame = self.pickerView.frame;
    pickerFrame.origin.y = self.view.bounds.size.height;
    self.pickerView.frame = pickerFrame;
    
    self.touchCatcherView.alpha = 0.0f;
    
    self.pickerView.hidden = NO;
    self.touchCatcherView.hidden = NO;
    
    [UIView animateWithDuration:0.3 animations:^{
        
        pickerFrame.origin.y = self.view.bounds.size.height - pickerFrame.size.height;
        self.pickerView.frame = pickerFrame;
        
        self.touchCatcherView.alpha = 0.3;
        
    }];
}

- (void)hidePicker
{
    [UIView animateWithDuration:0.3 animations:^{
        
        CGRect pickerFrame = self.pickerView.frame;
        pickerFrame.origin.y = self.view.bounds.size.height;
        self.pickerView.frame = pickerFrame;
        
        self.touchCatcherView.alpha = 0.0f;
        
    } completion:^(BOOL finished) {
        self.pickerView.hidden = YES;
        self.touchCatcherView.hidden = YES;
    }];
}

- (void)handleAttributeButtonTap:(UIButton*)button
{
    [self displayPicker];
}

- (void)handleTouchCatcherTap:(UITapGestureRecognizer*)tap
{
    [self hidePicker];
}

- (void)updateAttributeButtonWithTitleAtIndex:(NSInteger)index
{
    NSString* key = [self.data objectAtIndex:index];
    self.sortKey = key;
    [self.attributeButton setTitle:key forState:UIControlStateNormal];
    [self reloadFetchedResultsController];
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return [self.data count];
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    return [self.data objectAtIndex:row];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    [self updateAttributeButtonWithTitleAtIndex:row];
}

@end

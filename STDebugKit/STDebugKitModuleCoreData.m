//
//  STDebugKitModuleCoreData.m
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

#import "STDebugKitModuleCoreData.h"
#import "STDebugKit.h"

@interface STDebugKitCoreDataDisplayViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) NSManagedObjectID* objectId;
@property (nonatomic, strong) UITableView* tableView;
@property (nonatomic, strong) NSMutableArray* attributes;
@property (nonatomic, strong) NSMutableArray* attributesValues;
@property (nonatomic, strong) NSMutableArray* relationships;
@property (nonatomic, strong) NSMutableArray* relationshipsValues;

@end

@implementation STDebugKitCoreDataDisplayViewController

- (id)initWithObjectID:(NSManagedObjectID*)objectId
{
    self = [super init];
    if (self)
    {
        self.objectId = objectId;
        
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
    
    NSManagedObject* object = [[NSManagedObjectContext defaultContext] objectWithID:self.objectId];
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
        else if ([value isKindOfClass:[NSArray class]] || [value isKindOfClass:[NSSet class]])
        {
            [self.relationshipsValues addObject:[NSString stringWithFormat:@"(%i)", [(NSArray*)value count]]];
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
        else if ([[self.relationshipsValues objectAtIndex:indexPath.row] isKindOfClass:[NSString class]])
        {
            [cell setAccessoryType:UITableViewCellAccessoryNone];
            cell.detailTextLabel.text = [self.relationshipsValues objectAtIndex:indexPath.row];
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
        if ([[self.relationshipsValues objectAtIndex:indexPath.row] isKindOfClass:[NSNull class]])
        {
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
        }
        else
        {
            NSManagedObjectID* objectId = [self.relationshipsValues objectAtIndex:indexPath.row];
            STDebugKitCoreDataDisplayViewController* display = [[STDebugKitCoreDataDisplayViewController alloc] initWithObjectID:objectId];
            [self.navigationController pushViewController:display animated:YES];
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

@interface STDebugKitCoreDataFindViewController : UIViewController <UIPickerViewDataSource, UIPickerViewDelegate, UITextFieldDelegate>

@property (nonatomic, strong) UIPickerView* pickerView;
@property (nonatomic, strong) NSMutableArray* data;
@property (nonatomic, strong) UIButton* entityButton;
@property (nonatomic, strong) UIButton* attributeButton;
@property (nonatomic, strong) UITextField* textField;
@property (nonatomic, strong) UIView* touchCatcherView;
@property (nonatomic, strong) UIButton* selectedButton;
@property (nonatomic, strong) UIButton* searchButton;

@end

@implementation STDebugKitCoreDataFindViewController

NSString* const STDebugKitCoreDataFindViewControllerAttributeButtonText = @"Choose Attribute";

- (id)init
{
    self = [super init];
    if (self)
    {
        self.data = [[NSMutableArray alloc] init];
        self.title = @"Find";
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.view setBackgroundColor:[UIColor whiteColor]];
    
    self.entityButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [self.entityButton setFrame:CGRectMake(20, 20, self.view.bounds.size.width - 40, 40)];
    [self.entityButton setAutoresizingMask:(UIViewAutoresizingFlexibleWidth)];
    [self.entityButton setTitle:@"Choose Entity" forState:UIControlStateNormal];
    [self.entityButton addTarget:self action:@selector(handleEntityButtonTap:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.entityButton];
    
    self.attributeButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [self.attributeButton setFrame:CGRectMake(20, 80, self.view.bounds.size.width - 40, 40)];
    [self.attributeButton setAutoresizingMask:(UIViewAutoresizingFlexibleWidth)];
    [self.attributeButton setTitle:STDebugKitCoreDataFindViewControllerAttributeButtonText forState:UIControlStateNormal];
    [self.attributeButton addTarget:self action:@selector(handleAttributeButtonTap:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.attributeButton];
    [self.attributeButton setHidden:YES];
    
    self.textField = [[UITextField alloc] initWithFrame:CGRectMake(20, 140, self.view.bounds.size.width - 40, 30)];
    [self.textField setAutoresizingMask:(UIViewAutoresizingFlexibleWidth)];
    [self.textField setBorderStyle:UITextBorderStyleRoundedRect];
    [self.view addSubview:self.textField];
    [self.textField setDelegate:self];
    [self.textField setHidden:YES];
    
    self.searchButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [self.searchButton setFrame:CGRectMake(20, 190, self.view.bounds.size.width - 40, 40)];
    [self.searchButton setAutoresizingMask:(UIViewAutoresizingFlexibleWidth)];
    [self.searchButton setTitle:@"Find" forState:UIControlStateNormal];
    [self.searchButton addTarget:self action:@selector(handleSearchButtonTap:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.searchButton];
    [self.searchButton setHidden:YES];
    
    self.touchCatcherView = [[UIView alloc] initWithFrame:self.view.bounds];
    [self.touchCatcherView setAutoresizingMask:(UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight)];
    [self.view addSubview:self.touchCatcherView];
    [self.touchCatcherView setBackgroundColor:[UIColor blackColor]];
    [self.touchCatcherView setAlpha:0.3f];
    [self.touchCatcherView setHidden:YES];
    
    [self.touchCatcherView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTouchCatcherTap:)]];
    
    self.pickerView = [[UIPickerView alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height - 216, self.view.bounds.size.width, 216)];
    [self.pickerView setAutoresizingMask:(UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleTopMargin)];
    [self.view addSubview:self.pickerView];
    [self.pickerView setDataSource:self];
    [self.pickerView setDelegate:self];
    [self.pickerView setHidden:YES];
}

- (void)handleEntityButtonTap:(UIButton*)button
{
    [self.data removeAllObjects];
    
    NSManagedObjectModel* model = [NSManagedObjectContext defaultContext].persistentStoreCoordinator.managedObjectModel;
    NSArray* entities = model.entities;
    
    for (NSEntityDescription* entity in entities)
    {
        [self.data addObject:entity.name];
    }
    
    if ([self.data count] > 0)
    {
        [self.pickerView reloadAllComponents];
        [self.pickerView selectRow:0 inComponent:0 animated:NO];
        self.selectedButton = self.entityButton;
        [self updateEntityButtonWithTitleAtIndex:0];
        
        [self displayPicker];
    }
    else
    {
        [[[UIAlertView alloc] initWithTitle:@"Erreur" message:@"Cette base n'a pas d'entités" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Ok", nil] show];
    }
}

- (void)handleAttributeButtonTap:(UIButton*)button
{
    [self.data removeAllObjects];
    
    NSString* entityName = [self.entityButton titleForState:UIControlStateNormal];
    NSEntityDescription* entity = [NSEntityDescription entityForName:entityName inManagedObjectContext:[NSManagedObjectContext defaultContext]];
    NSDictionary* attributes = [entity attributesByName];
    
    for (NSString* attribute in [attributes allKeys])
    {
        [self.data addObject:attribute];
    }
    
    if ([self.data count] > 0)
    {
        [self.pickerView reloadAllComponents];
        [self.pickerView selectRow:0 inComponent:0 animated:NO];
        self.selectedButton = self.attributeButton;
        [self updateAttributeButtonWithTitleAtIndex:0];
        
        [self displayPicker];
    }
    else
    {
        [[[UIAlertView alloc] initWithTitle:@"Erreur" message:@"Cette entité n'a pas d'attributs" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Ok", nil] show];
    }
}

- (void)handleSearchButtonTap:(UIButton*)button
{
    NSString* entityName = [self.entityButton titleForState:UIControlStateNormal];
    NSString* attributeName = [self.attributeButton titleForState:UIControlStateNormal];
    NSString* attributeValue = [self.textField text];
    
    NSEntityDescription* entity = [NSEntityDescription entityForName:entityName inManagedObjectContext:[NSManagedObjectContext defaultContext]];
    Class entityClass = NSClassFromString([entity managedObjectClassName]);
    
    NSManagedObject* object = nil;
    
    if ([attributeName isEqualToString:STDebugKitCoreDataFindViewControllerAttributeButtonText])
    {
        object = [entityClass findFirst];
    }
    else
    {
        object = [entityClass findFirstWithPredicate:[NSPredicate predicateWithFormat:@"%K = %@", attributeName, attributeValue]];
    }
    
    if (object)
    {
        STDebugKitCoreDataDisplayViewController* display = [[STDebugKitCoreDataDisplayViewController alloc] initWithObjectID:object.objectID];
        [self.navigationController pushViewController:display animated:YES];
    }
    else
    {
        [[[UIAlertView alloc] initWithTitle:@"Erreur" message:@"Aucun objet n'a été trouvé" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Ok", nil] show];
    }
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

- (void)handleTouchCatcherTap:(UITapGestureRecognizer*)tap
{
    [self hidePicker];
}

- (void)updateEntityButtonWithTitleAtIndex:(NSInteger)index
{
    [self.entityButton setTitle:[self.data objectAtIndex:index] forState:UIControlStateNormal];
    [self.attributeButton setHidden:NO];
    [self.attributeButton setTitle:STDebugKitCoreDataFindViewControllerAttributeButtonText forState:UIControlStateNormal];
    [self.textField setHidden:YES];
    [self.searchButton setHidden:NO];
}

- (void)updateAttributeButtonWithTitleAtIndex:(NSInteger)index
{
    [self.attributeButton setTitle:[self.data objectAtIndex:index] forState:UIControlStateNormal];
    [self.textField setHidden:NO];
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
    if (self.selectedButton == self.entityButton)
    {
        [self updateEntityButtonWithTitleAtIndex:row];
    }
    else
    {
        [self updateAttributeButtonWithTitleAtIndex:row];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self.textField resignFirstResponder];
    return YES;
}

@end

@interface STDebugKitCoreDataCountViewController : UIViewController <UIPickerViewDataSource, UIPickerViewDelegate>

@property (nonatomic, strong) UIPickerView* pickerView;
@property (nonatomic, strong) NSMutableArray* data;
@property (nonatomic, strong) UIButton* entityButton;
@property (nonatomic, strong) UIView* touchCatcherView;
@property (nonatomic, strong) UILabel* label;

@end

@implementation STDebugKitCoreDataCountViewController

- (id)init
{
    self = [super init];
    if (self)
    {
        self.data = [[NSMutableArray alloc] init];
        self.title = @"Count";
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.view setBackgroundColor:[UIColor whiteColor]];
    
    self.entityButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [self.entityButton setFrame:CGRectMake(20, 20, self.view.bounds.size.width - 40, 40)];
    [self.entityButton setAutoresizingMask:(UIViewAutoresizingFlexibleWidth)];
    [self.entityButton setTitle:@"Choose Entity" forState:UIControlStateNormal];
    [self.entityButton addTarget:self action:@selector(handleEntityButtonTap:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.entityButton];
    
    self.label = [[UILabel alloc] initWithFrame:CGRectMake(20, 80, self.view.bounds.size.width - 40, 30)];
    [self.label setBackgroundColor:[UIColor whiteColor]];
    [self.label setTextColor:[UIColor blackColor]];
    [self.label setFont:[UIFont systemFontOfSize:18]];
    [self.label setTextAlignment:NSTextAlignmentCenter];
    [self.label setAutoresizingMask:(UIViewAutoresizingFlexibleWidth)];
    [self.view addSubview:self.label];
    
    self.touchCatcherView = [[UIView alloc] initWithFrame:self.view.bounds];
    [self.touchCatcherView setAutoresizingMask:(UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight)];
    [self.view addSubview:self.touchCatcherView];
    [self.touchCatcherView setBackgroundColor:[UIColor blackColor]];
    [self.touchCatcherView setAlpha:0.3f];
    [self.touchCatcherView setHidden:YES];
    
    [self.touchCatcherView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTouchCatcherTap:)]];
    
    self.pickerView = [[UIPickerView alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height - 216, self.view.bounds.size.width, 216)];
    [self.pickerView setAutoresizingMask:(UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleTopMargin)];
    [self.view addSubview:self.pickerView];
    [self.pickerView setDataSource:self];
    [self.pickerView setDelegate:self];
    [self.pickerView setHidden:YES];
}

- (void)handleEntityButtonTap:(UIButton*)button
{
    [self.data removeAllObjects];
    
    NSManagedObjectModel* model = [NSManagedObjectContext defaultContext].persistentStoreCoordinator.managedObjectModel;
    NSArray* entities = model.entities;
    
    for (NSEntityDescription* entity in entities)
    {
        [self.data addObject:entity.name];
    }
    
    if ([self.data count] > 0)
    {
        [self.pickerView reloadAllComponents];
        [self.pickerView selectRow:0 inComponent:0 animated:NO];
        [self updateEntityButtonWithTitleAtIndex:0];
        
        [self displayPicker];
    }
    else
    {
        [[[UIAlertView alloc] initWithTitle:@"Erreur" message:@"Cette base n'a pas d'entités" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Ok", nil] show];
    }
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

- (void)handleTouchCatcherTap:(UITapGestureRecognizer*)tap
{
    [self hidePicker];
}

- (void)updateEntityButtonWithTitleAtIndex:(NSInteger)index
{
    [self.entityButton setTitle:[self.data objectAtIndex:index] forState:UIControlStateNormal];
    
    NSString* entityName = [self.entityButton titleForState:UIControlStateNormal];
    
    NSEntityDescription* entity = [NSEntityDescription entityForName:entityName inManagedObjectContext:[NSManagedObjectContext defaultContext]];
    Class entityClass = NSClassFromString([entity managedObjectClassName]);
    
    self.label.text = [NSString stringWithFormat:@"%i",[entityClass countOfEntities]];
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
    [self updateEntityButtonWithTitleAtIndex:row];
}

@end

@interface STDebugKitCoreDataDeleteViewController : UIViewController <UIPickerViewDataSource, UIPickerViewDelegate, UITextFieldDelegate>

@property (nonatomic, strong) UIPickerView* pickerView;
@property (nonatomic, strong) NSMutableArray* data;
@property (nonatomic, strong) UIButton* entityButton;
@property (nonatomic, strong) UIButton* attributeButton;
@property (nonatomic, strong) UITextField* textField;
@property (nonatomic, strong) UIView* touchCatcherView;
@property (nonatomic, strong) UIButton* selectedButton;
@property (nonatomic, strong) UIButton* deleteButton;

@end

@implementation STDebugKitCoreDataDeleteViewController

NSString* const STDebugKitCoreDataDeleteViewControllerAttributeButtonText = @"Choose Attribute";

- (id)init
{
    self = [super init];
    if (self)
    {
        self.data = [[NSMutableArray alloc] init];
        self.title = @"Delete";
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.view setBackgroundColor:[UIColor whiteColor]];
    
    self.entityButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [self.entityButton setFrame:CGRectMake(20, 20, self.view.bounds.size.width - 40, 40)];
    [self.entityButton setAutoresizingMask:(UIViewAutoresizingFlexibleWidth)];
    [self.entityButton setTitle:@"Choose Entity" forState:UIControlStateNormal];
    [self.entityButton addTarget:self action:@selector(handleEntityButtonTap:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.entityButton];
    
    self.attributeButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [self.attributeButton setFrame:CGRectMake(20, 80, self.view.bounds.size.width - 40, 40)];
    [self.attributeButton setAutoresizingMask:(UIViewAutoresizingFlexibleWidth)];
    [self.attributeButton setTitle:STDebugKitCoreDataDeleteViewControllerAttributeButtonText forState:UIControlStateNormal];
    [self.attributeButton addTarget:self action:@selector(handleAttributeButtonTap:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.attributeButton];
    [self.attributeButton setHidden:YES];
    
    self.textField = [[UITextField alloc] initWithFrame:CGRectMake(20, 140, self.view.bounds.size.width - 40, 30)];
    [self.textField setAutoresizingMask:(UIViewAutoresizingFlexibleWidth)];
    [self.textField setBorderStyle:UITextBorderStyleRoundedRect];
    [self.view addSubview:self.textField];
    [self.textField setDelegate:self];
    [self.textField setHidden:YES];
    
    self.deleteButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [self.deleteButton setFrame:CGRectMake(20, 190, self.view.bounds.size.width - 40, 40)];
    [self.deleteButton setAutoresizingMask:(UIViewAutoresizingFlexibleWidth)];
    [self.deleteButton setTitle:@"Delete" forState:UIControlStateNormal];
    [self.deleteButton addTarget:self action:@selector(handleDeleteButtonTap:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.deleteButton];
    [self.deleteButton setHidden:YES];
    
    self.touchCatcherView = [[UIView alloc] initWithFrame:self.view.bounds];
    [self.touchCatcherView setAutoresizingMask:(UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight)];
    [self.view addSubview:self.touchCatcherView];
    [self.touchCatcherView setBackgroundColor:[UIColor blackColor]];
    [self.touchCatcherView setAlpha:0.3f];
    [self.touchCatcherView setHidden:YES];
    
    [self.touchCatcherView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTouchCatcherTap:)]];
    
    self.pickerView = [[UIPickerView alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height - 216, self.view.bounds.size.width, 216)];
    [self.pickerView setAutoresizingMask:(UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleTopMargin)];
    [self.view addSubview:self.pickerView];
    [self.pickerView setDataSource:self];
    [self.pickerView setDelegate:self];
    [self.pickerView setHidden:YES];
}

- (void)handleEntityButtonTap:(UIButton*)button
{
    [self.data removeAllObjects];
    
    NSManagedObjectModel* model = [NSManagedObjectContext defaultContext].persistentStoreCoordinator.managedObjectModel;
    NSArray* entities = model.entities;
    
    for (NSEntityDescription* entity in entities)
    {
        [self.data addObject:entity.name];
    }
    
    if ([self.data count] > 0)
    {
        [self.pickerView reloadAllComponents];
        [self.pickerView selectRow:0 inComponent:0 animated:NO];
        self.selectedButton = self.entityButton;
        [self updateEntityButtonWithTitleAtIndex:0];
        
        [self displayPicker];
    }
    else
    {
        [[[UIAlertView alloc] initWithTitle:@"Erreur" message:@"Cette base n'a pas d'entités" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Ok", nil] show];
    }
}

- (void)handleAttributeButtonTap:(UIButton*)button
{
    [self.data removeAllObjects];
    
    NSString* entityName = [self.entityButton titleForState:UIControlStateNormal];
    NSEntityDescription* entity = [NSEntityDescription entityForName:entityName inManagedObjectContext:[NSManagedObjectContext defaultContext]];
    NSDictionary* attributes = [entity attributesByName];
    
    for (NSString* attribute in [attributes allKeys])
    {
        [self.data addObject:attribute];
    }
    
    if ([self.data count] > 0)
    {
        [self.pickerView reloadAllComponents];
        [self.pickerView selectRow:0 inComponent:0 animated:NO];
        self.selectedButton = self.attributeButton;
        [self updateAttributeButtonWithTitleAtIndex:0];
        
        [self displayPicker];
    }
    else
    {
        [[[UIAlertView alloc] initWithTitle:@"Erreur" message:@"Cette entité n'a pas d'attributs" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Ok", nil] show];
    }
}

- (void)handleDeleteButtonTap:(UIButton*)button
{
    NSString* entityName = [self.entityButton titleForState:UIControlStateNormal];
    NSString* attributeName = [self.attributeButton titleForState:UIControlStateNormal];
    NSString* attributeValue = [self.textField text];
    
    NSEntityDescription* entity = [NSEntityDescription entityForName:entityName inManagedObjectContext:[NSManagedObjectContext defaultContext]];
    Class entityClass = NSClassFromString([entity managedObjectClassName]);
    
    NSManagedObject* object = nil;
    
    if ([attributeName isEqualToString:STDebugKitCoreDataDeleteViewControllerAttributeButtonText])
    {
        object = [entityClass findFirst];
    }
    else
    {
        object = [entityClass findFirstWithPredicate:[NSPredicate predicateWithFormat:@"%K = %@", attributeName, attributeValue]];
    }
    
    if (object)
    {
        [object deleteEntity];
        
        [[NSManagedObjectContext defaultContext] saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
            [[[UIAlertView alloc] initWithTitle:@"Delete" message:@"Delete successfull" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Ok", nil] show];
        }];
    }
    else
    {
        [[[UIAlertView alloc] initWithTitle:@"Erreur" message:@"Aucun objet n'a été trouvé" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Ok", nil] show];
    }
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

- (void)handleTouchCatcherTap:(UITapGestureRecognizer*)tap
{
    [self hidePicker];
}

- (void)updateEntityButtonWithTitleAtIndex:(NSInteger)index
{
    [self.entityButton setTitle:[self.data objectAtIndex:index] forState:UIControlStateNormal];
    [self.attributeButton setHidden:NO];
    [self.attributeButton setTitle:STDebugKitCoreDataDeleteViewControllerAttributeButtonText forState:UIControlStateNormal];
    [self.textField setHidden:YES];
    [self.deleteButton setHidden:NO];
}

- (void)updateAttributeButtonWithTitleAtIndex:(NSInteger)index
{
    [self.attributeButton setTitle:[self.data objectAtIndex:index] forState:UIControlStateNormal];
    [self.textField setHidden:NO];
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
    if (self.selectedButton == self.entityButton)
    {
        [self updateEntityButtonWithTitleAtIndex:row];
    }
    else
    {
        [self updateAttributeButtonWithTitleAtIndex:row];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self.textField resignFirstResponder];
    return YES;
}

@end

@interface STDebugKitCoreDataClearViewController : UIViewController <UIPickerViewDataSource, UIPickerViewDelegate>

@property (nonatomic, strong) UIPickerView* pickerView;
@property (nonatomic, strong) NSMutableArray* data;
@property (nonatomic, strong) UIButton* entityButton;
@property (nonatomic, strong) UIButton* clearButton;
@property (nonatomic, strong) UIView* touchCatcherView;

@end

@implementation STDebugKitCoreDataClearViewController

NSString* const STDebugKitCoreDataClearViewControllerAllEntitiesText = @"All Entities";

- (id)init
{
    self = [super init];
    if (self)
    {
        self.data = [[NSMutableArray alloc] init];
        self.title = @"Clear";
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.view setBackgroundColor:[UIColor whiteColor]];
    
    self.entityButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [self.entityButton setFrame:CGRectMake(20, 20, self.view.bounds.size.width - 40, 40)];
    [self.entityButton setAutoresizingMask:(UIViewAutoresizingFlexibleWidth)];
    [self.entityButton setTitle:@"Choose Entity" forState:UIControlStateNormal];
    [self.entityButton addTarget:self action:@selector(handleEntityButtonTap:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.entityButton];
    
    self.clearButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [self.clearButton setFrame:CGRectMake(20, 80, self.view.bounds.size.width - 40, 40)];
    [self.clearButton setAutoresizingMask:(UIViewAutoresizingFlexibleWidth)];
    [self.clearButton setTitle:@"Clear" forState:UIControlStateNormal];
    [self.clearButton addTarget:self action:@selector(handleClearButtonTap:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.clearButton];
    [self.clearButton setHidden:YES];
    
    self.touchCatcherView = [[UIView alloc] initWithFrame:self.view.bounds];
    [self.touchCatcherView setAutoresizingMask:(UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight)];
    [self.view addSubview:self.touchCatcherView];
    [self.touchCatcherView setBackgroundColor:[UIColor blackColor]];
    [self.touchCatcherView setAlpha:0.3f];
    [self.touchCatcherView setHidden:YES];
    
    [self.touchCatcherView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTouchCatcherTap:)]];
    
    self.pickerView = [[UIPickerView alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height - 216, self.view.bounds.size.width, 216)];
    [self.pickerView setAutoresizingMask:(UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleTopMargin)];
    [self.view addSubview:self.pickerView];
    [self.pickerView setDataSource:self];
    [self.pickerView setDelegate:self];
    [self.pickerView setHidden:YES];
}

- (void)handleEntityButtonTap:(UIButton*)button
{
    [self.data removeAllObjects];
    
    NSManagedObjectModel* model = [NSManagedObjectContext defaultContext].persistentStoreCoordinator.managedObjectModel;
    NSArray* entities = model.entities;
    
    [self.data addObject:STDebugKitCoreDataClearViewControllerAllEntitiesText];
    
    for (NSEntityDescription* entity in entities)
    {
        [self.data addObject:entity.name];
    }
    
    if ([self.data count] > 0)
    {
        [self.pickerView reloadAllComponents];
        [self.pickerView selectRow:0 inComponent:0 animated:NO];
        [self updateEntityButtonWithTitleAtIndex:0];
        
        [self displayPicker];
    }
    else
    {
        [[[UIAlertView alloc] initWithTitle:@"Erreur" message:@"Cette base n'a pas d'entités" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Ok", nil] show];
    }
}

- (void)handleClearButtonTap:(UIButton*)button
{
    NSString* entityName = [self.entityButton titleForState:UIControlStateNormal];
    
    if ([entityName isEqualToString:STDebugKitCoreDataClearViewControllerAllEntitiesText])
    {
        NSManagedObjectModel* model = [NSManagedObjectContext defaultContext].persistentStoreCoordinator.managedObjectModel;
        NSArray* entities = model.entities;
        
        for (NSEntityDescription* entity in entities)
        {
            Class entityClass = NSClassFromString([entity managedObjectClassName]);
            [entityClass truncateAll];
        }
    }
    else
    {
        NSEntityDescription* entity = [NSEntityDescription entityForName:entityName inManagedObjectContext:[NSManagedObjectContext defaultContext]];
        Class entityClass = NSClassFromString([entity managedObjectClassName]);
        
        [entityClass truncateAll];
    }
    
    [[NSManagedObjectContext defaultContext] saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
        [[[UIAlertView alloc] initWithTitle:@"Clear" message:@"delete successfull" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Ok", nil] show];
    }];
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

- (void)handleTouchCatcherTap:(UITapGestureRecognizer*)tap
{
    [self hidePicker];
}

- (void)updateEntityButtonWithTitleAtIndex:(NSInteger)index
{
    [self.entityButton setTitle:[self.data objectAtIndex:index] forState:UIControlStateNormal];
    [self.clearButton setHidden:NO];
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
    [self updateEntityButtonWithTitleAtIndex:row];
}

@end

@interface STDebugKitModuleCoreData () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView* tableView;
@property (nonatomic, strong) NSMutableArray* data;

@end

@implementation STDebugKitModuleCoreData

#ifdef STDebugKitModuleCoreDataEnabled
+ (void)load
{
    STDebugTool* tool = [STDebugTool debugToolNamed:@"CoreData" viewControllerClass:[self class]];
#ifdef STDebugKitModuleCoreDataOrder
    tool.order = STDebugKitModuleCoreDataOrder;
#else
    tool.order = 999;
#endif
    [STDebugKit addGlobalDebugTool:tool];
}
#endif

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"CoreData";
    
    self.data = [[NSMutableArray alloc] init];
	
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds];
    [self.tableView setAutoresizingMask:(UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight)];
    [self.view addSubview:self.tableView];
    [self.tableView setDelegate:self];
    [self.tableView setDataSource:self];
    
    [self.data addObject:@"Find"];
    [self.data addObject:@"Count"];
    [self.data addObject:@"Delete"];
    [self.data addObject:@"Clear"];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.data count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString* identifier = @"identifier";
    
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    
    if (!cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    cell.textLabel.text = [self.data objectAtIndex:indexPath.row];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0)
    {
        STDebugKitCoreDataFindViewController* find = [[STDebugKitCoreDataFindViewController alloc] init];
        [self.navigationController pushViewController:find animated:YES];
    }
    else if (indexPath.row == 1)
    {
        STDebugKitCoreDataCountViewController* count = [[STDebugKitCoreDataCountViewController alloc] init];
        [self.navigationController pushViewController:count animated:YES];
    }
    else if (indexPath.row == 2)
    {
        STDebugKitCoreDataDeleteViewController* clear = [[STDebugKitCoreDataDeleteViewController alloc] init];
        [self.navigationController pushViewController:clear animated:YES];
    }
    else if (indexPath.row == 3)
    {
        STDebugKitCoreDataClearViewController* clear = [[STDebugKitCoreDataClearViewController alloc] init];
        [self.navigationController pushViewController:clear animated:YES];
    }
}

@end

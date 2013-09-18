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

#import <QuartzCore/QuartzCore.h>

#import "STDebugKitModuleCoreDataViewer.h"

@interface STDebugKitCoreDataFindViewController : UIViewController <UIPickerViewDataSource, UIPickerViewDelegate, UITextFieldDelegate>

@property (nonatomic, strong) UIPickerView* pickerView;
@property (nonatomic, strong) NSMutableArray* data;
@property (nonatomic, strong) UIButton* entityButton;
@property (nonatomic, strong) UIButton* attributeButton;
@property (nonatomic, strong) UITextField* textField;
@property (nonatomic, strong) UIView* touchCatcherView;
@property (nonatomic, strong) UIButton* selectedButton;
@property (nonatomic, strong) NSManagedObjectContext* usingContext;

@end

@implementation STDebugKitCoreDataFindViewController

NSString* const STDebugKitCoreDataFindViewControllerAttributeButtonText = @"- All -";
NSString* const STDebugKitCoreDataFindViewControllerEntityButtonText = @"Choose Entity";

- (id)initWithContext:(NSManagedObjectContext*)context
{
    self = [super init];
    if (self)
    {
        self.data = [[NSMutableArray alloc] init];
        self.title = @"Find";
        self.usingContext = context;
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
    
    [self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:@"Find" style:UIBarButtonItemStyleDone target:self action:@selector(handleSearchButtonTap:)]];
    
    self.entityButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [self.entityButton setBackgroundColor:[UIColor whiteColor]];
    [self.entityButton setFrame:CGRectMake(20, 20, self.view.bounds.size.width - 40, 40)];
    [self.entityButton setAutoresizingMask:(UIViewAutoresizingFlexibleWidth)];
    [self.entityButton setTitle:STDebugKitCoreDataFindViewControllerEntityButtonText forState:UIControlStateNormal];
    [self.entityButton addTarget:self action:@selector(handleEntityButtonTap:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.entityButton];
    
    self.attributeButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [self.attributeButton setFrame:CGRectMake(20, 80, self.view.bounds.size.width - 40, 40)];
    [self.attributeButton setAutoresizingMask:(UIViewAutoresizingFlexibleWidth)];
    [self.attributeButton setTitle:STDebugKitCoreDataFindViewControllerAttributeButtonText forState:UIControlStateNormal];
    [self.attributeButton addTarget:self action:@selector(handleAttributeButtonTap:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.attributeButton];
    [self.attributeButton setHidden:YES];
    
    NSArray* digits = [[[UIDevice currentDevice] systemVersion] componentsSeparatedByString:@"."];
    if ([digits count] > 0 && [digits[0] intValue] > 6)
    {
        void (^configure)(UIButton*) = ^(UIButton* btn){
            [btn setBackgroundColor:[UIColor whiteColor]];
            [btn.layer setCornerRadius:5];
            [btn.layer setBorderColor:[UIColor lightGrayColor].CGColor];
            [btn.layer setBorderWidth:1];
        };
        configure(self.entityButton);
        configure(self.attributeButton);
    }
    
    self.textField = [[UITextField alloc] initWithFrame:CGRectMake(20, 140, self.view.bounds.size.width - 40, 30)];
    [self.textField setAutocapitalizationType:UITextAutocapitalizationTypeNone];
    [self.textField setAutoresizingMask:(UIViewAutoresizingFlexibleWidth)];
    [self.textField setBorderStyle:UITextBorderStyleRoundedRect];
    [self.view addSubview:self.textField];
    [self.textField setDelegate:self];
    [self.textField setHidden:YES];
    
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

- (void)handleEntityButtonTap:(UIButton*)button
{
    [self.data removeAllObjects];
    
    NSManagedObjectModel* model = self.usingContext.persistentStoreCoordinator.managedObjectModel;
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
        [[[UIAlertView alloc] initWithTitle:@"Error" message:@"No Entity found" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Ok", nil] show];
    }
}

- (void)handleAttributeButtonTap:(UIButton*)button
{
    [self.data removeAllObjects];
    
    NSString* entityName = [self.entityButton titleForState:UIControlStateNormal];
    NSEntityDescription* entity = [NSEntityDescription entityForName:entityName inManagedObjectContext:self.usingContext];
    NSDictionary* attributes = [entity attributesByName];
    
    [self.data addObject:STDebugKitCoreDataFindViewControllerAttributeButtonText];
    
    for (NSString* attribute in [attributes allKeys])
    {
        [self.data addObject:attribute];
    }
    
    [self.pickerView reloadAllComponents];
    [self.pickerView selectRow:0 inComponent:0 animated:NO];
    self.selectedButton = self.attributeButton;
    [self updateAttributeButtonWithTitleAtIndex:0];
    
    [self displayPicker];
}

- (void)handleSearchButtonTap:(id)button
{
    NSString* entityName = [self.entityButton titleForState:UIControlStateNormal];
    
    if ([entityName isEqualToString:STDebugKitCoreDataFindViewControllerEntityButtonText])
    {
        [[[UIAlertView alloc] initWithTitle:@"Error" message:@"You should choose an entity" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Ok", nil] show];
    }
    else
    {
        NSString* attributeName = [self.attributeButton titleForState:UIControlStateNormal];
        id attributeValue = [self.textField text];
        
        NSEntityDescription* entity = [NSEntityDescription entityForName:entityName inManagedObjectContext:self.usingContext];
        Class entityClass = NSClassFromString([entity managedObjectClassName]);
        
        NSDictionary* attributes = [entity attributesByName];
        NSAttributeDescription* attribute = [attributes objectForKey:attributeName];
        NSAttributeType type = attribute.attributeType;
        
        if (type == NSInteger16AttributeType || type == NSInteger32AttributeType)
        {
            attributeValue = @([attributeValue integerValue]);
        }
        else if (type == NSFloatAttributeType)
        {
            attributeValue = @([attributeValue floatValue]);
        }
        else if (type == NSDoubleAttributeType)
        {
            attributeValue = @([attributeValue doubleValue]);
        }
        else if (type == NSBooleanAttributeType)
        {
            attributeValue = @([attributeValue boolValue]);
        }
        
        STDebugKitModuleCoreDataPredicateViewer* viewer = [[STDebugKitModuleCoreDataPredicateViewer alloc] init];
        viewer.usingContext = self.usingContext;
        viewer.entityClass = entityClass;
        if (![attributeName isEqualToString:STDebugKitCoreDataFindViewControllerAttributeButtonText])
        {
            viewer.predicate = [NSPredicate predicateWithFormat:@"%K = %@", attributeName, attributeValue];
        }
        [self.navigationController pushViewController:viewer animated:YES];
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
}

- (void)updateAttributeButtonWithTitleAtIndex:(NSInteger)index
{
    NSString* title = [self.data objectAtIndex:index];
    [self.attributeButton setTitle:title forState:UIControlStateNormal];
    [self.textField setHidden:[title isEqualToString:STDebugKitCoreDataFindViewControllerAttributeButtonText]];
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
@property (nonatomic, strong) NSManagedObjectContext* usingContext;

@end

@implementation STDebugKitCoreDataCountViewController

- (id)initWithContext:(NSManagedObjectContext*)context
{
    self = [super init];
    if (self)
    {
        self.data = [[NSMutableArray alloc] init];
        self.usingContext = context;
        self.title = @"Count";
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
    
    self.entityButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [self.entityButton setFrame:CGRectMake(20, 20, self.view.bounds.size.width - 40, 40)];
    [self.entityButton setAutoresizingMask:(UIViewAutoresizingFlexibleWidth)];
    [self.entityButton setTitle:@"Choose Entity" forState:UIControlStateNormal];
    [self.entityButton addTarget:self action:@selector(handleEntityButtonTap:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.entityButton];
    
    NSArray* digits = [[[UIDevice currentDevice] systemVersion] componentsSeparatedByString:@"."];
    if ([digits count] > 0 && [digits[0] intValue] > 6)
    {
        [self.entityButton setBackgroundColor:[UIColor whiteColor]];
        [self.entityButton.layer setCornerRadius:5];
        [self.entityButton.layer setBorderColor:[UIColor lightGrayColor].CGColor];
        [self.entityButton.layer setBorderWidth:1];
    }
    
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
    [self.pickerView setBackgroundColor:[UIColor whiteColor]];
    [self.pickerView setAutoresizingMask:(UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleTopMargin)];
    [self.view addSubview:self.pickerView];
    [self.pickerView setDataSource:self];
    [self.pickerView setDelegate:self];
    [self.pickerView setHidden:YES];
}

- (void)handleEntityButtonTap:(UIButton*)button
{
    [self.data removeAllObjects];
    
    NSManagedObjectModel* model = self.usingContext.persistentStoreCoordinator.managedObjectModel;
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
        [[[UIAlertView alloc] initWithTitle:@"Error" message:@"No entity found" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Ok", nil] show];
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
    
    NSEntityDescription* entity = [NSEntityDescription entityForName:entityName inManagedObjectContext:self.usingContext];
    Class entityClass = NSClassFromString([entity managedObjectClassName]);
    
    self.label.text = [NSString stringWithFormat:@"%i",[entityClass countOfEntitiesWithContext:self.usingContext]];
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

@interface STDebugKitCoreDataDeleteViewController : UIViewController <UIPickerViewDataSource, UIPickerViewDelegate, UITextFieldDelegate, UIActionSheetDelegate>

@property (nonatomic, strong) UIPickerView* pickerView;
@property (nonatomic, strong) NSMutableArray* data;
@property (nonatomic, strong) UIButton* entityButton;
@property (nonatomic, strong) UIButton* attributeButton;
@property (nonatomic, strong) UITextField* textField;
@property (nonatomic, strong) UIView* touchCatcherView;
@property (nonatomic, strong) UIButton* selectedButton;
@property (nonatomic, strong) UIButton* deleteButton;
@property (nonatomic, strong) NSManagedObjectContext* usingContext;

@end

@implementation STDebugKitCoreDataDeleteViewController

NSString* const STDebugKitCoreDataDeleteViewControllerAttributeButtonText = @"- All -";
NSString* const STDebugKitCoreDataDeleteViewControllerEntityButtonText = @"Choose Entity";

- (id)initWithContext:(NSManagedObjectContext*)context
{
    self = [super init];
    if (self)
    {
        self.data = [[NSMutableArray alloc] init];
        self.usingContext = context;
        self.title = @"Delete";
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
    
    [self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:@"Delete" style:UIBarButtonItemStyleDone target:self action:@selector(handleDeleteButtonTap:)]];
    
    self.entityButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [self.entityButton setFrame:CGRectMake(20, 20, self.view.bounds.size.width - 40, 40)];
    [self.entityButton setAutoresizingMask:(UIViewAutoresizingFlexibleWidth)];
    [self.entityButton setTitle:STDebugKitCoreDataDeleteViewControllerEntityButtonText forState:UIControlStateNormal];
    [self.entityButton addTarget:self action:@selector(handleEntityButtonTap:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.entityButton];
    
    self.attributeButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [self.attributeButton setFrame:CGRectMake(20, 80, self.view.bounds.size.width - 40, 40)];
    [self.attributeButton setAutoresizingMask:(UIViewAutoresizingFlexibleWidth)];
    [self.attributeButton setTitle:STDebugKitCoreDataDeleteViewControllerAttributeButtonText forState:UIControlStateNormal];
    [self.attributeButton addTarget:self action:@selector(handleAttributeButtonTap:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.attributeButton];
    [self.attributeButton setHidden:YES];
    
    NSArray* digits = [[[UIDevice currentDevice] systemVersion] componentsSeparatedByString:@"."];
    if ([digits count] > 0 && [digits[0] intValue] > 6)
    {
        void (^configure)(UIButton*) = ^(UIButton* btn){
            [btn setBackgroundColor:[UIColor whiteColor]];
            [btn.layer setCornerRadius:5];
            [btn.layer setBorderColor:[UIColor lightGrayColor].CGColor];
            [btn.layer setBorderWidth:1];
        };
        configure(self.entityButton);
        configure(self.attributeButton);
    }
    
    self.textField = [[UITextField alloc] initWithFrame:CGRectMake(20, 140, self.view.bounds.size.width - 40, 30)];
    [self.textField setAutoresizingMask:(UIViewAutoresizingFlexibleWidth)];
    [self.textField setAutocapitalizationType:UITextAutocapitalizationTypeNone];
    [self.textField setBorderStyle:UITextBorderStyleRoundedRect];
    [self.view addSubview:self.textField];
    [self.textField setDelegate:self];
    [self.textField setHidden:YES];
    
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

- (void)handleEntityButtonTap:(UIButton*)button
{
    [self.data removeAllObjects];
    
    NSManagedObjectModel* model = self.usingContext.persistentStoreCoordinator.managedObjectModel;
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
        [[[UIAlertView alloc] initWithTitle:@"Error" message:@"No entity found" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Ok", nil] show];
    }
}

- (void)handleAttributeButtonTap:(UIButton*)button
{
    [self.data removeAllObjects];
    
    NSString* entityName = [self.entityButton titleForState:UIControlStateNormal];
    NSEntityDescription* entity = [NSEntityDescription entityForName:entityName inManagedObjectContext:[NSManagedObjectContext defaultContext]];
    NSDictionary* attributes = [entity attributesByName];
    
    [self.data addObject:STDebugKitCoreDataDeleteViewControllerAttributeButtonText];
    
    for (NSString* attribute in [attributes allKeys])
    {
        [self.data addObject:attribute];
    }
    
    [self.pickerView reloadAllComponents];
    [self.pickerView selectRow:0 inComponent:0 animated:NO];
    self.selectedButton = self.attributeButton;
    [self updateAttributeButtonWithTitleAtIndex:0];
    
    [self displayPicker];
}

- (void)handleDeleteButtonTap:(UIButton*)button
{
    if ([[self.entityButton titleForState:UIControlStateNormal] isEqualToString:STDebugKitCoreDataDeleteViewControllerEntityButtonText])
    {
        [[[UIAlertView alloc] initWithTitle:@"Error" message:@"You should choose an entity" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Ok", nil] show];
    }
    else
    {
        UIActionSheet* sheet = [[UIActionSheet alloc] initWithTitle:@"This action can't be undone" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Delete" otherButtonTitles:nil];
        [sheet showInView:self.view];
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == actionSheet.destructiveButtonIndex)
    {
        NSString* entityName = [self.entityButton titleForState:UIControlStateNormal];
        NSString* attributeName = [self.attributeButton titleForState:UIControlStateNormal];
        id attributeValue = [self.textField text];
        
        NSEntityDescription* entity = [NSEntityDescription entityForName:entityName inManagedObjectContext:self.usingContext];
        Class entityClass = NSClassFromString([entity managedObjectClassName]);
        
        NSDictionary* attributes = [entity attributesByName];
        NSAttributeDescription* attribute = [attributes objectForKey:attributeName];
        NSAttributeType type = attribute.attributeType;
        
        if (type == NSInteger16AttributeType || type == NSInteger32AttributeType)
        {
            attributeValue = @([attributeValue integerValue]);
        }
        else if (type == NSFloatAttributeType)
        {
            attributeValue = @([attributeValue floatValue]);
        }
        else if (type == NSDoubleAttributeType)
        {
            attributeValue = @([attributeValue doubleValue]);
        }
        else if (type == NSBooleanAttributeType)
        {
            attributeValue = @([attributeValue boolValue]);
        }
        
        NSArray* objects = nil;
        
        if ([attributeName isEqualToString:STDebugKitCoreDataDeleteViewControllerAttributeButtonText])
        {
            objects = [entityClass findAllInContext:self.usingContext];
        }
        else
        {
            objects = [entityClass findAllWithPredicate:[NSPredicate predicateWithFormat:@"%K = %@", attributeName, attributeValue] inContext:self.usingContext];
        }
        
        if (objects)
        {
            for (NSManagedObject* object in objects)
            {
                [object deleteInContext:self.usingContext];
            }
            
            void(^completion)(BOOL, NSError*) = ^(BOOL success, NSError *error) {
                [[[UIAlertView alloc] initWithTitle:@"Delete successful" message:[NSString stringWithFormat:@"%i object(s) deleted", [objects count]] delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Ok", nil] show];
            };
            
            if (self.usingContext == [NSManagedObjectContext defaultContext])
            {
                [self.usingContext saveToPersistentStoreWithCompletion:completion];
            }
            else
            {
                [self.usingContext saveOnlySelfWithCompletion:completion];
            }
        }
        else
        {
            [[[UIAlertView alloc] initWithTitle:@"Error" message:@"No objects found" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Ok", nil] show];
        }
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
    NSString* title = [self.data objectAtIndex:index];
    [self.attributeButton setTitle:title forState:UIControlStateNormal];
    [self.textField setHidden:[title isEqualToString:STDebugKitCoreDataDeleteViewControllerAttributeButtonText]];
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

@interface STDebugKitCoreDataClearViewController : UIViewController <UIPickerViewDataSource, UIPickerViewDelegate, UIActionSheetDelegate>

@property (nonatomic, strong) UIPickerView* pickerView;
@property (nonatomic, strong) NSMutableArray* data;
@property (nonatomic, strong) UIButton* entityButton;
@property (nonatomic, strong) UIButton* clearButton;
@property (nonatomic, strong) UIView* touchCatcherView;
@property (nonatomic, strong) NSManagedObjectContext* usingContext;

@end

@implementation STDebugKitCoreDataClearViewController

NSString* const STDebugKitCoreDataClearViewControllerAllEntitiesText = @"All Entities";

- (id)initWithContext:(NSManagedObjectContext*)context
{
    self = [super init];
    if (self)
    {
        self.data = [[NSMutableArray alloc] init];
        self.usingContext = context;
        self.title = @"Clear";
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
    
    [self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:@"Clear" style:UIBarButtonItemStyleDone target:self action:@selector(handleClearButtonTap:)]];
    
    self.entityButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [self.entityButton setFrame:CGRectMake(20, 20, self.view.bounds.size.width - 40, 40)];
    [self.entityButton setAutoresizingMask:(UIViewAutoresizingFlexibleWidth)];
    [self.entityButton setTitle:STDebugKitCoreDataClearViewControllerAllEntitiesText forState:UIControlStateNormal];
    [self.entityButton addTarget:self action:@selector(handleEntityButtonTap:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.entityButton];
    
    NSArray* digits = [[[UIDevice currentDevice] systemVersion] componentsSeparatedByString:@"."];
    if ([digits count] > 0 && [digits[0] intValue] > 6)
    {
        [self.entityButton setBackgroundColor:[UIColor whiteColor]];
        [self.entityButton.layer setCornerRadius:5];
        [self.entityButton.layer setBorderColor:[UIColor lightGrayColor].CGColor];
        [self.entityButton.layer setBorderWidth:1];
    }
    
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

- (void)handleEntityButtonTap:(UIButton*)button
{
    [self.data removeAllObjects];
    
    NSManagedObjectModel* model = self.usingContext.persistentStoreCoordinator.managedObjectModel;
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
        [[[UIAlertView alloc] initWithTitle:@"Error" message:@"No entity found" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Ok", nil] show];
    }
}

- (void)handleClearButtonTap:(UIButton*)button
{
    UIActionSheet* sheet = [[UIActionSheet alloc] initWithTitle:@"This action can't be undone" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Clear" otherButtonTitles:nil];
    [sheet showInView:self.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == actionSheet.destructiveButtonIndex)
    {
        NSString* entityName = [self.entityButton titleForState:UIControlStateNormal];
        
        if ([entityName isEqualToString:STDebugKitCoreDataClearViewControllerAllEntitiesText])
        {
            NSManagedObjectModel* model = [NSManagedObjectContext defaultContext].persistentStoreCoordinator.managedObjectModel;
            NSArray* entities = model.entities;
            
            for (NSEntityDescription* entity in entities)
            {
                Class entityClass = NSClassFromString([entity managedObjectClassName]);
                [entityClass truncateAllInContext:self.usingContext];
            }
        }
        else
        {
            NSEntityDescription* entity = [NSEntityDescription entityForName:entityName inManagedObjectContext:[NSManagedObjectContext defaultContext]];
            Class entityClass = NSClassFromString([entity managedObjectClassName]);
            
            [entityClass truncateAllInContext:self.usingContext];
        }
        
        void(^completion)(BOOL, NSError*) = ^(BOOL success, NSError *error) {
            [[[UIAlertView alloc] initWithTitle:@"Clear successful" message:[NSString stringWithFormat:@"All objects deleted"] delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Ok", nil] show];
        };
        
        if (self.usingContext == [NSManagedObjectContext defaultContext])
        {
            [self.usingContext saveToPersistentStoreWithCompletion:completion];
        }
        else
        {
            [self.usingContext saveOnlySelfWithCompletion:completion];
        }
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
    
#ifdef __IPHONE_7_0
    if ([self respondsToSelector:@selector(setEdgesForExtendedLayout:)])
    {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
#endif
    
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
    NSManagedObjectContext* context = self.usingContext ?: [NSManagedObjectContext defaultContext];
    
    if (indexPath.row == 0)
    {
        STDebugKitCoreDataFindViewController* find = [[STDebugKitCoreDataFindViewController alloc] initWithContext:context];
        [self.navigationController pushViewController:find animated:YES];
    }
    else if (indexPath.row == 1)
    {
        STDebugKitCoreDataCountViewController* count = [[STDebugKitCoreDataCountViewController alloc] initWithContext:context];
        [self.navigationController pushViewController:count animated:YES];
    }
    else if (indexPath.row == 2)
    {
        STDebugKitCoreDataDeleteViewController* clear = [[STDebugKitCoreDataDeleteViewController alloc] initWithContext:context];
        [self.navigationController pushViewController:clear animated:YES];
    }
    else if (indexPath.row == 3)
    {
        STDebugKitCoreDataClearViewController* clear = [[STDebugKitCoreDataClearViewController alloc] initWithContext:context];
        [self.navigationController pushViewController:clear animated:YES];
    }
}

@end

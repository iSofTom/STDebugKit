//
//  STDebugKitRootViewController.m
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

#import "STDebugKitRootViewController.h"

#import "STDebugTool.h"

@interface STDebugKitRootViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView* tableView;
@property (nonatomic, strong) NSArray* contextActions;
@property (nonatomic, strong) NSArray* globalActions;

@end

@implementation STDebugKitRootViewController

- (id)initWithContextActions:(NSDictionary*)contextActions globalActions:(NSArray*)globalActions
{
    self = [super init];
    if (self)
    {
        NSMutableArray* actions = [[NSMutableArray alloc] init];
        for (NSArray* currentActions in [contextActions allValues])
        {
            [actions addObjectsFromArray:currentActions];
        }
        self.contextActions = actions;
        
        self.globalActions = [globalActions sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            STDebugTool* tool1 = obj1;
            STDebugTool* tool2 = obj2;
            
            if ([tool1 order] < [tool2 order])
            {
                return NSOrderedAscending;
            }
            else if ([tool1 order] > [tool2 order])
            {
                return NSOrderedDescending;
            }
            return NSOrderedSame;
        }];
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
    
    UIBarButtonItem* closeButton = [[UIBarButtonItem alloc] initWithTitle:@"Close" style:UIBarButtonItemStyleDone target:self action:@selector(handleCloseTap:)];
    self.navigationItem.rightBarButtonItem = closeButton;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
}

- (void)handleCloseTap:(id)sender
{
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0)
    {
        return [self.contextActions count];
    }
    else
    {
        return [self.globalActions count];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString* identifier = @"identifier";
    
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    
    if (!cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
    
    STDebugTool* tool = nil;
    
    if (indexPath.section == 0)
    {
        tool = [self.contextActions objectAtIndex:indexPath.row];
    }
    else
    {
        tool = [self.globalActions objectAtIndex:indexPath.row];
    }
    
    cell.accessoryType = tool.type == STDebugToolTypeViewController ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone;
    cell.textLabel.text = [tool toolName];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 20;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0)
    {
        return @"Context";
    }
    else
    {
        return @"Global";
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    STDebugTool* tool = nil;
    
    if (indexPath.section == 0)
    {
        tool = [self.contextActions objectAtIndex:indexPath.row];
    }
    else
    {
        tool = [self.globalActions objectAtIndex:indexPath.row];
    }
    
    if (tool.type == STDebugToolTypeViewController)
    {
        UIViewController* vc = [[tool.toolClass alloc] init];
        [self.navigationController pushViewController:vc animated:YES];
    }
    else
    {
        dispatch_block_t action = tool.toolAction;
        if (action)
        {
            action();
        }
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

@end

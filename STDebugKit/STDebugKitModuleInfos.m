//
//  STDebugKitModuleInfos.m
//  STDebugKit
//
//  Created by Thomas Dupont on 09/09/13.

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

#import "STDebugKitModuleInfos.h"
#import "STDebugKit.h"

@interface STDebugKitModuleInfos () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView* tableView;
@property (nonatomic, strong) NSMutableArray* dataNames;
@property (nonatomic, strong) NSMutableArray* dataValues;

@end

@implementation STDebugKitModuleInfos

#ifdef STDebugKitModuleInfosEnabled
+ (void)load
{
    STDebugTool* tool = [STDebugTool debugToolNamed:@"Infos" viewControllerClass:[self class]];
#ifdef STDebugKitModuleInfosOrder
    tool.order = STDebugKitModuleInfosOrder;
#else
    tool.order = 999;
#endif
    [STDebugKit addGlobalDebugTool:tool];
}
#endif

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"Infos";
    
    self.dataNames = [[NSMutableArray alloc] init];
    self.dataValues = [[NSMutableArray alloc] init];
	
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds];
    [self.tableView setAutoresizingMask:(UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight)];
    [self.view addSubview:self.tableView];
    [self.tableView setDelegate:self];
    [self.tableView setDataSource:self];
    
    NSDictionary* dict = [[NSBundle mainBundle] infoDictionary];
    for (NSString* key in [dict allKeys])
    {
        NSString* value = [dict objectForKey:key];
        
        if ([value isKindOfClass:[NSString class]])
        {
            [self.dataNames addObject:key];
            [self.dataValues addObject:value];
        }
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.dataNames count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString* identifier = @"identifier";
    
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    
    if (!cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:identifier];
    }
    
    cell.textLabel.text = [self.dataNames objectAtIndex:indexPath.row];
    cell.detailTextLabel.text = [self.dataValues objectAtIndex:indexPath.row];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [[[UIAlertView alloc] initWithTitle:[self.dataNames objectAtIndex:indexPath.row] message:[self.dataValues objectAtIndex:indexPath.row] delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Ok", nil] show];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end

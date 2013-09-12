//
//  ViewController.m
//  STDebugKitDemo
//
//  Created by Thomas Dupont on 03/09/13.
//  Copyright (c) 2013 iSofTom. All rights reserved.
//

#import "ViewController.h"

#import "SecondViewController.h"

@interface ViewController () <UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, assign) NSInteger numberOfLines;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    self.numberOfLines = 1;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
    
    DebugKitAddAction(@"Add Cell", ^(id o){
        self.numberOfLines = MIN(self.numberOfLines + 1, 10);
        [self.tableView reloadData];
    })
    
    DebugKitAddAction(@"Remove Cell", ^(id o){
        self.numberOfLines = MAX(self.numberOfLines - 1, 0);
        [self.tableView reloadData];
    })
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    DebugKitRemove()
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.numberOfLines;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString* identifier = @"identifier";
    
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    
    if (!cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
    
    cell.textLabel.text = [NSString stringWithFormat:@"Cell n°%i", indexPath.row];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    SecondViewController* vc = [[SecondViewController alloc] initWithName:[NSString stringWithFormat:@"Cell n°%i", indexPath.row]];
    [self.navigationController pushViewController:vc animated:YES];
}

@end

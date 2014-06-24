//
//  KATGMessagesViewController.m
//  KATG
//
//  Created by Nicolas Rostov on 25.06.14.
//  Copyright (c) 2014 Doug Russell. All rights reserved.
//

#import "KATGMessagesViewController.h"

@implementation KATGMessagesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.rowHeight = 68;
    self.title = @"Messages";
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self.tableView
               selector:@selector(reloadData)
                   name:NSUserDefaultsDidChangeNotification
                 object:nil];
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center removeObserver:self.tableView name:NSUserDefaultsDidChangeNotification object:nil];
}

#pragma mark - Table view data source
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
    NSArray *notifications = [def objectForKey:@"notifications"];
    return [notifications count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    if(!cell)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
    
    NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
    NSArray *notifications = [def objectForKey:@"notifications"];
    NSDictionary *userInfo = notifications[indexPath.row];
    NSString *message = userInfo[@"alert.body"];
    cell.textLabel.text = message;
    cell.textLabel.font = [UIFont systemFontOfSize:12];
    cell.textLabel.numberOfLines = 3;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}

@end

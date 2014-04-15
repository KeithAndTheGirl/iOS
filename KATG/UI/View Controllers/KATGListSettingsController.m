//
//  KATGListSettingsController.m
//  KATG
//
//  Created by Nicolas Rostov on 16.04.14.
//  Copyright (c) 2014 Doug Russell. All rights reserved.
//

#import "KATGListSettingsController.h"

@implementation KATGListSettingsController

- (void)viewDidLoad {
    [super viewDidLoad];
}

-(UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

#pragma mark Actions
-(IBAction)doneAction:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(IBAction)cancelAction:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark UITableView
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) {
        return 2;
    }
    else {
        return 1;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if(section == 0)
        return @"Sort By:";
    else if(section == 1)
        return @"Filter Episodes";
    return @"";
}

- (UITableViewCell *)tableView:(UITableView *)_tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];
    
    if (indexPath.section == 0) {
        BOOL sortByRecentlyListened = [[NSUserDefaults standardUserDefaults] boolForKey:EPISODES_SORT_RECENTLY_LISTENED];
        cell.accessoryType = UITableViewCellAccessoryNone;
        if(indexPath.row == 0) {
            cell.textLabel.text = @"Recently Listened";
            if(sortByRecentlyListened)
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
        else {
            cell.textLabel.text = @"Posted Date";
            if(!sortByRecentlyListened)
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
    }
    else {
        BOOL filterDownloaded = [[NSUserDefaults standardUserDefaults] boolForKey:EPISODES_FILTER_DOWNLOADED];
        cell.textLabel.text = @"Downloaded only";
        if(filterDownloaded)
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
	return cell;
}

-(CGFloat)tableView:(UITableView *)_tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 44;
}

-(void)tableView:(UITableView *)_tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [_tableView deselectRowAtIndexPath:indexPath animated:YES];
    if(indexPath.section == 0) {
        [[NSUserDefaults standardUserDefaults] setBool:(indexPath.row == 0) forKey:EPISODES_SORT_RECENTLY_LISTENED];
    }
    else {
        BOOL filterDownloaded = [[NSUserDefaults standardUserDefaults] boolForKey:EPISODES_FILTER_DOWNLOADED];
        [[NSUserDefaults standardUserDefaults] setBool:!filterDownloaded forKey:EPISODES_FILTER_DOWNLOADED];
    }
    [_tableView reloadData];
}


@end

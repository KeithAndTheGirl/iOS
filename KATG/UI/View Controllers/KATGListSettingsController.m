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
    doneButton.backgroundColor = [UIColor colorWithWhite:0 alpha:0.2];
    [doneButton.layer setBorderColor:[[UIColor colorWithWhite:1 alpha:0.75] CGColor]];
    [doneButton.layer setBorderWidth:0.5];
    [doneButton.layer setCornerRadius:4];
    cancelButton.backgroundColor = [UIColor colorWithWhite:0 alpha:0.2];
    [cancelButton.layer setBorderColor:[[UIColor colorWithWhite:1 alpha:0.75] CGColor]];
    [cancelButton.layer setBorderWidth:0.5];
    [cancelButton.layer setCornerRadius:4];
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
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) {
        return 2;
    }
    else if (section == 1) {
        return 1;
    }
    else {
        downloadedShows = 0;
        for(KATGShow *show in self.episodes) {
            if(show.file_url) downloadedShows++;
        }
        if(downloadedShows > 0)
            return 1;
        else
            return 0;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if(section == 0) {
        return @"Sort By:";
    }
    else if(section == 1) {
        return @"Filter Episodes";
    }
    else if(section == 2) {
        if(downloadedShows > 0)
            return @"Remove Downloaded";
        else
            return @"";
    }
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
    else if (indexPath.section == 1) {
        BOOL filterDownloaded = [[NSUserDefaults standardUserDefaults] boolForKey:EPISODES_FILTER_DOWNLOADED];
        cell.textLabel.text = @"Downloaded only";
        if(filterDownloaded)
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    else {
        cell.textLabel.text = [NSString stringWithFormat:@"Remove all downloaded files (%i)", downloadedShows];
        cell.textLabel.textColor = [UIColor redColor];
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
    else if(indexPath.section == 1) {
        BOOL filterDownloaded = [[NSUserDefaults standardUserDefaults] boolForKey:EPISODES_FILTER_DOWNLOADED];
        [[NSUserDefaults standardUserDefaults] setBool:!filterDownloaded forKey:EPISODES_FILTER_DOWNLOADED];
    }
    else {
        for(KATGShow *show in self.episodes) {
            if(show.file_url)
                [[KATGDataStore sharedStore] removeDownloadedEpisodeAudio:show];
        }
    }
    [_tableView reloadData];
}


@end

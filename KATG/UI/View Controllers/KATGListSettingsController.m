//
//  KATGListSettingsController.m
//  KATG
//
//  Created by Nicolas Rostov on 16.04.14.
//  Copyright (c) 2014 Doug Russell. All rights reserved.
//

#import "KATGListSettingsController.h"
#import "KATGAudioDownloadManager.h"

@implementation KATGListSettingsController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.selectedEpisodes = [NSMutableArray array];
    self.downloadedEpisodes = [NSMutableArray array];
    
    doneButton.backgroundColor = [UIColor colorWithWhite:0 alpha:0.2];
    [doneButton.layer setBorderColor:[[UIColor colorWithWhite:1 alpha:0.75] CGColor]];
    [doneButton.layer setBorderWidth:0.5];
    [doneButton.layer setCornerRadius:4];
}

-(UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    for(KATGShow *show in self.episodes) {
        if(show.downloaded)
            [self.downloadedEpisodes addObject:show];
    }
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
        if([self.downloadedEpisodes count] > 0)
            return [self.downloadedEpisodes count]+2;
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
        if([self.downloadedEpisodes count] > 0)
            return @"Remove Downloaded";
        else
            return @" ";
    }
    return @" ";
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
        if(indexPath.row == 0) {
            cell.textLabel.text = [NSString stringWithFormat:@"Remove all downloaded files (%i)", (int)[self.downloadedEpisodes count]];
            cell.textLabel.textColor = [UIColor redColor];
        }
        else if(indexPath.row == 1) {
            cell.textLabel.text = [NSString stringWithFormat:@"Remove selected files (%i)", (int)[self.selectedEpisodes count]];
        }
        else {
            KATGShow *show = self.downloadedEpisodes[indexPath.row-2];
            cell.indentationLevel = 2;
            cell.textLabel.font = [UIFont systemFontOfSize:12];
            cell.textLabel.text = show.title;
            if([self.selectedEpisodes containsObject:show])
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            else
                cell.accessoryType = UITableViewCellAccessoryNone;
        }
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
        if(indexPath.row == 0) {
            [[[UIAlertView alloc] initWithTitle:@"Confirmation"
                                        message:@"Are you sure you want to delete all files?"
                                       delegate:self
                              cancelButtonTitle:@"No"
                              otherButtonTitles:@"Yes", nil] show];
        }
        else if(indexPath.row == 1) {
            for(KATGShow *show in self.selectedEpisodes) {
                if(show.downloaded)
                    [[KATGAudioDownloadManager sharedManager] removeDownloadedEpisodeAudio:show];
            }
            [self.selectedEpisodes removeAllObjects];
        }
        else {
            KATGShow *show = self.downloadedEpisodes[indexPath.row-2];
            if([self.selectedEpisodes containsObject:show])
                [self.selectedEpisodes removeObject:show];
            else
                [self.selectedEpisodes addObject:show];
        }
    }
    
    [self.downloadedEpisodes removeAllObjects];
    for(KATGShow *show in self.episodes) {
        if(show.downloaded)
            [self.downloadedEpisodes addObject:show];
    }
    [_tableView reloadData];
}

// remove all downloaded episodes
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if(buttonIndex == 1) {
        for(KATGShow *show in self.episodes) {
            if(show.downloaded)
                [[KATGAudioDownloadManager sharedManager] removeDownloadedEpisodeAudio:show];
        }
    }
}

@end

//
//  KATGMoreViewController.m
//  KATG
//
//  Created by Nicolas Rostov on 25.06.14.
//  Copyright (c) 2014 Doug Russell. All rights reserved.
//

#import "KATGMoreViewController.h"
#import "KATGPlaybackManager.h"
#import "KATGShowViewController.h"
#import "KATGShow.h"

#define ROW_TEXT @[@"About Keith and The Girl", @"KATG VIP Account", @"App Feedback", @"Messages"]
#define ROW_IMAGES @[@"About", @"star", @"feedback", @"messages"]

@implementation KATGMoreViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.rowHeight = 54;
    self.navigationItem.title = [NSString stringWithFormat:@"KATG app version %@", APP_VERSION];
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self registerStateObserver];
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self unregisterStateObserver];
}

#pragma mark UITableView
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return 3;
}

- (UITableViewCell *)tableView:(UITableView *)_tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = [_tableView dequeueReusableCellWithIdentifier:@"cell"];
    if(!cell)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
    cell.textLabel.text = ROW_TEXT[indexPath.row];
    cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ArrowNext.png"]];
    cell.imageView.image = [UIImage imageNamed:ROW_IMAGES[indexPath.row]];
	return cell;
}

-(void)tableView:(UITableView *)_tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [_tableView deselectRowAtIndexPath:indexPath animated:YES];
    UIViewController *nextView;
    if(indexPath.row == 0) {
        nextView = [[KATGAboutViewController alloc] init];
    }
    else if(indexPath.row == 1) {
        NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
        NSString *key = [def valueForKey:KATG_PLAYBACK_KEY];
        NSString *uid = [def valueForKey:KATG_PLAYBACK_UID];
        if(!key || !uid) {
            KATGVipLoginViewController *loginView =  [[KATGVipLoginViewController alloc] init];
            loginView.completion = (^() {
                [self.navigationController popToRootViewControllerAnimated:YES];
                [KATGUtil alertWithTitle:@"KATG VIP" message:@"Login success"];
            });
            nextView = loginView;
        }
        else
            nextView =  [[KATGVIPViewController alloc] init];
        nextView.title = @"KATG VIP";
    }
    else if(indexPath.row == 2) {
        if([MFMailComposeViewController canSendMail]) {
            MFMailComposeViewController *mailView = [[MFMailComposeViewController alloc] init];
            [mailView setSubject:[NSString stringWithFormat:@"Feedback for the KATG app version %@ (iOS)", APP_VERSION]];
            [mailView setToRecipients:@[@"support@keithandthegirl.com"]];
            mailView.mailComposeDelegate = self;
            [self presentViewController:mailView animated:YES completion:nil];
        }
        else {
            [[[UIAlertView alloc] initWithTitle:@"KATG Feedback" message:@"Sorry, you can't send email now" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        }
        return;
    }
    else if(indexPath.row == 3) {
        nextView = [[KATGMessagesViewController alloc] init];
    }

    [self.navigationController pushViewController:nextView animated:YES];
}

#pragma mark MFMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    [controller dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark GlobalPlayState
-(void)registerStateObserver {
    [[KATGPlaybackManager sharedManager] addObserver:self forKeyPath:@"state" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:NULL];
    [self configureTopBar];
}

-(void)unregisterStateObserver {
	[[KATGPlaybackManager sharedManager] removeObserver:self forKeyPath:@"state"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    [self configureTopBar];
}

- (void)configureTopBar
{
	if ([[KATGPlaybackManager sharedManager] currentShow] &&
        [[KATGPlaybackManager sharedManager] state] == KATGAudioPlayerStatePlaying)
	{
		UIView *v = [self.tableView viewWithTag:1313];
        if(!v) {
            UIButton *nowPlayingButton = [UIButton buttonWithType:UIButtonTypeCustom];
            [nowPlayingButton setImage:[UIImage imageNamed:@"NowPlaying.png"] forState:UIControlStateNormal];
            nowPlayingButton.frame = CGRectMake(0.0f, -48.0f, 320.0f, 48.0f);
            [nowPlayingButton addTarget:self action:@selector(showNowPlayingEpisode) forControlEvents:UIControlEventTouchUpInside];
            nowPlayingButton.tag = 1313;
            
            [self.tableView addSubview:nowPlayingButton];
            UIEdgeInsets contentInsets = self.tableView.contentInset;
            contentInsets.top += 48;
            self.tableView.contentInset = contentInsets;
        }
	}
	else {
        UIView *v = [self.tableView viewWithTag:1313];
        if(v) {
            [v removeFromSuperview];
            UIEdgeInsets contentInsets = self.tableView.contentInset;
            contentInsets.top -= 48;
            self.tableView.contentInset = contentInsets;
        }
	}
}

-(void)showNowPlayingEpisode {
    KATGShow *show = [[KATGPlaybackManager sharedManager] currentShow];
    KATGShowViewController *showViewController = [[KATGShowViewController alloc] initWithNibName:@"KATGShowViewController" bundle:nil];
	showViewController.showObjectID = [show objectID];
	showViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    [self presentViewController:showViewController animated:YES completion:nil];
}

@end

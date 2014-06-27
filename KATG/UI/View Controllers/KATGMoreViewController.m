//
//  KATGMoreViewController.m
//  KATG
//
//  Created by Nicolas Rostov on 25.06.14.
//  Copyright (c) 2014 Doug Russell. All rights reserved.
//

#import "KATGMoreViewController.h"

#define ROW_TEXT @[@"About Keith and The Girl", @"KATG VIP Account", @"App Feedback", @"Messages"]
#define ROW_IMAGES @[@"About", @"star", @"feedback", @"messages"]

@implementation KATGMoreViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.rowHeight = 54;
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
        UIViewController *feedbackView = [[KATGLiveShowFeedbackViewController alloc] init];
        [self presentViewController:feedbackView animated:YES completion:nil];
        return;
    }
    else if(indexPath.row == 3) {
        nextView = [[KATGMessagesViewController alloc] init];
    }

    [self.navigationController pushViewController:nextView animated:YES];
}
@end

//
//  KATGWelcomeViewController.m
//  KATG
//
//  Created by Nicolas Rostov on 27.12.13.
//  Copyright (c) 2013 Doug Russell. All rights reserved.
//

#import "KATGWelcomeViewController.h"

@implementation KATGWelcomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    UIImageView *imageView1 = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"welcome1.png"]];
    [scroll addSubview:imageView1];
    imageView1.frame = CGRectMake(0, 0, imageView1.frame.size.width, imageView1.frame.size.height);
    UIImageView *imageView2 = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"welcome2.png"]];
    [scroll addSubview:imageView2];
    imageView2.frame = CGRectMake(imageView1.frame.size.width, 0, imageView2.frame.size.width, imageView2.frame.size.height);
    UIImageView *imageView3 = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"welcome3.png"]];
    [scroll addSubview:imageView3];
    imageView3.frame = CGRectMake(imageView2.frame.origin.x+imageView2.frame.size.width, 0, imageView3.frame.size.width, imageView3.frame.size.height);
    scroll.contentSize = CGSizeMake(imageView1.frame.size.width * 3, imageView1.frame.size.height);
    
    getStartedButton.frame = CGRectMake(imageView3.frame.origin.x+20, getStartedButton.frame.origin.y, getStartedButton.frame.size.width, getStartedButton.frame.size.height);
    [scroll bringSubviewToFront:getStartedButton];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)startAction:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    int i = scroll.contentOffset.x / scroll.frame.size.width;
    indicatorsView.image = [UIImage imageNamed:[NSString stringWithFormat:@"indicators%i.png", i+1]];
}

@end

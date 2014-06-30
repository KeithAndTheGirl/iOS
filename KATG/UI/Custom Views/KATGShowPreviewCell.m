//
//  KATGShowPreviewCell.m
//  KATG
//
//  Created by Nicolas Rostov on 30.06.14.
//  Copyright (c) 2014 Doug Russell. All rights reserved.
//

#import "KATGShowPreviewCell.h"
#import "UIButton+AFNetworking.h"

@implementation KATGShowPreviewCell

-(void)audioPreviewAction:(UIButton*)sender {
    [self.delegate audioPreviewAction];
}

-(void)videoPreviewAction:(UIButton*)sender {
    [self.delegate videoPreviewAction:self.videoID];
}


-(void)setPreviewURL:(NSString *)previewURL {
    _previewURL = previewURL;
    for(UIView *v in [self.contentView subviews])
        [v removeFromSuperview];
    
    if([previewURL rangeOfString:@"youtube"].location != NSNotFound) {
        NSRange yt_id = [previewURL rangeOfString:@"watch?v="];
        if(yt_id.location == NSNotFound)
            yt_id = [previewURL rangeOfString:@"/" options:NSBackwardsSearch];
        self.videoID = [previewURL substringFromIndex:yt_id.location+yt_id.length];
        
        UIButton *videoButton = [[UIButton alloc] initWithFrame:self.frame];
        videoButton.autoresizingMask = 63;
        NSURL *imageURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://img.youtube.com/vi/%@/hqdefault.jpg", self.videoID]];
        [videoButton setImage:[UIImage imageNamed:@"play"] forState:UIControlStateNormal];
        [videoButton setBackgroundImageForState:UIControlStateNormal withURL:imageURL];
        [videoButton addTarget:self action:@selector(videoPreviewAction:) forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:videoButton];
    }
    else if([previewURL rangeOfString:@"mp3"].location != NSNotFound) {
        UIButton *playButton = [[UIButton alloc] initWithFrame:self.frame];
        playButton.autoresizingMask = 63;
        [playButton setImage:[UIImage imageNamed:@"play"] forState:UIControlStateNormal];
        [playButton setTitle:@"Play Audio Preview" forState:UIControlStateNormal];
        [playButton setTitleColor:[UIColor darkTextColor] forState:UIControlStateNormal];
        playButton.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 40);
        [playButton addTarget:self action:@selector(audioPreviewAction:) forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:playButton];
    }
}

@end

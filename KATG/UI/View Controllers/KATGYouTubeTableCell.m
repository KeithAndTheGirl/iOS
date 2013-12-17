//
//  KATGYouTubeTableCell.m
//  KATG
//
//  Created by Nick on 12/17/13.
//  Copyright (c) 2013 Doug Russell. All rights reserved.
//

#import "KATGYouTubeTableCell.h"
#import "UIImageView+AFNetworking.h"

@implementation KATGYouTubeTableCell

- (void)configureWithDictionary:(NSDictionary *)itemDictionary {
    titleLabel.text = itemDictionary[@"title"];
    [pictureView setImageWithURL:[NSURL URLWithString:itemDictionary[@"thumbnail"][@"sqDefault"]]];
}

@end

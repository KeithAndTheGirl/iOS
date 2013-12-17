//
//  KATGYouTubeTableCell.h
//  KATG
//
//  Created by Nick on 12/17/13.
//  Copyright (c) 2013 Doug Russell. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface KATGYouTubeTableCell : UITableViewCell {
    IBOutlet UIImageView *pictureView;
    IBOutlet UILabel *titleLabel;
}

- (void)configureWithDictionary:(NSDictionary *)itemDictionary;

@end

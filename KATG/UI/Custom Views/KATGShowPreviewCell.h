//
//  KATGShowPreviewCell.h
//  KATG
//
//  Created by Nicolas Rostov on 30.06.14.
//  Copyright (c) 2014 Doug Russell. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol KATGShowPreviewCellDelegate <NSObject>

-(void)audioPreviewAction;
-(void)videoPreviewAction:(NSString*)videoID;

@end

@interface KATGShowPreviewCell : UITableViewCell

@property (nonatomic, strong) NSString *previewURL;
@property (nonatomic, strong) NSString *videoID;
@property (nonatomic) id<KATGShowPreviewCellDelegate> delegate;

@end

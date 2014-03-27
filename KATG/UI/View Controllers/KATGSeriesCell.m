//
//  KATGSeriesCell.m
//  KATG
//
//  Created by Nicolas Rostov on 27.03.14.
//  Copyright (c) 2014 Doug Russell. All rights reserved.
//

#import "KATGSeriesCell.h"
#import "UIImageView+AFNetworking.h"

@implementation KATGSeriesCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        imageView = [[UIImageView alloc] initWithFrame:CGRectMake(16, 0, 108, 108)];
        imageView.backgroundColor = [UIColor grayColor];
        [self addSubview:imageView];
        
        titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 110, 108, 34)];
        titleLabel.numberOfLines = 3;
        titleLabel.font = [UIFont boldSystemFontOfSize:13];
        titleLabel.textColor = [UIColor whiteColor];
        [self addSubview:titleLabel];
    }
    return self;
}

-(void)setObject:(KATGSeries *)value {
    _object = value;
    
    [imageView setImageWithURL:[NSURL URLWithString:_object.cover_image_url]];
    
    BOOL vip = [_object.vip_status boolValue];
    NSString *title = [NSString stringWithFormat:@"%@ %@ ", vip?@" VIP ":@"", _object.title];
    
    NSMutableAttributedString *asTitle = [[NSMutableAttributedString alloc] initWithString:title];
    [asTitle addAttribute:NSBackgroundColorAttributeName value:[UIColor colorWithPatternImage:[UIImage imageNamed:@"TitleBackground.png"]] range:NSMakeRange(vip?5:0, [title length]-(vip?5:0)) ];
    if(vip)
        [asTitle addAttribute:NSBackgroundColorAttributeName value:[UIColor colorWithPatternImage:[UIImage imageNamed:@"TitleBackgroundVip.png"]] range:NSMakeRange(0, 5)];
    titleLabel.attributedText = asTitle;
    [titleLabel sizeToFit];
}

+(CGSize)cellSize {
	return CGSizeMake(140, 160);
}

+(CGFloat)lineSpacing {
    return 10;
}

@end

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
        
        titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 110, 108, 50)];
        titleLabel.numberOfLines = 3;
        titleLabel.font = [UIFont boldSystemFontOfSize:12.5];
        titleLabel.textColor = [UIColor whiteColor];
        [self addSubview:titleLabel];
    }
    return self;
}

-(void)setObject:(KATGSeries *)value {
    _object = value;
    [self setNeedsLayout];
}

-(void)layoutSubviews {
    [imageView setImageWithURL:[NSURL URLWithString:_object.cover_image_url]];
    [[NSUserDefaults standardUserDefaults] setObject:_object.cover_image_url forKey:[NSString stringWithFormat:@"cover-%@", _object.series_id]];
    
    BOOL vip = [_object.vip_status boolValue];
    NSString *title = [NSString stringWithFormat:@"%@ %@ ", vip?@" VIP ":@"", _object.title];
    
    NSMutableAttributedString *asTitle = [[NSMutableAttributedString alloc] initWithString:title];
    [asTitle addAttribute:NSBackgroundColorAttributeName value:[UIColor colorWithPatternImage:[UIImage imageNamed:@"TitleBackground.png"]] range:NSMakeRange(vip?5:0, [title length]-(vip?5:0)) ];
    if(vip)
        [asTitle addAttribute:NSBackgroundColorAttributeName value:[UIColor colorWithPatternImage:[UIImage imageNamed:@"TitleBackgroundVip.png"]] range:NSMakeRange(0, 5)];
    titleLabel.attributedText = asTitle;
    
    [titleLabel setLineBreakMode:NSLineBreakByWordWrapping];
    

    CGRect expectedLabelRect = [title boundingRectWithSize:CGSizeMake(titleLabel.frame.size.width, MAXFLOAT)
                                                   options:NSStringDrawingUsesLineFragmentOrigin
                                                attributes:@{NSFontAttributeName: titleLabel.font}
                                                   context:nil];
    CGFloat lineHeight = 15.3;
    int maxLinesNumber = 3;
    CGFloat height = round(expectedLabelRect.size.height/lineHeight)*lineHeight;
    if(height > lineHeight*maxLinesNumber) height = lineHeight*maxLinesNumber;
    CGRect newFrame = titleLabel.frame;
    newFrame.size.height = height;
    titleLabel.frame = newFrame;
}

-(void)willMoveToSuperview:(UIView *)newSuperview {
    [self setNeedsLayout];
}

+(CGSize)cellSize {
	return CGSizeMake(140, 160);
}

+(CGFloat)lineSpacing {
    return 10;
}

@end

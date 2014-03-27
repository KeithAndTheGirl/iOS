//
//  KATGSeriesCell.h
//  KATG
//
//  Created by Nicolas Rostov on 27.03.14.
//  Copyright (c) 2014 Doug Russell. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KATGSeries.h"

@interface KATGSeriesCell : UICollectionViewCell {
    UIImageView *imageView;
    UILabel *titleLabel;
}

@property (nonatomic, strong) KATGSeries *object;

+(CGSize)cellSize;
+(CGFloat)lineSpacing;

@end

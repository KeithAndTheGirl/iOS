//
//  KATGShowGuestCell.m
//  KATG
//
//  Created by Timothy Donnelly on 12/10/12.
//  Copyright (c) 2012 Doug Russell. All rights reserved.
//  
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//  
//  http://www.apache.org/licenses/LICENSE-2.0
//  
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//  

#import "KATGShowGuestCell.h"
#import "UIImageView+AFNetworking.h"

@implementation KATGShowGuestCell

-(void)setImages:(NSArray*)imagesUrls {
    for(UIView *v in [self.contentView subviews])
        if(v.tag == 111)
            [v removeFromSuperview];
    for(int i=0; i<[imagesUrls count]; i++) {
        UIImageView *imgView = [[UIImageView alloc] initWithFrame:
                                CGRectMake(10+i*110, 5, 100, 100)];
        [self.contentView addSubview:imgView];
        imgView.tag = 111;
        imgView.contentMode = UIViewContentModeScaleAspectFit;
        [imgView setImageWithURL:[NSURL URLWithString:imagesUrls[i]]];
    }
}

@end

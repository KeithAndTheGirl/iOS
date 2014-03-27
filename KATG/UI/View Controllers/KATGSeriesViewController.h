//
//  KATGSeriesViewController.h
//  KATG
//
//  Created by Nicolas Rostov on 26.03.14.
//  Copyright (c) 2014 Doug Russell. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface KATGSeriesViewController : UIViewController <NSFetchedResultsControllerDelegate> {
    IBOutlet UICollectionView *collectionView;
}

@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;

@end

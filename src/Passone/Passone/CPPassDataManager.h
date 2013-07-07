//
//  CPPassDataManager.h
//  Passone
//
//  Created by wangyw on 6/13/13.
//  Copyright (c) 2013 codingpotato. All rights reserved.
//

@class CPMemo;

@interface CPPassDataManager : NSObject

@property (strong, nonatomic) NSFetchedResultsController *passwordsController;

+ (CPPassDataManager *)defaultManager;

- (void)setPasswordText:(NSString *)text atIndex:(NSUInteger)index;

- (CPMemo *)addMemoText:(NSString *)text intoIndex:(NSUInteger)index;

- (BOOL)canToggleRemoveStateOfPasswordAtIndex:(NSUInteger)index;
- (void)toggleRemoveStateOfPasswordAtIndex:(NSUInteger)index;

- (void)exchangePasswordBetweenIndex1:(NSUInteger)index1 andIndex2:(NSUInteger)index2;

- (NSArray *)memosContainText:(NSString *)text;

@end

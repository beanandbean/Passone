//
//  CPMemoCollectionViewManager.m
//  Locor
//
//  Created by wangsw on 8/31/13.
//  Copyright (c) 2013 codingpotato. All rights reserved.
//

#import "CPMemoCollectionViewManager.h"

#import "CPLocorConfig.h"

#import "CPMemoCell.h"
#import "CPMemoCellRemoving.h"
#import "CPMemoCellRemovingBackground.h"

#import "CPMemoCollectionViewFlowLayout.h"

#import "CPMainViewController.h"
#import "CPAdManager.h"

#import "CPAppearanceManager.h"

#import "CPPassDataManager.h"
#import "CPPassword.h"

#import "CPProcessManager.h"
#import "CPEditingPassCellProcess.h"
#import "CPScrollingCollectionViewProcess.h"
#import "CPRemovingMemoCellProcess.h"

#define NS_INDEX_PATH_ZERO [NSIndexPath indexPathForRow:0 inSection:0]

static NSString *CELL_REUSE_IDENTIFIER_NORMAL = @"normal-cell";
static NSString *CELL_REUSE_IDENTIFIER_NORMAL_BACKGROUND = @"normal-cell-background";
static NSString *CELL_REUSE_IDENTIFIER_REMOVING = @"removing-cell";
static NSString *CELL_REUSE_IDENTIFIER_REMOVING_BACKGROUND = @"removing-cell-background";

@interface CPMemoCollectionViewManager ()

@property (weak, nonatomic) UIView *superview;

@property (weak, nonatomic) UIView *frontLayer;
@property (weak, nonatomic) UIView *backLayer;

@property (strong, nonatomic) NSArray *frontCollectionViewConstraints;
@property (strong, nonatomic) NSArray *backCollectionViewConstraints;

@property (nonatomic) CGPoint draggingBasicOffset;
@property (strong, nonatomic) NSIndexPath *addingCellIndex;

@property (weak, nonatomic) CPMemoCellRemoving *frontRemovingCell;
@property (strong, nonatomic) NSIndexPath *frontRemovingCellIndex;
@property (weak, nonatomic) CPMemoCellRemovingBackground *backRemovingCell;
@property (strong, nonatomic) NSIndexPath *backRemovingCellIndex;

@property (nonatomic) NSValue *collectionViewOffsetBeforeEdit;

@end

@implementation CPMemoCollectionViewManager

- (UICollectionView *)makeCollectionView {
    UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:[[CPMemoCollectionViewFlowLayout alloc] init]];
    collectionView.translatesAutoresizingMaskIntoConstraints = NO;
    collectionView.backgroundColor = [UIColor clearColor];
    collectionView.showsHorizontalScrollIndicator = NO;
    collectionView.dataSource = self;
    collectionView.delegate = self;
    
    [collectionView addGestureRecognizer:[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)]];
    return collectionView;
}

- (UICollectionView *)frontCollectionView {
    if (!_frontCollectionView) {
        _frontCollectionView = [self makeCollectionView];
        
        [_frontCollectionView registerClass:[CPMemoCell class] forCellWithReuseIdentifier:CELL_REUSE_IDENTIFIER_NORMAL];
        [_frontCollectionView registerClass:[CPMemoCellRemoving class] forCellWithReuseIdentifier:CELL_REUSE_IDENTIFIER_REMOVING];
    }
    return _frontCollectionView;
}

- (UICollectionView *)backCollectionView {
    if (!_backCollectionView) {
        _backCollectionView = [self makeCollectionView];
        
        [_backCollectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:CELL_REUSE_IDENTIFIER_NORMAL_BACKGROUND];
        [_backCollectionView registerClass:[CPMemoCellRemovingBackground class] forCellWithReuseIdentifier:CELL_REUSE_IDENTIFIER_REMOVING_BACKGROUND];
    }
    return _backCollectionView;
}

- (NSArray *)frontCollectionViewConstraints {
    if (!_frontCollectionViewConstraints) {
        _frontCollectionViewConstraints = [CPAppearanceManager constraintsWithView:self.frontCollectionView edgesAlignToView:self.frontLayer];
    }
    return _frontCollectionViewConstraints;
}

- (NSArray *)backCollectionViewConstraints {
    if (!_backCollectionViewConstraints) {
        _backCollectionViewConstraints = [CPAppearanceManager constraintsWithView:self.backCollectionView edgesAlignToView:self.backLayer];
    }
    return _backCollectionViewConstraints;
}

- (UITextField *)textField {
    if (!_textField) {
        _textField = [[UITextField alloc] init];
        _textField.translatesAutoresizingMaskIntoConstraints = NO;
        [_textFieldContainer addSubview:_textField];
    }
    return _textField;
}

- (UIView *)textFieldContainer {
    if (!_textFieldContainer) {
        _textFieldContainer = [[UIView alloc] init];
        _textFieldContainer.translatesAutoresizingMaskIntoConstraints = NO;
        _textFieldContainer.userInteractionEnabled = NO;
        _textFieldContainer.clipsToBounds = YES;
    }
    return _textFieldContainer;
}

- (NSArray *)textFieldContainerConstraints {
    if (!_textFieldContainerConstraints) {
        _textFieldContainerConstraints = [[NSArray alloc] initWithObjects:
                                          [NSLayoutConstraint constraintWithItem:self.textFieldContainer attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.frontCollectionView attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0.0],
                                          [NSLayoutConstraint constraintWithItem:self.textFieldContainer attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.frontCollectionView attribute:NSLayoutAttributeRight multiplier:1.0 constant:0.0],
                                          [NSLayoutConstraint constraintWithItem:self.textFieldContainer attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.frontCollectionView attribute:NSLayoutAttributeTop multiplier:1.0 constant:0.0],
                                          [NSLayoutConstraint constraintWithItem:self.textFieldContainer attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.frontCollectionView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0],
                                          nil];
    }
    return _textFieldContainerConstraints;
}

- (void)setMemos:(NSMutableArray *)memos {
    _memos = memos;
    [self endEditing];
    [self reloadData];
}

- (id)initWithSuperview:(UIView *)superview frontLayer:(UIView *)frontLayer backLayer:(UIView *)backLayer andDelegate:(id<CPMemoCollectionViewManagerDelegate>)delegate {
    self = [super init];
    if (self) {
        self.memos = [NSMutableArray array];
        self.delegate = delegate;
        self.superview = superview;
        self.frontLayer = frontLayer;
        self.backLayer = backLayer;
        
        [self.frontLayer addSubview:self.frontCollectionView];
        [self.frontLayer addSubview:self.textFieldContainer];
        [self.backLayer addSubview:self.backCollectionView];
        [self.frontLayer addConstraints:self.frontCollectionViewConstraints];
        [self.frontLayer addConstraints:self.textFieldContainerConstraints];
        [self.backLayer addConstraints:self.backCollectionViewConstraints];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidUndock:) name:UIKeyboardDidChangeFrameNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidHide:) name:UIKeyboardDidHideNotification object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(invalidateLayout) name:CPDeviceOrientationWillChangeNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(invalidateLayout) name:CPAdResizingDidAffectContentNotification object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidChangeFrameNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidHideNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:CPDeviceOrientationWillChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:CPAdResizingDidAffectContentNotification object:nil];
}

- (void)showMemoCollectionViewAnimated {
    UIView *fakeMemoContainer = [[UIView alloc] init];
    fakeMemoContainer.clipsToBounds = YES;
    fakeMemoContainer.translatesAutoresizingMaskIntoConstraints = NO;
    [self.backLayer addSubview:fakeMemoContainer];
    
    [self.backLayer addConstraints:[CPAppearanceManager constraintsWithView:fakeMemoContainer edgesAlignToView:self.backLayer]];
    
    NSMutableArray *fakeMemos = [NSMutableArray array];
    for (UIView *realMemo in self.backCollectionView.subviews) {
        UIView *fakeMemo = [[UIView alloc] init];
        fakeMemo.backgroundColor = realMemo.backgroundColor;
        fakeMemo.translatesAutoresizingMaskIntoConstraints = NO;
        [fakeMemoContainer addSubview:fakeMemo];
        [fakeMemos addObject:fakeMemo];
        
        NSLayoutConstraint *fakeMemoTopConstraint = [NSLayoutConstraint constraintWithItem:fakeMemo attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:realMemo attribute:NSLayoutAttributeTop multiplier:1.0 constant:0.0];
        [self.backLayer addConstraint:fakeMemoTopConstraint];
        NSLayoutConstraint *fakeMemoBottomConstraint = [NSLayoutConstraint constraintWithItem:fakeMemo attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:realMemo attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0];
        [self.backLayer addConstraint:fakeMemoBottomConstraint];
        NSLayoutConstraint *fakeMemoLeftConstraint = [NSLayoutConstraint constraintWithItem:fakeMemo attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:realMemo attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0.0];
        [self.backLayer addConstraint:fakeMemoLeftConstraint];
        NSLayoutConstraint *fakeMemoWidthConstraint= [NSLayoutConstraint constraintWithItem:fakeMemo attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:0.0 constant:0.0];
        [fakeMemo addConstraint:fakeMemoWidthConstraint];
    }
    
    for (UIView *subview in self.frontCollectionView.subviews) {
        subview.alpha = 0.0;
    }
    for (UIView *subview in self.backCollectionView.subviews) {
        subview.alpha = 0.0;
    }
    
    [self.superview layoutIfNeeded];
    
    for (int i = 0; i < fakeMemos.count; i++) {
        [CPAppearanceManager animateWithDuration:0.4 delay:0.34 + 0.04 * i options:0 animations:^{
            ((NSLayoutConstraint *)[((UIView *)[fakeMemos objectAtIndex:i]).constraints objectAtIndex:0]).constant = self.backCollectionView.frame.size.width - 2 * BOX_SEPARATOR_SIZE;
            [(UIView *)[fakeMemos objectAtIndex:i] layoutIfNeeded];
        } completion:^(BOOL finished) {
            ((UIView *)[self.backCollectionView.subviews objectAtIndex:i]).alpha = 1.0;
            
            if (i == fakeMemos.count - 1) {
                [fakeMemoContainer removeFromSuperview];
            }
        }];
        
        [CPAppearanceManager animateWithDuration:0.3 delay:0.44 + 0.04 * i options:0 animations:^{
            ((UIView *)[self.frontCollectionView.subviews objectAtIndex:i]).alpha = 1.0;
        } completion:nil];
    }

}

- (void)setEnabled:(BOOL)enabled {
    self.frontCollectionView.userInteractionEnabled = enabled;
    self.frontCollectionView.alpha = self.backCollectionView.alpha = enabled ? 1.0 : 0.0;
}

- (void)endEditing {
    if (self.editingCell) {
        [self.editingCell endEditingAtIndexPath:[self.frontCollectionView indexPathForCell:self.editingCell]];
    }
}

- (void)setOffset:(CGPoint)offset animated:(BOOL)animated {
    [self.frontCollectionView setContentOffset:offset animated:animated];
    [self.backCollectionView setContentOffset:offset animated:animated];
}

- (void)reloadData {
    [self.frontCollectionView reloadData];
    [self.backCollectionView reloadData];
}

- (void)invalidateLayout {
    [self endEditing];
    [self.frontCollectionView.collectionViewLayout invalidateLayout];
    [self.backCollectionView.collectionViewLayout invalidateLayout];
}

- (void)handlePanGesture:(UIPanGestureRecognizer *)panGesture {
    if (panGesture.state == UIGestureRecognizerStateChanged) {
        CGPoint translation = [panGesture translationInView:panGesture.view];
        if (!IS_IN_PROCESS(REMOVING_MEMO_CELL_PROCESS) && !IS_IN_PROCESS(SCROLLING_COLLECTION_VIEW_PROCESS)) {
            CGPoint location = [panGesture locationInView:panGesture.view];
            NSIndexPath *panningCellIndex = [self.frontCollectionView indexPathForItemAtPoint:location];
            
            if (self.editingCell) {
                [self.editingCell endEditingAtIndexPath:[self.frontCollectionView indexPathForCell:self.editingCell]];
            }
            
            // TODO: Determine if the memo cell should fall back to original position when you start removing after it is raised up when editing.
            
            if (fabsf(translation.x) > fabsf(translation.y) && panningCellIndex) {
                [CPProcessManager startProcess:REMOVING_MEMO_CELL_PROCESS withPreparation:^{
                    self.frontRemovingCellIndex = self.backRemovingCellIndex = panningCellIndex;
                    [self reloadData];
                }];
            } else {
                self.collectionViewOffsetBeforeEdit = nil;
                [CPProcessManager startProcess:SCROLLING_COLLECTION_VIEW_PROCESS withPreparation:^{
                    if (IS_IN_PROCESS(EDITING_PASS_CELL_PROCESS)) {
                        self.draggingBasicOffset = CGPointMake(self.frontCollectionView.contentOffset.x, self.frontCollectionView.contentOffset.y + MEMO_CELL_HEIGHT + BOX_SEPARATOR_SIZE);
                    } else {
                        self.draggingBasicOffset = self.frontCollectionView.contentOffset;
                    }
                    [self reloadData];
                }];
            }
        }
        if (IS_IN_PROCESS(REMOVING_MEMO_CELL_PROCESS)) {
            self.frontRemovingCell.leftOffset = self.backRemovingCell.leftOffset = translation.x;
        }
        if (IS_IN_PROCESS(SCROLLING_COLLECTION_VIEW_PROCESS)) {
            CGPoint offset = CGPointMake(self.draggingBasicOffset.x, self.draggingBasicOffset.y - translation.y);
            [self setOffset:offset animated:NO];
            
            if (IS_IN_PROCESS(EDITING_PASS_CELL_PROCESS)) {
                CPMemoCell *addingCell = (CPMemoCell *)[self.frontCollectionView cellForItemAtIndexPath:NS_INDEX_PATH_ZERO];
                if (addingCell && offset.y < 30.0) {
                    addingCell.label.text = @"Release to add a new memo";
                } else {
                    addingCell.label.text = @"Drag to add a new memo";
                }
            }
        }
    } else if (panGesture.state == UIGestureRecognizerStateEnded || panGesture.state == UIGestureRecognizerStateCancelled || panGesture.state == UIGestureRecognizerStateFailed) {
        CGPoint translation = [panGesture translationInView:panGesture.view];
        
        [CPProcessManager stopProcess:REMOVING_MEMO_CELL_PROCESS withPreparation:^{
            if (fabsf(translation.x) < self.frontRemovingCell.contentView.frame.size.width / 2) {
                self.frontRemovingCell.leftOffset = self.backRemovingCell.leftOffset = 0.0;
                [CPAppearanceManager animateWithDuration:0.5 animations:^{
                    [self.superview layoutIfNeeded];
                } completion:^(BOOL finished) {
                    [self reloadData];
                }];
                [CPAppearanceManager animateWithDuration:0.3 delay:0.2 options:0 animations:^{
                    self.frontRemovingCell.leftLabel.alpha = 0.0;
                    self.frontRemovingCell.rightLabel.alpha = 0.0;
                } completion:nil];
            } else {
                [CPAppearanceManager animateWithDuration:0.3 animations:^{
                    self.frontRemovingCell.contentView.alpha = self.backRemovingCell.contentView.alpha = 0.0;
                }completion:^(BOOL finished) {
                    NSIndexPath *removingIndex = [self.frontCollectionView indexPathForCell:self.frontRemovingCell];
                    CPMemo *memo = [self.memos objectAtIndex:removingIndex.row];
                    [self.memos removeObject:memo];
                    [[CPPassDataManager defaultManager] removeMemo:memo];
                    [self.frontCollectionView deleteItemsAtIndexPaths:[NSArray arrayWithObject:removingIndex]];
                    [self.backCollectionView deleteItemsAtIndexPaths:[NSArray arrayWithObject:removingIndex]];
                }];
            }
        }];
        
        [CPProcessManager stopProcess:SCROLLING_COLLECTION_VIEW_PROCESS withPreparation:^{
            CGPoint offset = CGPointMake(self.draggingBasicOffset.x, self.draggingBasicOffset.y - translation.y);
            float contentHeight = MAX(self.frontCollectionView.contentSize.height, self.frontCollectionView.frame.size.height);
            
            if (IS_IN_PROCESS(EDITING_PASS_CELL_PROCESS)) {
                if (offset.y < 30.0) {
                    self.addingCellIndex = NS_INDEX_PATH_ZERO;
                    [self.memos insertObject:[self.delegate newMemo] atIndex:0];
                } else {
                    offset = CGPointMake(offset.x, offset.y - MEMO_CELL_HEIGHT - BOX_SEPARATOR_SIZE);
                    contentHeight = MAX(self.frontCollectionView.contentSize.height - MEMO_CELL_HEIGHT - BOX_SEPARATOR_SIZE, self.frontCollectionView.frame.size.height);
                }
            }
            
            [self reloadData];
            
            // This code is strange. I don't know why it works but it indeed works and it will fail without the second line.
            // The strange thing happens only when in editing pass cell process (that means I have to add a line to the top of collection view writting "Drag to add" and I have to adjust the offset so when it starts dragging the first line won't suddenly jump out, and the several lines before this is to fix the offset change when the top line is removed. The next two lines are used to fix the offest after I fix the offset change.)
            // When you drag the last cell up too high and it need to fall back. This two lines fix it high up there and the following if-statement creates an animation to let it fall back. However, if I don't write the second line, the front collection view will simply fall back down without animation instead of stay high up. When the second line is added, the effect turns out to be what I want.
            // I hope somebody can find out what is happening and why I need to set frontCollectionView's offset twice.
            [self setOffset:offset animated:NO];
            [self.frontCollectionView setContentOffset:offset animated:NO];
            
            if (offset.y < 0.0) {
                offset.y = 0.0;
                [self setOffset:offset animated:YES];
            } else if (offset.y > contentHeight - self.frontCollectionView.frame.size.height) {
                offset.y = contentHeight - self.frontCollectionView.frame.size.height;
                [self setOffset:offset animated:YES];
            }
        }];
    }
}

- (void)keyboardDidShow:(NSNotification *)notification {
    // TODO: Scrolling to show editing memo cell isn't working properly when iPad is landscape.
    
    if (!self.collectionViewOffsetBeforeEdit) {
        self.collectionViewOffsetBeforeEdit = [NSValue valueWithCGPoint:self.frontCollectionView.contentOffset];
    }
    
    // TODO: Figure out why editing cell will not rise if starting edit cell just after search bar.
    
    NSValue *rectObj = [notification.userInfo valueForKey:UIKeyboardFrameEndUserInfoKey];
    if (self.editingCell) {
        if (rectObj) {
            CGRect rect = rectObj.CGRectValue;
            float transformedY = [self.frontCollectionView convertPoint:rect.origin fromView:nil].y;
            if (self.editingCell.frame.origin.y + self.editingCell.frame.size.height + BOX_SEPARATOR_SIZE > transformedY) {
                CGPoint offsetPoint = CGPointMake(self.frontCollectionView.contentOffset.x, self.frontCollectionView.contentOffset.y + self.editingCell.frame.origin.y + self.editingCell.frame.size.height + BOX_SEPARATOR_SIZE - transformedY);
                [self setOffset:offsetPoint animated:YES];
            }
        } else {
            [self setOffset:self.collectionViewOffsetBeforeEdit.CGPointValue animated:YES];
        }
    }
}

- (void)keyboardDidUndock:(NSNotification *)notification {
    if (self.collectionViewOffsetBeforeEdit) {
        [self setOffset:self.collectionViewOffsetBeforeEdit.CGPointValue animated:YES];
        self.collectionViewOffsetBeforeEdit = nil;
    }
}

- (void)keyboardDidHide:(NSNotification *)notification {
    if (self.collectionViewOffsetBeforeEdit && !self.editingCell) {
        [self setOffset:self.collectionViewOffsetBeforeEdit.CGPointValue animated:YES];
        self.collectionViewOffsetBeforeEdit = nil;
    }
}

- (void)memoCellAtIndexPath:(NSIndexPath *)indexPath updateText:(NSString *)text {
    NSAssert(indexPath, @"No memo cell index path specified when updating memo cell text!");
    NSAssert(text, @"No text specified when updating memo cell text!");
    
    CPMemo *memo = [self.memos objectAtIndex:indexPath.row];
    memo.text = text;
    
    [[CPPassDataManager defaultManager] saveContext];
}

#pragma mark - UICollectionViewDataSource implement

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (IS_IN_PROCESS(SCROLLING_COLLECTION_VIEW_PROCESS) && IS_IN_PROCESS(EDITING_PASS_CELL_PROCESS)) {
        return self.memos.count + 1;
    } else {
        return self.memos.count;
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *initializedCell;
    
    if (collectionView == self.frontCollectionView) {
        if (self.frontRemovingCellIndex && self.frontRemovingCellIndex.section == indexPath.section && self.frontRemovingCellIndex.row == indexPath.row) {
            // frontRemovingCellIndex is used once and then throw away
            self.frontRemovingCellIndex = nil;
            
            self.frontRemovingCell = [collectionView dequeueReusableCellWithReuseIdentifier:CELL_REUSE_IDENTIFIER_REMOVING forIndexPath:indexPath];
            
            self.frontRemovingCell.text = ((CPMemo *)[self.memos objectAtIndex:indexPath.row]).text;
            
            self.frontRemovingCell.label.font = [UIFont boldSystemFontOfSize:35.0];
            self.frontRemovingCell.label.backgroundColor = [UIColor clearColor];
            self.frontRemovingCell.label.textColor = [UIColor whiteColor];
            
            initializedCell = self.frontRemovingCell;
        } else {
            CPMemoCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:CELL_REUSE_IDENTIFIER_NORMAL forIndexPath:indexPath];
            
            cell.delegate = self;
            
            cell.label.font = [UIFont boldSystemFontOfSize:35.0];
            cell.label.backgroundColor = [UIColor clearColor];
            cell.label.textColor = [UIColor whiteColor];
            
            if (IS_IN_PROCESS(SCROLLING_COLLECTION_VIEW_PROCESS) && IS_IN_PROCESS(EDITING_PASS_CELL_PROCESS)) {
                if (indexPath.section == 0 && indexPath.row == 0) {
                    cell.label.text = @"Drag to add a new memo";
                } else {
                    CPMemo *memo = [self.memos objectAtIndex:indexPath.row - 1];
                    cell.label.text = memo.text;
                }
            } else {
                CPMemo *memo = [self.memos objectAtIndex:indexPath.row];
                cell.label.text = memo.text;
            }
            
            if (self.addingCellIndex && self.addingCellIndex.section == indexPath.section && self.addingCellIndex.row == indexPath.row) {
                // addingCellIndex is used once and then throw away
                self.addingCellIndex = nil;
                
                [cell startEditing];
            }
            
            initializedCell = cell;
        }
    } else {
        if (self.backRemovingCellIndex && self.backRemovingCellIndex.section == indexPath.section && self.backRemovingCellIndex.row == indexPath.row) {
            // backRemovingCellIndex is used once and then throw away
            self.backRemovingCellIndex = nil;
            
            self.backRemovingCell = [collectionView dequeueReusableCellWithReuseIdentifier:CELL_REUSE_IDENTIFIER_REMOVING_BACKGROUND forIndexPath:indexPath];
            
            self.backRemovingCell.color = ((CPMemo *)[self.memos objectAtIndex:indexPath.row]).password.realColor;
            
            initializedCell = self.backRemovingCell;
        } else {
            initializedCell = [collectionView dequeueReusableCellWithReuseIdentifier:CELL_REUSE_IDENTIFIER_NORMAL_BACKGROUND forIndexPath:indexPath];
            
            CPMemo *memo;
            
            if (IS_IN_PROCESS(SCROLLING_COLLECTION_VIEW_PROCESS) && IS_IN_PROCESS(EDITING_PASS_CELL_PROCESS)) {
                if (indexPath.row == 0) {
                    initializedCell.backgroundColor = self.inPasswordMemoColor;
                } else {
                    memo = [self.memos objectAtIndex:indexPath.row - 1];
                }
            } else {
                memo = [self.memos objectAtIndex:indexPath.row];
            }
            
            if (memo) {
                initializedCell.backgroundColor = memo.password.realColor;
            }
        }
    }
    
    return initializedCell;
}

#pragma mark - UICollectionViewDelegate implement

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    if ([(CPMemoCell *)cell isEditing]) {
        [(CPMemoCell *)cell endEditingAtIndexPath:indexPath];
    }
}

#pragma mark - UIScrollViewDelegate implement

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (self.editingCell) {
        [self.editingCell refreshingConstriants];
    }
    [self.superview layoutIfNeeded];
}

@end

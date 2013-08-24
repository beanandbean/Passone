//
//  CPMainViewController.m
//  Passone
//
//  Created by wangyw on 6/1/13.
//  Copyright (c) 2013 codingpotato. All rights reserved.
//

#import "CPMainViewController.h"

#import "CPMainPasswordManager.h"

#import "CPAdManager.h"

#import "CPPassGridManager.h"
#import "CPTopBarAndSearchManager.h"

#import "CPNotificationCenter.h"
#import "CPAppearanceManager.h"

#import "CPProcessManager.h"

@interface CPMainViewController ()

@property (strong, nonatomic) CPMainPasswordManager *mainPasswordManager;
@property (strong, nonatomic) CPAdManager *adManager;
@property (strong, nonatomic) CPPassGridManager *passGridManager;
@property (strong, nonatomic) CPTopBarAndSearchManager *topBarAndSearchManager;

@end

@implementation CPMainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor blackColor];
    
    UIView *outerView = [[UIView alloc] init];
    outerView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:outerView];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:outerView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTop multiplier:1.0 constant:0.0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:outerView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0.0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:outerView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeRight multiplier:1.0 constant:0.0]];
    
    UIView *adView = [[UIView alloc] init];
    adView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:adView];

    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:adView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0.0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:adView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeRight multiplier:1.0 constant:0.0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:adView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:outerView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:adView attribute:NSLayoutAttributeTop multiplier:1.0 constant:0.0]];
    
    UIView *contentView = [[UIView alloc] init];
    contentView.translatesAutoresizingMaskIntoConstraints = NO;
    [outerView addSubview:contentView];
    
    [CPNotificationCenter createNotificationCenterWithSuperView:outerView];

    self.adManager = [[CPAdManager alloc] initWithSuperview:adView];
    
    self.passGridManager = [[CPPassGridManager alloc] initWithSuperView:contentView];
    
    self.topBarAndSearchManager = [[CPTopBarAndSearchManager alloc] initWithSuperView:outerView];
    
    [outerView addConstraint:[NSLayoutConstraint constraintWithItem:contentView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.topBarAndSearchManager.searchBar attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0]];
    [outerView addConstraint:[NSLayoutConstraint constraintWithItem:contentView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:outerView attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0.0]];
    [outerView addConstraint:[NSLayoutConstraint constraintWithItem:contentView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:outerView attribute:NSLayoutAttributeRight multiplier:1.0 constant:0.0]];
    [outerView addConstraint:[NSLayoutConstraint constraintWithItem:contentView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:outerView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0]];
    
    // Not using main password while testing other parts of app.
    // self.mainPasswordManager = [[CPMainPasswordManager alloc] initWithSuperview:self.view];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end

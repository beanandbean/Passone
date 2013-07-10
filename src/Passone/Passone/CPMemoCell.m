//
//  CPMemoCell.m
//  Passone
//
//  Created by wangyw on 7/8/13.
//  Copyright (c) 2013 codingpotato. All rights reserved.
//

#import "CPMemoCell.h"

@implementation CPMemoCell

/*- (id)initWithColor:(UIColor *)color reuseIdentifier:(NSString  {
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
    if (self) {
        self.textLabel.backgroundColor = [UIColor clearColor];
        UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
        view.backgroundColor = color;
        view.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:view];
        [self.contentView bringSubviewToFront:self.textLabel];
        
        [self.contentView addConstraints:[[NSArray alloc] initWithObjects:
                                          [NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeTop multiplier:1.0 constant:1.0],
                                          [NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeLeft multiplier:1.0 constant:1.0],
                                          [NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeRight multiplier:1.0 constant:-1.0],
                                          [NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:-1.0],
                                          nil]];
    }
    return self;
}*/

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self) {
        self.label = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 0.0, frame.size.width, frame.size.height)];
        self.label.textAlignment = NSTextAlignmentCenter;
        self.label.textColor = [UIColor blackColor];
        self.label.font = [UIFont boldSystemFontOfSize:35.0];
        self.label.backgroundColor = [UIColor clearColor];
        
        [self.contentView addSubview:self.label];;
    }
    return self;
}


@end

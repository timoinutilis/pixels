//
//  SearchToolbar.m
//  Pixels
//
//  Created by Timo Kloss on 5/10/15.
//  Copyright © 2015 Inutilis Software. All rights reserved.
//

#import "SearchToolbar.h"

@interface SearchToolbar() <UIToolbarDelegate, UITextFieldDelegate>

@property UITextField *findTextField;
@property UITextField *replaceTextField;

@property (weak) UITextField *activeTextField;

@end

@implementation SearchToolbar

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        _findTextField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 60, 30)];
        _findTextField.placeholder = @"Find Text";
        _findTextField.borderStyle = UITextBorderStyleRoundedRect;
        _findTextField.autocapitalizationType = UITextAutocapitalizationTypeAllCharacters;
        _findTextField.delegate = self;
        
        _replaceTextField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 60, 30)];
        _replaceTextField.placeholder = @"Replace With";
        _replaceTextField.borderStyle = UITextBorderStyleRoundedRect;
        _replaceTextField.autocapitalizationType = UITextAutocapitalizationTypeAllCharacters;
        _replaceTextField.delegate = self;
        
        UIBarButtonItem *findFieldItem = [[UIBarButtonItem alloc] initWithCustomView:_findTextField];
        UIBarButtonItem *findPrevItem = [[UIBarButtonItem alloc] initWithTitle:@"<-" style:UIBarButtonItemStylePlain target:self action:@selector(onFindPrevTapped:)];
        UIBarButtonItem *findNextItem = [[UIBarButtonItem alloc] initWithTitle:@"->" style:UIBarButtonItemStylePlain target:self action:@selector(onFindNextTapped:)];
        UIBarButtonItem *replaceFieldItem = [[UIBarButtonItem alloc] initWithCustomView:_replaceTextField];
        UIBarButtonItem *replaceItem = [[UIBarButtonItem alloc] initWithTitle:@"Replace" style:UIBarButtonItemStylePlain target:self action:@selector(onReplaceTapped:)];
        
        self.items = @[findFieldItem, findPrevItem, findNextItem, replaceFieldItem, replaceItem];
        self.delegate = self;
    }
    return self;
}

- (UIBarPosition)positionForBar:(id<UIBarPositioning>)bar
{
    return UIBarPositionTop;
}

- (void)layoutSubviews
{
    CGFloat availableWidth = self.bounds.size.width - 165;
    
    if (availableWidth >= 320)
    {
        CGRect findRect = _findTextField.frame;
        findRect.size.width = availableWidth * 0.5;
        _findTextField.frame = findRect;
        
        CGRect replaceRect = _replaceTextField.frame;
        replaceRect.size.width = availableWidth * 0.5;
        _replaceTextField.frame = replaceRect;
    }
    else
    {
        CGRect findRect = _findTextField.frame;
        if (self.activeTextField == _findTextField)
        {
            findRect.size.width = availableWidth * 0.75;
        }
        else if (self.activeTextField)
        {
            findRect.size.width = availableWidth * 0.25;
        }
        else
        {
            findRect.size.width = availableWidth * 0.5;
        }
        _findTextField.frame = findRect;

        CGRect replaceRect = _replaceTextField.frame;
        if (self.activeTextField == _replaceTextField)
        {
            replaceRect.size.width = availableWidth * 0.75;
        }
        else if (self.activeTextField)
        {
            replaceRect.size.width = availableWidth * 0.25;
        }
        else
        {
            replaceRect.size.width = availableWidth * 0.5;
        }
        _replaceTextField.frame = replaceRect;
    }

    [super layoutSubviews];
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    self.activeTextField = textField;
    [self setNeedsLayout];
    [UIView animateWithDuration:0.3 animations:^{
        [self layoutIfNeeded];
    }];
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    self.activeTextField = nil;
    [self setNeedsLayout];
    [UIView animateWithDuration:0.3 animations:^{
        [self layoutIfNeeded];
    }];
}

- (void)onFindPrevTapped:(id)sender
{
    if (self.findTextField.text.length > 0)
    {
        [self endEditing:YES];
        [self.searchDelegate searchToolbar:self didSearch:self.findTextField.text backwards:YES];
    }
}

- (void)onFindNextTapped:(id)sender
{
    if (self.findTextField.text.length > 0)
    {
        [self endEditing:YES];
        [self.searchDelegate searchToolbar:self didSearch:self.findTextField.text backwards:NO];
    }
}

- (void)onReplaceTapped:(id)sender
{
    if (self.findTextField.text.length > 0 && self.replaceTextField.text.length > 0)
    {
        [self endEditing:YES];
        [self.searchDelegate searchToolbar:self didReplace:self.findTextField.text with:self.replaceTextField.text];
    }
}

@end

//
//  EditorTextView.m
//  Pixels
//
//  Created by Timo Kloss on 25/2/15.
//  Copyright (c) 2015 Inutilis Software. All rights reserved.
//

#import "EditorTextView.h"

NSString *EditorTextView_transferText;

@interface EditorTextView ()
@property UIToolbar *keyboardToolbar;
@end

@implementation EditorTextView

+ (void)setTransferText:(NSString *)text
{
    EditorTextView_transferText = text;
}

+ (NSString *)transferText
{
    return EditorTextView_transferText;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    [self initKeyboardToolbar];

    UIMenuController *menu = [UIMenuController sharedMenuController];
    menu.menuItems = @[
                       [[UIMenuItem alloc] initWithTitle:@"Help" action:@selector(help:)],
                       [[UIMenuItem alloc] initWithTitle:@"Copy to Transfer" action:@selector(transferCopy:)],
                       [[UIMenuItem alloc] initWithTitle:@"Paste from Transfer" action:@selector(transferPaste:)]
                       ];
}

- (void)initKeyboardToolbar
{
    self.keyboardToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
    
    NSArray *keys = @[@"=", @"<", @">", @"+", @"-", @"*", @"/", @"(", @")", @"\"", @"$", @":"];
    NSMutableArray *buttons = [NSMutableArray array];
    for (NSString *key in keys)
    {
        UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithTitle:key style:UIBarButtonItemStylePlain target:self action:@selector(onSpecialKeyTapped:)];
        [buttons addObject:button];
        
        UIBarButtonItem *space = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        [buttons addObject:space];
    }
    
    
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(onKeyboardDoneTapped:)];
    [buttons addObject:doneButton];
    
    self.keyboardToolbar.tintColor = self.tintColor;
    
    self.keyboardToolbar.items = buttons;
    self.inputAccessoryView = self.keyboardToolbar;
}

- (void)onSpecialKeyTapped:(UIBarButtonItem *)button
{
    [self insertText:button.title];
}

- (void)onKeyboardDoneTapped:(UIBarButtonItem *)button
{
    [self resignFirstResponder];
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender
{
    if (action == @selector(transferCopy:))
    {
        return self.selectedRange.length > 0;
    }
    else if (action == @selector(transferPaste:))
    {
        return [EditorTextView transferText].length > 0;
    }
    else if (action == @selector(help:))
    {
        return self.selectedRange.length > 0 && self.selectedRange.length <= 20;
    }
    else if (   action == @selector(copy:)
             || action == @selector(paste:)
             || action == @selector(cut:)
             || action == @selector(delete:)
             || action == @selector(select:)
             || action == @selector(selectAll:) )
    {
        return [super canPerformAction:action withSender:sender];
    }
    return NO;
}

- (void)transferCopy:(id)sender
{
    [EditorTextView setTransferText:[self.text substringWithRange:self.selectedRange]];
}

- (void)transferPaste:(id)sender
{
    if (!self.delegate || [self.delegate textView:self shouldChangeTextInRange:self.selectedRange replacementText:[EditorTextView transferText]])
    {
        [self insertText:[EditorTextView transferText]];
    }
}

- (void)help:(id)sender
{
    [self.editorDelegate editorTextView:self didSelectHelpWithRange:self.selectedRange];
}

@end

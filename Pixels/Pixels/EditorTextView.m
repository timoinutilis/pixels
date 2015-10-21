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
                       [[UIMenuItem alloc] initWithTitle:@"Indent <" action:@selector(indentLeft:)],
                       [[UIMenuItem alloc] initWithTitle:@"Indent >" action:@selector(indentRight:)],
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
    [self insertCheckedText:button.title];
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
    else if (   action == @selector(indentRight:)
             || action == @selector(indentLeft:) )
    {
        return YES;
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
    [self insertCheckedText:[EditorTextView transferText]];
}

- (void)help:(id)sender
{
    [self.editorDelegate editorTextView:self didSelectHelpWithRange:self.selectedRange];
}

- (void)indentRight:(id)sender
{
    [self indentToRight:YES];
}

- (void)indentLeft:(id)sender
{
    [self indentToRight:NO];
}

- (void)indentToRight:(BOOL)right
{
    NSRange originalRange = [self.text lineRangeForRange:self.selectedRange];
    NSRange finalRange = originalRange;
    NSMutableString *subtext = [[self.text substringWithRange:originalRange] mutableCopy];
    NSInteger pos = 0;
    while (pos < subtext.length)
    {
        if (right)
        {
            [subtext insertString:@"  " atIndex:pos];
            finalRange.length += 2;
        }
        else
        {
            NSInteger num = 0;
            for (NSInteger ci = pos; ci < pos + 2 && ci < subtext.length; ci++)
            {
                unichar character = [subtext characterAtIndex:ci];
                if (character == ' ')
                {
                    num++;
                }
                else if (character == '\n')
                {
                    break;
                }
            }
            if (num > 0)
            {
                [subtext replaceCharactersInRange:NSMakeRange(pos, num) withString:@""];
                finalRange.length -= num;
            }
        }
        
        NSRange lineRange = [subtext lineRangeForRange:NSMakeRange(pos, 0)];
        pos += lineRange.length;
    }
    self.text = [self.text stringByReplacingCharactersInRange:originalRange withString:subtext];

    // selection and menu
    if (finalRange.location + finalRange.length < self.text.length)
    {
        finalRange.length--;
    }
    self.selectedRange = finalRange;
    CGRect rect = [self firstRectForRange:self.selectedTextRange];
    UIMenuController *menu = [UIMenuController sharedMenuController];
    [menu setTargetRect:rect inView:self];
    [menu setMenuVisible:YES animated:NO];
}

- (void)insertCheckedText:(NSString *)text
{
    if (!self.delegate || [self.delegate textView:self shouldChangeTextInRange:self.selectedRange replacementText:text])
    {
        [self insertText:text];
    }
}

@end

//
//  EditorTextView.m
//  Pixels
//
//  Created by Timo Kloss on 25/2/15.
//  Copyright (c) 2015 Inutilis Software. All rights reserved.
//

#import "EditorTextView.h"

NSString *EditorTextView_transferText;

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
    
    UIMenuController *menu = [UIMenuController sharedMenuController];
    menu.menuItems = @[
                       [[UIMenuItem alloc] initWithTitle:@"Copy to Transfer" action:@selector(transferCopy:)],
                       [[UIMenuItem alloc] initWithTitle:@"Paste from Transfer" action:@selector(transferPaste:)]
                       ];
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
    [self insertText:[EditorTextView transferText]];
}

@end

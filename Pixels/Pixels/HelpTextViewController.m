//
//  HelpTextViewController.m
//  Pixels
//
//  Created by Timo Kloss on 25/12/14.
//  Copyright (c) 2014 Inutilis Software. All rights reserved.
//

#import "HelpTextViewController.h"
#import "HelpTableViewController.h"
#import "HelpContent.h"

@interface HelpTextViewController ()

@property (weak, nonatomic) IBOutlet UIWebView *webView;

@end

@implementation HelpTextViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.webView.delegate = self;
    
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"manual" withExtension:@"html"];
    _helpContent = [[HelpContent alloc] initWithURL:url];
    
    [self.webView loadHTMLString:self.helpContent.manualHtml baseURL:url];
}

- (IBAction)onDoneTapped:(id)sender
{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)setChapter:(NSString *)chapter
{
    _chapter = chapter;
    if (!self.webView.isLoading)
    {
        [self jumpToChapter:self.chapter];
    }
}

- (void)jumpToChapter:(NSString *)chapter
{
    NSString *script = [NSString stringWithFormat:@"document.getElementById('%@').scrollIntoView(true);", chapter];
    [self.webView stringByEvaluatingJavaScriptFromString:script];
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    if (self.chapter)
    {
        [self jumpToChapter:self.chapter];
    }
}

@end

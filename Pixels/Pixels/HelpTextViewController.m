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

@property UIViewController *contentsViewController;

@end

@implementation HelpTextViewController

+ (void)showHelpWithParent:(UIViewController *)parent
{
    static UIViewController *helpViewController = nil;
    
    if (!helpViewController)
    {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Help" bundle:nil];
        helpViewController = (UIViewController *)[storyboard instantiateInitialViewController];
        helpViewController.modalPresentationStyle = UIModalPresentationPageSheet;
    }
    [parent presentViewController:helpViewController animated:YES completion:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.webView.delegate = self;
    
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"manual" withExtension:@"html"];
    _helpContent = [[HelpContent alloc] initWithURL:url];
    
    [self.webView loadHTMLString:self.helpContent.manualHtml baseURL:url];
}

- (IBAction)onContentsTapped:(id)sender
{
    if (!self.contentsViewController)
    {
        self.contentsViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"Contents"];
        self.contentsViewController.modalPresentationStyle = UIModalPresentationPopover;
    }
    self.contentsViewController.popoverPresentationController.barButtonItem = sender;
    self.contentsViewController.popoverPresentationController.backgroundColor = self.navigationController.navigationBar.barTintColor;

    [self presentViewController:self.contentsViewController animated:YES completion:nil];
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

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    if (navigationType == UIWebViewNavigationTypeLinkClicked)
    {
        // open links in Safari
        [[UIApplication sharedApplication] openURL:[request URL]];
        return NO;
    }
    return YES;
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

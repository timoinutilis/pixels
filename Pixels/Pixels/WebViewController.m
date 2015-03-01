//
//  WebViewController.m
//  Pixels
//
//  Created by Timo Kloss on 28/2/15.
//  Copyright (c) 2015 Inutilis Software. All rights reserved.
//

#import "WebViewController.h"
#import "ModelManager.h"
#import "ExplorerViewController.h"

@interface WebViewController ()

@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *backItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *forwardItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *getItem;

@property UIActivityIndicatorView *activityView;

@end

@implementation WebViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    UIBarButtonItem *activityItem = [[UIBarButtonItem alloc] initWithCustomView:self.activityView];
    self.navigationItem.leftBarButtonItem = activityItem;
    
    self.webView.delegate = self;
    
    [self goHome];
}

- (void)goHome
{
    NSURL *url = [[NSURL alloc] initWithString:@"http://lowres.inutilis.com"];
    [self.webView loadRequest:[[NSURLRequest alloc] initWithURL:url]];
}

- (void)updateButtons
{
    self.backItem.enabled = self.webView.canGoBack;
    self.forwardItem.enabled = self.webView.canGoForward;
}

- (IBAction)onDoneTapped:(id)sender
{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)onBackTapped:(id)sender
{
    [self.webView goBack];
}

- (IBAction)onForwardTapped:(id)sender
{
    [self.webView goForward];
}

- (IBAction)onGetTapped:(id)sender
{
    
    Project *project = [[ModelManager sharedManager] createNewProject];
    project.name = @"TODO";
    project.sourceCode = @"TODO";
    
    [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
        [[NSNotificationCenter defaultCenter] postNotificationName:ExplorerRefreshAddedProjectNotification object:self];
    }];
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    if (navigationType == UIWebViewNavigationTypeLinkClicked)
    {
        if (![request.URL.host isEqualToString:@"lowres.inutilis.com"])
        {
            // open external links in Safari
            [[UIApplication sharedApplication] openURL:[request URL]];
            return NO;
        }
    }
    return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    [self.activityView startAnimating];
//    self.getItem.enabled = NO;
    [self updateButtons];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [self.activityView stopAnimating];
    self.getItem.enabled = YES;
    [self updateButtons];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"error" withExtension:@"html"];
    [self.webView loadRequest:[[NSURLRequest alloc] initWithURL:url]];
//    self.getItem.enabled = NO;
    [self updateButtons];
}

@end

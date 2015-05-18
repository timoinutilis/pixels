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
#import "AppStyle.h"
#import "AppController.h"

@interface WebViewController ()

@property (weak, nonatomic) IBOutlet UIWebView *webView;

@property UIActivityIndicatorView *activityView;
@property UIBarButtonItem *backItem;
@property UIBarButtonItem *forwardItem;
@property UIBarButtonItem *getItem;
@property UIBarButtonItem *spaceItem;
@property UIBarButtonItem *doneItem;

@end

@implementation WebViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [AppStyle styleNavigationController:self.navigationController];
    
    self.activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    UIBarButtonItem *activityItem = [[UIBarButtonItem alloc] initWithCustomView:self.activityView];
    
    self.backItem = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:self action:@selector(onBackTapped:)];
    self.forwardItem = [[UIBarButtonItem alloc] initWithTitle:@"Forw." style:UIBarButtonItemStylePlain target:self action:@selector(onForwardTapped:)];
    self.navigationItem.leftBarButtonItems = @[self.backItem, self.forwardItem, activityItem];
    
    self.getItem = [[UIBarButtonItem alloc] initWithTitle:@"Get Program" style:UIBarButtonItemStylePlain target:self action:@selector(onGetTapped:)];
    self.spaceItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    self.spaceItem.width = 15;
    self.doneItem = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(onDoneTapped:)];
    self.navigationItem.rightBarButtonItems = @[self.doneItem];
    
    self.webView.delegate = self;
    
    [self goHome];
}

- (void)goHome
{
    NSURL *url = [[NSURL alloc] initWithString:@"http://lowres.inutilis.com/news-and-programs"];
    [self.webView loadRequest:[[NSURLRequest alloc] initWithURL:url]];
}

- (void)updateButtons
{
    self.backItem.enabled = self.webView.canGoBack;
    self.forwardItem.enabled = self.webView.canGoForward;
}

- (void)onDoneTapped:(id)sender
{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
        [[AppController sharedController] registerForNotifications];
    }];
    
}

- (void)onBackTapped:(id)sender
{
    [self.webView goBack];
}

- (void)onForwardTapped:(id)sender
{
    [self.webView goForward];
}

- (void)onGetTapped:(id)sender
{
    
    Project *project = [[ModelManager sharedManager] createNewProject];
    project.name = [self pageProgramTitle];
    project.sourceCode = [self pageSourceCode];
    
    [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
        [[NSNotificationCenter defaultCenter] postNotificationName:ExplorerRefreshAddedProjectNotification object:self];
        [[AppController sharedController] registerForNotifications];
    }];
}

- (void)updateWithSourceCode:(BOOL)hasSourceCode
{
    if (hasSourceCode)
    {
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
        {
            self.title = nil;
        }
        [self.navigationItem setRightBarButtonItems:@[self.doneItem, self.spaceItem, self.getItem] animated:YES];
    }
    else
    {
        self.title = @"Web";
        [self.navigationItem setRightBarButtonItems:@[self.doneItem] animated:YES];
    }
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
    [self updateWithSourceCode:NO];
    [self updateButtons];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [self.activityView stopAnimating];
    [self updateWithSourceCode:[self pageHasSourceCode]];
    [self updateButtons];
    
    // reset app icon badge
    [AppController sharedController].numNews = 0;
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"error" withExtension:@"html"];
    [self.webView loadRequest:[[NSURLRequest alloc] initWithURL:url]];
    self.getItem.enabled = NO;
    [self updateButtons];
}

- (BOOL)pageHasSourceCode
{
    NSString *result = [self.webView stringByEvaluatingJavaScriptFromString:@"document.getElementsByName('sourcecode').length > 0"];
    return [result isEqualToString:@"true"];
}

- (NSString *)pageSourceCode
{
    NSString *result = [self.webView stringByEvaluatingJavaScriptFromString:@"document.getElementsByName('sourcecode')[0].textContent"];
    return result;
}

- (NSString *)pageProgramTitle
{
    NSString *result = [self.webView stringByEvaluatingJavaScriptFromString:@"document.getElementsByClassName('entry-title')[0].textContent"];
    return result;
}

@end

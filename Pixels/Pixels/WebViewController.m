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

@interface WebViewController ()

@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *getItem;

@property UIActivityIndicatorView *activityView;
@property UIBarButtonItem *backItem;
@property UIBarButtonItem *forwardItem;

@end

@implementation WebViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [AppStyle styleNavigationController:self.navigationController];
    
    self.activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    UIBarButtonItem *activityItem = [[UIBarButtonItem alloc] initWithCustomView:self.activityView];
    
    NSMutableArray *toolbarItems = [NSMutableArray array];
    [toolbarItems addObject:activityItem];
    [toolbarItems addObjectsFromArray:self.toolbarItems];
    self.toolbarItems = toolbarItems;
    
    self.backItem = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:self action:@selector(onBackTapped:)];
    self.forwardItem = [[UIBarButtonItem alloc] initWithTitle:@"Forw." style:UIBarButtonItemStylePlain target:self action:@selector(onForwardTapped:)];
    self.navigationItem.leftBarButtonItems = @[self.backItem, self.forwardItem];
    
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

- (IBAction)onDoneTapped:(id)sender
{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)onBackTapped:(id)sender
{
    [self.webView goBack];
}

- (void)onForwardTapped:(id)sender
{
    [self.webView goForward];
}

- (IBAction)onGetTapped:(id)sender
{
    
    Project *project = [[ModelManager sharedManager] createNewProject];
    project.name = [self pageProgramTitle];
    project.sourceCode = [self pageSourceCode];
    
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
    self.getItem.enabled = NO;
    [self updateButtons];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [self.activityView stopAnimating];
    self.getItem.enabled = [self pageHasSourceCode];
    [self updateButtons];
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

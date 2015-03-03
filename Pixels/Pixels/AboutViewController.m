//
//  AboutViewController.m
//  Pixels
//
//  Created by Timo Kloss on 16/1/15.
//  Copyright (c) 2015 Inutilis Software. All rights reserved.
//

#import "AboutViewController.h"
#import "GORSeparatorView.h"

@interface AboutViewController ()
@property (weak, nonatomic) IBOutlet UILabel *versionLabel;
@property (weak, nonatomic) IBOutlet GORSeparatorView *separatorView;
@property NSArray *menuTitles;
@property NSArray *menuIndices;
@end

@implementation AboutViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.separatorView.separatorColor = self.tableView.separatorColor;
    self.versionLabel.text = [NSString stringWithFormat:@"Version %@", self.appVersion];
    
    self.menuTitles = @[
                        @"Upgrade to full version",
                        @"Rate in App Store",
                        @"More from Inutilis",
                        @"Contact"];
    self.menuIndices = @[@0, @1, @2, @3];
}

- (IBAction)onDoneTapped:(id)sender
{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.menuIndices.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    NSNumber *index = self.menuIndices[indexPath.row];
    cell.textLabel.text = self.menuTitles[index.integerValue];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSNumber *index = self.menuIndices[indexPath.row];
    if (index.integerValue == 0)
    {
        [self performSegueWithIdentifier:@"Upgrade" sender:self];
    }
    else if (index.integerValue == 1)
    {
        // App Store
        NSURL *url = [NSURL URLWithString:@"itms-apps://itunes.apple.com/us/app/lowres-coder/id962117496"];
        [[UIApplication sharedApplication] openURL:url];
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
    else if (index.integerValue == 2)
    {
        // Web
        NSURL *url = [NSURL URLWithString:@"http://www.inutilis.com"];
        [[UIApplication sharedApplication] openURL:url];
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
    else if (index.integerValue == 3)
    {
        // Contact
        [self sendMail];
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

- (void)sendMail
{
    if ([MFMailComposeViewController canSendMail])
    {
        MFMailComposeViewController *mailViewController = [[MFMailComposeViewController alloc] init];
        mailViewController.mailComposeDelegate = self;
        mailViewController.view.tintColor = self.view.tintColor;
        
        UIDevice *device = [UIDevice currentDevice];
        
        [mailViewController setToRecipients:@[@"support@inutilis.com"]];
        [mailViewController setSubject:@"LowRes Coder"];
        [mailViewController setMessageBody:[NSString stringWithFormat:@"\n\n\n\n%@\n%@ %@\nApp %@", device.model, device.systemName, device.systemVersion, self.appVersion] isHTML:NO];
        
        [self presentViewController:mailViewController animated:YES completion:nil];
    }
    else
    {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"mailto:support@inutilis.com"]];
    }
}

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (NSString *)appVersion
{
    return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
}

@end

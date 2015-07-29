//
//  AppController.m
//  Pixels
//
//  Created by Timo Kloss on 3/3/15.
//  Copyright (c) 2015 Inutilis Software. All rights reserved.
//

#import "AppController.h"
#import <Parse/Parse.h>
#import "UIViewController+LowResCoder.h"
#import "CWStatusBarNotification.h"
#import "AppStyle.h"

NSString *const FullVersionProductID = @"fullversion";

NSString *const NumProgramsOpenedKey = @"NumProgramsOpened";
NSString *const ErrorKey = @"Error";

NSString *const PurchaseStateNotification = @"PurchaseStateNotification";
NSString *const NewsNotification = @"NewsNotification";

NSString *const InfoIDNews = @"InfoIDNews";

@interface AppController()
@property NSString *notificationPostId;
@end

@implementation AppController

+ (AppController *)sharedController
{
    static AppController *sharedController = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedController = [[self alloc] init];
    });
    return sharedController;
}

- (instancetype)init
{
    if (self = [super init])
    {
        _purchaseState = PurchaseStateUninitialized;
        [self initNotification];
    }
    return self;
}

- (BOOL)isFullVersion
{
    NSUserDefaults *storage = [NSUserDefaults standardUserDefaults];
    return [storage boolForKey:FullVersionProductID];
}

- (void)upgradeToFullVersion
{
    NSUserDefaults *storage = [NSUserDefaults standardUserDefaults];
    [storage setBool:YES forKey:FullVersionProductID];
    [storage synchronize];
}

- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message
{
    UIViewController *vc = ((UINavigationController *)[UIApplication sharedApplication].keyWindow.rootViewController).visibleViewController;

    UIAlertController* alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    
    [vc presentViewController:alert animated:YES completion:nil];
}

- (void)requestProducts
{
    self.purchaseState = PurchaseStateLoadingProducts;
    NSSet *productIdentifiers = [NSSet setWithObject:FullVersionProductID];
    SKProductsRequest *productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:productIdentifiers];
    productsRequest.delegate = self;
    [productsRequest start];
}

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
    for (SKProduct *product in response.products)
    {
        if ([product.productIdentifier isEqualToString:FullVersionProductID])
        {
            _fullVersionProduct = product;
        }
    }
    self.purchaseState = PurchaseStateProductsReady;
}

- (void)purchaseProduct:(SKProduct *)product
{
    self.purchaseState = PurchaseStateBusy;
    SKMutablePayment *payment = [SKMutablePayment paymentWithProduct:product];
    [[SKPaymentQueue defaultQueue] addPayment:payment];
}

- (void)restorePurchases
{
    self.purchaseState = PurchaseStateBusy;
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions
{
    for (SKPaymentTransaction *transaction in transactions)
    {
        switch (transaction.transactionState)
        {
            case SKPaymentTransactionStatePurchasing: {
                break;
            }
            case SKPaymentTransactionStateDeferred: {
                break;
            }
            case SKPaymentTransactionStateFailed: {
                [self showAlertWithTitle:@"Not upgraded" message:transaction.error.localizedDescription];
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                self.purchaseState = PurchaseStateProductsReady;
                break;
            }
            case SKPaymentTransactionStatePurchased: {
                [self purchasedProductID:transaction.payment.productIdentifier];
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                self.purchaseState = PurchaseStateProductsReady;
                break;
            }
            case SKPaymentTransactionStateRestored: {
                [self purchasedProductID:transaction.payment.productIdentifier];
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                self.purchaseState = PurchaseStateProductsReady;
                break;
            }
            default:
                // For debugging
                NSLog(@"Unexpected transaction state %@", @(transaction.transactionState));
                break;
        }
    }
}

- (void)paymentQueue:(SKPaymentQueue *)queue removedTransactions:(NSArray *)transactions
{
    self.purchaseState = PurchaseStateProductsReady;
}

- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error
{
    self.purchaseState = PurchaseStateProductsReady;
}

- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue
{
    self.purchaseState = PurchaseStateProductsReady;
    if (!self.isFullVersion)
    {
        [self showAlertWithTitle:@"Not upgraded to full version" message:@"Maybe you upgraded with another App Store account?"];
    }
}

- (void)purchasedProductID:(NSString *)productID
{
    if ([productID isEqualToString:FullVersionProductID])
    {
        [self upgradeToFullVersion];
    }
}

- (void)setPurchaseState:(PurchaseState)purchaseState
{
    _purchaseState = purchaseState;
    [[NSNotificationCenter defaultCenter] postNotificationName:PurchaseStateNotification object:self];
}

- (BOOL)isUnshownInfoID:(NSString *)infoId
{
    NSUserDefaults *storage = [NSUserDefaults standardUserDefaults];
    return ![storage boolForKey:infoId];
}

- (void)onShowInfoID:(NSString *)infoId
{
    NSUserDefaults *storage = [NSUserDefaults standardUserDefaults];
    [storage setBool:YES forKey:infoId];
}

- (NSInteger)numProgramsOpened
{
    NSUserDefaults *storage = [NSUserDefaults standardUserDefaults];
    return [storage integerForKey:NumProgramsOpenedKey];
}

- (void)onProgramOpened
{
    NSUserDefaults *storage = [NSUserDefaults standardUserDefaults];
    [storage setInteger:([storage integerForKey:NumProgramsOpenedKey] + 1) forKey:NumProgramsOpenedKey];
}

- (void)registerForNotifications
{
    // Register for Push Notitications
    UIApplication *application = [UIApplication sharedApplication];
    UIUserNotificationType userNotificationTypes = (UIUserNotificationTypeAlert | UIUserNotificationTypeBadge | UIUserNotificationTypeSound);
    UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:userNotificationTypes categories:nil];
    [application registerUserNotificationSettings:settings];
    [application registerForRemoteNotifications];
}

- (NSInteger)numNews
{
    PFInstallation *installation = [PFInstallation currentInstallation];
    NSInteger numNews = installation.badge;
    
    // show news badge on first start
    if (numNews == 0 && [self isUnshownInfoID:InfoIDNews])
    {
        numNews = 1;
    }
    
    return numNews;
}

- (void)setNumNews:(NSInteger)numNews
{
    if (numNews != self.numNews)
    {
        PFInstallation *installation = [PFInstallation currentInstallation];
        if (numNews != installation.badge)
        {
            installation.badge = numNews;
            [installation saveEventually];
        }
        
        [self onShowInfoID:InfoIDNews];
        [[NSNotificationCenter defaultCenter] postNotificationName:NewsNotification object:self];
    }
}

- (void)storeError:(NSError *)error message:(NSString *)message
{
    NSUserDefaults *storage = [NSUserDefaults standardUserDefaults];
    [storage setObject:[NSString stringWithFormat:@"%@: %@", message, error.description] forKey:ErrorKey];
    [storage synchronize];
}

- (NSString *)popStoredError
{
    NSUserDefaults *storage = [NSUserDefaults standardUserDefaults];
    NSString *error = [storage objectForKey:ErrorKey];
    if (error)
    {
        [storage removeObjectForKey:ErrorKey];
    }
    return error;
}

- (void)handlePush:(NSDictionary *)userInfo inForeground:(BOOL)inForeground
{
    NSString *postId = userInfo[@"lrcPostId"];
    NSDictionary *aps = userInfo[@"aps"];
    NSString *alertText = aps[@"alert"];
    NSNumber *badge = aps[@"badge"];
    
    if (badge)
    {
        [UIApplication sharedApplication].applicationIconBadgeNumber = badge.integerValue;
    }
    
    if (inForeground)
    {
        self.notificationPostId = postId;
        
//        [self.notification displayNotificationWithMessage:alertText forDuration:3];

        
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 64)];
        view.backgroundColor = [AppStyle tintColor];
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10, 20, 300, 44)];
        label.backgroundColor = [UIColor clearColor];
        label.textColor = [AppStyle darkColor];
        label.textAlignment = NSTextAlignmentCenter;
        label.text = alertText;
        label.numberOfLines = 0;
        label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [view addSubview:label];
        [self.notification displayNotificationWithView:view forDuration:3];
    }
    else
    {
        self.shouldShowPostId = postId;
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:NewsNotification object:self];
}

- (void)initNotification
{
    _notification = [[CWStatusBarNotification alloc] init];
    _notification.notificationStyle = CWNotificationStyleNavigationBarNotification;
    _notification.notificationAnimationInStyle = CWNotificationAnimationStyleTop;
    _notification.notificationAnimationOutStyle = CWNotificationAnimationStyleTop;
    _notification.notificationAnimationType = CWNotificationAnimationTypeOverlay;
    
    __weak AppController *weakSelf = self;
    _notification.notificationTappedBlock = ^(void) {
        
        if (!weakSelf.notification.notificationIsDismissing)
        {
            [weakSelf.notification dismissNotification];
            
            weakSelf.shouldShowPostId = weakSelf.notificationPostId;
            [[NSNotificationCenter defaultCenter] postNotificationName:NewsNotification object:weakSelf];
        }
        
    };
}

@end

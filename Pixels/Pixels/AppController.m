//
//  AppController.m
//  Pixels
//
//  Created by Timo Kloss on 3/3/15.
//  Copyright (c) 2015 Inutilis Software. All rights reserved.
//

#import "AppController.h"

NSString *const FullVersionProductID = @"fullversion";

NSString *const PurchaseStateNotification = @"PurchaseStateNotification";

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
    }
    return self;
}

- (BOOL)isFullVersion
{
    NSUserDefaults *storage = [NSUserDefaults standardUserDefaults];
    return [storage boolForKey:FullVersionProductID];
}

- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message
{
    UIViewController *vc = ((UINavigationController *)[UIApplication sharedApplication].keyWindow.rootViewController).visibleViewController;

    UIAlertController* alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    alert.view.tintColor = vc.view.tintColor;
    
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
        NSUserDefaults *storage = [NSUserDefaults standardUserDefaults];
        [storage setBool:YES forKey:FullVersionProductID];
        [storage synchronize];
    }
}

- (void)setPurchaseState:(PurchaseState)purchaseState
{
    _purchaseState = purchaseState;
    [[NSNotificationCenter defaultCenter] postNotificationName:PurchaseStateNotification object:self];
}

@end

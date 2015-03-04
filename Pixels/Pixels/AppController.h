//
//  AppController.h
//  Pixels
//
//  Created by Timo Kloss on 3/3/15.
//  Copyright (c) 2015 Inutilis Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

typedef NS_ENUM(NSInteger, PurchaseState) {
    PurchaseStateUninitialized,
    PurchaseStateLoadingProducts,
    PurchaseStateProductsReady,
    PurchaseStateBusy
};

extern NSString *const PurchaseStateNotification;

@interface AppController : NSObject <SKProductsRequestDelegate, SKPaymentTransactionObserver>

@property (readonly) PurchaseState purchaseState;
@property (readonly) BOOL isFullVersion;
@property (readonly) SKProduct *fullVersionProduct;

+ (AppController *)sharedController;

- (void)requestProducts;
- (void)purchaseProduct:(SKProduct *)product;
- (void)restorePurchases;

@end

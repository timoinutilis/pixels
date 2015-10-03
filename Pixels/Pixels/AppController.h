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
extern NSString *const NewsNotification;
extern NSString *const ShowPostNotification;

@class CWStatusBarNotification;

@interface AppController : NSObject <SKProductsRequestDelegate, SKPaymentTransactionObserver>

@property (readonly) PurchaseState purchaseState;
@property (readonly) BOOL isFullVersion;
@property (readonly) SKProduct *fullVersionProduct;
@property (readonly) NSInteger numProgramsOpened;
@property BOOL shouldShowTransferAlert;
@property (nonatomic) NSInteger numNews;
@property NSString *shouldShowPostId;
@property (readonly) CWStatusBarNotification *notification;

+ (AppController *)sharedController;

- (void)upgradeToFullVersion;

- (void)requestProducts;
- (void)purchaseProduct:(SKProduct *)product;
- (void)restorePurchases;

- (BOOL)isUnshownInfoID:(NSString *)infoId;
- (void)onShowInfoID:(NSString *)infoId;

- (void)onProgramOpened;

- (void)registerForNotifications;

- (void)storeError:(NSError *)error message:(NSString *)message;
- (NSString *)popStoredError;

- (void)handlePush:(NSDictionary *)userInfo inForeground:(BOOL)inForeground;
- (BOOL)handleOpenURL:(NSURL *)url;
;
@end

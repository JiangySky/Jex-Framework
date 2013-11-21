//
//  JexComm_ext.h
//  JexFrm
//
//  Created by Jiangy on 13-11-21.
//  Copyright (c) 2013年 Jiangy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JexCommon.h"

#pragma mark - == Sqlite == -

#import <sqlite3.h>

#define kDataFile           @"Jex.db"
#define kTablePlayer		@"Player"

@interface Sqlite : NSObject {
    sqlite3 *				datebase;
	BOOL					resetSQL;
}

- (void)doneWithQuery:(NSString *)query;
- (void)debugQuery:(NSString *)query;

- (void)createDatebase;
- (BOOL)openDatebase;
- (void)closeDatebase;
- (BOOL)existTable:(NSString *)tableName;
- (void)createTable:(NSString *)tableName;
- (void)appendTable:(NSString *)tableName;
- (void)recreateTeable:(NSString *)tableName;
- (void)dropTable:(NSString *)tableName;
- (void)clearTable:(NSString *)tableName;
- (BOOL)isNullTable:(NSString *)tableName;

- (void)createTableByApp;
- (NSString *)qureyOfCreateTable:(NSString *)tableName;
- (void)loadData;
- (void)saveData;
- (void)resetData;

@end

#pragma mark - == GPS == -

#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>

#define REFRESH_INTERVAL        10
#define LOCATION_WITH_MAP

@interface GPS : NSObject <CLLocationManagerDelegate, MKMapViewDelegate> {
    NSInteger               getCityNext;
    BOOL                    requestFail;
    BOOL                    requestFinish;
    NSDate *                refreshTime;
    
    CLLocationManager *     location;
    NSMutableData *         receivedData;
    
    CLLocationCoordinate2D  coordinate;
    NSString *              fullAddress;
	NSString *              streetNumber;
	NSString *              route;
	NSString *              city;
	NSString *              province;
	NSString *              postalCode;
	NSString *              country;
#ifdef LOCATION_WITH_MAP
    MKMapView *             jexMapView;
#endif
}

@property BOOL              requestFinish;
@property BOOL              requestFail;

@property CLLocationCoordinate2D            coordinate;
@property (nonatomic, retain) NSString *    fullAddress;
@property (nonatomic, retain) NSString *    streetNumber;
@property (nonatomic, retain) NSString *    route;
@property (nonatomic, retain) NSString *    city;
@property (nonatomic, retain) NSString *    province;
@property (nonatomic, retain) NSString *    postalCode;
@property (nonatomic, retain) NSString *    country;

DECLARE_SINGLETON_FOR_CLASS(GPS)
+ (BOOL)isEnabel;
- (void)refresh:(BOOL)getCity;
- (void)requestForCity;
- (void)ignoreProvinceName;
- (NSString *)provinceAndCity;

@end

#pragma mark - == IAP == -

#import <StoreKit/StoreKit.h>
#import "GTMBase64.h"

#ifdef COCOS2D_DEBUG
#define IAP_URL             @"https://sandbox.itunes.apple.com/verifyReceipt"
#else
#define IAP_URL             @"https://buy.itunes.apple.com/verifyReceipt"
#endif

typedef enum  {
	kIAPTransactionStatusComplete,
	kIAPTransactionStatusRestore,
	kIAPTransactionStatusFailed
} IAPTransactionStatus;

typedef enum {
	kIAPVerifyRecepitModeNone,
	kIAPVerifyRecepitModeDevice,
	kIAPVerifyRecepitModeServer,
} IAPVerifyRecepitMode;

@protocol IAPDeletage

@required
- (void)didFailedTransaction:(NSString *)proIdentifier;
- (void)didRestoreTransaction:(NSString *)proIdentifier;
@optional
- (void)didReceivedProducts:(NSArray *)products;
// if you do not need to verify receipt, plz implement this function
- (void)didCompleteTransaction:(NSString *)proIdentifier;
// if you want to verify receipt via iphone or server, plz implement the follow functions
- (void)verifyReceipt:(SKPaymentTransaction *)transaction;
- (void)didCompleteTransactionAndVerifySucceed:(NSString *)proIdentifier;
- (void)didCompleteTransactionAndVerifyFailed:(NSString *)error;

@end

@interface IAP : NSObject <SKPaymentTransactionObserver, SKProductsRequestDelegate> {
    NSMutableArray *        completeTrans;
	NSMutableArray *        failedTrans;
	NSMutableArray *        restoreTrans;
    
    SKProductsRequest *     productsRequest;
	id <IAPDeletage>        delegate;
	IAPVerifyRecepitMode    verifyRecepitMode;
    
    id <SKPaymentTransactionObserver> paymentObserver;
}

@property (nonatomic, retain) NSMutableArray *  completeTrans;
@property (nonatomic, retain) NSMutableArray *  failedTrans;
@property (nonatomic, retain) NSMutableArray *  restoreTrans;
@property (nonatomic, retain) id <IAPDeletage>  delegate;
@property (assign) IAPVerifyRecepitMode         verifyRecepitMode;
@property (nonatomic, retain) id <SKPaymentTransactionObserver> paymentObserver;

DECLARE_SINGLETON_FOR_CLASS(IAP)

- (void)recordTransaction:(SKPaymentTransaction *)transaction withStatus:(int)status;
- (void)provideContent:(NSString *)productIdentifier;

- (void)completeTransaction:(SKPaymentTransaction *)transaction;
- (void)failedTransaction:(SKPaymentTransaction *)transaction;
- (void)restoreTransaction:(SKPaymentTransaction *)transaction;

- (void)requestProductData:(NSString *)proIdentifier;
- (void)requestProductsData:(NSArray *)proIdentifiers;
- (void)addPayment:(NSString *)productIdentifier;
- (void)verifyReceipt:(SKPaymentTransaction *)transaction;

@end

#pragma mark - == JexComm_ext == -

@interface JexComm_ext : NSObject

@end

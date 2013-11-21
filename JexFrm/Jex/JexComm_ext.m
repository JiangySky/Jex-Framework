//
//  JexComm_ext.m
//  JexFrm
//
//  Created by Jiangy on 13-11-21.
//  Copyright (c) 2013年 Jiangy. All rights reserved.
//

#import "JexComm_ext.h"
#import "Jex.h"

#pragma mark - == Sqlite == -

@implementation Sqlite

- (id)init {
    if ((self = [super init])) {
        [self createDatebase];
		resetSQL = NO;
    }
    return self;
}

- (void)doneWithQuery:(NSString *)query {
	sqlite3_stmt * stmt;
	sqlite3_prepare(datebase, [query UTF8String], -1, &stmt, NULL);
	int dbResult = sqlite3_step(stmt);
	if (dbResult != SQLITE_DONE) {
		NSAssert1(0, @"Error in doneWithQuery: <%i>", dbResult);
	}
	sqlite3_finalize(stmt);
}

- (void)debugQuery:(NSString *)query {
	printf("%s\n", [query UTF8String]);
	char * errMsg;
	int dbResult = sqlite3_exec(datebase, [query UTF8String], NULL, NULL, &errMsg);
	if (dbResult != SQLITE_OK) {
		[self closeDatebase];
		NSAssert2(0, @"Error in saveBattleData: <%i\t%s>", dbResult, errMsg);
	}
}

#pragma mark -

- (void)createDatebase {
	if (![NSFileManager fileExit:[APP resourceInDocument:kDataFile] isDirectory:NO]) {
		if ([self openDatebase]) {
            [self createTable:kTablePlayer];
            [self createTableByApp];
            
			[self closeDatebase];
		}
	}
	
	// MARK: appendTable: when upgrade app
    
    NSLog(@"DB path: %@", [APP resourceInDocument:kDataFile]);
}

- (BOOL)openDatebase {
	NSString * dbPathName = [APP resourceInDocument:kDataFile];
	int dbResult = sqlite3_open([dbPathName UTF8String], &datebase);
	if (dbResult != SQLITE_OK) {
		sqlite3_close(datebase);
		NSAssert2(0, @"Failed to open database: <%i\t%@>", dbResult, dbPathName);
	}
	return YES;
}

- (void)closeDatebase {
	sqlite3_close(datebase);
}

- (BOOL)existTable:(NSString *)tableName {
	BOOL retResult = YES;
    
	NSString * query = [NSString stringWithFormat:@"SELECT * FROM sqlite_master WHERE type='table' AND name='%@'", tableName];
	sqlite3_stmt * stmt;
	sqlite3_prepare(datebase, [query UTF8String], -1, &stmt, NULL);
	if (sqlite3_step(stmt) != SQLITE_ROW) {
		retResult = NO;
	}
	sqlite3_finalize(stmt);
	
	return retResult;
}

- (void)createTable:(NSString *)tableName {
	NSString * createTable = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@", tableName];
	NSString * qurey = [self qureyOfCreateTable:tableName];
	char * errMsg;
	int dbResult = sqlite3_exec(datebase, [[createTable stringByAppendingString:qurey] UTF8String], NULL, NULL, &errMsg);
	if (dbResult != SQLITE_OK) {
		[self closeDatebase];
		NSAssert2(0, @"Error in createTable: <%i\t%s>", dbResult, errMsg);
	}
}

- (void)appendTable:(NSString *)tableName {
	if ([self openDatebase]) {
		[self createTable:tableName];
		[self closeDatebase];
	}
}

- (void)recreateTeable:(NSString *)tableName {
    if ([self openDatebase]) {
        if ([self existTable:tableName]) {
            NSString * query = [NSString stringWithFormat:@"DROP TABLE %@", tableName];
            [self doneWithQuery:query];
        }
        [self createTable:tableName];
        [self closeDatebase];
    }
}

- (void)dropTable:(NSString *)tableName {
	if ([self openDatebase]) {
        if ([self existTable:tableName]) {
            NSString * query = [NSString stringWithFormat:@"DROP TABLE %@", tableName];
            [self doneWithQuery:query];
        }
        [self closeDatebase];
    }
}

- (void)clearTable:(NSString *)tableName {
	if ([self openDatebase]) {
		NSString * query = [NSString stringWithFormat:@"DELETE FROM %@", tableName];
        [self doneWithQuery:query];
		[self closeDatebase];
	}
}

- (BOOL)isNullTable:(NSString *)tableName {
	BOOL retResult = YES;
	if ([self openDatebase]) {
		NSString * query = [NSString stringWithFormat:@"SELECT * FROM %@", tableName];
		sqlite3_stmt * stmt;
		sqlite3_prepare(datebase, [query UTF8String], -1, &stmt, NULL);
		if (sqlite3_step(stmt) == SQLITE_ROW) {
			retResult = NO;
		}
		sqlite3_finalize(stmt);
		[self closeDatebase];
	}
	return retResult;
}

#pragma mark -

- (void)createTableByApp {
    // NOTE: create table owned by App. Overwrite me
}

- (NSString *)qureyOfCreateTable:(NSString *)tableName {
    if ([tableName isEqualToString:kTablePlayer]) {
		return @"(ID NUMERIC PRIMARY KEY AUTOINCREMENT, name TEXT, usicOn NUMERIC, soundOn NUMERIC)";
	}
    return nil;
}

- (void)loadData {
    // NOTE: load data. Overwrite me
}

- (void)saveData {
    // NOTE: save data. Overwrite me
}

- (void)resetData {
	// NOTE: reset data. Overwrite me
}

@end

#pragma mark - == GPS == -

@implementation GPS

@synthesize requestFinish, requestFail;
@synthesize coordinate, fullAddress, streetNumber, route, city, province, postalCode, country;

SYNTHESIZE_SINGLETON_FOR_CLASS(GPS);

+ (BOOL)isEnabel {
    return [CLLocationManager locationServicesEnabled];
}

- (id)init {
    if ((self = [super init])) {
        location = [[CLLocationManager alloc] init];
        location.delegate = self;
        location.distanceFilter = 100;
        location.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
        
        getCityNext = 0;
        requestFinish = NO;
        requestFail = NO;
        refreshTime = [[NSDate alloc] initWithTimeIntervalSinceNow:0];
#ifdef LOCATION_WITH_MAP
        jexMapView = [[MKMapView alloc] initWithFrame:CGRectMake(0, 0, 480, 320)];
        jexMapView.mapType = MKMapTypeStandard;
        jexMapView.showsUserLocation = YES;
        jexMapView.delegate = self;
#endif
    }
    return self;
}

- (void)dealloc {
    RELEASE(refreshTime);
    RELEASE(fullAddress);
    RELEASE(streetNumber);
    RELEASE(route);
    RELEASE(city);
    RELEASE(province);
    RELEASE(postalCode);
    RELEASE(country);
#ifdef LOCATION_WITH_MAP
    RELEASE(jexMapView);
#endif
    [super dealloc];
}

- (void)refresh:(BOOL)getCity {
    if (location && ([refreshTime timeIntervalSinceNow] <= 0
                     || (FLOAT_EQUAL(coordinate.latitude, 0) && FLOAT_EQUAL(coordinate.longitude, 0)))) {
        getCityNext = (getCity ? 1 : 0);
        requestFinish = NO;
        requestFail = NO;
        
        [location startUpdatingLocation];
    }
}

- (void)requestForCity {
#ifdef GPS_LOCAL
    NSString * urlString = [NSString stringWithFormat:@"http://maps.googleapis.com/maps/api/geocode/json?latlng=%f,%f&sensor=true",
                            coordinate.latitude, coordinate.longitude];
    NSURL * requestURL = [NSURL URLWithString:[urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    NSURLRequest * geocodingRequest=[NSURLRequest requestWithURL:requestURL
                                                     cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                 timeoutInterval:60.0];
    
    // NOTE: create connection and start downloading data
    NSURLConnection * connection = [[NSURLConnection alloc] initWithRequest:geocodingRequest delegate:self];
    if (connection) {
        receivedData = [[NSMutableData data] retain];
        getCityNext = 2;
    } else {
        NSLog(@"Request for city fail");
    }
#else
    getCityNext = 2;
    requestFinish = YES;
#endif
}

/*!
 @function
 @abstract   忽略“省”，“市”
 @return     void
 */
- (void)ignoreProvinceName {
    if ([province hasSuffix:@"省"] || [province hasSuffix:@"市"]) {
        province = [[province substringWithRange:NSMakeRange(0, [province length] - 1)] copy];
    }
}

- (NSString *)provinceAndCity {
    return [NSString stringWithFormat:@"%@ %@", province, city];
}

#pragma mark -

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
    NSLog(@"GPS Location: {%f, %f}", newLocation.coordinate.latitude, newLocation.coordinate.longitude);
#ifdef LOCATION_WITH_MAP
    jexMapView.showsUserLocation = YES;
#else
    coordinate = newLocation.coordinate;
    if ([CURRENT_DEVICE isSimulator]) {
        coordinate.latitude = 23.129163;
        coordinate.longitude = 113.264435;
    }
    if (getCityNext > 0) {
        if (getCityNext == 1) {
            [self requestForCity];
        }
    } else {
        requestFinish = YES;
    }
    [location stopUpdatingLocation];
    RELEASE(refreshTime);
    refreshTime = [[NSDate alloc] initWithTimeIntervalSinceNow:REFRESH_INTERVAL];
#endif
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error{
	NSLog(@"Failed to find location!");
    requestFail = YES;
    requestFinish = YES;
}

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation {
    NSLog(@"Map Location: {%f, %f}", userLocation.location.coordinate.latitude, userLocation.location.coordinate.longitude);
    coordinate = userLocation.location.coordinate;
    if ([CURRENT_DEVICE isSimulator]) {
        coordinate.latitude = 23.129163;
        coordinate.longitude = 113.264435;
    }
    if (getCityNext > 0) {
        if (getCityNext == 1) {
            [self requestForCity];
        }
    } else {
        requestFinish = YES;
    }
    [location stopUpdatingLocation];
    RELEASE(refreshTime);
    refreshTime = [[NSDate alloc] initWithTimeIntervalSinceNow:REFRESH_INTERVAL];
    jexMapView.showsUserLocation = NO;
}

- (void)mapView:(MKMapView *)mapView didFailToLocateUserWithError:(NSError *)error {
    NSLog(@"Failed to locate user!");
    requestFail = YES;
    requestFinish = YES;
    jexMapView.showsUserLocation = NO;
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    [receivedData setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [receivedData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    NSLog(@"Connection failed! Error - %@ %@",
          [error localizedDescription], [[error userInfo] objectForKey:NSURLErrorFailingURLStringErrorKey]);
    RELEASE(connection);
    RELEASE(receivedData);
    requestFail = YES;
    requestFinish = YES;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    NSDictionary * resultDict = [JSON_READ deserializeAsDictionary:receivedData error:nil];
	NSString * status = [resultDict valueForKey:@"status"];
	if ([status isEqualToString:@"OK"]) {
		// NOTE: get first element as array
		NSArray * firstResultAddress = [[[resultDict objectForKey:@"results"] objectAtIndex:0] objectForKey:@"address_components"];
		streetNumber = [JexCommon addressComponent:@"street_number" inAddressArray:firstResultAddress ofType:@"long_name"];
		route = [JexCommon addressComponent:@"route" inAddressArray:firstResultAddress ofType:@"long_name"];
		city = [JexCommon addressComponent:@"locality" inAddressArray:firstResultAddress ofType:@"long_name"];
		province = [JexCommon addressComponent:@"administrative_area_level_1" inAddressArray:firstResultAddress ofType:@"short_name"];
		postalCode = [JexCommon addressComponent:@"postal_code" inAddressArray:firstResultAddress ofType:@"short_name"];
		country = [JexCommon addressComponent:@"country" inAddressArray:firstResultAddress ofType:@"long_name"];
        
	} else {
		NSLog(@"Connection failed: %@", status);
        requestFail = YES;
	}
    requestFinish = YES;
}

@end

#pragma mark - == IAP == -

@implementation IAP

@synthesize completeTrans, failedTrans, restoreTrans;
@synthesize delegate, verifyRecepitMode;
@dynamic paymentObserver;

SYNTHESIZE_SINGLETON_FOR_CLASS(IAP);

- (id)init {
	if ((self = [super init])) {
        completeTrans = [[NSMutableArray alloc] init];
        failedTrans = [[NSMutableArray alloc] init];
        restoreTrans = [[NSMutableArray alloc] init];
        [self setPaymentObserver:self];
	}
	return self;
}

- (void)dealloc {
    RELEASE(completeTrans);
    RELEASE(failedTrans);
    RELEASE(restoreTrans);
    
    [super dealloc];
}

- (id <SKPaymentTransactionObserver>)paymentObserver {
    return paymentObserver;
}
- (void)setPaymentObserver:(id <SKPaymentTransactionObserver>)observer {
    if (paymentObserver) {
        [[SKPaymentQueue defaultQueue] removeTransactionObserver:paymentObserver];
    }
    RELEASE(paymentObserver);
    paymentObserver = [observer retain];
    [[SKPaymentQueue defaultQueue] addTransactionObserver:paymentObserver];
}

#pragma mark - == SKPaymentTransactionObserver == -

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions {
	for (SKPaymentTransaction * transaction in transactions) {
        switch (transaction.transactionState) {
            case SKPaymentTransactionStatePurchased:
                [self completeTransaction:transaction];
                break;
            case SKPaymentTransactionStateFailed:
                [self failedTransaction:transaction];
                break;
            case SKPaymentTransactionStateRestored:
                [self restoreTransaction:transaction];
            default:
                break;
        }
    }
}

- (void)completeTransaction:(SKPaymentTransaction *)transaction {
    NSLog(@"Purchase Successful");
	[self recordTransaction:transaction withStatus:0];
    [self provideContent:transaction.payment.productIdentifier];
    switch (verifyRecepitMode) {
        case kIAPVerifyRecepitModeNone:
            [delegate didCompleteTransaction:transaction.payment.productIdentifier];
            break;
        case kIAPVerifyRecepitModeDevice:
            [self verifyReceipt:transaction];
            break;
        case kIAPVerifyRecepitModeServer:
            [delegate verifyReceipt:transaction];
            break;
        default:
            break;
    }
	[[SKPaymentQueue defaultQueue] finishTransaction:transaction];
}

- (void)restoreTransaction:(SKPaymentTransaction *)transaction {
    NSLog(@"Restore Transaction");
    [self recordTransaction:transaction withStatus:1];
    [self provideContent:transaction.originalTransaction.payment.productIdentifier];
	[delegate didRestoreTransaction:transaction.payment.productIdentifier];
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
}

- (void)failedTransaction:(SKPaymentTransaction *)transaction {
    NSLog(@"Failed Transaction");
	[self recordTransaction:transaction withStatus:2];
	[delegate didFailedTransaction:transaction.payment.productIdentifier];
	[[SKPaymentQueue defaultQueue] finishTransaction:transaction];
}

#pragma mark -

- (void)recordTransaction:(SKPaymentTransaction *)transaction withStatus:(int)status {
	switch (status) {
        case 0:
            [completeTrans addObject:transaction];
            break;
        case 1:
            [restoreTrans addObject:transaction];
            break;
        case 2:
            [failedTrans addObject:transaction];
            break;
            
        default:
            break;
    }
}

- (void)provideContent:(NSString *)productIdentifier {
    
}

#pragma mark -

- (void)requestProductData:(NSString *)proIdentifier {
    if ([SKPaymentQueue canMakePayments]) {
        productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithObject:proIdentifier]];
		productsRequest.delegate = self;
		[productsRequest start];
    }
}

- (void)requestProductsData:(NSArray *)proIdentifiers {
	NSSet * sets = [NSSet setWithArray:proIdentifiers];
    productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:sets];
    productsRequest.delegate = self;
    [productsRequest start];
}

#pragma mark - == SKProductsRequestDelegate == -

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
    NSArray * products = response.products;
	[delegate didReceivedProducts:products];
	[productsRequest release];
}

- (void)addPayment:(NSString *)productIdentifier {
    if ([SKPaymentQueue canMakePayments]) {
        SKPayment * payment = [SKPayment paymentWithProductIdentifier:productIdentifier];
        [[SKPaymentQueue defaultQueue] addPayment:payment];
    }
}

- (void)verifyReceipt:(SKPaymentTransaction *)transaction {
	// TODO: verify server
    /*
     networkQueue = [ASINetworkQueue queue];
     [networkQueue retain];
     NSURL * verifyURL = [NSURL URLWithString:IAP_URL];
     ASIHTTPRequest * vryRequest = [[ASIHTTPRequest alloc] initWithURL:verifyURL];
     [vryRequest setRequestMethod: @"POST"];
     [vryRequest setDelegate:self];
     [vryRequest setDidFinishSelector:@selector(didFinishVerify:)];
     [vryRequest addRequestHeader:@"Content-Type" value:@"application/json"];
     
     NSString * recepit = [GTMBase64 stringByEncodingData:transaction.transactionReceipt];
     NSDictionary * data = [NSDictionary dictionaryWithObjectsAndKeys:recepit, @"receipt-data", nil];
     [vryRequest appendPostData:[data JSONData]];
     [networkQueue addOperation:vryRequest];
     [networkQueue go];
     */
}

/**
 *	Verify server finish
 *
 *	@param request HTTPRequest
 */
/*
 - (void)didFinishVerify:(ASIHTTPRequest *)request {
 NSString * response = [request responseString];
 NSDictionary * jsonData = [NSDictionary dictionaryWithJSONData:[response JSONData]];
 NSString * status = [jsonData objectForKey:@"status"];
 if ([status intValue] == 0) {
 NSDictionary * receipt = [jsonData objectForKey:@"receipt"];
 NSString * productIdentifier = [receipt objectForKey:@"product_id"];
 [delegate didCompleteTransactionAndVerifySucceed:productIdentifier];
 } else {
 NSString * exception = [jsonData objectForKey:@"exception"];
 [delegate didCompleteTransactionAndVerifyFailed:exception];
 }
 }
 */
@end

#pragma mark - == JexComm_ext == -

@implementation JexComm_ext

@end

//
//  MobiAPIEndpoints.h
//  MobiPubSDK
//
//  Created by 刘峰 on 2020/6/23.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#define Mobi_API_PATH_AD_REQUEST @"/mbid"

@interface MobiAPIEndpoints : NSObject

@property (nonatomic, copy, class) NSString *baseHostname;
@property (nonatomic, copy, readonly, class) NSString *baseURL;

+ (void)setUsesHTTPS:(BOOL)usesHTTPS;
+ (NSURLComponents *)baseURLComponentsWithPath:(NSString *)path;

@end

NS_ASSUME_NONNULL_END

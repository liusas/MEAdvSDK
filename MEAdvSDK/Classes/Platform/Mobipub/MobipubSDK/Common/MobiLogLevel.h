//
//  MobiLogLevel.h
//  MobiPubSDK
//
//  Created by 刘峰 on 2020/6/29.
//

#import <Foundation/Foundation.h>

/**
 SDK logging level. The "MPB" prefix is used instead of "MP" to avoid namespace collision.
 @remark Lower values equate to more detailed logs.
 */
typedef NS_ENUM(NSUInteger, MobiLogLevel) {
    MobiLogLevelDebug = 20,
    MobiLogLevelInfo  = 30,
    MobiLogLevelNone  = 70
};

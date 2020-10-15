//
//  MobiRealTimeTimer.h
//
//  Copyright 2018-2020 Twitter, Inc.
//  Licensed under the MoPub SDK License Agreement
//  http://www.mopub.com/legal/sdk-license-agreement/
//

#import <UIKit/UIKit.h>

/***
 * MobiRealTimeTimer is a class meant for situations in which one may want to disaptch an event for later without
 * any regard for application state. Backgrounding and suspension will not affect time keeping. MobiRealTimeTimer will NOT
 * fire while the application is backgrounded or suspended, but will fire immediately upon foregrounding if the
 * application is not foregrounded when the time interval elapses.
 *
 * Note: MobiRealTimeTimer uses NSTimer as a base and as such perfect accuracy is not guaranteed.
 ***/

@interface MobiRealTimeTimer : NSObject

// Initializer which takes in a time interval (from when `scheduleNow` is called) and a block to execute when firing.
- (instancetype)initWithInterval:(NSTimeInterval)interval
                           block:(void(^)(MobiRealTimeTimer *))block NS_DESIGNATED_INITIALIZER;

// Returns `YES` if the timer is currently keeping time; `NO` if it's waiting to be scheduled.
@property (nonatomic, assign, readonly) BOOL isScheduled;

// Schedules the MobiRealTimeTimer instance to fire at `interval` seconds from now. Calling `scheduleNow` while
// `isScheduled` is set to `YES` will do nothing.
- (void)scheduleNow;

// Executes `block` and stops all time keeping.
- (void)fire;

// Stops all time keeping without executing anything.
- (void)invalidate;

// Use of `init` is not supported.
- (instancetype)init NS_UNAVAILABLE;

@end

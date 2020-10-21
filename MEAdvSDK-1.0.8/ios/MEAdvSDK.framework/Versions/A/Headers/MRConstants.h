//
//  MRConstants.h
//
//  Copyright 2018-2020 Twitter, Inc.
//  Licensed under the MoPub SDK License Agreement
//  http://www.mopub.com/legal/sdk-license-agreement/
//

enum {
    MRAdViewStateHidden,
    MRAdViewStateDefault,
    MRAdViewStateExpanded,
    MRAdViewStateResized
};
typedef NSUInteger MRAdViewState;

enum {
    MRAdViewPlacementTypeInline,//banner 广告
    MRAdViewPlacementTypeInterstitial//插屏广告
};
typedef NSUInteger MRAdViewPlacementType;

extern NSString *const kOrientationPropertyForceOrientationPortraitKey;
extern NSString *const kOrientationPropertyForceOrientationLandscapeKey;
extern NSString *const kOrientationPropertyForceOrientationNoneKey;
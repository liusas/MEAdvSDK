typedef NS_ENUM(NSInteger, MobiPubDisplayAgentType) {
    /**
     Use in-app views for display agent without escaping the app. @c SFSafariViewController is used
     for web browsing, and @c SKStoreProductViewController is used for supported App Store links.
     */
    MobiPubDisplayAgentTypeInApp = 0,

    /**
     Use the iOS Native Safari browser app for display agent.
     */
    MobiPubDisplayAgentTypeNativeSafari,
};

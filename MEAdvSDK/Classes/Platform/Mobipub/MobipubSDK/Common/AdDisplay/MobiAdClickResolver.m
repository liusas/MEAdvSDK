//
//  MobiAdClickResolver.m
//  MobiPubSDK
//
//  Created by 刘峰 on 2020/7/13.
//

#import "MobiAdClickResolver.h"
#import "NSURL+MPAdditions.h"
#import <WebKit/WebKit.h>
#import <StoreKit/StoreKit.h>
#import "MobiURLRequest.h"
#import "MobiHTTPNetworkSession.h"
#import "NSHTTPURLResponse+MPAdditions.h"
#import "MPAdDestinationDisplayAgent.h"

@interface MobiAdClickResolver ()

@property (nonatomic, copy) NSDictionary *resolveDic;
@property (nonatomic, strong) NSURL *currentURL;
@property (nonatomic, copy) MobiAdClickResolverCompletionBlock completion;
@property (nonatomic, strong) NSURLSessionTask *task;

@end

@implementation MobiAdClickResolver

+ (instancetype)resolverWithDict:(NSDictionary *)resolveDic completion:(MobiAdClickResolverCompletionBlock)completion {
    return [[MobiAdClickResolver alloc] initWithDict:resolveDic completion:completion];
}

- (instancetype)initWithDict:(NSDictionary *)resolveDic completion:(MobiAdClickResolverCompletionBlock)completion {
    self = [super init];
    if (self) {
        _resolveDic = [resolveDic copy];
        _completion = [completion copy];
    }
    return self;
}

- (void)start {
    [self.task cancel];

    self.currentURL = [NSURL URLWithString:self.resolveDic[@"curl"]];
    NSError *error = nil;
    MPURLActionInfo *info = [self actionInfoFromDict:self.resolveDic error:&error];
    
    if (info) {
        [self safeInvokeAndNilCompletionBlock:info error:nil];
    } else if ([self shouldOpenWithInAppWebBrowser]) {
        NSURL *URL = [NSURL URLWithString:self.resolveDic[@"curl"]];
        info = [MPURLActionInfo infoWithURL:URL webViewBaseURL:self.currentURL];
        [self safeInvokeAndNilCompletionBlock:info error:nil];
    } else if (error) {
        [self safeInvokeAndNilCompletionBlock:nil error:error];
    } else {
        NSURL *URL = [NSURL URLWithString:self.resolveDic[@"curl"]];
        MobiURLRequest *request = [[MobiURLRequest alloc] initWithURL:URL];
        self.task = [self httpTaskWithRequest:request];
    }
}

- (NSURLSessionTask *)httpTaskWithRequest:(MobiURLRequest *)request {
    __weak __typeof__(self) weakSelf = self;
    NSURLSessionTask * task = [MobiHTTPNetworkSession startTaskWithHttpRequest:request responseHandler:^(NSData * _Nonnull data, NSHTTPURLResponse * _Nonnull response) {
        __typeof__(self) strongSelf = weakSelf;

        // Set the response content type
        NSStringEncoding responseEncoding = NSUTF8StringEncoding;
        NSDictionary *headers = [response allHeaderFields];
        NSString *contentType = [headers objectForKey:kMoPubHTTPHeaderContentType];
        if (contentType != nil) {
            responseEncoding = [response stringEncodingFromContentType:contentType];
        }

        NSURL *URL = [NSURL URLWithString:strongSelf.resolveDic[@"curl"]];
        NSString *responseString = [[NSString alloc] initWithData:data encoding:responseEncoding];
        MPURLActionInfo *info = [MPURLActionInfo infoWithURL:URL HTTPResponseString:responseString webViewBaseURL:strongSelf.currentURL];
        [strongSelf safeInvokeAndNilCompletionBlock:info error:nil];

    } errorHandler:^(NSError * _Nonnull error) {
        __typeof__(self) strongSelf = weakSelf;
        [strongSelf safeInvokeAndNilCompletionBlock:nil error:error];
    } shouldRedirectWithNewRequest:^BOOL(NSURLSessionTask * _Nonnull task, NSURLRequest * _Nonnull newRequest) {
        __typeof__(self) strongSelf = weakSelf;

        // First, check to see if the redirect URL matches any of our suggested actions.
        NSError * actionInfoError = nil;
        
        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:strongSelf.resolveDic];
        dict[@"curl"] = newRequest.URL.absoluteString;
        strongSelf.resolveDic = [NSDictionary dictionaryWithDictionary:dict];
        MPURLActionInfo * info = [strongSelf actionInfoFromDict:strongSelf.resolveDic error:&actionInfoError];

        if (info) {
            [task cancel];
            [strongSelf safeInvokeAndNilCompletionBlock:info error:nil];
            return NO;
        } else {
            // The redirected URL didn't match any actions, so we should continue with loading the URL.
            strongSelf.currentURL = newRequest.URL;
            return YES;
        }
    }];

    return task;
}

- (void)cancel {
    
}

- (void)safeInvokeAndNilCompletionBlock:(MPURLActionInfo *)info error:(NSError *)error
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.completion != nil) {
            self.completion(info, error);
            self.completion = nil;
        }
    });
}


// MARK: - Hanlding Application/StoreKit Dict
- (MPURLActionInfo *)actionInfoFromDict:(NSDictionary *)resolveDic error:(NSError **)error {
    MPURLActionInfo *actionInfo = nil;
    
    if (resolveDic == nil) {
        if (error) {
            *error = [NSError errorWithDomain:@"mobi.resolver.error" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"resolve dic is nil"}];
        }
        return nil;
    }
    
    NSInteger ctype = [resolveDic[@"ctype"] integerValue];
    switch (ctype) {
        case 1: { // App Store
            NSURL *URL = [NSURL URLWithString:resolveDic[@"curl"]];
            NSDictionary * storeKitParameters = [self appStoreProductParametersForURL:URL];
            if (storeKitParameters != nil) {
                actionInfo = [MPURLActionInfo infoWithURL:URL iTunesStoreParameters:storeKitParameters iTunesStoreFallbackURL:URL];
            }
        }
            break;
        case 2: { // Browser
            NSURL *URL = [NSURL URLWithString:resolveDic[@"curl"]];
            actionInfo = [MPURLActionInfo infoWithURL:URL safariDestinationURL:URL];
        }
            break;
        case 3: { // webview
            NSURL *URL = [NSURL URLWithString:resolveDic[@"curl"]];
            actionInfo = [MPURLActionInfo infoWithURL:URL webViewBaseURL:URL];
        }
            break;
        case 4: { // Deeplink
            NSURL *cURL = [NSURL URLWithString:resolveDic[@"curl"]];
            NSURL *dURL = [NSURL URLWithString:resolveDic[@"durl"]];
            NSURL *wURL = [NSURL URLWithString:resolveDic[@"wurl"]];
            NSArray *dlinkTracks = [NSArray arrayWithArray:resolveDic[@"dlink_track"]];
            
            MPEnhancedDeeplinkRequest *request = [[MPEnhancedDeeplinkRequest alloc] initWithPrimaryURL:dURL originalURL:cURL fallbackURL:wURL primaryTrackingURLs:dlinkTracks fallbackTrackingURLs:nil];
            if (request) {
                actionInfo = [MPURLActionInfo infoWithURL:cURL enhancedDeeplinkRequest:request];
            } else {
                actionInfo = [MPURLActionInfo infoWithURL:cURL deeplinkURL:dURL];
            }
        }
            break;
            
        default: {
            NSURL *cURL = [NSURL URLWithString:resolveDic[@"curl"]];
            actionInfo = [MPURLActionInfo infoWithURL:cURL
            webViewBaseURL:self.currentURL];
        }
            break;
    }
    
    return actionInfo;
}

#pragma mark Identifying Application URLs

- (BOOL)URLShouldOpenInApplication:(NSURL *)URL
{
    return ![self URLIsHTTPOrHTTPS:URL] || [self URLPointsToAMap:URL];
}

- (BOOL)URLIsHTTPOrHTTPS:(NSURL *)URL
{
    return [URL.scheme isEqualToString:@"http"] || [URL.scheme isEqualToString:@"https"];
}

- (BOOL)URLHasDeeplinkPlusScheme:(NSURL *)URL
{
    return [[URL.scheme lowercaseString] isEqualToString:@"deeplink+"];
}

- (BOOL)URLPointsToAMap:(NSURL *)URL
{
    return [URL.host hasSuffix:@"maps.google.com"] || [URL.host hasSuffix:@"maps.apple.com"];
}

- (BOOL)URLIsAppleScheme:(NSURL *)URL
{
    // Definitely not an Apple URL scheme.
    if (![URL.host hasSuffix:@".apple.com"]) {
        return NO;
    }

    // Constant set of supported Apple Store subdomains that will be loaded into
    // SKStoreProductViewController. This is lazily initialized and limited to the
    // scope of this method.
    static NSSet * supportedStoreSubdomains = nil;
    if (supportedStoreSubdomains == nil) {
        supportedStoreSubdomains = [NSSet setWithArray:@[@"apps", @"books", @"itunes", @"music"]];
    }

    // Assumes that the Apple Store sub domains are of the format store-type.apple.com
    // At this point we are guaranteed at least 3 components from the previous ".apple.com"
    // check.
    NSArray * hostComponents = [URL.host componentsSeparatedByString:@"."];
    NSString * subdomain = hostComponents[0];

    return [supportedStoreSubdomains containsObject:subdomain];
}

#pragma mark Extracting StoreItem Identifiers

- (NSDictionary *)appStoreProductParametersForURL:(NSURL *)URL
{
    // Definitely not an Apple URL scheme. Don't bother to parse.
    if (![self URLIsAppleScheme:URL]) {
        return nil;
    }

    // Failed to parse out the URL into its components. Likely to be an invalid URL.
    NSURLComponents * urlComponents = [NSURLComponents componentsWithURL:URL resolvingAgainstBaseURL:YES];
    if (urlComponents == nil) {
        return nil;
    }

    // Attempt to parse out the item identifier.
    NSString * itemIdentifier = ({
        NSString * lastPathComponent = URL.path.lastPathComponent;
        NSString * itemIdFromQueryParameter = [URL.mp_queryAsDictionary objectForKey:@"id"];
        NSString * parsedIdentifier = nil;

        // Old style iTunes item identifiers are prefixed with "id".
        // Example: https://apps.apple.com/.../id923917775
        if ([lastPathComponent hasPrefix:@"id"]) {
            parsedIdentifier = [lastPathComponent substringFromIndex:2];
        }
        // Look for the item identifier as a query parameter in the URL.
        // Example: https://itunes.apple.com/...?id=923917775
        else if (itemIdFromQueryParameter != nil) {
            parsedIdentifier = itemIdFromQueryParameter;
        }
        // Newer style Apple Store identifiers are just the last path component.
        // Example: https://music.apple.com/.../1451047660
        else {
            parsedIdentifier = lastPathComponent;
        }

        // Check that the parsed item identifier doesn't exist or contains invalid characters.
        NSCharacterSet * nonIntegers = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
        if (parsedIdentifier.length > 0 && [parsedIdentifier rangeOfCharacterFromSet:nonIntegers].location != NSNotFound) {
            parsedIdentifier = nil;
        }

        parsedIdentifier;
    });

    // Item identifier is a required field. If it doesn't exist, there is no point
    // in continuing to parse the URL.
    if (itemIdentifier.length == 0) {
        return nil;
    }

    // Attempt parsing for the following StoreKit product keys:
    // SKStoreProductParameterITunesItemIdentifier      (required)
    // SKStoreProductParameterProductIdentifier         (not supported)
    // SKStoreProductParameterAdvertisingPartnerToken   (not supported)
    // SKStoreProductParameterAffiliateToken            (optional)
    // SKStoreProductParameterCampaignToken             (optional)
    // SKStoreProductParameterProviderToken             (not supported)
    //
    // Query parameter parsing according to:
    // https://affiliate.itunes.apple.com/resources/documentation/basic_affiliate_link_guidelines_for_the_phg_network/
    NSMutableDictionary * parameters = [NSMutableDictionary dictionaryWithCapacity:3];
    parameters[SKStoreProductParameterITunesItemIdentifier] = itemIdentifier;

    for (NSURLQueryItem * queryParameter in urlComponents.queryItems) {
        // OPTIONAL: Attempt parsing of SKStoreProductParameterAffiliateToken
        if ([queryParameter.name isEqualToString:@"at"]) {
            parameters[SKStoreProductParameterAffiliateToken] = queryParameter.value;
        }
        // OPTIONAL: Attempt parsing of SKStoreProductParameterCampaignToken
        else if ([queryParameter.name isEqualToString:@"ct"]) {
            parameters[SKStoreProductParameterCampaignToken] = queryParameter.value;
        }
    }

    return parameters;
}

#pragma mark - Identifying NSStringEncoding from NSURLResponse Content-Type header

- (NSStringEncoding)stringEncodingFromContentType:(NSString *)contentType
{
    NSStringEncoding encoding = NSUTF8StringEncoding;

    if (![contentType length]) {
//        MPLogInfo(@"Attempting to set string encoding from nil %@", kMoPubHTTPHeaderContentType);
        return encoding;
    }

    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"(?<=charset=)[^;]*" options:kNilOptions error:nil];

    NSTextCheckingResult *charsetResult = [regex firstMatchInString:contentType options:kNilOptions range:NSMakeRange(0, [contentType length])];
    if (charsetResult && charsetResult.range.location != NSNotFound) {
        NSString *charset = [contentType substringWithRange:[charsetResult range]];

        // ensure that charset is not deallocated early
        CFStringRef cfCharset = (CFStringRef)CFBridgingRetain(charset);
        CFStringEncoding cfEncoding = CFStringConvertIANACharSetNameToEncoding(cfCharset);
        CFBridgingRelease(cfCharset);

        if (cfEncoding == kCFStringEncodingInvalidId) {
            return encoding;
        }
        encoding = CFStringConvertEncodingToNSStringEncoding(cfEncoding);
    }

    return encoding;
}

#pragma mark - Check if it's necessary to handle the clickthrough URL outside of a web browser
// There are two types of clickthrough URL sources: from webviews and from non-web views.
// The ones from webviews start with (https|http)://ads.mopub.com/m/aclk
// For webviews, in order for a URL to be processed in a web browser, the redirect URL scheme needs to be http/https.
- (BOOL)shouldOpenWithInAppWebBrowser
{
    if (!self.currentURL) {
        return NO;
    }

    // If redirect URL isn't http/https, do not open it in a browser. It is likely a deep link
    // or an Apple Store scheme that will need special parsing.
    if (![self URLIsHTTPOrHTTPS:self.currentURL] || [self URLIsAppleScheme:self.currentURL]) {
        return NO;
    }

    // ADF-4215: If this trailing return value should be changed, check whether App Store redirection
    // links will end up showing the App Store UI in app (expected) or escaping the app to open the
    // native iOS App Store (unexpected).
    return [MPAdDestinationDisplayAgent shouldDisplayContentInApp];
}

@end

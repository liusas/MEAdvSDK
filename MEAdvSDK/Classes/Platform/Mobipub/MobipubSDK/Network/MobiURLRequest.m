//
//  MobiURLRequest.m
//  MobiPubSDK
//
//  Created by 刘峰 on 2020/6/24.
//

#import "MobiURLRequest.h"
#import "MobiURL.h"
#import "MobiAPIEndpoints.h"
#import "MPWebBrowserUserAgentInfo.h"

// All requests have a 10 second timeout.
const NSTimeInterval kRequestTimeoutInterval = 10.0;

/// 字符串转义,摘自AFNetwork,RFC3986文档规定，Url中只允许包含以下四种
/// 1. 英文字母（a-zA-Z）
/// 2. 数字（0-9）
/// 3. -_.~ 4个特殊字符
/// 4. 所有保留字符，RFC3986中指定了以下字符为保留字符(英文字符)
/// ! * ' ( ) ; : @ & = + $ , / ? # [ ]
/// @param string 需要转义的字符
NSString * MobiPercentEscapedStringFromString(NSString *string) {
    static NSString * const kAFCharactersGeneralDelimitersToEncode = @":#[]@";
    // does not include "?" or "/" due to RFC 3986 - Section 3.4
    static NSString * const kAFCharactersSubDelimitersToEncode = @"!$&'()*+,;=";
    
    NSMutableCharacterSet * allowedCharacterSet = [[NSCharacterSet URLQueryAllowedCharacterSet] mutableCopy];
    [allowedCharacterSet removeCharactersInString:[kAFCharactersGeneralDelimitersToEncode stringByAppendingString:kAFCharactersSubDelimitersToEncode]];
    
    // return [string stringByAddingPercentEncodingWithAllowedCharacters:allowedCharacterSet];
    
    static NSUInteger const batchSize = 50;
    
    NSUInteger index = 0;
    NSMutableString *escaped = @"".mutableCopy;
    
    while (index < string.length) {
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wgnu"
        NSUInteger length = MIN(string.length - index, batchSize);
#pragma GCC diagnostic pop
        NSRange range = NSMakeRange(index, length);
        
        // To avoid breaking up character sequences such as 👴🏻👮🏽
        range = [string rangeOfComposedCharacterSequencesForRange:range];
        
        NSString *substring = [string substringWithRange:range];
        NSString *encoded = [substring stringByAddingPercentEncodingWithAllowedCharacters:allowedCharacterSet];
        [escaped appendString:encoded];
        
        index += range.length;
    }
    
    return escaped;
}

/// 请求的参数键值对,以`field=value`形式呈现
@interface MobiQueryStringPair : NSObject

@property (nonatomic, strong) id field;
@property (nonatomic, strong) id value;

- (instancetype)initWithField:(id)field value:(id)value;

- (NSString *)URLEncodedStringValue;

@end

@implementation MobiQueryStringPair

- (instancetype)initWithField:(id)field value:(id)value {
    self = [super init];
    if (!self) {
        return nil;
    }

    self.field = field;
    self.value = value;

    return self;
}

/// 对字符编码,一般需要编码的字符都不适合传输,这里为字符进行编码
- (NSString *)URLEncodedStringValue {
    if (!self.value || [self.value isEqual:[NSNull null]]) {
        return MobiPercentEscapedStringFromString([self.field description]);
    } else {
        return [NSString stringWithFormat:@"%@=%@", MobiPercentEscapedStringFromString([self.field description]), MobiPercentEscapedStringFromString([self.value description])];
    }
}

@end

/// 声明我有这么两个函数,这个关键字兼容性更强而已,并无其他
FOUNDATION_EXPORT NSArray *MobiQueryStringPairsFromDictionary(NSDictionary *dictionary);
FOUNDATION_EXPORT NSArray *MobiQueryStringPairsFromKeyAndValue(NSString *key, id value);

/// 将字典型的请求参数转成特定格式字符串,如`userid=12345&token=123324325`
/// @param parameters 请求参数
NSString *MobiQueryStringFromParameters(NSDictionary *parameters) {
    NSMutableArray *mutablePairs = [NSMutableArray array];
    for (MobiQueryStringPair *pair in MobiQueryStringPairsFromDictionary(parameters)) {
        [mutablePairs addObject:[pair URLEncodedStringValue]];
    }
    
    return [mutablePairs componentsJoinedByString:@"&"];
}

/// 从字典中获取MobiQueryStringPair类型的数组,即多个`key=value`形式的元素
/// @param dictionary 拥有请求参数的键值对
NSArray *MobiQueryStringPairsFromDictionary(NSDictionary *dictionary) {
    return MobiQueryStringPairsFromKeyAndValue(nil, dictionary);
}

/// 这是一个递归函数,递归处理请求参数,将其变成`key=value`或`key[nestkey]=value`元素组成的数组
/// @param key 该层参数上一层的参数,比如字典套字典,
/// {user:{id:1234, token:12345}},经过转换后变成user[id]=1234,user[token]=12345这样的元素
/// @param value 参数的value值
NSArray *MobiQueryStringPairsFromKeyAndValue(NSString *key, id value) {
    // 存放`key=value`MobiQueryStringPair形式元素的数组
    NSMutableArray *mutableQueryStringComponents = [NSMutableArray array];
    // 若value为集合类,则对集合类进行一次排序,确保queryString中的元素数据一致,为了应对反序列化可能引发歧义的序列,比如array和dictionary
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"description" ascending:YES selector:@selector(compare:)];

    if ([value isKindOfClass:[NSDictionary class]]) {
        NSDictionary *dictionary = value;
        for (id nestedKey in [dictionary.allKeys sortedArrayUsingDescriptors:@[ sortDescriptor ]]) {
            id nestedValue = dictionary[nestedKey];
            if (nestedValue) {
                [mutableQueryStringComponents addObjectsFromArray:MobiQueryStringPairsFromKeyAndValue((key ? [NSString stringWithFormat:@"%@[%@]", key, nestedKey] : nestedKey), nestedValue)];
            }
        }
    } else if ([value isKindOfClass:[NSArray class]]) {
        NSArray *array = value;
        for (id nestedValue in array) {
            [mutableQueryStringComponents addObjectsFromArray:MobiQueryStringPairsFromKeyAndValue([NSString stringWithFormat:@"%@[]", key], nestedValue)];
        }
    } else if ([value isKindOfClass:[NSSet class]]) {
        NSSet *set = value;
        for (id obj in [set sortedArrayUsingDescriptors:@[ sortDescriptor ]]) {
            [mutableQueryStringComponents addObjectsFromArray:MobiQueryStringPairsFromKeyAndValue(key, obj)];
        }
    } else {
        [mutableQueryStringComponents addObject:[[MobiQueryStringPair alloc] initWithField:key value:value]];
    }

    return mutableQueryStringComponents;
}

@interface MobiURLRequest()

/// 请求参数
@property (nonatomic, strong) NSMutableDictionary *parameters;

@end

@implementation MobiURLRequest

- (instancetype)initWithURL:(NSURL *)URL {
    // 参数
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    // 请求方法
    NSString *HTTPMethod = @"GET";
    // 请求头
    NSMutableDictionary *HTTPHeaders = [[NSMutableDictionary alloc] init];
    
    if ([URL isKindOfClass:[MobiURL class]]) {
        MobiURL *mobiURL = (MobiURL *)URL;
        // 请求参数
        if ([NSJSONSerialization isValidJSONObject:mobiURL.parameters]) {
            params = mobiURL.parameters;
        } else {
//            MPLogInfo(@"🚨 POST data failed to serialize into JSON:\n%@", mpUrl.postData);
        }
        
        // 请求方法
        HTTPMethod = mobiURL.HTTPMethod;
        
        // 请求头
        HTTPHeaders = mobiURL.HTTPHeaders;
    }
    
    if (self = [super initWithURL:URL]) {
        [self setHTTPShouldHandleCookies:NO];
        [self setValue:MPWebBrowserUserAgentInfo.userAgent forHTTPHeaderField:@"User-Agent"];
        [self setCachePolicy:NSURLRequestReloadIgnoringCacheData];
        [self setTimeoutInterval:kRequestTimeoutInterval];
        
        // 设置请求头
        [HTTPHeaders enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            if (![self valueForHTTPHeaderField:key]) {
                [self setValue:obj forHTTPHeaderField:key];
            }
        }];
        
        // 将字典形式的请求参数,转化成RFC3986规定的形式
        NSString *query = nil;
        if (params) {
            query = MobiQueryStringFromParameters(params);
        }
        
        if ([HTTPMethod isEqualToString:@"GET"]) {
            if (query && query.length > 0) {
                self.URL = [NSURL URLWithString:[[URL absoluteString] stringByAppendingFormat:URL.query ? @"&%@" : @"?%@", query]];
            }
        } else {
            // POST请求
            // #2864: an empty string is a valid x-www-form-urlencoded payload
            if (!query) {
                query = @"";
            }
            if (![self valueForHTTPHeaderField:@"Content-Type"]) {
                [self setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
            }
            [self setHTTPBody:[query dataUsingEncoding:NSUTF8StringEncoding]];
        }

    }
    
    return self;
}

+ (MobiURLRequest *)requestWithURL:(NSURL *)URL {
    return [[MobiURLRequest alloc] initWithURL:URL];
}


@end

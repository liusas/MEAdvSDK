//
//  MEAdMemoryCache.m
//  MEAdvSDK
//
//  Created by 刘峰 on 2019/12/12.
//

#import "MEAdMemoryCache.h"
#import "MEConfigManager.h"
#import <pthread.h>

/// 信息流广告失效时间设置为30分钟,这里取得毫秒
#define kFeedViewExpireTime 30.0*60.0*1000

/// 缓存节点
@interface MEAdCacheNode : NSObject {
    @package
    __unsafe_unretained MEAdCacheNode *_prev; // 双向链表的前驱节点，指向上一个节点, 需要手动释放
    __unsafe_unretained MEAdCacheNode *_next; // 双向链表的后继节点，指向下一个节点, 需要手动释放
    id _key;///节点key
    id _value;///节点value
    NSTimeInterval _time;/// 渲染的时间,超过半个小时则判定为失效节点
    BOOL _isUsed;/// 使用过,也属于失效节点
}

@end

@implementation MEAdCacheNode
@end

@interface MEAdCacheNodeMap : NSObject {
    @package
    CFMutableArrayRef _array;
    MEAdCacheNode *_head;
    MEAdCacheNode *_tail;
    /// 缓存key-value的总个数
    NSUInteger _totalCount;
}

- (void)insertNodeAtHead:(MEAdCacheNode *)node;
- (void)bringNodeToHead:(MEAdCacheNode *)node;
- (void)removeNode:(MEAdCacheNode *)node;
- (MEAdCacheNode *)removeTailNode;
- (void)removeAll;

@end

@implementation MEAdCacheNodeMap

- (instancetype)init {
    self = [super init];
    if (self) {
        _array = CFArrayCreateMutable(CFAllocatorGetDefault(), 0, &kCFTypeArrayCallBacks);
    }
    return self;
}

- (void)dealloc {
    CFRelease(_array);
}

- (void)insertNodeAtHead:(MEAdCacheNode *)node {
    CFArrayAppendValue(_array, (__bridge const void *)(node));
    _totalCount++;
    if (_head) {
        node->_next = _head;
        _head->_prev = node;
        _head = node;
    } else {
        _head = _tail = node;
    }
}

- (void)bringNodeToHead:(MEAdCacheNode *)node {
    if (_head == node) return;
    if (_tail == node) {
        _tail = node->_prev;
        _tail->_next = nil;
        node->_next = _head;
        node->_prev = nil;
        node = _head->_prev;
        _head = node;
    }
}

- (void)removeNode:(MEAdCacheNode *)node {
    for (int i = 0; i < CFArrayGetCount(_array); i++) {
        MEAdCacheNode *arrNode = CFArrayGetValueAtIndex(_array, i);
        if ([node isEqual:arrNode]) {
            CFArrayRemoveValueAtIndex(_array, i);
        }
    }

    _totalCount--;
    if (node->_next) node->_next->_prev = node->_prev;
    if (node->_prev) node->_prev->_next = node->_next;
    if (_head == node) _head = node->_next;
    if (_tail == node) _tail = node->_prev;
}

- (MEAdCacheNode *)removeTailNode {
    if (!_tail) return nil;
    MEAdCacheNode *tail = _tail;
    _totalCount--;
    
    CFArrayRemoveValueAtIndex(_array, _totalCount);
    
    if (_head == _tail) {
        _head = _tail = nil;
    } else {
        _tail = _tail->_prev;
        _tail->_next = nil;
    }
    return tail;
}

- (void)removeAll {
    _head = nil;
    _tail = nil;
    _totalCount = 0;
    
    if (CFArrayGetCount(_array) > 0) {
        CFMutableArrayRef arrHolder = _array;
        _array = CFArrayCreateMutable(CFAllocatorGetDefault(), 0, &kCFTypeArrayCallBacks);
        CFRelease(arrHolder);
    }
}

@end

/// 广告数据的内存缓存类
@interface MEAdMemoryCache () {
    pthread_mutex_t _lock;//线程锁
}

/// 穿山甲缓存
@property (nonatomic, strong) NSMutableDictionary *buadCache;
/// 广点通缓存
@property (nonatomic, strong) NSMutableDictionary *gdtCache;

@end

@implementation MEAdMemoryCache

/// 初始化
- (instancetype)init {
    self = [super init];
    if (self) {
        // 初始化穿山甲和广点通cache
        self.buadCache = [NSMutableDictionary dictionary];
        self.gdtCache = [NSMutableDictionary dictionary];
        _totalCount = 2;
        // 单位毫秒, 判断预加载的广告是否超过了30分钟
        _ageLimit = 30 * 60 * 1000.f;
        _autoTrimInterval = 20;
    }
    return self;
}

/// 判断缓存中是否存在key对应的广告数据
/// @param sceneId 广告的场景id
/// @param posid 广告位id
/// @param platformType 平台类型
- (BOOL)containsObjectWithSceneId:(NSString *)sceneId posId:(NSString *)posid platformType:(MEAdAgentType)platformType {
    MEAdCacheNodeMap *nodeMap = [self getNodeWithKey:sceneId platformType:platformType];
    pthread_mutex_lock(&_lock);
    BOOL contains = NO;
    if (nodeMap) {
        contains = [self getNodeWithNodeMap:nodeMap posid:posid] != nil ? YES : NO;
    }
    pthread_mutex_unlock(&_lock);
    return contains;
}

/// 添加广告数据到缓存
/// @param object 广告数据,应该是一个view
/// @param sceneId 广告的场景id
/// @param posid 广告位id
/// @param platformType 平台类型
- (void)setObject:(id)object forSceneId:(NSString *)sceneId posId:(NSString *)posid platformType:(MEAdAgentType)platformType {
    
    pthread_mutex_lock(&_lock);
    MEAdCacheNodeMap *nodeMap = [self getNodeWithKey:sceneId platformType:platformType];
    NSTimeInterval now = [NSDate date].timeIntervalSince1970;
    if (nodeMap) {
        // 找一下缓存是否有未失效和未使用的node
        MEAdCacheNode *node = [self getNodeWithNodeMap:nodeMap posid:posid];
        if (node) {
            // 若有,则更新这个node
            [nodeMap removeNode:node];
        }
        
        MEAdCacheNode *headNode = [MEAdCacheNode new];
        headNode->_time = now;
        headNode->_key = posid;
        headNode->_value = object;
        [nodeMap insertNodeAtHead:headNode];
    } else {
        nodeMap = [MEAdCacheNodeMap new];
        MEAdCacheNode *node = [MEAdCacheNode new];
        node->_time = now;
        node->_key = posid;
        node->_value = object;
        [nodeMap insertNodeAtHead:node];
    }
    
    if (platformType == MEAdAgentTypeBUAD) {
        [self.buadCache setObject:nodeMap forKey:sceneId];
    } else {
        [self.gdtCache setObject:nodeMap forKey:sceneId];
    }
    pthread_mutex_unlock(&_lock);
}

/// 根据广告场景id查找缓存中的广告数据
/// @param sceneId 广告的场景id
/// @param posid 广告位id
/// @param platformType 平台类型
- (nullable id)objectForSceneId:(NSString *)sceneId posId:(NSString *)posid platformType:(MEAdAgentType)platformType {
    pthread_mutex_lock(&_lock);
    MEAdCacheNodeMap *nodeMap = [self getNodeWithKey:sceneId platformType:platformType];
    if (!nodeMap) return nil;
    
    MEAdCacheNode *node = [self getNodeWithNodeMap:nodeMap posid:posid];
    node->_isUsed = YES;
    pthread_mutex_unlock(&_lock);
    return node ? node->_value : nil;
}

/// 删除场景id对应的广告数据
/// @param sceneId 广告的场景id
/// @param posid 广告位id
/// @param platformType 平台类型
- (void)removeObjectForSceneId:(NSString *)sceneId posId:(NSString *)posid platformType:(MEAdAgentType)platformType {
    pthread_mutex_lock(&_lock);
    MEAdCacheNodeMap *nodeMap = [self getNodeWithKey:sceneId platformType:platformType];
    MEAdCacheNode *node = [self getNodeWithNodeMap:nodeMap posid:posid];
    [nodeMap removeNode:node];
    pthread_mutex_unlock(&_lock);
}

/// 清空所有缓存
- (void)removeAllObject {
    pthread_mutex_lock(&_lock);
    for (MEAdCacheNodeMap *nodeMap in self.buadCache.allValues) {
        [nodeMap removeAll];
    }
    
    for (MEAdCacheNodeMap *nodeMap in self.gdtCache.allValues) {
        [nodeMap removeAll];
    }
    pthread_mutex_unlock(&_lock);
}

/// 循环修剪缓存
- (void)trimRecursively {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10.f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self trimInBackground];
        [self trimRecursively];
    });
}

/// 后台修剪缓存
- (void)trimInBackground {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        [self trimToAge:self->_ageLimit];
    });
}

/// 根据缓存最大限制个数修剪
/// @param countLimit 缓存最大限制个数
- (void)trimToCount:(NSUInteger)countLimit {
    
}

/// 根据周期修剪缓存,将过期广告删除,并拉取新广告
/// @param age 周期长度
- (void)trimToAge:(NSTimeInterval)age {
    
}

// MARK: Private

/// 根据key值从缓存取出包含node实例的map
/// @param key 场景id
- (MEAdCacheNodeMap *)getNodeWithKey:(NSString *)key platformType:(MEAdAgentType)platformType {
    if (platformType == MEAdAgentTypeBUAD) {
        return [self.buadCache objectForKey:key];
    }
    
    return [self.gdtCache objectForKey:key];
}

- (MEAdCacheNode *)getNodeWithNodeMap:(MEAdCacheNodeMap *)nodeMap posid:(NSString *)posid {
    MEAdCacheNode *node = nodeMap->_head;
    while (node) {
        if ([node->_key isEqualToString:posid]) {
            if ([NSDate date].timeIntervalSince1970 - node->_time > kFeedViewExpireTime) {
                // 大于半个小时,则属于失效信息流,需要删除
                MEAdCacheNode *tempNode = node;
                node = node->_next;
                [nodeMap removeNode:tempNode];
            } else if (node->_isUsed == YES) {
                if (nodeMap->_totalCount >= _totalCount) {
                    // 若个数超出限制,则删除缓存节点
                    MEAdCacheNode *tempNode = node;
                    node = node->_next;
                    [nodeMap removeNode:tempNode];
                } else {
                    node = node->_next;
                }
            } else {
                return node;
            }
        }
    }
    
    return nil;
}

@end

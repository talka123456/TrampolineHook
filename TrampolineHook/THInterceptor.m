//
//  THInterceptor.m
//  TrampolineHook
//
//  Created by z on 2020/4/25.
//  Copyright © 2020 SatanWoo. All rights reserved.
//

#import "THInterceptor.h"
#import "THSimplePageAllocator.h"
#import "THVariadicPageAllocator.h"

#define THInterceptorResultFail \
        [[THInterceptorResult alloc] initWithReplacedAddress:NULL state:THInterceptStateFailed]

@implementation THInterceptorResult

- (instancetype)initWithReplacedAddress:(IMP)address state:(THInterceptState)state
{
    self = [super init];
    if (self) {
        _replacedAddress = address;
        _state = state;
    }
    return self;
}

@end

@interface THInterceptor()
@property (nonatomic, strong) id<THDynamicAllocatable> pageAllactor;
@property (nonatomic, unsafe_unretained, readwrite) IMP redirectFunction;
@end

@implementation THInterceptor

- (instancetype)initWithRedirectionFunction:(IMP)redirectFunction
{
    self = [super init];
    if (self) {
        _redirectFunction = redirectFunction;
    }
    return self;
}

#pragma mark - Public API
/// function 是值被拦截的 function
- (THInterceptorResult *)interceptFunction:(IMP)function
{
    if (function == NULL) return THInterceptorResultFail;
    
    // allocateDynamicPageForFunction 开始是核心处理逻辑
    IMP jumpAddress = [self.pageAllactor allocateDynamicPageForFunction:function];
    if (!jumpAddress) {
        NSAssert(jumpAddress != NULL, @"[THInterceptor]::Allocate dynamic page failed");
        return THInterceptorResultFail;
    }
    
    return [[THInterceptorResult alloc] initWithReplacedAddress:jumpAddress
                                                          state:THInterceptStateSuccess];
}

#pragma mark - Getter
// 这里用映射+协议解决多态问题。

- (id<THDynamicAllocatable>)pageAllactor
{
    if (!_pageAllactor) {
        // 用 THSimplePageAllocator 初始化 pageAllactor 对象
        Class cls = [[self class] pageAllocatorClass];
        _pageAllactor =  [[cls alloc] initWithRedirectionFunction:self.redirectFunction];
    }
    return _pageAllactor;
}

+ (Class)pageAllocatorClass
{
    return [THSimplePageAllocator class];
}

@end


#pragma mark - THVariadicInterceptor Implementation
@implementation THVariadicInterceptor

- (instancetype)initWithRedirectionFunction:(IMP)redirectFunction
{
    return [super initWithRedirectionFunction:redirectFunction];
}

+ (Class)pageAllocatorClass
{
    return [THVariadicPageAllocator class];
}


@end


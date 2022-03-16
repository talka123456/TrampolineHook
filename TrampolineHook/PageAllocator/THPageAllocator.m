//
//  THPageAllocator.m
//  TrampolineHook
//
//  Created by z on 2020/5/19.
//  Copyright © 2020 SatanWoo. All rights reserved.
//

#import "THPageAllocator.h"
#import "THPageDefinition.h"

@interface THPageAllocator()
@property (nonatomic, unsafe_unretained, readwrite) IMP redirectionFunction;
@property (nonatomic, strong) NSMutableArray *dynamicPages;
@end

@implementation THPageAllocator

- (instancetype)initWithRedirectionFunction:(IMP)redirectFunction
{
    self = [super init];
    if (self) {
        _redirectFunction = redirectFunction;
    }
    return self;
}

/// function 是值被拦截的 function
- (IMP)allocateDynamicPageForFunction:(IMP)functionAdress
{
    if (!functionAdress) return NULL;
    
    // 读取一个动态页
    void *dynamicePage = [self fetchCandidiateDynamicPage];
    
    if (!dynamicePage) return NULL;
    
    // 生成桥的地址
    return [self replaceAddress:functionAdress inPage:dynamicePage];
}

#pragma mark - Abstract Function
- (void)configurePageLayoutForNewPage:(void *)newPage
{
    NSException *exception = [NSException exceptionWithName:@"com.satanwoo.pageallocator" reason:@"<configurePageLayoutForNewPage> must be override by subclass" userInfo:nil];
    [exception raise];
}

- (BOOL)isValidReusablePage:(void *)resuablePage
{
    NSException *exception = [NSException exceptionWithName:@"com.satanwoo.pageallocator" reason:@"<isValidReusablePage> must be override by subclass" userInfo:nil];
    [exception raise];
    
    return FALSE;
}

- (void *)templatePageAddress
{
    NSException *exception = [NSException exceptionWithName:@"com.satanwoo.pageallocator" reason:@"<templatePageAddress> must be override by subclass" userInfo:nil];
    [exception raise];
    
    return NULL;
}

- (IMP)replaceAddress:(IMP)functionAddress inPage:(void *)page
{
    NSException *exception = [NSException exceptionWithName:@"com.satanwoo.pageallocator" reason:@"<replaceAddress:inPage:> must be override by subclass" userInfo:nil];
    [exception raise];
    
    return NULL;
}

#pragma mark - Private
- (void *)fetchCandidiateDynamicPage
{
    // 最后一个 动态内存页 page 指针
    void *reusablePage = [[self.dynamicPages lastObject] pointerValue];
    
    // 校验是否可重用
    if (![self isValidReusablePage:reusablePage]) {
        //不可重用, 从模板对象地址处拷贝用于创建动态虚拟内存页
        void *toCopyAddress = [self templatePageAddress];
        if (!toCopyAddress) return NULL;
        
        // 创建新的动态内存页
        reusablePage = (void *)THCreateDynamicePage(toCopyAddress);
        if (!reusablePage) return NULL;
        
        // 配置新页偏移
        [self configurePageLayoutForNewPage:reusablePage];
        
        // 存储新的页，
        [self.dynamicPages addObject:[NSValue valueWithPointer:reusablePage]];
    }
    
    // 返回可用的 page
    return reusablePage;
}

#pragma mark - Getter
- (NSMutableArray *)dynamicPages
{
    if (!_dynamicPages) {
        _dynamicPages = @[].mutableCopy;
    }
    return _dynamicPages;
}


@end

//
//  THInterceptor.h
//  TrampolineHook
//
//  Created by z on 2020/4/25.
//  Copyright © 2020 SatanWoo. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
/// 状态枚举， 表示桥接是否成功
typedef NS_ENUM(NSUInteger, THInterceptState) {
    THInterceptStateSuccess = 0,
    THInterceptStateFailed  = 1
};

/// 返回的对象实体， 用于桥接后的其他操作。主要是状态属性和
@interface THInterceptorResult : NSObject
- (instancetype)init NS_UNAVAILABLE;
@property (nonatomic, unsafe_unretained, readonly) IMP replacedAddress; //!< 桥接后的 IMP
@property (nonatomic, readonly)                    THInterceptState state; //!< 桥接状态
@end


@interface THInterceptor : NSObject

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithRedirectionFunction:(IMP)redirectFunction;

@property (nonatomic, unsafe_unretained, readonly) IMP redirectFunction; //!< 重定向后的函数

/// 需要拦截的函数
/// @param function 函数 IMP 指针
- (THInterceptorResult *)interceptFunction:(IMP)function;
+ (Class)pageAllocatorClass;

@end


@interface THVariadicInterceptor : THInterceptor
- (instancetype)init NS_UNAVAILABLE;
@end

NS_ASSUME_NONNULL_END

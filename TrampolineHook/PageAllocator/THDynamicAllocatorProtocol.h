//
//  THDynamicAllocatorProtocol.h
//  TrampolineHook
//
//  Created by z on 2020/5/18.
//  Copyright © 2020 SatanWoo. All rights reserved.
//

#ifndef THDynamicAllocatorProtocol_h
#define THDynamicAllocatorProtocol_h
#import <Foundation/Foundation.h>

/// 遵循该协议的所有类都可以作为桥接器使用
@protocol THDynamicAllocatable <NSObject>
@required

- (instancetype)initWithRedirectionFunction:(IMP)redirectFunction;
- (IMP)allocateDynamicPageForFunction:(IMP)functionAdress;

@end


#endif /* THDynamicAllocatorProtocol_h */

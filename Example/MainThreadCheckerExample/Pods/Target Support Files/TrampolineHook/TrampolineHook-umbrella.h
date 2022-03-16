#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "THInterceptor.h"
#import "THPageDefinition.h"
#import "THDynamicAllocatorProtocol.h"
#import "THPageAllocator.h"
#import "THSimplePageAllocator.h"
#import "THVariadicPageAllocator.h"
#import "THPageDefinition_arm64.h"
#import "THPageVariadicContext_arm64.h"

FOUNDATION_EXPORT double TrampolineHookVersionNumber;
FOUNDATION_EXPORT const unsigned char TrampolineHookVersionString[];


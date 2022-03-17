//
//  THPageVariadicContext.h
//  TrampolineHook
//
//  Created by z on 2020/5/17.
//  Copyright © 2020 SatanWoo. All rights reserved.
//

#ifndef THPageVariadicContext_arm64_h
#define THPageVariadicContext_arm64_h

#import <Foundation/Foundation.h>

#if defined(__cplusplus)
extern "C" {
#endif

// No use. Just for easy understanding of the memory layout
// 分配堆空间时，内存布局结构内容。
typedef struct _THPageVariadicContext {
    int64_t gR[10];              // general registers x0-x8 + x13  8字节元素大小的数组，存储通用寄存器 10 * 8 = 80字节
    int64_t vR[16];              // float   registers q0-q7 8字节大小的数组 8 * 16 = 128字节， 存放浮点寄存器，由于浮点寄存器占 16 字节，所以 8 个开辟了 16 * 8内存空间。
    int64_t linkRegister;        // lr 存放 lr 8字节
    int64_t originIMPRegister;   // origin 存放原函数 IMP 8 字节
} THPageVariadicContext;

void THPageVariadicContextPre(void);
void THPageVariadicContextPost(void);
    
#ifdef __cplusplus
}
#endif


#endif /* THPageVariadicContext_arm64_h */

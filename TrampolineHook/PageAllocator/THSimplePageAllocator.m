//
//  THDynamicAllocator.m
//  TrampolineHook
//
//  Created by z on 2020/4/25.
//  Copyright © 2020 SatanWoo. All rights reserved.
//

#import "THSimplePageAllocator.h"
#import "THPageDefinition.h"

/// 定义全局符号 th_dynamic_page ，实现在对应汇编文件中。
FOUNDATION_EXTERN id th_dynamic_page(id, SEL);

#if defined(__arm64__)
#import "THPageDefinition_arm64.h"
/// THSimplePageInstructionCount代表 拦截器函数指令数，即 entry 指令数，需要和 TH_Page_arm64.s 中Entry 的指令数量对应。
static const int32_t THSimplePageInstructionCount = 32;
#else
#error x86_64 & arm64e to be supported
#endif

/// struct 数据结构映射虚拟内存页
/// THPageSize 由于对齐为 16kb 对齐， 所以大小为 0x4000
/// THSimplePageInstructionCount 为拦截器指令数，32 条，32 * 4字节 128 字节
/// THDynamicPageEntryGroup 定位为 2 * int32_t 8字节， 表示每次 hook 执行 entry 需要两条指令，即 保存 lr & bl entry
/// 计算方式为， （单页内存大小 - 函数指令数 * 指令大小（4 字节 == int32_t））/ 每次 hook 占用的指令大小（THDynamicPageEntryGroup）== 数据内存页可供存储的 hook 次数
/// THNumberOfDataPerSimplePage是不是 也是可以桥接次数的上限， 即只能 hook 这么多个函数？
static const size_t THNumberOfDataPerSimplePage = (THPageSize - THSimplePageInstructionCount * sizeof(int32_t)) / sizeof(THDynamicPageEntryGroup);

/// 数据页
typedef struct {
    union {
        // placeholder 占位内存的前 12 个字节，用来存储重定向函数 IMP 和可用的索引值
        struct {
            /// 重定向的 IMP 8 字节
            IMP redirectFunction;
            /// 下一个可用的位置 4 字节
            int32_t nextAvailableIndex;
        };
        
        /// 占位符，大小为 32 * 4 字节， 是不是意味着重定向函数只能有 16 个？
        /// 这里用 32 * 4来占位是因为对应着 fixedInstructions 指令集合的位置，不允许存放 IMP（IMP 是根据当前指令地址 - 0x4000 偏移计算的）所以fixedInstructions对应的偏移位置是不能存放数据的，不然会偏移混乱,
        int32_t placeholder[THSimplePageInstructionCount];
    };
    
    /// THDynamicData 为结构体，里面包含一个 IMP 变量表示原来的函数 IMP
    /// dynamicData数组，
    THDynamicData dynamicData[THNumberOfDataPerSimplePage];
} THDataPage;

/// 代码页，包含两个列表结构，
/// fixedInstructions 为Entry hook 函数实现的指令集， 指令数 32 条
/// jumpInstructions 是生成的 一组一组的桥指令地址，每一组桥指令集都可用于 hook 一个函数， 可 hook次数根据数据页可存储大小决定。
typedef struct {
    int32_t fixedInstructions[THSimplePageInstructionCount];
    THDynamicPageEntryGroup jumpInstructions[THNumberOfDataPerSimplePage];
} THCodePage;

// THDynamicPage 动态内存页， 分为 代码页 和 数据页
typedef struct {
    THDataPage dataPage;
    THCodePage codePage;
} THDynamicPage;


@implementation THSimplePageAllocator

/// 配置新的动态页的重定向函数的 IMP 地址。
/// @param newPage 新的虚拟内存页的地址
- (void)configurePageLayoutForNewPage:(void *)newPage
{
    if (!newPage) return;
    
    THDynamicPage *page = (THDynamicPage *)newPage;
    page->dataPage.redirectFunction = self.redirectFunction;
}

/// 校验是否 Data Page 还有可用的内存空间
/// @param resuablePage 传入的动态页 地址
- (BOOL)isValidReusablePage:(void *)resuablePage
{
    if (!resuablePage) return FALSE;
    
    // 当Data Page 可用索引达到当前页的最大值，返回 false, 表示已经存满
    THDynamicPage *page = (THDynamicPage *)resuablePage;
    if (page->dataPage.nextAvailableIndex == THNumberOfDataPerSimplePage) return FALSE;
    return YES;
}

/// 模板页地址，这里th_dynamic_page是指针的 Code Page 内存页
- (void *)templatePageAddress
{
    return &th_dynamic_page;
}

- (IMP)replaceAddress:(IMP)functionAddress inPage:(void *)page
{
    if (!page) return NULL;
    
    THDynamicPage *dynamicPage = (THDynamicPage *)page;
    
    // 可用位置的索引
    int slot = dynamicPage->dataPage.nextAvailableIndex;
    
    // 存储原函数的 IMP
    dynamicPage->dataPage.dynamicData[slot].originIMP = (IMP)functionAddress;
    // 索引++
    dynamicPage->dataPage.nextAvailableIndex++;

    // 返回对应索引的桥接入口函数的IMP
    return (IMP)&dynamicPage->codePage.jumpInstructions[slot];
}


@end

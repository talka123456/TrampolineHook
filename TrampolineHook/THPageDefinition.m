//
//  THPageLayout.m
//  TrampolineHook
//
//  Created by z on 2020/5/18.
//  Copyright © 2020 SatanWoo. All rights reserved.
//

#import "THPageDefinition.h"

/// 创建动态虚拟内存页
/// @param toMapAddress 模板内存地址， 这里传入的是汇编 CodePage 中的页起始地址，因为是代码段，所以有读和执行的权限。
void *THCreateDynamicePage(void *toMapAddress)
{
    if (!toMapAddress) return NULL;
    
    vm_address_t fixedPage = (vm_address_t)toMapAddress; // th_dynamic_page 的地址
    
    vm_address_t newDynamicPage = 0;
    kern_return_t kernResult = KERN_SUCCESS;

    // 在当前 mach task（对应上层的线程）中创建两页大小的虚拟内存空间，起始地址存储到 newDynamicPage
    kernResult = vm_allocate(current_task(), &newDynamicPage, PAGE_SIZE * 2, VM_FLAGS_ANYWHERE); // 申请两页大小的虚拟内存
    NSCAssert1(kernResult == KERN_SUCCESS, @"[THDynamicPage]::vm_allocate failed", kernResult);
    
    vm_address_t newCodePageAddress = newDynamicPage + PAGE_SIZE; // 代码内存页地址 偏移为第二页的地址。
    kernResult = vm_deallocate(current_task(), newCodePageAddress, PAGE_SIZE); // 释放第二页
    NSCAssert1(kernResult == KERN_SUCCESS, @"[THDynamicPage]::vm_deallocate failed", kernResult);
    
    vm_prot_t currentProtection, maxProtection;
    
    // 将 fixedPage 内存映射到 newCodePageAddress，
    kernResult = vm_remap(current_task(), &newCodePageAddress, PAGE_SIZE, 0, 0, current_task(), fixedPage, FALSE, &currentProtection, &maxProtection, VM_INHERIT_SHARE); // 第二页映射 th_dynamic_page
    NSCAssert1(kernResult == KERN_SUCCESS, @"[THDynamicPage]::vm_remap failed", kernResult);
    
    return (void *)newDynamicPage;
}

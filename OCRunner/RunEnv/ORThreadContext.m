//
//  ORThreadContext.m
//  OCRunner
//
//  Created by Jiang on 2020/12/15.
//

#import "ORThreadContext.h"
#import <pthread.h>
ORThreadContext *currentContext(void){
    //每一个线程拥有一个独立的参数栈
    __uint64_t threadId;
    pthread_threadid_np(NULL, &threadId);
    static NSMutableDictionary *cache = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cache = [NSMutableDictionary dictionary];
    });
    NSValue *value = cache[@(threadId)];
    if (!value) {
        ORThreadContext *ctx = malloc(sizeof(ORThreadContext));
        ctx->stack_capcity = 4096;
        ctx->stack = malloc(sizeof(void *) * ctx->stack_capcity);
        ctx->stack_header = ctx->stack;
        cache[@(threadId)] = [NSValue valueWithPointer:ctx];
        return ctx;
    }
    return [value pointerValue];
}

void contextMultiPush(NSArray *args){
    ORThreadContext *ctx = currentContext();
    *(ctx->stack) = (__bridge_retained void *)args;
    ctx->stack++;

}
void contextMultiPop(){
    ORThreadContext *ctx = currentContext();
    CFRelease(*(ctx->stack - 1));
    *(ctx->stack - 1) = NULL;
    ctx->stack--;
}

NSArray *contextStackSeek(){
    ORThreadContext *ctx = currentContext();
    return (__bridge NSArray *)(*(ctx->stack - 1));
}

BOOL contextStackIsEmpty(void){
    ORThreadContext *ctx = currentContext();
    return ctx->stack_header == ctx->stack;
}

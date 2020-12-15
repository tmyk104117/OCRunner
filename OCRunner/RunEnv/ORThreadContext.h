//
//  ORThreadContext.h
//  OCRunner
//
//  Created by Jiang on 2020/12/15.
//

#import <Foundation/Foundation.h>
@class MFValue;
typedef union{
    UInt32 w;
    UInt64 x;
}XRegister;

typedef union{
    float f;
    double d;
}DRegister;

typedef struct ORThreadContext {
    XRegister x0;
    XRegister x1;
    XRegister x2;
    XRegister x3;
    XRegister x4;
    XRegister x5;
    XRegister x6;
    XRegister x7;
    XRegister x8;
    XRegister x9;
    XRegister x10;
    DRegister d0;
    DRegister d1;
    DRegister d2;
    DRegister d3;
    DRegister d4;
    DRegister d5;
    DRegister d6;
    DRegister d7;
    DRegister d8;
    DRegister d9;
    DRegister d10;
    void **stack_header;
    void **stack;
    size_t stack_capcity;
}ORThreadContext;

ORThreadContext *currentContext(void);

void contextMultiPush(NSArray *args);
void contextMultiPop(void);
NSArray *contextStackSeek(void);
BOOL contextStackIsEmpty(void);

//
//  ORImp.m
//  OCRunner
//
//  Created by Jiang on 2020/6/8.
//  Copyright © 2020 SilverFruity. All rights reserved.
//

#import "ORCoreImp.h"
#import "MFValue.h"
#import <objc/message.h>
#import "RunnerClasses+Execute.h"
#import "MFMethodMapTable.h"
#import "MFPropertyMapTable.h"
#import "ORTypeVarPair+TypeEncode.h"
#import "util.h"
#import "ORStructDeclare.h"
#import "ORCoreFunctionCall.h"
void methodIMP(ffi_cif *cfi,void *ret,void **args, void*userdata){
    MFScopeChain *scope = [MFScopeChain scopeChainWithNext:[MFScopeChain topScope]];
    ORMethodImplementation *methodImp = (__bridge ORMethodImplementation *)userdata;
    id target = *(__strong id *)args[0];
    SEL sel = *(SEL *)args[1];
    BOOL classMethod = object_isClass(target);
    NSMethodSignature *sig = [target methodSignatureForSelector:sel];
    NSMutableArray<MFValue *> *argValues = [NSMutableArray array];
    for (NSUInteger i = 2; i < sig.numberOfArguments; i++) {
        MFValue *argValue = [[MFValue alloc] initTypeEncode:[sig getArgumentTypeAtIndex:i] pointer:args[i]];
        [argValues addObject:argValue];
    }
    if (classMethod) {
        scope.instance = [MFValue valueWithClass:target];
    }else{
        scope.instance = [MFValue valueWithObject:target];
    }
    contextMultiPush(argValues);
    MFValue *value = [methodImp execute:scope];
    contextMultiPop();
    if (value.type != TypeVoid && value.pointer != NULL){
        // 类型转换
        [value writePointer:ret typeEncode:[sig methodReturnType]];
    }
}

void blockInter(ffi_cif *cfi,void *ret,void **args, void*userdata){
    struct MFSimulateBlock *block = *(void **)args[0];
    MFBlock *mangoBlock =  (__bridge MFBlock *)(block->wrapper);
    NSMethodSignature *sig = [NSMethodSignature signatureWithObjCTypes:[MFBlock typeEncodingForBlock:mangoBlock.ocBlock]];
    NSMutableArray<MFValue *> *argValues = [NSMutableArray array];
    for (NSUInteger i = 1; i < cfi->nargs; i++) {
        MFValue *argValue = [[MFValue alloc] initTypeEncode:[sig getArgumentTypeAtIndex:i] pointer:args[i]];
        [argValues addObject:argValue];
    }
    MFValue *value = nil;
    contextMultiPush(argValues);
    value = [mangoBlock.func execute:mangoBlock.outScope];
    contextMultiPop();
    if (value.type != TypeVoid && value.pointer != NULL){
        // 类型转换
        [value writePointer:ret typeEncode:[sig methodReturnType]];
    }
}


void getterImp(ffi_cif *cfi,void *ret,void **args, void*userdata){
    id target = *(__strong id *)args[0];
    SEL sel = *(SEL *)args[1];
    ORPropertyDeclare *propDef = (__bridge ORPropertyDeclare *)userdata;
    NSString *propName = propDef.var.var.varname;
    NSMethodSignature *sig = [target methodSignatureForSelector:sel];
    __autoreleasing MFValue *propValue = objc_getAssociatedObject(target, mf_propKey(propName));
    if (!propValue) {
        propValue = [MFValue defaultValueWithTypeEncoding:propDef.var.typeEncode];
    }
    if (propValue.type != TypeVoid && propValue.pointer != NULL){
        [propValue writePointer:ret typeEncode:sig.methodReturnType];
    }
}

void setterImp(ffi_cif *cfi,void *ret,void **args, void*userdata){
    id target = *(__strong id *)args[0];
    SEL sel = *(SEL *)args[1];
    const char *argTypeEncode = [[target methodSignatureForSelector:sel] getArgumentTypeAtIndex:2];
    MFValue *value = [MFValue valueWithTypeEncode:argTypeEncode pointer:args[2]];
    ORPropertyDeclare *propDef = (__bridge ORPropertyDeclare *)userdata;
    NSString *propName = propDef.var.var.varname;
    MFPropertyModifier modifier = propDef.modifier;
    if (modifier & MFPropertyModifierMemWeak) {
        value.modifier = DeclarationModifierWeak;
    }
    objc_AssociationPolicy associationPolicy = mf_AssociationPolicy_with_PropertyModifier(modifier);
    objc_setAssociatedObject(target, mf_propKey(propName), value, associationPolicy);
}


MFValue *invoke_sueper_values(id instance, SEL sel, NSArray<MFValue *> *argValues){
    BOOL isClassMethod = object_isClass(instance);
    Class superClass;
    if (isClassMethod) {
        superClass = class_getSuperclass(instance);
    }else{
        superClass = class_getSuperclass([instance class]);
    }
    struct objc_super *superPtr = &(struct objc_super){instance,superClass};
    NSMutableArray *args = [@[[MFValue valueWithPointer:(void *)superPtr],[MFValue valueWithSEL:sel]] mutableCopy];
    [args addObjectsFromArray:argValues];
    NSMethodSignature *sig = [instance methodSignatureForSelector:sel];
    MFValue *retValue = [MFValue defaultValueWithTypeEncoding:sig.methodReturnType];
    void *funcptr = &objc_msgSendSuper;
    invoke_functionPointer(funcptr, args, retValue);
    return retValue;
}

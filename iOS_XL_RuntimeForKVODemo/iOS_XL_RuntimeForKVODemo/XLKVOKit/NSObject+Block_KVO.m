//
//  NSObject+Block_KVO.m
//  iOS_XL_RuntimeForKVO
//
//  Created by Mac-Qke on 2019/7/22.
//  Copyright © 2019 Mac-Qke. All rights reserved.
//

#import "NSObject+Block_KVO.h"
#import <objc/runtime.h>
#import <objc/message.h>

//as prefix string of kvo class
static NSString *const kXLkvoClassPrefix_for_Block = @"XLObserver_";
static NSString *const kXLkvoAssiocateObserver_for_Block = @"XLAssiocateObserver";
@interface XL_ObserverInfo_for_Block : NSObject
///设置观察者配置信息
@property (nonatomic, weak) NSObject *observer;
@property (nonatomic, copy) NSString *key;
@property (nonatomic, copy) XL_ObservingHandler handler;

@end

@implementation XL_ObserverInfo_for_Block

- (instancetype)initWithObserver:(NSObject *)observer forKey:(NSString *)key observeHandler:(XL_ObservingHandler)handler {
    if (self = [super init]) {
        _observer = observer;
        self.key = key;
        self.handler = handler;
    }
    return self;
}

@end

#pragma mark -- Transform setter or getter to each other Methods

/* 将name转变成setName: ///setter 转getter name->setName: */
static NSString *setterForGetter(NSString *getter){
    
    if (getter.length <= 0) return nil;
    NSString *firstString = [[getter substringToIndex:1] uppercaseString];
    NSString *leaveString = [getter substringFromIndex:1];
    
    return [NSString stringWithFormat:@"set%@%@:",firstString,leaveString];
}


/* 将setName转变成name ///setter 转getter setName:->name */

static NSString * getterForSetter(NSString * setter){
    if (setter.length <= 0 || ![setter hasPrefix:@"set"] ||  ![setter hasSuffix:@":"]) {
        return nil;
    }
    
    NSRange range = NSMakeRange(3, setter.length - 4);
    NSString *getter = [setter substringWithRange:range];
    NSString *firstString = [[getter substringToIndex:1] lowercaseString];
    getter = [getter stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:firstString];
    return getter;
}

#pragma mark -- Override setter and getter Methods
static void KVO_setter(id self, SEL _cmd, id newValue){
    NSString * setterName = NSStringFromSelector(_cmd);
    NSString *getterName = getterForSetter(setterName);
    if (!getterName) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"unrecognized selector sent to instance %p",self] userInfo:nil];
        return ;
    }
    
    id oldValue = [self valueForKey:getterName];
    struct objc_super superClass = {
        .receiver = self,
        .super_class = class_getSuperclass(object_getClass(self))
    
    };
    
    [self willChangeValueForKey:getterName];
    void (*objc_msgSendSuperKVO)(void *, SEL, id) = (void *)objc_msgSendSuper;
    objc_msgSendSuperKVO(&superClass, _cmd,newValue);
    [self didChangeValueForKey:getterName];
    
    //获取所有监听回调对象进行回调
    NSMutableArray * observers = objc_getAssociatedObject(self, (__bridge const void*)kXLkvoClassPrefix_for_Block);
    for (XL_ObserverInfo_for_Block * info in observers) {
        if ([info.key isEqualToString:getterName]) {
            dispatch_async(dispatch_queue_create(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                info.handler(self, getterName, oldValue, newValue);
            });
        }
    }
}

static Class kvo_Class(id self)
{
    return class_getSuperclass(object_getClass(self));
}



#pragma mark -- NSObject Category(KVO Reconstruct)
@implementation NSObject (Block_KVO)

- (void)XL_addObserver:(NSObject *)observer forKey:(NSString *)key withBlock:(XL_ObservingHandler)observedHandler {
    //step 1 get setter method, if not, throw exception
    //  ///伪代码MethodList:[Method:{SEL:IMP},Method:{SEL:IMP}....]
 
    SEL setterSelector = NSSelectorFromString(setterForGetter(key));
    //获取通过SEL获取一个方法
    Method setterMethod = class_getInstanceMethod([self class], setterSelector);
    ///先判断是否有Setter Method
    if (!setterMethod) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"unrecognized selector sent to instance %@",self] userInfo:nil];
        return;
    }
    
    //自己的类作为被观察者类
    Class observedClass = object_getClass(self); //返回obj中的isa指针
    NSString * className = NSStringFromClass(observedClass);
    
    //如果被监听者没有CMObserver_，那么判断是否需要创建新类
    ///判断类是否已经添加过观察者，判断方式就是前缀
    if (![className hasPrefix:kXLkvoClassPrefix_for_Block]) {
    //【代码①】被观察的类如果是被观察对象本来的类，那么，就要专门依据本来的类新建一个新的子类，区分是否这个子类的标记是带有kCMkvoClassPrefix_for_Block的前缀
        ///获取新注册的类
      
        observedClass = [self createKVOClassWithOriginalClassName:className];
        //【API注解①】object_setClass ///把对象的class指针指向新注册的类
        // 我们可以在运行时创建新的class，这个特性用得不多，但其实它还是很强大的。你能通过它创建新的子类，并添加新的方法。
//        但这样的一个子类有什么用呢？别忘了Objective-C的一个关键点：object内部有一个叫做isa的变量指向它的class。这个变量可以被改变，而不需要重新创建。然后就可以添加新的ivar和方法了。可以通过以下命令来修改一个object的class
 // object_setClass(myObject, [MySubclass class]);
    // 这可以用在Key Value Observing。当你开始observing an object时，Cocoa会创建这个object的class的subclass，然后将这个object的isa指向新创建的subclass。
        object_setClass(self,observedClass);
      
    }
    
    //add kvo setter method if its class(or superclass)hasn't implement setter
    ///如果本类没有Setter SEL实现--IMP
    if (![self hasSelector:setterSelector]) {
        const char *types = method_getTypeEncoding(setterMethod);
        //【代码②】// 将原来的setter方法替换一个新的setter方法（这就是runtime的黑魔法，Method Swizzling）
        class_addMethod(observedClass, setterSelector, (IMP)KVO_setter, types);
        
    }
    
    //add this observation info to saved new observer
    //【代码③】 是新建一个观察者类。这个类的实现写在同一个class，相当于导入一个类：XL_ObserverInfo_for_Block。这个类的作用是观察者，并在初始化的时候负责调用者传过来的Block回调。如下，self.handler = handler;即负责回调。
    XL_ObserverInfo_for_Block *newInfo = [[XL_ObserverInfo_for_Block alloc] initWithObserver:observer forKey:key observeHandler:observedHandler];
    
     //【代码④】
//    作用是，以及已知的“属性名”，类型为NSString的静态变量kCMkvoAssiociateObserver_for_Block来获取这个“属性”观察者数组（这个其实并不是真正意义的属性，属于runtime关联对象的知识范畴，可理解成 观察者数组 这样一个属性）
    //【API注解③】(__bridge void *)
    // 在 ARC 有效时，通过 (__bridge void *)转换 id 和 void * 就能够相互转换。为什么转换？这是因为objc_getAssociatedObject的参数要求的。先看一下它的API：
    //objc_getAssociatedObject(id _Nonnull object, const void * _Nonnull key)
//    可以知道，这个“属性名”的key是必须是一个void *类型的参数。所以需要转换。关于这个转换，下面给一个转换的例子：
//
//    id obj = [[NSObject alloc] init];
//
//    void *p = (__bridge void *)obj;
//    id o = (__bridge id)p;
    NSMutableArray *observers = objc_getAssociatedObject(self, (__bridge void*)kXLkvoClassPrefix_for_Block);
    
    if (!observers) {
        // ///如果属性变量不存在 就重新初始化，并添加到类属性列表里
        observers = [NSMutableArray array];
        objc_setAssociatedObject(self, (__bridge void*)kXLkvoClassPrefix_for_Block, observers, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    ///把初始化的观察者信息对象添加到观察者里
    [observers addObject:newInfo];
    
    
    
}

- (void)XL_removeObserver:(NSObject *)object forKey:(NSString *)key {
    ///获取属性变量Observers
    NSMutableArray *observers = objc_getAssociatedObject(self, (__bridge void *)kXLkvoClassPrefix_for_Block);
     ///遍历观察者列表，找到一致的对象，移除
    XL_ObserverInfo_for_Block *observerRemoved = nil;
    for (XL_ObserverInfo_for_Block *observerInfo in observers) {
        if (observerInfo.observer == object && [observerInfo.key isEqualToString:key]) {
            observerRemoved  = observerInfo;
            break;
        }
    }
    
    [observers removeObject:observerRemoved];
    
}

// 新建一个子类
- (Class)createKVOClassWithOriginalClassName:(NSString *)className {
     ///根据原类名拼接出派生类
    NSString *kvoClassName = [kXLkvoClassPrefix_for_Block stringByAppendingString:className];
    Class observedClass = NSClassFromString(kvoClassName);
    if (observedClass) {
        return observedClass;
    }
    
    //创建新类，并且添加CMObserver_为类名新前缀
    Class originalClass = object_getClass(self); ///获取本类
    //【API注解②】// objc_allocateClassPair
//    运行时创建类只需要三步：
//    1、为"class pair"分配空间（使用objc_allocateClassPair).
//    2、为创建的类添加方法和成员（上例使用class_addMethod添加了一个方法）。
//    3、注册你创建的这个类，使其可用(使用objc_registerClassPair)。
    
//    为什么这里1和3都说到pair，我们知道pair的中文意思是一对，这里也就是一对类，那这一对类是谁呢？他们就是Class、MetaClass。
//
//    需要配置的参数为：
//    1、第一个参数：作为新类的超类,或用Nil来创建一个新的根类。
//    2、第二个参数：新类的名称
//    3、第三个参数：一般传0


    Class kvoClass = objc_allocateClassPair(originalClass, kvoClassName.UTF8String, 0);
    //获取监听对象的class方法实现代码，然后替换新建类的class实现
    Method classMethod = class_getInstanceMethod(originalClass, @selector(class)); //  ///为派生类的class方法添加实现
    const char *types = method_getTypeEncoding(classMethod);
    class_addMethod(kvoClass, @selector(class), (IMP)kvo_Class, types);
    // ///注册到RunTime
    objc_registerClassPair(kvoClass);
    return kvoClass;
}


// ///判断是否有这个方法
- (BOOL)hasSelector:(SEL)selector {
    Class observedClass = object_getClass(self);
    unsigned int methodCount = 0;
    Method *methodList = class_copyMethodList(observedClass, &methodCount);
    for (int i = 0; i < methodCount; i++) {
        SEL thisSelector = method_getName(methodList[i]);
        if (thisSelector == selector) {
            free(methodList);
            return YES;
        }
    }
    
    free(methodList);
    return NO;
}

// runtime：关联对象相关API

//objc_getAssociatedObject(id _Nonnull object, const void * _Nonnull key)
//objc_setAssociatedObject(id _Nonnull object, const void * _Nonnull key,
//                         id _Nullable value, objc_AssociationPolicy policy)

// runtime：方法替换相关API
//BOOL class_addMethod(Class cls, SEL name, IMP imp, const char *types);
//object_getClass(id _Nullable obj)
//Method class_getInstanceMethod(Class cls, SEL name);
//const char * method_getTypeEncoding(Method m);
//FOUNDATION_EXPORT SEL NSSelectorFromString(NSString *aSelectorName);

// runtime：消息机制相关API
//objc_msgSendSuper
// KVO
//- (void)willChangeValueForKey:(NSString *)key;
//- (void)didChangeValueForKey:(NSString *)key;
@end

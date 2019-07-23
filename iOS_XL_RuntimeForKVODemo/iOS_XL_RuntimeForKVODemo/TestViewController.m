//
//  TestViewController.m
//  iOS_XL_RuntimeForKVO
//
//  Created by Mac-Qke on 2019/7/22.
//  Copyright © 2019 Mac-Qke. All rights reserved.
//

#import "TestViewController.h"
#import "Person.h"
@interface TestViewController ()
@property (nonatomic, strong) Person *person;
@end

@implementation TestViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    // 综合例子
    //添加观察者
    _person = [[Person alloc] init];
    [_person addObserver:self forKeyPath:@"age" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
    
}

//KVO回调方法
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    NSLog(@"%@对象的%@属性改变了，change字典为：%@",object,keyPath,change);
    NSLog(@"属性新值为：%@",change[NSKeyValueChangeNewKey]);
    NSLog(@"属性旧值为：%@",change[NSKeyValueChangeOldKey]);
    
}

// //移除观察者
- (void)dealloc {
    [self.person removeObserver:self forKeyPath:@"age"];
}



// 1. KVO理论基础
// 1.1 KVO的基本用法
// 步骤
// 1.注册观察者，实施监听
//[self.person addObserver:self
//              forKeyPath:@"age"
//                 options:NSKeyValueObservingOptionNew
//                 context:nil];

// 2.回调方法，在这里处理属性发生的变化
// - (void)observeValueForKeyPath:(NSString *)keyPath
//ofObject:(id)object
//change:(NSDictionary<NSString *,id> *)change
//context:(void *)context {
//    //...实现监听处理
//}
//3.移除观察者
// [self removeObserver:self forKeyPath:@“age"];
// 利用了KVO实现键值监听的第三方框架 AFNetworking，MJRresh

// 1.2 KVO的实现原理
// KVO 是 Objective-C 对 观察者模式（Observer Pattern）的实现。当被观察对象的某个属性发生更改时，观察者对象会获得通知。
//KVO 的实现也依赖于 Objective-C 强大的 Runtime 。Apple 的文档有简单提到过 KVO 的实现。Apple 的文档唯一有用的信息是：被观察对象的 isa 指针会指向一个中间类，而不是原来真正的类。Apple 并不希望过多暴露 KVO 的实现细节。

// 简单概述下 KVO 的实现：
// 当你观察一个对象时，一个新的类会动态被创建。这个类继承自该对象的原本的类，并重写了被观察属性的 setter 方法。自然，重写的 setter 方法会负责在调用原 setter方法之前和之后，通知所有观察对象值的更改。最后把这个对象的 isa 指针 ( isa 指针告诉 Runtime 系统这个对象的类是什么 ) 指向这个新创建的子类，对象就神奇的变成了新创建的子类的实例。
//原来，这个中间类，继承自原本的那个类。不仅如此，Apple 还重写了 -class 方法，企图欺骗我们这个类没有变，就是原本那个类。

// 1.3 KVO的不足
// 比如，你只能通过重写 -observeValueForKeyPath:ofObject:change:context:方法来获得通知。想要提供自定义的 selector ，不行；想要传一个 block ，门都没有。而且你还要处理父类的情况 - 父类同样监听同一个对象的同一个属性。但有时候，你不知道父类是不是对这个消息有兴趣。虽然 context 这个参数就是干这个的，也可以解决这个问题 - 在 -addObserver:forKeyPath:options:context: 传进去一个父类不知道的 context。但总觉得框在这个 API 的设计下，代码写的很别扭。至少至少，也应该支持 block 吧。


@end

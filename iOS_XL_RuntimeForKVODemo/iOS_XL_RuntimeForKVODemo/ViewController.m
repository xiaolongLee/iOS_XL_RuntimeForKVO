//
//  ViewController.m
//  iOS_XL_RuntimeForKVODemo
//
//  Created by Mac-Qke on 2019/7/22.
//  Copyright © 2019 Mac-Qke. All rights reserved.
//

#import "ViewController.h"
#import "ObservedObject.h"
#import "NSObject+Block_KVO.h"
#import "NSObject+Delegate_KVO.h"
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    ObservedObject * object = [ObservedObject new];
    object.observedNum = @11;
    
    #pragma mark - Observed By Delegate
    
//    [object XL_addObserver:self forKey:@"observedNum"];
    
    #pragma mark - Observed By Block
    [object XL_addObserver:self forKey:@"observedNum" withBlock:^(id  _Nonnull observedObject, NSString * _Nonnull observedKey, id  _Nonnull oldValue, id  _Nonnull newValue) {
        NSLog(@"Value had changed yet with observing Block");
        NSLog(@"oldValue---%@",oldValue);
        NSLog(@"newValue---%@",newValue);
    }];
    
    object.observedNum = @88;
}

#pragma mark - ObserverDelegate
- (void)XL_ObserverValueForKeyPath:(NSString *)keyPath ofObject:(id)object oldValue:(id)oldValue newValue:(id)newValue {
    NSLog(@"Value had changed yet with observing Delegate");
    NSLog(@"oldValue---%@",oldValue);
    NSLog(@"newValue---%@",newValue);
}


@end

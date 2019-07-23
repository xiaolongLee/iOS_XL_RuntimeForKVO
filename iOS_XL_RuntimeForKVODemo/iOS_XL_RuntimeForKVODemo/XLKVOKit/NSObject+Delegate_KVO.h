//
//  NSObject+Delegate_KVO.h
//  iOS_XL_RuntimeForKVODemo
//
//  Created by Mac-Qke on 2019/7/23.
//  Copyright © 2019 Mac-Qke. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ObserverDelegate <NSObject>

@optional

/**
 回调
 
 @param keyPath 属性名称
 @param object 被观察的对象
 */

- (void)XL_ObserverValueForKeyPath:(NSString *)keyPath ofObject:(id)object oldValue:(id)oldValue newValue:(id)newValue;


@end


@interface NSObject (Delegate_KVO)<ObserverDelegate>

/**
 *  method stead of traditional addObserver API
 *
 *  @param object          object as observer
 *  @param key             attribute of object to be observed
 */

- (void)XL_addObserver:(NSObject *)object forKey:(NSString *)key;
/**
 *  remove the observe
 *
 *  @param object object as observer
 *  @param key    attribute observed will remove the observe
 */

- (void)XL_removeObserver:(NSObject *)object forKey:(NSString *)key;


@end

NS_ASSUME_NONNULL_END

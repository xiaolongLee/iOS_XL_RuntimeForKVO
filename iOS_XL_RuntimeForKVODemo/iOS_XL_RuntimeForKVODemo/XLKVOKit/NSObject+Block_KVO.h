//
//  NSObject+Block_KVO.h
//  iOS_XL_RuntimeForKVO
//
//  Created by Mac-Qke on 2019/7/22.
//  Copyright © 2019 Mac-Qke. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^XL_ObservingHandler)(id observedObject, NSString *observedKey, id oldValue, id newValue);

@interface NSObject (Block_KVO)
/**
 *  method stead of traditional addObserver API
 *  //自定义添加观察者
 *  @param object          object as observer
 *  @param key             attribute of object to be observed
 *  @param observedHandler method to be invoked when notification be observed has changed
 */

- (void)XL_addObserver:(NSObject *)object forKey:(NSString *)key withBlock:(XL_ObservingHandler)observedHandler;


/**
 *  remove the observe
 *  ///移除自定义观察者
 *  @param object object as observer
 *  @param key    attribute observed will remove the observe
 */

- (void)XL_removeObserver:(NSObject *)object forKey:(NSString *)key;
@end

NS_ASSUME_NONNULL_END

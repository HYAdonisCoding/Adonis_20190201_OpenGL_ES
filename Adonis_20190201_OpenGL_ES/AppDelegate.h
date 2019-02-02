//
//  AppDelegate.h
//  Adonis_20190201_OpenGL_ES
//
//  Created by Adonis_HongYang on 2019/2/2.
//  Copyright © 2019年 Nikoyo (China）Electronics Systems Co., Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong) NSPersistentContainer *persistentContainer;

- (void)saveContext;


@end


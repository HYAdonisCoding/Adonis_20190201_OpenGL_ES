//
//  CCViewController.m
//  Adonis_20190201_OpenGL_ES
//
//  Created by Adonis_HongYang on 2019/2/11.
//  Copyright © 2019年 Nikoyo (China）Electronics Systems Co., Ltd. All rights reserved.
//

#import "CCViewController.h"
#import "CCView.h"

@interface CCViewController ()
/** view */
@property (nonatomic, strong) CCView *myView;
@end

@implementation CCViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.myView = (CCView *)self.view;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end

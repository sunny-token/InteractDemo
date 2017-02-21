//
//  ViewController.m
//  InteractDemo
//
//  Created by admin on 2017/2/21.
//  Copyright © 2017年 sunhua. All rights reserved.
//

#import "ViewController.h"
#import "InterRactViewController.h"
#import "FirstViewController.h"

@interface ViewController ()

@property (nonatomic, strong) InterRactViewController *tempVc;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    [btn setFrame:CGRectMake(0, 0, 100, 100)];
    [btn setTitle:@"action!" forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(actionForNew) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
    
    UITapGestureRecognizer *ges = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(animationForClick)];
    [self.view addGestureRecognizer:ges];
}

-(void)actionForNew {
    FirstViewController *first = [[FirstViewController alloc] init];
    [self.tempVc setInterRactContentViewController:first];
    [self.tempVc showInteractView];
}

- (void)animationForClick {
    [self.tempVc animateWhenClickBgView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (InterRactViewController *)tempVc {
    if (!_tempVc) {
        _tempVc = [[InterRactViewController alloc] init];
        [self addChildViewController:_tempVc];
        [self.view addSubview:_tempVc.view];
        [_tempVc didMoveToParentViewController:self];
    }
    return _tempVc;
}
@end

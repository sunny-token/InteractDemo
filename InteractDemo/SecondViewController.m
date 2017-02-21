//
//  SecondViewController.m
//  InteractDemo
//
//  Created by admin on 2017/2/21.
//  Copyright © 2017年 sunhua. All rights reserved.
//

#import "SecondViewController.h"

@interface SecondViewController ()

@end

@implementation SecondViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self.view setBackgroundColor:[UIColor clearColor]];
    UILabel *labe = [[UILabel alloc] init];
    labe.text = NSStringFromClass([self class]);
    labe.textColor = [UIColor blackColor];
    labe.center = self.view.center;
    labe.font = [UIFont systemFontOfSize:20];
    labe.bounds = CGRectMake(0, 0, SINGLELINE_TEXTSIZE(NSStringFromClass([self class]), [UIFont systemFontOfSize:20]).width, 100);
    [self.view addSubview:labe];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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

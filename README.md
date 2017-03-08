# InteractDemo
一个在 viewcontroller 里面展示子 controller 的框架
[demo](./demo.gif)

## 使用指南
导入'InterRactViewController.h' 和 'InterRactViewController.m' ,然后创建 'InterRactViewController' 的属性
```
@property (nonatomic, strong) InterRactViewController *tempVc;
...
- (InterRactViewController *)tempVc {
    if (!_tempVc) {
        _tempVc = [[InterRactViewController alloc] init];
        [self addChildViewController:_tempVc];
        [self.view addSubview:_tempVc.view];
        [_tempVc didMoveToParentViewController:self];
    }
    return _tempVc;
}
```

在需要展现的地方调用
```
-(void)actionForNew {
    FirstViewController *first = [[FirstViewController alloc] init];
    [self.tempVc setInterRactContentViewController:first];
    [self.tempVc showInteractView];
}
```

点击空白地方，展示动画
```
- (void)animationForClick {
    [self.tempVc animateWhenClickBgView];
}
```



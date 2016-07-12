### iOS中线程同步的方法

#####1、 串行队列

```
dispatch_queue_t serialQueue = dispatch_queue_create("com.lcd.test", DISPATCH_QUEUE_SERIAL);
    
    for (NSInteger i = 0 ; i < 10; i++) {
        
        dispatch_async(serialQueue, ^{
            
            //TODO:处理事件
        });
    }
```

#####2、 dispatch_group

```
	dispatch_group_t group = dispatch_group_create();
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    for (NSInteger i = 0 ; i < 10; i++) {
        
        dispatch_group_async(group, queue, ^{
            
            NSLog(@"%ld",i);
        });
    }
    
    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
    NSLog(@"完成");
```

打印的结果是:

```
2016-07-12 14:31:24.938 123[28485:894621] 2
2016-07-12 14:31:24.938 123[28485:894633] 7
2016-07-12 14:31:24.938 123[28485:894629] 3
2016-07-12 14:31:24.938 123[28485:894615] 0
2016-07-12 14:31:24.938 123[28485:894630] 4
2016-07-12 14:31:24.938 123[28485:894604] 1
2016-07-12 14:31:24.938 123[28485:894631] 5
2016-07-12 14:31:24.938 123[28485:894632] 6
2016-07-12 14:31:24.938 123[28485:894634] 8
2016-07-12 14:31:24.938 123[28485:894621] 9
2016-07-12 14:31:24.939 123[28485:894477] 完成
```

##### 3、dispatch_barrier

`dispatch_barrier` 需要注意的是, 在全局的并发队列`dispatch_get_global_queue`里面,`dispatch_barrier`是不会生效的,所以只能用在自定义的全局并发队列里面


在全局`dispatch_get_global_queue `里面测试一下`dispatch_barrier`的合法性,结果是错乱的。

```
	    dispatch_queue_t globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    for (NSInteger i = 0 ; i < 10; i ++) {
        
        dispatch_async(globalQueue, ^{
            
            NSLog(@"%ld",i);
        });
    }
    dispatch_barrier_async(globalQueue, ^{
        NSLog(@"完成了");
    });
    
    
    dispatch_async(globalQueue, ^{
        
        NSLog(@"继续执行下面的并发任务");
    });
```

打印出来的结果是:

```
2016-07-12 14:40:34.571 123[28564:899958] 0
2016-07-12 14:40:34.571 123[28564:899962] 2
2016-07-12 14:40:34.571 123[28564:899974] 7
2016-07-12 14:40:34.571 123[28564:899963] 3
2016-07-12 14:40:34.571 123[28564:899951] 1
2016-07-12 14:40:34.571 123[28564:899972] 4
2016-07-12 14:40:34.571 123[28564:899971] 5
2016-07-12 14:40:34.571 123[28564:899973] 6
2016-07-12 14:40:34.572 123[28564:899975] 8
2016-07-12 14:40:34.572 123[28564:899958] 9
2016-07-12 14:40:34.572 123[28564:899974] 继续执行下面的并发任务
2016-07-12 14:40:34.572 123[28564:899962] 完成了
```

在自定义队列里面测试, 符合预期

```
- (void)createDispatchBarrier {    
dispatch_queue_create("com.mt.PHPhotoLibraryCurrent",DISPATCH_QUEUE_CONCURRENT);
    
    
    for (NSInteger i = 0 ; i < 10; i ++) {
        
        dispatch_async(queue, ^{
            
            NSLog(@"%ld",i);
        });
    }
    dispatch_barrier_async(queue, ^{
        NSLog(@"完成了");
    });
    
    
    dispatch_async(queue, ^{
        
        NSLog(@"继续执行下面的并发任务");
    });
    
}

```


打印的结果是:

```
2016-07-12 14:44:45.510 123[28690:903017] 2
2016-07-12 14:44:45.510 123[28690:903031] 6
2016-07-12 14:44:45.510 123[28690:903013] 1
2016-07-12 14:44:45.510 123[28690:903028] 5
2016-07-12 14:44:45.510 123[28690:903032] 7
2016-07-12 14:44:45.510 123[28690:903003] 0
2016-07-12 14:44:45.510 123[28690:903029] 3
2016-07-12 14:44:45.510 123[28690:903030] 4
2016-07-12 14:44:45.511 123[28690:903017] 9
2016-07-12 14:44:45.511 123[28690:903033] 8
2016-07-12 14:44:45.511 123[28690:903033] 完成了
2016-07-12 14:44:45.511 123[28690:903033] 继续执行下面的并发任务
```

#####4、dispatch_semaphore

信号量本身有一个值, 表示当前信号量的总数有多少

+	dispatch_semaphore_signal: 信号量+1
+ 	dispatch_semaphore_wait: 信号量为0的时候则等待,直到信号量不为0,信号量-1

```
	    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    
    
    double delayInSeconds = 3.0;
    dispatch_time_t delayTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    //延迟3秒执行
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_after(delayTime, queue, ^(void){
        
        
        NSLog(@"3秒后的任务执行了");
        dispatch_semaphore_signal(semaphore);
    });
    
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    
    NSLog(@"开始执行后面的任务");
```

打印出来的结果是:

```
2016-07-12 15:01:34.859 123[28818:912952] 3秒后的任务执行了
2016-07-12 15:01:34.860 123[28818:912801] 开始执行后面的任务
```


异步写入数据

```
    dispatch_queue_t queue = dispatch_queue_create("com.lcd.test", DISPATCH_QUEUE_CONCURRENT);
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(1);
    NSMutableArray *array = [NSMutableArray array];
    for (NSInteger i = 0; i < 20; i ++) {
    
        dispatch_async(queue, ^{
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
            NSLog(@"保存数据中 %ld",i);
            [array addObject:@(i)];
            dispatch_semaphore_signal(semaphore);
        });
    }
    
    dispatch_barrier_async(queue, ^{
        
        NSLog(@"开始执行后面的任务了");
    });
```

打印的是:

```
2016-07-12 15:51:58.855 123[29630:942787] 保存数据中 0
2016-07-12 15:51:58.855 123[29630:942787] 保存数据中 9
2016-07-12 15:51:58.856 123[29630:942787] 保存数据中 10
2016-07-12 15:51:58.856 123[29630:942797] 保存数据中 11
2016-07-12 15:51:58.856 123[29630:942793] 保存数据中 4
2016-07-12 15:51:58.856 123[29630:942793] 保存数据中 15
2016-07-12 15:51:58.856 123[29630:942794] 保存数据中 6
2016-07-12 15:51:58.856 123[29630:942795] 保存数据中 7
2016-07-12 15:51:58.856 123[29630:942795] 保存数据中 19
2016-07-12 15:51:58.856 123[29630:942789] 保存数据中 2
2016-07-12 15:51:58.857 123[29630:942788] 保存数据中 1
2016-07-12 15:51:58.857 123[29630:942787] 保存数据中 12
2016-07-12 15:51:58.857 123[29630:942791] 保存数据中 3
2016-07-12 15:51:58.857 123[29630:942797] 保存数据中 13
2016-07-12 15:51:58.857 123[29630:942798] 保存数据中 14
2016-07-12 15:51:58.857 123[29630:942792] 保存数据中 5
2016-07-12 15:51:58.857 123[29630:942793] 保存数据中 16
2016-07-12 15:51:58.858 123[29630:942799] 保存数据中 17
2016-07-12 15:51:58.858 123[29630:942794] 保存数据中 18
2016-07-12 15:51:58.858 123[29630:942796] 保存数据中 8
2016-07-12 15:51:58.858 123[29630:942796] 开始执行后面的任务了
```



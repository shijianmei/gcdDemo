//
//  ViewController.m
//  gcd Demo
//
//  Created by Jianmei on 2017/8/23.
//  Copyright © 2017年 Jianmei. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()
@property(nonatomic,strong)dispatch_semaphore_t semaphore;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    
    
    [self groupSync];
}

#pragma mark - 概念
/*
 异步: 提交的任务立刻返回，在后台队列中执行
 同步: 提交的任务在执行完成后才会返回
 注意:提交到队列中的任务是串行执行，还是并行执行由队列本身决定。

 
 死锁:FIFO,串行队列的同步任务容易导致死锁
 
 
 
 
 
 
 */



#pragma mark - 并发队列,同步和异步执行
/**
 并发队列异步执行：开多个线程，并发执行（不一定是一个一个）执行
 并发队列同步执行：不开线程，在原来线程里面一个一个顺序执行
 */
-(void)currentQueue
{
    dispatch_queue_t concurrentQueue = dispatch_queue_create("my.concurrent.queue", DISPATCH_QUEUE_CONCURRENT);
    NSLog(@"1");
//    dispatch_sync(concurrentQueue, ^(){
//        NSLog(@"2");
//        [NSThread sleepForTimeInterval:10];
//        NSLog(@"3");
//    });
    dispatch_async(concurrentQueue, ^{
        NSLog(@"2");
        [NSThread sleepForTimeInterval:10];
        NSLog(@"3");
    });
    NSLog(@"4");
}
#pragma mark - 串行队列,同步和异步执行

/**
 串行队列同步执行：不开线程，在原来线程里面一个一个顺序执行
 串行队列异步执行：开一条线程，在这个新线程里面一个一个顺序执行
 */
-(void)seriaQueue
{
    dispatch_queue_t concurrentQueue = dispatch_queue_create("my.concurrent.queue", DISPATCH_QUEUE_SERIAL);
    NSLog(@"1");
        dispatch_sync(concurrentQueue, ^(){
            NSLog(@"2");
            [NSThread sleepForTimeInterval:10];
            NSLog(@"3");
        });
//    dispatch_async(concurrentQueue, ^{
//        NSLog(@"2");
//        [NSThread sleepForTimeInterval:10];
//        NSLog(@"3");
//    });
    NSLog(@"4");
}



#pragma mark dispatch_barrier_async 栅栏的作用
-(void)barrier
{
    dispatch_queue_t conCurrentQueue = dispatch_queue_create("com.dullgrass.conCurrentQueue", DISPATCH_QUEUE_CONCURRENT);
    dispatch_async(conCurrentQueue, ^{
        NSLog(@"dispatch 1");
    });
    dispatch_async(conCurrentQueue, ^{
        NSLog(@"dispatch 2");
    });
    dispatch_barrier_async(conCurrentQueue, ^{
        NSLog(@"dispatch barrier");
    });
    dispatch_async(conCurrentQueue, ^{
        NSLog(@"dispatch 3");
    });
    dispatch_async(conCurrentQueue, ^{
        NSLog(@"dispatch 4");
    });
}
#pragma mark 队列组
-(void)queueGroup
{
    dispatch_queue_t conCurrentGlobalQueue = dispatch_get_global_queue(0, 0);
    dispatch_group_t groupQueue = dispatch_group_create();
    NSLog(@"current task");
    dispatch_group_async(groupQueue, conCurrentGlobalQueue, ^{
        NSLog(@"并行任务1");
        sleep(1);
    });
    dispatch_group_async(groupQueue, conCurrentGlobalQueue, ^{
        NSLog(@"并行任务2");
        sleep(1);
    });
//    这两个还是稍微有点差别，一个是设置资源线程等待
    dispatch_group_wait(groupQueue, DISPATCH_TIME_FOREVER);
//    下面这个是通知形式的，可以做一些没有返回值方法的更新UI操作
    dispatch_group_notify(groupQueue, dispatch_get_main_queue(), ^{
        NSLog(@"所有任务完成");
    });

    NSLog(@"next task");
}

- (void)groupSync
{
    dispatch_group_t group = dispatch_group_create();
    dispatch_group_enter(group);
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        sleep(5);
        NSLog(@"任务一完成");
        dispatch_group_leave(group);
    });
    dispatch_group_enter(group);
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        sleep(8);
        NSLog(@"任务二完成");
        dispatch_group_leave(group);
    });
    dispatch_group_notify(group, dispatch_get_global_queue(0, 0), ^{
        NSLog(@"任务完成");
    });
    NSLog(@"任务完成后");
}


#pragma mark dispatch_apply
/**
 以指定的次数将指定的Block加入到指定的队列中。并等待队列中操作全部完成.
 */
-(void)dispatch_apply
{
    NSArray *array = [NSArray arrayWithObjects:@"/Users/chentao/Desktop/copy_res/gelato.ds",
                      @"/Users/chentao/Desktop/copy_res/jason.ds",
                      @"/Users/chentao/Desktop/copy_res/jikejunyi.ds",
                      @"/Users/chentao/Desktop/copy_res/molly.ds",
                      @"/Users/chentao/Desktop/copy_res/zhangdachuan.ds",
                      nil];
    NSString *copyDes = @"/Users/chentao/Desktop/copy_des";
    NSFileManager *fileManager = [NSFileManager defaultManager];
    dispatch_async(dispatch_get_global_queue(0, 0), ^(){
        dispatch_apply([array count], dispatch_get_global_queue(0, 0), ^(size_t index){
            NSLog(@"copy-%ld", index);
            NSString *sourcePath = [array objectAtIndex:index];
            NSString *desPath = [NSString stringWithFormat:@"%@/%@", copyDes, [sourcePath lastPathComponent]];
            [fileManager copyItemAtPath:sourcePath toPath:desPath error:nil];
        });
        NSLog(@"done");
    });
    NSLog(@"2");
}
#pragma mark 信号量：(基于计数器的一种多线程同步机制)
//就是一种可用来控制访问资源的数量的标识，设定了一个信号量，在线程访问之前，加上信号量的处理，则可告知系统按照我们指定的信号量数量来执行多个线程。其实，这有点类似锁机制了，只不过信号量都是系统帮助我们处理了，我们只需要在执行线程之前，设定一个信号量值，并且在使用时，加上信号量处理方法就行了。

//这两句代码中间的执行代码，每次只会允许一个线程进入，这样就有效的保证了在多线程环境下，只能有一个线程进入。
-(void)dispatchSignal{
    //crate的value表示，最多几个资源可访问
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(3);
    dispatch_queue_t quene = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    //任务1
    dispatch_async(quene, ^{
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        NSLog(@"run task 1");
        sleep(1);
        NSLog(@"complete task 1");
//        dispatch_semaphore_signal(semaphore);
    });
    //任务2
    dispatch_async(quene, ^{
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        NSLog(@"run task 2");
        sleep(1);
        NSLog(@"complete task 2");
//        dispatch_semaphore_signal(semaphore);
    });
    //任务3
    dispatch_async(quene, ^{
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        NSLog(@"run task 3");
        sleep(1);
        NSLog(@"complete task 3");
//        dispatch_semaphore_signal(semaphore);
    });
    
    dispatch_async(quene, ^{
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        NSLog(@"run task 4");
        sleep(1);
        NSLog(@"complete task 4");
        //        dispatch_semaphore_signal(semaphore);
    });

}

- (__kindof NSArray  *)fetchDataFromServe{
    
    //修改下面的代码，使用信号量来进行一个同步数据
    //我们传入一个参数0 ，表示没有资源，非0 表示是有资源，这一点需要搞清楚
    //补充：这里的整形参数如果是非0 就是总资源
    dispatch_semaphore_t semaoh = dispatch_semaphore_create(0);
    
    //假如下面这个数组是用来存放数据的
    NSMutableArray * array = [NSMutableArray arrayWithCapacity:0];
    //下面这个来代替我们平时常用的异步网络请求
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        for (int i=0; i<10; i++) {
            [array addObject:[NSNumber numberWithInt:i]];
        }
        NSLog(@"array = %@",array);
        dispatch_semaphore_signal(semaoh);
        
    });
    //信号等待 时，资源数 -1  阻塞当前线程 这个难理解的可以理解成等待红绿灯的车辆，红灯等待车辆
    //车辆自然是累加的排队等候，没有资源，会一直触发信号控制
    dispatch_semaphore_wait(semaoh, DISPATCH_TIME_FOREVER);
    
    
    return array;
}

#pragma mark - 死锁问题
-(void)siSuo
{
    NSLog(@"1"); // 任务1
    dispatch_sync(dispatch_get_main_queue(), ^{
        NSLog(@"2"); // 任务2
    });
    NSLog(@"3"); // 任务3
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end

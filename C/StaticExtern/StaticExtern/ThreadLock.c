//
//  ThreadLock.c
//  StaticExtern
//
//  Created by JinTao on 2020/8/19.
//  Copyright © 2020 vine. All rights reserved.
//

#include <stdio.h>
#include <pthread.h>
#include <unistd.h>

#ifndef ThreadLock

#define ThreadLock

#pragma mark - recursive
/// 递归锁：允许同一个线程对一把锁进行重复加锁
void recursiveLock() {
    // 初始化属性
    pthread_mutexattr_t attr;
    pthread_mutexattr_init(&attr);
    pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_RECURSIVE);
    // 初始化锁
    pthread_mutex_t mutex;
    pthread_mutex_init(&mutex, &attr);
    // 销毁属性
    pthread_mutexattr_destroy(&attr);
}


#pragma mark - conditon
static pthread_mutex_t count_lock;
static pthread_cond_t count_nonzero;
static unsigned count = 0;
void *decrement_count(void *arg) {
    // 使用pthread_cond_wait前要先加锁
    pthread_mutex_lock (&count_lock);
    printf("decrement_count get count_lock\n");
    while(count == 0) {
        printf("decrement_count count == 0 \n");
        printf("decrement_count before cond_wait \n");
        // 内部会解锁，然后等待条件变量被其它线程激活
        pthread_cond_wait( &count_nonzero, &count_lock);
        printf("decrement_count after cond_wait \n");
    }
    count = count - 1;
    // 被激活后会再自动加锁
    pthread_mutex_unlock (&count_lock);
    return NULL;
}

void *increment_count(void *arg) {
    // 加锁（和等待线程用同一个锁）
    pthread_mutex_lock(&count_lock);
    printf("increment_count get count_lock\n");
    if(count == 0) {
        printf("increment_count before cond_signal\n");
        // 发送激活信号
        pthread_cond_signal(&count_nonzero);
        //pthread_cond_broadcast(&count_nonzero);
        printf("increment_count after cond_signal\n");
    }
    count = count + 1;
    // 解锁
    pthread_mutex_unlock(&count_lock);
    return NULL;
}

 
/// 条件锁，发送条件信号激活等待，与信号量有区别
void conditionLock(void) {
    pthread_t tid1, tid2;
    pthread_mutex_init(&count_lock, NULL);
    pthread_cond_init(&count_nonzero, NULL);
    pthread_create(&tid1, NULL, decrement_count, NULL);
    sleep(2);
    pthread_create(&tid2, NULL, increment_count, NULL);
    sleep(10);
    pthread_exit(0);
}

#endif

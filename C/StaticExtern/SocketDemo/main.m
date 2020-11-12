//
//  main.m
//  SocketDemo
//
//  Created by JinTao on 2020/11/12.
//  Copyright © 2020 vine. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <sys/socket.h>
#import <netinet/in.h>
#import <arpa/inet.h>

#define ADDRESS "127.0.0.1"
#define PORT  9002
#define BUFFER_SIZE 200

void connectToServer() {
    int clientSocket = socket(AF_INET, SOCK_STREAM, 0);
    
    ///定义sockaddr_in
    struct sockaddr_in servaddr;
    memset(&servaddr, 0, sizeof(servaddr));
    servaddr.sin_family = AF_INET;
    servaddr.sin_port = htons(PORT);  ///服务器端口
    servaddr.sin_addr.s_addr = inet_addr(ADDRESS);  ///服务器ip
    
    ///连接服务器，成功返回0，错误返回-1
    if (connect(clientSocket, (struct sockaddr *)&servaddr, sizeof(servaddr)) < 0) {
        perror("connect");
        return;
    }
    
    printf("连接服务器成功\n");
    __block bool hasClosedSocket = false;
    dispatch_queue_t globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_group_t group = dispatch_group_create();
    dispatch_group_async(group, globalQueue, ^{
        char sendBuf[BUFFER_SIZE];
        while (true) {
            sendBuf[0] = '\0';
            printf("请输入\n");
            scanf("%s", sendBuf);
            if (hasClosedSocket) {
                return;
            }
            size_t length = strlen(sendBuf);
            sendBuf[length] = '\0';
            ssize_t sendedSize = send(clientSocket, sendBuf, length, 0);
            printf("发送 %zd 个字节\n", sendedSize);
            if (strcmp(sendBuf, "exit") == 0) {
                printf("结束发送 \n");
                break;
            }
        }
        if (!hasClosedSocket) {
            hasClosedSocket = true;
            close(clientSocket);
        }
    });
    dispatch_group_async(group, globalQueue, ^{
        char recvBuf[BUFFER_SIZE];
        while (true) {
            recvBuf[0] = '\0';
            ssize_t receivedSize = recv(clientSocket, recvBuf, 200, 0);
            if (receivedSize <= 0) {
                perror("recv null");
                break;
            }
            recvBuf[receivedSize] = '\0';
            printf("收到:%s\n", recvBuf);
            if (strcmp(recvBuf, "exit") == 0) {
                printf("结束接收 \n");
                break;
            }
        }
        if (!hasClosedSocket) {
            hasClosedSocket = true;
            close(clientSocket);
        }
    });
    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
    printf("关闭 \n");
}

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        connectToServer();
        NSLog(@"完!");
    }
    return 0;
}

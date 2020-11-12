//
//  main.c
//  SocketDemo
//
//  Created by JinTao on 2020/11/12.
//

#include <stdio.h>

#import <sys/socket.h>
#import <netinet/in.h>
#import <arpa/inet.h>
#include <string.h>
#include <unistd.h>
#include <dispatch/dispatch.h>

#define ADDRESS "127.0.0.1"
#define PORT  9002
#define BUFFER_SIZE 1024

void startListen() {
    int serverSocket = socket(AF_INET, SOCK_STREAM, 0);
    
    ///定义sockaddr_in
    struct sockaddr_in servAddr;
    memset(&servAddr, 0, sizeof(servAddr));
    servAddr.sin_family = AF_INET;
    servAddr.sin_port = htons(PORT);  ///服务器端口
    servAddr.sin_addr.s_addr = inet_addr(ADDRESS);  ///服务器ip
    
    
    ///成功返回0，错误返回-1
    if (bind(serverSocket, (struct sockaddr *)&servAddr, sizeof(servAddr)) < 0) {
        perror("bind");
        return;
    }
    
    if (listen(serverSocket, 5) < 0) {
        perror("listen");
        return;
    }
    printf("监听端口: %d\n", PORT);
    
    dispatch_queue_t globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    while (1) {
        //调用accept函数后，会进入阻塞状态
        //accept返回一个套接字的文件描述符，这样服务器端便有两个套接字的文件描述符，
        //serverSocket和client。
        //serverSocket仍然继续在监听状态，client则负责接收和发送数据
        //clientAddr是一个传出参数，accept返回时，传出客户端的地址和端口号
        //addr_len是一个传入-传出参数，传入的是调用者提供的缓冲区的clientAddr的长度，以避免缓冲区溢出。
        //传出的是客户端地址结构体的实际长度。
        //出错返回-1
        struct sockaddr_in clientAddr;
        int addr_len = sizeof(clientAddr);
        int client = accept(serverSocket, (struct sockaddr *)&clientAddr, (socklen_t *)&addr_len);
        
        if (client < 0) {
            perror("accept");
            continue;
        }
        char *clientIP = inet_ntoa(clientAddr.sin_addr);
        int clientPort = htons(clientAddr.sin_port);
        printf("连接 %d IP %s Port: %d\n", client, clientIP, clientPort);
        
        __block bool hasClosedSocket = false;
        dispatch_group_t group = dispatch_group_create();
        dispatch_group_async(group, globalQueue, ^{
            char buffer[200];
            buffer[0] = '\0';
            while (true) {
                ssize_t receivedSize = recv(client, buffer, 1024, 0);
                if (receivedSize <= 0) {
                    perror("recv null");
                    break;
                }
                buffer[receivedSize] = '\0';
                printf("收到%s:%d数据: %s\n", clientIP, clientPort, buffer);
                if (strcmp(buffer, "exit") == 0) {
                    printf("结束接收%s:%d \n", clientIP, clientPort);
                    break;
                }
            }
            if (!hasClosedSocket) {
                hasClosedSocket = true;
                printf("结束监听%s:%d \n", clientIP, clientPort);
                close(client);
            }
        });
        dispatch_group_async(group, globalQueue, ^{
            //struct sockaddr_in clientAddr_ = clientAddr;
            char buffer[200];
            while (1) {
                buffer[0] = '\0';
                printf("请输入\n%s", buffer);
                scanf("%s", buffer);
                if (hasClosedSocket) {
                    return;
                }
                size_t length = strlen(buffer);
                buffer[length] = '\0';
                //send(serverSocket, buffer, strlen(buffer), 0);
                ssize_t sendedSize = sendto(client, buffer, length, 0, (struct sockaddr *)&clientAddr, sizeof(struct sockaddr));
                printf("发送给%s:%d %zd 个字节\n", clientIP, clientPort, sendedSize);
                
                if (strcmp(buffer, "exit") == 0) {
                    printf("结束发送%s:%d \n", clientIP, clientPort);
                    break;
                }
            }
            if (!hasClosedSocket) {
                hasClosedSocket = true;
                printf("结束监听%s:%d \n", clientIP, clientPort);
                close(client);
            }
        });
        /*dispatch_group_notify(group, globalQueue, ^{
            //int client_ = client;
            close(client);
            printf("关闭 %d \n", client);
        });*/
    }
    
    //close(serverSocket);
}

int main(int argc, const char * argv[]) {
    // insert code here...
    startListen();
    printf("结束!\n");
    return 0;
}

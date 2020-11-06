#!/bin/sh  #"#!"脚本开头, 用来声明脚本由什么shell解析, 否则使用默认shell

#echo $SHELL #查看linux系统的默认解析, 区分大小写, 系统提供的shell命令解析器: sh ash bash

#给脚本加上可执行权限, 在cmd中执行下面命令, 后面为脚本文件名 chmod +x shell.sh
#三种运行方式:
#1 ./xxx.sh 先按照文件中#!指定的解析器解析, 如果#指定指定的解析器不存在, 才会使用系统默认的解析器
#2 bash xxx.sh 指明先用bash解析器解析, 如果bash不存在, 才会使用默认解析器
#3 . xxx.sh 直接使用默认解析器解析, 在Mac下执行不了

#定义变量
#readonly num=10 #等号两边不能直接接空格符
#echo "num=$num" #num解析出值
#echo 'num=$num' #num当字符串"num"处理

#echo $num # "$"表示引用变量

#unset num #清除变量值

#read -p "请入值:" num num2 # 从键盘取值, 存入变量, -p 后面的字符串会在cmd工具中显示出来, Mac一次只能读一个值

#evn #查看环境变量

#source source0.sh #在当前bash环境下读取并执行FileName中的命令, 会执行资源文件的命令, 但不会调用文件里声明的函数
#ftest

#预设变量
#echo $# #传给shell脚本参数的数量
#echo $* #传给shell脚本所有参数的内容
#echo $3 #传给shell脚本参数, 后面数字表示第几个, $0表示当前执行的进程名 $$表示当前进程的进程号
#echo $? #命令执行后返回的状态

#echo "today is `date`" #``里面为系统命令, 并执行其内容, 可以替换输出为一个变量
#echo -e "123\n4" #要加 -e , \n才能起到转义作用
#(
#ls
#) #(圆括号里的命令在子shell中完成, 不影响当前shell的值)
#{
#pwd
#} #{花括号里的命令在当前shell中完成, 会影响当前shell的值}

#echo ${num:-100} #如果变量num存在, 整个表达式的值为num, 否则为100
#echo ${num:=100} #如果变量num存在, 整个表达式的值为num, 否则为100, 同时将num的值赋值为100

#字符串操作
#str="kf329d.sfjlfsfljs34"
#echo ${#str} #测量字符串的长度
#echo ${str:3} #从下标3的位置开始到结尾, 提取字符串
#echo ${str:3:3} #从下标3的位置开始, 提取3个长度字符串
#echo ${str/j/9} #用9替换str中出现的第一个j, 原变量str的值不变
#echo ${str//j/9} #用9替换str中出现的所有j, 原变量str的值不变

#条件测试
#test 用于测试字符串,文件状态和数字
# test condition 或 [ condition ] 用方括号时, 条件两边要加空格
# 测试文件: -e 是否存在, -d 是目录, -f 是文件, -r 可读, -w 可写, -x 可执行, -L 符号连接, -c 是否字符设备, -b 是否块设备, -s 文件非空
#if [ -e source0.sh ]; then
#    echo "source0 存在"
#elif [ -e "source0.sh" ]; then
#    echo "source0.sh \"\" 存在"
#else
#    echo "不存在"
#fi

#测试字符串, 也有以上两种写法
# = 两个字符串相等, != 两个字符串不相等, -z 空字符串, -n 非空字符串
#if [ "1" = "2" ]; then
#    echo "1"
#fi

#测试数值, 也有以上两种写法
# -eq 数值相等, -ne 数值不相等, -gt 大于, -ge 大于等于, -le 小于等于, -lt 小于

#shell中 可用 && || 和 -a -o ! 组合条件, 前者组合时如果能判定结果, 就不会再执行后面的逻辑语句, 是短路操作符
#if [ 1 -gt 2 ] || test -e "shell.sh"; then
#    echo "a"
#fi

#read -p "请输入yes/no:" choice
#case $choice in
#    yes | y* | Y*)
#        echo "输入了yes"
#        ;; #相当于c语言的break
#    no | n* | N*)
#        echo "输入了no"
#        ;;
#    *) #相当于c语言的default
#        echo "输入了其他"
#        ;;
#esac

#declare -i sum=0 #声明sum为整形, declare也可写作typeset
#declare -i i=0
#for (( i=0; i<=100; i++ ))
#do
#    sum=$sum+$i;
#done
#echo "$sum"
#for i in 1 2 3 4 5 6
#do
#    sum=$sum+$i;
#done
#echo "$sum"

#for fileName in `ls`
#do
#    if [ -d $fileName ];then
#        echo "$fileName 文件夹"
#    elif [ -f $fileName ];then
#        echo "$fileName 文件"
#    fi
#done

#echo $TMPDIR #临时文件目录

#set -e #与set -o errexit 作用相同, 在文件开头, 告诉bash如果任何语句的执行结果不是true则应该退出。

#sed #stream edit, sed [-nefri]  'command' test.txt
#参数: -e 可以指定多个命令, -f 指定命令文件, -n 取消默认控制台输出，与p一起使用可打印指定内容, -i 输出到原文件，静默执行（修改原文件的意思）
#sed -e 's/系统/00/g' -e '2d' test.txt #执行多个指令
#sed -i "" "s/test/test222/"  source0.sh #将文件中的test替换成test222
#sed -f ab.log test.txt #多个命令写进ab.log文件里，一行一条命令，效果同-e
#i 插入,  i 的后面可以接字串，而这些字串会在新的一行出现(目前的上一行)
#sed '2i testContent' test.txt #在第 2 行前面插入一行内容
#sed '1,3i testContent' test.txt #在原文的第 1~3 行前面各插入一行内容
#a 新增, a 的后面可以接字串，而这些字串会在新的一行出现(目前的下一行)～
#sed '2a testContent' test.txt #在第 2 行后面新增一行内容
#sed '1,3a testContent' test.txt #在原文的第 1~3 行后面各新增一行内容
#c 取代, c 的后面可以接字串，这些字串可以取代 n1,n2 之间的行！
#sed '2c testContent' test.txt #将第 2 行内容整行替换
#sed '1,3c testContent' test.txt #将第 1~3 行内容替换成一行指定内容
#d 删除, 因为是删除啊，所以 d 后面通常不接任何咚咚
#sed '2d' test.txt #删除第 2 行
#sed '1,3d' test.txt #删除第1~3行
#p 打印, 打印，亦即将某个选择的数据印出。通常 p 会与参数 sed -n 一起运行～
#sed '2p' test.txt #重复打印第 2 行, 文件中其它行打印一次, 第 2 行重复打印
#sed '1,3p' test.txt #重复打印第1~3行
#sed -n '2p' test.txt #只打印第 2 行
#sed -n '1,3p' test.txt #只打印第 1~3 行
#sed -n '/user/p' test.txt #打印匹配到user的行，类似grep
#sed -n '/user/!p' test.txt #! 反选，打印没有匹配到user的行
#sed -n 's/old/new/gp' test #只打印匹配替换的行
#s 取代, 取代，可以直接进行取代的工作哩！通常这个 s 的动作可以搭配正规表示法！例如 1,20s/old/new/g 就是啦
#sed 's/old/new/' test.txt #匹配每一行的第一个old替换为new
#sed 's/old/new/gi' test.txt #匹配所有old替换为new，g 代表一行多个，i 代表匹配忽略大小写
#sed '3,9s/old/new/gi' test.txt #匹配第 3~9 行所有old替换为new


#cd - #在Mac上和cd ~ 效果一样
#~ 表示为 home 目录的意思， . 则是表示目前所在的目录， .. 则表示目前目录位置的上一层目录。

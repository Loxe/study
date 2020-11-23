//
//  SwiftTest.swift
//  SwiftDemo
//
//  Created by JinTao on 2020/11/6.
//

import Foundation


enum EnumTest: String {
    case a = "dbc"
    case b
}

func enumTest() {
    let a = EnumTest.a
    print(MemoryLayout.size(ofValue: a)) // 需要使用的内存大小
    print(MemoryLayout.stride(ofValue: a)) // 实际分配的内存大小
    print(MemoryLayout.alignment(ofValue: a)) // 内存对齐数
    
    print(a.rawValue)
    
    let b = EnumTest.b
    print(b)
}

struct Option {
    var bool: Bool = false {
        willSet {
            
        }
        didSet {
            
        }
    }
    var value: Int
}

/// 这里_silgen_name(""), 引号里面的才是c中调用的函数名
@_silgen_name("swiftFuction")
func swiftFunction() {
    //enumTest()
    //strinTest();
    //autoclosureTest(30)
}

func strinTest() {
    let s1: String = "1234324"
    print(MemoryLayout.size(ofValue: s1))
    print(MemoryLayout.stride(ofValue: s1))
    print(MemoryLayout.alignment(ofValue: s1))
    
    exec(v1: 10, v2: 11, fn: {$0 + $1})
    // 闭包省略成一个运算符, 对参数有严格限制
    exec(v1: 10, v2: 11, fn: +)
    // 尾随闭包, 只能用在最后一个实参是闭包的情况
    exec(v1: 10, v2: 11) {
        // 只有一个表达式时, 函数默认返回此表达式的结果
        $0 + $1
    }
    // 如果函数里只有一个闭包参数, "()"也可以不写
    exec1{1}
}


func exec(v1: Int, v2: Int, fn: (Int, Int) -> Int) {
    print(fn(v1, v2))
}

func exec1(fn: () -> Int) {
    print(fn())
}

// 自动闭包: 调用时只传一个值, 编译器会帮生成一个闭包, 只支持无参闭包, 不能传正常闭包
func autoclosureTest(_ p: @autoclosure ()-> Int) {
    print(p())
}



class Person {
    var age: Int
    init(age: Int) {
        self.age = age
    }
}

class Student: Person {
    override init(age: Int) {
        super.init(age: age)
    }
    
    convenience init(age: Int, no: Int) {
        self.init(age: age)
    }
}

let s = Student(age: 0)

var a = 10;
func pointerTest() {
    pointerTest1(p1: &a)
}
func pointerTest1(p1: UnsafeMutablePointer<Int>) {
    p1.pointee = 11
}
func pointerTest2(p1: UnsafeMutableRawPointer) {
    print(p1.load(as: Int.self))
    p1.storeBytes(of: 12, as: Int.self)
}
func pointerTest3(p1: UnsafeMutableBufferPointer<Int>) {
    p1.assign(repeating: 1)
}

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

/// 这里_silgen_name(""), 引号里面的才是c中调用的函数名
@_silgen_name("swiftFuction")
func swiftFunction() {
    //enumTest()
    strinTest();
}

func strinTest() {
    let s1: String = "1234324"
    print(MemoryLayout.size(ofValue: s1))
    print(MemoryLayout.stride(ofValue: s1))
    print(MemoryLayout.alignment(ofValue: s1))
}

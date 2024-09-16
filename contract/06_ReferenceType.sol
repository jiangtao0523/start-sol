// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract ReferenceType {


    // ————————————————————————————————————————————————————————————————数组————————————————————————————————————————————
    // 固定长度数组
    uint[8] a;
    bytes1[5] b;
    bytes c;
    address[100] h; 

    // 可变长度数组
    uint[] e; 
    bytes1[] f;
    address[] g;
    bytes i;

    function func() public pure returns(uint[] memory) {
        // 对于memory修饰的动态数组, 可以使用new创建, 但必须要声明长度, 声明后无法改变
        uint[] memory j = new uint[](3);
        return j;
    }
    
    // 数组字面量的方式创建数组
    uint[3] k = [uint(1), 2, 3];
    
    function func2() public {
        // 获取数组长度
        e.length;
        // 在数组最后追加1个元素
        e.push(1);
        // 弹出数组的最后一个元素
        e.pop();

    }

    // ———————————————————————————————————————————————————————————————结构体————————————————————————————————————————————
    struct Student {
        uint id;
        uint score;
    }

    // 初始化一个Student结构体
    Student public student;

    // 第一种赋值方式
    function initStudent1() public {
        Student storage _student = student;
        _student.id = 1;
        _student.score = 100;
    }
    // 第二种直接引用状态变量
    function initStudent2() public {
        student.id = 1;
        student.score = 100;
    }
    // 第三种构造函数的方式
    function initStudent3() public {
        student = Student(1, 100);
    }
    // 第四种key value方式
    function initStudent4() public {
        student = Student({id: 1, score: 100});
    }

}
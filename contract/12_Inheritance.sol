// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Inheritance {

}



contract GrandPa {
    event Log(string mas);

    // 希望被子类重写的方法需要加上virtual修饰符
    function hip() public virtual {
        emit Log("GrandPa");
    }

    function pop() public virtual {
        emit Log("GrandPa");
    }

    function grandPa() public virtual {
        emit Log("GrandPa");
    }
}



// 继承使用 is 语法 重写父类方法只需要在对应的方法后面加上override关键字即可
contract Father is GrandPa {
    function hip() public virtual override {
        // 可以直接使用父类的Log事件
        emit Log("Father");
    }

    function pop() public virtual override {
        emit Log("Father");
    }

    function father() public virtual {
        emit Log("Father");
    }
}



/*
    1. 多重继承需要按照辈分的从高到底写
    2. 如果一个函数在多个继承合约都存在，在子合约必须重写，否则会报错
    3. 重写在多个父合约中重名的函数时, override 关键字后面需要加上所有父合约名字
*/
contract Son is GrandPa, Father {

    function hip() public virtual override(GrandPa, Father) {
        emit Log("Son");
    }

    function pop() public virtual override(GrandPa, Father) {
        emit Log("Son");
    }

    function callParent() public {
        // 通过super关键字调用父合约方法
        super.father();
        // 通过父合约名称.方法名称调用父合约方法
        Father.father();
    }

}

contract ParentModifier {
    modifier exactDividedBy2And3(uint _a) virtual {
        require(_a % 2 == 0 && _a % 3 == 0);
        _;
    }
}


contract SonModifier is ParentModifier {

    // 可以在子合约中直接使用父合约定义的修饰符  也可以重写父合约的修饰符
    // modifier exactDividedBy2And3(uint _a) override {
    //     _;
    //     require(_a % 2 == 0 && _a % 3 == 0);
    // }

     // 计算一个数分别被2除和被3除的值，但是传入的参数必须是2和3的倍数 
    function getExactDividedBy2And3(uint _dividend) public exactDividedBy2And3(_dividend) pure returns(uint, uint) {
        return getExactDividedBy2And3WithoutModifier(_dividend);
    }

    //计算一个数分别被2除和被3除的值
    function getExactDividedBy2And3WithoutModifier(uint _dividend) public pure returns(uint, uint){
        uint div2 = _dividend / 2;
        uint div3 = _dividend / 3;
        return (div2, div3);
    }
}

contract ParentConstructor {
    uint public a;
    constructor(uint _a) {
        a = _a;
    }
}

contract SonConstructor is ParentConstructor {
    uint public b;
    constructor(uint _a, uint _b) ParentConstructor(_a) {
        b = _b;
    }
}



/*
    Adam、Eve继承了God People继承了Adam、Eve
    当使用super调用父合约函数的时候会一次调用Eve、Adam、God的哈数
*/
contract God {
    event Log(string message);

    function foo() public virtual {
        emit Log("God.foo called");
    }

    function bar() public virtual {
        emit Log("God.bar called");
    }
}

contract Adam is God {
    function foo() public virtual override {
        emit Log("Adam.foo called");
        super.foo();
    }

    function bar() public virtual override {
        emit Log("Adam.bar called");
        super.bar();
    }
}

contract Eve is God {
    function foo() public virtual override {
        emit Log("Eve.foo called");
        super.foo();
    }

    function bar() public virtual override {
        emit Log("Eve.bar called");
        super.bar();
    }
}

contract People is Adam, Eve {
    function foo() public override(Adam, Eve) {
        super.foo();
    }

    function bar() public override(Adam, Eve) {
        super.bar();
    }
}
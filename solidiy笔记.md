# solidity语法学习

## 1.1基础数据类型

**uint**   表示有符合

**uint256** 表示无符号

**bool**   默认为false

**string**  字符串类型

**bytes32** 字节类型 会计算一个字符串的字节数是否超过

**bytes**  字节类型 会自动计算字符串的类型

**address**  地址类型

## 1.2存储类型

**结构体[  ]**  名字 例如： Info[]  infos   相当于java中的array

**mapping**映射相当于java中的       map

**storage**  永久存储  相当于成员变量

**memory**  临时存储   存储在内存中可以对数据进行修改

**calldata**  临时存储    数据只能读取不能进行更改 

## 1.3 修饰符

![已上传的图片](https://files.oaiusercontent.com/file-A3UtvtZ6JvtbCtEi3meAT3?se=2025-08-08T08%3A25%3A45Z&sp=r&sv=2024-08-04&sr=b&rscc=max-age%3D299%2C%20immutable%2C%20private&rscd=attachment%3B%20filename%3D90a3a01d-b5a0-4b5e-bcf5-e82cf5fbf3c6.png&sig=/fIZq23ZKDhUyaMazZJeLVBl0N8C619TFtQ7EmwOzX4%3D)

 **public**

**private**

**internal**

**external**

## 1.4其他类型

**msg.send  ** 当前调用合约的地址

**msg.value**  当前合约发送的余额值

## 1.5合约转账

payable(msg.sender).transfer(amaount)  在区块链中进行转账的单位是以wei单位存储的 也就是1的18次方

1 ether =  1 *18   =  1 *15  Finney   

## 1.6合约结构

在 Solidity 中，合约类似于面向对象编程语言中的类。 每个合约中可以包含 [状态变量](https://docs.soliditylang.org/zh-cn/latest/structure-of-a-contract.html#structure-state-variables)， [函数](https://docs.soliditylang.org/zh-cn/latest/structure-of-a-contract.html#structure-functions)， [函数修饰器](https://docs.soliditylang.org/zh-cn/latest/structure-of-a-contract.html#structure-function-modifiers)， [事件](https://docs.soliditylang.org/zh-cn/latest/structure-of-a-contract.html#structure-events)， [错误](https://docs.soliditylang.org/zh-cn/latest/structure-of-a-contract.html#structure-errors)， [结构类型](https://docs.soliditylang.org/zh-cn/latest/structure-of-a-contract.html#structure-struct-types) 和 [枚举类型](https://docs.soliditylang.org/zh-cn/latest/structure-of-a-contract.html#structure-enum-types) 的声明，且合约可以从其他合约继承。

还有一些特殊种类的合约，叫做 [库合约](https://docs.soliditylang.org/zh-cn/latest/contracts.html#libraries) 和 [接口合约](https://docs.soliditylang.org/zh-cn/latest/contracts.html#interfaces)。

在关于 [合约](https://docs.soliditylang.org/zh-cn/latest/contracts.html#contracts) 的部分包含比本节更多的细节，它的作用是提供一个快速的概述。

**修饰符**

**modifier onlySeller(){**

**require(msg.sender == owner,"Only  seller can  this ")**

**}**

## 1.7枚举类型

```
enum State { Created, Locked, Inactive } // 枚举
```






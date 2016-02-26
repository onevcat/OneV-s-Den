---
layout: post
title: Perl中JSON的解析和utf-8乱码的解决
date: 2012-10-29 00:08:28.000000000 +09:00
tags: 能工巧匠集
---
最近在做一个带有网络通讯和同步功能的app，需要自己写一些后台的东西。因为是半路入门，所以从事开发以来就没有做过后台相关的工作，属于绝对的小白菜鸟。而因为公司在入职前给新员工提过学习Perl的要求，所以还算是稍微看过一些。这次的后台也直接就用Perl来写了。

### 基本使用

和app的通讯，很大程度上依赖了JSON，一来是熟悉，二来是iOS现在解析JSON也十分方便。iOS客户端的话JSON的解析和生成都是没什么问题的：iOS5中加入了[NSJSONSerialization](http://developer.apple.com/library/ios/#documentation/Foundation/Reference/NSJSONSerialization_Class/Reference/Reference.html)类来提供相关功能，如果希望支持更早的系统版本的话，相关的开源代码也有很多，也简单易用，比如[SBJson](http://stig.github.com/json-framework/)或者[JSONKit](https://github.com/johnezang/JSONKit)。同样，在Perl里也有不少类似的JSON处理的模块，最有名最早的应该是[JSON](http://search.cpan.org/~makamaka/JSON-2.53/lib/JSON.pm)模块了，同时也简单易用，应该可以满足大部分情况下的需求了。

使用也很简单，安装完模块后，use之后使用encode_json命令即可将perl的array或者dic转换为标准的JSON字符串了：

```
use JSON qw/encode_json decode_json/;
my $data = [
    {
        'name' => 'Ken',
        'age' => 19
    },
    {
        'name' => 'Ken',
        'age' => 25
    }
];
my $json_out = encode_json($data);
```

得到的字符串为

```
[{"name":"Ken","age":19},{"name":"Ken","age":25}]
```

相对应地，解析也很容易

```
my $array = decode_json($json_out);
```

得到的$array是含有两个字典的数组的ref。


### UTF-8乱码解决

在数据中含有UTF-8字符的时候需要稍微注意，如果直接按照上面的方法将会出现乱码。JSON模块的encode_json和decode_json自身是支持UTF8编码的，但是perl为了简洁高效，默认是认为程序是非UTF8的，因此在程序开头处需要申明需要UTF8支持。另外，如果需要用到JSON编码的功能（即encode_json）的话，还需要加入Encode模块的支持。总之，在程序开始处加入以下：

```perl
use utf8;
use Encode;
```

另外，如果使用非UTF8进行编码的内容的话，最好先使用Encode的from_to命令转换成UTF8，之后再进行JSON编码。比如使用GBK编码的简体字（一般来自比较早的Windows的文件等会偶尔变成非UTF8编码），先进性如下转换：

```
use JSON;
use Encode 'from_to';
 
# 假设$json是GBK编码的
my $json = '{"test" : "我是GBK编码的哦"}';
 
from_to($json, 'GBK', 'UTF-8');
 
my $data = decode_json($json);
```

其他的，如果追求更高的JSON转换性能的话，可以试试看[JSON::XS](http://search.cpan.org/~mlehmann/JSON-XS-2.33/XS.pm)之类的附加模块～

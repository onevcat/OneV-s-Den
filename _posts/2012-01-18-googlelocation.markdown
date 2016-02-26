---
layout: post
title: Google查询地理信息API
date: 2012-01-18 22:24:09.000000000 +09:00
tags: 能工巧匠集
---
向Google Map查询给定经纬度的位置信息，返回为JSON

```
+ (NSString *)googleReverseStringWithCoordinate:(CLLocationCoordinate2D)coordinate {
    return [NSString stringWithFormat:@"http://maps.google.com/maps/geo?q=%lf,%lf&output=json&sensor=false&accuracy=4", coordinate.latitude,coordinate.longitude];
}
```

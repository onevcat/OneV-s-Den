---
layout: post
title: Unity3D中暂停时的动画及粒子效果实现
date: 2013-01-26 00:23:34.000000000 +09:00
tags: 能工巧匠集
---


![](http://www.onevcat.com/wp-content/uploads/2013/01/big副本.png)

暂停是游戏中经常出现的功能，而Unity3D中对于暂停的处理并不是很理想。一般的做法是将`Time.timeScale`设置为0。Unity的文档中对于这种情况有以下描述；

> The scale at which the time is passing. This can be used for slow motion effects….When timeScale is set to zero the game is basically paused …

timeScale表示游戏中时间流逝快慢的尺度。文档中明确表示，这个参数是用来做慢动作效果的。对于将timeScale设置为0的情况，仅只有一个补充说明。在实际使用中，通过设置timeScale来实现慢动作特效，是一种相当简洁且不带任何毒副作用的方法，但是当将timeScale设置为0来实现暂停时，由于时间不再流逝，所有和时间有关的功能痘将停止，有些时候这正是我们想要的，因为毕竟是暂停。但是副作用也随之而来，在暂停时各种动画和粒子效果都将无法播放（因为是时间相关的），FixedUpdate也将不再被调用。

**换句话说，最大的影响是，在timeScale＝0的暂停情况下，你将无法实现暂停菜单的动画以及各种漂亮的点击效果。**

但是并非真的没办法，关于timeScale的文档下就有提示：

> Except for realtimeSinceStartup, timeScale affects all the time and delta time measuring variables of the Time class.

因为 `realtimeSinceStartup` 和 `timeScale` 无关，因此也就成了解决在暂停下的动画和粒子效果的救命稻草。对于Unity动画，在每一帧，根据实际时间寻找相应帧并采样显示的方法来模拟动画：

```csharp
AnimationState _currState = animation[clipName];

bool isPlaying = true;
float _progressTime = 0F;
float _timeAtLastFrame = 0F;
float _timeAtCurrentFrame = 0F;
bool _inReversePlaying = false;
float _deltaTime = 0F;

animation.Play(clipName);
_timeAtLastFrame = Time.realtimeSinceStartup;

while (isPlaying) {
    _timeAtCurrentFrame = Time.realtimeSinceStartup;
    _deltaTime = _timeAtCurrentFrame - _timeAtLastFrame;
    _timeAtLastFrame = _timeAtCurrentFrame;
    _progressTime += _deltaTime;
    _currState.normalizedTime = _inReversePlaying ? 1.0f - (_progressTime / _currState.length) : _progressTime / _currState.length; 
    animation.Sample();
    //…repeat or over by wrap mode 
}
```

对于粒子效果，同样进行计时，并通过粒子系统的Simulate方法来模拟对应时间的粒子状态来完成效果，比如对于Legacy粒子，使Emitter在`timeScale＝0`暂停时继续有效发射并显示效果：

```
_deltaTime = Time.realtimeSinceStartup - _timeAtLastFrame;
_timeAtLastFrame = Time.realtimeSinceStartup;
if (Time.timeScale == 0 ){
	_emitter.Simulate(_deltaTime);
	_emitter.emit = true;
}
```

核心的代码基本都在上面了，可以根据这个思路完成实现。[完整的代码和示例工程](https://github.com/onevcat/UnpauseMe)我放到了github上，有需要的朋友可以去查看，也欢迎大家指正。

---
layout: post
title: WWDC15 Session笔记 - Xcode 7 UI 测试初窥
date: 2015-09-27 20:58:47.000000000 +09:00
tags: 能工巧匠集
---
![](/assets/images/2015/ui-testing-title.png)

Unit Test 在 iOS 开发中已经有足够多的讨论了。Objective-C 时代除了 Xcode 集成的 XCTest 以外，还有很多的测试相关的工具链可以使用，比如专注于提供 Mock 和 Stub 的 [OCMock](http://ocmock.org)，使用行为驱动测试的 [Kiwi](https://github.com/kiwi-bdd/Kiwi) 或者 [Specta](https://github.com/specta/specta) 等等。在 Swift 中，我们可以继续使用 XCTest 来进行测试，而 Swift 的 mock 和 stub 的处理，我们甚至不需要再借助于第三方框架，而使用 Swift 自身可以在方法中内嵌类型的特性来完成。关于这方面的内容，可以参看下 NSHipster [这篇文章](http://nshipster.com/xctestcase/)里关于 Mocking in Swift 部分的内容。

不过这些都是单元测试 (Unit Test) 的相关内容。单元测试非常适合用来做 app 的逻辑以及网络接口方面的测试，但是一个 app 所面向的最终人群还是使用的用户。对于用户来说，app 的功能和 UI 界面是否正确是判断这个 app 是否合格的更为直接标准。而传统的单元测试很难对 app 的功能或者 UI 进行测试。iOS 的开源社区有过一系列的尝试，比如 [KIF 框架](https://github.com/kif-framework/KIF)，Apple 自己的 [Automating UI Testing](https://developer.apple.com/library/mac/documentation/DeveloperTools/Conceptual/InstrumentsUserGuide/UsingtheAutomationInstrument/UsingtheAutomationInstrument.html) 或者 Facebook 的[截图测试](https://github.com/facebook/ios-snapshot-test-case)等。关于这些 UI 测试框架的更详细的介绍，可以参看 objc 中国上的 [UI 测试](http://objccn.io/issue-15-6/)和[截图测试](http://objccn.io/issue-15-7/)两篇文章。不过这些方法有一个共同的特点，那就是配置起来十分繁琐，使用上也有诸多不便。测试的目的是保证代码的质量和发布时的信心，以加速开发和迭代的效率；但是如果测试本身太过于难写复杂的话，反而会拖累开发速度。这大概也是 UI 测试所面临的最大窘境 -- 往往开发者在一个项目里写了一两个 UI 测试用例后，就会觉得难以维护，怯于巨大的时间成本，继而放弃。

Apple 在 Xcode 7 中新加入了一套 UI Testing 的工具，其目的就是解决这个问题。新的 UI Testing 比以往的解决方案要简单不少，特别是在创建测试用例的时候更集成了录制的功能，这有希望让 UI Testing 变得更为普及。这篇文章将通过一个简单的例子来说明 Xcode 7 中 UI Testing 的基本概念和使用方法。

本文是我的 [WWDC15 笔记](http://onevcat.com/2015/06/ios9-sdk/)中的一篇，本文所参考的有：

* [UI Testing in Xcode](https://developer.apple.com/videos/wwdc/2015/?id=406)

### UI Testing 和 Accessibility

在开始实际深入到 UI Testing 之前，我们可能需要补充一点关于 app 可用性 (Accessibility) 的基本知识。[UI Accessibility](https://developer.apple.com/library/ios/documentation/UserExperience/Conceptual/iPhoneAccessibility/Introduction/Introduction.html) 早在 iOS 3.0 就被引入了，用来辅助身体不便的人士使用 app。VoiceOver 是 Apple 的屏幕阅读技术，而 UI Accessibility 的基本原则就是对屏幕上的 UI 元素进行分类和标记。两者配合，通过阅读或者聆听这些元素，用户就可以在不接触屏幕的情况下通过声音来使用 app。

Accessibility 的核心思想是对 UI 元素进行分类和标记 -- 将屏幕上的 UI 分类为像是按钮，文本框，cell 或者是静态文本 (也就是 label) 这样的类型，然后使用 identifier 来区分不同的 UI 元素。用户可以通过语音控制 app 的按钮点击，或是询问某个 label 的内容等等，十分方便。iOS SDK 中的控件都实现了默认的 Accessibility 支持，而我们如果使用自定义的控件的话，则需要自行使用 Accessibility 的 API 来进行添加。

但是因为最初 Accessibility 和 VoiceOver 都是基于英文的，所以在国内的 iOS 应用中并不是十分受到重视。不仅如此，因为添加完备的可用性支持对于开发者来说也是不小的额外工作量，所以除非应用有特殊的使用场景，对于 Accessibility 的支持和重视程度都十分有限。但是在 UI 测试中，可用性的作用就非常大了。UI 测试的本质就是定位在屏幕上的元素，实现一些像是点击或者拖动这样的操作交互，然后获取 UI 的状态进行断言来判断是否符合我们的预期。这个过程及其需求与 Accessibility 的功能是高度吻合的。这也是为什么 iOS 中大部分的 UI 测试框架都是基于 UI Accessibility 的原因，Xcode 7 的 UI Testing 也不例外。

### 集成 UI Testing

在项目中加入 UI Testing 的支持非常容易。如果是新项目的话，在新建项目时 UI Testing 就已经是默认选上的了:

![](/assets/images/2015/ui-testing-1.png)

如果你要在已有项目中添加 UI Testing 的话，可以新建一个 iOS UI Testing 的 target：

![](/assets/images/2015/ui-testing-2.png)

无论使用那种方法，Xcode 将为你配置好你所需要的 UI 测试环境。我们这里通过一个简单的例子来说明 UI Testing 的基本使用方法。这个 app 非常简单，只有两个主要界面。首先是输入用户名密码的登陆界面，在登陆之后的带有一个 Switcher 的界面。用户可以通过点击这个开关来将下面的签到次数 +1。这个项目的代码可以在 GitHub 的[这个仓库](git@github.com:onevcat/UITestDemo.git)中找到。

![](/assets/images/2015/ui-testing-3.png)

### UI 行为录制和第一个测试

相比起其他一些 UI 测试框架，Xcode 的 UI Testing 最为诱人的优点在于可以直接录制操作。我们首先来看看 UI Testing 的基本结构吧。在新建 UI Testing 后，我们会得到一个 `{ProjectName}UITests` 文件，默认实现是：

```Swift
import XCTest

class UITestDemoUITests: XCTestCase {
        
    override func setUp() {
        super.setUp()

        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        XCUIApplication().launch()

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testExample() {
       // Use recording to get started writing UI tests.
       // Use XCTAssert and related functions to verify your tests produce the correct results.
    }    
}
```

在 `setUp` 中，我们使用 `XCUIApplication` 的 `launch` 方法来启动测试 app。和单元测试的思路类似，在每一个 UI Testing 执行之前，我们都希望从一个“干净”的 app 状态开始进行。`XCUIApplication` 是 `UIApplication` 在测试进程中的代理 (proxy)，我们可以在 UI 测试中通过这个类型和应用本身进行一些交互，比如开始或者终止一个 app。我们先来测试在没有输入时直接点击 Login 按钮的运行情况。在 test 文件中加入一个方法，`testEmptyUserNameAndPassword`，在模拟器中运行程序后，将输入光标放在方法实现中，并点击工具栏上的录制按钮，就可以进行实时录制了：

![](/assets/images/2015/ui-testing-4.png)

第一个测试非常简单，我们直接保持用户名和密码文本框为空，直接点击 login。这时 UI 录制会记录下这次点击行为：

```swift
func testEmptyUserNameAndPassword() {
    XCUIApplication().buttons["Login"].tap()

}
```

`XCUIApplication()` 我们刚才说过，是一个在 UI Testing 中代表整个 app 的对象。然后我们使用 `buttons` 来获取当前屏幕上所有的按钮的代理。使用 `buttons` 来获取一个对 app 的 query 对象，它可以用来寻找 app 内所有被标记为按钮的 UI 元素，其实上它是 `XCUIApplication().descendantsMatchingType(.Button)` 的简写形式。同样地，我们还有像是 `TextField`，`Cell` 之类的类型，完整的类型列表可以在[这里](http://masilotti.com/xctest-documentation/Constants/XCUIElementType.html)找到。类似这样的从 app 中寻找元素的方法，所得到返回是一个 `XCUIElementQuery` 对象。除了 `descendantsMatchingType` 以外，还有仅获取当前层级子元素的 `childrenMatchingType` 和所有包含的元素的 `containingType`。我们可以通过级联和结合使用这些方法获取到我们想要的层级的元素。

当得到一个可用的 `XCUIElementQuery` 后，我们就可以进一步地获取代表 app 中具体 UI 元素的 `XCUIElement` 了。和 `XCUIApplication` 类似，`XCUIElement` 也只是 app 中的 UI 元素在测试框架中的代理。我们不能直接通过得到的 `XCUIElement` 来直接访问被测 app 中的元素，而只能通过 Accessibility 中的像是 `identifier` 或者 `frame` 这样的属性来获取 UI 的信息。关于具体的可用属性，可以参看 [`XCUIElementAttributes`](http://masilotti.com/xctest-documentation/Protocols/XCUIElementAttributes.html) 的文档。

> 其实 `XCUIApplication` 是 `XCUIElement` 的子类，了解到这一点后，我们就不难理解 `XCUIApplication` 也是一个代理的事实了。

在这里 `XCUIApplication().buttons["Login"]`，做的是在应用当前界面中找到所有的按钮，然后找到 Login 按钮。接下来我们对这个 UI 代理发送 `tap` 进行点击。在我们的 app 中，点击 Login 后我们模拟了一个网络请求，在没有填写用户名和密码的情况下，将弹出一个 alert 来提示用户需要输入必要的登陆信息：

![](/assets/images/2015/ui-testing-5.png)

虽然 UI Testing 的交互会等待 UI 空闲后再进行之后的交互操作，但是由于登陆是在后台线程完成的，UI 其实已经空闲下来了，因此我们在测试中也需要等待一段时间，然后对这个 alert 是否弹出进行判断。将 `testEmptyUserNameAndPassword` 中的内容改写为：

```swift
func testEmptyUserNameAndPassword() {
    let app = XCUIApplication()
    app.buttons["Login"].tap()
    
    let alerts = app.alerts
    let label = app.alerts.staticTexts["Empty username/password"]
    
    let alertCount = NSPredicate(format: "count == 1")
    let labelExist = NSPredicate(format: "exists == 1")
    
    expectationForPredicate(alertCount, evaluatedWithObject: alerts, handler: nil)
    expectationForPredicate(labelExist, evaluatedWithObject: label, handler: nil)
    
    waitForExpectationsWithTimeout(5, handler: nil)
}
```

注意我们这里用了一个预言期望，而不是直接采用断言。按照一般思维来说，我们可能会倾向于使用像是 dispatch_after 来让断言延迟，类似这样：

```swift
func testEmptyUserNameAndPassword() {
    //...
    app.buttons["Login"].tap()

    let expection = expectationWithDescription("wait for login")
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(3 * NSEC_PER_SEC)), dispatch_get_main_queue()) { () -> Void in
        XCTAssertEqual(alerts.count, 1, "There should be an alert.")
        expection.fulfill()
    }

    waitForExpectationsWithTimeout(5, handler: nil)
}
```

但是你会发现这段代码中 block 的部分并不会执行，这是因为在 UI Testing 中有不能 dispatch 到主线程的限制。我们可以通过把 main thread 改为其他 thread 来让代码进入 block，但是这会导致断言崩溃。因此，对于这种需要在一定时间之后再进行判断的测试例，可以使用 `expectationForPredicate` 来对未来的状态作出假设并测试在规定的超时时间内是否得到理想的结果。在 `testEmptyUserNameAndPassword` 的例子中，我们应该在点击 Login 后得到的是一个 alert 框，并且其中有一个 label，文本是 "Empty username/password"。Cmd+U，测试通过！你也可以打开模拟器查看整个过程，同时试着更改一下 Predicate 中的内容，看看运行的结果，来证明测试确实有效。

### 文本输入和 ViewController 切换

接下来可以试着测试下登陆成功。我们有一组可用的用户名/密码，现在要做的是用 UI Testing 的方式在用户名和密码的文本框中。最简单的方式还是直接使用 UI 动作的录制功能。对应的测试代码如下：

```swift
func testLoginSuccessfully() {
    let app = XCUIApplication()
    let element = app.otherElements.containingType(.NavigationBar, identifier:"Login").childrenMatchingType(.Other).element.childrenMatchingType(.Other).element.childrenMatchingType(.Other).element.childrenMatchingType(.Other).elementBoundByIndex(1)
    let textField = element.childrenMatchingType(.Other).elementBoundByIndex(0).childrenMatchingType(.TextField).element
    textField.tap()
    textField.typeText("onevcat")
    element.childrenMatchingType(.Other).elementBoundByIndex(1).childrenMatchingType(.SecureTextField).element.typeText("123")
    
    // Other more test code
}
```

自动录制生成的代码使用了很多 query 来查询文本框，虽然这么做是可以找到合适的文本框，但是现在的做法显然难以理解。这是因为我们没有对这两个 textfield 的 identifier 进行设置，因此无法用下标的方式进行访问。我们可以通过在 Interface Builder 或者代码中进行设置。

![](/assets/images/2015/ui-testing-6.png)

然后就可以在测试方法中把寻找元素的 query 改为更好看的方式，并且加上测试 ViewController 切换的相关代码了：

```swift
func testLoginSuccessfully() {
    
    let userName = "onevcat"
    let password = "123"
    
    let app = XCUIApplication()
    
    let userNameTextField = app.textFields["username"]
    userNameTextField.tap()
    userNameTextField.typeText(userName)
    
    let passwordTextField = app.secureTextFields["password"]
    passwordTextField.tap()
    passwordTextField.typeText(password)

    app.buttons["Login"].tap()

    let navTitle = app.navigationBars[userName].staticTexts[userName]
    expectationForPredicate(NSPredicate(format: "exists == 1"), evaluatedWithObject: navTitle, handler: nil)

    waitForExpectationsWithTimeout(5, handler: nil)
}
```

> 注意在当前的 Xcode 版本 (7.0 7A218) 中 UI 录制在对于有 identifier 的文本框时，没有自动插入 `tap()`，这会导致测试时出现 “UI Testing Failure - Neither element nor any descendant has keyboard focus on secureTextField” 的错误。我们可以手动在输入文本 (`typeText`) 之前加入 `tap` 的调用。相信在之后的 Xcode 版本中这个问题会得到修正。

对于 ViewController 切换的判断，我们可以通过判断 navigation bar 上的 title 是否正确来加以判断。

### 实时的 UI 反馈测试和关于 XCUIElementQuery 的说明
 
我们接下来测试 DetailViewController 中的 Switcher 点击。在成功登陆之后，我们可以看到一个默认为 off 状态的 switcher 按钮。点击打开这个按钮，下面的 count label 计数就会加一。首先我们需要成功登陆，在上面的测试例 (`testLoginSuccessfully`) 我们已经测试了成功登陆，我们先在新的测试方法中模拟登陆过程：

```swift
func testSwitchAndCount() {
    let userName = "onevcat"
    let password = "123"

    let app = XCUIApplication()

    let userNameTextField = app.textFields["username"]
    userNameTextField.tap()
    userNameTextField.typeText(userName)

    let passwordTextField = app.secureTextFields["password"]
    passwordTextField.tap()
    passwordTextField.typeText(password)

    app.buttons["Login"].tap()
    
    // To be continued..
}
```

接下来因为 Login 是在后台进行的，我们需要等一段时间，让新的 DetailViewController 出现。在上面两个测试例中，我们直接用 expectationForPredicate 来作为断言，这样 Xcode 只需要在超时之前观测到符合断言的变化即可以结束测试。而在这里，我们要在新的 View 里进行 UI 交互，这就需要一定时间的等待 (包括模拟的网络请求和 UI 迁移的动画等)。因为 UI 测试和 app 本身是在不同进程中运行的，我们可以简单地使用 `sleep` 来等待。接下来我们点击这个 switcher 并添加断言。在上面代码中注释的地方接着写：

```swift
func testSwitchAndCount() {
    //...
    
    sleep(3)
    
    let switcher = app.switches["checkin"]
    let l = app.staticTexts["countLabel"]

    switcher.tap()
    XCTAssertEqual(l.label, "1", "Count label should be 1 after clicking check in.")
    
    switcher.tap()
    XCTAssertEqual(l.label, "0", "And 0 after clicking again.")
}
```

`checkin` 和 `countLabel` 是我们在 IB 中为 UI 设置的 identifier。默认情况下，我们可以通过 `label` 属性来获取一个 Label 的文字值。

到此为止，这个简单的 demo 就书写完毕了。当然，实际的 app 中的情况会比这种 demo 复杂得多，但是基本的思路和步骤是一致的 -- 通过 query 寻找要交互的 UI 元素，进行交互，判断结果。在 UI 录制的帮助下，我们一般只需要关心如何书写断言和对结果进行判断，这大大节省了书写和维护测试的时间。

对于 `XCUIElementQuery`，还有一点需要特别说明的。Query 的执行是延迟的，它和最后我们得到的 `XCUIElement` 并不是一一对应的。和 `NSURL` 与请求到的内容的关系类似，随着时间的变化，同一个 URL 有可能请求到不同的内容。我们生成 Query，然后在通过下标或者是访问方法获取的时候才真正从 app 中寻找对应的 UI 元素。这就是说，随着我们的 UI 的变化，同样的 query 也是有可能获取到不用的元素的。这在某些元素会消失或者 identifier 变化的时候是需要特别注意的。

### 小结

UI Testing 在易用性上比 KIF 这样的框架要有所进步，随着 UI Testing 的推出，Apple 也将原来的 UI Automation 一系列内容标记为弃用。这意味着 UI Testing 至少在今后一段时间内将会是 iOS 开发中的首选工具。但是我们也应该看到，基于 Accessibility 的测试方式有时候并不是很直接。在这个限制下，我们只能得到 UI 的代理对象，而不是 UI 元素本身，这让我们无法得到关于 UI 元素更多的信息 (比如直接获取 UI 元素中的内容，或者与 ViewController 中的相关的值)，现在的 UI Testing 在很大程度上还停留在比较简易的阶段。

但是相比使用 UIAutomation 在 Instruments 中用 JavaScript 与 app 交互，我们现在可以用 Swift 或者 Objective-C 直接在 Xcode 里进行 UI 测试了，这使得测试时可以方便地进行和被调试。Xcode 7.0 中的 UI Testing 作为第一个版本，还有不少限制和 bug，使用起来也有不少“小技巧”，很多时候可能并没有像单元测试那样直接。但即便如此，使用 UI Testing 来作为人工检查的替代和防止开发过程中 bug 引入还是很有意义的，相比起开发人员，也许 QA 人员从 UI 录制方面收益更多。如果 QA 职位的员工可以掌握一些基本的 UI Testing 内容的话，应该可以极大地缩短他们的工作时间和压力。而且相信 Apple 也会不断改进和迭代 UI Testing，并以此驱动 app 质量的提升，所以尽早掌握这一技术还是十分必要的。

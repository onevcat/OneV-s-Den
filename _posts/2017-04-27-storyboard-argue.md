---
layout: post
title: "再看关于 Storyboard 的一些争论"
date: 2017-04-27 10:45:00.000000000 +09:00
tags: 能工巧匠集
---

从 iOS 5 的时代 Apple 推出 Storyboard (以下简称 SB) 后，关于使用这种方式构建 UI 的争论就在 Cocoa 开发者社区里一直发生着。我在 2013 年写过一篇关于[代码手写 UI，xib 和 SB 之间的取舍](https://onevcat.com/2013/12/code-vs-xib-vs-storyboard/)的文章。在四五年后的今天，SB 得到了多次进化，大家也积攒了很多关于使用 SB 进行开发的经验，我们不妨再回头看看当初的忧虑，并结合 SB 开发的现状，来提取一些现阶段被认为比较好的实践。

这篇文章缘起为对[使用 SB 的方式](http://www.jianshu.com/p/478998f0a274)一文 (及其[英文原文](https://medium.cobeisfresh.com/a-case-for-using-storyboards-on-ios-3bbe69efbdf4)) 的回应，我对其中部分意见有一些不同的看法。不过正如原文作者在最后一段所说，你应该选择最适合自己的使用方式。所以我的意见或者说所谓的「好的实践」，也只是从我自己的观点出发所得到的结论。本文将首先对原文提出的几个论点逐个分析，然后介绍一些我自己在日常使用 SB 时的经验和方式。

(反正关于 Storyboard 或者 Interface Builder 已经吵了那么多年了，也不在乎多这么一篇-。-)

## 原文分析

### Storyboard 冲突风险和加载

原文中有一个非常激进的观点，那就是：

> 每个 SB 里只放一个 UIViewController

我无法赞同这个观点。如果在 iOS 3 或者 4 时代有 xib 使用经验的开发者会知道，这基本就是将 SB 倒退到 xib 的用法。原文中提到这么做的原因主要有三点：

> - 减少两个开发者同时开发一个 View Controller 时的 git 冲突
> - 加速 storyboard 加载，因为只需要加载一个 UIViewController
> - 只用 initial view controller 就可以从 SB 中加载想要的 View Controller

在 Xcode 7 [引入了 SB reference](https://developer.apple.com/videos/play/wwdc2015/215/) 以后，「SB 容易冲突」已经彻底变成假命题了。通过合理地划分功能模块和每个开发者负责的部分，我们可以完全避免 SB 的修改冲突。最近两三年以来我们在实际项目中完全没有出现过 SB 冲突的情况。

另外，即使 SB 划分出现问题，影响也是可控的。在单个的 SB 文件中，每个 View Controller 有各自的范围域，因此即使存在不同开发者同时着手一个 SB 文件的情况，只要他们不同时修改同一个 View Controller 的内容，也并不会在 View Controller 上产生冲突。在 SB 文件中确实存在一些共用的部分，比如 IB 的版本，系统的版本等，但它们并不影响实质的 UI，而且可以通过统一开发成员的环境来避免冲突。因此，一个 SB 中多个 VC 和一个 SB 中一个 VC，其实所带来的冲突风险几乎是一样的。

关于 SB 的加载，可以看出原作者可能并没有搞清 UI 加载的整个流程，不求甚解地认为 SB 文件中 View Controller 越多加载时间越长，但事实并非如此。细心的同学 (或者项目中有很多 SB 文件的同学) 会发现，在编译的时候 Xcode 有一个 Compiling Storyboard files 的过程：

![](/assets/images/2017/compiling-sb.png)

编译过程中，项目里用到的 SB 文件也会被编译，并以 `storyboardc` 为扩展名保存在最终的 app 包内。这个文件和 `.bundle` 或者 `.framework` 类似，实际上是一个文件夹，里面存储了一个描述该编译后的 SB 信息的 `Info.plist` 文件，以及一系列 `.nib` 文件。原来的 SB 中的每个对象 (或者说，一般就是每个 View Controller) 将会被编译为一个单独的 `.nib`，而 `.nib` 中包含了编码后的对应的对象层级。在加载一个 SB，并从中读取单个 View Controller 时，首先系统会找到编译后的 `.storyboardc` 文件，从 `Info.plist` 中获取所需的 View Controller 类型和 nib 的关系，来完成 `UIStoryboard` 的初始化。接下来读取对应的某个 nib，并使用 `UINibDecoder` 进行解码，将 nib 二进制还原为实际的对象，最后调用该对象的 `initWithCoder:` 完成各个属性的解码。在完成这些工作后，`awakeFromNib` 被调用，来通知开发者从 nib 的加载已经完毕。

如果你理解这个过程，就可以看出，从只有单个 View Controller 的 SB 中加载这个 VC，与从多个 View Controller 中加载一个的情况，在速度上并不会有什么区别。硬要说的话，如果使用太多 SB 文件，反而会在初始化 `UIStoryboard` 时需要读取更多的 `Info.plist`，反而造成性能下降 (相对地我们可以使用 View Controller 的 `storyboard` 属性来获取当前 VC 所属的 `UIStoryboard`，从而避免多次初始化同一个 Storyboard，不过这点性能损失其实无关紧要)。

关于第三点，原作者使用了一段代码来展示如何通过类似这样的方法来创建类型安全的对象：

```swift
let feed = FeedViewController.instance()
// `feed` is of type `FeedViewController`
```

这么做有几个前提，首先它需要按照 View Controller 类型名字来创建 SB 文件，其次还需要为 `UIViewController` 添加按照类型名字寻找 SB 文件的辅助方法。这并不是一个很明显的优点，它肯定会引入 `NSStringFromClass` 这种动态的东西，而且其实我们有很多更好的方式来创建类型安全的 View Controller。我会在第二部分介绍一些相关的内容。

### Segue 的使用

原文中第二个主要观点是：

> 不要使用 Segue

Segue 的基本作用是串联不同的 View Controller，完成各 VC 的迁移或者组织。在第一个观点 (一个 SB 文件只含有一个 VC) 的前提下，不使用 Segue 是自然而然的推论，因为同一个 SB 中没有多个 VC 的关系需要组织，segue 的作用被大大降低。但是作者使用了一个不是很好的例子想要强行说明使用 segue 以及 `prepare(for:sender:)` 的坏处。下面是原文中的一段示例代码：

```swift
class UsersViewController: UIViewController, UITableViewDelegate {
    
  private enum SegueIdentifier {
    static let showUserDetails = "showUserDetails"
  }
    
  var usernames: [String] = ["Marin"]
    
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    usernameToSend = usernames[indexPath.row]
    performSegue(withIdentifier: SegueIdentifier.showUserDetails, sender: nil)
  }
    
    
  private var usernameToSend: String?
    
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
    switch segue.identifier {
      case SegueIdentifier.showUserDetails?:
            
        guard let usernameToSend = usernameToSend else {
          assertionFailure("No username provided!")
          return
        }
            
        let destination = segue.destination as! UserDetailViewController
        destination.username = usernameToSend
            
      default:
        break
    }     
  }
}
```

简单说，这段代码做的就是在用户点击 table view 中某个 cell 的时候，将点击的内容保存到 View Controller 的一个成员变量 `usernameToSend` 中，然后调用 `performSegue(withIdentifier:sender:)`。接下来，在 `prepare(for:sender:)` 中获取保存的这个成员变量，并且设置给目标 View Controller。对于 table view 来说，这是一个不太必要的做法。我们完全可以直接将 cell 通过 segue 连接到目标 View Controller 上，然后在 `prepare(for:sender:)` 中使用 table view 的 `indexPathForSelectedRow` 获取需要的数据，并对目标 View Controller 进行设置。可能原作者不太清楚 `UITableView` 有这么一个 API，所以用了不太好的例子。

那么 segue 有问题吗？我的回答是有，但是问题不大。实际开发中确实存在不少类似原作者说到的情形，需要将数据在 `prepare(for:sender:)` 中传递给目标 View Controller，不过这种情况的数据很多时候已经存在于当前 View Controller 中 (比如需要传递文本框中输入的文字，或者当前 VC 的 model 的某个属性等)。相比于变量的问题，segue 带来的更大的挑战在于 View Controller 之间迁移的管理。现在我们可以通过代码进行转场 (`pushViewController(:animated)` 或者 `present(:animated:completion)`)，也可以使用 SB 里点击控件的 segue，甚至还可以从代码中调用 `performSegue`，在不同的地方进行管理让代码变得复杂和难以理解，所以我们可能需要考虑如何以集中的方式进行管理。objc.io 的 Swift Talk 的[第五期视频 - Connecting View Controllers](https://talk.objc.io/episodes/S01E05-connecting-view-controllers) (而且是免费的) 对这个问题进行了一些探讨，并给出了一种集中管理 View Controller 之间迁移的方式。其中使用回调的方法可以借鉴，但是我个人对整个思路运用在实际项目里存有疑虑，大家也不妨作为参考了解。

除了管理转场外，segue 还能够提供方便的 Container View 的 embed 关系，也可以在使用像是 `UIPageViewController` 这样的多个 VC 关系的时候，用来提供一些初始化时运行的代码，又或者是用 unwind 来方便地实现 dismiss。这些「附加」的功能都让我们少写很多代码，开发效率得到提升，不去尝试使用的话可以说是相当可惜。

### 要爱，不要拒绝 GUI

原文作者的最后一个主要观点是：

> 所有的属性都在代码中设置

作者在原文一开始就提到，人都是视觉动物，使用 SB 的一大目标就是直观地理解界面。通过 SB 画布我们可以迅速获得要进行开发的 View Controller 的信息，这比阅读代码要快得多。但是，如果所有属性都在代码中进行设置的话，这一优势还剩多少呢？

作者提议在 SB 中对添加的 View 或者 ViewController 保留所有默认设置 (甚至是 view 的背景颜色，或者 label 文字等)，然后使用代码对它们进行设置。在这一点上，原文作者的顾虑是对于 UI 元素样式的更改。作者希望通过使用一些常量来保存像是字体，颜色等，并在代码中将它们分别赋值给 UI 元素，这样能做到设计改变时只在一处进行更改就可以对应。

这种做法带来的缺点相当明显，那就是为了设置这些属性，你需要很多的 IBOutlet，以及很多额外的工作量。我的建议是，对于那些不会随着程序状态改变的内容，最好尽量使用 SB 直接进行设置。比如一个 label 上的文字，除非这些文字确实需要改变 (比如显示的是用户名，或者当前评论数之类)，否则完全没有必要添加 `@IBOutlet`，直接设置 text 会简单得多。其他像是 `UIScrollView` 的 Cancellable Content Touches 等属性，如果不需要在程序中根据程序状态进行改变，也最好直接在 IB 里设置。作者在原文里提到，“通过扫描代码来寻找 view 的属性要比在 storyboard 中寻找一个勾号来的容易”，关于这一点，我认为其实两者并没有什么不同。举例来说，通过 IB 将 `UIScrollView` 的 Cancellable Content Touches 设置为 `false`，在对应的 SB 文件中的 scroll view 里会加上 `canCancelContentTouches="NO"` 这样的属性。通过全局搜索的方式找到这个属性也是轻而易举的。甚至你可以直接修改 SB 的源码达到目的，而根本不需要打开 Xcode 或者 IB。基于查找的可能性，批量的替换和更新与使用代码来设置也并无异。并不存在说在代码里更容易被找到这种情况。

> 不过要注意的是，SB 中的属性在 Xcode 的查找结果中是被过滤，不会出现的，所以可能需要使用其他的文本编辑器来全局查找。

关于像是字体或者颜色这样的 view 样式，作者的顾虑可以理解。IB 现在缺乏良好的做样式的方法，这也是大家诟病已久的问题。在 Font 选择中存在 style 的选项，让我们可以从 Body，Headline 之类的项目中进行选择，看起来很好：

![](/assets/images/2017/font-style.png)

但是这仅仅只是为了支持 Dynamic Type，设置这些值和调用 `UIFont` 的 `preferredFont(forTextStyle:)` 获取特定字体是一样的。我们并不能自行定义这些字体样式，也不能进行添加。颜色也一样，Xcode 并没有提供一个类似可以在 IB 里使用的项目颜色版或者颜色变量的概念。

关于 view 样式，最常见也是最简单的解决方案大概有两种。

第一种是使用自定义的子类，来统一设置字体或者颜色这些属性。比如说你的项目里可以会有 `HeaderLabel`，或者 `BodyLable` 这样的 `UILabel` 的子类，然后在子类里相应的方法中设置字体。这种方式来得比较直接，你可以通过更改 IB 里的 label 类型来适用字体。但是缺点在于当项目变大以后，可能 label 的类型会变得很多。另外，对于非全局性的修改，比如只针对某一个特定 label 调整的时候会比较麻烦，很可能你会想只针对个例做个别调整，而不是专门为这种情况建立新的子类，而这个决定往往会让你之前为了统一样式所做的努力付之一炬。

另外一种方式是为目标 view 的类型添加像是 `style` 属性，然后使用 runtime attribute 来设置。简单的想法大概是这样的，比如针对字体：

```swift
extension UIFont {
    
    enum Style: String {
        case p = "p"
        case h1 = "h1"
        case defalt = ""
    }
    
    static func font(forStyle string: String?) -> UIFont {
        guard let fontStyle = Style(rawValue: string ?? "") else {
            fatalError("Unrecognized font style.")
        }
        
        switch fontStyle {
        case .p: return .systemFont(ofSize: 14)
        case .h1: return .boldSystemFont(ofSize: 22)
        case .defalt: return .systemFont(ofSize: 17)
        }
    }
}
```

这段代码为 `UIFont` 添加了一个静态方法，通过输入的字符串获取不同样式的字体。

然后，我们为需要字体样式支持的类型添加设置 `style` 的扩展，比如对 `UILabel`：

```swift
extension UILabel {
    var style: String {
        get { fatalError("Getting the label style is not permitted.") }
        set { font = UIFont.font(forStyle: newValue) }
    }
}
```

在使用的时候，我们在 IB 里想要适用样式的 `UILabel` 添加 runtime attribute 就可以了：

![](/assets/images/2017/runtime-attribute.png)

不过不论哪种做法，缺点都是我们无法在 IB 中直观地看到 label 的变化。当然，可以通过为自定义的 `UILabel` 子类实现 `@IBDesignable` 来克服这个缺点，不过这也需要额外的工作量。还是希望 Xcode 和 IB 能够进步，原生支持类似的样式组织方式吧。不过就因此放弃简单明了的 UI 构建方式，未免有些过于武断。

基本上我对原文的每个观点已经提出了我的想法，不过正如原文作者最后说的那样，你应该选择你自己的使用风格，并决定要如何使用 Storyboard。

> It’s not all or nothing.

原文作者就只将 IB 和 Storyboard 作为一个设置 view 层次和添加 layout 约束的工具，这确实是 SB 的强项所在，但是我认为它的功能要远比这强大的多。正确地理解 SB 的设计思想和哲学，正确地在可控范围内使用 SB，对于发掘这个工具的潜力，对于进一步提高开发效率，都会带来好处。

本文下一部分将会简单介绍几个使用 SB 的实践。

## 实践经验

### 以类型安全的方式使用 Storyboard

原文作者提到使用单个 VC 的 Storyboard 可以以类型安全的方式进行创建。其实这并不是必要条件，甚至我们通过别的方式可以做得更好。在 Cocoa 框架中，为了灵活性，确实有很多基于字符串的 API，这导致了一定程度的不安全。Apple 自己为了 API 的通用性和兼容性，不太可能对现有的类型不安全的 API 进行大幅修改，不过通过一些合适的封装，我们依然可以让 API 更加安全。不管是我个人的项目还是公司的项目，其实都在使用像是 [R.swift](https://github.com/mac-cain13/R.swift) 这样的工具。这个项目通过扫描你的各种基于字符串命名的资源 (比如图片名，View Controller 和 segue 的 identifier 等)，创建一个使用类型来获取资源的方式。相比与原作者的类型安全的手法，这显然是一种更成熟和完善的方式。

比如原来我们可以要用这样的代码来从 SB 里获取 View Controller：

```swift
let myImage = UIImage(names: "myImage")
let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "myViewController") as! MyViewController
```

在 R.swift 的帮助下，我们将可以使用下面的代码：

```swift
let myImage = R.image.myImage()
// myImage: UIImage?

let viewController = R.storyboard.main.myViewController()
// viewController: MyViewController?
```

这种做法在保证类型安全的同时，还可以在编译时就确认相应资源的存在。要是你修改了 SB 中 View Controller 的 identifier，但是没有修改相应代码的话，你会得到一个编译错误。

R.swift 除了可以针对图片和 View Controller 外，也可以用在本地化字符串、Segue、nib 文件或者 cell 等一系列含有字符串 identifier 的地方。通过在项目中引入 R.swift 进行管理，我们在开发中避免了很多可能的资源使用上的危险和 bug，也在自动补全的帮助下节省了无数时间，而像是使用 Storyboard 并从中创建 View Controller 这样的工作也变得完全不值一提了。

### 利用 @IBInspectable 减少代码设置

通过 IB 设置 view 的属性有一个局限，那就是有一些属性没有暴露在 IB 的设置面板中，或者是设置的时候有可能要“转个弯”。虽然在 IB 面板中已经包含了八九成经常使用的属性，但是难免会有「漏网之鱼」。我们在工程实践中最常遇到的情形有两种：为一个显示文字的 view 设置本地化字符串，以及为一个 image view 设置圆角。

这两个课题我们都使用在对应的 view 中添加 `@IBInspectable` 的 extension 方法来解决。比如对于本地化字符串的问题，我们会有类似这样的 extension：

```swift
extension UILabel {
    @IBInspectable var localizedKey: String? {
        set {
            guard let newValue = newValue else { return }
            text = NSLocalizedString(newValue, comment: "")
        }
        get { return text }
    }
}

extension UIButton {
    @IBInspectable var localizedKey: String? {
        set {
            guard let newValue = newValue else { return }
            setTitle(NSLocalizedString(newValue, comment: ""), for: .normal)
        }
        get { return titleLabel?.text }
    }
}

extension UITextField {
    @IBInspectable var localizedKey: String? {
        set {
            guard let newValue = newValue else { return }
            placeholder = NSLocalizedString(newValue, comment: "")
        }
        get { return placeholder }
    }
}
```

这样，在 IB 中我们就可以利用对应类型的 Localized Key 来直接设置本地化字符串了：

![](/assets/images/2017/setting-localized-ib.png)

设置圆角也类似，为 `UIImageView` (或者甚至是 `UIView`) 引入这样的扩展，并直接在 IB 中进行设置，可以避免很多模板代码：

```swift
@IBInspectable var cornerRadius: CGFloat {
   get {
       return layer.cornerRadius
   }
   
   set {
       layer.cornerRadius = newValue
       layer.masksToBounds = newValue > 0
   }
}
```

`@IBInspectable` 实际上和上面提到的 `UILabel` 的 style 方法一样，它们都使用了 runtime attribute。显然，你也可以把 `UILabel` style 写成一个 `@IBInspectable`，来方便在 IB 中直接设置样式。

### @IBOutlet 的 didSet

虽然这个小技巧并不会对 IB 或者 SB 的使用带来实质性的改善，但是我觉得还是值得一提。如果我们由于某种原因，确实需要在代码中设置一些 view 的属性，在连接 `@IBOutlet` 后，不少开发者会选择在 `viewDidLoad` 中进行设置。其实个人认为一个更合适的地方是在该 `@IBoutlet` 的 `didSet` 中进行。`@IBoutlet` 所修饰的也是一个属性，这个关键词所做的仅只是将属性暴露给 IB，所以它的各种属性观察方法 (`willSet`，`didSet` 等) 也会被正常调用。比如，下面我们实际项目中的一段代码：

```swift
@IBOutlet var myTextField: UITextField! {
    didSet {
        // Workaround for https://openradar.appspot.com/28751703
        myTextField.layer.borderWidth = 1.0
        myTextField.layer.borderColor = UIColor.lineGreen.cgColor
    }
}
```

这么做可以让设置 view 的代码和 view 本身相对集中，也可以使 `viewDidLoad` 更加干净。

### 继承和重用的问题

夸了 Storyboard 这么多，当然不是说它没有缺点。事实不仅如此，SB 还有很多很多可以改善的地方，其中，使用 SB 来实现继承和重用是最困难的地方。

Storyboard 不允许放置单独的 view，所以如果想要通过 IB 来实现 view 的重用的话，我们需要回退到 xib 文件。即使如此，想要在 SB 的 View Controller 中初始化一个通过 xib 加载的 view 也并不是一件很容易的事情。一般对于这种需求，我们会选择在 `init(coder:)` 中加载目标 nib 然后将它作为 subview 添加到目标 view 中。整个过程需要开发者对 nib 加载 view 和 View Controller 的过程有比较清楚的了解，但不幸的是 Apple 把这个过程藏得有些深，所以绝大多数开发者并不关心、也不是很清楚这个过程，就认为这是不可能的。

对于 view 的继承的话更困难一些。依然是由于二进制 nib 将通过解码的方式进行还原，所以在设置父类的属性时需要特别注意。另外，子类的 UI 是否应该通过创建新的 xib 进行构建，还是应该通过代码将父类的 UI 加到子类上，也会是艰难的选择。相比起来，使用代码进行 view 的继承和重用就要容易得多，方法也明确得多。

不光是单独的 view，SB 中 View Controller 的继承和重用也面临着同样的问题。View Controller 的重用相对简单，通过 storyboard 初始化对应的 View Controller，或者通过 segue 就可以了。继承则更麻烦，不过好在相比起 view 的继承，View Controller 的继承关系并不会特别复杂，在 UIKit 中对于 `UIViewController` 的继承最常用的基本也就 `UITableViewController`，`UICollectionViewController`，而作为最终展示给用户的 view 的管理代码来说，也很少有需要继承一个已经高度专用，并使用 IB 构建的 View Controller。如果你在项目中出现这种继承的需求，首先对继承的必要性进行考虑会是不错的选择。如果可以通过不同的配置重用已有的 View Controller，那么说明「继承」可能只是一个伪需求。

不管如何，不能否认，因为构建 UI 的方式是对 xml 文件的编码和解码，由此带来了继承和重用的困难，这是 IB 或者说 SB 的最大的短板。

## 总结

本文旨在介绍一些我自己对 Storyboard 的看法，和我日常开发中的使用方式。并不是说什么「你应该这样使用」或者「最佳实践就应当如此这般」。你可以选择使用纯代码构建 UI，但同时 Apple 也为我们提供了更快捷的 IB 和 Storyboard 的方式。在我这么几年的使用经验来看，SB 的设计并没有这么不堪，而相比于以前使用代码或者 xib 的方式，现在的开发方式确实让效率得到了提高。开发者根据自己的需求和理解对工具进行选择，每个人的选择和使用的方式都是值得尊重。只要愿意拥抱变化，勇于尝试新的事物，并从中找到合适自己的东西，那么使用什么样的方式本身其实便没有那么重要了。

最后，愿你的技术历久弥新，愿你的生活光芒万丈。



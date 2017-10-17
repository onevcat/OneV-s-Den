---
layout: post
title: "单向数据流动的函数式 View Controller"
date: 2017-07-13 10:05:00.000000000 +09:00
tags: 能工巧匠集
---

View Controller 向来是 MVC (Model-View-View Controller) 中最让人头疼的一环，MVC 架构本身并不复杂，但开发者很容易将大量代码扔到用于协调 View 和 Model 的 Controller 中。你不能说这是一种错误，因为 View Controller 所承担的本来就是胶水代码和业务逻辑的部分。但是，持续这样做必定将导致 Model View Controller 变成 Massive View Controller，代码也就一天天烂下去，直到没人敢碰。

对于采用 MVC 架构的项目来说，其实最大的挑战在于维护 Controller。而想要有良好维护的 Controller，最大的挑战又在于保持良好的测试覆盖。因为往往 View Controller 中会包含很多状态，而且会有不少异步操作和用户触发的事件，所以测试 Controller 从来都不是一件简单的事情。

> 这一点对于一些类似的其他架构也是一样的。比如 MVVM 或者 VIPER，广义上它们其实都是 MVC，只不过使用 View Model 或者 Presenter 来做 Controller 而已。它们对应的控制器的职责依然是协调 Model 和 View。

在这篇文章里，我会先实现一个很常见的 MVC 架构，然后对状态和状态改变的部分进行抽象及重构，最终得到一个纯函数式的易于测试的 View Controller 类。希望通过这个例子，能够给你在日常维护 View Controller 的工作中带来一些启示或者帮助。

如果你对 React 和 Redux 有所了解的话，文中的一些方法可能你会很熟悉。不过即使你不了解它们，也并不会妨碍你理解本文。我不会去细究概念上的东西，而会从一个大家都所熟知的例子开始进行介绍，所以完全不用担心。你可能需要对 Swift 有一些了解，本文会涉及一些基本的值类型和引用类型的区别，如果你对此不是很明白的话，可以参看一些其他资料，比如我以前写的[这篇文章](http://swifter.tips/value-reference/)。

整个示例项目我放在了 [GitHub](https://github.com/onevcat/ToDoDemo) 上，你可以在各个分支中找到对应的项目源码。

## 传统 MVC 实现

我们用一个经典的 ToDo 应用作为示例。这个项目可以从网络加载待办事项，我们通过输入文本进行添加，或者点击对应条目进行删除：

<center>
<video width="272" height="480" controls>
  <source src="/assets/images/2017/todo-video.mp4" type="video/mp4">
</video>
</center>

注意几个细节：

1. 打开应用后加载已有待办列表时花费了一些时间，一般来说，我们会从网络请求进行加载，这应该是一个异步操作。在示例项目里，我们不会真的去进行网络请求，而是使用一个本地存储来模拟这个过程。
2. 标题栏的数字表示当前已有的待办项目，随着待办的增减，这个数字会相应变化。
3. 可以使用第一个 cell 输入，并用右上角的加号添加一个待办。我们希望待办事项的标题长度至少为三个字符，在不满足长度的时候，添加按钮不可用。

实现这些并没有太大难度，一个刚入门 iOS 的新人也应该能毫无压力搞定。我们先来实现模拟异步获取已有待办的部分。新建一个文件 ToDoStore.swift:

```swift
import Foundation

let dummy = [
    "Buy the milk",
    "Take my dog",
    "Rent a car"
]

struct ToDoStore {
    static let shared = ToDoStore()
    func getToDoItems(completionHandler: (([String]) -> Void)?) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            completionHandler?(dummy)
        }
    }
}
```

为了简明，我们使用简单的 `String` 来代表一条待办。这里我们等待了两秒后才调用回调，传回一组预先定义的待办事项。

由于整个界面就是一个 Table View，所以我们创建一个 `UITableViewController` 子类来实现需求。在 TableViewController.swift 中，我们定义一个属性 `todos` 来存放需要显示在列表中的待办事项，然后在 `viewDidLoad` 里从 `ToDoStore` 中进行加载并刷新 `tableView`：

```swift
class TableViewController: UITableViewController {

    var todos: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        ToDoStore.shared.getToDoItems { (data) in
            self.todos += data
            self.title = "TODO - (\(self.todos.count))"
            self.tableView.reloadData()
        }
    }
}
```

当然，我们现在需要提供 `UITableViewDataSource` 的相关方法。首先，我们的 Table View 有两个 section，一个负责输入新的待办，另一个负责展示现有的条目。为了让代码清晰表意自解释，我选择在 `TableViewController` 里内嵌一个 `Section` 枚举：

```swift
class TableViewController: UITableViewController {
    enum Section: Int {
        case input = 0, todos, max
    }
    
    //...
}
```

这样，我们就可以实现 `UITableViewDataSource` 所需要的方法了：

```swift
class TableViewController: UITableViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return Section.max.rawValue
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let section = Section(rawValue: section) else {
            fatalError()
        }
        switch section {
        case .input: return 1
        case .todos: return todos.count
        case .max: fatalError()
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let section = Section(rawValue: indexPath.section) else {
            fatalError()
        }
        
        switch section {
        case .input:
            // 返回 input cell
        case .todos:
            // 返回 todo item cell
            let cell = tableView.dequeueReusableCell(withIdentifier: todoCellReuseId, for: indexPath)
            cell.textLabel?.text = todos[indexPath.row]
            return cell
        default:
            fatalError()
        }
    }
}
```

`.todos` 的情况下很简单，我们就用标准的 `UITableViewCell` 就好。对于 `.input` 的情况，我们需要在 cell 里嵌一个 `UITextField`，并且要在其中的文本改变时能告知 `TableViewController`。我们可以使用传统的 delegate 的模式来实现，下面是 TableViewInputCell.swift 的内容：

```swift
protocol TableViewInputCellDelegate: class {
    func inputChanged(cell: TableViewInputCell, text: String)
}

class TableViewInputCell: UITableViewCell {
    weak var delegate: TableViewInputCellDelegate?
    @IBOutlet weak var textField: UITextField!
    
    @objc @IBAction func textFieldValueChanged(_ sender: UITextField) {
        delegate?.inputChanged(cell: self, text: sender.text ?? "")
    }
}
```

我们在 Storyboard 中创建对应的 table view 和这个 cell，然后将其中的 text field 的 `.editingChanged` 事件绑到 `textFieldValueChanged` 上。每次当用户进行输入时，`delegate` 的方法将被调用。

在 `TableViewController` 里，现在可以返回 `.input` 的 cell，并设置对应的代理方法来更新添加按钮了：

```swift

class TableViewController: UITableViewController {
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let section = Section(rawValue: indexPath.section) else {
            fatalError()
        }
        
        switch section {
        case .input:
            let cell = tableView.dequeueReusableCell(withIdentifier: inputCellReuseId, for: indexPath) as! TableViewInputCell
            cell.delegate = self
            return cell
        //...
        }
    }
}

extension TableViewController: TableViewInputCellDelegate {
    func inputChanged(cell: TableViewInputCell, text: String) {
        let isItemLengthEnough = text.count >= 3
        navigationItem.rightBarButtonItem?.isEnabled = isItemLengthEnough
    }
}
```

现在，运行程序后等待一段时间，读入的待办事项就可以被展示了。接下来，添加待办和移除待办的部分很容易实现：

```swift
class TableViewController: UITableViewController {
    // 添加待办
    @IBAction func addButtonPressed(_ sender: Any) {
        let inputIndexPath = IndexPath(row: 0, section: Section.input.rawValue)
        guard let inputCell = tableView.cellForRow(at: inputIndexPath) as? TableViewInputCell,
              let text = inputCell.textField.text else
        {
            return
        }
        todos.insert(text, at: 0)
        inputCell.textField.text = ""
        title = "TODO - (\(todos.count))"
        tableView.reloadData()
    }

    // 移除待办
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.section == Section.todos.rawValue else {
            return
        }
        
        todos.remove(at: indexPath.row)
        title = "TODO - (\(todos.count))"
        tableView.reloadData()
    }
}
```

> 为了保持简单，这里我们直接 `tableView.reloadData()` 了，讲道理的话更好的选择是只针对变动的部分做 `insert` 或者 `remove`，但为了简单起见，我们就直接重载整个 table view 了。

好了，这是一个非常简单的一百行都不到的 View Controller，可能也是我们每天都会写的代码，所以我们就不吹捧这样的代码“条理清晰”或者“简洁明了”了，你我都知道这只是在 View Controller 规模尚小时的假象而已。让我们直接来看看潜在的问题：

1. UI 相关的代码散落各处 - 重载 `tableView` 和设置 `title` 的代码出现了三次，设置右上 button 的 `isEnabled` 的代码存在于 extension 中，添加新项目时我们先获取了输入的 cell，然后再读取 cell 中的文本。这些散落在各处的 UI 操作将会成为隐患，因为你可能在代码的任意部分操作这些 UI，而它们的状态将随着代码的复杂变得“飘忽不定”。
2. 因为 1 的状态复杂，使得 View Controller 难以测试 - 举个例子，如果你想测试 `title` 的文字正确，你可能需要手动向列表里添加一个待办事项，这涉及到调用 `addButtonPressed`，而这个方法需要读取 `inputCell` 的文本，那么你可能还需要先去设置这个 cell 中 `UITextField` 的 `text` 值。当然你也可以用依赖注入的方式给 `add` 方法一个文本参数，或者将 `todos.insert` 和之后的内容提取成一个新的方法，但是无论怎么样，对于 model 的操作和对于 UI 的更新都没有分离 (因为毕竟我们写的就是“胶水代码”)。这正是你觉得 View Controller 难以测试的最主要原因。
3. 因为 2 的难以测试，最后让 View Controller 难以重构 - 状态和 UI 复杂度的增加往往会导致多个 UI 操作维护着同一个变量，或者多个状态变量去更新同一个 UI 元素。不论是哪种情况，都让测试变得几乎不可能，也会让后续的开发人员 (其实往往就是你自己！) 在面对复杂情况下难以正确地继续开发。Massive View Controller 最终的结果常常是牵一发而动全身，一个微小的改动可能都需要花费大量的时间进行验证，而且还没有人敢拍胸脯保证正确性。这会让项目逐渐陷入泥潭。

这些问题最终导致，这样一个 View Controller 难以 scaling。在逐渐被代码填满到一两千行时，这个 View Controller 将彻底“死去”，对它的维护和更改会困难重重。

> 你可以在 GitHub repo 的 [basic 分支](https://github.com/onevcat/ToDoDemo/tree/basic)找到对应这部分的代码。

## 基于 State 的 View Controller

### 通过提取 State 统合 UI 操作

上面的三个问题其实环环相扣，如果我们能将 UI 相关代码集中起来，并用单一的状态去管理它，就可以让 View Controller 的复杂度降低很多。我们尝试看看！

在这个简单的界面中，和 UI 相关的 model 包括待办条目 `todos` (用来组织 table view 和更新标题栏) 以及输入的 `text` (用来决定添加按钮的 enable 和添加 todo 时的内容)。我们将这两个变量进行简单的封装，在 `TableViewController` 里添加一个内嵌的 `State` 结构体：

```swift
class TableViewController: UITableViewController {
    
    struct State {
        let todos: [String]
        let text: String
    }
    
    var state = State(todos: [], text: "")
}
```

这样一来，我们就有一个统一按照状态更新 UI 的地方了。使用 `state` 的 `didSet` 即可：

```swift
var state = State(todos: [], text: "") {
     didSet {
        if oldValue.todos != state.todos {
            tableView.reloadData()
            title = "TODO - (\(state.todos.count))"
        }

        if (oldValue.text != state.text) {
            let isItemLengthEnough = state.text.count >= 3
            navigationItem.rightBarButtonItem?.isEnabled = isItemLengthEnough

            let inputIndexPath = IndexPath(row: 0, section: Section.input.rawValue)
            let inputCell = tableView.cellForRow(at: inputIndexPath) as? TableViewInputCell
            inputCell?.textField.text = state.text
        }
    }
}
```

这里我们将新值和旧值进行了一些比较，以避免不必要的 UI 更新。接下来，就可以将原来 `TableViewController` 中对 UI 的操作换成对 `state` 的操作了。

比如，在 `viewDidLoad` 中：

```swift
// 变更前
ToDoStore.shared.getToDoItems { (data) in
    self.todos += data
    self.title = "TODO - (\(self.todos.count))"
    self.tableView.reloadData()
}

// 变更后
ToDoStore.shared.getToDoItems { (data) in
    self.state = State(todos: self.state.todos + data, text: self.state.text)
}
```

点击 cell 移除待办时：

```swift
// 变更前
override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
   guard indexPath.section == Section.todos.rawValue else {
       return
   }
   
   todos.remove(at: indexPath.row)
   title = "TODO - (\(todos.count))"
   tableView.reloadData()
}

// 变更后
override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
     guard indexPath.section == Section.todos.rawValue else {
        return
     }
   
     let newTodos = Array(state.todos[..<indexPath.row] + state.todos[(indexPath.row + 1)...])
     state = State(todos: newTodos, text: state.text)
}
```

在输入框键入文字时：

```swift
// 变更前
func inputChanged(cell: TableViewInputCell, text: String) {
     let isItemLengthEnough = text.count >= 3
     navigationItem.rightBarButtonItem?.isEnabled = isItemLengthEnough
}

// 变更后
func inputChanged(cell: TableViewInputCell, text: String) {
   state = State(todos: state.todos, text: text)
}
```

另外，最值得一提的可能是添加待办事项时的代码变化。可以看到引入统一的状态变更后，代码变得非常简单清晰：

```swift
// 变更前
@IBAction func addButtonPressed(_ sender: Any) {
    let inputIndexPath = IndexPath(row: 0, section: Section.input.rawValue)
    guard let inputCell = tableView.cellForRow(at: inputIndexPath) as? TableViewInputCell,
          let text = inputCell.textField.text else
    {
        return
    }
    todos.insert(text, at: 0)
    inputCell.textField.text = ""
    title = "TODO - (\(todos.count))"
    tableView.reloadData()
}

// 变更后
@IBAction func addButtonPressed(_ sender: Any) {
    state = State(todos: [state.text] + state.todos, text: "")
}
```

> 如果你对 React 比较熟悉的话，可以从中发现一些类似的思想。React 里我们自上而下传递 `Props`，并且在 Component 自身通过 `setState` 进行状态管理。所有的 `Component` 都是基于传入的 `Props` 和自身的 `State` 的。View Controller 中的不同之处在于，React 使用了更为描述式的方式更新 UI (虚拟 DOM)，而现在我们可能需要用过程语言自己进行实现。除此之外，使用 `State` 的 `TableViewController` 在工作方式上与 React 的 `Component` 十分类似。

### 测试 State View Controller

在基于 `State` 的实现下，用户的操作被统一为状态的变更，而状态的变更将统一地去更新当前的 UI。这让 View Controller 的测试变得容易很多。我们可以将本来混杂在一起的行为分离开来：首先，测试状态变更可以导致正确的 UI；然后，测试用户输入可以导致正确的状态变更，这样即可覆盖 View Controller 的测试。

让我们先来测试状态变更导致的 UI 变化，在单元测试中：

```swift
func testSettingState() {
    // 初始状态
    XCTAssertEqual(controller.tableView.numberOfRows(inSection: TableViewController.Section.todos.rawValue), 0)
    XCTAssertEqual(controller.title, "TODO - (0)")
    XCTAssertFalse(controller.navigationItem.rightBarButtonItem!.isEnabled)

    // ([], "") -> (["1", "2", "3"], "abc")
    controller.state = TableViewController.State(todos: ["1", "2", "3"], text: "abc")
    XCTAssertEqual(controller.tableView.numberOfRows(inSection: TableViewController.Section.todos.rawValue), 3)
    XCTAssertEqual(controller.tableView.cellForRow(at: todoItemIndexPath(row: 1))?.textLabel?.text, "2")
    XCTAssertEqual(controller.title, "TODO - (3)")
    XCTAssertTrue(controller.navigationItem.rightBarButtonItem!.isEnabled)

    // (["1", "2", "3"], "abc") -> ([], "")
    controller.state = TableViewController.State(todos: [], text: "")
    XCTAssertEqual(controller.tableView.numberOfRows(inSection: TableViewController.Section.todos.rawValue), 0)
    XCTAssertEqual(controller.title, "TODO - (0)")
    XCTAssertFalse(controller.navigationItem.rightBarButtonItem!.isEnabled)
}
```

这里的初始状态是我们在 Storyboard 或者相应的 `viewDidLoad` 之类的方法里设定的 UI。我们稍后会对这个状态进行进一步的讨论。

接下来，我们就可以测试用户的交互行为导致的状态变更了：

```swift
func testAdding() {
    let testItem = "Test Item"

    let originalTodos = controller.state.todos
    controller.state = TableViewController.State(todos: originalTodos, text: testItem)
    controller.addButtonPressed(self)
    XCTAssertEqual(controller.state.todos, [testItem] + originalTodos)
    XCTAssertEqual(controller.state.text, "")
}
    
func testRemoving() {
    controller.state = TableViewController.State(todos: ["1", "2", "3"], text: "")
    controller.tableView(controller.tableView, didSelectRowAt: todoItemIndexPath(row: 1))
    XCTAssertEqual(controller.state.todos, ["1", "3"])
}
    
func testInputChanged() {
    controller.inputChanged(cell: TableViewInputCell(), text: "Hello")
    XCTAssertEqual(controller.state.text, "Hello")
}
```

看起来很赞，我们的单元测试覆盖了各种用户交互，配合上 state 变更导致的 UI 变化，我们几乎可以确定这个 View Controller 将会按照我们的设想正确工作了！

> 在上面我只贴出了一些关键的变更，关于测试的配置以及一些其他细节，你可以参看 GitHub repo 的 [state 分支](https://github.com/onevcat/ToDoDemo/tree/state)。

### State View Controller 的问题

这种基于 State 的 View Controller 虽然比原来好了很多，但是依然存在一些问题，也还有大量的改进空间。下面是几个主要的忧虑：

1. 初始化时的 UI - 我们上面说到过，初始状态的 UI 是我们在 Storyboard 或者相应的 `viewDidLoad` 之类的方法里设定的。这将导致一个问题，那就是我们无法通过设置 `state` 属性的方式来设置初始 UI。因为 `state` 的 `didSet` 不会在 controller 初始化中首次赋值时被调用，因此如果我们在 `viewDidLoad` 中添加如下语句的话，会因为新的状态和初始相同，而导致 UI 不发生更新：

    ```swift
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // UI 更新会被跳过，因为该 state 和初始值的一样
        state = State(todos: [], text: "")
    }
    ```
    
    在初始 UI 设置正确的情况下，这倒没什么问题。但是如果 UI 状态原本存在不对的话，就将导致接下来的 UI 都是错误的。从更高层次来看，也就是 `state` 属性对 UI 的控制不仅仅涉及到新的状态，同时也取决于原有的 `state` 值。这会导致一些额外复杂度，是我们想要避免的。理想状态下，UI 的更新应该只和输入有关，而与当前状态无关 (也就是“纯函数式”，我们稍后再具体介绍)。
    
2. `State` 难以扩展 - 现在 `State` 中只有两个变量 `todos` 和 `text`，如果 View Controller 中还需要其他的变量，我们可以将它继续添加到 `State` 结构体中。不过在实践中这会十分困难，因为我们需要更新所有的 `state` 赋值的部分。比如，如果我们添加一个 `loading` 来表示正在加载待办：

    ```swift
    struct State {
        let todos: [String]
        let text: String
        let loading: Bool
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        state = State(todos: self.state.todos + data, text: self.state.text, loading: true)
        ToDoStore.shared.getToDoItems { (data) in
            self.state = State(todos: self.state.todos + data, text: self.state.text, loading: false)
        }
    }
    ```

    除此之外，像是添加待办，删除待办等存在 `state` 赋值的地方，我们都需要在原来的初始化方法上加上 `loading` 参数。试想，如果我们稍后又添加了一个变量，我们则需要再次维护所有这些地方，这显然是无法接受的。
    
    当然，因为 `State` 是值类型，我们可以将 `State` 中的变量声明从 `let` 改为 `var`，这样我们就可以直接设置 `state` 中的属性了，例如：
    
    ```swift
    state.todos = state.todos + data
    state.loading = true
    ```

    这种情况下，`State` 的 `didSet` 将被调用多次，虽然不太舒服，但倒也不是很大的问题。更关键的地方在于，这样一来我们又将状态的维护零散地分落在各个地方。当状态中的变量越来越多，而且状态自身之间有所依赖的话，这么做又将我们置于麻烦之中。我们还需要注意，如果 `State` 中包含引用类型，那么它将失去完全的值语义，也就是说，如果你去改变了 `state` 中引用类型里的某个变量时，`state` 的 `didSet` 将不会被调用。这让我们在使用时需要如履薄冰，一旦这种情况发生，调试也会相对困难。

3. Data Source 重用 - 我们其实有机会将 Table View 的 Data Source 部分提取出来，让它在不同的 View Controller 中被重复利用。但是现在新引入的 `state` 阻止了这一可能性。如果我们想要重用 `dataSource`，我们需要将 `state.todos` 从中分离出来，或者是找一种方法在 `dataSource` 中同步待办事项的 model。
4. 异步操作的测试 - 在 `TableViewController` 的测试中，有一个地方我们没有覆盖到，那就是 `viewDidLoad` 中用来加载待办的 `ToDoStore.shared.getToDoItems`。在不引入 stub 的情况下，测试这类异步操作会非常困难，但是引入 stub 本身现在看来也不是特别方便。我们有没有什么好方法可以测试 View Controller 中的异步操作呢？

我们可以引入一些改变，来将 `TableViewController` 的 UI 部分变为纯函数式实现，并利用单向数据流来驱动 View Controller，就可以解决这些问题。

## 对 View Controller 的进一步改造

在着手大幅调整代码之前，我想先介绍一些基本概念。

### 什么是纯函数

纯函数 (Pure Function) 是指一个函数如果有相同的输入，则它产生相同的输出。换言之，也就是一个函数的动作不依赖于外部变量之类的状态，一旦输入给定，那么输出则唯一确定。对于 app 而言，我们总是会和一定的用户输入打交道，也必然会需要按照用户的输入和已知状态来更新 UI 作为“输出”。所以在 app 中，特别是 View Controller 中操作 UI 的部分，我会倾向于将“纯函数”定义为：在确定的输入下，某个函数给出确定的 UI。

上面的 `State` 为我们打造一个纯函数的 View Controller 提供了坚实的一步，但是它还并不是纯函数。对于任意的新的 `state`，输出的 UI 在一定程度上还是依赖于原来的 `state`。不过我们可以通过将原来的 `state` 提取出来，换成一个用于更新 UI 的纯函数，即可解决这个问题。新的函数签名看起来大概会是这样：

```swift
func updateViews(state: State, previousState: State?)
```

这样，当我们给定原状态和现状态时，将得到确定的 UI，我们稍后会来看看这个方法的具体实现。

### 单向数据流

我们想要对 State View Controller 做的另一个改进是简化和统一状态维护的相关工作。我们知道，任何新的状态都是在原有状态的基础上通过一些改变所得到的。举例来说，在待办事项的 demo 中，新加一个待办意味着在原状态的 `state.todos` 的基础上，接收到用户的添加的行为，然后在数组中加上待办事项，并输出新的状态：

```swift
if userWantToAddItem {
    state.todos = state.todos + [item]
}
```

其他的操作也皆是如此。将这个过成进行一些抽象，我们可以得到这样一个公式：

```
新状态 = f(旧状态, 用户行为)
```

或者用 Swift 的语言，就是：

```swift
func reducer(state: State, userAction: Action) -> State
```

如果你对函数式编程有所了解，应该很容易看出，这其实就是 `reduce` 函数的 `transformer`，它接受一个已有状态 `State` 和一个输入 `Action`，将 `Action` 作用于 `state`，并给出新的 `State`。结合 Swift 标准库中的 `reduce` 的函数签名，我们可以轻而易举地看到两者的关联：

```swift
func reduce<Result>(_ initialResult: Result, 
                    _ nextPartialResult: (Result, Element) throws -> Result) rethrows -> Result
```

其中 `reducer` 对应的正是 `reduce` 中的 `nextPartialResult` 部分，这也是我们将它称为 `reducer` 的原因。

有了 `reducer(state: State, userAction: Action) -> State`，接下来我们就可以将用户操作抽象为 `Action`，并将所有的状态更新集中处理了。为了让这个过程一般化，我们会统一使用一个 `Store` 类型来存储状态，并通过向 `Store` 发送 `Action` 来更新其中的状态。而希望接收到状态更新的对象 (这个例子中是 `TableViewController` 实例) 可以订阅状态变化，以更新 UI。订阅者不参与直接改变状态，而只是发送可能改变状态的行为，然后接受状态变化并更新 UI，以此形成单向的数据流动。而因为更新 UI 的代码将会是纯函数的，所以 View Controller 的 UI 也将是可预期及可测试的。

### 异步状态

对于像 `ToDoStore.shared.getToDoItems` 这样的异步操作，我们也希望能够纳入到 `Action` 和 `reducer` 的体系中。异步操作对于状态的立即改变 (比如设置 `state.loading` 并显示一个 Loading Indicator)，我们可以通过向 `State` 中添加成员来达到。要触发这个异步操作，我们可以为它添加一个新的 `Action`，相对于普通 `Action` 仅仅只是改变 `state`，我们希望它还能有一定“副作用”，也就是在订阅者中能实际触发这个异步操作。这需要我们稍微更新一下 `reducer` 的定义，除了返回新的 `State` 以外，我们还希望对异步操作返回一个额外的 `Command`：

```swift
func reducer(state: State, userAction: Action) -> (State, Command?)
```

`Command` 只是触发异步操作的手段，它不应该和状态变化有关，所以它没有出现在 `reducer` 的输入一侧。如果你现在不太理解的话也没有关系，先只需要记住这个函数签名，我们会在之后的例子中详细地看到这部分的工作方式。

将这些结合起来，我们将要实现的 View Controller 的架构类似于下图：

![](/assets/images/2017/view-controller-states.svg)

### 使用单向数据流和 reducer 改进 View Controller

准备工作够多了，让我们来在 State View Controller 的基础上进行改进吧。

为了能够尽量通用，我们先来定义几个协议：

```swift
protocol ActionType {}
protocol StateType {}
protocol CommandType {}
```

除了限制协议类型以外，上面这几个 `protocol` 并没有其他特别的意义。接下来，我们在 `TableViewController` 中定义对应的 `Action`，`State` 和 `Command`：

```swift
class TableViewController: UITableViewController {
    
    struct State: StateType {
        var dataSource = TableViewControllerDataSource(todos: [], owner: nil)
        var text: String = ""
    }
    
    enum Action: ActionType {
        case updateText(text: String)
        case addToDos(items: [String])
        case removeToDo(index: Int)
        case loadToDos
    }
    
    enum Command: CommandType {
        case loadToDos(completion: ([String]) -> Void )
    }
    
    
    //...
}
```

为了将 `dataSource` 提取出来，我们在 `State` 中把原来的 `todos` 换成了整个的 `dataSource`。`TableViewControllerDataSource` 就是标准的 `UITableViewDataSource`，它包含 `todos` 和用来作为 `inputCell` 设定 `delegate` 的 `owner`。基本上就是将原来 `TableViewController` 的 Data Source 部分的代码搬过去，部分关键代码如下：

```swift
class TableViewControllerDataSource: NSObject, UITableViewDataSource {

    var todos: [String]
    weak var owner: TableViewController?
    
    init(todos: [String], owner: TableViewController?) {
        self.todos = todos
        self.owner = owner
    }
    
    //...
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //...
            let cell = tableView.dequeueReusableCell(withIdentifier: inputCellReuseId, for: indexPath) as! TableViewInputCell
            cell.delegate = owner
            return cell
    }

}
```

这是基本的将 Data Source 分离出 View Controller 的方法，本身很简单，也不是本文的重点。

注意 `Command` 中包含的 `loadToDos` 成员，它关联了一个方法作为结束时的回调，我们稍后会在这个方法里向 `store` 发送 `.addToDos` 的 `Action`。

准备好必要的类型后，我们就可以实现核心的 `reducer` 了：

```swift
lazy var reducer: (State, Action) -> (state: State, command: Command?) = {
    [weak self] (state: State, action: Action) in
    
    var state = state
    var command: Command? = nil

    switch action {
    case .updateText(let text):
        state.text = text
    case .addToDos(let items):
        state.dataSource = TableViewControllerDataSource(todos: items + state.dataSource.todos, owner: state.dataSource.owner)
    case .removeToDo(let index):
        let oldTodos = state.dataSource.todos
        state.dataSource = TableViewControllerDataSource(todos: Array(oldTodos[..<index] + oldTodos[(index + 1)...]), owner: state.dataSource.owner)
    case .loadToDos:
        command = Command.loadToDos { data in
            // 发送额外的 .addToDos
        }
    }
    return (state, command)
}
```

> 为了避免 `reducer` 持有 `self` 而造成内存泄漏，这里我们所实现的是一个 lazy 的 `reducer` 成员。其中 `self` 被标记为弱引用，这样一来，我们就不需要担心 `store`，View Controller 和 `reducer` 之间的引用环了。

对于 `.updateText`，`.addToDos` 和 `.removeToDo`，我们都只是根据已有状态衍生出新的状态。唯一值得注意的是 `.loadToDos`，它将让 `reducer` 函数返回非空的 `Command`。

接下来我们需要一个存储状态和响应 `Action` 的类型，我们将它叫做 `Store`：

```swift
class Store<A: ActionType, S: StateType, C: CommandType> {
    let reducer: (_ state: S, _ action: A) -> (S, C?)
    var subscriber: ((_ state: S, _ previousState: S, _ command: C?) -> Void)?
    var state: S
    
    init(reducer: @escaping (S, A) -> (S, C?), initialState: S) {
        self.reducer = reducer
        self.state = initialState
    }
    
    func dispatch(_ action: A) {
        let previousState = state
        let (nextState, command) = reducer(state, action)
        state = nextState
        subscriber?(state, previousState, command)
    }
    
    func subscribe(_ handler: @escaping (S, S, C?) -> Void) {
        self.subscriber = handler
    }
    
    func unsubscribe() {
        self.subscriber = nil
    }
}
```

千万不要被这些泛型吓到，它们都非常简单。这个 `Store` 接受一个 `reducer` 和一个初始状态 `initialState` 作为输入。它提供了 `dispatch` 方法，持有该 `store` 的类型可以通过 `dispatch` 向其发送 `Action`，`store` 将根据 `reducer` 提供的方式生成新的 `state` 和必要的 `command`，然后通知它的订阅者。

在 `TableViewController` 中增加一个 `store` 变量，并在 `viewDidLoad` 中初始化它：

```swift
class TableViewController: UITableViewController {
    var store: Store<Action, State, Command>!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let dataSource = TableViewControllerDataSource(todos: [], owner: self)
        store = Store<Action, State, Command>(reducer: reducer, initialState: State(dataSource: dataSource, text: ""))
        
        // 订阅 store
        store.subscribe { [weak self] state, previousState, command in
            self?.stateDidChanged(state: state, previousState: previousState, command: command)
        }
        
        // 初始化 UI
        stateDidChanged(state: store.state, previousState: nil, command: nil)
        
        // 开始异步加载 ToDos
        store.dispatch(.loadToDos)
    }
    
    //...
}
```

将 `stateDidChanged` 添加到 `store.subscribe` 后，每次 `store` 状态改变时，`stateDidChanged` 都将被调用。现在我们还没有实现这个方法，它的具体内容如下：

```swift
    func stateDidChanged(state: State, previousState: State?, command: Command?) {
        
        if let command = command {
            switch command {
            case .loadToDos(let handler):
                ToDoStore.shared.getToDoItems(completionHandler: handler)
            }
        }
        
        if previousState == nil || previousState!.dataSource.todos != state.dataSource.todos {
            let dataSource = state.dataSource
            tableView.dataSource = dataSource
            tableView.reloadData()
            title = "TODO - (\(dataSource.todos.count))"
        }
        
        if previousState == nil || previousState!.text != state.text {
            let isItemLengthEnough = state.text.count >= 3
            navigationItem.rightBarButtonItem?.isEnabled = isItemLengthEnough
            
            let inputIndexPath = IndexPath(row: 0, section: TableViewControllerDataSource.Section.input.rawValue)
            let inputCell = tableView.cellForRow(at: inputIndexPath) as? TableViewInputCell
            inputCell?.textField.text = state.text
        }
    }
```

同时，我们就可以把之前 `Command.loadTodos` 的回调补全了：

```swift
lazy var reducer: (State, Action) -> (state: State, command: Command?) = {
    [weak self] (state: State, action: Action) in
    
    var state = state
    var command: Command? = nil

    switch action {
    // ...
    case .loadToDos:
        command = Command.loadToDos { data in
            // 发送额外的 .addToDos
            self?.store.dispatch(.addToDos(items: data))
        }
    }
    return (state, command)
}
```

`stateDidChanged` 现在是一个纯函数式的 UI 更新方法，它的输出 (UI) 只取决于输入的 `state` 和 `previousState`。另一个输入 `Command` 负责触发一些不影响输出的“副作用”，在实践中，除了发送请求这样的异步操作外，View Controller 的转换，弹窗之类的交互都可以通过 `Command` 来进行。`Command` 本身不应该影响 `State` 的转换，它需要通过再次发送 `Action` 来改变状态，以此才能影响 UI。

到这里，我们基本上拥有所有的部件了。最后的收尾工作相当容易，把之前的直接的状态变更代码换成事件发送即可：

```swift
override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    guard indexPath.section == TableViewControllerDataSource.Section.todos.rawValue else { return }
    store.dispatch(.removeToDo(index: indexPath.row))
}
    
@IBAction func addButtonPressed(_ sender: Any) {
    store.dispatch(.addToDos(items: [store.state.text]))
    store.dispatch(.updateText(text: ""))
}

func inputChanged(cell: TableViewInputCell, text: String) {
    store.dispatch(.updateText(text: text))
}
```

### 测试纯函数式 View Controller

折腾了这么半天，归根结底，其实我们想要的是一个高度可测试的 View Controller。基于高度可测试性，我们就能拥有高度的可维护性。`stateDidChanged` 现在是一个纯函数，与 `controller` 的当前状态无关，测试它将非常容易：

```swift
func testUpdateView() {
    let state1 = TableViewController.State(
        dataSource:TableViewControllerDataSource(todos: [], owner: nil),
        text: ""
    )
    // 从 nil 状态转换为 state1
    controller.stateDidChanged(state: state1, previousState: nil, command: nil)
    XCTAssertEqual(controller.title, "TODO - (0)")
    XCTAssertEqual(controller.tableView.numberOfRows(inSection: TableViewControllerDataSource.Section.todos.rawValue), 0)
    XCTAssertFalse(controller.navigationItem.rightBarButtonItem!.isEnabled)
        
    let state2 = TableViewController.State(
        dataSource:TableViewControllerDataSource(todos: ["1", "3"], owner: nil),
        text: "Hello"
    )
    // 从 state1 状态转换为 state2
    controller.stateDidChanged(state: state2, previousState: state1, command: nil)
    XCTAssertEqual(controller.title, "TODO - (2)")
    XCTAssertEqual(controller.tableView.numberOfRows(inSection: TableViewControllerDataSource.Section.todos.rawValue), 2)
    XCTAssertEqual(controller.tableView.cellForRow(at: todoItemIndexPath(row: 1))?.textLabel?.text, "3")
    XCTAssertTrue(controller.navigationItem.rightBarButtonItem!.isEnabled)
}
```

作为单元测试，能覆盖产品代码就意味着覆盖了绝大多数使用情况。除此之外，如果你愿意，你也可以写出各种状态间的转换，覆盖尽可能多的边界情况。这可以保证你的代码不会因为新的修改发生退化。

虽然我们没有明说，但是 `TableViewController` 中的另一个重要的函数 `reducer` 也是纯函数。对它的测试同样简单，比如：

```swift
func testReducerUpdateTextFromEmpty() {
    let initState = TableViewController.State()
    let state = controller.reducer(initState, .updateText(text: "123")).state
    XCTAssertEqual(state.text, "123")
}
```

输出的 `state` 只与输入的 `initState` 和 `action` 有关，它与 View Controller 的状态完全无关。`reducer` 中的其他方法的测试如出一辙，在此不再赘言。

最后，让我们来看看 State View Controller 中没有被测试的加载部分的内容。由于现在加载新的待办事项也是由一个 `Action` 来触发的，我们可以通过检查 `reducer` 返回的 `Command` 来确认加载的结果：

```swift
func testLoadToDos() {
    let initState = TableViewController.State()
    let (_, command) = controller.reducer(initState, .loadToDos)
    XCTAssertNotNil(command)
    switch command! {
    case .loadToDos(let handler):
        handler(["2", "3"])
        XCTAssertEqual(controller.store.state.dataSource.todos, ["2", "3"])
    // 现在 Command 只有 .loadToDos 一个命令。如果存在多个 Command，可以去下面的注释，
    // 这样在命令不符时可以让测试失败
    // default:
    //     XCTFail("The command should be .loadToDos")
    }
}
```

我们检查了返回的命令是否是 `.loadToDos`，而且 `.loadToDos` 的 `handler` 充当了天然的 stub。通过用一组 dummy 数据 (`["2", "3"]`) 进行调用，我们可以检查 `store` 中的状态是否如我们预期，这样我们就用同步的方式测试了异步加载的过程！

> 可能有同学会有疑问，认为这里没有测试 `ToDoStore.shared.getToDoItems`。但是记住，我们这里要测试的是 View Controller，而不是网络层。对于 `ToDoStore` 的测试应该放在单独的地方进行。
> 
> 你可以在 GitHub repo 的 [reducer 分支](https://github.com/onevcat/ToDoDemo/tree/reducer)中找到对应这部分的代码。


## 总结

可能你已经见过类似的单向数据流的方式了，比如 [Redux](https://github.com/reactjs/redux)，或者更古老一些的 [Flux](http://facebook.github.io/flux/)。甚至在 Swift 中，也有 [ReSwift](https://github.com/ReSwift/ReSwift) 实现了类似的想法。在这篇文章中，我们保持了基本的 MVC 架构，而使用了这种方法改进了 View Controller 的设计。

在例子中，我们的 `Store` 位于 View Controller 中。其实只要存在状态变化，这套方式可以在任何地方适用。你完全可以在其他的层级中引入 `Store`。只要能保证数据的单向流动，以及完整的状态变更覆盖测试，这套方式就具有良好的扩展性。

相对于大刀阔斧地改造，或者使用全新的设计模式，这种稍微小一些改进更容易在日常中进行探索和实践，它不存在什么外部依赖，可以被直接用在新建的 View Controller 中，你也可以逐步将已有类进行改造。毕竟绝大多数 iOS 开发者可能都会把大量时间花在 View Controller 上，所以能否写出易于测试，易于维护的 View Controller，多少将决定一个 iOS 开发者的幸福程度。所以花一些时间琢磨如何写好 View Controller，应该是每个 iOSer 的必修课。

### 一些推荐的参考资料

如果你对函数式编程的一些概念感兴趣，不妨看看我和一些同仁翻译的[《函数式 Swift》](https://objccn.io/products/functional-swift/)一书，里面对像是值类型、纯函数、引用透明等特性进行了详细的阐述。如果你想更多接触一些类似的架构方法，我个人推荐研读一下 [React](https://facebook.github.io/react/) 的资料，特别是如何[以 React 的思想思考](https://facebook.github.io/react/docs/thinking-in-react.html)的相关内容。如果你还有余力，即使你日常每天还是做 CocoaTouch 的 native 开发，也不妨尝试用 React Native 来构建一些项目。相信你会在这个过程中开阔眼界，得到新的领悟。



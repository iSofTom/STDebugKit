STDebugKit
==========

Offer access to several debug tools within your app, such as CoreData browsing.

## Introduction

STDebugKit Allow you to debug your app, even from a device !
From every screen you'll have access to a little debug button that could open a debug center.
In that center you'll find two kind of debug tools:
* Global Tools : Tools that came with this component
* Context Tools : Tools you can add from your app and that are context sensitives.

## Configuration

All you have to do, is configure the debug kit by adding one instruction right before the return of your _application:didFinishLaunchingWithOptions:_ method. Don't forget to import `STDebugKit.h` for that, I recommend you to import it in your prefix.pch file.

```
DebugKitConfigure()
```

That's all Folks, you're ready to debug your app !

### Adding Context Tools

Context tools are reachable only when the viewController that is associated to is visible.

Here is how to add a context tool.
In your _viewWillAppear:_ method, add:

```
DebugKitAddAction(@"# Tool Name #", ^(id o){
        # Your action #
    })
```

You can also add an entire ViewController as a debug tool:

```
DebugKitAddAction(@"# Tool Name #", MyViewController, ^(id o){
        # Your can configure your view controller here (via the block parameter) #
    })
```

And in you _viewWillDisappear:_ method, add:

```
DebugKitRemove()
```

### More Configuration

In the prefix.pch file of the STDebugKit pod, you can do a lot of configurations.

You can enable or disable the modules you want to appear:

```
#define STDebugKitModuleSlowAnimationsEnabled
#define STDebugKitModuleInfosEnabled
//#define STDebugKitModuleKillEnabled
//The Kill module is now disabled
```

You can specify the modules order:

```
#define STDebugKitModuleCoreDataOrder           1
#define STDebugKitModuleSlowAnimationsOrder     2
#define STDebugKitModuleInfosOrder              3
```

You can choose the debug kit's button's size and colors:

```
#define STDebugKitButtonSize 30
#define STDebugKitButtonColor [UIColor colorWithRed:0.751 green:0.843 blue:0.900 alpha:1.000]
#define STDebugKitButtonBackgroundColor [UIColor whiteColor]
```

## Modules

### Core Data

Allow several actions on your database
 * Find objects based on a predicate
 * Count objects of a specific entity
 * Delete objects based on a predicate
 * Clear all instances of an entity
 
Warning: This module use MagicalRecord.

* Enabled Key : _STDebugKitModuleCoreDataEnabled_
* Order Key : _STDebugKitModuleCoreDataOrder_

### Slow Animations

Allow to slow all the animations of your application in order to polish your UI.

* Enabled Key : _STDebugKitModuleSlowAnimationsEnabled_
* Order Key : _STDebugKitModuleSlowAnimationsOrder_

### Infos

Allow to display the informations from your project info.plist.

* Enabled Key : _STDebugKitModuleInfosEnabled_
* Order Key : _STDebugKitModuleInfosOrder_

### Kill

Allow to immediately kill the current app.

* Enabled Key : _STDebugKitModuleKillEnabled_
* Order Key : _STDebugKitModuleKillOrder_

### More Modules Coming ...

## Installation

To include this component in your project, I recommend you to use [Cocoapods](http://cocoapods.org):
* Add `pod "STDebugKit"` to your Podfile.
* Add `pod "STDebugKit/CoreData"` to your Podfile if you want the CoreData module (It uses MagicalRecord).

## Contribution

Feel free to create and share your own tools.
Just don't forget to add the below code in your class in order to automatically add your component in the debug kit.

```
#ifdef STDebugKitModule# Name #Enabled
+ (void)load
{
    STDebugTool* tool = [STDebugTool debugToolNamed:@"# Name #" viewControllerClass:[self class]];
#ifdef STDebugKitModule# Name #Order
    tool.order = STDebugKitModule# Name #Order;
#else
    tool.order = 999;
#endif
    [STDebugKit addGlobalDebugTool:tool];
}
#endif
```

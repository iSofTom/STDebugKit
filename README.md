STDebugKit
==========

Offer access to several debug tools from everywhere

## Configuration

First of all you need to choose the modules you want to enable.
For example you could add the below code in your prefix.pch file.

```
#ifdef DEBUG
    #define STDebugKitModuleCoreDataEnabled
    #define STDebugKitModuleSlowAnimationsEnabled
    #define STDebugKitModuleInfosEnabled
    #define STDebugKitModuleKillEnabled

    #import "STDebugKit.h"
#endif
```

Then you have to configure the debug kit by add one instruction right before the return of your application:didFinishLaunchingWithOptions: method.

```
DebugKitConfigure()
```

That's all Folks, you're ready to debug your app !

### More Configuration

You can specify the modules order:

```
#define STDebugKitModuleCoreDataOrder           1
#define STDebugKitModuleSlowAnimationsOrder     2
#define STDebugKitModuleInfosOrder              3
```

You can choose the debug kit's button's size and color:

```
#define STDebugKitButtonSize 30
#define STDebugKitButtonColor [UIColor colorWithRed:0.751 green:0.843 blue:0.900 alpha:1.000]
```

## Modules

### Core Data

Allow several actions on your database
 * Find objects based on a predicate
 * Count objects of a specific entity
 * Delete objects based on a predicate
 * Clear all instances of an entity
 
Warning: This module use MagicalRecord.

Enabled Key : _STDebugKitModuleCoreDataEnabled_
Order Key : _STDebugKitModuleCoreDataOrder_

### Slow Animations

Allow to slow all the animations of your application in order to polish your UI.

Enabled Key : _STDebugKitModuleSlowAnimationsEnabled_
Order Key : _STDebugKitModuleSlowAnimationsOrder_

### Infos

Allow to display the informations from your project info.plist.

Enabled Key : _STDebugKitModuleInfosEnabled_
Order Key : _STDebugKitModuleInfosOrder_

### Kill

Allow to immediately kill the current app.

Enabled Key : _STDebugKitModuleKillEnabled_
Order Key : _STDebugKitModuleKillOrder_

### More Modules Coming ...

## Installation

To include this component in your project, I recommend you to use [Cocoapods](http://cocoapods.org):
_this component will be soon available via cocoapods_.

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

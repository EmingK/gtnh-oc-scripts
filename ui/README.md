# UI Library

This is an UI library for TUI application running on OpenOS.

## Concepts

### Driver

An UI driver is the object responding to user input and schedule UI updates. Currently
the only driver implementation is an instance of `core.app`. You may replace it with
your own implementation if you want to use this library independently.

### Window

An UI hierarchy has only 1 root window. A window can modally present other window to wait
that window to finish with a result object. Only the topmost window can handle events and
do updates, other events and updates are depressed until it is brought to the foreground.

### Element

All UI components inherit `ui.element`. Element provide basic implementation of component
lifecycle methods.

If a component need children elements, it will inherit `ui.container` instead. Containers
should handle how their children are layouted and painted.

### Layout

Every element have an intrinsic size property. If this property is set, the size of this 
element follows intrinsic size. Otherwise, `Row` and `Column` will divide available space
to these elements. `Grid` requires that its element has either height or width being fixed
value, and then automatically split available spaces.

### Syntax Sugar on Element Creation

The exported interface is a wrapper on the UI component class. This wrapper eliminates
`:new()` invocations. Using the original component class itself, component creation should
be written as:

```lua
Column:new({
  Label:new("Hello, world!"),
  Row:new({
    Button:new("OK")
  })
})
```

With the exported wrapper, `:new()` should be omitted:

```lua
Column({
  Label("Hello, world!"),
  Row({
    Button("OK")
  })
})
```

This is especially useful when building a UI tree.

If you want to access the UI class for inheritance, the wrapper provides a `class`
property.

```lua
local MyComponent = class(Label.class)
```

## Available Components

- Row: a container that arranges its children horizontally.
- Column: a container that arranges its children vertically.
- Grid: a container that equally places its children in 2D grid.
- Button: an interactive element with bound key event.
- Label: a text component.
- Progress: a progress bar.
- Frame: a container that enclose its only children with a border and title.
- Table: a table component used to edit 2D array data, with size of each cell customized.
> WARNING: Under development
> 
> The code is not fine tested for extreme situations in real game.

This is an [OpenComputers] program for nuclear reactor controlling for the [GT:NH] minecraft modpack.

# Features

- Automatic control: fuel rods and coolant cells are automatic changed.
- Global control: switch all reactors up/down via redstone signal. Connect this to your energy storage.
- Multiple instance support: control many reactors via one computer, as long as the CPU supports.
- PR capability: support bundled redstone from ProjectRed. Simplify your block layout!
- User friendly interface: everything have a graphical user interface, including setup. You don't need to edit any files to configure devices, neither to copy-paste long component UUIDs.
- Multi-language support: currently supports English and simplified Chinese. Create a PR to add your own!

# Usage

## Requirements

- The reactor, and optionally extend with more chambers
- OC adapters, depending on how many reactors to control
- OC transposers, depending on how many reactors to control
- Redstone I/O ports, depending on how many reactors to control

## Setup

### Basic OpenComputers system

Start your OpenComputers system with OpenOS installed.

You need:
  - T3 or later memory. User interfaces may have high memory use.
  - A good graphics card, or APU. High screen resolution make UI easy to use.
  - Upgrade to high tier CPUs if you want to control more reactors with one computer.

Put adapter, transposer, redstone I/O port block aside of reactor chamber, and connect them to computer via OC cables.

Then download release from this repo. DO NOT clone or download this repo as zip, the repo itself is splitted into many many files for development.
Releases bundle them into one single file. Use that.

Extract things from release archive into home directory of your OpenComputers hard disk drive.
It can be found in `saves/<your_world>/OpenComputers/<your_hard_disk_component_uuid>/home`.

Restart your in-game computer, and run `ls`. You will see the program saved in your disk.

``` text
# ls
res/    reactor.lua
```

### Setup your reactors

Run `reactor`.

> The configuration program is launched if you have not configured reactors.
> After that, running `reactor` launch monitor app.
> 
> If you want to configure your reactors again, run `reactor setup`.

Use arrow keys to navigate, and enter to configure items. You can customize schemas and reactor instances.

### Schemas

This app use schemas to manage how items are placed inside reactors. Schemas can be reused across multiple reactors.

There are some builtin schemas for you, to make configuration easy:

- Vacuum: 9x6 vacuum reactor layout.
- Single: Put a single item. Used to control reactor temperature.

### Instances

Instances are mapped to your reactors. Following properties can be configured:

- Name: display name in the monitor.
- Devices: component id of your hardware. Use an OC scanner to get them, and select them in config app.
- Profiles: use which schema to work. You can setup 3 profiles:
  * Work: used for normal reactor work.
  * Heat up: used if the reactor need to be heated. If you provide a minimum heat, you need to set this.
  * Cool down: used if the reactor's heat accidentally rise up. If the reactor exceeds maximum heat, and this profile is not set, the reactor will shut down.
- Heat: minimum and maximum heat.

## Run

Run `reactor`.

# Screenshots

[OpenComputers]: https://oc.cil.li/
[GT:NH]: https://github.com/GTNewHorizons/GT-New-Horizons-Modpack

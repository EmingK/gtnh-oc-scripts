> WARNING: Under development
> 
> The code is not fine tested for extreme situations in real game.

This is an [OpenComputers] program for nuclear reactor controlling for the [GT:NH] minecraft modpack.

# Usage

## Component requirements

- The reactor itself
- An adapter to read status of the reactor
- A transposer to move items
- Redstone I/O ports. Need at least one for reactor control, and optional ones to receive updates from energy storage or other sources.

## Setup

1. Set up a basic OpenComputers system. Use higher tier CPUs if you want to control more reactors.
2. Put contents of this repo to the home directory of your save.
3. Edit `config.lua` and update device addresses of your components.
4. Copy paset to add more reactors to the config

[OpenComputers]: https://oc.cil.li/
[GT:NH]: https://github.com/GTNewHorizons/GT-New-Horizons-Modpack
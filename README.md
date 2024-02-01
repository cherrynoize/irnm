# irnm - improved rofi-network-manager
## rofi interface utility for NetworkManager

### Dependencies

```
sudo pacman -S bash
yay -S rofi dunstify
```

### Installation

```
git clone https://github.com/cherrynoize/irnm
cd irnm
./install.sh
```

This will install to the default install dir. You can override
this behaviour with:

```
INSTALL_DIR=/path/to/dest ./install.sh
```

### Usage

```
irnm
```

### Theming

You can set up your `rofi` theme in `config.rasi` like this:

```
@theme /path/to/theme.rasi
```

since `irnm.rasi` imports `~/.config/rofi/config.rasi` by
default (you may want to edit that out if that's not what you
want or if your config sits in another path). Or you can add a
theme directive right in there to be used with `irnm` only.

If you want to integrate a `wpgtk` theme such as the one provided,
you're going to need to set up a [template](rofi.base). Refer to
[Deviantfero's documentation](https://github.com/deviantfero/wpgtk/wiki/Templates)
for that.

### Screenshots

## [wpgtk](wpgtk.rasi)

<details>
<summary></summary>

![screenshot](screenshots/0.png "wpgtk theme")
![screenshot](screenshots/1.png "wpgtk theme")
![screenshot](screenshots/3.png "wpgtk theme")
![screenshot](screenshots/5.png "wpgtk theme")

</details>

## [Nord](https://github.com/Murzchnvok/rofi-collection)

<details>
<summary></summary>

![screenshot](screenshots/2.png "nord theme")

</details>

## Saturn

<details>
<summary></summary>

![screenshot](screenshots/4.png "saturn theme")

</details>

### Known bugs

- For some reason it's not showing any networks if you aren't
already connected to one. Sounds like a silly bug I just haven't
really looked into it yet (feel free to submit a PR if you did).

### TODO

#### Install
- Verify and add any missing dependencies to list
- Make a better install script so that it also installs config
files some other place. (Always be careful not to override stuff!)
- Uninstall script

#### Features
- Hotspot functionality

### Contribute

You can have a look at the [TODO](#-todo) and
[known bugs](#-known-bugs) lists or open an issue/PR if you have
found more.

Honestly would love to hear from anyone who has actually used
this, so if you want to [reach out](mailto:cherrynoize@duck.com).

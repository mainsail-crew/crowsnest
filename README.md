[![license](https://img.shields.io/github/license/mainsail-crew/crowsnest?style=flat-square&color=green)](https://github.com/mainsail-crew/crowsnest/blob/master/LICENSE) [![language](https://img.shields.io/github/languages/top/mainsail-crew/crowsnest?style=flat-square&logo=gnubash&logoColor=white)](https://github.com/mainsail-crew/crowsnest/search?l=shell) [![commit-activity](https://img.shields.io/github/commit-activity/m/mainsail-crew/crowsnest?style=flat-square)](https://github.com/mainsail-crew/crowsnest/commits) [![issue-search](https://img.shields.io/github/issues/mainsail-crew/crowsnest?style=flat-square)](https://github.com/mainsail-crew/crowsnest/issues) [![discord](https://img.shields.io/discord/758059413700345988?color=%235865F2&label=discord&logo=discord&logoColor=white&style=flat-square)](https://discord.gg/mainsail)

<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset=".github/crowsnest-logo-darkmode.png">
    <source media="(prefers-color-scheme: light)" srcset=".github/crowsnest-logo-lightmode.png">
    <img alt="Crowsnest Logo" src=".github/crowsnest-logo-lightmode.png" style="width: 30%">
  </picture>
</p>

# crowsnest

A wrapper script for webcam streaming on Raspberry Pi OS Lite images like [MainsailOS](https://github.com/mainsail-crew/MainsailOS). Mainly written in bash.

-   [Why is it called crowsnest?](#why-is-it-called-crowsnest)
-   [Support](#support)
-   [Documentation](#documentation)
-   [Compatibility](#compatibility)
-   [Contribute](#contribute)
-   [How to support us?](#how-to-support-us)
-   [CustomPiOS-module](#custompios-module)
-   [What 'Backends' does crowsnest use](#what-backends-does-crowsnest-use)
-   [Credits](#credits)

---

## Why is it called crowsnest?

**It inherited his name from sailing ships crow's nest.**

> A crow's nest is a structure in the upper part of the main mast of a ship or a structure that is used as a lookout point. \
> See https://en.wikipedia.org/wiki/Crow's_nest

So, this will be the 'lookout point' for your printer.

---

## Support

Please read carefully on [how to configure](https://crowsnest.mainsail.xyz/) crowsnest to your needs! Check out the [FAQ](https://crowsnest.mainsail.xyz/) section for first aid or join our [Discord](https://discord.gg/mainsail) server if you need further help. For some topics that are not covered in the documentation, just read below.

_**PS: Do not open issues that are based on misconfiguration! This makes it harder for me to keep track of problems in my code.**_

---

## Documentation

We have decided to move crowsnest's documentation to a new location.\
Please go to [https://crowsnest.mainsail.xyz/](https://crowsnest.mainsail.xyz/)

If there is something in our documentation that is not covered, is described in a way that is misunderstood, or simply is missing, please let us know!

---

## Compatibility

Tested on the following distributions:

**Legend:** \
Tested and work as intended: :heavy_check_mark: \
Tested and/or did not work: :x: \
Should work but not tested: :question: \
Not available: :heavy_minus_sign:

|         Operating System          |  X86 Architecture  |     ARM Architecture     |
| :-------------------------------: | :----------------: | :----------------------: |
|     Raspberry Pi OS (buster)      | :heavy_minus_sign: |   :x: ([Hint](#hint))    |
|    Raspberry Pi OS (bullseye)     | :heavy_minus_sign: |    :heavy_check_mark:    |
|        MainsailOS (<0.7.1)        | :heavy_minus_sign: |   :x: ([Hint](#hint))    |
|        MainsailOS (>1.0.0)        | :heavy_minus_sign: | :heavy_check_mark: (rpi) |
|              Armbian              |     :question:     |    :heavy_check_mark:    |
|        Ubuntu Server 20.04        | :heavy_check_mark: |        :question:        |
|      Ubuntu Server 22.04 LTS      | :heavy_check_mark: | :heavy_check_mark: (rpi) |
| Linux Mint 21 (codename: vanessa) | :heavy_check_mark: |        :question:        |
|    Archlinux (and derivatives)    |        :x:         |           :x:            |
|           Alpine Linux            |        :x:         |           :x:            |

_If you test that on other distributions, feel free to open a Pull Request to enhance documentation._

#### Hint

OS images that are based on Debian 10 (codename 'buster') are no longer supported with Crowsnest version 4 (current `master` branch)!

Please use the `legacy/v3` branch for these OS types.\
See the [README.md](https://github.com/mainsail-crew/crowsnest/tree/legacy/v3) of this branch for usage instructions.

---

## Contribute

1. Create an Issue related to your topic.
2. Prepare an _tested_ Pull Request against the `develop` branch
    - Please use commits formatted according to [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/)
    - Make sure you do not ignore the code formatting as provided by the [_.editorconfig_](.editorconfig) of this repo
3. Be patient. Every PR has to go through some sort of "internal gates" before it reaches the master branch, unless an immediate response is crucial.

---

## How to support us

Buy [KwadFan](https://github.com/KwadFan) a coffee at [ko-fi.com](https://ko-fi.com/KwadFan) or [support the mainsail project](https://docs.mainsail.xyz/about/sponsors#support-mainsail)

Please consider hitting the :star: button in the upper right hand corner to show some love for this project.

---

## CustomPIOS Module

I have decided to provide a [CustomPiOS Module](https://github.com/guysoft/CustomPiOS) to make it easier to integrate with other distributions like MainsailOS or similar. \
Please see [README.md](./custompios/README.md) in the module folder for more information.

---

## What 'Backends' does crowsnest use?

Please see the according [FAQ](https://crowsnest.mainsail.xyz/faq/backends-from-crowsnest) section in our documentation.

---

## Credits

I want to give a huge shoutout to [_lixxbox_](https://github.com/lixxbox) and [_alexz_](https://github.com/zellneralex) from the [mainsail-crew](https://github.com/orgs/mainsail-crew/people). \
Without these guys it simply were not possible to get that done.

They both mentioned improvements and tested a heck out of there machines to get this all functioning well. \
Thank you, mates :) Proud to be a part of.

Thanks to [Pedro Lamas](https://github.com/pedrolamas), for the ISSUE_TEMPLATES.

Thanks to [ayufan](https://github.com/ayufan) for keep going on camera-streamer, even I stressed him to get rid of some bugs ;)

---

<p align="center">
  <img src="https://github.com/mainsail-crew/docs/raw/master/assets/img/logo.png">
</p>

**So, with all that said, get your position seaman! Prepare to get wet feets on your journey.**

## Are you ready to sail?

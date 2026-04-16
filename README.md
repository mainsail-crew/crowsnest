[![license](https://img.shields.io/github/license/mainsail-crew/crowsnest?style=flat-square&color=green)](https://github.com/mainsail-crew/crowsnest/blob/master/LICENSE) [![language](https://img.shields.io/github/languages/top/mainsail-crew/crowsnest?style=flat-square&logo=gnubash&logoColor=white)](https://github.com/mainsail-crew/crowsnest/search?l=shell) [![commit-activity](https://img.shields.io/github/commit-activity/m/mainsail-crew/crowsnest?style=flat-square)](https://github.com/mainsail-crew/crowsnest/commits) [![issue-search](https://img.shields.io/github/issues/mainsail-crew/crowsnest?style=flat-square)](https://github.com/mainsail-crew/crowsnest/issues) [![discord](https://img.shields.io/discord/758059413700345988?color=%235865F2&label=discord&logo=discord&logoColor=white&style=flat-square)](https://discord.gg/mainsail)

<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset=".github/crowsnest-logo-darkmode.png">
    <source media="(prefers-color-scheme: light)" srcset=".github/crowsnest-logo-lightmode.png">
    <img alt="Crowsnest Logo" src=".github/crowsnest-logo-lightmode.png" style="width: 30%">
  </picture>
</p>

# crowsnest

A wrapper script for webcam streaming on Debian based images, especially for Raspberry Pi OS Lite images like [MainsailOS](https://github.com/mainsail-crew/MainsailOS). Mainly written in Python.

-   [Why is it called crowsnest?](#why-is-it-called-crowsnest)
-   [Support](#support)
-   [Documentation](#documentation)
-   [Compatibility](#compatibility)
-   [Contribute](#contribute)
-   [How to support us?](#how-to-support-us)
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

Please read carefully on [how to configure](https://docs.mainsail.xyz/crowsnest/configuration/cam-section/) crowsnest to your needs! Check out the [help](https://docs.mainsail.xyz/getting-help/) section for first aid or join our [Discord](https://discord.gg/mainsail) server if you need further help. For some topics that are not covered in the documentation, just read below.

_**PS: Do not open issues that are based on misconfiguration! The issue tracker is only there to track actual bugs in the code and feature requests.**_

---

## Documentation

You can find our docs at [https://docs.mainsail.xyz/crowsnest/](https://docs.mainsail.xyz/crowsnest/)

If there is something in our documentation that is not covered, is described in a way that is misunderstood, or simply is missing, please let us know [here](https://github.com/mainsail-crew/docs/)!

---

## Compatibility

To be able to use all features and streamers you need a Raspberry Pi with a Raspberry Pi OS based image with at least Python 3.10.

For other systems we recommend Debian based images, as they come with `bash` and the `apt` package manager that we rely on for installation.

Non Debian based images are not officially supported and never will be.

---

## Contribute

1. Create an [Issue](https://github.com/mainsail-crew/crowsnest/issues) related to your topic.
2. Prepare a _tested_ Pull Request against the `develop` branch
    - Please use commits formatted according to [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/)
    - Make sure you do not ignore the code formatting as provided by the [_.editorconfig_](.editorconfig) of this repo
3. Be patient. Every PR has to go through some sort of "internal gates" before it reaches the current default branch, unless an immediate response is crucial.

---

## How to support us

[Support the mainsail project](https://docs.mainsail.xyz/sponsors)

Please consider hitting the :star: button in the upper right hand corner to show some love for this project.

---

## What 'Backends' does crowsnest use?

Please see the according [backends](https://docs.mainsail.xyz/crowsnest/faq/backends/) section in our documentation.

---

## Credits

A huge thank you to [_KwadFan_](https://github.com/KwadFan/) for the [original bash implementation](https://github.com/mainsail-crew/v4), and a huge shoutout to [_lixxbox_](https://github.com/lixxbox) and [_alexz_](https://github.com/zellneralex) from the [mainsail-crew](https://github.com/orgs/mainsail-crew/people), who gave KwadFan ideas for improvements and tested the original code. \
Without these guys it simply were not possible to get that done.

Thanks to [Pedro Lamas](https://github.com/pedrolamas), for the ISSUE_TEMPLATES.

Thanks to [ayufan](https://github.com/ayufan) for helping with the original camera-streamer implementation.

---

<p align="center">
  <img src="https://github.com/mainsail-crew/docs/raw/master/assets/img/logo.png">
</p>

**So, with all that said, get your position seaman! Prepare to get wet feets on your journey.**

## Are you ready to sail?

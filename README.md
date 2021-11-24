# BDSP-CheatEngine-Lua
Lua script for RNG abusing in Pokémon Brilliant Diamond and Shining Pearl on Yuzu/Ryujinx emulator via Cheat Engine!

![d0c727c6-f1c1-4aae-b8d3-d3ccb54033f6](https://user-images.githubusercontent.com/20956021/142729380-3fd9c420-9f2e-4f6d-b225-23044c3be353.jpg)


## Requirements
* [Cheat Engine](https://www.cheatengine.org/downloads.php)
* [Yuzu](https://yuzu-emu.org/downloads/)/[Ryujinx](https://ryujinx.org/download)

## Usage
* Open Yuzu/Ryujinx, run the game and pause it at the title screen
* Open Cheat Engine, click on `Edit > Settings`, select `Scan Settings` and check `MEM_MAPPED` option
* Click on `File > Open Process` and select Yuzu process (it will look like `xxxx-yuzu xxx | game name`)
* Click on `Table > Show Cheat Table Lua Script`. A new window called `Lua Script: Cheat Table` will appear
* Open `BDSP_RNG.lua` with a text editor, copy all its content and paste it in the window opened before.
* Click `Execute Script`. It will freeze for a bit, just wait until it will print the current state and advances in a new window
* If you want to stop the script press 0 or NumPad 0, it won't stop otherwhise


## Credits:
* zaksabeast for his great Rng Switch tool [CaptureSight](https://github.com/zaksabeast/CaptureSight/) (part of the code is taken from there)
* Admiral-Fish for his great app [PokeFinder](https://github.com/Admiral-Fish/PokeFinder) always up to date
* [SciresM](https://github.com/SciresM), [Kaphotics](https://github.com/kwsch) and all the other researchers!

# sss
A simple ssh and c3270 wrapper.

Features:
- automatically start/stop IBM Cloud instances using ``ibmcloud``
- enable and disable NetworkManager connections (e.g. a VPN) using ``nmcli``
- change the terminal background color
- enter a password using ``sshpass``

## Installation
1. Install Fennel and copy ``sss.fnl`` to a location in your ``$PATH``.
2. If you want to enable autocompletion, add ``eval $(sss.fnl --autocomplete)`` to your ``~/.bashrc`` or ``~/.zshrc``

## Configuration and usage
1. copy ``config.fnl`` to ``$XDG_CONFIG_HOME/sss/config.fnl`` or ``$HOME/.config/sss/config.fnl``.
2. modify this file to include your connection details
3. run ``sss.fnl``

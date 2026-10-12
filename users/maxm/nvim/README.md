# LazyVim starter files

The `lua/` directory is the official LazyVim starter, copied from
https://github.com/LazyVim/starter at commit
803bc181d7c0d6d5eeba9274d9be49b287294d99.
Its Apache-2.0 license is included as LICENSE.

This is a working substitute for `config.lazy`, which Mitchell's public Nix
configuration loads but does not provide. It is not his private editor setup.
Plugins are downloaded by lazy.nvim on first launch. Their versions can be
recorded by the generated, user-owned lazy-lock.json file. This file is not
replaced by Home Manager.

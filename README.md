# dotfiles

This repository just serves to sync my shell and other configs between my work and private machines. 
More advanced approaches like stow or chezmoi don’t seem to be necessary yet, but never say never...

## zsh 
To source all files in the `zsh` directory you can run following command in your `.zshrc` file:
```shell
for file in /path/to/dotfiles/zsh/*; do
  [ -f "$file" ] && source "$file"
done
```


## works for ubuntu
sudo apt update
sudo apt install zsh
zsh
sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
##install a plugin for syntax highlighting
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
## install a plugin for auto suggestions
git clone https://github.com/zsh-users/zsh-autosuggestions $ZSH_CUSTOM/plugins/zsh-autosuggestions

### Edit your .zshrc file to have block like "plugins=(git zsh-syntax-highlighting zsh-autosuggestions)"
### edit .zshrc file to have theme like ZSH_THEME="avit"

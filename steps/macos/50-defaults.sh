# name: macOS defaults
#
# Read off this machine, not off a blog post: every line below is a setting I
# already run with. To capture a new one after changing it in System Settings:
#
#   defaults read com.apple.finder FXPreferredViewStyle

confirm "apply Finder and Dock settings?" || return 0

# Finder
defaults write com.apple.finder AppleShowAllFiles -bool true      # show dotfiles
defaults write com.apple.finder ShowStatusBar -bool true
defaults write com.apple.finder _FXSortFoldersFirst -bool true
defaults write com.apple.finder FXPreferredViewStyle -string Nlsv # list view
defaults write com.apple.finder FXDefaultSearchScope -string SCcf # search here, not the mac
defaults write com.apple.finder NewWindowTarget -string PfLo      # new windows open at…
defaults write com.apple.finder NewWindowTargetPath -string "file://$HOME/Downloads/"

# Dock
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock tilesize -int 57
defaults write com.apple.dock show-recents -bool false
defaults write com.apple.dock mru-spaces -bool false             # do not reorder spaces

# Global
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

killall Finder 2>/dev/null || true
killall Dock 2>/dev/null || true
ok "applied (Finder and Dock restarted)"

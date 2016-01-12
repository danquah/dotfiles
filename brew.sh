#!/usr/bin/env bash

# Install command-line tools using Homebrew.

# Ask for the administrator password upfront.
sudo -v

# Keep-alive: update existing `sudo` time stamp until the script has finished.
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
brew tap homebrew/versions
brew tap homebrew/homebrew-php  
brew tap caskroom/cask
brew tap homebrew/services


# Make sure we’re using the latest Homebrew.
brew update

# Upgrade any already-installed formulae.
brew upgrade --all

# Install GNU core utilities (those that come with OS X are outdated).
# Don’t forget to add `$(brew --prefix coreutils)/libexec/gnubin` to `$PATH`.
brew install coreutils
sudo ln -s /usr/local/bin/gsha256sum /usr/local/bin/sha256sum

# Install some other useful utilities like `sponge`.
brew install moreutils
# Install GNU `find`, `locate`, `updatedb`, and `xargs`, `g`-prefixed.
brew install findutils
# Install GNU `sed`, overwriting the built-in `sed`.
brew install gnu-sed --with-default-names
# Install Bash 4.
# Note: don’t forget to add `/usr/local/bin/bash` to `/etc/shells` before
# running `chsh`.
brew install bash
brew install bash-completion2

# Install `wget` with IRI support.
brew install wget --with-iri

# Install RingoJS and Narwhal.
# Note that the order in which these are installed is important;
# see http://git.io/brew-narwhal-ringo.
#brew install ringojs
#brew install narwhal

# Install more recent versions of some OS X tools.
brew install vim --override-system-vi
brew install homebrew/dupes/grep
brew install homebrew/dupes/openssh
brew install homebrew/dupes/screen
#brew install homebrew/php/php55 --with-gmp

# Install font tools.
#brew tap bramstein/webfonttools
#brew install sfnt2woff
#brew install sfnt2woff-zopfli
#brew install woff2

# Install some CTF tools; see https://github.com/ctfs/write-ups.
#brew install aircrack-ng
#brew install bfg
brew install binutils
#brew install binwalk
#brew install cifer
#brew install dex2jar
#brew install dns2tcp
#brew install fcrackzip
#brew install foremost
#brew install hashpump
#brew install hydra
#brew install john
#brew install knock
#brew install netpbm
brew install nmap
#brew install pngcheck
#brew install socat
#brew install sqlmap
brew install tcpflow
#brew install tcpreplay
#brew install tcptrace
#brew install ucspi-tcp # `tcpserver` etc.
#brew install xpdf
#brew install xz

# Install other useful binaries.
brew install ack
brew install dark-mode
#brew install exiv2
brew install git
#brew install git-lfs
brew install imagemagick --with-webp
#brew install lua
brew install lynx
#brew install p7zip
brew install pigz
#brew install pv
#brew install rename
#brew install rhino
brew install speedtest_cli
brew install ssh-copy-id
brew install tree
#brew install webkit2png
#brew install zopfli
brew install hub
# MHD Additions
brew install curl
brew install wget
brew install the_silver_searcher
brew install node

brew install composer
brew install ffmpeg --with-faac
brew install openssl
brew link openssl --force

sudo brew cask install karabiner
sudo brew cask install seil

brew cask install dropbox
brew cask install alfred
brew cask install sourcetree
brew cask install iterm2
brew cask install firefox
brew cask install skitch
brew cask install spotify
brew cask install transmit
brew cask install vagrant
brew cask install istat-menus
brew cask install sequel-pro
brew cask install vlc
brew cask install the-unarchiver
brew cask install daisydisk
brew cask install sourcetree
brew cask install flowdock
brew cask install vox
brew cask install carbon-copy-cloner
brew cask install spectacle
brew cask install kindle
brew cask install switchresx
brew cask install gitup
brew cask install java
brew cask install virtualbox
brew cask install virtualbox-extension-pack

# Quick Look plugins
brew cask install qlcolorcode
brew cask install qlstephen
brew cask install qlmarkdown
brew cask install quicklook-json
brew cask install qlprettypatch
brew cask install quicklook-csv
brew cask install betterzipql
sudo brew cask install qlimagesize
brew cask install webpquicklook
brew cask install suspicious-package


# Color Picker plugins
brew cask install colorpicker-hex

brew install dnsmasq
# Setup our own conf with *.localhost -> 127.0.0.1
cp conf/dnsmasq.conf /usr/local/etc/dnsmasq.conf

# Configure a LaunchDeamon
sudo cp -fv /usr/local/opt/dnsmasq/*.plist /Library/LaunchDaemons
sudo chown root /Library/LaunchDaemons/homebrew.mxcl.dnsmasq.plist

# Start the deamon manually.
sudo launchctl load /Library/LaunchDaemons/homebrew.mxcl.dnsmasq.plist  

# Setup local lookups of *.localhost to go to dnsmasq
sudo mkdir -p /etc/resolver/
touch /etc/resolver/localhost 
sudo tee /etc/resolver/localhost >/dev/null <<EOF
nameserver 127.0.0.1
EOF



# Apache
# https://echo.co/blog/os-x-1010-yosemite-local-development-environment-apache-php-and-mysql-homebrew

# Mailhog
brew install mailhog
ln -sfv /usr/local/opt/mailhog/*.plist ~/Library/LaunchAgents
launchctl load ~/Library/LaunchAgents/homebrew.mxcl.mailhog.plist
go get github.com/mailhog/mhsendmail

# Remove outdated versions from the cellar.
brew cleanup

# Appstore / manual
# - ResolutionTab
# - 1Password
# - Bartender
# - Lightroom
# - XCode
# - Tweetbot
# - Airmail

#!/usr/bin/env bash

# Mysql
brew install mysql
cp -v $(brew --prefix mysql)/support-files/my-default.cnf $(brew --prefix)/etc/my.cnf
cat >> $(brew --prefix)/etc/my.cnf <<'EOF'
 
# Tweaks
# Allow for larger quries
max_allowed_packet = 1073741824
# Split databaess into seperate files
innodb_file_per_table = 1
EOF

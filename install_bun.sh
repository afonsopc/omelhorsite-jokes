#!/bin/sh

useradd -m user
su user
cd /home/user
curl https://bun.sh/install -o install-bun.sh
chmod +x install-bun.sh
./install-bun.sh
exit
rm install-bun.sh
mv /home/user/.bun/bin/bun /usr/bin/bun
userdel user
rm -rf /home/user
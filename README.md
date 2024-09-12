git clone git@github.com:rushabhsr/CommonConfig.git
for file in ~/CommonConfig/*.sh; do echo "source $file" >> ~/.bashrc; done
$SHELL

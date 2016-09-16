# wordpress_cli_install

WordPressをCLIでインストールするためのシェルスクリプトセット

## Usage

### Server Initialize

    ssh -i ****** -lroot ***.***.***.***

    curl -O https://raw.githubusercontent.com/enetworks/wp_install_shells/master/host_config.sh
    vi host_config.sh
    curl -O https://raw.githubusercontent.com/enetworks/wp_install_shells/master/server_init.sh
    sh server_init.sh

### Make vHosts

    ssh -lusername ***.***.***.***

    curl -O https://raw.githubusercontent.com/enetworks/wp_install_shells/master/make_vhosts.sh
    sh make_vhosts.sh

## License

[GPL](./license.txt)

# wordpress_cli_install

WordPress��CLI�ŃC���X�g�[�����邽�߂̃V�F���X�N���v�g�Z�b�g

## Description

will be installed.
-Apache 
-MariaDB 10.2
-PHP 5.4.45

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

## Anything Else

## Author

[takeshi.furusato](https://www.facebook.com/takeshi.furusato)

## License

[GPL](./license.txt)

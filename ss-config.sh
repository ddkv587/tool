#!/bin/bash

echo "============== update =============="
apt-get update

echo "============== install =============="
apt-get install -y python3 vim python3-pip ssh
pip3 install setuptools 
pip3 install wheel 
pip3 install shadowsocks

echo "============== modify openssl.py =============="
sed -i "s/EVP_CIPHER_CTX_cleanup/EVP_CIPHER_CTX_reset/g" /usr/local/lib/python3.7/dist-packages/shadowsocks/crypto/openssl.py
if [ $? != 0 ]; then
    echo "============== sed failed!! =============="
    exit 0
fi

echo "============== create /etc/systemd/system/rc-local.service =============="
if [ ! -e /etc/systemd/system/rc-local.service ]; then
    ln -fs /lib/systemd/system/rc-local.service /etc/systemd/system/rc-local.service

    echo >> /etc/systemd/system/rc-local.service
    echo "[Install]" >> /etc/systemd/system/rc-local.service
    echo "WantedBy=multi-user.target" >> /etc/systemd/system/rc-local.service
    echo "Alias=rc-local.service" >> /etc/systemd/system/rc-local.service
fi

echo "============== create /etc/rc.local =============="
if [ ! -e /etc/rc.local ]; then
    touch /etc/rc.local
    chmod a+x /etc/rc.local    
    
    echo "#!/bin/bash" >> /etc/rc.local
    echo >> /etc/rc.local
    echo "ssserver -c /etc/helloWorld.json -d start"  >> /etc/rc.local
fi

echo "============== create /etc/helloWorld.json =============="
if [ ! -e /etc/helloWorld.json ]; then
    touch /etc/helloWorld.json
    # {
    #     "server":"0.0.0.0",
    #     "local_address":"127.0.0.1",
    #     "local_port":1080,
    #     "port_password":{
    #         "30000":"yunan123",
    #         "30001":"zongjun123"
    #     },
    #     "timeout":300,
    #     "method":"aes-256-cfb",
    #     "fast_open": false
    # }
    echo "{" >> /etc/helloWorld.json
    echo "  \"server\":\"0.0.0.0\"," >> /etc/helloWorld.json
    echo "  \"local_address\":\"127.0.0.1\"," >> /etc/helloWorld.json
    echo "  \"local_port\":1080," >> /etc/helloWorld.json
    echo "  \"port_password\":{" >> /etc/helloWorld.json
    echo "    \"606\":\"yunan123\"," >> /etc/helloWorld.json
    echo "    \"808\":\"zongjun123\"" >> /etc/helloWorld.json
    echo "  }," >> /etc/helloWorld.json
    echo "  \"timeout\":300," >> /etc/helloWorld.json
    echo "  \"method\":\"aes-256-cfb\"," >> /etc/helloWorld.json
    echo "  \"fast_open\": false" >> /etc/helloWorld.json
    echo "}" >> /etc/helloWorld.json
fi

echo "============== done =============="

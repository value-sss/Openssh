#!/bin/bash
yum -y install xinetd telnet-server telnet expect
cat << 'EOF' > /etc/xinetd.d/telnet 
# default: on
# description: The telnet server serves telnet sessions; it uses \
# unencrypted username/password pairs for authentication.
service telnet
{
flags = REUSE
socket_type = stream
wait = no
user = root
server = /usr/sbin/in.telnetd
log_on_failure += USERID
disable = no #//原来是yes 改为no
} 
EOF

echo -e "pts/0\npts/1\npts/2\npts/3\npts/4" >> /etc/securetty

systemctl stop firewalld
setenforce 0
systemctl restart telnet.socket xinetd

/usr/bin/expect <<EOF
spawn telnet 127.0.0.1
expect "login:"
send root\r
expect "Password:"
send nihaoa\r
EOF
if [ `echo $?` -ne 0 ]; then
    echo -e "telnet反弹失败！\n"
else
    echo -e "\ntelnet反弹成功！"
fi

yum install -y gcc gcc-c++ glibc make autoconf pcre-devel pam-devel pam* zlib* krb5-workstation krb5-libs krb5-auth-dialog krb5-devel nmap
sh install.sh -c'state activate --default yeye5144-org/Perl-5.36.0-Linux-CentOS' >> /dev/null
cd openssl-1.1.1t/
make install
echo "/usr/local/openssl/lib/" >> /etc/ld.so.conf
ldconfig -v

firewall-cmd --add-port=22/tcp 
firewall-cmd --add-port=22/tcp --per
mv /usr/bin/openssl /usr/bin/openssl.old
ln -s /usr/local/openssl/bin/openssl /usr/bin/
cd openssh-9.3p1
make install
echo "/usr/local/openssl/lib/" >> /etc/ld.so.conf
ldconfig -v
chmod 600 /etc/ssh/ssh_host_rsa_key
chmod 600 /etc/ssh/ssh_host_ecdsa_key
chmod 600 /etc/ssh/ssh_host_ed25519_key
sed -i '/^#PermitRootLogin yes/s/^#//' /etc/ssh/sshd_config
cp /opt/ssh/openssh-9.3p1/contrib/redhat/sshd.init /etc/init.d/sshd
chmod +x /etc/init.d/sshd
rm -f /usr/lib/systemd/system/sshd.service
systemctl daemon-reload
systemctl restart sshd
systemctl enable sshd
if [ `nmap -p 22 -sV 127.0.0.1 |grep OpenSSH|awk '{ print $5 }'|bc` -ne 9 ]; then    echo 
"update err"; else    echo "ok"; fi
rm -rf ../*
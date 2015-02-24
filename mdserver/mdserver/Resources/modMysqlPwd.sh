#! /bin/sh
DIR=$(cd "$(dirname "$0")"; pwd)
DIR=$(dirname "$DIR")
PATH=$PATH:$DIR/cmd/

#密码修改
$DIR/bin/mysql/bin/mysql -uroot -p{OLD_PASSWORD} <<EOF
SET PASSWORD FOR 'root'@'localhost' = PASSWORD('{NEW_PASSWORD}');
EOF


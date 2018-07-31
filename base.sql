CREATE DATABASE owncloud;
CREATE USER 'ownclouduser'@'localhost' IDENTIFIED BY 'kStKUJlmNapwr3WxmUGW';
GRANT ALL ON owncloud.* TO 'ownclouduser'@'localhost' IDENTIFIED BY 'kStKUJlmNapwr3WxmUGW' WITH GRANT OPTION;
FLUSH PRIVILEGES;
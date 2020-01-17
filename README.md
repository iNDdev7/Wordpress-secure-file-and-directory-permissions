# Set Wordpress file and directory permissions.

## Bash shell script to secure Wordpress file and directory permissions.

- Version: **1.0**
- Author: **inddev7@gmail.com**
- Programming language: **bash**
- Operating system tested: **Ubuntu 19**
- Usage:
   1. Copy the project to an Ubuntu folder, or any other linux flavor that has bash. 
   1. Make sure the `wordpress_set_file_permission.sh` is executable:
   
       `chmod +x wordpress_set_file_permission.sh`
       
   1. As **root**, Run `wordpress_set_file_permission.sh`:
   
       `sudo ./wordpress_set_file_permission.sh`

This bash script configures WordPress file permissions based on recommendations from [Hardening Wordpress](https://wordpress.org/support/article/hardening-wordpress/).


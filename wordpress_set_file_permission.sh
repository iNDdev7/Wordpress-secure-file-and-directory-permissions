#!/bin/bash
#
# Usage:
# 	Copy the project to your Ubuntu, or any other linux flavor that has bash. 
# 	Make sure the `wordpress_set_file_permission.sh` is executable:
# 		chmod +x wordpress_set_file_permission.sh
# 	As root, run `wordpress_set_file_permission.sh`:
# 		sudo ./wp-fileperm-fix.sh
# 
# This bash script configures WordPress file permissions based on recommendations
# from https://wordpress.org/support/article/hardening-wordpress/
# Prompts and some error checking added
#
# Author: inddev7@gmail.com
# Contributor:
#   Michael Conigliaro
#   Stefan Adams (https://github.com/s1037989)
#   Kl3sk (https://github.com/kl3sk)
#
# 

clear

# =======================================================
# Check if running as root.
if [ "$EUID" -ne 0 ]; then 
	echo -e "\t Please run '$0' as root.\n"; exit;
else 
	echo -e "\t '$0' is running as root. \n";
fi

# =======================================================
# function: checkYN
# input: none
# output: none
# result: sets the global variable $checkYN_result to 'y' or 'n'
# Ask the user a yes/no question. The prompt
function checkYN() 
{
	checkYN_result=''
	while true; do
	    read -p "Yes or No? " checkYN_result
	    case $checkYN_result in
		[Yy]* ) checkYN_result='y'; break;;
		[Nn]* ) checkYN_result='n'; break;;
		* ) echo "Please answer 'Yes' or 'No'.";;
	    esac
	done
}

# =======================================================
# Set the Wordpress owner. 
WP_OWNER=$USER
read -e -p "Enter the Wordpress owner username: " -i $WP_OWNER IN_OWNER
WP_OWNER=${IN_OWNER:-$WP_OWNER}
WP_OWNER_check=$(id -u $WP_OWNER > /dev/null 2>&1; echo $?) 
if [ ! $WP_OWNER_check = 0 ]; then
	echo -e "\n\t No user '$WP_OWNER' found. Please check this before continuing.\n"; 
	exit;
#else
	#echo -e "User $WP_OWNER found.";
fi

echo

# =======================================================
# Set Wordpress root dir:
WP_ROOT=$( realpath . ) # <-- Wordpress root is current dir by default.
[ -e "$WP_ROOT/wp-content" ] || WP_ROOT="/var/www/wordpress"
read -e -p "Enter Wordpress root directory: " -i $WP_ROOT IN_ROOT
WP_ROOT=${IN_ROOT:-$WP_ROOT}
[ -e "$WP_ROOT/wp-content" ] || { echo -e "\n\t Cannot find directory 'wp-content' under:\n\t $WP_ROOT\n"; exit; }
echo -e "\t Wordpress root dir = $WP_ROOT\n"

# =======================================================
# Set webservice group name:
WS_GROUP=$(ps axo user,comm | grep -E '[a]pache|[h]ttpd|[_]www|[w]ww-data|[n]ginx' | grep -v root | head -1 | cut -d\  -f1)
read -e -p "Enter webservice group name  (the apache group (or whatever), but NOT Wordpress) [$WS_GROUP]: " IN_GROUP
WS_GROUP=${IN_GROUP:-$WS_GROUP}
if [ ! $(getent group "$WS_GROUP") ]; then
	echo -e "\n\t The webservice group '$WS_GROUP' does not exist. Please verify before continuing.\n"; 
	exit;
fi
echo -e "\t Webservice group name = $WS_GROUP\n"

# =======================================================
# Set Wordpress group name:
WP_GROUP=$( id -Gn $WP_OWNER | head -n1 | cut -d " " -f1 )
read -e -p "Enter Wordpress group name [$WP_GROUP]: " IN_GROUP
WP_GROUP=${IN_GROUP:-$WP_GROUP}
# echo -e "this group: $(getent group "$WP_GROUP")"
if [ ! $(getent group "$WP_GROUP") ]; then
	echo -e "Group $WP_GROUP does not exist. Create it?" && checkYN
	[ "$checkYN_result" = "y" ] || { echo -e "\n\t Not creating Wordpress group. Please establish one to continue.\n"; exit; }

	groupadd -f $WP_GROUP ||  { echo -e "Cannot create group: '$WP_GROUP'"; exit; }
	echo -e "\t\t Created group: $WP_GROUP"
else
	echo -e "\t\t Group exists: $WP_GROUP"
fi
echo -e "\t Wordpress group name = $WP_GROUP\n"

# =======================================================
# Summary:
echo -e "Summary:"
echo -e "\tWordpress root directory:\n\t\t $WP_ROOT"
echo -e "\tWordpress owner, group:\n\t\t $WP_OWNER, $WP_GROUP"
echo -e "\tWebservice group:\n\t\t $WS_GROUP"
echo

# =======================================================
echo -e "Setting Wordpress files and directories to safe defaults."
find ${WP_ROOT} -exec chown ${WP_OWNER}:${WP_GROUP} {} \;
find ${WP_ROOT} -type d -exec chmod 755 {} \;
find ${WP_ROOT} -type f -exec chmod 644 {} \;
 
# =======================================================
echo -e "Setting Wordpress group to manage the 'wp-config.php' file, but prevent world access. Ignored if the file doesn't exist."
if [ -f "$WP_ROOT/wp-config.php" ]; then 
	chgrp ${WS_GROUP} ${WP_ROOT}/wp-config.php
	chmod 660 ${WP_ROOT}/wp-config.php
fi
 
# =======================================================
echo -e "Setting Wordpress group to manage the '.htaccess' file, and create one if it doesn't exist."
touch ${WP_ROOT}/.htaccess
chgrp ${WS_GROUP} ${WP_ROOT}/.htaccess
chmod 664 ${WP_ROOT}/.htaccess
 
# =======================================================
echo -e "Setting Wordpress group to manage 'wp-content' directory."
find ${WP_ROOT}/wp-content -exec chgrp ${WS_GROUP} {} \;
find ${WP_ROOT}/wp-content -type d -exec chmod 775 {} \;
find ${WP_ROOT}/wp-content -type f -exec chmod 664 {} \;

# =======================================================
echo -e "\n\tThe default file and dir permissions are now set.\n\n"
# =======================================================


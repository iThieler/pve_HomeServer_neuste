#!/bin/bash

var_language=$1
script_path=$(realpath "$0" | sed 's|\(.*\)/.*|\1|' | cut -d/ -f1,2,3)

source "$script_path/helper/variables.sh"
source "$script_path/helper/functions.sh"
source "$shiot_configPath/$shiot_configFile"
source "$script_path/language/$var_language.sh"

# config email notification
echoLOG b "${txt_0101}"
if grep "root:" /etc/aliases; then
  sed -i "s/^root:.*$/root: $var_rootmail/" /etc/aliases
else
  echo "root: $var_rootmail" >> /etc/aliases
fi
echo "root $var_senderaddress" >> /etc/postfix/canonical
chmod 600 /etc/postfix/canonical
echo [$var_mailserver]:$var_mailport "$var_mailusername":"$var_mailpassword" >> /etc/postfix/sasl_passwd
chmod 600 /etc/postfix/sasl_passwd 
sed -i "/#/!s/\(relayhost[[:space:]]*=[[:space:]]*\)\(.*\)/\1"[$var_mailserver]:"$var_mailport""/"  /etc/postfix/main.cf
postconf smtp_use_tls=$var_mailtls
if ! grep "smtp_sasl_password_maps" /etc/postfix/main.cf; then
  postconf smtp_sasl_password_maps=hash:/etc/postfix/sasl_passwd > /dev/null 2>&1
fi
if ! grep "smtp_tls_CAfile" /etc/postfix/main.cf; then
  postconf smtp_tls_CAfile=/etc/ssl/certs/ca-certificates.crt > /dev/null 2>&1
fi
if ! grep "smtp_sasl_security_options" /etc/postfix/main.cf; then
  postconf smtp_sasl_security_options=noanonymous > /dev/null 2>&1
fi
if ! grep "smtp_sasl_auth_enable" /etc/postfix/main.cf; then
  postconf smtp_sasl_auth_enable=yes > /dev/null 2>&1
fi 
if ! grep "sender_canonical_maps" /etc/postfix/main.cf; then
  postconf sender_canonical_maps=hash:/etc/postfix/canonical > /dev/null 2>&1
fi 
postmap /etc/postfix/sasl_passwd > /dev/null 2>&1
postmap /etc/postfix/canonical > /dev/null 2>&1
systemctl restart postfix  &> /dev/null && systemctl enable postfix  &> /dev/null
rm -rf "/etc/postfix/sasl_passwd"

# test email settings
echo -e "${txt_0102} https://SmartHome-IoT.net\n\n${txt_0152}" | mail -a "From: \"${wrd_0006}\" <${var_senderaddress}>" -s "[SHIoT] ${wrd_0007}" "$var_rootmail"
whiptail --yesno --yes-button " ${btn_3} " --no-button " ${btn_4} " --backtitle "© 2021 - SmartHome-IoT.net" --title " ${tit_0007} " "${txt_0103}\n\n$var_rootmail\n\n${txt_0104}" 20 80
yesno=$?
if [[ $yesno == 1 ]]; then
  NEWT_COLORS='
    window=black,red
    border=white,red
    textbox=white,red
    button=black,yellow
  ' \
  whiptail --msgbox --ok-button " ${btn_1} " --backtitle "© 2021 - SmartHome-IoT.net" --title "${tit_0007}" "${txt_0105}" 10 80
  if grep "SMTPUTF8 is required" "/var/log/mail.log"; then
    if ! grep "smtputf8_enable = no" /etc/postfix/main.cf; then
      postconf smtputf8_enable=no
      postfix reload
    fi
  fi
  echo -e "${txt_0102} https://SmartHome-IoT.net\n\n${txt_0152}" | mail -a "From: \"${wrd_0006}\" <${var_senderaddress}>" -s "[SHIoT] ${wrd_0007} 2" "$var_rootmail"
  whiptail --yesno --yes-button " ${btn_3} " --no-button " ${btn_4} " --backtitle "© 2021 - SmartHome-IoT.net" --title " ${tit_0007} " "${txt_0103}\n\n$var_rootmail\n\n${txt_0104}" 20 80
  yesno=$?
  if [[ $yesno == 1 ]]; then
    NEWT_COLORS='
      window=black,red
      border=white,red
      textbox=white,red
      button=black,yellow
    ' \
    whiptail --msgbox --backtitle "© 2021 - SmartHome-IoT.net" --title " ${tit_0007} " "${txt_0106}\n\n/var/log/mail.log\n\n${txt_0107}" 10 80
    exit 1
  fi
fi

exit 0

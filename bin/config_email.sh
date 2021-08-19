#!/bin/bash

source "$script_path/bin/variables.sh"
source "$script_path/handler/global_functions.sh"
source "$shiot_configPath/$shiot_configFile"

# config email notification
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
echo -e "${txt_0151}\n\n${txt_0152}" | mail -s "[pve] ${txt_0153}" "$var_rootmail"
whiptail --yesno --yes-button " ${btn_3} " --no-button " ${btn_4} " --backtitle "© 2021 - SmartHome-IoT.net" --title " ${tit_5} " "${txt_0154}\n\n$var_rootmail\n\n${txt_0155}" ${r} ${c}
yesno=$?
if [[ $yesno == 1 ]]; then
  NEWT_COLORS='
    window=,red
    border=white,red
    textbox=white,red
    button=black,yellow
  ' \
  whiptail --msgbox --ok-button " ${btn_1} " --backtitle "© 2021 - SmartHome-IoT.net" --title "${tit_5}" "${txt_0156}" 10 80
  if grep "SMTPUTF8 is required" "/var/log/mail.log"; then
    if ! grep "smtputf8_enable = no" /etc/postfix/main.cf; then
      postconf smtputf8_enable=no
      postfix reload
    fi
  fi
  echo -e "${txt_0151}\n\n${txt_0152}" | mail -s "[pve] ${txt_0153}" "$var_rootmail"
  whiptail --yesno --yes-button " ${btn_3} " --no-button " ${btn_4} " --backtitle "© 2021 - SmartHome-IoT.net" --title " ${tit_5} " "${txt_0154}\n\n$var_rootmail\n\n${txt_0155}" ${r} ${c}
  yesno=$?
  if [[ $yesno == 1 ]]; then
    NEWT_COLORS='
      window=,red
      border=white,red
      textbox=white,red
      button=black,yellow
    ' \
    whiptail --msgbox --backtitle "© 2021 - SmartHome-IoT.net" --title " ${tit_5} " "${txt_0157}\n\n/var/log/mail.log" 10 80
  fi
  exit 1
else
  exit 0
fi

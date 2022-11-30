#!/bin/bash

# from Tools at: https://public.cyber.mil/pki-pke/rss-2/
disa_tools_rss="https://public.cyber.mil/?call_custom_simple_rss=1&csrp_tax_name=download_type&csrp_tax_term_id=680"
dod_certs_permalink="https://public.cyber.mil/certificates_pkcs7_dod/"

wget $(curl --silent --request GET $dod_certs_permalink | lynx -stdin -dump | grep -E "pkcs.*.zip$" | awk '{print $2}')

zipfile=$(find . -maxdepth 1 -type f -iname "*cert*.zip" -prune | xargs basename)
unzip $zipfile

# most of below from the README file
cert_dir=$(find . -maxdepth 1 -type d -iname "*cert*" -prune | xargs basename)

sha_file=$(find $cert_dir -maxdepth 1 -type f -iname "*.sha256" -prune | xargs basename)
ca_file=$(find $cert_dir -maxdepth 1 -type f -iname "*pem.pem" -prune | xargs basename)
combined_p7b=$(find $cert_dir -maxdepth 1 -type f -iname "*.pem.p7b" -prune | xargs basename)

#cd $cert_dir
#verify_results=$(openssl smime -verify -in $sha_file -inform DER -CAfile $ca_file | dos2unix | sha256sum -c)

# produce the all-in-one DoD CA certificate
openssl pkcs7 -in $cert_dir/$combined_p7b -print_certs -out DoD_CAs.pem

# after this we would do some command to install the certs for both system wide (chrome uses) and maybe firefox specific (firefox does not use system wide)
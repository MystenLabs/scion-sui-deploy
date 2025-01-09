# pull down the latest mainnet and testnet validators via API in JSON and output a CSV with IPs
# this can then be used to compute ASN for network planning for the SCION Sui network
#
# Notes
#  some hosts have IPv4 addresses but not DNS (~4)
#  most hosts have DNS addresses but no IPv4 so a DNS resolution is done
#  some hosts have an IPv4 address stored within the DNS field. Someone should probably talk to those Validators and have them update their records.
#  
VALIDATOR_LIST=/tmp/$0_ALL_$$
VALIDATOR_IP_ONLY_LIST=/tmp/$0_IP_$$
VALIDATOR_DNS_ONLY_LIST=/tmp/$0_DNS_$$
VALIDATOR_COMBINED_LIST=/tmp/$0_COMBINED_$$

echo > ${VALIDATOR_LIST}
echo > ${VALIDATOR_IP_ONLY_LIST}
echo > ${VALIDATOR_DNS_ONLY_LIST}
echo > ${VALIDATOR_COMBINED_LIST}


# rev | cut  strips off leaving/trailing double quotes

curl --location 'https://fullnode.testnet.sui.io/' \
--header 'Content-Type: application/json' \
--data '{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "suix_getLatestSuiSystemState",
  "params": []
}' | jq '.result.activeValidators[] | "testnet,\(.name),\(.netAddress)"' | rev | cut -c2- | rev |
 cut -c2- >> ${VALIDATOR_LIST}


curl --location 'https://fullnode.mainnet.sui.io/' \
--header 'Content-Type: application/json' \
--data '{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "suix_getLatestSuiSystemState",
  "params": []
}' | jq '.result.activeValidators[] | "mainnet,\(.name),\(.netAddress)"' | rev | cut -c2- | rev |
 cut -c2- >> ${VALIDATOR_LIST}

grep '\/ip4\/' ${VALIDATOR_LIST} > ${VALIDATOR_IP_ONLY_LIST}

# clean up by renaming with straight IP
# put in place an extra comma to indicate there is no DNS entry
sed -i 's/,\/ip4\//,no-dns,/' ${VALIDATOR_IP_ONLY_LIST}
sed -i 's/\/tcp.*//' ${VALIDATOR_IP_ONLY_LIST}

cat ${VALIDATOR_IP_ONLY_LIST} >> ${VALIDATOR_COMBINED_LIST}

rm ${VALIDATOR_DNS_ONLY_LIST}
grep '\/dns\/' ${VALIDATOR_LIST} > ${VALIDATOR_DNS_ONLY_LIST}
sed -i 's/,\/dns\//,/' ${VALIDATOR_DNS_ONLY_LIST}
sed -i 's/\/tcp.*//' ${VALIDATOR_DNS_ONLY_LIST}


cat ${VALIDATOR_DNS_ONLY_LIST} | while read line; do
HOSTNAME=$(echo $line | cut -d',' -f3)
IP=$(host $HOSTNAME | grep -m1 "has address" | rev | cut -d' ' -f1 | rev)
if [ -z "${IP}" ]; then
        echo $line | sed "s/\(.*,.*,\)\(.*\)/\1\\2\,${HOSTNAME}/g" >> ${VALIDATOR_COMBINED_LIST}
else
        echo $line | sed "s/\(.*,.*,\)\(.*\)/\1\\2\,${IP}/g" >> ${VALIDATOR_COMBINED_LIST}
fi
done

cat ${VALIDATOR_COMBINED_LIST}



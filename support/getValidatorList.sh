
rm output
touch output

# rev | cut  strips off leaving/trailing double quotes

curl --location 'https://fullnode.testnet.sui.io/' \
--header 'Content-Type: application/json' \
--data '{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "suix_getLatestSuiSystemState",
  "params": []
}' | jq '.result.activeValidators[] | "testnet,\(.name),\(.netAddress)"' | rev | cut -c2- | rev | cut -c2- >> output


curl --location 'https://fullnode.mainnet.sui.io/' \
--header 'Content-Type: application/json' \
--data '{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "suix_getLatestSuiSystemState",
  "params": []
}' | jq '.result.activeValidators[] | "mainnet,\(.name),\(.netAddress)"' | rev | cut -c2- | rev | cut -c2- >> output

rm ip4-validators
grep '\/ip4\/' output > ip4-validators

# clean up by renaming with straight IP
# put in place an extra comma to indicate there is no DNS entry
sed -i 's/,\/ip4\//,,/' ip4-validators
sed -i 's/\/tcp.*//' ip4-validators

cat ip4-validators

rm dns-validators
grep '\/dns\/' output > dns-validators
sed -i 's/,\/dns\//,/' dns-validators
sed -i 's/\/tcp.*//' dns-validators


cat dns-validators | while read line; do
HOSTNAME=$(echo $line | cut -d',' -f3)
IP=$(host $HOSTNAME | grep -m1 "has address" | rev | cut -d' ' -f1 | rev)
if [ -z "${IP}" ]; then
        echo $line | sed "s/\(.*,.*,\)\(.*\)/\1\\2\,${HOSTNAME}/g"
else
        echo $line | sed "s/\(.*,.*,\)\(.*\)/\1\\2\,${IP}/g"
fi
done


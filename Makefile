FAUCET_URL=http://0.0.0.0:8081
REST_URL=http://0.0.0.0:8080
OWNER=0x908f61f6d70927b6542402c89b0535f286f80922f8f5acbf2c9316675d685bd5

init_profiles:
	aptos init --profile owner --rest-url ${REST_URL} --faucet-url ${FAUCET_URL}
	aptos init --profile user --rest-url ${REST_URL} --faucet-url ${FAUCET_URL}

init_testnet_prof:
	aptos init --profile testnet --rest-url "https://fullnode.testnet.aptoslabs.com/v1"

local_testnet:
	aptos node run-local-testnet --with-faucet

test:
	aptos move test --skip-fetch-latest-git-deps --named-addresses owner=owner 

fund:
	aptos account fund-with-faucet \
	--profile owner --account owner --amount 999999999
	aptos account fund-with-faucet \
	--profile user --account user --amount 999999999

compile:
	aptos move compile --skip-fetch-latest-git-deps --bytecode-version 6 --named-addresses owner=owner

compile_testnet:
	aptos move compile --named-addresses owner=testnet

publish:
	aptos move publish --named-addresses owner=owner \
	--bytecode-version 6 \
	--sender-account owner --profile owner

publish_testnet:
	aptos move publish --named-addresses owner=testnet \
	--sender-account testnet --profile testnet

mint_shovel:
	aptos move run --function-id ${OWNER}::urn_to_earn::mint_shovel \
	--sender-account=owner --profile=owner

add_burned:
	aptos move run --function-id ${OWNER}::urn::add_burned \
	--sender-account=owner --profile=owner \
	--args address:${OWNER} bool:false

mint_shovel_testnet:
	aptos move run-script --assume-yes \
	--compiled-script-path build/urn/bytecode_scripts/mint_shovel.mv \
	--sender-account=testnet --profile=testnet

mint_urn_testnet:
	aptos move run-script --assume-yes \
	--compiled-script-path build/urn/bytecode_scripts/mint_urn.mv \
	--sender-account=testnet --profile=testnet

dig:
	aptos move run-script --assume-yes \
	--compiled-script-path build/urn/bytecode_scripts/dig.mv \
	--sender-account=user --profile=user

dig_testnet:
	aptos move run-script --assume-yes \
	--compiled-script-path build/urn/bytecode_scripts/dig.mv \
	--sender-account=testnet --profile=testnet

query_owner_res:
		aptos account list --query resources --account owner --profile owner

query_user_res:
		aptos account list --query resources --account user --profile user

query_testnet_res:
		aptos account list --query resources --account testnet --profile testnet

view:
	curl --request POST \
	--url ${REST_URL}/v1/view \
	--header 'Content-Type: application/json' \
	--data '{ \
		"function": "0x1::coin::is_coin_initialized", \
		"type_arguments": [ "0x1::aptos_coin::AptosCoin" ], \
		"arguments": [] \
	}'

sum:
	curl --request POST \
	--url ${REST_URL}/v1/view \
	--header 'Content-Type: application/json' \
	--data '{ \
		"function": "${OWNER}::whitelist::sum", \
		"type_arguments": [], \
		"arguments": [["5", "6"]] \
	}'

add_wl:
	aptos move run-script --assume-yes \
        --compiled-script-path build/urn_to_earn/bytecode_scripts/add_to_whitelist.mv \
        --sender-account owner --profile=owner \

add_collection:
	aptos move run-script --assume-yes \
        --compiled-script-path build/urn_to_earn/bytecode_scripts/add_collection.mv \
        --sender-account owner --profile=owner \

add_wl_cli:
	aptos move run-script --assume-yes \
        --compiled-script-path build/urn_to_earn/bytecode_scripts/add_to_whitelist2.mv \
        --sender-account owner --profile=owner \

sum2:
	aptos move run --function-id ${OWNER}::whitelist::sum2 \
	--sender-account=owner --profile=owner \
	--args 'vector<u64>:1,2,3'

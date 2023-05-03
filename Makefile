FAUCET_URL=http://0.0.0.0:8081
REST_URL=http://0.0.0.0:8080
TESTNET_URL=https://fullnode.testnet.aptoslabs.com
OWNER=0x572941edfecf00c392ebf17fdb20729be425ecb5ce018999f19e7e2be534676f
TESTNET=0x880f255dea4800fcea4b640cc6a9dfdb711f6d75a89719d7e06f936d3b8dbaea

init_profiles:
	aptos init --profile owner --rest-url ${REST_URL} --faucet-url ${FAUCET_URL}
	aptos init --profile user --rest-url ${REST_URL} --faucet-url ${FAUCET_URL}

init_testnet_prof:
	aptos init --profile testnet --rest-url "https://fullnode.testnet.aptoslabs.com/v1"

local_testnet:
	aptos node run-local-testnet --force-restart --with-faucet

test:
	aptos move test --skip-fetch-latest-git-deps --named-addresses owner=owner 

fund:
	aptos account fund-with-faucet \
	--profile owner --account owner --amount 999999999
	aptos account fund-with-faucet \
	--profile user --account user --amount 999999999

compile:
	aptos move compile --bytecode-version 6 --named-addresses owner=${profile}

compile_testnet:
	aptos move compile --named-addresses owner=testnet

publish:
	aptos move publish --named-addresses owner=${profile} \
	--bytecode-version=6 --included-artifacts=none \
	--sender-account ${profile} --profile ${profile}

publish_testnet:
	aptos move publish --named-addresses owner=testnet \
	--sender-account testnet --profile testnet

mint_shovel:
	aptos move run --function-id ${OWNER}::urn_to_earn::mint_shovel \
	--sender-account=owner --profile=owner
	
wl_mint_shovel:
	aptos move run --function-id ${OWNER}::urn_to_earn::bayc_wl_mint_shovel \
	--sender-account=user --profile=user

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
	aptos move run --function-id ${OWNER}::urn_to_earn::dig \
	--sender-account=owner --profile=owner

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

add_wl:
	aptos move run-script --assume-yes \
        --compiled-script-path build/urn_to_earn/bytecode_scripts/add_to_whitelist.mv \
        --sender-account ${profile} --profile ${profile} \

add_collection:
	aptos move run-script --assume-yes \
        --compiled-script-path build/urn_to_earn/bytecode_scripts/add_collection.mv \
        --sender-account ${profile} --profile ${profile} \

get_collection_left_quota:
	curl --request POST \
	--url ${REST_URL}/v1/view \
	--header 'Content-Type: application/json' \
	--data '{ \
		"function": "${OWNER}::whitelist::get_collection_left_quota", \
		"type_arguments": [], \
		"arguments": ["BAYC"] \
	}'

get_collection_left_quota_testnet:
	curl --request POST \
	--url ${TESTNET_URL}/v1/view \
	--header 'Content-Type: application/json' \
	--data '{ \
		"function": "${TESTNET}::whitelist::get_collection_left_quota", \
		"type_arguments": [], \
		"arguments": ["BAYC"] \
	}'

view_is_whitelisted:
	curl --request POST \
	--url ${REST_URL}/v1/view \
	--header 'Content-Type: application/json' \
	--data '{ \
		"function": "${OWNER}::whitelist::view_is_whitelisted", \
		"type_arguments": [], \
		"arguments": ["BAYC", "0x572941edfecf00c392ebf17fdb20729be425ecb5ce018999f19e7e2be534676f"] \
	}'

view_is_whitelisted_testnet:
	curl --request POST \
	--url ${TESTNET_URL}/v1/view \
	--header 'Content-Type: application/json' \
	--data '{ \
		"function": "${TESTNET}::whitelist::view_is_whitelisted", \
		"type_arguments": [], \
		"arguments": ["Blocto", "0x14bb3a81a6a92db55f4ef6f4f1abef445c418a33d5ddfd4bd672346c9db38add"] \
	}'

view_is_whitelisted_and_minted_testnet:
	curl --request POST \
	--url ${TESTNET_URL}/v1/view \
	--header 'Content-Type: application/json' \
	--data '{ \
		"function": "${TESTNET}::whitelist::view_is_whitelisted_and_minted", \
		"type_arguments": [], \
		"arguments": ["Blocto", "0x14bb3a81a6a92db55f4ef6f4f1abef445c418a33d5ddfd4bd672346c9db38add"] \
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

sum2:
	aptos move run --function-id ${OWNER}::whitelist::sum2 \
	--sender-account=owner --profile=owner \
	--args 'vector<u64>:1,2,3'

FAUCET_URL=http://0.0.0.0:8081
REST_URL=http://0.0.0.0:8080

init_profiles:
	aptos init --profile owner --rest-url ${REST_URL} --faucet-url ${FAUCET_URL}
	aptos init --profile user --rest-url ${REST_URL} --faucet-url ${FAUCET_URL}

local_testnet:
	aptos node run-local-testnet --with-faucet

fund:
	aptos account fund-with-faucet \
	--profile owner --account owner --amount 999999999
	aptos account fund-with-faucet \
	--profile user --account user --amount 999999999

compile:
	aptos move compile --named-addresses owner=owner

publish:
	aptos move publish --named-addresses owner=owner \
	--sender-account owner --profile owner

mint_shovel:
	aptos move run-script --assume-yes \
	--compiled-script-path build/urn/bytecode_scripts/mint_shovel.mv \
	--sender-account=user --profile=user

dig:
	aptos move run-script --assume-yes \
	--compiled-script-path build/urn/bytecode_scripts/dig.mv \
	--sender-account=user --profile=user

query_owner_res:
		aptos account list --query resources --account owner --profile owner

query_user_res:
		aptos account list --query resources --account user --profile user
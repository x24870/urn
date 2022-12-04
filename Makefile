FAUCET_URL=http://0.0.0.0:8081
REST_URL=http://0.0.0.0:8080

init_profiles:
	aptos init --profile owner --rest-url ${REST_URL} --faucet-url ${FAUCET_URL}
	aptos init --profile user --rest-url ${REST_URL} --faucet-url ${FAUCET_URL}

init_testnet_prof:
	aptos init --profile testnet --rest-url "https://fullnode.testnet.aptoslabs.com/v1"

local_testnet:
	aptos node run-local-testnet --with-faucet

test:
	aptos move test --named-addresses owner=owner 

fund:
	aptos account fund-with-faucet \
	--profile owner --account owner --amount 999999999
	aptos account fund-with-faucet \
	--profile user --account user --amount 999999999

compile:
	aptos move compile --named-addresses owner=owner

compile_testnet:
	aptos move compile --named-addresses owner=testnet

publish:
	aptos move publish --named-addresses owner=owner \
	--sender-account owner --profile owner

publish_testnet:
	aptos move publish --named-addresses owner=testnet \
	--sender-account testnet --profile testnet

mint_shovel:
	aptos move run-script --assume-yes \
	--compiled-script-path build/urn/bytecode_scripts/mint_shovel.mv \
	--sender-account=user --profile=user

mint_urn:
	aptos move run-script --assume-yes \
	--compiled-script-path build/urn/bytecode_scripts/mint_urn.mv \
	--sender-account=user --profile=user

dig:
	aptos move run-script --assume-yes \
	--compiled-script-path build/urn/bytecode_scripts/dig.mv \
	--sender-account=user --profile=user

query_owner_res:
		aptos account list --query resources --account owner --profile owner

query_user_res:
		aptos account list --query resources --account user --profile user

query_testnet_res:
		aptos account list --query resources --account testnet --profile testnet
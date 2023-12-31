include Makefile.config
export PATH := deps/aptos-core/target/release/:$(PATH)
TESTNET_URL=https://fullnode.testnet.aptoslabs.com

.PHONY: build install-aptos test compile local-node

install-aptos:
	cd deps/aptos-core && cargo install --profile release --path crates/aptos

clean:
	rm -rf layerzero/build && rm -rf apps/bridge/build && rm -rf apps/oracle/build

build:
	cd deps/aptos-core && cargo build --profile release

test-common:
	cd layerzero-common && aptos move test --named-addresses layerzero_common=${layerzero_common}

test-layerzero:
	cd layerzero && aptos move test --named-addresses layerzero_common=${layerzero_common},msglib_auth=${msglib_auth},zro=${zro},msglib_v1_1=${msglib_v1_1},msglib_v2=${msglib_v2},layerzero=${layerzero},executor_auth=${executor_auth},executor_v2=${executor_v2}

test-oracle:
	cd apps/oracle && aptos move test --named-addresses layerzero_common=${layerzero_common},msglib_auth=${msglib_auth},zro=${zro},msglib_v1_1=${msglib_v1_1},msglib_v2=${msglib_v2},executor_auth=${executor_auth},executor_v2=${executor_v2},layerzero=${layerzero},oracle=0xBEAD

test-counter:
	cd apps/counter && aptos move test --named-addresses layerzero_common=${layerzero_common},msglib_auth=${msglib_auth},zro=${zro},msglib_v1_1=${msglib_v1_1},msglib_v2=${msglib_v2},executor_auth=${executor_auth},executor_v2=${executor_v2},layerzero=${layerzero},counter=0xBEAD

test-bridge:
	cd apps/bridge && aptos move test --named-addresses layerzero_common=${layerzero_common},msglib_auth=${msglib_auth},zro=${zro},msglib_v1_1=${msglib_v1_1},msglib_v2=${msglib_v2},executor_auth=${executor_auth},executor_v2=${executor_v2},layerzero=${layerzero},bridge=0xBEAD

test-layerzero-apps:
	cd layerzero-apps && aptos move test --named-addresses layerzero_common=${layerzero_common},msglib_auth=${msglib_auth},zro=${zro},msglib_v1_1=${msglib_v1_1},msglib_v2=${msglib_v2},layerzero=${layerzero},executor_auth=${executor_auth},executor_v2=${executor_v2},layerzero_apps=${layerzero_apps}

test-oft:
	cd apps/example/oft && aptos move test --named-addresses layerzero_common=${layerzero_common},msglib_auth=${msglib_auth},zro=${zro},msglib_v1_1=${msglib_v1_1},msglib_v2=${msglib_v2},executor_auth=${executor_auth},executor_v2=${executor_v2},layerzero=${layerzero},layerzero_apps=${layerzero_apps},oft=0xBEAD

test-proxy-oft:
	cd apps/example/proxy-oft && aptos move test --named-addresses layerzero_common=${layerzero_common},msglib_auth=${msglib_auth},zro=${zro},msglib_v1_1=${msglib_v1_1},msglib_v2=${msglib_v2},executor_auth=${executor_auth},executor_v2=${executor_v2},layerzero=${layerzero},layerzero_apps=${layerzero_apps},proxy_oft=0xBEAD

test-executor-ext:
	cd executor/executor-ext && aptos move test --named-addresses executor_ext=${executor_ext}

test: test-common test-layerzero test-oracle test-counter test-bridge test-layerzero-apps test-oft test-proxy-oft test-executor-ext

compile-common:
	cd layerzero-common && aptos move compile --included-artifacts=${included_artifacts} --save-metadata --named-addresses layerzero_common=${layerzero_common}
publish-common:
	cd layerzero-common && aptos move publish --assume-yes --included-artifacts=${included_artifacts} --named-addresses layerzero_common=owner --profile owner

compile-zro:
	cd zro && aptos move compile --included-artifacts=${included_artifacts} --save-metadata --named-addresses zro=${zro}
publish-zro:
	cd zro && aptos move publish --assume-yes --included-artifacts=${included_artifacts} --named-addresses zro=owner --profile owner

compile-msglib-auth:
	cd ./msglib/msglib-auth && aptos move compile --included-artifacts=${included_artifacts} --save-metadata --named-addresses layerzero_common=${layerzero_common},msglib_auth=${msglib_auth}
publish-msglib-auth:
	cd ./msglib/msglib-auth && aptos move publish --assume-yes --included-artifacts=${included_artifacts} --named-addresses msglib_auth=owner,layerzero_common=owner --profile owner

compile-msglib-v2:
	cd ./msglib/msglib-v2 && aptos move compile --included-artifacts=${included_artifacts} --save-metadata --named-addresses layerzero_common=${layerzero_common},msglib_auth=${msglib_auth},zro=${zro},msglib_v2=${msglib_v2}
publish-msglib-v2:
	cd ./msglib/msglib-v2 && aptos move publish --assume-yes --included-artifacts=${included_artifacts} --named-addresses msglib_v2=owner,layerzero_common=owner,msglib_auth=owner,zro=owner --profile owner

compile-msglib-v1-1:
	cd ./msglib/msglib-v1/msglib-v1-1 && aptos move compile --included-artifacts=${included_artifacts} --save-metadata --named-addresses layerzero_common=${layerzero_common},msglib_auth=${msglib_auth},zro=${zro},msglib_v1_1=${msglib_v1_1}
publish-msglib-v1-1:
	cd ./msglib/msglib-v1/msglib-v1-1 && aptos move publish --assume-yes --included-artifacts=${included_artifacts} --named-addresses msglib_v1_1=owner,layerzero_common=owner,msglib_auth=owner,zro=owner --profile owner

compile-layerzero:
	cd layerzero && aptos move compile --included-artifacts=${included_artifacts} --save-metadata --named-addresses layerzero_common=${layerzero_common},msglib_auth=${msglib_auth},zro=${zro},msglib_v1_1=${msglib_v1_1},msglib_v2=${msglib_v2},layerzero=${layerzero},executor_auth=${executor_auth},executor_v2=${executor_v2}
publish-layerzero:
	cd layerzero && aptos move publish --assume-yes --included-artifacts=${included_artifacts} --named-addresses executor_v2=owner,executor_auth=owner,layerzero=owner,layerzero_common=owner,msglib_auth=owner,zro=owner,msglib_v1_1=owner,msglib_v2=owner,executor_auth=owner,executor_v2=owner --profile owner

compile-executor-auth:
	cd ./executor/executor-auth && aptos move compile --included-artifacts=${included_artifacts} --save-metadata --named-addresses layerzero_common=${layerzero_common},executor_auth=${executor_auth}
publish-executor-auth:
	cd ./executor/executor-auth && aptos move publish --assume-yes --included-artifacts=${included_artifacts} --named-addresses executor_auth=owner,layerzero_common=owner --profile owner

compile-executor-v2:
	cd ./executor/executor-v2 && aptos move compile --included-artifacts=${included_artifacts} --save-metadata --named-addresses layerzero_common=${layerzero_common},executor_auth=${executor_auth},executor_v2=${executor_v2}
publish-executor-v2:
	cd ./executor/executor-v2 && aptos move publish --assume-yes --included-artifacts=${included_artifacts} --named-addresses executor_v2=owner,layerzero_common=owner,executor_auth=owner --profile owner

# deploy layerzero modules locally but seems it requires some additional steps
# like init_endpoint, init_msglib...
# this is not working yet
publish-layerzero-local: publish-common publish-zro publish-msglib-auth publish-msglib-v2 publish-msglib-v1-1 publish-layerzero publish-executor-auth publish-executor-v2
init_endpoint:
	aptos move run --function-id ${profile}::endpoint::init \
	--sender-account=${profile} --profile=${profile} \
	--args u64:10108


compile-executor-ext:
	cd ./executor/executor-ext && aptos move compile --included-artifacts=${included_artifacts} --save-metadata --named-addresses executor_ext=${executor_ext}

compile-counter:
	aptos move compile --included-artifacts=${included_artifacts} --skip-fetch-latest-git-deps --save-metadata --named-addresses layerzero_common=${layerzero_common},msglib_auth=${msglib_auth},zro=${zro},msglib_v1_1=${msglib_v1_1},msglib_v2=${msglib_v2},executor_auth=${executor_auth},executor_v2=${executor_v2},layerzero=${layerzero},counter=testnet
	# cd apps/counter && aptos move compile --included-artifacts=${included_artifacts} --save-metadata --named-addresses layerzero_common=${layerzero_common},msglib_auth=${msglib_auth},zro=${zro},msglib_v1_1=${msglib_v1_1},msglib_v2=${msglib_v2},executor_auth=${executor_auth},executor_v2=${executor_v2},layerzero=${layerzero},counter=0xBEAD

compile-bridge:
	cd apps/bridge && aptos move compile --included-artifacts=${included_artifacts} --save-metadata --named-addresses layerzero_common=${layerzero_common},msglib_auth=${msglib_auth},zro=${zro},msglib_v1_1=${msglib_v1_1},msglib_v2=${msglib_v2},executor_auth=${executor_auth},executor_v2=${executor_v2},layerzero=${layerzero},bridge=0xBEAD

compile: compile-common compile-msglib-auth compile-zro compile-msglib-v1-1 compile-msglib-v2 compile-layerzero compile-counter compile-bridge compile-oracle compile-executor-v2 compile-executor-auth compile-executor-ext

local-node:
	@-pkill -f aptos
	rm -rf .aptos
	aptos node run-local-testnet --with-faucet &
	@curl --silent --retry 15 --retry-delay 2 --retry-connrefused http://localhost:8080/
	@curl --silent --retry 15 --retry-delay 2 --retry-connrefused http://localhost:8081/

publish-counter:
	aptos move publish --included-artifacts=${included_artifacts} --skip-fetch-latest-git-deps \
	--named-addresses layerzero_common=${layerzero_common},msglib_auth=${msglib_auth},zro=${zro},msglib_v1_1=${msglib_v1_1},msglib_v2=${msglib_v2},executor_auth=${executor_auth},executor_v2=${executor_v2},layerzero=${layerzero},counter=testnet \
	--sender-account testnet --profile testnet

publish-counter-testnet:
	aptos move publish --included-artifacts=${included_artifacts} --skip-fetch-latest-git-deps \
	--named-addresses layerzero_common=${TESTNET_ENDPOINT},msglib_auth=${TESTNET_ENDPOINT},zro=${TESTNET_ENDPOINT},msglib_v1_1=${TESTNET_ENDPOINT},executor_auth=${TESTNET_ENDPOINT},executor_v2=${TESTNET_ENDPOINT},msglib_v2=${TESTNET_ENDPOINT},layerzero=${TESTNET_ENDPOINT},counter=testnet \
	--sender-account testnet --profile testnet

set-remote:
	aptos move run --function-id testnet::counter::set_remote \
	--sender-account=testnet --profile=testnet \
	--args u64:10121 "u8:[]"

# set-config:
# 	aptos move run --function-id testnet::counter::set_cfg \
# 	--sender-account=testnet --profile=testnet \
# 	--args u64:10132 u64:2

# set-send-msglib:
# 	aptos move run --function-id testnet::counter::set_send_msglib \
# 	--sender-account=testnet --profile=testnet \
# 	--args u64:10132

create-counter:
	aptos move run --function-id testnet::counter::create_counter \
	--sender-account=testnet --profile=testnet \
	--args u64:2

get-count:
	aptos move view --function-id testnet::counter::get_count_view --url=${TESTNET_URL} --args address:0e1926f82510045d7341f2101515c9ffb9cd4fea327cebbc5965c04754b49f37

send_to_remote:
	aptos move run --assume-yes --function-id testnet::counter::send_to_remote \
	--sender-account=testnet --profile=testnet \
	--args u64:10121 u64:555 "u8:[]"

quote_fee:
	aptos move run-script --assume-yes \
	--script-path scripts/qoute_fee.move --url=${TESTNET_URL} \
	--sender-account=testnet --profile=testnet

get_default_send_msglib:
	aptos move view --function-id testnet::counter::get_default_send_msglib --url=${TESTNET_URL} --args u64:10121
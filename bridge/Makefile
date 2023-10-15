include .env
export $(shell sed 's/=.*//' .env)

deploy_goerli:
	forge create src/OmniCounter.sol:OmniCounter --rpc-url=${GOERLI} --private-key=${PRIVATE_KEY} --constructor-args=0xbfD2135BFfbb0B5378b56643c2Df8a87552Bfa23

deploy_optimism_goerli:
	forge create src/OmniCounter.sol:OmniCounter --rpc-url=${OPTIMISM_GOERLI} --private-key=${PRIVATE_KEY} --constructor-args=0xae92d5aD7583AD66E49A0c67BAd18F6ba52dDDc1

getCountGoerli:
	cast call --rpc-url=${GOERLI} ${GOERLI_CONTRACT} "getCount()"

getCountOptimismGoerli:
	cast call --rpc-url=${OPTIMISM_GOERLI} ${OPTIMISM_GOERLI_CONTRACT} "getCount()"

setTrustedRemoteGoerli:
	cast send --rpc-url=${GOERLI} --private-key=${PRIVATE_KEY} ${GOERLI_CONTRACT} \
	"setTrustedRemote(uint16,bytes)" 10132 \
	$(shell cast abi-encode "func(address,address)" ${OPTIMISM_GOERLI_CONTRACT} ${GOERLI_CONTRACT})

setTrustedRemoteOptimismGoerli:
	cast send --rpc-url=${OPTIMISM_GOERLI} --private-key=${PRIVATE_KEY} ${OPTIMISM_GOERLI_CONTRACT} \
	"setTrustedRemote(uint16,bytes)" 10121 \
	$(shell cast abi-encode "func(address,address)" ${GOERLI_CONTRACT} ${OPTIMISM_GOERLI_CONTRACT})


abiEncodeGoerli:
	cast abi-encode "func(address,address)" ${OPTIMISM_GOERLI_CONTRACT} ${GOERLI_CONTRACT}

abiEncodeOptimismGoerli:
	cast abi-encode "func(address,address)" ${GOERLI_CONTRACT} ${OPTIMISM_GOERLI_CONTRACT}

# not working
incrementCounterGoerli:
	cast send --rpc-url=${GOERLI} --private-key=${PRIVATE_KEY} --value 0.01ether ${GOERLI_CONTRACT} "incrementCounter(uint16)" 10132
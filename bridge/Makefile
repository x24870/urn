include .env
export $(shell sed 's/=.*//' .env)

deploy_goerli:
	forge create src/OmniCounter.sol:OmniCounter --rpc-url=${GOERLI} --private-key=${PRIVATE_KEY} --constructor-args=0xbfD2135BFfbb0B5378b56643c2Df8a87552Bfa23
deploy_reborn_goerli:
	forge create src/TheReborn.sol:Reborn --rpc-url=${GOERLI} --private-key=${PRIVATE_KEY} --constructor-args=0xbfD2135BFfbb0B5378b56643c2Df8a87552Bfa23 --constructor-args=0xF5E8A439C599205C1aB06b535DE46681Aed1007a

deploy_op_goerli:
	forge create src/OmniCounter.sol:OmniCounter --rpc-url=${OP_GOERLI} --private-key=${PRIVATE_KEY} --constructor-args=0xae92d5aD7583AD66E49A0c67BAd18F6ba52dDDc1

getCountGoerli:
	cast call --rpc-url=${GOERLI} ${GOERLI_CONTRACT} "getCount()"

getCountOpGoerli:
	cast call --rpc-url=${OP_GOERLI} ${OP_GOERLI_CONTRACT} "getCount()"

setTrustedRemoteGoerli:
	cast send --rpc-url=${GOERLI} --private-key=${PRIVATE_KEY} ${GOERLI_CONTRACT} \
	"setTrustedRemote(uint16,bytes)" 10132 \
	$(shell cast abi-encode "func(address,address)" ${OP_GOERLI_CONTRACT} ${GOERLI_CONTRACT})

setTrustedRemoteOpGoerli:
	cast send --rpc-url=${OP_GOERLI} --private-key=${PRIVATE_KEY} ${OP_GOERLI_CONTRACT} \
	"setTrustedRemote(uint16,bytes)" 10121 \
	$(shell cast abi-encode "func(address,address)" ${GOERLI_CONTRACT} ${OP_GOERLI_CONTRACT})

opSetTrustedRemoteAddressAptos:
	cast send --rpc-url=${OP_GOERLI} --private-key=${PRIVATE_KEY} ${OP_GOERLI_CONTRACT} \
	"setTrustedRemoteAddress(uint16,bytes)" 10108 ${APTOS_CONTRACT}

setTrustedRemoteAddressAptos:
	cast send --rpc-url=${GOERLI} --private-key=${PRIVATE_KEY} ${GOERLI_CONTRACT} \
	"setTrustedRemoteAddress(uint16,bytes)" 10108 ${APTOS_CONTRACT}
setRebornRemoteAddressAptos:
	cast send --rpc-url=${GOERLI} --private-key=${PRIVATE_KEY} ${REBORN_GOERLI_CONTRACT} \
	"setTrustedRemoteAddress(uint16,bytes)" 10108 ${REBORN_APTOS_CONTRACT}

abiEncodeGoerli:
	cast abi-encode "func(address,address)" ${OP_GOERLI_CONTRACT} ${GOERLI_CONTRACT}

abiEncodeOpGoerli:
	cast abi-encode "func(address,address)" ${GOERLI_CONTRACT} ${OP_GOERLI_CONTRACT}

incrementCounterGoerli:
	cast send --rpc-url=${GOERLI} --private-key=${PRIVATE_KEY} --value 0.01ether ${GOERLI_CONTRACT} "incrementCounter(uint16)" ${LZ_OP_GOERLI_CHAIN_ID}

incrementCounterOpGoerli:
	cast send --rpc-url=${OP_GOERLI} --private-key=${PRIVATE_KEY} --value 0.01ether ${OP_GOERLI_CONTRACT} "incrementCounter(uint16)" ${LZ_GOERLI_CHAIN_ID}
	
hasStoredPayloadGoerli:
	# cast call --rpc-url=${GOERLI} ${GOERLI_ENDPOINT_CONTRACT} "hasStoredPayload(uint16,bytes)" ${LZ_OP_GOERLI_CHAIN_ID} ${OP_GOERLI_CONTRACT}
	# cast call --rpc-url=${GOERLI} ${GOERLI_ENDPOINT_CONTRACT} "hasStoredPayload(uint16,bytes)" ${LZ_OP_GOERLI_CHAIN_ID} ${OP_GOERLI_CONTRACT}
	cast call --rpc-url=${GOERLI} ${GOERLI_ENDPOINT_CONTRACT} "hasStoredPayload(uint16,bytes)" ${LZ_GOERLI_CHAIN_ID} ${GOERLI_CONTRACT}

hasStoredPayloadOpGoerli:
	# cast call --rpc-url=${OP_GOERLI} ${OP_GOERLI_ENDPOINT_CONTRACT} "hasStoredPayload(uint16,bytes)" ${LZ_GOERLI_CHAIN_ID} ${GOERLI_CONTRACT}
	cast call --rpc-url=${OP_GOERLI} ${OP_GOERLI_ENDPOINT_CONTRACT} "hasStoredPayload(uint16,bytes)" ${LZ_GOERLI_CHAIN_ID} ${GOERLI_CONTRACT}


### txs note
# https://testnet.layerzeroscan.com/10121/address/0x90763448e65f7a0fe1dfd466357f46c7bac4abbc/message/10132/address/0x50999b17c01eb86ec8507791a80fbf4417b1dde2/nonce/1
# https://testnet.layerzeroscan.com/10132/address/0x50999b17c01eb86ec8507791a80fbf4417b1dde2/message/10121/address/0x90763448e65f7a0fe1dfd466357f46c7bac4abbc/nonce/1
# https://testnet.layerzeroscan.com/10121/address/0x90763448e65f7a0fe1dfd466357f46c7bac4abbc/message/10132/address/0x50999b17c01eb86ec8507791a80fbf4417b1dde2/nonce/2

# https://goerli-optimism.etherscan.io/tx/0xceb4e9c8c9b2ba1e04f1914754b671275cd4c9d2f2db08a0c673e8db15b3fe27#eventlog
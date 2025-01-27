deploy:
	forge script script/Router.s.sol:RouterDeployScript \
		--rpc-url https://mainnet.mode.network \
		--broadcast \
		--legacy \
		--chain-id 34443 \
		-vvvv
		
verify:
	source .env && forge verify-contract \
    $(ROUTER) \
    src/CLPoolRouter.sol:CLPoolRouter \
    --chain-id 34443 \
    --verifier-url https://api.mode.network \
    --verifier blockscout \
    --watch
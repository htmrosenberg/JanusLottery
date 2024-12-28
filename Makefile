-include .env

.PHONY: build, update, test, coverage, coverage-report,fund-automation,fund-vrf,buy-ticket,offer-jackpot,view-info

build :; forge build
update:; forge update
tests :; forge test
coverage :; forge coverage
coverage-report :; forge coverage --report debug > coverage-report.txt

anvil :; anvil -m 'test test test test test test test test test test test junk' --steps-tracing --block-time 1


deploy-anvil:
	forge create src/JanusLottery.sol:JanusLottery --account $(ACCOUNT) --constructor-args $(MINSELLHRS) $(MAXSELLHRS) $(FUNDHRS) $(MINJACK) $(FEE) $(VRF) $(SUBID) $(LAN) $(CALLBACK)

NETWORK_ARGS := --rpc-url http://localhost:8545 --private-key $(DEFAULT_ANVIL_KEY) --broadcast

ifeq ($(findstring --network sepolia,$(ARGS)),--network sepolia)
	NETWORK_ARGS := --rpc-url $(SEPOLIA_RPC_URL) --private-key $(PRIVATE_KEY) --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv
endif


fund-automation:; forge script script/Interactions.s.sol:SetUpAutomation $(NETWORK_ARGS)
fund-vrf:; forge script script/Interactions.s.sol:SetUpVRF $(NETWORK_ARGS)
buy-ticket:; forge script script/Interactions.s.sol:BufTicket $(NETWORK_ARGS)
offer-jackpot:; forge script script/Interactions.s.sol:OfferJackpot $(NETWORK_ARGS)
view-info:; forge script script/Interactions.s.sol:ViewState --sig "getInfo(address payable)" $(ADDRESS) --rpc-url $(RPC)


fdeploy:
	@forge script script/DeployRaffle.s.sol:DeployRaffle $(NETWORK_ARGS)

createSubscription:
	@forge script script/Interactions.s.sol:CreateSubscription $(NETWORK_ARGS)

addConsumer:
	@forge script script/Interactions.s.sol:AddConsumer $(NETWORK_ARGS)

fundSubscription:
	@forge script script/Interactions.s.sol:FundSubscription $(NETWORK_ARGS)

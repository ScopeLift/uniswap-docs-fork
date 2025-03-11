// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {console2} from "forge-std/console2.sol";
import {Script} from "forge-std/script.sol";
import {IUniswapV3Factory} from "lib/v3-core/contracts/interfaces/IUniswapV3Factory.sol";

interface IUniswapGovernorBravoDelegator {
    // function to create a proposal on Ethereum L1 using the Uniswap Governor Bravo Delegator contract
    function propose(
        address[] memory targets,
        uint256[] memory values,
        string[] memory signatures,
        bytes[] memory calldatas,
        string memory description
    ) external returns (uint256);
}

contract EthereumToBnbChainSender is Script {
    // Address of the WormholeMessageReceiver contract on BNB Chain
    address constant WORMHOLE_MESSAGE_RECEIVER_ADDRESS = 0x341c1511141022cf8eE20824Ae0fFA3491F1302b;

    // BNB Chain chainId
    uint256 constant CHAIN_ID = 56;

    // target addresses on BNB Chain
    address constant v3FactoryTargetAddress = 0xdB1d10011AD0Ff90774D0C6Bb92e5C5c8b4461F7;

    // target address for UniSwap DAO governor bravo delegate
    address uniswapGovernorBravoDelegatorAddress = 0x408ED6354d4973f66138C91495F2f2FCbd8724C3;

    // Address of the WormholdMessageSender contract on Ethereum (L1)
    address constant WORMHOLE_MESSAGE_SENDER_ADDRESS = 0xf5F4496219F31CDCBa6130B5402873624585615a;

    // function to create a proposal on Ethereum L1 to enable a fee amount on the Uniswap V3 Factory on BNB Chain.
    // Upon execution of the proposal, the WormholeMessageSender contract function sendMessage is called, containing calldata for the
    // uniswap v3 factory to enable a fee amount on Uniswap V3 Factory on BNB Chain.
    function proposeForExecutionOnBnbChain() external payable {
        // setup calldata for the destination chain uniswap v3Factory.enableFeeAmount call
        bytes memory _v3FactoryEnableFeeAmounCalldata =
            abi.encodeWithSelector(IUniswapV3Factory.enableFeeAmount.selector, 10000, 205);

        // setup calldata for calling WormholeMessageSender sendMessage
        address[] memory _sendMessageTargets = new address[](1);
        uint256[] memory _sendMessageValues = new uint256[](1);
        bytes[] memory _sendMessageCalldatas = new bytes[](1);
        _sendMessageTargets[0] = v3FactoryTargetAddress;
        _sendMessageValues[0] = 0;
        _sendMessageCalldatas[0] = _v3FactoryEnableFeeAmounCalldata;
        bytes memory _sendMessageCalldata = abi.encode(
            _sendMessageTargets, _sendMessageValues, _sendMessageCalldatas, WORMHOLE_MESSAGE_RECEIVER_ADDRESS, CHAIN_ID
        );

        // make the proposal on the L1 side
        IUniswapGovernorBravoDelegator governor = IUniswapGovernorBravoDelegator(uniswapGovernorBravoDelegatorAddress);
        address[] memory _targets = new address[](1);
        uint256[] memory _values = new uint256[](1);
        string[] memory _signatures = new string[](1);
        bytes[] memory _calldatas = new bytes[](1);
        _targets[0] = WORMHOLE_MESSAGE_SENDER_ADDRESS;
        _values[0] = 0;
        _signatures[0] = "sendMessage(address[],uint256[],bytes[],address,uint16)";
        _calldatas[0] = _sendMessageCalldata;
        uint256 _proposalId = governor.propose(
            _targets,
            _values,
            _signatures,
            _calldatas,
            "Proposal to enable 10000 fee amount of 205 on Uniswap V3 Factory on BNB Chain"
        );
        console2.log("Proposal ID: %d", _proposalId);
    }
}

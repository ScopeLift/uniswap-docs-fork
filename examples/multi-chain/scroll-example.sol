// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {console2} from "forge-std/console2.sol";
import {Script} from "forge-std/script.sol";
import {IUniswapV3Factory} from "lib/v3-core/contracts/interfaces/IUniswapV3Factory.sol";

interface ICrossChainAccount {
    function forward(address target, bytes memory data) external;
}

interface IUniswapGovernorBravoDelegator {
    function propose(
        address[] memory targets,
        uint256[] memory values,
        string[] memory signatures,
        bytes[] memory calldatas,
        string memory description
    ) external returns (uint256);
}

contract ScrollExample is Script {
    // target address for the cross domain messenger on Ethereum L1 responsible for sending messages to Scroll
    address constant L1_SCROLL_MESSENGER_ADDRESS = 0x6774Bcbd5ceCeF1336b5300fb5186a12DDD8b367;

    // target addresses on Scroll
    address constant v3FactoryTargetAddress = 0x70C62C8b8e801124A4Aa81ce07b637A3e83cb919;
    address constant crossChainAccountTargetAddress = 0x3b441EEa8e042dcB9517b0FC1afFb0d8CBa0f388;

    // target address for UniSwap DAO governor bravo delegate contract on Ethereum L1
    address uniswapGovernorBravoDelegatorAddress = 0x408ED6354d4973f66138C91495F2f2FCbd8724C3;

    // function to create a proposal on Ethereum L1 to enable a fee amount on the Uniswap V3 Factory on Scroll.
    // Upon execution of the proposal, the L1ScrollMessenger function sendMessage is called containing calldata for the
    // CrossChainAccount.forward function on Scroll that will be called containing calldata for the uniswap v3 factory
    // to enable a fee amount on Uniswap V3 Factory on Scroll
    function proposeForExecutionOnScroll() public {
        // setup calldata for the Scroll uniswap v3Factory.enableFeeAmount call
        bytes memory _v3FactoryEnableFeeAmounCalldata =
            abi.encodeWithSelector(IUniswapV3Factory.enableFeeAmount.selector, 10000, 205);

        // encode the calldata for the CrossChainAccount.forward call
        bytes memory _messageForwardCalldata = abi.encodeWithSelector(
            ICrossChainAccount.forward.selector, v3FactoryTargetAddress, _v3FactoryEnableFeeAmounCalldata
        );

        // make the proposal on the L1 side
        IUniswapGovernorBravoDelegator governor = IUniswapGovernorBravoDelegator(uniswapGovernorBravoDelegatorAddress);
        address[] memory _targets = new address[](1);
        uint256[] memory _values = new uint256[](1);
        string[] memory _signatures = new string[](1);
        bytes[] memory _calldatas = new bytes[](1);
        _targets[0] = L1_SCROLL_MESSENGER_ADDRESS;
        _values[0] = 0;
        _signatures[0] = "sendMessage(address,uint256,bytes,uint256)";
        _calldatas[0] = abi.encode(address(crossChainAccountTargetAddress), 0, _messageForwardCalldata, 500_000);
        uint256 _proposalId = governor.propose(
            _targets,
            _values,
            _signatures,
            _calldatas,
            "Proposal to enable 10000 fee amount of 205 on Uniswap V3 Factory on Scroll"
        );
        console2.log("Proposal ID: %d", _proposalId);
    }
}

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

contract OptimismExample is Script {
    // target address for the cross domain messenger on Ethereum L1 responsible for sending messages to Optimism
    //  (this address would be different for Base, Blast, or Zora)
    address constant l1CrossDomainMessengerAddress = 0x25ace71c97B33Cc4729CF772ae268934F7ab5fA1;

    // target addresses on Optimism (these addresses would be different for various target chains)
    address constant v3FactoryTargetAddress = 0x1F98431c8aD98523631AE4a59f267346ea31F984;
    address constant crossChainAccountTargetAddress = 0xa1dD330d602c32622AA270Ea73d078B803Cb3518;

    // target address for UniSwap DAO governor bravo delegate contract on Ethereum L1
    address uniswapGovernorBravoDelegatorAddress = 0x408ED6354d4973f66138C91495F2f2FCbd8724C3;

    // function to create a proposal on Ethereum L1 to enable a fee amount on the Uniswap V3 Factory on Optimism.
    // Upon execution of the proposal, the L1CrossDomainMessenger function sendMessage is called containing calldata for the
    // CrossChainAccount.forward function on Optimism that will be called containing calldata for the uniswap v3 factory
    // to enable a fee amount on Uniswap V3 Factory on Optimism
    function proposeForExecutionOnOptimism() public {
        // setup calldata for the Optimism uniswap v3Factory.enableFeeAmount call
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
        _targets[0] = l1CrossDomainMessengerAddress;
        _values[0] = 0;
        _signatures[0] = "sendMessage(address,bytes,uint256)";
        _calldatas[0] = abi.encode(address(crossChainAccountTargetAddress), _messageForwardCalldata, 500_000);
        uint256 _proposalId = governor.propose(
            _targets,
            _values,
            _signatures,
            _calldatas,
            "Proposal to enable 10000 fee amount of 205 on Uniswap V3 Factory on Optimism"
        );
        console2.log("Proposal ID: %d", _proposalId);
    }
}

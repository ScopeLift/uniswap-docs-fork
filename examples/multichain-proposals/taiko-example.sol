// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {console2} from "forge-std/console2.sol";
import {Script} from "forge-std/script.sol";
import {IUniswapV3Factory} from "lib/v3-core/contracts/interfaces/IUniswapV3Factory.sol";

interface IUniswapGovernorBravoDelegator {
    function propose(
        address[] memory targets,
        uint256[] memory values,
        string[] memory signatures,
        bytes[] memory calldatas,
        string memory description
    ) external returns (uint256);
}

contract TaikoExample is Script {
    // target address for the Taiko Signal Service contract on Ethereum L1 responsible for sending messages to Taiko
    address constant TAIKO_SIGNAL_SERVICE_ADDRESS = 0x9e0a24964e5397B566c1ed39258e21aB5E35C77C;

    // target addresses on Taiko
    address constant v3FactoryTargetAddress = 0x75FC67473A91335B5b8F8821277262a13B38c9b3;

    // target address for UniSwap DAO governor bravo delegate contract on Ethereum L1
    address uniswapGovernorBravoDelegatorAddress = 0x408ED6354d4973f66138C91495F2f2FCbd8724C3;

    // function to create a proposal on Ethereum L1 to enable a fee amount on the Uniswap V3 Factory on Taiko.
    // Upon execution of the proposal, the Signal Service function "emitSignal" is called containing calldata for the
    // uniswap v3 factory to enable a fee amount on Uniswap V3 Factory on Taiko.
    function proposeForExecutionOnTaiko() public {
        // setup calldata for the Taiko uniswap v3Factory.enableFeeAmount call
        bytes memory _v3FactoryEnableFeeAmounCalldata = abi.encode(int24(10000), int24(205));

        // make the proposal on the L1 side
        IUniswapGovernorBravoDelegator governor = IUniswapGovernorBravoDelegator(uniswapGovernorBravoDelegatorAddress);
        address[] memory _targets = new address[](1);
        uint256[] memory _values = new uint256[](1);
        string[] memory _signatures = new string[](1);
        bytes[] memory _calldatas = new bytes[](1);
        _targets[0] = TAIKO_SIGNAL_SERVICE_ADDRESS;
        _values[0] = 0;
        _signatures[0] = "emitSignal(bytes)";
        _calldatas[0] = abi.encode(address(v3FactoryTargetAddress), _v3FactoryEnableFeeAmounCalldata);
        uint256 _proposalId = governor.propose(
            _targets,
            _values,
            _signatures,
            _calldatas,
            "Proposal to enable 10000 fee amount of 205 on Uniswap V3 Factory on Taiko"
        );
        console2.log("Proposal ID: %d", _proposalId);
    }
}

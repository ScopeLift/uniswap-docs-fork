// SPDX-License-Identifier: UNLICENSED
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

contract PolygonExample is Script {
    // target address for UniSwap DAO governor bravo delegate
    address uniswapGovernorBravoDelegatorAddress = 0x408ED6354d4973f66138C91495F2f2FCbd8724C3;

    // Address of the FxRoot contract Ethereum (L1)
    address constant FXROOT_ADDRESS = 0xfe5e5D361b2ad62c541bAb87C45a0B9B018389a2;

    // target addresses on Polygon
    address v3FactoryTargetAddress = 0x1F98431c8aD98523631AE4a59f267346ea31F984;

    // function to create a proposal on Ethereum L1 to enable a fee amount on the Uniswap V3 Factory on Polygon.
    // Upon execution of the proposal, the FxRoot contract function sendMessageToChild is called, containing calldata for the
    // uniswap v3 factory to enable a fee amount on Uniswap V3 Factory on Polygon.
    function proposeForExecutionOnPolygon() external payable {
        // setup calldata for the uniswap v3Factory.enableFeeAmount call
        bytes memory _v3FactoryEnableFeeAmounCalldata =
            abi.encodeWithSelector(IUniswapV3Factory.enableFeeAmount.selector, 10000, 205);

        // setup calldata for calling FxRoot.sendMessageToChild
        bytes memory _proposalCalldata = abi.encode(v3FactoryTargetAddress, _v3FactoryEnableFeeAmounCalldata);

        // make the proposal on the L1 side
        IUniswapGovernorBravoDelegator governor = IUniswapGovernorBravoDelegator(uniswapGovernorBravoDelegatorAddress);
        address[] memory _targets = new address[](1);
        uint256[] memory _values = new uint256[](1);
        string[] memory _signatures = new string[](1);
        bytes[] memory _calldatas = new bytes[](1);
        _targets[0] = FXROOT_ADDRESS;
        _values[0] = 0;
        _signatures[0] = "sendMessageToChild(address,bytes)";
        _calldatas[0] = _proposalCalldata;
        uint256 _proposalId = governor.propose(
            _targets,
            _values,
            _signatures,
            _calldatas,
            "Proposal to enable 10000 fee amount of 205 on Uniswap V3 Factory on Polygon"
        );
        console2.log("Proposal ID: %d", _proposalId);
    }
}

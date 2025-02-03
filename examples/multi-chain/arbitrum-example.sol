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

contract EthereumToArbitrumSender is Script {
    // target address for UniSwap DAO governor bravo delegate
    address uniswapGovernorBravoDelegatorAddress = 0x408ED6354d4973f66138C91495F2f2FCbd8724C3;

    // Address of the Arbitrum Inbox on Ethereum (L1)
    address constant INBOX_ADDRESS = 0x4Dbd4fc535Ac27206064B68FfCf827b0A60BAB3f;

    // target addresses on Arbitrum
    address v3FactoryTargetAddress = 0x1F98431c8aD98523631AE4a59f267346ea31F984;

    // function to create a proposal on Ethereum L1 to enable a fee amount on the Uniswap V3 Factory on Arbitrum.
    // Upon execution of the proposal, the Inbox contract function createRetryableTicket is called, containing calldata for the
    // uniswap v3 factory to enable a fee amount on Uniswap V3 Factory on Arbitrum
    function proposeForExecutionOnArbitrum() external payable {
        // setup calldata for the Arbitrum uniswap v3Factory.enableFeeAmount call
        bytes memory _v3FactoryEnableFeeAmounCalldata =
            abi.encodeWithSelector(IUniswapV3Factory.enableFeeAmount.selector, 10000, 205);

        // setup calldata for the creating retryable ticket
        uint256 callValue = 0; // Amount of ETH to send with the call on Arbitrum
        uint256 maxSubmissionCost = 0.01 ether; // Estimated cost for submission
        uint256 maxGas = 1_000_000; // Maximum gas for Arbitrum execution
        uint256 gasPriceBid = 1 gwei; // Gas price for Arbitrum execution

        // Define refund addresses for excess fees and call value
        address excessFeeRefundAddress = msg.sender;
        address callValueRefundAddress = msg.sender;

        // setup calldata for the proposal
        bytes memory _proposalCalldata = abi.encode(
            v3FactoryTargetAddress,
            callValue,
            maxSubmissionCost,
            excessFeeRefundAddress,
            callValueRefundAddress,
            callValueRefundAddress,
            maxGas,
            gasPriceBid,
            _v3FactoryEnableFeeAmounCalldata
        );

        // make the proposal on the L1 side
        IUniswapGovernorBravoDelegator governor = IUniswapGovernorBravoDelegator(uniswapGovernorBravoDelegatorAddress);
        address[] memory _targets = new address[](1);
        uint256[] memory _values = new uint256[](1);
        string[] memory _signatures = new string[](1);
        bytes[] memory _calldatas = new bytes[](1);
        _targets[0] = INBOX_ADDRESS;
        _values[0] = 0;
        _signatures[0] = "createRetryableTicket(address,uint256,uint256,address,address,uint256,uint256,bytes)";
        _calldatas[0] = _proposalCalldata;
        uint256 _proposalId = governor.propose(
            _targets,
            _values,
            _signatures,
            _calldatas,
            "Proposal to enable 10000 fee amount of 205 on Uniswap V3 Factory on Arbitrum"
        );
        console2.log("Proposal ID: %d", _proposalId);
    }
}

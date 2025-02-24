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

contract EthereumToZkSyncSender is Script {
    // target address for UniSwap DAO governor bravo delegate
    address uniswapGovernorBravoDelegatorAddress = 0x408ED6354d4973f66138C91495F2f2FCbd8724C3;

    // Address of the MailboxFacet contract on Ethereum (L1)
    address constant MAILBOX_FACET_ADDRESS = 0x63b5EC36B09384fFA7106A80Ec7cfdFCa521fD08;

    // target addresses on ZkSync Era
    address v3FactoryTargetAddress = 0x8FdA5a7a8dCA67BBcDd10F02Fa0649A937215422;

    // function to create a proposal on Ethereum L1 to enable a fee amount on the Uniswap V3 Factory on ZkSync Era.
    // Upon execution of the proposal, the MailboxFacet contract function requestL2Transaction is called, containing calldata for the
    // uniswap v3 factory to enable a fee amount on Uniswap V3 Factory on ZkSync Era.
    function proposeForExecutionOnZkSync() external payable {
        // setup calldata for the ZkSync Era uniswap v3Factory.enableFeeAmount call
        bytes memory _v3FactoryEnableFeeAmounCalldata =
            abi.encodeWithSelector(IUniswapV3Factory.enableFeeAmount.selector, 10000, 205);

        // setup calldata for the creating retryable ticket
        uint256 callValue = 0; // Amount of ETH to send with the call on ZkSync Era
        uint256 maxSubmissionCost = 0.01 ether; // Estimated cost for submission
        uint256 maxGas = 1_000_000; // Maximum gas for ZkSync Era execution

        // Define refund addresses
        address refundRecipientAddress = msg.sender;

        // Define known L2 dependency addresses
        bytes[] memory knownL2DependentAddresses = new bytes[](1);

        // setup calldata for the proposal
        bytes memory _proposalCalldata = abi.encode(
            v3FactoryTargetAddress,
            callValue,
            _v3FactoryEnableFeeAmounCalldata,
            maxGas,
            maxSubmissionCost,
            knownL2DependentAddresses,
            refundRecipientAddress
        );

        // make the proposal on the L1 side
        IUniswapGovernorBravoDelegator governor = IUniswapGovernorBravoDelegator(uniswapGovernorBravoDelegatorAddress);
        address[] memory _targets = new address[](1);
        uint256[] memory _values = new uint256[](1);
        string[] memory _signatures = new string[](1);
        bytes[] memory _calldatas = new bytes[](1);
        _targets[0] = MAILBOX_FACET_ADDRESS;
        _values[0] = 0;
        _signatures[0] = "requestL2Transaction(address,uint256,bytes,uint256,uint256,bytes[],address)";
        _calldatas[0] = _proposalCalldata;
        uint256 _proposalId = governor.propose(
            _targets,
            _values,
            _signatures,
            _calldatas,
            "Proposal to enable 10000 fee amount of 205 on Uniswap V3 Factory on ZkSync Era"
        );
        console2.log("Proposal ID: %d", _proposalId);
    }
}

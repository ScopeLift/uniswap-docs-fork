// SPDX-License-Identifier: UNLICENSED
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

contract EthereumToAvaxSender is Script {
    // target address for UniSwap DAO governor bravo delegate
    address uniswapGovernorBravoDelegatorAddress = 0x408ED6354d4973f66138C91495F2f2FCbd8724C3;

    // Address of the LayerZero:EndpointV2 contract on Ethereum (L1)
    address constant LAYERZERO_ENDPOINT_ADDRESS = 0x1a44076050125825900e736c501f859c50fE728c;

    // Address of the OmniChainExecutor contract on AVAX
    address constant OMNICHAIN_EXECUTOR_ADDRESS = 0x341c1511141022cf8eE20824Ae0fFA3491F1302b;

    // target addresses on AVAX
    address v3FactoryTargetAddress = 0x740b1c1de25031C31FF4fC9A62f554A55cdC1baD;

    // AVAX chainId
    uint256 constant CHAIN_ID = 43114;

    // function to create a proposal on Ethereum L1 to enable a fee amount on the Uniswap V3 Factory on AVAX.
    // Upon execution of the proposal, the WormholeMessageSender contract function sendMessage is called, containing calldata for the
    // uniswap v3 factory to enable a fee amount on Uniswap V3 Factory on AVAX.
    function proposeForExecutionOnAvax() external payable {
        // setup calldata for the AVAX uniswap v3Factory.enableFeeAmount call
        bytes memory _v3FactoryEnableFeeAmounCalldata =
            abi.encodeWithSelector(IUniswapV3Factory.enableFeeAmount.selector, 10000, 205);

        // encode the calldata for the LayerZeroEndpoint.send call
        bytes memory _sendCalldata = abi.encode(
            CHAIN_ID, // Destination chain ID
            OMNICHAIN_EXECUTOR_ADDRESS, // Address on the destination chain
            _v3FactoryEnableFeeAmounCalldata, // Message payload
            address(this), // Refund address for unused gas
            address(0), // Address for paying fees in ZRO (if used)
            0 // Parameters for adapter services (e.g., gas limits)
        );

        // make the proposal on the L1 side
        IUniswapGovernorBravoDelegator governor = IUniswapGovernorBravoDelegator(uniswapGovernorBravoDelegatorAddress);
        address[] memory _targets = new address[](1);
        uint256[] memory _values = new uint256[](1);
        string[] memory _signatures = new string[](1);
        bytes[] memory _calldatas = new bytes[](1);
        _targets[0] = LAYERZERO_ENDPOINT_ADDRESS;
        _values[0] = 0;
        _signatures[0] = "send(uint16,bytes,bytes,address,address,bytes)";
        _calldatas[0] = _sendCalldata;
        uint256 _proposalId = governor.propose(
            _targets,
            _values,
            _signatures,
            _calldatas,
            "Proposal to enable 10000 fee amount of 205 on Uniswap V3 Factory on AVAX"
        );
        console2.log("Proposal ID: %d", _proposalId);
    }
}

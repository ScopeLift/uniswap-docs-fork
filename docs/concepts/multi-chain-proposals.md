---
id: multi-chain-proposals
title: Multi-Chain Proposals
---

This is a living document which represents the current process guidelines for developing and advancing multi-chain Uniswap Governance Proposals. It was last updated January 2025.

## Introduction

Uniswap V3 has now been deployed across 24 blockchain networks, including many Layer 2 chains.
However, because Uniswap governance (using GovernorBravo and its associated Timelock contract) executes approved proposals on Ethereum mainnet, implementing changes on these other blockchains requires some extra steps in the proposals' executable code.

For a proposal to successfully enact changes on a non-mainnet chain, the proposal's code must transmit the necessary code to effect the change on the specific target chain for execution.
A variety of mechanisms are used on the individual non-mainnet chains to receive the proposal code, although in some cases, similar or even identical communication methods and contracts are used to bridge proposals from Ethereum mainnet to the target chain.

This document provides a detailed guide on constructing such proposals for each target non-mainnet chain, including Solidity code snippets for each general approach.
The code snippets are written as Forge/Foundry scripts, and assume they are being run on the Forge platform, in a code repository with the necessary libraries (forge-std, uniswap-v3-core, and uniswap-v3-periphery) imported.
It is important to note that the code provided here is a general template and may require modification to suit the specific requirements of the target chain.

## Overview

Of the 24 chains where Uniswap V3 is deployed there are 10 chains that are OP Stack based and use an `L1CrossDomainMessenger` contract for bridging proposals.
There are 6 chains that use Wormhole for bridging proposals.
The remaining 8 chains use a variety of other methods for bridging proposals, all described below.
The table below contains links to the various proposal methods for each chain.

| Chain(s)      | Proposal Method                                       |
| ------------- | ----------------------------------------------------- |
| Arbitrum      | [Arbitrum - Aliased Timelock](#arbitrum)              |
| Avalanche     | [Avalanche - OmnichainGovernanceExecutor](#avalanche) |
| Base          | [OP Stack - CrossChainAccount](#op-stack)             |
| Blast         | [OP Stack - CrossChainAccount](#op-stack)             |
| BNB Chain     | [Wormhole](#wormhole)                                 |
| Boba          | [OP Stack - CrossChainAccount](#op-stack)             |
| Celo          | [Wormhole](#wormhole)                                 |
| Filecoin      | [Filecoin - TODO](#filecoin)                          |
| Gnosis Chain  | [Wormhole](#wormhole)                                 |
| Linea         | [OP Stack - CrossChainAccount](#op-stack)             |
| Manta Pacific | [OP Stack - CrossChainAccount](#op-stack)             |
| Mantle        | [OP Stack - CrossChainAccount](#op-stack)             |
| Moonbeam      | [Wormhole](#wormhole)                                 |
| Optimism      | [OP Stack - CrossChainAccount](#op-stack)             |
| Polygon       | [Polygon - FxChild](#polygon)                         |
| Polygon zkEVM | [Polygon zkEVM - TODO](#polygon-zkevm)                |
| Redstone      | [OP Stack - CrossChainAccount](#op-stack)             |
| Rootstock     | [Wormhole](#wormhole)                                 |
| Scroll        | [Scroll - CrossChainAccount](#scroll)                 |
| Sei           | [Sei - Wormhole](#wormhole)                           |
| Taiko         | [Taiko - InvokableAccount](#taiko)                    |
| WorldCoin     | [OP Stack - CrossChainAccount](#op-stack)             |
| ZkSync Era    | [ZkSync Era - Aliased Timelock](#zksync-era)          |
| Zora          | [OP Stack - CrossChainAccount](#op-stack)             |

## Arbitrum

Arbitrum uses an approach where the owner of the V3Factory is a special aliased address (offset by the value `0x1111000000000000000000000000000000001111`) that (when the offset is subtracted away) is the L1 address of the Uniswap DAO Timelock contract. A Solidity code example for sending a proposal to Arbitrum is shown below.

Proposal calldata on mainnet intended for Arbitrum should be forwarded through a call to `createRetryableTicket` on the Arbitrum Inbox contract.
The call would have wrapped calldata for a Uniswap contract function call that would effect the change. An example:

```
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
```

## Avalanche

Avalanche makes use of a contract called `OmnichainGovernanceExecutor` to receive proposals from Ethereum mainnet.
Proposal calldata on mainnet intended for Avalanche should be forwarded through a call to `send` on the contract called `LayerZero:EndpointV2`.
A Solidity code example for sending a proposal to AVAX is below.

```
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
```

## Filecoin

Filecoin EVM ?? TODO: Add details

## OP Stack

Proposal calldata on mainnet meant for an OP stack chain should be forwarded through a call to sendMessage on the chain's corresponding mainnet `L1CrossDomainMessenger` contract.
The call would have doubly-wrapped calldata for the `CrossChainAccount:forward` function as well as the ultimate Uniswap contract function call that would effect the change. An example for Optimism:

```
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
```

Because 10 networks all use the same CrossChainAccount approach for communication, the only modifications to the above code snippet for those networks would be to change the first 3 address constant definitions. The definitions for all of the OP Stack based networks are below:

:::warning
**Linea**'s `sendMessage` reverses the order of the `fee` and `message` parameters.
:::

The relevant OP Stack contract addresses are as follows:

<table>
  <thead>
    <tr>
      <th>Network</th>
      <th>Contract Addresses</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>Base</td>
      <td>
        <b>l1CrossDomainMessengerAddress:</b><br />
            <span style={{ marginLeft: '20px' }}>0x866E82a600A1414e583f7F13623F1aC5d58b0Afa</span><br />
        <b>v3FactoryTargetAddress:</b><br />
            <span style={{ marginLeft: '20px' }}>0x33128a8fC17869897dcE68Ed026d694621f6FDfD</span><br />
        <b>crossChainAccountTarget:</b><br />
            <span style={{ marginLeft: '20px' }}>0x31FAfd4889FA1269F7a13A66eE0fB458f27D72A9</span><br />
      </td>
    </tr>
    <tr>
      <td>Blast</td>
      <td>
        <b>l1CrossDomainMessengerAddress:</b><br />
            <span style={{ marginLeft: '20px' }}>0x5D4472f31Bd9385709ec61305AFc749F0fA8e9d0</span><br />
        <b>v3FactoryTargetAddress:</b><br />
            <span style={{ marginLeft: '20px' }}>0x792edAdE80af5fC680d96a2eD80A44247D2Cf6Fd</span><br />
        <b>crossChainAccountTarget:</b><br />
            <span style={{ marginLeft: '20px' }}>0x2339C0d23b60739B3E5ABF201F05903D24A26C77</span><br />
      </td>
    </tr>
    <tr>
      <td>Boba</td>
      <td>
        <b>l1CrossDomainMessengerAddress:</b><br />
            <span style={{ marginLeft: '20px' }}>0x6D4528d192dB72E282265D6092F4B872f9Dff69e</span><br />
        <b>v3FactoryTargetAddress:</b><br />
            <span style={{ marginLeft: '20px' }}>0xFFCd7Aed9C627E82A765c3247d562239507f6f1B</span><br />
        <b>crossChainAccountTarget:</b><br />
            <span style={{ marginLeft: '20px' }}>0x53163235746CeB81Da32293bb0932e1A599256B4</span><br />
      </td>
    </tr>
    <tr>
      <td>Linea (see warning)</td>
      <td>
        <b>l1CrossDomainMessengerAddress:</b><br />
            <span style={{ marginLeft: '20px' }}>0xd19d4B5d358258f05D7B411E21A1460D11B0876F</span><br />
        <b>v3FactoryTargetAddress:</b><br />
            <span style={{ marginLeft: '20px' }}>0x1111??</span><br />
        <b>crossChainAccountTarget:</b><br />
            <span style={{ marginLeft: '20px' }}>0x581F86Da293A1D5Cd087a10E7227a75d2d2201A8</span><br />
      </td>
    </tr>
    <tr>
      <td>Manta Pacific</td>
      <td>
        <b>l1CrossDomainMessengerAddress:</b><br />
            <span style={{ marginLeft: '20px' }}>0x635ba609680c55C3bDd0B3627b4c5dB21b13c310</span><br />
        <b>v3FactoryTargetAddress:</b><br />
            <span style={{ marginLeft: '20px' }}>0x06D830e15081f65923674268121FF57Cc54e4e23</span><br />
        <b>crossChainAccountTarget:</b><br />
            <span style={{ marginLeft: '20px' }}>0x683553d74D9779955a15d57D208234C956B6Eae6</span><br />
      </td>
    </tr>
    <tr>
      <td>Mantle</td>
      <td>
        <b>l1CrossDomainMessengerAddress:</b><br />
            <span style={{ marginLeft: '20px' }}>0x676A795fe6E43C17c668de16730c3F690FEB7120</span><br />
        <b>v3FactoryTargetAddress:</b><br />
            <span style={{ marginLeft: '20px' }}>0x0d922Fb1Bc191F64970ac40376643808b4B74Df9</span><br />
        <b>crossChainAccountTarget:</b><br />
            <span style={{ marginLeft: '20px' }}>0x9b7aC6735b23578E81260acD34E3668D0cc6000A</span><br />
      </td>
    </tr>
    <tr>
      <td>Optimism</td>
      <td>
        <b>l1CrossDomainMessengerAddress:</b><br />
            <span style={{ marginLeft: '20px' }}>0x25ace71c97B33Cc4729CF772ae268934F7ab5fA1</span><br />
        <b>v3FactoryTargetAddress:</b><br />
            <span style={{ marginLeft: '20px' }}>0x1F98431c8aD98523631AE4a59f267346ea31F984</span><br />
        <b>crossChainAccountTarget:</b><br />
            <span style={{ marginLeft: '20px' }}>0xa1dD330d602c32622AA270Ea73d078B803Cb3518</span><br />
      </td>
    </tr>
    <tr>
      <td>Redstone</td>
      <td>
        <b>l1CrossDomainMessengerAddress:</b><br />
            <span style={{ marginLeft: '20px' }}>0x592C1299e0F8331D81A28C0FC7352Da24eDB444a</span><br />
        <b>v3FactoryTargetAddress:</b><br />
            <span style={{ marginLeft: '20px' }}>0xece75613Aa9b1680f0421E5B2eF376DF68aa83Bb</span><br />
        <b>crossChainAccountTarget:</b><br />
            <span style={{ marginLeft: '20px' }}>0x2d00e94d78Fc307FC5E6195BBe2fB6aFC2FC07d4</span><br />
      </td>
    </tr>
    <tr>
      <td>Worldcoin</td>
      <td>
        <b>l1CrossDomainMessengerAddress:</b><br />
            <span style={{ marginLeft: '20px' }}>0xf931a81D18B1766d15695ffc7c1920a62b7e710a</span><br />
        <b>v3FactoryTargetAddress:</b><br />
            <span style={{ marginLeft: '20px' }}>0x7a5028BDa40e7B173C278C5342087826455ea25a</span><br />
        <b>crossChainAccountTarget:</b><br />
            <span style={{ marginLeft: '20px' }}>0xcb2436774C3e191c85056d248EF4260ce5f27A9D</span><br />
      </td>
    </tr>
    <tr>
      <td>Worldcoin</td>
      <td>
        <b>l1CrossDomainMessengerAddress:</b><br />
            <span style={{ marginLeft: '20px' }}>0xdC40a14d9abd6F410226f1E6de71aE03441ca506</span><br />
        <b>v3FactoryTargetAddress:</b><br />
            <span style={{ marginLeft: '20px' }}>0x7145F8aeef1f6510E92164038E1B6F8cB2c42Cbb</span><br />
        <b>crossChainAccountTarget:</b><br />
            <span style={{ marginLeft: '20px' }}>0x36eEC182D0B24Df3DC23115D64DB521A93D5154f</span><br />
      </td>
    </tr>
  </tbody>
</table>

## Polygon

Polygon makes use of an L1 contract called FxRoot for sending messages (in the case of Uniswap, executable proposals), and contracts called FxChild and EthereumProxy on the Polygon chain for forwarding the executable proposals to Uniswap V3 on Polygon.

Proposal calldata on mainnet meant for Polygon should be forwarded through a call to `sendMessageToChild` on the chain's corresponding mainnet `FxRoot` contract.
The call would have wrapped calldata for a Uniswap contract function call that would effect the change. The FxRoot/FxChild tunnel would bridge that message to Polygon where FxChild would route the message the EthereumProxy parent contract of UniSwap V3. An example:

```
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
```

## Polygon zkEVM

Polygon zkEVM uses a different approach than Polygon TODO: Add details

## Scroll

Scroll also makes use of the CrossChainAccount contract for receiving proposals from Ethereum mainnet, but the way that messages are sent is different from the other OP Stack approaches.
Proposal calldata on mainnet meant for the Scroll chain should be forwarded through a call to `sendMessage` on the chain's corresponding mainnet `L1ScrollMessenger` contract.

```
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
```

## Taiko

Taiko makes use of a contract called `InvokableAccount`.
Proposal calldata on mainnet meant for the Taiko chain should be forwarded through a call to`emitSignal`on the chain's corresponding mainnet`SignalService` contract.
The call would have wrapped calldata for the Uniswap contract function call that would effect the change. An example:

```
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
```

## Wormhole

There are 5 chains where Uniswap V3 is deployed that use the same Ethereum mainnet instance of the `UniswapWormholeMessageSender` contract for sending proposals to the target.
Proposal calldata on mainnet meant for a target chain using Wormhole should be forwarded through a call to the `sendMessage` function of that contract.
The function takes both a target address for the message receiving contract on the destination chain, as well as the Chain ID of the destination chain as parameters, allowing the function to be used for sending to multiple destination chains.

A Solidity code example for sending a proposal to one these chains (BNB Chain) is provided below.

```
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
```

Because 5 networks all use the same Wormhole-based approach for communication, the only modifications to the above code snippet for those networks would be to change the first 3 constant definitions. The definitions for all 5 networks that use Wormhole communication are below:

| Network   | WORMHOLE_MESSAGE_RECEIVER_ADDRESS            | CHAIN_ID | V3FactoryTargetAddress                       |
| --------- | -------------------------------------------- | -------- | -------------------------------------------- |
| Celo      | `0x0Eb863541278308c3A64F8E908BC646e27BFD071` | 42220    | `0xAfE208a311B21f13EF87E33A90049fC17A7acDEc` |
| Gnosis    | `0xfFA5599136fBaB9af7799A6703b57BB33E5390Cf` | 100      | `0xe32F7dD7e3f098D518ff19A22d5f028e076489B1` |
| Moonbeam  | `0xB2af16D6c7074228fC487F17929De830303E6531` | 1284     | `0xe32F7dD7e3f098D518ff19A22d5f028e076489B1` |
| Rootstock | `0x38aE7De6f9c51e17f49cF5730DD5F2d29fa20758` | 1329     | `0xaF37EC98A00FD63689CF3060BF3B6784E00caD82` |
| Sei       | `0xDAA94C43133c6c645017134Ba372DDa4829F34A6` | 30       | `0x75FC67473A91335B5b8F8821277262a13B38c9b3` |

## ZkSync Era

ZkSync Era uses the Arbitrum-style approach where the parent of the V3Factory contract is an aliased address, but the method of sending the proposal is different than the one used for Arbitrum.
Proposal calldata on mainnet intended for ZkSync Era should be forwarded through a call to `requestL2Transaction` on the `MailBoxFacet` contract.
The call would have wrapped calldata for a Uniswap contract function call that would effect the change. An example:

```
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
```

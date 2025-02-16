---
id: process
title: Process
---

This is a living document which represents the current process guidelines for developing and advancing Uniswap Governance Proposals. It was last updated September 2024.

## Tools

Uniswap Governance takes place in several venues. Each serves its own particular purpose.

1.  [_Governance Forum_](https://gov.uniswap.org/)

A Discourse-hosted forum for governance-related discussion. Community members must register for an account before sharing or liking posts. New members must read 4 topics and a combined 15 posts over the course of at least 10 minutes before they may  post themselves.

2. [_Snapshot_](https://snapshot.box/#/s:uniswapgovernance.eth)

A simple voting interface that allows users to signal sentiment off-chain. Votes on Snapshot are weighted by the number of UNI delegated to the address used to vote.

3. [_Uniswap Agora_](https://vote.uniswapfoundation.org)

The [Uniswap Foundation](https://www.uniswapfoundation.org) supports this voting and delegation interface. [Tally](https://www.tally.xyz/gov/uniswap) is another excellent app that supports proposal creation, delegation, and voting.


## Process

Below we outline the current Uniswap governance process, detailing where these venues fit in. These processes are subject to change according to feedback from the Uniswap community.

### Phase 1: Request for Comment (RFC)

_Timeframe_: At least 7 days

_Form_: [Governance Forum](https://gov.uniswap.org/) Post

As a proposer, you should use the RFC phase to introduce the community to your proposal. Your post should detail exactly what you are asking delegates to vote on as well as your rationale for why it is a good idea. You should be prepared to answer questions about your proposal. Willingness to adjust based on community feedback is a hallmark of successful past proposals.

To post a RFC, label your post “RFC - [Your Title Here]”. Prior to moving to Phase 2, give the community at least 7 days to read and comment on the RFC. Please respond to questions in the comments, and take feedback into account in the next iteration of the proposal posted in Phase 2.

### Phase 2: Temperature Check

_Timeframe_: 5 days

_Quorum_: 10M UNI

_Form_: [Snapshot Poll](https://snapshot.box/#/s:uniswapgovernance.eth)

The purpose of the Temperature Check is to signal community sentiment on a proposal prior to moving towards an onchain vote.

To create a Temperature Check:

1. Incorporate the community feedback from the RFC phase into the proposal.

2. Create and post this version of the proposal in the [Governance Forum](https://gov.uniswap.org/) with the title “Temperature Check — [Your Title Here]”. Include a link to the RFC post. You will update the post to include a link to the Snapshot poll after you’ve posted that.

3. Create a [Snapshot poll](https://snapshot.box/#/s:uniswapgovernance.eth). The voting options should consist of those which have gained support in the RFC Phase. This poll can be either binary or multiple choice but must include a `No change` option. Set the poll duration to 5 days. Include a link to the Forum Temperature Check post.

4. Update the Forum post with a link to the Snapshot Poll.

At the end of 5 days, the option with the majority of votes wins. There must be at least 10M UNI `Yes` votes to move onto Phase 3. If the “No change” option wins, the proposal will not move onto the Phase 3.

### Phase 3: Governance Proposal

_Timeframe_: 2 day waiting period, 7 day voting period, 2 day timelock

 _Threshold_: 1M UNI

_Quorum_: 40M UNI votes in favor

Form: [Governance Proposal](https://vote.uniswapfoundation.org/)

![](./images/Proposal_Flow.png)

Phase 3 is the final step of the governance process. If this vote passes, then a change will be enacted onchain.

To create an onchain Governance Proposal:

1. Incorporate any last iterations to your proposal based on feedback prior to posting.

2. Create a topic in the [Governance Forum](https://gov.uniswap.org/) titled "Governance Proposal — [Your Title Here]" and link to previous forum posts and the Temperature Check Snapshot poll.

3. Create your proposal. This can be done either through an interface (e.g. [Tally](https://tally.xyz/gov/uniswap)) or through writing the calldata for more complicated proposal logic. If the proposal passed, this calldata will execute. If writing the calldata yourself, please review the logic with a qualified Uniswap community member prior to posting the proposal.

4. Ensure that at least 1 million UNI is delegated to your address in order to submit a proposal, or find a delegate who has enough delegated UNI to meet the proposal threshold to propose on your behalf.

5. Once you submit the proposal, a two-day voting delay will start. After the voting delay finishes, a ~seven-day voting period begins. If the proposal passes, a two-day timelock must pass before you can execute the proposed code.

## Changes to the Governance Process

Timeframe: 7 days

_Quorum_: 40M UNI

Form: [Snapshot Poll](https://snapshot.box/#/s:uniswapgovernance.eth)

In the future, the community governance process above may need to undergo additional changes to continue to meet the needs of the Uniswap community. While an onchain vote is not required to change the majority of this process, a clear display of community support and acceptance is important for process changes to have legitimacy.

Thus, changes to all off-chain community governance processes should be voted on through an off-chain Snapshot vote. There should be a 7-day voting period and 40M UNI quorum.

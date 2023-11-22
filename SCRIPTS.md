# Scripts

## Convert Scores (list unpacked) to Number (packed)

Convert a list of scores into a packed value.

> The list of scores must be in order. Check the `Scores` section in the [README.md](./README.md) file.

`yarn scores-to-number --scores 3,4,5,4,3,4,2 --bitsPerScore 5`

Go to [script](./script/scores-to-number.ts).

## Convert Number (packed) to Scores (list unpacked)

Convert a packed value (score) into a list of scores (unpacked).

`yarn number-to-scores --number 3360820354 --totalScores 6 --bitsPerScore 5`

Go to [script](./script/number-to-scores.ts).

## Get the current Risk Scores from yDaemon API

`yarn get-risk-scores --network 1`

Go to [script](./script/getCurrentRiskScores.ts).

## Convert tags (string) into bytes32

`yarn tags-to-bytes32 --tags curve,aave --separator ,`

Go to [script](./script/tags-to-bytes32.ts).

## Get Risk Scores from the Subgraph

- Gets all the scores for network id 1

`yarn get-risk-scores-subgraph --network 1`

- Gets all the scores for all the network

`yarn get-risk-scores-subgraph --network 0` or `yarn get-risk-scores-subgraph --network 1`

Go to [script](./script/get-risk-scores-subgraph.ts).

## Set the Scores to a List of Targets

`forge script ./script/SetScore.s.sol:SetScoreScript --rpc-url <rpc-url> --etherscan-api-key <etherscan-api-key> -vvvv --broadcastfy`

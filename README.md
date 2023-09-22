# Risk Framework Onchain

## How to Calculate the Scores in Uint

Let's say, we want to score a target address using these 7 scores:

Scores: 5, 4, 3, 2, 1, 2, and 3.

If we convert each score into binary, each one is:

Scores: 00101, 00100, 00011, 00010, 00001, 00010 and 00011

But if we join all the binary values in one number:

`101001000001100010000010001000011`

The decimal representation is: `5506139203`

That is the value we use to call the Risk Framework onchain.

The values are manipulated by bitwise operators in the library `ScoresLib.sol`.

## Considerations

- It supports up to 15 scores.
- The scores are processed in order (right to left).
- The sorting process cannot be change in the scores. It means that if the first score (right) represents the Testing score, then it cannot be changed to the second place, because as we saw before, the final number (decimal representation) would change.

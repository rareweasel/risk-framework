import parseArgvs, { ParsedArgs } from "minimist";
import { fromNumberToScore } from "../src/utils/utils";

const args = parseArgvs(process.argv.slice(2), {
  string: [],
  boolean: [],
});

/**
    Example: yarn number-to-scores --number 3360820354 --totalScores 7 --bitsPerScore 5
 */
const execute = async (parsedArgs: ParsedArgs) => {
  if (!parsedArgs.number) throw new Error("Missing scores argument");
  const number = parseInt(parsedArgs.number);
  const totalScores = parsedArgs.totalScores ? parsedArgs.totalScores : 7;
  const bitsPerScore = parsedArgs.bitsPerScore ? parsedArgs.bitsPerScore : 5;
  const scores = fromNumberToScore(number, totalScores, bitsPerScore, false);
  console.log(`Scores: ${scores.join(",")}`);
};

execute(args)
  .catch((reason) => {
    console.log("Execution failed:");
    console.log(reason);
  })
  .finally(() => console.log("Execution finished"));

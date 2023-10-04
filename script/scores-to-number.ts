import parseArgvs, { ParsedArgs } from "minimist";
import { fromScoreToNumber } from "../src/utils/utils";

const args = parseArgvs(process.argv.slice(2), {
  string: [],
  boolean: [],
});

/**
    Example: yarn scores-to-number --scores 3,4,5,4,3,4,2 --bitsPerScore 5
 */
const execute = async (parsedArgs: ParsedArgs) => {
  if (!parsedArgs.scores) throw new Error("Missing scores argument");

  const scores = parsedArgs.scores.split(",").map((score:string) => parseInt(score));
  const bitsPerScore = parsedArgs.bitsPerScore ? parsedArgs.bitsPerScore : 5;
  const number = fromScoreToNumber(scores, bitsPerScore, false);
  console.log(`Decimal Score: ${number}`);
};

execute(args)
  .catch((reason) => {
    console.log("Execution failed:");
    console.log(reason);
  })
  ;//.finally(() => console.log("Execution finished"));

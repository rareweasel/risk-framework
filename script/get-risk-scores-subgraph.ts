import parseArgvs, { ParsedArgs } from "minimist";
import axios from "axios";

const args = parseArgvs(process.argv.slice(2), {
  string: [],
  boolean: [],
});

const SUBGRAPH_BASE_API_URL = "https://api.thegraph.com/subgraphs/name/yearn/yearn-risk-framework";

const getScores = async (network: number) => {
  let where = 'targets {';
  if (network > 0) {
    where = `targets(where: {networkId:${network}}) {`;
  }
  const query = `
    {
      ${where}
        id
        address
        targetUrl
        networkId
        score {
          score
          scores
          averageScore
        }
        tags {
          value
          timestamp
          removed
        }
      }
    }
  `;
  const response = await axios.post(SUBGRAPH_BASE_API_URL, {query});
  return response.data.data.targets;
};

/**
    Example:
    
    - yarn get-risk-scores-subgraph --network 1
      Gets all the scores for the network 1 (Ethereum Mainnet)
    - yarn get-risk-scores-subgraph
      Gets all the scores for all the networks
    
 */
const execute = async (parsedArgs: ParsedArgs) => {
  const network = parsedArgs.network === undefined ? 0 : parseInt(parsedArgs.network);
  const scores = await getScores(network);
  const formatTo = (value: string, decimals: number = 3): string => {
    return (parseFloat(value.toString()) / 1000 ).toFixed(decimals);
  }
  const headerText = `#|Network Id|Target URL|Decimal Score|Scores|Average Score|Tags`;
  console.log(headerText);
  let counter = 1;
  for (const scoreItem of scores) {
    const {
      targetUrl,
      networkId,
      score,
      tags
    } = scoreItem;
    const {
      score: decimalScore, scores, averageScore
    } = score;
    const strategyText = `${networkId}|${targetUrl}`;
    const scoreText = `${decimalScore}|${scores}|${formatTo(averageScore)}`;
    const tagsText = `${tags.filter((tag: any) => tag.removed == false).map((tag: any) => tag.value).join(",")}`;
    console.log(`${counter}|${strategyText}|${scoreText}|${tagsText}`);
    counter++;
  }
};

execute(args)
  .catch((reason) => {
    console.log("Execution failed:");
    console.log(reason);
  })
  .finally(() => console.log("Execution finished"));

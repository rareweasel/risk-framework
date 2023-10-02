import parseArgvs, { ParsedArgs } from "minimist";
import axios from "axios";
import { fromScoreToNumber } from "../src/utils/utils";

const args = parseArgvs(process.argv.slice(2), {
  string: [],
  boolean: [],
});

const YDAEMON_BASE_API_URL = "https://ydaemon.yearn.fi";

const getVaults = async (network: number) => {
  const url = `${YDAEMON_BASE_API_URL}/${network}/vaults/all?classification=all&strategiesDetails=withDetails`;
  const response = await axios.get(url);
  return response.data;
};

const getStrategies = async (network: number, strategyAddress: string) => {
  const response = await axios.get(`${YDAEMON_BASE_API_URL}/${network}/strategies/${strategyAddress}`);
  return response.data;
};

/**
    Example: yarn get-risk-scores --network 1 --bitsPerScore 5
 */
const execute = async (parsedArgs: ParsedArgs) => {
  if (!parsedArgs.network) throw new Error("Missing network argument");
  const network = parseInt(parsedArgs.network);
  const bitsPerScore = parsedArgs.bitsPerScore ? parsedArgs.bitsPerScore : 5;
  
  const vaults = await getVaults(network);
  const formatTo = (value: string, decimals: number = 2): string => {
    return parseFloat(value.toString()).toFixed(decimals);
  }
  const headerText = `#|Network Id|Vault Name|Vault Address|Strategy Address|Strategy Name|Display Name|Audit|Code Review|Complexity|Longevity|Protocol Safety|Team Knowledge|Testing|Decimal Risk Score|Status|Current TVL|Available TVL|Current Amount|Available Amount`;
  console.log(headerText);
  let counter = 1;
  for (const vault of vaults as Array<any>) {
    const strategies = vault.strategies || [];
    for (const strategy of strategies as Array<any>) {
      const {
        address: strategyAddress, name, displayName, description, details, risk, 
      } = await getStrategies(network, strategy.address);
      const {
        riskScore,
        riskGroup,
        riskDetails: {
          TVLImpact,
          auditScore,
          codeReviewScore,
          complexityScore,
          longevityImpact,
          protocolSafetyScore,
          teamKnowledgeScore,
          testingScore
        },
        allocation: {
          status,
          currentTVL,
          availableTVL,
          currentAmount,
          availableAmount,
        }
      } = risk;
      const scores = [
        parseInt(auditScore),
        parseInt(codeReviewScore),
        parseInt(complexityScore),
        parseInt(longevityImpact),
        parseInt(protocolSafetyScore),
        parseInt(teamKnowledgeScore),
        parseInt(testingScore)
      ];
      
      const scoreDecimals = fromScoreToNumber(scores, bitsPerScore, false);

      const vaultText = `${vault.name}|${vault.address}`;
      const strategyText = `${strategyAddress}|${name}|${displayName}`;
      const riskScoreText = `${auditScore}|${codeReviewScore}|${complexityScore}|${longevityImpact}|${protocolSafetyScore}|${teamKnowledgeScore}|${testingScore}|${scoreDecimals}`;
      const allocationText = `${status}|${formatTo(currentTVL)}|${formatTo(availableTVL)}|${formatTo(currentAmount)}|${formatTo(availableAmount)}`;
      console.log(`${counter}|${network}|${vaultText}|${strategyText}|${riskScoreText}|${allocationText}`);
      counter++;
    }
  }

};

execute(args)
  .catch((reason) => {
    console.log("Execution failed:");
    console.log(reason);
  })
  .finally(() => console.log("Execution finished"));

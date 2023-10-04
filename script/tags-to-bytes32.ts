import parseArgvs, { ParsedArgs } from "minimist";
import web3 from "web3";

const args = parseArgvs(process.argv.slice(2), {
  string: [],
  boolean: [],
});

/**
    Example: yarn tags-to-bytes32 --tags curve,aave --separator ,
 */
const execute = async (parsedArgs: ParsedArgs) => {
  if (!parsedArgs.tags) throw new Error("Missing tags argument");
  const tagsString = parsedArgs.tags.toString();
  const separator = parsedArgs.separator ? parsedArgs.separator : ',';
  const tagsStringList = tagsString.split(separator);
  const tags = new Array<string>;
  for (const tagString of tagsStringList) {
    const tag = web3.utils.fromAscii(tagString).padEnd(66, '0');
    console.log(`${tagString} => ${tag}`);
    tags.push(tag);
  }
  console.log(`[${tags.join(",")}]`);
};

execute(args)
  .catch((reason) => {
    console.log("Execution failed:");
    console.log(reason);
  })
  .finally(() => console.log("Execution finished"));

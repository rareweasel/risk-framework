/* eslint-disable no-console */
/* eslint-disable import/no-extraneous-dependencies */
/* eslint-disable import/prefer-default-export */

export const stringToBytes32 = (ethers: any, value: string) =>
    ethers.utils.formatBytes32String(value);

export const fromScoreToNumber = (scores: number[], padding: number = 5, printAll: boolean = false): number => {

    const decimalNotation = scores.map(score => score.toString().padStart(padding, ' ')).join(' | ');
    const result = scores.map(score => score.toString(2).padStart(padding, '0'));
    const decimal = parseInt(result.join(''), 2);

    if (printAll) {
        console.log(`1. Decimal notations: ${decimalNotation}`);
        console.log(`2. Binary notations:  ${result.join(' | ')} => ${result.join('')}`);
        console.log(`3. Decimal notation:  ${decimal} = ${result.join('')}`);
    } else {
        console.log(decimal);
    }
    return decimal;
};

export const fromNumberToScore = (number: number, totalScores: number = 7, bitsPerScore: number = 5, printAll: boolean = false): number[] => {
    const totalDigits = totalScores * bitsPerScore;
    const binaryNumber = number.toString(2).padStart(totalDigits, '0');
    const binaryNotations = binaryNumber.match(/.{1,5}/g) ?? [];
    const decimalNotations = binaryNotations.map((notation: string) => parseInt(parseInt(notation, 2).toString(10)));
    if (printAll) {
        console.log(`1. Binary number:      ${binaryNumber}`);
        console.log(`2. Binary notations:   ${binaryNotations.join(' | ')}`);
        console.log(`3. Decimal notations:  ${decimalNotations.map(score => score.toString().padStart(bitsPerScore, ' ')).join(' | ')}`);
    } else {
        console.log(decimalNotations);
    }
    return decimalNotations;
};
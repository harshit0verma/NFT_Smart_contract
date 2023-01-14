const {ethers, network } = require("hardhat");
const fs = require("fs");

const FRONT_END_ADDRESS = "../nextjs-smart-contract-lottery/constants/contractAddresses.json";
const FRONT_END_ABI = "../nextjs-smart-contract-lottery/constants/abi.json";

module.exports = async function (){
    if(process.env.UPDATE_FRONTEND){
        console.log("UPDATING FRONT END ..........");
        
        updateContractAddresses();
        updateAbi();
    }
}

async function updateAbi(){

    const contract = await etheres.getContract(lottery);
    fs.writeFileSync(FRONT_END_ABI, contract.interface.format(ethers.utils.FormatTypes.json));
}

async function updateContractAddresses(){
    const contract = await ethers.getContract("Lottery");
    const currentAddress = JSON.parse(fs.readFileSync(FRONT_END_ADDRESS,"utf8"));
    const chainId = network.config.chainId.toString();
    if( chainId in contractAddress ){
        if(!contractAddress[chainId].includes(contract.address)){
            currentAddress[chainId].push(raffle.address);
        }
    }
    {
        currentAddress[chainId] = [raffle.address];
    }
    fs.writeFileSync(FRONT_END_ADDRESS,JSON.stringify(currentAddress));
}

module.exports.tags =   ["all"]["frontend"];
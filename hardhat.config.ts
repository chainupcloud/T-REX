import '@xyrusworx/hardhat-solidity-json';
import '@nomicfoundation/hardhat-toolbox';
import { HardhatUserConfig } from 'hardhat/config';
import '@openzeppelin/hardhat-upgrades';
import 'solidity-coverage';
import '@nomiclabs/hardhat-solhint';
import '@primitivefi/hardhat-dodoc';
import '@nomicfoundation/hardhat-foundry';
import 'hardhat-gas-reporter';

const config: HardhatUserConfig = {
  solidity: {
    version: '0.8.17',
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  gasReporter: {
    enabled: true,
    outputFile: 'gas-report.txt', // 可选：输出到文件
    noColors: false, // 可选：是否禁用颜色
  },
  dodoc: {
    runOnCompile: false,
    debugMode: true,
    outputDir: './docgen',
    freshOutput: true,
  },
};

export default config;

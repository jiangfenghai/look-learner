## npm初始化

npm init - y

## 下载hardhat安装

npm install    hardhat  --save-dev  (淘宝镜像没有需要指定官方镜像源)

## 初始化hardhat

npx  hardhat

## hardhat编译

npx hardhat compile 

## hardhat部署

npx hardhat run 

## hardhat部署合约步骤

await  ethers.getContractFactory("合约名")

部署 await ethers.deploy

## hardhat获取签名 

ethers.getsingers();如果在配置文件中有多个的话默认是第一个

## hardhat合约验证

await fundMeDepoly.deploymentTransaction().wait(5);

  verifyFundMe(fundMeDepoly.target, [10]);


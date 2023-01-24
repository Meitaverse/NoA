import { BigNumber } from '@ethersproject/bignumber';
import { parseEther } from '@ethersproject/units';
import '@nomiclabs/hardhat-ethers';
import { expect } from 'chai';
import { 
  ERC20__factory,
  DerivativeNFTV1,
  DerivativeNFTV1__factory,
 } from '../../typechain';
import { MAX_UINT256, ZERO_ADDRESS } from '../helpers/constants';
import { ERRORS } from '../helpers/errors';

import { 
  createProfileReturningTokenId,
  createHubReturningHubId,
  createProjectReturningProjectId,
  matchEvent,
  getTimestamp, 
  waitForTx 
} from '../helpers/utils';

import {
  abiCoder,
  INITIAL_SUPPLY,
  VOUCHER_AMOUNT_LIMIT,
  FIRST_PROFILE_ID,
  SECOND_PROFILE_ID,
  THIRD_PROFILE_ID,
  FOUR_PROFILE_ID,
  FIRST_HUB_ID,
  FIRST_PROJECT_ID,
  FIRST_DNFT_TOKEN_ID,
  SECOND_DNFT_TOKEN_ID,
  FIRST_PUBLISH_ID,
  GENESIS_FEE_BPS,
  DEFAULT_COLLECT_PRICE,
  DEFAULT_TEMPLATE_NUMBER,
  NickName,
  NickName3,
  governance,
  manager,
  makeSuiteCleanRoom,
  MAX_PROFILE_IMAGE_URI_LENGTH,
  mockModuleData,
  MOCK_FOLLOW_NFT_URI,
  MOCK_PROFILE_HANDLE,
  MOCK_PROFILE_URI,
  userAddress,
  user,
  userTwo,
  userTwoAddress,
  sbtContract,
  metadataDescriptor,
  publishModule,
  feeCollectModule,
  template,
  receiverMock,
  moduleGlobals,
  bankTreasuryContract,
  deployer,
  voucherContract,
  marketPlaceContract
} from '../__setup.spec';

let derivativeNFT: DerivativeNFTV1;

const Default_royaltyBasisPoints = 50; //
const SALE_ID = 1;
const THIRD_DNFT_TOKEN_ID =3;
const SALE_PRICE = 100;

makeSuiteCleanRoom('Market Place', function () {

  beforeEach(async function () {
 
    expect(
      await createProfileReturningTokenId({
          sender: user,
          vars: {
          wallet: userAddress,
          nickName: NickName,
          imageURI: MOCK_PROFILE_URI,
          },
         }) 
      ).to.eq(SECOND_PROFILE_ID);
             
      //mint some Values to user
      await manager.connect(governance).mintSBTValue(SECOND_PROFILE_ID, parseEther('10'));


      expect(
      await createProfileReturningTokenId({
            sender: userTwo,
            vars: {
            wallet: userTwoAddress,
            nickName: NickName3,
            imageURI: MOCK_PROFILE_URI,
            },
          }) 
        ).to.eq(THIRD_PROFILE_ID);

      await manager.connect(governance).mintSBTValue(THIRD_PROFILE_ID, parseEther('10'));

      expect(await manager.getWalletBySoulBoundTokenId(SECOND_PROFILE_ID)).to.eq(userAddress);
      expect(await manager.getWalletBySoulBoundTokenId(THIRD_PROFILE_ID)).to.eq(userTwoAddress);
      
      expect(
        await createHubReturningHubId({
          sender: user,
          hub: {
            soulBoundTokenId: SECOND_PROFILE_ID,
            name: "bitsoul",
            description: "Hub for bitsoul",
            imageURI: "image",
          },
        })
      ).to.eq(FIRST_HUB_ID);

      expect(
        await createProjectReturningProjectId({
          project: {
            soulBoundTokenId: SECOND_PROFILE_ID,
            hubId: FIRST_HUB_ID,
            name: "bitsoul",
            description: "Hub for bitsoul",
            image: "image",
            metadataURI: "metadataURI",
            descriptor: metadataDescriptor.address,
            defaultRoyaltyPoints: 0,
            feeShareType: 0, //Level two
            permitByHubOwner: false
          },
        })
    ).to.eq(FIRST_PROJECT_ID);
    
    let projectInfo = await manager.connect(user).getProjectInfo(FIRST_PROJECT_ID);
    expect(projectInfo.soulBoundTokenId).to.eq(SECOND_PROFILE_ID);
    expect(projectInfo.hubId).to.eq(FIRST_HUB_ID);
    expect(projectInfo.name).to.eq("bitsoul");
    expect(projectInfo.description).to.eq("Hub for bitsoul");
    expect(projectInfo.image).to.eq("image");
    expect(projectInfo.metadataURI).to.eq("metadataURI");
    expect(projectInfo.descriptor.toUpperCase()).to.eq(metadataDescriptor.address.toUpperCase());

    derivativeNFT = DerivativeNFTV1__factory.connect(
      await manager.getDerivativeNFT(FIRST_PROJECT_ID),
      user
    );

    const publishModuleinitData = abiCoder.encode(
      ['address', 'uint256'],
      [template.address, DEFAULT_TEMPLATE_NUMBER],
    );

    const collectModuleInitData = abiCoder.encode(
        ['uint256', 'uint16', 'uint256', 'uint256'],
       
        [SECOND_PROFILE_ID, GENESIS_FEE_BPS, DEFAULT_COLLECT_PRICE, Default_royaltyBasisPoints]
    );

    await expect(
        manager.connect(user).prePublish({
          soulBoundTokenId: SECOND_PROFILE_ID,
          hubId: FIRST_HUB_ID,
          projectId: FIRST_PROJECT_ID,
          amount: 11,
          salePrice: DEFAULT_COLLECT_PRICE,
          royaltyBasisPoints: Default_royaltyBasisPoints,              
          name: "Dollar",
          description: "Hand draw",
          canCollect: true,
          materialURIs: [],
          fromTokenIds: [],
          collectModule: feeCollectModule.address,
          collectModuleInitData: collectModuleInitData,
          publishModule: publishModule.address,
          publishModuleInitData: publishModuleinitData,
      })
      ).to.not.be.reverted;

      const dNFTTokenId = await manager.connect(user).callStatic.publish(FIRST_PUBLISH_ID);
      await expect(
        manager.connect(user).publish(FIRST_PUBLISH_ID)
      ).to.not.be.reverted;

      expect(dNFTTokenId).to.eq(FIRST_DNFT_TOKEN_ID);  

      expect(
        await derivativeNFT.ownerOf(FIRST_DNFT_TOKEN_ID)
      ).to.eq(userAddress);


      await derivativeNFT.setApprovalForAll(marketPlaceContract.address, true);

  });

  context('MarketPlace', function () {
    context('Negatives', function () {
      it('User should fail to add market with non operator', async function () {

        await expect(
          marketPlaceContract.connect(user).addMarket(
            derivativeNFT.address,
             0,
             0,
             50,
          )
        ).to.be.revertedWith("Operator: caller does not have the Operator role");

      });

      it('User should fail to setBuyPrice with not owner of dNFT', async function () {
        await expect( 
          marketPlaceContract.connect(userTwo).setBuyPrice(
            {
              derivativeNFT: derivativeNFT.address, 
              tokenId: FIRST_DNFT_TOKEN_ID,
              onSellUnits: 100, //revert UnitsGTTotal
              startTime: 1673236726,
              salePrice: SALE_PRICE,
              min: 0,
              max: 1,
            })
        ).to.be.reverted;
      });

      it('User should fail to setBuyPrice with none exists dNFT tokenId', async function () {
        await expect( 
          marketPlaceContract.connect(user).setBuyPrice(
            {
              derivativeNFT: derivativeNFT.address, 
              tokenId: SECOND_DNFT_TOKEN_ID,
              onSellUnits: 100, //revert UnitsGTTotal
              startTime: 1673236726,
              salePrice: SALE_PRICE,
              min: 0,
              max: 1,
            })
        ).to.be.reverted;
      });


/*

      it('User should fail to publishSale when on sell units is gt total', async function () {

        await expect(
          marketPlaceContract.connect(user).publishSale({
            soulBoundTokenId: SECOND_PROFILE_ID,
            projectId: FIRST_PROJECT_ID,
            tokenId: FIRST_DNFT_TOKEN_ID,
            onSellUnits: 100, //revert UnitsGTTotal
            startTime: 1673236726,
            salePrice: 100,
            priceType: 0,
            min: 0,
            max: 1,
          }
          )
        ).to.be.reverted;

      });

      it('User should fail to publishSale when max is gt total', async function () {

        await expect(
          marketPlaceContract.connect(user).publishSale({
            soulBoundTokenId: SECOND_PROFILE_ID,
            projectId: FIRST_PROJECT_ID,
            tokenId: FIRST_DNFT_TOKEN_ID,
            onSellUnits: 10, 
            startTime: 1673236726,
            salePrice: 100,
            priceType: 0,
            min: 0,
            max: 12, //revert MAXGTTotal
          }
          )
        ).to.be.reverted;

      });

      it('User should fail to publishSale when min is gt max', async function () {

        await expect(
          marketPlaceContract.connect(user).publishSale({
            soulBoundTokenId: SECOND_PROFILE_ID,
            projectId: FIRST_PROJECT_ID,
            tokenId: FIRST_DNFT_TOKEN_ID,
            onSellUnits: 10, 
            startTime: 1673236726,
            salePrice: 100,
            priceType: 0,
            min: 3,//revert MinGTMax
            max: 2, 
          }
          )
        ).to.be.reverted;

      });
      
      it('User should fail to buy units with non exists sale id', async function () {

        await expect(
          marketPlaceContract.connect(governance).addMarket(
            derivativeNFT.address,
             0,
             0,
             50,
          )
        ).to.not.be.reverted;
        
        //approve market contract
        await derivativeNFT.connect(user)['approve(address,uint256)'](marketPlaceContract.address, FIRST_DNFT_TOKEN_ID);

        await marketPlaceContract.connect(user).publishSale({
            soulBoundTokenId: SECOND_PROFILE_ID,
            projectId: FIRST_PROJECT_ID,
            tokenId: FIRST_DNFT_TOKEN_ID,
            onSellUnits: 1, 
            startTime: 1673236726,
            salePrice: 100,
            priceType: 0,
            min: 0,
            max: 10, 
          }
          );

        await expect(
          marketPlaceContract.connect(userTwo).buyUnits(
            THIRD_PROFILE_ID,
            22, //revert
            1,
          )
        ).to.be.reverted;

      });

      it('User should fail to buy units with exceed units', async function () {

        await expect(
          marketPlaceContract.connect(governance).addMarket(
            derivativeNFT.address,
             0,
             0,
             50,
          )
        ).to.not.be.reverted;
        
        //approve market contract
        await derivativeNFT.connect(user)['approve(address,uint256)'](marketPlaceContract.address, FIRST_DNFT_TOKEN_ID);

        await marketPlaceContract.connect(user).publishSale({
            soulBoundTokenId: SECOND_PROFILE_ID,
            projectId: FIRST_PROJECT_ID,
            tokenId: FIRST_DNFT_TOKEN_ID,
            onSellUnits: 1, 
            startTime: 1673236726,
            salePrice: 100,
            priceType: 0,
            min: 0,
            max: 10, 
          }
          );

         
        await expect(
          marketPlaceContract.connect(userTwo).buyUnits(
            THIRD_PROFILE_ID,
            SALE_ID, 
            400,//revert
          )
        ).to.be.reverted;

      });
*/
    });


    context('Success', function () {
      /*
        it('UserTwo should buy units', async function () {
          await expect(
            marketPlaceContract.connect(governance).addMarket(
              derivativeNFT.address,
               0,
               0,
               50,
            )
          ).to.not.be.reverted;
          
          //approve market contract
          await derivativeNFT.connect(user)['approve(address,uint256)'](marketPlaceContract.address, FIRST_DNFT_TOKEN_ID);
  
          await marketPlaceContract.connect(user).publishSale({
              soulBoundTokenId: SECOND_PROFILE_ID,
              projectId: FIRST_PROJECT_ID,
              tokenId: FIRST_DNFT_TOKEN_ID,
              onSellUnits: 10, 
              startTime: 1673236726,
              salePrice: 100,
              priceType: 0,
              min: 0,
              max: 10, 
            }
            );
            
          expect(
              await derivativeNFT.ownerOf(FIRST_DNFT_TOKEN_ID)
            ).to.eq(userAddress);
  
          expect(
              await derivativeNFT.ownerOf(SECOND_DNFT_TOKEN_ID)
            ).to.eq(marketPlaceContract.address);
        

          await marketPlaceContract.connect(userTwo).buyUnits(
              THIRD_PROFILE_ID,
              SALE_ID, 
              1,
            );

          expect(
            await derivativeNFT.ownerOf(THIRD_DNFT_TOKEN_ID)
          ).to.eq(userTwoAddress);

          let saleData = await marketPlaceContract.getSaleData(SALE_ID);
          console.log('\n\t---saleData.salePrice---:', saleData.salePrice.toNumber());
          console.log('\t---saleData.onSellUnits---:', saleData.onSellUnits.toNumber());
          console.log('\t---saleData.seledUnits---:', saleData.seledUnits.toNumber());

          
        });
       */
    });

  });

});

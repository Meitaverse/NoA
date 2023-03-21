import '@nomiclabs/hardhat-ethers';
import { expect } from 'chai';
import { BigNumber } from 'ethers';
import { DataTypes } from '../../../typechain/contracts/interfaces/IManager';

import { MAX_UINT256, ZERO_ADDRESS } from '../../helpers/constants';
import { ERRORS } from '../../helpers/errors';
import { 
    getSetDispatcherWithSigParts
} from '../../helpers/utils';

import {
  SECOND_PROFILE_ID,
  FIRST_HUB_ID,
  FIRST_PROJECT_ID,
  manager,
  makeSuiteCleanRoom,
  MOCK_PROFILE_URI,
  userAddress,
  user,
  userTwo,
  userTwoAddress,
  sbtContract,
  metadataDescriptor,
  abiCoder,
  template,
  DEFAULT_TEMPLATE_NUMBER,
  DEFAULT_COLLECT_PRICE,
  feeCollectModule,
  publishModule,
  FIRST_PUBLISH_ID,
  THIRD_PROFILE_ID,
  testWallet,
  bankTreasuryContract,
  admin,
  governance
} from '../../__setup.spec';

const Default_royaltyBasisPoints = 50; //


makeSuiteCleanRoom('Dispatcher Functionality', function () {
  context('Generic', function () {
    beforeEach(async function () {

      await expect(
        manager.createProfile({
          wallet: userAddress,
          nickName: 'Alice',
          imageURI: MOCK_PROFILE_URI,
        })
      ).to.not.be.reverted;

      await expect(
        manager.createProfile({
          wallet: userTwoAddress,
          nickName: 'Bob',
          imageURI: MOCK_PROFILE_URI,
        })
      ).to.not.be.reverted;

      //mint some Value to user
      await bankTreasuryContract.connect(user).buySBT(SECOND_PROFILE_ID, {value: 10000});
      //mint some  Value to userTwo
      await bankTreasuryContract.connect(userTwo).buySBT(THIRD_PROFILE_ID, {value: 10000});
      
    });

    context('Negatives', function () {
      it('UserTwo should fail to set dispatcher on profile owned by user 1', async function () {
        await expect(
          manager.connect(userTwo).setDispatcher(SECOND_PROFILE_ID, userTwoAddress)
        ).to.be.revertedWith(ERRORS.NOT_PROFILE_OWNER);
      });


      it('UserTwo should fail to publish on profile owned by user 1 without being a dispatcher', async function () {
        
        await expect(
          manager.connect(userTwo).createHub({
            soulBoundTokenId: SECOND_PROFILE_ID,
            name: "bitsoul",
            description: "Hub for bitsoul",
            imageURI: "https://ipfs.io/ipfs/QmVnu7JQVoDRqSgHBzraYp7Hy78HwJtLFi6nUFCowTGdzp/11.png",
          })
        ).to.be.revertedWith(ERRORS.NOT_PROFILE_OWNER_OR_DISPATCHER);

      });

  
    });

    context('Scenarios', function () {
      it('User should set user two as a dispatcher on their profile, user two should createHub, createProject, prePublish, publish and airdrop', async function () {
        
        await manager.connect(user).setDispatcher(SECOND_PROFILE_ID, userTwoAddress);
      
        await 
          manager.connect(userTwo).createHub({
            soulBoundTokenId: SECOND_PROFILE_ID,
            name: "bitsoul",
            description: "Hub for bitsoul",
            imageURI: "https://ipfs.io/ipfs/QmVnu7JQVoDRqSgHBzraYp7Hy78HwJtLFi6nUFCowTGdzp/11.png",
          });
      

        await 
          manager.connect(userTwo).createProject(
            {
              soulBoundTokenId: SECOND_PROFILE_ID,
              hubId: FIRST_HUB_ID,
              name: "bitsoul",
              description: "Hub for bitsoul",
              image: "image",
              metadataURI: "metadataURI",
              descriptor: metadataDescriptor.address,
              defaultRoyaltyPoints: 0,
              permitByHubOwner: false
            },
          );

        const publishModuleinitData = abiCoder.encode(
          ['address', 'uint256'],
          [template.address, DEFAULT_TEMPLATE_NUMBER],
        );
        
        const collectModuleInitData = abiCoder.encode(
            ['uint256', 'uint16', 'uint16'],
            [DEFAULT_COLLECT_PRICE, Default_royaltyBasisPoints, 0]
        );


        await 
          manager.connect(userTwo).prePublish({
            soulBoundTokenId: SECOND_PROFILE_ID,
            hubId: FIRST_HUB_ID,
            projectId: FIRST_PROJECT_ID,
            currency: sbtContract.address,
            amount: 1,
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
          });

        let info = await  manager.connect(userTwo).getPublication(FIRST_PUBLISH_ID);
        console.log("getPublication,  projectId: ", info.projectId);
        console.log("getPublication,  amount: ", info.amount);

        await expect(
          manager.connect(userTwo).publish(FIRST_PUBLISH_ID)
        ).to.not.be.reverted;

        // await expect(
        //   manager.connect(userTwo).airdrop({
        //     publishId: FIRST_PROJECT_ID,
        //     ownershipSoulBoundTokenId: SECOND_PROFILE_ID,
        //     toSoulBoundTokenIds: [THIRD_PROFILE_ID],
        //     tokenId: FIRST_DNFT_TOKEN_ID,
        //     values: [1],
        //   })
        // ).to.not.be.reverted;

        // console.log('\t--- balance of collector: ', (await sbtContract["balanceOf(uint256)"](THIRD_PROFILE_ID)).toNumber());

        // let derivativeNFT: DerivativeNFT;
        // derivativeNFT = DerivativeNFT__factory.connect(
        //   await manager.connect(user).getDerivativeNFT(FIRST_PROJECT_ID),
        //   user
        // );

        // expect(
        //   await derivativeNFT.ownerOf(FIRST_DNFT_TOKEN_ID)
        // ).to.eq(userAddress);

        // let value_DNFT1 = await derivativeNFT.connect(userTwo)['balanceOf(uint256)'](FIRST_DNFT_TOKEN_ID)
        // console.log('value_DNFT1: ', value_DNFT1);


        // await manager.connect(userTwo).collect({
        //   publishId: FIRST_PUBLISH_ID,
        //   collectorSoulBoundTokenId: THIRD_PROFILE_ID,
        //   collectUnits: 1,
        //   data: [],
        // });
  
      });
    });
    
  });


  context('Meta-tx', function () {
    beforeEach(async function () {

      await expect(
        manager.connect(testWallet).createProfile({
          wallet: testWallet.address,
          nickName: 'Alice',
          imageURI: MOCK_PROFILE_URI,
        })
      ).to.not.be.reverted;


      //mint 10000 Value to testWallet
      await bankTreasuryContract.connect(testWallet).buySBT(SECOND_PROFILE_ID, {value: 10000});
      
    });

    context('Negatives', function () {
      it('TestWallet should fail to set dispatcher with sig with signature deadline mismatch', async function () {
        const nonce = (await manager.sigNonces(testWallet.address)).toNumber();
        const { v, r, s } = await getSetDispatcherWithSigParts(
          SECOND_PROFILE_ID,
          userTwoAddress,
          nonce,
          '0'
        );

        await expect(
          manager.connect(governance).setDispatcherWithSig({
            soulBoundTokenId: SECOND_PROFILE_ID,
            dispatcher: userTwoAddress,
            sig: {
              v,
              r,
              s,
              deadline: MAX_UINT256,
            },
          })
        ).to.be.revertedWith(ERRORS.SIGNATURE_INVALID);
      });

      it('TestWallet should fail to set dispatcher with sig with invalid deadline', async function () {
        const nonce = (await manager.sigNonces(testWallet.address)).toNumber();
        const { v, r, s } = await getSetDispatcherWithSigParts(
          SECOND_PROFILE_ID,
          userTwoAddress,
          nonce,
          '0'
        );

        await expect(
          manager.connect(governance).setDispatcherWithSig({
            soulBoundTokenId: SECOND_PROFILE_ID,
            dispatcher: userTwoAddress,
            sig: {
              v,
              r,
              s,
              deadline: '0',
            },
          })
        ).to.be.revertedWith(ERRORS.SIGNATURE_EXPIRED);
      });


      it('TestWallet should fail to set dispatcher with sig with invalid nonce', async function () {
        const nonce = (await manager.sigNonces(testWallet.address)).toNumber();
        const { v, r, s } = await getSetDispatcherWithSigParts(
          SECOND_PROFILE_ID,
          userTwoAddress,
          nonce + 1,
          MAX_UINT256
        );

        await expect(
          manager.connect(governance).setDispatcherWithSig({
            soulBoundTokenId: SECOND_PROFILE_ID,
            dispatcher: userTwoAddress,
            sig: {
              v,
              r,
              s,
              deadline: MAX_UINT256,
            },
          })
        ).to.be.revertedWith(ERRORS.SIGNATURE_INVALID);
      });

      
    });

    context('Scenarios', function () {
      it('TestWallet should set user two as dispatcher for their profile, user two should createHub, createProject, prePublish and publish', async function () {
        const nonce = (await manager.sigNonces(testWallet.address)).toNumber();
        const { v, r, s } = await getSetDispatcherWithSigParts(
          SECOND_PROFILE_ID,
          userTwoAddress,
          nonce,
          MAX_UINT256
        );

        await expect(
          manager.connect(governance).setDispatcherWithSig({
            soulBoundTokenId: SECOND_PROFILE_ID,
            dispatcher: userTwoAddress,
            sig: {
              v,
              r,
              s,
              deadline: MAX_UINT256,
            },
          })
        ).to.not.be.reverted;
        
        await expect(
          manager.connect(userTwo).createHub({
            soulBoundTokenId: SECOND_PROFILE_ID,
            name: "bitsoul",
            description: "Hub for bitsoul",
            imageURI: "https://ipfs.io/ipfs/QmVnu7JQVoDRqSgHBzraYp7Hy78HwJtLFi6nUFCowTGdzp/11.png",
          })
        ).to.not.be.reverted;

        await expect(
          manager.connect(userTwo).createProject(
            {
              soulBoundTokenId: SECOND_PROFILE_ID,
              hubId: FIRST_HUB_ID,
              name: "bitsoul",
              description: "Hub for bitsoul",
              image: "image",
              metadataURI: "metadataURI",
              descriptor: metadataDescriptor.address,
              defaultRoyaltyPoints: 0,
              permitByHubOwner: false
            },
          )
        ).to.not.be.reverted;


        const publishModuleinitData = abiCoder.encode(
          ['address', 'uint256'],
          [template.address, DEFAULT_TEMPLATE_NUMBER],
        );
        
        const collectModuleInitData = abiCoder.encode(
          ['uint256', 'uint16', 'uint16'],
          [DEFAULT_COLLECT_PRICE, Default_royaltyBasisPoints, 0]
      );

        await expect(
          manager.connect(userTwo).prePublish({
            soulBoundTokenId: SECOND_PROFILE_ID,
            hubId: FIRST_HUB_ID,
            projectId: FIRST_PROJECT_ID,
            currency: sbtContract.address,
            amount: 1,
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

        await expect(
          manager.connect(userTwo).publish(FIRST_PUBLISH_ID)
        ).to.not.be.reverted;


      });
    });
    
  });
  
  
});

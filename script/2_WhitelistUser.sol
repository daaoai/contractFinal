// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {console2} from "forge-std/console2.sol";

import {Script} from "forge-std/Script.sol";
import {DaaoToken} from "../src/DaaoToken.sol"; // Adjust the path based on your project structure
import {Daao} from "../src/Daao.sol"; // Adjust the path based on your project structure

contract WhitelistUser is Script {
    function run() public {
        // Load private key
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        address DAO_CONTRACT_ADDRESS = 0xEc7b0FD288E87eBC1C301E360092c645567e79B9;

        Daao daosWorldV1 = Daao(DAO_CONTRACT_ADDRESS);

        // Setup: Add user to whitelist
        address[] memory users = new address[](123);
        users[0] = 0x6F5961A01a4E6c5C2f77399E3758b124219d7A78; // Platinum
        users[1] = 0x5A9e792143bf2708b4765C144451dCa54f559a19; // Gold
        users[2] = 0x144fC87fF9101CD09fAb6Efc8aA5F3bF63ad6c0F; // Gold
        users[3] = 0x764a35367283220659C89B30E3ABF880cC1CcCdc; // Gold
        users[4] = 0xACe481203531ACa5293994A4dF59B31a43501e69; // Gold
        users[5] = 0xf289Bbc3207322bb5531B041540Ad2119c01ADc2; // Gold
        users[6] = 0xC0225f37F8645d1153b566077F49b109D3156d0B; // Gold
        users[7] = 0x3B16c2b430173113EE14850566B9431D4Eb0f93D; // Gold
        users[8] = 0xd7f4a04c736cC1C5857231417E6cB8Da9cAdbEC7; // Gold
        users[9] = 0x2C63B830aDd926fdB888ADdEE6a29C6b2B26450b; // Gold
        users[10] = 0x47D65fFc85f4812DD5eC75FfF2EcCB8E4623dea7; // Gold
        users[11] = 0xbeb15caee71001d82F430E4deda80e16dDf438Db; // Gold
        users[12] = 0x25444E5A985Cdb09d2d2A45c8DC29480C7fa09F8; // Gold
        users[13] = 0x154D73802a6B3324c017481AC818050afE4a0b0A; // Gold
        users[14] = 0x580744a9D40Cd99A99F3bE0398476F29C1B54583; // Gold
        users[15] = 0x7B4d92Ba4e14bAe7a5e2C92117eD86E40c0DFaaD; // Gold
        users[16] = 0xE184C2E2796E51938553FCdc6efa87916b29d206; // Gold
        users[17] = 0xAF806d39019eB02B8d767b63773147e058B5Dc01; // Gold
        users[18] = 0xCc263863362fe3d31784cb467111dE8eD9C95FB1; // Gold
        users[19] = 0xaD9242795Ad7FE630addA2b29ed39A4F4c4Fd84B; // Gold
        users[20] = 0xdd85816551d84c3f5ABD5C18F2634A853D734a7e; // Gold
        users[21] = 0x3c3e6750f5C942AB5044b0B630EA44341b5F3036; // Gold
        users[22] = 0x1c511874BA7a9892D8Fe4369f51D55cA4EA9837C; // Gold
        users[23] = 0xfE4d940101887C0F7087bd8F52beCCAdbF898d49; // Gold
        users[24] = 0x6439f5D99c85A66a3dE6D2ceE73CcC4E2B011aEe; // Gold
        users[25] = 0x5D4d3FaE4d0282FD8A558b5f42Ba700974cBfd1A; // Gold
        users[26] = 0x1E8eE48D0621289297693fC98914DA2EfDcE1477; // Gold
        users[27] = 0xDD5730a33719083470e641cF0e4154Dd04D5738d; // Gold
        users[28] = 0x81e3C9dED64CAF37ee5fFd643637E1a97CD64F5f; // Gold
        users[29] = 0xbF219572481F58569249319560a45d9cbf4C82f9; // Gold
        users[30] = 0x9d8fCFE97Ff0D25545C43115e8F39927Dc7936C6; // Gold
        users[31] = 0x2fE3772CA654FE3aaafd34e73d3B04DE9a882a09; // Gold
        users[32] = 0x3c9007960Bb9d1ABc9B6A4C2193f920e70518d06; // Gold
        users[33] = 0x0C0586a35FA30FF528b2d7Ce5969B845eB8c3A8c; // Gold
        users[34] = 0x10EbFA39E053407d8254317CA5937c3575bD3BB8; // Gold
        users[35] = 0x7DC7e58235acb6b24C48afD5Dba323d892D579B4; // Gold
        users[36] = 0x2Ef2Ec363A9766d6914ab179583B70C78Dd264e0; // Gold
        users[37] = 0xAF53E59f70443f333dD3CD7764851638DD120b2E; // Gold
        users[38] = 0xc9287F06eD8a4fDEeE9C768333F505bac5AbA916; // Gold
        users[39] = 0xFf7566Ac885A5f4d2bbDD44378C6C288a879b893; // Gold
        users[40] = 0xaA5A722BE2A79B661e30cac3ad1c3C1BB773EA98; // Gold
        users[41] = 0x5D642F47f920Ea36C9F805411165a2ca6b787419; // Gold
        users[42] = 0xBAe1C79c72DC0C6836727E0808aEbBAAaC9C6833; // Gold
        users[43] = 0xf936104FcCb3e7A45eD589F6f08CD22FC99683f8; // Gold
        users[44] = 0x9CE7e613477b775D956e378fCa79eE22c2e8d17B; // Gold
        users[45] = 0xDe13AE64205f3443eC3833B0612D0e34BF1c6F33; // Silver
        users[46] = 0x6c9e52a76048E8DA6d97FC016201151854465B5E; // Silver
        users[47] = 0x0fA837970fC4c4a3fdb49D40B3566b3038575967; // Silver
        users[48] = 0xB4B1b6928337974D98843f45aBbb8B38DFB1B72C; // Silver
        users[49] = 0x3b6239114d84A25D4CE995B344d399DD0a0ed4f6; // Silver
        users[50] = 0x7ed98e8C43df9EbD1C5E679033Ef388680CEd37E; // Silver
        users[51] = 0x74c96A0Bf84Cfa9f9B7D16A3F128c85755C02344; // Silver
        users[52] = 0x402A61E972707213E83448feA274f3540178da3D; // Silver
        users[53] = 0xF317010A611dC9CCbf0C38211768fEF37a6D57ec; // Silver
        users[54] = 0x50B4107012168431615d21DA2C22FFAA08720521; // Silver
        users[55] = 0x11C486e7BF25b8548D8F181420316F01FD43F4a2; // Silver
        users[56] = 0x8aE497630AD9DD3e7F5daFa2Bb4F3fF19F64d379; // Silver
        users[57] = 0x3E54705e1874D3eF30085887854816B98b4EA77c; // Silver
        users[58] = 0x2A06017cAd6d266C593c67803298d984059bBB12; // Silver
        users[59] = 0x27b0B4033b6BdCdf12c8d4B86969E3AEe53Ca107; // Silver
        users[60] = 0xDbEa54A5360373b0E2aD1c403e3449A71f0D4b79; // Silver
        users[61] = 0x9C3F9ACf579405750D97ed7CF9F7e903CE4C63E4; // Silver
        users[62] = 0x7CB0422b9D6470f476aC49065BaEc6009eAB7171; // Silver
        users[63] = 0xEa5bf2AD6af8168DE10546B3e4D5679bb22305C8; // Silver
        users[64] = 0xDdAFb7c8EDB48d394bBC38bf05F5378732B6592c; // Silver
        users[65] = 0xe7dD6A45492111B40a8fE47c016afF911A018293; // Silver
        users[66] = 0x81C3908eFd51F52728c13c40ecCb67DE2Fd6a446; // Silver
        users[67] = 0x4145d65C1FD099047b7eE25e6C4Fa51C1bC33697; // Silver
        users[68] = 0x10EbFA39E053407d8254317CA5937c3575bD3BB8; // Silver
        users[69] = 0xA3bAAef6D5217a12eF59e5a5B7338F58a58B7447; // Silver
        users[70] = 0xdB93bE61B72544bbA87632f8ed5bF471e6970E74; // Silver
        users[71] = 0xd3E3002B8B972aBA524EBB1F68a9050e3bBeeDBF; // Silver
        users[72] = 0xc2804e82BE8e6b6227C5AF52AE2E93e6756b0e72; // Silver
        users[73] = 0x3c121f91d5faeC12c217257A7E2B91E347F667e1; // Silver
        users[74] = 0x7967CD835D4DDeed329B118AA66363a9F3B1004a; // Silver
        users[75] = 0x87d0638e703a5a3C4D306b72A2381226029DC6a9; // Silver
        users[76] = 0x7C578AFA61700A190B849c0F0b2B6eCB73af0b9F; // Silver
        users[77] = 0xd2344312E4ce35ab20C42B374A436f24bb9f9E1b; // Silver
        users[78] = 0xbFf52760005102225903602aDD098D18469aa4cF; // Silver
        users[79] = 0xc2f6BFAdFc3677754111d06f18A7AfBa77279F99; // Silver
        users[80] = 0xde9B757C8BB7D5688737e29355B3fD2d27AC6C88; // Silver
        users[81] = 0x2E3629eA3de95F6C264192b999f219Ceb77ea3AA; // Silver
        users[82] = 0xb95230d99B87119F59407BcfFfDdD06F42ed86c6; // Silver
        users[83] = 0xbD7F1E341d6E35e70cE6f215A21a9D1a49F7449D; // Silver
        users[84] = 0xe20696329135CC09D0EA891Cc882afdcE1d0d01B; // Silver
        users[85] = 0x8af44DdBC4Cd9C54943922aBF861223FDF87b4dD; // Silver
        users[86] = 0x8782E67e9A997E81e0aDEa06bfec340C8D06EaB4; // Silver
        users[87] = 0x4056eC665A86efD44A4632B127FA52d90e193565; // Silver
        users[88] = 0x67Adf88c937E3d35817aee63e105c1981B90e58d; // Silver
        users[89] = 0x63d9060bBb6786d687402d3e8Be3f44fC6C979D5; // Silver
        users[90] = 0xEA77c8987A0878637C6730CBE4D34eA0F0EC0188; // Silver
        users[91] = 0xF5F1135d3E01455FE23851CE54AAda860de39F67; // Silver
        users[92] = 0x0e2aBBfFB9Ad35699af33950Bd0F8f2D44c8b376; // Silver
        users[93] = 0xe336aB85505aB4F1f6844A5Be6C92b11fa394C3C; // Silver
        users[94] = 0xDeF0418beAe2db327aF1d43A37faD3E62a54f455; // Silver
        users[95] = 0xaef17636Fa3b464633D9242Eb85c633363A3bd2F; // Silver
        users[96] = 0x99649d38DdBe08F315E76839DC49Eb754F8D0ff3; // Silver
        users[97] = 0xbb1A104dbf7931746D26089C49928977DEbb51b3; // Gold
        users[98] = 0x724B2266C3E107E3f6b9399FCE2aabF2Df8c58BF; // Gold
        users[99] = 0xE180464B6dC64b6e8F3D6aCFebDc9ca379AaFcE8; // Gold
        users[100] = 0x205bB17D3213762bEfB0a14408618A9ddB660FAB; // Gold
        users[101] = 0x849aeFB8ea02C6c0F059301D1602B2C43E2Fd298; // Gold
        users[102] = 0x2F21665Bfd0A8245699597fadCb9fe4346d3DFe9; // Gold
        users[103] = 0x9B3Bf9AAbFB9401a5472A7d2581E01c1C5928448; // Gold
        users[104] = 0x7DC7e58235acb6b24C48afD5Dba323d892D579B4; // Gold
        users[105] = 0xdC661e35ee63132FCC1BA5a00B94018A4dfC08B5; // Gold
        users[106] = 0xdcC788e6D0d2E373e4d25295Ff7682A86e167525; // Gold
        users[107] = 0x5D642F47f920Ea36C9F805411165a2ca6b787419; // Gold
        users[108] = 0xbBef93E67909E95BE117Fa8Db16a84780A12f764; // Gold
        users[109] = 0xFa4c474e87c3d3fD8408ffb50Af76ad642656D24; // Gold
        users[110] = 0xFc6463DbAbb15aa8B6F72b77D9D08E19E83c1062; // Gold
        users[111] = 0x2145346A3F9f716949C68CF739405d8F3e292d24; // Gold
        users[112] = 0xBAe1C79c72DC0C6836727E0808aEbBAAaC9C6833; // Gold
        users[113] = 0xDeE885846ffd3f89aDFb7445A30EffF2E3512d25; // Gold
        users[114] = 0x260107Ef8a7A2971c3808c418E6db7c4bD57C29f; // Gold
        users[115] = 0x270e5EBE770C6AED37dD139660839135984aCe63; // Gold
        users[116] = 0xE3af29059679C9FCDfFD9DbDB07562C078b449bd; // Gold
        users[117] = 0x022498e8B5C02CF9F91312B7917fe916E0AEC389; // Gold
        users[118] = 0x2C27C8497De51dBeF7E7A2C01866cc73DD82359e; // Gold
        users[119] = 0xAf1ed8defd866C6C298FDBfa2F5EF5f055d9DB85; // Gold
        users[120] = 0xE3a5059D97ddCB9670ea697410F6B30661cd46eA; // Gold
        users[121] = 0xC9A547A87F4E10Df92C260c50F0642618688f466; // Gold
        users[122] = 0x4eC705687453662b4b7795C9A63f2bc109F552B7; // Gold

        Daao.WhitelistTier[] memory tiers = new Daao.WhitelistTier[](123);
        tiers[0] = Daao.WhitelistTier.Platinum; // First user is Platinum

        // Gold tier users (1-44, 97-122)
        for (uint256 i = 1; i <= 44; i++) {
            tiers[i] = Daao.WhitelistTier.Gold;
        }
        // Silver tier users (45-96)
        for (uint256 i = 45; i <= 96; i++) {
            tiers[i] = Daao.WhitelistTier.Silver;
        }

        // GOLD tier users
        for (uint256 i = 97; i <= 122; i++) {
            tiers[i] = Daao.WhitelistTier.Gold;
        }

        // First send some MODE tokens to the contract
        daosWorldV1.addOrUpdateWhitelist(users, tiers);

        // update tier limit if required
        daosWorldV1.updateTierLimit(Daao.WhitelistTier.Silver, 8000 ether);
        daosWorldV1.updateTierLimit(Daao.WhitelistTier.Gold, 12000 ether);
        daosWorldV1.updateTierLimit(Daao.WhitelistTier.Platinum, 150000 ether);

        vm.stopBroadcast();
    }
}

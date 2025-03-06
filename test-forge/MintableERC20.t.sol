// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Test.sol";

import "contracts/token/MintableERC20.sol";
import "contracts/_testContracts/TestERC20Compliance.sol";

// forge test --match-path test-forge/MintableERC20.t.sol
contract MintableERC20Test is Test {
    MintableERC20 token;
    TestERC20Compliance compliance;

    address admin = address(1);
    address mintBurner = address(2);
    address user = address(3);

    function setUp() public {
        token = new MintableERC20("Test Token", "TT", 18, admin, mintBurner);
        compliance = new TestERC20Compliance(address(token));
    }

    // forge test -vvvv --match-test test_mintAndBurn
    function test_mintAndBurn() public {
        vm.prank(mintBurner);
        token.mint(user, 1e19);
        assertEq(token.balanceOf(user), 1e19);

        vm.prank(mintBurner);
        token.burn(user, 5e18);
        assertEq(token.balanceOf(user), 5e18);
    }

    // forge test -vvvv --match-test test_Revert_mintNotAccess
    function test_mintNotAccess() public {
        vm.startPrank(admin);
        vm.expectRevert(
            abi.encodePacked(
                "AccessControl: account ",
                Strings.toHexString(admin),
                " is missing role ",
                Strings.toHexString(uint256(token.minterRole()), 32)
            )
        );
        token.mint(user, 1e19);
        vm.stopPrank();
    }

    // forge test -vvvv --match-test test_blackList
    function test_blackList() public {
        vm.prank(admin);
        token.addBlackList(user);
        assertEq(token.hasRole(token.DEFAULT_ADMIN_ROLE(), admin), true);

        vm.prank(mintBurner);
        vm.expectRevert(abi.encodeWithSignature("AccountIsBlacklisted(address)", user));
        token.mint(user, 1e19);
    }

    // forge test -vvvv --match-test test_compliance
    function test_compliance() public {
        vm.prank(admin);
        token.setCompliance(address(compliance));
        assertEq(token.compliance(), address(compliance));

        vm.prank(mintBurner);
        token.mint(user, 1e21);
        vm.prank(mintBurner);
        token.mint(user, 1e21);
        assertEq(token.balanceOf(user), 2e21);

        bool isCompliant = compliance.isCompliant(user, admin, 1e21 + 1e18);
        assertEq(isCompliant, false);
        vm.prank(user);
        vm.expectRevert(abi.encodeWithSignature("NotCompliance()"));
        token.transfer(admin, 1e21 + 1e18);
    }
}

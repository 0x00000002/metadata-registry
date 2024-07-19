// SPDX-License-Identifier: MIT

pragma solidity 0.8.26;

import "@openzeppelin/contracts/access/manager/AccessManager.sol";

import "../src/examples/NFT.sol";
import "../src/MetadataRegistry.sol";
import "../src/AttributesRegister.sol";
import "../src/utils/AccessManagedRoles.sol";

import "forge-std/Test.sol";
import "forge-std/console.sol";

bytes32 constant label = keccak256("label");
bytes32 constant metatata = keccak256("metadata");

bytes32 constant DEFAULT_ADMIN_ROLE = 0x00;

/**
 * @dev Tests for the ASM The Next Legend - Character contract
 */
contract MRTest is Test {
    // Naming convention: contracts variables ends with _, e.g.: nft_ or am_,
    // and their addresses starts with `a`, e.g.: aNft or aManager

    AccessManager am_;
    SignersRegister sr_;

    address aSignersRegistry;
    address aManager;

    address user;
    address admin;
    address studio;
    address signer;

    uint256 signerPK;

    bool isTrue;
    bool isClosed;
    bool canCall;
    uint256 delay;

    /** ----------------------------------
     * ! Setup
     * ----------------------------------- */

    // The state of the contract gets reset before each
    // test is run, with the `setUp()` function being called
    // each time after deployment. Think of this like a JavaScript
    // `beforeEach` block
    function setUp() public {
        setupAddresses();
        setupAccessManager();
        setupSignersRegister();
    }

    function setupAddresses() public {
        admin = vm.addr(
            vm.parseUint(
                "0xe49dcc90004a6788dcf67b74878c755d61502d686f76f1714f3ed91629fd4d52"
            )
        );
        vm.label(admin, "ADMIN");

        user = makeAddr("user");
        studio = makeAddr("studio");

        (signer, signerPK) = makeAddrAndKey("signer");
    }

    // AcessManager contract is deployed on both Porcini and ROOT chains,
    // this setup recreates the roles of the real AccessManager contract
    function setupAccessManager() internal {
        am_ = new AccessManager(admin);
        aManager = address(am_);
    }

    function setupSignersRegister() internal {
        sr_ = new SignersRegister(aManager);
        aSignersRegistry = address(sr_);

        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = sr_.setSigner.selector;
        vm.prank(admin);
        am_.grantRole(FV_SR_MANAGER, studio, 0);
    }

    function test_setSigner_restricted() public {
        vm.prank(user);

        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessManaged.AccessManagedUnauthorized.selector,
                user
            )
        );
        sr_.setSigner(studio, signer, true);
    }

    function test_setSigner_happy_path() public {
        vm.skip(false);

        vm.prank(admin);
        sr_.setSigner(studio, signer, true);

        address res = sr_.getSigner(studio);
        assertEq(res, signer);
    }

    function test_smthg() public view {}
}

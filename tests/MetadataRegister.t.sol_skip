// SPDX-License-Identifier: MIT

pragma solidity 0.8.26;

import "@openzeppelin/contracts/access/manager/AccessManager.sol";

import "../src/examples/NFT.sol";
import "../src/MetadataRegistry.sol";
import "../src/AttributesRegister.sol";
import "../src/utils/AccessManagedRoles.sol";

import "forge-std/Test.sol";

import "forge-std/console.sol";

bytes32 constant DEFAULT_ADMIN_ROLE = 0x00;

uint256 constant SRC_TOKEN_1 = 2525;
uint256 constant SRC_TOKEN_2 = 3636;
uint256 constant SRC_TOKEN_3 = 5555;

uint256 constant NFT_ID_1 = 7824;
uint256 constant NFT_ID_2 = 123456;

uint256 constant AMOUNT_TO_MINT_SEQUENTIALLY = 10;

/**
 * @dev Tests for the ASM The Next Legend - Character contract
 */
contract NFT_Test is Test {
    address deployer = address(this);

    // Naming convention: contracts variables ends with _, e.g.: nft_ or am_,
    // and their addresses starts with `a`, e.g.: aNft or aManager
    NFT nft_;
    AccessManager am_;
    SignersRegister sr_;
    address aManager;
    address aRegister;
    address aNft;

    address user;
    address admin;
    address multisig;
    address ms_signer_1;
    address ms_signer_2;
    address studio_1_signer;
    address studio_2_signer;
    address aStudio_1;
    address aStudio_2;
    string studio_1_name = "Studio 1";
    string studio_2_name = "Studio 2";
    bytes32 studio_1 = bytes32(abi.encodePacked(studio_1_name));
    bytes32 studio_2 = bytes32(abi.encodePacked(studio_2_name));
    address sr_admin;

    uint256 signer1PK;
    uint256 signer2PK;

    bool isTrue;
    bool isClosed;
    bool canCall;
    uint256 delay;

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

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
        setupTestContracts();
    }

    function setupAddresses() public {
        admin = vm.addr(
            vm.parseUint(
                "0xe49dcc90004a6788dcf67b74878c755d61502d686f76f1714f3ed91629fd4d52"
            )
        );
        vm.label(admin, "ADMIN");

        user = makeAddr("user");
        multisig = makeAddr("multisig");

        ms_signer_1 = makeAddr("ms_signer_1");
        ms_signer_2 = makeAddr("ms_signer_2");

        sr_admin = makeAddr("sr_admin");

        aStudio_1 = makeAddr(studio_1_name);
        aStudio_2 = makeAddr(studio_2_name);

        (studio_1_signer, signer1PK) = makeAddrAndKey("studio_1_signer");
        (studio_2_signer, signer2PK) = makeAddrAndKey("studio_2_signer");
    }

    // AcessManager contract is deployed on both Porcini and ROOT chains,
    // this setup recreates the roles of the real AccessManager contract
    function setupAccessManager() internal {
        am_ = new AccessManager(admin);
        aManager = address(am_);

        // Multisig's permissions
        bytes4[] memory selectors = new bytes4[](16);
        selectors[0] = am_.labelRole.selector;
        selectors[1] = am_.grantRole.selector;
        selectors[2] = am_.revokeRole.selector;
        selectors[3] = am_.renounceRole.selector;
        selectors[4] = am_.setRoleAdmin.selector;
        selectors[5] = am_.setRoleGuardian.selector;
        selectors[6] = am_.setGrantDelay.selector;
        selectors[7] = am_.setTargetFunctionRole.selector;
        selectors[8] = am_.setTargetAdminDelay.selector;
        selectors[9] = am_.setTargetClosed.selector;
        selectors[10] = am_.schedule.selector;
        selectors[11] = am_.execute.selector;
        selectors[12] = am_.cancel.selector;
        selectors[13] = am_.consumeScheduledOp.selector;
        selectors[14] = am_.updateAuthority.selector;
        selectors[15] = am_.multicall.selector;

        vm.startPrank(admin);

        // Admin role is required for managing AccessManager itself with a Zero delay
        // Multisig can have not an ADMIN_ROLE, but then delay is required (AccessManager limitation)
        am_.grantRole(ADMIN_ROLE, multisig, 0);

        isClosed = am_.isTargetClosed(aManager);
        assertTrue(!isClosed, "AccessManager should be open");
        isClosed = am_.isTargetClosed(aRegister);
        assertTrue(!isClosed, "SignersRegister should be open");

        vm.stopPrank();

        (canCall, delay) = am_.canCall(
            multisig,
            aManager,
            am_.setTargetFunctionRole.selector
        );
        assertTrue(canCall, "Multisig can call setTargetFunctionRole()");
        assertEq(delay, 0, "Multisig has no delay for setTargetFunctionRole()");

        (canCall, delay) = am_.canCall(
            multisig,
            aManager,
            am_.grantRole.selector
        );

        assertTrue(canCall, "Multisig should be able to call grantRole()");
        assertEq(delay, 0, "Multisig should have no delay for grantRole()");

        vm.startPrank(multisig);

        am_.grantRole(FV_SR_MANAGER, sr_admin, 1 hours);
        vm.stopPrank();
    }

    function setupSignersRegister() internal {
        vm.startPrank(admin);
        sr_ = new SignersRegister(aManager);
        aRegister = address(sr_);

        sr_.update(studio_1, aStudio_1, studio_1_signer, true);
        sr_.update(studio_2, aStudio_2, studio_2_signer, true);

        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = sr_.update.selector;

        vm.startPrank(admin);
        am_.grantRole(FV_SR_MANAGER, sr_admin, 1 hours);
        am_.setTargetFunctionRole(aRegister, selectors, FV_SR_MANAGER);
        vm.stopPrank();
    }

    function setupTestContracts() internal {
        nft_ = new NFT("NFT", "NFT", aManager, aRegister);
        aNft = address(nft_);

        // bytes4[] memory selectors = new bytes4[](2);
        // selectors[0] = nft_.addAttributes.selector;
        // selectors[1] = 0xa89fed51; // there are two setAttributes functions
        // // therefore, nft_.setAttributes.selector won't work
        // // you can find its selectors by `forge selectors ls AttributesRegister`
        // // or use abi.encodeCall and get the first 4 bytes of the result

        // vm.startPrank(admin);
        // am_.grantRole(STUDIO_MANAGER, aStudio_1, 0);
        // am_.grantRole(STUDIO_MANAGER, aStudio_2, 0);
        // am_.setTargetFunctionRole(aNft, selectors, STUDIO_MANAGER);
        // vm.stopPrank();

        assertEq(nft_.balanceOf(user), 0);
        vm.prank(admin);
        nft_.mint(user, NFT_ID_1);
        assertEq(nft_.balanceOf(user), 1);
    }

    /** ----------------------------------
     * ! Contracts states
     * ----------------------------------- */

    function test_print_addresses() public {
        vm.skip(true);
        // emit log_address(address(this));
        // emit log_address(admin);
        // emit log_address(user);
        // emit log_address(ms_signer_1);
        // emit log_address(ms_signer_2);
        // emit log_address(aManager);
        // emit log_address(aMultisig);
        console.log("%s: \t\t %s", "deployer", address(this));
        console.log("%s: \t\t %s", "admin", admin);
        console.log("%s: \t\t %s", "user", user);
        console.log("%s: \t\t %s", "ms_signer_1", ms_signer_1);
        console.log("%s: \t\t %s", "ms_signer_2", ms_signer_2);
        console.log("%s: \t\t %s", "multisig", multisig);
        console.log("%s: \t\t %s", "FVAM", aManager);
        console.log("-------------");
        console.log("%s: \t\t %s", "aStudio_1", aStudio_1);
        console.log("%s: \t %s", "studio_1_signer", studio_1_signer);
        console.log("%s: \t\t %s", "aStudio_2", aStudio_2);
        console.log("%s: \t %s", "studio_2_signer", studio_2_signer);
        console.log("-------------");
    }

    function test_contracts_states() public {
        vm.skip(false);

        assertTrue(
            sr_.getSigner(aStudio_1) == studio_1_signer,
            "Game Studio 1's singer is BE Signer 1"
        );
    }

    /** ----------------------------------
     * ! Business logic
     * ----------------------------------- */

    function test_signing_itself() public {
        vm.skip(false);

        bytes memory data = abi.encode("test");
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(abi.encode(data))
            )
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signer1PK, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.prank(user);
        sr_.validateSignature(data, signature);
    }

    function test_setAttributesWithSignature_happy_path() public {
        AttributesRegister.Attribute[]
            memory attrs = new AttributesRegister.Attribute[](1);

        attrs[0] = AttributesRegister.Attribute(studio_1_signer, "STRENGTH");

        vm.startPrank(aStudio_1);
        bytes32[] memory uris = nft_.addAttributes(attrs);
        uint256[] memory values = new uint256[](uris.length);
        values[0] = 100;

        (bytes memory data, bytes memory signature) = sign(
            NFT_ID_1,
            uris,
            values,
            signer1PK
        );

        nft_.setAttributes(data, signature);
    }

    function test_setAttributesWithSignature_wrong_owner() public {
        AttributesRegister.Attribute[]
            memory attrs = new AttributesRegister.Attribute[](1);

        attrs[0] = AttributesRegister.Attribute(studio_1_signer, "STAMINA");

        vm.prank(aStudio_1);
        bytes32[] memory uris = nft_.addAttributes(attrs);
        uint256[] memory values = new uint256[](uris.length);
        values[0] = 100;

        (bytes memory data, bytes memory signature) = sign(
            NFT_ID_1,
            uris,
            values,
            signer2PK
        );

        bytes32[] memory list = nft_.getAttributesList();

        assertTrue(list.length == 1, "Should have 1 attribute");
        assertEq(
            list[0],
            keccak256(
                abi.encodePacked(studio_1, bytes32(abi.encodePacked("STAMINA")))
            )
        );

        vm.prank(aStudio_2);
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.InvalidAttribute.selector,
                WRONG_ATTRIBUTE_OWNER,
                uris[0]
            )
        );
        nft_.setAttributes(data, signature);
    }

    function test_setAttributes_forced_happy_path() public {
        AttributesRegister.Attribute[]
            memory attrs = new AttributesRegister.Attribute[](1);

        attrs[0] = AttributesRegister.Attribute(studio_1_signer, "STAMINA");

        vm.startPrank(aStudio_1);
        bytes32[] memory uris = nft_.addAttributes(attrs);
        uint256[] memory values = new uint256[](uris.length);
        values[0] = 100;
        nft_.setAttributes(NFT_ID_1, uris, values);
        vm.stopPrank();
    }

    function test_setAttributes_forced_wrong_owner() public {
        AttributesRegister.Attribute[]
            memory attrs = new AttributesRegister.Attribute[](1);

        attrs[0] = AttributesRegister.Attribute(studio_1_signer, "STAMINA");

        vm.prank(aStudio_1);
        bytes32[] memory uris = nft_.addAttributes(attrs);
        uint256[] memory values = new uint256[](uris.length);
        values[0] = 100;

        bytes32[] memory list = nft_.getAttributesList();

        assertTrue(list.length == 1, "Should have 1 attribute");
        assertEq(
            list[0],
            keccak256(
                abi.encodePacked(studio_1, bytes32(abi.encodePacked("STAMINA")))
            )
        );

        vm.prank(aStudio_2);
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.InvalidAttribute.selector,
                WRONG_ATTRIBUTE_OWNER,
                uris[0]
            )
        );
        nft_.setAttributes(NFT_ID_1, uris, values);
    }

    function sign(
        uint256 tokenId,
        bytes32[] memory attrs,
        uint256[] memory values,
        uint256 pk
    ) public pure returns (bytes memory payload, bytes memory signature) {
        require(attrs.length == values.length, "Arrays length mismatch");

        payload = abi.encode(tokenId, attrs, values);
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(abi.encode(payload))
            )
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(pk, digest);
        signature = abi.encodePacked(r, s, v);
    }
}

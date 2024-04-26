// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import "@openzeppelin/contracts/access/manager/AccessManager.sol";

import "../src/examples/NFT.sol";
import "../src/utils/Errors.sol";
import "../src/utils/AccessManagedRoles.sol";

import "ds-test/test.sol";
import "forge-std/console.sol";
import "forge-std/Vm.sol";

address constant admin = 0x1Fb0E85b7Ba55F0384d0E06D81DF915aeb3baca3;
address constant user = 0xA847d497b38B9e11833EAc3ea03921B40e6d847c;
address constant be_signer = 0xaebC048B4D219D6822C17F1fe06E36Eba67D4144;

// Run `anvil` to get PKs for the following addresses
address constant cso = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
address constant multisig = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;
address constant sr_admin = 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC;
address constant game_studio_1 = 0x90F79bf6EB2c4f870365E785982E1f101E93b906;
address constant game_studio_2 = 0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65;
address constant acc4 = 0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc;
address constant acc5 = 0x976EA74026E726554dB657fA54763abd0C3a0aa9;
address constant acc6 = 0x14dC79964da2C08b23698B3D3cc7Ca32193d9955;
address constant acc7 = 0x23618e81E3f5cdF7f54C3d65f7FBc0aBf5B21E8f;
address constant acc8 = 0xa0Ee7A142d267C1f36714E4a8F75612F20a79720;

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
contract NFT_Test is DSTest, Errors {
    address deployer = address(this);

    // Naming convention: contracts variables ends with _, e.g.: nft_ or am_,
    // and their addresses starts with `a`, e.g.: aNft or aAManager
    NFT nft_;
    AccessManager am_;
    SignersRegister sr_;
    address aAManager;
    address aSRegister;
    address aNft;

    // Cheat codes are state changing methods called from the address:
    // 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D
    Vm vm = Vm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

    uint256 signerPK = vm.envUint("DEV_SIGNER_PRIVATE_KEY");
    // 0xc367447789c3d98a0005c48b761ffe7d2802cea44dace8656033b15d90914c1d;

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
        setupAccessManager_external();
        setupSignersRegister();
        setupTestContracts();
    }

    // AcessManager contract is deployed on both Porcini and ROOT chains,
    // this setup recreates the roles of the real AccessManager contract
    function setupAccessManager_external() internal {
        am_ = new AccessManager(admin);
        aAManager = address(am_);

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
        am_.grantRole(FV_AM_MULTISIG, multisig, 0); // 1 hour delay for all operations
        am_.setTargetFunctionRole(aAManager, selectors, FV_AM_MULTISIG);
        uint64 role = am_.getTargetFunctionRole(
            aAManager,
            am_.grantRole.selector
        );
        assertTrue(
            role == FV_AM_MULTISIG,
            "Multisig should have FV_AM_MULTISIG role for grantRole()"
        );
        (bool hasRole, ) = am_.hasRole(role, multisig);
        assertTrue(hasRole, "Multisig should have FV_AM_MULTISIG role");
        bool isClosed = am_.isTargetClosed(aAManager);
        assertTrue(!isClosed, "AccessManager should be open");
        isClosed = am_.isTargetClosed(aSRegister);
        assertTrue(!isClosed, "SignersRegister should be open");

        vm.stopPrank();

        (bool canCall, uint256 delay) = am_.canCall(
            multisig,
            aAManager,
            am_.setTargetFunctionRole.selector
        );
        assertTrue(canCall, "Multisig can call setTargetFunctionRole()");
        assertEq(delay, 0, "Multisig has no delay for setTargetFunctionRole()");

        (canCall, delay) = am_.canCall(
            multisig,
            aAManager,
            am_.grantRole.selector
        );

        assertTrue(canCall, "Multisig should be able to call grantRole()");
        assertEq(delay, 0, "Multisig should have no delay for grantRole()");

        // console.logBytes4(am_.grantRole.selector);
        // console.log("multisig:", multisig);
        // console.log("am_:", address(am_));
        // console.log("FV_SR_MANAGER:", FV_SR_MANAGER);

        vm.startPrank(multisig);
        // am_.setTargetClosed(aAManager, true);
        // am_.grantRole(FV_SR_MANAGER, sr_admin, 1 hours);
        vm.stopPrank();
    }

    function setupSignersRegister() internal {
        vm.startPrank(admin);
        sr_ = new SignersRegister(aAManager);
        aSRegister = address(sr_);

        sr_.addManager(game_studio_1, be_signer, true);

        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = sr_.addManager.selector;

        vm.startPrank(admin);
        am_.grantRole(FV_SR_MANAGER, sr_admin, 1 hours);
        am_.setTargetFunctionRole(aSRegister, selectors, FV_SR_MANAGER);
        vm.stopPrank();
    }

    function setupTestContracts() internal {
        nft_ = new NFT("NFT", "NFT", aAManager, aSRegister);
        aNft = address(nft_);

        // Setup Signers Register (SR)

        // bytes memory data = abi.encodeCall(sr_.setSigner, (be_signer, true));
        // uint48 when = uint48(block.timestamp) + 1 days;
        // console.logBytes4(sr_.setSigner.selector);
        // console.logBytes(data);
        // console.log("aSRegister:", aSRegister);
        // console.log("be_signer:", be_signer);
        // console.log("aAManager:", aAManager);
        // console.log("when:", when);
        // vm.prank(multisig);
        // am_.schedule(aAManager, data, when);
    }

    /** ----------------------------------
     * ! Contracts states
     * ----------------------------------- */

    function test_contracts_states() public {
        // vm.skip(true);

        assertTrue(
            nft_.supportsInterface(type(IERC721).interfaceId),
            "Should support IERC721 interface"
        );

        assertTrue(
            nft_.supportsInterface(type(IERC4906).interfaceId),
            "Should support IERC4906 interface"
        );

        assertTrue(
            nft_.supportsInterface(type(IERC7160).interfaceId),
            "Should support IERC7160 interface"
        );

        assertTrue(
            sr_.getSigner(game_studio_1) == be_signer,
            "Game Studio 1's singer is BE Signer"
        );
    }

    /** ----------------------------------
     * ! Business logic
     * ----------------------------------- */

    function test_signing_itself() public {
        vm.skip(false);

        bytes memory data = abi.encode("asdf");
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(abi.encode(data))
            )
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPK, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.prank(user);
        sr_.validateSignature(data, signature);
    }

    function test_adding_attributes() public {
        assertEq(nft_.balanceOf(user), 0);
        vm.prank(admin);
        nft_.mint(user, NFT_ID_1);
        assertEq(nft_.balanceOf(user), 1);

        DynamicAttributes.Attribute memory attr = DynamicAttributes.Attribute(
            be_signer,
            "HP" // hitpoints
        );

        bytes32 uri = keccak256(abi.encodePacked("HP"));

        bytes32[] memory uris = new bytes32[](1);
        uint256[] memory values = new uint256[](1);
        uris[0] = uri;
        values[0] = 100;

        vm.startPrank(game_studio_1);
        nft_.addAttribute(uri, attr);

        (bytes memory data1, bytes memory signature1) = sign(
            NFT_ID_1,
            uris,
            values
        );

        (, bytes memory signature2) = sign(NFT_ID_2, uris, values);

        // different data/signature
        vm.expectRevert(
            abi.encodeWithSelector(Errors.InvalidInput.selector, UNKNOWN_SIGNER)
        );
        nft_.setAttribute(data1, signature2);

        // should pass
        nft_.setAttribute(data1, signature1);
    }

    function sign(
        uint256 tokenId,
        bytes32[] memory attrs,
        uint256[] memory values
    ) public view returns (bytes memory payload, bytes memory signature) {
        require(attrs.length == values.length, "Arrays length mismatch");

        payload = abi.encode(tokenId, attrs, values);
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(abi.encode(payload))
            )
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPK, digest);
        signature = abi.encodePacked(r, s, v);
    }
}

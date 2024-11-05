// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

error SBT__NotDownToken();
error SBT__NotUpToken();
error SBT__Soulbound();

contract SBT is ERC1155 {
    using Math for uint256;

    IERC20 public downToken;
    IERC20 public upToken;

    modifier onlyDownToken() {
        if (msg.sender != address(downToken)) {
            revert SBT__NotDownToken();
        }
        _;
    }

    modifier onlyUpToken() {
        if (msg.sender != address(upToken)) {
            revert SBT__NotUpToken();
        }
        _;
    }

    constructor(address _downToken, address _upToken) ERC1155("") {
        downToken = IERC20(_downToken);
        upToken = IERC20(_upToken);
    }

    function uri(uint256 tokenId) public pure override returns (string memory) {
        if (tokenId == 0) {
            return
                "ipfs://bafkreig5jsygnxekfhdjsp6qw3uoag2rxg4khnnfc2h4pvx47dczmbg2pm";
        } else if (tokenId == 1) {
            return
                "ipfs://bafkreic5b7p2obdpzdho22h2wzvvukjpfxdk3uk3viat6nescsxlj5d45y";
        }

        return "";
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes memory data
    ) public override {
        if (from != address(0) && to != address(0)) {
            revert SBT__Soulbound();
        }

        super.safeTransferFrom(from, to, id, value, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values,
        bytes memory data
    ) public override {
        if (from != address(0) && to != address(0)) {
            revert SBT__Soulbound();
        }

        super.safeBatchTransferFrom(from, to, ids, values, data);
    }

    function downVote(address wallet, uint256 amount) public onlyDownToken {

        _mint(wallet, 0, amount, "");

        emit DownVoted(wallet, amount);
    }

    function upVote(address wallet, uint256 amount) public onlyUpToken {

        _mint(wallet, 1, amount, "");

        emit UpVoted(wallet, amount);
    }

    event DownVoted(address indexed from, uint256 amount);
    event UpVoted(address indexed from, uint256 amount);
}

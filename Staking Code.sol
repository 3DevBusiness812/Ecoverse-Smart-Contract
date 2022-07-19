// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract StakingNFTStore is Ownable {

    // to make the arthmetic calculation strong
    using SafeMath for uint256;

    /*
    ** to store the entries of different users
    ** storeroom for ERC1155 store data
    ** storeroom2 for ERC721 store data 
    */
    mapping(address => mapping(address => mapping(uint256 => uint256))) public storeroom;
    mapping(address => mapping(address => uint256)) public storeroom2;
    mapping(uint256 => address) private _tokenowners;

    string public ContractName;

    address public factoryAdmin;
    uint256 public _factoryfee = 0.001 ether;
    
    uint256 public adminfee = 0.001 ether;

    event deposit1155(address nft, address from, uint256 id, uint256 amount);
    event withdrawal1155(address nft, address from, uint256 id, uint256 amount);
    event withdrawal721(address nft, address from, uint256 id);
    event deposit721(address nft, address from, uint256 id);

    constructor(string memory _cname, address _owneradmin, address _factoryAdmin) {
        ContractName = _cname;
        _transferOwnership(_owneradmin);
        factoryAdmin = _factoryAdmin;
    }

    function setdepositERC1155(address _nftContractAddress, uint256 _tokenId, uint256 _amount) public {
        require(_nftContractAddress != address(0),"Invalid Contract Address");
        IERC1155 _token = IERC1155(_nftContractAddress);
        _token.safeTransferFrom(msg.sender, address(this), _tokenId, _amount , "");
        storeroom[msg.sender][_nftContractAddress][_tokenId] += _amount;
        emit deposit1155(_nftContractAddress, msg.sender, _tokenId, _amount);
    }

    function getwithdrawalERC1155(address _nftContractAddress, uint256 _tokenId, uint256 _amount) public payable {
        require(_nftContractAddress != address(0),"Invalid Contract Address");
        require(msg.value >= _factoryfee.add(adminfee), "Need to pay Factory Admin Fee");
        payable(factoryAdmin).transfer(_factoryfee);
        payable(owner()).transfer(msg.value.sub(_factoryfee));
        IERC1155 _token = IERC1155(_nftContractAddress);
        _token.safeTransferFrom(address(this), msg.sender, _tokenId, _amount, "");
        storeroom[msg.sender][_nftContractAddress][_tokenId] -= _amount;
        emit withdrawal1155(_nftContractAddress, msg.sender, _tokenId, _amount);
    }

    function setdepositERC721(address _nftContractAddress, uint256 _tokenId) public {
        require(_nftContractAddress != address(0),"Invalid Contract Address");
        IERC721 _token = IERC721(_nftContractAddress);
        _token.transferFrom(msg.sender, address(this), _tokenId);
        storeroom2[msg.sender][_nftContractAddress] += 1;
        _tokenowners[_tokenId] = msg.sender;
        emit deposit721(_nftContractAddress, msg.sender, _tokenId);
    }

    function getwithdrawalERC721(address _nftContractAddress, uint256 _tokenId) public payable {
        require(_nftContractAddress != address(0),"Invalid Contract Address");
        require(msg.value >= _factoryfee.add(adminfee), "Need to pay Factory Admin Fee");
        payable(factoryAdmin).transfer(_factoryfee);
        payable(owner()).transfer(msg.value.sub(_factoryfee));
        IERC721 _token = IERC721(_nftContractAddress);
        _token.transferFrom(address(this), msg.sender, _tokenId);
        storeroom2[msg.sender][_nftContractAddress] -= 1;
        delete(_tokenowners[_tokenId]);
        emit withdrawal721(_nftContractAddress, msg.sender, _tokenId);
    }

    function feeChange(uint256 _adminfee) public onlyOwner {
        adminfee = _adminfee;
    }

    function onERC1155Received(address operator, address from, uint256 id, uint256 value, bytes calldata data) external returns (bytes4) {
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }

    function onERC1155BatchReceived(address operator, address from, uint256[] memory id, uint256[] memory value, bytes calldata data) external returns (bytes4) {
        return bytes4(keccak256("onERC1155Received(address,address,uint256[],uint256[],bytes)"));
    }

    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4) {
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }
}

contract factory is Ownable {

    address[] public childContract;
    /*
    ** _name : Company Name
    ** _owner : Admin  wallet address
    */
    function createChild(string memory _name, address _admin) public returns(address contractAddress) {
        StakingNFTStore child = new StakingNFTStore(_name, _admin, owner());
        childContract.push(address(child));
        return address(child);
    }
}
//SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "./Interfaces/IRewardToken.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Governance is Ownable {
    struct User {
        uint256 availableCoins;
        uint256 purchaseCoins;
        uint256 refferalCoins;
        uint256 reviewCoins;
        uint256 reedemedCoins;
        mapping(address brands => uint256 coins) rewardCoins;
    }

    struct UserRewardData {
        uint256 timestamp;
        uint256 amount;
    }

    struct Brand {
        uint256 totalCoinsPool;
        mapping(address user => UserRewardData[]) userRewardData;
    }

    address private immutable i_tokenAddress;
    uint256 public purchaseRewardRate = 100;
    uint256 public refferalCoinsRewarded = 200;
    // uint256 public reviewRewardRate = 50;
    uint256 public maxCoinsPossible = 1000;

    mapping(address => User) public addressToUser;
    mapping(address => Brand) public addressToBrand;
    mapping(address => bool) private registeredAddress;
    mapping(address => bool) private registeredUsers;

    error MORE_THAN_MAX_POSSIBLE_COINS();
    error REFFERED_USER_ITSELF();
    error AMOUNT_MUST_BE_GREATER_THAN_ZERO();
    error NOT_SUFFICIENT_COINS_TO_REDEEM();
    error ZERO_ADDRESS_NOT_ALLOWED();
    error NOT_SUFFICIENT_COINS_TO_SEND();
    error NOT_SUFFICIENT_COINS_TO_BURN();
    error USER_IS_NOT_REGISTERED();
    error ADDRESS_IS_NOT_REGISTERED();

    event Tokens_Burned(uint256 amount);
    event Brand_Reward_Burned(uint256 amount);
    event Tokens_Expired();
    event Token_Rewarded(
        address indexed brand,
        address indexed user,
        uint256 indexed amount
    );

    event Purchase_Coins_Received(
        address indexed user,
        address indexed brand,
        uint256 indexed coins
    );

    event Refferal_Coins_Received(
        address indexed personRefferedBy,
        address indexed personReffered,
        uint256 indexed coins
    );

    event Review_Award_Transferred();

    modifier sameUser(address _userAddress) {
        if (msg.sender == _userAddress) {
            revert REFFERED_USER_ITSELF();
        }
        _;
    }

    modifier notZeroAddress(address _address) {
        if (_address == address(0)) {
            revert ZERO_ADDRESS_NOT_ALLOWED();
        }
        _;
    }

    modifier greaterThanZero(uint256 _amount) {
        if (_amount == 0) {
            revert AMOUNT_MUST_BE_GREATER_THAN_ZERO();
        }
        _;
    }

    modifier isUserRegistered() {
        if (registeredUsers[msg.sender] == false) {
            revert USER_IS_NOT_REGISTERED();
        }
        _;
    }

    modifier isBrandAddressRegistered() {
        if (registeredAddress[msg.sender] == false) {
            revert ADDRESS_IS_NOT_REGISTERED();
        }
        _;
    }

    constructor(address _tokenAddress) {
        i_tokenAddress = _tokenAddress;
    }

    function registerUser() external {
        registeredUsers[msg.sender] = true;
    }

    function registerAddress() external {
        registeredAddress[msg.sender] = true;
    }

    function purchaseItem(
        uint256 _purchaseAmount,
        address _brandAddress
    ) external isUserRegistered {
        uint256 coins = _purchaseAmount * purchaseRewardRate;
        if (coins > maxCoinsPossible) {
            coins = maxCoinsPossible;
        }
        //Mint for user as well as brands
        User storage _user = addressToUser[msg.sender];
        _user.purchaseCoins += coins;
        _user.availableCoins += coins;
        Brand storage brand = addressToBrand[_brandAddress];
        brand.totalCoinsPool += coins;
        IRewardToken(i_tokenAddress).mint(coins, msg.sender);
        IRewardToken(i_tokenAddress).mint(coins, _brandAddress);
        emit Purchase_Coins_Received(msg.sender, _brandAddress, coins);
    }

    function refferalUser(
        address reffererAddress
    ) external sameUser(reffererAddress) isUserRegistered {
        //Update all the mappings
        User storage _user1 = addressToUser[reffererAddress];
        User storage _user2 = addressToUser[msg.sender];
        _user1.refferalCoins += refferalCoinsRewarded;
        _user1.availableCoins += refferalCoinsRewarded;
        _user2.refferalCoins += refferalCoinsRewarded;
        _user2.availableCoins += refferalCoinsRewarded;
        IRewardToken(i_tokenAddress).mint(
            refferalCoinsRewarded,
            reffererAddress
        );
        IRewardToken(i_tokenAddress).mint(refferalCoinsRewarded, msg.sender);
        // then mint for the user as well as refree
        emit Refferal_Coins_Received(
            reffererAddress,
            msg.sender,
            refferalCoinsRewarded
        );
    }

    function reviewItem(
        uint256 _amount,
        address _userToPay
    ) external onlyOwner greaterThanZero(_amount) {
        // update the mappings and only owner can pay to the user , will only and update thew mappings
        User storage _user = addressToUser[_userToPay];
        _user.reviewCoins += _amount;
        _user.availableCoins += _amount;
        IRewardToken(i_tokenAddress).mint(_amount, _userToPay);
        emit Review_Award_Transferred();
    }

    // redeem coins on purchase , review and refferal

    /* Add a modfier for the brand check*/

    function redeemCoins(
        uint256 _coinsAmount
    ) external greaterThanZero(_coinsAmount) isUserRegistered {
        // User mapping would be updated and then that much tokens would be burned from user balance
        User storage _user = addressToUser[msg.sender];
        uint256 _availableCoins = _user.availableCoins;
        if (_availableCoins < _coinsAmount) {
            revert NOT_SUFFICIENT_COINS_TO_REDEEM();
        }
        _user.availableCoins -= _coinsAmount;
        _user.reedemedCoins += _coinsAmount;
        IRewardToken(i_tokenAddress).burn(_coinsAmount, msg.sender);
        emit Tokens_Burned(_coinsAmount);
    }

    function redeemBrandReward(
        address _brandAddress,
        uint256 _coinsAmount
    ) external greaterThanZero(_coinsAmount) isUserRegistered {
        //Check the available coins* that in the user mapping
        // Brand mapping would be updated and then that much tokens would be burned from user balance
        User storage _user = addressToUser[msg.sender];
        uint256 brandCoins = _user.rewardCoins[_brandAddress];
        if (brandCoins < _coinsAmount) {
            revert NOT_SUFFICIENT_COINS_TO_REDEEM();
        }
        _user.rewardCoins[_brandAddress] -= _coinsAmount;
        _user.reedemedCoins += _coinsAmount;
        IRewardToken(i_tokenAddress).burn(_coinsAmount, msg.sender);
        emit Brand_Reward_Burned(_coinsAmount);
    }

    function rewardUser(
        address _rewardingUser,
        uint256 _amount
    ) external greaterThanZero(_amount) isBrandAddressRegistered {
        // The Brand will give tokens to their loyal users on their own
        // We will update the rewards mapping in the users table as well as the rewards mapping in the brands struct
        // We will also update the totalRewardedCoins in the brands struct
        Brand storage _brand = addressToBrand[msg.sender];
        User storage _user = addressToUser[_rewardingUser];
        if (_brand.totalCoinsPool < _amount) {
            revert NOT_SUFFICIENT_COINS_TO_SEND();
        }
        _brand.totalCoinsPool -= _amount;
        _brand.userRewardData[_rewardingUser].push(
            UserRewardData(block.timestamp, _amount)
        );
        _user.rewardCoins[msg.sender] += _amount;

        /*Approve first in frontend using approve then call this */
        /*Approve function to be added so that user can call and not on */
        IRewardToken(i_tokenAddress).transferFrom(
            msg.sender,
            _rewardingUser,
            _amount
        );
        emit Token_Rewarded(msg.sender, _rewardingUser, _amount);
    }

    function expireTokens(
        uint256 _brandCoins,
        address[] memory _brands,
        uint256[] memory _brandAmount,
        uint256 _platformCoins
    ) external {
        User storage _user = addressToUser[msg.sender];
        /*check for array lengths to be same */
        if (_brandCoins > 0) {
            for (uint i = 0; i < _brands.length; i++) {
                /*Addd validation checks for that no zero address is there */
                if (_user.rewardCoins[_brands[i]] < _brandAmount[i]) {
                    revert NOT_SUFFICIENT_COINS_TO_BURN();
                }
                _user.rewardCoins[_brands[i]] -= _brandAmount[i];
            }
        }
        if (_platformCoins > 0) {
            if (_user.availableCoins < _platformCoins) {
                revert NOT_SUFFICIENT_COINS_TO_BURN();
            }
            _user.availableCoins -= _platformCoins;
        }
        IRewardToken(i_tokenAddress).burn(
            _brandCoins + _platformCoins,
            msg.sender
        );
        emit Tokens_Expired();
    }

    /*All getter functions 
        struct User {
        uint256 availableCoins;
        uint256 purchaseCoins;
        uint256 refferalCoins;
        uint256 reviewCoins;
        uint256 reedemedCoins;
        mapping(address brands => uint256 coins) rewardCoins;
    }

    struct UserRewardData {
        uint256 timestamp;
        uint256 amount;
    }

    struct Brand {
        uint256 totalCoinsPool;
        uint256 usedForServices;
        mapping(address user => UserRewardData[]) userRewardData;
    }


    mapping(address user => User obj) public addressToUser;
    mapping(address brand => Brand obj) public addressToBrand;
    mapping(address => bool) private registeredAddress;
    mapping(address => bool) private registeredUsers;
    */

    function updatePurchaseReward(uint256 _updatedRate) external onlyOwner {
        purchaseRewardRate = _updatedRate;
    }

    function updateRefferalReward(uint256 _updatedReward) external onlyOwner {
        refferalCoinsRewarded = _updatedReward;
    }

    function updateMaxCoins(uint256 _updatedReward) external onlyOwner {
        maxCoinsPossible = _updatedReward;
    }

    function getUserBrandCoins(
        address user,
        address brand
    ) external view returns (uint256) {
        User storage _user = addressToUser[user];
        return _user.rewardCoins[brand];
    }

    function getBrandRewardData(
        address brand
    ) external view returns (UserRewardData[] memory) {
        Brand storage _brand = addressToBrand[brand];
        return _brand.userRewardData[msg.sender];
    }

    function getTokenAddress() external view onlyOwner returns (address) {
        return i_tokenAddress;
    }
}
 
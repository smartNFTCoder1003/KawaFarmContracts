//SPDX-License-Identifier: Unlicense
pragma solidity >0.6.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract KawaPool is Ownable {
    struct user {
        uint256 staked;
        uint256 withdrawn;
        uint256[] stakeTimes;
        uint256[] stakeAmounts;
        uint256[] startingAPYLength;
    }
    using SafeMath for uint256;
    uint256 public mintedTokens;
    uint256 public totalStaked;
    uint256[] apys;
    uint256[] apyTimes;
    mapping(address => user) public userList;
    event StakeTokens(address indexed user, uint256 tokensStaked);
    IERC20 stakeToken;
    IERC20 xKawaToken;
    mapping(address => uint256) earlyUnstake;

    constructor(
        address tokenAddress,
        address rewardTokenAddress,
        uint256 initAPY
    ) public {
        stakeToken = IERC20(tokenAddress);
        xKawaToken = IERC20(rewardTokenAddress);
        apys.push(initAPY);
        apyTimes.push(now);
    }

    function userStaked(address addrToCheck) public view returns (uint256) {
        return userList[addrToCheck].staked;
    }

    function userClaimable(address addrToCheck)
        public
        view
        returns (uint256 withdrawable)
    {
        if (xKawaToken.balanceOf(address(this)) > 0) {
            withdrawable = calculateStaked(addrToCheck)
            .add(earlyUnstake[addrToCheck])
            .sub(userList[msg.sender].withdrawn);
            if (withdrawable > xKawaToken.balanceOf(address(this))) {
                withdrawable = xKawaToken.balanceOf(address(this));
            }
        } else {
            withdrawable = 0;
        }
    }

    function changeAPY(uint256 newAPY) external onlyOwner {
        apys.push(newAPY);
        apyTimes.push(now);
    }

    function emergencyWithdraw() external onlyOwner {
        require(
            xKawaToken.transfer(
                msg.sender,
                xKawaToken.balanceOf(address(this))
            ),
            "Emergency withdrawl failed"
        );
    }

    function withdrawTokens() public {
        //remove supplied
        earlyUnstake[msg.sender] = userClaimable(msg.sender);
        require(
            stakeToken.transfer(msg.sender, userList[msg.sender].staked),
            "Stake Token Transfer failed"
        );
        totalStaked = totalStaked.sub(userList[msg.sender].staked);
        delete userList[msg.sender];
    }

    function withdrawReward() public {
        uint256 withdrawable = userClaimable(msg.sender);
        require(
            xKawaToken.transfer(msg.sender, withdrawable),
            "Reward Token Transfer failed"
        );
        userList[msg.sender].withdrawn = userList[msg.sender].withdrawn.add(
            withdrawable
        );
        delete earlyUnstake[msg.sender];
        mintedTokens = mintedTokens.add(withdrawable);
    }

    function claimAndWithdraw() public {
        withdrawReward();
        withdrawTokens();
    }

    function stakeTokens(uint256 amountOfTokens) public {
        totalStaked = totalStaked.add(amountOfTokens);
        require(
            stakeToken.transferFrom(msg.sender, address(this), amountOfTokens),
            "Stake Token Transfer Failed"
        );
        userList[msg.sender].staked = userList[msg.sender].staked.add(
            amountOfTokens
        );
        userList[msg.sender].stakeTimes.push(now);
        userList[msg.sender].stakeAmounts.push(amountOfTokens);
        userList[msg.sender].startingAPYLength.push(apys.length - 1);
        emit StakeTokens(msg.sender, amountOfTokens);
    }

    function calculateStaked(address usercheck)
        public
        view
        returns (uint256 totalMinted)
    {
        totalMinted = 0;
        for (uint256 i = 0; i < userList[usercheck].stakeAmounts.length; i++) {
            //loop through everytime they have staked
            for (
                uint256 j = userList[usercheck].startingAPYLength[i];
                j < apys.length;
                j++
            ) {
                //for the i number of time they have staked, go through each apy times and values since they have staked (which is startingAPYLength)
                if (userList[usercheck].stakeTimes[i] < apyTimes[j]) {
                    //this will happen if there is an APY change after the user has staked, since only after apy change can apy time > user staked time
                    if (userList[usercheck].stakeTimes[i] < apyTimes[j - 1]) {
                        //assuming there are 2 or more apy changes after staking, it will mean user has amount still staked in between the 2 apy
                        totalMinted = totalMinted.add(
                            (
                                userList[usercheck].stakeAmounts[i].mul(
                                    (apyTimes[j].sub(apyTimes[j - 1]))
                                )
                            )
                            .mul(apys[j])
                            .div(10**18)
                        );
                    } else {
                        //will take place on the 1st apy change after staking
                        totalMinted = totalMinted.add(
                            (
                                userList[usercheck].stakeAmounts[i].mul(
                                    (now.sub(apyTimes[j]))
                                )
                            )
                            .mul(apys[j])
                            .div(10**18)
                        );
                    }
                } else {
                    //Will take place only once for each iteration in i, as only once and the first time will apy time < user stake time
                    totalMinted = totalMinted.add(
                        (
                            userList[usercheck].stakeAmounts[i].mul(
                                (now.sub(userList[usercheck].stakeTimes[i]))
                            )
                        )
                        .mul(apys[j])
                        .div(10**18)
                    );
                    //multiplies stake amount with time staked, divided by apy value which gives number of tokens to be minted
                }
            }
        }
    }
}

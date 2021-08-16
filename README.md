# Rock-Paper-Scissors test project

The objective of this test is to create a smart contract named **RockPaperScissors** whereby two players can play the classic game of rock :moyai:, paper :page_facing_up:, scissors :scissors: using ERC20 for bet. 

_Exactly_ team determine the following characteristics for this smart contract:

- Each player needs to deposit the right token amount, possibly zero. :heavy_check_mark:
- To play, each Bob and Alice need to submit their unique move. :heavy_check_mark:
- The contract decides and rewards the winner with all tokens wagered. :heavy_check_mark:
- Make it a utility whereby any 2 people can decide to play against each other. :heavy_check_mark:
- Reduce gas costs as much as possible. :heavy_check_mark:
- Let players bet their previous winnings. :heavy_check_mark:
- How can you entice players to play, knowing that they may have their funds stuck in the contract if they face an uncooperative player? :heavy_check_mark:
- Include any tests using Hardhat. :x:

The green tick means that my implementation has the requested characteristic. On the other hand, the red cross means that this solution has not implemented these characteristics. 

So, How did I solve this? Let's take a look...

## :lock: Hidden values & Blockchain
One key characteristic of the Ethereum blockchain is that all the submitted values when interacting with a contract are saved and stored forever in the blockchain. But, Which will be the incentive for a player to start a rock-paper-scissors game if his/her selection will be public? Second player will always win if so. The difficulty of implementing this game on chain is that both players can't share their values at the same time and player one will always be at a disadvantage. 

There are many ways of implementing this solution (for example Oracles) but a very simple way of doing this is with a Commitment Scheme. It consists of allowing someone to commit to a value while keeping it hidden from others with the compromise of revealing it later. The scheme has two phases: a commit phase in which a value is chosen and saved, and a reveal phase in which the value is revealed and checked. 

## :computer: My implementation
In the case of this game, _Player 1_ submit his/her rock-paper-scissor selection embedded in a hash that is preprocessed. _Player 1_ doesn't submit his/her select unhidden, it's protected with the preprocessed hash that was processed before this submission. 

Does _Player 2_ also need to submit his/her selection in an embedded hash? There is no need for that. All the implementations that I saw when I had to Google how to solve this problem had 4 steps: _Player 1_ submit his/her hidden selection, _Player 2_ submit his/her selection, _Player 1_ reveals his/her selection, _Player 2_ reveals his/her selection. In this implementation, _Player 2_ doesn't need to hide his/her selection, only _Player 1_ and a step less is required. 

What happens if _Player 1_ knowing he or she has already lost because _Player 2_ selection is unhidden doesn't want to cooperate and show his/her selection? In this case, _Player 1_ has a limit of one day since _Player 2_ makes his/her move. If _Player 1_ doesn't cooperate before this time limit, _Player 2_ can claim the price. _Player 1_ is also secure if _Player 2_ doesn't accept his/her game: _Player 1_ can cancel the game before _Player 2_ makes his/her move and withdraws the bet. 

Only 3 steps are needed to resolve a game: _Player 1_ submit his/her hidden selection, _Player 2_ submit his/her unhidden selection, _Player 1_ reveals his/her selection or _Player 2_ claims the price is time limit has been exceeded. 

## :moneybag: ERC20 chosen
The contract is prepared for using any ERC20 as betting and earning currency because in the constructor function is being passed the contract address token as an argument. For testing purposes, I used a dummy ERC20 contract called **"DummyUBI.sol"** that is a dummy Token named _Universal Basic Income_ like Santi Siri's project. 

## :boom: Extras
This implementation allows players to have as many games simultaneously as they want but they can only play against a specific player only one game simultaneously. 

Earnings will be deposited in the contract and players can use it totally or partially to start or accept another game. They can also use a mix of earnings and new deposits for new games. Of course, pre-approval is necessary to use ERC20 for this contract on behalf of players. If they do not approve, their transactions will be reverted. 

## :hammer: Tools
For this project, I used **Visual Studio Code** for coding and **Remix** for testing and tuning.

Links:
- https://aliazam60.medium.com/implementing-rock-paper-scissors-in-solidity-989db92126af
- https://medium.com/swlh/exploring-commit-reveal-schemes-on-ethereum-c4ff5a777db8
- Universal Basic Income: https://www.proofofhumanity.id/

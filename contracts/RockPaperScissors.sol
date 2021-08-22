pragma solidity ^0.8.4;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol";

contract RockPaperScissors {
    
    IERC20 iToken;
    
    enum Choice {
        None,
        Rock,
        Paper,
        Scissors
    }
    
    enum Status {
        Canceled,
        Started,
        Accepted,
        Finished
    }
    
    enum Result {
        Draw,
        Player1,
        Player2
    }
    
    struct Game {
        uint limitTime;
        bytes32 player1Commitment;
        Choice player2Choice;
        Status status; 
        uint bet;
    }
    
    mapping(address => mapping(address => Game)) games;
    mapping(address => uint) winnings;
    
    // This event will trigger when player 1 start the game
    event StartGame(address _player1, address _player2, uint _bet);
    // This event will trigger when player 2 place his/her bet
    event AcceptGame(address _player1, address _player2, uint limitTime);
    // This event will trigger when player 1 reveals his/her bet or player 2 claims the game when time limit is rechead
    event FinishGame(address _player1, address _player2, Choice _player1Choice, Choice _player2Choice, uint _bet, Result _result);
    // This event will trigger when player 1 cancel the game before player 2 accepts it
    event CancelGame(address _player1, address _player2, Status _status);
    
    constructor(address _token) {
        iToken = IERC20(_token); // ERC20 Token interface is created
    }
    
    // Player 1 place a bet with a hidden selection
    function startGame(uint _bet, bool _useEarnings, address _opponent, bytes32 _selection) external {
        
        // No other game within this two players on course
        require(games[_opponent][msg.sender].status == Status.Canceled || games[_opponent][msg.sender].status == Status.Finished,"You already have a game ongoing with this opponent");
        require(games[msg.sender][_opponent].status == Status.Canceled || games[msg.sender][_opponent].status == Status.Finished,"You already have a game ongoing with this opponent");
        
        //Approval for ERC20 and this contract must happen before. Otherwise it will fail
        if (_bet > 0 && _useEarnings == false) {
            
            uint allowance = iToken.allowance(msg.sender,address(this));
            require(allowance >= _bet,"The allowance is not enough for this bet. Please rise");
            iToken.transferFrom(msg.sender,address(this),_bet);
        
        // Players can reuse their earnings that are still in the contract
        } else if (_bet > 0 && _useEarnings == true) {
            if (_bet <= winnings[msg.sender]) {
                winnings[msg.sender] -= _bet;
            } else {
                uint rest = _bet - winnings[msg.sender];
                uint allowance = iToken.allowance(msg.sender,address(this));
                require(allowance >= rest,"The allowance is not enough for this bet. Please rise");
				winnings[msg.sender] = 0;
				iToken.transferFrom(msg.sender,address(this),rest);
            }
            
        }
        
        games[msg.sender][_opponent] = Game(0, _selection, Choice.None, Status.Started, _bet);
        emit StartGame(msg.sender, _opponent, _bet);
        
    }
    
    // Player 2 accept the game and save the unhidden selection 
    function acceptGame(address _opponent, Choice _selection, bool _useEarnings) external {
        
        // Valid selection
        require(_selection == Choice.Rock || _selection == Choice.Paper || _selection == Choice.Scissors, "Selection must be ROCK, PAPER or SCISSORS");
        
        // Check is the game exists and is playable
        require(games[_opponent][msg.sender].status == Status.Started, "The game is not in the correct status");
        
        //Approval for ERC20 and this contract must happen before. Otherwise it will fail
        if (games[_opponent][msg.sender].bet > 0 && _useEarnings == false) {
            
            uint allowance = iToken.allowance(msg.sender,address(this));
            require(allowance >= games[_opponent][msg.sender].bet,"The allowance is not enough for this bet. Please rise");
            iToken.transferFrom(msg.sender,address(this),games[_opponent][msg.sender].bet);
        
        // Players can reuse their earnings that are still in the contract
        } else if (games[_opponent][msg.sender].bet > 0 && _useEarnings == true) {
            if (games[_opponent][msg.sender].bet <= winnings[msg.sender]) {
                winnings[msg.sender] -= games[_opponent][msg.sender].bet;
            } else {
                uint rest = games[_opponent][msg.sender].bet - winnings[msg.sender];
                uint allowance = iToken.allowance(msg.sender,address(this));
                require(allowance >= rest,"The allowance is not enough for this bet. Please rise");
				winnings[msg.sender] = 0;
				iToken.transferFrom(msg.sender,address(this),rest);
            }
            
        }
        
        
        games[_opponent][msg.sender].player2Choice = _selection;
        games[_opponent][msg.sender].limitTime = block.timestamp + 1 days;
        games[_opponent][msg.sender].status = Status.Accepted;
        emit AcceptGame(_opponent, msg.sender, games[_opponent][msg.sender].limitTime);
        
    }
    
    // Player 1 reveal his/her selection and the game finish calculating the winner
    function finishGame(address _opponent, Choice _selection, string memory _secret) external {
        
        // Valid selection
        require(_selection == Choice.Rock || _selection == Choice.Paper || _selection == Choice.Scissors, "Selection must be ROCK, PAPER or SCISSORS");
        
        // Valid status
        require(games[msg.sender][_opponent].status == Status.Accepted, "The game is not in the correct status");
        
        // Valid player 1 hash
        require(keccak256(abi.encodePacked(msg.sender, _selection, _secret)) == games[msg.sender][_opponent].player1Commitment, "The hash is invalid");
        
        Result resultGame;
        
        // Both player selected same choice
        if(games[msg.sender][_opponent].player2Choice == _selection) {
            winnings[msg.sender] = games[msg.sender][_opponent].bet;
            winnings[_opponent] = games[msg.sender][_opponent].bet;
            resultGame = Result.Draw;
        }
        // Player 1 selected Rock
        else if (_selection == Choice.Rock) { 
            assert(games[msg.sender][_opponent].player2Choice == Choice.Paper || games[msg.sender][_opponent].player2Choice == Choice.Scissors);
            
            if(games[msg.sender][_opponent].player2Choice == Choice.Paper) {
                // player 2 wins
                winnings[_opponent] = games[msg.sender][_opponent].bet * 2; 
                resultGame = Result.Player2;
            } else if (games[msg.sender][_opponent].player2Choice == Choice.Scissors) {
                // player 1 wins 
                winnings[msg.sender] = games[msg.sender][_opponent].bet * 2; 
                resultGame = Result.Player1;
            }
            
        }
        // Player 1 selected Paper
        else if (_selection == Choice.Paper) {
            assert(games[msg.sender][_opponent].player2Choice == Choice.Rock || games[msg.sender][_opponent].player2Choice == Choice.Scissors);
            
            if(games[msg.sender][_opponent].player2Choice == Choice.Rock) {
                // player 1 wins
                winnings[msg.sender] = games[msg.sender][_opponent].bet * 2;  
                resultGame = Result.Player1;
            } else if (games[msg.sender][_opponent].player2Choice == Choice.Scissors) {
                // player 2 wins 
                winnings[_opponent] = games[msg.sender][_opponent].bet * 2; 
                resultGame = Result.Player2;
            }
            
        }
        // Player 1 selected Scissors
        else if (_selection == Choice.Scissors) {
            assert(games[msg.sender][_opponent].player2Choice == Choice.Rock || games[msg.sender][_opponent].player2Choice == Choice.Paper);
            
            if(games[msg.sender][_opponent].player2Choice == Choice.Rock) {
                // player 2 wins
                winnings[_opponent] = games[msg.sender][_opponent].bet * 2; 
                resultGame = Result.Player2;
            } else if (games[msg.sender][_opponent].player2Choice == Choice.Paper) {
                // player 1 wins
                winnings[msg.sender] = games[msg.sender][_opponent].bet * 2;  
                resultGame = Result.Player1;
            }
            
        }
        
        games[msg.sender][_opponent].status = Status.Finished;
        emit FinishGame(msg.sender, _opponent, _selection, games[msg.sender][_opponent].player2Choice, games[msg.sender][_opponent].bet, resultGame);
        
        
    }
    
    // This function is for player 2 to claim the price if player 1 doesn't coperate
    function claimGame(address _opponent) public {
        
        // Valid status
        require(games[_opponent][msg.sender].status == Status.Accepted, "The game is not in the correct status");
        
        // Valid limitTime
        require(games[_opponent][msg.sender].limitTime < block.timestamp, "Limit timeline has not been reached");
        
        
        winnings[msg.sender] = games[_opponent][msg.sender].bet * 2;
        games[_opponent][msg.sender].status = Status.Finished;
        emit FinishGame(_opponent, msg.sender, Choice.None, games[msg.sender][_opponent].player2Choice, games[msg.sender][_opponent].bet, Result.Player2);
        
    }
    
    // This function is for player 1 to cancel the game if player 2 hasn't accepted yet
    function cancelGame(address _opponent) public {
        
        // Valid status
        require(games[msg.sender][_opponent].status == Status.Started, "The game is not in the correct status");
        
        
        winnings[msg.sender] = games[msg.sender][_opponent].bet;
        games[msg.sender][_opponent].status = Status.Canceled;
        emit CancelGame(msg.sender, _opponent, Status.Canceled);
        
    }
    
    // Function for withdraw a player's earnings    
     function withdrawEarnings() public {
        require(winnings[msg.sender] > 0, "Your winnings are 0");
        winnings[msg.sender] = 0;
		iToken.transfer(msg.sender,winnings[msg.sender]);
     }
     
     // Read-only function for help player 1 calculate the hash
     function getHash(Choice _selection, string memory _secret) public view returns (bytes32) {
        return(keccak256(abi.encodePacked(msg.sender, _selection, _secret)));
     }
    
    // Read-only function for get a player's earnings 
    function getMyEarnings() public view returns (uint) {
        return(winnings[msg.sender]);
     }
}
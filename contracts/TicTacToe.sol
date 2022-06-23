//SPDX-License-Identifier: Unlicense
pragma solidity ^0.4.19;

/**
 * @title TicTacToe contract
 **/
contract TicTacToe {
    uint constant GAME_NOT_STARTED = 0;
    uint constant GAME_PLAYER_1_WON = 1;
    uint constant GAME_PLAYER_2_WON = 2;
    uint constant GAME_DRAW = 3;
    uint constant GAME_STARTED = 4;

    /**
      Players in the game
     */
    address[2] public players;

    /**
      Number of players that have joined the game
     */
    uint8 public playersJoined;
    
    /**
      Amount to bet
     */
    uint256 public betAmount;

    /**
     turn
     1 - players[0]'s turn
     2 - players[1]'s turn
     */
    uint public turn = 1;


    /**
     status
      GAME_NOT_STARTED = 0
      GAME_PLAYER_1_WON = 1
      GAME_PLAYER_2_WON = 2
      GAME_DRAW = 3
      GAME_STARTED = 4
     */
    uint public status = GAME_NOT_STARTED;

    /**
      Winner has been paid
     */
    bool private paidWinner = false;

    /**
    board status
     0    1    2
     3    4    5
     6    7    8
     */
    uint[3][3] private board;

    /**
      * @dev Deploy the contract to create a new game
      * @param opponent The address of player2
      **/
    constructor(address opponent) public payable {
        require(msg.sender != opponent, "No self play.");
        require(msg.value > 0, "Bet too small");

        betAmount = msg.value;
        players[0] = msg.sender;
        players[1] = opponent;
        playersJoined = 1;
    }

    /**
      * @dev Join the game - game then starts
      **/
    function join() external payable  {
        require (playersJoined == 1, "Already joined");
        require(msg.sender == players[1], "You are not the opponent");
        require(msg.value == betAmount, "Wrong bet amount.");

        playersJoined = 2;
        status = GAME_STARTED;
    }


    /**
      * @dev Check a, b, c in a line are the same
      * _threeInALine doesn't check if a, b, c are in a line
      * @param a position a
      * @param b position b
      * @param c position c
      */    
    function _threeInALine(uint a, uint b, uint c) private pure returns (bool){
       
        return (a != 0 && a == b && a == c);

    }

    /**
      * @dev Checks if there are three in a line in one of the rows
      * @return player number of winner three in a line, otherwise return game status
      */    
    function winnerInRow() private view returns (uint){
      for (uint8 x = 0; x < 3; x++) {
        if (_threeInALine(board[x][0], board[x][1], board[x][2])) {
          return board[x][0];
        }
      }

      return GAME_STARTED;
    }

    /**
      * @dev Checks if there are three in a line in one of the columns
      * @return player number of winner three in a line, otherwise return game status
      */    
    function winnerInColumn() private view returns (uint){
      for (uint8 y = 0; y < 3; y++) {
        if (_threeInALine(board[0][y], board[1][y], board[2][y])) {
          return board[0][y];
        }
      }

      return GAME_STARTED;
    }

    /**
      * @dev Checks if there are three in a line in one of the diagonals
      * @return player number of winner three in a line, otherwise return game status
      */   
    function winnerInDiagonal() private view returns (uint){
      
      if (_threeInALine(board[0][0], board[1][1], board[2][2])) {
        return board[0][0];
      }
      
      if (_threeInALine(board[0][2], board[1][1], board[2][0])) {
        return board[0][0];
      }

      return GAME_STARTED;
    }

    /**
      * @dev Checks if the board is full
      * @return if the board is full
      */  
    function fullBoard() private view returns (bool){
      
      for (uint j=0; j < board.length; j++) {
        for (uint k=0; k < board.length; k++) {
          if (board[j][k] == 0) {
            return false;
          }
        }
      }

      return true;
    }



    /**
     * @dev get the status of the game
     * @return status of the game
     */
    function _getStatus() private view returns (uint) {
       

        uint cur_status = winnerInRow();

        if (cur_status < GAME_STARTED) {
          return cur_status;
        }

        cur_status = winnerInColumn();

        if (cur_status < GAME_STARTED) {
          return cur_status;
        }

        cur_status = winnerInDiagonal();

        if (cur_status < GAME_STARTED) {
          return cur_status;
        }

        if (fullBoard()) {
          return GAME_DRAW;
        }

        return GAME_STARTED;
    }

    /**
     * @dev ensure the game is still ongoing before a player move
     * update game status after a player move
     */
    modifier _checkStatus {
       
        require(status == GAME_STARTED, "Game is Complete.");
        _;
        status = _getStatus();
        if (status > GAME_NOT_STARTED && status < GAME_DRAW) {
          payWinner();
        } else if (status == GAME_DRAW) {
          draw();
        }
    }

    /**
     * @dev check if it's msg.sender's turn
     * @return true if it's msg.sender's turn otherwise false
     */
    function myTurn() public view returns (bool) {
       return msg.sender == players[turn-1];
    }

    /**
     * @dev ensure it's a msg.sender's turn before player move
     * update the turn after player move
     */
    modifier _myTurn() {
      require(myTurn(), "Not your turn!");
      _;
      turn = (turn % 2) + 1;

    }

    /**
     * @dev check player move is valid
     * @param pos_x the x position the player places at
     * @param pos_y the y position the player places at
     * @return true if valid player move otherwise false
     */
    function validMove(uint pos_x, uint pos_y) public view returns (bool) {
      return pos_x >= 0 && pos_x < 9 && pos_y >= 0 && pos_y < 9 && board[pos_x][pos_y] == 0;

    }

    /**
     * @dev ensure player move is valid before move is made
     * @param pos_x the x position the player places at
     * @param pos_y the y position the player places at
     */
    modifier _validMove(uint pos_x, uint pos_y) {
      require (validMove(pos_x, pos_y), "Move is invalid.");
      _;
    }

    /**
     * @dev a player makes a move
     * @param pos_x the x position the player places at
     * @param pos_y the y position the player places at
     */
    function move(uint pos_x, uint pos_y) public _validMove(pos_x, pos_y) _checkStatus _myTurn {
        board[pos_x][pos_y] = turn;
    }

    /**
     * @dev show the current board state
     * @return board
     */
    function showBoard() public view returns (uint[3][3]) {
      return board;
    }

    /**
     * @dev return funds to respective owners
     */
    function draw() private {
      if (!paidWinner) {
        paidWinner = true;
        players[0].transfer(betAmount);
        players[1].transfer(betAmount);
      } 
    }

    /**
     * @dev award winner with winnings
     */
    function payWinner() private {
      if (!paidWinner) {
        paidWinner = true;
        players[status - 1].transfer(betAmount + betAmount);
      }
    }
}

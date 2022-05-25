//SPDX-License-Identifier: Unlicense
pragma solidity ^0.4.24;

/**
 * @title TicTacToe contract
 **/
contract TicTacToe {
    address[2] public players;
    address[2] public playersJoined;
    
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
     0 - ongoing
     1 - players[0] won
     2 - players[1] won
     3 - draw
     4 - Not started
     */
    uint public status = 4;
    bool private paidWinner = false;
    /**
    board status
     0    1    2
     3    4    5
     6    7    8
     */
    uint[3][3] private board;

    /**
      Mapping
     */
    // mapping(uint => uint[][]) public lines;
    // uint[][] private tests;

    /**
      * @dev Deploy the contract to create a new game
      * @param opponent The address of player2
      **/
    constructor(address opponent) public {
        require(msg.sender != opponent, "No self play.");
        // require(msg.value <= msg.sender.balance, "Player 1 insufficient balance.");
        // require(msg.value <= opponent.balance, "Player 2 insufficient balance.");

        players[0] = msg.sender;
        players[1] = opponent;
        

        /**
          Fill up lines mapping
        */

        // lines[0] = [[0,1,2],[0,3,6],[0,4,8]];
        // lines[1] = [[0,1,2],[1,4,7]];
        // lines[2] = [[0,1,2],[2,5,8],[2,4,6]];
        // lines[3] = [[3,4,5],[0,3,6]];
        // lines[4] = [[3,4,5],[1,4,7],[0,4,8],[2,4,6]];
        // lines[5] = [[3,4,5],[2,5,8]];
        // lines[6] = [[6,7,8],[0,3,6],[2,4,6]];
        // lines[7] = [[6,7,8],[1,4,7]];
        // lines[8] = [[6,7,8],[2,5,8],[0,4,8]];
    }

    modifier _hasJoined(address sender) {
      require((sender == players[0] && playersJoined[0] == address(0)) || (sender == players[1] && playersJoined[1] == address(0)), "Already Joined");
      _;
    }

    function join() external payable _hasJoined(msg.sender) {
        
        if (msg.sender == players[0]){
          playersJoined[0] = msg.sender;
          betAmount = msg.value;
        }

        if (msg.sender == players[1]) {
          require(msg.value == betAmount, "Wrong bet amount.");
          playersJoined[1] = msg.sender;
          status = 0;
        }
        
    }


    /**
      * @dev Check a, b, c in a line are the same
      * _threeInALine doesn't check if a, b, c are in a line
      * @param a position a
      * @param b position b
      * @param c position c
      */    
    function _threeInALine(uint a, uint b, uint c) private pure returns (bool){
        /*Please complete the code here.*/
        return (a != 0 && a == b && a == c);

    }

    modifier _allJoined() {
      for (uint i=0; i < playersJoined.length; i++) {
        require((players[0] != address(0) && playersJoined[0] == players[0]));
      }
      _;
    }


    function winnerInRow(uint[3][3] memory _board) private pure returns (uint){
      for (uint8 x = 0; x < 3; x++) {
        if (_threeInALine(_board[x][0], _board[x][1], _board[x][2])) {
          return _board[x][0];
        }
      }

      return 0;
    }

    function winnerInColumn(uint[3][3] memory _board) private pure returns (uint){
      for (uint8 y = 0; y < 3; y++) {
        if (_threeInALine(_board[0][y], _board[1][y], _board[2][y])) {
          return _board[0][y];
        }
      }

      return 0;
    }

    function winnerInDiagonal(uint[3][3] memory _board) private pure returns (uint){
      
      if (_threeInALine(_board[0][0], _board[1][1], _board[2][2])) {
        return _board[0][0];
      }
      
      if (_threeInALine(_board[0][2], _board[1][1], _board[2][0])) {
        return _board[0][0];
      }

      return 0;
    }

    function fullBoard(uint[3][3] memory _board) private pure returns (bool){
      
      for (uint j=0; j < _board.length; j++) {
        for (uint k=0; k < _board.length; k++) {
          if (_board[j][k] == 0) {
            return false;
          }
        }
      }

      return true;
    }



    /**
     * @dev get the status of the game
     * @return the status of the game
     */
    function _getStatus() private view returns (uint) {
        /*Please complete the code here.*/

        uint cur_status = winnerInRow(board);

        if (cur_status > 0) {
          return cur_status;
        }

        cur_status = winnerInColumn(board);

        if (cur_status > 0) {
          return cur_status;
        }

        cur_status = winnerInDiagonal(board);

        if (cur_status > 0) {
          return cur_status;
        }

        if (fullBoard(board)) {
          return 3;
        }

        return 0;

        // for (uint j=0; j < lines[pos].length; j++) {
        //   if (_threeInALine(lines[pos][j][0], lines[pos][j][1], lines[pos][j][2])){
        //     return board[pos];
        //   }
        // }


        // for (uint k=0; k < board.length; k++) {
        //   if (board[k] == 0) {
        //     return 0;
        //   }
        // }

        // return 3;
    }

    /**
     * @dev ensure the game is still ongoing before a player moving
     * update the status of the game after a player moving
     */
    modifier _checkStatus {
        /*Please complete the code here.*/
        require(status == 0, "Game is Complete.");
        _;
        status = _getStatus();
        if (status > 0 && status < 3 && !paidWinner) {
          paidWinner = true;
          payWinner();
        }
    }

    /**
     * @dev check if it's msg.sender's turn
     * @return true if it's msg.sender's turn otherwise false
     */
    function myTurn() public view returns (bool) {
       /*Please complete the code here.*/
       return msg.sender == players[turn-1];
    }

    /**
     * @dev ensure it's a msg.sender's turn
     * update the turn after a move
     */
    modifier _myTurn() {
      /*Please complete the code here.*/
      require(myTurn(), "Not your turn!");
      _;
      turn = (turn % 2) + 1;

    }

    /**
     * @dev check a move is valid
     * @param pos_x the position the player places at
     * @param pos_y the position the player places at
     * @return true if valid otherwise false
     */
    function validMove(uint pos_x, uint pos_y) public view returns (bool) {
      /*Please complete the code here.*/
      return pos_x >= 0 && pos_x < 9 && pos_y >= 0 && pos_y < 9 && board[pos_x][pos_y] == 0;

    }

    /**
     * @dev ensure a move is valid
     * @param pos_x the position the player places at
     * @param pos_y the position the player places at
     */
    modifier _validMove(uint pos_x, uint pos_y) {
      /*Please complete the code here.*/
      require (validMove(pos_x, pos_y), "Move is invalid.");
      _;
    }

    /**
     * @dev a player makes a move
     * @param pos_x the position the player places at
     * @param pos_y the position the player places at
     */
    function move(uint pos_x, uint pos_y) public _allJoined _validMove(pos_x, pos_y) _checkStatus _myTurn {
        board[pos_x][pos_y] = turn;
    }

    /**
     * @dev show the current board
     * @return board
     */
    function showBoard() public view returns (uint[3][3]) {
      return board;
    }


    function payWinner() private {
      players[status - 1].transfer(betAmount + betAmount);
    }
}


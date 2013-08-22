# Implements the strategy described at http://en.wikipedia.org/wiki/Tic-tac-toe#Strategy.
class TicTacToe

  CORNERS = [[0, 0], [2, 2], [0, 2], [2, 0]]
  SIDES = [[0, 1], [1, 0], [1, 2], [2, 1]]

  FIRST_PLAYER_SYMBOL = :x

  attr_reader :computer_symbol
  attr_reader :player_symbol

  def initialize(player_first = rand(2).zero?)
    @board ||= Array.new(3) { Array.new(3) }
    @board.map! { |array| array.map! { |_| nil }}  # Clear current @board object.
    @computer_symbol = player_first ? :o : :x
    @player_symbol = player_first ? :x : :o
    make_move unless player_first
  end

  # Clear the board and optionally change the assigned symbols.
  def restart(player_first = computer_symbol == :o)
    initialize(player_first)
  end

  # Returns true if move was valid and false otherwise.
  def record_player_move(x, y)
    x = x.to_i
    y = y.to_i
    return false if @board[x][y]
    @board[x][y] = player_symbol
    @last_player_move = [x, y]
    true
  end

  def make_move
    # Try to make a winning move within a row, column or diagonal.
    move = find_completing_moves(computer_symbol).first
    if move
      @board[move.first][move.last] = computer_symbol
      @last_computer_move = move
      return
    end

    # Try to make a blocking move within a row, column or diagonal.
    move = find_completing_moves(player_symbol).first
    if move
      @board[move.first][move.last] = computer_symbol
      @last_computer_move = move
      return
    end

    # Try to fork (create an opportunity where the computer has two threats to win) by trying to mark each empty spot
    # with the computer's symbol, then checking if there are multiple completing moves.
    (0...3).each do |row|
      (0...3).each do |col|
        next unless @board[row][col].nil?

        @board[row][col] = computer_symbol
        @last_computer_move = [row, col]
        return if has_fork?(computer_symbol)

        @board[row][col] = nil
      end
    end

    # Block player's potential fork.
    player_forking_move = forking_move(player_symbol)
    if player_forking_move
      # Option 1: Create two in a row to force the player to defend, as long as it doesn't result in them creating a
      # fork.
      (0...3).each do |row|
        (0...3).each do |col|
          next unless @board[row][col].nil?
          @board[row][col] = computer_symbol

          # Check whether we created two in a row.
          move = find_completing_moves(computer_symbol).first
          if move
            # Check that the player's block doesn't create a fork.
            @board[move.first][move.last] = player_symbol
            has_fork = has_fork?(player_symbol)
            @board[move.first][move.last] = nil
            @last_computer_move = [row, col]
            return unless has_fork
          end

          @board[row][col] = nil
        end
      end

      # Option 2: Block the fork directly.
      @board[player_forking_move.first][player_forking_move.last] = computer_symbol
      @last_computer_move = player_forking_move
      return
    end

    # Mark the center.
    if @board[1][1].nil?
      @board[1][1] = computer_symbol
      @last_computer_move = [1, 1]
      return
    end

    # Mark the opposite corner.
    CORNERS.each do |corner|
      if @board[corner.first][corner.last] == player_symbol && @board[2 - corner.first][2 - corner.last].nil?
        @board[2 - corner.first][2 - corner.last] = computer_symbol
        @last_computer_move = [2 - corner.first, 2 - corner.last]
        return
      end
    end

    # Mark any corner, then any middle square on any of the four sides.
    (CORNERS + SIDES).each do |pos|
      next if @board[pos.first][pos.last]
      @board[pos.first][pos.last] = computer_symbol
      @last_computer_move = pos
      return
    end
  end

  # Returns a string representing the board with coordinates, e.g.:
  #
  #   0 1 2
  # 0 x|x|x
  #   -----
  # 1 o|o|o
  #   -----
  # 2 x|x|x
  #
  # The last computer and player moves are colored red and green, respectively.
  def board_string
    result = "  0 1 2\n"
    (0...3).each do |row|
      result += "#{row} "
      (0...3).each do |col|
        value = maybe_colorize(row, col)
        result += value + '|'
      end
      result = result[0..-2] + "\n"
      result += "  #{'-' * 5}\n" unless row == 2  # No horizontal divider after last row.
    end
    result
  end

  # Returns the winner (:computer or :player) if there is one, :draw if there is a draw, and otherwise nil.
  def winner
    has_more_moves = false
    iterate_triples do |triple|
      has_more_moves = true if triple.include?(nil)
      uniq = triple.uniq
      if uniq.count == 1 && !uniq.first.nil?
        return triple.uniq.first == player_symbol ? :player : :computer
      end
    end

    return has_more_moves ? nil : :draw
  end

private

  # Returns an array of coordinates indicating completing moves within the board for the symbol argument. A completing
  # move is one that results in three in a row/column/diagonal for symbol.
  def find_completing_moves(symbol)
    results = []

    iterate_triples do |triple, index, type|
      index_of_nil = two_of_a_kind(triple, symbol)
      next unless index_of_nil
      case type
      when :row
        results << [index, index_of_nil]
      when :column
        results << [index_of_nil, index]
      when :diagonal
      results << [index_of_nil, index.call(index_of_nil)]
      end
    end

    results
  end

  # Returns coordinates for a forking move for the symbol argument, or nil if there are none. A forking move is one that
  # results in more than one completing move for the symbol.
  def forking_move(symbol)
    (0...3).each do |row|
      (0...3).each do |col|
        next unless @board[row][col].nil?

        @board[row][col] = symbol
        if has_fork?(symbol)
          @board[row][col] = nil
          return row, col
        end

        @board[row][col] = nil
      end
    end

    nil
  end

  # Iterates through all the rows, columns and diagonals on the board. Calls the given block with three arguments: the
  # triple, the index of the row or column (or a lambda to convert between forward and backward diagonals) and the type
  # of the triple (either :row, :column or :diagonal).
  def iterate_triples(&block)
    (0...3).each do |i|
      row = @board[i]
      block.call(row, i, :row)

      col = []
      (0...3).each { |j| col << @board[j][i] }
      block.call(col, i, :column)
    end

    # The lambdas handle the forward and backward diagonal cases.
    [lambda { |x| x }, lambda { |x| 2 - x }].each do |offset|
      diagonal = []
      (0...3).each { |i| diagonal << @board[i][offset.call(i)] }
      block.call(diagonal, offset, :diagonal)
    end
  end

  def has_fork?(symbol)
    return find_completing_moves(symbol).count > 1
  end

  def maybe_colorize(row, col)
    value = @board[row][col]
    return ' ' if value.nil?

    if value == computer_symbol
      if @last_computer_move == [row, col]
        "\e[31m#{computer_symbol}\e[0m"
      else
        computer_symbol.to_s
      end
    else
      if @last_player_move == [row, col]
        "\e[32m#{player_symbol}\e[0m"
      else
        player_symbol.to_s
      end
    end
  end

  # Takes an array of three elements representing either a row, column or diagonal on the board. If the array contains
  # two of the same symbols and one nil element, the index of the nil element is returned. Otherwise, nil is returned.
  def two_of_a_kind(array, symbol)
    index_of_nil = array.find_index(nil)
    return unless index_of_nil

    return array.select { |e| e == symbol }.count == 2 ? index_of_nil : nil
  end

end
